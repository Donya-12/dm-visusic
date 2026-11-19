// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

/// Decoded linear PCM in mono and optional stereo at one sample rate.
final class PcmBuffer {
  /// Creates a PCM buffer.
  const PcmBuffer({required this.sampleRate, required this.mono, this.stereo});

  /// Sample rate in hertz.
  final int sampleRate;

  /// Downmixed or native mono samples.
  final Float32List mono;

  /// Optional interleaved stereo samples (L, R, L, R).
  final Float32List? stereo;

  /// Number of mono frames.
  int get frames => mono.length;

  /// Duration in seconds.
  double get duration => frames / sampleRate;
}

/// One compact feature frame on the analysis timeline.
final class AnalysisFrame {
  /// Creates a feature frame.
  AnalysisFrame({
    required this.rms,
    required this.peak,
    required this.energyShort,
    required this.energyLong,
    required this.beatPhase,
    required this.isBeat,
    required this.beatIndex,
    required this.spectrum,
    required this.bands,
  });

  /// Root-mean-square level.
  final double rms;

  /// Peak level.
  final double peak;

  /// Short-term smoothed energy.
  final double energyShort;

  /// Long-term smoothed energy.
  final double energyLong;

  /// Phase inside the current beat in 0..1.
  final double beatPhase;

  /// Whether this frame contains a beat attack.
  final bool isBeat;

  /// Beat number since the timeline start.
  final int beatIndex;

  /// Sixty-four logarithmically grouped spectrum values in 0..1.
  final Float32List spectrum;

  /// Seven normalized band energies in the fixed band order.
  final Float32List bands;
}

/// Result of offline audio analysis.
final class AnalysisResult {
  /// Creates an analysis result.
  AnalysisResult({
    required this.sampleRate,
    required this.hopSize,
    required this.frames,
    required this.waveformPeaks,
    required this.bpm,
    required this.key,
    required this.duration,
    required this.bandNames,
  });

  /// Original sample rate.
  final int sampleRate;

  /// STFT hop size in samples.
  final int hopSize;

  /// Feature frames at hop resolution.
  final List<AnalysisFrame> frames;

  /// Interleaved min/max waveform peaks (256 pairs).
  final Float32List waveformPeaks;

  /// Estimated tempo.
  final double bpm;

  /// Estimated key, or unknown.
  final String key;

  /// Audio duration in seconds.
  final double duration;

  /// Ordered band names matching [AnalysisFrame.bands].
  final List<String> bandNames;
}

/// Deterministic offline analysis pipeline for PCM audio.
abstract final class AudioAnalyzer {
  /// STFT window length in samples.
  static const int fftSize = 2048;

  /// STFT hop length in samples.
  static const int hopSize = 512;

  /// Ordered frequency band names from low to high.
  static const List<String> bandNames = <String>[
    'sub',
    'bass',
    'lowMid',
    'mid',
    'highMid',
    'high',
    'air',
  ];

  /// Lower and upper frequency edges for each band in hertz.
  static const List<(double, double)> bandEdges = <(double, double)>[
    (20, 60),
    (60, 250),
    (250, 800),
    (800, 2500),
    (2500, 6000),
    (6000, 12000),
    (12000, 20000),
  ];

  /// Runs the complete pipeline and returns time-aligned features.
  static AnalysisResult analyze(PcmBuffer buffer) {
    if (buffer.frames < fftSize) {
      throw ArgumentError('Audio is too short to analyze.');
    }
    final magnitudes = _stft(buffer.mono, buffer.sampleRate);
    final flux = _spectralFlux(magnitudes);
    final bpm = _estimateBpm(flux, buffer.sampleRate);
    final beatPeriod = 60.0 / bpm;
    final beatPhase0 = _onsetPhase(flux, buffer.sampleRate, beatPeriod);
    final bands = _bandEnergies(magnitudes, buffer.sampleRate);
    final normalized = _normalizeBands(bands);
    final spectrum = _logSpectrum(magnitudes, buffer.sampleRate);
    final envelope = _envelope(buffer.mono, buffer.sampleRate);
    final frames = <AnalysisFrame>[];
    final beatIndexes = <int>[];
    for (var index = 0; index < magnitudes.length; index++) {
      final time = index * hopSize / buffer.sampleRate;
      final position = (time - beatPhase0) / beatPeriod;
      final beatIndex = position < 0 ? 0 : position.floor() + 1;
      final beatPhase = ((time - beatPhase0) / beatPeriod) % 1;
      final isBeat =
          beatPhase >= 0 && beatPhase < 0.08 && _isOnset(flux, index);
      frames.add(
        AnalysisFrame(
          rms: envelope.rms[index],
          peak: envelope.peak[index],
          energyShort: envelope.energyShort[index],
          energyLong: envelope.energyLong[index],
          beatPhase: beatPhase < 0 ? beatPhase + 1 : beatPhase,
          isBeat: isBeat,
          beatIndex: beatIndex,
          spectrum: spectrum[index],
          bands: normalized[index],
        ),
      );
      beatIndexes.add(beatIndex);
    }
    return AnalysisResult(
      sampleRate: buffer.sampleRate,
      hopSize: hopSize,
      frames: frames,
      waveformPeaks: _waveformPeaks(buffer.mono),
      bpm: bpm,
      key: _estimateKey(magnitudes, buffer.sampleRate),
      duration: buffer.duration,
      bandNames: bandNames,
    );
  }

  static List<Float32List> _stft(Float32List mono, int sampleRate) {
    final frames = <Float32List>[];
    final window = Float32List(fftSize);
    for (var index = 0; index < fftSize; index++) {
      window[index] = 0.5 - 0.5 * math.cos(2 * math.pi * index / (fftSize - 1));
    }
    final real = Float32List(fftSize);
    final imag = Float32List(fftSize);
    for (var start = 0; start + fftSize <= mono.length; start += hopSize) {
      for (var index = 0; index < fftSize; index++) {
        real[index] = mono[start + index] * window[index];
        imag[index] = 0;
      }
      _fft(real, imag);
      final half = fftSize ~/ 2 + 1;
      final magnitude = Float32List(half);
      for (var index = 0; index < half; index++) {
        magnitude[index] = math.sqrt(
          real[index] * real[index] + imag[index] * imag[index],
        );
      }
      frames.add(magnitude);
    }
    return frames;
  }

  static void _fft(Float32List real, Float32List imag) {
    final n = real.length;
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      while ((j & bit) != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;
        final ti = imag[i];
        imag[i] = imag[j];
        imag[j] = ti;
      }
    }
    for (var length = 2; length <= n; length <<= 1) {
      final angle = -2 * math.pi / length;
      final wr = math.cos(angle);
      final wi = math.sin(angle);
      for (var i = 0; i < n; i += length) {
        var cr = 1.0;
        var ci = 0.0;
        for (var k = 0; k < length ~/ 2; k++) {
          final evenR = real[i + k];
          final evenI = imag[i + k];
          final oddR = real[i + k + length ~/ 2];
          final oddI = imag[i + k + length ~/ 2];
          final tr = oddR * cr - oddI * ci;
          final ti = oddR * ci + oddI * cr;
          real[i + k] = evenR + tr;
          imag[i + k] = evenI + ti;
          real[i + k + length ~/ 2] = evenR - tr;
          imag[i + k + length ~/ 2] = evenI - ti;
          final ncr = cr * wr - ci * wi;
          ci = cr * wi + ci * wr;
          cr = ncr;
        }
      }
    }
  }

  static List<double> _spectralFlux(List<Float32List> magnitudes) {
    final flux = List<double>.filled(magnitudes.length, 0);
    for (var index = 1; index < magnitudes.length; index++) {
      final previous = magnitudes[index - 1];
      final current = magnitudes[index];
      var sum = 0.0;
      for (var bin = 0; bin < current.length; bin++) {
        final delta = math.log(current[bin] + 1) - math.log(previous[bin] + 1);
        if (delta > 0) {
          sum += delta;
        }
      }
      flux[index] = sum;
    }
    return flux;
  }

  static double _estimateBpm(List<double> flux, int sampleRate) {
    var bestBpm = 120.0;
    var bestScore = -1.0;
    final minLag = (60 / 200 * sampleRate / hopSize).round();
    final maxLag = (60 / 60 * sampleRate / hopSize).round();
    for (var lag = minLag; lag <= maxLag; lag++) {
      var correlation = 0.0;
      var normalization = 0.0;
      for (var index = 0; index + lag < flux.length; index++) {
        correlation += flux[index] * flux[index + lag];
        normalization += flux[index] * flux[index];
      }
      if (normalization <= 0) {
        continue;
      }
      final score = correlation / normalization;
      if (score > bestScore) {
        bestScore = score;
        bestBpm = 60 * sampleRate / (lag * hopSize);
      }
    }
    return bestBpm;
  }

  static double _onsetPhase(
    List<double> flux,
    int sampleRate,
    double beatPeriod,
  ) {
    final periodFrames = (beatPeriod * sampleRate / hopSize).round();
    assert(periodFrames > 0);
    var strongest = 0.0;
    var strongestIndex = 0;
    for (var index = 1; index < flux.length - 1; index++) {
      if (flux[index] > flux[index - 1] &&
          flux[index] >= flux[index + 1] &&
          flux[index] > strongest) {
        strongest = flux[index];
        strongestIndex = index;
      }
    }
    return strongestIndex * hopSize / sampleRate % beatPeriod;
  }

  static bool _isOnset(List<double> flux, int index) {
    if (index <= 1 || index >= flux.length - 1) {
      return false;
    }
    final threshold = _percentile(flux, 0.7) * 1.4 + 0.02;
    return flux[index] > threshold &&
        flux[index] >= flux[index - 1] &&
        flux[index] >= flux[index + 1];
  }

  static List<Float32List> _bandEnergies(
    List<Float32List> magnitudes,
    int sampleRate,
  ) {
    final nyquist = sampleRate / 2;
    final edges = bandEdges
        .map(
          (band) => (
            _binFor(band.$1, sampleRate),
            _binFor(math.min(band.$2, nyquist), sampleRate),
          ),
        )
        .toList(growable: false);
    return magnitudes
        .map((magnitude) {
          final energies = Float32List(bandNames.length);
          for (var band = 0; band < edges.length; band++) {
            var sum = 0.0;
            for (var bin = edges[band].$1; bin < edges[band].$2; bin++) {
              if (bin < magnitude.length) {
                final value = magnitude[bin];
                sum += value * value;
              }
            }
            energies[band] = sum;
          }
          return energies;
        })
        .toList(growable: false);
  }

  static List<Float32List> _normalizeBands(List<Float32List> energies) {
    final result = List<Float32List>.filled(
      energies.length,
      Float32List(bandNames.length),
    );
    for (var band = 0; band < bandNames.length; band++) {
      final values =
          energies
              .map((frame) => frame[band].toDouble())
              .toList(growable: false)
            ..sort();
      final low = _percentile(values, 0.05);
      final high = _percentile(values, 0.95);
      final range = (high - low).abs() < 1e-9 ? 1.0 : high - low;
      for (var frame = 0; frame < energies.length; frame++) {
        final value = ((energies[frame][band] - low) / range).clamp(0, 1);
        result[frame][band] = value.toDouble();
      }
    }
    return result;
  }

  static List<Float32List> _logSpectrum(
    List<Float32List> magnitudes,
    int sampleRate,
  ) {
    const groups = 64;
    final edges = List<double>.generate(groups + 1, (index) {
      return 20 *
          math
              .pow((math.min(sampleRate / 2, 20000)) / 20, index / groups)
              .toDouble();
    });
    return magnitudes
        .map((magnitude) {
          final result = Float32List(groups);
          var maxValue = 1e-9;
          for (var group = 0; group < groups; group++) {
            final start = _binFor(edges[group], sampleRate);
            final end = _binFor(edges[group + 1], sampleRate);
            var sum = 0.0;
            var count = 0;
            for (var bin = start; bin <= end && bin < magnitude.length; bin++) {
              sum += magnitude[bin];
              count++;
            }
            final value = count == 0 ? 0.0 : sum / count;
            result[group] = value;
            if (value > maxValue) {
              maxValue = value;
            }
          }
          for (var group = 0; group < groups; group++) {
            result[group] = result[group] / maxValue;
          }
          return result;
        })
        .toList(growable: false);
  }

  static _Envelope _envelope(Float32List mono, int sampleRate) {
    final count = ((mono.length - fftSize) / hopSize).floor() + 1;
    final rms = Float32List(count);
    final peak = Float32List(count);
    final short = Float32List(count);
    final long = Float32List(count);
    var shortLevel = 0.0;
    var longLevel = 0.0;
    const shortAttack = 0.08;
    const shortRelease = 0.2;
    const longAttack = 0.5;
    const longRelease = 0.9;
    for (var frame = 0; frame < count; frame++) {
      final start = frame * hopSize;
      var sumSquares = 0.0;
      var max = 0.0;
      for (var index = 0; index < fftSize; index++) {
        final value = mono[start + index];
        sumSquares += value * value;
        final absolute = value.abs();
        if (absolute > max) {
          max = absolute;
        }
      }
      rms[frame] = math.sqrt(sumSquares / fftSize);
      peak[frame] = max;
      shortLevel = _smooth(shortLevel, rms[frame], shortAttack, shortRelease);
      longLevel = _smooth(longLevel, rms[frame], longAttack, longRelease);
      short[frame] = shortLevel;
      long[frame] = longLevel;
    }
    return _Envelope(rms, peak, short, long);
  }

  static double _smooth(
    double previous,
    double target,
    double attack,
    double release,
  ) {
    final coefficient = target > previous
        ? 1 - math.exp(-1 / attack)
        : 1 - math.exp(-1 / release);
    return previous + (target - previous) * coefficient;
  }

  static Float32List _waveformPeaks(Float32List mono) {
    const buckets = 256;
    final result = Float32List(buckets * 2);
    final bucketSize = math.max(1, (mono.length / buckets).floor());
    for (var bucket = 0; bucket < buckets; bucket++) {
      var min = 0.0;
      var max = 0.0;
      final start = bucket * bucketSize;
      final end = math.min(mono.length, start + bucketSize);
      for (var index = start; index < end; index++) {
        final value = mono[index];
        if (value < min) min = value;
        if (value > max) max = value;
      }
      result[bucket * 2] = min;
      result[bucket * 2 + 1] = max;
    }
    return result;
  }

  static String _estimateKey(List<Float32List> magnitudes, int sampleRate) {
    final chroma = Float32List(12);
    for (final magnitude in magnitudes) {
      for (var bin = 0; bin < magnitude.length; bin++) {
        final frequency = bin * sampleRate / fftSize;
        if (frequency < 20 || frequency > 5000) {
          continue;
        }
        final midi = 69 + 12 * math.log(frequency / 440) / math.log(2);
        final pitch = midi.round() % 12;
        chroma[pitch] += magnitude[bin];
      }
    }
    const major = <double>[
      6.35,
      2.23,
      3.48,
      2.33,
      4.38,
      4.09,
      2.52,
      5.19,
      2.39,
      3.66,
      2.29,
      2.88,
    ];
    const minor = <double>[
      6.33,
      2.68,
      3.52,
      5.38,
      2.60,
      3.53,
      2.54,
      4.75,
      3.98,
      2.69,
      3.34,
      3.17,
    ];
    const names = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    var best = 'unknown';
    var bestScore = -double.infinity;
    for (var tonic = 0; tonic < 12; tonic++) {
      for (final profile in <(List<double>, String)>[
        (major, 'major'),
        (minor, 'minor'),
      ]) {
        var score = 0.0;
        for (var pitch = 0; pitch < 12; pitch++) {
          score += chroma[pitch] * profile.$1[(pitch - tonic + 12) % 12];
        }
        if (score > bestScore) {
          bestScore = score;
          best = '${names[tonic]} ${profile.$2}';
        }
      }
    }
    return best;
  }

  static int _binFor(double frequency, int sampleRate) {
    return (frequency * fftSize / sampleRate)
        .round()
        .clamp(0, fftSize ~/ 2)
        .toInt();
  }

  static double _percentile(List<double> values, double fraction) {
    if (values.isEmpty) {
      return 0;
    }
    final index = ((values.length - 1) * fraction)
        .round()
        .clamp(0, values.length - 1)
        .toInt();
    return values[index];
  }
}

final class _Envelope {
  const _Envelope(this.rms, this.peak, this.energyShort, this.energyLong);
  final Float32List rms;
  final Float32List peak;
  final Float32List energyShort;
  final Float32List energyLong;
}
