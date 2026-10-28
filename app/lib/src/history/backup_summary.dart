// SPDX-License-Identifier: Apache-2.0
/// The one summary a history backup import ends with, on the phone and the desktop:
/// "Restored: 12 payments, 5 notes, 2 pairings and settings."
library;

import '../l10n.dart';

/// What came back, joined in the reader's language; the "nothing new" sentence when nothing
/// did. [alreadyHere] records the wallet had already are told after it.
String backupRestoredText(
  AppLocalizations l, {
  int payments = 0,
  int notes = 0,
  int labels = 0,
  int contacts = 0,
  int stars = 0,
  int pairings = 0,
  int invoices = 0,
  bool settings = false,
  bool walletName = false,
  int alreadyHere = 0,
}) {
  final items = [
    if (payments > 0) l.backupRestoredPayments(payments),
    if (notes > 0) l.backupRestoredNotes(notes),
    if (labels > 0) l.backupRestoredLabels(labels),
    if (contacts > 0) l.backupRestoredContacts(contacts),
    if (stars > 0) l.backupRestoredStars(stars),
    if (pairings > 0) l.backupRestoredPairings(pairings),
    if (invoices > 0) l.backupRestoredInvoices(invoices),
    if (walletName) l.backupRestoredWalletName,
    if (settings) l.backupRestoredSettings,
  ];
  final head = items.isEmpty
      ? l.historyBackupImportNothingNew
      : l.backupRestoredSummary(
          items.length == 1
              ? items.single
              : '${items.sublist(0, items.length - 1).join(l.backupListSeparator)}'
                    '${l.backupListLastSeparator}${items.last}',
        );
  return alreadyHere > 0 && items.isNotEmpty ? '$head ${l.backupRestoredAlreadyHere(alreadyHere)}' : head;
}
