// SPDX-License-Identifier: Apache-2.0
// A contact's Pairing block on the desktop (pairing v3): Verified with its switches and
// "confirmed too", Paired not verified with Check the words, Waiting, keys changed, Ended with
// its reason and the held send, Not paired with Pair, and deleting a paired contact removes
// this wallet's pairing too. Also the Contacts rows' badges, the Experimental switch gone, and
// a relay move: the dialog, the open request, the refused line and the moved date.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart' show deskLevelProvider;
import 'package:epic_wallet/src/desktop/data/invoice_state.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings, localDayMonth;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/pairing_fake.dart' show FakePairing;
import 'package:epic_wallet/src/models.dart' show PairingParty;
import 'package:epic_wallet/src/wallet_service.dart' show PairingApi, PairingEndReason, PairingRecord, PairingState, RelayMoveState;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingsProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/add_to_contacts_button.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/relay_move_dialog.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart' show hostSettingsProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart' show DeskPairedSaveDialog, deskConfirmRemovePairingKey, deskSaveContactNameKey, deskWay1SendKey;
import 'package:epic_wallet/src/desktop/screens/settings/settings_advanced.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/history/domain_check_book.dart' show DomainStatus;
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

Future<void> _open(WidgetTester tester, Widget screen, {Size size = const Size(1280, 1100), bool experimental = true, WalletLevel? level}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet()), if (level != null) deskLevelProvider.overrideWithValue(level)]);
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

  testWidgets('waiting (answered, not heard): the line, Check the words, Show my invite, Remove pairing; nothing sealed', (tester) async {
    await _contact(tester, 'c6');
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', state: PairingState.waiting, paymentsAddress: piotr.epicbox);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.pairWaitingFor('Piotr Nowak')), findsWidgets);
    expect(find.textContaining(_l.pairAnsweredNotHeard), findsOneWidget);
    expect(find.byKey(deskContactCheckKey), findsOneWidget);
    expect(find.byKey(deskContactShowInviteKey), findsOneWidget);
    expect(find.byKey(deskContactCancelPairingKey), findsNothing);
    expect(find.byKey(deskContactRemovePairingKey), findsOneWidget);
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
    _fake.peerMismatch(mockAnnaPairing);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byKey(deskContactEndedKey), findsOneWidget);
    expect(find.text(_l.pairEndedRowPeerMismatch), findsOneWidget);
    expect(find.text(_l.trustEnded), findsWidgets);
    expect(find.byKey(deskContactPairAgainKey), findsOneWidget);
    expect(find.byKey(deskContactRemovePairingKey), findsOneWidget);
    expect(find.text(_l.contactSealPayments), findsNothing);
  });

  testWidgets('a shop that did not answer the check: Not answering on its row and page, the line, Pair again', (tester) async {
    await _contact(tester, 'c6');
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    _fake
      ..seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', kind: PairingParty.shop, peerProfile: 2, state: PairingState.paired, paymentsAddress: piotr.epicbox)
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

  testWidgets('a proven domain shows under the name and in Pairing; a refused one only in Pairing', (tester) async {
    await _contact(tester, 'c6');
    final piotr = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c6');
    for (final (status, under, word) in [
      (DomainStatus.proven, findsOneWidget, _l.contactDomainVerified),
      (DomainStatus.refused, findsNothing, _l.contactDomainRefused),
    ]) {
      _fake.seedPaired(
        id: 'p-piotr',
        name: 'Piotr',
        contactId: 'c6',
        state: PairingState.verified,
        paymentsAddress: piotr.epicbox,
        peerDomain: 'piotr.example',
        domainStatus: status,
      );
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
      expect(find.byKey(deskContactHeaderDomainKey), under, reason: status.name);
      if (under == findsOneWidget) {
        expect(find.descendant(of: find.byKey(deskContactHeaderDomainKey), matching: find.text('piotr.example')), findsOneWidget);
      }
      expect(find.descendant(of: find.byKey(deskContactDomainKey), matching: find.text(word)), findsOneWidget, reason: status.name);
    }
  });

  testWidgets('never finished: Remove drops it, the contact stays with Pair', (tester) async {
    await _contact(tester, 'c6');
    _fake.seedPaired(id: 'p-piotr', name: 'Piotr', contactId: 'c6', state: PairingState.ended, endedReason: PairingEndReason.neverFinished);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text(_l.pairEndedRowNeverFinished), findsOneWidget);
    await tester.tap(find.byKey(deskContactRemovePairingKey));
    await _real(tester);
    await tester.tap(find.byKey(deskConfirmRemovePairingKey));
    await _real(tester);
    expect(await tester.runAsync(() => _pairing.pairing('p-piotr')), isNull);
    expect(find.text(_l.pairNotPaired), findsOneWidget);
    expect(_c.read(deskProvider).contacts!.any((x) => x.id == 'c6'), isTrue);
  });

  testWidgets('a pairing in no contact: Remove shows it working until it is gone, and cannot be pressed twice', (tester) async {
    await _open(tester, const ContactsScreen());
    _fake.seedPaired(id: 'p-lol', name: 'Lol', state: PairingState.paired);
    _fake.removeDelay = const Duration(seconds: 3);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    await tester.ensureVisible(find.byKey(deskPairingMoreKey('p-lol')));
    await tester.tap(find.byKey(deskPairingMoreKey('p-lol')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(deskPairingRemoveKey));
    await _real(tester);
    await tester.tap(find.byKey(deskConfirmRemovePairingKey));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(deskPairingBusyKey('p-lol')), findsOneWidget, reason: 'the core tells the contact first: the row says it is working');
    expect(find.byKey(deskPairingMoreKey('p-lol')), findsNothing, reason: 'no second Remove while the first runs');
    await tester.pump(const Duration(seconds: 3));
    await _real(tester);
    expect(find.byKey(deskPairingRowKey('p-lol')), findsNothing);
    expect(_fake.calls.where((c) => c == 'remove'), hasLength(1));
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

  testWidgets('the Verified dialog: Save as a new contact puts the pairing in it and closes, though the new contact changes the dialog', (tester) async {
    await _open(tester, const ContactsScreen());
    _fake.seedPaired(id: 'p-shop', name: 'Shop', state: PairingState.verified, paymentsAddress: 'esShopProvenKey@epicbox.epiccash.com');
    // Frames run while the core attaches: the dialog rebuilds for the new contact meanwhile.
    _fake.attachDelay = const Duration(milliseconds: 600);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    unawaited(showEDialog<void>(tester.element(find.byType(ContactsScreen)), builder: (_) => const DeskPairedSaveDialog(pairingId: 'p-shop', verified: true)));
    await _real(tester);
    final add = find.descendant(of: find.byType(DeskPairedSaveDialog), matching: find.byKey(deskAddToContactsKey));
    await tester.tap(add);
    await _real(tester);
    await tester.tap(find.byKey(deskAddToContactsNewKey));
    await _real(tester);
    await tester.enterText(find.byKey(deskSaveContactNameKey), 'Shop');
    await tester.tap(find.widgetWithText(EButton, _l.deskConSave));
    await _real(tester);
    final shop = _c.read(deskProvider).contacts!.singleWhere((x) => x.name == 'Shop');
    expect((await tester.runAsync(() => _pairing.pairing('p-shop')))!.contactId, shop.id, reason: 'the pairing joins the contact the dialog made');
    expect(find.byType(DeskPairedSaveDialog), findsNothing, reason: 'saved: the dialog closes, it does not offer "Add to Shop"');
  });

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

  // The Pair page shows only at Deep end: below it, no Pair that would land on Overview.
  for (final level in [WalletLevel.justSendReceive, WalletLevel.casual]) {
    testWidgets('below Deep end ($level) Contacts offers no Pair: no button, no Pairing block, none in the header', (tester) async {
      await _open(tester, const ContactsScreen(arg: ContactsArgs(selectedId: 'c6')), level: level);
      expect(find.byKey(deskContactPairKey), findsNothing);
      expect(find.text(_l.contactPairing), findsNothing);
      expect(find.byKey(deskContactsPairKey), findsNothing);
    });
  }

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
    expect(find.text(_l.pairEndedRowUnpaired), findsOneWidget);
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

  testWidgets('the rows: Verified, Paired, Waiting and Ended badges; a row answered, not heard, with Remove under ⋯', (tester) async {
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
    expect(find.byKey(deskPairingCancelKey), findsNothing);
    expect(find.byKey(deskPairingMoreKey(_fake.records.firstWhere((r) => r.name == 'Northwind').id)), findsOneWidget);
  });

  testWidgets('Pair shows with the old pairing switch stored off; Settings › Advanced has no Pairing row', (tester) async {
    await _open(tester, const ContactsScreen(), experimental: false);
    expect(find.byKey(deskContactsPairKey), findsOneWidget);
    await _open(tester, const SettingsAdvancedScreen(), experimental: false);
    expect(find.byKey(const ValueKey('adv-pairing')), findsNothing);
    expect(find.byKey(const ValueKey('adv-invoices')), findsOneWidget);
  });

  group('a contact moves to another relay', () {
    const moved = 'box.example.org';

    /// Anna as a domain-backed contact, asking to move to [moved].
    Future<void> asking(WidgetTester tester) async {
      await tester.runAsync(() async {
        final r = (await _pairing.pairing(mockAnnaPairing))!;
        _fake.seed(r.copyWith(peerEncKey: FakePairing.serviceKey));
        await _fake.askRelayMove(mockAnnaPairing, moved);
      });
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
    }

    Future<PairingRecord> anna(WidgetTester tester) async =>
        (await tester.runAsync(() async => (await _pairing.pairings()).firstWhere((p) => p.id == mockAnnaPairing)))!;

    testWidgets('the dialog: Accept adds the relay last and moves Anna', (tester) async {
      await _open(tester, const _AskDesk());
      await asking(tester);
      expect((await anna(tester)).relayMove, RelayMoveState.ask);
      await tester.tap(find.byKey(_askDeskKey));
      await _real(tester);
      expect(find.byKey(deskRelayMoveDialogKey), findsOneWidget);
      expect(find.text(_l.relayMoveTitle('Anna Kowalska')), findsOneWidget);
      expect(find.text(_l.relayMoveBody('Anna Kowalska', moved)), findsOneWidget);
      expect(find.text(_l.relayMoveAddsServer(moved)), findsOneWidget);
      await tester.tap(find.byKey(deskRelayMoveAcceptKey));
      await _real(tester);
      expect(_fake.calls, contains('acceptMove:$mockAnnaPairing'));
      expect((await anna(tester)).homeRelay, moved);
      final hosts = _c.read(hostSettingsProvider);
      expect(hosts.epicboxLabels.last, moved);
      expect(hosts.epicboxUse, isNot(moved), reason: 'never made the one in use');
    });

    testWidgets('the dialog: Refuse moves nothing and adds no server', (tester) async {
      await _open(tester, const _AskDesk());
      await asking(tester);
      await tester.tap(find.byKey(_askDeskKey));
      await _real(tester);
      await tester.tap(find.byKey(deskRelayMoveRefuseKey));
      await _real(tester);
      expect(_fake.calls, contains('refuseMove:$mockAnnaPairing'));
      expect((await anna(tester)).relayMove, RelayMoveState.refused);
      expect(_c.read(hostSettingsProvider).epicboxLabels, isNot(contains(moved)));
    });

    testWidgets('closed without a choice: the request on the details with Accept and Refuse; Refuse leaves a line with Accept', (tester) async {
      await _contact(tester, 'c1');
      await asking(tester);
      await tester.runAsync(() => _fake.markRelayMoveShown(mockAnnaPairing, moved));
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
      expect(find.byKey(deskContactMoveAskedKey), findsOneWidget);
      expect(find.text(_l.contactMoveAsked(moved)), findsOneWidget);
      await tester.tap(find.byKey(deskContactMoveRefuseKey));
      await _real(tester);
      expect(find.byKey(deskContactMoveAskedKey), findsNothing);
      expect(find.text(_l.contactMoveRefused(moved)), findsOneWidget);
      await tester.tap(find.byKey(deskContactMoveAcceptKey));
      await _real(tester);
      expect(_fake.calls, contains('acceptMove:$mockAnnaPairing'));
      expect(find.text(_l.contactMoveRefused(moved)), findsNothing);
    });

    testWidgets('any other contact is moved without a word and dated; a relay that is not public is not followed', (tester) async {
      await _contact(tester, 'c1');
      await tester.runAsync(() => _fake.askRelayMove(mockAnnaPairing, moved));
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
      final p = await anna(tester);
      expect(p.homeRelay, moved);
      expect(find.byKey(deskContactMoveAskedKey), findsNothing);
      expect(find.text(_l.contactMovedOn(localDayMonth(_l, p.movedAt!))), findsOneWidget);

      await tester.runAsync(() => _fake.askRelayMove(mockAnnaPairing, '10.0.0.7'));
      _c.invalidate(deskPairingsProvider);
      await _real(tester);
      expect(find.text(_l.contactMoveNotPublic('10.0.0.7')), findsOneWidget);
      expect(find.byKey(deskContactMoveAcceptKey), findsNothing);
    });
  });
}

const Key _askDeskKey = ValueKey('test-ask-move');

/// A button that shows Anna's relay move the way the shell does.
class _AskDesk extends ConsumerWidget {
  const _AskDesk();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(deskPairingsProvider).value?.where((p) => p.id == mockAnnaPairing).firstOrNull;
    return Center(
      child: TextButton(key: _askDeskKey, onPressed: p == null ? null : () => deskAskRelayMove(context, ref, p), child: const Text('Ask')),
    );
  }
}
