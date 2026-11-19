// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:visusic_audio/visusic_audio.dart';

void main() {
  test('analyzes a 120 BPM click track and detects the tempo', () {
    final pcm = _clickTrack(120, seconds: 6);
    final result = AudioAnalyzer.analyze(pcm);
    expect(result.bpm, closeTo(120, 8));
    expect(result.frames, isNotEmpty);
    expect(result.bandNames, hasLength(7));
    expect(result.frames.first.spectrum, hasLength(64));
    expect(result.waveformPeaks, hasLength(512));
    expect(result.key, isNotEmpty);
  });

  test('analysis cache round-trips and resolves frame features', () {
    final result = AudioAnalyzer.analyze(_clickTrack(120, seconds: 3));
    final cache = AnalysisCache(
      sampleRate: result.sampleRate,
      hopSize: result.hopSize,
      bpm: result.bpm,
      key: result.key,
      duration: result.duration,
      bandNames: result.bandNames,
      frames: result.frames,
      waveformPeaks: result.waveformPeaks,
    );
    final restored = AnalysisCache.decode(cache.encode());
    expect(restored.frames, hasLength(cache.frames.length));
    expect(restored.bpm, closeTo(cache.bpm, 0.001));
    expect(restored.bandNames, cache.bandNames);
    final snapshot = restored.frameAt(1.0);
    expect(snapshot.time, 1.0);
    expect(snapshot.spectrum, hasLength(64));
    expect(snapshot.bands.keys, contains('bass'));
  });

  test('MessagePack codec round-trips supported values', () {
    final values = <String, Object?>{
      'null': null,
      'bool': true,
      'int': -42,
      'double': 3.5,
      'text': 'hello',
      'bytes': Uint8List.fromList(<int>[1, 2, 3]),
      'list': <Object?>[1, 'two', null],
      'map': <String, Object?>{'nested': true},
    };
    final decoded = MsgPackDecoder.decode(MsgPackEncoder.encode(values));
    expect(decoded, isA<Map<Object?, Object?>>());
    final map = decoded as Map<Object?, Object?>;
    expect(map['null'], isNull);
    expect(map['bool'], isTrue);
    expect(map['int'], -42);
    expect(map['double'], 3.5);
    expect(map['text'], 'hello');
    expect(map['bytes'], <int>[1, 2, 3]);
    expect(map['list'], <Object?>[1, 'two', null]);
    expect((map['map'] as Map<Object?, Object?>)['nested'], isTrue);
  });
}

PcmBuffer _clickTrack(double bpm, {required int seconds}) {
  const sampleRate = 48000;
  final length = sampleRate * seconds;
  final mono = Float32List(length);
  final period = sampleRate * 60 / bpm;
  for (var start = 0.0; start < length; start += period) {
    final index = start.round();
    for (var sample = 0; sample < 1200 && index + sample < length; sample++) {
      final envelope = math.exp(-sample / 160);
      mono[index + sample] =
          0.8 * envelope * math.sin(2 * math.pi * 1000 * sample / sampleRate);
    }
  }
  return PcmBuffer(sampleRate: sampleRate, mono: mono);
}
