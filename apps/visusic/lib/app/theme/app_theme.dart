// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/theme/app_tokens.dart';

/// Material 3 themes and component defaults used throughout VisuSic.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF7C4DFF);

  /// The dark professional-tool theme used by default.
  static ThemeData dark() => _build(Brightness.dark);

  /// The matching light theme.
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness).copyWith(
          surface: isDark ? const Color(0xFF101014) : const Color(0xFFFCF9FF),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0A0A0E)
              : const Color(0xFFFFFFFF),
          surfaceContainerLow: isDark
              ? const Color(0xFF15151B)
              : const Color(0xFFF6F0FA),
          surfaceContainer: isDark
              ? const Color(0xFF1B1B22)
              : const Color(0xFFF0EAF5),
          surfaceContainerHigh: isDark
              ? const Color(0xFF23232B)
              : const Color(0xFFEAE2F0),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2D2D36)
              : const Color(0xFFE3DBE9),
        );
    final textTheme = _textTheme.apply(fontFamily: 'Inter');
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: roundedShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: roundedShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          animationDuration: AppDurations.short,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: roundedShape,
          side: BorderSide(color: colorScheme.outlineVariant),
          animationDuration: AppDurations.short,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          colorScheme.outline.withValues(alpha: 0.65),
        ),
        trackColor: WidgetStatePropertyAll<Color>(colorScheme.surface),
        thickness: const WidgetStatePropertyAll<double>(8),
        radius: const Radius.circular(AppRadii.xl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: roundedShape,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, height: 1.12, letterSpacing: -0.25),
    displayMedium: TextStyle(fontSize: 45, height: 1.16),
    displaySmall: TextStyle(fontSize: 36, height: 1.22),
    headlineLarge: TextStyle(fontSize: 32, height: 1.25),
    headlineMedium: TextStyle(fontSize: 28, height: 1.29),
    headlineSmall: TextStyle(fontSize: 24, height: 1.33),
    titleLarge: TextStyle(fontSize: 22, height: 1.27),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.5,
      letterSpacing: 0.15,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.43,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, letterSpacing: 0.15),
    bodyMedium: TextStyle(fontSize: 14, height: 1.43, letterSpacing: 0.25),
    bodySmall: TextStyle(fontSize: 12, height: 1.33, letterSpacing: 0.4),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.43,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.33,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.45,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    ),
  );
}
