// The phone's pairing screens (SPEC 2.1-2.6, 2.11) against the fake engine: the three ways in,
// an online invite from making to answered, entering words or a link, the incoming invite,
// the words check and what follows it, Pending invites, and a contact's Pairing block.
import 'package:epic_wallet/src/sas_table.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/pairing_text.dart' show pairingSpan;
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/pairing/pair_check.dart';
import 'package:epic_wallet/src/ui/pairing/pair_incoming.dart';
import 'package:epic_wallet/src/ui/pairing/pair_screen.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_notices.dart' show PairingNotices, pairingNoticeOf;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart';
import 'package:epic_wallet/src/ui/pairing/pending_invites.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/experimental.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => false;

  @override
  Future<bool> configured() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

class _Harness {
  _Harness({String? seenAs = 'the owner'}) {
    if (seenAs != null) store.values['pairing.seen_as'] = seenAs;
  }

  final session = FakeWalletSession();
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);

  FakePairing get api => session.pairing;

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  Future<void> pump(WidgetTester tester, Widget home, {PairNet? net, bool settle = true}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          // On from the first frame, before the stored settings load.
          pairingOnProvider.overrideWithValue(true),
          invoicesOnProvider.overrideWithValue(true),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          pushPlatformProvider.overrideWithValue(_NoPush()),
          slateFilesProvider.overrideWithValue(files),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          if (net != null) pairNetProvider.overrideWithValue(net),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await _frames(tester);
    }
  }
}

/// Frames for a screen with a spinner, which never settles.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String? _notice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.text;

void main() {
  test('a key check LEPIC refuses (one a day) is said, not silent (PAIR-AND-16)', () {
    final n = pairingNoticeOf(_l, const PairingEvent(PairingEventKind.keyCheckRefused, pairingId: 'p', name: 'Anna'));
    expect(n?.text, _l.noticeKeyCheckRefused('Anna'));
  });

  group('Pair', () {
    testWidgets('offers in person, online and entering a link or words', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen());
      expect(find.text(_l.pairLead), findsOneWidget);
      for (final t in [_l.pairInPerson, _l.pairOnline, _l.pairEnter]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.byKey(pairOnlineKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairOnlineTitle), findsOneWidget);
    });

    testWidgets('offline: Online goes by hand, as with Epicbox off (PAIR-LNX-6)', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), net: PairNet.offline);
      final online = tester.widget<ListTile>(find.descendant(of: find.byKey(pairOnlineKey), matching: find.byType(ListTile)));
      expect(online.enabled, isTrue);
      expect(find.text(_l.pairOfflineHint), findsWidgets);
      expect(_notice(tester), _l.pairOfflineHint);
      await tester.tap(find.byKey(pairOnlineKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairOnlineLeadByHand), findsOneWidget);
      expect(find.text(_l.pairWordsNeedEpicbox, skipOffstage: false), findsOneWidget);
      expect(find.byKey(pairUseWordsKey), findsNothing);
      await tester.tap(find.byKey(pairShareKey));
      await tester.pumpAndSettle();
      expect(h.api.records.single.state, PairingState.pendingInvite);
      expect(find.text(_l.pairInviteSentTitle), findsOneWidget);
    });

    testWidgets('names the contact it pairs with', (tester) async {
      final h = _Harness();
      await h.pump(tester, PairScreen(contact: Contact(id: 'c1', name: 'Anna', address: _anna)));
      expect(find.text(_l.pairWithName('Anna')), findsOneWidget);
    });
  });

  group('online', () {
    testWidgets('the invite: 24 hours by default, copied, then sent, then answered', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairOnlineScreen());
      final expiry = tester.widget<SegmentedButton<Duration>>(find.byType(SegmentedButton<Duration>));
      expect(expiry.selected, {const Duration(hours: 24)});
      expect(find.text(_l.pairShareWarning), findsOneWidget);
      await tester.tap(find.byKey(pairShareKey));
      await tester.pumpAndSettle();
      final invite = h.api.records.single;
      expect(invite.state, PairingState.pendingInvite);
      expect(h.files.sharedTexts.single, contains(invite.inviteLink!));
      expect(h.files.sharedTexts.single, startsWith('the owner '));
      // The link ends the text: a one-line field drops the line breaks (PAIR-LNX-1).
      expect(h.files.sharedTexts.single, endsWith(invite.inviteLink!));
      expect(find.text(_l.pairInviteSentTitle), findsOneWidget);
      expect(find.text(_l.pairInviteSentBodyAnyone), findsOneWidget);

      h.api.answerInvite(invite.id, name: 'Anna');
      await tester.pumpAndSettle();
      expect(find.byType(CheckWordsScreen), findsOneWidget);
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
    });

    testWidgets('without the name they will see, nothing is made', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const PairOnlineScreen());
      await tester.tap(find.byKey(pairShareKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairSeenAsMissing), findsOneWidget);
      expect(h.api.records, isEmpty);
    });

    testWidgets('a name typed and Share tapped at once, keyboard still up: the invite carries it (PAIR-AND-1)', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const PairOnlineScreen());
      await tester.enterText(find.byKey(pairNameFieldKey), 'Ola');
      await tester.pump();
      await tester.tap(find.byKey(pairShareKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairSeenAsMissing), findsNothing);
      expect(h.api.records.single.state, PairingState.pendingInvite);
      expect(h.files.sharedTexts.single, startsWith('Ola '));
      await tester.pump(const Duration(seconds: 1));
      expect(h.store.values['pairing.seen_as'], 'Ola', reason: 'kept once typing paused');
    });

    testWidgets('Cancel invite asks first, then cancels', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairOnlineScreen());
      await tester.tap(find.byKey(pairShareKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairCancelInviteKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairCancelInviteTitle(_l.pairUnnamedInvite)), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(_l.pairCancelInvite)));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('cancelInvite'));
      expect(find.byType(PairOnlineScreen), findsNothing);
    });

    testWidgets('pairing words opened again: the open invite shows again, no new one each visit', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairingWordsScreen());
      final first = h.api.records.single;
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester, const PairingWordsScreen());
      expect(h.api.records.single.id, first.id);
      expect(h.api.calls.where((c) => c == 'makeInvite'), hasLength(1));
      for (final w in first.inviteWords) {
        expect(find.text(w.name), findsOneWidget, reason: w.name);
      }
    });

    testWidgets('pairing words: five of them, good for 10 minutes', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairingWordsScreen());
      final invite = h.api.records.single;
      expect(invite.inviteWords, hasLength(pairingWordCount));
      expect(find.text(_l.pairWordsLead), findsOneWidget);
      expect(find.text(_l.pairWordsFooter), findsOneWidget);
      for (final w in invite.inviteWords) {
        expect(find.text(w.name), findsOneWidget, reason: w.name);
      }
    });
    testWidgets('pairing words with no pairing relay reachable: says so, not that the relay is down (report utc3fhjj)', (tester) async {
      final h = _Harness();
      h.api.relayUnreachable = true;
      // No words: the card's spinner never settles.
      await h.pump(tester, const PairingWordsScreen(), settle: false);
      await _frames(tester);
      expect(find.text(_l.pairNoRelay), findsOneWidget);
      expect(find.text(_l.pairRelayUnreachableTitle), findsNothing);
    });
  });

  group('enter a link or words', () {
    testWidgets('words nobody offered: says so, nothing is stored', (tester) async {
      final h = _Harness();
      await h.pump(tester, const EnterLinkScreen());
      final words = fakeSasWords('nobody', count: pairingWordCount).map((w) => w.name).join(' ');
      await tester.enterText(find.byKey(pairEnterFieldKey), '$words ');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairEnterNotFound), findsOneWidget);
      expect(h.api.records, isEmpty);
    });

    testWidgets('pairing words pasted with their emoji, as the copy once put them, open the invite', (tester) async {
      final h = _Harness();
      final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Northwind'));
      final five = [sasTable[7], sasTable[42], sasTable[7], sasTable[200], sasTable[3]];
      h.api.wordsInvites[five.map((w) => w.name).join(' ')] = preview;
      await h.pump(tester, const EnterLinkScreen());
      await tester.enterText(find.byKey(pairEnterFieldKey), '${five.map((w) => '${w.emoji} ${w.name}').join('  ')}\n');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      // The incoming invite's countdown never settles.
      await _frames(tester);
      expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
    });

    testWidgets('words with no pairing relay reachable: says so, not "no invite found"', (tester) async {
      final h = _Harness();
      h.api.relayUnreachable = true;
      await h.pump(tester, const EnterLinkScreen());
      final words = fakeSasWords('nobody', count: pairingWordCount).map((w) => w.name).join(' ');
      await tester.enterText(find.byKey(pairEnterFieldKey), '$words ');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairNoRelay), findsOneWidget);
      expect(find.text(_l.pairEnterNotFound), findsNothing);
    });

    testWidgets('a word being typed is completed from the table', (tester) async {
      final h = _Harness();
      await h.pump(tester, const EnterLinkScreen());
      final word = fakeSasWords('one', count: 1).single;
      await tester.enterText(find.byKey(pairEnterFieldKey), word.name.substring(0, 3));
      await tester.pumpAndSettle();
      final suggestion = find.widgetWithText(ActionChip, word.name);
      expect(suggestion, findsWidgets);
      await tester.tap(suggestion.first);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(pairEnterFieldKey));
      expect(field.controller!.text, '${word.name} ');
    });

    testWidgets('this wallet\'s own invite: This is your own code, no Pair with … (PAIR-AND-2)', (tester) async {
      final h = _Harness();
      final mine = await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24));
      await h.pump(tester, const EnterLinkScreen());
      await tester.enterText(find.byKey(pairEnterFieldKey), mine.inviteLink!);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await _frames(tester);
      expect(find.text(_l.pairOwnCode), findsOneWidget);
      expect(find.text(_l.pairIncomingTitle('the owner')), findsNothing);
      expect(h.api.records.single.state, PairingState.pendingInvite, reason: 'nothing answered');
    });

    testWidgets('the incoming invite with no name kept: the field stays while typing, and Pair with the keyboard up uses it (PAIR-AND-1)', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const EnterLinkScreen());
      await tester.enterText(find.byKey(pairEnterFieldKey), h.api.inviteLinkFrom(name: 'Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await _frames(tester);
      expect(find.byKey(pairNameFieldKey), findsOneWidget);
      await tester.enterText(find.byKey(pairNameFieldKey), 'O');
      await tester.pump();
      expect(find.byKey(pairNameFieldKey), findsOneWidget, reason: 'the field does not go after the first letter');
      await tester.enterText(find.byKey(pairNameFieldKey), 'Ola');
      await tester.pump();
      await tester.tap(find.byKey(incomingPairKey));
      await _frames(tester);
      expect(find.text(_l.pairSeenAsMissing), findsNothing);
      expect(h.api.records.single.state, PairingState.pendingReply);
    });

    testWidgets('the incoming invite with the keyboard up: the name field and Pair stay above it (PAIR-AND-17)', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const EnterLinkScreen());
      await tester.enterText(find.byKey(pairEnterFieldKey), h.api.inviteLinkFrom(name: 'Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await _frames(tester);
      // Edge-to-edge Android 15+: the keyboard is a view inset the sheet itself must clear.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await _frames(tester);
      final keyboardTop = 2340 / 3 - 300;
      expect(tester.getBottomLeft(find.byKey(incomingPairKey)).dy, lessThanOrEqualTo(keyboardTop));
      expect(tester.getBottomLeft(find.byKey(pairNameFieldKey)).dy, lessThanOrEqualTo(keyboardTop));
    });

    testWidgets('an invite link opens the incoming invite; Pair answers and waits', (tester) async {
      final h = _Harness();
      await h.pump(tester, const EnterLinkScreen());
      final link = h.api.inviteLinkFrom(name: 'Northwind', kind: PairingParty.exchange, asksInvoices: true);
      await tester.enterText(find.byKey(pairEnterFieldKey), link);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await _frames(tester);
      expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
      expect(find.byType(ClaimedNameBadge), findsOneWidget);
      // The claimed kind and name prove nothing: invoices stay off until the user says so.
      final allow = tester.widget<Switch>(find.byKey(incomingAllowKey));
      expect(allow.value, isFalse);
      await tester.tap(find.byKey(incomingPairKey));
      await _frames(tester);
      final answered = h.api.records.single;
      expect((answered.state, answered.asksInvoices), (PairingState.pendingReply, false));
      expect(find.byType(PairingWaitingScreen), findsOneWidget);
      expect(find.text(_l.pairWaitingTitle('Northwind')), findsOneWidget);

      h.api.confirmAnswer(answered.id);
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('an expired invite says so and stores nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester, const EnterLinkScreen());
      await tester.enterText(
        find.byKey(pairEnterFieldKey),
        h.api.inviteLinkFrom(name: 'Anna', expiresIn: const Duration(minutes: -5)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(pairEnterGoKey));
      await tester.pumpAndSettle();
      expect(find.byType(PairingOutcomeScreen), findsOneWidget);
      expect(find.text(_l.pairExpiredTitle), findsOneWidget);
      expect(h.api.records, isEmpty);
    });

    testWidgets('the relay is not reachable: the answer goes by hand', (tester) async {
      final h = _Harness();
      h.api.relayUnreachable = true;
      final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
      final answered = await h.api.acceptInvite(token: preview.token, name: 'the owner');
      await h.pump(tester, PairingWaitingScreen(pairingId: answered.id), settle: false);
      expect(find.text(_l.pairRelayUnreachableTitle), findsOneWidget);
      await tester.tap(find.byKey(waitingByHandKey));
      await _frames(tester);
      expect(find.byType(PairingByHandScreen), findsOneWidget);
      expect(find.text(_l.pairByHandLead('Anna')), findsOneWidget);
    });
    testWidgets('waiting while this wallet is Offline or has Epicbox off: says which, not a relay fault (qa-linux)', (tester) async {
      for (final (net, text) in [(PairNet.offline, _l.pairOfflineHint), (PairNet.epicboxOff, _l.pairEpicboxOffNotice)]) {
        final h = _Harness();
        final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
        final answered = await h.api.acceptInvite(token: preview.token, name: 'the owner', byHand: true);
        await h.pump(tester, PairingWaitingScreen(pairingId: answered.id), net: net, settle: false);
        expect(find.text(text), findsOneWidget, reason: '$net');
        expect(find.text(_l.pairRelayUnreachableTitle), findsNothing, reason: '$net');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('check the words', () {
    Future<PairingRecord> open(WidgetTester tester, _Harness h, {String? contactId}) async {
      final r = h.api.seedPaired(id: 'p1', name: 'Anna', state: PairingState.paired, contactId: contactId);
      await h.pump(tester, const CheckWordsScreen(pairingId: 'p1'));
      return r;
    }

    testWidgets('shows the four words; They match verifies and offers to save the contact', (tester) async {
      final h = _Harness();
      final r = await open(tester, h);
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      for (final w in r.sas) {
        expect(find.text(w.name), findsOneWidget, reason: w.name);
      }
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pumpAndSettle();
      expect((await h.api.pairing('p1'))!.state, PairingState.verified);
      expect(find.text(_l.sasMatchedTitle('Anna')), findsOneWidget);
      expect(find.text(_l.pairSaveContactTitle('Anna')), findsOneWidget);
      // Never "already in your contacts": the user picks, a new contact or one of theirs.
      expect(find.byKey(resultSaveNewKey), findsOneWidget);
      expect(find.byKey(resultAddToKey), findsOneWidget);

      await tester.tap(find.byKey(resultSaveNewKey));
      await tester.pumpAndSettle();
      expect(find.byType(ContactEditScreen), findsOneWidget);
      await tester.tap(find.text(_l.contactsSave));
      await tester.pumpAndSettle();
      final saved = (await h.session.contacts()).singleWhere((c) => c.name == 'Anna');
      expect((await h.api.pairing('p1'))!.contactId, saved.id);
      expect(_notice(tester), _l.pairSavedAs('Anna'));
      expect(find.text(_l.pairSaveContactTitle('Anna')), findsNothing);
    });

    testWidgets('a re-pair: a contact of its name with an old pairing is offered first, and Add to starts the key check (PAIR-LNX-7)', (tester) async {
      final h = _Harness();
      final anna = await h.session.saveContact(contact: Contact(id: '', name: ' anna  ', address: _anna));
      h.api.seedPaired(id: 'old', name: 'Anna', state: PairingState.verified, contactId: anna.id);
      await open(tester, h);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pumpAndSettle();
      expect(find.byKey(resultAddToNamedKey), findsOneWidget);
      expect(find.text(_l.pairAddToNamed(anna.name)), findsOneWidget);
      expect(find.byKey(resultSaveNewKey), findsOneWidget, reason: 'the other choices stay');
      expect(find.byKey(resultAddToKey), findsOneWidget);
      await tester.tap(find.byKey(resultAddToNamedKey));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('attach'));
      // The fake's key check found the old keys: the new pairing folded into the old one.
      expect(await h.api.pairing('p1'), isNull);
      expect((await h.api.pairing('old'))!.contactId, anna.id);
      // Not an empty page: the contact, whose notice says the keys are back.
      expect(find.byType(PairingResultScreen), findsNothing);
      expect(find.byType(ContactPage), findsOneWidget);
    });

    testWidgets('re-pair answered while the old contact page is open: the notice opens the new words, They match shows the result (PAIR-AND-15)', (tester) async {
      final h = _Harness();
      final anna = await h.session.saveContact(contact: Contact(id: '', name: 'Anna', address: _anna));
      h.api.seedPaired(id: 'old', name: 'Anna', state: PairingState.verified, contactId: anna.id);
      await h.pump(tester, const Scaffold(body: PairingNotices()));
      // The test font's wide glyphs: the notice with its action needs more than 360 dp.
      tester.view.physicalSize = const Size(1800, 2340);
      final invite = await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1));
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => ContactPage(contactId: anna.id))));
      await tester.pumpAndSettle();
      h.api.answerInvite(invite.id, name: 'Anna');
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(tester.element(find.byType(Navigator).first));
      c.read(noticeProvider)!.action!.onPressed();
      await tester.pumpAndSettle();
      expect(find.byType(CheckWordsScreen), findsOneWidget);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('check:match'));
      expect((await h.api.pairing(invite.id))!.state, PairingState.verified);
      expect(find.byType(PairingResultScreen), findsOneWidget);
    });

    testWidgets('the notice\'s Check the words opens the words even after the widget that showed it was rebuilt away (PAIR-AND-15)', (tester) async {
      final h = _Harness();
      await h.pump(tester, const Scaffold(body: PairingNotices(key: ValueKey('first'))));
      tester.view.physicalSize = const Size(1800, 2340);
      final invite = await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1));
      h.api.answerInvite(invite.id, name: 'Anna');
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(tester.element(find.byType(Navigator).first));
      final action = c.read(noticeProvider)!.action!;
      // The home screen rebuilt: a new PairingNotices, the one that showed the notice is gone.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: PairingNotices(key: ValueKey('second')))));
      await tester.pumpAndSettle();
      action.onPressed();
      await tester.pumpAndSettle();
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('no contact of its name, or two unpaired ones: nothing is suggested (PAIR-LNX-7)', (tester) async {
      final h = _Harness();
      await h.session.saveContact(contact: Contact(id: '', name: 'Anna', address: _anna));
      await h.session.saveContact(contact: Contact(id: '', name: 'ANNA', address: 'esOtherKeyForAnnaTwo@epicbox.example'));
      await open(tester, h);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pumpAndSettle();
      expect(find.byKey(resultAddToNamedKey), findsNothing);
      expect(find.byKey(resultSaveNewKey), findsOneWidget);
    });

    testWidgets('They don\'t match asks, then drops the pairing', (tester) async {
      final h = _Harness();
      await open(tester, h);
      await tester.tap(find.byKey(checkNoMatchKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.sasNoMatchTitle), findsOneWidget);
      expect(find.text(_l.sasNoMatchBody), findsOneWidget);
      await tester.tap(find.byKey(checkStopKey));
      await tester.pumpAndSettle();
      expect(await h.api.pairing('p1'), isNull);
      expect(find.byType(CheckWordsScreen), findsNothing);
    });

    testWidgets('Skip for now: paired, not verified, invoices wait', (tester) async {
      final h = _Harness();
      await open(tester, h, contactId: 'c1');
      await tester.tap(find.byKey(checkSkipKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.sasSkippedTitle('Anna')), findsOneWidget);
      expect(find.text(_l.sasSkippedBody('Anna')), findsOneWidget);
      expect((await h.api.pairing('p1'))!.state, PairingState.paired);
    });
  });

  test('a span counts whole minutes: a fresh 24 h invite is 23 h 59 min, not 1 d 0 h', () {
    expect(pairingSpan(_l, const Duration(hours: 23, minutes: 59, seconds: 59)), _l.pairDurHours(23, 59));
    expect(pairingSpan(_l, const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)), _l.pairDurDays(6, 23));
    expect(pairingSpan(_l, const Duration(minutes: 1, seconds: 30)), _l.pairDurMinutes(1));
    expect(pairingSpan(_l, const Duration(seconds: 59)), _l.pairDurUnderMinute);
  });

  group('Contacts', () {
    testWidgets('a pairing in no contact is listed by its name with Not in contacts and its menu (PAIR-AND-8)', (tester) async {
      final h = _Harness();
      h.api.seedPaired(id: 'p-floo', name: 'Floo C', state: PairingState.verified);
      await h.pump(tester, const ContactsScreen());
      expect(find.text(_l.contactsEmptyTitle), findsNothing, reason: 'not the empty book');
      expect(find.text('Floo C'), findsOneWidget);
      expect(find.text(_l.pairNotInContacts), findsOneWidget);
      await tester.tap(find.byKey(contactsOrphanMenuKey('p-floo')));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairSaveNewContact), findsOneWidget);
      expect(find.text(_l.pairAddToAContact), findsOneWidget);
      await tester.tap(find.text(_l.contactRemovePairing));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, _l.contactRemove).last);
      await tester.pumpAndSettle();
      expect(await h.api.pairing('p-floo'), isNull);
      expect(find.text('Floo C'), findsNothing);
    });
  });

  testWidgets('a contact saved without an address keeps none: its name and note change and save (PAIR-AND-9)', (tester) async {
    final h = _Harness();
    final saved = await h.session.saveContact(contact: Contact(id: '', name: 'Floo C'));
    await h.pump(tester, ContactEditScreen(contact: saved));
    await tester.enterText(find.widgetWithText(TextField, _l.contactsNameLabel).first, 'Floo Cee');
    await tester.tap(find.text(_l.contactsSave));
    await tester.pumpAndSettle();
    expect(find.text(_l.contactsAddressMissing), findsNothing);
    expect((await h.session.contacts()).single.name, 'Floo Cee');
  });

  testWidgets('a new plain contact still needs an address (PAIR-AND-9)', (tester) async {
    final h = _Harness();
    await h.pump(tester, const ContactEditScreen());
    await tester.enterText(find.widgetWithText(TextField, _l.contactsNameLabel).first, 'Nobody');
    await tester.tap(find.text(_l.contactsSave));
    await tester.pumpAndSettle();
    expect(find.text(_l.contactsAddressMissing), findsOneWidget);
    expect(await h.session.contacts(), isEmpty);
  });

  testWidgets('a scan of the same card again replaces the unchecked one; the row has Remove (PAIR-AND-7)', (tester) async {
    final h = _Harness();
    final first = await h.api.scanCard(cardId: (await h.api.showCard(name: 'the owner')).id, text: h.api.cardLinkFrom('Ola'));
    final second = await h.api.scanCard(cardId: (await h.api.showCard(name: 'the owner')).id, text: h.api.cardLinkFrom('Ola'));
    await dropOlderInPersonPairings(h.api, second);
    expect(await h.api.pairing(first.id), isNull);
    expect((await h.api.pairing(second.id))!.state, PairingState.paired);
    await h.pump(tester, const PendingInvitesScreen());
    expect(find.text('Ola'), findsOneWidget);
    await tester.tap(find.byKey(pendingRowMenuKey(second.id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.contactRemovePairing));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, _l.contactRemove).last);
    await tester.pumpAndSettle();
    expect(await h.api.pairing(second.id), isNull);
  });

  testWidgets('by hand: the inviter takes the answer, sends the confirm back, then checks the words (PAIR-AND-10)', (tester) async {
    // The inviter, Epicbox off: an invite, then the answer pasted by hand.
    final a = _Harness();
    final invite = await a.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24));
    final reply = fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Ola'});
    await a.pump(tester, const EnterLinkScreen(), net: PairNet.epicboxOff);
    await tester.enterText(find.byKey(pairEnterFieldKey), reply);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pairEnterGoKey));
    await _frames(tester);
    expect(find.byType(PairingByHandScreen), findsOneWidget, reason: 'the confirm goes back first');
    expect(find.text(_l.pairConfirmByHandLead('Ola')), findsOneWidget);
    final confirm = await a.api.confirmLink(invite.id);
    expect(find.text(confirm), findsOneWidget);
    await tester.tap(find.byKey(byHandCheckWordsKey));
    await _frames(tester);
    expect(find.byType(CheckWordsScreen), findsOneWidget);
    await tester.tap(find.byKey(checkMatchKey));
    await tester.pumpAndSettle();
    expect((await a.api.pairing(invite.id))!.state, PairingState.verified);
  });

  testWidgets('by hand: the one who answered pastes the confirm and its words open (PAIR-AND-10)', (tester) async {
    final a = _Harness();
    final invite = await a.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24));
    final confirm = await a.api.confirmLink(invite.id);
    final b = _Harness();
    final preview = await b.api.openInvite(invite.inviteLink!);
    await b.api.acceptInvite(token: preview.token, name: 'Ola', byHand: true);
    await b.pump(tester, const EnterLinkScreen(), net: PairNet.epicboxOff);
    await tester.enterText(find.byKey(pairEnterFieldKey), confirm);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pairEnterGoKey));
    await _frames(tester);
    expect(find.byType(CheckWordsScreen), findsOneWidget);
    expect(b.api.records.single.state, PairingState.paired);
  });

  testWidgets('the wait for the confirm closes once the confirm came by hand under it (item 25)', (tester) async {
    final h = _Harness();
    final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
    final answered = await h.api.acceptInvite(token: preview.token, name: 'the owner', byHand: true);
    await h.pump(tester, const Scaffold(body: Text('home')));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => PairingWaitingScreen(pairingId: answered.id))));
    await _frames(tester);
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const EnterLinkScreen())));
    await _frames(tester);
    await tester.enterText(find.byKey(pairEnterFieldKey), fakePairingLink('pair-confirm', {'t': answered.id, 'n': 'Anna'}));
    await tester.pump();
    await tester.tap(find.byKey(pairEnterGoKey));
    await _frames(tester);
    expect(find.byType(CheckWordsScreen), findsOneWidget);
    await tester.tap(find.byKey(checkMatchKey));
    await _frames(tester);
    await tester.tap(find.byKey(checkDoneKey));
    await _frames(tester);
    expect(find.byType(PairingWaitingScreen, skipOffstage: false), findsNothing, reason: 'Done never lands on the old wait');
  });

  testWidgets('an answer the relay did not take: Send by hand on its row while the link is known (PAIR-AND-11)', (tester) async {
    final h = _Harness();
    h.api.relayUnreachable = true;
    final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
    await h.api.acceptInvite(token: preview.token, name: 'the owner');
    await h.pump(tester, const PendingInvitesScreen());
    expect(find.byKey(pendingByHandKey), findsOneWidget);
    expect(find.byKey(pendingRemoveReplyKey), findsOneWidget);
    await tester.tap(find.byKey(pendingByHandKey));
    await tester.pumpAndSettle();
    expect(find.byType(PairingByHandScreen), findsOneWidget);
  });

  group('Pending invites', () {
    testWidgets('empty: says how an invite gets here', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PendingInvitesScreen());
      expect(find.text(_l.pendingEmpty), findsOneWidget);
    });

    testWidgets('an answer waiting for a confirm can be removed; an unnamed invite has a glyph (PAIR-LNX-8)', (tester) async {
      final h = _Harness();
      final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
      await h.api.acceptInvite(token: preview.token, name: 'the owner');
      await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24));
      await h.pump(tester, const PendingInvitesScreen());
      expect(find.text(_l.pairUnnamedInvite), findsOneWidget);
      final open = find.ancestor(of: find.text(_l.pairUnnamedInvite), matching: find.byType(Row)).first;
      expect(find.descendant(of: open, matching: find.byIcon(Icons.link)), findsOneWidget);
      expect(find.descendant(of: open, matching: find.text('?')), findsNothing);
      await tester.tap(find.byKey(pendingRemoveReplyKey));
      await tester.pumpAndSettle();
      expect(h.api.records.where((r) => r.state == PairingState.pendingReply), isEmpty);
      expect(find.text('Anna'), findsNothing);
    });

    testWidgets('lists a link, words, and an expired invite with Invite again', (tester) async {
      final h = _Harness();
      await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Anna');
      await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1), words: true, label: 'Tom');
      h.api.clock = () => DateTime.now().subtract(const Duration(hours: 3));
      await h.api.makeInvite(name: 'the owner', expiry: const Duration(hours: 1), label: 'Marta');
      h.api.clock = DateTime.now;
      await h.pump(tester, const PendingInvitesScreen());
      for (final name in ['Anna', 'Tom', 'Marta']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.textContaining(_l.pendingExpired, findRichText: true), findsOneWidget);
      expect(find.byKey(pendingInviteAgainKey), findsOneWidget);
    });
  });

  group('a contact\'s Pairing', () {
    Future<_Harness> open(WidgetTester tester, {PairingState state = PairingState.verified, bool keysChanged = false}) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      final r = h.api.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1', state: state, paymentsAddress: _anna);
      if (keysChanged) h.api.changeKeys(r.id);
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      return h;
    }

    testWidgets('verified: the badge, Seal payments on, Allow invoices off until turned on', (tester) async {
      final h = await open(tester);
      expect(find.text(_l.contactPairing), findsOneWidget);
      expect(find.text(_l.trustVerified), findsWidgets);
      expect(tester.widget<Switch>(find.byKey(contactPageSealKey)).value, isTrue);
      expect(tester.widget<Switch>(find.byKey(contactPageInvoicesKey)).value, isFalse);
      await tester.ensureVisible(find.byKey(contactPageInvoicesKey));
      await tester.tap(find.byKey(contactPageInvoicesKey));
      await tester.pumpAndSettle();
      expect((await h.api.pairing('p1'))!.allowInvoices, isTrue);
    });

    testWidgets('paired, not verified: Allow invoices waits for the words check', (tester) async {
      await open(tester, state: PairingState.paired);
      expect(find.text(_l.trustPaired), findsWidgets);
      expect(find.text(_l.contactCheckWordsFirst), findsOneWidget);
      expect(tester.widget<Switch>(find.byKey(contactPageInvoicesKey)).onChanged, isNull);
    });

    testWidgets('keys changed: the text as written, and Keep the old keys', (tester) async {
      final h = await open(tester, keysChanged: true);
      expect(find.text(_l.contactKeysChangedTitle('Anna')), findsOneWidget);
      expect(
        _l.contactKeysChangedBody,
        'This can mean they use a different wallet now, or someone else is using their name. Check the words again.',
      );
      expect(find.text(_l.contactKeysChangedBody), findsOneWidget);
      await tester.tap(find.text(_l.contactKeepOldKeys));
      await tester.pumpAndSettle();
      expect((await h.api.pairing('p1'))!.state, PairingState.verified);
      expect(find.text(_l.contactKeysChangedTitle('Anna')), findsNothing);
    });

    testWidgets('keys back while the page is open: the page docks the notice until OK (PAIR-LNX-15)', (tester) async {
      final h = await open(tester);
      expect(find.text(_l.contactKeysBack('Anna')), findsNothing);
      h.api.restoreKeys('p1');
      await tester.pumpAndSettle();
      expect(find.text(_l.contactKeysBack('Anna')), findsOneWidget);
      expect(find.text(_l.contactKeysBackBody), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, _l.commonOk));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactKeysBack('Anna')), findsNothing);
    });

    testWidgets('Remove pairing asks first; the contact stays', (tester) async {
      final h = await open(tester);
      await tester.ensureVisible(find.byKey(contactPageRemovePairingKey));
      await tester.tap(find.byKey(contactPageRemovePairingKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactRemovePairingTitle('Anna')), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(_l.contactRemove)));
      await tester.pumpAndSettle();
      expect(await h.api.pairing('p1'), isNull);
      expect(h.session.contactsValue.single.name, 'Anna');
      expect(find.text(_l.pairNotPaired), findsOneWidget);
    });

    testWidgets('not paired: offers Pair', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c2', name: 'Tom', address: _anna));
      await h.pump(tester, const ContactPage(contactId: 'c2'));
      expect(find.text(_l.pairNotPaired), findsOneWidget);
      await tester.ensureVisible(find.byKey(contactPagePairKey));
      await tester.tap(find.byKey(contactPagePairKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairWithName('Tom')), findsOneWidget);
    });

    testWidgets('a core without pairing shows no Pairing section', (tester) async {
      final h = _Harness();
      h.api.enabled = false;
      h.session.contactsValue.add(Contact(id: 'c2', name: 'Tom', address: _anna));
      await h.pump(tester, const ContactPage(contactId: 'c2'));
      expect(find.text(_l.contactPairing), findsNothing);
      expect(find.byType(TrustBadge), findsNothing);
    });
  });

  group('opening a sealed file (SPEC 2.9)', () {
    const json = '{"id":"in-1"}';

    /// A payment Anna's wallet sent, as the fake reads it.
    _Harness anna() {
      final h = _Harness();
      h.service.slateInfos[json] = SlateInfo(slateId: 'in-1', amount: BigInt.from(500000000), fee: BigInt.zero, stage: SlateStage.send);
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      h.api.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1', paymentsAddress: _anna);
      return h;
    }

    testWidgets('sealed for this wallet: opens, and the answer goes back sealed', (tester) async {
      final h = anna();
      final sealed = await h.api.sealSlate(id: 'p1', slateJson: json);
      await h.pump(tester, SlateFileScreen(file: SlateFile(name: 'from-anna.epicsealed', json: sealed)));
      expect(find.textContaining('5'), findsWidgets);
      await tester.tap(find.text(_l.slateAcceptPayment));
      await tester.pumpAndSettle();
      expect(h.session.receivedSlates, [json], reason: 'the slate inside went to the wallet');
      expect(find.text(_l.trustSealedFor('Anna')), findsOneWidget);
      expect(find.textContaining(sealedFileName('in-1')), findsWidgets);
    });

    testWidgets('sealed for another wallet or install: says so, nothing is signed', (tester) async {
      final h = anna();
      final other = FakeWalletSession().pairing..seedPaired(id: 'p-elsewhere', name: 'Someone');
      final sealed = await other.sealSlate(id: 'p-elsewhere', slateJson: json);
      await h.pump(tester, SlateFileScreen(file: SlateFile(name: 'x.epicsealed', json: sealed)));
      expect(find.text(_l.openSealedOtherTitle), findsOneWidget);
      expect(find.text(_l.openSealedOtherBody), findsOneWidget);
      expect(find.text(_l.slateAcceptPayment), findsNothing);
      expect(h.session.receivedSlates, isEmpty);
    });

    testWidgets('sealed by a newer wallet: Update Epic Cash to open this', (tester) async {
      final h = anna();
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: 'x.epicsealed', json: 'BEGINEPICSEALED.v2.ENDEPICSEALED.')));
      expect(find.text(_l.pairNewerTitle), findsOneWidget);
      expect(find.text(_l.pairNewerFileBody), findsOneWidget);
      expect(find.byKey(slateCheckUpdatesKey), findsOneWidget);
    });

    testWidgets('a plain file from a contact that seals: This arrived unsealed', (tester) async {
      final h = anna();
      h.api.plainFrom[json] = 'p1';
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: 'from-anna.tx', json: json)));
      expect(_notice(tester), '${_l.openArrivedUnsealed} ${_l.openArrivedUnsealedBody('Anna')}');
      expect(find.text(_l.slateAcceptPayment), findsOneWidget);
    });

    test('a sealed file passes the file check; other text does not', () {
      expect(decodeSlateFile(utf8.encode('  BEGINEPICSEALED. abc. ENDEPICSEALED.')), startsWith('BEGINEPICSEALED'));
      expect(() => decodeSlateFile(utf8.encode('hello')), throwsA(isA<FormatException>()));
    });
  });

  group('a withdrawal from a paired exchange (SPEC 2.8)', () {
    testWidgets('its page: Withdrawal from …, waiting for it to post, the timeline', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c8', name: 'Northwind Exchange', address: _anna));
      h.api.seedPaired(id: 'p-nw', name: 'Northwind', contactId: 'c8', kind: PairingParty.exchange, paymentsAddress: _anna);
      final events = <PairingEvent>[];
      h.api.events().listen(events.add);
      final slateId = h.api.withdrawalFrom('p-nw', BigInt.from(10000000000), reference: 'WD-1042');
      await tester.pump();
      expect(events.single.kind, PairingEventKind.withdrawalFromContact);
      expect(await h.api.slateOf(slateId), const PairingSlate(pairingId: 'p-nw', purpose: SlatePurpose.withdrawal, reference: 'WD-1042'));
      await h.pump(tester, TxDetailsScreen(txKey: 's:$slateId'), settle: false);
      expect(find.text(_l.reqWithdrawalFrom('Northwind Exchange')), findsOneWidget);
      expect(find.text(_l.reqReceivedWaiting('Northwind Exchange')), findsOneWidget);
      expect(find.text(_l.reqTlAnswerDelivered('Northwind Exchange')), findsOneWidget);
      expect(find.text(_l.reqTlPosted('Northwind Exchange')), findsOneWidget);
      expect(find.text('WD-1042'), findsOneWidget);
    });

    testWidgets('a withdrawal still waiting: Cancel waits out the 15-minute hold, without a second status', (tester) async {
      final h = _Harness();
      h.api.seedPaired(id: 'p-nw', name: 'Northwind', kind: PairingParty.exchange, paymentsAddress: _anna);
      final slateId = h.api.withdrawalFrom('p-nw', BigInt.from(10000000000));
      await tester.pump();
      await h.pump(tester, TxDetailsScreen(txKey: 's:$slateId'), settle: false);
      expect(find.text(_l.reqReceivedWaiting('Northwind')), findsOneWidget);
      // Just accepted: no Cancel yet, a line says when it comes (the receive Cancel rule).
      await tester.scrollUntilVisible(find.byKey(txDetailsCancelHoldKey), 200, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(txDetailsCancelHoldKey), findsOneWidget);
      expect(find.byKey(txDetailsCancelReceiveKey), findsNothing);
      expect(find.byType(TxStatusChip), findsNothing, reason: 'the withdrawal block says where it stands');
    });
  });
}
