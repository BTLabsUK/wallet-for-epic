/// Requests › To pay: the inbox of invoices from trusted senders and the payments to settle
/// (docs/invoices/flow.md §4.2, §4.4, §4.5). Answered invoices leave it; paid ones live in Activity. Owned by the payer part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';
import 'pay_dialogs.dart';

class PayTab extends ConsumerWidget {
  const PayTab({super.key, required this.book, this.selected});

  final InvoiceBook book;

  /// A slate id to bring into view.
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final needs = book.needsAction;
    final waiting = book.waiting;
    void trust() => nav.go(DeskRoute.settingsInvoices);
    return ListView(
      padding: EdgeInsets.only(bottom: Sp.x6),
      children: [
        if (needs.isNotEmpty) ...[
          ESectionHead(l.deskInvPayerNeedsHead, top: 0),
          for (final i in needs) ...[_NeedsNotice(invoice: i, book: book), SizedBox(height: Sp.x2)],
          SizedBox(height: Sp.x4),
        ],
        if (waiting.isEmpty && needs.isEmpty)
          EPanel(
            child: EEmpty(
              icon: EIcons.invoice,
              title: l.deskInvPayerEmptyTitle,
              text: l.deskInvPayerEmptyText,
              actions: [
                ELink(label: l.deskInvPayerTrustService, onPressed: trust),
                ELink(label: l.deskInvPayerYourInvoiceAddress, onPressed: trust),
              ],
            ),
          )
        else if (waiting.isNotEmpty) ...[
          ESectionHead(l.deskInvPayerWaitingHead, top: 0),
          EPanel(
            padding: EdgeInsets.symmetric(vertical: Sp.x1),
            child: Column(
              children: [
                for (final (n, i) in waiting.indexed) ...[
                  if (n > 0) const EDivider(space: 0),
                  _WaitingRow(invoice: i, now: book.now, selected: i.slateId == selected),
                ],
              ],
            ),
          ),
        ],
        if (book.dropped > 0) ...[
          SizedBox(height: Sp.x3),
          _DroppedLine(count: book.dropped, onTrust: trust),
        ],
      ],
    );
  }
}

/// "−18.00000000 EPIC": an amount that leaves the wallet, never green, never "+".
class PayAmount extends StatelessWidget {
  const PayAmount(this.nano, {super.key, this.size = Fs.md, this.dim = false});

  final int nano;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final color = dim ? c.dim : c.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text('−', style: context.ts.mono(size: size, color: color, weight: FontWeight.w500))),
        EMoney(nano, size: size, color: color),
      ],
    );
  }
}

class _WaitingRow extends ConsumerWidget {
  const _WaitingRow({required this.invoice, required this.now, required this.selected});

  final IncomingInvoice invoice;
  final DateTime now;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final i = invoice;
    final line = cleanInvoiceText(i.message, max: invoiceLineMaxChars);
    return Container(
      color: selected ? c.s3 : null,
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
      child: Row(
        children: [
          EAvatar(i.label),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(i.label, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: Sp.x1),
                    Icon(EIcons.trusted, size: Ctl.iconSm, color: c.dim, semanticLabel: l.invoiceSettingsServicesTitle),
                  ],
                ),
                Text(
                  line.isEmpty ? l.deskInvPayerNoMessage : line,
                  style: ts.small.copyWith(color: line.isEmpty ? c.faint : c.dim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                InvCountdown(expiresAt: i.expiresAt, now: now),
              ],
            ),
          ),
          SizedBox(width: Sp.x4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.deskInvYouPay, style: ts.caption),
              PayAmount(i.amount),
            ],
          ),
          SizedBox(width: Sp.x4),
          InvButton(
            label: l.deskInvPayerReview,
            kind: EBtnKind.primary,
            onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoiceReview, i.slateId),
          ),
        ],
      ),
    );
  }
}

/// A payment the user must settle: Retry for one not delivered, Cancel payment for one the
/// service withdrew or that never reached the chain.
class _NeedsNotice extends ConsumerWidget {
  const _NeedsNotice({required this.invoice, required this.book});

  final IncomingInvoice invoice;
  final InvoiceBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final i = invoice;
    final (title, text, tone) = switch (i.state) {
      PayState.notDelivered => (l.deskInvPayerNotDeliveredTitle(i.label), l.deskInvPayerNotDeliveredText, ETone.risk),
      PayState.withdrawnAfterPay => (l.deskInvPayerWithdrawnTitle(i.label), l.deskInvPayerWithdrawnText, ETone.warn),
      _ => (l.deskInvPayerPastTtlTitle(i.label), l.deskInvPayerPastTtlText, ETone.warn),
    };
    return ENotice(
      tone: tone,
      title: title,
      text: text,
      actionsBelow: true,
      actions: [
        if (i.state == PayState.notDelivered)
          InvButton(label: l.invoiceRetry, kind: EBtnKind.primary, icon: EIcons.refresh, onPressed: () => retryPayment(context, i)),
        InvButton(label: l.deskInvPayerCancelPayment, width: InvW.md, onPressed: () => showCancelPaymentDialog(context, i)),
        if (i.txId != null)
          InvButton(label: l.deskInvPayerView, kind: EBtnKind.ghost, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, i.txId)),
      ],
    );
  }
}

class _DroppedLine extends StatelessWidget {
  const _DroppedLine({required this.count, required this.onTrust});

  final int count;
  final VoidCallback onTrust;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x1),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Sp.x2,
        children: [
          Icon(EIcons.shield, size: Ctl.iconSm, color: c.dim),
          Text(l.deskInvPayerDropped(count), style: context.ts.small),
          ELink(label: l.deskInvPayerTrustService, onPressed: onTrust),
        ],
      ),
    );
  }
}
