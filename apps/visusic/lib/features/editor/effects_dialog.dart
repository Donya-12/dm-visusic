// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';

/// Post-processing effects inspector.
final class EffectsDialog extends StatelessWidget {
  /// Creates the dialog.
  const EffectsDialog({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    double value(String id) {
      for (final effect in controller.project.postFx) {
        if (effect.id == id) {
          return effect.intensity;
        }
      }
      return 0;
    }

    return AlertDialog(
      title: Text(l10n.effects),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _effectSlider(context, l10n.effectBloom, value('bloom'), 'bloom'),
            _effectSlider(context, l10n.effectVignette, value('vignette'), 'vignette'),
            _effectSlider(context, l10n.effectGrain, value('grain'), 'grain'),
            _effectSlider(context, l10n.effectShake, value('shake'), 'shake'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _effectSlider(
    BuildContext context,
    String label,
    double value,
    String id,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: value,
          min: 0,
          max: 1,
          onChanged: (next) => controller.setPostFx(id, next),
        ),
      ],
    );
  }
}
