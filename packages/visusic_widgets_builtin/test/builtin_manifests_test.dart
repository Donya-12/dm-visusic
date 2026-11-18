// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

void main() {
  test('all built-in JSON manifests pass the public validator', () {
    final registry = BuiltinLibrary.createRegistry();
    expect(registry.manifests, hasLength(BuiltinWidgetIds.all.length));
    for (final manifest in registry.manifests) {
      expect(manifest.name.resolve('ru'), isNotEmpty);
      expect(manifest.parameters, hasLength(lessThanOrEqualTo(12)));
      expect(manifest.primaryParameters(), hasLength(lessThanOrEqualTo(3)));
      final defaults = manifest.defaultParams();
      for (final parameter in manifest.parameters) {
        if (parameter.type != ParameterType.group) {
          expect(
            () => parameter.validate(defaults[parameter.id]),
            returnsNormally,
          );
        }
      }
    }
  });
}
