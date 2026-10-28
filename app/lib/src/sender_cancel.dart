// SPDX-License-Identifier: Apache-2.0
/// What the app does by itself when the sender of an incoming payment this wallet answered
/// reports that it cancelled it: the payment is released here, so it no longer waits for a
/// sender who will never post it. Phone and desktop share the policy and the runner.
///
/// LEPIC only records the report; the release is this wallet's own cancel, which asks the node
/// first and refuses a payment already in its pool or in a block (`invalidArgument`). Such a
/// payment is left alone: it will confirm. Any other failure (no node, a locked wallet) is tried
/// again with the next list read. A confirmed payment, or one in a block, is never touched.
library;

import 'log.dart';
import 'wallet_service.dart';

/// Releases the incoming payments their senders cancelled, for one open wallet. Call [run] with
/// the wallet's list on a `paymentCancelled` notice and whenever the list is read.
class SenderCancelRelease {
  /// Payments the node already has: refused once, never asked again while the wallet is open.
  final _onNetwork = <String>{};
  bool _running = false;

  /// Cancels each payment of [txs] waiting for a sender that cancelled it
  /// ([senderCancelPending]), once per call. True when any was released, so the caller can
  /// read the list again.
  Future<bool> run(WalletSession session, Iterable<TxEntry> txs) async {
    if (_running) return false;
    _running = true;
    try {
      var released = false;
      for (final tx in txs.toList()) {
        final id = tx.id;
        if (id == null || !senderCancelPending(tx) || _onNetwork.contains(tx.key)) continue;
        try {
          await session.cancelTransaction(txId: id);
          released = true;
          logInfo('sender-cancel', 'payment the sender cancelled released');
        } on WalletError catch (error) {
          if (error.kind == WalletErrorKind.invalidArgument) {
            _onNetwork.add(tx.key);
            logInfo('sender-cancel', 'sender cancelled, but the network has the payment: left to confirm');
          } else {
            logWarn('sender-cancel', 'release failed, tried again later: ${error.kind.name}');
          }
        }
      }
      return released;
    } finally {
      _running = false;
    }
  }
}
