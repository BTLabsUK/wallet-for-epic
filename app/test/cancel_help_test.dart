// SPDX-License-Identifier: Apache-2.0
// Help › "Cancelling a payment" (2026-10-25): one topic on both platforms, in six
// languages, with Sending / Receiving / Requests headings that the quiet line beside every
// Cancel button opens it at; the words a stuck user searches for find it; no protocol jargon.
import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/cancel_note.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.off, onion: 'abc.onion');
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [countedConfirmationsProvider.overrideWithValue(BigInt.from(3)), phoneTorProvider.overrideWith(_Tor.new)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
        builder: (context, child) => AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the topic', () {
    for (final platform in HelpPlatform.values) {
      final topic = helpTopics(3, platform: platform).firstWhere((t) => t.id == HelpId.cancel);

      test('${platform.name}: three headings in order, under When something goes wrong', () {
        expect(topic.section, 'trouble');
        expect(topic.title, 'Cancelling a payment');
        expect([for (final b in topic.body) if (b.kind == HelpBlockKind.h) b.anchor], [HelpAnchor.sending, HelpAnchor.receiving, HelpAnchor.requests]);
        expect([for (final b in topic.body) if (b.kind == HelpBlockKind.h) b.text], ['Sending', 'Receiving', 'Invoices (experimental)']);
        // Every other block has no anchor; a heading is never a list.
        for (final b in topic.body) {
          expect(b.anchor.isNotEmpty, b.kind == HelpBlockKind.h, reason: b.text);
        }
      });

      // WAL-20: once the other side holds what it needs to finish the payment, Cancel offers two
      // ways: Move coins back (one network fee) and the free Unlock coins (B-04 names).
      test('${platform.name}: names the two ways to cancel, the fee, and what may still finish means', () {
        final all = topic.bodyText;
        // The bold names render with their own spacing: check the name and its sentence apart.
        expect(all, contains('Move coins back'));
        expect(all, contains('moves the coins back to this wallet first, for the normal network fee'));
        expect(all, contains('Unlock coins'));
        expect(all, contains('is free and moves nothing'));
        expect(all, contains('if it does, it shows as paid'));
        expect(all, isNot(contains('offered with the cancel')));
        // Plain words (the owner, 2026-10-30): no signatures, halves or kernels anywhere.
        for (final jargon in ['signature', 'signed', 'half', 'output', 'input']) {
          expect(all, isNot(contains(jargon)), reason: jargon);
        }
      });

      test('${platform.name}: the words a stuck user types find it; no jargon', () {
        for (final word in ['cancel', 'stuck', 'refund', 'undo']) {
          expect(helpMatches(topic, helpQueryWords(word)), isTrue, reason: word);
        }
        final all = '${topic.title} ${topic.short} ${topic.bodyText}';
        for (final jargon in ['slate', 'S2', 'kernel', 'finalize', 'mempool']) {
          expect(all, isNot(contains(jargon)), reason: jargon);
        }
        // The rules: a waiting send is certain, a signed receive is not, a paid request is not.
        expect(all, contains('Cancel is certain'));
        expect(all, contains('It is not certain'));
        expect(all, contains('could still finish the payment'));
        expect(all, contains('1,440 blocks'));
      });
    }

    test('every language keeps the headings and their anchors', () {
      for (final lang in ['de', 'pl', 'ru', 'zh', 'th']) {
        for (final platform in HelpPlatform.values) {
          final t = localizedHelpTopics(lang, 3, platform: platform).firstWhere((t) => t.id == HelpId.cancel);
          expect([for (final b in t.body) if (b.kind == HelpBlockKind.h) b.anchor], [HelpAnchor.sending, HelpAnchor.receiving, HelpAnchor.requests], reason: lang);
          expect(t.title, isNot('Cancelling a payment'), reason: lang);
        }
      }
    });
  });

  group('the quiet line', () {
    testWidgets('says its case, then More in Help opens the topic at the heading', (tester) async {
      await _pump(
        tester,
        Scaffold(body: Center(child: CancelNote(text: englishStrings.txDetailsCancelWhileReported, anchor: HelpAnchor.receiving))),
      );
      expect(find.text('Cancel is unavailable while the sender reports it posted.'), findsOneWidget);
      expect(find.text('How cancelling works'), findsOneWidget);
      await tester.tap(find.text('How cancelling works'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(tester.widget<HelpTopicScreen>(find.byType(HelpTopicScreen)).topic.id, HelpId.cancel);
      // The page arrives scrolled to the Receiving heading: it is on screen without scrolling
      // by hand (the title above may have scrolled away).
      expect(find.text('Receiving'), findsOneWidget);
      final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getRect(find.text('Receiving')).top, inInclusiveRange(0, screen));
    });

    testWidgets('the phone Help lists the topic under When something goes wrong', (tester) async {
      await _pump(tester, const HelpScreen());
      final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Cancelling a payment'), 300, scrollable: list.last);
      expect(find.text('Cancelling a payment'), findsOneWidget);
    });
  });
}
