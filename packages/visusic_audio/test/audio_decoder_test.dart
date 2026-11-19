// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:visusic_audio/visusic_audio.dart';

void main() {
  test('WAV decoder resamples a stereo PCM16 file to 48 kHz mono', () {
    final bytes = _wav(sampleRate: 44100, channels: 2, seconds: 1);
    final pcm = decodeWav(bytes);
    expect(pcm.sampleRate, 48000);
    expect(pcm.frames, closeTo(48000, 500));
    expect(pcm.mono.any((value) => value.abs() > 0.01), isTrue);
  });

  test('WAV decoder rejects non-WAV data', () {
    expect(
      () => decodeWav(Uint8List.fromList(List<int>.filled(100, 0))),
      throwsFormatException,
    );
  });
}

Uint8List _wav({
  required int sampleRate,
  required int channels,
  required int seconds,
}) {
  final frames = sampleRate * seconds;
  final dataSize = frames * channels * 2;
  final out = BytesBuilder();
  void string(String value) => out.add(value.codeUnits);
  void u16(int value) => out.add(
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List(),
  );
  void u32(int value) => out.add(
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List(),
  );
  string('RIFF');
  u32(36 + dataSize);
  string('WAVE');
  string('fmt ');
  u32(16);
  u16(1);
  u16(channels);
  u32(sampleRate);
  u32(sampleRate * channels * 2);
  u16(channels * 2);
  u16(16);
  string('data');
  u32(dataSize);
  for (var frame = 0; frame < frames; frame++) {
    final value = (math.sin(frame * 0.05) * 12000).round();
    for (var channel = 0; channel < channels; channel++) {
      u16(value & 0xffff);
    }
  }
  return out.toBytes();
}
