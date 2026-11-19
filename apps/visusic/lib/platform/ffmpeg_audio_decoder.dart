// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:io';
import 'dart:typed_data';

import 'package:visusic_audio/visusic_audio.dart';

/// FFmpeg-backed decoder producing 48 kHz float PCM for the analyzer.
final class FfmpegAudioDecoder implements AudioDecoder {
  /// Creates a decoder using a bundled or PATH-resolved ffmpeg binary.
  const FfmpegAudioDecoder();

  @override
  Future<PcmBuffer> decode(Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp('visusic-decode-');
    final input = File('${directory.path}/input');
    await input.writeAsBytes(bytes, flush: true);
    try {
      final result = await Process.run(_ffmpegPath(), <String>[
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        input.path,
        '-f',
        'f32le',
        '-acodec',
        'pcm_f32le',
        '-ar',
        '48000',
        '-ac',
        '1',
        '-',
      ], stdoutEncoding: null);
      if (result.exitCode != 0) {
        throw FormatException(
          'FFmpeg could not decode the audio file: ${result.stderr}',
        );
      }
      final raw = result.stdout as List<int>;
      final data = Uint8List.fromList(raw);
      final bytesPerSample = 4;
      final samples = data.length ~/ bytesPerSample;
      final mono = Float32List(samples);
      final view = ByteData.sublistView(data);
      for (var index = 0; index < samples; index++) {
        mono[index] = view.getFloat32(index * 4, Endian.little);
      }
      return PcmBuffer(sampleRate: 48000, mono: mono);
    } finally {
      await directory.delete(recursive: true);
    }
  }

  String _ffmpegPath() {
    for (final relative in const <String>[
      'tool/ffmpeg/ffmpeg.exe',
      '../tool/ffmpeg/ffmpeg.exe',
      '../../tool/ffmpeg/ffmpeg.exe',
    ]) {
      final file = File(relative);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }
    return 'ffmpeg';
  }
}
