// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic_render/visusic_render.dart';

void main() {
  test('scene schema starts at version one', () {
    expect(sceneSchemaVersion, 1);
  });
}
