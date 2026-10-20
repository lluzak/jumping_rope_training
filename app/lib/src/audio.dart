import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
import 'plan.dart';

enum Wave { square, triangle, sine }

class Tone {
  const Tone(this.freq, this.dur, {this.at = 0, this.wave = Wave.square, this.level = 1});
  final double freq;
  final double dur;
  final double at;
  final Wave wave;
  final double level;
}

/// The beeps, same as the web version: 3-2-1 ticks, high tone for work,
/// low tone for rest, a short melody at the end.
const sounds = <String, List<Tone>>{
  'tick': [Tone(880, 0.12, level: 0.7)],
  'work': [Tone(988, 0.14), Tone(1319, 0.55, at: 0.16)],
  'rest': [Tone(659, 0.2, wave: Wave.triangle, level: 1.3), Tone(440, 0.5, at: 0.22, wave: Wave.triangle, level: 1.3)],
  'soft': [Tone(587, 0.35, wave: Wave.triangle, level: 1.2)],
  'half': [Tone(1568, 0.07, wave: Wave.sine, level: 1.4), Tone(1568, 0.07, at: 0.12, wave: Wave.sine, level: 1.4)],
  'done': [Tone(523, 0.16), Tone(659, 0.16, at: 0.17), Tone(784, 0.16, at: 0.34), Tone(1047, 0.7, at: 0.51)],
};

/// Renders tones to a 16-bit mono WAV file.
Uint8List renderWav(List<Tone> tones, {int rate = 44100}) {
  final length = tones.map((t) => t.at + t.dur).reduce(math.max) + 0.05;
  final n = (length * rate).ceil();
  final buf = Float64List(n);
  for (final t in tones) {
    final start = (t.at * rate).round();
    final count = (t.dur * rate).round();
    final attack = 0.01 * rate, release = 0.04 * rate;
    for (var i = 0; i < count && start + i < n; i++) {
      final phase = (t.freq * i / rate) % 1.0;
      final v = switch (t.wave) {
        Wave.square => phase < 0.5 ? 1.0 : -1.0,
        Wave.triangle => 4 * (phase < 0.5 ? phase : 1 - phase) - 1,
        Wave.sine => math.sin(2 * math.pi * phase),
      };
      final env = math.min(1.0, math.min(i / attack, (count - i) / release));
      buf[start + i] += v * env * 0.3 * t.level;
    }
  }
  final data = ByteData(44 + n * 2);
  void str(int o, String s) => s.codeUnits.asMap().forEach((i, c) => data.setUint8(o + i, c));
  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    data.setInt16(44 + i * 2, (buf[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Native iOS audio (ios/Runner/AudioCoach.swift).
///
/// Beeps mix with music from other apps; while the voice speaks, other audio
/// is ducked (made quieter) instead of paused.
class AudioCoach {
  static const _channel = MethodChannel('skakanka/audio');
  bool _ready = false;

  double volume = 0.8;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _channel.invokeMethod('load', {for (final e in sounds.entries) e.key: renderWav(e.value)});
      _ready = true;
    } on MissingPluginException {
      // Not on iOS (tests, other platforms): stay silent.
    } catch (e) {
      debugPrint('AudioCoach.init: $e');
    }
  }

  Future<void> play(String name) async {
    if (!_ready) return;
    await _channel.invokeMethod('play', {'name': name, 'volume': volume});
  }

  Future<void> speak(String text) async {
    if (!_ready) return;
    await _channel.invokeMethod('speak', {'text': text, 'volume': volume});
  }

  Future<void> stopSpeaking() async {
    if (!_ready) return;
    await _channel.invokeMethod('stopSpeaking');
  }
}

/// Maps engine events to beeps and spoken prompts.
class CoachCues implements Cues {
  CoachCues(this.audio, {required this.beeps, required this.voice});

  final AudioCoach audio;
  final bool beeps;
  final bool voice;

  void _beep(String name) {
    if (beeps) audio.play(name);
  }

  void _say(String text, {int delayMs = 0}) {
    if (!voice) return;
    Future.delayed(Duration(milliseconds: delayMs), () => audio.speak(text));
  }

  @override
  void stepStarted(Step step, Step? nextWork) {
    switch (step.type) {
      case StepType.work:
        _beep('work');
        _say(step.name, delayMs: 650);
      case StepType.rest:
      case StepType.setRest:
        _beep('rest');
        final lead = step.type == StepType.setRest ? 'Przerwa.' : 'Odpoczynek.';
        _say(nextWork == null ? lead : '$lead Następnie: ${nextWork.name}', delayMs: 750);
      case StepType.prep:
        _say('Przygotuj się.');
      case StepType.warm:
      case StepType.cool:
        _beep('soft');
        _say(step.name, delayMs: 450);
    }
  }

  @override
  void countdown(int secondsLeft) => _beep('tick');

  @override
  void halfway() => _beep('half');

  @override
  void finished() {
    _beep('done');
    _say('Koniec treningu. Dobra robota!', delayMs: 1000);
  }
}
