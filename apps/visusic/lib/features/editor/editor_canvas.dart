// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/editor/inspector_panel.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/visusic_render.dart';

/// Scene zoom, drag-and-drop insertion, transforms, guides, and quick inspector.
final class EditorCanvas extends StatefulWidget {
  /// Creates the editor canvas.
  const EditorCanvas({
    required this.controller,
    required this.onOpenPalette,
    super.key,
  });

  /// Current editor state.
  final EditorController controller;

  /// Opens the W widget palette.
  final VoidCallback onOpenPalette;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final GlobalKey _canvasKey = GlobalKey();
  String _zoomMode = 'fit';
  double _zoom = 1;
  bool _phoneFrame = false;
  Rect? _dropGhost;
  List<SnapGuide> _guides = const <SnapGuide>[];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: <Widget>[
              for (final zoom in const <(String, String, IconData)>[
                ('fit', 'Fit', Icons.fit_screen_rounded),
                ('fill', 'Fill', Icons.rectangle_rounded),
                ('100%', '100%', Icons.percent_rounded),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: ChoiceChip(
                    label: Text(zoom.$2),
                    avatar: Icon(zoom.$3, size: 16),
                    selected: _zoomMode == zoom.$1,
                    onSelected: (_) => setState(() => _zoomMode = zoom.$1),
                  ),
                ),
              const VerticalDivider(),
              IconButton(
                tooltip: l10n.zoomOut,
                onPressed: () => _adjustZoom(-0.1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Text('${(_zoom * 100).round()}%'),
              IconButton(
                tooltip: l10n.zoomIn,
                onPressed: () => _adjustZoom(0.1),
                icon: const Icon(Icons.add_rounded),
              ),
              IconButton(
                tooltip: _phoneFrame ? l10n.phoneFrame : l10n.sceneFrame,
                onPressed: () => setState(() => _phoneFrame = !_phoneFrame),
                icon: Icon(
                  _phoneFrame
                      ? Icons.rectangle_rounded
                      : Icons.smartphone_rounded,
                ),
              ),
              IconButton(
                tooltip: '${l10n.grid} (${widget.controller.gridSize} px)',
                onPressed: () => setState(() {
                  widget.controller.showGrid = !widget.controller.showGrid;
                }),
                icon: const Icon(Icons.grid_4x4_rounded),
              ),
              PopupMenuButton<int>(
                tooltip: l10n.grid,
                onSelected: (value) => setState(() {
                  widget.controller
                    ..gridSize = value
                    ..showGrid = true;
                }),
                itemBuilder: (_) => const <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(value: 8, child: Text('8 px')),
                  PopupMenuItem<int>(value: 16, child: Text('16 px')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.grid_on_rounded),
                ),
              ),
              IconButton(
                tooltip: l10n.safeArea,
                onPressed: () => setState(() {
                  widget.controller.showSafeArea =
                      !widget.controller.showSafeArea;
                }),
                icon: const Icon(Icons.shield_outlined),
              ),
              if (widget.controller.selectedIds.length > 1)
                PopupMenuButton<String>(
                  tooltip: l10n.align,
                  onSelected: widget.controller.alignSelected,
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'left',
                      child: Text('Align left'),
                    ),
                    PopupMenuItem<String>(
                      value: 'centerX',
                      child: Text('Align horizontal centers'),
                    ),
                    PopupMenuItem<String>(
                      value: 'right',
                      child: Text('Align right'),
                    ),
                    PopupMenuItem<String>(
                      value: 'top',
                      child: Text('Align top'),
                    ),
                    PopupMenuItem<String>(
                      value: 'centerY',
                      child: Text('Align vertical centers'),
                    ),
                    PopupMenuItem<String>(
                      value: 'bottom',
                      child: Text('Align bottom'),
                    ),
                  ],
                  icon: const Icon(Icons.align_horizontal_left_rounded),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final project = widget.controller.project;
              final canvas = project.canvas;
              final availableWidth = math.max(1, constraints.maxWidth - 56);
              final availableHeight = math.max(1, constraints.maxHeight - 56);
              final baseScale = switch (_zoomMode) {
                'fill' => math.max(
                  availableWidth / canvas.width,
                  availableHeight / canvas.height,
                ),
                '100%' => 1.0,
                _ => math.min(
                  availableWidth / canvas.width,
                  availableHeight / canvas.height,
                ),
              };
              final scale = baseScale * _zoom;
              final width = canvas.width * scale;
              final height = canvas.height * scale;
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: _buildScene(width, height, scale),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScene(double width, double height, double scale) {
    final controller = widget.controller;
    final project = controller.project;
    final layer = controller.selectedLayer;
    final scene = DragTarget<WidgetManifest>(
      key: _canvasKey,
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final rect = _dropRect(details.offset, details.data, scale);
        if (rect != null) {
          setState(() => _dropGhost = rect);
        }
      },
      onLeave: (_) => setState(() => _dropGhost = null),
      onAcceptWithDetails: (details) {
        final rect = _dropRect(details.offset, details.data, scale);
        setState(() => _dropGhost = null);
        if (rect != null) {
          controller.addWidget(
            details.data,
            topLeft: Offset(rect.left, rect.top),
          );
          if (details.data.id == 'builtin.barSpectrum') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).spectrumDropHint),
              ),
            );
          }
        }
      },
      builder: (context, candidates, rejected) {
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: SceneView(
                  project: project,
                  features: controller.features,
                  images: controller.images,
                  expressionValues: controller.expressionValues,
                  shaderPrograms: controller.shaderPrograms,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _EditorGuidesPainter(
                      controller: controller,
                      scale: scale,
                      guides: _guides,
                    ),
                  ),
                ),
              ),
              if (_dropGhost != null)
                Positioned.fromRect(
                  rect: _dropGhost!,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              for (final layer in project.layers)
                if (!layer.hidden)
                  _LayerControl(
                    key: ValueKey<String>(layer.id),
                    controller: controller,
                    layer: layer,
                    scale: scale,
                    canvasKey: _canvasKey,
                    onGuides: (guides) => setState(() => _guides = guides),
                  ),
              if (project.layers.isEmpty)
                Positioned.fill(
                  child: _EmptyScene(onAdd: widget.onOpenPalette),
                ),
              if (layer != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final parameter
                                  in controller.registry
                                      .require(layer.widgetId)
                                      .primaryParameters())
                                SizedBox(
                                  width: 205,
                                  child: ParameterEditor(
                                    key: ValueKey<String>(
                                      'quick-${layer.id}-${parameter.id}',
                                    ),
                                    controller: controller,
                                    layer: controller.project.layerById(
                                      layer.id,
                                    )!,
                                    parameter: parameter,
                                    compact: true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (!_phoneFrame) {
      return scene;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF4B4B55), width: 2),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: scene),
    );
  }

  Rect? _dropRect(Offset global, WidgetManifest manifest, double scale) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }
    final local = box.globalToLocal(global);
    final project = widget.controller.project;
    final width = manifest.defaultWidth * project.canvas.width / 1920;
    final height = manifest.defaultHeight * project.canvas.height / 1080;
    final proposed = SceneRect(
      x: (local.dx - width * scale / 2) / scale,
      y: (local.dy - height * scale / 2) / scale,
      width: width,
      height: height,
    );
    final result = SnapEngine.snapMove(
      rect: proposed,
      canvasWidth: project.canvas.width.toDouble(),
      canvasHeight: project.canvas.height.toDouble(),
      neighbors: project.layers.map((layer) => layer.rect).toList(),
      gridSize: widget.controller.gridSize,
      safeFactor: project.canvas.height > project.canvas.width ? 0.8 : 0.9,
    );
    return Rect.fromLTWH(
      result.rect.x * scale,
      result.rect.y * scale,
      result.rect.width * scale,
      result.rect.height * scale,
    );
  }

  void _adjustZoom(double amount) {
    setState(() => _zoom = (_zoom + amount).clamp(0.2, 4).toDouble());
  }
}

final class _EmptyScene extends StatelessWidget {
  const _EmptyScene({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.auto_awesome_outlined, size: 36),
              const SizedBox(height: 12),
              Text(
                l10n.emptySceneTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 360,
                child: Text(l10n.emptySceneBody, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    key: const Key('demo-scene-button'),
                    onPressed: () {
                      final editor = context
                          .findAncestorWidgetOfExactType<EditorCanvas>();
                      editor?.controller.buildDemoScene();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(l10n.buildDemoScene),
                  ),
                  OutlinedButton(onPressed: onAdd, child: Text(l10n.addWidget)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LayerControl extends StatefulWidget {
  const _LayerControl({
    required this.controller,
    required this.layer,
    required this.scale,
    required this.canvasKey,
    required this.onGuides,
    super.key,
  });
  final EditorController controller;
  final SceneLayer layer;
  final double scale;
  final GlobalKey canvasKey;
  final ValueChanged<List<SnapGuide>> onGuides;

  @override
  State<_LayerControl> createState() => _LayerControlState();
}

class _LayerControlState extends State<_LayerControl> {
  SceneLayer? _before;
  SceneRect? _startRect;
  (double, double)? _handle;
  Offset? _lastGlobal;
  double _rotationOffset = 0;

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final selected = widget.controller.selectedIds.contains(layer.id);
    final rect = layer.rect;
    final width = rect.width * widget.scale;
    final height = rect.height * widget.scale;
    return Positioned(
      left: rect.x * widget.scale,
      top: rect.y * widget.scale,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: rect.rotation * math.pi / 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => widget.controller.select(
                  layer.id,
                  additive: HardwareKeyboard.instance.isControlPressed,
                ),
                onPanStart: layer.locked ? null : _startMove,
                onPanUpdate: layer.locked ? null : _updateMove,
                onPanEnd: layer.locked ? null : _endEdit,
                onSecondaryTapDown: _openContextMenu,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0x00000000),
                      width: selected ? 1.5 : 0,
                    ),
                  ),
                ),
              ),
            ),
            if (selected && !layer.locked) ...<Widget>[
              for (final handle in const <(double, double)>[
                (-1, -1),
                (0, -1),
                (1, -1),
                (-1, 0),
                (1, 0),
                (-1, 1),
                (0, 1),
                (1, 1),
              ])
                _resizeHandle(handle, width, height),
              Positioned(
                left: width / 2 - 8,
                top: -34,
                child: GestureDetector(
                  onPanStart: _startRotate,
                  onPanUpdate: _updateRotate,
                  onPanEnd: _endEdit,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: CircleAvatar(
                      radius: 8,
                      child: Icon(Icons.rotate_right_rounded, size: 12),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width / 2,
                top: -26,
                child: Container(
                  width: 1,
                  height: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resizeHandle((double, double) handle, double width, double height) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final x = (handle.$1 + 1) / 2 * width;
    final y = (handle.$2 + 1) / 2 * height;
    return Positioned(
      left: x - 5,
      top: y - 5,
      child: GestureDetector(
        onPanStart: (details) {
          _before = widget.layer;
          _startRect = widget.layer.rect;
          _handle = handle;
          _lastGlobal = details.globalPosition;
        },
        onPanUpdate: _updateResize,
        onPanEnd: _endEdit,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: selectedColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _startMove(DragStartDetails details) {
    _before = widget.layer;
    _startRect = widget.layer.rect;
    _lastGlobal = details.globalPosition;
  }

  void _updateMove(DragUpdateDetails details) {
    final before = _before;
    final last = _lastGlobal;
    if (before == null || last == null) {
      return;
    }
    final delta = (details.globalPosition - last) / widget.scale;
    _lastGlobal = details.globalPosition;
    final current = widget.controller.project.layerById(before.id) ?? before;
    final proposed = current.rect.translate(delta.dx, delta.dy);
    if (HardwareKeyboard.instance.isShiftPressed) {
      widget.controller.previewLayer(current.copyWith(rect: proposed));
      widget.onGuides(const <SnapGuide>[]);
      return;
    }
    final snapped = SnapEngine.snapMove(
      rect: proposed,
      canvasWidth: widget.controller.project.canvas.width.toDouble(),
      canvasHeight: widget.controller.project.canvas.height.toDouble(),
      neighbors: widget.controller.project.layers
          .where((layer) => layer.id != before.id && !layer.hidden)
          .map((layer) => layer.rect)
          .toList(),
      gridSize: widget.controller.gridSize,
      safeFactor:
          widget.controller.project.canvas.height >
              widget.controller.project.canvas.width
          ? 0.8
          : 0.9,
      threshold: 8 / widget.scale,
    );
    widget.controller.previewLayer(current.copyWith(rect: snapped.rect));
    widget.onGuides(snapped.guides);
  }

  void _updateResize(DragUpdateDetails details) {
    final before = _before;
    final start = _startRect;
    final last = _lastGlobal;
    final handle = _handle;
    if (before == null || start == null || last == null || handle == null) {
      return;
    }
    final delta = (details.globalPosition - last) / widget.scale;
    _lastGlobal = details.globalPosition;
    final angle = -start.rotation * math.pi / 180;
    final dx = (delta.dx * math.cos(angle) - delta.dy * math.sin(angle));
    final dy = (delta.dx * math.sin(angle) + delta.dy * math.cos(angle));
    final centerMode = HardwareKeyboard.instance.isAltPressed;
    var x = start.x;
    var y = start.y;
    var width = start.width;
    var height = start.height;
    if (handle.$1 < 0) {
      width += centerMode ? -2 * dx : -dx;
      if (!centerMode) x += dx;
    } else if (handle.$1 > 0) {
      width += centerMode ? 2 * dx : dx;
    }
    if (handle.$2 < 0) {
      height += centerMode ? -2 * dy : -dy;
      if (!centerMode) y += dy;
    } else if (handle.$2 > 0) {
      height += centerMode ? 2 * dy : dy;
    }
    width = math.max(16, width).toDouble();
    height = math.max(16, height).toDouble();
    if (HardwareKeyboard.instance.isShiftPressed &&
        handle.$1 != 0 &&
        handle.$2 != 0) {
      final ratio = start.width / start.height;
      if ((width / start.width - 1).abs() > (height / start.height - 1).abs()) {
        height = width / ratio;
      } else {
        width = height * ratio;
      }
    }
    if (centerMode) {
      x = start.centerX - width / 2;
      y = start.centerY - height / 2;
    }
    final current = widget.controller.project.layerById(before.id) ?? before;
    widget.controller.previewLayer(
      current.copyWith(
        rect: SceneRect(
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: start.rotation,
        ),
      ),
    );
  }

  void _startRotate(DragStartDetails details) {
    _before = widget.layer;
    _startRect = widget.layer.rect;
    _rotationOffset =
        _pointerAngle(details.globalPosition) - widget.layer.rect.rotation;
  }

  void _updateRotate(DragUpdateDetails details) {
    final before = _before;
    if (before == null) {
      return;
    }
    var rotation = _pointerAngle(details.globalPosition) - _rotationOffset;
    if (HardwareKeyboard.instance.isShiftPressed) {
      rotation = (rotation / 15).round() * 15.0;
    }
    final current = widget.controller.project.layerById(before.id) ?? before;
    widget.controller.previewLayer(
      current.copyWith(rect: current.rect.copyWith(rotation: rotation)),
    );
  }

  double _pointerAngle(Offset global) {
    final rect =
        widget.controller.project.layerById(widget.layer.id)?.rect ??
        widget.layer.rect;
    final box =
        widget.canvasKey.currentContext!.findRenderObject() as RenderBox;
    final center = box.localToGlobal(
      Offset(rect.centerX * widget.scale, rect.centerY * widget.scale),
    );
    final delta = global - center;
    return math.atan2(delta.dy, delta.dx) * 180 / math.pi + 90;
  }

  void _endEdit(DragEndDetails details) {
    final before = _before;
    if (before != null) {
      final current = widget.controller.project.layerById(before.id);
      if (current != null) {
        widget.controller.commitLayerChange(before, current);
      }
    }
    _before = null;
    _startRect = null;
    _handle = null;
    _lastGlobal = null;
    widget.onGuides(const <SnapGuide>[]);
  }

  void _openContextMenu(TapDownDetails details) async {
    widget.controller.select(widget.layer.id);
    final l10n = AppLocalizations.of(context);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'duplicate', child: Text(l10n.duplicate)),
        PopupMenuItem<String>(value: 'copy', child: Text(l10n.copy)),
        PopupMenuItem<String>(value: 'paste', child: Text(l10n.paste)),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'forward', child: Text(l10n.bringForward)),
        PopupMenuItem<String>(
          value: 'backward',
          child: Text(l10n.sendBackward),
        ),
        const PopupMenuDivider(),
        for (final manifest in widget.controller.registry.manifests)
          if (manifest.id != widget.layer.widgetId)
            PopupMenuItem<String>(
              value: 'replace:${manifest.id}',
              child: Text(
                '${l10n.replaceWidget}: ${manifest.name.resolve(Localizations.localeOf(context).languageCode)}',
              ),
            ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'delete', child: Text(l10n.delete)),
      ],
    );
    if (action == null || !mounted) {
      return;
    }
    final layer = widget.controller.project.layerById(widget.layer.id);
    if (layer == null) {
      return;
    }
    final index = widget.controller.project.layers.indexWhere(
      (item) => item.id == layer.id,
    );
    if (action == 'duplicate') {
      widget.controller.duplicateSelected();
    } else if (action == 'copy') {
      widget.controller.copySelected();
    } else if (action == 'paste') {
      widget.controller.paste();
    } else if (action == 'forward' &&
        index < widget.controller.project.layers.length - 1) {
      widget.controller.moveLayer(index, index + 1);
    } else if (action == 'backward' && index > 0) {
      widget.controller.moveLayer(index, index - 1);
    } else if (action == 'delete') {
      widget.controller.deleteSelected();
    } else if (action.startsWith('replace:')) {
      widget.controller.replaceWidget(
        layer,
        widget.controller.registry.require(action.substring(8)),
      );
    }
  }
}

final class _EditorGuidesPainter extends CustomPainter {
  _EditorGuidesPainter({
    required this.controller,
    required this.scale,
    required this.guides,
  });
  final EditorController controller;
  final double scale;
  final List<SnapGuide> guides;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / scale;
    final height = size.height / scale;
    canvas.save();
    canvas.scale(scale);
    if (controller.showGrid) {
      final step = controller.gridSize.toDouble();
      if (step * scale >= 3) {
        final paint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.08)
          ..strokeWidth = 1 / scale;
        for (var x = 0.0; x <= width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
        }
        for (var y = 0.0; y <= height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(width, y), paint);
        }
      }
    }
    if (controller.showSafeArea) {
      final factor = height > width ? 0.8 : 0.9;
      final safeWidth = width * factor;
      final safeHeight = height * factor;
      canvas.drawRect(
        Rect.fromLTWH(
          (width - safeWidth) / 2,
          (height - safeHeight) / 2,
          safeWidth,
          safeHeight,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / scale
          ..color = const Color(0x80FFFFFF),
      );
    }
    final paint = Paint()
      ..color = const Color(0xFFFF537A)
      ..strokeWidth = 1 / scale;
    for (final guide in guides) {
      final start = guide.isVertical
          ? Offset(guide.position, guide.start)
          : Offset(guide.start, guide.position);
      final end = guide.isVertical
          ? Offset(guide.position, guide.end)
          : Offset(guide.end, guide.position);
      canvas.drawLine(start, end, paint);
      if (guide.distanceLabel != null) {
        final text = TextPainter(
          text: TextSpan(
            text: guide.distanceLabel,
            style: TextStyle(
              color: const Color(0xFFFF537A),
              fontSize: 14 / scale,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final midpoint = (start + end) / 2;
        final labelOffset = guide.isVertical
            ? midpoint + Offset(6 / scale, -text.height)
            : midpoint + Offset(6 / scale, -text.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            (labelOffset - const Offset(2, 2)) &
                Size(text.width + 4, text.height + 4),
            Radius.circular(3 / scale),
          ),
          Paint()..color = const Color(0xFF202028),
        );
        text.paint(canvas, labelOffset);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EditorGuidesPainter oldDelegate) => true;
}
