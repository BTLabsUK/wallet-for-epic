// SPDX-License-Identifier: Apache-2.0
// Home, Activity and the payment detail: the balance parts in plain words, the in-flight card's
// live steps, every Activity chip, the payment's actions, and the payment's five steps.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/pay_steps.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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

Future<void> _pump(WidgetTester tester, Widget screen, List<Tx> txs) async {
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet(txs))]);
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
  testWidgets('Home: the balance parts in plain words, the payment card with live steps', (tester) async {
    await _pump(tester, const OverviewScreen(), [_sendToAlice]);
    expect(find.text(_l.deskOvBalance), findsOneWidget);
    expect(find.text(_l.deskPayTileConfirming), findsOneWidget);
    expect(find.text(_l.deskPayTileLocked), findsOneWidget);
    expect(find.text(_l.deskOvBreakTotal), findsOneWidget);
    expect(find.text('On its way to Alice'), findsOneWidget);
    expect(find.text('Alice signed'), findsOneWidget);
    expect(find.text('Posted to the network'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    // No slate jargon on a screen (#06): what it waits for, the relay's host on hover.
    expect(find.textContaining('S1'), findsNothing);
    expect(find.text('Waiting for Alice’s wallet'), findsOneWidget);
    expect(find.byTooltip('epicbox.example.org'), findsOneWidget);
    expect(find.textContaining('closed'), findsNothing, reason: 'never "receives while closed"');
  });

  testWidgets('Home of a wallet with no payments: the empty state with Show address', (tester) async {
    await _pump(tester, const OverviewScreen(), const []);
    expect(find.widgetWithText(EButton, _l.deskOvShowAddress), findsOneWidget);
    expect(find.text(_l.deskOvEmptyTitle), findsOneWidget);
  });

  testWidgets('Activity: every chip, and the rows in plain state words', (tester) async {
    await _pump(tester, const ActivityScreen(), [_sendToAlice, _fromBob]);
    expect(find.textContaining(_l.deskActFilterReceived), findsWidgets);
    expect(find.textContaining(_l.historyFilterPending), findsWidgets);
    expect(find.textContaining(_l.historyFilterCancelled), findsWidgets);
    expect(find.text('Waiting for Alice to sign'), findsOneWidget);
  });

  testWidgets('Payment detail: Cancel and Finalize, the method and fee rows', (tester) async {
    final l = englishStrings;
    await _pump(tester, SingleChildScrollView(child: TxDetail(tx: _fileSend)), [_fileSend]);
    expect(find.text(l.deskTxCancelOutgoingAction), findsOneWidget);
    expect(find.text(l.deskTxFinalize), findsOneWidget);
    expect(find.text(l.deskTxFactMethod), findsOneWidget);
    expect(find.text(l.deskTxFactFee), findsOneWidget);
  });

  group('the steps of a payment', () {
    final l = englishStrings;
    List<String> words(Tx t, {String? name = 'Alice'}) => [for (final s in payStepList(l, t, name: name)) s.title];

    test('a send: the five steps of the phone (A-03)', () {
      expect(words(_sendToAlice), ['Payment started', 'Alice signed', 'Posted to the network', 'Confirming', 'Completed']);
      expect(words(_sendToAlice, name: null), ['Payment started', 'Recipient signed', 'Posted to the network', 'Confirming', 'Completed']);
      // No slate jargon: an Epicbox send waits "On Epicbox", the relay's host on hover (#06).
      final anon = payStepList(l, _sendToAlice);
      expect(anon[1].sub, 'On Epicbox');
      for (final s in anon) {
        expect('${s.title} ${s.sub ?? ''}', isNot(contains('S1')));
      }
    });

    test('a receive: arrived, sender finished, posted, confirming, done', () {
      expect(words(_fromBob, name: 'Bob'), ['Payment arrived', 'Signed and returned', 'Posted to the network', 'Confirming', 'Completed']);
      final s = payStepList(l, _fromBob, name: 'Bob');
      expect([for (final x in s) x.state], [PayStepState.done, PayStepState.now, PayStepState.todo, PayStepState.todo, PayStepState.todo]);
      expect(s[1].sub, l.deskTxStatusWaitingSender);
    });

    test('the current step and its sub-line follow the data', () {
      final s = payStepList(l, _sendToAlice, name: 'Alice');
      expect([for (final x in s) x.state], [PayStepState.done, PayStepState.now, PayStepState.todo, PayStepState.todo, PayStepState.todo]);
      expect(s[1].sub, 'Waiting for Alice’s wallet');
      // No name: where it waits, never a name invented.
      expect(payStepList(l, _sendToAlice)[1].sub, 'On Epicbox');
      // A file send waits for a response file.
      expect(payStepList(l, _fileSend)[1].sub, l.deskTxStepWaitingFile);
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
      final c = payStepList(l, confirming, name: 'Alice');
      // "2 of 6" in no-break spaces: it never splits across lines (#12).
      expect(c[3].title, 'Confirming 2 of ${confirming.confirmationsNeeded}');
      expect([for (final x in c) x.state], [PayStepState.done, PayStepState.done, PayStepState.done, PayStepState.now, PayStepState.todo]);
    });

    test('only ordinary payments have steps', () {
      expect(payHasSteps(_sendToAlice), isTrue);
      expect(payHasSteps(Tx(id: 9, slateId: '', direction: TxDirection.received, state: TxState.confirming, method: TxMethod.epicbox, amount: 1, fee: 0, created: DateTime(2026), coinbase: true)), isFalse);
      expect(payHasSteps(Tx(id: 9, slateId: 'x', direction: TxDirection.sent, state: TxState.cancelled, method: TxMethod.epicbox, amount: 1, fee: 0, created: DateTime(2026))), isFalse);
    });
  });
}
