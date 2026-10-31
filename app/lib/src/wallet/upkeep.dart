// SPDX-License-Identifier: Apache-2.0
/// The open wallet's own upkeep, one copy for the phone and the desktop (T-04): what each stack
/// runs by itself at open and after each node answer. The policies are their own files
/// (stall_retry.dart, sender_cancel.dart, cancel_final.dart); this is the glue both called.
library;

import '../log.dart';
import '../models.dart';
import '../wallet_service.dart' show WalletSession;

/// Sends each undelivered Epicbox send in [transactions] again once: the app was killed before
/// its first attempt, or the relay refused it. An HTTP or Tor send waits for the user's Send
/// again, as its recipient may be offline. A failure is logged under [tag] and leaves that send
/// for the user. [stillOpen] false ends the round between two sends (the wallet closed). True
/// when one went.
Future<bool> resendUndelivered(
  WalletSession session,
  Iterable<TxEntry> transactions, {
  required String tag,
  bool Function()? stillOpen,
}) async {
  var sent = false;
  for (final tx in transactions.where((t) => t.undelivered && t.transport == 'epicbox').toList()) {
    if (stillOpen != null && !stillOpen()) return sent;
    try {
      await session.resendEpicbox(key: tx.key);
      sent = true;
    } catch (error) {
      logWarn(tag, 'resend at open failed: ${error is WalletError ? error.kind.name : error.runtimeType}');
    }
  }
  return sent;
}
