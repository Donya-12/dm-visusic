// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/src/scene_models.dart';

/// Deterministic numeric parameter interpolation.
abstract final class KeyframeAnimation {
  /// Resolves the base value or the surrounding cubic-bezier keyframes.
  static Object? valueAt(SceneLayer layer, String parameterId, double timeMs) {
    final base = layer.params[parameterId];
    final frames = layer.keyframes[parameterId];
    if (frames == null || frames.isEmpty || base is! num) {
      return base;
    }
    final sorted = [...frames]..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    if (timeMs <= sorted.first.timeMs) {
      return sorted.first.value;
    }
    if (timeMs >= sorted.last.timeMs) {
      return sorted.last.value;
    }
    for (var index = 0; index < sorted.length - 1; index++) {
      final start = sorted[index];
      final end = sorted[index + 1];
      if (timeMs >= start.timeMs && timeMs <= end.timeMs) {
        final duration = end.timeMs - start.timeMs;
        final linear = duration <= 0 ? 1.0 : (timeMs - start.timeMs) / duration;
        final progress = _bezierYAtX(linear, start.curve);
        return start.value + (end.value - start.value) * progress;
      }
    }
    return base;
  }

  static double _bezierYAtX(double x, List<double> curve) {
    if (curve.length != 4) {
      return x;
    }
    final x1 = curve[0].clamp(0.0, 1.0).toDouble();
    final y1 = curve[1];
    final x2 = curve[2].clamp(0.0, 1.0).toDouble();
    final y2 = curve[3];
    var lower = 0.0;
    var upper = 1.0;
    var t = x;
    for (var iteration = 0; iteration < 18; iteration++) {
      final currentX = _bezierCoordinate(t, x1, x2);
      if ((currentX - x).abs() < 0.00001) {
        break;
      }
      if (currentX < x) {
        lower = t;
      } else {
        upper = t;
      }
      t = (lower + upper) / 2;
    }
    return _bezierCoordinate(t, y1, y2);
  }

  static double _bezierCoordinate(double t, double p1, double p2) {
    final inverse = 1 - t;
    return 3 * inverse * inverse * t * p1 +
        3 * inverse * t * t * p2 +
        t * t * t;
  }
}
