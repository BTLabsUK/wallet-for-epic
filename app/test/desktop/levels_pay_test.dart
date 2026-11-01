// SPDX-License-Identifier: Apache-2.0
// Wallet levels on Overview, Activity and the payment detail: Shallow's hero is one number and
// one sentence with no tiles, the chips and the actions follow the level, and the payment's steps
// read in the level's words. The Deep end stays today's screens.
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/pay_steps.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/levels/level_features.dart' show TimelineStyle;
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _epic = 100000000;

/// Alice has not signed a send of 25; Bob's 12.5 is on its way in.
final _sendToAlice = Tx(
  id: 1,
  slateId: 'a1f9e8d7',
  direction: TxDirection.sent,
  state: TxState.waitingRecipient,
  method: TxMethod.epicbox,
  amount: 25 * _epic,
  fee: 800000,
  created: DateTime(2026, 10, 21, 11, 30),
  counterparty: 'esAliceAddress@epicbox.example.org',
  contactName: 'Alice',
  cancellable: true,
);
final _fromBob = Tx(
  id: 2,
  slateId: 'b2c3d4e5',
  direction: TxDirection.received,
  state: TxState.waitingRecipient,
  method: TxMethod.epicbox,
  amount: 125 * _epic ~/ 10,
  fee: 0,
  created: DateTime(2026, 10, 21, 9, 2),
  counterparty: 'esBobAddress@epicbox.example.org',
  contactName: 'Bob',
);
final _fileSend = Tx(
  id: 3,
  slateId: 'c3d4e5f6',
  direction: TxDirection.sent,
  state: TxState.waitingRecipient,
  method: TxMethod.file,
  amount: 5 * _epic,
  fee: 800000,
  created: DateTime(2026, 10, 21, 8, 0),
  counterparty: 'pay.tx',
  cancellable: true,
);

class _Wallet extends MockDeskWallet {
  _Wallet(this.list) : super(delay: Duration.zero);

  final List<Tx> list;

  @override
  Future<Balance> balance() async => list.isEmpty
      ? const Balance(spendable: 0, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0)
      : const Balance(spendable: 128152610000, awaitingConfirmation: 5000000000, locked: 1891900000, awaitingFinalization: 0);

  @override
  Future<List<Tx>> transactions() async => list;
}

Future<void> _pump(WidgetTester tester, Widget screen, WalletLevel level, List<Tx> txs) async {
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet(txs)), deskLevelProvider.overrideWithValue(level)]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Shallow Overview: one number, one sentence, no tiles, no eye; the payment card has live steps', (tester) async {
    await _pump(tester, const OverviewScreen(), WalletLevel.justSendReceive, [_sendToAlice, _fromBob]);
    expect(find.text('Available to spend'), findsOneWidget);
    expect(find.text('+12.5000 arriving from Bob'), findsOneWidget);
    expect(find.text('25.0000 on hold until Alice signs'), findsOneWidget);
    for (final tile in ['Total', 'Locked in sends', 'Set aside for sends']) {
      expect(find.text(tile), findsNothing, reason: tile);
    }
    expect(find.byTooltip('Hide amounts'), findsNothing);
    expect(find.text('On its way to Alice'), findsOneWidget);
    expect(find.text('Alice signed'), findsOneWidget);
    expect(find.text('Waiting for Alice’s wallet'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.textContaining('closed'), findsNothing, reason: 'never "receives while closed"');
  });

  testWidgets('Shallow Overview of a wallet with no payments: ready notice with Show address, "Nothing arriving yet."', (tester) async {
    await _pump(tester, const OverviewScreen(), WalletLevel.justSendReceive, const []);
    expect(find.text('Your wallet is ready.'), findsOneWidget);
    expect(find.text('Share the address to get the first EPIC.'), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Show address'), findsOneWidget);
    expect(find.text('Nothing arriving yet.'), findsOneWidget);
    expect(find.text('No payments yet'), findsOneWidget);
  });

  testWidgets('Deeper Overview: the tiles in casual words; the Deep end keeps today\'s', (tester) async {
    await _pump(tester, const OverviewScreen(), WalletLevel.casual, [_sendToAlice]);
    expect(find.text('Still confirming'), findsOneWidget);
    expect(find.text('Set aside for sends'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('On its way to Alice'), findsOneWidget);
    expect(find.text('Waiting for Alice’s wallet'), findsOneWidget);
  });

  testWidgets('Deep end Overview: today\'s tiles and words, the card in technical words', (tester) async {
    await _pump(tester, const OverviewScreen(), WalletLevel.everything, [_sendToAlice]);
    // The balance tile and the payment card's Confirming step (the phone's five steps, A-03).
    expect(find.text('Confirming'), findsWidgets);
    expect(find.text('Locked in sends'), findsOneWidget);
    expect(find.text('Still confirming'), findsNothing);
    expect(find.text('Sending to Alice'), findsOneWidget);
    expect(find.text('Recipient signed'), findsOneWidget);
    expect(find.text('Posted to the network'), findsOneWidget);
    // No slate jargon on a screen (#06): what it waits for, the relay's host on hover.
    expect(find.textContaining('S1'), findsNothing);
    expect(find.text('Waiting for Alice’s wallet'), findsOneWidget);
    expect(find.byTooltip('epicbox.example.org'), findsOneWidget);
  });

  testWidgets('Activity chips: All, Sent, Received at Shallow; Pending and Cancelled from Deeper', (tester) async {
    await _pump(tester, const ActivityScreen(), WalletLevel.justSendReceive, [_sendToAlice, _fromBob]);
    expect(find.textContaining('Received'), findsWidgets);
    expect(find.textContaining('Pending'), findsNothing);
    expect(find.textContaining('Cancelled'), findsNothing);
    // Plain state words, no method, fee or id.
    expect(find.text('Waiting for Alice'), findsOneWidget);
    expect(find.text('Arriving'), findsOneWidget);
    expect(find.textContaining('Epicbox'), findsNothing);
    expect(find.textContaining('Fee'), findsNothing);

    await _pump(tester, const ActivityScreen(), WalletLevel.casual, [_sendToAlice, _fromBob]);
    expect(find.textContaining('Pending'), findsWidgets);
    expect(find.textContaining('Cancelled'), findsWidgets);
    expect(find.text('Waiting for Alice to sign'), findsOneWidget);
  });

  testWidgets('Payment detail: Cancel is the one action at Shallow; Finalize is there from Deeper', (tester) async {
    final l = englishStrings;
    await _pump(tester, SingleChildScrollView(child: TxDetail(tx: _fileSend)), WalletLevel.justSendReceive, [_fileSend]);
    expect(find.text(l.deskTxCancelOutgoingAction), findsOneWidget);
    expect(find.text(l.deskTxFinalize), findsNothing);
    expect(find.text(l.deskTxFactMethod), findsNothing, reason: 'no method at Shallow');
    expect(find.text(l.deskTxFactFee), findsNothing, reason: 'no fee at Shallow');
    expect(find.text(l.deskTxMore), findsNothing, reason: 'no technical rows at Shallow');

    await _pump(tester, SingleChildScrollView(child: TxDetail(tx: _fileSend)), WalletLevel.casual, [_fileSend]);
    expect(find.text(l.deskTxCancelOutgoingAction), findsOneWidget);
    expect(find.text(l.deskTxFinalize), findsOneWidget);
    expect(find.text(l.deskTxFactMethod), findsOneWidget);
  });

  group('the steps of a payment', () {
    final l = englishStrings;
    List<String> words(Tx t, TimelineStyle style, {String? name = 'Alice'}) => [for (final s in payStepList(l, t, style, name: name)) s.title];

    test('a send: the five steps of the phone at every level (A-03)', () {
      final five = ['Payment started', 'Alice signed', 'Posted to the network', 'Confirming', 'Completed'];
      expect(words(_sendToAlice, TimelineStyle.liveSentence), five);
      expect(words(_sendToAlice, TimelineStyle.casualSteps), five);
      expect(words(_sendToAlice, TimelineStyle.technicalSteps), ['Payment started', 'Recipient signed', 'Posted to the network', 'Confirming', 'Completed']);
      // No slate jargon: an Epicbox send waits "On Epicbox", the relay's host on hover (#06).
      final anon = payStepList(l, _sendToAlice, TimelineStyle.technicalSteps);
      expect(anon[1].sub, 'On Epicbox');
      for (final s in anon) {
        expect('${s.title} ${s.sub ?? ''}', isNot(contains('S1')));
      }
    });

    test('a receive: arrived, sender finished, posted, confirming, done', () {
      expect(words(_fromBob, TimelineStyle.liveSentence, name: 'Bob'), ['Payment arrived', 'Signed and returned', 'Posted to the network', 'Confirming', 'Completed']);
      final s = payStepList(l, _fromBob, TimelineStyle.liveSentence, name: 'Bob');
      expect([for (final x in s) x.state], [PayStepState.done, PayStepState.now, PayStepState.todo, PayStepState.todo, PayStepState.todo]);
      expect(s[1].sub, l.deskTxStatusWaitingSender);
    });

    test('the current step and its sub-line follow the data', () {
      final s = payStepList(l, _sendToAlice, TimelineStyle.liveSentence, name: 'Alice');
      expect([for (final x in s) x.state], [PayStepState.done, PayStepState.now, PayStepState.todo, PayStepState.todo, PayStepState.todo]);
      expect(s[1].sub, 'Waiting for Alice’s wallet');
      // No name: where it waits, never a name invented.
      expect(payStepList(l, _sendToAlice, TimelineStyle.liveSentence)[1].sub, 'On Epicbox');
      // A file send waits for a response file.
      expect(payStepList(l, _fileSend, TimelineStyle.casualSteps)[1].sub, l.deskTxStepWaitingFile);
      // Confirming: the count shows on the current step.
      final confirming = Tx(
        id: 4,
        slateId: 'd4',
        direction: TxDirection.sent,
        state: TxState.confirming,
        method: TxMethod.epicbox,
        amount: 1,
        fee: 0,
        created: DateTime(2026),
        confirmations: 2,
      );
      final c = payStepList(l, confirming, TimelineStyle.casualSteps, name: 'Alice');
      // "2 of 6" in no-break spaces: it never splits across lines (#12).
      expect(c[3].title, 'Confirming 2\u00a0of\u00a0${confirming.confirmationsNeeded}');
      expect(payStepList(l, confirming, TimelineStyle.technicalSteps)[3].title, 'Confirming 2/${confirming.confirmationsNeeded}');
      expect([for (final x in c) x.state], [PayStepState.done, PayStepState.done, PayStepState.done, PayStepState.now, PayStepState.todo]);
    });

    test('only ordinary payments have steps', () {
      expect(payHasSteps(_sendToAlice), isTrue);
      expect(payHasSteps(Tx(id: 9, slateId: '', direction: TxDirection.received, state: TxState.confirming, method: TxMethod.epicbox, amount: 1, fee: 0, created: DateTime(2026), coinbase: true)), isFalse);
      expect(payHasSteps(Tx(id: 9, slateId: 'x', direction: TxDirection.sent, state: TxState.cancelled, method: TxMethod.epicbox, amount: 1, fee: 0, created: DateTime(2026))), isFalse);
    });
  });
}
