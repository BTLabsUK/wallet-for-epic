import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'tx_display.dart';

/// One transaction: amount and counterparty, where it stands, its progress, details, proof,
/// technical details and the actions it allows (cancel, finalize).
class TxDetail extends ConsumerStatefulWidget {
  const TxDetail({super.key, required this.tx});

  final Tx tx;

  @override
  ConsumerState<TxDetail> createState() => _TxDetailState();
}

class _TxDetailState extends ConsumerState<TxDetail> {
  bool _cancelling = false;

  String _now(Tx t) => switch (t.state) {
    TxState.waitingRecipient => t.method == TxMethod.file
        ? 'Waiting for the response file. Finalize when it arrives.'
        : 'Waiting for the recipient to sign. Nothing leaves the wallet until it is finalized.',
    TxState.posted => 'Posted to the network, waiting for a block.',
    TxState.confirming => 'In a block, ${t.confirmations} of $minConfirmations confirmations.',
    TxState.confirmed => 'Confirmed, ${t.confirmations} confirmations.',
    TxState.cancelled => 'Cancelled.',
  };

  Future<void> _cancel() async {
    final ok = await showCancelTxDialog(context, widget.tx);
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    await ref.read(deskProvider.notifier).cancelTx(widget.tx.id);
    if (mounted) setState(() => _cancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.tx;
    final total = t.amount + (t.incoming ? 0 : t.fee);
    final cancelable = !t.incoming && (t.state == TxState.waitingRecipient || t.state == TxState.posted);
    final finalizable = !t.incoming && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    final steps = _steps(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TxIcon(t, size: 44),
            const SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: EMoney(t.incoming ? t.amount : -t.amount, sign: true, size: Fs.h2, weight: FontWeight.w500, color: t.incoming && t.state != TxState.cancelled ? c.ok : c.text),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: t.incoming ? 'from ' : 'to '),
                        TextSpan(text: whoOf(t), style: t.contactName == null ? ts.mono(size: Fs.xs, color: c.text) : TextStyle(color: c.text)),
                      ],
                    ),
                    style: ts.small,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.x4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 10),
          decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
          child: Row(
            children: [
              TxStateMark(t),
              const SizedBox(width: Sp.x3),
              Expanded(child: Text(_now(t), style: ts.body)),
            ],
          ),
        ),
        if (t.state != TxState.cancelled) ...[
          _Sub('Progress'),
          for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1),
        ],
        _Sub('Details'),
        EFacts(labelWidth: 96, [
          ('Date', Text(dateTimeOf(t))),
          if (t.counterparty != null)
            (
              t.incoming ? 'From' : 'To',
              Row(
                children: [
                  Expanded(child: Text(t.counterparty!, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.mono(size: Fs.xs))),
                  ECopyButton(text: t.counterparty!, label: 'Copy address'),
                ],
              ),
            ),
          ('Method', Text(methodLabel(t.method))),
          ('Amount', EMoney(t.amount)),
          if (!t.incoming) ...[('Fee', EMoney(t.fee)), ('Total', EMoney(total, weight: FontWeight.w600))],
          if (t.message != null) ('Message', Text(t.message!)),
        ]),
        if (t.hasProof) ...[
          _Sub('Payment proof'),
          Row(
            children: [
              Icon(EIcons.proof, size: Ctl.iconSm, color: c.ok),
              const SizedBox(width: Sp.x2),
              Expanded(child: Text('Signed by the recipient', style: ts.small)),
              EButton(label: 'View', kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => showTxProofDialog(context, t)),
            ],
          ),
        ],
        const SizedBox(height: Sp.x5),
        EDetails(
          title: 'Technical details',
          child: EFacts(labelWidth: 96, [
            ('Id', Text('${t.id}', style: ts.mono(size: Fs.xs))),
            (
              'Slate id',
              Row(
                children: [
                  Expanded(child: Text(t.slateId, style: ts.mono(size: Fs.xs))),
                  ECopyButton(text: t.slateId, label: 'Copy slate id'),
                ],
              ),
            ),
            ('Height', Text(t.height == null ? '-' : '${t.height}', style: ts.mono(size: Fs.xs))),
            ('Kernel', Text(t.kernel ?? '-', style: ts.mono(size: Fs.xs))),
            ('Type', Text(t.incoming ? 'TxReceived' : 'TxSent', style: ts.mono(size: Fs.xs))),
          ]),
        ),
        if (cancelable || finalizable) ...[
          const SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          const SizedBox(height: Sp.x4),
          Row(
            children: [
              if (cancelable)
                EButton(
                  label: _cancelling ? 'Cancelling' : 'Cancel',
                  icon: EIcons.cancel,
                  kind: EBtnKind.danger,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _cancel,
                ),
              const Spacer(),
              if (finalizable)
                EButton.primary(
                  label: 'Finalize',
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

  List<_Step> _steps(Tx t) {
    final at = t.created;
    String hm(Duration d) => timeOf(Tx(id: 0, slateId: '', direction: t.direction, state: t.state, method: t.method, amount: 0, fee: 0, created: at.add(d)));
    final signed = t.state != TxState.waitingRecipient;
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || t.state == TxState.posted;
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(t.incoming ? 'Received slate' : 'Created and signed', _S.done, hm(Duration.zero)),
      _Step(
        t.incoming ? 'Signed and returned' : 'Signed by the recipient',
        signed ? _S.done : _S.now,
        signed ? hm(const Duration(seconds: 40)) : '',
        sub: signed ? null : (t.method == TxMethod.file ? 'Waiting for the response file' : 'Waiting for the recipient'),
      ),
      _Step('Posted to the network', posted ? _S.done : _S.todo, posted ? hm(const Duration(minutes: 1)) : ''),
      _Step(
        'Confirming',
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        inBlock ? hm(const Duration(minutes: 2)) : '',
        sub: t.state == TxState.confirming ? '${t.confirmations} of $minConfirmations' : null,
      ),
      _Step('Spendable', done ? _S.done : _S.todo, done ? hm(const Duration(minutes: 12)) : ''),
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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: c.s1,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: switch (step.state) {
            _S.done => c.ok.withValues(alpha: 0.5),
            _S.now => c.accent,
            _S.todo => c.lineStrong,
          },
        ),
      ),
      child: switch (step.state) {
        _S.done => Icon(EIcons.check, size: 13, color: c.ok),
        _S.now => Padding(padding: const EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent)),
        _S.todo => null,
      },
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                mark,
                if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: step.state == _S.done ? c.ok.withValues(alpha: 0.5) : c.lineStrong)),
              ],
            ),
          ),
          const SizedBox(width: Sp.x3),
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
          Text(step.time, style: ts.mono(size: Fs.xs, color: c.faint)),
        ],
      ),
    );
  }
}

class _Sub extends StatelessWidget {
  const _Sub(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Sp.x6, bottom: Sp.x3),
    child: Semantics(header: true, child: Text(title, style: context.ts.label)),
  );
}

/// Asks before cancelling an unfinished send.
Future<bool?> showCancelTxDialog(BuildContext context, Tx t) => showEDialog<bool>(
  context,
  builder: (context) => EDialog(
    title: 'Cancel this send?',
    icon: EIcons.cancel,
    tone: ETone.risk,
    description: '${formatEpic(t.amount)} EPIC to ${whoOf(t)}. The locked amount returns to the balance. '
        'If the recipient already finalized it, it may still confirm.',
    actions: [
      EButton(label: 'Keep', size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
      EButton(label: 'Cancel send', kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
    ],
  ),
);

/// The payment proof: who signed what, with copy and export.
Future<void> showTxProofDialog(BuildContext context, Tx t) => showEDialog<void>(
  context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final ts = context.ts;
      Widget field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: ts.small),
            const SizedBox(height: Sp.x1),
            Row(
              children: [
                Expanded(child: Text(value, style: ts.mono(size: Fs.xs), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ECopyButton(text: value, label: 'Copy $label'),
              ],
            ),
          ],
        ),
      );
      return EDialog(
        title: 'Payment proof',
        icon: EIcons.proof,
        tone: ETone.ok,
        description: 'Proves that ${t.incoming ? 'this wallet' : 'the recipient'} received ${formatEpic(t.amount)} EPIC in this kernel.',
        width: 520,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field('Kernel', t.kernel ?? '-'),
            field('Sender address', 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b'),
            field('Recipient address', (t.counterparty ?? '').split('@').first),
            field('Recipient signature', '3045022100c7a1e9f0b2d4a6c8e0f2b4d6a8c0e2f4b6d8a0c2e4f6b8d0a2c4e6f8b0d2a4c602205f'),
          ],
        ),
        actions: [
          EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
          EButton.primary(
            label: 'Export',
            icon: EIcons.download,
            size: EBtnSize.sm,
            onPressed: () async {
              final path = await ref.read(deskApiProvider).exportProof(t.id);
              if (context.mounted) {
                showEToast(context, 'Proof saved', text: path);
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  ),
);
