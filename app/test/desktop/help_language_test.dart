// SPDX-License-Identifier: Apache-2.0
// The Help language switch on the desktop: the flag and own name of the help's language, a menu
// of the six languages, a choice that is remembered and changes only the help, and the default
// that follows the interface language, which follows the computer's unless one is chosen.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/language_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {List<Locale> system = const [Locale('en')], DeskSettings? settings}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.localesTestValue = system;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final wallet = MockDeskWallet(delay: Duration.zero);
  if (settings != null) await wallet.saveSettings(settings);
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
  return container;
}

Finder get _switch => find.byType(ESelect<String>);

void main() {
  testWidgets('the system language the app has is the help language until one is picked', (tester) async {
    await _pump(tester, system: const [Locale('de', 'DE')]);
    expect(find.descendant(of: _switch, matching: find.text('Deutsch')), findsOneWidget);
    expect(find.descendant(of: _switch, matching: find.byType(LanguageFlag)), findsOneWidget);
  });

  testWidgets('a system language the app lacks gives English help', (tester) async {
    await _pump(tester, system: const [Locale('ja')]);
    expect(find.descendant(of: _switch, matching: find.text('English')), findsOneWidget);
  });

  testWidgets('picking a language is remembered and changes only the help', (tester) async {
    final container = await _pump(tester, system: const [Locale('de')]);
    await tester.tap(_switch);
    await tester.pumpAndSettle();
    for (final a in appLanguages) {
      expect(find.text(a.name), findsWidgets, reason: a.code);
    }
    await tester.tap(find.text('ไทย').last);
    await tester.pumpAndSettle();
    final settings = container.read(deskProvider).settings;
    expect(settings.helpLanguage, 'th');
    // The interface is as it was: the computer's language, as the setting says.
    expect(settings.language, isNull);
    expect(deskLocaleOf(settings.language), isNull);
    expect(find.descendant(of: _switch, matching: find.text('ไทย')), findsOneWidget);
    expect(find.text('Search help'), findsOneWidget);
  });

  testWidgets('a remembered choice beats the computer\'s language', (tester) async {
    await _pump(tester, system: const [Locale('de')], settings: const DeskSettings(helpLanguage: 'ru'));
    expect(find.descendant(of: _switch, matching: find.text('Русский')), findsOneWidget);
  });

  test('the choice is saved with the settings and a bad one is dropped', () {
    final json = deskSettingsToJson(const DeskSettings(helpLanguage: 'pl'));
    expect(deskSettingsFromJson(json).helpLanguage, 'pl');
    expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings())).helpLanguage, isNull);
    expect(deskSettingsFromJson({...json, 'helpLanguage': 'ja'}).helpLanguage, isNull);
    expect(deskSettingsFromJson({...json, 'helpLanguage': 3}).helpLanguage, isNull);
    expect(const DeskSettings(helpLanguage: 'pl').copyWith(scale: 110).helpLanguage, 'pl');
    expect(const DeskSettings(helpLanguage: 'pl').copyWith(helpLanguage: () => null).helpLanguage, isNull);
  });

  test('the interface language is saved with the settings; none follows the computer', () {
    final json = deskSettingsToJson(const DeskSettings(language: 'de'));
    expect(deskSettingsFromJson(json).language, 'de');
    expect(deskSettingsFromJson(deskSettingsToJson(const DeskSettings())).language, isNull);
    expect(deskSettingsFromJson({...json, 'language': 'Deutsch'}).language, isNull);
    expect(const DeskSettings(language: 'de').copyWith(scale: 110).language, 'de');
    expect(const DeskSettings(language: 'de').copyWith(language: () => null).language, isNull);
  });

  test('every language of the desktop picker has a locale and a flag', () {
    for (final a in appLanguages) {
      expect(languageFlagFiles, contains(a.code));
    }
    expect(deskLocaleOf('th'), const Locale('th'));
  });
}
