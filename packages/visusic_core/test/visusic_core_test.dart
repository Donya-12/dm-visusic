// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  test('project schema starts at version one', () {
    expect(projectSchemaVersion, 1);
  });
}
