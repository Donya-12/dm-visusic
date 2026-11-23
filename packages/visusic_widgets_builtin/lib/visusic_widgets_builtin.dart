// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_widgets_builtin/src/builtin_manifests.dart';

/// Stable identifiers for built-in editor widgets.
abstract final class BuiltinWidgetIds {
  /// Filled shape layer.
  static const String rectangle = 'builtin.rectangle';

  /// Static editable text.
  static const String text = 'builtin.text';

  /// Animated title text.
  static const String title = 'builtin.title';

  /// Image asset layer.
  static const String image = 'builtin.image';

  /// Vertical spectrum bars.
  static const String barSpectrum = 'builtin.barSpectrum';

  /// Moving gradient background.
  static const String meshGradient = 'builtin.meshGradient';

  /// Deterministic particles.
  static const String particles = 'builtin.particles';

  /// Artwork or vinyl display.
  static const String albumArt = 'builtin.albumArt';

  /// Timeline progress indicator.
  static const String progress = 'builtin.progress';

  /// Text readability overlay.
  static const String scrim = 'builtin.scrim';

  /// Word-synced karaoke lyrics.
  static const String karaoke = 'builtin.karaoke';

  /// Multi-line rolling lyrics.
  static const String rollingLyrics = 'builtin.rollingLyrics';

  /// Prebuilt GLSL shader playground.
  static const String shaderPulse = 'builtin.shaderPulse';

  /// All identifiers available in the built-in library.
  static const List<String> all = <String>[
    rectangle,
    text,
    title,
    image,
    barSpectrum,
    meshGradient,
    particles,
    albumArt,
    progress,
    scrim,
    karaoke,
    rollingLyrics,
    shaderPulse,
  ];
}

/// Creates the validated built-in manifest registry.
abstract final class BuiltinLibrary {
  /// Parses all built-in manifests with the public schema validator.
  static ManifestRegistry createRegistry() =>
      ManifestRegistry.fromJsonString(builtinManifestsJson);

  /// Original manifest JSON used by parser tests and tooling.
  static String get manifestJson => builtinManifestsJson;
}
