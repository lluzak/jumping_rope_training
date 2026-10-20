import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skakanka/main.dart';
import 'package:skakanka/src/audio.dart';
import 'package:skakanka/src/health_sync.dart';
import 'package:skakanka/src/settings.dart';

void main() {
  testWidgets('home shows plans, custom editor and starts a workout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await tester.pumpWidget(SkakankaApp(settings: settings, audio: AudioCoach(), health: HealthSync()));

    expect(find.text('PIERWSZE INTERWAŁY'), findsOneWidget);
    expect(find.text('TABATA 20/10'), findsOneWidget);

    await tester.tap(find.text('TWOJE USTAWIENIA'));
    await tester.pump();
    expect(settings.planId, 'custom');
    expect(find.text('ĆWICZENIA W SERII'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PRZYGOTUJ SIĘ'), findsOneWidget);
    expect(find.text('PAUZA'), findsOneWidget);

    await tester.tap(find.text('PAUZA'));
    await tester.pump();
    expect(find.text('WZNÓW'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Zakończ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zakończ'));
    await tester.pumpAndSettle();
    expect(find.text('KONIEC TRENINGU'), findsOneWidget);
  });
}
