/// Issuer actions other screens call (Requests › Sent, Activity's Invoice block): withdraw a
/// waiting request, repost a finalized one, cancel one that was never posted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../../../help/help_content.dart' show HelpAnchor;
import '../wallet/cancel_note.dart';
import 'invoice_parts.dart';

String _payer(IssuedRequest r) => r.payerName ?? shortAddress(r.payerAddress, compact: true);

/// A yes/no question in the app's dialog; true when [confirm] was chosen.
Future<bool> _ask(BuildContext context, {required String title, required String body, required String confirm, required String keep, String? helpAnchor}) async {
  final ok = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: title,
      description: body,
      icon: EIcons.alert,
      tone: ETone.warn,
      body: helpAnchor == null ? null : DeskCancelNote(anchor: helpAnchor, inDialog: true),
      actions: [
        InvButton(label: keep, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(false)),
        InvButton(label: confirm, kind: EBtnKind.danger, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks, then withdraws a waiting request (flow.md §3.4).
Future<void> showWithdrawRequest(BuildContext context, WidgetRef ref, IssuedRequest request) async {
  final l = context.l10n;
  final yes = await _ask(
    context,
    title: l.deskInvIssuerWithdrawTitle,
    body: l.deskInvIssuerWithdrawBody(_payer(request)),
    confirm: l.deskInvIssuerWithdraw,
    keep: l.deskInvIssuerKeep,
    helpAnchor: HelpAnchor.requests,
  );
  if (!yes || !context.mounted) return;
  try {
    await ref.read(deskInvoicesProvider.notifier).withdraw(request.slateId);
    if (context.mounted) showEToast(context, l.deskInvIssuerWithdrawn, tone: ETone.neutral);
  } on Object {
    if (context.mounted) showEToast(context, l.deskInvFailed, tone: ETone.risk);
  }
}

/// Posts a [RequestState.notPosted] request's payment again.
Future<void> repostRequestPayment(BuildContext context, WidgetRef ref, IssuedRequest request) async {
  final l = context.l10n;
  try {
    await ref.read(deskInvoicesProvider.notifier).repost(request.slateId);
    if (context.mounted) showEToast(context, l.deskInvIssuerReposted, tone: ETone.ok);
  } on InvoiceError catch (e) {
    if (context.mounted) showEToast(context, e.problem == InvoiceProblem.nodeDown ? l.deskInvIssuerNodeDown : l.deskInvFailed, tone: ETone.risk);
  } on Object {
    if (context.mounted) showEToast(context, l.deskInvFailed, tone: ETone.risk);
  }
}

/// Asks, then cancels a paid request that was never posted (flow.md draft 2 §3.3, Advanced):
/// the payment will not arrive.
Future<void> showCancelRequestPayment(BuildContext context, WidgetRef ref, IssuedRequest request) async {
  final l = context.l10n;
  final yes = await _ask(
    context,
    title: l.deskInvIssuerCancelTitle,
    body: l.deskInvIssuerCancelBody(_payer(request)),
    confirm: l.deskInvIssuerCancel,
    keep: l.deskInvIssuerKeep,
  );
  if (!yes || !context.mounted) return;
  try {
    await ref.read(deskInvoicesProvider.notifier).cancelRequestPayment(request.slateId);
    if (context.mounted) showEToast(context, l.deskInvPayerCancelled, tone: ETone.neutral);
  } on InvoiceError catch (e) {
    if (!context.mounted) return;
    final text = switch (e.problem) {
      InvoiceProblem.onItsWay => l.deskInvPayerOnItsWay,
      InvoiceProblem.cannotCheck || InvoiceProblem.nodeDown => l.deskInvPayerCannotCheck,
      _ => l.deskInvFailed,
    };
    showEToast(context, text, tone: ETone.risk);
  } on Object {
    if (context.mounted) showEToast(context, l.deskInvFailed, tone: ETone.risk);
  }
}
