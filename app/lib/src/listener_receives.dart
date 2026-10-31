// SPDX-License-Identifier: Apache-2.0
/// Payments the wallet's own listeners took in by themselves (Link · HTTP, Link · Tor): anyone
/// who can reach a listener can make one, so a stranger can fill the history and the pending
/// balance with payments that never come. The app cancels the ones still waiting after
/// [listenerReceiveTtl] and keeps at most [maxListenerReceives] waiting, cancelling the oldest
/// beyond that ([listenerReceivesToCancel]). On screen such a payment looks like any other
/// receive waiting for its sender, and once cancelled like any cancelled one: no text of its
/// own. LEPIC keeps its own, longer expiry; this is the app's policy.
///
/// A cancel is safe for a real payment that was slow: when the sender posts it after all and the
/// chain mines it, LEPIC moves it from cancelled to confirmed.
library;

import 'models.dart';

/// How long a listener's payment may wait for its sender. A sender's wallet finalizes and posts
/// within seconds of the answer.
const Duration listenerReceiveTtl = Duration(hours: 6);

/// At most this many listener payments wait at once.
const int maxListenerReceives = 20;

/// Whether [tx] is a payment a listener took in by itself and is still waiting for its sender:
/// received over `http` or `tor`, not a request this wallet issued, not on the chain.
bool isListenerReceive(TxEntry tx) =>
    tx.kind == TxKind.received &&
    !tx.isRequest &&
    (tx.transport == 'http' || tx.transport == 'tor') &&
    tx.status == TxStatus.awaitingConfirmation &&
    tx.blockHeight == null;

/// The local ids of the listener payments in [txs] to cancel at [now]: those older than
/// [listenerReceiveTtl], and beyond the newest [maxListenerReceives] of the rest.
List<int> listenerReceivesToCancel(List<TxEntry> txs, DateTime now) {
  final waiting = [for (final tx in txs) if (tx.id != null && isListenerReceive(tx)) tx]
    ..sort((a, b) => b.createdAtUnix.compareTo(a.createdAtUnix));
  final oldest = now.subtract(listenerReceiveTtl).millisecondsSinceEpoch ~/ 1000;
  final cancel = <int>[];
  var kept = 0;
  for (final tx in waiting) {
    if (tx.createdAtUnix < oldest || kept >= maxListenerReceives) {
      cancel.add(tx.id!);
    } else {
      kept++;
    }
  }
  return cancel;
}
