// SPDX-License-Identifier: Apache-2.0
/// The open wallet's own upkeep, one copy for the phone and the desktop (T-04): what each stack
/// runs by itself at open and after each node answer. The policies are their own files
/// (stall_retry.dart, sender_cancel.dart, cancel_final.dart); this is the glue both called.
library;

import '../cancel_final.dart' show CancelFinal;
import '../log.dart';
import '../models.dart';
import '../sender_cancel.dart' show SenderCancelRelease;
import '../stall_retry.dart' show StallRetry;
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

/// Posts again the payments the chain has not taken and sends again paid invoices' answers that
/// [retry]'s policy finds due at [now] (stall_retry.dart). True when one went, so the caller
/// reads the list again; a failure is logged under [tag] and answers false.
Future<bool> retryStalled(StallRetry retry, WalletSession session, List<TxEntry> transactions, DateTime now, {required String tag}) async {
  try {
    return await retry.run(session, transactions, now);
  } catch (error) {
    logWarn(tag, 'automatic retry failed: ${error.runtimeType}');
    return false;
  }
}

/// Releases the incoming payments their senders cancelled that still wait
/// (sender_cancel.dart). True when one was; a failure is logged under [tag], answers false and
/// goes again at the next call.
Future<bool> releaseSenderCancelled(SenderCancelRelease release, WalletSession session, Iterable<TxEntry> transactions, {required String tag}) async {
  try {
    return await release.run(session, transactions);
  } catch (error) {
    logWarn(tag, 'release of a cancelled payment failed: ${error.runtimeType}');
    return false;
  }
}

/// Spends back the coins of the cancelled payments whose spend back failed (cancel_final.dart);
/// nothing when none is owed. True when one went; a failure is logged under [tag] and answers
/// false.
Future<bool> retrySpendBack(CancelFinal cancels, WalletSession session, {required String tag}) async {
  if (!cancels.owed) return false;
  try {
    return await cancels.retry(session);
  } catch (error) {
    logWarn(tag, 'spend back of a cancelled payment failed: ${error.runtimeType}');
    return false;
  }
}
