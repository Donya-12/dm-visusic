// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/app.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English and Russian are supported', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(<Locale>[const Locale('en'), const Locale('ru')]),
    );
  });

  testWidgets('opens the about and license views', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const VisuSicApp());
    await tester.pumpAndSettle();

    expect(find.text('A stage for your sound'), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-button')));
    await tester.pumpAndSettle();
    expect(find.text('Version 0.1.0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('third-party-licenses-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('switches between English and Russian', (tester) async {
    await tester.pumpWidget(const VisuSicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский').last);
    await tester.pumpAndSettle();

    expect(find.text('Сцена для твоего звука'), findsOneWidget);
    expect(find.text('Твоя музыка. Твоя сцена.'), findsOneWidget);
  });

  testWidgets('starts dark and switches to the light theme', (tester) async {
    await tester.pumpWidget(const VisuSicApp());
    await tester.pumpAndSettle();

    BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();

    context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
