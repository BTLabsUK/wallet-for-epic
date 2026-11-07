// SPDX-License-Identifier: Apache-2.0
/// Pieces every invoice screen shares: the three standard control
/// widths, the state words and tones of requests and invoices, and the countdown text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';

/// Buttons and dropdowns come in three widths, labels centred (a UI rule): [sm] for a
/// row's or a dialog's action, [md] for a page's main action and dropdowns, [lg] for a lone
/// call to action.
abstract final class InvW {
  static double get sm => 120.u;
  static double get md => 176.u;
  static double get lg => 240.u;
}

/// An [EButton] at one of the [InvW] widths, its label centred.
class InvButton extends StatelessWidget {
  const InvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.kind = EBtnKind.secondary,
    this.size = EBtnSize.sm,
    this.icon,
    this.busy = false,
    this.tooltip,
    this.semanticsId,
  });

  final String label;
  final VoidCallback? onPressed;

  /// One of [InvW], the least width; [InvW.sm] when null. A longer label (German, Russian)
  /// widens the button instead of being cut (LNX3-9).
  final double? width;
  final EBtnKind kind;
  final EBtnSize size;
  final IconData? icon;
  final bool busy;
  final String? tooltip;

  /// The test drivers' stable name for this control (`TrustIds`, lib/src/trust_ids.dart).
  final String? semanticsId;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: width ?? InvW.sm),
      child: EButton(semanticsId: semanticsId, label: label, onPressed: onPressed, kind: kind, size: size, icon: icon, busy: busy, expand: true, tooltip: tooltip),
    ),
  );
}

/// The state of a request this wallet sent, as a word and a tone, counting [needed]
/// confirmations (the wallet's). Never green before the payment is in: a waiting request is
/// not money.
(String, ETone) requestStateWord(BuildContext context, IssuedRequest r, int needed) {
  final l = context.l10n;
  return switch (r.state) {
    RequestState.waiting => (l.deskInvReqWaiting, ETone.neutral),
    RequestState.paid => (l.deskInvReqPaid, ETone.info),
    RequestState.confirming =>
      r.confirmations == 0 ? (l.deskInvReqPosted, ETone.info) : (l.deskInvConfirming(r.confirmations, needed), ETone.info),
    RequestState.completed => (l.deskInvCompleted, ETone.ok),
    RequestState.notPosted => (l.deskInvReqNotPosted, ETone.risk),
    RequestState.declined => (l.deskInvDeclined, ETone.warn),
    RequestState.expired => (l.deskInvExpired, ETone.neutral),
    RequestState.withdrawn => (l.deskInvWithdrawn, ETone.neutral),
    RequestState.bounced => (l.deskInvReqBounced, ETone.warn),
    RequestState.cancelled => (l.deskInvPayCancelled, ETone.neutral),
  };
}

/// The state of an invoice this wallet received, as a word and a tone, counting [needed]
/// confirmations (the wallet's).
(String, ETone) payStateWord(BuildContext context, IncomingInvoice i, int needed) {
  final l = context.l10n;
  return switch (i.state) {
    PayState.waiting => (l.deskInvPayWaiting, ETone.info),
    PayState.notDelivered => (l.deskInvPayNotDelivered, ETone.risk),
    PayState.delivered => (l.deskInvPayDelivered, ETone.neutral),
    PayState.stalled => (l.deskInvPayStalled, ETone.risk),
    PayState.posted => (l.deskInvPayPosted(i.label), ETone.neutral),
    PayState.confirming => (l.deskInvConfirming(i.confirmations, needed), ETone.neutral),
    PayState.completed => (l.deskInvCompleted, ETone.ok),
    PayState.withdrawnAfterPay => (l.deskInvPayWithdrawnAfterPay, ETone.warn),
    PayState.pastTtl => (l.deskInvPayPastTtl, ETone.warn),
    PayState.cancelled => (l.deskInvPayCancelled, ETone.neutral),
    PayState.declined => (l.deskInvDeclined, ETone.neutral),
    PayState.expired => (l.deskInvExpired, ETone.neutral),
    PayState.withdrawn => (l.deskInvWithdrawn, ETone.neutral),
  };
}

/// [requestStateWord] as a tag.
class RequestStateTag extends ConsumerWidget {
  const RequestStateTag(this.request, {super.key});

  final IssuedRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (word, tone) = requestStateWord(context, request, deskMinConfirmations(ref));
    return EBadge(word, tone: tone);
  }
}

/// [payStateWord] as a tag.
class PayStateTag extends ConsumerWidget {
  const PayStateTag(this.invoice, {super.key});

  final IncomingInvoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (word, tone) = payStateWord(context, invoice, deskMinConfirmations(ref));
    return EBadge(word, tone: tone);
  }
}

/// "3 h 10 min left", "12 min left", "Less than a minute left"; the phone's words.
String invTimeLeft(BuildContext context, Duration left) {
  final l = context.l10n;
  if (left.inMinutes < 1) return l.invoiceTimeLeftUnderMinute;
  if (left.inHours < 1) return l.invoiceTimeLeftMinutes(left.inMinutes);
  return l.invoiceTimeLeftHours(left.inHours, left.inMinutes % 60);
}

/// "22 Oct, 14:30" in the reader's language: an expiry or a check time.
String invWhen(BuildContext context, DateTime t) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMM, HH:mm', tag).format(t);
}

/// "14:30": a time today.
String invClock(BuildContext context, DateTime t) => DateFormat('HH:mm', Localizations.localeOf(context).toLanguageTag()).format(t);

/// A countdown that shows the absolute time on hover; [left] at [InvoiceBook.now].
class InvCountdown extends StatelessWidget {
  const InvCountdown({super.key, required this.expiresAt, required this.now, this.style});

  final DateTime expiresAt;
  final DateTime now;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final left = expiresAt.difference(now);
    final text = left.isNegative ? context.l10n.deskInvExpired : invTimeLeft(context, left);
    return ETip.value(
      context.l10n.deskInvExpiresAt(invWhen(context, expiresAt)),
      child: Text(text, style: style ?? context.ts.small.copyWith(color: left.inHours < 1 ? context.dc.warn : context.dc.dim)),
    );
  }
}

/// The invoice or request opened from Activity: scrolled into view once, marked selected.
class InvReveal extends StatefulWidget {
  const InvReveal({super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  State<InvReveal> createState() => _InvRevealState();
}

class _InvRevealState extends State<InvReveal> {
  @override
  void initState() {
    super.initState();
    if (widget.selected) _reveal();
  }

  @override
  void didUpdateWidget(InvReveal old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Scrollable.ensureVisible(context, alignment: 0.1, duration: reduce ? Duration.zero : const Duration(milliseconds: 220), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) => Semantics(selected: widget.selected, child: widget.child);
}

/// Why a received invoice can no longer be paid, naming who sent it.
String deskInvoiceEndedText(AppLocalizations l, IncomingInvoice i) => switch (i.state) {
  PayState.withdrawn => i.label.isEmpty ? l.invoiceNoticeWithdrawn : l.deskInvNoticeWithdrawn(i.label),
  PayState.expired || PayState.waiting => l.invoiceExpired,
  PayState.declined => l.deskInvPayerDeclinedText,
  _ when i.state.paid => l.deskInvPayerPaid,
  _ => l.invoiceGone,
};
