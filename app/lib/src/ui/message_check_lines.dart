// SPDX-License-Identifier: Apache-2.0
/// The lines the status places show for the wallet's message checks, on phone and desktop:
/// "Checking messages" while one runs, why the last one failed or when it was done, and what it
/// read, held or refused, each only when it is not zero.
library;

import '../../l10n/app_localizations.dart';
import '../l10n.dart' show localClock;
import '../message_checks.dart';

/// The lines for [check], in the order they show, with the time in [l]'s clock.
List<String> messageCheckLines(AppLocalizations l, MessageCheck check) {
  final o = check.outcome;
  return [
    if (check.checking)
      l.msgChecking
    else if (check.failed)
      l.msgCheckFailed
    else if (check.checkedAt != null)
      l.deskInvCheckedAt(localClock(l, check.checkedAt!.toLocal())),
    if (o.messages > 0) l.msgCheckRead(o.messages),
    if (o.held > 0) l.msgCheckHeld(o.held),
    if (o.refused > 0) l.msgCheckRefused(o.refused),
    if (o.failed > 0) l.msgCheckPairingFailed(o.failed),
    if (o.unreadable > 0) l.msgCheckUnreadable(o.unreadable),
    if (o.capped > 0) l.msgCheckMore,
  ];
}
