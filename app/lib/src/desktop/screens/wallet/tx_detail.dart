import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../known_relays.dart' show recipientRelay;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../invoices/tx_invoice_block.dart';
import 'tx_details_dialog.dart';
import 'tx_display.dart';
import 'tx_label.dart';

/// One transaction: amount and counterparty, where it stands, its progress, details, proof,
/// technical details and the actions it allows (cancel, finalize).
class TxDetail extends ConsumerStatefulWidget {
  const TxDetail({super.key, required this.tx, this.showTitle = false});

  final Tx tx;

  /// Starts with the title (the label's field), for a layout whose page title is a plain string.
  final bool showTitle;

  @override
  ConsumerState<TxDetail> createState() => _TxDetailState();
}

class _TxDetailState extends ConsumerState<TxDetail> {
  bool _cancelling = false;

  String _now(AppLocalizations l, Tx t) => t.fromBackup
      ? l.deskTxNowBackup
      : t.immature
      ? l.deskTxNowImmature(coinbaseMaturity)
      : switch (t.state) {
          TxState.waitingRecipient when t.undelivered => switch ((t.method, recipientRelay(t.counterparty ?? ''))) {
            (TxMethod.http, _) => l.deskTxNowUndeliveredDirect('HTTP'), // l10n-ok: the method's name
            (TxMethod.tor, _) => l.deskTxNowUndeliveredDirect('Tor'), // l10n-ok: the method's name
            (TxMethod.epicbox, final relay?) => l.deskTxNowUndeliveredRelay(relay.label),
            _ => l.deskTxNowUndelivered,
          },
          TxState.waitingRecipient =>
            t.incoming
                ? l.deskTxNowWaitingSender
                : t.method == TxMethod.file
                ? l.deskTxNowWaitingResponseFile
                : l.deskTxNowWaitingRecipient,
          TxState.posted when t.notPosted => l.deskTxNowNotPosted,
          TxState.posted => l.deskTxNowPosted,
          TxState.confirming => l.deskTxNowConfirming(t.confirmations, t.confirmationsNeeded),
          TxState.confirmed => l.deskTxNowConfirmed(t.confirmations),
          TxState.cancelled => l.deskTxNowCancelled,
        };

  Future<void> _sendAgain() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).resendTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, context.l10n.deskTxNotSent, text: deskErrorText(e, context.l10n));
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, context.l10n.deskTxSentAgain, text: context.l10n.deskTxSentAgainText);
  }

  Future<void> _broadcastAgain() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).repostTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, context.l10n.deskTxNotSent, text: deskErrorText(e, context.l10n));
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, context.l10n.deskTxBroadcastDone);
  }

  Future<void> _cancel() async {
    final ok = await showCancelTxDialog(context, widget.tx);
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, context.l10n.deskTxNotCancelled, text: deskErrorText(e, context.l10n));
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, context.l10n.deskTxCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final t = widget.tx;
    final total = t.amount + (t.incoming ? 0 : t.fee);
    // A send can be cancelled while it waits for the recipient, or when the node refused its
    // post (its outputs stay locked otherwise). Once posted (a Direct HTTP or Tor send is
    // finalized and posted in one step) it has gone out and shows as sent, never cancellable.
    // Invoice-flow transactions take their actions from the Invoice block (flow.md §4.4).
    final cancelable = !t.fromBackup &&
        !t.isInvoice &&
        (t.incoming
            ? t.cancellable && t.state != TxState.cancelled && t.state != TxState.confirmed
            : (t.cancellable && t.state == TxState.waitingRecipient) || t.notPosted);
    final finalizable = !t.fromBackup && !t.incoming && !t.isInvoice && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    // The node refused it: broadcast it again at once (android-17); the app also does by itself.
    final repostable = !t.fromBackup && !t.isInvoice && t.notPosted;
    final steps = _steps(l, t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTitle) ...[
          TxPanelTitle(tx: t, fallback: t.isInvoice ? l.deskInvActBlock : (t.incoming ? l.deskActDetailReceived : l.deskActDetailSent)),
          SizedBox(height: Sp.x4),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TxIcon(t, size: 44.u),
            SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitMoney(
                    t.incoming ? t.amount : -t.amount,
                    sign: !txAsked(t),
                    sizes: const [Fs.h2, Fs.h3, Fs.lg, Fs.md],
                    weight: FontWeight.w500,
                    color: t.state == TxState.cancelled ? c.txCancelled : (txAsked(t) ? c.text : (t.incoming ? c.txReceived : c.txSent)),
                  ),
                  // Not money yet: the row's caption, by the big amount too (P-1).
                  if (txAsked(t) && t.state == TxState.waitingRecipient) Text(context.l10n.deskInvUnpaid, style: ts.caption),
                  const SizedBox(height: 2),
                  if (t.foundByScan && t.contactName == null)
                    Text(t.foundDuring == FoundDuring.restore ? l.deskTxHeadRestored : l.deskTxHeadFoundOnChain, style: ts.small)
                  else if (t.fromBackup && t.counterparty == null)
                    Text(l.deskTxHeadBackup, style: ts.small)
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          // The name sits in its own style: split the sentence at a marker.
                          for (final (i, part) in (t.incoming ? l.deskTxHeadFrom('\u0001') : l.deskTxHeadTo('\u0001')).split('\u0001').indexed) ...[
                            if (i > 0)
                              TextSpan(
                                text: whoOf(l, t),
                                style: whoIsAddress(t) ? ts.mono(size: Fs.xs, color: c.text) : TextStyle(color: c.text),
                              ),
                            TextSpan(text: part),
                          ],
                        ],
                      ),
                      style: ts.small,
                    ),
                  if (whoTip(l, t) != null && !(t.fromBackup && t.counterparty == null)) ...[const SizedBox(height: 2), Text(whoTip(l, t)!, style: ts.small.copyWith(color: c.faint))],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x4),
        if (!t.isInvoice)
        Container(
          padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 10.u),
          decoration: BoxDecoration(
            color: c.s2,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              TxStateMark(t),
              SizedBox(width: Sp.x3),
              Expanded(child: Text(_now(l, t), style: ts.body)),
            ],
          ),
        ),
        // An invoice-flow transaction: the invoice behind it, in the Invoices page's words.
        if (t.isInvoice) TxInvoiceBlock(tx: t),
        if (t.state != TxState.cancelled && !t.fromBackup && !t.isInvoice) ...[_Sub(l.deskTxSubProgress), for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1)],
        _SubBar(
          l.deskTxSubDetails,
          [
            if (t.restored)
              EButton(
                label: _typed(t) ? l.deskTxDetailsEdit : l.deskTxDetailsAdd,
                icon: _typed(t) ? EIcons.pencil : EIcons.plus,
                kind: EBtnKind.ghost,
                size: EBtnSize.inline,
                onPressed: () => showTxDetailsDialog(context, t),
              ),
            EButton(
              label: t.labelText == null ? l.deskTxLabelAdd : l.deskTxLabelEdit,
              icon: EIcons.pencil,
              kind: EBtnKind.ghost,
              size: EBtnSize.inline,
              onPressed: () => ref.read(txLabelEditingProvider.notifier).open(t.key, txLabelDetailPlace),
            ),
          ],
        ),
        EFacts(labelWidth: 96.u, [
          (l.deskTxFactDate, Text(dateTimeOf(l, t))),
          if (t.counterparty != null)
            (
              t.incoming ? l.deskTxFactFrom : l.deskTxFactTo,
              _withTag(
                t,
                ManualField.counterparty,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.counterparty!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ts.mono(size: Fs.xs),
                      ),
                    ),
                    ECopyButton(text: t.counterparty!, label: l.deskTxCopyAddress),
                  ],
                ),
              ),
            ),
          (
            l.deskTxFactMethod,
            t.foundByScan
                ? _withTag(t, ManualField.transport, Text(restoredMethodOf(l, t) ?? '–'))
                : Text(methodLabel(l, t.method)),
          ),
          (l.deskTxFactAmount, EMoney(t.amount)),
          if (!t.incoming) ...[(l.deskTxFactFee, EMoney(t.fee)), (l.deskTxFactTotal, EMoney(total, weight: FontWeight.w600))],
          if (t.message != null) (l.deskTxFactMessage, Text(t.message!)),
          if (t.note != null && t.note!.trim().isNotEmpty) (l.deskTxDetailsNote, _withTag(t, ManualField.note, Text(t.note!))),
        ]),
        if (DeskFeatures.paymentProofs && t.hasProof) ...[
          _Sub(l.deskTxPaymentProof),
          Row(
            children: [
              Icon(EIcons.proof, size: Ctl.iconSm, color: c.ok),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskTxSignedByRecipient, style: ts.small)),
              EButton(label: l.deskTxProofView, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => showTxProofDialog(context, t)),
            ],
          ),
        ],
        SizedBox(height: Sp.x5),
        EDetails(
          title: l.deskTxTechTitle,
          child: EFacts(labelWidth: 96.u, [
            (l.deskTxTechId, Text('${t.id}', style: ts.mono(size: Fs.xs))),
            (
              l.deskTxTechSlate,
              Row(
                children: [
                  Expanded(
                    child: Text(t.slateId.isEmpty ? '-' : t.slateId, style: ts.mono(size: Fs.xs)),
                  ),
                  if (t.slateId.isNotEmpty) ECopyButton(text: t.slateId, label: l.deskTxCopySlate),
                ],
              ),
            ),
            (l.deskTxTechHeight, Text(t.height == null ? '-' : '${t.height}', style: ts.mono(size: Fs.xs))),
            (l.deskTxTechKernel, Text(t.kernel ?? '-', style: ts.mono(size: Fs.xs))),
            (l.deskTxTechConfirmed, Text(t.confirmedAt == null ? '-' : dateTimeOf(l, t, at: t.confirmedAt))),
            (l.deskTxTechCredited, EMoney(t.incoming ? t.amount : 0, unit: false)),
            (l.deskTxTechDebited, EMoney(t.incoming ? 0 : t.amount + t.fee, unit: false)),
            (l.deskTxTechStatus, Text(t.state.name, style: ts.mono(size: Fs.xs))),
            (l.deskTxTechType, Text(t.coinbase ? 'ConfirmedCoinbase' : (t.incoming ? 'TxReceived' : 'TxSent'), style: ts.mono(size: Fs.xs))), // l10n-ok: the core's type names
          ]),
        ),
        if (cancelable || finalizable || t.undelivered || repostable) ...[
          SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          SizedBox(height: Sp.x4),
          Row(
            children: [
              if (cancelable)
                EButton(
                  label: _cancelling ? l.deskTxCancelling : l.commonCancel,
                  icon: EIcons.cancel,
                  kind: EBtnKind.danger,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _cancel,
                ),
              const Spacer(),
              if (t.undelivered)
                EButton.primary(
                  label: context.l10n.deskTxSendAgain,
                  icon: EIcons.refresh,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _sendAgain,
                ),
              if (repostable)
                EButton.primary(
                  label: l.deskTxBroadcastAgain,
                  icon: EIcons.refresh,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _broadcastAgain,
                ),
              if (finalizable)
                EButton.primary(
                  label: l.deskTxFinalize,
                  icon: EIcons.fileDown,
                  size: EBtnSize.sm,
                  onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Whether the user has typed a sender, method or note on this scan find.
  bool _typed(Tx t) => t.manualFields.any((f) => f != ManualField.label);

  /// [value] with "Added by you" under it when the user typed [field].
  Widget _withTag(Tx t, ManualField field, Widget value) => t.manualFields.contains(field)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            value,
            SizedBox(height: Sp.x1),
            ManualTag(t, field),
          ],
        )
      : value;

  List<_Step> _steps(AppLocalizations l, Tx t) {
    final at = t.created;
    String hm(Duration d) => timeOf(Tx(id: 0, slateId: '', direction: t.direction, state: t.state, method: t.method, amount: 0, fee: 0, created: at.add(d)));
    if (t.coinbase || t.foundByScan) {
      final left = coinbaseMaturity - t.confirmations;
      return [
        _Step(t.coinbase ? l.deskTxStepMined : foundTexts(l, t).step, _S.done, hm(Duration.zero), sub: t.coinbase ? null : foundTexts(l, t).note),
        if (t.coinbase)
          _Step(l.deskTxStepSpendable, t.immature ? _S.now : _S.done, '', sub: t.immature ? l.deskTxStepBlocksToGo(left) : null)
        else
          _Step(l.deskTxStepSpendable, _S.done, ''),
      ];
    }
    final signed = t.state != TxState.waitingRecipient;
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || (t.state == TxState.posted && !t.notPosted);
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(t.incoming ? l.deskTxStepReceivedSlate : l.deskTxStepCreated, _S.done, hm(Duration.zero)),
      _Step(
        t.incoming ? l.deskTxStepSignedReturned : l.deskTxSignedByRecipient,
        signed ? _S.done : _S.now,
        signed ? hm(const Duration(seconds: 40)) : '',
        sub: signed ? null : (t.method == TxMethod.file ? l.deskTxStepWaitingFile : l.deskTxStepWaitingRecipient),
      ),
      _Step(l.deskTxStepPosted, posted ? _S.done : _S.todo, posted ? hm(const Duration(minutes: 1)) : ''),
      _Step(
        l.deskTxStepConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        inBlock ? hm(const Duration(minutes: 2)) : '',
        sub: t.state == TxState.confirming ? l.deskTxStepProgress(t.confirmations, t.confirmationsNeeded) : null,
      ),
      _Step(l.deskTxStepSpendable, done ? _S.done : _S.todo, done ? hm(Duration(minutes: 2 + t.confirmationsNeeded)) : ''),
    ];
  }
}

enum _S { done, now, todo }

class _Step {
  const _Step(this.title, this.state, this.time, {this.sub});

  final String title;
  final _S state;
  final String time;
  final String? sub;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final mark = Container(
      width: 20.u,
      height: 20.u,
      decoration: BoxDecoration(
        color: c.s1,
        borderRadius: BorderRadius.circular(5.u),
        border: Border.all(
          color: switch (step.state) {
            _S.done => c.ok.withValues(alpha: 0.5),
            _S.now => c.info,
            _S.todo => c.lineStrong,
          },
        ),
      ),
      child: switch (step.state) {
        _S.done => Icon(EIcons.check, size: 13.u, color: c.ok),
        _S.now => Padding(
          padding: EdgeInsets.all(4.u),
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.info),
        ),
        _S.todo => null,
      },
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20.u,
            child: Column(
              children: [
                mark,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: step.state == _S.done ? c.ok.withValues(alpha: 0.5) : c.lineStrong,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : Sp.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: step.state == _S.todo ? ts.body.copyWith(color: c.faint, fontWeight: FontWeight.w500) : ts.strong,
                  ),
                  if (step.sub != null) Text(step.sub!, style: ts.small.copyWith(color: c.faint)),
                ],
              ),
            ),
          ),
          Text(
            step.time,
            style: ts.mono(size: Fs.xs, color: c.faint),
          ),
        ],
      ),
    );
  }
}

/// A sub-header with ghost buttons at its end.
class _SubBar extends StatelessWidget {
  const _SubBar(this.title, this.actions);

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Sp.x6, bottom: Sp.x2),
    // The buttons drop under the title when the panel is too narrow for both.
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: Sp.x1,
      children: [
        Semantics(header: true, child: Text(title, style: context.ts.label)),
        Wrap(spacing: Sp.x1, children: actions),
      ],
    ),
  );
}

class _Sub extends StatelessWidget {
  const _Sub(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Sp.x6, bottom: Sp.x3),
    child: Semantics(header: true, child: Text(title, style: context.ts.label)),
  );
}

/// Asks before cancelling an unfinished send, or an incoming payment the node has not seen.
Future<bool?> showCancelTxDialog(BuildContext context, Tx t) => showEDialog<bool>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: t.incoming ? l.deskTxCancelIncomingTitle : l.deskTxCancelOutgoingTitle,
      icon: EIcons.cancel,
      tone: ETone.risk,
      description: t.incoming
          ? l.deskTxCancelIncomingBody(formatEpicL(l, t.amount), whoOf(l, t))
          : l.deskTxCancelOutgoingBody(formatEpicL(l, t.amount), whoOf(l, t)),
      actions: [
        EButton(label: l.deskTxCancelKeep, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
        EButton(label: t.incoming ? l.deskTxCancelIncomingAction : l.deskTxCancelOutgoingAction, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  },
);

/// The payment proof: who signed what, with copy and export. Shows what the transaction carries;
/// without a proof (or without its sender and signature) it says so and offers nothing to export.
String? _some(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

Future<void> showTxProofDialog(BuildContext context, Tx t) => showEDialog<void>(
  context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final ts = context.ts;
      final l = context.l10n;
      Widget field(String label, String copyLabel, String value) => Padding(
        padding: EdgeInsets.only(bottom: Sp.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: ts.small),
            SizedBox(height: Sp.x1),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: ts.mono(size: Fs.xs),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ECopyButton(text: value, label: copyLabel),
              ],
            ),
          ],
        ),
      );
      final sender = _some(t.proofSender), signature = _some(t.proofSignature);
      if (!t.hasProof || (sender == null && signature == null)) {
        return EDialog(
          title: l.deskTxPaymentProof,
          icon: EIcons.proof,
          width: 520.u,
          body: Text(l.deskTxProofNone, style: ts.body),
          actions: [EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: () => Navigator.pop(context))],
        );
      }
      // An address the user typed is not what the payment's proof is about: never shown here.
      final recipient = t.manualFields.contains(ManualField.counterparty) ? null : _some((t.counterparty ?? '').split('@').first);
      return EDialog(
        title: l.deskTxPaymentProof,
        icon: EIcons.proof,
        tone: ETone.ok,
        description: t.incoming ? l.deskTxProofIncoming(formatEpicL(l, t.amount)) : l.deskTxProofOutgoing(formatEpicL(l, t.amount)),
        width: 520.u,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_some(t.kernel) != null) field(l.deskTxTechKernel, l.deskTxProofCopyKernel, t.kernel!),
            if (sender != null) field(l.deskTxProofSenderAddress, l.deskTxProofCopySender, sender),
            if (recipient != null) field(l.deskTxProofRecipientAddress, l.deskTxProofCopyRecipient, recipient),
            if (signature != null) field(l.deskTxProofRecipientSignature, l.deskTxProofCopySignature, signature),
          ],
        ),
        actions: [
          EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
          EButton.primary(
            label: l.deskTxProofExport,
            icon: EIcons.download,
            size: EBtnSize.sm,
            onPressed: () async {
              final path = await ref.read(deskApiProvider).exportProof(t.id);
              if (context.mounted) {
                showEToast(context, l.deskTxProofSaved, text: path);
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  ),
);
