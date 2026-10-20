import 'package:flutter_test/flutter_test.dart';
import 'package:skakanka/src/engine.dart';
import 'package:skakanka/src/plan.dart';

class RecordingCues implements Cues {
  final events = <String>[];
  @override
  void stepStarted(Step step, Step? nextWork) =>
      events.add('start:${step.name}${nextWork == null ? '' : '>${nextWork.name}'}');
  @override
  void countdown(int secondsLeft) => events.add('tick:$secondsLeft');
  @override
  void halfway() => events.add('half');
  @override
  void finished() => events.add('done');
}

void main() {
  late DateTime now;
  late RecordingCues cues;
  final plan = defaultCustomPlan.copyWith(
    work: 20,
    rest: 10,
    sets: 1,
    setRest: 0,
    exerciseIds: ['basic', 'knees'],
    warmup: false,
    cooldown: false,
  );

  WorkoutEngine make({bool halfway = false}) {
    now = DateTime(2026, 1, 1, 8);
    cues = RecordingCues();
    return WorkoutEngine(steps: buildSteps(plan), cues: cues, halfwaySignal: halfway, clock: () => now)
      ..start(runTimer: false);
  }

  void advance(WorkoutEngine e, double secs) {
    for (var t = 0; t < secs * 10; t++) {
      now = now.add(const Duration(milliseconds: 100));
      e.tick();
    }
  }

  test('runs through all steps with countdown and cues', () {
    final e = make(halfway: true);
    expect(e.step.type, StepType.prep);
    expect(cues.events.first, 'start:Przygotuj się>Podstawowy skok');
    advance(e, 10);
    expect(e.step.name, 'Podstawowy skok');
    expect(cues.events.where((x) => x.startsWith('tick')), ['tick:3', 'tick:2', 'tick:1']);
    advance(e, 20);
    expect(e.step.type, StepType.rest);
    expect(cues.events, contains('half'));
    expect(cues.events.last, 'start:Odpoczynek>Wysokie kolana');
    advance(e, 30);
    expect(e.finished, isTrue);
    expect(cues.events.last, 'done');
    expect(e.completedWork, 2);
    expect(e.workDone, 40);
  });

  test('pause freezes the clock', () {
    final e = make();
    advance(e, 4);
    e.togglePause();
    final left = e.remaining;
    advance(e, 30);
    expect(e.remaining, left);
    expect(e.index, 0);
    e.togglePause();
    advance(e, 6.1);
    expect(e.step.name, 'Podstawowy skok');
  });

  test('skip and back', () {
    final e = make();
    e.skip();
    expect(e.step.name, 'Podstawowy skok');
    advance(e, 5);
    e.back(); // more than 2.5 s in: restart this step
    expect(e.step.name, 'Podstawowy skok');
    expect(e.remaining, const Duration(seconds: 20));
    e.back(); // right at the start: go to the previous step
    expect(e.step.type, StepType.prep);
  });

  test('catches up after the app was suspended', () {
    final e = make();
    now = now.add(const Duration(seconds: 35)); // prep 10 + work 20 + 5 s into rest
    e.tick();
    expect(e.step.type, StepType.rest);
    expect(e.remaining.inSeconds, inInclusiveRange(4, 5));
    expect(e.spent[1], 20);
  });

  test('stop counts time spent so far', () {
    final e = make();
    advance(e, 15);
    e.stop();
    expect(e.finished, isTrue);
    expect(e.workDone, closeTo(5, 0.2));
    expect(cues.events, isNot(contains('done')));
  });
}
