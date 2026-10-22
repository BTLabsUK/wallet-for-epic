// Cancelling an incoming, unconfirmed payment on the desktop (decision D5): the button follows the
// core's `cancellable` flag, the dialog speaks of a payment, and a refusal (the node already has
// it) is a toast that leaves the row. The send cancel keeps its words.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

/// Records cancels; refuses them as the core does for a payment the node has.
class _Desk extends MockDeskWallet {
  _Desk({this.refuse = false}) : super(delay: Duration.zero);

  final bool refuse;
  final List<int> cancelled = [];

  @override
  Future<void> cancelTx(int id) async {
    cancelled.add(id);
    if (refuse) throw const DeskError(cancelRefusedText);
    return super.cancelTx(id);
  }
}

Tx _tx({required bool incoming, TxState state = TxState.posted, bool cancellable = true, bool fromBackup = false, TxMethod method = TxMethod.epicbox, bool notPosted = false}) => Tx(
  id: 77,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  direction: incoming ? TxDirection.received : TxDirection.sent,
  state: state,
  method: method,
  amount: 250000000,
  fee: incoming ? 0 : 7000000,
  created: DateTime(2026, 10, 20),
  counterparty: 'esAlice@epicbox.example',
  cancellable: cancellable,
  fromBackup: fromBackup,
  notPosted: notPosted,
);

Future<void> _pump(WidgetTester tester, Tx tx, _Desk desk) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(desk)]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: TxDetail(tx: tx))),
      ),
    ),
  );
  // A confirming row animates for ever, so no pumpAndSettle here.
  await tester.pump(const Duration(milliseconds: 400));
}

Finder get _cancelButton => find.widgetWithText(EButton, 'Cancel');

void main() {
  group('the Cancel button', () {
    testWidgets('is offered for an incoming payment the core can cancel', (tester) async {
      await _pump(tester, _tx(incoming: true), _Desk());
      expect(_cancelButton, findsOneWidget);
    });

    testWidgets('is hidden for a confirmed or non-cancellable incoming payment', (tester) async {
      await _pump(tester, _tx(incoming: true, state: TxState.confirmed), _Desk());
      expect(_cancelButton, findsNothing);
      await _pump(tester, _tx(incoming: true, cancellable: false), _Desk());
      expect(_cancelButton, findsNothing);
      await _pump(tester, _tx(incoming: true, fromBackup: true), _Desk());
      expect(_cancelButton, findsNothing);
      await _pump(tester, _tx(incoming: true, state: TxState.cancelled), _Desk());
      expect(_cancelButton, findsNothing);
    });

    testWidgets('a send only while it waits for the recipient', (tester) async {
      await _pump(tester, _tx(incoming: false, state: TxState.waitingRecipient), _Desk());
      expect(_cancelButton, findsOneWidget);
      await _pump(tester, _tx(incoming: false, state: TxState.waitingRecipient, cancellable: false), _Desk());
      expect(_cancelButton, findsNothing, reason: 'the core says no');
      await _pump(tester, _tx(incoming: false, state: TxState.confirming), _Desk());
      expect(_cancelButton, findsNothing);
    });

    // A Direct send (HTTP or Tor) is finalized and posted in one step: once out, it is a sent
    // payment like any other, never cancelled in the wallet while the recipient has the coins.
    testWidgets('a send the node refused stays cancellable', (tester) async {
      await _pump(tester, _tx(incoming: false, method: TxMethod.tor, cancellable: false, notPosted: true), _Desk());
      expect(_cancelButton, findsOneWidget, reason: 'its outputs stay locked otherwise');
    });

    for (final method in [TxMethod.http, TxMethod.tor, TxMethod.epicbox]) {
      testWidgets('a posted ${method.name} send has no Cancel', (tester) async {
        await _pump(tester, _tx(incoming: false, method: method), _Desk());
        expect(_cancelButton, findsNothing);
        await _pump(tester, _tx(incoming: false, method: method, cancellable: false), _Desk());
        expect(_cancelButton, findsNothing);
      });
    }
  });

  group('the dialog', () {
    testWidgets('for an incoming payment speaks of the payment and the node check', (tester) async {
      final desk = _Desk();
      await _pump(tester, _tx(incoming: true), desk);
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      expect(find.text('Cancel this payment?'), findsOneWidget);
      expect(find.textContaining('leaves your balance'), findsOneWidget);
      expect(find.textContaining('asks the node first'), findsOneWidget);
      expect(find.textContaining('pool or a block'), findsOneWidget);
      expect(find.textContaining('may still arrive'), findsOneWidget);
      expect(find.textContaining('locked amount'), findsNothing);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(desk.cancelled, isEmpty);
    });

    testWidgets('for a send is unchanged', (tester) async {
      final desk = _Desk();
      await _pump(tester, _tx(incoming: false, state: TxState.waitingRecipient), desk);
      await tester.tap(_cancelButton);
      // A waiting send's step animates for ever: pump the dialog in, no settle.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Cancel this send?'), findsOneWidget);
      expect(find.textContaining('The locked amount returns to the balance'), findsOneWidget);
      expect(find.text('Cancel send'), findsOneWidget);
    });
  });

  group('the result', () {
    testWidgets('a refusal shows the toast and leaves the row', (tester) async {
      final desk = _Desk(refuse: true);
      await _pump(tester, _tx(incoming: true), desk);
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel payment'));
      await tester.pumpAndSettle();
      expect(desk.cancelled, [77]);
      expect(find.text('Not cancelled'), findsOneWidget);
      expect(find.text(cancelRefusedText), findsOneWidget);
      expect(find.text('Transaction cancelled'), findsNothing);
      expect(_cancelButton, findsOneWidget, reason: 'the payment is still there to try again');
    });

    testWidgets('a cancel that goes through says so', (tester) async {
      final desk = _Desk();
      await _pump(tester, _tx(incoming: true), desk);
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel payment'));
      await tester.pumpAndSettle();
      expect(desk.cancelled, [77]);
      expect(find.text('Transaction cancelled'), findsOneWidget);
    });
  });

  group('deskTx', () {
    core.TxEntry entry({bool cancellable = true, core.TxFlow flow = core.TxFlow.payment}) =>
        core.fakeTx(id: 7, slateId: 'a1', kind: core.TxKind.received, cancellable: cancellable, flow: flow);

    test('carries the core flag; an issued invoice request is not offered', () {
      expect(deskTx(entry(), tip: 10, minConf: 3, fallbackId: -1).cancellable, isTrue);
      expect(deskTx(entry(cancellable: false), tip: 10, minConf: 3, fallbackId: -1).cancellable, isFalse);
      expect(deskTx(entry(flow: core.TxFlow.invoice), tip: 10, minConf: 3, fallbackId: -1).cancellable, isFalse);
    });
  });

  group('LepicDeskWallet.cancelTx', () {
    late Directory dir;
    late _Session session;
    late LepicDeskWallet wallet;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('desk-cancel-test-');
      session = _Session();
      wallet = LepicDeskWallet(
        service: core.FakeWalletService(password: _password, session: session),
        walletDir: (_) async => (await Directory('${dir.path}/w').create(recursive: true)).path,
        secrets: MemorySecretStore(),
        filesDir: () async => dir,
        nodePoll: const Duration(hours: 1),
      );
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await wallet.sync();
    });

    tearDown(() async {
      await wallet.dispose();
      await dir.delete(recursive: true);
    });

    test('a payment in the node pool is refused with the toast text and stays', () async {
      session.refuse = true;
      await expectLater(
        wallet.cancelTx(7),
        throwsA(isA<DeskError>().having((e) => e.message, 'message', cancelRefusedText)),
      );
      expect(session.cancelCalls, [7]);
      final rows = await wallet.transactions();
      expect(rows.single.state, isNot(TxState.cancelled));
      expect(rows.single.cancellable, isTrue);
    });

    test('a payment the node has not seen is cancelled and the list reloads', () async {
      await wallet.cancelTx(7);
      expect(session.cancelCalls, [7]);
      expect((await wallet.transactions()).single.state, TxState.cancelled);
    });
  });
}

/// One incoming payment; the core refuses its cancel when [refuse] is set, as LEPIC does for a
/// payment in the node's pool.
class _Session extends core.FakeWalletSession {
  _Session() {
    transactionsValue = [core.fakeTx(id: 7, slateId: 'a1', kind: core.TxKind.received, cancellable: true)];
  }

  bool refuse = false;
  final List<int> cancelCalls = [];

  @override
  Future<void> cancelTransaction({required int txId}) async {
    cancelCalls.add(txId);
    if (refuse) throw const core.WalletError(kind: core.WalletErrorKind.invalidArgument, message: 'the node has this payment in its pool');
    transactionsValue = [core.fakeTx(id: txId, slateId: 'a1', kind: core.TxKind.receivedCancelled, status: core.TxStatus.cancelled)];
  }
}
