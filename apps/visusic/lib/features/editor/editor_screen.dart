// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/aspect_presets.dart';
import 'package:visusic/features/editor/editor_canvas.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/editor/editor_left_panel.dart';
import 'package:visusic/features/editor/inspector_panel.dart';
import 'package:visusic/features/editor/timeline_panel.dart';
import 'package:visusic/features/editor/widget_library.dart';
import 'package:visusic/features/export/export_dialog.dart';
import 'package:visusic/features/lyrics/lyrics_dialog.dart';
import 'package:visusic/platform/file_project_storage.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_platform/visusic_platform.dart';

/// Complete M1–M2 scene editor screen.
final class EditorScreen extends StatefulWidget {
  /// Creates an editor with optional platform and state overrides for tests.
  const EditorScreen({
    required this.registry,
    this.storage,
    this.controller,
    super.key,
  });

  /// Validated widget library.
  final ManifestRegistry registry;

  /// Optional host file implementation.
  final ProjectStorage? storage;

  /// Optional preloaded controller.
  final EditorController? controller;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late final EditorController _controller;
  late final Ticker _ticker;
  late final bool _ownsController;
  bool _recoveryChecked = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
              EditorController(
                registry: widget.registry,
                storage: widget.storage ?? FileProjectStorage(),
              )
          ..startAutosave();
    _controller.addListener(_syncTicker);
    _ticker = createTicker(_controller.tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerRecovery());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            _perform(_controller.save),
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): () =>
            _perform(() => _controller.save(saveAs: true)),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _openProject,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            _controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            _controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            _controller.duplicateSelected,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            _controller.copySelected,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _controller.paste,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _controller.selectAll,
        const SingleActivator(LogicalKeyboardKey.keyW): _openPalette,
        const SingleActivator(LogicalKeyboardKey.delete):
            _controller.deleteSelected,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _controller.select(null),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _nudge(const Offset(-1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _nudge(const Offset(1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _nudge(const Offset(0, -1)),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _nudge(const Offset(0, 1)),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _addPrimaryKeyframe,
        const SingleActivator(LogicalKeyboardKey.slash, shift: true):
            _showShortcuts,
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _requestClose();
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    tooltip: l10n.close,
                    onPressed: _requestClose,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  titleSpacing: 8,
                  title: InkWell(
                    onTap: _renameProject,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _controller.project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_controller.dirty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    DropdownButton<String>(
                      key: const Key('aspect-selector'),
                      value: _controller.project.canvas.aspect,
                      underline: const SizedBox.shrink(),
                      items: <DropdownMenuItem<String>>[
                        for (final preset in AspectPresets.values)
                          DropdownMenuItem<String>(
                            value: preset.aspect,
                            child: Text(preset.aspect),
                          ),
                        const DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: _changeAspect,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const Key('undo-button'),
                      tooltip: l10n.undo,
                      onPressed: _controller.canUndo ? _controller.undo : null,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    IconButton(
                      key: const Key('redo-button'),
                      tooltip: l10n.redo,
                      onPressed: _controller.canRedo ? _controller.redo : null,
                      icon: const Icon(Icons.redo_rounded),
                    ),
                    IconButton(
                      key: const Key('load-audio-button'),
                      tooltip: l10n.loadAudio,
                      onPressed: _controller.busy
                          ? null
                          : () => _perform(
                              _controller.openAudioFile,
                              showSuccess: false,
                            ),
                      icon: const Icon(Icons.music_note_outlined),
                    ),
                    IconButton(
                      key: const Key('lyrics-button'),
                      tooltip: l10n.lyrics,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => LyricsDialog(controller: _controller),
                      ),
                      icon: const Icon(Icons.lyrics_outlined),
                    ),
                    IconButton(
                      key: const Key('export-button'),
                      tooltip: l10n.export,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => ExportDialog(controller: _controller),
                      ),
                      icon: const Icon(Icons.movie_outlined),
                    ),
                    IconButton(
                      key: const Key('open-button'),
                      tooltip: l10n.openProject,
                      onPressed: _controller.busy ? null : _openProject,
                      icon: const Icon(Icons.folder_open_outlined),
                    ),
                    IconButton(
                      key: const Key('save-button'),
                      tooltip: l10n.save,
                      onPressed: _controller.busy
                          ? null
                          : () => _perform(_controller.save),
                      icon: const Icon(Icons.save_outlined),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'saveAs') {
                          _perform(() => _controller.save(saveAs: true));
                        } else if (action == 'shortcuts') {
                          _showShortcuts();
                        }
                      },
                      itemBuilder: (_) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'saveAs',
                          child: Text(l10n.saveAs),
                        ),
                        PopupMenuItem<String>(
                          value: 'shortcuts',
                          child: Text(l10n.shortcuts),
                        ),
                      ],
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Column(
                    children: <Widget>[
                      if (_controller.busy)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 280,
                              child: EditorLeftPanel(controller: _controller),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: EditorCanvas(
                                controller: _controller,
                                onOpenPalette: _openPalette,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: 320,
                              child: InspectorPanel(controller: _controller),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 170,
                        child: TimelinePanel(controller: _controller),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openPalette() async {
    if (!_editorHasFocus) {
      return;
    }
    final manifest = await showDialog<WidgetManifest>(
      context: context,
      builder: (_) => WidgetPalette(registry: widget.registry),
    );
    if (manifest != null) {
      _controller.addWidget(manifest);
    }
  }

  void _nudge(Offset delta) {
    if (_editorHasFocus) {
      final multiplier = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
      _controller.nudge(delta * multiplier);
    }
  }

  void _addPrimaryKeyframe() {
    final layer = _controller.selectedLayer;
    if (layer == null) {
      return;
    }
    final manifest = _controller.registry.require(layer.widgetId);
    for (final parameter in manifest.primaryParameters()) {
      if (parameter.type == ParameterType.float ||
          parameter.type == ParameterType.integer) {
        _controller.addKeyframe(layer, parameter.id);
        return;
      }
    }
  }

  Future<void> _changeAspect(String? aspect) async {
    if (aspect == null || aspect == _controller.project.canvas.aspect) {
      return;
    }
    if (aspect == 'custom') {
      await _showCustomAspect();
      return;
    }
    final preset = AspectPresets.byAspect(aspect);
    if (preset != null) {
      _controller.changeCanvas(preset);
    }
  }

  Future<void> _showCustomAspect() async {
    final width = TextEditingController(
      text: _controller.project.canvas.width.toString(),
    );
    final height = TextEditingController(
      text: _controller.project.canvas.height.toString(),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.customAspect),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: width,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.logicalWidth),
              ),
              TextField(
                controller: height,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.logicalHeight),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      final w = int.tryParse(width.text);
      final h = int.tryParse(height.text);
      if (w != null &&
          h != null &&
          w >= 16 &&
          h >= 16 &&
          w <= 8192 &&
          h <= 8192) {
        _controller.changeCanvas(
          SceneCanvas(width: w, height: h, aspect: 'custom'),
        );
      }
    }
    width.dispose();
    height.dispose();
  }

  Future<void> _renameProject() async {
    final name = TextEditingController(text: _controller.project.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.projectName),
          content: TextField(controller: name, autofocus: true),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(name.text),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
    if (result != null) {
      _controller.renameProject(result);
    }
    name.dispose();
  }

  Future<void> _openProject() async {
    if (!await _ensureCanLeave()) {
      return;
    }
    await _perform(_controller.open);
  }

  Future<bool> _ensureCanLeave() async {
    if (!_controller.dirty) {
      return true;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.unsavedTitle),
          content: Text(l10n.unsavedBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text(l10n.keepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('discard'),
              child: Text(l10n.discard),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: Text(l10n.saveAndClose),
            ),
          ],
        );
      },
    );
    if (action == 'discard') {
      return true;
    }
    if (action == 'save') {
      final path = await _perform(_controller.save, showSuccess: false);
      return path != null && !_controller.dirty;
    }
    return false;
  }

  Future<void> _requestClose() async {
    if (await _ensureCanLeave() && mounted && !_allowPop) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  Future<T?> _perform<T>(
    Future<T> Function() action, {
    bool showSuccess = true,
  }) async {
    try {
      final result = await action();
      if (mounted && showSuccess && result is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saved)),
        );
      }
      return result;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return null;
    }
  }

  Future<void> _offerRecovery() async {
    if (_recoveryChecked || _controller.project.layers.isNotEmpty) {
      return;
    }
    _recoveryChecked = true;
    try {
      final recovery = await _controller.readRecovery();
      if (recovery == null || !mounted) {
        return;
      }
      final action = await showDialog<String>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.recoveryTitle),
            content: Text(l10n.recoveryBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop('discard'),
                child: Text(l10n.dismiss),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('restore'),
                child: Text(l10n.restore),
              ),
            ],
          );
        },
      );
      if (action == 'restore') {
        await _perform(_controller.recover, showSuccess: false);
      } else if (action == 'discard') {
        await _controller.discardRecovery();
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _showShortcuts() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).shortcuts),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('W — Add widget'),
              Text('Ctrl+Z / Ctrl+Y — Undo / Redo'),
              Text('Ctrl+D — Duplicate'),
              Text('Ctrl+C / Ctrl+V — Copy / Paste'),
              Text('Ctrl+K — Add keyframe'),
              Text('Ctrl+O / Ctrl+S — Open / Save'),
              Text('Ctrl+Shift+S — Save As'),
              Text('Ctrl+A / Delete / Esc — Select all / Delete / Deselect'),
              Text('Arrows / Shift+Arrows — Nudge 1 / 10 px'),
              Text('Shift — Aspect ratio, rotation steps, disable snapping'),
              Text('Alt — Resize from center'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  bool get _editorHasFocus {
    final focus = FocusManager.instance.primaryFocus;
    final editable = focus?.context
        ?.findAncestorWidgetOfExactType<EditableText>();
    return editable == null;
  }

  void _syncTicker() {
    if (_controller.playing && !_ticker.isActive) {
      _ticker.start();
    } else if (!_controller.playing && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.removeListener(_syncTicker);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }
}
