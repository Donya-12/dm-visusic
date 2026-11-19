// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:visusic_audio/src/analysis.dart';

/// Decodes encoded audio bytes into a [PcmBuffer] at a fixed sample rate.
abstract interface class AudioDecoder {
  /// Decodes any supported audio file into mono/stereo 48 kHz PCM.
  Future<PcmBuffer> decode(Uint8List bytes);
}

/// Pure Dart PCM WAV decoder used for tests and `.wav` files without FFmpeg.
final class WavDecoder implements AudioDecoder {
  /// Creates a WAV decoder.
  const WavDecoder();

  @override
  Future<PcmBuffer> decode(Uint8List bytes) async => decodeWav(bytes);
}

/// Decodes a RIFF/WAVE file and resamples to 48 kHz mono.
PcmBuffer decodeWav(Uint8List bytes) {
  if (bytes.length < 44 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
    throw const FormatException('Not a supported WAV file.');
  }
  var offset = 12;
  int? dataOffset;
  int? dataLength;
  int channels = 1;
  int sampleRate = 48000;
  int bitsPerSample = 16;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = _uint32(bytes, offset + 4);
    final body = offset + 8;
    switch (id) {
      case 'fmt ':
        channels = _uint16(bytes, body + 2);
        sampleRate = _uint32(bytes, body + 4);
        bitsPerSample = _uint16(bytes, body + 14);
      case 'data':
        dataOffset = body;
        dataLength = size;
        offset = bytes.length;
        continue;
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  if (dataOffset == null || dataLength == null) {
    throw const FormatException('WAV data chunk is missing.');
  }
  final samples = dataLength ~/ (channels * bitsPerSample ~/ 8);
  final source = _samples(bytes, dataOffset, samples, channels, bitsPerSample);
  return _resample(source, sampleRate, channels);
}

Float32List _samples(
  Uint8List bytes,
  int offset,
  int samples,
  int channels,
  int bitsPerSample,
) {
  final result = Float32List(samples * channels);
  final bytesPerSample = bitsPerSample ~/ 8;
  for (var index = 0; index < samples * channels; index++) {
    final position = offset + index * bytesPerSample;
    if (bitsPerSample == 16) {
      result[index] = _int16(bytes, position) / 32768.0;
    } else if (bitsPerSample == 24) {
      final raw = _int24(bytes, position);
      result[index] = raw / 8388608.0;
    } else if (bitsPerSample == 32) {
      final data = ByteData.sublistView(bytes, position, position + 4);
      result[index] = data.getFloat32(0, Endian.little);
    } else {
      result[index] = (bytes[position] - 128) / 128.0;
    }
  }
  return result;
}

PcmBuffer _resample(Float32List source, int sampleRate, int channels) {
  const targetRate = 48000;
  final frameCount = source.length ~/ channels;
  final targetFrames = (frameCount * targetRate / sampleRate).ceil();
  final mono = Float32List(targetFrames);
  for (var frame = 0; frame < targetFrames; frame++) {
    final position = frame * sampleRate / targetRate;
    final leftIndex = position.floor();
    final rightIndex = (leftIndex + 1).clamp(0, frameCount - 1);
    final fraction = position - leftIndex;
    var sample = 0.0;
    for (var channel = 0; channel < channels; channel++) {
      final a = source[leftIndex * channels + channel];
      final b = source[rightIndex * channels + channel];
      sample += a + (b - a) * fraction;
    }
    mono[frame] = sample / channels;
  }
  return PcmBuffer(sampleRate: targetRate, mono: mono);
}

int _uint16(Uint8List bytes, int offset) {
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 2,
  ).getUint16(0, Endian.little);
}

int _uint32(Uint8List bytes, int offset) {
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 4,
  ).getUint32(0, Endian.little);
}

int _int16(Uint8List bytes, int offset) {
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 2,
  ).getInt16(0, Endian.little);
}

int _int24(Uint8List bytes, int offset) {
  final value =
      (bytes[offset] & 0xff) |
      ((bytes[offset + 1] & 0xff) << 8) |
      ((bytes[offset + 2] & 0xff) << 16);
  return value >= 0x800000 ? value - 0x1000000 : value;
}
