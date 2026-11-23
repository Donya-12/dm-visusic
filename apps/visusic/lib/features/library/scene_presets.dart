// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

/// Ready-to-apply scene presets shipped with the application.
abstract final class ScenePresets {
  /// Built-in presets.
  static List<SceneProject> get all => <SceneProject>[
    SceneProject(
      name: 'Minimal Lyrics',
      canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1920, 1080),
        _layer('spectrum', BuiltinWidgetIds.barSpectrum, 480, 800, 960, 200),
        _layer('lyrics', BuiltinWidgetIds.karaoke, 260, 460, 1400, 240),
      ],
    ),
    SceneProject(
      name: 'TikTok Vertical',
      canvas: const SceneCanvas(width: 1080, height: 1920, aspect: '9:16'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1080, 1920),
        _layer('art', BuiltinWidgetIds.albumArt, 240, 320, 600, 600),
        _layer('title', BuiltinWidgetIds.title, 40, 1100, 1000, 260),
      ],
    ),
    SceneProject(
      name: 'Retro VHS',
      canvas: const SceneCanvas(width: 1440, height: 1080, aspect: '4:3'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1440, 1080),
        _layer('title', BuiltinWidgetIds.title, 120, 380, 1200, 260),
        _layer('progress', BuiltinWidgetIds.progress, 220, 940, 1000, 80),
      ],
    ),
    SceneProject(
      name: 'Lo-fi Study',
      canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1920, 1080),
        _layer('particles', BuiltinWidgetIds.particles, 0, 0, 1920, 1080),
        _layer('title', BuiltinWidgetIds.title, 460, 420, 1000, 240),
      ],
    ),
    SceneProject(
      name: 'Spectrum Focus',
      canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1920, 1080),
        _layer('spectrum', BuiltinWidgetIds.barSpectrum, 160, 320, 1600, 440),
        _layer('title', BuiltinWidgetIds.text, 660, 140, 600, 120),
      ],
    ),
    SceneProject(
      name: 'Podcast / Radio',
      canvas: const SceneCanvas(width: 1080, height: 1080, aspect: '1:1'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1080, 1080),
        _layer('art', BuiltinWidgetIds.albumArt, 240, 200, 600, 600),
        _layer('text', BuiltinWidgetIds.text, 240, 860, 600, 120),
      ],
    ),
    SceneProject(
      name: 'Cinematic',
      canvas: const SceneCanvas(width: 2560, height: 1080, aspect: '21:9'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 2560, 1080),
        _layer('title', BuiltinWidgetIds.title, 680, 360, 1200, 260),
        _layer('progress', BuiltinWidgetIds.progress, 780, 880, 1000, 80),
      ],
    ),
    SceneProject(
      name: 'Neon Grid',
      canvas: const SceneCanvas(width: 1080, height: 1080, aspect: '1:1'),
      layers: <SceneLayer>[
        _layer('bg', BuiltinWidgetIds.meshGradient, 0, 0, 1080, 1080),
        _layer('particles', BuiltinWidgetIds.particles, 0, 0, 1080, 1080),
        _layer('text', BuiltinWidgetIds.text, 240, 470, 600, 140),
      ],
    ),
  ];

  static SceneLayer _layer(
    String id,
    String widgetId,
    double x,
    double y,
    double width,
    double height,
  ) => SceneLayer(
    id: id,
    widgetId: widgetId,
    name: id,
    rect: SceneRect(x: x, y: y, width: width, height: height),
  );
}
