// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers bundled assets whose licenses are not discovered from packages.
Future<void> registerThirdPartyLicenses() async {
  final interLicense = await rootBundle.loadString('assets/fonts/OFL.txt');
  LicenseRegistry.addLicense(
    () => Stream<LicenseEntry>.value(
      LicenseEntryWithLineBreaks(<String>['Inter'], interLicense),
    ),
  );
}
