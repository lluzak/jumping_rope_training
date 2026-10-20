import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/audio.dart';
import 'src/health_sync.dart';
import 'src/screens/home_screen.dart';
import 'src/settings.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final settings = await Settings.load();
  final audio = AudioCoach();
  await audio.init();
  runApp(SkakankaApp(settings: settings, audio: audio, health: HealthSync()));
}

class SkakankaApp extends StatelessWidget {
  const SkakankaApp({super.key, required this.settings, required this.audio, required this.health});

  final Settings settings;
  final AudioCoach audio;
  final HealthSync health;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skakanka HIIT',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: HomeScreen(settings: settings, audio: audio, health: health),
    );
  }
}
