// SPDX-License-Identifier: Apache-2.0
// The sender's cancel notice on an incoming payment this wallet answered: LEPIC records the
// report and raises `paymentCancelled`; the app releases the payment if it still waits, leaves
// one the network has (the cancel's node check refuses it) to confirm, tries again at the next
// refresh after any other failure, and never touches a confirmed payment. The row reads
// "Cancelled by the sender", before and after the release.
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart' show deskTx;
import 'package:epic_wallet/src/desktop/data/models.dart' show TxState;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show ETone;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/sender_cancel.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart' show txExplanation;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final _now = DateTime(2026, 10, 28, 12);
int _unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
final _l = englishStrings;
final _tip = BigInt.from(1000);

/// An incoming payment this wallet answered 5 minutes ago, waiting for its sender, whose sender
/// reported cancelling it when [cancelled].
TxEntry _waiting({
  bool cancelled = true,
  TxKind kind = TxKind.received,
  TxStatus status = TxStatus.awaitingConfirmation,
  BigInt? blockHeight,
  TxFlow flow = TxFlow.payment,
  int? reportedPostedAtUnix,
}) => fakeTx(
  slateId: 'cancelled-1',
  id: 9,
  kind: kind,
  status: status,
  blockHeight: blockHeight,
  createdAtUnix: _unix(_now.subtract(const Duration(minutes: 5))),
  amountCredited: BigInt.from(100000000),
  transport: 'epicbox',
  counterparty: 'esSender@epicbox.epiccash.com',
  cancellable: true,
  flow: flow,
  senderReportedPostedAtUnix: reportedPostedAtUnix,
  senderReportedCancelledAtUnix: cancelled ? _unix(_now.subtract(const Duration(minutes: 1))) : null,
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

const _onNetwork = WalletError(kind: WalletErrorKind.invalidArgument, message: 'in pool');
const _noNode = WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'node unreachable');

void main() {
  group('the rule', () {
    test('a waiting incoming payment its sender cancelled is pending; once cleared it stays cancelled by the sender', () {
      expect(senderCancelPending(_waiting()), isTrue);
      expect(senderCancelled(_waiting()), isTrue);
      final cleared = _waiting(kind: TxKind.receivedCancelled, status: TxStatus.cancelled);
      expect(senderCancelPending(cleared), isFalse);
      expect(senderCancelled(cleared), isTrue);
    });

    test('never for a confirmed payment, one in a block, a request, or a row without the report', () {
      expect(senderCancelled(_waiting(status: TxStatus.confirmed)), isFalse);
      expect(senderCancelPending(_waiting(blockHeight: BigInt.from(900))), isFalse);
      expect(senderCancelled(_waiting(blockHeight: BigInt.from(900))), isFalse);
      expect(senderCancelled(_waiting(flow: TxFlow.invoice)), isFalse);
      expect(senderCancelled(_waiting(cancelled: false)), isFalse);
      expect(senderCancelled(_waiting(kind: TxKind.sent)), isFalse);
    });

    test('Cancel is offered at once: no hold, whatever a posted report says', () {
      final hold = incomingCancelOf(_waiting(reportedPostedAtUnix: _unix(_now)), now: _now);
      expect(hold.holdLeft, greaterThan(Duration.zero));
      expect(hold.senderCancelled, isTrue);
      expect(hold.offered, isTrue);
      expect(incomingCancelOf(_waiting(cancelled: false), now: _now).offered, isFalse);
    });
  });

  group('the release', () {
    test('cancels a pending payment once; the cleared row is not cancelled again', () async {
      final session = FakeWalletSession(transactions: [_waiting()]);
      final release = SenderCancelRelease();
      expect(await release.run(session, await session.transactions(refresh: false)), isTrue);
      expect(session.cancelledTxIds, [9]);
      final rows = await session.transactions(refresh: false);
      expect(rows.single.kind, TxKind.receivedCancelled);
      expect(senderCancelled(rows.single), isTrue);
      expect(await release.run(session, rows), isFalse);
      expect(session.cancelledTxIds, [9]);
    });

    test('one the network has (InPool, OnChain) is left alone and never asked again', () async {
      final session = FakeWalletSession(transactions: [_waiting()])..cancelError = _onNetwork;
      final release = SenderCancelRelease();
      expect(await release.run(session, session.transactionsValue), isFalse);
      expect(await release.run(session, session.transactionsValue), isFalse);
      expect(session.cancelledTxIds, [9]);
      expect(session.transactionsValue.single.kind, TxKind.received);
    });

    test('any other failure is tried again at the next run', () async {
      final session = FakeWalletSession(transactions: [_waiting()])..cancelError = _noNode;
      final release = SenderCancelRelease();
      expect(await release.run(session, session.transactionsValue), isFalse);
      session.cancelError = null;
      expect(await release.run(session, session.transactionsValue), isTrue);
      expect(session.cancelledTxIds, [9, 9]);
    });

    test('a confirmed payment, one in a block, and a row without the report are never touched', () async {
      final session = FakeWalletSession(
        transactions: [
          _waiting(status: TxStatus.confirmed),
          _waiting(blockHeight: BigInt.from(900)),
          _waiting(cancelled: false),
        ],
      );
      expect(await SenderCancelRelease().run(session, session.transactionsValue), isFalse);
      expect(session.cancelledTxIds, isEmpty);
    });
  });

  group('LEPIC', () {
    lepic.TransactionDetails details({int? cancelledAtMs}) => lepic.TransactionDetails(
      txId: 9,
      direction: lepic.TxDirection.incoming,
      status: lepic.TxStatus.received,
      slateId: 'cancelled-1',
      transport: 'epicbox',
      amountCredited: BigInt.from(100000000),
      amountDebited: BigInt.zero,
      createdAtMs: 1790000000000,
      releasable: false,
      undelivered: false,
      flow: lepic.TxFlow.payment,
      messages: const [],
      origin: lepic.TxOrigin.wallet,
      outputCommits: const [],
      spentCommits: const [],
      unverified: false,
      coinbase: false,
      senderReportedCancelledAtMs: cancelledAtMs,
    );

    test('the report time comes over in seconds, and none stays none', () {
      expect(lepicTxEntry(details(cancelledAtMs: 1790000123456)).senderReportedCancelledAtUnix, 1790000123);
      expect(lepicTxEntry(details()).senderReportedCancelledAtUnix, isNull);
    });

    test('paymentCancelled is the session notice of the same name', () {
      expect(
        lepicInvoiceEvent(
          const lepic.WalletEvent(kind: lepic.WalletEventKind.paymentCancelled, txId: 9, slateId: 'cancelled-1'),
        ),
        const InvoiceEvent(kind: InvoiceEventKind.paymentCancelled, slateId: 'cancelled-1'),
      );
    });
  });

  group('phone', () {
    late FakeWalletSession session;
    late ProviderContainer c;

    Future<void> open(List<TxEntry> rows) async {
      session = FakeWalletSession(transactions: rows);
      c = ProviderContainer(retry: (_, _) => null, overrides: [sessionProvider.overrideWith(() => _Open(session))]);
      addTearDown(c.dispose);
      c.listen(homeProvider, (_, _) {});
      c.listen(paymentCancelledProvider, (_, _) {});
      await c.read(homeProvider.future);
      await pumpEventQueue();
    }

    test('the notice releases the waiting payment once, and the list shows it cleared', () async {
      await open([_waiting(cancelled: false)]);
      session.reportCancelled(slateId: 'cancelled-1');
      await pumpEventQueue();
      expect(c.read(paymentCancelledProvider)?.slateId, 'cancelled-1');
      expect(session.cancelledTxIds, [9]);
      final row = c.read(homeProvider).value!.transactions.single;
      expect(row.kind, TxKind.receivedCancelled);
      expect(txStatusLabel(_l, row, _tip, now: _now), _l.txStatusSenderCancelled);
    });

    test('one the network has stays, and a refresh does not ask again', () async {
      await open([_waiting(cancelled: false)]);
      session.cancelError = _onNetwork;
      session.reportCancelled(slateId: 'cancelled-1');
      await pumpEventQueue();
      c.invalidate(homeProvider);
      await c.read(homeProvider.future);
      await pumpEventQueue();
      expect(session.cancelledTxIds, [9]);
      expect(c.read(homeProvider).value!.transactions.single.kind, TxKind.received);
    });

    test('a release that failed goes again at the next refresh', () async {
      await open([_waiting(cancelled: false)]);
      session.cancelError = _noNode;
      session.reportCancelled(slateId: 'cancelled-1');
      await pumpEventQueue();
      expect(session.cancelledTxIds, [9]);
      session.cancelError = null;
      c.invalidate(homeProvider);
      await c.read(homeProvider.future);
      await pumpEventQueue();
      expect(session.cancelledTxIds, [9, 9]);
      expect(c.read(homeProvider).value!.transactions.single.kind, TxKind.receivedCancelled);
    });

    test('a wallet without reports is left as it was', () async {
      await open([_waiting(cancelled: false), _waiting(status: TxStatus.confirmed)]);
      c.invalidate(homeProvider);
      await c.read(homeProvider.future);
      await pumpEventQueue();
      expect(session.cancelledTxIds, isEmpty);
    });

    test('the words, before and after the release', () {
      expect(txStatusLabel(_l, _waiting(), _tip, now: _now), _l.txStatusSenderCancelled);
      expect(txExplanation(_l, _waiting(), _tip, now: _now), _l.txDetailsSenderCancelledWaiting);
      expect(txTimeline(_l, _waiting(), _tip, now: _now), isNull);
      final cleared = _waiting(kind: TxKind.receivedCancelled, status: TxStatus.cancelled);
      expect(txExplanation(_l, cleared, _tip, now: _now), _l.txDetailsSenderCancelled);
      expect(txStatusLabel(_l, _waiting(cancelled: false), _tip, now: _now), _l.txStatusWaitingSender);
    });
  });

  group('desktop', () {
    test('the row reads Cancelled by the sender, waiting or cleared, and nothing else changes', () {
      final waiting = deskTx(_waiting(), tip: 1000, minConf: 10, fallbackId: -1, now: _now);
      expect(waiting.state, TxState.waitingRecipient);
      expect(waiting.senderCancelled, isTrue);
      expect(statusOf(_l, waiting), ('Cancelled by the sender', ETone.neutral));
      final cleared = deskTx(_waiting(kind: TxKind.receivedCancelled, status: TxStatus.cancelled), tip: 1000, minConf: 10, fallbackId: -1, now: _now);
      expect(statusOf(_l, cleared), ('Cancelled by the sender', ETone.neutral));
      final plain = deskTx(_waiting(cancelled: false), tip: 1000, minConf: 10, fallbackId: -1, now: _now);
      expect(plain.senderCancelled, isFalse);
      expect(statusOf(_l, plain).$1, 'Waiting for sender');
    });
  });
}
