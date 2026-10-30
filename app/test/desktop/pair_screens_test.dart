// SPDX-License-Identifier: Apache-2.0
// The desktop's Pair page: the code with its words, an online invite
// copied with the name they will see, a pasted invite answered, and Pending invites.
import 'dart:async';

import 'package:epic_wallet/src/sas_table.dart';
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskOwnCardProvider, deskPairingsProvider, deskSeenAsProvider;
import 'package:epic_wallet/src/desktop/data/desk_store.dart' show deskSettingsFromJson, deskSettingsToJson;
import 'package:epic_wallet/src/desktop/data/invoice_state.dart' show deskInvoicesProvider;
import 'package:epic_wallet/src/desktop/data/invoices.dart' show IncomingInvoice, PayState;
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/review_screen.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart' show ContactsArgs, ContactsScreen;
import 'package:epic_wallet/src/desktop/screens/transfer/contact_picker.dart' show showContactPicker;
import 'package:epic_wallet/src/desktop/screens/settings/settings_invoices.dart' show InvoiceSettingsBlock;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_notices.dart' show pairingEventOnScreen, pairingWordsOnScreen;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/wallet_service.dart' show PairingEvent, PairingEventKind, PairingState;
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

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, Widget screen, {NetworkMode? mode}) async {
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
  if (mode != null) {
    final n = _c.read(deskProvider.notifier);
    await tester.runAsync(() => n.saveSettings(_c.read(deskProvider).settings.copyWith(advanced: _c.read(deskProvider).settings.advanced.withMode(mode))));
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await _real(tester);
}

Future<void> _seenAs(WidgetTester tester, String name) async {
  final field = find.descendant(of: find.widgetWithText(EField, _l.pairSeenAs), matching: find.byType(EditableText));
  await tester.enterText(field.first, name);
  await tester.pump();
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(deskForgetOpenChecks);

  testWidgets('the page: the lead, three ways as tiles (Words open), Got words or a link? and How pairing works', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairWaysLead), findsOneWidget);
    for (final t in [_l.pairWayAutomatic, _l.pairWayMessage, _l.pairInPerson, _l.pairGotInvite, _l.pairHowItWorks, _l.pairWayWordsHint, _l.pairWayInPersonDesk]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.byKey(deskPairWordsPanelKey), findsOneWidget);
    await tester.tap(find.byKey(deskPairMessageKey));
    await _real(tester);
    expect(find.byKey(deskPairMessagePanelKey), findsOneWidget);
    expect(find.bySemanticsLabel(_l.pairStepOf(1, _l.pairStepInvite)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invite by message: Copy message copies "Pair with me…", then the wait with Paste reply; a pasted reply opens the finish link, then the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await tester.tap(find.byKey(deskPairMessageKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    final invite = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingInvite).single;
    expect(_clip, _l.pairInviteMessage(invite.inviteLink!));
    expect(find.text(_l.pairAwaitReplyTitle), findsOneWidget);
    _clip = _l.pairReplyMessage(fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Ola'}));
    await tester.ensureVisible(find.byKey(deskPairPasteReplyKey));
    await tester.tap(find.byKey(deskPairPasteReplyKey));
    await _real(tester);
    expect(find.text(_l.pairFinishTitle), findsOneWidget);
    expect(find.text(_l.pairFinishLead('Ola')), findsOneWidget);
    await tester.tap(find.byKey(deskFinishCopyKey));
    await _real(tester);
    expect(_clip, startsWith(_l.pairFinishMessage('epiccash://pair-confirm/').replaceAll('epiccash://pair-confirm/', '')));
    expect(_clip, contains('epiccash://pair-confirm/'));
    await tester.tap(find.byKey(deskConfirmBackCheckKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Ola')), findsOneWidget);
    // Closed, so its pairing's one-check guard is free for the next test.
    Navigator.of(tester.element(find.byKey(deskCheckMatchKey))).pop();
    await _real(tester);
  });

  testWidgets('the joiner by message: Pair, the reply to copy, then Paste finish link opens the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    await tester.enterText(
      find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)),
      _l.pairInviteMessage(_pairing.inviteLinkFrom(name: 'Anna')),
    );
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    final answered = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply).single;
    expect(find.text(_l.pairReplyTitle), findsOneWidget);
    await tester.tap(find.byKey(deskReplyCopyKey));
    await _real(tester);
    expect(_clip, startsWith('My reply'));
    expect(find.text(_l.pairAwaitFinishTitle), findsOneWidget);
    _clip = fakePairingLink('pair-confirm', {'t': answered.id, 'n': 'Anna'});
    await tester.tap(find.byKey(deskPasteFinishKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Anna')), findsOneWidget);
    // Closed, so its pairing's one-check guard is free for the next test.
    Navigator.of(tester.element(find.byKey(deskCheckMatchKey))).pop();
    await _real(tester);
  });

  testWidgets('the clipboard is read on Paste only: nothing on open, Paste fills Got words or a link?, Pair opens it', (tester) async {
    await _open(tester, const DeskPairScreen());
    _clip = 'Pair with me in Epic Cash: ${_pairing.inviteLinkFrom(name: 'Northwind')}';
    await _seenAs(tester, 'Alex');
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsNothing, reason: 'no clipboard read on open');
    expect(tester.widget<EditableText>(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText))).controller.text, isEmpty);
    await tester.tap(find.byKey(deskPairPasteKey));
    await _real(tester);
    expect(tester.widget<EditableText>(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText))).controller.text, _clip);
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
  });

  testWidgets('a pasted invite opens the incoming dialog; Pair answers it', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    final link = _pairing.inviteLinkFrom(name: 'Northwind', asksInvoices: true);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), link);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    final answered = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply);
    expect(answered, hasLength(1));
    expect(answered.single.asksInvoices, isFalse, reason: 'Allow invoices is off until the user turns it on');
  });

  testWidgets('pairing words pasted with their emoji, as the copy once put them, open the invite', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    final preview = (await tester.runAsync(() => _pairing.openInvite(_pairing.inviteLinkFrom(name: 'Northwind'))))!;
    final five = [sasTable[7], sasTable[42], sasTable[7], sasTable[200], sasTable[3]];
    _pairing.wordsInvites[five.map((w) => w.name).join(' ')] = preview;
    final pasted = '${five.map((w) => '${w.emoji} ${w.name}').join('  ')}\n';
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), pasted);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
  });

  testWidgets('this wallet\'s own invite pasted: This is your own code, no Pair with …', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    final mine = (await tester.runAsync(() => _pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 24))))!;
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), mine.inviteLink!);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairOwnCode), findsOneWidget);
    expect(find.text(_l.pairIncomingTitle('Alex')), findsNothing);
  });

  testWidgets('the whole shared invite message, its lines run together by the field, opens the invite', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    final link = _pairing.inviteLinkFrom(name: 'Northwind', asksInvoices: true);
    final message = _l.pairInviteMessage(link).replaceAll('\n', '');
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), message);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
  });

  testWidgets('a pasted card link pairs face to face: this wallet\'s card to hand back, then the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), _pairing.cardLinkFrom('Ola'));
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairCardBackTitle('Ola')), findsOneWidget);
    final link = tester.widget<SelectableText>(find.byKey(deskCardBackLinkKey)).data!;
    expect(link, startsWith('epiccash://contact/'));
    await tester.tap(find.byKey(deskCardBackCheckKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Ola')), findsOneWidget);
    expect((await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.paired && r.name == 'Ola'), hasLength(1));
  });

  testWidgets('They match on a pairing in no contact: the result offers to save it, and Save as a new contact does', (tester) async {
    await _open(tester, const DeskPairScreen());
    await tester.tap(find.byKey(deskPairInPersonKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), _pairing.cardLinkFrom('Ola'));
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    await tester.tap(find.byKey(deskCheckMatchKey));
    await _real(tester);
    expect(find.text(_l.sasMatchedTitle('Ola')), findsOneWidget);
    expect(find.text(_l.pairSaveContactTitle('Ola')), findsOneWidget);
    await tester.tap(find.byKey(deskSavedNewKey));
    await _real(tester);
    await tester.enterText(find.descendant(of: find.byKey(deskSaveContactNameKey), matching: find.byType(EditableText)), 'Ola K.');
    await tester.tap(find.widgetWithText(EButton, _l.deskConSave));
    await _real(tester);
    final contact = _c.read(deskProvider).contacts!.firstWhere((c) => c.name == 'Ola K.');
    final paired = (await tester.runAsync(_pairing.pairings))!.firstWhere((r) => r.name == 'Ola');
    expect(paired.contactId, contact.id);
    expect(find.byType(DeskPairedSaveDialog), findsNothing, reason: 'saved: the result closes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a re-pair: the result offers the contact of its name first, and Add to starts the key check', (tester) async {
    await _open(tester, const DeskPairScreen());
    final id = (await tester.runAsync(() => _c.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Ola'))))!;
    _pairing.seedPaired(id: 'old-ola', name: 'Ola', state: PairingState.verified, contactId: id);
    _c.invalidate(deskPairingsProvider);
    await tester.tap(find.byKey(deskPairInPersonKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), _pairing.cardLinkFrom('Ola'));
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    await tester.tap(find.byKey(deskCheckMatchKey));
    await _real(tester);
    expect(find.text(_l.pairAddToNamed('Ola')), findsOneWidget);
    expect(find.byKey(deskSavedNewKey), findsOneWidget);
    await tester.tap(find.byKey(deskSavedAddToNamedKey));
    await _real(tester);
    expect(_pairing.calls, contains('attach'));
    final all = (await tester.runAsync(_pairing.pairings))!.where((r) => r.name == 'Ola').toList();
    expect(all.single.id, 'old-ola', reason: 'the old keys are back: the new pairing folded into the old one');
    expect(find.byType(DeskPairedSaveDialog), findsNothing);
  });

  testWidgets('the result closes when its pairing goes meanwhile (folded or removed), never an empty "is verified" (two-app c)', (tester) async {
    await _open(tester, const DeskPairScreen());
    await tester.tap(find.byKey(deskPairInPersonKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), _pairing.cardLinkFrom('Ola'));
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    await tester.tap(find.byKey(deskCheckMatchKey));
    await _real(tester);
    expect(find.byType(DeskPairedSaveDialog), findsOneWidget);
    final ola = (await tester.runAsync(_pairing.pairings))!.singleWhere((r) => r.name == 'Ola');
    await tester.runAsync(() => _pairing.removePairing(ola.id));
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byType(DeskPairedSaveDialog), findsNothing);
    expect(find.text(_l.sasMatchedTitle('')), findsNothing);
  });

  testWidgets('Copy my card link first: their card then goes straight to the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await tester.tap(find.byKey(deskPairInPersonKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    expect(_c.read(deskOwnCardProvider)?.link, startsWith('epiccash://contact/'));
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), _pairing.cardLinkFrom('Ola'));
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairCardBackTitle('Ola')), findsNothing);
    expect(find.text(_l.sasDialogTitle('Ola')), findsOneWidget);
    expect(_c.read(deskOwnCardProvider), isNull, reason: 'a card pairs once');
  });

  testWidgets('no name error on a page just opened; it shows once an action needs the name', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairSeenAsMissing), findsNothing);
    expect(find.text(_l.pairNameForCode), findsOneWidget);
    await tester.tap(find.byKey(deskPairMessageKey));
    await _real(tester);
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    expect(find.text(_l.pairSeenAsMissing), findsOneWidget);
  });

  testWidgets('the page opened again shows the words still open, no new invite each visit (WIN2-1)', (tester) async {
    await _open(tester, const DeskPairScreen());
    // The mock pins its pairing clock for the shots; the page counts in real time.
    _pairing.clock = DateTime.now;
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    final first = _pairing.records.where((r) => r.state == PairingState.pendingInvite && r.inviteWords.isNotEmpty).toList();
    expect(first, hasLength(1));
    Widget app(Widget screen) => UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    );
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpWidget(app(const DeskPairScreen()));
    await _real(tester, 1200);
    final again = _pairing.records.where((r) => r.state == PairingState.pendingInvite && r.inviteWords.isNotEmpty).toList();
    expect(again.map((r) => r.id), [first.single.id]);
    expect(_pairing.calls.where((c) => c == 'makeInvite'), hasLength(1));
  });

  testWidgets('the code appears once a name is typed, without opening the page again', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairNameForCode), findsOneWidget);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    expect(find.text(_l.pairNameForCode), findsNothing);
    expect(find.byType(WordTiles), findsOneWidget);
  });

  testWidgets('Offline: Words is off, Invite by message opens; in person the card shows and copies', (tester) async {
    await _open(tester, const DeskPairScreen(), mode: NetworkMode.nodeOnly);
    expect(find.text(_l.pairOfflineHint), findsOneWidget);
    expect(find.text(_l.pairWordsNeedEpicbox), findsOneWidget);
    expect(find.byKey(deskPairMessagePanelKey), findsOneWidget, reason: 'the message way opens first');
    await tester.tap(find.byKey(deskPairInPersonKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await _real(tester, 1200);
    expect(find.bySemanticsLabel(_l.pairCodeLabel), findsOneWidget);
    expect(_c.read(deskOwnCardProvider)?.link, startsWith('epiccash://contact/'));
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    expect(_clip, startsWith('epiccash://contact/'));
    await tester.tap(find.byKey(deskPairMessageKey));
    await _real(tester);
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    expect(_clip, contains('epiccash://pair/'));
    expect(tester.takeException(), isNull);
  });

  test('an answer a screen turns into the words check shows no notice of its own', () {
    bool shown(PairingEvent e) => e.pairingId == 'p1';
    const replied = PairingEvent(PairingEventKind.replied, pairingId: 'p1');
    const other = PairingEvent(PairingEventKind.replied, pairingId: 'p2');
    const request = PairingEvent(PairingEventKind.invoiceFromContact, pairingId: 'p1');
    expect(pairingEventOnScreen(replied), isFalse);
    pairingWordsOnScreen.add(shown);
    addTearDown(() => pairingWordsOnScreen.remove(shown));
    expect(pairingEventOnScreen(replied), isTrue);
    expect(pairingEventOnScreen(other), isFalse);
    expect(pairingEventOnScreen(request), isFalse, reason: 'only the answered and paired notices');
  });

  testWidgets('Settings › Invoices: keys changed has the risk badge, the paused line and Check the words', (tester) async {
    await _open(tester, const SingleChildScrollView(child: InvoiceSettingsBlock()));
    // The mock's Marta W. is in keys changed, as on her contact page.
    expect((await tester.runAsync(() => _pairing.pairing(mockMartaPairing)))!.state, PairingState.keysChanged);
    expect(find.text('Marta W.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final row = find.ancestor(of: find.text('Marta W.'), matching: find.byType(ESetRow));
    Finder inRow(Finder f) => find.descendant(of: row, matching: f);
    expect(inRow(find.text(_l.trustKeysChanged)), findsOneWidget);
    expect(inRow(find.textContaining(_l.contactKeysChangedStatus)), findsOneWidget);
    expect(inRow(find.textContaining(_l.invSetRowCheckFirst)), findsNothing, reason: 'not the paired text');
    await tester.tap(inRow(find.widgetWithText(EButton, _l.noticeCheckWords)));
    await _real(tester);
    expect(find.text(_l.sasMatch), findsOneWidget);
  });

  testWidgets('Pending invites lists what waits, with Cancel', (tester) async {
    await _open(tester, const DeskPendingScreen());
    // The mock's pairings live on its own date; this one is made now, as the screen counts.
    _pairing.clock = DateTime.now;
    await tester.runAsync(() => _pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 24), label: 'Ola'));
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text('Ola'), findsOneWidget);
    expect(find.text(_l.pairCopyMessage), findsWidgets);
    expect(find.text(_l.pairPasteReply), findsWidgets);
  });

  testWidgets('Pending invites: an answer waiting for a confirm can be removed; an unnamed invite has a glyph', (tester) async {
    await _open(tester, const DeskPendingScreen());
    _pairing.clock = DateTime.now;
    await tester.runAsync(() async {
      final preview = await _pairing.openInvite(_pairing.inviteLinkFrom(name: 'Anna'));
      await _pairing.acceptInvite(token: preview.token, name: 'Alex');
      await _pairing.makeInvite(name: 'Alex', expiry: const Duration(minutes: 10), words: true);
    });
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byIcon(EIcons.words), findsOneWidget);
    expect(find.text('·'), findsNothing);
    await tester.tap(find.byKey(deskPendingRemoveKey));
    await _real(tester);
    expect((await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply && r.name == 'Anna'), isEmpty);
  });

  testWidgets('Review request: a fee with no estimate shows as unknown, never 0', (tester) async {
    await _open(tester, const SizedBox.shrink());
    final now = DateTime.now();
    _mock.proto.toPay.add(
      IncomingInvoice(
        slateId: 'aaaaaaaa-0000-4000-8000-00000000f0e0',
        senderAddress: 'esA',
        label: 'Floo C',
        reference: 'DEMO-1042',
        amount: 8000000,
        fee: 0,
        feeKnown: false,
        receivedAt: now,
        expiresAt: now.add(const Duration(hours: 5)),
        state: PayState.waiting,
      ),
    );
    _c.invalidate(deskInvoicesProvider);
    await _real(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: const Scaffold(body: InvoiceReviewScreen(arg: 'aaaaaaaa-0000-4000-8000-00000000f0e0')),
        ),
      ),
    );
    await _real(tester);
    expect(find.text(_l.deskInvPayerFee), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2), reason: 'the fee and the total');
    // The reference, as the phone shows it.
    expect(find.text(_l.reqReference), findsOneWidget);
    expect(find.text('DEMO-1042'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New request on a core without request files names contacts only', (tester) async {
    await _open(tester, const SizedBox.shrink());
    _mock.supportsRequestFiles = false;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: IssueInvoiceScreen())),
      ),
    );
    await _real(tester);
    expect(find.textContaining('as a file'), findsNothing);
    expect(find.text(_l.reqNewToHintContacts).evaluate().length + find.text(_l.reqNoPayersContacts).evaluate().length, 1);
  });

  testWidgets('a contact row with no address: no Unknown tag', (tester) async {
    await _open(tester, const SizedBox(width: 400, child: EAddressLines(name: 'Floo C', address: '', note: 'met at the meetup')));
    expect(find.text('Floo C'), findsOneWidget);
    expect(find.text(_l.deskKitUnknown), findsNothing);
    expect(find.text('met at the meetup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow contact row with several addresses shows their kind tags, not one address', (tester) async {
    const box = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
    const tor = 'http://wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
    await _open(
      tester,
      const SizedBox(width: 150, child: EAddressLines(name: 'Floo C', address: box, addresses: [box, 'http://10.0.0.2:3415', tor], note: 'shop')),
    );
    expect(find.byType(EKindTag), findsNWidgets(3));
    expect(find.byType(EShortAddress), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide contact row with several addresses shows the default one short, then the tags', (tester) async {
    const box = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
    await _open(
      tester,
      const SizedBox(width: 600, child: EAddressLines(name: 'Floo C', address: box, addresses: [box, 'http://10.0.0.2:3415'], note: 'shop')),
    );
    expect(find.byType(EKindTag), findsNWidgets(2));
    expect(find.byType(EShortAddress), findsOneWidget);
    expect(find.text(' · shop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Contacts lists a pairing in no contact by its name, with its choices', (tester) async {
    await _open(tester, const ContactsScreen());
    _pairing.seedPaired(id: 'p-floo', name: 'Floo C', state: PairingState.verified);
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text('Floo C'), findsOneWidget);
    expect(find.text(_l.pairNotInContacts), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.pairSaveNewContact), findsOneWidget);
    expect(find.widgetWithText(EButton, _l.contactRemovePairing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a contact saved without an address keeps none: a new name saves', (tester) async {
    await _open(tester, const SizedBox.shrink());
    final id = (await tester.runAsync(() => _c.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Floo C'))))!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: ContactsScreen(arg: ContactsArgs(selectedId: id, editing: true)))),
      ),
    );
    await _real(tester);
    final name = find.descendant(of: find.widgetWithText(EField, _l.deskConFieldName), matching: find.byType(EditableText));
    await tester.enterText(name.first, 'Floo Cee');
    await tester.tap(find.widgetWithText(EButton, _l.deskConSave));
    await _real(tester);
    expect(find.text(_l.deskConErrAddressEmpty), findsNothing);
    expect(_c.read(deskProvider).contacts!.firstWhere((c) => c.id == id).name, 'Floo Cee');
  });

  testWidgets('Add to a contact: the picker says the pairing joins the contact, not Send\'s line', (tester) async {
    await _open(tester, const SizedBox.shrink());
    final ctx = tester.element(find.byType(SizedBox).first);
    unawaited(showContactPicker(ctx, description: _l.deskConPickForPairing));
    await _real(tester);
    expect(find.text(_l.deskConPickForPairing), findsOneWidget);
    expect(find.text(_l.deskSendPickDesc), findsNothing);
  });

  testWidgets('an answer pasted by hand: the confirm to send back, then the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'Alex');
    final invite = (await tester.runAsync(() => _pairing.makeInvite(name: 'Alex', expiry: const Duration(hours: 24))))!;
    await tester.enterText(
      find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)),
      fakePairingLink('pair-reply', {'t': invite.id, 'n': 'Ola'}),
    );
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairFinishLead('Ola')), findsOneWidget);
    expect(tester.widget<SelectableText>(find.byKey(deskConfirmBackLinkKey)).data, contains('epiccash://pair-confirm/'));
    await tester.tap(find.byKey(deskConfirmBackCheckKey));
    await _real(tester);
    expect(find.text(_l.sasDialogTitle('Ola')), findsOneWidget);
  });

  testWidgets('the name others see is kept in the settings', (tester) async {
    await _open(tester, const DeskPairScreen());
    await tester.tap(find.byKey(deskPairMessageKey));
    await _real(tester);
    await _seenAs(tester, 'Alex');
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    expect(_c.read(deskProvider).settings.pairingSeenAs, 'Alex');
    expect(_c.read(deskSeenAsProvider), 'Alex');
  });

  test('the settings file keeps the name, and an old file reads without it', () {
    final kept = deskSettingsFromJson(deskSettingsToJson(const DeskSettings(pairingSeenAs: 'Alex')));
    expect(kept.pairingSeenAs, 'Alex');
    expect(deskSettingsFromJson(const {}).pairingSeenAs, '');
    expect(deskSettingsToJson(const DeskSettings()).containsKey('pairingSeenAs'), isFalse);
  });

  testWidgets('a paid request from a paired contact: its timeline in the transaction', (tester) async {
    await _open(tester, const SizedBox.shrink());
    _c.read(deskInvoicesProvider);
    await _real(tester);
    final tx = _c.read(deskProvider).txs!.firstWhere((t) => t.id == 37);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SingleChildScrollView(child: TxDetail(tx: tx)))),
      ),
    );
    await _real(tester);
    final name = _c.read(deskProvider).contacts!.firstWhere((c) => c.id == 'c5').name;
    expect(find.text(_l.reqTlPaid), findsOneWidget);
    expect(find.text(_l.reqTlDelivered(name)), findsOneWidget);
    expect(find.text(_l.reqTlPosted(name)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New request to a pairing gone meanwhile asks for a contact, not "That did not work"', (tester) async {
    await _open(tester, const SizedBox.shrink());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: IssueInvoiceScreen(arg: 'folded-and-gone'))),
      ),
    );
    await _real(tester);
    final before = _c.read(deskInvoicesProvider)?.sent.length;
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskInvIssuerAmount), matching: find.byType(EditableText)), '0.04');
    await tester.pump();
    await tester.tap(find.text(_l.reqNewSend));
    await _real(tester);
    expect(find.text(_l.deskInvFailed), findsNothing);
    expect(find.text(_l.reqPickContact), findsWidgets);
    expect(_c.read(deskInvoicesProvider)?.sent.length, before, reason: 'nothing was asked');
  });

  testWidgets('withdrawn while the Approve dialog is open: it names the sender and Pay goes', (tester) async {
    await _open(tester, const SizedBox.shrink());
    final now = DateTime.now();
    const id = 'aaaaaaaa-0000-4000-8000-00000000f0e1';
    final waiting = IncomingInvoice(
      slateId: id,
      senderAddress: 'esA',
      label: 'Anna',
      amount: 8000000,
      fee: 1000000,
      receivedAt: now,
      expiresAt: now.add(const Duration(hours: 5)),
      state: PayState.waiting,
    );
    _mock.proto.toPay.add(waiting);
    _c.invalidate(deskInvoicesProvider);
    await _real(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _c,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: InvoiceReviewScreen(arg: id))),
      ),
    );
    await _real(tester);
    await tester.tap(find.text(_l.invoiceApprove).last);
    await _real(tester);
    expect(find.text(_l.deskInvPayerPay), findsOneWidget);

    _mock.proto.toPay
      ..remove(waiting)
      ..add(waiting.copyWith(state: PayState.withdrawn));
    await tester.runAsync(() => _c.read(deskInvoicesProvider.notifier).load());
    await _real(tester);
    expect(find.text(_l.deskInvNoticeWithdrawn('Anna')), findsWidgets);
    expect(find.text(_l.deskInvPayerPay), findsNothing);
    expect(find.text(_l.deskInvPayerClose), findsOneWidget);
  });
}
