// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/app.dart';
import 'package:visusic/app/app_router.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/app/theme/app_tokens.dart';
import 'package:visusic/app/widgets/brand_mark.dart';

/// The complete M0 welcome view and application preference controls.
class HomeScreen extends StatelessWidget {
  /// Creates the welcome view.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = HomeScope.of(context);
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandMark(size: 32),
            SizedBox(width: AppSpacing.md),
            Text('VisuSic'),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<Locale>(
            key: const Key('language-menu'),
            tooltip: l10n.language,
            icon: const Icon(Icons.translate_rounded),
            onSelected: scope.onLocaleChanged,
            itemBuilder: (context) => <PopupMenuEntry<Locale>>[
              CheckedPopupMenuItem<Locale>(
                value: const Locale('en'),
                checked: currentLocale.languageCode == 'en',
                child: const Text('English'),
              ),
              CheckedPopupMenuItem<Locale>(
                value: const Locale('ru'),
                checked: currentLocale.languageCode == 'ru',
                child: const Text('Русский'),
              ),
            ],
          ),
          IconButton(
            key: const Key('theme-toggle'),
            tooltip: scope.isDarkMode ? l10n.useLightTheme : l10n.useDarkTheme,
            onPressed: () => scope.onThemeChanged(!scope.isDarkMode),
            icon: Icon(
              scope.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            key: const Key('about-app-bar-button'),
            tooltip: l10n.about,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.about),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xxl),
                  const BrandMark(size: 72),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.welcomeTitle,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.tagline,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.welcomeDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      Chip(
                        avatar: const Icon(
                          Icons.offline_bolt_outlined,
                          size: 18,
                        ),
                        label: Text(l10n.offlineFirst),
                      ),
                      Chip(
                        avatar: const Icon(Icons.folder_zip_outlined, size: 18),
                        label: Text(l10n.portableWindows),
                      ),
                      Chip(
                        avatar: const Icon(Icons.code_rounded, size: 18),
                        label: Text(l10n.openSource),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton.icon(
                    key: const Key('new-scene-button'),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.editor),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(l10n.newScene),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    key: const Key('about-button'),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.about),
                    icon: const Icon(Icons.info_outline_rounded),
                    label: Text(l10n.aboutButton),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
