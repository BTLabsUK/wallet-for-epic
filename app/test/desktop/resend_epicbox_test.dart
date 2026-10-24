// An undelivered Epicbox, HTTP or Tor send on the desktop: the row says Not delivered and offers
// Send again beside Cancel; the send being made right now is not offered; unlock sends each
// Epicbox one again once; Send again goes to the stored URL or onion.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/desk_l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

class _Desk extends MockDeskWallet {
  _Desk() : super(delay: Duration.zero);

  final List<int> resent = [];
  final List<int> reposted = [];

  @override
  Future<void> resendTx(int id) async => resent.add(id);

  @override
  Future<void> repostTx(int id) async => reposted.add(id);
}

Tx _tx({bool undelivered = false, TxMethod method = TxMethod.epicbox, bool notPosted = false}) => Tx(
  id: 77,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  direction: TxDirection.sent,
  state: notPosted ? TxState.posted : TxState.waitingRecipient,
  notPosted: notPosted,
  method: method,
  amount: 250000000,
  fee: 7000000,
  created: DateTime(2026, 10, 20),
  counterparty: method == TxMethod.http ? 'http://10.90.15.122:3415/v2/foreign' : 'esAlice@epicbox.example',
  cancellable: true,
  undelivered: undelivered,
);

Future<void> _pump(WidgetTester tester, Tx tx, _Desk desk) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(desk)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TxDetail(tx: tx),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'an undelivered send says so and offers Send again beside Cancel',
    (tester) async {
      final desk = _Desk();
      await _pump(tester, _tx(undelivered: true), desk);
      expect(statusOf(englishStrings, _tx(undelivered: true)).$1, 'Not delivered');
      expect(find.textContaining('Not delivered.'), findsOneWidget);
      // linux-14: the relay that did not answer is named.
      expect(find.textContaining('epicbox.example did not answer'), findsOneWidget);
      expect(find.widgetWithText(EButton, 'Cancel'), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, 'Send again'));
      await tester.pump();
      expect(desk.resent, [77]);
      // The toast's timer ends with the tree.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    'a Link HTTP send that was not delivered says so and offers Send again (linux-13)',
    (tester) async {
      final desk = _Desk();
      final tx = _tx(undelivered: true, method: TxMethod.http);
      await _pump(tester, tx, desk);
      expect(statusOf(englishStrings, tx).$1, 'Not delivered');
      expect(find.textContaining('Not delivered.'), findsOneWidget);
      // Its words fit the method (windows-07): no epicbox for an HTTP send.
      expect(find.textContaining('(Link Payment · HTTP)'), findsOneWidget);
      expect(find.textContaining('did not reach the epicbox'), findsNothing);
      await tester.tap(find.widgetWithText(EButton, 'Send again'));
      await tester.pump();
      expect(desk.resent, [77]);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets('a Tor send that was not delivered names Tor', (tester) async {
    await _pump(tester, _tx(undelivered: true, method: TxMethod.tor), _Desk());
    expect(find.textContaining('(Link Payment · Tor)'), findsOneWidget);
    expect(find.textContaining('did not reach the epicbox'), findsNothing);
  });

  testWidgets(
    'a send the node refused says it is not on the network and offers Broadcast again at once (android-17)',
    (tester) async {
      final desk = _Desk();
      final tx = _tx(notPosted: true);
      await _pump(tester, tx, desk);
      expect(statusOf(englishStrings, tx).$1, 'Not on the network');
      expect(find.textContaining('Not on the network.'), findsOneWidget);
      expect(find.textContaining('waiting for a block'), findsNothing);
      await tester.tap(find.widgetWithText(EButton, 'Broadcast again'));
      await tester.pump();
      expect(desk.reposted, [77]);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    'a send that is not undelivered (the one being sent now) has no Send again',
    (tester) async {
      await _pump(tester, _tx(), _Desk());
      expect(statusOf(englishStrings, _tx()).$1, 'Waiting for recipient to sign');
      expect(find.widgetWithText(EButton, 'Send again'), findsNothing);
      expect(find.widgetWithText(EButton, 'Cancel'), findsOneWidget);
    },
  );

  test('unlock sends each undelivered epicbox send again, once', () async {
    final dir = Directory.systemTemp.createTempSync('resend');
    addTearDown(() => dir.deleteSync(recursive: true));
    final secrets = MemorySecretStore();
    final session = core.FakeWalletSession(
      transactions: [
        core.fakeTx(
          id: 4,
          slateId: 'a',
          kind: core.TxKind.sent,
          status: core.TxStatus.awaitingRecipient,
          transport: 'epicbox',
          undelivered: true,
        ),
        core.fakeTx(
          id: 5,
          slateId: 'b',
          kind: core.TxKind.sent,
          status: core.TxStatus.awaitingRecipient,
          transport: 'epicbox',
        ),
        // Its recipient may be offline: it waits for the user's Send again.
        core.fakeTx(
          id: 6,
          slateId: 'c',
          kind: core.TxKind.sent,
          status: core.TxStatus.awaitingRecipient,
          transport: 'http',
          counterparty: 'http://10.90.15.122:3415/v2/foreign',
          undelivered: true,
        ),
      ],
    );
    final service = core.FakeWalletService(
      password: _password,
      session: session,
    )..existingWallets.add('${dir.path}/wallets/mainnet');
    final wallet = LepicDeskWallet(
      service: service,
      walletDir: (chain) async => '${dir.path}/wallets/${chain.name}',
      secrets: secrets,
      filesDir: () async => dir,
    );
    expect(await wallet.unlock(_password), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(session.resentEpicboxKeys, ['s:a']);
    expect(session.httpSends, isEmpty);
    await wallet.dispose();
  });

  test('Send again on a Link send goes to its stored URL or onion', () async {
    final dir = Directory.systemTemp.createTempSync('resend');
    addTearDown(() => dir.deleteSync(recursive: true));
    const onion = 'fiax36yk6a2bksffszfskxao4pt726tbagetojui5ohv2fc36wfc5sad.onion';
    final session = core.FakeWalletSession(
      transactions: [
        core.fakeTx(
          id: 6,
          slateId: 'c',
          kind: core.TxKind.sent,
          status: core.TxStatus.awaitingRecipient,
          transport: 'http',
          counterparty: 'http://10.90.15.122:3415/v2/foreign',
          undelivered: true,
        ),
        core.fakeTx(
          id: 7,
          slateId: 'd',
          kind: core.TxKind.sent,
          status: core.TxStatus.awaitingRecipient,
          transport: 'tor',
          counterparty: onion,
          undelivered: true,
        ),
      ],
    );
    final service = core.FakeWalletService(
      password: _password,
      session: session,
    )..existingWallets.add('${dir.path}/wallets/mainnet');
    final wallet = LepicDeskWallet(
      service: service,
      walletDir: (chain) async => '${dir.path}/wallets/${chain.name}',
      secrets: MemorySecretStore(),
      filesDir: () async => dir,
    );
    expect(await wallet.unlock(_password), isTrue);
    await wallet.resendTx(6);
    expect(session.httpSends.single, (
      amount: null,
      txId: 6,
      url: 'http://10.90.15.122:3415/v2/foreign',
      allowPlainHttp: true,
    ));
    // Tor is off until it starts: the onion send says so and goes nowhere else.
    await expectLater(wallet.resendTx(7), throwsA(isA<DeskError>()));
    expect(session.torSends, isEmpty);
    expect(session.resentEpicboxKeys, isEmpty);
    expect((await wallet.transactions()).where((t) => t.undelivered).map((t) => t.id), [7]);
    await wallet.dispose();
  });

  group('linux-14: a relay that does not answer is named', () {
    late Directory dir;
    late core.FakeWalletSession session;
    late LepicDeskWallet wallet;
    const relayError = core.WalletError(kind: core.WalletErrorKind.transportFailed, message: 'epicbox post failed: relay sent nothing in time');

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('resend');
      session = core.FakeWalletSession(
        transactions: [
          core.fakeTx(
            id: 4,
            slateId: 'a',
            kind: core.TxKind.sent,
            status: core.TxStatus.awaitingRecipient,
            transport: 'epicbox',
            counterparty: '${'b' * 52}@epicbox.stackwalle',
            undelivered: true,
          ),
        ],
      );
      final service = core.FakeWalletService(password: _password, session: session)..existingWallets.add('${dir.path}/wallets/mainnet');
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async => '${dir.path}/wallets/${chain.name}',
        secrets: MemorySecretStore(),
        filesDir: () async => dir,
      );
      expect(await wallet.unlock(_password), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      session.resentEpicboxKeys.clear();
      await wallet.sync();
      session.summaryValue = core.WalletSummary(
        lastConfirmedHeight: BigInt.from(2500000),
        minimumConfirmations: BigInt.from(3),
        total: BigInt.from(100000000),
        spendable: BigInt.from(100000000),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
    });

    tearDown(() async {
      await wallet.dispose();
      dir.deleteSync(recursive: true);
    });

    test('Send again that fails says which server did not answer', () async {
      session.resendEpicboxError = relayError;
      Object? caught;
      try {
        await wallet.resendTx(4);
      } on Object catch (e) {
        caught = e;
      }
      expect(caught, isA<DeskError>());
      expect(deskErrorText(caught!, englishStrings), 'epicbox.stackwalle did not answer.');
    });

    test('a send that is not delivered says which server did not answer', () async {
      session.sendError = relayError;
      final r = await wallet.send(SendRequest(method: TxMethod.epicbox, amount: 1000, to: '${'c' * 52}@epicbox.stackwalle'));
      expect(r, isA<SendFailed>());
      expect((r as SendFailed).message, startsWith('Not delivered: epicbox.stackwalle did not answer.'));
      expect(r.inActivity, isTrue);
    });
  });
}
