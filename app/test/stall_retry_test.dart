// The automatic retries phone and desktop share (stall_retry.dart): a finished payment the
// chain has not taken is posted again on a backoff for as long as the wallet is open; a paid
// invoice's answer is sent again a few times, and reads Stalled after that. Nothing cancels.
import 'package:epic_wallet/src/stall_retry.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 10, 24, 3);
int _unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

TxEntry _finished({
  required String key,
  bool repostable = false,
  bool request = false,
}) => fakeTx(
  key: key,
  id: key.hashCode & 0xffff,
  slateId: key,
  kind: request ? TxKind.received : TxKind.sent,
  status: TxStatus.awaitingConfirmation,
  createdAtUnix: _unix(_t0),
  kernelExcess: '08abc',
  repostable: repostable,
  flow: request ? TxFlow.invoice : TxFlow.payment,
);

TxEntry _invoicePayment(String slateId) => fakeTx(
  key: 's:$slateId',
  id: 19,
  slateId: slateId,
  kind: TxKind.sent,
  status: TxStatus.awaitingRecipient,
  createdAtUnix: _unix(_t0),
  flow: TxFlow.invoice,
);

void main() {
  test('what waits for the chain: refused or posted, never unpaid or received', () {
    expect(awaitsChain(_finished(key: 'refused', repostable: true)), isTrue);
    expect(awaitsChain(_finished(key: 'posted')), isTrue);
    expect(awaitsChain(_finished(key: 'paid-request', request: true)), isTrue);
    // An unpaid request: no kernel, and still cancellable.
    expect(
      awaitsChain(
        fakeTx(
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          flow: TxFlow.invoice,
          cancellable: true,
        ),
      ),
      isFalse,
    );
    expect(
      awaitsChain(
        fakeTx(
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          kernelExcess: '08abc',
        ),
      ),
      isFalse,
      reason: 'a plain receive is the sender\'s to post',
    );
  });

  test('a payment off the chain is posted again on the backoff, and keeps trying', () async {
    final session = FakeWalletSession(
      transactions: [
        _finished(key: 'refused', repostable: true),
        _finished(key: 'posted'),
      ],
    );
    final retry = StallRetry();
    Future<bool> at(Duration d) =>
        retry.run(session, session.transactionsValue, _t0.add(d));

    expect(await at(Duration.zero), isFalse, reason: 'first seen now');
    expect(await at(const Duration(seconds: 59)), isFalse);
    expect(await at(const Duration(minutes: 1)), isTrue);
    expect(session.repostedKeys, ['refused', 'posted']);
    expect(await at(const Duration(minutes: 3)), isFalse);
    expect(await at(const Duration(minutes: 4)), isTrue);
    expect(await at(const Duration(minutes: 14)), isTrue);
    expect(await at(const Duration(minutes: 44)), isTrue);
    expect(await at(const Duration(minutes: 73)), isFalse);
    expect(await at(const Duration(minutes: 74)), isTrue, reason: 'the last wait repeats');
    expect(session.repostedKeys.length, 10);
    expect(session.cancelledTxIds, isEmpty, reason: 'nothing is ever cancelled');
  });

  test('a failed repost is tried again at the next wait', () async {
    final session = FakeWalletSession(
      transactions: [_finished(key: 'refused', repostable: true)],
    )..repostFailures = 1;
    final retry = StallRetry();
    Future<bool> at(Duration d) =>
        retry.run(session, session.transactionsValue, _t0.add(d));
    await at(Duration.zero);
    expect(await at(const Duration(minutes: 1)), isFalse);
    expect(session.repostedKeys, isEmpty);
    expect(await at(const Duration(minutes: 4)), isTrue);
    expect(session.repostedKeys, ['refused']);
  });

  test('a paid invoice\'s answer goes again a few times, then it reads Stalled', () async {
    final tx = _invoicePayment('0a9b35d2');
    final session = FakeWalletSession(transactions: [tx]);
    session.paidInvoicesValue['0a9b35d2'] = PaidInvoice(
      slateId: '0a9b35d2',
      senderAddress: 'esIssuer@epicbox.epiccash.com',
      amount: BigInt.from(5000000),
      status: InvoiceStatus.replied,
      txId: 19,
    );
    final retry = StallRetry();
    Future<bool> at(Duration d) =>
        retry.run(session, session.transactionsValue, _t0.add(d));

    expect(await at(const Duration(minutes: 1)), isFalse);
    expect(await at(const Duration(minutes: 2)), isTrue);
    expect(await at(const Duration(minutes: 6)), isFalse);
    expect(await at(const Duration(minutes: 7)), isTrue);
    expect(await at(const Duration(minutes: 17)), isTrue);
    expect(await at(const Duration(hours: 3)), isFalse, reason: 'three tries, then it stops');
    expect(session.deliveredReplies, ['0a9b35d2', '0a9b35d2', '0a9b35d2']);

    expect(invoicePaymentStalled(tx, _t0.add(const Duration(minutes: 19))), isFalse);
    expect(invoicePaymentStalled(tx, _t0.add(stalledAfter)), isTrue);
    final posted = answerResendWaits.fold(Duration.zero, (a, b) => a + b);
    expect(posted < stalledAfter, isTrue, reason: 'the resends run before it reads Stalled');
  });
}
