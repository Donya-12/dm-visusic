// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya
// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VisuSic';

  @override
  String get tagline => 'Your music, your stage.';

  @override
  String get welcomeTitle => 'A stage for your sound';

  @override
  String get welcomeDescription =>
      'Build music visualizations and lyric videos from editable scenes. VisuSic is designed to work offline, without accounts or subscriptions.';

  @override
  String get offlineFirst => 'Offline-first';

  @override
  String get portableWindows => 'Portable for Windows';

  @override
  String get openSource => 'Open source · MIT';

  @override
  String get aboutButton => 'About VisuSic';

  @override
  String get language => 'Language';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get useLightTheme => 'Use light theme';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'An open-source editor for audio-reactive scenes and lyric videos. No account, cloud, or telemetry.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get license => 'MIT License';

  @override
  String get thirdPartyLicenses => 'Third-party licenses';

  @override
  String get repository => 'Source repository';

  @override
  String get copyright => 'Copyright © 2026 Donya';
}
