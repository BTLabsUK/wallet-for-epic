// The desktop's Pair page (SPEC 2.1-2.3, desktop): the code with its words, an online invite
// copied with the name they will see, a pasted invite answered, and Pending invites.
import 'package:epic_wallet/src/advanced.dart' show AdvancedPrefs, NetworkMode;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskOwnCardProvider, deskPairingsProvider, deskSeenAsProvider;
import 'package:epic_wallet/src/desktop/data/desk_store.dart' show deskSettingsFromJson, deskSettingsToJson;
import 'package:epic_wallet/src/desktop/data/invoice_state.dart' show deskInvoicesProvider;
import 'package:epic_wallet/src/desktop/data/invoices.dart' show IncomingInvoice, PayState;
import 'package:epic_wallet/src/desktop/screens/invoices/issue_invoice_screen.dart';
import 'package:epic_wallet/src/desktop/screens/invoices/review_screen.dart';
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_invoices.dart' show InvoiceSettingsBlock;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_notices.dart' show pairingEventOnScreen, pairingWordsOnScreen;
import 'package:epic_wallet/src/wallet_service.dart' show PairingEvent, PairingEventKind, PairingState;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    return null;
  });
  _clip = null;
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  _mock = MockDeskWallet(delay: Duration.zero);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_mock)]);
  addTearDown(_c.dispose);
  await tester.runAsync(() => _c.read(deskProvider.notifier).refresh());
  if (mode != null) {
    final n = _c.read(deskProvider.notifier);
    await tester.runAsync(() => n.saveSettings(_c.read(deskProvider).settings.copyWith(advanced: AdvancedPrefs.none.withMode(mode))));
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

  testWidgets('the page: the lead, the code panel, Enter link or words and Invite online', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairLead), findsOneWidget);
    expect(find.text(_l.pairShowMyCode), findsOneWidget);
    expect(find.text(_l.pairEnter), findsOneWidget);
    expect(find.text(_l.pairingInviteOnline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Copy invite makes an invite under the name they will see', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    // The name makes the code (and its words invite) once typing pauses.
    await _real(tester, 1200);
    final before = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingInvite).length;
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    final invites = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingInvite).toList();
    expect(invites.length, before + 1);
  });

  testWidgets('a pasted invite opens the incoming dialog; Pair answers it', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
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

  testWidgets('this wallet\'s own invite pasted: This is your own code, no Pair with … (PAIR-AND-2)', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    final mine = (await tester.runAsync(() => _pairing.makeInvite(name: 'the owner', expiry: const Duration(hours: 24))))!;
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), mine.inviteLink!);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairOwnCode), findsOneWidget);
    expect(find.text(_l.pairIncomingTitle('the owner')), findsNothing);
  });

  testWidgets('the whole shared invite message, its lines run together by the field, opens the invite (PAIR-LNX-1)', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    final link = _pairing.inviteLinkFrom(name: 'Northwind', asksInvoices: true);
    final message = _l.pairShareText('Northwind', link, '26 Oct, 06:11').replaceAll('\n', '');
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), message);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
  });

  testWidgets('a pasted card link pairs face to face: this wallet\'s card to hand back, then the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
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

  testWidgets('They match on a pairing in no contact: the result offers to save it, and Save as a new contact does (PAIR-LNX-4)', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
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

  testWidgets('a re-pair: the result offers the contact of its name first, and Add to starts the key check (PAIR-LNX-7)', (tester) async {
    await _open(tester, const DeskPairScreen());
    final id = (await tester.runAsync(() => _c.read(deskProvider.notifier).saveContact(Contact(id: '', name: 'Ola'))))!;
    _pairing.seedPaired(id: 'old-ola', name: 'Ola', state: PairingState.verified, contactId: id);
    _c.invalidate(deskPairingsProvider);
    await _seenAs(tester, 'the owner');
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

  testWidgets('Copy my card link first: their card then goes straight to the words', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
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

  testWidgets('no name error on a page just opened; it shows once an action needs the name (PAIR-LNX-2)', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairSeenAsMissing), findsNothing);
    expect(find.text(_l.pairNameForCode), findsOneWidget);
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    expect(find.text(_l.pairSeenAsMissing), findsOneWidget);
  });

  testWidgets('the code appears once a name is typed, without opening the page again (PAIR-LNX-6)', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairNameForCode), findsOneWidget);
    await _seenAs(tester, 'the owner');
    await _real(tester, 1200);
    expect(find.text(_l.pairNameForCode), findsNothing);
    expect(find.bySemanticsLabel(_l.pairCodeLabel), findsOneWidget);
  });

  testWidgets('Offline pairs by hand: this wallet\'s card shows and copies, and the invite copies (PAIR-LNX-6)', (tester) async {
    await _open(tester, const DeskPairScreen(), mode: NetworkMode.offline);
    expect(find.text(_l.pairOfflineHint), findsOneWidget);
    await _seenAs(tester, 'the owner');
    await _real(tester, 1200);
    expect(find.bySemanticsLabel(_l.pairCodeLabel), findsOneWidget);
    expect(_c.read(deskOwnCardProvider)?.link, startsWith('epiccash://contact/'));
    await tester.ensureVisible(find.byKey(deskPairCopyCardKey));
    await tester.tap(find.byKey(deskPairCopyCardKey));
    await _real(tester);
    expect(_clip, startsWith('epiccash://contact/'));
    expect(find.text(_l.pairingInviteOnline), findsOneWidget);
    expect(find.text(_l.pairOnlineLeadByHand), findsOneWidget);
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
    await tester.tap(inRow(find.widgetWithText(EButton, _l.sasTitle)));
    await _real(tester);
    expect(find.text(_l.sasMatch), findsOneWidget);
  });

  testWidgets('Pending invites lists what waits, with Cancel', (tester) async {
    await _open(tester, const DeskPendingScreen());
    // The mock's pairings live on its own date; this one is made now, as the screen counts.
    _pairing.clock = DateTime.now;
    await tester.runAsync(() => _pairing.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Ola'));
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text('Ola'), findsOneWidget);
    expect(find.text(_l.pendingCopyLink), findsWidgets);
  });

  testWidgets('Pending invites: an answer waiting for a confirm can be removed; an unnamed invite has a glyph (PAIR-LNX-8)', (tester) async {
    await _open(tester, const DeskPendingScreen());
    _pairing.clock = DateTime.now;
    await tester.runAsync(() async {
      final preview = await _pairing.openInvite(_pairing.inviteLinkFrom(name: 'Anna'));
      await _pairing.acceptInvite(token: preview.token, name: 'the owner');
      await _pairing.makeInvite(name: 'the owner', expiry: const Duration(minutes: 10), words: true);
    });
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.byIcon(EIcons.words), findsOneWidget);
    expect(find.text('·'), findsNothing);
    await tester.tap(find.byKey(deskPendingRemoveKey));
    await _real(tester);
    expect((await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply && r.name == 'Anna'), isEmpty);
  });

  testWidgets('Review request: a fee with no estimate shows as unknown, never 0 (PAIR-LNX-5)', (tester) async {
    await _open(tester, const SizedBox.shrink());
    final now = DateTime.now();
    _mock.proto.toPay.add(
      IncomingInvoice(
        slateId: 'aaaaaaaa-0000-4000-8000-00000000f0e0',
        senderAddress: 'esA',
        label: 'Floo C',
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('New request on a core without request files names contacts only (PAIR-LNX-5)', (tester) async {
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

  testWidgets('a contact row with no address: no Unknown tag (PAIR-LNX-5)', (tester) async {
    await _open(tester, const SizedBox(width: 400, child: EAddressLines(name: 'Floo C', address: '', note: 'met at the meetup')));
    expect(find.text('Floo C'), findsOneWidget);
    expect(find.text(_l.deskKitUnknown), findsNothing);
    expect(find.text('met at the meetup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a contact row with several addresses shows their kind tags, not one address (PAIR-WIN-2)', (tester) async {
    const box = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';
    const tor = 'http://wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
    await _open(
      tester,
      const SizedBox(width: 360, child: EAddressLines(name: 'Floo C', address: box, addresses: [box, 'http://10.0.0.2:3415', tor], note: 'shop')),
    );
    expect(find.byType(EKindTag), findsNWidgets(3));
    expect(find.byType(EShortAddress), findsNothing);
    expect(find.text(' · shop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the name others see is kept in the settings', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    expect(_c.read(deskProvider).settings.pairingSeenAs, 'the owner');
    expect(_c.read(deskSeenAsProvider), 'the owner');
  });

  test('the settings file keeps the name, and an old file reads without it', () {
    final kept = deskSettingsFromJson(deskSettingsToJson(const DeskSettings(pairingSeenAs: 'the owner')));
    expect(kept.pairingSeenAs, 'the owner');
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
}
