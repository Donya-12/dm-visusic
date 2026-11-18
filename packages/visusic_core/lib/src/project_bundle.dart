// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:visusic_core/src/scene_models.dart';

/// A project manifest and its binary assets kept outside platform file APIs.
final class ProjectBundle {
  /// Creates an immutable project bundle.
  ProjectBundle({required this.project, Map<String, Uint8List>? assetBytes})
    : assetBytes = Map<String, Uint8List>.unmodifiable(
        assetBytes ?? const <String, Uint8List>{},
      );

  /// Serializable project.
  final SceneProject project;

  /// Binary asset contents keyed by asset ID.
  final Map<String, Uint8List> assetBytes;

  /// Copies selected bundle values.
  ProjectBundle copyWith({
    SceneProject? project,
    Map<String, Uint8List>? assetBytes,
  }) => ProjectBundle(
    project: project ?? this.project,
    assetBytes: assetBytes ?? this.assetBytes,
  );

  /// Creates an empty 16:9 project.
  factory ProjectBundle.empty() => ProjectBundle(
    project: SceneProject(
      name: 'Untitled Scene',
      canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
    ),
  );
}

/// Reads and writes the platform-independent .vsproj ZIP container.
abstract final class ProjectArchiveCodec {
  /// Encodes a complete project into a .vsproj byte stream.
  static Uint8List encode(ProjectBundle bundle) {
    final manifest = utf8.encode(jsonEncode(bundle.project.toJson()));
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'project.json',
          manifest.length,
          Uint8List.fromList(manifest),
        ),
      );
    for (final asset in bundle.project.assets) {
      _validateAssetPath(asset.path);
      final bytes = bundle.assetBytes[asset.id];
      if (bytes == null) {
        throw ProjectFormatException('Missing bytes for asset ${asset.id}.');
      }
      archive.addFile(ArchiveFile(asset.path, bytes.length, bytes));
    }
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Decodes and validates a .vsproj byte stream.
  static ProjectBundle decode(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.findFile('project.json');
      if (manifestFile == null) {
        throw const ProjectFormatException('project.json is missing.');
      }
      final manifestBytes = _fileBytes(manifestFile);
      final decoded = jsonDecode(utf8.decode(manifestBytes));
      if (decoded is! Map) {
        throw const ProjectFormatException('project.json must be an object.');
      }
      final project = SceneProject.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      final assetBytes = <String, Uint8List>{};
      for (final asset in project.assets) {
        _validateAssetPath(asset.path);
        final file = archive.findFile(asset.path);
        if (file == null) {
          throw ProjectFormatException('Missing project file ${asset.path}.');
        }
        assetBytes[asset.id] = Uint8List.fromList(_fileBytes(file));
      }
      return ProjectBundle(project: project, assetBytes: assetBytes);
    } on ProjectFormatException {
      rethrow;
    } on Object catch (error) {
      throw ProjectFormatException('Cannot read this .vsproj file: $error');
    }
  }

  static List<int> _fileBytes(ArchiveFile file) => file.content;

  static void _validateAssetPath(String path) {
    if (!path.startsWith('assets/') ||
        path.contains('..') ||
        path.contains('\\') ||
        path.endsWith('/')) {
      throw ProjectFormatException('Unsafe project asset path: $path.');
    }
  }
}
