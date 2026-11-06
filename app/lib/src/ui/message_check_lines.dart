// SPDX-License-Identifier: Apache-2.0
/// The lines the status places show for the wallet's message checks, on phone and desktop:
/// "Checking messages" while one runs, why the last one failed or when it was done, and what it
/// held or refused, the last two only when they are not zero.
library;

import '../../l10n/app_localizations.dart';
import '../l10n.dart' show localClock;
import '../message_checks.dart';

/// The lines for [check], in the order they show, with the time in [l]'s clock.
/// [showUnreadable] adds the count of messages that could not be read; it stays off until the
/// core reports that count.
List<String> messageCheckLines(AppLocalizations l, MessageCheck check, {bool showUnreadable = false}) {
  final o = check.outcome;
  return [
    if (check.checking)
      l.msgChecking
    else if (check.failed)
      l.msgCheckFailed
    else if (check.checkedAt != null)
      l.deskInvCheckedAt(localClock(l, check.checkedAt!.toLocal())),
    if (o.held > 0) l.msgCheckHeld(o.held),
    if (o.refused > 0) l.msgCheckRefused(o.refused),
    if (showUnreadable && o.unreadable > 0) l.msgCheckUnreadable(o.unreadable),
  ];
}
