// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

/// One time-tagged word inside an enhanced-LRC line.
final class LyricWord {
  /// Creates a word.
  const LyricWord({required this.timeMs, required this.text});

  /// Start time in milliseconds.
  final double timeMs;

  /// Word text.
  final String text;

  /// Serializes this word.
  Map<String, Object?> toJson() => <String, Object?>{
    'timeMs': timeMs,
    'text': text,
  };

  /// Parses a word.
  factory LyricWord.fromJson(Map<String, Object?> json) => LyricWord(
    timeMs: (json['timeMs'] as num).toDouble(),
    text: json['text'] as String,
  );
}

/// One synchronized lyric line with optional word timing and translation.
final class LyricLine {
  /// Creates a lyric line.
  const LyricLine({
    required this.timeMs,
    required this.text,
    this.words = const <LyricWord>[],
    this.translation,
    this.speaker,
  });

  /// Start time in milliseconds.
  final double timeMs;

  /// Visible line text without word timing markers.
  final String text;

  /// Per-word timings from enhanced-LRC tags, when present.
  final List<LyricWord> words;

  /// Optional second-language line.
  final String? translation;

  /// Optional speaker label such as A or B.
  final String? speaker;

  /// Serializes this line.
  Map<String, Object?> toJson() => <String, Object?>{
    'timeMs': timeMs,
    'text': text,
    'words': words.map((word) => word.toJson()).toList(growable: false),
    'translation': translation,
    'speaker': speaker,
  };

  /// Parses a line.
  factory LyricLine.fromJson(Map<String, Object?> json) => LyricLine(
    timeMs: (json['timeMs'] as num).toDouble(),
    text: json['text'] as String,
    words: (json['words'] as List? ?? const <Object?>[])
        .map(
          (word) => LyricWord.fromJson((word as Map).cast<String, Object?>()),
        )
        .toList(growable: false),
    translation: json['translation'] as String?,
    speaker: json['speaker'] as String?,
  );
}

/// A parsed, sorted lyric track.
final class LyricsTrack {
  /// Creates a track.
  LyricsTrack({
    required List<LyricLine> lines,
    this.offsetMs = 0,
    this.title,
    this.artist,
  }) : lines = _sortedLines(lines);

  /// Ordered synchronized lines.
  final List<LyricLine> lines;

  /// Manual global offset applied to every timestamp.
  final double offsetMs;

  /// Track title metadata, if present.
  final String? title;

  /// Track artist metadata, if present.
  final String? artist;

  /// Whether any line carries per-word timing.
  bool get hasWordTiming => lines.any((line) => line.words.isNotEmpty);

  /// Serializes the complete track.
  Map<String, Object?> toJson() => <String, Object?>{
    'offsetMs': offsetMs,
    'title': title,
    'artist': artist,
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
  };

  /// Parses a complete track.
  factory LyricsTrack.fromJson(Map<String, Object?> json) => LyricsTrack(
    lines: (json['lines'] as List? ?? const <Object?>[])
        .map(
          (line) => LyricLine.fromJson((line as Map).cast<String, Object?>()),
        )
        .toList(growable: false),
    offsetMs: (json['offsetMs'] as num? ?? 0).toDouble(),
    title: json['title'] as String?,
    artist: json['artist'] as String?,
  );

  static List<LyricLine> _sortedLines(List<LyricLine> source) {
    final copy = <LyricLine>[...source];
    copy.sort(
      (LyricLine a, LyricLine b) => a.timeMs < b.timeMs
          ? -1
          : a.timeMs > b.timeMs
          ? 1
          : 0,
    );
    return List<LyricLine>.unmodifiable(copy);
  }

  /// Index of the active line at a timeline position.
  int lineIndexAt(double timeMs) {
    var index = 0;
    for (var candidate = 0; candidate < lines.length; candidate++) {
      if (lines[candidate].timeMs <= timeMs) {
        index = candidate;
      } else {
        break;
      }
    }
    return index;
  }

  /// The active line at a timeline position.
  LyricLine? lineAt(double timeMs) =>
      lines.isEmpty ? null : lines[lineIndexAt(timeMs)];

  /// Progress through the active line in 0..1.
  double lineProgressAt(double timeMs) {
    final index = lineIndexAt(timeMs);
    if (lines.isEmpty) {
      return 0;
    }
    final start = lines[index].timeMs;
    final end = index + 1 < lines.length
        ? lines[index + 1].timeMs
        : start + 4000;
    if (end <= start) {
      return 1;
    }
    return ((timeMs - start) / (end - start)).clamp(0, 1).toDouble();
  }

  /// Index of the active word within the active line.
  int wordIndexAt(double timeMs) {
    final line = lineAt(timeMs);
    if (line == null || line.words.isEmpty) {
      return 0;
    }
    var index = 0;
    for (var candidate = 0; candidate < line.words.length; candidate++) {
      if (line.words[candidate].timeMs <= timeMs) {
        index = candidate;
      } else {
        break;
      }
    }
    return index;
  }

  /// Progress through the active word in 0..1.
  double wordProgressAt(double timeMs) {
    final lineIndex = lineIndexAt(timeMs);
    if (lines.isEmpty) {
      return 0;
    }
    final line = lines[lineIndex];
    if (line.words.isEmpty) {
      return 0;
    }
    final index = wordIndexAt(timeMs);
    final start = line.words[index].timeMs;
    final end = index + 1 < line.words.length
        ? line.words[index + 1].timeMs
        : lineIndex + 1 < lines.length
        ? lines[lineIndex + 1].timeMs
        : start + 600;
    if (end <= start) {
      return 1;
    }
    return ((timeMs - start) / (end - start)).clamp(0, 1).toDouble();
  }
}

/// A readable lyric parsing error.
final class LyricsParseException implements Exception {
  /// Creates a parse error.
  const LyricsParseException(this.message);

  /// Human-readable problem description.
  final String message;

  @override
  String toString() => 'LyricsParseException: $message';
}

/// Parses plain and enhanced LRC lyric text without executing input.
abstract final class LrcParser {
  static final RegExp _timestamp = RegExp(
    r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]',
  );
  static final RegExp _wordTag = RegExp(
    r'<(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?>',
  );
  static final RegExp _metadata = RegExp(
    r'^\[(ar|ti|al|au|length|offset|by|re):(.*)\]$',
  );

  /// Parses LRC content into a sorted [LyricsTrack].
  static LyricsTrack parse(String content) {
    final lines = <LyricLine>[];
    var offsetMs = 0.0;
    String? title;
    String? artist;
    for (final raw in content.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      final metadata = _metadata.firstMatch(line);
      if (metadata != null) {
        final key = metadata.group(1)!;
        final value = metadata.group(2)!.trim();
        if (key == 'offset') {
          offsetMs = double.tryParse(value) ?? 0;
        } else if (key == 'ti') {
          title = value;
        } else if (key == 'ar') {
          artist = value;
        }
        continue;
      }
      final timestamps = _timestamp.allMatches(line).toList(growable: false);
      if (timestamps.isEmpty) {
        continue;
      }
      var body = line;
      for (final match in timestamps.reversed) {
        body = body.replaceRange(match.start, match.end, '');
      }
      body = body.trim();
      String? speaker;
      final speakerMatch = RegExp(r'^\[([AB]):\]\s*').firstMatch(body);
      if (speakerMatch != null) {
        speaker = speakerMatch.group(1);
        body = body.substring(speakerMatch.end).trim();
      }
      final words = <LyricWord>[];
      if (body.contains('<')) {
        final matches = _wordTag.allMatches(body).toList(growable: false);
        for (var index = 0; index < matches.length; index++) {
          final tag = matches[index];
          final minutes = int.parse(tag.group(1)!);
          final seconds = int.parse(tag.group(2)!);
          final fraction = _fractionMs(tag.group(3));
          final wordTime = minutes * 60000 + seconds * 1000 + fraction;
          final start = tag.end;
          final end = index + 1 < matches.length
              ? matches[index + 1].start
              : body.length;
          final wordText = body.substring(start, end).trim();
          if (wordText.isNotEmpty) {
            words.add(LyricWord(timeMs: wordTime.toDouble(), text: wordText));
          }
        }
      }
      final plainText = body.replaceAll(_wordTag, '').trim();
      for (final match in timestamps) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fraction = _fractionMs(match.group(3));
        final timeMs = minutes * 60000 + seconds * 1000 + fraction + offsetMs;
        lines.add(
          LyricLine(
            timeMs: timeMs.toDouble(),
            text: plainText,
            words: words.isEmpty
                ? const <LyricWord>[]
                : List.unmodifiable(words),
            speaker: speaker,
          ),
        );
      }
    }
    if (lines.isEmpty) {
      throw const LyricsParseException('No synchronized lyric lines found.');
    }
    return LyricsTrack(
      lines: lines,
      offsetMs: offsetMs,
      title: title,
      artist: artist,
    );
  }

  /// Converts an LRC fraction (centiseconds) to milliseconds.
  static int _fractionMs(String? fraction) {
    if (fraction == null || fraction.isEmpty) {
      return 0;
    }
    final value = int.parse(fraction);
    return switch (fraction.length) {
      1 => value * 100,
      2 => value * 10,
      _ => value,
    };
  }
}
