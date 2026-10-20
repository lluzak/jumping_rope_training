import 'package:flutter/material.dart' hide Step;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../audio.dart';
import '../engine.dart';
import '../health_sync.dart';
import '../plan.dart';
import '../settings.dart';
import '../theme.dart';
import 'summary_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.plan,
    required this.settings,
    required this.audio,
    required this.health,
    required this.weightKg,
  });

  final Plan plan;
  final Settings settings;
  final AudioCoach audio;
  final HealthSync health;
  final double weightKg;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  late final WorkoutEngine engine;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    engine = WorkoutEngine(
      steps: buildSteps(widget.plan),
      cues: CoachCues(widget.audio, beeps: widget.settings.beeps, voice: widget.settings.voice),
      halfwaySignal: widget.settings.halfway,
    )..addListener(_onChange);
    engine.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catch up immediately when returning from the background.
    if (state == AppLifecycleState.resumed) engine.tick();
  }

  void _onChange() {
    if (engine.finished && !_left) {
      _left = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            engine: engine,
            plan: widget.plan,
            settings: widget.settings,
            health: widget.health,
            weightKg: widget.weightKg,
          ),
        ),
      );
    }
  }

  Future<void> _confirmStop() async {
    final wasPaused = engine.paused;
    if (!wasPaused) engine.togglePause();
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zakończyć trening?'),
        content: const Text('Dotychczasowy czas zostanie podsumowany.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ćwiczę dalej')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zakończ')),
        ],
      ),
    );
    if (stop == true) {
      widget.audio.stopSpeaking();
      engine.stop();
    } else if (!wasPaused) {
      engine.togglePause();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    engine.removeListener(_onChange);
    if (!engine.finished) engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: ListenableBuilder(
        listenable: engine,
        builder: (context, _) {
          if (engine.finished) return const Scaffold(backgroundColor: Palette.done);
          final s = engine.step;
          final nextWork = s.type == StepType.work ? null : engine.nextWorkFrom(engine.index + 1);
          final next = engine.next;
          final remaining = engine.remaining;
          String nextText;
          if (s.type == StepType.prep && next != null) {
            nextText = 'Następnie: ${next.name} · ${fmtClock(next.secs)}';
          } else if ((s.type == StepType.rest || s.type == StepType.setRest) && nextWork != null) {
            nextText = 'Następnie: ${nextWork.name} · ${fmtClock(nextWork.secs)}';
          } else if (next != null) {
            nextText = 'Potem: ${next.type == StepType.rest ? 'Odpoczynek' : next.name} · ${fmtClock(next.secs)}';
          } else {
            nextText = 'Ostatni etap';
          }
          final title = switch (s.type) {
            StepType.prep => '',
            StepType.rest => nextWork?.name ?? '',
            _ => s.name,
          };
          final workRef = s.type == StepType.work ? s : engine.nextWorkFrom(engine.index);
          final round = s.type == StepType.work
              ? '${s.label} · interwał ${s.workIndex}/${s.workCount}'
              : (workRef != null ? 'Przed interwałem ${workRef.workIndex}/${workRef.workCount}' : 'Po części głównej');
          const white = Colors.white;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: Palette.phase(s.type),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.plan.level} · ${widget.plan.name}',
                              style: const TextStyle(color: white, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _confirmStop,
                            style: TextButton.styleFrom(
                              foregroundColor: white,
                              backgroundColor: white.withValues(alpha: 0.14),
                            ),
                            child: const Text('Zakończ'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (engine.paused ? 'Pauza' : phaseNames[s.type]!).toUpperCase(),
                              style: display(20, color: white.withValues(alpha: 0.9), spacing: 4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: display(40, color: white),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 44,
                              child: Text(
                                s.cue,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: white.withValues(alpha: 0.9), fontSize: 15),
                              ),
                            ),
                            FittedBox(
                              child: Opacity(
                                opacity: engine.paused ? 0.55 : 1,
                                child: Text(
                                  fmtClock((remaining.inMilliseconds / 1000).ceil()),
                                  style: display(170, color: white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(nextText, style: const TextStyle(color: white, fontSize: 16)),
                          ],
                        ),
                      ),
                      _Bar(value: engine.stepProgress, height: 8),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(round, style: const TextStyle(color: white, fontSize: 13)),
                          ),
                          Text(
                            'Zostało ${fmtClock(engine.total - engine.doneSecs)}',
                            style: const TextStyle(color: white, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Bar(value: engine.doneSecs / engine.total, height: 4),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _CtrlButton(label: 'Wstecz', onTap: engine.back),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _CtrlButton(
                              label: engine.paused ? 'Wznów' : 'Pauza',
                              onTap: engine.togglePause,
                              main: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CtrlButton(label: 'Dalej', onTap: engine.skip),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.height});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      color: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
    ),
  );
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({required this.label, required this.onTap, this.main = false});
  final String label;
  final VoidCallback onTap;
  final bool main;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: main ? Colors.white : Colors.white.withValues(alpha: 0.16),
      foregroundColor: main ? const Color(0xFF141A2C) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label.toUpperCase(), style: display(main ? 22 : 17, spacing: 1.2)),
  );
}
