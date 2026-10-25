/// Invoices: invoices to pay and invoices issued, on two tabs (docs/invoices/flow.md §1). The
/// frame: tabs with their counts, Issue an invoice, the last check and the relay notice. The
/// wallet checks Epicbox by itself (on open and on a timer); there is no button for it.
/// The tabs' content is [PayTab] (payer part) and [IssueTab] (issuer part).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../app/tour.dart' show TourTarget;
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../settings/help_pairing.dart' show HelpAt;
import 'invoice_parts.dart';
import 'issue_tab.dart';
import 'pay_tab.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key, this.arg});

  /// A [InvoicesTab], or the slate id of a request or invoice to show.
  final Object? arg;

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  InvoicesTab? _tab;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    if (a is InvoicesTab) _tab = a;
    // Opening Requests asks the relay (flow.md §4.1).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(deskInvoicesProvider.notifier).check(quiet: true));
    });
  }

  @override
  void didUpdateWidget(InvoicesScreen old) {
    super.didUpdateWidget(old);
    if (widget.arg == old.arg) return;
    if (widget.arg is InvoicesTab) _tab = widget.arg! as InvoicesTab;
    if (widget.arg is String) _tab = null;
  }

  /// The tab a slate id belongs to; To pay when anything waits there, else Sent.
  InvoicesTab _tabFor(InvoiceBook book) {
    final a = widget.arg;
    if (a is String) {
      if (book.request(a) != null) return InvoicesTab.issue;
      if (book.invoice(a) != null) return InvoicesTab.pay;
    }
    if (book.attention == 0 && book.toPay.isEmpty && book.sent.isNotEmpty) return InvoicesTab.issue;
    return InvoicesTab.pay;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final book = ref.watch(deskInvoicesProvider);
    if (book == null) {
      return EPage(
        title: l.deskInvTitle,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Sp.x10),
          child: const Center(child: ESpinner()),
        ),
      );
    }
    final tab = _tab ?? _tabFor(book);
    final checking = book.check == InvoiceCheck.checking;
    final selected = widget.arg is String ? widget.arg! as String : null;
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (checking) ...[SizedBox.square(dimension: Ctl.iconSm, child: const ESpinner(size: 14)), SizedBox(width: Sp.x2)],
        Text(
          checking
              ? l.deskInvChecking
              : book.lastCheck == null
              ? ''
              : l.deskInvCheckedAt(invClock(context, book.lastCheck!)),
          style: ts.small.copyWith(color: c.dim),
        ),
      ],
    );
    return EPage(
      title: l.deskInvTitle,
      width: EPageWidth.full,
      scroll: false,
      actions: [
        InvButton(
          label: l.deskInvIssueAction,
          icon: EIcons.plus,
          kind: EBtnKind.primary,
          width: InvW.lg,
          onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoiceIssue),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // The tour's Invoices step points here (tour v2, id 'invoices-tabs').
              TourTarget(
                id: 'invoices-tabs',
                child: ESegmented<InvoicesTab>(
                  size: EBtnSize.md,
                  value: tab,
                  onChanged: (t) => setState(() => _tab = t),
                  segments: [
                    ESegment(InvoicesTab.pay, l.deskInvTabPay, icon: EIcons.invoice, count: book.attention == 0 ? null : book.attention),
                    ESegment(InvoicesTab.issue, l.deskInvTabIssue, icon: EIcons.request, count: book.openRequests.isEmpty ? null : book.openRequests.length),
                  ],
                ),
              ),
              SizedBox(width: Sp.x4),
              ELink(label: l.deskInvHowItWorks, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, const HelpAt('invoices'))),
              const Spacer(),
              Semantics(liveRegion: true, child: status),
            ],
          ),
          if (book.check == InvoiceCheck.failed) ...[
            SizedBox(height: Sp.x4),
            ENotice(tone: ETone.risk, icon: EIcons.alert, title: l.deskInvCheckFailedTitle, text: l.deskInvCheckFailedBody),
          ],
          SizedBox(height: Sp.x4),
          Expanded(
            child: switch (tab) {
              InvoicesTab.pay => PayTab(book: book, selected: selected),
              InvoicesTab.issue => IssueTab(book: book, selected: selected),
            },
          ),
        ],
      ),
    );
  }
}
