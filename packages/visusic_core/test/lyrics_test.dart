// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('parses plain LRC lines with multiple timestamps', () {
    final track = LrcParser.parse('''
[ti:Test]
[ar:Artist]
[00:01.00]First line
[00:03.50][00:10.00]Repeated line
''');
    expect(track.title, 'Test');
    expect(track.artist, 'Artist');
    expect(track.lines, hasLength(3));
    expect(track.lines.first.timeMs, 1000);
    expect(track.lines.last.text, 'Repeated line');
  });

  test('treats LRC fractions as centiseconds', () {
    final track = LrcParser.parse('[00:01.50]One and a half seconds');
    expect(track.lines.single.timeMs, 1500);
  });

  test('parses enhanced-LRC word timing tags', () {
    final track = LrcParser.parse(
      '[00:00.00]<00:00.00>Hello <00:00.50>world <00:01.00>again',
    );
    final line = track.lines.single;
    expect(line.words, isNotEmpty);
    expect(line.text, 'Hello world again');
    expect(track.hasWordTiming, isTrue);
  });

  test('applies offset metadata and rejects empty input', () {
    final track = LrcParser.parse('[offset:500]\n[00:02.00]Shifted');
    expect(track.lines.single.timeMs, 2500);
    expect(
      () => LrcParser.parse('no timestamps here'),
      throwsA(isA<LyricsParseException>()),
    );
  });

  test('resolves line and word progress', () {
    final track = LrcParser.parse(
      '[00:00.00]<00:00.00>One <00:01.00>two\n[00:03.00]Second',
    );
    expect(track.lineIndexAt(1500), 0);
    expect(track.lineIndexAt(3500), 1);
    expect(track.wordIndexAt(1100), 1);
    expect(track.lineProgressAt(1500), closeTo(0.5, 0.001));
    expect(track.wordProgressAt(1200), closeTo(0.1, 0.001));
  });
}
