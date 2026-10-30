// SPDX-License-Identifier: Apache-2.0
/// Requests › Sent: the requests this wallet sent and their states. A list and, beside it, the selected request; both panels share their edges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';
import 'issuer_actions.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;

class IssueTab extends ConsumerStatefulWidget {
  const IssueTab({super.key, required this.book, this.selected});

  final InvoiceBook book;

  /// A slate id to bring into view.
  final String? selected;

  @override
  ConsumerState<IssueTab> createState() => _IssueTabState();
}

/// Who a request went to: the contact's name, else the short address.
String payerOf(IssuedRequest r) => r.payerName ?? shortAddress(r.payerAddress, compact: true);

class _IssueTabState extends ConsumerState<IssueTab> {
  String? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.selected;
  }

  @override
  void didUpdateWidget(IssueTab old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected && widget.selected != null) _sel = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final sent = widget.book.sent;
    if (sent.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: EPanel(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Sp.x8),
            child: Column(
              children: [
                Icon(EIcons.request, size: 40.u, color: c.faint),
                SizedBox(height: Sp.x4),
                Text(l.deskInvIssuerEmpty, style: ts.bodyDim, textAlign: TextAlign.center),
                SizedBox(height: Sp.x5),
                InvButton(
                  label: l.deskInvIssueAction,
                  kind: EBtnKind.primary,
                  size: EBtnSize.md,
                  width: InvW.lg,
                  onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoiceIssue),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final selected = sent.where((r) => r.slateId == _sel).firstOrNull ?? sent.first;
    final list = _Frame(
      // Every row built, so the one opened from Activity can be scrolled to.
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final (i, r) in sent.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            InvReveal(
              selected: r.slateId == widget.selected,
              child: _Row(
                request: r,
                now: widget.book.now,
                selected: r.slateId == selected.slateId,
                onTap: () => setState(() => _sel = r.slateId),
              ),
            ),
          ],
        ],
      ),
    );
    final detail = _Frame(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Sp.x5),
        child: RequestDetail(request: selected, now: widget.book.now),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 860.u) {
          // One grid: the list and the detail share their top and bottom edges.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: list),
              SizedBox(width: Sp.x5),
              SizedBox(width: box.maxWidth >= 1400.u ? 460.u : 400.u, child: detail),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: list),
            SizedBox(height: Sp.x4),
            Expanded(flex: 3, child: detail),
          ],
        );
      },
    );
  }
}

/// A panel's frame without its padding: the list's rows run to its edges.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: child,
    );
  }
}

/// A request's amount: neutral with "Requested" until it is paid, then incoming.
class RequestAmount extends StatelessWidget {
  const RequestAmount(this.request, {super.key, this.size});

  final IssuedRequest request;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    // "+" and green only once the payment is in blocks; finalizing or unposted is not income yet.
    final paid = request.state == RequestState.confirming || request.state == RequestState.completed;
    final ended = request.state.endedUnpaid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        EMoney(request.amount, sign: paid, size: size ?? Fs.md, color: paid ? c.ok : (ended ? c.faint : c.text), weight: FontWeight.w600),
        if (!request.state.paidOut) Text(context.l10n.deskInvUnpaid, style: ts.caption.copyWith(color: c.dim)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.request, required this.now, required this.selected, required this.onTap});

  final IssuedRequest request;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final r = request;
    final line = cleanInvoiceText(r.message, max: invoiceLineMaxChars);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.s2 : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
            child: Row(
              children: [
                Container(
                  width: 36.u,
                  height: 36.u,
                  decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
                  child: Icon(EIcons.request, size: Ctl.iconSm, color: r.state.endedUnpaid ? c.faint : (r.state.paidOut ? c.txReceived : c.dim)),
                ),
                SizedBox(width: Sp.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            // A bare address: the full one on hover.
                            child: Builder(
                              builder: (context) {
                                final name = Text(r.byFile ? l.reqByFile : payerOf(r), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.body.copyWith(fontWeight: FontWeight.w600));
                                return r.payerName == null && r.payerAddress.isNotEmpty ? Tooltip(message: r.payerAddress, child: name) : name;
                              },
                            ),
                          ),
                          SizedBox(width: Sp.x2),
                          RequestStateTag(r),
                        ],
                      ),
                      SizedBox(height: 2.u),
                      Text(
                        [if (line.isNotEmpty) line, l.deskInvIssuerIssued(invWhen(context, r.issuedAt))].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.small.copyWith(color: c.dim),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sp.x4),
                SizedBox(
                  width: 150.u,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RequestAmount(r),
                      if (r.state == RequestState.waiting) InvCountdown(expiresAt: r.expiresAt, now: now, style: ts.caption.copyWith(color: c.dim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One request: what it asked, where it stands, and what can be done.
class RequestDetail extends ConsumerWidget {
  const RequestDetail({super.key, required this.request, required this.now});

  final IssuedRequest request;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final r = request;
    final technical = advancedHas(ref, AdvancedFeature.technicalDetails);
    // A request file has no payer: "Anyone with the file", and the file's own texts.
    final who = r.byFile ? l.reqToAnyone : payerOf(r);
    final (text, tone) = switch (r.state) {
      RequestState.waiting => (r.byFile ? l.reqFileLead : l.deskInvIssuerWaitingText(who), ETone.neutral),
      RequestState.paid || RequestState.confirming || RequestState.completed => (r.byFile ? l.deskFinPostedText : l.deskInvIssuerPaidText(who), ETone.ok),
      RequestState.notPosted => (l.deskInvIssuerNotPostedText, ETone.risk),
      RequestState.bounced => (l.deskInvIssuerBounced(who), ETone.warn),
      _ => (l.deskInvIssuerEnded, ETone.neutral),
    };
    final step = switch (r.state) {
      RequestState.waiting => 0,
      RequestState.paid || RequestState.notPosted => 1,
      RequestState.confirming => 2,
      RequestState.completed => 3,
      _ => -1,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(r.byFile ? l.deskInvIssuerToAnyone : l.deskInvIssuerTo(who), style: ts.h3)),
            SizedBox(width: Sp.x3),
            RequestStateTag(r),
          ],
        ),
        SizedBox(height: Sp.x4),
        Align(alignment: Alignment.centerLeft, child: _BigAmount(r)),
        SizedBox(height: Sp.x4),
        ENotice(
          tone: tone,
          icon: switch (tone) {
            ETone.ok => EIcons.okCircle,
            ETone.risk => EIcons.error,
            ETone.warn => EIcons.alert,
            _ => EIcons.info,
          },
          title: text,
        ),
        if (r.lateReplyRefused) ...[
          SizedBox(height: Sp.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EIcons.info, size: Ctl.iconSm, color: c.dim),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvIssuerLate, style: ts.small.copyWith(color: c.dim))),
            ],
          ),
        ],
        if (step >= 0) ...[SizedBox(height: Sp.x5), _Steps(step: step, confirmations: r.confirmations, needed: deskMinConfirmations(ref))],
        SizedBox(height: Sp.x5),
        EFacts(labelWidth: 96.u, [
          (l.deskInvIssuerPayerFact, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (r.byFile) Text(l.reqToAnyone), if (r.payerName != null) Text(r.payerName!), if (r.payerAddress.isNotEmpty) EMonoText(shortAddress(r.payerAddress, compact: true))])),
          if ((r.message ?? '').isNotEmpty) (l.deskInvIssuerMessageFact, Text(cleanInvoiceText(r.message))),
          (l.deskInvIssuerSentFact, Text(invWhen(context, r.issuedAt))),
          if (r.state == RequestState.waiting)
            (l.deskInvIssuerExpiresFact, InvCountdown(expiresAt: r.expiresAt, now: now, style: ts.body))
          else if (r.answeredAt != null)
            (l.deskInvIssuerAnsweredFact, Text(invWhen(context, r.answeredAt!))),
        ]),
        SizedBox(height: Sp.x5),
        Wrap(
          spacing: Sp.x3,
          runSpacing: Sp.x3,
          children: [
            if (r.state == RequestState.waiting)
              InvButton(label: l.deskInvIssuerWithdraw, kind: EBtnKind.danger, width: InvW.md, onPressed: () => showWithdrawRequest(context, ref, r)),
            if (r.state == RequestState.notPosted)
              InvButton(label: l.deskInvIssuerRepost, kind: EBtnKind.primary, width: InvW.md, onPressed: () => repostRequestPayment(context, ref, r)),
            if (r.state == RequestState.bounced) InvButton(label: l.deskInvIssuerSendFile, width: InvW.md, tooltip: l.deskInvIssuerSoon, onPressed: null),
          ],
        ),
        // Advanced › Technical details shows the slate id; Cancel payment, a recovery, always shows.
        if (technical || r.state == RequestState.notPosted) ...[
        SizedBox(height: Sp.x4),
        EDetails(
          title: l.deskInvAdvanced,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (technical)
              EFacts([
                (
                  l.deskInvSlateId,
                  Row(children: [Expanded(child: EMonoText(r.slateId)), ECopyButton(text: r.slateId, label: l.deskInvIssuerCopySlate)]),
                ),
              ]),
              if (r.state == RequestState.notPosted) ...[
                if (technical) SizedBox(height: Sp.x3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InvButton(label: l.deskInvIssuerCancel, kind: EBtnKind.danger, width: InvW.md, onPressed: () => showCancelRequestPayment(context, ref, r)),
                ),
              ],
            ],
          ),
        ),
        ],
      ],
    );
  }
}

class _BigAmount extends StatelessWidget {
  const _BigAmount(this.r);

  final IssuedRequest r;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final paid = r.state == RequestState.confirming || r.state == RequestState.completed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        EMoney(r.amount, sign: paid, size: Fs.h1, weight: FontWeight.w600, color: paid ? c.ok : (r.state.endedUnpaid ? c.faint : c.text)),
        if (!r.state.paidOut) ...[SizedBox(width: Sp.x3), Text(context.l10n.deskInvUnpaid, style: ts.small.copyWith(color: c.dim))],
      ],
    );
  }
}

/// Requested → Paid → Confirming → Completed, [step] reached.
class _Steps extends StatelessWidget {
  const _Steps({required this.step, required this.confirmations, required this.needed});

  final int step;
  final int confirmations;

  /// The wallet's minimum confirmations.
  final int needed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final names = [
      l.deskInvIssuerStepIssued,
      l.deskInvIssuerStepPaid,
      step == 2 ? l.deskInvConfirming(confirmations, needed) : l.deskInvIssuerStepConfirming,
      l.deskInvCompleted,
    ];
    return Row(
      children: [
        for (var i = 0; i < names.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2.u, color: i <= step ? c.ok : c.line)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reached steps are green; the one in progress (not the last) is the blue.
              Icon(i <= step ? EIcons.okCircle : EIcons.minusCircle, size: Ctl.iconSm, color: i < step || (i == step && step == names.length - 1) ? c.ok : (i == step ? c.info : c.faint)),
              SizedBox(height: Sp.x1),
              Text(names[i], style: ts.caption.copyWith(color: i <= step ? c.text : c.faint)),
            ],
          ),
        ],
      ],
    );
  }
}
