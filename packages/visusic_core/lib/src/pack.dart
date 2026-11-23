// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:visusic_core/src/scene_models.dart';
import 'package:visusic_core/src/widget_manifest.dart';

/// A distributable collection of widgets, scenes, and assets.
final class WidgetPack {
  /// Creates a template pack.
  WidgetPack({
    required this.name,
    required this.version,
    required this.author,
    required this.manifests,
    this.scenes = const <SceneProject>[],
    this.description,
    this.assetBytes = const <String, Uint8List>{},
  });

  /// Pack display name.
  final String name;

  /// Pack semantic version.
  final String version;

  /// Pack author.
  final String author;

  /// Optional description.
  final String? description;

  /// Widget manifests included in the pack.
  final List<WidgetManifest> manifests;

  /// Ready-to-apply scene presets.
  final List<SceneProject> scenes;

  /// Binary assets keyed by relative `assets/` path.
  final Map<String, Uint8List> assetBytes;
}

/// A readable pack error.
final class PackException implements Exception {
  /// Creates a pack error.
  const PackException(this.message);

  /// Human-readable problem description.
  final String message;

  @override
  String toString() => 'PackException: $message';
}

/// Reads and writes the `.vspack` ZIP container.
abstract final class PackCodec {
  /// Encodes a pack.
  static Uint8List encode(WidgetPack pack) {
    final manifest = utf8.encode(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'name': pack.name,
        'version': pack.version,
        'author': pack.author,
        if (pack.description != null) 'description': pack.description,
        'widgets': pack.manifests
            .map((widget) => widget.toJson())
            .toList(growable: false),
        'scenes': pack.scenes
            .map((scene) => scene.toJson())
            .toList(growable: false),
      }),
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile('pack.json', manifest.length, Uint8List.fromList(manifest)),
      );
    for (final entry in pack.assetBytes.entries) {
      _validateAssetPath(entry.key);
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Decodes and validates a pack.
  static WidgetPack decode(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.findFile('pack.json');
      if (manifestFile == null) {
        throw const PackException('pack.json is missing.');
      }
      final decoded = jsonDecode(utf8.decode(manifestFile.content));
      if (decoded is! Map) {
        throw const PackException('pack.json must be an object.');
      }
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      if (json['schemaVersion'] != 1) {
        throw PackException(
          'Unsupported pack schema ${json['schemaVersion']}.',
        );
      }
      final rawWidgets = json['widgets'];
      final rawScenes = json['scenes'];
      final manifests = rawWidgets is List
          ? rawWidgets
                .map(
                  (widget) => WidgetManifest.fromJson(
                    (widget as Map).cast<String, Object?>(),
                  ),
                )
                .toList(growable: false)
          : throw const PackException('Pack widgets must be an array.');
      final scenes = rawScenes is List
          ? rawScenes
                .map(
                  (scene) => SceneProject.fromJson(
                    (scene as Map).cast<String, Object?>(),
                  ),
                )
                .toList(growable: false)
          : const <SceneProject>[];
      final assetBytes = <String, Uint8List>{};
      for (final file in archive.files) {
        if (file.isFile && file.name.startsWith('assets/')) {
          assetBytes[file.name] = Uint8List.fromList(file.content);
        }
      }
      return WidgetPack(
        name: json['name'] as String? ?? 'Untitled Pack',
        version: json['version'] as String? ?? '1.0.0',
        author: json['author'] as String? ?? 'Unknown',
        description: json['description'] as String?,
        manifests: manifests,
        scenes: scenes,
        assetBytes: assetBytes,
      );
    } on PackException {
      rethrow;
    } on Object catch (error) {
      throw PackException('Cannot read this .vspack file: $error');
    }
  }

  static void _validateAssetPath(String path) {
    if (!path.startsWith('assets/') ||
        path.contains('..') ||
        path.contains('\\') ||
        path.endsWith('/')) {
      throw PackException('Unsafe pack asset path: $path.');
    }
  }
}
