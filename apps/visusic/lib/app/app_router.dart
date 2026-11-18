// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/features/editor/editor_screen.dart';
import 'package:visusic/features/home/home_screen.dart';
import 'package:visusic/features/settings/about_screen.dart';
import 'package:visusic_core/visusic_core.dart';

/// Named routes exposed by the application shell.
abstract final class AppRoutes {
  /// The welcome screen.
  static const String home = '/';

  /// Scene editor.
  static const String editor = '/editor';

  /// Version and license information.
  static const String about = '/about';
}

/// Creates complete application routes with shared widget definitions.
final class AppRouter {
  /// Creates a router using the shared registry.
  const AppRouter(this.registry);

  /// Shared built-in manifest registry.
  final ManifestRegistry registry;

  /// Resolves a route name to a complete screen.
  Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.about => const AboutScreen(),
      AppRoutes.editor => EditorScreen(registry: registry),
      _ => const HomeScreen(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
  }
}
