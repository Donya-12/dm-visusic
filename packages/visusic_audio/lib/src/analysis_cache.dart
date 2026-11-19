// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:visusic_audio/src/analysis.dart';
import 'package:visusic_audio/src/msgpack.dart';
import 'package:visusic_core/visusic_core.dart';

/// A readable error while loading or validating an analysis cache.
final class AnalysisCacheException implements Exception {
  /// Creates a cache error.
  const AnalysisCacheException(this.message);

  /// Human-readable problem description.
  final String message;

  @override
  String toString() => 'AnalysisCacheException: $message';
}

/// Versioned `.vsan` cache storing precomputed features for fast reads.
final class AnalysisCache {
  /// Creates an analysis cache from analyzer output.
  AnalysisCache({
    required this.sampleRate,
    required this.hopSize,
    required this.bpm,
    required this.key,
    required this.duration,
    required this.bandNames,
    required this.frames,
    required this.waveformPeaks,
  });

  /// Original sample rate.
  final int sampleRate;

  /// STFT hop size in samples.
  final int hopSize;

  /// Estimated tempo.
  final double bpm;

  /// Estimated key.
  final String key;

  /// Audio duration in seconds.
  final double duration;

  /// Ordered band names.
  final List<String> bandNames;

  /// Feature frames at hop resolution.
  final List<AnalysisFrame> frames;

  /// Interleaved min/max waveform peaks.
  final Float32List waveformPeaks;

  /// Frames per second.
  double get frameRate => sampleRate / hopSize;

  /// Encodes the cache to versioned MessagePack bytes.
  Uint8List encode() {
    final frameCount = frames.length;
    final rms = Float32List(frameCount);
    final peak = Float32List(frameCount);
    final energyShort = Float32List(frameCount);
    final energyLong = Float32List(frameCount);
    final beatPhase = Float32List(frameCount);
    final isBeat = Uint8List(frameCount);
    final beatIndex = Int32List(frameCount);
    final spectrum = Float32List(frameCount * 64);
    final bands = Float32List(frameCount * bandNames.length);
    for (var index = 0; index < frameCount; index++) {
      final frame = frames[index];
      rms[index] = frame.rms;
      peak[index] = frame.peak;
      energyShort[index] = frame.energyShort;
      energyLong[index] = frame.energyLong;
      beatPhase[index] = frame.beatPhase;
      isBeat[index] = frame.isBeat ? 1 : 0;
      beatIndex[index] = frame.beatIndex;
      spectrum.setRange(index * 64, (index + 1) * 64, frame.spectrum);
      bands.setRange(
        index * bandNames.length,
        (index + 1) * bandNames.length,
        frame.bands,
      );
    }
    return MsgPackEncoder.encode(<String, Object?>{
      'schemaVersion': 1,
      'sampleRate': sampleRate,
      'hopSize': hopSize,
      'bpm': bpm,
      'key': key,
      'duration': duration,
      'bandNames': bandNames,
      'frameCount': frameCount,
      'rms': _bytes(rms),
      'peak': _bytes(peak),
      'energyShort': _bytes(energyShort),
      'energyLong': _bytes(energyLong),
      'beatPhase': _bytes(beatPhase),
      'isBeat': isBeat,
      'beatIndex': _bytes(beatIndex),
      'spectrum': _bytes(spectrum),
      'bands': _bytes(bands),
      'waveformPeaks': _bytes(waveformPeaks),
    });
  }

  /// Decodes and validates a versioned cache.
  factory AnalysisCache.decode(Uint8List bytes) {
    try {
      final decoded = MsgPackDecoder.decode(bytes);
      if (decoded is! Map) {
        throw const AnalysisCacheException('Cache root is not a map.');
      }
      if (decoded['schemaVersion'] != 1) {
        throw AnalysisCacheException(
          'Unsupported cache schema ${decoded['schemaVersion']}.',
        );
      }
      final bandNames = _stringList(decoded['bandNames']);
      final frameCount = _int(decoded['frameCount']);
      final rms = _floatList(decoded['rms'], frameCount);
      final peak = _floatList(decoded['peak'], frameCount);
      final energyShort = _floatList(decoded['energyShort'], frameCount);
      final energyLong = _floatList(decoded['energyLong'], frameCount);
      final beatPhase = _floatList(decoded['beatPhase'], frameCount);
      final isBeat = _uint8List(decoded['isBeat'], frameCount);
      final beatIndex = _int32List(decoded['beatIndex'], frameCount);
      final spectrum = _floatList(decoded['spectrum'], frameCount * 64);
      final bands = _floatList(decoded['bands'], frameCount * bandNames.length);
      final waveformPeaks = _floatList(decoded['waveformPeaks'], 512);
      final frames = <AnalysisFrame>[];
      for (var index = 0; index < frameCount; index++) {
        frames.add(
          AnalysisFrame(
            rms: rms[index],
            peak: peak[index],
            energyShort: energyShort[index],
            energyLong: energyLong[index],
            beatPhase: beatPhase[index],
            isBeat: isBeat[index] != 0,
            beatIndex: beatIndex[index],
            spectrum: Float32List.sublistView(
              spectrum,
              index * 64,
              (index + 1) * 64,
            ),
            bands: Float32List.sublistView(
              bands,
              index * bandNames.length,
              (index + 1) * bandNames.length,
            ),
          ),
        );
      }
      return AnalysisCache(
        sampleRate: _int(decoded['sampleRate']),
        hopSize: _int(decoded['hopSize']),
        bpm: _double(decoded['bpm']),
        key: decoded['key'] as String? ?? 'unknown',
        duration: _double(decoded['duration']),
        bandNames: bandNames,
        frames: frames,
        waveformPeaks: waveformPeaks,
      );
    } on AnalysisCacheException {
      rethrow;
    } on Object catch (error) {
      throw AnalysisCacheException('Cannot read analysis cache: $error');
    }
  }

  /// Builds a [FeatureSnapshot] at a timeline position.
  FeatureSnapshot frameAt(double seconds) {
    if (frames.isEmpty) {
      return FeatureSnapshot.silent(duration);
    }
    final position = (seconds * frameRate).clamp(0, frames.length - 1);
    final index = position.floor();
    final nextIndex = math.min(index + 1, frames.length - 1);
    final fraction = position - index;
    final frame = frames[index];
    final next = frames[nextIndex];
    final spectrum = Float64List(64);
    for (var bin = 0; bin < 64; bin++) {
      spectrum[bin] =
          frame.spectrum[bin] +
          (next.spectrum[bin] - frame.spectrum[bin]) * fraction;
    }
    final waveform = Float64List(128);
    for (var bucket = 0; bucket < 128; bucket++) {
      final peaksIndex = (bucket * 2).clamp(0, waveformPeaks.length - 2);
      waveform[bucket] = math
          .max(
            waveformPeaks[peaksIndex].abs(),
            waveformPeaks[peaksIndex + 1].abs(),
          )
          .toDouble();
    }
    final bandValues = <String, double>{};
    for (var band = 0; band < bandNames.length; band++) {
      bandValues[bandNames[band]] =
          frame.bands[band] + (next.bands[band] - frame.bands[band]) * fraction;
    }
    return FeatureSnapshot(
      time: seconds,
      duration: duration,
      rms: frame.rms + (next.rms - frame.rms) * fraction,
      peak: frame.peak + (next.peak - frame.peak) * fraction,
      energyShort: frame.energyShort,
      energyLong: frame.energyLong,
      bpm: bpm,
      beatPhase: frame.beatPhase,
      beatIndex: frame.beatIndex,
      spectrum: spectrum,
      waveform: waveform,
      bands: bandValues,
    );
  }

  static Uint8List _bytes(TypedData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      throw const AnalysisCacheException('bandNames must be a list.');
    }
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static int _int(Object? value) {
    if (value is! int) {
      throw const AnalysisCacheException('Expected an integer.');
    }
    return value;
  }

  static double _double(Object? value) {
    if (value is! num) {
      throw const AnalysisCacheException('Expected a number.');
    }
    return value.toDouble();
  }

  static Float32List _floatList(Object? value, int length) {
    if (value is! Uint8List || value.length != length * 4) {
      throw const AnalysisCacheException('Float array length mismatch.');
    }
    final view = ByteData.sublistView(value);
    final result = Float32List(length);
    for (var index = 0; index < length; index++) {
      result[index] = view.getFloat32(index * 4, Endian.little);
    }
    return result;
  }

  static Uint8List _uint8List(Object? value, int length) {
    if (value is! Uint8List || value.length != length) {
      throw const AnalysisCacheException('Byte array length mismatch.');
    }
    return value;
  }

  static Int32List _int32List(Object? value, int length) {
    if (value is! Uint8List || value.length != length * 4) {
      throw const AnalysisCacheException('Integer array length mismatch.');
    }
    final view = ByteData.sublistView(value);
    final result = Int32List(length);
    for (var index = 0; index < length; index++) {
      result[index] = view.getInt32(index * 4, Endian.little);
    }
    return result;
  }
}
