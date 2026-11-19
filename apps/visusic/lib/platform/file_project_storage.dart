// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visusic_platform/visusic_platform.dart';

/// Native Windows file dialogs and application-support recovery storage.
final class FileProjectStorage implements ProjectStorage {
  static const int _maxProjectBytes = 128 * 1024 * 1024;
  static const int _maxImageBytes = 24 * 1024 * 1024;
  static const int _maxAudioBytes = 512 * 1024 * 1024;

  @override
  Future<StoredBinaryFile?> openProject() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'VisuSic project', extensions: <String>['vsproj']),
      ],
    );
    if (file == null) {
      return null;
    }
    await _checkLength(file, _maxProjectBytes);
    return StoredBinaryFile(
      path: file.path,
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<String?> saveProject({
    required String suggestedName,
    required Uint8List bytes,
    String? existingPath,
    bool saveAs = false,
  }) async {
    var path = existingPath;
    if (path == null || saveAs) {
      final safeName = suggestedName.toLowerCase().endsWith('.vsproj')
          ? suggestedName
          : '$suggestedName.vsproj';
      final location = await getSaveLocation(
        suggestedName: safeName,
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'VisuSic project', extensions: <String>['vsproj']),
        ],
      );
      if (location == null) {
        return null;
      }
      path = location.path;
    }
    await _writeAtomic(File(path), bytes);
    return path;
  }

  @override
  Future<StoredBinaryFile?> pickImage() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'Images',
          extensions: <String>['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (file == null) {
      return null;
    }
    await _checkLength(file, _maxImageBytes);
    return StoredBinaryFile(
      path: file.path,
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<StoredBinaryFile?> openAudio() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'Audio',
          extensions: <String>['wav', 'mp3', 'flac', 'ogg', 'm4a', 'aac'],
        ),
      ],
    );
    if (file == null) {
      return null;
    }
    await _checkLength(file, _maxAudioBytes);
    return StoredBinaryFile(
      path: file.path,
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<StoredBinaryFile?> openLyrics() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'Lyrics', extensions: <String>['lrc', 'txt']),
      ],
    );
    if (file == null) {
      return null;
    }
    await _checkLength(file, _maxProjectBytes);
    return StoredBinaryFile(
      path: file.path,
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<void> writeRecovery(String name, Uint8List bytes) async {
    final file = await _recoveryFile();
    await _writeAtomic(file, bytes);
  }

  @override
  Future<StoredBinaryFile?> readRecovery() async {
    final file = await _recoveryFile();
    if (!await file.exists()) {
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxProjectBytes) {
      throw const FileSystemException('Recovery project is too large.');
    }
    return StoredBinaryFile(
      path: '',
      name: 'Recovered scene.vsproj',
      bytes: bytes,
    );
  }

  @override
  Future<void> clearRecovery() async {
    final file = await _recoveryFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> _checkLength(XFile file, int limit) async {
    if (await file.length() > limit) {
      throw const FileSystemException('Selected file is too large.');
    }
  }

  static Future<void> _writeAtomic(File target, Uint8List bytes) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
  }

  static Future<File> _recoveryFile() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/recovery');
    return File('${directory.path}/untitled-recovery.vsproj');
  }
}
