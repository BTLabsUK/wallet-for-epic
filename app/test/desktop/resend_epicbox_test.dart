// An undelivered Epicbox send on the desktop: the row says Not delivered and offers Send again
// beside Cancel; the send being made right now is not offered; unlock sends each one again once.
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

  @override
  Future<void> resendEpicbox(int id) async => resent.add(id);
}

Tx _tx({bool undelivered = false}) => Tx(
  id: 77,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  direction: TxDirection.sent,
  state: TxState.waitingRecipient,
  method: TxMethod.epicbox,
  amount: 250000000,
  fee: 7000000,
  created: DateTime(2026, 10, 20),
  counterparty: 'esAlice@epicbox.example',
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
    await wallet.dispose();
  });
}
