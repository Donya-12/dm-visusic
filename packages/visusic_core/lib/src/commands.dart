// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/src/project_bundle.dart';
import 'package:visusic_core/src/scene_models.dart';

/// One reversible editor operation.
abstract interface class EditorCommand {
  /// Applies the operation.
  ProjectBundle apply(ProjectBundle bundle);

  /// Reverses the operation after [apply].
  ProjectBundle undo(ProjectBundle bundle);
}

/// Adds a layer to the back-to-front layer list.
final class AddLayerCommand implements EditorCommand {
  /// Creates an add operation.
  const AddLayerCommand(this.layer);

  /// Layer to add.
  final SceneLayer layer;

  @override
  ProjectBundle apply(ProjectBundle bundle) {
    if (bundle.project.layerById(layer.id) != null) {
      throw StateError('Layer ${layer.id} already exists.');
    }
    return bundle.copyWith(
      project: bundle.project.copyWith(
        layers: <SceneLayer>[...bundle.project.layers, layer],
      ),
    );
  }

  @override
  ProjectBundle undo(ProjectBundle bundle) => bundle.copyWith(
    project: bundle.project.copyWith(
      layers: bundle.project.layers
          .where((candidate) => candidate.id != layer.id)
          .toList(growable: false),
    ),
  );
}

/// Removes a layer and restores it at its previous index.
final class RemoveLayerCommand implements EditorCommand {
  /// Creates a remove operation.
  RemoveLayerCommand(this.layerId);

  /// ID of the layer to remove.
  final String layerId;
  SceneLayer? _removed;
  int _index = -1;

  @override
  ProjectBundle apply(ProjectBundle bundle) {
    _index = bundle.project.layers.indexWhere((layer) => layer.id == layerId);
    if (_index < 0) {
      throw StateError('Layer $layerId does not exist.');
    }
    _removed = bundle.project.layers[_index];
    final layers = [...bundle.project.layers]..removeAt(_index);
    return bundle.copyWith(project: bundle.project.copyWith(layers: layers));
  }

  @override
  ProjectBundle undo(ProjectBundle bundle) {
    final removed = _removed;
    if (removed == null || _index < 0) {
      throw StateError('Remove operation has not been applied.');
    }
    final layers = [...bundle.project.layers]..insert(_index, removed);
    return bundle.copyWith(project: bundle.project.copyWith(layers: layers));
  }
}

/// Updates one layer while storing only its before/after values.
final class UpdateLayerCommand implements EditorCommand {
  /// Creates an update operation.
  const UpdateLayerCommand(this.before, this.after);

  /// Previous layer value.
  final SceneLayer before;

  /// New layer value.
  final SceneLayer after;

  @override
  ProjectBundle apply(ProjectBundle bundle) => _replace(bundle, after);

  @override
  ProjectBundle undo(ProjectBundle bundle) => _replace(bundle, before);

  ProjectBundle _replace(ProjectBundle bundle, SceneLayer replacement) {
    var found = false;
    final layers = bundle.project.layers
        .map((layer) {
          if (layer.id == replacement.id) {
            found = true;
            return replacement;
          }
          return layer;
        })
        .toList(growable: false);
    if (!found) {
      throw StateError('Layer ${replacement.id} does not exist.');
    }
    return bundle.copyWith(project: bundle.project.copyWith(layers: layers));
  }
}

/// Updates several layers as one undoable operation.
final class UpdateLayersCommand implements EditorCommand {
  /// Creates a multi-layer update.
  UpdateLayersCommand({
    required Map<String, SceneLayer> before,
    required Map<String, SceneLayer> after,
  }) : before = Map.unmodifiable(before),
       after = Map.unmodifiable(after);

  /// Previous values keyed by ID.
  final Map<String, SceneLayer> before;

  /// New values keyed by ID.
  final Map<String, SceneLayer> after;

  @override
  ProjectBundle apply(ProjectBundle bundle) => _replace(bundle, after);

  @override
  ProjectBundle undo(ProjectBundle bundle) => _replace(bundle, before);

  ProjectBundle _replace(
    ProjectBundle bundle,
    Map<String, SceneLayer> replacements,
  ) {
    final layers = bundle.project.layers
        .map((layer) => replacements[layer.id] ?? layer)
        .toList(growable: false);
    return bundle.copyWith(project: bundle.project.copyWith(layers: layers));
  }
}

/// Changes layer order as one reversible operation.
final class ReorderLayerCommand implements EditorCommand {
  /// Creates a reorder operation using final list indexes.
  const ReorderLayerCommand(this.from, this.to);

  /// Index before the move.
  final int from;

  /// Index after the move.
  final int to;

  @override
  ProjectBundle apply(ProjectBundle bundle) => _move(bundle, from, to);

  @override
  ProjectBundle undo(ProjectBundle bundle) => _move(bundle, to, from);

  ProjectBundle _move(ProjectBundle bundle, int source, int destination) {
    final layers = [...bundle.project.layers];
    if (source < 0 ||
        source >= layers.length ||
        destination < 0 ||
        destination >= layers.length) {
      throw RangeError('Layer reorder index is out of range.');
    }
    final layer = layers.removeAt(source);
    layers.insert(destination, layer);
    return bundle.copyWith(project: bundle.project.copyWith(layers: layers));
  }
}

/// Changes canvas dimensions and optionally adapts all rectangles.
final class UpdateCanvasCommand implements EditorCommand {
  /// Creates a canvas operation.
  UpdateCanvasCommand({
    required this.before,
    required this.after,
    required Map<String, SceneRect> beforeRects,
    required Map<String, SceneRect> afterRects,
  }) : beforeRects = Map.unmodifiable(beforeRects),
       afterRects = Map.unmodifiable(afterRects);

  /// Previous canvas settings.
  final SceneCanvas before;

  /// New canvas settings.
  final SceneCanvas after;

  /// Previous layer rectangles.
  final Map<String, SceneRect> beforeRects;

  /// Adapted layer rectangles.
  final Map<String, SceneRect> afterRects;

  /// Creates an operation by proportionally adapting existing layers.
  factory UpdateCanvasCommand.adapt(SceneProject project, SceneCanvas after) {
    final afterRects = <String, SceneRect>{};
    for (final layer in project.layers) {
      afterRects[layer.id] = SceneRect(
        x: layer.rect.x * after.width / project.canvas.width,
        y: layer.rect.y * after.height / project.canvas.height,
        width: layer.rect.width * after.width / project.canvas.width,
        height: layer.rect.height * after.height / project.canvas.height,
        rotation: layer.rect.rotation,
      );
    }
    return UpdateCanvasCommand(
      before: project.canvas,
      after: after,
      beforeRects: <String, SceneRect>{
        for (final layer in project.layers) layer.id: layer.rect,
      },
      afterRects: afterRects,
    );
  }

  @override
  ProjectBundle apply(ProjectBundle bundle) =>
      _update(bundle, after, afterRects);

  @override
  ProjectBundle undo(ProjectBundle bundle) =>
      _update(bundle, before, beforeRects);

  ProjectBundle _update(
    ProjectBundle bundle,
    SceneCanvas canvas,
    Map<String, SceneRect> rectangles,
  ) {
    final layers = bundle.project.layers
        .map((layer) {
          final rect = rectangles[layer.id];
          return rect == null ? layer : layer.copyWith(rect: rect);
        })
        .toList(growable: false);
    return bundle.copyWith(
      project: bundle.project.copyWith(canvas: canvas, layers: layers),
    );
  }
}

/// Bounded command history with redo invalidation.
final class CommandHistory {
  /// Creates history with a configurable memory bound.
  CommandHistory({this.limit = 100}) : assert(limit > 0);

  /// Maximum retained operations.
  final int limit;
  final List<EditorCommand> _undo = <EditorCommand>[];
  final List<EditorCommand> _redo = <EditorCommand>[];

  /// Whether undo is available.
  bool get canUndo => _undo.isNotEmpty;

  /// Whether redo is available.
  bool get canRedo => _redo.isNotEmpty;

  /// Number of retained undo operations.
  int get length => _undo.length;

  /// Applies and records an operation.
  ProjectBundle execute(EditorCommand command, ProjectBundle bundle) {
    final result = command.apply(bundle);
    _undo.add(command);
    if (_undo.length > limit) {
      _undo.removeAt(0);
    }
    _redo.clear();
    return result;
  }

  /// Undoes the latest operation.
  ProjectBundle undo(ProjectBundle bundle) {
    if (_undo.isEmpty) {
      return bundle;
    }
    final command = _undo.removeLast();
    final result = command.undo(bundle);
    _redo.add(command);
    return result;
  }

  /// Reapplies the latest undone operation.
  ProjectBundle redo(ProjectBundle bundle) {
    if (_redo.isEmpty) {
      return bundle;
    }
    final command = _redo.removeLast();
    final result = command.apply(bundle);
    _undo.add(command);
    return result;
  }

  /// Clears history after loading a different project.
  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
