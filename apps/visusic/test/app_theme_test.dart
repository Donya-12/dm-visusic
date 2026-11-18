// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/theme/app_theme.dart';
import 'package:visusic/app/theme/app_tokens.dart';

void main() {
  test('themes use Material 3, Inter, and custom surfaces', () {
    final dark = AppTheme.dark();
    final light = AppTheme.light();

    expect(dark.useMaterial3, isTrue);
    expect(light.useMaterial3, isTrue);
    expect(dark.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(dark.colorScheme.surface, const Color(0xFF101014));
    expect(light.colorScheme.brightness, Brightness.light);
  });

  test('spacing follows the eight-pixel editor grid', () {
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.lg, 16);
    expect(AppSpacing.xl, 24);
  });
}
