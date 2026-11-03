// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/ui/help_language_switch.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/language_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() =>
      const PhoneTorState(phase: PhoneTorPhase.off, onion: 'abc.onion');
}

HelpTopic _topic(String id, String title) => HelpTopic(
  'start',
  title,
  'short $title',
  const [HelpBlock.p('body')],
  id: id,
);

/// Help on its own, in a UI of [locale] (null follows the test's system), with [store] behind the
/// settings.
Future<MemorySecretStore> _pump(
  WidgetTester tester, {
  Locale? locale,
  MemorySecretStore? store,
}) async {
  store ??= MemorySecretStore();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        countedConfirmationsProvider.overrideWithValue(BigInt.from(3)),
        phoneTorProvider.overrideWith(_Tor.new),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HelpScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  group('places with a label', () {
    test('[[label|place]] shows the label and goes to the place', () {
      final parts = helpInline(
        'Öffne [[Empfangen|Receive]] und **Kopieren**, dann [[Settings › Node]].',
      );
      expect(
        parts.map((p) => p.text).join(),
        'Öffne Empfangen und Kopieren, dann Settings › Node.',
      );
      final places = parts.where((p) => p.place).toList();
      expect(places.map((p) => p.text), ['Empfangen', 'Settings › Node']);
      expect(places.map((p) => p.target), ['Receive', 'Settings › Node']);
      expect(parts.where((p) => p.term).single.text, 'Kopieren');
      expect(
        parts.where((p) => !p.place).every((p) => p.target.isEmpty),
        isTrue,
      );
    });

    test(
      'spaces around the bar are dropped, and search sees the label only',
      () {
        final parts = helpInline(
          '[[ Einstellungen › Knoten | Settings › Node ]]',
        );
        expect(parts.single.text, 'Einstellungen › Knoten');
        expect(parts.single.target, 'Settings › Node');
        final topic = HelpTopic('how', 't', 's', const [
          HelpBlock.p('Siehe [[Knoten|Node]].'),
        ]);
        expect(topic.bodyText, contains('Knoten'));
        expect(topic.bodyText, isNot(contains('Node')));
      },
    );

    test('a translated place goes where its English target goes', () {
      expect(helpPlaceGoes('Receive'), isTrue);
      expect(helpPlaceGoes('Empfangen'), isFalse);
    });

    testWidgets(
      'the link says the label and is tappable only for a place the phone has',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (_, _, _) => const Column(
                  children: [
                    HelpBlockView(
                      block: HelpBlock.p('Öffne [[Empfangen|Receive]].'),
                      style: TextStyle(),
                    ),
                    HelpBlockView(
                      block: HelpBlock.p(
                        'Dann [[Wiederherstellen|Restore from a recovery phrase]].',
                      ),
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.text('Empfangen'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Empfangen'),
            matching: find.byType(InkWell),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Wiederherstellen', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('Wiederherstellen', findRichText: true),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
      },
    );
  });

  group('help in a language', () {
    test(
      'a missing topic stays English, a translated one is the translation',
      () {
        final english = [
          _topic('a', 'Alpha'),
          _topic('b', 'Beta'),
          _topic('c', 'Gamma'),
        ];
        final merged = mergeHelpTopics(english, [
          _topic('b', 'Beta auf Deutsch'),
        ]);
        expect(merged.map((t) => t.title), [
          'Alpha',
          'Beta auf Deutsch',
          'Gamma',
        ]);
        expect(mergeHelpTopics(english, const []).map((t) => t.title), [
          'Alpha',
          'Beta',
          'Gamma',
        ]);
        // The translation's own order and extras do not matter; the English list rules.
        final shuffled = mergeHelpTopics(english, [
          _topic('c', 'Gamma de'),
          _topic('z', 'Extra'),
          _topic('a', 'Alpha de'),
        ]);
        expect(shuffled.map((t) => t.title), ['Alpha de', 'Beta', 'Gamma de']);
      },
    );

    test('sections merge by id the same way', () {
      const translated = <HelpSection>[
        (
          id: 'how',
          title: 'So funktioniert es',
          lede: 'Beide Wallets',
          art: 'help-how',
        ),
      ];
      final merged = mergeHelpSections(helpSections, translated);
      expect(merged.map((s) => s.id), helpSections.map((s) => s.id));
      expect(
        merged.firstWhere((s) => s.id == 'how').title,
        'So funktioniert es',
      );
      expect(
        merged.firstWhere((s) => s.id == 'start').title,
        'Getting started',
      );
    });

    test('every language lists the English topics and sections, in order', () {
      for (final platform in HelpPlatform.values) {
        final english = helpTopics(3, platform: platform);
        for (final a in appLanguages) {
          final topics = localizedHelpTopics(a.code, 3, platform: platform);
          expect(
            topics.map((t) => t.id),
            english.map((t) => t.id),
            reason: '${a.code} ${platform.name}',
          );
          expect(
            topics.map((t) => t.section),
            english.map((t) => t.section),
            reason: '${a.code} ${platform.name}',
          );
        }
      }
      for (final a in appLanguages) {
        expect(
          localizedHelpSections(a.code).map((s) => s.id),
          helpSections.map((s) => s.id),
          reason: a.code,
        );
      }
    });

    test('English and a code the app does not have give the English text', () {
      final english = helpTopics(3, platform: HelpPlatform.phone);
      for (final code in const ['en', 'ja', '']) {
        final topics = localizedHelpTopics(
          code,
          3,
          platform: HelpPlatform.phone,
        );
        expect(
          topics.map((t) => t.title),
          english.map((t) => t.title),
          reason: code,
        );
      }
      expect(localizedHelpSections('ja'), helpSections);
      expect(helpTranslated('en'), isTrue);
    });

    test('the system language: the first of the phone\'s languages the app has, else English', () {
      expect(
        systemHelpLanguage(const [Locale('de', 'AT'), Locale('en')]),
        'de',
      );
      expect(systemHelpLanguage(const [Locale('ja'), Locale('th')]), 'th');
      expect(systemHelpLanguage(const [Locale('ja'), Locale('ko')]), 'en');
      expect(systemHelpLanguage(const []), 'en');
      expect(
        systemHelpLanguage(const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ]),
        'zh',
      );
    });

    test('the invoice topics come from the help language\'s strings', () {
      expect(helpStrings('de').localeName, 'de');
      expect(helpStrings('th').localeName, 'th');
      expect(helpStrings('ja').localeName, 'en');
    });
  });

  group('the Help language switch (phone)', () {
    testWidgets(
      'follows the UI language until one is picked, and shows its flag and name',
      (tester) async {
        await _pump(tester, locale: const Locale('de'));
        final switchFinder = find.byKey(helpLanguageKey);
        expect(
          find.descendant(of: switchFinder, matching: find.text('Deutsch')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: switchFinder,
            matching: find.byType(LanguageFlag),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'picking a language changes the help only, remembers it, and leaves the UI alone',
      (tester) async {
        final store = await _pump(tester, locale: const Locale('de'));
        expect(find.text('Hilfe'), findsOneWidget);
        await tester.tap(find.byKey(helpLanguageKey));
        await tester.pumpAndSettle();
        for (final a in appLanguages) {
          expect(find.text(a.name), findsWidgets, reason: a.code);
        }
        expect(
          find.byType(LanguageFlag),
          findsNWidgets(appLanguages.length + 1),
        );
        await tester.tap(find.text('ไทย').last);
        await tester.pumpAndSettle();
        expect(store.values['app.helpLanguage'], 'th');
        expect(store.values.containsKey('app.language'), isFalse);
        expect(
          find.descendant(
            of: find.byKey(helpLanguageKey),
            matching: find.text('ไทย'),
          ),
          findsOneWidget,
        );
        // The screen's own words are still German.
        expect(find.text('Hilfe'), findsOneWidget);
        expect(
          Localizations.localeOf(tester.element(find.byType(HelpScreen))),
          const Locale('de'),
        );
      },
    );

    testWidgets(
      'a remembered help language beats the UI language at the next start',
      (tester) async {
        final store = MemorySecretStore()..values['app.helpLanguage'] = 'pl';
        await _pump(tester, locale: const Locale('en'), store: store);
        expect(
          find.descendant(
            of: find.byKey(helpLanguageKey),
            matching: find.text('Polski'),
          ),
          findsOneWidget,
        );
        expect(find.text(_l.helpTitle), findsOneWidget);
      },
    );

    testWidgets('a code the app does not have is forgotten', (tester) async {
      final store = MemorySecretStore()..values['app.helpLanguage'] = 'ja';
      await _pump(tester, locale: const Locale('ru'), store: store);
      expect(
        find.descendant(
          of: find.byKey(helpLanguageKey),
          matching: find.text('Русский'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'the switch sits in the header and the topics stay reachable at 360 dp',
      (tester) async {
        await _pump(tester, locale: const Locale('ru'));
        tester.view.physicalSize = const Size(360 * 3, 640 * 3);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getTopLeft(find.byKey(helpLanguageKey)).dy,
          lessThan(kToolbarHeight),
        );
      },
    );
  });
}
