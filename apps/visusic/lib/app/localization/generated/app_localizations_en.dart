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

  @override
  String get newScene => 'New scene';

  @override
  String get selectLayer =>
      'Select a layer on the canvas or in the layers list';

  @override
  String get unknownWidget => 'Unknown widget';

  @override
  String get design => 'Design';

  @override
  String get motion => 'Motion';

  @override
  String get reactions => 'Reactions';

  @override
  String get layerName => 'Layer name';

  @override
  String get replaceWidget => 'Replace widget';

  @override
  String get unlock => 'Unlock';

  @override
  String get lock => 'Lock';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get bringForward => 'Bring forward';

  @override
  String get sendBackward => 'Send backward';

  @override
  String get layerTiming => 'Layer timing';

  @override
  String get inPoint => 'In point';

  @override
  String get outPoint => 'Out point';

  @override
  String get enter => 'Entrance';

  @override
  String get exit => 'Exit';

  @override
  String get duration => 'Duration';

  @override
  String get keyframes => 'Keyframes';

  @override
  String get noKeyframes =>
      'No keyframes. Use Ctrl+K or the diamond beside a numeric parameter.';

  @override
  String keyframeCount(int count) {
    return '$count keyframes';
  }

  @override
  String get attack => 'Attack';

  @override
  String get release => 'Release';

  @override
  String get noBindings => 'This widget has no music reactions.';

  @override
  String get expressions => 'Expressions';

  @override
  String get addKeyframe => 'Add keyframe';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get chooseColor => 'Choose color';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get demoSignal => 'Demo signal';

  @override
  String get demoSignalExplanation =>
      'These reactions use a deterministic built-in demo signal. Real audio decoding and analysis are introduced in M3.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get timelineEmpty => 'Add a widget to create the first timing lane';

  @override
  String get noLayers => 'No layers yet';

  @override
  String get mute => 'Mute layer';

  @override
  String get unmute => 'Unmute layer';

  @override
  String get solo => 'Solo layer';

  @override
  String get unsolo => 'Remove solo';

  @override
  String get layerOptions => 'Layer options';

  @override
  String get widgets => 'Widgets';

  @override
  String get layers => 'Layers';

  @override
  String get searchWidgets => 'Search widgets';

  @override
  String get all => 'All';

  @override
  String get categoryBasic => 'Basic';

  @override
  String get categoryText => 'Text';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryBackground => 'Background';

  @override
  String get categoryMeta => 'Meta';

  @override
  String get noWidgetsFound => 'No widgets match your search';

  @override
  String get newBadge => 'NEW';

  @override
  String get addWidget => 'Add widget';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get phoneFrame => 'Show phone frame';

  @override
  String get sceneFrame => 'Show scene frame';

  @override
  String get grid => 'Grid';

  @override
  String get safeArea => 'Safe area';

  @override
  String get align => 'Align selection';

  @override
  String get spectrumDropHint =>
      'Spectrum added. Try placing it above or below your text.';

  @override
  String get emptySceneTitle => 'Build your first scene';

  @override
  String get emptySceneBody =>
      'Start with a polished demo or add any widget. You can change every layer afterwards.';

  @override
  String get buildDemoScene => 'Build demo scene';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get openProject => 'Open project';

  @override
  String get loadAudio => 'Load audio track';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get importLyrics => 'Import .lrc file';

  @override
  String get searchLyrics => 'Search LRCLIB';

  @override
  String get lyricsTitle => 'Track title';

  @override
  String get lyricsArtist => 'Artist';

  @override
  String get noLyricsFound => 'Nothing here yet';

  @override
  String get tapToSync => 'Tap to sync the next line';

  @override
  String get export => 'Export video';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportResolution => 'Resolution';

  @override
  String get exportFps => 'Frame rate';

  @override
  String get exporting => 'Exporting…';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save As';

  @override
  String get shortcuts => 'Keyboard shortcuts';

  @override
  String get close => 'Close';

  @override
  String get customAspect => 'Custom canvas';

  @override
  String get logicalWidth => 'Logical width';

  @override
  String get logicalHeight => 'Logical height';

  @override
  String get projectName => 'Project name';

  @override
  String get unsavedTitle => 'Unsaved changes';

  @override
  String get unsavedBody =>
      'Save your scene before leaving? Your latest edits will otherwise be lost.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get saveAndClose => 'Save and continue';

  @override
  String get saved => 'Project saved';

  @override
  String get recoveryTitle => 'Restore unsaved scene?';

  @override
  String get recoveryBody =>
      'A recovery copy from an earlier editing session is available.';

  @override
  String get dismiss => 'Discard copy';

  @override
  String get restore => 'Restore';
}
