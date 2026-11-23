// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic/features/export/scene_export.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_platform/visusic_platform.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

void main() {
  testWidgets('exports a deterministic sequence of frames', (tester) async {
    final project = SceneProject(
      name: 'Export',
      canvas: const SceneCanvas(width: 320, height: 180, aspect: '16:9', duration: 2),
      layers: <SceneLayer>[
        SceneLayer(
          id: 'bg',
          widgetId: BuiltinWidgetIds.meshGradient,
          name: 'BG',
          rect: const SceneRect(x: 0, y: 0, width: 320, height: 180),
        ),
      ],
    );
    final service = SceneExportService(
      project: project,
      registry: BuiltinLibrary.createRegistry(),
    );
    final encoder = _FakeEncoder();
    await tester.runAsync(() async {
      await service.export(
        settings: const ExportSettings(
          width: 160,
          height: 90,
          fps: 10,
          container: 'mp4',
        ),
        encoder: encoder,
        outputPath: 'out.mp4',
      );
    });
    expect(encoder.frameCount, 20);
    expect(encoder.firstWidth, 160);
    expect(encoder.firstHeight, 90);
    expect(encoder.firstBytes, isNotEmpty);
  });
}

final class _FakeEncoder implements VideoEncoder {
  int frameCount = 0;
  int firstWidth = 0;
  int firstHeight = 0;
  List<int> firstBytes = const <int>[];

  @override
  Future<void> encode({
    required ExportSettings settings,
    required Stream<VideoFrame> frames,
    required String outputPath,
    String? audioPath,
    double? durationSeconds,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await for (final frame in frames) {
      frameCount++;
      if (frameCount == 1) {
        firstWidth = frame.width;
        firstHeight = frame.height;
        firstBytes = frame.rgba;
      }
    }
  }
}
