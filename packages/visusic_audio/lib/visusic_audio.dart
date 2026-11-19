// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

export 'src/analysis.dart';
export 'src/analysis_cache.dart';
export 'src/msgpack.dart';

/// Shared defaults for deterministic offline audio analysis.
abstract final class AudioAnalysisDefaults {
  /// PCM sample rate used by the analysis pipeline.
  static const int sampleRate = 48000;

  /// Number of samples in one STFT window.
  static const int fftSize = 2048;

  /// Number of samples between adjacent STFT windows.
  static const int hopSize = 512;
}
