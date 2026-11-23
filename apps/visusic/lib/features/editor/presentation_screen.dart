// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_render/visusic_render.dart';

/// Full-screen playback preview without editor chrome.
final class PresentationScreen extends StatelessWidget {
  /// Creates the presentation screen.
  const PresentationScreen({required this.controller, super.key});

  /// Editor state supplying the scene and playback.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SceneView(
              project: controller.project,
              features: controller.features,
              images: controller.images,
              expressionValues: controller.expressionValues,
              shaderPrograms: controller.shaderPrograms,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: IconButton.filled(
              tooltip: controller.playing ? 'Pause' : 'Play',
              onPressed: controller.togglePlayback,
              icon: Icon(
                controller.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: IconButton.filledTonal(
              tooltip: 'Exit',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
