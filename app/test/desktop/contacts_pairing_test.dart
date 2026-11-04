// SPDX-License-Identifier: Apache-2.0
// A contact's Pairing block on the desktop (pairing v3): Verified with its switches and
// "confirmed too", Paired not verified with Check the words, Waiting, keys changed, Ended with
// its reason and the held send, Not paired with Pair, and deleting a paired contact removes
// this wallet's pairing too. Also the Contacts rows' badges and the Experimental switch gone.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart' show FakePairing;
import 'package:epic_wallet/src/models.dart' show PairingParty;
import 'package:epic_wallet/src/wallet_service.dart' show PairingApi, PairingEndReason, PairingState;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingsProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/add_to_contacts_button.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart' show deskConfirmRemovePairingKey, deskSaveContactNameKey, deskWay1SendKey;
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import '../support/experimental.dart';

// The mock pairs Anna (c1, verified), Tom (c4, paired, not verified) and Marta (c9, keys
// changed); Piotr (c6) is not paired.
late ProviderContainer _c;

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  // The mock's own delays run on the test clock.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, Widget screen, {Size size = const Size(1280, 1100), bool experimental = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet())]);
  addTearDown(_c.dispose);
  await tester.runAsync(() async {
    await _c.read(deskProvider.notifier).refresh();
    if (experimental) await deskExperimentalOn(_c);
  });
  _c.read(deskInvoicesProvider);
  await _real(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _contact(WidgetTester tester, String id, {Size size = const Size(1280, 1100)}) => _open(tester, ContactsScreen(arg: ContactsArgs(selectedId: id)), size: size);

final _l = englishStrings;

PairingApi get _pairing => (_c.read(deskApiProvider) as MockDeskWallet).pairing;
FakePairing get _fake => _pairing as FakePairing;

ESwitch _switchOf(WidgetTester tester, String label) => tester.widget<ESwitch>(find.byWidgetPredicate((w) => w is ESwitch && w.semanticLabel == label));

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('a verified contact: Verified, the date, "has not checked yet", both switches on; the verdict makes it "confirmed too"', (tester) async {
    await _contact(tester, 'c1');
    expect(find.text(_l.contactPairing), findsOneWidget);
    expect(find.text(_l.trustVerified), findsWidgets);
    expect(find.textContaining(_l.pairNotChecked('Anna Kowalska')), findsOneWidget);
    expect(_switchOf(tester, _l.contactSealPayments).value, isTrue);
    final allow = _switchOf(tester, _l.contactAllowInvoices);
    allow.onChanged!(!allow.value);
    await _real(tester);
    expect((await tester.runAsync(() => _pairing.pairing(mockAnnaPairing)))!.allowInvoices, !allow.value);
    _fake.peerMatch(mockAnnaPairing);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.textContaining(_l.pairConfirmedToo('Anna Kowalska')), findsOneWidget);
  });

  testWidgets('a contact not verified: Check the words, Allow invoices waits for it', (tester) async {
    await _contact(tester, 'c4');
    expect(find.text(_l.trustPaired), findsWidgets);
    expect(find.byKey(deskContactCheckKey), findsOneWidget);
    expect(find.text(_l.contactCheckWordsFirst), findsOneWidget);
    expect(_switchOf(tester, _l.contactAllowInvoices).onChanged, isNull);
  });

  testWidgets('waiting (answered, not heard): the line, Check the words, Show my invite, Cancel; nothing sealed', (tester) async {
    await _contact(tester, 'c6');
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', state: PairingState.waiting, paymentsAddress: piotr.epicbox);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.pairWaitingFor('Piotr Nowak')), findsWidgets);
    expect(find.textContaining(_l.pairAnsweredNotHeard), findsOneWidget);
    expect(find.byKey(deskContactCheckKey), findsOneWidget);
    expect(find.byKey(deskContactShowInviteKey), findsOneWidget);
    expect(find.byKey(deskContactCancelPairingKey), findsOneWidget);
    expect(_switchOf(tester, _l.contactSealPayments).onChanged, isNull);
  });

  testWidgets('keys changed: the notice with its three ways out, both switches paused', (tester) async {
    await _contact(tester, 'c9');
    expect(find.text(_l.contactKeysChangedTitle('Marta W.')), findsOneWidget);
    expect(find.text(_l.contactKeysChangedBody), findsOneWidget);
    for (final t in [_l.pairCheckWords, _l.contactKeepOldKeys, _l.contactUseNewKeys]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text(_l.contactPausedUntilChecked), findsNWidgets(2));
  });

  testWidgets('ended by the peer: the reason, Pair again, Remove; no switches', (tester) async {
    await _contact(tester, 'c1');
    final anna = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c1');
    _fake.peerMismatch(mockAnnaPairing);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byKey(deskContactEndedKey), findsOneWidget);
    expect(find.text(_l.pairEndedPeerMismatch(anna.name)), findsOneWidget);
    expect(find.text(_l.trustEnded), findsWidgets);
    expect(find.byKey(deskContactPairAgainKey), findsOneWidget);
    expect(find.byKey(deskContactRemovePairingKey), findsOneWidget);
    expect(find.text(_l.contactSealPayments), findsNothing);
  });

  testWidgets('a shop that did not answer the check: Not answering on its row and page, the line, Pair again', (tester) async {
    await _contact(tester, 'c6');
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake
      ..seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', kind: PairingParty.shop, state: PairingState.paired, paymentsAddress: piotr.epicbox)
      ..silent.add('p-piotr');
    await tester.runAsync(() => _fake.checkContacts());
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byKey(deskContactNotAnsweringKey), findsOneWidget);
    expect(find.text(_l.contactNotAnsweringBody), findsOneWidget);
    expect(find.byKey(deskContactPairAgainKey), findsOneWidget);
    // The row's badge and the notice's title.
    expect(find.text(_l.trustNotAnswering), findsAtLeastNWidgets(2));
  });

  testWidgets('never finished: Remove drops it, the contact stays with Pair', (tester) async {
    await _contact(tester, 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', state: PairingState.ended, endedReason: PairingEndReason.neverFinished);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.pairEndedNeverFinished('Piotr Nowak')), findsOneWidget);
    await tester.tap(find.byKey(deskContactRemovePairingKey));
    await _real(tester);
    await tester.tap(find.byKey(deskConfirmRemovePairingKey));
    await _real(tester);
    expect(await tester.runAsync(() => _pairing.pairing('p-piotr')), isNull);
    expect(find.text(_l.pairNotPaired), findsOneWidget);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c6'), isTrue);
  });

  testWidgets('a pairing made before addresses were proven: the line and Pair again; a proven one has neither', (tester) async {
    await _contact(tester, 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', unproven: true);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.trustVerified), findsWidgets);
    expect(find.text(_l.pairAddressNotConfirmed), findsOneWidget);
    await tester.ensureVisible(find.byKey(deskContactPairAgainUnprovenKey));
    await tester.tap(find.byKey(deskContactPairAgainUnprovenKey));
    await _real(tester);
    expect(
      find.byKey(deskWay1SendKey).evaluate().isNotEmpty || _c.read(deskNavProvider).route == DeskRoute.pair,
      isTrue,
      reason: 'a new pairing with the contact starts: the request, or the Pair screen for it',
    );
  });

  for (final verified in [false, true]) {
    testWidgets('Save as new contact: the proven address is written ${verified ? 'at once, Verified' : 'only once Verified'}', (tester) async {
      await _open(tester, const ContactsScreen());
      const address = 'esZoeProvenKey@epicbox.epiccash.com';
      _fake.seedPaired(id: 'p-zoe', name: 'Zoe', state: verified ? PairingState.verified : PairingState.paired, paymentsAddress: address);
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
      final add = find.byKey(deskAddToContactsKey);
      await tester.ensureVisible(add.first);
      await tester.tap(add.first);
      await _real(tester);
      await tester.tap(find.byKey(deskAddToContactsNewKey));
      await _real(tester);
      await tester.enterText(find.byKey(deskSaveContactNameKey), 'Zoe');
      await tester.tap(find.widgetWithText(EButton, _l.deskConSave));
      await _real(tester);
      final zoe = _c.read(deskProvider).contacts!.singleWhere((x) => x.name == 'Zoe');
      expect(zoe.epicbox, verified ? address : isNull);
      expect((await tester.runAsync(() => _pairing.pairing('p-zoe')))!.contactId, zoe.id);
    });
  }

  testWidgets('a pairing not in contacts: Add to contacts and a ⋯ menu, no row of buttons; a contact of its name is offered first; Remove pairing from the menu', (tester) async {
    await _open(tester, const ContactsScreen());
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake.seedPaired(id: 'p-zoe', name: 'Zoe', paymentsAddress: 'esZoeProvenKey@epicbox.epiccash.com');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr Nowak', paymentsAddress: piotr.epicbox);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.pairNotInContacts), findsNWidgets(2));
    expect(find.byKey(deskAddToContactsKey), findsNWidgets(2));
    for (final t in [_l.pairSaveNewContact, _l.pairAddToAContact, _l.contactRemovePairing, _l.pairAddToNamed('Piotr Nowak')]) {
      expect(find.widgetWithText(EButton, t), findsNothing, reason: '$t is in a menu, not a button on the row');
    }
    final piotrRow = find.descendant(of: find.byKey(deskPairingRowKey('p-piotr')), matching: find.byKey(deskAddToContactsKey));
    await tester.ensureVisible(piotrRow);
    await tester.tap(piotrRow);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(deskAddToContactsSuggestedKey), findsOneWidget);
    expect(find.text(_l.pairAddToNamed('Piotr Nowak')), findsOneWidget);
    expect(find.byKey(deskAddToContactsNewKey), findsOneWidget);
    expect(find.byKey(deskAddToContactsExistingKey), findsOneWidget);
    await tester.tapAt(const Offset(900, 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(deskAddToContactsSuggestedKey), findsNothing, reason: 'a tap outside closes the menu');
    await tester.ensureVisible(find.byKey(deskPairingMoreKey('p-zoe')));
    await tester.tap(find.byKey(deskPairingMoreKey('p-zoe')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(deskPairingRemoveKey), findsOneWidget);
    await tester.tap(find.byKey(deskPairingRemoveKey));
    await _real(tester);
    await tester.tap(find.byKey(deskConfirmRemovePairingKey));
    await _real(tester);
    expect(find.byKey(deskPairingRowKey('p-zoe')), findsNothing);
    expect(find.byKey(deskPairingRowKey('p-piotr')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a proven pairing shows no unconfirmed line', (tester) async {
    await _contact(tester, 'c1');
    expect(find.text(_l.trustVerified), findsWidgets);
    expect(find.byKey(deskContactUnprovenKey), findsNothing);
    expect(find.byKey(deskContactPairAgainUnprovenKey), findsNothing);
  });

  testWidgets('a contact not paired offers Pair', (tester) async {
    await _contact(tester, 'c6');
    expect(find.text(_l.pairNotPaired), findsOneWidget);
    expect(find.text(_l.pairNotPairedHint), findsOneWidget);
    expect(find.byKey(deskContactPairKey), findsOneWidget);
  });

  testWidgets('Pair in the header: labelled, secondary, never gold; no hint card, no Pending', (tester) async {
    await _open(tester, const ContactsScreen());
    final pair = tester.widget<EButton>(find.byKey(deskContactsPairKey));
    expect(pair.label, _l.pairTitle);
    expect(pair.kind, EBtnKind.secondary);
    expect(find.text(_l.contactsPairHint), findsNothing);
    expect(find.text(_l.pendingTitle), findsNothing);
  });

  testWidgets('the header keeps Edit, Star and Delete as buttons where they fit, and folds them into a ⋯ menu in a narrow pane', (tester) async {
    await _contact(tester, 'c6');
    expect(find.byKey(deskContactMoreKey), findsNothing);
    expect(find.byKey(deskContactDeleteKey), findsOneWidget);
    await _contact(tester, 'c6', size: const Size(480, 900));
    expect(find.byKey(deskContactPairKey), findsOneWidget, reason: 'Send and Pair stay out');
    expect(find.byKey(deskContactDeleteKey), findsNothing, reason: 'in the menu until it opens');
    await tester.tap(find.byKey(deskContactMoreKey));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(deskContactEditKey), findsOneWidget);
    expect(find.byKey(deskContactStarKey), findsOneWidget);
    expect(find.byKey(deskContactDeleteKey), findsOneWidget);
    // Out of the tree before the test ends, so the providers it read (the contact line's
    // among them) are let go on a frame of the test's own clock.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a contact whose pairing the other side removed: Ended · removed, Pair again', (tester) async {
    await _contact(tester, 'c1');
    _fake.removedByPeer(mockAnnaPairing);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.noticeUnpaired('Anna Kowalska')), findsOneWidget);
    expect(find.text(_l.contactSealPayments), findsNothing);
    expect(find.byKey(deskContactPairAgainKey), findsOneWidget);
    expect(find.byKey(deskContactPairKey), findsOneWidget);
  });

  testWidgets('a paired contact has no Pair in its header', (tester) async {
    await _contact(tester, 'c1');
    expect(find.byKey(deskContactPairKey), findsNothing);
  });

  testWidgets('deleting a paired contact says the pairing goes, and removes it', (tester) async {
    await _contact(tester, 'c1');
    await tester.tap(find.text(_l.deskConDelete));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining(_l.contactDeletePaired('Anna Kowalska')), findsOneWidget);
    await tester.tap(find.text(_l.deskConDeleteAction));
    await _real(tester, 800);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c1'), isFalse);
    expect(await tester.runAsync(() => _pairing.pairing(mockAnnaPairing)), isNull);
  });

  testWidgets('keys back: the contact page docks the notice until OK', (tester) async {
    await _contact(tester, 'c1');
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsNothing);
    _fake.restoreKeys(mockAnnaPairing);
    await _real(tester);
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.commonOk));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_l.contactKeysBack('Anna Kowalska')), findsNothing);
  });

  testWidgets('the rows: Verified, Paired, Waiting and Ended badges; a pending row with Cancel', (tester) async {
    await _open(tester, const ContactsScreen());
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', state: PairingState.waiting, paymentsAddress: piotr.epicbox);
    _fake.seedPaired(id: 'p-gone', name: 'Gone', state: PairingState.ended, endedReason: PairingEndReason.neverFinished);
    await tester.runAsync(() => _fake.standingCode(name: 'Alex'));
    _fake.answerInvite(_fake.standing!.id, name: 'Northwind');
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    for (final t in [_l.trustVerified, _l.trustPairedShort, _l.trustWaiting, _l.trustEnded]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text(_l.pairAnsweredNotHeard), findsWidgets);
    expect(find.byKey(deskPairingCancelKey), findsWidgets);
  });

  testWidgets('Pair shows with the old pairing switch stored off; Settings › Advanced has no Pairing row', (tester) async {
    await _open(tester, const ContactsScreen(), experimental: false);
    expect(find.byKey(deskContactsPairKey), findsOneWidget);
    await _open(tester, const SettingsAdvancedScreen(), experimental: false);
    expect(find.byKey(const ValueKey('adv-pairing')), findsNothing);
    expect(find.byKey(const ValueKey('adv-invoices')), findsOneWidget);
  });
}
