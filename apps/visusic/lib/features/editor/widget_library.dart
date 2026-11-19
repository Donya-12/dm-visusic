// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/visusic_render.dart';

/// Searchable, categorized widget cards with click and drag insertion.
final class WidgetLibraryPanel extends StatefulWidget {
  /// Creates the widget library.
  const WidgetLibraryPanel({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  State<WidgetLibraryPanel> createState() => _WidgetLibraryPanelState();
}

class _WidgetLibraryPanelState extends State<WidgetLibraryPanel> {
  final TextEditingController _search = TextEditingController();
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final query = _search.text.trim().toLowerCase();
    final manifests = widget.controller.registry.manifests
        .where((manifest) {
          final matchesCategory =
              _category == 'all' || manifest.category == _category;
          final name = manifest.name.resolve(language).toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              name.contains(query) ||
              manifest.name.english.toLowerCase().contains(query) ||
              manifest.tags.any((tag) => tag.toLowerCase().contains(query));
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: const Key('widget-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.searchWidgets,
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: <Widget>[
              for (final category in const <String>[
                'all',
                'basic',
                'text',
                'audio',
                'background',
                'meta',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(l10n, category)),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: manifests.isEmpty
              ? Center(child: Text(l10n.noWidgetsFound))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: manifests.length,
                  itemBuilder: (context, index) {
                    final manifest = manifests[index];
                    return _LibraryCard(
                      key: ValueKey<String>(manifest.id),
                      controller: widget.controller,
                      manifest: manifest,
                      languageCode: language,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _categoryLabel(AppLocalizations l10n, String category) =>
      switch (category) {
        'all' => l10n.all,
        'basic' => l10n.categoryBasic,
        'text' => l10n.categoryText,
        'audio' => l10n.categoryAudio,
        'background' => l10n.categoryBackground,
        _ => l10n.categoryMeta,
      };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

final class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.controller,
    required this.manifest,
    required this.languageCode,
    super.key,
  });
  final EditorController controller;
  final WidgetManifest manifest;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final preview = _ManifestPreview(manifest: manifest);
    return Tooltip(
      message: '${manifest.id} · ${manifest.version}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Draggable<WidgetManifest>(
          data: manifest,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 180, height: 112, child: preview),
          ),
          childWhenDragging: Opacity(
            opacity: 0.45,
            child: _cardContent(context, preview),
          ),
          child: InkWell(
            key: Key('add-${manifest.id}'),
            onTap: () => controller.addWidget(manifest),
            child: _cardContent(context, preview),
          ),
        ),
      ),
    );
  }

  Widget _cardContent(BuildContext context, Widget preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(aspectRatio: 16 / 9, child: preview),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    manifest.name.resolve(languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                if (manifest.tags.contains('new'))
                  Text(
                    AppLocalizations.of(context).newBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _ManifestPreview extends StatelessWidget {
  const _ManifestPreview({required this.manifest});
  final WidgetManifest manifest;

  @override
  Widget build(BuildContext context) {
    final fill = manifest.anchor == 'fill';
    final layer = SceneLayer(
      id: 'preview',
      widgetId: manifest.id,
      name: manifest.name.english,
      rect: fill
          ? const SceneRect(x: 0, y: 0, width: 480, height: 270)
          : const SceneRect(x: 30, y: 45, width: 420, height: 180),
      params: manifest.defaultParams(),
    );
    final project = SceneProject(
      name: 'Preview',
      canvas: const SceneCanvas(width: 480, height: 270, aspect: '16:9'),
      layers: <SceneLayer>[layer],
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: parseSceneColor('#101014')),
      child: SceneView(
        project: project,
        features: FeatureSnapshot.demo(1.4, 30),
      ),
    );
  }
}

/// Search dialog opened by the W shortcut.
final class WidgetPalette extends StatefulWidget {
  /// Creates a palette.
  const WidgetPalette({required this.registry, super.key});

  /// Searchable manifests.
  final ManifestRegistry registry;

  @override
  State<WidgetPalette> createState() => _WidgetPaletteState();
}

class _WidgetPaletteState extends State<WidgetPalette> {
  final TextEditingController _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final query = _search.text.toLowerCase().trim();
    final results = widget.registry.manifests
        .where((manifest) {
          return query.isEmpty ||
              manifest.name.resolve(language).toLowerCase().contains(query) ||
              manifest.tags.any((tag) => tag.contains(query));
        })
        .toList(growable: false);
    return AlertDialog(
      title: Text(l10n.addWidget),
      content: SizedBox(
        width: 420,
        height: 480,
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.searchWidgets,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: <Widget>[
                  for (final manifest in results)
                    ListTile(
                      key: Key('palette-${manifest.id}'),
                      title: Text(manifest.name.resolve(language)),
                      subtitle: Text(manifest.tags.join(' · ')),
                      onTap: () => Navigator.of(context).pop(manifest),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
