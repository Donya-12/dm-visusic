// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_core/visusic_core.dart';

/// Reorderable back-to-front layer list with visibility and solo controls.
final class LayersPanel extends StatelessWidget {
  /// Creates the layer list.
  const LayersPanel({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final layers = controller.project.layers;
    if (layers.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noLayers));
    }
    final ordered = layers.reversed.toList(growable: false);
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ordered.length,
      onReorder: (oldIndex, newIndex) {
        final displayDestination = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final source = layers.length - 1 - oldIndex;
        final destination = layers.length - 1 - displayDestination;
        controller.moveLayer(source, destination);
      },
      itemBuilder: (context, index) {
        final layer = ordered[index];
        final sourceIndex = layers.indexWhere((item) => item.id == layer.id);
        final selected = controller.selectedIds.contains(layer.id);
        return _LayerTile(
          key: ValueKey<String>(layer.id),
          controller: controller,
          layer: layer,
          sourceIndex: index,
          selected: selected,
        );
      },
    );
  }
}

final class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.controller,
    required this.layer,
    required this.sourceIndex,
    required this.selected,
    super.key,
  });
  final EditorController controller;
  final SceneLayer layer;
  final int sourceIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _tagColor(layer.colorTag);
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      onTap: () => controller.select(layer.id),
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ReorderableDragStartListener(
            index: sourceIndex,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(Icons.drag_indicator_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              layer.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: layer.hidden ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (layer.muted) const Icon(Icons.volume_off_outlined, size: 14),
          if (layer.solo) const Icon(Icons.star_rounded, size: 14),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: layer.hidden ? l10n.show : l10n.hide,
            onPressed: () => controller.commitLayerChange(
              layer,
              layer.copyWith(hidden: !layer.hidden),
            ),
            icon: Icon(
              layer.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: layer.locked ? l10n.unlock : l10n.lock,
            onPressed: () => controller.commitLayerChange(
              layer,
              layer.copyWith(locked: !layer.locked),
            ),
            icon: Icon(
              layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 17,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.layerOptions,
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'mute',
                child: Text(layer.muted ? l10n.unmute : l10n.mute),
              ),
              PopupMenuItem<String>(
                value: 'solo',
                child: Text(layer.solo ? l10n.unsolo : l10n.solo),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'default', child: Text('Default')),
              const PopupMenuItem<String>(value: 'violet', child: Text('Violet')),
              const PopupMenuItem<String>(value: 'mint', child: Text('Mint')),
              const PopupMenuItem<String>(value: 'amber', child: Text('Amber')),
              const PopupMenuItem<String>(value: 'rose', child: Text('Rose')),
            ],
            onSelected: (action) {
              if (<String>['default', 'violet', 'mint', 'amber', 'rose'].contains(action)) {
                controller.commitLayerChange(layer, layer.copyWith(colorTag: action));
              } else if (action == 'mute') {
                controller.commitLayerChange(layer, layer.copyWith(muted: !layer.muted));
              } else if (action == 'solo') {
                controller.commitLayerChange(layer, layer.copyWith(solo: !layer.solo));
              }
            },
          ),
        ],
      ),
    );
  }

  Color _tagColor(String tag) => switch (tag) {
    'violet' => const Color(0xFF9B7BFF),
    'mint' => const Color(0xFF3DDC97),
    'amber' => const Color(0xFFFFD84D),
    'rose' => const Color(0xFFFF7A90),
    _ => Theme.of(context).colorScheme.outlineVariant,
  };
}
