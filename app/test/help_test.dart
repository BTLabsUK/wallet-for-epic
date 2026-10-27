import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.off, onion: 'abc.onion');
}

/// Help with no wallet open: three confirmations, Tor available, no invoices.
class AppHarness {
  AppHarness({this.advanced = AdvancedPrefs.none});

  /// The Advanced choices the tree runs under (none, as a new wallet).
  final AdvancedPrefs advanced;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          countedConfirmationsProvider.overrideWithValue(BigInt.from(3)),
          phoneTorProvider.overrideWith(_Tor.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
          builder: (context, child) => AdvancedOptions(prefs: advanced, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

final _list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable));

/// Scrolls the page's list until [finder] is built and expects one.
Future<void> _see(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _list.last);
  expect(finder, findsOneWidget);
}

void main() {
  group('shared help content', () {
    test('the phone and the desktop share the structure and most of the words', () {
      final phone = helpTopics(3, platform: HelpPlatform.phone);
      final desk = helpTopics(3, platform: HelpPlatform.desktop);
      expect(desk, hasLength(26));
      // The phone adds "What an address looks like" and keeps every desktop id but the
      // desktop-only folder cleanup.
      expect(phone.map((t) => t.id), containsAll(desk.map((t) => t.id).where((id) => id != HelpId.cleanup)));
      expect(phone.map((t) => t.id), isNot(contains(HelpId.cleanup)));
      expect(phone.where((t) => t.id == HelpId.addresses), hasLength(1));
      for (final t in phone) {
        expect(helpSections.map((s) => s.id), contains(t.section), reason: t.title);
        expect(t.id, isNotEmpty, reason: t.title);
        expect(t.body, isNotEmpty, reason: t.title);
        expect(t.bodyText, isNot(contains('**')), reason: t.title);
        expect(t.bodyText, isNot(contains('[[')), reason: t.title);
      }
      expect(phone.map((t) => t.id).toSet(), hasLength(phone.length));
    });

    test('the phone says PIN, phone and its own places, never a port or a wallet folder', () {
      final all = helpTopics(3, platform: HelpPlatform.phone)
          .map((t) => '${t.title} ${t.short} ${t.bodyText}')
          .join('\n');
      expect(all, contains('your PIN'));
      expect(all, contains('this phone'));
      expect(all, isNot(contains('wallet password')));
      expect(all, isNot(contains('this computer')));
      expect(all, isNot(contains('Port 3415')));
      expect(all, isNot(contains('Wallet folder')));
      expect(all, isNot(contains('Epic address')));
      expect(all, isNot(contains('listener')));
      expect(all.toLowerCase(), isNot(contains(' we ')));
      // The owner's Tor rule: one switch, nothing the user chose changes.
      final tor = helpTopics(3, platform: HelpPlatform.phone).firstWhere((t) => t.id == HelpId.tor);
      expect(tor.bodyText, contains('Settings › Privacy & network › Tor Network'));
      // The owner: the switch names only what goes over Tor, never what does not.
      expect(tor.bodyText, isNot(contains('Not over Tor')));
      expect(tor.bodyText, contains('same address'));
      expect(helpTopics(3, platform: HelpPlatform.phone, tor: false).where((t) => t.id == HelpId.tor), isEmpty);
    });

    test('Offline names the node by its IP address, on both platforms, in every language', () {
      for (final platform in HelpPlatform.values) {
        final modes = helpTopics(3, platform: platform).firstWhere((t) => t.id == HelpId.modes);
        expect(modes.bodyText, contains('In Offline, give the node by its IP address, for example  10.100.10.20:3413 . Names are not looked up.'));
        for (final lang in ['de', 'pl', 'ru', 'zh', 'th']) {
          final local = localizedHelpTopics(lang, 3, platform: platform).firstWhere((t) => t.id == HelpId.modes);
          expect(local.bodyText, contains('10.100.10.20:3413'), reason: '$lang ${platform.name}');
        }
      }
    });

    test('search matches every word, in any field', () {
      final topics = helpTopics(3, platform: HelpPlatform.phone);
      expect(helpQueryWords('  Locked  CHANGE '), ['locked', 'change']);
      final hits = topics.where((t) => helpMatches(t, helpQueryWords('split change'))).map((t) => t.id);
      expect(hits, contains(HelpId.split));
      expect(topics.where((t) => helpMatches(t, helpQueryWords('zzzz'))), isEmpty);
      expect(topics.where((t) => helpMatches(t, const [])), hasLength(topics.length));
    });

    test('places the phone can go to', () {
      expect(helpPlaceGoes('Receive'), isTrue);
      expect(helpPlaceGoes('Settings › Security › Back up recovery phrase'), isTrue);
      expect(helpPlaceGoes('Settings › Privacy & network › Node'), isTrue);
      expect(helpPlaceGoes('Settings › Privacy & network › Epicbox'), isTrue);
      expect(helpPlaceGoes('Settings › Recovery phrase'), isFalse);
      expect(helpPlaceGoes('Restore from a recovery phrase'), isFalse);
    });
  });

  group('help screen', () {
    testWidgets('the index lists every section with a phone topic, and its topics', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const HelpScreen());
      // Maintenance is desktop-only: the phone's index skips a section none of its topics uses.
      final used = helpTopics(3, platform: HelpPlatform.phone).map((t) => t.section).toSet();
      expect(used, isNot(contains('maintenance')));
      for (final s in helpSections.where((s) => used.contains(s.id))) {
        await tester.scrollUntilVisible(find.text(s.title), 300, scrollable: _list);
        expect(find.text(s.title), findsOneWidget);
      }
      // The loop ended at the foot of the page, below the topics: scroll up to them.
      await tester.scrollUntilVisible(find.text('Troubleshooting'), -300, scrollable: _list.last);
      await tester.scrollUntilVisible(find.text('Payments by another wallet'), 300, scrollable: _list.last);
    });

    testWidgets('search narrows the list and marks the words; no match says so', (tester) async {
      final h = AppHarness(advanced: AdvancedPrefs.all);
      await h.pump(tester, const HelpScreen());
      await tester.enterText(find.byKey(helpSearchKey), 'consolidate');
      await tester.pumpAndSettle();
      expect(find.text('Split and consolidate'), findsOneWidget);
      expect(find.text('Fees'), findsNothing);
      expect(find.textContaining('topic'), findsWidgets);
      await tester.enterText(find.byKey(helpSearchKey), 'qwertyu');
      await tester.pumpAndSettle();
      expect(find.text('No help matches "qwertyu"'), findsOneWidget);
    });

    testWidgets('the Outputs topics are not listed or found while Advanced hides Outputs', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const HelpScreen());
      expect(find.text('Split and consolidate'), findsNothing);
      expect(find.text('Smallest or All: which outputs a send spends'), findsNothing);
      await tester.enterText(find.byKey(helpSearchKey), 'consolidate');
      await tester.pumpAndSettle();
      expect(find.text('No help matches "consolidate"'), findsOneWidget);
    });

    testWidgets('a topic opens as a page with its section, body and the related rows', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const HelpScreen());
      await tester.scrollUntilVisible(find.text('Fees'), 300, scrollable: _list);
      await tester.ensureVisible(find.text('Fees'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fees'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(find.text('How Epic Cash works'), findsOneWidget);
      await _see(tester, find.textContaining('Network fee'));
      await _see(tester, find.text('More in this section'));
      await _see(tester, find.text('Confirmations'));
    });

    testWidgets('opening Help on a topic lands on that page, Back on the index', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const HelpScreen(topic: HelpId.phrase));
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(find.text('Your recovery phrase'), findsOneWidget);
      await _see(tester, find.textContaining('your PIN'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicScreen), findsNothing);
      expect(find.byKey(helpSearchKey), findsOneWidget);
    });

    testWidgets('the handshake topic offers the animated sheet', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const HelpScreen(topic: HelpId.handshake));
      await _see(tester, find.text('Show how it works'));
    });

    testWidgets('a HelpButton opens its topic and is 44 dp', (tester) async {
      final h = AppHarness();
      await h.pump(tester, const Scaffold(body: Center(child: HelpButton(HelpId.locked))));
      final size = tester.getSize(find.byType(HelpButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();
      expect(find.text('Locked amounts and change'), findsOneWidget);
    });
  });
}
