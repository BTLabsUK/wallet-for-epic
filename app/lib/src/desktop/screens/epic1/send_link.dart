// SPDX-License-Identifier: Apache-2.0
/// Send for an epic1 link (spec D3): one field, "epic1 link or contact". A link is read, an
/// unknown server asked about, reviewed with its server and paid. The Payment sent modal
/// follows; under it the page waits for the recipient with "Try next server" and "Cancel and
/// unlock", and gives way to Send's start, the classic form, once the payment is answered. A
/// contact goes to the paired send, and a classic address or transaction goes back to the
/// classic form or Import.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contact_epic1.dart';
import '../../../epic1.dart';
import '../../../epic1_hosts.dart';
import '../../../l10n.dart' show LocalizedFormatException;
import '../../../providers.dart' show defaultMinimumConfirmations;
import '../../../recipient.dart' show epic1AddressOnly, epic1Unwrap;
import '../../../scan/scan_router.dart';
import '../../../trust_ids.dart';
import '../../../ui/theme/brand.dart' show GlyphTile;
import '../../../ui/theme/epic1_mark.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../app/tour.dart' show TourTarget;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../scan/desk_scan.dart';
import '../scan/desk_scan_text.dart';
import '../in_person/in_person_entry.dart' show openDeskInPersonText, openDeskPayInPerson;
import '../transfer/contact_picker.dart' show contactEpic1Link, showContactPicker;
import '../transfer/file_panels.dart' show ResultGlyph, ResultPanel;
import '../transfer/import_tx_screen.dart' show ImportArgs;
import '../transfer/payment_sent.dart';
import '../transfer/send_screen.dart' show SendArgs, SendSummaryPanel;
import 'epic1_files.dart';

enum _Step { form, waiting }

class Epic1SendPage extends ConsumerStatefulWidget {
  const Epic1SendPage({super.key, this.code, this.amount});

  /// A link or text Send opens with (a desktop link, [SendArgs.code]).
  final String? code;

  /// The amount Send opens with (an amount typed on Home); a link's own amount stands over it.
  final String? amount;

  @override
  ConsumerState<Epic1SendPage> createState() => _Epic1SendPageState();
}

class _Epic1SendPageState extends ConsumerState<Epic1SendPage> {
  final _to = TextEditingController();
  final _amount = TextEditingController();
  String _last = '';
  String Function(AppLocalizations l)? _error;
  String? _amountError;
  bool _reading = false;
  String? _link;
  Epic1LinkInfo? _info;
  bool _hostsOk = false;
  _Step _step = _Step.form;
  bool _busy = false;

  /// The network fee for the amount, as Send estimates it; null until it comes.
  int? _fee;
  int _feeAsked = 0;
  Epic1Payment? _pay;
  String? _payError;

  /// The amount of [_pay], as sent.
  int _paid = 0;

  /// The Payment sent modal is on screen.
  bool _sentShown = false;

  /// The payment was answered while the modal was on screen: Send's start follows the modal.
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _amount.text = widget.amount ?? '';
    final code = widget.code;
    if (code != null && code.trim().isNotEmpty) {
      // In the field as a paste would put it; what it is not clears it.
      _to.text = _last = code.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_open(code));
      });
    }
  }

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    super.dispose();
  }

  Epic1Wallet? get _e1 => ref.read(deskApiProvider).epic1;

  void _fail(String Function(AppLocalizations l) error) => setState(() {
    _error = error;
    _reading = false;
    _link = null;
    _info = null;
  });

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim();
    if (t == null || t.isEmpty || !mounted) return;
    _to.text = t;
    _last = t;
    await _open(t);
  }

  Future<void> _scan() async {
    final r = await deskScanQr(context, title: context.l10n.scanQrTitle, hint: context.l10n.scanQrHint);
    final t = r?.scanText;
    if (t == null || t.isEmpty || !mounted) return;
    _to.text = t;
    _last = t;
    await _open(t);
  }

  /// One change of 8 or more characters is a paste and is read at once; typing only clears
  /// the error.
  void _changed(String text) {
    final pasted = text.length - _last.length >= 8;
    _last = text;
    // Emptied: the classic form is Send's start, and it keeps the amount typed here.
    if (text.trim().isEmpty) return _start(amount: _amount.text.trim());
    if (pasted) {
      unawaited(_open(text));
      return;
    }
    setState(() {
      _error = null;
      if (_link != null && text.trim() != _link) {
        _link = null;
        _info = null;
      }
    });
  }

  /// A pasted or opened [text]: an epic1 link, an epic1 file's text, an in-person code, or
  /// a classic code, which goes back to its own screen.
  Future<void> _open(String text) async {
    final t = epic1Unwrap(text.trim());
    if (t.isEmpty) return;
    setState(() {
      _error = null;
    });
    if (looksLikeEpictx(t)) {
      setState(() => _to.clear());
      _last = '';
      await openDeskEpictx(context, ref, t);
      return;
    }
    // An epic1 address alone names no server, so it cannot be paid: the line says so.
    if (epic1AddressOnly(t)) {
      final verdict = await checkEpic1(_e1, t);
      if (mounted) _fail((l) => epic1CheckText(l, verdict, invalid: l.deskE1ErrNotLink) ?? l.deskE1ErrNotLink);
      return;
    }
    if (looksLikeEpic1Link(t)) return _read(t);
    if (await openDeskInPersonText(context, t)) {
      if (mounted) setState(() => _to.clear());
      _last = '';
      return;
    }
    if (!mounted) return;
    final nav = ref.read(deskNavProvider.notifier);
    switch (deskClassify(ref.read(deskApiProvider), t)) {
      // A classic address, request or transaction goes back to its own screen.
      case ScannedAddress() || PaymentRequest() || WrongNetwork() || PaymentLink() || PairingLink():
        nav.go(DeskRoute.send, SendArgs(code: t));
      case SlateText() || SlateFrames():
        nav.go(DeskRoute.importTx, ImportArgs(text: t));
      default:
        // No code: a name, so the contacts are searched for it, as the field's line says
        // ("epic1 link or contact").
        await _pick(query: t);
    }
  }

  Future<void> _read(String link) async {
    final e1 = _e1;
    if (e1 == null) return;
    setState(() {
      _reading = true;
      _info = null;
      _link = null;
    });
    final Epic1LinkInfo info;
    try {
      info = await e1.readLink(link);
    } on Object catch (e) {
      if (mounted) _fail((l) => deskErrorText(e, l));
      return;
    }
    if (!mounted) return;
    final unknown = epic1UnknownHost(info.hosts);
    if (unknown != null) {
      final ok = await _askServer(unknown.label);
      if (!mounted) return;
      if (!ok) {
        setState(() => _reading = false);
        return;
      }
      unawaited(rememberEpic1Hosts([unknown]));
    }
    setState(() {
      _reading = false;
      _link = link;
      _info = info;
      // The review shows the server and an unknown one was confirmed: LEPIC pays only with this.
      _hostsOk = true;
      _amountError = null;
    });
    unawaited(_estimate());
  }

  Future<bool> _askServer(String host) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('e1-unknown-server'),
        title: l.deskE1UnknownServerTitle,
        description: l.deskE1UnknownServerBody(host),
        icon: EIcons.server,
        tone: ETone.warn,
        actions: [
          EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
          EButton.primary(key: const ValueKey('e1-use-server'), label: l.deskE1UseServer, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _pick({String query = ''}) async {
    final c = await showContactPicker(context, send: true, query: query);
    if (c == null || !mounted) return;
    // No pairing that takes epic1: the contact's epic1 link is paid, as if pasted.
    if (contactEpic1Link(ref, c, watch: false) case final link?) {
      _to.text = link;
      _last = link;
      return _open(link);
    }
    // The paired send: it goes native by itself for a contact with epic1.
    ref.read(deskNavProvider.notifier).go(DeskRoute.send, SendArgs(contact: c));
  }

  int? _nano() {
    final l = context.l10n;
    final raw = _amount.text.trim();
    if (raw.isEmpty) {
      setState(() => _amountError = l.deskSendErrAmountEnter);
      return null;
    }
    final int nano;
    try {
      nano = parseEpicIn(l, raw);
    } on LocalizedFormatException catch (e) {
      setState(() => _amountError = e.text(l));
      return null;
    }
    if (nano <= 0) {
      setState(() => _amountError = l.deskSendErrAmountZero);
      return null;
    }
    return nano;
  }

  /// The amount the summary shows: the link's own, else the typed one; 0 when none is valid.
  int get _shownNano {
    final fixed = _info?.amount;
    if (fixed != null) return fixed.toInt();
    try {
      final n = parseEpicIn(context.l10n, _amount.text.trim());
      return n > 0 ? n : 0;
    } on Object {
      return 0;
    }
  }

  /// Estimates the fee for the amount shown, as Send does; the last ask wins.
  Future<void> _estimate() async {
    final n = _shownNano;
    final ask = ++_feeAsked;
    if (n <= 0) {
      if (_fee != null) setState(() => _fee = null);
      return;
    }
    try {
      final fee = await ref.read(deskApiProvider).estimateFee(n);
      if (mounted && ask == _feeAsked) setState(() => _fee = fee);
    } on Object {
      if (mounted && ask == _feeAsked) setState(() => _fee = null);
    }
  }

  void _review() {
    if (_info == null) {
      unawaited(_open(_to.text));
      return;
    }
    if (_info!.amount == null && _nano() == null) return;
    unawaited(_openReview());
  }

  /// The review over the form, as Send's: what goes where and through which server.
  Future<void> _openReview() async {
    final info = _info!;
    final send = await showEDialog<bool>(
      context,
      builder: (ctx) {
        final l = ctx.l10n;
        final nano = info.amount?.toInt() ?? parseEpicIn(l, _amount.text);
        final server = info.hosts.firstOrNull?.label;
        return EDialog(
          key: const ValueKey('e1-review-panel'),
          title: l.deskE1ReviewTitle,
          icon: EIcons.send,
          body: EFacts([
            (l.deskE1To, Text(shortMiddle(info.address), style: ctx.ts.mono(size: Fs.sm))),
            (l.deskSendAmount, Text(epicTextL(l, nano))),
            if (_fee case final fee?) ...[(l.deskSendNetworkFee, Text(epicTextL(l, fee))), (l.deskSendTotal, Text(epicTextL(l, nano + fee), style: ctx.ts.strong))],
            if (server != null) (l.deskE1Server, KeyedSubtree(key: const ValueKey('e1-review-server'), child: Text(server))),
          ]),
          actions: [
            EButton(key: const ValueKey('e1-back'), label: l.deskE1Back, onPressed: () => Navigator.of(ctx).pop(false)),
            EButton.primary(
              key: const ValueKey('e1-send'),
              semanticsId: TrustIds.e1Send,
              label: l.deskE1Send,
              icon: EIcons.send,
              autofocus: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
    if (send == true && mounted) await _send();
  }

  Future<void> _send() async {
    final e1 = _e1;
    final info = _info;
    final link = _link;
    if (e1 == null || info == null || link == null) return;
    final nano = info.amount == null ? _nano() : null;
    if (info.amount == null && nano == null) return;
    final amount = info.amount?.toInt() ?? nano!;
    setState(() => _busy = true);
    final conf = ref.read(deskProvider).balance?.minConfirmations ?? defaultMinimumConfirmations;
    try {
      final p = await e1.payLink(
        link: link,
        amount: nano == null ? null : BigInt.from(nano),
        minimumConfirmations: BigInt.from(conf),
        hostsOk: _hostsOk,
      );
      if (!mounted) return;
      setState(() {
        _pay = p;
        _paid = amount;
        _payError = null;
        _step = _Step.waiting;
      });
      unawaited(ref.read(deskProvider.notifier).refresh());
      // A payment no server took is not sent yet: the page says so and offers the next server.
      if (p.posted != null) unawaited(_showSent(p));
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The Payment sent modal for [p], over the waiting page.
  Future<void> _showSent(Epic1Payment p) async {
    _sentShown = true;
    await showPaymentSent(context, txId: p.txId, amount: _paid, address: p.address, method: context.l10n.deskE1PaymentLink, epic1Link: true);
    _sentShown = false;
    // Answered meanwhile: Send's start, unless the modal left for Activity.
    if (mounted && _answered && ref.read(deskNavProvider).route == DeskRoute.send) _start();
  }

  Future<void> _next() async {
    final e1 = _e1;
    final p = _pay;
    if (e1 == null || p == null) return;
    setState(() => _busy = true);
    try {
      final again = await e1.postNext(slateId: p.slateId, hostsOk: _hostsOk);
      if (!mounted) return;
      setState(() {
        _pay = again;
        _payError = null;
      });
      // The first server that took it: now it is sent.
      if (p.posted == null && again.posted != null) unawaited(_showSent(again));
    } on Object catch (e) {
      if (mounted) setState(() => _payError = deskErrorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final p = _pay;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(p.txId);
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskTxNotCancelled, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Back to Send's start, the classic form: To cleared, or the payment done. It opens empty
  /// (but for [amount]) with To focused, whatever the classic form held before the link.
  void _start({String amount = ''}) => ref
      .read(deskNavProvider.notifier)
      .reset(DeskRoute.send, SendArgs(amount: amount.isEmpty ? null : amount, focusTo: true));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The payment's row in the list says when it was answered or cancelled.
    Tx? rowOf(List<Tx>? txs) => _pay == null ? null : txs?.where((t) => t.id == _pay!.txId).firstOrNull;
    final tx = rowOf(ref.watch(deskProvider.select((s) => s.txs)));
    // Answered: back to Send's start, with a toast. While the modal is open it says how far the
    // payment is, and the start waits until it closes: the classic form takes the focus.
    ref.listen(deskProvider.select((s) => s.txs), (_, txs) {
      final row = rowOf(txs);
      if (_answered || row == null || row.state == TxState.waitingRecipient || row.state == TxState.cancelled) return;
      if (_sentShown) return setState(() => _answered = true);
      showEToast(context, context.l10n.deskPaySentTitle, tone: ETone.ok);
      _start();
    });
    final Widget body = switch (_step) {
      _Step.waiting when tx?.state == TxState.cancelled => ResultPanel(
        key: const ValueKey('e1-cancelled'),
        glyph: const ResultGlyph(icon: EIcons.cancel, tone: ETone.neutral),
        title: l.deskE1Cancelled,
        text: epicTextL(l, tx!.amount),
        actions: [EButton.primary(key: const ValueKey('e1-done'), label: l.deskE1Done, onPressed: _start)],
      ),
      // Answered under the open modal: nothing left to wait for here.
      _Step.waiting when _answered => const SizedBox.shrink(),
      _Step.waiting => _waiting(_pay!),
      _Step.form => _form(),
    };
    return EPage(
      title: l.deskSendTitle,
      width: EPageWidth.mid,
      child: body,
    );
  }

  /// Send's form with an epic1 link in To: the To card (Pay in person under it), the Amount
  /// card, and Send's summary beside them with Review; under each other when narrow. Once the
  /// link is read the To field gives way to the recipient's row, the link's note and the seal
  /// line.
  Widget _form() {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final info = _info;
    final error = _error?.call(l);
    final empty = _to.text.trim().isEmpty;
    final st = ref.watch(deskProvider);
    final n = _shownNano;
    Widget card(Key? key, List<Widget> children) => EPanel(
      key: key,
      padding: EdgeInsets.all(Sp.panel),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
    final toCard = TourTarget(
      id: 'e1-send-form',
      child: card(const ValueKey('e1-send-form'), [
        if (info != null)
          EField(
            label: l.deskSendTo,
            child: _Recipient(address: info.address, onClear: _start),
          )
        else
          EField(
            label: l.deskSendTo,
            error: error,
            help: error == null && empty ? l.deskE1SendField : null,
            child: EInput(
              key: const ValueKey('e1-send-to'),
              semanticsId: TrustIds.e1SendTo,
              controller: _to,
              mono: true,
              fadeEnd: true,
              autofocus: true,
              invalid: error != null,
              hint: l.deskE1SendFieldHint,
              semanticLabel: l.deskE1SendFieldSem,
              onChanged: _changed,
              onSubmitted: (t) => unawaited(_open(t)),
              trailingTabStop: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reading)
                    Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x2), child: ESpinner(size: 16.u))
                  else if (empty)
                    EIconButton(key: const ValueKey('e1-paste'), icon: EIcons.paste, label: l.commonPaste, size: EBtnSize.inline, tabStop: false, onPressed: _paste)
                  else
                    EIconButton(key: const ValueKey('e1-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, onPressed: _start),
                  if (empty && !_reading) ...[SizedBox(width: Sp.x1), DeskScanButton(key: const ValueKey('e1-scan'), onScan: _scan, size: EBtnSize.inline)],
                  SizedBox(width: Sp.x1),
                  EButton(key: const ValueKey('e1-contacts'), label: l.deskSendContacts, icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                ],
              ),
            ),
          ),
        if (empty && !_reading) const DeskNoCameraLine(),
        if (info?.message case final m? when m.isNotEmpty) ...[
          SizedBox(height: Sp.x3),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.deskE1LinkNote, style: ts.caption),
                Text(m, key: const ValueKey('e1-link-message'), style: ts.body.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
        // LEPIC seals every payment to a link, so the line holds before it is sent.
        if (info != null) ...[
          SizedBox(height: Sp.x3),
          Container(
            key: const ValueKey('e1-seal'),
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            decoration: BoxDecoration(color: c.okSoft, borderRadius: BorderRadius.circular(Rad.sm)),
            child: Row(
              children: [
                Icon(EIcons.sealed, size: Ctl.iconSm, color: c.ok),
                SizedBox(width: Sp.x2),
                Epic1Text(l.deskE1Sealed, style: ts.body.copyWith(color: c.ok, fontWeight: FontWeight.w500)),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _SealSweep(words: metaLine([if (n > 0) epicTextL(l, n), info.message])),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: Sp.x2),
        // Flush with the field's edge, as Send's Pay with a file.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Transform.translate(
            offset: Offset(-EButton.labelInset(EBtnSize.inline), 0),
            child: EButton.ghost(
              key: const ValueKey('e1-pay-in-person'),
              semanticsId: TrustIds.e1PayInPerson,
              label: l.deskE1PayInPerson,
              icon: EIcons.phone,
              size: EBtnSize.inline,
              onPressed: () => unawaited(openDeskPayInPerson(context)),
            ),
          ),
        ),
      ]),
    );
    final amountCard = card(null, [
      EField(
        label: l.deskSendAmount,
        error: _amountError,
        child: info?.amount != null
            ? Wrap(
                spacing: Sp.x3,
                runSpacing: Sp.x1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(epicTextL(l, info!.amount!.toInt()), key: const ValueKey('e1-amount-fixed'), style: ts.mono(size: Fs.sm)),
                  EBadge(l.deskE1AmountFixed, key: const ValueKey('e1-amount-set')),
                ],
              )
            : EInput(
                key: const ValueKey('e1-amount'),
                semanticsId: TrustIds.e1Amount,
                controller: _amount,
                mono: true,
                hint: '0',
                invalid: _amountError != null,
                semanticLabel: l.deskSendAmountSem,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  setState(() => _amountError = null);
                  unawaited(_estimate());
                },
                onSubmitted: (_) => _review(),
              ),
      ),
    ]);
    final summary = SendSummaryPanel(
      titleTrailing: info == null ? null : Epic1Mark(fontSize: Fs.md, color: c.text),
      via: info == null ? null : l.methodEpicbox,
      viaIcon: EIcons.epicbox,
      to: info == null ? null : shortMiddle(info.address, keep: 18),
      amount: n,
      fee: n > 0 ? _fee : null,
      feeLoading: n > 0 && _fee == null,
      spendable: st.balance?.spendable,
      updating: st.status?.syncProgress != null,
      hint: error != null || _amountError != null ? l.deskSendHintFix : (info == null ? l.deskE1SendFieldHint : l.deskSendNothingLeaves),
      reviewing: _reading || _busy,
      onReview: empty || _reading || _busy ? null : _review,
      reviewLabel: l.deskE1Review,
      reviewKey: const ValueKey('e1-review'),
      reviewId: TrustIds.e1Review,
      lockRows: false,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [toCard, SizedBox(height: Sp.x3), amountCard]);
        if (box.maxWidth >= Lay.xl) return PanelRow(main: form, side: summary, sideWidth: Ctl.sideSm);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, SizedBox(height: Sp.col), summary]);
      },
    );
  }

  Widget _row(String label, String value, {Key? key, bool mono = false}) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(vertical: Sp.x2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120.u, child: Text(label, style: context.ts.bodyDim)),
        Expanded(child: Text(value, style: mono ? context.ts.mono(size: Fs.sm) : context.ts.body)),
      ],
    ),
  );

  Widget _waiting(Epic1Payment p) {
    final l = context.l10n;
    final c = context.dc;
    final host = p.postedHost;
    return EPanel(
      key: const ValueKey('e1-waiting'),
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(EIcons.clock, size: Ctl.icon, color: c.info),
              SizedBox(width: Sp.x3),
              Expanded(child: Text(l.deskE1Waiting, style: context.ts.h3)),
            ],
          ),
          SizedBox(height: Sp.x3),
          _row(l.deskE1To, shortMiddle(p.address), mono: true),
          if (host != null) _row(l.deskE1Server, host, key: const ValueKey('e1-waiting-server')),
          if (host == null || _payError != null) ...[
            SizedBox(height: Sp.x3),
            ENotice(key: const ValueKey('e1-not-posted'), title: _payError ?? l.deskE1NotPosted, tone: ETone.warn),
          ],
          SizedBox(height: Sp.x5),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            children: [
              EButton(
                key: const ValueKey('e1-cancel-unlock'),
                semanticsId: TrustIds.e1CancelUnlock,
                label: l.deskE1CancelUnlock,
                icon: EIcons.lock,
                onPressed: _busy ? null : () => unawaited(_cancel()),
              ),
              EButton(
                key: const ValueKey('e1-try-next'),
                semanticsId: TrustIds.e1TryNext,
                label: l.deskE1TryNext,
                icon: EIcons.refresh,
                busy: _busy,
                onPressed: _busy ? null : () => unawaited(_next()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The link's recipient in the To field's place, as tall and edged as the input: the epic1
/// glyph on a ticked tile, the address short with its ends in the accent, what it is, and Clear.
class _Recipient extends StatelessWidget {
  const _Recipient({required this.address, required this.onClear});

  final String address;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    return Container(
      key: const ValueKey('e1-recipient'),
      constraints: BoxConstraints(minHeight: Ctl.md),
      padding: EdgeInsetsDirectional.only(start: Sp.x2, end: Sp.x1),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineField)),
      child: Row(
        children: [
          GlyphTile(size: 28.u, child: Epic1Glyph(size: Ctl.iconSm, color: c.text)),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [Epic1ShortAddress(address), Text(l.deskE1PaymentLink, style: context.ts.caption)],
            ),
          ),
          SizedBox(width: Sp.x2),
          EIconButton(key: const ValueKey('e1-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, onPressed: onClear),
        ],
      ),
    );
  }
}

/// The payment's [words] turning into blocks at the end of the seal line: once, after a short
/// pause, and the blocks at once when animations are off. Decoration, not read out.
class _SealSweep extends StatefulWidget {
  const _SealSweep({required this.words});

  final String words;

  @override
  State<_SealSweep> createState() => _SealSweepState();
}

class _SealSweepState extends State<_SealSweep> with SingleTickerProviderStateMixin {
  static const _pause = Duration(milliseconds: 240);
  late final AnimationController _run = AnimationController(vsync: this, duration: _pause + Dur.slow);
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _run,
    curve: Interval(_pause.inMilliseconds / (_pause + Dur.slow).inMilliseconds, 1, curve: Motion.easeOut),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _run.value = 1;
    } else {
      _run.forward();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, words) => CustomPaint(
          foregroundPainter: _BlocksPainter(c.ok.withValues(alpha: 0.5), _sweep.value, block: 5.u, gap: 2.u),
          child: Opacity(opacity: 1 - _sweep.value, child: words),
        ),
        child: Text(widget.words, style: context.ts.mono(size: Fs.xs, color: c.dim), maxLines: 1, softWrap: false, overflow: TextOverflow.clip),
      ),
    );
  }
}

/// A row of small blocks over the first [shown] share of the width.
class _BlocksPainter extends CustomPainter {
  const _BlocksPainter(this.color, this.shown, {required this.block, required this.gap});

  final Color color;
  final double shown;
  final double block;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final end = size.width * shown;
    for (var x = 0.0; x < end; x += block + gap) {
      final right = x + block;
      canvas.drawRect(Rect.fromLTRB(x, gap, right < end ? right : end, size.height - gap), paint);
    }
  }

  @override
  bool shouldRepaint(_BlocksPainter old) => old.color != color || old.shown != shown || old.block != block || old.gap != gap;
}
