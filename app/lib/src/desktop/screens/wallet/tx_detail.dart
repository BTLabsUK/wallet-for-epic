import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
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

  String _now(Tx t) => t.fromBackup
      ? 'From backup; the chain was not asked.'
      : t.immature
      ? 'Confirmed, but a mining reward is spendable only after $coinbaseMaturity confirmations.'
      : switch (t.state) {
          TxState.waitingRecipient =>
            t.incoming
                ? 'Signed and returned. Waiting for the sender to finalize.'
                : t.method == TxMethod.file
                ? 'Waiting for the response file. Finalize when it arrives.'
                : 'Waiting for the recipient to sign. Nothing leaves the wallet until it is finalized.',
          TxState.posted => 'Posted to the network, waiting for a block.',
          TxState.confirming => 'In a block, ${t.confirmations} of ${t.confirmationsNeeded} confirmations.',
          TxState.confirmed => 'Confirmed, ${t.confirmations} confirmations.',
          TxState.cancelled => 'Cancelled.',
        };

  Future<void> _cancel() async {
    final ok = await showCancelTxDialog(context, widget.tx);
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, 'Not cancelled', text: deskErrorText(e));
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, 'Transaction cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.tx;
    final total = t.amount + (t.incoming ? 0 : t.fee);
    final cancelable = !t.fromBackup && !t.incoming && (t.state == TxState.waitingRecipient || t.state == TxState.posted);
    final finalizable = !t.fromBackup && !t.incoming && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    final steps = _steps(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    sign: true,
                    sizes: const [Fs.h2, Fs.h3, Fs.lg, Fs.md],
                    weight: FontWeight.w500,
                    color: t.incoming && t.state != TxState.cancelled ? c.ok : c.text,
                  ),
                  const SizedBox(height: 2),
                  if (t.foundByScan && t.contactName == null)
                    Text(t.foundDuring == FoundDuring.restore ? 'restored' : 'found on the chain', style: ts.small)
                  else if (t.fromBackup && t.counterparty == null)
                    Text('added from a history backup', style: ts.small)
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: t.incoming ? 'from ' : 'to '),
                          TextSpan(
                            text: whoOf(t),
                            style: whoIsAddress(t) ? ts.mono(size: Fs.xs, color: c.text) : TextStyle(color: c.text),
                          ),
                        ],
                      ),
                      style: ts.small,
                    ),
                  if (whoTip(t) != null && !(t.fromBackup && t.counterparty == null)) ...[const SizedBox(height: 2), Text(whoTip(t)!, style: ts.small.copyWith(color: c.faint))],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x4),
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
              Expanded(child: Text(_now(t), style: ts.body)),
            ],
          ),
        ),
        if (t.state != TxState.cancelled && !t.fromBackup) ...[_Sub('Progress'), for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1)],
        _Sub('Details'),
        EFacts(labelWidth: 96.u, [
          ('Date', Text(dateTimeOf(t))),
          if (t.counterparty != null)
            (
              t.incoming ? 'From' : 'To',
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
                  ECopyButton(text: t.counterparty!, label: 'Copy address'),
                ],
              ),
            ),
          ('Method', Text(t.foundByScan ? '–' : methodLabel(t.method))),
          ('Amount', EMoney(t.amount)),
          if (!t.incoming) ...[('Fee', EMoney(t.fee)), ('Total', EMoney(total, weight: FontWeight.w600))],
          if (t.message != null) ('Message', Text(t.message!)),
        ]),
        if (DeskFeatures.paymentProofs && t.hasProof) ...[
          _Sub('Payment proof'),
          Row(
            children: [
              Icon(EIcons.proof, size: Ctl.iconSm, color: c.ok),
              SizedBox(width: Sp.x2),
              Expanded(child: Text('Signed by the recipient', style: ts.small)),
              EButton(label: 'View', kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => showTxProofDialog(context, t)),
            ],
          ),
        ],
        SizedBox(height: Sp.x5),
        EDetails(
          title: 'Technical details',
          child: EFacts(labelWidth: 96.u, [
            ('Id', Text('${t.id}', style: ts.mono(size: Fs.xs))),
            (
              'Slate id',
              Row(
                children: [
                  Expanded(
                    child: Text(t.slateId.isEmpty ? '-' : t.slateId, style: ts.mono(size: Fs.xs)),
                  ),
                  if (t.slateId.isNotEmpty) ECopyButton(text: t.slateId, label: 'Copy slate id'),
                ],
              ),
            ),
            ('Height', Text(t.height == null ? '-' : '${t.height}', style: ts.mono(size: Fs.xs))),
            ('Kernel', Text(t.kernel ?? '-', style: ts.mono(size: Fs.xs))),
            ('Confirmed', Text(t.confirmedAt == null ? '-' : dateTimeOf(t, at: t.confirmedAt))),
            ('Credited', EMoney(t.incoming ? t.amount : 0, unit: false)),
            ('Debited', EMoney(t.incoming ? 0 : t.amount + t.fee, unit: false)),
            ('Status', Text(t.state.name, style: ts.mono(size: Fs.xs))),
            ('Type', Text(t.coinbase ? 'ConfirmedCoinbase' : (t.incoming ? 'TxReceived' : 'TxSent'), style: ts.mono(size: Fs.xs))),
          ]),
        ),
        if (cancelable || finalizable) ...[
          SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          SizedBox(height: Sp.x4),
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
    if (t.coinbase || t.foundByScan) {
      final left = coinbaseMaturity - t.confirmations;
      return [
        _Step(t.coinbase ? 'Mined in a block' : foundTexts(t).step, _S.done, hm(Duration.zero), sub: t.coinbase ? null : foundTexts(t).note),
        if (t.coinbase)
          _Step('Spendable', t.immature ? _S.now : _S.done, '', sub: t.immature ? '$left blocks to go' : null)
        else
          _Step('Spendable', _S.done, ''),
      ];
    }
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
        sub: t.state == TxState.confirming ? '${t.confirmations} of ${t.confirmationsNeeded}' : null,
      ),
      _Step('Spendable', done ? _S.done : _S.todo, done ? hm(Duration(minutes: 2 + t.confirmationsNeeded)) : ''),
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
            _S.now => c.accent,
            _S.todo => c.lineStrong,
          },
        ),
      ),
      child: switch (step.state) {
        _S.done => Icon(EIcons.check, size: 13.u, color: c.ok),
        _S.now => Padding(
          padding: EdgeInsets.all(4.u),
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent),
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

class _Sub extends StatelessWidget {
  const _Sub(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Sp.x6, bottom: Sp.x3),
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
    description:
        '${formatEpic(t.amount)} EPIC to ${whoOf(t)}. The locked amount returns to the balance. '
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
        width: 520.u,
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
