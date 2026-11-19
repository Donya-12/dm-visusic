// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VisuSic'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your music, your stage.'**
  String get tagline;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A stage for your sound'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Build music visualizations and lyric videos from editable scenes. VisuSic is designed to work offline, without accounts or subscriptions.'**
  String get welcomeDescription;

  /// No description provided for @offlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Offline-first'**
  String get offlineFirst;

  /// No description provided for @portableWindows.
  ///
  /// In en, this message translates to:
  /// **'Portable for Windows'**
  String get portableWindows;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open source · MIT'**
  String get openSource;

  /// No description provided for @aboutButton.
  ///
  /// In en, this message translates to:
  /// **'About VisuSic'**
  String get aboutButton;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @useLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Use light theme'**
  String get useLightTheme;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'An open-source editor for audio-reactive scenes and lyric videos. No account, cloud, or telemetry.'**
  String get aboutDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get license;

  /// No description provided for @thirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Third-party licenses'**
  String get thirdPartyLicenses;

  /// No description provided for @repository.
  ///
  /// In en, this message translates to:
  /// **'Source repository'**
  String get repository;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright © 2026 Donya'**
  String get copyright;

  /// No description provided for @newScene.
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get newScene;

  /// No description provided for @selectLayer.
  ///
  /// In en, this message translates to:
  /// **'Select a layer on the canvas or in the layers list'**
  String get selectLayer;

  /// No description provided for @unknownWidget.
  ///
  /// In en, this message translates to:
  /// **'Unknown widget'**
  String get unknownWidget;

  /// No description provided for @design.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motion;

  /// No description provided for @reactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactions;

  /// No description provided for @layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer name'**
  String get layerName;

  /// No description provided for @replaceWidget.
  ///
  /// In en, this message translates to:
  /// **'Replace widget'**
  String get replaceWidget;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @bringForward.
  ///
  /// In en, this message translates to:
  /// **'Bring forward'**
  String get bringForward;

  /// No description provided for @sendBackward.
  ///
  /// In en, this message translates to:
  /// **'Send backward'**
  String get sendBackward;

  /// No description provided for @layerTiming.
  ///
  /// In en, this message translates to:
  /// **'Layer timing'**
  String get layerTiming;

  /// No description provided for @inPoint.
  ///
  /// In en, this message translates to:
  /// **'In point'**
  String get inPoint;

  /// No description provided for @outPoint.
  ///
  /// In en, this message translates to:
  /// **'Out point'**
  String get outPoint;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get enter;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @keyframes.
  ///
  /// In en, this message translates to:
  /// **'Keyframes'**
  String get keyframes;

  /// No description provided for @noKeyframes.
  ///
  /// In en, this message translates to:
  /// **'No keyframes. Use Ctrl+K or the diamond beside a numeric parameter.'**
  String get noKeyframes;

  /// No description provided for @keyframeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} keyframes'**
  String keyframeCount(int count);

  /// No description provided for @attack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attack;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @noBindings.
  ///
  /// In en, this message translates to:
  /// **'This widget has no music reactions.'**
  String get noBindings;

  /// No description provided for @expressions.
  ///
  /// In en, this message translates to:
  /// **'Expressions'**
  String get expressions;

  /// No description provided for @addKeyframe.
  ///
  /// In en, this message translates to:
  /// **'Add keyframe'**
  String get addKeyframe;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get replaceImage;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get chooseColor;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @demoSignal.
  ///
  /// In en, this message translates to:
  /// **'Demo signal'**
  String get demoSignal;

  /// No description provided for @demoSignalExplanation.
  ///
  /// In en, this message translates to:
  /// **'These reactions use a deterministic built-in demo signal. Real audio decoding and analysis are introduced in M3.'**
  String get demoSignalExplanation;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a widget to create the first timing lane'**
  String get timelineEmpty;

  /// No description provided for @noLayers.
  ///
  /// In en, this message translates to:
  /// **'No layers yet'**
  String get noLayers;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute layer'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute layer'**
  String get unmute;

  /// No description provided for @solo.
  ///
  /// In en, this message translates to:
  /// **'Solo layer'**
  String get solo;

  /// No description provided for @unsolo.
  ///
  /// In en, this message translates to:
  /// **'Remove solo'**
  String get unsolo;

  /// No description provided for @layerOptions.
  ///
  /// In en, this message translates to:
  /// **'Layer options'**
  String get layerOptions;

  /// No description provided for @widgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgets;

  /// No description provided for @layers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layers;

  /// No description provided for @searchWidgets.
  ///
  /// In en, this message translates to:
  /// **'Search widgets'**
  String get searchWidgets;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @categoryBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get categoryBasic;

  /// No description provided for @categoryText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get categoryText;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// No description provided for @categoryBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get categoryBackground;

  /// No description provided for @categoryMeta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get categoryMeta;

  /// No description provided for @noWidgetsFound.
  ///
  /// In en, this message translates to:
  /// **'No widgets match your search'**
  String get noWidgetsFound;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @addWidget.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get addWidget;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @phoneFrame.
  ///
  /// In en, this message translates to:
  /// **'Show phone frame'**
  String get phoneFrame;

  /// No description provided for @sceneFrame.
  ///
  /// In en, this message translates to:
  /// **'Show scene frame'**
  String get sceneFrame;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @safeArea.
  ///
  /// In en, this message translates to:
  /// **'Safe area'**
  String get safeArea;

  /// No description provided for @align.
  ///
  /// In en, this message translates to:
  /// **'Align selection'**
  String get align;

  /// No description provided for @spectrumDropHint.
  ///
  /// In en, this message translates to:
  /// **'Spectrum added. Try placing it above or below your text.'**
  String get spectrumDropHint;

  /// No description provided for @emptySceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your first scene'**
  String get emptySceneTitle;

  /// No description provided for @emptySceneBody.
  ///
  /// In en, this message translates to:
  /// **'Start with a polished demo or add any widget. You can change every layer afterwards.'**
  String get emptySceneBody;

  /// No description provided for @buildDemoScene.
  ///
  /// In en, this message translates to:
  /// **'Build demo scene'**
  String get buildDemoScene;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get openProject;

  /// No description provided for @loadAudio.
  ///
  /// In en, this message translates to:
  /// **'Load audio track'**
  String get loadAudio;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @importLyrics.
  ///
  /// In en, this message translates to:
  /// **'Import .lrc file'**
  String get importLyrics;

  /// No description provided for @searchLyrics.
  ///
  /// In en, this message translates to:
  /// **'Search LRCLIB'**
  String get searchLyrics;

  /// No description provided for @lyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Track title'**
  String get lyricsTitle;

  /// No description provided for @lyricsArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get lyricsArtist;

  /// No description provided for @noLyricsFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noLyricsFound;

  /// No description provided for @tapToSync.
  ///
  /// In en, this message translates to:
  /// **'Tap to sync the next line'**
  String get tapToSync;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcuts;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @customAspect.
  ///
  /// In en, this message translates to:
  /// **'Custom canvas'**
  String get customAspect;

  /// No description provided for @logicalWidth.
  ///
  /// In en, this message translates to:
  /// **'Logical width'**
  String get logicalWidth;

  /// No description provided for @logicalHeight.
  ///
  /// In en, this message translates to:
  /// **'Logical height'**
  String get logicalHeight;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedTitle;

  /// No description provided for @unsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Save your scene before leaving? Your latest edits will otherwise be lost.'**
  String get unsavedBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saveAndClose.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndClose;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Project saved'**
  String get saved;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore unsaved scene?'**
  String get recoveryTitle;

  /// No description provided for @recoveryBody.
  ///
  /// In en, this message translates to:
  /// **'A recovery copy from an earlier editing session is available.'**
  String get recoveryBody;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Discard copy'**
  String get dismiss;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
