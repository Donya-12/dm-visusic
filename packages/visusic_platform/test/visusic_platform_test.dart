// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:test/test.dart';
import 'package:visusic_platform/visusic_platform.dart';

void main() {
  test('platform contract starts at version one', () {
    expect(platformContractVersion, 1);
  });
}
