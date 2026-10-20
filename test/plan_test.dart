import 'package:flutter_test/flutter_test.dart';
import 'package:skakanka/src/plan.dart';

void main() {
  test('beginner plan: 5 sets x 4 exercises with rests between', () {
    final steps = buildSteps(presetPlans.first);
    final work = steps.where((s) => s.type == StepType.work).toList();
    expect(work, hasLength(20));
    expect(work.first.label, 'Seria 1/5 · ćwiczenie 1/4');
    expect(work.last.workIndex, 20);
    expect(steps.where((s) => s.type == StepType.setRest), hasLength(4));
    expect(steps.where((s) => s.type == StepType.rest), hasLength(15));
    // 10 s prep + 5 min warm-up + 5×(4×30 + 3×30) + 4×90 + 5 min cool-down
    expect(totalSecs(steps), 10 + 300 + 5 * 210 + 360 + 300);
  });

  test('tabata has no warm-up, cool-down or set rest', () {
    final steps = buildSteps(presetPlans.firstWhere((p) => p.id == 'tabata'));
    expect(steps.first.type, StepType.prep);
    expect(steps.where((s) => s.type == StepType.work), hasLength(8));
    expect(steps.where((s) => s.type == StepType.rest), hasLength(7));
    expect(steps.last.type, StepType.work);
    expect(totalSecs(steps), 10 + 8 * 20 + 7 * 10);
  });

  test('no set rest falls back to normal rest between sets', () {
    final p = defaultCustomPlan.copyWith(sets: 2, setRest: 0, exerciseIds: ['basic'], warmup: false, cooldown: false);
    final types = buildSteps(p).map((s) => s.type).toList();
    expect(types, [StepType.prep, StepType.work, StepType.rest, StepType.work]);
  });

  test('kcal estimate uses MET x kg x hours', () {
    final steps = [const Step(type: StepType.work, secs: 3600, name: 'x', cue: '')];
    expect(estimateKcal(steps, {0: 3600}, 70), closeTo(770, 0.01));
  });

  test('fmtClock', () {
    expect(fmtClock(0), '0:00');
    expect(fmtClock(65), '1:05');
    expect(fmtClock(-3), '0:00');
  });
}
