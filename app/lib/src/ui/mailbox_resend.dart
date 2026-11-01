// SPDX-License-Identifier: Apache-2.0
/// A send through a paired contact's mailbox that nobody answered (`trust/contact_trust.dart`,
/// [mailboxResendOffer]): after 24 hours the details offer **Cancel and send by Epicbox**, which
/// cancels the waiting send through the ordinary cancel and starts an ordinary Epicbox send of
/// the same amount to the contact's address, after one confirm. At 7 days the relay has dropped
/// the message: the line says so and Cancel is the main action.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../trust/contact_trust.dart';
import 'badge.dart' show BadgeTone;
import 'pairing/pairing_parts.dart' show PairEdgeNotice;

/// Keys for tests.
const Key txDetailsResendKey = ValueKey('tx-details-resend-epicbox');
const Key txDetailsKeepWaitingKey = ValueKey('tx-details-keep-waiting');
const Key mailboxResendConfirmKey = ValueKey('mailbox-resend-confirm');
const Key mailboxResendCardKey = ValueKey('mailbox-resend-card');

/// The one confirm before Cancel and send by Epicbox. True when the user chose it.
Future<bool> confirmCancelAndSendByEpicbox(BuildContext context, String name) async {
  final l = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.mailboxResendTitle),
      content: Text(l.mailboxResendBody(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.mailboxKeepWaiting)),
        FilledButton(
          key: mailboxResendConfirmKey,
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.mailboxResendAction),
        ),
      ],
    ),
  );
  return sure ?? false;
}

/// The notice on the details of an unanswered mailbox send: its stage as the title, the
/// 7-day line, and the actions the stage calls for. [onResend] null when the contact has no
/// Epicbox address: the facts and nothing else. [onKeepWaiting] closes the details.
class MailboxResendCard extends StatelessWidget {
  const MailboxResendCard({
    super.key,
    required this.offer,
    required this.name,
    required this.busy,
    required this.onResend,
    required this.onKeepWaiting,
  });

  final MailboxResendOffer offer;
  final String name;
  final bool busy;
  final VoidCallback? onResend;
  final VoidCallback onKeepWaiting;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final resend = onResend;
    return PairEdgeNotice(
      key: mailboxResendCardKey,
      tone: BadgeTone.warn,
      title: offer.gone ? l.mailboxNotPickedUp : l.mailboxNotAnswered,
      body: offer.gone ? l.mailboxNeverPickedUp(name) : null,
      stretchActions: offer.resendPrimary,
      actions: [
        if (resend != null && offer.resendPrimary) ...[
          FilledButton(key: txDetailsResendKey, onPressed: busy ? null : resend, child: Text(l.mailboxResendTitle)),
          TextButton(key: txDetailsKeepWaitingKey, onPressed: onKeepWaiting, child: Text(l.mailboxKeepWaiting)),
        ] else if (resend != null)
          // At 7 days Cancel (below) is the main action; this one stays second.
          OutlinedButton(key: txDetailsResendKey, onPressed: busy ? null : resend, child: Text(l.mailboxResendTitle)),
      ],
    );
  }
}
