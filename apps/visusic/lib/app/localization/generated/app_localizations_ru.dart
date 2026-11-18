// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya
// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'VisuSic';

  @override
  String get tagline => 'Твоя музыка. Твоя сцена.';

  @override
  String get welcomeTitle => 'Сцена для твоего звука';

  @override
  String get welcomeDescription =>
      'Создавай музыкальную визуализацию и лирик-видео из редактируемых сцен. VisuSic работает офлайн, без аккаунтов и подписок.';

  @override
  String get offlineFirst => 'Работает офлайн';

  @override
  String get portableWindows => 'Portable для Windows';

  @override
  String get openSource => 'Открытый код · MIT';

  @override
  String get aboutButton => 'О VisuSic';

  @override
  String get language => 'Язык';

  @override
  String get useDarkTheme => 'Включить тёмную тему';

  @override
  String get useLightTheme => 'Включить светлую тему';

  @override
  String get about => 'О программе';

  @override
  String get aboutDescription =>
      'Редактор аудиореактивных сцен и лирик-видео с открытым кодом. Без аккаунта, облака и телеметрии.';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get license => 'Лицензия MIT';

  @override
  String get thirdPartyLicenses => 'Сторонние лицензии';

  @override
  String get repository => 'Репозиторий исходного кода';

  @override
  String get copyright => 'Copyright © 2026 Donya';
}
