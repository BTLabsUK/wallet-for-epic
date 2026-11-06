// SPDX-License-Identifier: Apache-2.0
/// Overview's Requests card: what waits for the user and for others.
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
    Widget line(IconData icon, String text, {Widget? trailing, Color? color}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x1),
      child: Row(
        children: [
          Icon(icon, size: Ctl.iconSm, color: color ?? c.dim),
          SizedBox(width: Sp.x2),
          Expanded(child: Text(text, style: ts.body.copyWith(color: color ?? c.text))),
          ?trailing,
        ],
      ),
    );
    // Nothing waiting either way: the two lines and the button share one row, so the card
    // takes the room of a list row instead of a box around two "nothing" lines.
    final quiet = waiting.isEmpty && open.isEmpty && attention.isEmpty;
    final openButton = InvButton(label: l.deskInvActOpenInvoices, width: InvW.md, onPressed: () => nav.go(DeskRoute.invoices));
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4),
      child: EPanel(
        title: l.deskInvActOverviewTitle,
        padding: quiet ? EdgeInsets.symmetric(horizontal: Sp.panel, vertical: Sp.x3) : null,
        child: quiet
            ? LayoutBuilder(
                builder: (context, box) {
                  final lines = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      line(EIcons.invoice, l.deskInvActOverviewToPay(0)),
                      line(EIcons.request, l.deskInvActOverviewWaiting(0)),
                    ],
                  );
                  if (box.maxWidth < Lay.sm) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [lines, SizedBox(height: Sp.x3), openButton],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: lines),
                      SizedBox(width: Sp.x4),
                      openButton,
                    ],
                  );
                },
              )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(
              EIcons.invoice,
              l.deskInvActOverviewToPay(waiting.length),
              trailing: waiting.isEmpty
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        EMoney(-toPay, sign: true, unit: false, size: Fs.md, color: c.text),
                        Text(l.deskInvYouPay, style: ts.caption),
                      ],
                    ),
            ),
            line(EIcons.request, l.deskInvActOverviewWaiting(open.length)),
            if (attention.isNotEmpty) line(EIcons.alert, l.deskInvActOverviewAttention(attention.length), color: c.warn),
            SizedBox(height: Sp.x3),
            Align(
              alignment: Alignment.centerLeft,
              child: waiting.isNotEmpty || attention.isNotEmpty
                  ? InvButton(label: l.deskInvActReview, kind: EBtnKind.primary, width: InvW.md, onPressed: () => nav.go(DeskRoute.invoices, InvoicesTab.pay))
                  : openButton,
            ),
          ],
        ),
      ),
    );
  }
}
