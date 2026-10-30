// SPDX-License-Identifier: Apache-2.0
import '../../../network_gate.dart' show NetGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../devices/device_ending.dart' show deviceEndingLabel;
import '../../../l10n.dart' show localClock, localDay, localDayMonth;
import '../../../models.dart' show DeviceEnding;
import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../data/pairing_state.dart' show DeskPairNet, deskPairNetProvider, deskPairingNameProvider, deskPairingSlateProvider, deskPairsProvider;
import '../../data/method_names.dart';
import '../../widgets/kit.dart';
import '../invoices/invoice_parts.dart' show payStateWord, requestStateWord;
import 'tx_label.dart';

export '../../data/method_names.dart' show methodLabel;

/// Who the other side is: the contact's name, else a shortened address or the file name, else
/// what kind of transaction it was.
String whoOf(AppLocalizations l, Tx t) {
  // A payment another linked device made: the row says where it came from.
  if (t.deviceName != null) return l.txSentFromDevice(t.deviceName!);
  if (t.contactName != null) return t.contactName!;
  if (t.toSelf) return l.deskTxThisWallet;
  if (t.coinbase) return l.deskTxMiningReward;
  if (t.otherWallet && t.incoming && t.receivedOn != null) return l.txReceivedOnDevice(t.receivedOn!);
  if (t.otherWallet) return t.incoming ? l.txReceivedByOtherWallet : (t.unverified ? l.txSentFromOtherWalletUnverified : l.txSentFromOtherWallet);
  // A scan find names no one until the user types a sender (then the address, as for any row).
  if (t.foundByScan && t.counterparty == null) return foundTexts(l, t).label;
  final cp = t.counterparty;
  // An invoice from a backup with no address (asked by file) is named as the live one is.
  if (cp == null && t.fromBackup && !t.isInvoice) return t.incoming ? l.deskTxReceived : l.deskTxSent;
  if (cp == null) return t.incoming ? l.deskTxUnknownSender : l.deskTxUnknownRecipient;
  // A file is the transaction file; its name is the row's second line ([fileNameOf]).
  if (t.method == TxMethod.file) return l.slateFileTitle;
  // An invoice's other side is an Epicbox address: first six and last six, no host.
  return shortAddress(cp, compact: t.isInvoice);
}

/// The words for a payment a scan found with no record, by which scan found it. An
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

/// The paired contact a payment went to or came from through its mailbox (RFC 9.1: no
/// address), by name, or null. The core's link ([Tx.pairingId]) names it at every state, both
/// ways; without one, rows ask only for a send still waiting for its answer, as each ask reads
/// the wallet's payments, and [any] asks for any such send (the detail pane).
String? deskTxMailboxName(WidgetRef ref, Tx t, {bool any = false}) {
  if (t.isInvoice || t.fromBackup || !ref.watch(deskPairsProvider)) return null;
  if (t.pairingId case final id?) {
    final name = ref.watch(deskPairingNameProvider(id));
    return name.isEmpty ? null : name;
  }
  if (t.incoming || t.counterparty != null || t.slateId.isEmpty) return null;
  if (!any && t.state != TxState.waitingRecipient) return null;
  final pairingId = ref.watch(deskPairingSlateProvider(t.slateId)).value?.pairingId;
  if (pairingId == null) return null;
  final name = ref.watch(deskPairingNameProvider(pairingId));
  return name.isEmpty ? null : name;
}

/// [statusOf], with "Waiting for Anna to sign" for a send through [mailbox]'s mailbox, and
/// "Waiting for Anna" for a payment from it: Anna's wallet finalizes by itself, no file. While
/// Epicbox is off ([paused]) a send waits in the outbox, and the row says that instead.
(String, ETone) statusWithMailbox(AppLocalizations l, Tx t, String? mailbox, {bool paused = false}) =>
    mailbox != null && t.state == TxState.waitingRecipient && !t.undelivered && !t.senderPosted && !t.senderCancelled
    ? (t.incoming ? l.txStatusWaitingFor(mailbox) : (paused ? l.contactPausedEpicboxOff : l.deskTxStatusWaitingFor(mailbox)), paused ? ETone.warn : ETone.info)
    : statusOf(l, t);

/// A file payment's file name, without its folder; null for any other payment.
String? fileNameOf(Tx t) => t.method == TxMethod.file && t.counterparty != null ? t.counterparty!.split(RegExp(r'[\\/]')).last : null;

/// What a row is called: the user's label, else [whoOf].
String titleOf(AppLocalizations l, Tx t) => t.labelText ?? whoOf(l, t);

/// Whether [whoOf] names someone or something (a contact, an address, a file), which joins the
/// second line when a label takes the title.
bool whoNamesSomeone(Tx t) => !t.toSelf && !t.coinbase && !t.otherWallet && (t.contactName != null || t.counterparty != null);

/// A line explaining [whoOf] where it needs one.
String? whoTip(AppLocalizations l, Tx t) =>
    t.detail ?? (t.foundByScan && t.contactName == null && t.counterparty == null ? foundTexts(l, t).tip : (t.fromBackup ? l.deskTxBackupTip : null));

/// Whether the name is an address (shown in mono).
bool whoIsAddress(Tx t) => t.deviceName == null && t.contactName == null && !t.toSelf && t.counterparty != null && t.method != TxMethod.file;

/// How it travelled, in the short tier of a row's tag, or null when that is not known (mining
/// rewards, scan finds).
String? methodOf(AppLocalizations l, Tx t) => t.coinbase || t.otherWallet || t.foundByScan ? null : methodShortLabel(l, t.method);

/// How a scan find came, in the words of the details dialog; null until the user says. [short]
/// for a row's tag.
String? restoredMethodOf(AppLocalizations l, Tx t, {bool short = false}) {
  if (!t.foundByScan || t.transport == null) return null;
  return short ? methodShortLabel(l, t.method) : methodLabel(l, t.method);
}

IconData iconOf(Tx t) => switch (t.method) {
  TxMethod.file => t.incoming ? EIcons.fileDown : EIcons.fileUp,
  _ => t.incoming ? EIcons.receive : EIcons.send,
};

/// Whether the state of [t] is another linked device's word (held, ended there, released here,
/// expired by a fallback) and not yet the chain's: the row carries the info mark.
bool deskStatusFromDevice(Tx t) => t.deviceName != null && t.height == null;

/// The info mark behind such a status: hover or focus says where the status comes from.
Widget deskDeviceStatusInfo(AppLocalizations l, Tx t) => Padding(
  padding: EdgeInsetsDirectional.only(start: Sp.x1),
  child: EInfoHint(l.devicesStatusInfo(t.deviceName ?? ''), title: l.txSentFromDevice(t.deviceName ?? ''), icon: EIcons.devices),
);

/// The state in words, with a tone for its colour.
(String, ETone) statusOf(AppLocalizations l, Tx t) => t.deviceEnding != null
    ? (deviceEndingLabel(l, t.deviceEnding!, t.deviceName ?? ''), t.deviceEnding == DeviceEnding.failed ? ETone.risk : ETone.warn)
    : t.fromBackup
    ? (l.deskTxFromBackup, ETone.neutral)
    : t.immature
    ? (l.deskTxStatusImmature, ETone.info)
    : switch (t.state) {
        TxState.waitingRecipient when t.undelivered => (l.deskTxStatusUndelivered, ETone.warn),
        // The sender's word: over, and cleared by itself (sender_cancel.dart).
        TxState.waitingRecipient || TxState.cancelled when t.incoming && t.senderCancelled => (l.txStatusSenderCancelled, ETone.neutral),
        // The sender's word, not the chain's: in progress, never Received before a block.
        TxState.waitingRecipient when t.incoming && t.senderPosted => (l.deskTxStatusSenderPosted, ETone.info),
        TxState.waitingRecipient => (
          t.incoming ? l.deskTxStatusWaitingSender : (t.method == TxMethod.file ? l.deskTxStatusWaitingResponseFile : l.deskTxStatusWaitingRecipient),
          // Waiting is in progress (blue); amber only for a wait that went wrong.
          ETone.info,
        ),
        // Finished under Kill switch: a device that is online posts it (in progress, not a fault).
        TxState.posted when t.notPosted && NetGate.killSwitch => (l.txPostElsewhere, ETone.info),
        TxState.posted when t.notPosted => (l.deskTxStatusNotPosted, ETone.warn),
        TxState.posted => (l.deskTxStatusWaitingBlock, ETone.neutral),
        // Kill switch asks no node: the count is the one seen last.
        TxState.confirming when NetGate.killSwitch => (l.lastKnownConfirming(l.deskTxStatusConfirming(t.confirmations, t.confirmationsNeeded)), ETone.info),
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
  const FitMoney(this.nano, {super.key, required this.sizes, this.color, this.sign = false, this.unit = false, this.weight, this.width, this.decimals});

  final int nano;
  final List<double> sizes;

  /// The width to fit, when the caller knows it (inside IntrinsicHeight, where a
  /// LayoutBuilder can't measure).
  final double? width;
  final Color? color;
  final bool sign;
  final bool unit;
  final FontWeight? weight;

  /// At least this many decimals (a row of tiles shows one precision).
  final int? decimals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final text = '${sign && nano > 0 ? '+' : ''}${hidden ? '••••••' : formatEpicL(context.l10n, nano, minDecimals: decimals ?? 4)}${unit ? ' EPIC' : ''}';
    final style = context.ts.mono(weight: weight ?? FontWeight.w500);
    if (width != null) {
      return EMoney(nano, size: fitFontSize(context, text, style, sizes, width!), color: color, sign: sign, unit: unit, weight: weight, decimals: decimals);
    }
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.maxWidth.isFinite ? fitFontSize(context, text, style, sizes, box.maxWidth) : sizes.first;
        return ClipRect(
          child: EMoney(nano, size: size, color: color, sign: sign, unit: unit, weight: weight, decimals: decimals),
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

/// The 36 px square with the direction icon: green in, red out, grey when cancelled.
class TxIcon extends StatelessWidget {
  const TxIcon(this.tx, {super.key, this._size});

  final Tx tx;
  final double? _size;
  double get size => _size ?? 36.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final off = tx.state == TxState.cancelled;
    // Direction, as the phone draws it: green in, red out, grey when cancelled (txSent and kin).
    final color = off ? c.txCancelled : (txAsked(tx) ? c.dim : (tx.incoming ? c.txReceived : c.txSent));
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
    if (tx.immature) return Icon(EIcons.sand, size: size * 0.75, color: c.info);
    // The chain was not asked about a payment only a backup knows: no count to show.
    if (tx.fromBackup) return Icon(EIcons.archive, size: size * 0.75, color: c.dim);
    return switch (tx.state) {
      TxState.cancelled => ERing(confirmations: 0, size: size, off: true),
      TxState.waitingRecipient => Icon(EIcons.sand, size: size * 0.75, color: tx.undelivered ? c.warn : c.info),
      TxState.posted => ERing(confirmations: 0, size: size),
      _ => ERing(confirmations: tx.confirmations, needed: tx.confirmationsNeeded, size: size),
    };
  }
}

/// The amount column: signed, green when in, red when out, struck through when cancelled; fee under a send.
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
    // A request not paid yet is not money: neutral, no sign, "Requested".
    final asked = txAsked(tx);
    final color = off ? c.txCancelled : (asked ? c.text : (tx.incoming ? c.txReceived : c.txSent));
    final line = asked && tx.state == TxState.waitingRecipient ? context.l10n.deskInvUnpaid : sub ?? (showFee && !tx.incoming && tx.fee > 0 ? context.l10n.deskTxFee(formatEpicL(context.l10n, tx.fee)) : null);
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
  const TxRow({super.key, required this.tx, required this.onTap, this.compact = false, this.selected = false, this.onFinalize, this.title, this.labelEditable = false});

  final Tx tx;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;
  final VoidCallback? onFinalize;

  /// Replaces the name (a contact's own history says Sent / Received).
  final String? title;

  /// Shows the pen that edits the label in place (Activity).
  final bool labelEditable;

  @override
  ConsumerState<TxRow> createState() => _TxRowState();
}

class _TxRowState extends ConsumerState<TxRow> {
  bool _hover = false;

  /// Something in the row has the focus (the row itself or its pen): the pen shows.
  bool _within = false;
  final FocusNode _pen = FocusNode();

  @override
  void dispose() {
    _pen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // A narrow list gets the compact row: no room for the status and time columns.
    builder: (context, box) => _row(context, widget.compact || box.maxWidth < txRowFullWidth),
  );

  TxLabelSite get _site => (key: widget.tx.key, place: txLabelRowPlace);

  void _closeLabel({required bool byKey}) {
    ref.read(txLabelEditingProvider.notifier).close(widget.tx.key, txLabelRowPlace);
    // Enter and Esc leave the focus where the pen is; a click elsewhere keeps it there.
    if (byKey) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _pen.requestFocus() : null);
  }

  Widget _row(BuildContext context, bool compact) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.tx;
    final mailbox = deskTxMailboxName(ref, t);
    final (word, tone) =
        invoiceStatusOf(context, ref, t) ??
        statusWithMailbox(context.l10n, t, mailbox, paused: mailbox != null && ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff);
    final toneColor = switch (tone) {
      ETone.ok => c.dim,
      ETone.warn => c.warn,
      ETone.info => c.info,
      ETone.gold => c.accentText,
      _ => c.faint,
    };
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final l = context.l10n;
    final fromDevice = deskStatusFromDevice(t);
    // Another device's payment takes no label here: the row is rebuilt from its notices.
    final labelEditable = widget.labelEditable && t.deviceName == null;
    final editing = labelEditable && ref.watch(txLabelEditingProvider) == _site;
    final labelled = t.labelText != null && widget.title == null;
    final restoredMethod = restoredMethodOf(l, t, short: true);
    // Through a pairing's mailbox: Epicbox, though LEPIC keeps it as an export.
    final method = t.foundByScan ? foundTexts(l, t).line : (t.fromBackup ? l.deskTxFromBackup : (mailbox != null ? methodShortLabel(l, TxMethod.epicbox) : methodOf(l, t)));
    final extra = t.message ?? (DeskFeatures.paymentProofs && t.hasProof ? l.deskTxPaymentProof : null);
    // A label takes the title; who it replaced moves to the second line so nothing is lost.
    final file = fileNameOf(t);
    final replaced = (labelled || t.deviceName != null) && whoNamesSomeone(t) ? (t.contactName ?? file ?? shortAddress(t.counterparty!, compact: true)) : null;
    // A file row is titled Transaction file; the file's name is its second line.
    final fileLine = replaced == null && t.contactName == null ? file : null;
    final parts = <String>[?method, ?restoredMethod, ?replaced, ?fileLine, ?extra];
    final meta = <InlineSpan>[
      for (final (i, p) in parts.indexed) ...[
        if (i > 0)
          TextSpan(
            text: '  ·  ',
            style: TextStyle(color: c.lineField),
          ),
        TextSpan(text: p),
      ],
    ];
    // The sender, method or note the user typed on a scan find carries the tag.
    final typed = t.manualFields.any((f) => f != ManualField.label);
    final TextStyle titleStyle = ts.strong;
    final Widget name;
    if (labelled) {
      name = Text(t.labelText!, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle);
    } else if (widget.title == null && whoIsAddress(t) && !t.isInvoice) {
      name = EShortAddress(t.counterparty!, style: ts.mono(size: 12.5, weight: FontWeight.w500));
    } else {
      name = Text(widget.title ?? invoiceTitleOf(context, t) ?? mailbox ?? whoOf(l, t), maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle);
    }
    final titleLine = editing
        ? TxLabelField(
            site: _site,
            initial: t.labelText ?? '',
            style: titleStyle,
            onSave: (text) => saveTxLabel(context, ref, t, text),
            onClose: _closeLabel,
          )
        : Row(
            children: [
              Flexible(
                child: ExcludeSemantics(
                  child: _Tip(message: widget.title == null && !labelled && (t.foundByScan || t.fromBackup) ? whoTip(l, t) : null, child: name),
                ),
              ),
              if (labelEditable) ...[
                SizedBox(width: Sp.x1),
                TxPen(
                  tx: t,
                  focusNode: _pen,
                  visible: _hover || _within || widget.selected,
                  onPressed: () => ref.read(txLabelEditingProvider.notifier).open(t.key, txLabelRowPlace),
                ),
              ],
            ],
          );
    final who = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleLine,
        if (compact || meta.isNotEmpty) const SizedBox(height: 2),
        if (compact)
          ExcludeSemantics(
            child: Row(
              children: [
                TxStateMark(t, size: 15.u),
                SizedBox(width: 6.u),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: word,
                      children: [
                        if (replaced != null)
                          TextSpan(
                            text: '  ·  $replaced',
                            style: TextStyle(color: c.faint),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.small.copyWith(color: toneColor),
                  ),
                ),
                if (fromDevice) deskDeviceStatusInfo(l, t),
              ],
            ),
          )
        else if (meta.isNotEmpty || typed)
          ExcludeSemantics(
            child: Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(children: meta),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.small.copyWith(color: c.faint),
                  ),
                ),
                if (typed) ...[SizedBox(width: Sp.x2), Flexible(child: ManualTag(t, t.manualFields.firstWhere((f) => f != ManualField.label)))],
              ],
            ),
          ),
      ],
    );
    final finalizable = !compact && !t.incoming && t.method == TxMethod.file && t.state == TxState.waitingRecipient;
    final row = Row(
      children: [
        ExcludeSemantics(child: TxIcon(t)),
        SizedBox(width: Sp.x4),
        Expanded(flex: 16, child: who),
        if (!compact) ...[
          SizedBox(width: Sp.x4),
          Expanded(
            flex: 10,
            // The state, always; a file send's Finalize shows on hover or selection,
            // and in the detail pane.
            child: ExcludeSemantics(
              child: Row(
                children: [
                  TxStateMark(t),
                  SizedBox(width: Sp.x2),
                  // Under the pointer the cell offers the action in the state's place; the
                  // detail pane keeps its Finalize button.
                  if (finalizable && (_hover || _within))
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: EButton(label: l.deskTxFinalize, icon: EIcons.fileDown, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: widget.onFinalize),
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.small.copyWith(color: toneColor),
                      ),
                    ),
                  if (fromDevice) deskDeviceStatusInfo(l, t),
                ],
              ),
            ),
          ),
          SizedBox(width: Sp.x4),
          SizedBox(
            width: txTimeWidth,
            child: ExcludeSemantics(
              child: Text(
                timeOf(t),
                textAlign: TextAlign.right,
                style: ts.mono(size: Fs.xs, color: c.faint),
              ),
            ),
          ),
        ],
        SizedBox(width: Sp.x4),
        ExcludeSemantics(
          child: compact
              ? TxAmount(t, sub: compactTime(l, t))
              : SizedBox(
                  width: txAmountWidth,
                  child: Align(alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: TxAmount(t))),
                ),
        ),
      ],
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      onTap: widget.onTap,
      // A request is never read out as money received;
      // it reads Unpaid only while it is, then its state word says what became of it. The pen
      // keeps its own node.
      label: _semantics(l, t, hidden ? l.deskTxHiddenAmount : '${formatEpicL(l, t.amount)} EPIC', word),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (v) => setState(() => _within = v),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          child: Container(
            constraints: BoxConstraints(minHeight: 60.u),
            padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
            // Never null: a Container adds its ColoredBox only for a colour, so a null here would
            // rebuild the row's whole subtree on hover and drop a label being typed.
            color: widget.selected ? c.s3 : (_hover ? c.hover : Colors.transparent),
            child: row,
          ),
        ),
      ),
    );
  }
}

extension on _TxRowState {
  String _semantics(AppLocalizations l, Tx t, String amount, String status) {
    final who = titleOf(l, t);
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
    return r == null ? null : requestStateWord(context, r, t.confirmationsNeeded);
  }
  final i = book.invoiceOfTx(t.id);
  return i == null ? null : payStateWord(context, i, t.confirmationsNeeded);
}

/// "Requested from Piotr", "Paid invoice — Coffee Roasters"; null for a plain payment.
String? invoiceTitleOf(BuildContext context, Tx t) {
  if (!t.isInvoice) return null;
  final l = context.l10n;
  return t.incoming ? l.deskInvIssuerTo(whoOf(l, t)) : l.deskInvActFrom(whoOf(l, t));
}

/// A request this wallet sent that is not paid, waiting or ended: never shown as money received.
bool txAsked(Tx t) => t.isInvoice && t.incoming && (t.state == TxState.waitingRecipient || t.state == TxState.cancelled);
