// SPDX-License-Identifier: Apache-2.0
/// The two reminder cards Home can show under its slot: a history backup that is due, and sends
/// the recipient has not answered. Both are notices in the shell's own style; Home places them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import 'common.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart' show homeCardGap, paymentsNotInBackup, unbackedPayments;
import 'settings_history.dart' show exportHistoryBackup;
import 'tx_details_screen.dart';

/// Reminds the user to export a history backup, which a restore from the phrase cannot replace.
class HistoryBackupCard extends ConsumerWidget {
  const HistoryBackupCard({super.key, required this.chain, required this.transactions});

  final Chain chain;
  final List<TxEntry> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final exportedAt = settings.historyExportedAt[chain.name];
    final firstSeenAt = settings.historyReminderFirstSeenAt[chain.name];
    if (firstSeenAt == null &&
        unbackedPayments(
              transactions,
              exportedAt: exportedAt,
              snapshot: settings.historyExportSnapshots[chain.name],
            ) >
            0) {
      // The 30 days of a wallet with no export and no dismissal start here.
      final notifier = ref.read(appSettingsProvider.notifier);
      Future.microtask(() => notifier.markHistoryReminderSeen(chain, now));
    }
    final count = paymentsNotInBackup(
      transactions,
      now: now,
      exportedAt: exportedAt,
      dismissedAt: settings.historyReminderDismissedAt[chain.name],
      firstSeenAt: firstSeenAt,
      snapshot: settings.historyExportSnapshots[chain.name],
    );
    if (count == null) return const SizedBox.shrink();
    final l = context.l10n;
    // Before any export nothing is in a backup; after one, some payments may only have changed.
    final text = exportedAt == null
        ? l.homeHistoryNotBackedUp(count)
        : l.homeHistoryChangedSinceBackup(count);
    return Padding(
      padding: const EdgeInsets.only(top: homeCardGap),
      child: InlineNotice(
        level: NoticeLevel.warning,
        text: text,
        actions: [
          TextButton(
            onPressed: () => ref
                .read(appSettingsProvider.notifier)
                .dismissHistoryReminder(chain, now),
            child: Text(l.homeHistoryReminderNotNow),
          ),
          TextButton(
            onPressed: () => exportHistoryBackup(context, ref),
            child: Text(l.homeHistoryExportButton),
          ),
        ],
      ),
    );
  }
}

/// Sends the recipient has not answered yet, with what that means.
class PendingSendsCard extends ConsumerWidget {
  const PendingSendsCard({super.key, required this.transactions, required this.open});

  static final ButtonStyle _compact = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );

  final List<TxEntry> transactions;
  final Future<void> Function(Widget screen) open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = transactions
        .where(
          (t) =>
              // Another linked device's payment is that device's to follow, not this one's.
              t.status == TxStatus.awaitingRecipient && !isFromBackupUnknown(t) && t.origin != TxOrigin.linkedDevice,
        )
        .toList();
    if (waiting.isEmpty) return const SizedBox.shrink();
    final hidden = amountDisplay(ref).hidden;
    final total = waiting.fold(
      BigInt.zero,
      (sum, t) => sum + txAmount(t).amount,
    );
    final l = context.l10n;
    final count = waiting.length;
    return Padding(
      padding: const EdgeInsets.only(top: homeCardGap),
      // In progress, not a warning: the blue edge. One line; "Why is it waiting?" has the rest.
      child: InlineNotice(
        level: NoticeLevel.info,
        title: l.homePendingTitle(count),
        text: l.homePendingShort(shownEpic(l, total, hidden: hidden)),
        actions: [
                  TextButton(
                    style: _compact,
                    onPressed: () =>
                        openHelp(context, HelpId.send),
                    child: Text(l.homePendingWhy),
                  ),
                  TextButton(
                    style: _compact,
                    onPressed: () => open(
                      count == 1
                          ? TxDetailsScreen(txKey: waiting.single.key)
                          : const HistoryScreen(filter: HistoryFilter.pending),
                    ),
                    child: Text(l.homePendingView(count)),
                  ),
        ],
      ),
    );
  }
}
