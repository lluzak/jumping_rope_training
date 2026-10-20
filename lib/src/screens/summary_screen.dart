import 'package:flutter/material.dart' hide Step;

import '../engine.dart';
import '../health_sync.dart';
import '../plan.dart';
import '../settings.dart';
import '../theme.dart';

enum _SaveState { idle, saving, saved, failed }

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.engine,
    required this.plan,
    required this.settings,
    required this.health,
    required this.weightKg,
  });

  final WorkoutEngine engine;
  final Plan plan;
  final Settings settings;
  final HealthSync health;
  final double weightKg;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  _SaveState _save = _SaveState.idle;
  int? _avgHr;

  WorkoutEngine get e => widget.engine;
  int get _kcal => estimateKcal(e.steps, e.spent, widget.weightKg).round();
  Duration get _duration => e.endedAt!.difference(e.startedAt);

  @override
  void initState() {
    super.initState();
    if (widget.settings.healthEnabled) {
      widget.health.averageHeartRate(e.startedAt, e.endedAt!).then((hr) {
        if (mounted) setState(() => _avgHr = hr);
      });
      if (widget.settings.autoSave && e.workDone > 0) _saveToHealth();
    }
  }

  @override
  void dispose() {
    e.dispose();
    super.dispose();
  }

  Future<void> _saveToHealth() async {
    setState(() => _save = _SaveState.saving);
    final ok = await widget.health.saveWorkout(
      start: e.startedAt,
      end: e.endedAt!,
      kcal: _kcal,
      title: 'Skakanka HIIT – ${widget.plan.name}',
    );
    if (mounted) setState(() => _save = ok ? _SaveState.saved : _SaveState.failed);
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    Widget fact(String value, String label) => Column(
      children: [
        Text(value, style: display(34, color: white)),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(color: white.withValues(alpha: 0.8), fontSize: 11, letterSpacing: 1.4),
        ),
      ],
    );
    final healthLine = switch (_save) {
      _SaveState.idle => null,
      _SaveState.saving => 'Zapisuję w aplikacji Zdrowie…',
      _SaveState.saved => 'Zapisano w aplikacji Zdrowie',
      _SaveState.failed => 'Nie udało się zapisać. Sprawdź dostęp w Ustawieniach → Zdrowie.',
    };
    return Scaffold(
      backgroundColor: Palette.done,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('KONIEC TRENINGU', style: display(20, color: white.withValues(alpha: 0.9), spacing: 4)),
                    const SizedBox(height: 10),
                    Text(
                      e.completedWork == e.steps.where((s) => s.type == StepType.work).length
                          ? 'DOBRA ROBOTA'
                          : 'ZAPISANE',
                      style: display(44, color: white),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 28,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        fact(fmtClock(_duration.inSeconds), 'Czas'),
                        fact('${e.completedWork}', 'Interwały'),
                        fact(fmtClock(e.workDone), 'Skakania'),
                        fact('~$_kcal', 'kcal'),
                        if (_avgHr != null) fact('$_avgHr', 'Śr. tętno'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (healthLine != null)
                      Text(
                        healthLine,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: white),
                      ),
                    if (widget.settings.healthEnabled && (_save == _SaveState.idle || _save == _SaveState.failed))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: _saveToHealth,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: white,
                            side: const BorderSide(color: white),
                          ),
                          child: const Text('Zapisz w Zdrowiu'),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: white,
                    foregroundColor: const Color(0xFF141A2C),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('WRÓĆ DO PLANU', style: display(22, spacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
