import 'dart:async';

import 'package:flutter/foundation.dart';

import 'plan.dart';

/// What the engine tells the outside world (sound and voice).
abstract class Cues {
  /// A step began. [next] is the next work step when [step] is a break.
  void stepStarted(Step step, Step? nextWork);
  void countdown(int secondsLeft);
  void halfway();
  void finished();
}

/// Runs a list of steps against a wall clock.
///
/// Time is derived from an end timestamp rather than counted ticks, so the
/// workout stays correct when the app is suspended and resumed: on the next
/// tick every step that ended in the meantime is skipped silently.
class WorkoutEngine extends ChangeNotifier {
  WorkoutEngine({required this.steps, required this.cues, this.halfwaySignal = false, DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final List<Step> steps;
  final Cues cues;
  final bool halfwaySignal;
  final DateTime Function() _now;

  int index = 0;
  bool paused = false;
  bool finished = false;
  late DateTime startedAt;
  DateTime? endedAt;

  /// Seconds actually spent in each step, for the calorie estimate.
  final Map<int, double> spent = {};

  late DateTime _endAt;
  Duration _left = Duration.zero;
  int? _lastSec;
  Timer? _timer;

  Step get step => steps[index];

  Duration get remaining {
    if (finished) return Duration.zero;
    final r = paused ? _left : _endAt.difference(_now());
    return r.isNegative ? Duration.zero : r;
  }

  double get stepProgress => 1 - remaining.inMilliseconds / (step.secs * 1000);

  int get total => totalSecs(steps);

  double get doneSecs {
    if (finished) return total.toDouble();
    final before = steps.take(index).fold(0, (a, s) => a + s.secs);
    return before + step.secs - remaining.inMilliseconds / 1000;
  }

  Step? nextWorkFrom(int from) {
    for (var j = from; j < steps.length; j++) {
      if (steps[j].type == StepType.work) return steps[j];
    }
    return null;
  }

  Step? get next => index + 1 < steps.length ? steps[index + 1] : null;

  void start({bool runTimer = true}) {
    startedAt = _now();
    _enter(0);
    if (runTimer) _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
  }

  void _enter(int i, {bool silent = false}) {
    index = i;
    _left = Duration(seconds: step.secs);
    _endAt = _now().add(_left);
    _lastSec = step.secs;
    if (!silent) cues.stepStarted(step, step.type == StepType.work ? null : nextWorkFrom(i + 1));
    notifyListeners();
  }

  void _record(int i, double secs) => spent[i] = (spent[i] ?? 0) + secs;

  void tick() {
    if (paused || finished) return;
    var rem = _endAt.difference(_now());

    // Catch up on steps that ended while the app was not ticking.
    var skipped = false;
    while (rem.inMilliseconds <= -1000 && index + 1 < steps.length) {
      _record(index, step.secs.toDouble());
      final overshoot = -rem;
      index++;
      _endAt = _now().add(Duration(seconds: step.secs)).subtract(overshoot);
      _lastSec = null;
      rem = _endAt.difference(_now());
      skipped = true;
    }
    if (skipped && rem > Duration.zero) {
      _lastSec = (rem.inMilliseconds / 1000).ceil();
      cues.stepStarted(step, step.type == StepType.work ? null : nextWorkFrom(index + 1));
    }

    final sec = (rem.inMilliseconds / 1000).ceil();
    if (sec != _lastSec) {
      _lastSec = sec;
      if (sec >= 1 && sec <= 3) cues.countdown(sec);
      if (halfwaySignal && step.type == StepType.work && step.secs >= 20 && sec == step.secs ~/ 2) cues.halfway();
    }
    if (rem <= Duration.zero) {
      _record(index, step.secs.toDouble());
      if (index + 1 >= steps.length) {
        _finish();
      } else {
        _enter(index + 1);
      }
      return;
    }
    notifyListeners();
  }

  void togglePause() {
    if (finished) return;
    if (paused) {
      paused = false;
      _endAt = _now().add(_left);
    } else {
      _left = remaining;
      paused = true;
    }
    notifyListeners();
  }

  void skip() {
    if (finished) return;
    _record(index, step.secs - remaining.inMilliseconds / 1000);
    if (index + 1 >= steps.length) return _finish();
    final wasPaused = paused;
    _enter(index + 1);
    if (wasPaused) _left = Duration(seconds: step.secs);
  }

  void back() {
    if (finished) return;
    final elapsed = step.secs - remaining.inMilliseconds / 1000;
    _record(index, elapsed);
    final target = elapsed > 2.5 || index == 0 ? index : index - 1;
    final wasPaused = paused;
    _enter(target);
    if (wasPaused) _left = Duration(seconds: step.secs);
  }

  /// Ends early; time spent so far still counts.
  void stop() {
    if (finished) return;
    _record(index, step.secs - remaining.inMilliseconds / 1000);
    _timer?.cancel();
    finished = true;
    endedAt = _now();
    notifyListeners();
  }

  void _finish() {
    _timer?.cancel();
    finished = true;
    endedAt = _now();
    cues.finished();
    notifyListeners();
  }

  int get completedWork =>
      spent.entries.where((e) => steps[e.key].type == StepType.work && e.value >= steps[e.key].secs * 0.8).length;

  double get workDone =>
      spent.entries.where((e) => steps[e.key].type == StepType.work).fold(0.0, (a, e) => a + e.value);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
