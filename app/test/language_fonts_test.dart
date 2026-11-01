// SPDX-License-Identifier: Apache-2.0
// The language pickers draw every language's own name (中文 and ไทย among them) with the bundled
// fonts as fallback, so a Linux or Windows desktop without a CJK or Thai font still shows them:
// each text that holds a name resolves to a style whose fallback list has the bundled faces.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/help_language_switch.dart';
import 'package:epic_wallet/src/ui/theme/fonts.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every drawn text holding [name] falls back to the bundled CJK and Thai faces.
void _expectBundledFallback(WidgetTester tester, String name) {
  final texts = tester.widgetList<RichText>(
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(name)),
  );
  expect(texts, isNotEmpty, reason: name);
  for (final t in texts) {
    final fallback = t.text.style?.fontFamilyFallback;
    expect(fallback, containsAll([cjkFamily, 'NotoSansThai']), reason: '$name: $fallback');
  }
}

void main() {
  test('the CJK subset is a bundled fallback', () {
    expect(bundledFallback, contains(cjkFamily));
    // Tests run on a desktop host, where the phone theme takes the bundled list too.
    expect(phoneFontFallback, bundledFallback);
  });

  testWidgets('desktop: the language select and its menu', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final wallet = MockDeskWallet(delay: Duration.zero);
    await wallet.saveSettings(const DeskSettings(helpLanguage: 'zh'));
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: SettingsHelpScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectBundledFallback(tester, '简体中文');
    await tester.tap(find.byType(ESelect<String>));
    await tester.pumpAndSettle();
    for (final a in appLanguages) {
      _expectBundledFallback(tester, a.name);
    }
  });

  testWidgets('phone: the Help language switch and its menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secretStoreProvider.overrideWithValue(MemorySecretStore())],
        child: MaterialApp(
          theme: buildWalletTheme(protocolDark, Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: HelpLanguageSwitch(current: 'zh'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectBundledFallback(tester, '简体中文');
    await tester.tap(find.byKey(helpLanguageKey));
    await tester.pumpAndSettle();
    for (final a in appLanguages) {
      _expectBundledFallback(tester, a.name);
    }
  });
}
