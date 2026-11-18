// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_platform/visusic_platform.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

/// Application state and reversible operations for the scene editor.
final class EditorController extends ChangeNotifier {
  /// Creates an editor controller.
  EditorController({
    required this.registry,
    required this.storage,
    ProjectBundle? bundle,
  }) : _bundle = bundle ?? ProjectBundle.empty() {
    _features = FeatureSnapshot.silent(project.canvas.duration);
    unawaited(refreshImages());
  }

  /// Validated widget library.
  final ManifestRegistry registry;

  /// Host file operations.
  final ProjectStorage storage;

  ProjectBundle _bundle;
  final CommandHistory _history = CommandHistory();
  final BindingResolver _bindingResolver = BindingResolver();
  final Set<String> _selectedIds = <String>{};
  final Map<String, ui.Image> _images = <String, ui.Image>{};
  Timer? _autosaveTimer;
  FeatureSnapshot _features = FeatureSnapshot.silent(30);
  String? _currentPath;
  bool _dirty = false;
  bool _busy = false;
  bool _playing = false;
  int _nextLayerId = 1;
  int _nextAssetId = 1;
  /// Snap/grid interval in logical pixels.
  int gridSize = 8;

  /// Whether the editor grid is visible.
  bool showGrid = false;

  /// Whether the safe-area outline is visible.
  bool showSafeArea = true;

  static List<Map<String, Object?>> _clipboard = <Map<String, Object?>>[];

  /// Current project bundle.
  ProjectBundle get bundle => _bundle;

  /// Current project manifest.
  SceneProject get project => _bundle.project;

  /// Decoded project images.
  Map<String, ui.Image> get images => Map.unmodifiable(_images);

  /// Current deterministic demo feature frame.
  FeatureSnapshot get features => _features;

  /// Evaluated per-layer expression properties.
  Map<String, Map<String, double>> expressionValues =
      <String, Map<String, double>>{};

  /// Current selected IDs.
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Primary selected layer.
  SceneLayer? get selectedLayer {
    if (_selectedIds.isEmpty) {
      return null;
    }
    for (final layer in project.layers.reversed) {
      if (_selectedIds.contains(layer.id)) {
        return layer;
      }
    }
    return null;
  }

  /// Native project path after save/open.
  String? get currentPath => _currentPath;

  /// Whether unsaved changes exist.
  bool get dirty => _dirty;

  /// Whether an async file operation is running.
  bool get busy => _busy;

  /// Whether the demo transport is playing.
  bool get playing => _playing;

  /// Whether one or more operations can be undone.
  bool get canUndo => _history.canUndo;

  /// Whether one or more operations can be redone.
  bool get canRedo => _history.canRedo;

  /// Current playhead position in milliseconds.
  double get timeMs => _features.time * 1000;

  /// Begins periodic crash-recovery saves.
  void startAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_dirty && !_busy) {
        unawaited(writeRecovery());
      }
    });
  }

  /// Toggles deterministic demo playback.
  void togglePlayback() {
    if (!_playing && _features.time >= project.canvas.duration) {
      seek(0);
    }
    _playing = !_playing;
    notifyListeners();
  }

  /// Advances demo time from the UI ticker.
  void tick(Duration elapsed) {
    if (!_playing) {
      return;
    }
    final next = _features.time + elapsed.inMilliseconds / 1000;
    if (next >= project.canvas.duration) {
      _features = FeatureSnapshot.demo(
        project.canvas.duration,
        project.canvas.duration,
      );
      _playing = false;
    } else {
      _features = FeatureSnapshot.demo(next, project.canvas.duration);
    }
    _refreshExpressions();
    notifyListeners();
  }

  /// Moves the playhead and resets time-dependent bindings.
  void seek(double timeMs) {
    final seconds = (timeMs / 1000)
        .clamp(0, project.canvas.duration)
        .toDouble();
    _bindingResolver.reset();
    _features = FeatureSnapshot.demo(seconds, project.canvas.duration);
    _refreshExpressions();
    notifyListeners();
  }

  /// Selects a layer, optionally adding/removing it from multi-selection.
  void select(String? id, {bool additive = false}) {
    if (id == null) {
      _selectedIds.clear();
    } else if (additive) {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    } else {
      _selectedIds
        ..clear()
        ..add(id);
    }
    notifyListeners();
  }

  /// Selects all currently visible layers.
  void selectAll() {
    _selectedIds
      ..clear()
      ..addAll(
        project.layers.where((layer) => !layer.hidden).map((layer) => layer.id),
      );
    notifyListeners();
  }

  /// Adds a widget using smart default placement.
  SceneLayer addWidget(WidgetManifest manifest, {Offset? topLeft, int? index}) {
    final xScale = project.canvas.width / 1920;
    final yScale = project.canvas.height / 1080;
    final width = (manifest.defaultWidth * xScale).clamp(
      32,
      project.canvas.width,
    );
    final height = (manifest.defaultHeight * yScale).clamp(
      32,
      project.canvas.height,
    );
    final rawX =
        topLeft?.dx ??
        (manifest.anchor == 'fill'
            ? 0
            : (project.canvas.width - width) / 2 + (_nextLayerId % 4) * 12);
    final rawY =
        topLeft?.dy ??
        (manifest.anchor == 'fill'
            ? 0
            : manifest.anchor == 'bottom-center'
            ? project.canvas.height - height - project.canvas.height * 0.08
            : (project.canvas.height - height) / 2 + (_nextLayerId % 4) * 12);
    final proposed = SceneRect(
      x: rawX.toDouble(),
      y: rawY.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
    );
    final snap = SnapEngine.snapMove(
      rect: proposed,
      canvasWidth: project.canvas.width.toDouble(),
      canvasHeight: project.canvas.height.toDouble(),
      neighbors: project.layers.map((layer) => layer.rect).toList(),
      gridSize: gridSize,
      safeFactor: project.canvas.height > project.canvas.width ? 0.8 : 0.9,
    );
    final layer = SceneLayer(
      id: _newLayerId(),
      widgetId: manifest.id,
      name: manifest.name.english,
      rect: snap.rect,
      params: _copyParams(manifest.defaultParams()),
      anchor: manifest.anchor,
    );
    if (index == null) {
      _execute(AddLayerCommand(layer));
    } else {
      _execute(AddLayerCommand(layer));
      final lastIndex = project.layers.length - 1;
      if (index != lastIndex) {
        _execute(ReorderLayerCommand(lastIndex, index));
      }
    }
    _selectedIds
      ..clear()
      ..add(layer.id);
    unawaited(refreshImages());
    notifyListeners();
    return layer;
  }

  /// Replaces a widget while preserving placement, timing, and compatible params.
  void replaceWidget(SceneLayer before, WidgetManifest manifest) {
    final params = manifest.defaultParams();
    for (final parameter in manifest.parameters) {
      final oldValue = before.params[parameter.id];
      if (oldValue == null) {
        continue;
      }
      try {
        parameter.validate(oldValue);
        params[parameter.id] = oldValue;
      } on ManifestException {
        // Incompatible values intentionally reset to the new widget default.
      }
    }
    final after = before.copyWith(
      widgetId: manifest.id,
      name: manifest.name.english,
      params: _copyParams(params),
    );
    commitLayerChange(before, after);
  }

  /// Previews a layer edit without creating a command for every pointer event.
  void previewLayer(SceneLayer after) {
    _replaceDirect(after);
    _dirty = true;
    _refreshExpressions();
    notifyListeners();
  }

  /// Commits one layer operation after a drag or inspector edit.
  void commitLayerChange(SceneLayer before, SceneLayer after) {
    _execute(UpdateLayerCommand(before, after));
  }

  /// Reorders a layer using ReorderableListView indexes.
  void reorder(int oldIndex, int newIndex) {
    var destination = newIndex;
    if (destination > oldIndex) {
      destination--;
    }
    destination = destination.clamp(0, project.layers.length - 1);
    if (destination == oldIndex) {
      return;
    }
    _execute(ReorderLayerCommand(oldIndex, destination));
  }

  /// Moves a layer directly between final list indexes.
  void moveLayer(int from, int to) {
    if (from != to) {
      _execute(ReorderLayerCommand(from, to));
    }
  }

  /// Deletes all selected layers.
  void deleteSelected() {
    for (final id in _selectedIds.toList()) {
      _execute(RemoveLayerCommand(id));
    }
    _selectedIds.clear();
    notifyListeners();
  }

  /// Duplicates selected layers with fresh IDs and a small offset.
  void duplicateSelected() {
    final duplicates = project.layers
        .where((layer) => _selectedIds.contains(layer.id))
        .map(_duplicateLayer)
        .toList(growable: false);
    _selectedIds.clear();
    for (final layer in duplicates) {
      _execute(AddLayerCommand(layer));
      _selectedIds.add(layer.id);
    }
    notifyListeners();
  }

  /// Copies selected layers to the app-wide clipboard.
  void copySelected() {
    _clipboard = project.layers
        .where((layer) => _selectedIds.contains(layer.id))
        .map((layer) => layer.toJson())
        .toList(growable: false);
  }

  /// Pastes layers, including between two open editor windows.
  void paste() {
    _selectedIds.clear();
    for (final json in _clipboard) {
      final source = SceneLayer.fromJson(json);
      final layer = _duplicateLayer(source);
      _execute(AddLayerCommand(layer));
      _selectedIds.add(layer.id);
    }
    notifyListeners();
  }

  /// Adds a cubic-bezier keyframe at the current playhead.
  void addKeyframe(SceneLayer layer, String parameterId) {
    final value = layer.params[parameterId];
    if (value is! num) {
      return;
    }
    final frames = <SceneKeyframe>[...?layer.keyframes[parameterId]]
      ..removeWhere((frame) => (frame.timeMs - timeMs).abs() < 1);
    frames.add(SceneKeyframe(timeMs: timeMs, value: value.toDouble()));
    frames.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    commitLayerChange(
      layer,
      layer.copyWith(
        keyframes: <String, List<SceneKeyframe>>{
          ...layer.keyframes,
          parameterId: frames,
        },
      ),
    );
  }

  /// Removes all keyframes for one numeric parameter.
  void clearKeyframes(SceneLayer layer, String parameterId) {
    final frames = <String, List<SceneKeyframe>>{...layer.keyframes}
      ..remove(parameterId);
    commitLayerChange(layer, layer.copyWith(keyframes: frames));
  }

  /// Nudges every selected layer as one command.
  void nudge(Offset delta) {
    final before = <String, SceneLayer>{};
    final after = <String, SceneLayer>{};
    for (final layer in project.layers) {
      if (_selectedIds.contains(layer.id) && !layer.locked) {
        before[layer.id] = layer;
        after[layer.id] = layer.copyWith(
          rect: layer.rect.translate(delta.dx, delta.dy),
        );
      }
    }
    if (before.isNotEmpty) {
      _execute(UpdateLayersCommand(before: before, after: after));
    }
  }

  /// Aligns selected layers using left, centerX, right, top, centerY, or bottom.
  void alignSelected(String alignment) {
    final selected = project.layers
        .where((layer) => _selectedIds.contains(layer.id) && !layer.locked)
        .toList(growable: false);
    if (selected.length < 2) {
      return;
    }
    final left = selected
        .map((layer) => layer.rect.x)
        .reduce((a, b) => math.min(a, b).toDouble());
    final right = selected
        .map((layer) => layer.rect.right)
        .reduce((a, b) => math.max(a, b).toDouble());
    final top = selected
        .map((layer) => layer.rect.y)
        .reduce((a, b) => math.min(a, b).toDouble());
    final bottom = selected
        .map((layer) => layer.rect.bottom)
        .reduce((a, b) => math.max(a, b).toDouble());
    final before = <String, SceneLayer>{};
    final after = <String, SceneLayer>{};
    for (final layer in selected) {
      final rect = layer.rect;
      final updated = switch (alignment) {
        'left' => rect.copyWith(x: left),
        'centerX' => rect.copyWith(x: (left + right) / 2 - rect.width / 2),
        'right' => rect.copyWith(x: right - rect.width),
        'top' => rect.copyWith(y: top),
        'centerY' => rect.copyWith(y: (top + bottom) / 2 - rect.height / 2),
        'bottom' => rect.copyWith(y: bottom - rect.height),
        _ => rect,
      };
      before[layer.id] = layer;
      after[layer.id] = layer.copyWith(rect: updated);
    }
    _execute(UpdateLayersCommand(before: before, after: after));
  }

  /// Changes canvas size and proportionally adapts all layers.
  void changeCanvas(SceneCanvas canvas) {
    final updated = canvas.copyWith(
      fps: project.canvas.fps,
      duration: project.canvas.duration,
      background: project.canvas.background,
    );
    _execute(UpdateCanvasCommand.adapt(project, updated));
    seek(timeMs.clamp(0, updated.duration * 1000).toDouble());
  }

  /// Changes the project name.
  void renameProject(String name) {
    if (name.trim().isEmpty || name == project.name) {
      return;
    }
    final before = project;
    final after = project.copyWith(name: name.trim());
    final command = _RenameProjectCommand(before, after);
    _execute(command);
  }

  /// Adds a polished demo scene in one click.
  void buildDemoScene() {
    if (project.layers.isNotEmpty) {
      return;
    }
    addWidget(registry.require(BuiltinWidgetIds.meshGradient));
    addWidget(registry.require(BuiltinWidgetIds.particles));
    final scrim = addWidget(registry.require(BuiltinWidgetIds.scrim));
    previewLayer(
      scrim.copyWith(
        rect: SceneRect(
          x: project.canvas.width * 0.1,
          y: project.canvas.height * 0.25,
          width: project.canvas.width * 0.8,
          height: project.canvas.height * 0.5,
        ),
      ),
    );
    commitLayerChange(scrim, project.layerById(scrim.id)!);
    addWidget(registry.require(BuiltinWidgetIds.title));
    final spectrum = addWidget(registry.require(BuiltinWidgetIds.barSpectrum));
    previewLayer(
      spectrum.copyWith(
        rect: SceneRect(
          x: project.canvas.width * 0.15,
          y: project.canvas.height * 0.69,
          width: project.canvas.width * 0.7,
          height: project.canvas.height * 0.2,
        ),
      ),
    );
    commitLayerChange(spectrum, project.layerById(spectrum.id)!);
    addWidget(registry.require(BuiltinWidgetIds.progress));
    seek(1000);
  }

  /// Saves the current project, optionally asking for a new path.
  Future<String?> save({bool saveAs = false}) async {
    String? savedPath;
    await _runBusy(() async {
      final bytes = ProjectArchiveCodec.encode(_bundle);
      final path = await storage.saveProject(
        suggestedName: '${_safeName(project.name)}.vsproj',
        bytes: bytes,
        existingPath: _currentPath,
        saveAs: saveAs,
      );
      savedPath = path;
      if (path != null) {
        _currentPath = path;
        _dirty = false;
        await storage.clearRecovery();
      } else {
        return;
      }
    });
    return savedPath;
  }

  /// Opens a .vsproj file and resets editor history.
  Future<bool> open() async {
    var opened = false;
    await _runBusy(() async {
      final file = await storage.openProject();
      if (file == null) {
        return;
      }
      final decoded = ProjectArchiveCodec.decode(file.bytes);
      _load(decoded, file.path);
      opened = true;
    });
    return opened;
  }

  /// Loads recovery bytes offered by the host storage.
  Future<bool> recover() async {
    final file = await storage.readRecovery();
    if (file == null) {
      return false;
    }
    _load(ProjectArchiveCodec.decode(file.bytes), null);
    return true;
  }

  /// Returns available recovery data without loading it.
  Future<StoredBinaryFile?> readRecovery() => storage.readRecovery();

  /// Persists current recovery data.
  Future<void> writeRecovery() async {
    await storage.writeRecovery(
      project.name,
      ProjectArchiveCodec.encode(_bundle),
    );
  }

  /// Discards recovery data after the user makes an explicit choice.
  Future<void> discardRecovery() => storage.clearRecovery();

  /// Chooses and imports an image into a layer's asset parameter.
  Future<void> importImage(SceneLayer before) async {
    await _runBusy(() async {
      final file = await storage.pickImage();
      if (file == null) {
        return;
      }
      final image = await _decodeImage(file.bytes);
      final id = _newAssetId();
      final asset = ProjectAsset(
        id: id,
        path: 'assets/$id-${_safeName(file.name)}',
        mimeType: _mimeType(file.name),
      );
      final after = before.copyWith(
        params: <String, Object?>{...before.params, 'asset': id},
      );
      _images[id] = image;
      _bundle = _bundle.copyWith(
        project: _bundle.project.copyWith(
          assets: <ProjectAsset>[...project.assets, asset],
        ),
        assetBytes: <String, Uint8List>{..._bundle.assetBytes, id: file.bytes},
      );
      _execute(UpdateLayerCommand(before, after));
    });
  }

  /// Re-decodes assets after image changes or project loading.
  Future<void> refreshImages() async {
    final used = <String>{};
    for (final asset in project.assets) {
      used.add(asset.id);
      if (_images.containsKey(asset.id)) {
        continue;
      }
      final bytes = _bundle.assetBytes[asset.id];
      if (bytes != null) {
        _images[asset.id] = await _decodeImage(bytes);
      }
    }
    _images.removeWhere((id, _) => !used.contains(id));
    notifyListeners();
  }

  /// Undoes the latest command.
  void undo() {
    _applyHistoryResult(_history.undo(_bundle));
  }

  /// Redoes the latest undone command.
  void redo() {
    _applyHistoryResult(_history.redo(_bundle));
  }

  void _load(ProjectBundle decoded, String? path) {
    _bundle = decoded;
    _currentPath = path;
    _dirty = path == null;
    _history.clear();
    _selectedIds.clear();
    _nextLayerId = 1;
    _nextAssetId = 1;
    _playing = false;
    _bindingResolver.reset();
    _features = FeatureSnapshot.silent(project.canvas.duration);
    unawaited(refreshImages());
  }

  void _applyHistoryResult(ProjectBundle result) {
    _bundle = result;
    _dirty = true;
    _selectedIds.removeWhere((id) => project.layerById(id) == null);
    _refreshExpressions();
    notifyListeners();
  }

  void _execute(EditorCommand command) {
    _bundle = _history.execute(command, _bundle);
    _dirty = true;
    _refreshExpressions();
    notifyListeners();
  }

  void _replaceDirect(SceneLayer replacement) {
    _bundle = _bundle.copyWith(
      project: project.copyWith(
        layers: project.layers
            .map((layer) => layer.id == replacement.id ? replacement : layer)
            .toList(growable: false),
      ),
    );
  }

  void _refreshExpressions() {
    expressionValues = _bindingResolver.resolve(
      project,
      registry.manifests,
      _features,
    );
  }

  SceneLayer _duplicateLayer(SceneLayer source) {
    return source
        .copyWith(
          name: '${source.name} copy',
          rect: source.rect.translate(24, 24),
        )
        ._withId(_newLayerId());
  }

  String _newLayerId() {
    while (project.layerById('layer-$_nextLayerId') != null) {
      _nextLayerId++;
    }
    return 'layer-${_nextLayerId++}';
  }

  String _newAssetId() {
    final ids = project.assets.map((asset) => asset.id).toSet();
    while (ids.contains('asset-$_nextAssetId')) {
      _nextAssetId++;
    }
    return 'asset-${_nextAssetId++}';
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } on Object catch (error) {
      throw FormatException('The selected image cannot be decoded: $error');
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      await action();
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }
}

final class _RenameProjectCommand implements EditorCommand {
  const _RenameProjectCommand(this.before, this.after);
  final SceneProject before;
  final SceneProject after;

  @override
  ProjectBundle apply(ProjectBundle bundle) => bundle.copyWith(project: after);

  @override
  ProjectBundle undo(ProjectBundle bundle) => bundle.copyWith(project: before);
}

extension on SceneLayer {
  SceneLayer _withId(String id) => SceneLayer(
    id: id,
    widgetId: widgetId,
    name: name,
    rect: rect,
    params: Map<String, Object?>.from(params),
    keyframes: keyframes,
    timing: timing,
    locked: locked,
    hidden: hidden,
    muted: muted,
    solo: solo,
    anchor: anchor,
    groupId: groupId,
    colorTag: colorTag,
  );
}

Map<String, Object?> _copyParams(Map<String, Object?> source) => source.map(
  (key, value) =>
      MapEntry(key, value is List ? List<Object?>.from(value) : value),
);

String _safeName(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
  return safe.isEmpty ? 'scene' : safe;
}

String _mimeType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/png';
}
