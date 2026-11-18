// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/src/scene_models.dart';

/// A magnetic alignment guide drawn by the editor.
final class SnapGuide {
  /// Creates a guide.
  const SnapGuide({
    required this.position,
    required this.isVertical,
    required this.start,
    required this.end,
    this.distanceLabel,
  });

  /// X for vertical guides, Y for horizontal guides.
  final double position;

  /// Whether this is a vertical guide.
  final bool isVertical;

  /// Start coordinate along the guide.
  final double start;

  /// End coordinate along the guide.
  final double end;

  /// Optional distance annotation in logical pixels.
  final String? distanceLabel;
}

/// Result of magnetic placement.
final class SnapResult {
  /// Creates a snap result.
  const SnapResult(this.rect, this.guides);

  /// Adjusted rectangle.
  final SceneRect rect;

  /// Active alignment guides.
  final List<SnapGuide> guides;
}

/// Grid, safe-area, and neighbor snapping shared by move and drop operations.
abstract final class SnapEngine {
  /// Snaps a proposed rectangle without changing its dimensions or rotation.
  static SnapResult snapMove({
    required SceneRect rect,
    required double canvasWidth,
    required double canvasHeight,
    List<SceneRect> neighbors = const <SceneRect>[],
    int gridSize = 8,
    double safeFactor = 0.9,
    double threshold = 8,
    bool useGrid = true,
  }) {
    var x = rect.x;
    var y = rect.y;
    var bestX = threshold;
    var bestY = threshold;
    double? guideX;
    double? guideY;
    var distanceX = 0.0;
    var distanceY = 0.0;

    if (useGrid && gridSize > 0) {
      x = (x / gridSize).round() * gridSize.toDouble();
      y = (y / gridSize).round() * gridSize.toDouble();
    }
    var candidate = rect.copyWith(x: x, y: y);

    final safeWidth = canvasWidth * safeFactor;
    final safeHeight = canvasHeight * safeFactor;
    final verticalTargets = <double>[
      (canvasWidth - safeWidth) / 2,
      canvasWidth / 2,
      (canvasWidth + safeWidth) / 2,
      for (final neighbor in neighbors) ...<double>[
        neighbor.x,
        neighbor.centerX,
        neighbor.right,
      ],
    ];
    final horizontalTargets = <double>[
      (canvasHeight - safeHeight) / 2,
      canvasHeight / 2,
      (canvasHeight + safeHeight) / 2,
      for (final neighbor in neighbors) ...<double>[
        neighbor.y,
        neighbor.centerY,
        neighbor.bottom,
      ],
    ];

    for (final target in verticalTargets) {
      for (final anchor in <double>[
        candidate.x,
        candidate.centerX,
        candidate.right,
      ]) {
        final delta = target - anchor;
        if (delta.abs() < bestX) {
          bestX = delta.abs();
          distanceX = delta;
          guideX = target;
        }
      }
    }
    for (final target in horizontalTargets) {
      for (final anchor in <double>[
        candidate.y,
        candidate.centerY,
        candidate.bottom,
      ]) {
        final delta = target - anchor;
        if (delta.abs() < bestY) {
          bestY = delta.abs();
          distanceY = delta;
          guideY = target;
        }
      }
    }

    x += distanceX;
    y += distanceY;
    candidate = candidate.copyWith(x: x, y: y);
    final guides = <SnapGuide>[
      if (guideX != null)
        SnapGuide(
          position: guideX,
          isVertical: true,
          start: 0,
          end: canvasHeight,
          distanceLabel: _distanceLabel(candidate, verticalTargets, true),
        ),
      if (guideY != null)
        SnapGuide(
          position: guideY,
          isVertical: false,
          start: 0,
          end: canvasWidth,
          distanceLabel: _distanceLabel(candidate, horizontalTargets, false),
        ),
    ];
    return SnapResult(candidate, List.unmodifiable(guides));
  }

  static String _distanceLabel(
    SceneRect rect,
    List<double> targets,
    bool vertical,
  ) {
    final anchors = vertical
        ? <double>[rect.x, rect.centerX, rect.right]
        : <double>[rect.y, rect.centerY, rect.bottom];
    var distance = double.infinity;
    for (final target in targets) {
      for (final anchor in anchors) {
        final current = (target - anchor).abs();
        if (current < distance) {
          distance = current;
        }
      }
    }
    return distance.isFinite ? '${distance.round()} px' : '0 px';
  }
}
