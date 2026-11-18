// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_audio/visusic_audio.dart';

void main() {
  test('analysis defaults match the audio contract', () {
    expect(AudioAnalysisDefaults.sampleRate, 48000);
    expect(AudioAnalysisDefaults.fftSize, 2048);
    expect(AudioAnalysisDefaults.hopSize, 512);
  });
}
