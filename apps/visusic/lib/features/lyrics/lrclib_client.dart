// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:convert';

import 'package:http/http.dart' as http;

/// One LRCLIB search result.
final class LrclibResult {
  /// Creates a result.
  const LrclibResult({
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.syncedLyrics,
    this.plainLyrics,
  });

  /// Track title.
  final String title;

  /// Artist name.
  final String artist;

  /// Album name.
  final String? album;

  /// Track duration in seconds.
  final double? duration;

  /// Synchronized LRC text.
  final String? syncedLyrics;

  /// Plain text lyrics.
  final String? plainLyrics;

  /// Parses one JSON entry.
  factory LrclibResult.fromJson(Map<String, Object?> json) => LrclibResult(
    title: (json['trackName'] as String?) ?? '',
    artist: (json['artistName'] as String?) ?? '',
    album: json['albumName'] as String?,
    duration: (json['duration'] as num?)?.toDouble(),
    syncedLyrics: json['syncedLyrics'] as String?,
    plainLyrics: json['plainLyrics'] as String?,
  );
}

/// Minimal LRCLIB API client without a key or authentication.
final class LrclibClient {
  /// Creates a client.
  LrclibClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _base = 'https://lrclib.net/api';

  final http.Client _client;

  /// Searches for synchronized lyrics.
  Future<List<LrclibResult>> search(String trackName, String artistName) async {
    final uri = Uri.parse('$_base/search').replace(
      queryParameters: <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HttpException('LRCLIB search failed (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as List<Object?>;
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => LrclibResult.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  /// Fetches the best match, preferring a synchronized result.
  Future<LrclibResult?> get(String trackName, String artistName) async {
    final uri = Uri.parse('$_base/get').replace(
      queryParameters: <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw HttpException('LRCLIB request failed (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    return LrclibResult.fromJson(decoded);
  }

  /// Releases the underlying client.
  void close() => _client.close();
}

/// A network error with a readable message.
final class HttpException implements Exception {
  /// Creates the error.
  const HttpException(this.message);

  /// Human-readable description.
  final String message;

  @override
  String toString() => message;
}
