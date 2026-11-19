// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/lyrics/lrclib_client.dart';

/// Import and search dialog for synchronized lyrics.
final class LyricsDialog extends StatefulWidget {
  /// Creates the dialog.
  const LyricsDialog({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  State<LyricsDialog> createState() => _LyricsDialogState();
}

class _LyricsDialogState extends State<LyricsDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _artist = TextEditingController();
  final LrclibClient _client = LrclibClient();
  List<LrclibResult> _results = const <LrclibResult>[];
  bool _searching = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.lyrics),
      content: SizedBox(
        width: 460,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await widget.controller.importLyricsFile();
                  if (context.mounted) Navigator.of(context).pop();
                } on Object catch (error) {
                  setState(() => _error = error.toString());
                }
              },
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.importLyrics),
            ),
            const Divider(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _title,
                    decoration: InputDecoration(labelText: l10n.lyricsTitle),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _artist,
                    decoration: InputDecoration(labelText: l10n.lyricsArtist),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _searching ? null : _search,
              icon: const Icon(Icons.search_rounded),
              label: Text(l10n.searchLyrics),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(l10n.noLyricsFound))
                  : ListView(
                      children: <Widget>[
                        for (final result in _results)
                          ListTile(
                            title: Text(result.title),
                            subtitle: Text(
                              '${result.artist} · ${result.duration?.round() ?? 0}s',
                            ),
                            onTap: () {
                              widget.controller.setLyricsFromText(
                                result.syncedLyrics ?? result.plainLyrics ?? '',
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
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

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _client.search(
        _title.text.trim(),
        _artist.text.trim(),
      );
      if (mounted) {
        setState(() => _results = results);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _client.close();
    super.dispose();
  }
}
