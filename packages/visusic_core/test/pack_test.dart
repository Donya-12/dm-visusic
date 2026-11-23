// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('.vspack round-trips widgets, scenes, and assets', () {
    final pack = WidgetPack(
      name: 'Demo Pack',
      version: '1.2.0',
      author: 'Donya',
      description: 'Test pack',
      manifests: <WidgetManifest>[
        WidgetManifest(
          id: 'demo.rect',
          version: '1.0.0',
          name: LocalizedText(<String, String>{
            'en': 'Rect',
            'ru': 'Прямоугольник',
          }),
          author: 'Donya',
          category: 'basic',
          parameters: <ParameterSpec>[
            ParameterSpec(
              id: 'size',
              type: ParameterType.float,
              label: LocalizedText(<String, String>{'en': 'Size'}),
              defaultValue: 10,
              minimum: 1,
              maximum: 100,
            ),
          ],
          bindings: const <WidgetBindingSpec>[],
          expressions: const <String, String>{},
          render: const WidgetRenderSpec(type: 'native', id: 'rect'),
          needsAudio: false,
          needsLyrics: false,
          defaultWidth: 100,
          defaultHeight: 100,
        ),
      ],
      scenes: <SceneProject>[
        SceneProject(
          name: 'Empty',
          canvas: const SceneCanvas(width: 1920, height: 1080, aspect: '16:9'),
        ),
      ],
      assetBytes: <String, Uint8List>{
        'assets/icon.png': Uint8List.fromList(<int>[1, 2, 3]),
      },
    );
    final restored = PackCodec.decode(PackCodec.encode(pack));
    expect(restored.name, 'Demo Pack');
    expect(restored.manifests, hasLength(1));
    expect(restored.manifests.single.name.resolve('ru'), 'Прямоугольник');
    expect(restored.manifests.single.parameters.single.minimum, 1);
    expect(restored.scenes, hasLength(1));
    expect(restored.assetBytes['assets/icon.png'], <int>[1, 2, 3]);
  });
}
