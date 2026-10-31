// SPDX-License-Identifier: Apache-2.0
// Level-aware payment screens: step derivation, level 1 Send (no method strip, QR Payment as a
// quiet link) and level 1 Receive (New today badge after an Epicbox server move).
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/level_providers.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/levels/payment_steps.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart' show TimelineState;
import 'package:epic_wallet/src/levels/level_features.dart' show TimelineStyle;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

BigInt _epic(num n) => BigInt.from((n * 100000000).round());

const _address = 'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@box.epic.invalid';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Moved extends RelaySwitchResultNotifier {
  @override
  RelaySwitchResult? build() => const RelaySwitchResult(
    from: EpicboxRelay(host: 'old.example'),
    relay: EpicboxRelay(host: 'new.example'),
    name: 'Stack Wallet',
    address: _address,
  );
}

Future<void> _pump(WidgetTester tester, Widget screen, {bool moved = false}) async {
  tester.view.physicalSize = const Size(1080, 3300);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(2499990),
      minimumConfirmations: BigInt.from(3),
      total: _epic(50),
      spendable: _epic(40),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
  )..address = _address;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        currentLevelProvider.overrideWithValue(WalletLevel.justSendReceive),
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        if (moved) relaySwitchResultProvider.overrideWith(_Moved.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container
      .read(walletConfigProvider.notifier)
      .select(
        WalletConfig(
          dataDir: '/fake',
          chain: Chain.mainnet,
          nodeUrl: 'https://node.example',
          epicboxDomain: 'box.epic.invalid',
          epicboxPort: 443,
        ),
      );
  await tester.pumpAndSettle();
}

void main() {
  group('step derivation', () {
    late AppLocalizations l;
    setUp(() async {
      await initializeDateFormatting('en');
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    final tip = BigInt.from(1000);
    TxEntry sent(TxStatus status, {BigInt? height, int? finalized}) => fakeTx(
      id: 1,
      slateId: 's',
      kind: TxKind.sent,
      status: status,
      amountDebited: _epic(2),
      blockHeight: height,
      finalizedAtUnix: finalized,
    );

    test('a send waiting for its recipient names them', () {
      final tx = sent(TxStatus.awaitingRecipient);
      expect(paymentStepWord(l, tx, tip, style: TimelineStyle.liveSentence, who: 'Alice'), 'Waiting for Alice');
      final steps = paymentSteps(l, tx, tip, who: 'Alice')!;
      expect(steps.map((s) => s.state), [
        TimelineState.done,
        TimelineState.current,
        TimelineState.todo,
        TimelineState.todo,
        TimelineState.todo,
      ]);
      // The second step reads "Recipient signed" until they have; no invented times.
      expect(steps[1].detail, isNull);
    });

    test('taken by the network but in no block yet is Posted, never Confirming 0 of 3', () {
      final posted = sent(TxStatus.awaitingConfirmation, height: BigInt.from(1001), finalized: 1700000000);
      expect(paymentStepWord(l, posted, tip, style: TimelineStyle.liveSentence, target: 3), 'Posted');
      expect(paymentStepWord(l, posted, tip, style: TimelineStyle.casualSteps, target: 3), 'Posted');
      expect(paymentStepWord(l, posted, tip, style: TimelineStyle.technicalSteps, target: 3), 'Confirming 0/3');
      final steps = paymentSteps(l, posted, tip, target: 3, who: 'Alice')!;
      expect(steps.map((s) => s.label), ['Payment started', 'Alice signed', 'Posted to the network', 'Confirming', 'Completed']);
      expect(steps.map((s) => s.state), [
        TimelineState.done,
        TimelineState.done,
        TimelineState.current,
        TimelineState.todo,
        TimelineState.todo,
      ]);
      expect(steps[2].detail, isNotNull, reason: 'the step under way shows its time');
    });

    test('an address at level 1 is its key alone', () {
      const address = 'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@box.epic.invalid';
      expect(shortAddress(address), 'esVeVU…3es6TA@box.epic.invalid');
      expect(shortAddress(address, relay: false), 'esVeVU…3es6TA');
    });

    test('confirming counts against the target, completed names the way it went', () {
      final confirming = sent(TxStatus.awaitingConfirmation, height: BigInt.from(999), finalized: 1700000000);
      expect(
        paymentStepWord(l, confirming, tip, style: TimelineStyle.liveSentence, target: 3),
        'Confirming 2 of 3',
      );
      final steps = paymentSteps(l, confirming, tip, target: 3, who: 'Alice')!;
      expect(steps[1].label, 'Alice signed');
      expect(steps[3].label, 'Confirming 2 of 3');
      expect(steps[3].state, TimelineState.current);
      expect(steps[2].detail, isNotNull, reason: 'posted time is known from finalizedAtUnix');
      final done = sent(TxStatus.confirmed, height: BigInt.from(900));
      expect(paymentStepWord(l, done, tip, style: TimelineStyle.liveSentence), 'Sent');
      expect(paymentStepWord(l, done, tip, style: TimelineStyle.technicalSteps), 'Sent');
    });

    test('an incoming payment the sender has not finished is Arriving at level 1, today\'s word at level 3', () {
      final tx = fakeTx(
        id: 2,
        slateId: 'r',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        amountCredited: _epic(1),
      );
      expect(paymentStepWord(l, tx, tip, style: TimelineStyle.liveSentence), 'Arriving');
      expect(paymentStepWord(l, tx, tip, style: TimelineStyle.technicalSteps), l.txStatusWaitingSender);
    });
  });

  testWidgets('Send at level 1 has no method strip and offers QR Payment as a quiet link', (tester) async {
    await _pump(tester, SlotScaffold(body: SendView(onDone: () {})));
    expect(find.byKey(sendMethodsKey), findsNothing);
    expect(find.byKey(sendQuietQrKey), findsOneWidget);
    expect(find.text('Both phones here? QR Payment'), findsOneWidget);
    // The step is Send, not a method to pick; no address-shape hint; the link sits under the
    // Paste / Contacts shortcuts.
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Payment method'), findsNothing);
    expect(find.byTooltip('Address kinds'), findsNothing);
    expect(
      tester.getRect(find.byKey(sendQuietQrKey)).top,
      greaterThan(tester.getRect(find.text('Paste')).bottom),
    );
  });

  testWidgets('Receive at level 1 says Connected without the server', (tester) async {
    await _pump(tester, const SlotScaffold(body: ReceiveView()));
    expect(find.byKey(receiveEpicboxKey), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(receiveEpicboxKey), matching: find.textContaining('box.epic.invalid')),
      findsNothing,
    );
  });

  testWidgets('Receive at level 1 shows New today and the server line after a server move', (tester) async {
    await _pump(tester, const SlotScaffold(body: ReceiveView()), moved: true);
    expect(find.byKey(receiveTabsKey), findsNothing);
    expect(find.text('New today'), findsOneWidget);
    expect(find.text('Epicbox server: Stack Wallet.'), findsOneWidget);
    expect(find.text('Anyone with the old address needs the new one.'), findsOneWidget);
  });

  testWidgets('Receive at level 1 without a move has no badge', (tester) async {
    await _pump(tester, const SlotScaffold(body: ReceiveView()));
    expect(find.text('New today'), findsNothing);
  });
}
