// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

void main() {
  test('built-in widget identifiers are unique', () {
    expect(BuiltinWidgetIds.all, hasLength(13));
    expect(BuiltinWidgetIds.all.toSet(), hasLength(13));
  });
}
