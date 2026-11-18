// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:visusic/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Inter license can be registered', () async {
    await expectLater(registerThirdPartyLicenses(), completes);
  });
}
