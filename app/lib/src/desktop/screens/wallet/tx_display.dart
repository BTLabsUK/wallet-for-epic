import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../l10n.dart' show localClock, localDay, localDayMonth;
import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../invoices/invoice_parts.dart' show payStateWord, requestStateWord;

String methodLabel(AppLocalizations l, TxMethod m) => switch (m) {
  TxMethod.epicbox => 'Epicbox', // l10n-ok: product name
  TxMethod.http => 'HTTP', // l10n-ok: protocol name
  TxMethod.tor => 'Tor', // l10n-ok: product name
  TxMethod.file => l.deskTxMethodFile,
};

/// Who the other side is: the contact's name, else a shortened address or the file name, else
/// what kind of transaction it was.
String whoOf(AppLocalizations l, Tx t) {
  if (t.contactName != null) return t.contactName!;
  if (t.coinbase) return l.deskTxMiningReward;
  if (t.foundByScan) return foundTexts(l, t).label;
  final cp = t.counterparty;
  if (cp == null && t.fromBackup) return t.incoming ? l.deskTxReceived : l.deskTxSent;
  if (cp == null) return t.incoming ? l.deskTxUnknownSender : l.deskTxUnknownRecipient;
  if (t.method == TxMethod.file) return cp;
  // An invoice's other side is an Epicbox address: first six and last six, no host.
  return shortAddress(cp, compact: t.isInvoice);
}

/// The words for a payment a scan found with no record (F17), by which scan found it. An
/// entry stored before the core recorded the scan makes no claim about it.
typedef FoundTexts = ({String label, String line, String step, String note, String tip});

FoundTexts foundTexts(AppLocalizations l, Tx t) {
  final unknown = l.deskTxNoteUnknown;
  final note = t.datedByBlock ? l.deskTxNoteBlock : l.deskTxNoteScanTime;
  return switch (t.foundDuring) {
    FoundDuring.restore => (
      label: l.deskTxFoundRestoredLabel,
      line: l.deskTxFoundRestoredLine,
      step: l.deskTxFoundRestoredStep,
      note: note,
      tip: l.deskTxFoundRestoredTip,
    ),
    FoundDuring.rescan => (
      label: l.deskTxFoundRescanLabel,
      line: l.deskTxFoundRescanLine,
      step: l.deskTxFoundRescanStep,
      note: note,
      tip: l.deskTxFoundRescanTip,
    ),
    null => (label: l.deskTxFoundRescanLabel, line: l.deskTxFoundScanLine, step: l.deskTxFoundScanStep, note: unknown, tip: l.deskTxFoundScanTip),
  };
}

/// A line explaining [whoOf] where it needs one.
String? whoTip(AppLocalizations l, Tx t) =>
    t.detail ?? (t.foundByScan && t.contactName == null ? foundTexts(l, t).tip : (t.fromBackup ? l.deskTxBackupTip : null));

/// Whether the name is an address (shown in mono).
bool whoIsAddress(Tx t) => t.contactName == null && t.counterparty != null && t.method != TxMethod.file;

/// How it travelled, or null when that is not known (mining rewards, scan finds).
String? methodOf(AppLocalizations l, Tx t) => t.coinbase || t.foundByScan ? null : methodLabel(l, t.method);

IconData iconOf(Tx t) => switch (t.method) {
  TxMethod.file => t.incoming ? EIcons.fileDown : EIcons.fileUp,
  _ => t.incoming ? EIcons.receive : EIcons.send,
};

/// The state in words, with a tone for its colour.
(String, ETone) statusOf(AppLocalizations l, Tx t) => t.fromBackup
    ? (l.deskTxFromBackup, ETone.neutral)
    : t.immature
    ? (l.deskTxStatusImmature, ETone.warn)
    : switch (t.state) {
        TxState.waitingRecipient => (
          t.incoming ? l.deskTxStatusWaitingSender : (t.method == TxMethod.file ? l.deskTxStatusWaitingResponseFile : l.deskTxStatusWaitingRecipient),
          ETone.warn,
        ),
        TxState.posted => (l.deskTxStatusWaitingBlock, ETone.neutral),
        TxState.confirming => (l.deskTxStatusConfirming(t.confirmations, t.confirmationsNeeded), ETone.info),
        TxState.confirmed => (t.incoming ? l.deskTxReceived : l.deskTxSent, ETone.ok),
        TxState.cancelled => (l.deskTxStatusCancelled, ETone.neutral),
      };

final _time = DateFormat('HH:mm');
// English reads the built-in default locale: a screen pumped on its own has no date data loaded.
final _dayEn = DateFormat('d MMM yyyy');
final _dayMonthEn = DateFormat('d MMM');

/// "21 Sep 2026", or the language's own short date.
String shortDay(AppLocalizations l, DateTime d) => l.localeName == 'en' ? _dayEn.format(d) : localDay(l, d);

/// "21 Sep", or the language's own.
String shortDayMonth(AppLocalizations l, DateTime d) => l.localeName == 'en' ? _dayMonthEn.format(d) : localDayMonth(l, d);

/// A full weekday and date: "Wednesday 21 October" (English), the language's own order elsewhere.
String _weekdayDate(AppLocalizations l, DateTime d, {required bool year}) => (l.localeName == 'en'
        ? DateFormat(year ? 'EEEE d MMMM yyyy' : 'EEEE d MMMM')
        : (year ? DateFormat.yMMMMEEEEd(l.localeName) : DateFormat.MMMMEEEEd(l.localeName)))
    .format(d);

String timeOf(Tx t) => _time.format(t.created);
String dateTimeOf(AppLocalizations l, Tx t, {DateTime? at}) => '${shortDay(l, at ?? t.created)}, ${l.localeName == 'en' ? _time.format(at ?? t.created) : localClock(l, at ?? t.created)}';

/// The first of [sizes] (whole type sizes, largest first) at which [text] in [style] fits
/// [maxWidth] after the app's text scaler, else the last one (the caller ellipsizes). Text is
/// stepped down, never scale-transformed, so it stays crisp.
double fitFontSize(BuildContext context, String text, TextStyle style, List<double> sizes, double maxWidth, {double extra = 0}) {
  final scaler = MediaQuery.textScalerOf(context);
  for (final size in sizes) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = tp.width;
    tp.dispose();
    if (w + extra <= maxWidth) return size;
  }
  return sizes.last;
}

/// An [EMoney] that steps its size down through [sizes] to fit its width.
class FitMoney extends ConsumerWidget {
  const FitMoney(this.nano, {super.key, required this.sizes, this.color, this.sign = false, this.unit = false, this.weight, this.width});

  final int nano;
  final List<double> sizes;

  /// The width to fit, when the caller knows it (inside IntrinsicHeight, where a
  /// LayoutBuilder can't measure).
  final double? width;
  final Color? color;
  final bool sign;
  final bool unit;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final text = '${sign && nano > 0 ? '+' : ''}${hidden ? '••••••' : formatEpic(nano)}${unit ? ' EPIC' : ''}';
    final style = context.ts.mono(weight: weight ?? FontWeight.w500);
    if (width != null) {
      return EMoney(nano, size: fitFontSize(context, text, style, sizes, width!), color: color, sign: sign, unit: unit, weight: weight);
    }
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.maxWidth.isFinite ? fitFontSize(context, text, style, sizes, box.maxWidth) : sizes.first;
        return ClipRect(
          child: EMoney(nano, size: size, color: color, sign: sign, unit: unit, weight: weight),
        );
      },
    );
  }
}

/// The mock's clock, so day labels stay stable in screenshots.
final DateTime _now = DateTime(2026, 10, 21, 14, 30);

/// Day separators: "Today · Wednesday 21 October", "Yesterday · …", "Monday 19 October".
String dayLabel(AppLocalizations l, DateTime d, {DateTime? now}) {
  final n = now ?? _now;
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(n.year, n.month, n.day);
  final diff = b.difference(a).inDays;
  final full = _weekdayDate(l, d, year: d.year != n.year);
  if (diff == 0) return l.deskTxDayToday(full);
  if (diff == 1) return l.deskTxDayYesterday(full);
  return full;
}

/// Compact rows: "Today 16:58", else "16 Oct 09:15".
String compactTime(AppLocalizations l, Tx t, {DateTime? now}) {
  final n = now ?? _now;
  final d = t.created;
  final today = d.year == n.year && d.month == n.month && d.day == n.day;
  return today ? l.deskTxTodayAt(_time.format(d)) : '${shortDayMonth(l, d)} ${_time.format(d)}';
}

/// "today", "yesterday", "3 days ago", then "12 Oct" (with the year when it is not this year).
String whenText(AppLocalizations l, DateTime d, {DateTime? now}) {
  final n = now ?? _now;
  final days = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days == 0) return l.deskTxToday;
  if (days == 1) return l.deskTxYesterday;
  if (days > 1 && days < 7) return l.deskTxDaysAgo(days);
  return d.year == n.year ? shortDayMonth(l, d) : shortDay(l, d);
}

/// The 36 px square with the direction icon: green in, gold out, dashed when cancelled.
class TxIcon extends StatelessWidget {
  const TxIcon(this.tx, {super.key, this._size});

  final Tx tx;
  final double? _size;
  double get size => _size ?? 36.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final off = tx.state == TxState.cancelled;
    // Direction, as the phone draws it: green in, plain out; never gold for a state.
    final color = off ? c.faint : (txAsked(tx) ? c.dim : (tx.incoming ? c.ok : c.text));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: off ? c.line : c.lineStrong),
      ),
      child: Icon(tx.isInvoice ? (tx.incoming ? EIcons.request : EIcons.invoice) : iconOf(tx), size: Ctl.icon, color: color),
    );
  }
}

/// Ring or icon for the state, sized for a row.
class TxStateMark extends StatelessWidget {
  const TxStateMark(this.tx, {super.key, this._size});

  final Tx tx;
  final double? _size;
  double get size => _size ?? 22.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    if (tx.immature) return Icon(EIcons.sand, size: size * 0.75, color: c.warn);
    // The chain was not asked about a payment only a backup knows: no count to show.
    if (tx.fromBackup) return Icon(EIcons.archive, size: size * 0.75, color: c.dim);
    return switch (tx.state) {
      TxState.cancelled => ERing(confirmations: 0, size: size, off: true),
      TxState.waitingRecipient => Icon(EIcons.sand, size: size * 0.75, color: c.warn),
      TxState.posted => ERing(confirmations: 0, size: size),
      _ => ERing(confirmations: tx.confirmations, needed: tx.confirmationsNeeded, size: size),
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
    // A request not paid yet is not money: neutral, no sign, "Requested" (flow.md §3.3).
    final asked = txAsked(tx);
    final color = off ? c.faint : (asked ? c.text : (tx.incoming ? c.ok : c.text));
    final line = asked && tx.state == TxState.waitingRecipient ? context.l10n.deskInvUnpaid : sub ?? (showFee && !tx.incoming && tx.fee > 0 ? context.l10n.deskTxFee(formatEpic(tx.fee)) : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(decoration: off ? TextDecoration.lineThrough : null, decorationColor: c.faint),
          child: EMoney(tx.incoming ? tx.amount : -tx.amount, sign: !asked, unit: false, color: color, size: Fs.md),
        ),
        if (line != null) ...[const SizedBox(height: 2), Text(line, style: context.ts.caption)],
      ],
    );
  }
}

/// Fixed widths of the Time and Amount columns, shared by [TxRow] and the Activity header so
/// every row lines up whatever its amount says.
double get txTimeWidth => 52.u;
double get txAmountWidth => 150.u;

/// Narrower than this, [TxRow] uses its compact form.
double get txRowFullWidth => 560.u;

/// One transaction row. [compact] (Overview) puts the state under the name and the time
/// under the amount; the full row (Activity) has state, time and amount columns.
class TxRow extends ConsumerStatefulWidget {
  const TxRow({super.key, required this.tx, required this.onTap, this.compact = false, this.selected = false, this.onFinalize, this.title});

  final Tx tx;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;
  final VoidCallback? onFinalize;

  /// Replaces the name (a contact's own history says Sent / Received).
  final String? title;

  @override
  ConsumerState<TxRow> createState() => _TxRowState();
}

class _TxRowState extends ConsumerState<TxRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // A narrow list gets the compact row: no room for the status and time columns.
    builder: (context, box) => _row(context, widget.compact || box.maxWidth < txRowFullWidth),
  );

  Widget _row(BuildContext context, bool compact) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.tx;
    final (word, tone) = invoiceStatusOf(context, ref, t) ?? statusOf(context.l10n, t);
    final toneColor = switch (tone) {
      ETone.ok => c.dim,
      ETone.warn => c.warn,
      ETone.info => c.info,
      ETone.gold => c.accentText,
      _ => c.faint,
    };
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final l = context.l10n;
    final method = t.foundByScan ? foundTexts(l, t).line : (t.fromBackup ? l.deskTxFromBackup : methodOf(l, t));
    final extra = t.message ?? (DeskFeatures.paymentProofs && t.hasProof ? l.deskTxPaymentProof : null);
    final meta = <InlineSpan>[
      if (method != null) TextSpan(text: method),
      if (extra != null) ...[
        if (method != null)
          TextSpan(
            text: '  ·  ',
            style: TextStyle(color: c.lineField),
          ),
        TextSpan(text: extra),
      ],
    ];
    final who = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tip(
          message: widget.title == null && (t.foundByScan || t.fromBackup) ? whoTip(l, t) : null,
          child: widget.title == null && whoIsAddress(t) && !t.isInvoice
              ? EShortAddress(t.counterparty!, style: ts.mono(size: 12.5, weight: FontWeight.w500), tooltip: false)
              : Text(widget.title ?? invoiceTitleOf(context, t) ?? whoOf(l, t), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.strong),
        ),
        if (compact || meta.isNotEmpty) const SizedBox(height: 2),
        if (compact)
          Row(
            children: [
              TxStateMark(t, size: 15.u),
              SizedBox(width: 6.u),
              Flexible(
                child: Text(
                  word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.small.copyWith(color: toneColor),
                ),
              ),
            ],
          )
        else if (meta.isNotEmpty)
          Text.rich(
            TextSpan(children: meta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts.small.copyWith(color: c.faint),
          ),
      ],
    );
    final finalizable = !compact && !t.incoming && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    final row = Row(
      children: [
        TxIcon(t),
        SizedBox(width: Sp.x4),
        Expanded(flex: 16, child: who),
        if (!compact) ...[
          SizedBox(width: Sp.x4),
          Expanded(
            flex: 10,
            child: finalizable
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: EButton(label: l.deskTxFinalize, icon: EIcons.fileDown, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: widget.onFinalize),
                  )
                : Row(
                    children: [
                      TxStateMark(t),
                      SizedBox(width: Sp.x2),
                      Flexible(
                        child: Text(
                          word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts.small.copyWith(color: toneColor),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(width: Sp.x4),
          SizedBox(
            width: txTimeWidth,
            child: Text(
              timeOf(t),
              textAlign: TextAlign.right,
              style: ts.mono(size: Fs.xs, color: c.faint),
            ),
          ),
        ],
        SizedBox(width: Sp.x4),
        compact
            ? TxAmount(t, sub: compactTime(l, t))
            : SizedBox(
                width: txAmountWidth,
                child: Align(alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: TxAmount(t))),
              ),
      ],
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      // A request is never read out as money received (flow.md §5, fake invoice dressed as income);
      // it reads Unpaid only while it is, then its state word says what became of it.
      label: _semantics(l, t, hidden ? l.deskTxHiddenAmount : '${formatEpic(t.amount)} EPIC', word),
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        child: Container(
          constraints: BoxConstraints(minHeight: 60.u),
          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
          color: widget.selected ? c.s3 : (_hover ? c.hover : null),
          child: row,
        ),
      ),
    );
  }
}

extension on _TxRowState {
  String _semantics(AppLocalizations l, Tx t, String amount, String status) {
    final who = whoOf(l, t);
    if (t.isInvoice) return l.deskTxSemKind(txAsked(t) ? l.deskInvUnpaid : l.deskInvActBlock, amount, who, status);
    return t.incoming ? l.deskTxSemReceived(amount, who, status) : l.deskTxSemSent(amount, who, status);
  }
}

/// A tooltip when there is something to say, else the child alone.
class _Tip extends StatelessWidget {
  const _Tip({required this.message, required this.child});

  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) => message == null ? child : Tooltip(message: message, child: child);
}


/// An invoice transaction's state in the words of Requests (the request or the invoice behind
/// it), or null for a plain payment.
(String, ETone)? invoiceStatusOf(BuildContext context, WidgetRef ref, Tx t) {
  if (!t.isInvoice) return null;
  final book = ref.watch(deskInvoicesProvider);
  if (book == null) return null;
  if (t.incoming) {
    final r = book.requestOfTx(t.id);
    return r == null ? null : requestStateWord(context, r);
  }
  final i = book.invoiceOfTx(t.id);
  return i == null ? null : payStateWord(context, i);
}

/// "Requested from Piotr", "Paid invoice — Coffee Roasters"; null for a plain payment.
String? invoiceTitleOf(BuildContext context, Tx t) {
  if (!t.isInvoice) return null;
  final l = context.l10n;
  return t.incoming ? l.deskInvIssuerTo(whoOf(l, t)) : l.deskInvActFrom(whoOf(l, t));
}

/// A request this wallet sent that is not paid, waiting or ended: never shown as money received.
bool txAsked(Tx t) => t.isInvoice && t.incoming && (t.state == TxState.waitingRecipient || t.state == TxState.cancelled);
