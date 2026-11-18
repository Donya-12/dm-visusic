// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/visusic_core.dart';

/// Common scene dimensions plus user-defined logical sizes.
abstract final class AspectPresets {
  /// Named preset canvases.
  static const List<SceneCanvas> values = <SceneCanvas>[
    SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
    SceneCanvas(width: 1080, height: 1920, aspect: '9:16'),
    SceneCanvas(width: 1080, height: 1080, aspect: '1:1'),
    SceneCanvas(width: 1080, height: 1350, aspect: '4:5'),
    SceneCanvas(width: 1080, height: 1440, aspect: '3:4'),
    SceneCanvas(width: 2560, height: 1080, aspect: '21:9'),
    SceneCanvas(width: 1440, height: 1080, aspect: '4:3'),
    SceneCanvas(width: 1920, height: 960, aspect: '2:1'),
    SceneCanvas(width: 1080, height: 2520, aspect: '9:21'),
  ];

  /// Returns a preset or null for custom dimensions.
  static SceneCanvas? byAspect(String aspect) {
    for (final preset in values) {
      if (preset.aspect == aspect) {
        return preset;
      }
    }
    return null;
  }
}
