// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  SceneLayer layer(int index, {double x = 0}) => SceneLayer(
    id: 'layer-$index',
    widgetId: 'builtin.rectangle',
    name: 'Rectangle $index',
    rect: SceneRect(x: x, y: 0, width: 100, height: 100),
  );

  test('add, update, reorder, undo, and redo work as commands', () {
    final history = CommandHistory();
    var bundle = ProjectBundle.empty();
    bundle = history.execute(AddLayerCommand(layer(1)), bundle);
    bundle = history.execute(AddLayerCommand(layer(2)), bundle);
    final before = bundle.project.layerById('layer-1')!;
    final after = before.copyWith(rect: before.rect.translate(20, 30));
    bundle = history.execute(UpdateLayerCommand(before, after), bundle);
    bundle = history.execute(const ReorderLayerCommand(0, 1), bundle);
    expect(bundle.project.layers.map((item) => item.id), <String>[
      'layer-2',
      'layer-1',
    ]);

    bundle = history.undo(bundle);
    expect(bundle.project.layers.map((item) => item.id), <String>[
      'layer-1',
      'layer-2',
    ]);
    bundle = history.undo(bundle);
    expect(bundle.project.layerById('layer-1')!.rect.x, 0);
    bundle = history.redo(bundle);
    expect(bundle.project.layerById('layer-1')!.rect.x, 20);
  });

  test('twenty independent actions can all be undone', () {
    final history = CommandHistory();
    var bundle = history.execute(
      AddLayerCommand(layer(1)),
      ProjectBundle.empty(),
    );
    for (var index = 1; index <= 20; index++) {
      final before = bundle.project.layers.single;
      bundle = history.execute(
        UpdateLayerCommand(
          before,
          before.copyWith(rect: before.rect.copyWith(x: index.toDouble())),
        ),
        bundle,
      );
    }
    for (var index = 0; index < 20; index++) {
      bundle = history.undo(bundle);
    }
    expect(bundle.project.layers.single.rect.x, 0);
    expect(history.canUndo, isTrue);
    bundle = history.undo(bundle);
    expect(history.canUndo, isFalse);
  });

  test('canvas changes adapt rectangles in both directions', () {
    var bundle = ProjectBundle.empty();
    bundle = AddLayerCommand(layer(1)).apply(bundle);
    final project = bundle.project;
    final portrait = SceneCanvas(
      width: 1080,
      height: 1920,
      aspect: '9:16',
      duration: project.canvas.duration,
    );
    final command = UpdateCanvasCommand.adapt(project, portrait);
    var resized = command.apply(bundle);
    expect(resized.project.layers.single.rect.width, closeTo(56.25, 0.001));
    resized = command.undo(resized);
    expect(resized.project.layers.single.rect.width, 100);
  });
}
