// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

/// Binary content selected through a host file dialog.
final class StoredBinaryFile {
  /// Creates a binary file value.
  const StoredBinaryFile({
    required this.path,
    required this.name,
    required this.bytes,
  });

  /// Host path, or an empty string for an in-memory recovery value.
  final String path;

  /// Original file name.
  final String name;

  /// Complete file contents.
  final Uint8List bytes;
}

/// Host file operations used by the editor without leaking dart:io into UI.
abstract interface class ProjectStorage {
  /// Opens a native .vsproj picker.
  Future<StoredBinaryFile?> openProject();

  /// Saves bytes, reusing an existing path unless Save As is requested.
  Future<String?> saveProject({
    required String suggestedName,
    required Uint8List bytes,
    String? existingPath,
    bool saveAs = false,
  });

  /// Opens a native image picker.
  Future<StoredBinaryFile?> pickImage();

  /// Opens a native audio picker.
  Future<StoredBinaryFile?> openAudio();

  /// Opens a native lyric-file picker.
  Future<StoredBinaryFile?> openLyrics();

  /// Writes crash-recovery data when the document is dirty.
  Future<void> writeRecovery(String name, Uint8List bytes);

  /// Reads pending recovery data, if any.
  Future<StoredBinaryFile?> readRecovery();

  /// Deletes recovery data after save or explicit discard.
  Future<void> clearRecovery();
}
