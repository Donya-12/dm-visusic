// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/export/scene_export.dart';
import 'package:visusic/platform/ffmpeg_video_encoder.dart';
import 'package:visusic_platform/visusic_platform.dart';

/// Export wizard with deterministic scene rendering and progress.
final class ExportDialog extends StatefulWidget {
  /// Creates the dialog.
  const ExportDialog({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _container = 'mp4';
  String _resolution = 'canvas';
  int _fps = 30;
  bool _exporting = false;
  double _progress = 0;
  bool _cancelled = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.export),
      content: SizedBox(
        width: 420,
        child: _exporting ? _progressView(l10n) : _settingsView(l10n),
      ),
      actions: _exporting
          ? <Widget>[
              TextButton(
                onPressed: () => setState(() => _cancelled = true),
                child: Text(l10n.cancel),
              ),
            ]
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.movie_outlined),
                label: Text(l10n.export),
              ),
            ],
    );
  }

  Widget _settingsView(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _container,
          decoration: InputDecoration(labelText: l10n.exportFormat),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'mp4', child: Text('MP4 (H.264)')),
            DropdownMenuItem<String>(value: 'webm', child: Text('WebM (VP9)')),
          ],
          onChanged: (value) => setState(() => _container = value ?? 'mp4'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _resolution,
          decoration: InputDecoration(labelText: l10n.exportResolution),
          items: <DropdownMenuItem<String>>[
            for (final preset in _resolutions)
              DropdownMenuItem<String>(
                value: preset.$1,
                child: Text(preset.$2),
              ),
          ],
          onChanged: (value) => setState(() => _resolution = value ?? 'canvas'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _fps,
          decoration: InputDecoration(labelText: l10n.exportFps),
          items: const <DropdownMenuItem<int>>[
            DropdownMenuItem<int>(value: 24, child: Text('24 fps')),
            DropdownMenuItem<int>(value: 30, child: Text('30 fps')),
            DropdownMenuItem<int>(value: 60, child: Text('60 fps')),
          ],
          onChanged: (value) => setState(() => _fps = value ?? 30),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }

  Widget _progressView(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(l10n.exporting, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 8),
        Text('${(_progress * 100).round()}%'),
      ],
    );
  }

  List<(String, String)> get _resolutions {
    final canvas = widget.controller.project.canvas;
    final ratio = canvas.width / canvas.height;
    return <(String, String)>[
      ('canvas', '${canvas.width} × ${canvas.height} (scene)'),
      ('720', '${(1280).round()} × ${(1280 / ratio).round()} (720p)'),
      ('1080', '${1920} × ${(1920 / ratio).round()} (1080p)'),
      ('2160', '${3840} × ${(3840 / ratio).round()} (2160p)'),
    ];
  }

  Future<void> _start() async {
    final suggested = '${widget.controller.project.name}.$_container';
    final location = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(label: 'Video', extensions: <String>[_container]),
      ],
    );
    if (location == null) {
      return;
    }
    final (width, height) = _resolution == 'canvas'
        ? (widget.controller.project.canvas.width, widget.controller.project.canvas.height)
        : _scaledSize(_resolution);
    setState(() {
      _exporting = true;
      _cancelled = false;
      _progress = 0;
      _error = null;
    });
    try {
      final service = SceneExportService(
        project: widget.controller.project,
        registry: widget.controller.registry,
        cache: widget.controller.analysisCache,
        lyrics: widget.controller.lyricsTrack,
        images: widget.controller.images,
      );
      await service.export(
        settings: ExportSettings(
          width: width,
          height: height,
          fps: _fps,
          container: _container,
        ),
        encoder: const FfmpegVideoEncoder(),
        outputPath: location.path,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        isCancelled: () => _cancelled,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _exporting = false;
          _error = error.toString();
        });
      }
    }
  }

  (int, int) _scaledSize(String preset) {
    final canvas = widget.controller.project.canvas;
    final ratio = canvas.width / canvas.height;
    final targetWidth = switch (preset) {
      '720' => 1280,
      '1080' => 1920,
      _ => 3840,
    };
    return (targetWidth, (targetWidth / ratio).round());
  }
}
