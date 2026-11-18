// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';

/// The compact gradient mark used beside the VisuSic product name.
class BrandMark extends StatelessWidget {
  /// Creates a square brand mark.
  const BrandMark({super.key, this.size = 40});

  /// Width and height of the mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: 'VisuSic',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[colors.primary, colors.tertiary],
          ),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          color: colors.onPrimary,
          size: size * 0.58,
        ),
      ),
    );
  }
}
