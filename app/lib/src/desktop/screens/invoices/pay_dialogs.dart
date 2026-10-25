/// The payer's dialogs (docs/invoices/flow.md §4.3, §4.4): approve with the wallet password,
/// decline, cancel a payment. Each reads its own [WidgetRef], so the screenshot tour and other
/// screens can open them with a [BuildContext] alone. Owned by the payer part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

/// Approve → password → pay (flow.md §4.3). The only path to [DeskInvoices.pay]. On success the
/// app goes back to To pay with a toast. [demoPassword] fills and submits the field at once
/// (the screenshot tour's wrong-password state).
Future<void> showApproveInvoice(BuildContext context, IncomingInvoice invoice, {String? demoPassword}) async {
  final paid = await showEDialog<IncomingInvoice>(context, builder: (_) => _ApproveDialog(invoice: invoice, demoPassword: demoPassword));
  if (paid == null || !context.mounted) return;
  final ref = ProviderScope.containerOf(context, listen: false);
  _afterPay(context, ref, paid);
}

void _afterPay(BuildContext context, ProviderContainer c, IncomingInvoice paid) {
  final l = context.l10n;
  if (c.read(deskNavProvider).route != DeskRoute.invoices) c.read(deskNavProvider.notifier).go(DeskRoute.invoices, InvoicesTab.pay);
  if (paid.state == PayState.notDelivered) {
    showEToast(context, l.deskInvPayerNotDeliveredToast, text: l.deskInvPayerNotDeliveredToastText, tone: ETone.risk);
  } else {
    showEToast(context, l.invoicePaidNotice(paid.label), tone: ETone.ok);
  }
}

class _ApproveDialog extends ConsumerStatefulWidget {
  const _ApproveDialog({required this.invoice, this.demoPassword});

  final IncomingInvoice invoice;
  final String? demoPassword;

  @override
  ConsumerState<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends ConsumerState<_ApproveDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _fieldError;

  /// A refusal that ends the dialog's use: only Close remains.
  String? _final;

  /// A refusal that may pass (the node): Pay works again.
  String? _problem;

  @override
  void initState() {
    super.initState();
    final demo = widget.demoPassword;
    if (demo != null) {
      _password.text = demo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pay();
      });
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    // Disabled on the first tap: a second tap (or Enter) cannot pay twice.
    if (_busy || _final != null) return;
    final l = context.l10n;
    if (_password.text.isEmpty) {
      setState(() => _fieldError = l.deskInvPayerEnterPassword);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _problem = null;
    });
    try {
      final paid = await ref.read(deskInvoicesProvider.notifier).pay(widget.invoice.slateId, amount: widget.invoice.amount, password: _password.text);
      if (mounted) Navigator.of(context).pop(paid);
    } on InvoiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        switch (e.problem) {
          case InvoiceProblem.wrongPassword:
            _fieldError = l.deskInvPayerWrongPassword;
          case InvoiceProblem.nodeDown:
            _problem = l.deskInvPayerNodeDownPay;
          case InvoiceProblem.expired:
            _final = l.invoiceExpired;
          case InvoiceProblem.alreadyAnswered:
            _final = l.deskInvPayerAlreadyAnswered;
          case InvoiceProblem.lockedAboveTip:
            _final = l.deskInvPayerLocked;
          // A reply the relay did not take comes back as a state; a thrown relay failure
          // came before anything was signed or stored.
          case InvoiceProblem.relayDown:
            _problem = l.deskInvPayerRelayDownPay;
          case InvoiceProblem.notDelivered:
            _problem = l.deskInvPayerNotDeliveredToastText;
          default:
            _final = l.deskInvPayerCannotPay;
        }
      });
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _final = l.deskInvPayerCannotPay;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final i = widget.invoice;
    // Withdrawn, expired or answered elsewhere while the dialog was open: nothing to pay.
    final live = ref.watch(deskInvoicesProvider)?.toPay.where((x) => x.slateId == i.slateId).firstOrNull;
    final ended = !_busy && _final == null && live != null && live.state != PayState.waiting ? deskInvoiceEndedText(l, live) : null;
    final reason = _final ?? ended;
    final done = reason != null;
    return EDialog(
      title: l.deskInvPayerApproveTitle(formatEpicL(l, i.amount), formatEpicL(l, i.fee), i.label),
      description: l.deskInvPayerApproveText(formatEpicL(l, i.total)),
      icon: EIcons.invoice,
      tone: ETone.gold,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            ENotice(tone: ETone.warn, title: reason)
          else
            EField(
              label: l.deskInvPayerPassword,
              error: _fieldError,
              reserveError: true,
              child: EPasswordInput(
                controller: _password,
                autofocus: true,
                invalid: _fieldError != null,
                semanticLabel: l.deskInvPayerPassword,
                onChanged: (_) {
                  if (_fieldError != null) setState(() => _fieldError = null);
                },
                onSubmitted: (_) => _pay(),
              ),
            ),
          if (_problem != null) ...[
            SizedBox(height: Sp.x3),
            ENotice(tone: ETone.risk, title: _problem!),
          ],
        ],
      ),
      actions: done
          ? [InvButton(label: l.deskInvPayerClose, onPressed: () => Navigator.of(context).pop())]
          : [
              InvButton(label: l.deskInvPayerCancel, onPressed: _busy ? null : () => Navigator.of(context).pop()),
              InvButton(label: l.deskInvPayerPay, kind: EBtnKind.primary, busy: _busy, onPressed: _busy ? null : _pay),
            ],
    );
  }
}

/// Decline → confirm → decline → back to To pay with a toast (flow.md §4.3).
Future<void> showDeclineInvoice(BuildContext context, IncomingInvoice invoice) async {
  final ok = await showEDialog<bool>(context, builder: (_) => _DeclineDialog(invoice: invoice));
  if (ok != true || !context.mounted) return;
  final c = ProviderScope.containerOf(context, listen: false);
  if (c.read(deskNavProvider).route != DeskRoute.invoices) c.read(deskNavProvider.notifier).go(DeskRoute.invoices, InvoicesTab.pay);
  showEToast(context, context.l10n.deskInvPayerDeclined, tone: ETone.neutral);
}

class _DeclineDialog extends ConsumerStatefulWidget {
  const _DeclineDialog({required this.invoice});

  final IncomingInvoice invoice;

  @override
  ConsumerState<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends ConsumerState<_DeclineDialog> {
  bool _busy = false;

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref.read(deskInvoicesProvider.notifier).decline(widget.invoice.slateId);
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: l.invoiceDeclineTitle,
      description: l.invoiceDeclineBody(widget.invoice.label),
      icon: EIcons.closeCircle,
      dismissible: !_busy,
      actions: [
        InvButton(label: l.invoiceDeclineKeep, onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        InvButton(label: l.invoiceDecline, kind: EBtnKind.danger, busy: _busy, onPressed: _busy ? null : _decline),
      ],
    );
  }
}

/// What a Cancel payment dialog ended with.
enum _Cancelled { no, cancelled, spent, spendFailed }

/// Cancel payment (flow.md §4.4, D-2): always the user's choice; LEPIC asks the node first.
/// "Spend them to myself now" then spends the unlocked coins to this wallet itself, which makes
/// the cancel final. [demoConfirm] presses Cancel payment at once (the screenshot tour's error
/// states).
Future<void> showCancelPaymentDialog(BuildContext context, IncomingInvoice invoice, {bool demoConfirm = false}) async {
  final done = await showEDialog<_Cancelled>(context, builder: (_) => _CancelDialog(invoice: invoice, demoConfirm: demoConfirm));
  if (done == null || done == _Cancelled.no || !context.mounted) return;
  final l = context.l10n;
  switch (done) {
    case _Cancelled.spent:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpentText, tone: ETone.ok);
    case _Cancelled.spendFailed:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpendFailedText, tone: ETone.warn);
    case _Cancelled.cancelled || _Cancelled.no:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerCancelledText, tone: ETone.ok);
  }
}

class _CancelDialog extends ConsumerStatefulWidget {
  const _CancelDialog({required this.invoice, this.demoConfirm = false});

  final IncomingInvoice invoice;
  final bool demoConfirm;

  @override
  ConsumerState<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends ConsumerState<_CancelDialog> {
  bool _busy = false;
  String? _error;

  /// Spend the unlocked coins to this wallet right after the cancel (D-2); off unless chosen,
  /// as it costs a fee.
  bool _spend = false;

  /// The node said it is on its way: nothing to cancel.
  bool _final = false;

  @override
  void initState() {
    super.initState();
    if (widget.demoConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cancel();
      });
    }
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invoices = ref.read(deskInvoicesProvider.notifier);
      await invoices.cancelPayment(widget.invoice.slateId);
      var done = _Cancelled.cancelled;
      if (_spend) {
        try {
          await invoices.spendToSelf(widget.invoice.slateId);
          done = _Cancelled.spent;
        } on Object {
          // The cancel stands; the toast says the coins did not move.
          done = _Cancelled.spendFailed;
        }
      }
      if (mounted) Navigator.of(context).pop(done);
    } on InvoiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _final = e.problem == InvoiceProblem.onItsWay;
        _error = switch (e.problem) {
          InvoiceProblem.onItsWay => l.deskInvPayerOnItsWay,
          _ => l.deskInvPayerCannotCheck,
        };
      });
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.deskInvPayerCannotCheck;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final i = widget.invoice;
    return EDialog(
      title: l.deskInvPayerCancelTitle,
      description: l.deskInvPayerCancelWho(formatEpicL(l, i.total), i.label),
      icon: EIcons.cancel,
      tone: ETone.warn,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ENotice(tone: ETone.warn, title: l.deskInvPayerCancelText),
          if (!_final) ...[
            SizedBox(height: Sp.x4),
            ECheckbox(value: _spend, onChanged: _busy ? (_) {} : (v) => setState(() => _spend = v), label: l.deskInvPayerSpendToSelf),
            Padding(
              padding: EdgeInsets.only(left: 28.u, top: Sp.x1),
              child: Text(l.deskInvPayerSpendToSelfHelp, style: context.ts.small.copyWith(color: context.dc.dim)),
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: Sp.x3),
            ENotice(tone: ETone.risk, title: _error!),
          ],
        ],
      ),
      actions: _final
          ? [InvButton(label: l.deskInvPayerClose, onPressed: () => Navigator.of(context).pop(_Cancelled.no))]
          : [
              InvButton(label: l.deskInvPayerKeepPayment, onPressed: _busy ? null : () => Navigator.of(context).pop(_Cancelled.no)),
              InvButton(label: l.deskInvPayerCancelPayment, width: InvW.md, kind: EBtnKind.danger, busy: _busy, onPressed: _busy ? null : _cancel),
            ],
    );
  }
}

/// Retry a [PayState.notDelivered] payment: sends the stored reply again, signs nothing.
Future<void> retryPayment(BuildContext context, IncomingInvoice invoice) async {
  final c = ProviderScope.containerOf(context, listen: false);
  final l = context.l10n;
  try {
    final i = await c.read(deskInvoicesProvider.notifier).retry(invoice.slateId);
    if (!context.mounted) return;
    if (i.state == PayState.notDelivered) {
      showEToast(context, l.deskInvPayerRetryFailed, text: l.deskInvPayerRetryFailedText, tone: ETone.risk);
    } else {
      showEToast(context, l.invoicePaidNotice(invoice.label), tone: ETone.ok);
    }
  } on Object {
    if (context.mounted) showEToast(context, l.deskInvPayerRetryFailed, text: l.deskInvPayerRetryFailedText, tone: ETone.risk);
  }
}
