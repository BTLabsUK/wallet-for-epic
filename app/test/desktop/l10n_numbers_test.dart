// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_frame.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(String lang, Widget home) => ProviderScope(
  child: MaterialApp(
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildDeskTheme(Brightness.dark),
    home: Scaffold(body: home),
  ),
);

void main() {
  const nano = 128152615000;
  testWidgets('an amount and a node height follow the language', (tester) async {
    late BuildContext ctx;
    final h = Builder(builder: (c) {
      ctx = c;
      final l = AppLocalizations.of(c);
      return Column(children: [
        Text(formatEpicL(l, nano), key: const Key('amount')),
        Text(digits(l, 3214557), key: const Key('height')),
      ]);
    });
    for (final (lang, amount, height) in [
      ('de', '1.281,52615', '3.214.557'),
      ('en', '1,281.52615', '3,214,557'),
    ]) {
      await tester.pumpWidget(_app(lang, h));
      expect(tester.widget<Text>(find.byKey(const Key('amount'))).data, amount);
      expect(tester.widget<Text>(find.byKey(const Key('height'))).data, height);
    }
    expect(ctx, isNotNull);
    // The canonical form stays what fields, files and logic use.
    expect(formatEpic(nano), '1,281.52615');
  });

  for (final (lang, key) in [('de', 'Seed-Phrase'), ('pl', 'Fraza odzyskiwania'), ('de', 'Guthaben neu prüfen')]) {
    testWidgets('$lang settings sections are whole at 1280x800', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(lang, const SettingsFrame(route: DeskRoute.settingsAbout, child: SizedBox())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text(key), findsOneWidget);
    });
  }
}
