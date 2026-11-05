// SPDX-License-Identifier: Apache-2.0
/// Payment links on the desktop Send: the trust line under To, and the dialogs for a refused
/// link, a request paid before and a listing that changed wallet. The words and the checks are
/// the phone's (`ui/link_send.dart`); nothing here pays.
library;

import 'package:flutter/material.dart';

import '../../../name_service/name_service.dart';
import '../../../ui/link_send.dart' show linkTrustText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

const Key deskLinkTrustKey = ValueKey('send-link-trust');

/// Who the link's payee is and where it was listed, with the pictures of the listing code. The
/// changed-wallet sentence takes the warning tone, the others stay neutral.
class DeskLinkTrust extends StatelessWidget {
  const DeskLinkTrust({super.key, required this.link});

  final LinkOpened link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final changed = link.standing.trust == NameServiceTrust.changedWallet;
    return Semantics(
      container: true,
      child: ENotice(
        key: deskLinkTrustKey,
        title: linkTrustText(l, link),
        tone: changed ? ETone.warn : ETone.neutral,
        icon: changed ? Icons.warning_amber_rounded : EIcons.shield,
        below: Padding(
          padding: EdgeInsets.only(top: Sp.x2),
          child: Semantics(
            label: link.payeeLabel == null ? l.linkCodeLabelPlain : l.linkCodeLabel(link.payeeLabel!),
            child: Wrap(
              spacing: Sp.x2,
              children: [for (final w in codeWords(link.listingCode)) SasPicture(w, size: 24, excludeFromSemantics: true)],
            ),
          ),
        ),
      ),
    );
  }
}

/// A refused link: why, and the start of its text.
void showLinkRefusal(BuildContext context, String reason) => showEDialog<void>(
  context,
  builder: (ctx) => EDialog(
    key: const ValueKey('send-link-refused'),
    title: reason,
    icon: Icons.link_off,
    actions: [EButton.primary(label: ctx.l10n.commonClose, onPressed: () => Navigator.of(ctx).pop())],
  ),
);

/// A link whose payee is a contact that takes no payments: one dialog, OK.
void showLinkNoPayments(BuildContext context, String name) => showEDialog<void>(
  context,
  builder: (ctx) => EDialog(
    key: const ValueKey('send-link-no-payments'),
    title: ctx.l10n.linkNoPaymentsTitle,
    description: ctx.l10n.contactNoPaymentsNamed(name),
    icon: Icons.link_off,
    actions: [EButton.primary(label: ctx.l10n.commonOk, onPressed: () => Navigator.of(ctx).pop())],
  ),
);

/// "You paid this request on ‹date›": true when the user taps Pay again.
Future<bool> askPayAgain(BuildContext context, String date) async =>
    await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('send-link-paid'),
        title: ctx.l10n.linkPaidTitle,
        description: ctx.l10n.linkPaidBefore(date),
        icon: Icons.history,
        actions: [
          EButton(label: ctx.l10n.commonCancel, onPressed: () => Navigator.of(ctx).pop(false)),
          EButton.primary(key: const ValueKey('send-link-pay-again'), label: ctx.l10n.linkPayAgain, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    ) ??
    false;

/// The extra confirm before sending to a listing that changed wallet.
Future<bool> confirmChangedWalletDesk(BuildContext context, LinkOpened link) async =>
    await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('send-link-changed'),
        title: ctx.l10n.linkChangedConfirmTitle,
        description: linkTrustText(ctx.l10n, link),
        icon: Icons.warning_amber_rounded,
        tone: ETone.warn,
        actions: [
          EButton(label: ctx.l10n.commonCancel, onPressed: () => Navigator.of(ctx).pop(false)),
          EButton.primary(key: const ValueKey('send-link-changed-send'), label: ctx.l10n.homeSendButton, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    ) ??
    false;
