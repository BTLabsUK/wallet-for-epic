// SPDX-License-Identifier: Apache-2.0
/// Send in epic1 mode (spec D3): one field, "epic1 link or contact". A link is read, an
/// unknown server asked about, reviewed with its server, paid, then waits for the recipient
/// with "Try next server" and "Cancel and unlock". A contact goes to the paired send.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../../l10n.dart' show LocalizedFormatException;
import '../../../providers.dart' show defaultMinimumConfirmations;
import '../../../scan/scan_router.dart';
import '../../../trust_ids.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../in_person/in_person_entry.dart' show openDeskInPersonText, openDeskPayInPerson;
import '../transfer/contact_picker.dart' show showContactPicker;
import '../transfer/send_screen.dart' show SendArgs;
import 'epic1_files.dart';

enum _Step { form, review, waiting }

class Epic1SendPage extends ConsumerStatefulWidget {
  const Epic1SendPage({super.key, this.code});

  /// A link or text Send opens with (a desktop link, [SendArgs.code]).
  final String? code;

  @override
  ConsumerState<Epic1SendPage> createState() => _Epic1SendPageState();
}

class _Epic1SendPageState extends ConsumerState<Epic1SendPage> {
  final _to = TextEditingController();
  final _amount = TextEditingController();
  String _last = '';
  String Function(AppLocalizations l)? _error;
  // The error is a mode line: "Settings" opens the switch.
  bool _errorSettings = false;
  String? _amountError;
  bool _reading = false;
  String? _link;
  Epic1LinkInfo? _info;
  bool _hostsOk = false;
  _Step _step = _Step.form;
  bool _busy = false;
  Epic1Payment? _pay;
  String? _payError;

  @override
  void initState() {
    super.initState();
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

  void _fail(String Function(AppLocalizations l) error, {bool settings = false}) => setState(() {
    _error = error;
    _errorSettings = settings;
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

  /// One change of 8 or more characters is a paste and is read at once; typing only clears
  /// the error.
  void _changed(String text) {
    final pasted = text.length - _last.length >= 8;
    _last = text;
    if (pasted) {
      unawaited(_open(text));
      return;
    }
    setState(() {
      _error = null;
      _errorSettings = false;
      if (_link != null && text.trim() != _link) {
        _link = null;
        _info = null;
      }
    });
  }

  /// A pasted or opened [text]: an epic1 link, an epic1 file's text, an in-person code, or
  /// a classic code this mode cannot pay.
  Future<void> _open(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _error = null;
      _errorSettings = false;
    });
    if (looksLikeEpictx(t)) {
      setState(() => _to.clear());
      _last = '';
      await openDeskEpictx(context, ref, t);
      return;
    }
    if (looksLikeEpic1Link(t)) return _read(t);
    if (await openDeskInPersonText(context, t)) {
      if (mounted) setState(() => _to.clear());
      _last = '';
      return;
    }
    if (!mounted) return;
    switch (deskClassify(ref.read(deskApiProvider), t)) {
      case ScannedAddress() || PaymentRequest() || WrongNetwork():
        _fail((l) => l.deskE1ModeClassicAddress, settings: true);
      case SlateText() || SlateFrames():
        _fail((l) => l.deskE1ModeClassicFile, settings: true);
      default:
        _fail((l) => l.deskE1ErrNotLink);
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
    var ok = false;
    final unknown = info.hosts.where((h) => !h.inRelayList).firstOrNull;
    if (unknown != null) {
      ok = await _askServer(unknown.label);
      if (!mounted) return;
      if (!ok) {
        setState(() => _reading = false);
        return;
      }
    }
    setState(() {
      _reading = false;
      _link = link;
      _info = info;
      _hostsOk = ok;
      _amount.clear();
      _amountError = null;
    });
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

  Future<void> _pick() async {
    final c = await showContactPicker(context);
    if (c == null || !mounted) return;
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

  void _review() {
    if (_info == null) {
      unawaited(_open(_to.text));
      return;
    }
    if (_info!.amount == null && _nano() == null) return;
    setState(() => _step = _Step.review);
  }

  Future<void> _send() async {
    final e1 = _e1;
    final info = _info;
    final link = _link;
    if (e1 == null || info == null || link == null) return;
    final nano = info.amount == null ? _nano() : null;
    if (info.amount == null && nano == null) return;
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
        _payError = null;
        _step = _Step.waiting;
      });
      unawaited(ref.read(deskProvider.notifier).refresh());
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    final e1 = _e1;
    final p = _pay;
    if (e1 == null || p == null) return;
    setState(() => _busy = true);
    try {
      final again = await e1.postNext(slateId: p.slateId, hostsOk: _hostsOk);
      if (mounted) {
        setState(() {
          _pay = again;
          _payError = null;
        });
      }
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

  void _reset() => setState(() {
    _to.clear();
    _amount.clear();
    _last = '';
    _error = null;
    _errorSettings = false;
    _amountError = null;
    _link = null;
    _info = null;
    _hostsOk = false;
    _pay = null;
    _payError = null;
    _step = _Step.form;
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The payment's row in the list says when it was answered or cancelled.
    final txs = ref.watch(deskProvider.select((s) => s.txs));
    final pay = _pay;
    final tx = pay == null ? null : txs?.where((t) => t.id == pay.txId).firstOrNull;
    final Widget body = switch (_step) {
      _Step.waiting when tx?.state == TxState.cancelled => _result(EIcons.close, l.deskE1Cancelled, 'e1-cancelled'),
      _Step.waiting when tx != null && tx.state != TxState.waitingRecipient => _result(EIcons.check, l.deskE1Sent, 'e1-sent'),
      _Step.waiting => _waiting(pay!),
      _Step.review => _reviewPanel(),
      _Step.form => _form(),
    };
    return EPage(
      title: l.deskSendTitle,
      width: EPageWidth.mid,
      child: body,
    );
  }

  Widget _form() {
    final l = context.l10n;
    final info = _info;
    final error = _error?.call(l);
    final empty = _to.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EPanel(
          key: const ValueKey('e1-send-form'),
          padding: EdgeInsets.all(Sp.panel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EField(
                label: l.deskE1SendField,
                error: error,
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
                        EIconButton(key: const ValueKey('e1-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, onPressed: _reset),
                      SizedBox(width: Sp.x1),
                      EButton(key: const ValueKey('e1-contacts'), label: l.deskSendContacts, icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                    ],
                  ),
                ),
              ),
              if (_errorSettings) ...[
                SizedBox(height: Sp.x2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: EButton.ghost(
                    key: const ValueKey('e1-send-settings'),
                    label: l.deskRecvSettings,
                    icon: EIcons.settings,
                    size: EBtnSize.inline,
                    onPressed: () => jumpToEpic1Switch(ref),
                  ),
                ),
              ],
              if (info != null) ...[
                SizedBox(height: Sp.x5),
                if (info.message case final m? when m.isNotEmpty) ...[
                  Text('"$m"', key: const ValueKey('e1-link-message'), style: context.ts.body.copyWith(fontStyle: FontStyle.italic)),
                  SizedBox(height: Sp.x4),
                ],
                EField(
                  label: l.deskSendAmount,
                  error: _amountError,
                  child: info.amount != null
                      ? Text(epicTextL(l, info.amount!.toInt()), key: const ValueKey('e1-amount-fixed'), style: context.ts.mono(size: Fs.sm))
                      : EInput(
                          key: const ValueKey('e1-amount'),
                          semanticsId: TrustIds.e1Amount,
                          controller: _amount,
                          mono: true,
                          hint: '0',
                          invalid: _amountError != null,
                          semanticLabel: l.deskSendAmountSem,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() => _amountError = null),
                          onSubmitted: (_) => _review(),
                        ),
                ),
              ],
              SizedBox(height: Sp.x5),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: EButton.primary(
                  key: const ValueKey('e1-review'),
                  semanticsId: TrustIds.e1Review,
                  label: l.deskE1Review,
                  onPressed: empty || _reading ? null : _review,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Sp.x4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: EButton(
            key: const ValueKey('e1-pay-in-person'),
            semanticsId: TrustIds.e1PayInPerson,
            label: l.deskE1PayInPerson,
            icon: EIcons.phone,
            onPressed: () => unawaited(openDeskPayInPerson(context)),
          ),
        ),
      ],
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

  Widget _reviewPanel() {
    final l = context.l10n;
    final info = _info!;
    final nano = info.amount?.toInt() ?? parseEpicIn(l, _amount.text);
    final server = info.hosts.firstOrNull?.label;
    return EPanel(
      key: const ValueKey('e1-review-panel'),
      title: l.deskE1ReviewTitle,
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(l.deskE1To, shortMiddle(info.address), mono: true),
          _row(l.deskSendAmount, formatEpicL(l, nano)),
          if (server != null) _row(l.deskE1Server, server, key: const ValueKey('e1-review-server')),
          SizedBox(height: Sp.x5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EButton(key: const ValueKey('e1-back'), label: l.deskE1Back, onPressed: _busy ? null : () => setState(() => _step = _Step.form)),
              SizedBox(width: Sp.x3),
              EButton.primary(
                key: const ValueKey('e1-send'),
                semanticsId: TrustIds.e1Send,
                label: l.deskE1Send,
                icon: EIcons.send,
                busy: _busy,
                autofocus: true,
                onPressed: _busy ? null : () => unawaited(_send()),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              Icon(EIcons.clock, size: 20.u, color: c.info),
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

  Widget _result(IconData icon, String title, String key) => EPanel(
    key: ValueKey(key),
    padding: EdgeInsets.all(Sp.panel),
    child: EEmpty(
      icon: icon,
      title: title,
      actions: [EButton.primary(key: const ValueKey('e1-done'), label: context.l10n.deskE1Done, onPressed: _reset)],
    ),
  );
}
