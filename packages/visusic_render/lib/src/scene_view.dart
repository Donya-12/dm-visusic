// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/src/scene_painter.dart';

/// A scene surface that can host editor overlays above the deterministic paint.
final class SceneView extends StatelessWidget {
  /// Creates a scene surface.
  const SceneView({
    required this.project,
    required this.features,
    this.images = const <String, ui.Image>{},
    this.expressionValues = const <String, Map<String, double>>{},
    this.child,
    super.key,
  });

  /// Scene document.
  final SceneProject project;

  /// Playback/demo feature frame.
  final FeatureSnapshot features;

  /// Decoded image assets.
  final Map<String, ui.Image> images;

  /// Evaluated expressions.
  final Map<String, Map<String, double>> expressionValues;

  /// Optional editor overlay.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: ScenePainter(
              project: project,
              features: features,
              images: images,
              expressionValues: expressionValues,
            ),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}
