// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

/// Immutable named feature values consumed by renderers and bindings.
final class FeatureSnapshot {
  /// Creates a feature frame.
  FeatureSnapshot({
    required this.time,
    required this.duration,
    this.rms = 0,
    this.peak = 0,
    this.energyShort = 0,
    this.energyLong = 0,
    this.bpm = 120,
    this.beatPhase = 0,
    this.beatIndex = 0,
    required this.spectrum,
    required this.waveform,
    Map<String, double>? bands,
    this.lyricLineIndex = 0,
    this.lyricWordIndex = 0,
    this.lyricLineProgress = 0,
    this.lyricWordProgress = 0,
    this.lyricLine,
    this.lyricNextLine,
    this.lyricTranslation,
  }) : bands = Map.unmodifiable(bands ?? const <String, double>{});

  /// Position in seconds.
  final double time;

  /// Timeline duration in seconds.
  final double duration;

  /// Overall RMS level.
  final double rms;

  /// Overall peak level.
  final double peak;

  /// Short-term normalized energy.
  final double energyShort;

  /// Long-term normalized energy.
  final double energyLong;

  /// Tempo in beats per minute.
  final double bpm;

  /// Phase inside the current beat in the 0..1 range.
  final double beatPhase;

  /// Beat index since the timeline start.
  final int beatIndex;

  /// Sixty-four logarithmically grouped spectrum values.
  final Float64List spectrum;

  /// One hundred twenty-eight waveform values.
  final Float64List waveform;

  /// Named frequency bands.
  final Map<String, double> bands;

  /// Index of the active lyric line.
  final int lyricLineIndex;

  /// Index of the active word inside the line.
  final int lyricWordIndex;

  /// Progress through the active line in 0..1.
  final double lyricLineProgress;

  /// Progress through the active word in 0..1.
  final double lyricWordProgress;

  /// Active lyric line text.
  final String? lyricLine;

  /// Next lyric line text, when available.
  final String? lyricNextLine;

  /// Optional active translation line.
  final String? lyricTranslation;

  /// Whether this frame contains a beat attack.
  bool get isBeat => beatPhase < 0.045;

  /// Progress in the 0..1 range.
  double get progress =>
      duration <= 0 ? 0 : (time / duration).clamp(0, 1).toDouble();

  /// Silent frame used for empty states and tests.
  factory FeatureSnapshot.silent(double duration) => FeatureSnapshot(
    time: 0,
    duration: duration,
    spectrum: Float64List(64),
    waveform: Float64List(128),
  );

  /// Deterministic demonstration data; no microphone or real audio is used.
  factory FeatureSnapshot.demo(double time, double duration) {
    const bpm = 120.0;
    final beatPosition = time * bpm / 60;
    final phase = beatPosition - beatPosition.floorToDouble();
    final kick = math.exp(-phase * 9);
    final bass = (0.28 + kick * 0.68).clamp(0, 1).toDouble();
    final spectrum = Float64List.fromList(
      List<double>.generate(64, (int index) {
        final frequency = index / 63;
        final envelope = math.exp(-frequency * 1.8) * 0.55 + 0.15;
        final motion = math.sin(time * 3.1 + index * 0.43) * 0.16;
        final beatBoost = kick * math.exp(-frequency * 3.2) * 0.45;
        return (envelope + motion + beatBoost).clamp(0, 1).toDouble();
      }),
    );
    final waveform = Float64List.fromList(
      List<double>.generate(128, (int index) {
        final position = index / 127;
        return math.sin(position * math.pi * 8 + time * 5) *
            (0.28 + bass * 0.45);
      }),
    );
    return FeatureSnapshot(
      time: time,
      duration: duration,
      rms: 0.22 + bass * 0.5,
      peak: 0.45 + bass * 0.5,
      energyShort: bass,
      energyLong: 0.42,
      bpm: bpm,
      beatPhase: phase,
      beatIndex: beatPosition.floor(),
      spectrum: spectrum,
      waveform: waveform,
      bands: <String, double>{
        'sub': bass * 0.8,
        'bass': bass,
        'lowMid': 0.35 + kick * 0.25,
        'mid': 0.4 + math.sin(time * 1.7) * 0.18,
        'highMid': 0.32 + math.sin(time * 2.3) * 0.12,
        'high': 0.25 + kick * 0.18,
        'air': 0.16 + math.sin(time * 3.7) * 0.06,
      },
    );
  }

  /// Copies this frame with lyric state attached for renderers.
  FeatureSnapshot copyWithLyrics({
    int? lyricLineIndex,
    int? lyricWordIndex,
    double? lyricLineProgress,
    double? lyricWordProgress,
    String? lyricLine,
    String? lyricNextLine,
    String? lyricTranslation,
  }) {
    return FeatureSnapshot(
      time: time,
      duration: duration,
      rms: rms,
      peak: peak,
      energyShort: energyShort,
      energyLong: energyLong,
      bpm: bpm,
      beatPhase: beatPhase,
      beatIndex: beatIndex,
      spectrum: spectrum,
      waveform: waveform,
      bands: bands,
      lyricLineIndex: lyricLineIndex ?? this.lyricLineIndex,
      lyricWordIndex: lyricWordIndex ?? this.lyricWordIndex,
      lyricLineProgress: lyricLineProgress ?? this.lyricLineProgress,
      lyricWordProgress: lyricWordProgress ?? this.lyricWordProgress,
      lyricLine: lyricLine ?? this.lyricLine,
      lyricNextLine: lyricNextLine ?? this.lyricNextLine,
      lyricTranslation: lyricTranslation ?? this.lyricTranslation,
    );
  }

  /// Resolves a feature path to a number for bindings and expressions.
  double valueAt(String path) {
    return switch (path) {
      'level.rms' => rms,
      'level.peak' => peak,
      'level.attack' => isBeat ? 1 : 0,
      'energy.short' => energyShort,
      'energy.long' => energyLong,
      'beat.isBeat' => isBeat ? 1 : 0,
      'beat.phase' => beatPhase,
      'beat.bpm' => bpm,
      'beat.index' => beatIndex.toDouble(),
      'time.now' => time,
      'time.progress' => progress,
      'lyric.lineProgress' => lyricLineProgress,
      'lyric.wordProgress' => lyricWordProgress,
      'lyric.lineIndex' => lyricLineIndex.toDouble(),
      'lyric.wordIndex' => lyricWordIndex.toDouble(),
      _ when path.startsWith('band.') => bands[path.substring(5)] ?? 0,
      _ => 0,
    };
  }
}
