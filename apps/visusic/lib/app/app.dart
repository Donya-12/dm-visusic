// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/app_router.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/app/theme/app_theme.dart';
import 'package:visusic_core/visusic_core.dart';

/// Root application widget owning theme and language preferences.
class VisuSicApp extends StatefulWidget {
  /// Creates the application.
  const VisuSicApp({required this.registry, super.key});

  /// Shared widget definitions passed to the editor route.
  final ManifestRegistry registry;

  @override
  State<VisuSicApp> createState() => _VisuSicAppState();
}

class _VisuSicAppState extends State<VisuSicApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        cupertino.GlobalCupertinoLocalizations.delegate,
        flutter_localizations.GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: _resolveLocale,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter(widget.registry).onGenerateRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.5,
            ),
          ),
          child: HomeScope(
            isDarkMode: _themeMode == ThemeMode.dark,
            onThemeChanged: _setDarkMode,
            onLocaleChanged: _setLocale,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Locale _resolveLocale(Locale? requested, Iterable<Locale> supported) {
    if (requested?.languageCode == 'ru') {
      return const Locale('ru');
    }
    return const Locale('en');
  }

  void _setDarkMode(bool value) {
    setState(() => _themeMode = value ? ThemeMode.dark : ThemeMode.light);
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }
}

/// Application-wide actions shared by the lightweight shell screens.
class HomeScope extends InheritedWidget {
  /// Creates the preference scope.
  const HomeScope({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required super.child,
    super.key,
  });

  /// Whether the current preference selects the dark theme.
  final bool isDarkMode;

  /// Updates the preferred brightness.
  final ValueChanged<bool> onThemeChanged;

  /// Updates the preferred locale.
  final ValueChanged<Locale> onLocaleChanged;

  /// Returns the nearest preference scope.
  static HomeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HomeScope>();
    assert(scope != null, 'HomeScope is missing above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(HomeScope oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}
