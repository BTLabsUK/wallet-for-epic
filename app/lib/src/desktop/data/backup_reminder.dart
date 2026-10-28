/// The history backup reminder rule, for the desktop. A copy of the phone's, unchanged:
/// `historyReminderMinPayments`, `historyReminderPause`, `historyReminderQuiet`,
/// `unbackedPayments` and `paymentsNotInBackup` in `lib/src/ui/home_screen.dart`. The desktop
/// does not import a phone screen; when the rule moves to a shared pure-Dart file both import
/// it and this copy goes .
library;

import '../../settings.dart' show HistoryExportSnapshot;
import '../../wallet_service.dart' show TxEntry, TxSource, TxStatus;

/// The reminder shows only with at least this many payments not in a backup.
const int deskReminderMinPayments = 10;

/// How long the reminder stays away after the last export, the last "Not now", or (for a
/// wallet never exported nor dismissed) the first time it had something to remind of.
const Duration deskReminderPause = Duration(days: 30);

/// The reminder never shows while a payment this recent is in the list.
const Duration deskReminderQuiet = Duration(minutes: 10);

/// How many payments a history backup would keep that the last export ([exportedAt], Unix
/// seconds) does not have: newer than it, pending then and settled since, or with another
/// note ([snapshot]). Restored and imported rows are left out.
int deskUnbackedPayments(Iterable<TxEntry> txs, {int? exportedAt, HistoryExportSnapshot? snapshot}) {
  bool changed(TxEntry t) {
    if (exportedAt == null || t.timeUnix > exportedAt) return true;
    if (snapshot == null) return false;
    final settled = snapshot.pendingKeys.contains(t.key) && (t.status == TxStatus.confirmed || t.status == TxStatus.cancelled);
    return settled || snapshot.noteHashes[t.key] != HistoryExportSnapshot.noteHash(t.note);
  }

  return txs.where((t) => t.source == TxSource.wallet && changed(t)).length;
}

/// The count the reminder names, or null while it stays hidden: fewer than
/// [deskReminderMinPayments]; a wallet payment from the last [deskReminderQuiet]; or less than
/// [deskReminderPause] since the latest of [exportedAt], [dismissedAt] and [firstSeenAt] (Unix
/// seconds). With none of the three known it waits for [firstSeenAt] to be stored.
int? deskPaymentsNotInBackup(
  Iterable<TxEntry> txs, {
  required DateTime now,
  int? exportedAt,
  int? dismissedAt,
  int? firstSeenAt,
  HistoryExportSnapshot? snapshot,
}) {
  final n = deskUnbackedPayments(txs, exportedAt: exportedAt, snapshot: snapshot);
  if (n < deskReminderMinPayments) return null;
  final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
  final quietFrom = nowSeconds - deskReminderQuiet.inSeconds;
  if (txs.any((t) => t.source == TxSource.wallet && t.timeUnix > quietFrom)) return null;
  final marks = [exportedAt, dismissedAt, firstSeenAt].nonNulls;
  if (marks.isEmpty) return null;
  final since = marks.reduce((a, b) => a > b ? a : b);
  if (now.difference(DateTime.fromMillisecondsSinceEpoch(since * 1000)) < deskReminderPause) return null;
  return n;
}
