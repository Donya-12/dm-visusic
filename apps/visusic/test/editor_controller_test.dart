// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_platform/visusic_platform.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

void main() {
  final registry = BuiltinLibrary.createRegistry();

  test('five rectangles save, reopen, and undo twenty nudges', () async {
    final storage = _FakeProjectStorage();
    final controller = EditorController(registry: registry, storage: storage);

    for (var index = 0; index < 5; index++) {
      controller.addWidget(registry.require(BuiltinWidgetIds.rectangle));
    }
    expect(controller.project.layers, hasLength(5));

    final path = await controller.save();
    expect(path, 'demo.vsproj');
    expect(controller.dirty, isFalse);
    final restored = ProjectArchiveCodec.decode(storage.savedBytes);
    expect(restored.project.layers, hasLength(5));

    controller.select(controller.project.layers.last.id);
    final startX = controller.selectedLayer!.rect.x;
    for (var index = 0; index < 20; index++) {
      controller.nudge(const Offset(1, 1));
    }
    for (var index = 0; index < 20; index++) {
      controller.undo();
    }
    expect(
      controller.project.layerById(controller.project.layers.last.id)!.rect.x,
      startX,
    );
    expect(controller.canUndo, isTrue);
  });

  test('demo scene uses reactive M2 widgets and resolves expressions', () {
    final controller = EditorController(
      registry: registry,
      storage: _FakeProjectStorage(),
    );
    controller.buildDemoScene();
    expect(controller.project.layers, isNotEmpty);
    expect(controller.expressionValues, isNotEmpty);
    controller.seek(500);
    expect(controller.features.time, greaterThan(0));
    expect(controller.expressionValues, isNotEmpty);
  });

  test('aspect change adapts every layer proportionally', () {
    final controller = EditorController(
      registry: registry,
      storage: _FakeProjectStorage(),
    );
    controller.addWidget(registry.require(BuiltinWidgetIds.rectangle));
    final before = controller.project.layers.single.rect.width;
    controller.changeCanvas(
      const SceneCanvas(width: 1080, height: 1920, aspect: '9:16'),
    );
    expect(controller.project.canvas.aspect, '9:16');
    expect(controller.project.layers.single.rect.width, lessThan(before));
  });
}

final class _FakeProjectStorage implements ProjectStorage {
  Uint8List savedBytes = Uint8List(0);
  StoredBinaryFile? toOpen;

  @override
  Future<void> clearRecovery() async {}

  @override
  Future<StoredBinaryFile?> openAudio() async => null;

  @override
  Future<StoredBinaryFile?> openLyrics() async => null;

  @override
  Future<StoredBinaryFile?> openProject() async => toOpen;

  @override
  Future<StoredBinaryFile?> pickImage() async => null;

  @override
  Future<StoredBinaryFile?> readRecovery() async => null;

  @override
  Future<String?> saveProject({
    required String suggestedName,
    required Uint8List bytes,
    String? existingPath,
    bool saveAs = false,
  }) async {
    savedBytes = bytes;
    return 'demo.vsproj';
  }

  @override
  Future<void> writeRecovery(String name, Uint8List bytes) async {}
}
