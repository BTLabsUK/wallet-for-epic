// SPDX-License-Identifier: Apache-2.0
/// Home's invoices strip: what waits for the user and for others, and nothing when nothing does.
/// Amounts to pay are outgoing ("You pay"), never income; requested amounts are not counted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

class OverviewInvoicesCard extends ConsumerWidget {
  const OverviewInvoicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final book = ref.watch(deskInvoicesProvider);
    if (book == null) return const SizedBox.shrink();
    final nav = ref.read(deskNavProvider.notifier);
    final waiting = book.waiting;
    final open = book.openRequests;
    final attention = book.needsAction;
    final toPay = waiting.fold<int>(0, (a, i) => a + i.amount);
    // Nothing waits either way: the Invoices tab says so and Home says nothing.
    if (waiting.isEmpty && open.isEmpty && attention.isEmpty) return const SizedBox.shrink();
    // What waits, the most pressing first: to pay, to look at, issued and not paid yet.
    final lines = [
      if (waiting.isNotEmpty) l.deskInvActOverviewToPay(waiting.length),
      if (attention.isNotEmpty) l.deskInvActOverviewAttention(attention.length),
      if (open.isNotEmpty) l.deskInvActOverviewWaiting(open.length),
    ];
    final act = waiting.isNotEmpty || attention.isNotEmpty;
    final button = act
        ? InvButton(label: l.deskInvActReview, kind: EBtnKind.primarySoft, width: InvW.md, onPressed: () => nav.go(DeskRoute.invoices, InvoicesTab.pay))
        : InvButton(label: l.deskInvActOpenInvoices, width: InvW.md, onPressed: () => nav.go(DeskRoute.invoices));
    final tile = Container(
      width: Ctl.sm,
      height: Ctl.sm,
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(Rad.sm)),
      child: Icon(EIcons.invoice, size: Ctl.icon, color: c.accentText),
    );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lines.first, style: ts.strong.copyWith(color: waiting.isEmpty && attention.isNotEmpty ? c.warn : c.text)),
        if (lines.length > 1) Text(metaLine(lines.skip(1).toList()), style: ts.small),
      ],
    );
    final amount = waiting.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              EMoney(-toPay, sign: true, unit: false, size: Fs.md, color: c.text),
              Text(l.deskInvYouPay, style: ts.caption),
            ],
          );
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4),
      child: Container(
        key: const ValueKey('home-invoices'),
        padding: EdgeInsets.fromLTRB(14.u, 10.u, Sp.x3, 10.u),
        decoration: BoxDecoration(color: c.s1, border: Border.all(color: act ? c.lineStrong : c.line), borderRadius: BorderRadius.circular(Rad.sm)),
        child: LayoutBuilder(
          builder: (context, box) {
            final head = Row(
              children: [
                tile,
                SizedBox(width: 14.u),
                Expanded(child: words),
                if (amount != null) ...[SizedBox(width: Sp.x4), amount],
              ],
            );
            // The button under the words where the strip is too narrow for it beside them.
            if (box.maxWidth < Lay.sm) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [head, SizedBox(height: Sp.x3), button]);
            }
            return Row(children: [Expanded(child: head), SizedBox(width: Sp.x4), button]);
          },
        ),
      ),
    );
  }
}
