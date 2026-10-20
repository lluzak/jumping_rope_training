import 'package:flutter/material.dart' hide Step;

import '../audio.dart';
import '../health_sync.dart';
import '../plan.dart';
import '../settings.dart';
import '../theme.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings, required this.audio, required this.health});

  final Settings settings;
  final AudioCoach audio;
  final HealthSync health;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _healthWeight;

  Settings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    if (s.healthEnabled) _loadWeight();
  }

  Future<void> _loadWeight() async {
    final w = await widget.health.latestWeightKg();
    if (mounted) setState(() => _healthWeight = w);
  }

  double get _weight => _healthWeight ?? s.weightKg;

  Future<void> _toggleHealth(bool on) async {
    if (on) {
      final ok = await widget.health.connect();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Brak dostępu do Zdrowia. Zezwól w Ustawieniach → Zdrowie → Dostęp do danych → Skakanka.'),
            ),
          );
        }
        return;
      }
      await _loadWeight();
    }
    s.healthEnabled = on;
  }

  void _testSound() {
    widget.audio.volume = s.volume;
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 1000 * i), () => widget.audio.play('tick'));
    }
    Future.delayed(const Duration(milliseconds: 3000), () => widget.audio.play('work'));
    if (s.voice) Future.delayed(const Duration(milliseconds: 3700), () => widget.audio.speak('Test dźwięku. Start!'));
  }

  void _start() {
    widget.audio.volume = s.volume;
    final plan = s.selectedPlan;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WorkoutScreen(plan: plan, settings: s, audio: widget.audio, health: widget.health, weightKg: _weight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final plan = s.selectedPlan;
        final steps = buildSteps(plan);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Text('INTERWAŁY ZE SKAKANKĄ', style: eyebrow(context)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'SKAKANKA '),
                      TextSpan(
                        text: 'HIIT',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                  style: display(40),
                ),
                const SizedBox(height: 24),
                _SectionTitle('Trening'),
                _PlanGrid(selected: s.planId, custom: s.customPlan, onSelect: (id) => s.planId = id),
                if (s.planId == 'custom') ...[
                  const SizedBox(height: 12),
                  _CustomEditor(plan: s.customPlan, onChanged: (p) => s.customPlan = p),
                ],
                const SizedBox(height: 24),
                _SectionTitle('Przebieg'),
                _Summary(plan: plan, steps: steps, weightKg: _weight),
                const SizedBox(height: 24),
                _SectionTitle('Dźwięk'),
                _Card(
                  children: [
                    SwitchListTile(
                      title: const Text('Sygnały'),
                      subtitle: const Text('3-2-1 przed zmianą, wysoki ton na start, niski na odpoczynek'),
                      value: s.beeps,
                      onChanged: (v) => s.beeps = v,
                    ),
                    SwitchListTile(
                      title: const Text('Głos lektora'),
                      subtitle: const Text('Ścisza muzykę na czas komunikatu, nie zatrzymuje jej'),
                      value: s.voice,
                      onChanged: (v) => s.voice = v,
                    ),
                    SwitchListTile(
                      title: const Text('Sygnał w połowie interwału'),
                      value: s.halfway,
                      onChanged: (v) => s.halfway = v,
                    ),
                    ListTile(
                      title: const Text('Głośność'),
                      subtitle: Slider(value: s.volume, onChanged: (v) => s.volume = v),
                      trailing: OutlinedButton(onPressed: _testSound, child: const Text('Test')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle('Apple Zdrowie'),
                _Card(
                  children: [
                    SwitchListTile(
                      title: const Text('Połącz ze Zdrowiem'),
                      subtitle: const Text('Zapis treningów i kalorii, odczyt wagi i tętna'),
                      value: s.healthEnabled,
                      onChanged: widget.health.available ? _toggleHealth : null,
                    ),
                    if (s.healthEnabled)
                      SwitchListTile(
                        title: const Text('Zapisuj automatycznie po treningu'),
                        value: s.autoSave,
                        onChanged: (v) => s.autoSave = v,
                      ),
                    ListTile(
                      title: const Text('Waga do szacowania kalorii'),
                      subtitle: Text(_healthWeight != null ? 'Z aplikacji Zdrowie' : 'Ustaw ręcznie'),
                      trailing: _healthWeight != null
                          ? Text('${_healthWeight!.toStringAsFixed(1)} kg', style: display(20))
                          : _Stepper(
                              value: s.weightKg.round(),
                              min: 30,
                              max: 200,
                              step: 1,
                              unit: 'kg',
                              onChanged: (v) => s.weightKg = v.toDouble(),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle('Technika'),
                const _Tips(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('START', style: display(24, spacing: 2)),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(), style: display(20, weight: FontWeight.w700, spacing: 0.8)),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.selected, required this.custom, required this.onSelect});

  final String selected;
  final Plan custom;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final plans = [...presetPlans, custom];
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final p in plans)
              SizedBox(
                width: w,
                child: Material(
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: p.id == selected ? cs.primary : cs.outlineVariant,
                      width: p.id == selected ? 2.5 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelect(p.id),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.level.toUpperCase(), style: eyebrow(context)),
                          const SizedBox(height: 6),
                          Text(p.name.toUpperCase(), style: display(19, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(p.scheme, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Text(
                            '${(totalSecs(buildSteps(p)) / 60).round()} min',
                            style: display(16, color: cs.primary, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CustomEditor extends StatelessWidget {
  const _CustomEditor({required this.plan, required this.onChanged});

  final Plan plan;
  final ValueChanged<Plan> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int value, int min, int max, int step, String unit, Plan Function(int) apply) => ListTile(
      title: Text(label),
      trailing: _Stepper(
        value: value,
        min: min,
        max: max,
        step: step,
        unit: unit,
        onChanged: (v) => onChanged(apply(v)),
      ),
    );
    return _Card(
      children: [
        row('Praca', plan.work, 5, 600, 5, 's', (v) => plan.copyWith(work: v)),
        row('Odpoczynek', plan.rest, 0, 600, 5, 's', (v) => plan.copyWith(rest: v)),
        row('Serie', plan.sets, 1, 20, 1, '', (v) => plan.copyWith(sets: v)),
        row('Przerwa między seriami', plan.setRest, 0, 600, 15, 's', (v) => plan.copyWith(setRest: v)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ĆWICZENIA W SERII', style: eyebrow(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final ex in exercises.values)
                    FilterChip(
                      label: Text(ex.name),
                      selected: plan.exerciseIds.contains(ex.id),
                      onSelected: (on) {
                        final ids = [
                          for (final id in exercises.keys)
                            if (id == ex.id ? on : plan.exerciseIds.contains(id)) id,
                        ];
                        if (ids.isNotEmpty) onChanged(plan.copyWith(exerciseIds: ids));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Rozgrzewka 5 min'),
          value: plan.warmup,
          onChanged: (v) => onChanged(plan.copyWith(warmup: v)),
        ),
        SwitchListTile(
          title: const Text('Schłodzenie 5 min'),
          value: plan.cooldown,
          onChanged: (v) => onChanged(plan.copyWith(cooldown: v)),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
  });

  final int value, min, max, step;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: value - step >= min ? () => onChanged(value - step) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 64,
        child: Text('$value${unit.isEmpty ? '' : ' $unit'}', textAlign: TextAlign.center, style: display(18)),
      ),
      IconButton(
        onPressed: value + step <= max ? () => onChanged(value + step) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan, required this.steps, required this.weightKg});

  final Plan plan;
  final List<Step> steps;
  final double weightKg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kcal = estimateKcal(steps, {for (var i = 0; i < steps.length; i++) i: steps[i].secs.toDouble()}, weightKg);
    Widget fact(String value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: display(26)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: eyebrow(context)),
      ],
    );
    final unique = plan.exerciseIds.toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            fact(fmtClock(totalSecs(steps)), 'Całość'),
            fact(fmtClock(workSecs(steps)), 'Czysta praca'),
            fact('${steps.where((s) => s.type == StepType.work).length}', 'Interwały'),
            fact('~${kcal.round()}', 'kcal'),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                for (final s in steps)
                  Expanded(
                    flex: s.secs,
                    child: Container(margin: const EdgeInsets.only(right: 1), color: Palette.phase(s.type)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final t in [StepType.warm, StepType.work, StepType.rest, StepType.setRest, StepType.cool])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: Palette.phase(t)),
                  const SizedBox(width: 6),
                  Text(phaseNames[t]!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          children: [
            for (var i = 0; i < unique.length; i++)
              ListTile(
                leading: Text('${i + 1}', style: display(22, color: Palette.work)),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: exercises[unique[i]]!.name),
                      TextSpan(
                        text: '  ${exercises[unique[i]]!.en}',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                subtitle: Text(exercises[unique[i]]!.cue),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Długość: stań na środku linki, uchwyty powinny sięgać mniej więcej pach.',
      'Kręć z nadgarstków, łokcie trzymaj blisko tułowia.',
      'Skacz nisko, na palcach, lądowanie miękkie z lekko ugiętymi kolanami.',
      'Jeśli ćwiczenie nie wychodzi, zrób w tym czasie podstawowy skok. Tempo ważniejsze niż figura.',
    ];
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: muted)),
                Expanded(
                  child: Text(t, style: TextStyle(color: muted)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
