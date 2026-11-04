// SPDX-License-Identifier: Apache-2.0
// The desktop's Pair page (pairing v3): Your invite with Copy invite and the name they see,
// Have their invite? with the Paste field, an invite pasted and answered, the wait with the
// answer by hand and the confirmation field, an answer pasted (the confirmation box), the
// words check without Skip, the request dialog of the contact pane and the Pair requests
// dialog.
import 'dart:async';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairRequestsProvider, deskPairingsProvider, deskSeenAsProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/invite_links.dart' show invitePageProvider;
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_text.dart' show pairReplyFallbackAfter, unnamedPeerName;
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/wallet_service.dart' show PairingEndReason, PairingState;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/experimental.dart';

final _l = englishStrings;
late ProviderContainer _c;
late MockDeskWallet _mock;
String? _clip;

FakePairing get _pairing => _mock.pairing;

final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, Widget screen, {NetworkMode? mode, bool epicbox = true}) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') _clip = (call.arguments as Map)['text'] as String?;
    if (call.method == 'Clipboard.getData') return <String, Object?>{'text': _clip};
    return null;
  });
  _clip = null;
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  _mock = MockDeskWallet(delay: Duration.zero);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_mock)]);
  addTearDown(_c.dispose);
  await tester.runAsync(() async {
    await _c.read(deskProvider.notifier).refresh();
    await deskExperimentalOn(_c);
  });
  final n = _c.read(deskProvider.notifier);
  if (mode != null) {
    await tester.runAsync(() => n.saveSettings(_c.read(deskProvider).settings.copyWith(advanced: _c.read(deskProvider).settings.advanced.withMode(mode))));
  }
  if (!epicbox) {
    final s = _c.read(deskProvider).settings;
    await tester.runAsync(() => n.saveSettings(s.copyWith(payments: s.payments.copyWith(epicbox: false))));
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await _real(tester);
}

Future<void> _paste(WidgetTester tester, String text) async {
  await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), text);
  await tester.pump();
  await tester.tap(find.byKey(deskPairGoKey));
  await _real(tester);
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(deskForgetOpenChecks);

  testWidgets('the page: Your invite as a QR, Copy invite, the footnote, the name they see, Have their invite?', (tester) async {
    await _open(tester, const DeskPairScreen());
    for (final t in [_l.pairYourCode, _l.pairCodeCaption, _l.pairStandingFootnote, _l.pairHaveTheirCode, _l.pairPasteField]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.byType(EQr), findsOneWidget);
    expect(_pairing.standing, isNotNull);
    final standing = _pairing.standing!.id;
    expect((await tester.runAsync(_pairing.pairings))!.where((r) => r.id == standing), isEmpty, reason: 'an unused invite is no row');
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    // The invite page from the settings: Copy invite carries its https link.
    final page = ProviderScope.containerOf(tester.element(find.byType(DeskPairScreen))).read(invitePageProvider);
    expect(_clip, _l.pairInviteMessage(deskPairingInviteText(_pairing.standing!, invitePage: page)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Your invite answered: Waiting for them with Check the words; heard: Paired with them, no spinner', (tester) async {
    await _open(tester, const DeskPairScreen());
    final id = _pairing.standing!.id;
    _pairing.answerInvite(id, name: 'Lol', features: featureStatusNotices);
    await _real(tester);
    expect(find.text(_l.pairWaitingFor('Lol')), findsOneWidget);
    expect(find.byKey(deskPairCheckWordsKey), findsOneWidget);
    _pairing.hear(id);
    await _real(tester);
    expect(find.text(_l.pairPairedWith('Lol')), findsOneWidget);
    expect(find.text(_l.pairAnsweredFinishing('Lol')), findsNothing);
    expect(find.byType(ESpinner), findsNothing);
    expect(find.byKey(deskPairCheckWordsKey), findsOneWidget, reason: 'the words are still to check');
  });

  testWidgets('Change: the name they see is kept in the settings and the invite is made anew', (tester) async {
    await _open(tester, const DeskPairScreen());
    final before = _pairing.standing!.id;
    await tester.tap(find.byKey(deskPairChangeNameKey));
    await _real(tester);
    await tester.enterText(find.descendant(of: find.byKey(deskPairNameKey), matching: find.byType(EditableText)), 'Alexander');
    await tester.tap(find.byKey(deskPairNameSaveKey));
    await _real(tester);
    expect(_c.read(deskSeenAsProvider), 'Alexander');
    expect(_c.read(deskProvider).settings.pairingSeenAs, 'Alexander');
    expect(_pairing.standing!.id, isNot(before));
    expect(find.text(_l.pairSeenAsLine('Alexander')), findsOneWidget);
  });

  testWidgets('no name by default, even when the wallet has one; an empty name clears it', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(_c.read(deskSeenAsProvider), isEmpty, reason: 'the wallet name is no default');
    expect(_pairing.standingName, unnamedPeerName);
    expect(find.text(_l.pairSeenAsNone), findsOneWidget);
    await _c.read(deskSeenAsProvider.notifier).set('Alexander');
    await _c.read(deskSeenAsProvider.notifier).set('');
    expect(_c.read(deskProvider).settings.pairingSeenAs, isEmpty);
  });

  testWidgets('framed for a contact: the title, captions and section name it', (tester) async {
    final anna = _c0Contact();
    await _open(tester, DeskPairScreen(arg: anna));
    expect(find.text(_l.pairWithName(anna.name)), findsOneWidget);
    expect(find.text(_l.pairCodeCaptionFor(anna.name)), findsOneWidget);
    expect(find.text(_l.pairHaveNamesCode(anna.name)), findsOneWidget);
  });

  testWidgets('Epicbox off: one line under Copy invite', (tester) async {
    await _open(tester, const DeskPairScreen(), epicbox: false);
    expect(find.text(_l.pairEpicboxOffLine), findsOneWidget);
  });

  testWidgets('Paste: not an invite says so; an invite opens Pair with …? by invite; Pair opens the wait, the confirm the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _paste(tester, 'hello');
    expect(find.text(_l.pairNotACode), findsWidgets);
    await _paste(tester, _l.pairInviteMessage(_pairing.inviteLinkFrom(name: 'Anna')));
    expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
    expect(find.byKey(deskPairNameKey), findsNothing, reason: 'no name field on the dialog');
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    expect(find.text(_l.pairPairingWith('Anna')), findsOneWidget);
    expect(find.byKey(deskWaitingAnswerKey), findsNothing);
    final answered = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply).single;
    _pairing.confirmAnswer(answered.id);
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Anna')), findsOneWidget);
    expect(find.byKey(deskCheckMatchKey), findsOneWidget);
    expect(find.byKey(deskCheckNoMatchKey), findsOneWidget);
    expect(find.text(_l.sasSkip), findsNothing);
    await tester.tap(find.byKey(deskCheckMatchKey));
    await _real(tester);
    expect((await tester.runAsync(() => _pairing.pairing(answered.id)))!.state, PairingState.verified);
  });

  testWidgets('the wait, relay slow: Your answer with Copy and the confirmation field; the confirmation pasted opens the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _paste(tester, _pairing.inviteLinkFrom(name: 'Anna'));
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    await tester.pump(pairReplyFallbackAfter + const Duration(seconds: 1));
    await _real(tester);
    expect(find.byKey(deskWaitingAnswerKey), findsOneWidget);
    expect(find.text(_l.pairYourAnswerBody), findsOneWidget);
    await tester.tap(find.byKey(deskWaitingCopyKey));
    await _real(tester);
    expect(_clip, contains('epiccash://pair-reply/'));
    final answered = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply).single;
    await tester.enterText(find.descendant(of: find.byKey(deskWaitingFinishKey), matching: find.byType(EditableText)), fakePairingLink('pair-confirm', {'t': answered.id}));
    await tester.tap(find.byKey(deskWaitingFinishGoKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Anna')), findsOneWidget);
  });

  testWidgets('the wait: Cancel asks, then forgets the answer', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _paste(tester, _pairing.inviteLinkFrom(name: 'Anna'));
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    await tester.tap(find.byKey(deskWaitingCancelKey));
    await _real(tester);
    expect(find.text(_l.pairCancelPairingTitle), findsOneWidget);
    await tester.tap(find.text(_l.pairCancelPairing));
    await _real(tester);
    expect((await tester.runAsync(_pairing.pairings))!.where((r) => r.state.isPending), isEmpty);
  });

  testWidgets('an answer pasted: the confirmation box with Copy, then the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    final invite = _pairing.standing!;
    await _paste(tester, fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Ola'}));
    expect(find.byKey(deskPairConfirmationKey), findsOneWidget);
    expect(find.text(_l.pairFinishCodeBody('Ola')), findsOneWidget);
    expect(_pairing.standing!.id, isNot(invite.id), reason: 'the used invite was replaced');
    await tester.tap(find.byKey(deskConfirmCopyKey));
    await _real(tester);
    expect(_clip, contains('epiccash://pair-confirm/'));
    await tester.tap(find.byKey(deskConfirmCheckKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Ola')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(deskCheckMatchKey))).pop();
    await _real(tester);
  });

  testWidgets('They do not match ends the pairing, kept, with the notice', (tester) async {
    await _open(tester, const DeskPairScreen());
    _pairing.seedPaired(id: 'p-ola', name: 'Ola', state: PairingState.paired);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    unawaited(showDeskCheckWordsFor(tester.element(find.byKey(deskPairEnterKey)), 'p-ola'));
    await _real(tester);
    await tester.tap(find.byKey(deskCheckNoMatchKey));
    await _real(tester);
    await tester.tap(find.widgetWithText(EButton, _l.sasNoMatch).last);
    await _real(tester);
    final r = (await tester.runAsync(() => _pairing.pairing('p-ola')))!;
    expect((r.state, r.endedReason), (PairingState.ended, PairingEndReason.mismatch));
    expect(find.text(_l.pairEndedNotice), findsOneWidget);
  });

  testWidgets('a request answered through the relay: Verified with a toast, no words', (tester) async {
    await _open(tester, const DeskPairScreen());
    final q = _pairing.receiveRequest(from: _anna, name: 'Anna')!;
    final preview = await tester.runAsync(() => _pairing.openRequest(q.id));
    final answered = (await tester.runAsync(() => _pairing.acceptInvite(token: preview!.token, name: 'Alex')))!;
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    _pairing.confirmAnswer(answered.id);
    await _real(tester);
    expect((await tester.runAsync(() => _pairing.pairing(answered.id)))!.state, PairingState.verified);
    expect(find.byKey(deskCheckMatchKey), findsNothing);
  });

  testWidgets('the contact pane: a proven peer gets the request dialog; Send request sends; Waiting with Show my invite and Cancel', (tester) async {
    await _open(tester, const ContactsArgs(selectedId: 'c6').let((a) => ContactsScreen(arg: a)));
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _pairing.clock = DateTime.now;
    _mock.peerCompats[piotr.epicbox!] = PeerCompat(lastMarkedAt: DateTime.now(), claimed: featureMarker | featurePairRequests, featuresAt: DateTime.now());
    _pairing.provenPeers.add(piotr.epicbox!);
    await tester.tap(find.byKey(deskContactPairKey));
    await _real(tester);
    expect(find.text(_l.pairRequestBody), findsOneWidget);
    await tester.tap(find.byKey(deskWay1SendKey));
    await _real(tester);
    expect(_pairing.sentRequests.single.to, piotr.epicbox);
    expect(find.byKey(deskContactWaitingKey), findsOneWidget);
    expect(find.byKey(deskContactShowInviteKey), findsOneWidget);
    expect(find.byKey(deskContactCancelPairingKey), findsOneWidget);
    await tester.tap(find.byKey(deskContactCancelPairingKey));
    await _real(tester);
    await tester.tap(find.text(_l.pairCancelPairing));
    await _real(tester);
    expect(await tester.runAsync(_pairing.pairings), isNot(contains(predicate<Object?>((r) => (r as dynamic).contactId == 'c6'))));
  });

  testWidgets('the contact pane: not a proven peer, Pair goes to the Pair page framed for the contact', (tester) async {
    await _open(tester, const ContactsScreen(arg: ContactsArgs(selectedId: 'c6')));
    await tester.tap(find.byKey(deskContactPairKey));
    await _real(tester);
    expect(_c.read(deskNavProvider).route, DeskRoute.pair);
    expect(_c.read(deskNavProvider).arg, isA<Contact>().having((c) => c.id, 'id', 'c6'));
  });

  testWidgets('Pair requests in the Contacts header: only a contact\'s, Pair opens the from-a-contact dialog, Not now dismisses', (tester) async {
    await _open(tester, const ContactsScreen());
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _pairing.receiveRequest(from: 'es${'z' * 50}@epicbox.epiccash.com', name: 'Stranger');
    _pairing.receiveRequest(from: piotr.epicbox!, name: 'Piotr');
    _c.invalidate(deskPairRequestsProvider);
    await _real(tester);
    expect(find.byKey(deskContactsRequestsKey), findsOneWidget);
    expect(find.text(_l.pairRequestsRow(1)), findsOneWidget);
    await tester.tap(find.byKey(deskContactsRequestsKey));
    await _real(tester);
    expect(find.text(_l.pairWantsToPair(piotr.name)), findsOneWidget);
    expect(find.text(_l.pairWantsToPair('Stranger')), findsNothing);
    await tester.tap(find.byKey(deskRequestsPairKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle(piotr.name)), findsOneWidget);
    expect(find.text(_l.pairInContacts), findsOneWidget);
    await tester.tap(find.byKey(deskIncomingNotNowKey));
    await _real(tester);
    await tester.tap(find.byKey(deskContactsRequestsKey));
    await _real(tester);
    await tester.tap(find.byKey(deskRequestsNotNowKey));
    await _real(tester);
    expect((await tester.runAsync(_pairing.requests))!.where((r) => r.fromAddress == piotr.epicbox), isEmpty);
  });
}

Contact _c0Contact() => Contact(id: 'c1', name: 'Anna Kowalska', address: _anna);

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
