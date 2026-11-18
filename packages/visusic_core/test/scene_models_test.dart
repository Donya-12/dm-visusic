// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('project JSON round-trip preserves layers and timing', () {
    final layer = SceneLayer(
      id: 'layer-1',
      widgetId: 'builtin.text',
      name: 'Title',
      rect: const SceneRect(x: 20, y: 40, width: 320, height: 90, rotation: 8),
      params: const <String, Object?>{'text': 'Hello', 'size': 56},
      keyframes: const <String, List<SceneKeyframe>>{
        'size': <SceneKeyframe>[
          SceneKeyframe(timeMs: 0, value: 20),
          SceneKeyframe(timeMs: 1000, value: 56),
        ],
      },
      timing: const LayerTiming(
        inMs: 200,
        outMs: 5000,
        enter: LayerAnimation(style: 'fade', durationMs: 400),
      ),
      locked: true,
      colorTag: 'violet',
    );
    final project = SceneProject(
      name: 'Demo',
      canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
      layers: <SceneLayer>[layer],
      assets: const <ProjectAsset>[
        ProjectAsset(
          id: 'image-1',
          path: 'assets/image.png',
          mimeType: 'image/png',
        ),
      ],
    );

    final restored = SceneProject.fromJson(project.toJson());
    expect(restored.name, 'Demo');
    expect(restored.layers, hasLength(1));
    expect(restored.layers.single.rect, layer.rect);
    expect(restored.layers.single.params['text'], 'Hello');
    expect(restored.layers.single.keyframes['size'], hasLength(2));
    expect(restored.layers.single.timing.enter.style, 'fade');
    expect(restored.assets.single.path, 'assets/image.png');
  });

  test('unsupported schema has a readable error', () {
    expect(
      () => SceneProject.fromJson(<String, Object?>{'schemaVersion': 99}),
      throwsA(
        isA<ProjectFormatException>().having(
          (error) => error.message,
          'message',
          contains('99'),
        ),
      ),
    );
  });
}
