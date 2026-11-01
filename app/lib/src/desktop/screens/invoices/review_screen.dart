// SPDX-License-Identifier: Apache-2.0
/// Review invoice: one invoice to pay or decline. The only way
/// to [DeskInvoices.pay]. Owned by the payer part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show localDayMonth;
import '../../desk_l10n.dart';
import '../../../ui/pairing/pairing_parts.dart' show ClaimedNameBadge, SealedBadge, TrustBadge;
import '../../data/invoice_state.dart';
import '../../data/pairing_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';
import 'pay_dialogs.dart';
import 'pay_tab.dart' show PayAmount;
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;

class InvoiceReviewScreen extends ConsumerWidget {
  const InvoiceReviewScreen({super.key, this.arg});

  /// The invoice's slate id.
  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final book = ref.watch(deskInvoicesProvider);
    void back() => ref.read(deskNavProvider.notifier).go(DeskRoute.invoices, InvoicesTab.pay);
    final invoice = arg is String ? book?.invoice(arg! as String) : null;
    if (book == null) {
      return EPage(
        title: l.reqTitle,
        onBack: back,
        child: Padding(padding: EdgeInsets.symmetric(vertical: Sp.x10), child: const Center(child: ESpinner())),
      );
    }
    if (invoice == null) {
      return EPage(
        title: l.reqTitle,
        onBack: back,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ENotice(title: l.invoiceGone),
            SizedBox(height: Sp.x6),
            InvButton(label: l.deskInvPayerBack, width: InvW.md, size: EBtnSize.md, onPressed: back),
          ],
        ),
      );
    }
    return EPage(
      title: l.reqTitle,
      onBack: back,
      child: _Review(invoice: invoice, book: book, onBack: back),
    );
  }
}

class _Review extends ConsumerWidget {
  const _Review({required this.invoice, required this.book, required this.onBack});

  final IncomingInvoice invoice;
  final InvoiceBook book;
  final VoidCallback onBack;

  /// "3 h 10 min" or "25 min".
  String _ago(BuildContext context, Duration d) {
    final l = context.l10n;
    if (d.inHours < 1) return l.deskInvPayerAgoMinutes(d.inMinutes);
    return d.inMinutes % 60 == 0 ? l.deskInvPayerAgoHoursOnly(d.inHours) : l.deskInvPayerAgoHours(d.inHours, d.inMinutes % 60);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final i = invoice;
    final balance = ref.watch(deskProvider.select((s) => s.balance));
    // Not ready as Send counts it: no answer, or the local node at height 0 still downloading.
    final nodeDown = ref.watch(
      deskProvider.select((st) {
        final s = st.status;
        if (s == null || (s.nodeHealth == ServiceHealth.slow && s.nodeHeight == 0)) return true;
        return s.nodeHealth != ServiceHealth.ok && s.nodeHealth != ServiceHealth.slow;
      }),
    );
    final spendable = balance?.spendable;
    final open = i.state == PayState.waiting && i.expiresAt.isAfter(book.now);
    final short = open && spendable != null && spendable < i.total;
    final same = open ? book.samePaidBefore(i) : null;
    final pairing = i.pairingId == null ? null : ref.watch(deskPairingByIdProvider(i.pairingId!));
    final message = cleanInvoiceText(i.message);

    // Why the invoice cannot be paid from here, read-only or blocked for now.
    final String? readOnly = open
        ? null
        : switch (i.state) {
            PayState.waiting => l.invoiceExpired,
            _ => deskInvoiceEndedText(l, i),
          };

    final amountPanel = EPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskInvYouPay, style: ts.small),
          SizedBox(height: Sp.x1),
          FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: PayAmount(i.amount, size: Fs.h1)),
          SizedBox(height: Sp.x4),
          EFacts([
            // No estimate (too little to spend): unknown, never a fee of 0.
            (l.deskInvPayerFee, i.feeKnown ? EMoney(i.fee, size: Fs.md) : Text('—', style: ts.mono(size: Fs.md, color: c.faint))),
            (l.deskInvPayerTotal, i.feeKnown ? PayAmount(i.total) : Text('—', style: ts.mono(size: Fs.md, color: c.faint))),
            if (spendable != null && open && (i.feeKnown || short))
              (
                l.deskInvPayerBalanceAfter,
                short
                    ? Text(l.deskInvPayerShort, style: ts.body.copyWith(color: c.risk))
                    : EMoney(spendable - i.total, size: Fs.md, color: c.dim),
              ),
          ]),
        ],
      ),
    );

    final messagePanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.invoiceReviewMessageLabel(i.label), style: ts.label),
        SizedBox(height: Sp.x2),
        Container(
          padding: EdgeInsets.all(Sp.x4),
          decoration: BoxDecoration(
            color: c.s1,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: c.lineStrong),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EIcons.note, size: Ctl.iconSm, color: c.faint),
              SizedBox(width: Sp.x3),
              Expanded(
                // Plain text only: never a link, never rich text.
                child: Text(message.isEmpty ? l.deskInvPayerNoMessage : message, style: ts.mono(size: Fs.sm, color: message.isEmpty ? c.faint : c.text)),
              ),
            ],
          ),
        ),
        SizedBox(height: Sp.x1),
        Text(l.deskInvPayerMessageCaption(i.label), style: ts.caption),
      ],
    );

    final facts = EPanel(
      child: EFacts([
        (
          l.deskInvPayerPaysTo,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A contact's request names the contact: its mailbox is never shown as an address
              // (RFC C-21).
              if (pairing != null)
                Text(i.label, style: ts.body, maxLines: 1, overflow: TextOverflow.ellipsis)
              else
                Row(
                  children: [
                    Flexible(
                      // Plain text, not EShortAddress: its LayoutBuilder has no intrinsic size, and
                      // the panel sits in an IntrinsicHeight row.
                      child: ETip.value(
                        i.senderAddress,
                        mono: true,
                        child: Semantics(
                          label: i.senderAddress,
                          excludeSemantics: true,
                          child: Text(shortAddress(i.senderAddress, compact: true), style: ts.mono(size: Fs.sm), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                    SizedBox(width: Sp.x2),
                    ECopyButton(text: i.senderAddress, label: l.deskInvPayerPaysTo),
                  ],
                ),
              // Sealed: it came through the contact's mailbox, sealed and signed by it.
              Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Sealed and signed only when it came from a pairing; its name is the
                  // contact's, or marked as chosen by the other side.
                  if (pairing != null) ...[
                    const SealedBadge(),
                    TrustBadge(pairing),
                    if (pairing.contactId == null) const ClaimedNameBadge(),
                    Text(
                      pairing.verifiedAt == null ? l.reqSealedSigned(i.label) : metaLine([l.reqSealedSigned(i.label), l.contactWordsChecked(localDayMonth(l, pairing.verifiedAt!))]),
                      style: ts.small,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // What the contact says it is for, as the phone shows it. Untrusted text.
        if (cleanInvoiceText(i.reference) case final reference when reference.isNotEmpty)
          (l.reqReference, Text(reference, style: ts.body, maxLines: 2, overflow: TextOverflow.ellipsis)),
        (l.deskInvPayerExpires, open ? InvCountdown(expiresAt: i.expiresAt, now: book.now, style: ts.body) : Text(invWhen(context, i.expiresAt))),
        if (advancedHas(ref, AdvancedFeature.technicalDetails)) (l.deskInvPayerLockHeight, Text(l.deskInvPayerLockNone)),
      ]),
    );

    final advanced = EDetails(
      title: l.deskInvAdvanced,
      child: EFacts([
        (l.deskInvSlateId, SelectableText(i.slateId, style: ts.mono(size: Fs.sm, color: c.dim))),
        (l.deskInvPayerReceived, Text(invWhen(context, i.receivedAt))),
      ]),
    );

    final blocked = short || nodeDown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EAvatar(i.label),
            SizedBox(width: Sp.x3),
            Expanded(child: Semantics(header: true, child: Text(l.invoiceReviewAsks(i.label), style: ts.h2))),
            if (!open) PayStateTag(i),
          ],
        ),
        SizedBox(height: Sp.x5),
        if (readOnly != null) ...[
          ENotice(tone: ETone.neutral, icon: EIcons.lock, title: readOnly),
          SizedBox(height: Sp.x4),
        ] else ...[
          ENotice(tone: ETone.warn, icon: EIcons.shield, title: l.deskInvPayerSafetyTitle, text: l.deskInvPayerSafetyText),
          SizedBox(height: Sp.x3),
          if (same != null) ...[
            ENotice(
              tone: ETone.risk,
              title: l.deskInvPayerSameBillTitle(i.label, _ago(context, book.now.difference(same.answeredAt ?? same.receivedAt))),
              text: l.deskInvPayerSameBillText,
            ),
            SizedBox(height: Sp.x3),
          ],
          // Why Approve is off, above the panels so it shows without scrolling.
          if (short) ...[
            ENotice(
              tone: ETone.risk,
              title: l.deskInvPayerShort,
              text: l.deskInvPayerShortText(formatEpicL(l, i.total), formatEpicL(l, spendable), deskMinConfirmations(ref)),
            ),
            SizedBox(height: Sp.x3),
          ],
          if (nodeDown) ...[
            ENotice(tone: ETone.risk, icon: EIcons.node, title: l.deskInvPayerNodeDownTitle, text: l.deskInvPayerNodeDownText),
            SizedBox(height: Sp.x3),
          ],
          SizedBox(height: Sp.x1),
        ],
        LayoutBuilder(
          builder: (context, box) => box.maxWidth < Lay.lg
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [amountPanel, SizedBox(height: Sp.x4), facts])
              // Side by side on one grid: both panels share their top and bottom edges.
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: amountPanel),
                      SizedBox(width: Sp.x4),
                      Expanded(child: facts),
                    ],
                  ),
                ),
        ),
        SizedBox(height: Sp.x5),
        messagePanel,
        SizedBox(height: Sp.x3),
        // Advanced › Technical details: the raw ids.
        if (advancedHas(ref, AdvancedFeature.technicalDetails)) advanced,
        SizedBox(height: Sp.x6),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Sp.x3,
          runSpacing: Sp.x3,
          children: open
              ? [
                  InvButton(label: l.invoiceDecline, width: InvW.md, size: EBtnSize.md, onPressed: () => showDeclineInvoice(context, i)),
                  InvButton(
                    label: l.invoiceApprove,
                    width: InvW.md,
                    size: EBtnSize.md,
                    kind: EBtnKind.primary,
                    tooltip: blocked ? (nodeDown ? l.deskInvPayerNodeDownTitle : l.deskInvPayerShort) : null,
                    onPressed: blocked ? null : () => showApproveInvoice(context, i),
                  ),
                ]
              : [
                  if (i.txId != null)
                    InvButton(label: l.deskInvPayerView, width: InvW.md, size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, i.txId)),
                  InvButton(label: l.deskInvPayerBack, width: InvW.md, size: EBtnSize.md, kind: EBtnKind.primary, onPressed: onBack),
                ],
        ),
      ],
    );
  }
}

/// The keys of the request file review, for tests.
const Key deskRequestFileWarnKey = ValueKey('desk-request-file-warn');
const Key deskRequestFileApproveKey = ValueKey('desk-request-file-approve');

/// Review request in its file form (DESIGN §3.3): a payment request read from a file, which
/// names nobody. A warn notice says so; the message box is the file's own text, cleaned.
/// Approve asks for the password, pays the amount shown and saves the answer
/// ([onAnswered]); Not now ([onNotNow]) pays, stores and sends nothing.
class RequestFileReview extends ConsumerWidget {
  const RequestFileReview({super.key, required this.file, required this.onAnswered, required this.onNotNow});

  final RequestFile file;
  final ValueChanged<ReceivedFile> onAnswered;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final f = file;
    final balance = ref.watch(deskProvider.select((s) => s.balance));
    // Not ready as Send counts it: no answer, or the local node at height 0 still downloading.
    final nodeDown = ref.watch(
      deskProvider.select((st) {
        final s = st.status;
        if (s == null || (s.nodeHealth == ServiceHealth.slow && s.nodeHeight == 0)) return true;
        return s.nodeHealth != ServiceHealth.ok && s.nodeHealth != ServiceHealth.slow;
      }),
    );
    final spendable = balance?.spendable;
    final open = !f.alreadyPaid;
    final short = open && spendable != null && spendable < f.total;
    final message = cleanInvoiceText(f.message);

    final amountPanel = EPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskInvYouPay, style: ts.small),
          SizedBox(height: Sp.x1),
          FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: PayAmount(f.amount, size: Fs.h1)),
          SizedBox(height: Sp.x4),
          EFacts([
            // No estimate (too little to spend): unknown, never a fee of 0.
            (l.deskInvPayerFee, f.feeKnown ? EMoney(f.fee, size: Fs.md) : Text('—', style: ts.mono(size: Fs.md, color: c.faint))),
            (l.deskInvPayerTotal, f.feeKnown ? PayAmount(f.total) : Text('—', style: ts.mono(size: Fs.md, color: c.faint))),
            if (spendable != null && open && (f.feeKnown || short))
              (
                l.deskInvPayerBalanceAfter,
                short
                    ? Text(l.deskInvPayerShort, style: ts.body.copyWith(color: c.risk))
                    : EMoney(spendable - f.total, size: Fs.md, color: c.dim),
              ),
          ]),
        ],
      ),
    );

    final messagePanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.reqFileMessageLabel, style: ts.label),
        SizedBox(height: Sp.x2),
        Container(
          padding: EdgeInsets.all(Sp.x4),
          decoration: BoxDecoration(
            color: c.s1,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: c.lineStrong),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EIcons.note, size: Ctl.iconSm, color: c.faint),
              SizedBox(width: Sp.x3),
              Expanded(
                // Plain text only: never a link, never rich text.
                child: Text(message.isEmpty ? l.deskInvPayerNoMessage : message, style: ts.mono(size: Fs.sm, color: message.isEmpty ? c.faint : c.text)),
              ),
            ],
          ),
        ),
      ],
    );

    final blocked = short || nodeDown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const ExcludeSemantics(child: _FileTile()),
            SizedBox(width: Sp.x3),
            Expanded(child: Semantics(header: true, child: Text(l.reqFromFileTitle, style: ts.h2))),
          ],
        ),
        SizedBox(height: Sp.x5),
        if (!open) ...[
          ENotice(tone: ETone.neutral, icon: EIcons.lock, title: l.reqFileAlreadyPaid),
          SizedBox(height: Sp.x4),
        ] else ...[
          ENotice(key: deskRequestFileWarnKey, tone: ETone.warn, icon: EIcons.shield, title: l.reqFromFileWarn),
          SizedBox(height: Sp.x3),
          ENotice(tone: ETone.warn, icon: EIcons.shield, title: l.deskInvPayerSafetyTitle, text: l.deskInvPayerSafetyText),
          SizedBox(height: Sp.x3),
          if (short) ...[
            ENotice(
              tone: ETone.risk,
              title: l.deskInvPayerShort,
              text: l.deskInvPayerShortText(formatEpicL(l, f.total), formatEpicL(l, spendable), deskMinConfirmations(ref)),
            ),
            SizedBox(height: Sp.x3),
          ],
          if (nodeDown) ...[
            ENotice(tone: ETone.risk, icon: EIcons.node, title: l.deskInvPayerNodeDownTitle, text: l.deskInvPayerNodeDownText),
            SizedBox(height: Sp.x3),
          ],
          SizedBox(height: Sp.x1),
        ],
        amountPanel,
        SizedBox(height: Sp.x5),
        messagePanel,
        if (advancedHas(ref, AdvancedFeature.technicalDetails)) ...[
          SizedBox(height: Sp.x3),
          EDetails(
            title: l.deskInvAdvanced,
            child: EFacts([(l.deskInvSlateId, SelectableText(f.slateId, style: ts.mono(size: Fs.sm, color: c.dim)))]),
          ),
        ],
        SizedBox(height: Sp.x6),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Sp.x3,
          runSpacing: Sp.x3,
          children: [
            InvButton(label: open ? l.reqNotNow : l.deskInvPayerBack, width: InvW.md, size: EBtnSize.md, onPressed: onNotNow),
            if (open)
              InvButton(
                key: deskRequestFileApproveKey,
                label: l.reqApproveSaveAnswer,
                width: InvW.lg,
                size: EBtnSize.md,
                kind: EBtnKind.primary,
                tooltip: blocked ? (nodeDown ? l.deskInvPayerNodeDownTitle : l.deskInvPayerShort) : null,
                onPressed: blocked
                    ? null
                    : () async {
                        final saved = await showApproveRequestFile(context, f);
                        if (saved != null) onAnswered(saved);
                      },
              ),
          ],
        ),
      ],
    );
  }
}

/// The file tile of a request read from a file, in place of the sender's avatar.
class _FileTile extends StatelessWidget {
  const _FileTile();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: 40.u,
      height: 40.u,
      decoration: c.well,
      child: Icon(EIcons.file, size: Ctl.icon, color: c.dim),
    );
  }
}
