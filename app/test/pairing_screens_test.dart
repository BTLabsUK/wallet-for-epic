// SPDX-License-Identifier: Apache-2.0
// The phone's pairing screens against the fake engine (pairing v3): the Pair screen (your
// invite, Have their invite?), an invite pasted and answered, the wait with the answer by
// hand, the confirmation after an answer taken by hand, the words check without Skip, the
// contact page's Pairing block in every state, Contacts rows and the Pair requests row, the
// Way 1 sheet, and the Experimental switch gone.

import 'package:epic_wallet/src/invite_links.dart' show invitePageProvider;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/pairing_text.dart' show pairReplyFallbackAfter, pairingSpan, unnamedPeerName;
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/pairing/contact_pairing_block.dart';
import 'package:epic_wallet/src/ui/pairing/pair_check.dart';
import 'package:epic_wallet/src/ui/pairing/pair_incoming.dart';
import 'package:epic_wallet/src/ui/pairing/pair_screen.dart';
import 'package:epic_wallet/src/ui/pairing/pair_way1.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_notices.dart' show PairingNotices, pairingNoticeOf;
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/experimental.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';
final String _tom = 'es${'t' * 50}@epicbox.epiccash.com';

BigInt _epic(int n) => BigInt.from(n) * BigInt.from(100000000);

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

class _Harness {
  _Harness({String? seenAs = 'Alex', this.prefs = phoneExperimentalOn}) {
    if (seenAs != null) store.values['pairing.seen_as'] = seenAs;
    store.values[phoneAdvancedPrefsKey] = prefs;
  }

  final String prefs;
  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);

  FakePairing get api => session.pairing;

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

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
          invoicesOnProvider.overrideWithValue(true),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
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
Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Puts [text] on the clipboard the app reads (Clipboard.getData).
void _clipboard(WidgetTester tester, String text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') return <String, Object?>{'text': text};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

String? _notice(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.text;

/// A proven peer at [address]: a marked payment yesterday, pair requests claimed.
PeerCompat _proven() => PeerCompat(lastMarkedAt: DateTime.now().subtract(const Duration(days: 1)), claimed: featureMarker | featurePairRequests, featuresAt: DateTime.now());

void main() {
  test('the notices: heard, ended, a request, answered elsewhere', () {
    expect(pairingNoticeOf(_l, const PairingEvent(PairingEventKind.heard, pairingId: 'p', name: 'Anna'))?.text, _l.pairPairedWith('Anna'));
    expect(pairingNoticeOf(_l, const PairingEvent(PairingEventKind.ended, pairingId: 'p', name: 'Anna', endedReason: PairingEndReason.peerMismatch))?.text, _l.pairEndedPeerMismatch('Anna'));
    expect(pairingNoticeOf(_l, const PairingEvent(PairingEventKind.requested, requestId: 'q', sender: 'x', name: 'Anna'))?.text, _l.pairWantsToPair('Anna'));
    expect(pairingNoticeOf(_l, const PairingEvent(PairingEventKind.pairedElsewhere, requestId: 'q', name: 'Desktop'))?.text, _l.pairPairedOn('Desktop'));
  });

  group('Pair', () {
    testWidgets('your invite as a QR with Share, the name they see with Change, Have their invite? with Paste', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), settle: false);
      expect(find.text(_l.pairYourCode), findsOneWidget);
      expect(find.text(_l.pairCodeCaption), findsOneWidget);
      expect(find.byKey(pairShareKey), findsOneWidget);
      expect(find.text(_l.pairSeenAsLine('Alex')), findsOneWidget);
      expect(find.text(_l.pairHaveTheirCode), findsOneWidget);
      expect(find.byKey(pairPasteKey), findsOneWidget);
      expect(find.byKey(pairScanKey), findsNothing, reason: 'no camera on this device');
      expect(h.api.standing, isNotNull, reason: 'the standing invite is made on open');
      expect(await h.api.pairings(), isEmpty, reason: 'an unused invite is no row');
      await tester.tap(find.byKey(pairShareKey));
      await _frames(tester);
      expect(h.files.sharedTexts.single, contains(pairingInviteText(h.api.standing!, invitePage: h.container(tester).read(invitePageProvider))));
    });

    testWidgets('Change: one name per wallet, a new invite carries it', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), settle: false);
      final before = h.api.standing!.id;
      await tester.tap(find.byKey(pairChangeNameKey));
      await _frames(tester);
      await tester.enterText(find.byKey(pairNameFieldKey), 'Alexander');
      await tester.tap(find.byKey(pairNameSaveKey));
      await _frames(tester);
      expect(find.text(_l.pairSeenAsLine('Alexander')), findsOneWidget);
      expect(h.api.standing!.id, isNot(before));
      expect(h.api.standingName, 'Alexander');
      expect(h.store.values['pairing.seen_as'], 'Alexander');
    });

    testWidgets('no name kept: no question, the invite carries the no-name word', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const PairScreen(), settle: false);
      expect(find.byKey(pairNameFieldKey), findsNothing, reason: 'nothing is asked');
      expect(h.api.standingName, unnamedPeerName);
      expect(find.text(_l.pairSeenAsNone), findsOneWidget);
      expect(find.text(_l.pairSeenAsAdd), findsOneWidget);
      expect(h.store.values['pairing.seen_as'], isNull);
    });

    testWidgets('Add name: a name is kept; Change to an empty name is accepted and stored as empty', (tester) async {
      final h = _Harness(seenAs: null);
      await h.pump(tester, const PairScreen(), settle: false);
      await tester.tap(find.byKey(pairChangeNameKey));
      await _frames(tester);
      await tester.enterText(find.byKey(pairNameFieldKey), 'Alex Brown');
      await tester.tap(find.byKey(pairNameSaveKey));
      await _frames(tester);
      expect(find.text(_l.pairSeenAsLine('Alex Brown')), findsOneWidget);
      expect(h.api.standingName, 'Alex Brown');
      await tester.tap(find.byKey(pairChangeNameKey));
      await _frames(tester);
      await tester.enterText(find.byKey(pairNameFieldKey), '  ');
      await tester.tap(find.byKey(pairNameSaveKey));
      await _frames(tester);
      expect(find.byKey(pairNameFieldKey), findsNothing, reason: 'an empty name is accepted');
      expect(find.text(_l.pairSeenAsNone), findsOneWidget);
      expect(h.api.standingName, unnamedPeerName);
      expect(h.store.values['pairing.seen_as'], '');
    });

    testWidgets('framed for a contact: the title and captions name it', (tester) async {
      final h = _Harness();
      await h.pump(tester, PairScreen(contact: Contact(id: 'c1', name: 'Anna', address: _anna)), settle: false);
      expect(find.text(_l.pairWithName('Anna')), findsOneWidget);
      expect(find.text(_l.pairCodeCaptionFor('Anna')), findsOneWidget);
      expect(find.text(_l.pairHaveNamesCode('Anna')), findsOneWidget);
    });

    testWidgets('Epicbox off: one line under Share, nothing else', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), net: PairNet.epicboxOff, settle: false);
      expect(find.text(_l.pairEpicboxOffLine), findsOneWidget);
    });

    testWidgets('Paste with no invite on the clipboard: Not a pairing invite', (tester) async {
      final h = _Harness();
      _clipboard(tester, 'hello');
      await h.pump(tester, const PairScreen(), settle: false);
      await tester.tap(find.byKey(pairPasteKey));
      await _frames(tester);
      expect(_notice(tester), _l.pairNotACode);
      expect(find.byType(IncomingInviteSheet), findsNothing);
    });

    testWidgets('Paste an invite: Pair with …? (by invite: no chip); Pair opens the wait', (tester) async {
      final h = _Harness();
      _clipboard(tester, 'Pair with me in BT Wallet: ${h.api.inviteLinkFrom(name: 'Northwind')}');
      await h.pump(tester, const PairScreen(), settle: false);
      await tester.tap(find.byKey(pairPasteKey));
      await _frames(tester);
      expect(find.byType(IncomingInviteSheet), findsOneWidget);
      expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
      expect(find.text(_l.pairNameClaimedShort), findsNothing);
      expect(find.text(_l.pairInContacts), findsNothing);
      expect(find.byKey(pairNameFieldKey), findsNothing, reason: 'no name field on the sheet');
      await tester.tap(find.byKey(incomingPairKey));
      await _frames(tester);
      expect(find.byType(PairingWaitingScreen), findsOneWidget);
      expect(find.text(_l.pairPairingWith('Northwind')), findsOneWidget);
      expect(find.byKey(waitingAnswerBoxKey), findsNothing, reason: 'the relay carries it first');
      // The confirm came through the relay: the words open.
      final answered = h.api.records.single;
      h.api.confirmAnswer(answered.id);
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('the wait: Your answer after 30 s with a QR, Share and the confirmation field; at once with Epicbox off', (tester) async {
      final h = _Harness();
      final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
      final answered = await h.api.acceptInvite(token: preview.token, name: 'Alex');
      await h.pump(tester, PairingWaitingScreen(pairingId: answered.id, name: 'Anna'), settle: false);
      expect(find.byKey(waitingAnswerBoxKey), findsNothing);
      await tester.pump(pairReplyFallbackAfter + const Duration(seconds: 1));
      await _frames(tester);
      expect(find.byKey(waitingAnswerBoxKey), findsOneWidget);
      expect(find.text(_l.pairByHandYourAnswer), findsOneWidget);
      expect(find.byKey(waitingShareKey), findsOneWidget);
      expect(find.byKey(waitingFinishFieldKey), findsOneWidget);
      await tester.tap(find.byKey(waitingShareKey));
      await _frames(tester);
      expect(h.files.sharedTexts.single, contains('epiccash://pair-reply/'));
      // The confirmation pasted in the field opens the words.
      await tester.enterText(find.byKey(waitingFinishFieldKey), fakePairingLink('pair-confirm', {'t': answered.id}));
      await tester.tap(find.byKey(waitingFinishGoKey));
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('Epicbox off: the answer box at once; Cancel asks, then forgets the answer', (tester) async {
      final h = _Harness();
      h.api.relayUnreachable = true;
      final preview = await h.api.openInvite(h.api.inviteLinkFrom(name: 'Anna'));
      final answered = await h.api.acceptInvite(token: preview.token, name: 'Alex');
      await h.pump(tester, PairingWaitingScreen(pairingId: answered.id, name: 'Anna'), net: PairNet.epicboxOff, settle: false);
      expect(find.byKey(waitingAnswerBoxKey), findsOneWidget);
      await tester.tap(find.byKey(waitingCancelKey));
      await _frames(tester);
      expect(find.text(_l.pairCancelPairingTitle), findsOneWidget);
      await tester.tap(find.text(_l.pairCancelPairing));
      await _frames(tester);
      expect(h.api.records, isEmpty);
    });

    testWidgets('an answer pasted on the Pair screen: the confirmation box, Share, Check the words', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), settle: false);
      final invite = h.api.standing!;
      _clipboard(tester, fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Anna'}));
      await tester.tap(find.byKey(pairPasteKey));
      await _frames(tester);
      expect(find.byKey(pairFinishBoxKey), findsOneWidget);
      expect(find.text(_l.pairFinishCodeTitle), findsOneWidget);
      expect(find.text(_l.pairFinishCodeBody('Anna')), findsOneWidget);
      expect(h.api.standing!.id, isNot(invite.id), reason: 'the used invite was replaced');
      await tester.scrollUntilVisible(find.byKey(pairFinishShareKey), 200, scrollable: find.byType(Scrollable).first);
      await _frames(tester);
      await tester.tap(find.byKey(pairFinishShareKey));
      await _frames(tester);
      expect(h.files.sharedTexts.single, contains('epiccash://pair-confirm/'));
      await tester.ensureVisible(find.byKey(pairCheckWordsKey).first);
      await tester.tap(find.byKey(pairCheckWordsKey).first);
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('an answer through the relay: the words open; a request answered ends Verified with a notice', (tester) async {
      final h = _Harness();
      await h.pump(tester, const PairScreen(), settle: false);
      h.api.answerInvite(h.api.standing!.id, name: 'Anna');
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsOneWidget);
    });

    testWidgets('a confirmation pasted elsewhere opens the words; a request confirm just says Paired with', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      final q = h.api.receiveRequest(from: _anna, name: 'Anna')!;
      final preview = await h.api.openRequest(q.id);
      final answered = await h.api.acceptInvite(token: preview.token, name: 'Alex', contactId: 'c1');
      _clipboard(tester, fakePairingLink('pair-confirm', {'t': answered.id}));
      await h.pump(tester, const PairScreen(), settle: false);
      await tester.tap(find.byKey(pairPasteKey));
      await _frames(tester);
      expect(find.byType(CheckWordsScreen), findsNothing);
      expect(_notice(tester), _l.pairPairedWith('Anna'));
      expect(h.api.records.single.state, PairingState.verified);
    });
  });

  group('check the words', () {
    testWidgets('They match · They do not match, no Skip; a match verifies and offers to save the contact', (tester) async {
      final h = _Harness();
      final r = h.api.seedPaired(name: 'Anna', state: PairingState.paired);
      await h.pump(tester, CheckWordsScreen(pairingId: r.id));
      expect(find.text(_l.sasTitle), findsOneWidget);
      expect(find.text(_l.sasLead('Anna')), findsOneWidget);
      expect(find.byKey(checkMatchKey), findsOneWidget);
      expect(find.byKey(checkNoMatchKey), findsOneWidget);
      expect(find.text(_l.sasSkip), findsNothing);
      expect(find.text(_l.sasLater), findsNothing);
      await tester.tap(find.byKey(checkMatchKey));
      await tester.pumpAndSettle();
      expect(h.api.records.single.state, PairingState.verified);
      expect(find.byType(PairingResultScreen), findsOneWidget);
      expect(find.text(_l.pairNotChecked('Anna')), findsOneWidget);
      expect(find.byKey(resultSaveNewKey), findsOneWidget);
    });

    testWidgets('They do not match asks, then ends the pairing (kept) with the notice', (tester) async {
      final h = _Harness();
      final r = h.api.seedPaired(name: 'Anna', state: PairingState.paired);
      await h.pump(tester, CheckWordsScreen(pairingId: r.id));
      await tester.tap(find.byKey(checkNoMatchKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.sasNoMatchBody), findsOneWidget);
      await tester.tap(find.byKey(checkStopKey));
      await tester.pumpAndSettle();
      final ended = h.api.records.single;
      expect((ended.state, ended.endedReason), (PairingState.ended, PairingEndReason.mismatch));
      expect(_notice(tester), _l.pairEndedNotice);
    });

    testWidgets('Back is later: the pairing stays Paired', (tester) async {
      final h = _Harness();
      final r = h.api.seedPaired(name: 'Anna', state: PairingState.paired);
      await h.pump(tester, const Scaffold(body: SizedBox.shrink()));
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: r.id))));
      await tester.pumpAndSettle();
      expect(find.byKey(checkMatchKey), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(checkMatchKey), findsNothing);
      expect(h.api.records.single.state, PairingState.paired);
    });
  });

  group('the contact page', () {
    Future<_Harness> page(WidgetTester tester, void Function(_Harness h) seed, {PairNet? net}) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      seed(h);
      await h.pump(tester, const ContactPage(contactId: 'c1'), net: net, settle: false);
      await _frames(tester);
      return h;
    }

    testWidgets('not paired: Pair in the header and the block; a proven peer gets the request sheet', (tester) async {
      final h = await page(tester, (h) {
        h.service.peerCompats[_anna] = _proven();
        h.api.provenPeers.add(_anna);
      });
      expect(find.byKey(contactPageHeaderPairKey), findsOneWidget);
      expect(find.text(_l.pairNotPaired), findsOneWidget);
      await tester.tap(find.byKey(contactPagePairKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairRequestBody), findsOneWidget);
      expect(find.byKey(way1SendKey), findsOneWidget);
      expect(find.byKey(way1ShowCodeKey), findsOneWidget);
      await tester.tap(find.byKey(way1SendKey));
      await _frames(tester);
      expect(h.api.sentRequests.single.to, _anna);
      expect(find.text(_l.pairWaitingFor('Anna')), findsWidgets);
      expect(find.byKey(contactPageShowCodeKey), findsOneWidget, reason: 'Show my invite from the first moment');
      expect(find.byKey(contactPageCancelPairingKey), findsOneWidget);
    });

    testWidgets('not a proven peer: Pair opens the Pair screen framed for the contact, no sentence about why', (tester) async {
      await page(tester, (_) {});
      await tester.tap(find.byKey(contactPagePairKey));
      await tester.pumpAndSettle();
      expect(find.byType(PairScreen), findsOneWidget);
      expect(find.text(_l.pairWithName('Anna')), findsOneWidget);
      expect(find.text(_l.pairNotProvenBody('Anna')), findsNothing);
    });

    testWidgets('Epicbox off: Pair opens the framed Pair screen too, even for a proven peer', (tester) async {
      await page(tester, (h) => h.service.peerCompats[_anna] = _proven(), net: PairNet.epicboxOff);
      await tester.tap(find.byKey(contactPagePairKey));
      await tester.pumpAndSettle();
      expect(find.byType(PairScreen), findsOneWidget);
      expect(find.text(_l.pairEpicboxOffLine), findsOneWidget);
    });

    testWidgets('a pairing made before addresses were proven: the line and Pair again, which starts a new pairing', (tester) async {
      await page(tester, (h) => h.api.seedPaired(name: 'Anna', contactId: 'c1', unproven: true));
      expect(find.textContaining(_l.trustVerified, findRichText: true), findsWidgets);
      expect(find.byKey(contactPageUnprovenKey), findsOneWidget);
      expect(find.text(_l.pairAddressNotConfirmed), findsOneWidget);
      await tester.ensureVisible(find.byKey(contactPagePairAgainUnprovenKey));
      await tester.tap(find.byKey(contactPagePairAgainUnprovenKey));
      await tester.pumpAndSettle();
      expect(find.byType(PairScreen), findsOneWidget, reason: 'not a proven peer: the Pair screen framed for the contact');
      expect(find.text(_l.pairWithName('Anna')), findsOneWidget);
    });

    testWidgets('a pairing that proves the contact\'s address: no line, no Pair again', (tester) async {
      await page(tester, (h) => h.api.seedPaired(name: 'Anna', contactId: 'c1', paymentsAddress: _anna));
      expect(find.textContaining(_l.trustVerified, findRichText: true), findsWidgets);
      expect(find.byKey(contactPageUnprovenKey), findsNothing);
      expect(find.byKey(contactPagePairAgainUnprovenKey), findsNothing);
    });

    testWidgets('a request expired unanswered: No answer, Pair again, Remove', (tester) async {
      final h = await page(tester, (h) {
        h.api.provenPeers.add(_anna);
        h.api.clock = () => DateTime.now().subtract(const Duration(days: 8));
      });
      await h.api.requestPairing(toAddress: _anna, name: 'Alex', contactId: 'c1');
      h.api.clock = DateTime.now;
      await h.container(tester).read(pairingsProvider.notifier).reload();
      await _frames(tester);
      expect(find.text(_l.pairNoAnswerFrom('Anna')), findsOneWidget);
      expect(find.byKey(contactPagePairAgainKey), findsOneWidget);
      await tester.tap(find.byKey(contactPageCancelPairingKey));
      await _frames(tester);
      expect(h.api.records, isEmpty);
      expect(find.text(_l.pairNotPaired), findsOneWidget);
    });

    testWidgets('a shop that did not answer the check: Not answering, the line, Pair again; heard again: gone', (tester) async {
      final h = await page(tester, (h) {
        h.api.seedPaired(id: 's', name: 'Anna', contactId: 'c1', kind: PairingParty.shop, state: PairingState.paired, paymentsAddress: _anna);
        h.api.silent.add('s');
      });
      await h.api.checkContacts();
      await h.container(tester).read(pairingsProvider.notifier).reload();
      await _frames(tester);
      expect(find.byKey(contactPageNotAnsweringKey), findsOneWidget);
      expect(find.text(_l.trustNotAnswering), findsWidgets);
      expect(find.text(_l.contactNotAnsweringBody), findsOneWidget);
      expect(find.byKey(contactPagePairAgainKey), findsOneWidget);

      h.api.silent.clear();
      await h.api.checkContacts();
      await h.container(tester).read(pairingsProvider.notifier).reload();
      await _frames(tester);
      expect(find.byKey(contactPageNotAnsweringKey), findsNothing);
      expect(find.text(_l.trustNotAnswering), findsNothing);
    });

    testWidgets('waiting (answered, not heard): the line, Check the words, Cancel; heard: Paired', (tester) async {
      final h = await page(tester, (h) => h.api.seedPaired(name: 'Anna', contactId: 'c1', state: PairingState.waiting, paymentsAddress: _anna));
      expect(find.text(_l.pairWaitingFor('Anna')), findsWidgets);
      expect(find.text(_l.pairAnsweredNotHeard), findsOneWidget);
      expect(find.byKey(contactPageCheckKey), findsOneWidget);
      expect(find.byKey(contactPageCancelPairingKey), findsOneWidget);
      final seal = tester.widget<Switch>(find.byKey(contactPageSealKey));
      expect(seal.onChanged, isNull, reason: 'nothing is sealed to a wallet not heard');
      h.api.hear(h.api.records.single.id);
      await _frames(tester);
      expect(find.text(_l.trustPaired), findsWidgets);
      expect(find.text(_l.pairNotChecked('Anna')), findsOneWidget);
    });

    testWidgets('verified: the date, "confirmed too" once the verdict came, both switches', (tester) async {
      final h = await page(tester, (h) => h.api.seedPaired(id: 'p', name: 'Anna', contactId: 'c1', paymentsAddress: _anna));
      expect(find.text(_l.pairNotChecked('Anna')), findsOneWidget);
      h.api.peerMatch('p');
      await tester.pumpAndSettle();
      expect(find.text(_l.pairConfirmedToo('Anna')), findsOneWidget);
      expect(tester.widget<Switch>(find.byKey(contactPageSealKey)).onChanged, isNotNull);
      expect(tester.widget<Switch>(find.byKey(contactPageInvoicesKey)).onChanged, isNotNull);
    });

    testWidgets('ended by the peer: the reason, the held send with Cancel, Pair again and Remove', (tester) async {
      final h = await page(tester, (h) {
        h.session.summaryValue = WalletSummary(lastConfirmedHeight: BigInt.from(10), minimumConfirmations: BigInt.one, total: _epic(100), spendable: _epic(100), awaitingConfirmation: BigInt.zero, awaitingFinalization: BigInt.zero, immature: BigInt.zero, locked: BigInt.zero, validatedWithNode: true);
        h.api.seedPaired(id: 'p', name: 'Anna', contactId: 'c1', state: PairingState.paired, paymentsAddress: _anna);
      });
      await h.api.sendViaMailbox(id: 'p', amount: _epic(25), minimumConfirmations: BigInt.one);
      h.container(tester).invalidate(homeProvider);
      h.api.peerMismatch('p');
      await tester.pumpAndSettle();
      expect(find.byKey(contactPageEndedKey), findsOneWidget);
      expect(find.text(_l.pairEndedPeerMismatch('Anna')), findsOneWidget);
      expect(find.byKey(contactPageHeldSendKey), findsOneWidget);
      expect(find.text(_l.pairHeldSend), findsOneWidget);
      expect(find.byKey(contactPagePairAgainKey), findsOneWidget);
      expect(find.byKey(contactPageRemovePairingKey), findsOneWidget);
      expect(find.byKey(contactPageSealKey), findsNothing, reason: 'no switches on an ended pairing');
      await tester.tap(find.widgetWithText(TextButton, _l.commonCancel).first);
      await _frames(tester);
      expect(h.session.cancelledTxIds, isNotEmpty, reason: 'the held send was cancelled');
    });

    testWidgets('never finished: the reason line; Remove drops it, the contact stays', (tester) async {
      final h = await page(tester, (h) => h.api.seedPaired(id: 'p', name: 'Anna', contactId: 'c1', state: PairingState.ended, endedReason: PairingEndReason.neverFinished));
      expect(find.text(_l.pairEndedNeverFinished('Anna')), findsOneWidget);
      await tester.tap(find.byKey(contactPageRemovePairingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(confirmRemovePairingKey));
      await tester.pumpAndSettle();
      expect(h.api.records, isEmpty);
      expect(find.text(_l.pairNotPaired), findsOneWidget);
    });

    testWidgets('a later card proves another address: Update the contact\'s address or Detach', (tester) async {
      final h = await page(tester, (h) => h.api.seedPaired(id: 'p', name: 'Anna', contactId: 'c1', paymentsAddress: _tom));
      expect(find.text(_l.pairProvesOther('Anna')), findsOneWidget);
      await tester.tap(find.byKey(contactPageUpdateAddressKey));
      await tester.pumpAndSettle();
      expect(h.session.contactsValue.single.epicbox, _tom);
      expect(find.text(_l.pairProvesOther('Anna')), findsNothing);
    });

    testWidgets('keys changed: the notice with its three ways out', (tester) async {
      final h = await page(tester, (h) => h.api.seedPaired(id: 'p', name: 'Anna', contactId: 'c1', paymentsAddress: _anna));
      h.api.changeKeys('p');
      await tester.pumpAndSettle();
      expect(find.text(_l.contactKeysChangedTitle('Anna')), findsOneWidget);
      for (final t in [_l.pairCheckWords, _l.contactKeepOldKeys, _l.contactUseNewKeys]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
    });
  });

  group('Contacts', () {
    testWidgets('rows carry one badge each: Verified, Paired, Waiting, Keys changed, Ended; no hint card', (tester) async {
      final h = _Harness();
      h.session.contactsValue.addAll([
        Contact(id: 'c1', name: 'Anna', address: _anna),
        Contact(id: 'c2', name: 'Bob', address: _tom),
        Contact(id: 'c3', name: 'Carl'),
        Contact(id: 'c4', name: 'Dana'),
        Contact(id: 'c5', name: 'Eve'),
      ]);
      h.api
        ..seedPaired(name: 'Anna', contactId: 'c1', paymentsAddress: _anna)
        ..seedPaired(name: 'Bob', contactId: 'c2', paymentsAddress: _tom, state: PairingState.paired)
        ..seedPaired(name: 'Carl', contactId: 'c3', state: PairingState.waiting)
        ..seedPaired(name: 'Dana', contactId: 'c4', state: PairingState.ended, endedReason: PairingEndReason.peerMismatch)
        ..seedPaired(id: 'e', name: 'Eve', contactId: 'c5');
      h.api.changeKeys('e');
      await h.pump(tester, const ContactsScreen());
      expect(find.byKey(contactsPairKey), findsOneWidget);
      expect(find.text(_l.contactsPairHint), findsNothing);
      expect(find.text(_l.pendingTitle), findsNothing);
      for (final t in [_l.trustVerified, _l.trustPairedShort, _l.trustWaiting, _l.trustKeysChanged, _l.trustEnded]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('a shop that did not answer the check: its row says Not answering instead of Paired', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      h.api
        ..seedPaired(id: 's', name: 'Anna', contactId: 'c1', kind: PairingParty.shop, state: PairingState.paired, paymentsAddress: _anna)
        ..silent.add('s');
      await h.api.checkContacts();
      await h.pump(tester, const ContactsScreen());
      expect(find.text(_l.trustNotAnswering), findsOneWidget);
      expect(find.text(_l.trustPairedShort), findsNothing);
    });

    testWidgets('a pending row (an invite answered, not heard) sits in the list with Cancel; an unused invite is no row', (tester) async {
      final h = _Harness();
      await h.api.standingCode(name: 'Alex');
      final invite = h.api.standing!;
      h.api.answerInvite(invite.id, name: 'Northwind');
      await h.pump(tester, const ContactsScreen());
      expect(find.byKey(contactsPairingRowKey(invite.id)), findsOneWidget);
      expect(find.text(_l.pairAnsweredNotHeard), findsOneWidget);
      await tester.tap(find.byKey(contactsOrphanMenuKey(invite.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(contactsCancelPairingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.pairCancelPairing));
      await tester.pumpAndSettle();
      expect(h.api.records, isEmpty);
      expect(find.byKey(contactsPairingRowKey(invite.id)), findsNothing);
    });

    testWidgets('Pair requests · 1 for a contact\'s request only; Pair opens the from-a-contact sheet; Not now dismisses', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      h.api.receiveRequest(from: _tom, name: 'Stranger');
      h.api.receiveRequest(from: _anna, name: 'Anna');
      await h.pump(tester, const ContactsScreen());
      expect(find.byKey(contactsRequestsKey), findsOneWidget);
      expect(find.text(_l.pairRequestsRow(1)), findsOneWidget);
      await tester.tap(find.byKey(contactsRequestsKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.pairWantsToPair('Anna')), findsOneWidget);
      expect(find.text(_l.pairWantsToPair('Stranger')), findsNothing);
      await tester.tap(find.byKey(requestsPairKey));
      await tester.pumpAndSettle();
      expect(find.byType(IncomingInviteSheet), findsOneWidget);
      expect(find.text(_l.pairInContacts), findsOneWidget);
      expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
      await tester.tap(find.byKey(incomingNotNowKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(requestsNotNowKey));
      await tester.pumpAndSettle();
      expect((await h.api.requests()).where((r) => r.fromAddress == _anna), isEmpty);
    });

    testWidgets('a stranger\'s request is dismissed on arrival by the notices, a contact\'s is announced', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      await h.pump(tester, const Scaffold(body: PairingNotices()));
      h.api.receiveRequest(from: _tom, name: 'Stranger');
      await tester.pumpAndSettle();
      expect(await h.api.requests(), isEmpty, reason: 'dismissed unseen');
      expect(_notice(tester), isNull);
      h.api.receiveRequest(from: _anna, name: 'Anna');
      await tester.pumpAndSettle();
      expect((await h.api.requests()).single.fromAddress, _anna);
      expect(_notice(tester), _l.pairWantsToPair('Anna'));
    });

    testWidgets('a request answered on the linked device: hidden, "Paired on Desktop."', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      final q = h.api.receiveRequest(from: _anna, name: 'Anna')!;
      await h.pump(tester, const Scaffold(body: PairingNotices()));
      await h.api.requestHandledOn(q.id, 'Desktop');
      await tester.pumpAndSettle();
      expect(_notice(tester), _l.pairPairedOn('Desktop'));
    });
  });

  group('the Experimental switch', () {
    testWidgets('Pair shows with the old pairing switch stored off', (tester) async {
      final h = _Harness(prefs: 'outputs|standard');
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Anna', address: _anna));
      await h.pump(tester, const ContactsScreen());
      expect(find.byKey(contactsPairKey), findsOneWidget);
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(find.byKey(contactPagePairKey), findsOneWidget);
    });
  });

  test('a span counts whole minutes: a fresh 7 d invite is 6 d 23 h', () {
    expect(pairingSpan(_l, const Duration(days: 7) - const Duration(seconds: 30)), _l.pairDurDays(6, 23));
  });
}
