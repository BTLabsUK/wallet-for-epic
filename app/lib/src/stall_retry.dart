/// What the app does again by itself, while the wallet is open, for a payment that has not
/// reached the chain: a finished payment is posted to the node again, and the answer to a paid
/// invoice is sent to the service again. Phone and desktop share the policy and the runner.
/// Nothing here ever cancels a payment.
library;

import 'log.dart';
import 'wallet_service.dart';

/// Waits before each automatic repost of a finished payment the chain has not taken: the first
/// from when the app first saw it waiting, each next one from the try before. The last wait
/// repeats for as long as the wallet stays open. Posting it again is safe: the same payment
/// cannot go through twice, and a node that holds it already says so.
const List<Duration> repostWaits = [
  Duration(minutes: 1),
  Duration(minutes: 3),
  Duration(minutes: 10),
  Duration(minutes: 30),
];

/// Waits before each automatic resend of a paid invoice's answer that the service has not
/// finished: the first from the payment, each next one from the try before. Then it stops.
const List<Duration> answerResendWaits = [
  Duration(minutes: 2),
  Duration(minutes: 5),
  Duration(minutes: 10),
];

/// A paid invoice whose payment is still not on the network this long after it was paid reads
/// "Stalled", with Send again. The automatic resends above have run by then.
const Duration stalledAfter = Duration(minutes: 20);

DateTime _created(TxEntry tx) =>
    DateTime.fromMillisecondsSinceEpoch(tx.createdAtUnix * 1000);

/// A payment this wallet finished that is not in a block yet: refused by the node
/// ([TxEntry.repostable]) or posted and waiting. A paid request it issued counts: it finished
/// that too. Only a finished payment has its kernel; an unpaid request and a plain receive have
/// none.
bool awaitsChain(TxEntry tx) =>
    tx.source == TxSource.wallet &&
    tx.status == TxStatus.awaitingConfirmation &&
    tx.blockHeight == null &&
    (tx.kind == TxKind.sent || tx.isRequest) &&
    (tx.repostable || (tx.kernelExcess != null && !tx.cancellable));

/// A payment of an invoice this wallet made, waiting for the service to finish and post it.
bool invoicePaymentWaiting(TxEntry tx) =>
    tx.flow == TxFlow.invoice &&
    tx.kind == TxKind.sent &&
    tx.status == TxStatus.awaitingRecipient &&
    tx.slateId != null;

/// [invoicePaymentWaiting] for [stalledAfter] or longer at [now].
bool invoicePaymentStalled(TxEntry tx, DateTime now) =>
    invoicePaymentWaiting(tx) && now.difference(_created(tx)) >= stalledAfter;

/// Runs the automatic reposts and resends for one open wallet. Call [run] with the wallet's
/// list whenever it is read; it does only what is due, one try per payment per call.
class StallRetry {
  final _seen = <String, DateTime>{};
  final _tries = <String, ({int count, DateTime last})>{};
  bool _running = false;
  bool _nodeBack = false;

  /// The node answers again after failing: at the next [run], each payment the chain has not
  /// taken is posted again at once, rather than at its next wait. A post that failed while the
  /// connection was down then goes out as soon as it is back.
  void nodeBack() => _nodeBack = true;

  /// Whether a try for [tx] is due at [now], from [waits]; [repeat] repeats the last wait.
  bool _due(
    String key,
    DateTime from,
    DateTime now,
    List<Duration> waits, {
    required bool repeat,
  }) {
    final tries = _tries[key];
    final count = tries?.count ?? 0;
    if (count >= waits.length && !repeat) return false;
    final wait = waits[count < waits.length ? count : waits.length - 1];
    return !now.isBefore((tries?.last ?? from).add(wait));
  }

  void _tried(String key, DateTime now) =>
      _tries[key] = (count: (_tries[key]?.count ?? 0) + 1, last: now);

  /// Posts again each payment of [txs] the chain has not taken, and sends again each paid
  /// invoice's answer the service has not finished, when its wait has passed. Failures are
  /// logged and tried again at the next wait. True when anything was sent, so the caller can
  /// read the list again.
  Future<bool> run(
    WalletSession session,
    Iterable<TxEntry> txs,
    DateTime now,
  ) async {
    if (_running) return false;
    _running = true;
    try {
      final list = txs.toList();
      final keys = {for (final t in list) t.key};
      _seen.removeWhere((k, _) => !keys.contains(k));
      _tries.removeWhere((k, _) => !keys.contains(k));
      var sent = false;
      final back = _nodeBack;
      _nodeBack = false;
      for (final tx in list) {
        if (awaitsChain(tx)) {
          final from = _seen.putIfAbsent(tx.key, () => now);
          // Back after an outage: a post the node refused goes again now. A payment that is
          // posted and waiting gains nothing from it, and keeps its waits.
          if (!(back && tx.repostable) && !_due(tx.key, from, now, repostWaits, repeat: true)) continue;
          _tried(tx.key, now);
          try {
            await session.repostTransaction(key: tx.key);
            sent = true;
            logInfo('stall', 'payment posted again');
          } on WalletError catch (error) {
            logWarn('stall', 'repost failed: ${error.kind.name}');
          }
        } else if (invoicePaymentWaiting(tx)) {
          if (!_due(tx.key, _created(tx), now, answerResendWaits, repeat: false)) {
            continue;
          }
          _tried(tx.key, now);
          try {
            await session.resendInvoiceReply(slateId: tx.slateId!);
            sent = true;
            logInfo('stall', 'invoice answer sent again');
          } on WalletError catch (error) {
            logWarn('stall', 'answer resend failed: ${error.kind.name}');
          }
        }
      }
      return sent;
    } finally {
      _running = false;
    }
  }
}
