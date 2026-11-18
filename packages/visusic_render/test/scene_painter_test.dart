// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/visusic_render.dart';

void main() {
  testWidgets('scene painter renders every built-in widget without error', (
    tester,
  ) async {
    final layers = <SceneLayer>[
      SceneLayer(
        id: 'bg',
        widgetId: 'builtin.meshGradient',
        name: 'BG',
        rect: const SceneRect(x: 0, y: 0, width: 320, height: 180),
        params: const <String, Object?>{
          'colors': <String>['#101014', '#7C4DFF'],
        },
      ),
      SceneLayer(
        id: 'title',
        widgetId: 'builtin.title',
        name: 'Title',
        rect: const SceneRect(x: 40, y: 40, width: 240, height: 80),
      ),
      SceneLayer(
        id: 'spectrum',
        widgetId: 'builtin.barSpectrum',
        name: 'Spectrum',
        rect: const SceneRect(x: 30, y: 120, width: 200, height: 50),
        params: const <String, Object?>{'colors': <String>['#7C4DFF', '#3DDC97']},
      ),
      SceneLayer(
        id: 'progress',
        widgetId: 'builtin.progress',
        name: 'Progress',
        rect: const SceneRect(x: 40, y: 170, width: 240, height: 30),
      ),
      SceneLayer(
        id: 'particles',
        widgetId: 'builtin.particles',
        name: 'Particles',
        rect: const SceneRect(x: 60, y: 10, width: 200, height: 60),
      ),
    ];
    final project = SceneProject(
      name: 'Smoke',
      canvas: const SceneCanvas(width: 320, height: 180, aspect: '16:9'),
      layers: layers,
    );
    final painter = ScenePainter(
      project: project,
      features: FeatureSnapshot.demo(1.2, 30),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, const Size(160, 90));
    final bytes = await tester.runAsync(() async {
      final image = await recorder.endRecording().toImage(160, 90);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    expect(bytes, isNotNull);
    expect(bytes!.lengthInBytes, greaterThan(0));
  });
}
