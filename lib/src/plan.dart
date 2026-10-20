/// Exercises, training plans and the step list a workout runs through.
library;

class Exercise {
  const Exercise(this.id, this.name, this.en, this.cue);

  final String id;
  final String name;
  final String en;
  final String cue;
}

const exercises = <String, Exercise>{
  'basic': Exercise(
    'basic',
    'Podstawowy skok',
    'Basic bounce',
    'Stopy razem, niskie skoki na palcach, łokcie przy tułowiu.',
  ),
  'boxer': Exercise(
    'boxer',
    'Krok bokserski',
    'Boxer step',
    'Przenoś ciężar z nogi na nogę, jedna stopa lekko przed drugą.',
  ),
  'knees': Exercise(
    'knees',
    'Wysokie kolana',
    'High knees',
    'Bieg w miejscu, kolana do wysokości bioder, brzuch napięty.',
  ),
  'side': Exercise('side', 'Skoki na boki', 'Side to side', 'Skoki obunóż w bok o 20–30 cm, lądowanie miękkie.'),
  'cross': Exercise('cross', 'Skrzyżowanie', 'Criss-cross', 'Co drugi obrót skrzyżuj ręce przed sobą, potem otwórz.'),
  'double': Exercise(
    'double',
    'Podwójny obrót',
    'Double under',
    'Wyższy skok, szybkie nadgarstki. Linka przechodzi 2× pod stopami.',
  ),
};

const _warmup = [
  ('Marsz w miejscu', 60, 'Spokojnie, unoś kolana, pracuj ramionami.'),
  ('Krążenia ramion', 45, 'Duże kręgi w przód i w tył.'),
  ('Krążenia nadgarstków i kostek', 45, 'Rozluźnij stawy, które będą pracować najwięcej.'),
  ('Przysiady', 45, 'Spokojne tempo, pełny zakres.'),
  ('Podskoki bez skakanki', 45, 'Lekko na palcach, naśladuj ruch nadgarstków.'),
  ('Luźne skakanie', 60, 'Podstawowy skok w wolnym tempie.'),
];

const _cooldown = [
  ('Marsz i spokojny oddech', 60, 'Wdech nosem, długi wydech ustami.'),
  ('Rozciąganie łydek', 60, 'Oprzyj ręce o ścianę, pięta przy podłodze. 30 s na nogę.'),
  ('Rozciąganie przodu uda', 60, 'Przyciągnij piętę do pośladka. 30 s na nogę.'),
  ('Skłon do nóg', 60, 'Kolana lekko ugięte, rozluźnij plecy.'),
  ('Rozciąganie barków', 60, 'Ramię przed klatką, dociśnij drugą ręką. 30 s na stronę.'),
];

class Plan {
  const Plan({
    required this.id,
    required this.level,
    required this.name,
    required this.work,
    required this.rest,
    required this.sets,
    required this.setRest,
    required this.exerciseIds,
    this.warmup = true,
    this.cooldown = true,
  });

  final String id;
  final String level;
  final String name;
  final int work;
  final int rest;
  final int sets;
  final int setRest;
  final List<String> exerciseIds;
  final bool warmup;
  final bool cooldown;

  Plan copyWith({
    int? work,
    int? rest,
    int? sets,
    int? setRest,
    List<String>? exerciseIds,
    bool? warmup,
    bool? cooldown,
  }) => Plan(
    id: id,
    level: level,
    name: name,
    work: work ?? this.work,
    rest: rest ?? this.rest,
    sets: sets ?? this.sets,
    setRest: setRest ?? this.setRest,
    exerciseIds: exerciseIds ?? this.exerciseIds,
    warmup: warmup ?? this.warmup,
    cooldown: cooldown ?? this.cooldown,
  );

  String get scheme {
    final s = sets == 1 ? 'seria' : (sets < 5 ? 'serie' : 'serii');
    return '$sets $s × ${exerciseIds.length} ćw. · $work s / $rest s';
  }
}

const presetPlans = [
  Plan(
    id: 'beg',
    level: 'Początkujący',
    name: 'Pierwsze interwały',
    work: 30,
    rest: 30,
    sets: 5,
    setRest: 90,
    exerciseIds: ['basic', 'boxer', 'side', 'knees'],
  ),
  Plan(
    id: 'mid',
    level: 'Średniozaawansowany',
    name: 'Interwały 40/20',
    work: 40,
    rest: 20,
    sets: 4,
    setRest: 60,
    exerciseIds: ['basic', 'boxer', 'knees', 'side', 'cross'],
  ),
  Plan(
    id: 'adv',
    level: 'Zaawansowany',
    name: 'Spalanie 45/15',
    work: 45,
    rest: 15,
    sets: 4,
    setRest: 45,
    exerciseIds: ['basic', 'knees', 'cross', 'side', 'double', 'boxer'],
  ),
  Plan(
    id: 'tabata',
    level: 'Szybki',
    name: 'Tabata 20/10',
    work: 20,
    rest: 10,
    sets: 1,
    setRest: 0,
    exerciseIds: ['basic', 'knees', 'basic', 'knees', 'basic', 'knees', 'basic', 'knees'],
    warmup: false,
    cooldown: false,
  ),
];

const defaultCustomPlan = Plan(
  id: 'custom',
  level: 'Własny',
  name: 'Twoje ustawienia',
  work: 30,
  rest: 30,
  sets: 3,
  setRest: 60,
  exerciseIds: ['basic', 'boxer', 'knees'],
);

enum StepType { prep, warm, work, rest, setRest, cool }

/// Rough MET values per phase, used for the calorie estimate.
const _met = {
  StepType.prep: 1.5,
  StepType.warm: 3.5,
  StepType.work: 11.0,
  StepType.rest: 3.0,
  StepType.setRest: 2.5,
  StepType.cool: 2.3,
};

class Step {
  const Step({
    required this.type,
    required this.secs,
    required this.name,
    required this.cue,
    this.exerciseId,
    this.label,
    this.workIndex,
    this.workCount,
  });

  final StepType type;
  final int secs;
  final String name;
  final String cue;
  final String? exerciseId;

  /// "Seria 2/5 · ćwiczenie 3/4" for work steps.
  final String? label;

  /// 1-based number of this work interval and the total number of them.
  final int? workIndex;
  final int? workCount;

  double get met => _met[type]!;
}

const _restCue = 'Oddychaj, rozluźnij ramiona.';

List<Step> buildSteps(Plan p) {
  final steps = <Step>[
    const Step(
      type: StepType.prep,
      secs: 10,
      name: 'Przygotuj się',
      cue: 'Weź skakankę i stań w miejscu z wolną przestrzenią.',
    ),
  ];
  if (p.warmup) {
    for (final (name, secs, cue) in _warmup) {
      steps.add(Step(type: StepType.warm, secs: secs, name: name, cue: cue));
    }
  }
  final total = p.sets * p.exerciseIds.length;
  var k = 0;
  for (var s = 0; s < p.sets; s++) {
    for (var j = 0; j < p.exerciseIds.length; j++) {
      final ex = exercises[p.exerciseIds[j]]!;
      k++;
      steps.add(
        Step(
          type: StepType.work,
          secs: p.work,
          name: ex.name,
          cue: ex.cue,
          exerciseId: ex.id,
          label: 'Seria ${s + 1}/${p.sets} · ćwiczenie ${j + 1}/${p.exerciseIds.length}',
          workIndex: k,
          workCount: total,
        ),
      );
      final lastInSet = j == p.exerciseIds.length - 1;
      if (!lastInSet && p.rest > 0) {
        steps.add(Step(type: StepType.rest, secs: p.rest, name: 'Odpoczynek', cue: _restCue));
      }
    }
    final lastSet = s == p.sets - 1;
    if (!lastSet && p.setRest > 0) {
      steps.add(
        Step(
          type: StepType.setRest,
          secs: p.setRest,
          name: 'Przerwa',
          cue: 'Koniec serii ${s + 1}. Napij się wody, chodź spokojnie.',
        ),
      );
    } else if (!lastSet && p.rest > 0) {
      steps.add(Step(type: StepType.rest, secs: p.rest, name: 'Odpoczynek', cue: _restCue));
    }
  }
  if (p.cooldown) {
    for (final (name, secs, cue) in _cooldown) {
      steps.add(Step(type: StepType.cool, secs: secs, name: name, cue: cue));
    }
  }
  return steps;
}

int totalSecs(List<Step> steps) => steps.fold(0, (a, s) => a + s.secs);

int workSecs(List<Step> steps) => steps.where((s) => s.type == StepType.work).fold(0, (a, s) => a + s.secs);

/// Estimated kcal for time actually spent in each step (MET × kg × hours).
double estimateKcal(List<Step> steps, Map<int, double> spentSecs, double weightKg) {
  var kcal = 0.0;
  spentSecs.forEach((i, secs) => kcal += steps[i].met * weightKg * secs / 3600);
  return kcal;
}

String fmtClock(num secs) {
  final s = secs.round().clamp(0, 1 << 30);
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
