import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skakanka/src/audio.dart';

void main() {
  test('renders valid 16-bit mono WAV for every sound', () {
    for (final entry in sounds.entries) {
      final wav = renderWav(entry.value);
      final d = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF', reason: entry.key);
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(d.getUint16(22, Endian.little), 1);
      expect(d.getUint32(24, Endian.little), 44100);
      expect(d.getUint32(40, Endian.little), wav.length - 44);
      // Not silent.
      var peak = 0;
      for (var i = 44; i < wav.length; i += 2) {
        peak = d.getInt16(i, Endian.little).abs() > peak ? d.getInt16(i, Endian.little).abs() : peak;
      }
      expect(peak, greaterThan(5000), reason: entry.key);
    }
  });
}
