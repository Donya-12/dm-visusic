// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/app.dart';
import 'package:visusic/app/licenses.dart';
import 'package:visusic_widgets_builtin/visusic_widgets_builtin.dart';

/// Starts the VisuSic Windows application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerThirdPartyLicenses();
  runApp(VisuSicApp(registry: BuiltinLibrary.createRegistry()));
}
