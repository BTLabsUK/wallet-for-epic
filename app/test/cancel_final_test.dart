// SPDX-License-Identifier: Apache-2.0
// Cancel made honest and final (WAL-20, 2026-10-30): a payment the other side can no longer
// finish without this wallet is a plain cancel, no fee. One the other side may finish anyway (an
// invoice this wallet paid, a send both wallets signed) is cancelled AND its coins are spent back
// to this wallet in the same action, so the old payment can never complete: no extra step, one
// line in the dialog names the network fee. A spend back that fails is tried again while the
// wallet is open, and the cancelled payment reads "may still finish" until its coins are spent.
import 'package:epic_wallet/src/cancel_final.dart';
import 'package:epic_wallet/src/desktop/data/clock.dart';
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' hide TxFlow;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/cancel_dialog.dart' show cancelForSureKey;
import 'package:epic_wallet/src/ui/common.dart' show DangerButton;
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());
final _l = englishStrings;
final DateTime _now = DateTime(2026, 10, 30, 12);
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
final BigInt _tip = BigInt.from(2500000);

const _coinA = 'aa00000000000000000000000000000000000000000000000000000000000000aa';
const _coinB = 'bb00000000000000000000000000000000000000000000000000000000000000bb';
const _other = 'cc00000000000000000000000000000000000000000000000000000000000000cc';

/// An outgoing payment: an invoice this wallet paid ([TxFlow.invoice]), a send still waiting
/// for its answer, or with [finalized] one both wallets signed that the node did not take.
TxEntry _send({TxFlow flow = TxFlow.payment, bool finalized = false, bool cancelled = false, bool releasable = false, CancelReason? reason}) => fakeTx(
  id: 9,
  slateId: 'pay-1',
  kind: cancelled ? TxKind.sentCancelled : TxKind.sent,
  status: cancelled
      ? TxStatus.cancelled
      : finalized
      ? TxStatus.awaitingConfirmation
      : TxStatus.awaitingRecipient,
  createdAtUnix: _at(_now.subtract(const Duration(days: 2))),
  amountDebited: _epic(3),
  fee: _epic(0.007),
  numInputs: 2,
  counterparty: 'esService@epicbox.epiccash.com',
  transport: 'epicbox',
  cancellable: !cancelled,
  repostable: finalized && !cancelled,
  releasable: releasable,
  finalizedAtUnix: finalized ? _at(_now.subtract(const Duration(days: 1))) : null,
  cancelReason: reason,
  flow: flow,
);

WalletOutput _out(String commitment, WalletOutputStatus status, {int? txId}) => WalletOutput(
  commitment: commitment,
  value: _epic(2),
  status: status,
  category: status == WalletOutputStatus.unspent ? OutputCategory.spendable : null,
  isCoinbase: false,
  height: BigInt.from(2400000),
  lockHeight: BigInt.zero,
  confirmations: BigInt.from(100),
  txId: txId,
);

WalletSummary get _summary => WalletSummary(
  lastConfirmedHeight: _tip,
  minimumConfirmations: BigInt.from(3),
  total: _epic(10),
  spendable: _epic(7),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(3),
  validatedWithNode: true,
);

/// Coins A and B locked by payment 9, another coin free.
FakeWalletSession _session(TxEntry tx) => FakeWalletSession(summary: _summary, transactions: [tx])
  ..outputsValue = [
    _out(_coinA, WalletOutputStatus.locked, txId: 9),
    _out(_coinB, WalletOutputStatus.locked, txId: 9),
    _out(_other, WalletOutputStatus.unspent, txId: 3),
  ];

void main() {
  group('which cancel spends back', () {
    test('an invoice paid and a send both signed: the other side may finish them', () {
      expect(cancelSpendsBack(_send(flow: TxFlow.invoice)), isTrue);
      expect(cancelSpendsBack(_send(finalized: true)), isTrue);
    });

    test('a send waiting for its answer, a receive, a cancelled one: no', () {
      expect(cancelSpendsBack(_send()), isFalse, reason: 'it cannot finish without this wallet');
      expect(cancelSpendsBack(fakeTx(id: 4, kind: TxKind.received, status: TxStatus.awaitingConfirmation, amountCredited: _epic(1))), isFalse);
      expect(cancelSpendsBack(_send(flow: TxFlow.invoice, cancelled: true)), isFalse);
    });

    test('final once no coin it locked is free with its link to it', () {
      final tx = _send(flow: TxFlow.invoice, cancelled: true);
      expect(cancelledMayComplete(tx), isTrue);
      expect(cancelFinal(tx, [_out(_coinA, WalletOutputStatus.unspent, txId: 9)]), isFalse);
      expect(cancelFinal(tx, [_out(_coinA, WalletOutputStatus.locked, txId: 12), _out(_other, WalletOutputStatus.unspent, txId: 3)]), isTrue);
      expect(cancelledMayComplete(_send(cancelled: true)), isFalse, reason: 'a plain cancel is certain');
    });
  });

  group('CancelFinal', () {
    test('a plain cancel: cancelled, nothing spent, no fee', () async {
      final s = _session(_send());
      expect(await CancelFinal().cancel(s, _send()), CancelResult.cancelled);
      expect(s.cancelledTxIds, [9]);
      expect(s.spentToSelf, isEmpty);
    });

    test('an invoice paid: cancelled, then exactly its coins spent back, in one call', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx);
      expect(await CancelFinal().cancel(s, tx), CancelResult.spentBack);
      expect(s.cancelledTxIds, [9]);
      expect(s.spentToSelf, [
        [_coinA, _coinB],
      ]);
    });

    test('a send both signed: the same', () async {
      final tx = _send(finalized: true);
      final s = _session(tx);
      expect(await CancelFinal().cancel(s, tx), CancelResult.spentBack);
      expect(s.spentToSelf.single, [_coinA, _coinB]);
    });

    test('a refused cancel (the network has it) spends nothing', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx)..cancelError = const WalletError(kind: WalletErrorKind.invalidArgument, message: 'in pool');
      await expectLater(CancelFinal().cancel(s, tx), throwsA(isA<WalletError>()));
      expect(s.spentToSelf, isEmpty);
    });

    test('a failed spend back is owed and goes with the next retry; spent coins are dropped', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx)..spendToSelfError = const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'down');
      final cancels = CancelFinal();
      expect(await cancels.cancel(s, tx), CancelResult.spendBackPending);
      expect(cancels.owed, isTrue);
      // Unlocked by the cancel, as LEPIC does: still linked to the payment.
      s
        ..outputsValue = [_out(_coinA, WalletOutputStatus.unspent, txId: 9), _out(_coinB, WalletOutputStatus.unspent, txId: 9)]
        ..spendToSelfError = null;
      expect(await cancels.retry(s), isTrue);
      expect(s.spentToSelf.last, [_coinA, _coinB]);
      expect(cancels.owed, isFalse);
      expect(await cancels.retry(s), isFalse, reason: 'nothing owed');
    });

    test('a retry finds the coins spent elsewhere: nothing left to do', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx)..spendToSelfError = const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'down');
      final cancels = CancelFinal();
      await cancels.cancel(s, tx);
      s.outputsValue = [_out(_coinA, WalletOutputStatus.locked, txId: 20)];
      expect(await cancels.retry(s), isFalse);
      expect(cancels.owed, isFalse);
      expect(s.spentToSelf, hasLength(1), reason: 'only the first, failed try');
    });

    test('the payment won the race: the spend back is refused for good, nothing owed', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx)
        ..spendToSelfError = const WalletError(kind: WalletErrorKind.inputsSpentByOwnPayment, message: 'spent by tx 9');
      final cancels = CancelFinal();
      expect(await cancels.cancel(s, tx), CancelResult.alreadyPaid);
      expect(cancels.owed, isFalse);
      expect(await cancels.retry(s), isFalse);
      expect(s.spentToSelf, hasLength(1));
    });

    test('Release funds follows the rule: released, then its coins spent back', () async {
      final tx = _send(finalized: true, releasable: true);
      final s = _session(tx);
      expect(await CancelFinal().release(s, tx), CancelResult.spentBack);
      expect(s.releasedKeys, [tx.key]);
      expect(s.spentToSelf.single, [_coinA, _coinB]);
    });

    test('the spend back gives back as many coins as it spends', () async {
      final tx = _send(flow: TxFlow.invoice);
      final s = _session(tx);
      expect(await CancelFinal().cancel(s, tx), CancelResult.spentBack);
      // Two coins of 2 EPIC each: two back, about 1.996 each.
      expect(s.spentToSelfOutputs, [2]);
    });

    test('Stop waiting: only cancelled, nothing spent, nothing owed', () async {
      for (final tx in [_send(flow: TxFlow.invoice), _send(finalized: true)]) {
        final s = _session(tx);
        final cancels = CancelFinal();
        expect(await cancels.cancel(s, tx, spendBack: false), CancelResult.stoppedWaiting);
        expect(s.cancelledTxIds, [9]);
        expect(s.spentToSelf, isEmpty);
        expect(cancels.owed, isFalse);
        // Unlocked by the cancel, as LEPIC does: a later retry still spends nothing.
        s.outputsValue = [_out(_coinA, WalletOutputStatus.unspent, txId: 9)];
        expect(await cancels.retry(s), isFalse);
        expect(s.spentToSelf, isEmpty);
      }
    });

    test('Stop waiting on a plain send is the plain cancel', () async {
      final tx = _send();
      final s = _session(tx);
      expect(await CancelFinal().cancel(s, tx, spendBack: false), CancelResult.cancelled);
      expect(s.spentToSelf, isEmpty);
    });

    test('Release coins can only stop waiting too: released, nothing spent', () async {
      final tx = _send(finalized: true, releasable: true);
      final s = _session(tx);
      expect(await CancelFinal().release(s, tx, spendBack: false), CancelResult.stoppedWaiting);
      expect(s.releasedKeys, [tx.key]);
      expect(s.spentToSelf, isEmpty);
    });

    test('the desktop demo wallet: Stop waiting leaves the cancel not final', () async {
      final m = MockDeskWallet(delay: Duration.zero);
      m.addSignedCancelDemo(id: MockDeskWallet.signedCancelDemoId);
      expect(await m.cancelTx(MockDeskWallet.signedCancelDemoId, spendBack: false), CancelResult.stoppedWaiting);
      final t = (await m.transactions()).singleWhere((t) => t.id == MockDeskWallet.signedCancelDemoId);
      expect(t.cancelFinal, isFalse);
    });

    test('a refused late post says why, on either side', () {
      for (final kind in [WalletErrorKind.inputsSpentByOwnPayment, WalletErrorKind.peerInputsSpent]) {
        expect(describeError(_l, WalletError(kind: kind, message: 'internal error')), _l.errorPaymentCancelledCoinsMoved);
      }
    });
  });

  group('how many coins a spend back gives back', () {
    BigInt e(num v) => BigInt.from((v * 100000000).round());

    test('the fee: 0.004 EPIC per output, less 0.001 per coin spent', () {
      expect(spendBackFee(1, 1), e(0.004));
      expect(spendBackFee(3, 3), e(0.010));
      expect(spendBackFee(3, 1), e(0.002));
      expect(spendBackFee(8, 8), e(0.025));
      expect(spendBackFee(9, 1), e(0.001), reason: 'never below one unit of weight');
    });

    test('one coin: one back', () => expect(spendBackOutputs([e(3)]), 1));

    test('three coins: three back', () => expect(spendBackOutputs([e(2), e(1.5), e(5)]), 3));

    test('many coins: one each, up to ten', () {
      expect(spendBackOutputs(List.filled(8, e(2))), 8);
      expect(spendBackOutputs(List.filled(14, e(2))), 10);
    });

    test('small coins: fewer outputs, so none is under 1 EPIC', () {
      // 3 × 0.9 = 2.7 EPIC: three of 0.9 or less are too small, two of about 1.345 are not.
      expect(spendBackOutputs([e(0.9), e(0.9), e(0.9)]), 2);
      // 3 × 0.5: even two would be 0.75 each, so one.
      expect(spendBackOutputs([e(0.5), e(0.5), e(0.5)]), 1);
      // Exactly 1 EPIC each after the fee stays split.
      expect(spendBackOutputs([e(1.005), e(1.005)]), 2);
      expect(spendBackOutputs([e(1.003), e(1.003)]), 1);
    });
  });

  // No new status sentences on the details (the owner, 2026-10-30): a cancelled payment keeps the
  // words it had, whether its coins were spent back or not.
  group('the cancelled payment keeps its words', () {
    String say(TxEntry tx, bool? isFinal) => txExplanation(_l, tx, _tip, cancelFinal: isFinal);

    test('an invoice paid: the same words, final or not', () {
      final tx = _send(flow: TxFlow.invoice, cancelled: true, reason: CancelReason.user);
      expect(say(tx, true), _l.txDetailsCancelledByUser);
      expect(say(tx, false), _l.txDetailsCancelledByUser);
    });

    test('a plain send keeps its certain words', () {
      expect(say(_send(cancelled: true, reason: CancelReason.user), null), _l.txDetailsCancelledByUser);
    });

    test('a released send keeps its released words', () {
      final tx = _send(finalized: true, cancelled: true, reason: CancelReason.release);
      expect(say(tx, false), _l.txDetailsCancelledReleased);
      expect(say(tx, true), _l.txDetailsCancelledReleased);
      expect(say(tx, null), _l.txDetailsCancelledReleased);
    });
  });

  group('phone', () {
    Future<FakeWalletSession> pump(WidgetTester tester, TxEntry tx) async {
      final session = _session(tx);
      final store = MemorySecretStore();
      store.values['wallet.mainnet.backedUp'] = '1';
      final service = FakeWalletService(session: session);
      session.owner = service;
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            relayProbeProvider.overrideWithValue(FakeRelayProbe()),
            walletServiceProvider.overrideWithValue(service),
            secretStoreProvider.overrideWithValue(store),
            biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
            updatePlatformProvider.overrideWithValue(null),
            clockProvider.overrideWithValue(() => _now),
            sessionProvider.overrideWith(() => _Open(session)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TxDetailsScreen(txKey: 's:pay-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return session;
    }

    String? notice(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.text;

    Future<void> cancel(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).first);
      await tester.pumpAndSettle();
    }

    testWidgets('an invoice paid: the note and the dialog say so, the fee in one line; one Cancel does both', (tester) async {
      final s = await pump(tester, _send(flow: TxFlow.invoice));
      await cancel(tester);
      expect(find.text(_l.txDetailsCancelRequestBody), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
      expect(find.text(_l.cancelFeeLine), findsOneWidget);
      await tester.tap(find.byKey(cancelForSureKey));
      await tester.pumpAndSettle();
      expect(s.cancelledTxIds, [9]);
      expect(s.spentToSelf.single, [_coinA, _coinB]);
      expect(notice(tester), _l.txDetailsPaymentCancelled);
    });

    testWidgets('a send waiting for its answer: certain, no fee, nothing spent', (tester) async {
      final s = await pump(tester, _send());
      await cancel(tester);
      expect(find.text(_l.txDetailsCancelSendBody), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
      expect(find.text(_l.cancelFeeLine), findsNothing);
      await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).last);
      await tester.pumpAndSettle();
      expect(s.spentToSelf, isEmpty);
      expect(notice(tester), _l.txDetailsPaymentCancelled);
    });

    testWidgets('a spend back that fails: cancelled, a warning that it is not final yet', (tester) async {
      final tx = _send(flow: TxFlow.invoice);
      final s = await pump(tester, tx);
      // The fake's cancel unlocks nothing: show the coins as LEPIC leaves them after a cancel,
      // unspent and still linked to the payment, so the retry after the reload finds them.
      s
        ..spendToSelfError = const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'down')
        ..outputsValue = [_out(_coinA, WalletOutputStatus.unspent, txId: 9), _out(_coinB, WalletOutputStatus.unspent, txId: 9)];
      await cancel(tester);
      await tester.tap(find.byKey(cancelForSureKey));
      await tester.pumpAndSettle();
      expect(s.cancelledTxIds, [9]);
      expect(notice(tester), _l.txDetailsPaymentCancelled);
      final container = ProviderScope.containerOf(tester.element(find.byType(Navigator).first));
      // Calm (the owner, 2026-10-30): a retry is information, not a warning.
      expect(container.read(noticeProvider)?.level, NoticeLevel.info);
      expect(container.read(cancelFinalProvider).owed, isTrue);
    });

    testWidgets('a cancelled invoice payment keeps its cancelled words', (tester) async {
      final tx = _send(flow: TxFlow.invoice, cancelled: true, reason: CancelReason.user);
      final s = _session(tx);
      expect(s.outputsValue.where((o) => o.txId == 9 && o.status == WalletOutputStatus.unspent), isEmpty);
      await pump(tester, tx);
      expect(find.text(_l.txDetailsCancelledByUser), findsOneWidget);
    });
  });

  group('desktop', () {
    Tx tx({bool cancelled = false, bool? isFinal}) => Tx(
      id: 77,
      slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
      direction: TxDirection.sent,
      state: cancelled ? TxState.cancelled : TxState.posted,
      method: TxMethod.epicbox,
      amount: 250000000,
      fee: 7000000,
      created: DateTime(2026, 10, 20),
      counterparty: 'esAlice@epicbox.example',
      cancellable: !cancelled,
      notPosted: !cancelled,
      cancelFinal: isFinal,
    );

    Future<void> pump(WidgetTester tester, Tx t) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final desk = MockDeskWallet(delay: Duration.zero);
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(desk), deskClockProvider.overrideWithValue(() => _now)]);
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: TxDetail(tx: t))),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a send both signed: the note and the dialog name the spend back and its fee', (tester) async {
      await pump(tester, tx());
      await tester.tap(find.widgetWithText(EButton, _l.deskTxCancelOutgoingAction).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_l.cancelFeeLine), findsOneWidget);
      expect(find.byType(ECheckbox), findsNothing, reason: 'no extra step');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('a cancelled one reads Cancelled, final or not', (tester) async {
      await pump(tester, tx(cancelled: true, isFinal: true));
      expect(find.text(_l.deskTxNowCancelled), findsOneWidget);
      await pump(tester, tx(cancelled: true, isFinal: false));
      expect(find.text(_l.deskTxNowCancelled), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}
