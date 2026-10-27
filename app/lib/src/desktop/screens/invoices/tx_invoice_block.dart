/// The Invoice block of a transaction's details (docs/invoices/flow.md §6): the request or the
/// invoice behind an invoice-flow transaction, where it stands, and its actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../../../help/help_content.dart' show HelpAnchor;
import '../wallet/cancel_note.dart';
import 'invoice_actions.dart';
import 'invoice_parts.dart';
import 'issuer_actions.dart';

class TxInvoiceBlock extends ConsumerWidget {
  const TxInvoiceBlock({super.key, required this.tx});

  final Tx tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final book = ref.watch(deskInvoicesProvider);
    if (!tx.isInvoice || book == null) return const SizedBox.shrink();
    final r = tx.incoming ? book.requestOfTx(tx.id) : null;
    final i = tx.incoming ? null : book.invoiceOfTx(tx.id);
    if (r == null && i == null) return const SizedBox.shrink();
    final slate = r?.slateId ?? i!.slateId;
    final String text;
    final List<Widget> actions;
    if (r != null) {
      final who = r.payerName ?? shortAddress(r.payerAddress, compact: true);
      text = switch (r.state) {
        RequestState.waiting => l.deskInvIssuerWaitingText(who),
        RequestState.paid || RequestState.confirming || RequestState.completed => l.deskInvIssuerPaidText(who),
        RequestState.notPosted => l.deskInvIssuerNotPostedText,
        RequestState.bounced => l.deskInvIssuerBounced(who),
        _ => l.deskInvIssuerEnded,
      };
      actions = [
        if (r.state == RequestState.waiting)
          InvButton(label: l.deskInvIssuerWithdraw, kind: EBtnKind.danger, width: InvW.md, onPressed: () => showWithdrawRequest(context, ref, r)),
        if (r.state == RequestState.notPosted)
          InvButton(label: l.deskInvIssuerRepost, kind: EBtnKind.primary, width: InvW.md, onPressed: () => repostRequestPayment(context, ref, r)),
      ];
    } else {
      final inv = i!;
      text = switch (inv.state) {
        PayState.notDelivered => l.invoiceDetailsReplyFailed(inv.label),
        PayState.delivered => l.invoiceDetailsReplied(inv.label),
        PayState.stalled => l.deskInvPayerStalledText,
        PayState.posted || PayState.confirming || PayState.completed => l.invoiceDetailsPosted(inv.label),
        PayState.withdrawnAfterPay => l.invoiceDetailsWithdrawn(inv.label),
        // A cancel is final only once these coins are spent again (P-3).
        PayState.cancelled => l.deskInvPayerCancelText,
        _ => payStateWord(context, inv, deskMinConfirmations(ref)).$1,
      };
      actions = [
        if (inv.state == PayState.notDelivered)
          InvButton(label: l.invoiceRetry, kind: EBtnKind.primary, width: InvW.md, onPressed: () => retryInvoicePayment(context, ref, inv)),
        // Delivered but never posted (linux-12): the stored reply goes again.
        if (inv.state == PayState.delivered || inv.state == PayState.stalled)
          InvButton(label: l.deskTxSendAgain, kind: EBtnKind.primary, width: InvW.md, onPressed: () => retryInvoicePayment(context, ref, inv)),
        if (inv.state.cancellable)
          InvButton(label: l.deskInvIssuerCancel, kind: EBtnKind.danger, width: InvW.md, onPressed: () => showCancelInvoicePayment(context, ref, inv)),
        if (inv.spendToSelf)
          InvButton(label: l.deskInvPayerSpendToSelf, kind: EBtnKind.primary, width: InvW.lg, onPressed: () => spendCancelledPayment(context, ref, inv)),
      ];
    }
    return Container(
      margin: EdgeInsets.only(top: Sp.x4),
      padding: EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(r != null ? EIcons.request : EIcons.invoice, size: Ctl.iconSm, color: c.dim),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvActBlock, style: ts.label)),
              if (r != null) RequestStateTag(r) else PayStateTag(i!),
            ],
          ),
          SizedBox(height: Sp.x3),
          Text(text, style: ts.body),
          if (i?.state == PayState.delivered) ...[
            SizedBox(height: Sp.x2),
            Text(l.invoiceDetailsRepliedHelp(i!.label), style: ts.small),
          ],
          if (i != null) ...[
            SizedBox(height: Sp.x3),
            EFacts(labelWidth: 96.u, [
              (l.deskInvActBilledBy, Text(i.label)),
              if ((i.message ?? '').isNotEmpty) (l.invoiceReviewMessageLabel(i.label), Text(cleanInvoiceText(i.message))),
            ]),
          ],
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...actions,
              // Opens the right tab with it selected: Issue for a request, Pay for an invoice
              // (under Paid when To pay no longer lists it).
              ELink(label: l.deskInvActOpen, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoices, slate)),
            ],
          ),
          // What Withdraw or Cancel does here, with the way to the Help topic (DeskCancelNote).
          if (r?.state == RequestState.waiting) ...[
            SizedBox(height: Sp.x2),
            DeskCancelNote(text: l.cancelNoteRequestWithdraw, anchor: HelpAnchor.requests),
          ] else if (i?.state.cancellable ?? false) ...[
            SizedBox(height: Sp.x2),
            DeskCancelNote(text: l.cancelNoteRequestPaid, anchor: HelpAnchor.requests),
          ],
        ],
      ),
    );
  }
}
