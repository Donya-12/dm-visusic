// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('.vsproj archive round-trip includes image assets', () {
    final original = ProjectBundle(
      project: SceneProject(
        name: 'Image scene',
        canvas: const SceneCanvas(width: 640, height: 360, aspect: '16:9'),
        assets: const <ProjectAsset>[
          ProjectAsset(
            id: 'cover',
            path: 'assets/cover.png',
            mimeType: 'image/png',
          ),
        ],
      ),
      assetBytes: <String, Uint8List>{
        'cover': Uint8List.fromList(<int>[1, 2, 3, 4]),
      },
    );

    final restored = ProjectArchiveCodec.decode(
      ProjectArchiveCodec.encode(original),
    );
    expect(restored.project.name, 'Image scene');
    expect(restored.assetBytes['cover'], <int>[1, 2, 3, 4]);
  });

  test('archive reader rejects missing manifest', () {
    expect(
      () => ProjectArchiveCodec.decode(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<ProjectFormatException>()),
    );
  });

  test('.vsproj round-trips the analysis cache entry', () {
    final analysis = Uint8List.fromList(<int>[9, 8, 7, 6]);
    final original = ProjectBundle(
      project: SceneProject(
        name: 'Audio scene',
        canvas: const SceneCanvas(width: 640, height: 360, aspect: '16:9'),
        audioPath: 'track.wav',
        audioAnalysis: 'analysis.vsan',
      ),
      analysisBytes: analysis,
    );
    final restored = ProjectArchiveCodec.decode(ProjectArchiveCodec.encode(original));
    expect(restored.project.audioPath, 'track.wav');
    expect(restored.project.audioAnalysis, 'analysis.vsan');
    expect(restored.analysisBytes, analysis);
  });
}
