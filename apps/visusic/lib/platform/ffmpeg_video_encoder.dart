// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:async';
import 'dart:io';

import 'package:visusic_platform/visusic_platform.dart';

/// FFmpeg-backed deterministic video encoder.
final class FfmpegVideoEncoder implements VideoEncoder {
  /// Creates an encoder using a bundled or PATH-resolved ffmpeg binary.
  const FfmpegVideoEncoder();

  @override
  Future<void> encode({
    required ExportSettings settings,
    required Stream<VideoFrame> frames,
    required String outputPath,
    String? audioPath,
    double? durationSeconds,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final isMp4 = settings.container == 'mp4';
    final args = <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-f',
      'rawvideo',
      '-pix_fmt',
      'rgba',
      '-s',
      '${settings.width}x${settings.height}',
      '-r',
      '${settings.fps}',
      '-i',
      '-',
      if (audioPath != null) ...<String>['-i', audioPath],
      '-c:v',
      isMp4 ? 'libx264' : 'libvpx-vp9',
      '-preset',
      settings.quality,
      '-pix_fmt',
      'yuv420p',
      if (isMp4) ...<String>['-movflags', '+faststart'],
      if (audioPath != null)
        ...<String>[
          '-c:a',
          isMp4 ? 'aac' : 'libopus',
          '-b:a',
          '320k',
          '-shortest',
        ],
      outputPath,
    ];
    final process = await Process.start(_ffmpegPath(), args);
    final totalFrames = durationSeconds == null
        ? null
        : (durationSeconds * settings.fps).ceil();
    var frameIndex = 0;
    try {
      await for (final frame in frames) {
        if (isCancelled?.call() ?? false) {
          process.kill();
          break;
        }
        process.stdin.add(frame.rgba);
        frameIndex++;
        final progress = totalFrames == null
            ? null
            : (frameIndex / totalFrames).clamp(0, 1);
        if (progress != null) {
          onProgress?.call(progress.toDouble());
        }
      }
      await process.stdin.close();
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final stderr = await process.stderr
            .transform(const SystemEncoding().decoder)
            .join();
        throw FormatException('FFmpeg export failed: $stderr');
      }
    } finally {
      if ((isCancelled?.call() ?? false) && File(outputPath).existsSync()) {
        await File(outputPath).delete();
      }
    }
  }

  String _ffmpegPath() {
    final candidates = <String>[
      File('${File(Platform.resolvedExecutable).parent.path}/ffmpeg.exe').path,
      'tool/ffmpeg/ffmpeg.exe',
      '../tool/ffmpeg/ffmpeg.exe',
      '../../tool/ffmpeg/ffmpeg.exe',
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return File(candidate).absolute.path;
      }
    }
    return 'ffmpeg';
  }
}
