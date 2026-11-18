// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/app_info.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/app/theme/app_tokens.dart';
import 'package:visusic/app/widgets/brand_mark.dart';

/// Version, source, and licensing information for the running application.
class AboutScreen extends StatelessWidget {
  /// Creates the about view.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            shrinkWrap: true,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BrandMark(size: 56),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.version(AppInfo.version),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.aboutDescription),
                    const SizedBox(height: AppSpacing.xl),
                    Card(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.balance_outlined),
                            title: Text(l10n.license),
                            subtitle: const Text(AppInfo.copyright),
                          ),
                          const Divider(),
                          ListTile(
                            key: const Key('third-party-licenses-button'),
                            leading: const Icon(Icons.library_books_outlined),
                            title: Text(l10n.thirdPartyLicenses),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showLicenses(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.repository, style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      AppInfo.repositoryUrl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.version,
      applicationLegalese: AppInfo.copyright,
    );
  }
}
