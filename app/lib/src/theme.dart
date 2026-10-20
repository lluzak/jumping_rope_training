import 'package:flutter/material.dart' hide Step;

import 'plan.dart';

/// Same palette as the web version.
class Palette {
  static const accentLight = Color(0xFF2545D3);
  static const accentDark = Color(0xFF7D93FF);

  static const prep = Color(0xFF2545D3);
  static const work = Color(0xFFD73A2E);
  static const rest = Color(0xFF0D7D6C);
  static const setRest = Color(0xFF4B3FB8);
  static const warm = Color(0xFFA8650A);
  static const cool = Color(0xFF3A6D93);
  static const done = Color(0xFF1D2438);

  static Color phase(StepType t) => switch (t) {
    StepType.prep => prep,
    StepType.warm => warm,
    StepType.work => work,
    StepType.rest => rest,
    StepType.setRest => setRest,
    StepType.cool => cool,
  };
}

const phaseNames = {
  StepType.prep: 'Przygotuj się',
  StepType.warm: 'Rozgrzewka',
  StepType.work: 'Praca',
  StepType.rest: 'Odpoczynek',
  StepType.setRest: 'Przerwa między seriami',
  StepType.cool: 'Schłodzenie',
};

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.accentLight,
    brightness: b,
    primary: dark ? Palette.accentDark : Palette.accentLight,
    surface: dark ? const Color(0xFF161B2E) : Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0D1120) : const Color(0xFFF2F4F8),
    useMaterial3: true,
  );
}

/// Condensed, heavy style for headings and the clock.
TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w800, double spacing = 0}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: spacing,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

TextStyle eyebrow(BuildContext context) => TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
);
