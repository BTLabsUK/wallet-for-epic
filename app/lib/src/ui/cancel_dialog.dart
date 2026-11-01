// SPDX-License-Identifier: Apache-2.0
/// The phone's cancel confirmations (WAL-20, 2026-10-30; calmer, B-04, 2026-11-01). the owner's
/// rule: cancelling is mostly a beginner's move, so the view is one calm sentence and clear
/// buttons named by what they do; the rest sits behind the "How cancelling works" link.
///
/// Two shapes. [showCancelChoices] is for a payment the other side could still finish (an
/// invoice this wallet paid, a send both wallets signed that the network refused, Release coins):
/// the sentence, a two-line comparison of the two ways, then the choices stacked: Move coins
/// back (with its fee, the one primary), Unlock coins, and the dismiss. [showPlainCancel] is for
/// a payment that cannot go through without this wallet: one free cancel, as before.
library;

import 'package:flutter/material.dart';

import '../amount.dart' show epicFor;
import '../cancel_choice.dart';
import '../help/help_content.dart';
import '../l10n.dart';
import '../text_join.dart' show keepNumbersWithUnits;
import 'app_dialog.dart';
import 'cancel_note.dart';
import 'theme/tokens.dart';

export '../cancel_choice.dart';

/// The info icon the cancel confirmations had beside the fee line (before B-04); kept for
/// callers, nothing draws it any more.
const Key cancelFeeHintKey = ValueKey('cancel-fee-hint');

/// The tile of every cancel confirmation (the desktop's EIcons.cancel).
const IconData cancelDialogIcon = Icons.block;

/// The three buttons (tests, the tour): Move coins back, Unlock coins, the dismiss.
const Key cancelForSureKey = ValueKey('cancel-for-sure');
const Key cancelStopWaitingKey = ValueKey('cancel-stop-waiting');
const Key cancelKeepKey = ValueKey('cancel-keep');

/// Move coins back / Unlock coins / Keep, for a payment the other side could still finish.
/// [body] is the one sentence that says so; [anchor] the Help heading the link opens
/// ([HelpAnchor]); [keepLabel] the dismiss ("Keep", "Keep waiting"); [fee] what moving the
/// coins back costs (`spendBackFeeOf` in cancel_final.dart), shown on its button when known. Closing the dialog is
/// [CancelChoice.keep].
Future<CancelChoice> showCancelChoices(
  BuildContext context, {
  required String title,
  required String body,
  required String anchor,
  required String keepLabel,
  BigInt? fee,
}) async {
  final choice = await showAppDialog<CancelChoice>(
    context,
    builder: (context) => _ChoicesDialog(title: title, body: body, anchor: anchor, keepLabel: keepLabel, fee: fee),
  );
  return choice ?? CancelChoice.keep;
}

/// Keep / the one cancel, for a payment that cannot go through without this wallet. True when
/// the user cancels.
Future<bool> showPlainCancel(
  BuildContext context, {
  required String title,
  required String body,
  required String anchor,
  required String keepLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showAppDialog<bool>(
    context,
    builder: (context) {
      final theme = Theme.of(context);
      return AppDialog(
        title: title,
        icon: cancelDialogIcon,
        body: CancelNote(
          text: body,
          anchor: anchor,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        // One destructive look: the cancelling choice in the outlined risk style, Keep the
        // shared outlined secondary.
        actions: [
          DialogButton.secondary(key: cancelKeepKey, label: keepLabel, onPressed: () => Navigator.pop(context, false)),
          DialogButton.risk(label: cancelLabel, onPressed: () => Navigator.pop(context, true)),
        ],
      );
    },
  );
  return confirmed ?? false;
}

class _ChoicesDialog extends StatelessWidget {
  const _ChoicesDialog({required this.title, required this.body, required this.anchor, required this.keepLabel, this.fee});

  final String title;
  final String body;
  final String anchor;
  final String keepLabel;
  final BigInt? fee;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final compare = theme.textTheme.bodyMedium!.copyWith(color: t.dim);
    final fee = this.fee;
    return AppDialog(
      title: title,
      icon: cancelDialogIcon,
      // The sentence, then the two ways side by side in two calm lines (B-04): no caption
      // under each button, no info icon; Help has the rest.
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: bodyStyle),
          const SizedBox(height: 16),
          Text(l.cancelCompareMoveBack, style: compare),
          const SizedBox(height: 4),
          CancelNote(text: l.cancelCompareUnlock, anchor: anchor, style: compare),
        ],
      ),
      // Named by outcome, full width so a long label never wraps beside another at 360 dp.
      // One primary: moving the coins back is the certain way, what Release and Cancel are
      // for; unlocking and the dismiss are the outlined secondaries.
      stackActions: true,
      actions: [
        DialogButton.primary(
          key: cancelForSureKey,
          label: fee == null ? l.cancelMoveBack : keepNumbersWithUnits(l.cancelMoveBackFee(epicFor(l, fee))),
          onPressed: () => Navigator.pop(context, CancelChoice.cancelForSure),
        ),
        DialogButton.secondary(
          key: cancelStopWaitingKey,
          label: l.cancelUnlockOpen,
          onPressed: () => Navigator.pop(context, CancelChoice.stopWaiting),
        ),
        DialogButton.secondary(
          key: cancelKeepKey,
          label: keepLabel,
          onPressed: () => Navigator.pop(context, CancelChoice.keep),
        ),
      ],
    );
  }
}
