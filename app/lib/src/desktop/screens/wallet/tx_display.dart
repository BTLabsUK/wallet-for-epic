import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/kit.dart';

/// Confirmations after which received funds are spendable.
const int minConfirmations = 10;

String methodLabel(TxMethod m) => switch (m) {
  TxMethod.epicbox => 'Epicbox',
  TxMethod.http => 'Direct HTTP',
  TxMethod.tor => 'Tor',
  TxMethod.file => 'File',
};

/// Who the other side is: the contact's name, else a shortened address or the file name.
String whoOf(Tx t) {
  if (t.contactName != null) return t.contactName!;
  final cp = t.counterparty;
  if (cp == null) return t.incoming ? 'Received' : 'Sent';
  if (t.method == TxMethod.file) return cp;
  return shortAddress(cp);
}

String shortAddress(String a) {
  if (a.startsWith('http')) {
    final host = a.replaceFirst(RegExp(r'^https?://'), '');
    if (host.contains('.onion')) return '${host.substring(0, 8)}….onion';
    return host;
  }
  final at = a.indexOf('@');
  final core = at > 0 ? a.substring(0, at) : a;
  if (core.length <= 18) return a;
  return '${core.substring(0, 8)}…${core.substring(core.length - 6)}${at > 0 ? a.substring(at) : ''}';
}

IconData iconOf(Tx t) => switch (t.method) {
  TxMethod.file => t.incoming ? EIcons.fileDown : EIcons.fileUp,
  _ => t.incoming ? EIcons.receive : EIcons.send,
};

/// The state in words, with a tone for its colour.
(String, ETone) statusOf(Tx t) => switch (t.state) {
  TxState.waitingRecipient => (t.incoming ? 'Waiting for sender' : 'Waiting for recipient', ETone.warn),
  TxState.posted => ('Waiting for a block', ETone.neutral),
  TxState.confirming => ('Confirming ${t.confirmations}/$minConfirmations', ETone.gold),
  TxState.confirmed => (t.incoming ? 'Received' : 'Sent', ETone.ok),
  TxState.cancelled => ('Cancelled', ETone.neutral),
};

final _time = DateFormat('HH:mm');
final _day = DateFormat('d MMM yyyy');
final _dayTime = DateFormat('d MMM yyyy, HH:mm');

String timeOf(Tx t) => _time.format(t.created);
String dateTimeOf(Tx t) => _dayTime.format(t.created);

/// "Today", "Yesterday" or the date, for day separators.
String dayLabel(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime(2026, 10, 21, 14, 30);
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(n.year, n.month, n.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return _day.format(d);
}

/// Short relative time for compact rows: "18 min", "3 h", "2 d", else the date.
String compactTime(Tx t, {DateTime? now}) {
  final n = now ?? DateTime(2026, 10, 21, 14, 30);
  final d = n.difference(t.created);
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  if (d.inDays < 7) return '${d.inDays} d';
  return _day.format(t.created);
}

/// The 36 px square with the direction icon: green in, gold out, dashed when cancelled.
class TxIcon extends StatelessWidget {
  const TxIcon(this.tx, {super.key, this.size = 36});

  final Tx tx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final off = tx.state == TxState.cancelled;
    final color = off ? c.faint : (tx.incoming ? c.ok : c.accentText);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: off ? c.line : c.lineStrong),
      ),
      child: Icon(iconOf(tx), size: Ctl.icon, color: color),
    );
  }
}

/// Ring or icon for the state, sized for a row.
class TxStateMark extends StatelessWidget {
  const TxStateMark(this.tx, {super.key, this.size = 22});

  final Tx tx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return switch (tx.state) {
      TxState.cancelled => ERing(confirmations: 0, size: size, off: true),
      TxState.waitingRecipient => Icon(EIcons.sand, size: size * 0.75, color: c.warn),
      TxState.posted => ERing(confirmations: 0, size: size),
      _ => ERing(confirmations: tx.confirmations, needed: minConfirmations, size: size),
    };
  }
}

/// The amount column: signed, green when in, struck through when cancelled; fee under a send.
class TxAmount extends StatelessWidget {
  const TxAmount(this.tx, {super.key, this.showFee = true, this.sub});

  final Tx tx;
  final bool showFee;

  /// Replaces the fee line (compact rows show the time there).
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final off = tx.state == TxState.cancelled;
    final color = off ? c.faint : (tx.incoming ? c.ok : c.text);
    final line = sub ?? (showFee && !tx.incoming && tx.fee > 0 ? 'Fee ${formatEpic(tx.fee)}' : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(decoration: off ? TextDecoration.lineThrough : null, decorationColor: c.faint),
          child: EMoney(tx.incoming ? tx.amount : -tx.amount, sign: true, unit: false, color: color, size: Fs.md),
        ),
        if (line != null) ...[
          const SizedBox(height: 2),
          Text(line, style: context.ts.caption),
        ],
      ],
    );
  }
}

/// One transaction row. [compact] (Overview) puts the state under the name and the time
/// under the amount; the full row (Activity) has state, time and amount columns.
class TxRow extends StatefulWidget {
  const TxRow({super.key, required this.tx, required this.onTap, this.compact = false, this.selected = false, this.onFinalize});

  final Tx tx;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;
  final VoidCallback? onFinalize;

  @override
  State<TxRow> createState() => _TxRowState();
}

class _TxRowState extends State<TxRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.tx;
    final (word, tone) = statusOf(t);
    final toneColor = switch (tone) {
      ETone.ok => c.dim,
      ETone.warn => c.warn,
      ETone.gold => c.accentText,
      _ => c.faint,
    };
    final meta = <InlineSpan>[
      TextSpan(text: methodLabel(t.method)),
      if (t.message != null) ...[
        TextSpan(text: '  ·  ', style: TextStyle(color: c.lineField)),
        TextSpan(text: t.message),
      ] else if (t.hasProof) ...[
        TextSpan(text: '  ·  ', style: TextStyle(color: c.lineField)),
        const TextSpan(text: 'Payment proof'),
      ],
    ];
    final who = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          whoOf(t),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.contactName == null && t.method != TxMethod.file
              ? ts.mono(size: 12.5, weight: FontWeight.w500)
              : ts.strong,
        ),
        const SizedBox(height: 2),
        if (widget.compact)
          Row(
            children: [
              TxStateMark(t, size: 15),
              const SizedBox(width: 6),
              Flexible(child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: toneColor))),
            ],
          )
        else
          Text.rich(TextSpan(children: meta), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: c.faint)),
      ],
    );
    final finalizable = !widget.compact && !t.incoming && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    final row = Row(
      children: [
        TxIcon(t),
        const SizedBox(width: Sp.x4),
        Expanded(flex: 16, child: who),
        if (!widget.compact) ...[
          const SizedBox(width: Sp.x4),
          Expanded(
            flex: 10,
            child: finalizable
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: EButton(
                      label: 'Finalize',
                      icon: EIcons.fileDown,
                      kind: EBtnKind.ghost,
                      size: EBtnSize.inline,
                      onPressed: widget.onFinalize,
                    ),
                  )
                : Row(
                    children: [
                      TxStateMark(t),
                      const SizedBox(width: Sp.x2),
                      Flexible(child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: toneColor))),
                    ],
                  ),
          ),
          const SizedBox(width: Sp.x4),
          SizedBox(width: 52, child: Text(timeOf(t), style: ts.mono(size: Fs.xs, color: c.faint))),
        ],
        const SizedBox(width: Sp.x4),
        TxAmount(t, sub: widget.compact ? compactTime(t) : null),
      ],
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${t.incoming ? 'Received' : 'Sent'} ${formatEpic(t.amount)} EPIC, ${whoOf(t)}, $word',
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
          color: widget.selected ? c.s3 : (_hover ? c.hover : null),
          child: row,
        ),
      ),
    );
  }
}
