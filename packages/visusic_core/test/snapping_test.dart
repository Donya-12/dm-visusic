// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('move snaps to the scene center and emits guides', () {
    final result = SnapEngine.snapMove(
      rect: const SceneRect(x: 455, y: 279, width: 100, height: 50),
      canvasWidth: 1000,
      canvasHeight: 600,
      useGrid: false,
    );
    expect(result.rect.centerX, 500);
    expect(result.rect.centerY, 300);
    expect(result.guides, hasLength(2));
  });

  test('grid rounds positions to eight pixels', () {
    final result = SnapEngine.snapMove(
      rect: const SceneRect(x: 13, y: 27, width: 100, height: 50),
      canvasWidth: 1000,
      canvasHeight: 600,
      threshold: 0,
    );
    expect(result.rect.x, 16);
    expect(result.rect.y, 24);
  });
}
