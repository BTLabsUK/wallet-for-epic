// SPDX-License-Identifier: Apache-2.0
/// The phone's cancel confirmations (WAL-20, 2026-10-30). the owner's rule: cancelling is mostly
/// a beginner's move, so the default view is one calm sentence and clear buttons; everything
/// else sits behind the info icon and the "How cancelling works" link.
///
/// Two shapes. [showCancelChoices] is for a payment the other side could still finish (an
/// invoice this wallet paid, a send both wallets signed that the network refused, Release coins):
/// three choices stacked, the main one first with its fee line and the info icon, then the free
/// "Stop waiting" with its own line, then the dismiss. [showPlainCancel] is for a payment that
/// cannot go through without this wallet: one free cancel, as before.
library;

import 'package:flutter/material.dart';

import '../cancel_choice.dart';
import '../help/help_content.dart';
import '../l10n.dart';
import 'app_dialog.dart';
import 'cancel_note.dart';
import 'info_hint.dart';
import 'theme/tokens.dart';

export '../cancel_choice.dart';

/// The info icon beside the fee line of a cancel confirmation (tests, the tour).
const Key cancelFeeHintKey = ValueKey('cancel-fee-hint');

/// The tile of every cancel confirmation (the desktop's EIcons.cancel).
const IconData cancelDialogIcon = Icons.block;

/// The three buttons (tests, the tour).
const Key cancelForSureKey = ValueKey('cancel-for-sure');
const Key cancelStopWaitingKey = ValueKey('cancel-stop-waiting');
const Key cancelKeepKey = ValueKey('cancel-keep');

/// Keep / Stop waiting / Cancel for sure, for a payment the other side could still finish.
/// [body] is the one sentence that says so; [anchor] the Help heading the link opens
/// ([HelpAnchor]); [keepLabel] the dismiss ("Keep", "Keep waiting"). Closing the dialog is
/// [CancelChoice.keep].
Future<CancelChoice> showCancelChoices(
  BuildContext context, {
  required String title,
  required String body,
  required String anchor,
  required String keepLabel,
}) async {
  final choice = await showAppDialog<CancelChoice>(
    context,
    builder: (context) => _ChoicesDialog(title: title, body: body, anchor: anchor, keepLabel: keepLabel),
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
  const _ChoicesDialog({required this.title, required this.body, required this.anchor, required this.keepLabel});

  final String title;
  final String body;
  final String anchor;
  final String keepLabel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final line = theme.textTheme.bodySmall!.copyWith(color: t.dim);
    return AppDialog(
      title: title,
      icon: cancelDialogIcon,
      // The one sentence, and the way to Help; the buttons below say the rest.
      body: CancelNote(text: body, anchor: anchor, style: bodyStyle),
      // The choices stack, each with its own quiet line, so the fee belongs to the main
      // button alone and the free one reads free. Full width, so a long label (German,
      // Russian) never wraps beside another button at 360 dp.
      stackActions: true,
      actions: [
        DialogButton.risk(
          key: cancelForSureKey,
          label: l.cancelForSure,
          onPressed: () => Navigator.pop(context, CancelChoice.cancelForSure),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          // The fee line and, right beside it, the info icon: the two ways to cancel.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(l.cancelFeeLine, style: line)),
              InfoHint(
                l.cancelChoicesWhy,
                key: cancelFeeHintKey,
                title: l.cancelChoicesTitle,
                icon: Icons.info_outline,
              ),
            ],
          ),
        ),
        DialogButton.secondary(
          key: cancelStopWaitingKey,
          label: l.cancelStopWaiting,
          onPressed: () => Navigator.pop(context, CancelChoice.stopWaiting),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14, left: 2),
          child: Text(l.cancelStopWaitingLine, style: line),
        ),
        // Keep: the shared outlined secondary (#50), as in every dialog.
        DialogButton.secondary(
          key: cancelKeepKey,
          label: keepLabel,
          onPressed: () => Navigator.pop(context, CancelChoice.keep),
        ),
      ],
    );
  }
}
