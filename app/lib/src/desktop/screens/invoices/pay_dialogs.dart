// SPDX-License-Identifier: Apache-2.0
/// The payer's dialogs: approve with the wallet password,
/// decline, cancel a payment. Each reads its own [WidgetRef], so the screenshot tour and other
/// screens can open them with a [BuildContext] alone. Owned by the payer part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cancel_final.dart' show CancelResult;
import '../../../send_amount_gate.dart';
import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../../../help/help_content.dart' show HelpAnchor;
import '../wallet/cancel_note.dart';
import 'invoice_parts.dart';
import '../../app/routes.dart' show deskNoLock;

/// An invoice or request file of [amount] against the [spendable] balance ([SendAmountGate]):
/// the amount is fixed and the fee was estimated with it ([fee], null when it could not be), so
/// the balance decides. Approve is off until it is ready, and the dialog asks again on Pay.
SendAmountGate deskPayGate(int? spendable, {required int amount, int? fee}) => SendAmountGate.check(
  amount: amount,
  spendable: spendable,
  estimate: fee == null ? null : (amount: amount, fee: fee),
  needsEstimate: false,
);

/// Approve → password → pay. The only path to [DeskInvoices.pay]. On success the
/// app goes back to To pay with a toast. [shotPassword] fills and submits the field at once
/// (the screenshot tour's wrong-password state).
Future<void> showApproveInvoice(BuildContext context, IncomingInvoice invoice, {String? shotPassword}) async {
  final paid = await showEDialog<IncomingInvoice>(context, builder: (_) => _ApproveDialog(invoice: invoice, shotPassword: shotPassword));
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
  const _ApproveDialog({required this.invoice, this.shotPassword});

  final IncomingInvoice invoice;
  final String? shotPassword;

  @override
  ConsumerState<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends ConsumerState<_ApproveDialog> {
  final _password = TextEditingController(text: deskNoLock ? 'demo' : '');
  bool _busy = false;
  String? _fieldError;

  /// A refusal that ends the dialog's use: only Close remains.
  String? _final;

  /// A refusal that may pass (the node): Pay works again.
  String? _problem;

  @override
  void initState() {
    super.initState();
    final shot = widget.shotPassword;
    if (shot != null) {
      _password.text = shot;
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
    // Asked again on Pay: the balance may have moved since Approve.
    final i = widget.invoice;
    if (deskPayGate(ref.read(deskProvider).balance?.spendable, amount: i.amount, fee: i.feeKnown ? i.fee : null).notEnough) {
      setState(() => _problem = l.deskInvPayerShort);
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

/// Decline → confirm → decline → back to To pay with a toast.
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

/// Cancel payment: always the user's choice; LEPIC asks the node first. The service holds the
/// signed payment, so the cancel also spends its coins back to this wallet, which makes it
/// final (cancel_final.dart): one action, no extra step. [shotConfirm] presses Cancel payment
/// at once (the screenshot tour's error states).
Future<void> showCancelPaymentDialog(BuildContext context, IncomingInvoice invoice, {bool shotConfirm = false}) async {
  final done = await showEDialog<CancelResult>(context, builder: (_) => _CancelDialog(invoice: invoice, shotConfirm: shotConfirm));
  if (done == null || !context.mounted) return;
  final l = context.l10n;
  switch (done) {
    case CancelResult.spentBack:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpentText, tone: ETone.ok);
    case CancelResult.spendBackPending:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpendFailedText, tone: ETone.info);
    case CancelResult.stoppedWaiting:
      showEToast(context, l.cancelStoppedWaitingTitle, text: l.cancelStoppedWaitingText, tone: ETone.info);
    case CancelResult.cancelled:
      showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerCancelledText, tone: ETone.ok);
    case CancelResult.alreadyPaid:
      showEToast(context, l.errorPaymentAlreadyWentThrough, tone: ETone.info);
  }
}

class _CancelDialog extends ConsumerStatefulWidget {
  const _CancelDialog({required this.invoice, this.shotConfirm = false});

  final IncomingInvoice invoice;
  final bool shotConfirm;

  @override
  ConsumerState<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends ConsumerState<_CancelDialog> {
  bool _busy = false;
  String? _error;

  /// The node said it is on its way: nothing to cancel.
  bool _final = false;

  @override
  void initState() {
    super.initState();
    if (widget.shotConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cancel();
      });
    }
  }

  /// [spendBack] false is Stop waiting: the coins stay in place, nothing is owed.
  Future<void> _cancel({bool spendBack = true}) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final done = await ref.read(deskInvoicesProvider.notifier).cancelPayment(widget.invoice.slateId, spendBack: spendBack);
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
      tone: ETone.neutral,
      dismissible: !_busy,
      // One calm sentence, then the two ways to cancel, named as their buttons are.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.deskInvPayerCancelText, style: context.ts.body),
          SizedBox(height: Sp.x4),
          const DeskCancelChoices(anchor: HelpAnchor.requests),
          if (_error != null) ...[
            SizedBox(height: Sp.x3),
            ENotice(tone: ETone.risk, title: _error!),
          ],
        ],
      ),
      actions: _final
          ? [InvButton(label: l.deskInvPayerClose, onPressed: () => Navigator.of(context).pop())]
          : [
              InvButton(label: l.deskInvPayerKeepPayment, onPressed: _busy ? null : () => Navigator.of(context).pop()),
              InvButton(label: l.cancelUnlockOpen, onPressed: _busy ? null : () => _cancel(spendBack: false)),
              // Named by outcome (B-04); moving the coins back is the one primary.
              InvButton(label: l.cancelMoveBack, kind: EBtnKind.primary, busy: _busy, onPressed: _busy ? null : _cancel),
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

/// Approve on a payment request read from a file → password → pay and save the answer (DESIGN
/// §3.3). The only path to [DeskInvoices.payFile]. Returns the saved answer, or null when the
/// dialog closed without paying.
Future<ReceivedFile?> showApproveRequestFile(BuildContext context, RequestFile file) =>
    showEDialog<ReceivedFile>(context, builder: (_) => _ApproveFileDialog(file: file));

class _ApproveFileDialog extends ConsumerStatefulWidget {
  const _ApproveFileDialog({required this.file});

  final RequestFile file;

  @override
  ConsumerState<_ApproveFileDialog> createState() => _ApproveFileDialogState();
}

class _ApproveFileDialogState extends ConsumerState<_ApproveFileDialog> {
  final _password = TextEditingController(text: deskNoLock ? 'demo' : '');
  bool _busy = false;
  String? _fieldError;

  /// A refusal that ends the dialog's use: only Close remains.
  String? _final;

  /// A refusal that may pass (the node): Approve works again.
  String? _problem;

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
    // Asked again on Approve: the balance may have moved since the review.
    final f = widget.file;
    if (deskPayGate(ref.read(deskProvider).balance?.spendable, amount: f.amount, fee: f.feeKnown ? f.fee : null).notEnough) {
      setState(() => _problem = l.deskInvPayerShort);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _problem = null;
    });
    try {
      final saved = await ref.read(deskInvoicesProvider.notifier).payFile(widget.file, _password.text);
      if (mounted) Navigator.of(context).pop(saved);
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
            _final = l.reqFileEnded;
          case InvoiceProblem.alreadyAnswered:
            _final = l.reqFileAlreadyPaid;
          case InvoiceProblem.lockedAboveTip:
            _final = l.deskInvPayerLocked;
          default:
            _final = l.deskInvPayerCannotPay;
        }
      });
    } on DeskError catch (e) {
      // The payment stands; only the answer could not be written.
      if (mounted) {
        setState(() {
          _busy = false;
          _final = e.text(l);
        });
      }
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
    final f = widget.file;
    final reason = _final;
    final done = reason != null;
    return EDialog(
      title: l.reqApproveSaveAnswer,
      description: l.deskInvPayerApproveText(formatEpicL(l, f.feeKnown ? f.total : f.amount)),
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
