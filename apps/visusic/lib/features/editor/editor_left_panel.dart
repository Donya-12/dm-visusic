// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic/features/editor/layers_panel.dart';
import 'package:visusic/features/editor/widget_library.dart';

/// Widget library and layer list in one compact left-side panel.
final class EditorLeftPanel extends StatelessWidget {
  /// Creates the left panel.
  const EditorLeftPanel({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: <Tab>[
              Tab(text: l10n.widgets),
              Tab(text: l10n.layers),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                WidgetLibraryPanel(controller: controller),
                LayersPanel(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
