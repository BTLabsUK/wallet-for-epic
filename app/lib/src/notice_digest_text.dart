// SPDX-License-Identifier: Apache-2.0
/// The words of a digest ([NoticeDigest]), for the phone and the desktop.
library;

import 'l10n.dart';
import 'notice_digest.dart';

/// "5 updates: 2 invoices, 1 withdrawal"; a single kind is its own count.
String noticeDigestText(AppLocalizations l, NoticeDigest digest) {
  final parts = [for (final e in digest.counts.entries) _part(l, e.key, e.value)].nonNulls;
  final list = parts.join(l.noticeDigestSeparator);
  return digest.counts.length == 1 ? list : l.noticeDigest(digest.total, list);
}

String? _part(AppLocalizations l, HeldKind kind, int count) => switch (kind) {
  HeldKind.invoice => l.noticeDigestInvoices(count),
  HeldKind.withdrawal => l.noticeDigestWithdrawals(count),
  HeldKind.paid => l.noticeDigestPaid(count),
  HeldKind.expired => l.noticeDigestExpired(count),
  HeldKind.withdrawn => l.noticeDigestWithdrawn(count),
  // Silent: they end a slate and are never counted.
  HeldKind.declined || HeldKind.cancelled => null,
};
