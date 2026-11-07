// SPDX-License-Identifier: Apache-2.0
/// The words of a digest ([NoticeDigest]), for the phone and the desktop: one line that counts
/// the updates, and the lines it unfolds into, one per kind, each with the place that lists
/// what it counts.
library;

import 'l10n.dart';
import 'notice_digest.dart';

/// "3 new updates": the folded line.
String noticeDigestText(AppLocalizations l, NoticeDigest digest) => l.noticeDigestNew(digest.total);

/// One line per kind of [digest]: "2 invoices", "1 withdrawal", "2 invoices paid".
typedef DigestItem = ({HeldKind kind, int count, String text, DigestPlace place});

/// The lines the digest unfolds into, in [HeldKind] order; a kind that is never counted
/// (declined, cancelled) has none. Each one's [DigestItem.place] is where a digest of that
/// kind alone opens.
List<DigestItem> noticeDigestItems(AppLocalizations l, NoticeDigest digest) => [
  for (final e in digest.counts.entries)
    if (_part(l, e.key, e.value) case final text?)
      (kind: e.key, count: e.value, text: text, place: NoticeDigest({e.key: e.value}).place),
];

String? _part(AppLocalizations l, HeldKind kind, int count) => switch (kind) {
  HeldKind.invoice => l.noticeDigestInvoices(count),
  HeldKind.withdrawal => l.noticeDigestWithdrawals(count),
  HeldKind.paid => l.noticeDigestPaid(count),
  HeldKind.expired => l.noticeDigestExpired(count),
  HeldKind.withdrawn => l.noticeDigestWithdrawn(count),
  // Silent: they end a slate and are never counted.
  HeldKind.declined || HeldKind.cancelled => null,
};
