// SPDX-License-Identifier: Apache-2.0
/// Requests › To pay: the inbox of invoices from paired contacts the user allows and the payments to settle
///. Answered invoices leave it; paid ones live in Activity,
/// and one opened from there shows under Paid, selected. Owned by the payer part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust_ids.dart';
import '../../desk_l10n.dart';
import '../../../ui/pairing/pairing_parts.dart' show TrustBadge;
import '../../data/invoice_state.dart';
import '../../data/pairing_state.dart';
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
    // Opened from Activity: a paid invoice To pay no longer lists (one waiting to post, say).
    final opened = selected == null ? null : book.invoice(selected!);
    final paid = opened != null && !needs.any((i) => i.slateId == opened.slateId) && !waiting.any((i) => i.slateId == opened.slateId)
        ? opened
        : null;
    return ListView(
      padding: EdgeInsets.only(bottom: Sp.x6),
      children: [
        if (needs.isNotEmpty) ...[
          ESectionHead(l.deskInvPayerNeedsHead, top: 0),
          for (final i in needs) ...[
            InvReveal(selected: i.slateId == selected, child: _NeedsNotice(invoice: i, book: book, selected: i.slateId == selected)),
            SizedBox(height: Sp.x2),
          ],
          SizedBox(height: Sp.x4),
        ],
        if (paid != null) ...[
          ESectionHead(l.deskInvPayerPaidHead, top: 0),
          EPanel(
            padding: EdgeInsets.symmetric(vertical: Sp.x1),
            child: InvReveal(selected: true, child: _PaidRow(invoice: paid)),
          ),
          SizedBox(height: Sp.x4),
        ],
        if (waiting.isEmpty && needs.isEmpty && paid == null)
          EPanel(
            child: EEmpty(
              icon: EIcons.invoice,
              title: l.deskInvPayerEmptyTitle,
              text: l.deskInvPayerEmptyText,
              actions: [
                ELink(label: l.invoicesEmptyAction, onPressed: trust),
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
                  InvReveal(selected: i.slateId == selected, child: _WaitingRow(invoice: i, now: book.now, selected: i.slateId == selected)),
                ],
              ],
            ),
          ),
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
                    if (i.pairingId != null)
                      if (ref.watch(deskPairingByIdProvider(i.pairingId!)) case final p?) TrustBadge(p, short: true),
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
            semanticsId: TrustIds.invPayReview,
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
  const _NeedsNotice({required this.invoice, required this.book, this.selected = false});

  final IncomingInvoice invoice;
  final InvoiceBook book;

  /// Opened from Activity: outlined.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final i = invoice;
    final (title, text, tone) = switch (i.state) {
      PayState.notDelivered => (l.deskInvPayerNotDeliveredTitle(i.label), l.deskInvPayerNotDeliveredText, ETone.risk),
      PayState.stalled => (l.deskInvPayerStalledTitle(i.label), l.deskInvPayerStalledText, ETone.risk),
      PayState.withdrawnAfterPay => (l.deskInvPayerWithdrawnTitle(i.label), l.deskInvPayerWithdrawnText, ETone.warn),
      _ => (l.deskInvPayerPastTtlTitle(i.label), l.deskInvPayerPastTtlText, ETone.warn),
    };
    final notice = ENotice(
      tone: tone,
      title: title,
      text: text,
      actionsBelow: true,
      actions: [
        if (i.state == PayState.notDelivered)
          InvButton(label: l.invoiceRetry, kind: EBtnKind.primary, icon: EIcons.refresh, onPressed: () => retryPayment(context, i)),
        if (i.state == PayState.stalled)
          InvButton(label: l.deskTxSendAgain, kind: EBtnKind.primary, icon: EIcons.refresh, onPressed: () => retryPayment(context, i)),
        // A stalled payment may still be finished by the service: no cancel until its time passed.
        if (i.state.cancellable)
          InvButton(label: l.deskInvPayerCancelPayment, width: InvW.md, kind: EBtnKind.danger, onPressed: () => showCancelPaymentDialog(context, i)),
        if (i.txId != null)
          InvButton(label: l.deskInvPayerView, kind: EBtnKind.ghost, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, i.txId)),
      ],
    );
    if (!selected) return notice;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: context.dc.dim, width: 2),
      ),
      child: notice,
    );
  }
}

/// A paid invoice opened from Activity: who billed, where the payment stands, and View back to
/// its transaction.
class _PaidRow extends ConsumerWidget {
  const _PaidRow({required this.invoice});

  final IncomingInvoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final i = invoice;
    final line = cleanInvoiceText(i.message, max: invoiceLineMaxChars);
    return Container(
      color: c.s3,
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
      child: Row(
        children: [
          EAvatar(i.label),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.label, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  line.isEmpty ? l.deskInvPayerNoMessage : line,
                  style: ts.small.copyWith(color: line.isEmpty ? c.faint : c.dim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: Sp.x4),
          PayStateTag(i),
          SizedBox(width: Sp.x4),
          PayAmount(i.amount),
          if (i.txId != null) ...[
            SizedBox(width: Sp.x4),
            InvButton(label: l.deskInvPayerView, kind: EBtnKind.ghost, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, i.txId)),
          ],
        ],
      ),
    );
  }
}
