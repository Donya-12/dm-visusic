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

  @override
  String get newScene => 'Новая сцена';

  @override
  String get selectLayer => 'Выбери слой на канвасе или в списке слоёв';

  @override
  String get unknownWidget => 'Неизвестный виджет';

  @override
  String get design => 'Дизайн';

  @override
  String get motion => 'Движение';

  @override
  String get reactions => 'Реакции';

  @override
  String get layerName => 'Имя слоя';

  @override
  String get replaceWidget => 'Заменить виджет';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get lock => 'Заблокировать';

  @override
  String get show => 'Показать';

  @override
  String get hide => 'Скрыть';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get delete => 'Удалить';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get bringForward => 'На слой выше';

  @override
  String get sendBackward => 'На слой ниже';

  @override
  String get layerTiming => 'Время слоя';

  @override
  String get inPoint => 'Начало';

  @override
  String get outPoint => 'Конец';

  @override
  String get enter => 'Появление';

  @override
  String get exit => 'Исчезновение';

  @override
  String get duration => 'Длительность';

  @override
  String get keyframes => 'Ключевые кадры';

  @override
  String get noKeyframes =>
      'Нет ключевых кадров. Нажми Ctrl+K или ромб рядом с числовым параметром.';

  @override
  String keyframeCount(int count) {
    return 'Ключевых кадров: $count';
  }

  @override
  String get attack => 'Атака';

  @override
  String get release => 'Затухание';

  @override
  String get noBindings => 'У этого виджета нет реакций на музыку.';

  @override
  String get expressions => 'Выражения';

  @override
  String get addKeyframe => 'Добавить ключевой кадр';

  @override
  String get chooseImage => 'Выбрать изображение';

  @override
  String get replaceImage => 'Заменить изображение';

  @override
  String get chooseColor => 'Выбрать цвет';

  @override
  String get cancel => 'Отмена';

  @override
  String get clear => 'Очистить';

  @override
  String get apply => 'Применить';

  @override
  String get demoSignal => 'Демо-сигнал';

  @override
  String get demoSignalExplanation =>
      'Реакции используют встроенный детерминированный демо-сигнал. Декодирование и анализ настоящего аудио появятся в M3.';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get timelineEmpty => 'Добавь виджет, чтобы появилась первая дорожка';

  @override
  String get noLayers => 'Слоёв пока нет';

  @override
  String get mute => 'Выключить слой';

  @override
  String get unmute => 'Включить слой';

  @override
  String get solo => 'Соло';

  @override
  String get unsolo => 'Убрать соло';

  @override
  String get layerOptions => 'Параметры слоя';

  @override
  String get widgets => 'Виджеты';

  @override
  String get layers => 'Слои';

  @override
  String get searchWidgets => 'Поиск виджетов';

  @override
  String get all => 'Все';

  @override
  String get categoryBasic => 'Базовые';

  @override
  String get categoryText => 'Текст';

  @override
  String get categoryAudio => 'Аудио';

  @override
  String get categoryBackground => 'Фон';

  @override
  String get categoryMeta => 'Служебные';

  @override
  String get noWidgetsFound => 'По запросу ничего не найдено';

  @override
  String get newBadge => 'NEW';

  @override
  String get addWidget => 'Добавить виджет';

  @override
  String get zoomOut => 'Уменьшить';

  @override
  String get zoomIn => 'Увеличить';

  @override
  String get phoneFrame => 'Показать рамку телефона';

  @override
  String get sceneFrame => 'Показать обычную рамку';

  @override
  String get grid => 'Сетка';

  @override
  String get safeArea => 'Безопасная зона';

  @override
  String get align => 'Выровнять выбранное';

  @override
  String get spectrumDropHint =>
      'Спектр добавлен. Попробуй расположить его выше или ниже текста.';

  @override
  String get emptySceneTitle => 'Собери первую сцену';

  @override
  String get emptySceneBody =>
      'Начни с готовой демо-сцены или добавь любой виджет. Каждый слой можно изменить позже.';

  @override
  String get buildDemoScene => 'Собрать демо-сцену';

  @override
  String get undo => 'Отменить';

  @override
  String get redo => 'Повторить';

  @override
  String get openProject => 'Открыть проект';

  @override
  String get loadAudio => 'Загрузить аудио';

  @override
  String get lyrics => 'Текст песни';

  @override
  String get importLyrics => 'Импортировать .lrc';

  @override
  String get searchLyrics => 'Найти в LRCLIB';

  @override
  String get lyricsTitle => 'Название трека';

  @override
  String get lyricsArtist => 'Исполнитель';

  @override
  String get noLyricsFound => 'Пока ничего нет';

  @override
  String get tapToSync => 'Тапни, чтобы синхронизировать строку';

  @override
  String get export => 'Экспорт видео';

  @override
  String get exportFormat => 'Формат';

  @override
  String get exportResolution => 'Разрешение';

  @override
  String get exportFps => 'Кадров в секунду';

  @override
  String get exporting => 'Экспорт…';

  @override
  String get templates => 'Шаблоны';

  @override
  String get importPack => 'Импорт .vspack';

  @override
  String get exportPack => 'Экспорт в .vspack';

  @override
  String get save => 'Сохранить';

  @override
  String get saveAs => 'Сохранить как';

  @override
  String get shortcuts => 'Горячие клавиши';

  @override
  String get close => 'Закрыть';

  @override
  String get customAspect => 'Свой размер канваса';

  @override
  String get logicalWidth => 'Логическая ширина';

  @override
  String get logicalHeight => 'Логическая высота';

  @override
  String get projectName => 'Название проекта';

  @override
  String get unsavedTitle => 'Несохранённые изменения';

  @override
  String get unsavedBody =>
      'Сохранить сцену перед выходом? Иначе последние изменения будут потеряны.';

  @override
  String get keepEditing => 'Продолжить редактирование';

  @override
  String get discard => 'Не сохранять';

  @override
  String get saveAndClose => 'Сохранить и продолжить';

  @override
  String get saved => 'Проект сохранён';

  @override
  String get recoveryTitle => 'Восстановить несохранённую сцену?';

  @override
  String get recoveryBody =>
      'Найдена копия восстановления из предыдущей сессии редактирования.';

  @override
  String get dismiss => 'Удалить копию';

  @override
  String get restore => 'Восстановить';
}
