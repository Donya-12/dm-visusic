// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/library/scene_presets.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/visusic_render.dart';

/// Templates page: ready scenes plus `.vspack` import and export.
final class TemplatesDialog extends StatefulWidget {
  /// Creates the dialog.
  const TemplatesDialog({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  State<TemplatesDialog> createState() => _TemplatesDialogState();
}

class _TemplatesDialogState extends State<TemplatesDialog> {
  WidgetPack? _imported;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.templates),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(l10n.importPack),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: Text(l10n.exportPack),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _imported == null
                  ? _sceneGrid(l10n)
                  : _importedGrid(l10n),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _sceneGrid(AppLocalizations l10n) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: ScenePresets.all.length,
      itemBuilder: (context, index) {
        final preset = ScenePresets.all[index];
        return _SceneCard(
          title: preset.name,
          project: preset,
          onApply: () {
            widget.controller.applyScene(preset);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _importedGrid(AppLocalizations l10n) {
    final pack = _imported!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${pack.name} · ${pack.version} · ${pack.author}',
            style: Theme.of(context).textTheme.titleMedium),
        if (pack.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(pack.description!),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
            ),
            itemCount: pack.scenes.length,
            itemBuilder: (context, index) {
              final scene = pack.scenes[index];
              return _SceneCard(
                title: scene.name,
                project: scene,
                onApply: () {
                  widget.controller.applyScene(scene);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _import() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'VisuSic pack', extensions: <String>['vspack']),
      ],
    );
    if (file == null) {
      return;
    }
    try {
      final pack = PackCodec.decode(await file.readAsBytes());
      setState(() {
        _imported = pack;
        _error = null;
      });
    } on Object catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _export() async {
    final pack = WidgetPack(
      name: widget.controller.project.name,
      version: '1.0.0',
      author: 'Donya',
      manifests: const <WidgetManifest>[],
      scenes: <SceneProject>[widget.controller.project],
    );
    final bytes = PackCodec.encode(pack);
    final location = await getSaveLocation(
      suggestedName: '${widget.controller.project.name}.vspack',
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'VisuSic pack', extensions: <String>['vspack']),
      ],
    );
    if (location != null) {
      final data = XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/zip');
      await data.saveTo(location.path);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

final class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.title,
    required this.project,
    required this.onApply,
  });
  final String title;
  final SceneProject project;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onApply,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SceneView(
                project: project,
                features: FeatureSnapshot.demo(1.0, project.canvas.duration),
              ),
            ),
            ListTile(
              dense: true,
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.check_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
