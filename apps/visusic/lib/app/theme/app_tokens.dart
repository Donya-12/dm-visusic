// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

/// Shared spacing values based on the editor's eight-pixel grid.
abstract final class AppSpacing {
  /// Extra-small spacing, 4 logical pixels.
  static const double xs = 4;

  /// Small spacing, 8 logical pixels.
  static const double sm = 8;

  /// Medium spacing, 12 logical pixels.
  static const double md = 12;

  /// Large spacing, 16 logical pixels.
  static const double lg = 16;

  /// Extra-large spacing, 24 logical pixels.
  static const double xl = 24;

  /// Section spacing, 32 logical pixels.
  static const double xxl = 32;

  /// Hero spacing, 48 logical pixels.
  static const double huge = 48;
}

/// Shared corner radii for Material 3 surfaces and controls.
abstract final class AppRadii {
  /// Extra-small radius.
  static const double xs = 4;

  /// Small radius.
  static const double sm = 8;

  /// Medium radius.
  static const double md = 12;

  /// Large radius.
  static const double lg = 16;

  /// Extra-large radius.
  static const double xl = 28;
}

/// Shared durations for restrained, expressive interface motion.
abstract final class AppDurations {
  /// Quick state feedback.
  static const Duration short = Duration(milliseconds: 200);

  /// Standard panel transition.
  static const Duration medium = Duration(milliseconds: 350);

  /// Deliberate large-surface transition.
  static const Duration long = Duration(milliseconds: 500);
}
