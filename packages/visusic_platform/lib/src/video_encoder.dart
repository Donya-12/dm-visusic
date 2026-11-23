// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

/// One raw RGBA frame ready for the encoder.
final class VideoFrame {
  /// Creates a frame.
  const VideoFrame({
    required this.width,
    required this.height,
    required this.rgba,
  });

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// RGBA8 pixel data, exactly width * height * 4 bytes.
  final Uint8List rgba;
}

/// Export container and codec choices.
final class ExportSettings {
  /// Creates export settings.
  const ExportSettings({
    required this.width,
    required this.height,
    required this.fps,
    required this.container,
    this.quality = 'fast',
  });

  /// Output width in pixels.
  final int width;

  /// Output height in pixels.
  final int height;

  /// Frames per second.
  final int fps;

  /// mp4 or webm.
  final String container;

  /// Encoder preset.
  final String quality;
}

/// Encodes a deterministic frame stream into a video file.
abstract interface class VideoEncoder {
  /// Writes frames to a video file, optionally muxing a source audio track.
  ///
  /// [onProgress] receives values in 0..1. When [isCancelled] returns true the
  /// encoder must stop and delete the partial output as soon as possible.
  Future<void> encode({
    required ExportSettings settings,
    required Stream<VideoFrame> frames,
    required String outputPath,
    String? audioPath,
    double? durationSeconds,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  });
}
