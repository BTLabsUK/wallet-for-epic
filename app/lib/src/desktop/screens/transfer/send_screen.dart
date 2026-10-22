import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/http_address.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'contact_picker.dart';
import 'epicbox_notice.dart';
import 'file_panels.dart';

/// Where the Send page is, so the tour reaches every state without taps.
enum SendStep { form, errors, review, sending, done, fileReady, failed }

/// Argument of the Send route. A [Contact] is accepted too (prefills the recipient).
/// [nodeSync] (0..1) and [epicboxHealth] stand in for the wallet's status in the tour.
class SendArgs {
  const SendArgs({
    this.method = TxMethod.epicbox,
    this.recipient,
    this.amount,
    this.message,
    this.step = SendStep.form,
    this.contact,
    this.nodeSync,
    this.epicboxHealth,
    this.privacyOpen = false,
    this.suggest = false,
  });

  final TxMethod method;
  final String? recipient;
  final String? amount;
  final String? message;
  final SendStep step;
  final Contact? contact;
  final double? nodeSync;
  final ServiceHealth? epicboxHealth;
  final bool privacyOpen;

  /// Show the contacts matching [recipient] as if it was typed.
  final bool suggest;
}

/// The summary of a send, shown in the review.
class _Draft {
  const _Draft({
    required this.method,
    required this.to,
    required this.contactName,
    required this.amount,
    required this.fee,
    required this.message,
    required this.sendAll,
    required this.dandelion,
  });

  final TxMethod method;
  final String? to;
  final String? contactName;
  final int amount;
  final int fee;
  final String message;
  final bool sendAll;
  final bool dandelion;

  int get total => amount + fee;
}

/// Amount text to nanoepic: null when it is not a number, [_tooLong] for more than 8 decimals.
const int _tooLong = -1;
int? _parseAmount(String raw) {
  final s = raw.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  final m = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(s);
  if (m == null || (m.group(1)!.isEmpty && (m.group(2) ?? '').isEmpty)) return null;
  final frac = m.group(2) ?? '';
  if (frac.length > 8) return _tooLong;
  return (int.tryParse(m.group(1)!.isEmpty ? '0' : m.group(1)!) ?? 0) * nanoPerEpic + (int.tryParse(frac.padRight(8, '0')) ?? 0);
}

String? _recipientError(TxMethod m, String v) {
  final t = v.trim();
  switch (m) {
    case TxMethod.file:
      return null;
    case TxMethod.epicbox:
      if (t.isEmpty) return 'Add an address to send to.';
      if (RegExp(r'^https?://', caseSensitive: false).hasMatch(t) || t.contains('.onion')) return 'This is not a valid Epicbox address.';
      if (!(t.contains('@') || t.startsWith('es') || t.startsWith('epicbox'))) return 'This is not a valid Epicbox address.';
      return null;
    case TxMethod.http:
      if (t.isEmpty) return 'Add an address to send to.';
      final problem = httpAddressProblem(t);
      return problem == null ? null : '$problem.';
    case TxMethod.tor:
      if (t.isEmpty) return 'Add an address to send to.';
      if (!RegExp(r'^(https?://)?[^\s/@]+\.onion(:\d+)?(/\S*)?$', caseSensitive: false).hasMatch(t)) return 'Enter a .onion address.';
      return null;
  }
}

String _kindLabel(TxMethod m) => switch (m) { TxMethod.epicbox => 'Epicbox', TxMethod.tor => 'Tor', TxMethod.file => 'File', TxMethod.http => 'HTTP' };
IconData _kindIcon(TxMethod m) => switch (m) { TxMethod.epicbox => EIcons.antenna, TxMethod.tor => EIcons.shield, TxMethod.file => EIcons.file, TxMethod.http => EIcons.web };

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _to = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  late final SendArgs _args;
  TxMethod _method = TxMethod.epicbox;
  bool _submitted = false;
  // A field's error goes away as soon as the field is edited, until the next review.
  bool _toEdited = false;
  bool _amountEdited = false;
  bool _all = false;
  bool _allBusy = false;
  String? _allError;
  bool _reviewing = false;
  bool _starting = false;
  bool _dandelion = true;
  // The suggestions under To were dismissed by a pick; typing again brings them back.
  bool _suggestOff = false;
  int? _fee;
  int _feeFor = -1;
  SendResult? _result;
  String? _failure;

  /// The failed payment may exist (waiting in Activity): no Review again.
  bool _failureInActivity = false;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    SendArgs args = const SendArgs();
    if (a is SendArgs) {
      args = a;
    } else if (a is Contact) {
      args = SendArgs(contact: a);
    }
    _args = args;
    final contact = args.contact;
    _method = contact != null ? contactMethod(contact) : args.method;
    _to.text = args.recipient ?? contact?.address ?? '';
    _route();
    _suggestOff = _to.text.isNotEmpty && !args.suggest;
    _amount.text = args.amount ?? '';
    _message.text = args.message ?? '';
    if (args.amount != null) unawaited(_loadFee());
    switch (args.step) {
      case SendStep.errors:
        _submitted = true;
      case SendStep.review || SendStep.sending:
        WidgetsBinding.instance.addPostFrameCallback((_) => _openReview(startBusy: args.step == SendStep.sending));
      case SendStep.done:
        _result = SendDone(_demoTx(TxMethod.epicbox, args.recipient));
      case SendStep.fileReady:
        _method = TxMethod.file;
        _result = SendFileReady(_demoTx(TxMethod.file, null), 'send_${args.amount ?? '12.5'}_epic_9f3a7c21.slate');
      case SendStep.failed:
        _failure = 'The recipient did not answer. Nothing was sent.';
        _submitted = true;
      case SendStep.form:
        break;
    }
  }

  Tx _demoTx(TxMethod m, String? to) => Tx(
    id: 36,
    slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
    direction: TxDirection.sent,
    state: m == TxMethod.file || m == TxMethod.epicbox ? TxState.waitingRecipient : TxState.posted,
    method: m,
    amount: _parseAmount(_amount.text) ?? 12 * nanoPerEpic,
    fee: 600000,
    created: DateTime.now(),
    counterparty: to,
  );

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  int? get _parsed => _parseAmount(_amount.text);
  int get _amountNano => (_parsed ?? 0) > 0 ? _parsed! : 0;

  ServiceHealth? _epicboxHealth(DeskState st) => _args.epicboxHealth ?? st.status?.epicboxHealth;

  /// Null while the node is usable; otherwise how far its sync is (0..1), or -1 when it does not answer.
  double? _nodeBlock(DeskState st) {
    if (_args.nodeSync != null) return _args.nodeSync;
    final s = st.status;
    if (s == null) return -1;
    return s.nodeHealth == ServiceHealth.ok || s.nodeHealth == ServiceHealth.slow ? null : -1;
  }

  bool _epicboxBlocked(DeskState st) {
    if (_method != TxMethod.epicbox) return false;
    final h = _epicboxHealth(st);
    return h == ServiceHealth.off || h == ServiceHealth.checking;
  }

  /// Tor is off or not connected yet: a send to an onion waits.
  bool _torBlocked(DeskState st) => _method == TxMethod.tor && !(st.settings.tor && (st.status?.torCanSend ?? false));

  bool _canSend(DeskState st) => _nodeBlock(st) == null && !_epicboxBlocked(st) && !_torBlocked(st) && _result is! SendDone;

  Future<void> _loadFee() async {
    final n = _amountNano;
    if (n <= 0) {
      setState(() {
        _fee = null;
        _feeFor = -1;
      });
      return;
    }
    if (n == _feeFor) return;
    _feeFor = n;
    int? fee;
    try {
      fee = await ref.read(deskApiProvider).estimateFee(n);
    } on Object {
      // More than can be sent, or the wallet is busy: the amount check says which.
      fee = null;
    }
    if (!mounted || _feeFor != n) return;
    setState(() => _fee = fee);
  }

  /// An onion goes over Tor, also when pasted under Epicbox or HTTP; an http(s) address
  /// under Tor goes over HTTP.
  void _route() {
    if (!DeskFeatures.tor || _method == TxMethod.file) return;
    final t = _to.text.trim();
    if (ref.read(deskApiProvider).isOnionAddress(t)) {
      _method = TxMethod.tor;
    } else if (_method == TxMethod.tor && DeskFeatures.httpDirect && httpAddressProblem(t) == null) {
      _method = TxMethod.http;
    }
  }

  bool _torBusy = false;

  Future<void> _turnOnTor() async {
    setState(() => _torBusy = true);
    try {
      await ref.read(deskProvider.notifier).setTor(true);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Tor not turned on', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _torBusy = false);
    }
  }

  void _changed({bool to = false, bool amount = false}) {
    setState(() {
      if (amount) {
        _all = false;
        _amountEdited = true;
        _allError = null;
      }
      if (to) {
        _toEdited = true;
        _suggestOff = false;
        _route();
      }
      if (_result is SendDone) _result = null;
      _failure = null;
    });
    if (amount) unawaited(_loadFee());
  }

  Future<void> _sendAll() async {
    if (_allBusy) return;
    final spendable = ref.read(deskProvider).balance?.spendable;
    if (spendable == null) return;
    setState(() {
      _allBusy = true;
      _allError = null;
    });
    try {
      final (n, fee) = spendable > 0 ? await ref.read(deskApiProvider).estimateMax() : (0, 0);
      if (!mounted) return;
      if (n <= 0) {
        setState(() => _allError = 'Nothing spendable to send.');
        return;
      }
      setState(() {
        _all = true;
        _amountEdited = true;
        _fee = fee;
        _feeFor = n;
        _amount.text = formatEpic(n).replaceAll(',', '');
      });
    } catch (_) {
      if (mounted) setState(() => _allError = 'Could not work out how much can be sent. Try again in a moment.');
    } finally {
      if (mounted) setState(() => _allBusy = false);
    }
  }

  String? _amountError(int? spendable) {
    final p = _parsed;
    if (_amount.text.trim().isEmpty || p == null) return 'Enter an amount.';
    if (p == _tooLong) return 'EPIC has at most 8 decimals.';
    if (p <= 0) return 'The amount must be more than 0.';
    if (spendable != null && p + (_fee ?? 0) > spendable) return 'More than the available balance.';
    return null;
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim();
    if (t == null || t.isEmpty || !mounted) return;
    setState(() => _to.text = t);
    _changed(to: true);
  }

  void _use(Contact c) {
    setState(() {
      _method = contactMethod(c);
      _to.text = c.address;
    });
    _changed(to: true);
    setState(() => _suggestOff = true);
  }

  Future<void> _pick() async {
    final c = await showContactPicker(context);
    if (c == null || !mounted) return;
    _use(c);
  }

  Contact? _contactOf(List<Contact>? contacts) {
    final v = _to.text.trim();
    if (v.isEmpty || contacts == null) return null;
    for (final c in contacts) {
      if (c.address == v) return c;
    }
    return null;
  }

  /// Contacts whose name or address holds what is typed in To, at most four.
  List<Contact> _matches(DeskState st) {
    final q = _to.text.trim().toLowerCase();
    final contacts = st.contacts;
    if (_suggestOff || q.length < 2 || contacts == null || _contactOf(contacts) != null) return const [];
    return contacts.where(contactSendable).where((c) => c.name.toLowerCase().contains(q) || c.address.toLowerCase().contains(q)).take(4).toList();
  }

  Future<void> _startListener() async {
    setState(() => _starting = true);
    try {
      await ref.read(deskProvider.notifier).setListening(true);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Listener not started', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _review() async {
    final st = ref.read(deskProvider);
    if (!_canSend(st) || _reviewing) return;
    setState(() {
      _submitted = true;
      _toEdited = false;
      _amountEdited = false;
      _reviewing = true;
    });
    try {
      await _loadFee();
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
    if (!mounted) return;
    if (_recipientError(_method, _to.text) != null || _amountError(st.balance?.spendable) != null) return;
    await _openReview();
  }

  Future<void> _openReview({bool startBusy = false}) async {
    // The summary's estimate may still be on its way: the review always shows the real fee.
    if (_fee == null) {
      final int fee;
      try {
        fee = await ref.read(deskApiProvider).estimateFee(_amountNano);
      } on Object catch (e) {
        if (mounted) {
          setState(() {
            _failure = deskErrorText(e);
            _failureInActivity = false;
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() => _fee = fee);
    }
    final contacts = ref.read(deskProvider).contacts;
    final n = _amountNano;
    final draft = _Draft(
      method: _method,
      to: _method == TxMethod.file ? null : _to.text.trim(),
      contactName: _contactOf(contacts)?.name,
      amount: n,
      fee: _fee ?? 0,
      message: _message.text.trim(),
      sendAll: _all,
      dandelion: _dandelion,
    );
    // Plain HTTP to another computer: the slate travels unencrypted, so ask first.
    final plain = draft.method == TxMethod.http && plainHttpNeedsConsent(draft.to!);
    if (plain) {
      final ok = await showEDialog<bool>(context, builder: (_) => const PlainHttpDialog());
      if (!mounted || ok != true) return;
    }
    final notifier = ref.read(deskProvider.notifier);
    final res = await showEDialog<SendResult>(
      context,
      dismissible: false,
      builder: (_) => _ReviewDialog(
        draft: draft,
        startBusy: startBusy,
        onConfirm: () => notifier.send(
          SendRequest(
            method: draft.method,
            amount: draft.amount,
            to: draft.to,
            message: draft.message.isEmpty ? null : draft.message,
            sendAll: draft.sendAll,
            dandelion: draft.dandelion,
            allowPlainHttp: plain,
          ),
        ),
      ),
    );
    if (!mounted || res == null) return;
    if (res is SendDone) showEToast(context, 'Sent', text: '${formatEpic(res.tx.amount)} EPIC');
    setState(() {
      switch (res) {
        case SendFailed(:final message, :final inActivity):
          _failure = message;
          _failureInActivity = inActivity;
          _result = null;
        default:
          _failure = null;
          _result = res;
          if (res is SendDone) {
            _to.clear();
            _amount.clear();
            _message.clear();
            _fee = null;
            _submitted = false;
          }
      }
    });
  }

  void _reset() => setState(() {
    _result = null;
    _failure = null;
    _to.clear();
    _amount.clear();
    _message.clear();
    _fee = null;
    _submitted = false;
  });

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final nav = ref.read(deskNavProvider.notifier);
    final res = _result;
    // A half-filled form holds Back (mouse, Alt+Left).
    return DeskStepBack(
      onBack: res is! SendFileReady && (_to.text.isNotEmpty || _amount.text.isNotEmpty || _message.text.isNotEmpty) ? () {} : null,
      child: EPage(
      title: 'Send',
      width: EPageWidth.mid,
      child: res is SendFileReady
          ? _fileReady(res, nav)
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 720.u;
                // Tab: the form's fields first, then Review send; Enter in Amount reviews.
                final form = FocusTraversalOrder(order: const NumericFocusOrder(1), child: FocusTraversalGroup(child: _form(st)));
                final summary = FocusTraversalOrder(order: const NumericFocusOrder(2), child: FocusTraversalGroup(child: _summary(st, res)));
                return EForm(
                  onSubmit: _canSend(st) && !_reviewing ? _review : null,
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: !wide
                        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, SizedBox(height: Sp.x6), summary])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: form),
                              SizedBox(width: Sp.x8),
                              SizedBox(width: 300.u, child: summary),
                            ],
                          ),
                  ),
                );
              },
            ),
    ),
    );
  }

  Widget _fileReady(SendFileReady r, DeskNav nav) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Ctl.narrow),
      child: ResultPanel(
        title: 'Transaction file ready',
        text: 'Give this file to the recipient. The wallet is waiting for the response file; finalize it when it comes back.',
        body: FileChip(r.fileName),
        actions: [
          EButton.primary(label: 'Finalize', icon: EIcons.fileUp, onPressed: () => nav.go(DeskRoute.finalize)),
          EButton(label: 'View in Activity', onPressed: () => nav.go(DeskRoute.activity, r.tx.id)),
          EButton.ghost(label: 'New send', onPressed: _reset),
        ],
      ),
    );
  }

  /// The one notice about what keeps a send from going out, most blocking first.
  Widget? _blockNotice(DeskState st) {
    final node = _nodeBlock(st);
    if (st.status != null && node != null) {
      return ENotice(
        title: 'Node not synced',
        text: node >= 0
            ? 'Sending is possible once the node has synced. ${(node * 100).round()}% done; the form can be filled in meanwhile.'
            : 'Sending is possible once the node has synced.',
        tone: ETone.warn,
        icon: EIcons.server,
      );
    }
    final eb = _epicboxHealth(st);
    if (_method == TxMethod.epicbox && eb == ServiceHealth.down) return const EpicboxDownNotice();
    if (_epicboxBlocked(st)) {
      return ENotice(
        title: 'Epicbox not connected',
        text: 'Epicbox sends are possible once the listener runs. Send by file meanwhile.',
        tone: ETone.warn,
        icon: EIcons.antenna,
        actions: [
          if (eb == ServiceHealth.off)
            EButton(label: 'Start listener', icon: EIcons.antenna, size: EBtnSize.inline, busy: _starting, onPressed: _starting ? null : _startListener),
        ],
      );
    }
    return null;
  }

  Widget _form(DeskState st) {
    final ts = context.ts;
    final c = context.dc;
    final spendable = st.balance?.spendable;
    final contact = _contactOf(st.contacts);
    final file = _method == TxMethod.file;
    final direct = _method == TxMethod.http || _method == TxMethod.tor;
    final toErr = _submitted && !_toEdited ? _recipientError(_method, _to.text) : null;
    final amErr = _allError ?? (_submitted && !_amountEdited ? _amountError(spendable) : null);
    final res = _result;
    final block = _blockNotice(st);
    final matches = file ? const <Contact>[] : _matches(st);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (res is SendDone) ...[
          ENotice(
            title: 'Sent',
            text: switch (res.tx.method) {
              TxMethod.tor || TxMethod.http => 'Finalized and posted to the network.',
              _ => 'Handed to Epicbox. Completes when the recipient answers.',
            },
            tone: ETone.ok,
            icon: EIcons.okCircle,
            actions: [
              EButton(label: 'View transaction', size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, res.tx.id)),
            ],
          ),
          SizedBox(height: Sp.x5),
        ],
        if (_failure != null) ...[
          ENotice(
            title: 'Send failed',
            text: _failure,
            tone: ETone.risk,
            icon: EIcons.error,
            actions: [
              // The payment may be waiting already: a second review could pay twice.
              if (_failureInActivity)
                EButton(label: 'View in Activity', size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity))
              else
                EButton(label: 'Review again', size: EBtnSize.inline, onPressed: _review),
            ],
          ),
          SizedBox(height: Sp.x5),
        ],
        if (block != null) ...[block, SizedBox(height: Sp.x5)],
        Align(
          alignment: Alignment.centerLeft,
          child: ESegmented<TxMethod>(
            segments: const [
              ESegment(TxMethod.epicbox, 'Epicbox', icon: EIcons.antenna),
              if (DeskFeatures.httpDirect || DeskFeatures.tor) ESegment(TxMethod.http, 'Direct', icon: EIcons.web),
              ESegment(TxMethod.file, 'File', icon: EIcons.file),
            ],
            value: direct ? TxMethod.http : _method,
            onChanged: (m) => setState(() {
              _method = m;
              _failure = null;
            }),
          ),
        ),
        if (direct) ...[
          SizedBox(height: Sp.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: ESegmented<TxMethod>(
              segments: const [if (DeskFeatures.httpDirect) ESegment(TxMethod.http, 'HTTP'), if (DeskFeatures.tor) ESegment(TxMethod.tor, 'Tor')],
              value: _method,
              onChanged: (m) => setState(() => _method = m),
            ),
          ),
        ],
        SizedBox(height: Sp.x2),
        Text(
          switch (_method) {
            TxMethod.epicbox => 'The recipient can be offline; it arrives when they open their wallet.',
            TxMethod.http => 'The recipient’s wallet must be online.',
            TxMethod.tor => 'Through Tor to an .onion address. The recipient’s wallet must be online.',
            TxMethod.file => 'Creates a transaction file to hand over; no address needed.',
          },
          style: ts.small,
        ),
        SizedBox(height: Sp.x6),
        if (!file) ...[
          EField(
            label: 'To',
            error: toErr,
            help: toErr == null
                ? switch (_method) {
                    TxMethod.epicbox => 'Epic address or contact',
                    TxMethod.http => 'http(s) address',
                    _ => '.onion address',
                  }
                : null,
            child: EInput(
              controller: _to,
              mono: true,
              invalid: toErr != null,
              hint: switch (_method) { TxMethod.epicbox => 'es…@epicbox.epiccash.com', TxMethod.http => 'http://host:3415', _ => 'xxxxxxxx.onion' },
              semanticLabel: 'Recipient',
              leading: EIcons.user,
              onChanged: (_) => _changed(to: true),
              // Enter picks the first matching contact, else goes on to Amount.
              onSubmitted: matches.isEmpty ? null : (_) => _use(matches.first),
              trailingTabStop: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_to.text.isNotEmpty)
                    EIconButton(icon: EIcons.close, label: 'Clear recipient', size: EBtnSize.inline, tabStop: false, onPressed: () {
                      _to.clear();
                      _changed(to: true);
                    })
                  else
                    EIconButton(icon: EIcons.paste, label: 'Paste', size: EBtnSize.inline, tabStop: false, onPressed: _paste),
                  SizedBox(width: Sp.x1),
                  EButton(label: 'Contacts', icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                ],
              ),
            ),
          ),
          if (matches.isNotEmpty) ...[
            SizedBox(height: Sp.x2),
            _Suggestions(contacts: matches, onPick: _use),
          ],
          if (_method == TxMethod.tor && (!st.settings.tor || !(st.status?.torIncluded ?? true))) ...[
            SizedBox(height: Sp.x3),
            ENotice(
              title: 'Tor is off',
              text: st.status?.torIncluded ?? true ? 'Turn it on to send to an .onion address.' : 'Tor not included in this build.',
              tone: ETone.warn,
              icon: EIcons.shield,
              actions: [
                if (st.status?.torIncluded ?? true)
                  EButton(label: 'Turn on Tor', size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : _turnOnTor),
              ],
            ),
          ] else if (_method == TxMethod.tor && st.status != null && !st.status!.torCanSend) ...[
            SizedBox(height: Sp.x3),
            Semantics(
              liveRegion: true,
              child: ENotice(
                title: st.status!.tor == ServiceHealth.down ? 'Tor is not connected' : 'Tor is connecting',
                text: st.status!.tor == ServiceHealth.down
                    ? '${torStatusLine(st.status!)}. Sending over Tor needs it.'
                    : '${torStatusLine(st.status!)} Sending over Tor starts once it is connected.',
                tone: st.status!.tor == ServiceHealth.down ? ETone.risk : ETone.neutral,
                icon: EIcons.shield,
                actions: [
                  if (st.status!.tor == ServiceHealth.down)
                    EButton(label: 'Retry', size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : _turnOnTor),
                ],
              ),
            ),
          ],
          if (contact != null) ...[
            SizedBox(height: Sp.x2),
            Row(
              children: [
                EAvatar(contact.name, size: 20.u),
                SizedBox(width: Sp.x2),
                Flexible(child: Text('${contact.name} from contacts', style: ts.small, overflow: TextOverflow.ellipsis)),
                SizedBox(width: Sp.x2),
                ETag(_kindLabel(contactMethod(contact)), tone: contactMethod(contact) == TxMethod.epicbox ? ETone.gold : ETone.neutral, icon: _kindIcon(contactMethod(contact))),
              ],
            ),
          ],
          SizedBox(height: Sp.x5),
        ],
        EField(
          label: 'Amount',
          error: amErr,
          aside: spendable == null
              ? Text('Available —', style: ts.small)
              : ELink(label: 'Available ${st.settings.hideAmounts ? '••••••' : formatEpic(spendable)} EPIC', dim: st.status?.syncProgress != null, tabStop: false, onPressed: _allBusy ? null : _sendAll),
          child: EInput(
            controller: _amount,
            mono: true,
            invalid: amErr != null,
            hint: '0',
            semanticLabel: 'Amount in EPIC',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            onChanged: (_) => _changed(amount: true),
            trailingTabStop: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EPIC', style: ts.small.copyWith(color: c.dim)),
                SizedBox(width: Sp.x2),
                EButton(label: 'All', size: EBtnSize.inline, busy: _allBusy, onPressed: spendable == null || _allBusy ? null : _sendAll),
              ],
            ),
          ),
        ),
        if ((st.balance?.awaitingConfirmation ?? 0) > 0) ...[
          SizedBox(height: Sp.x2),
          Text('${st.settings.hideAmounts ? 'Part of the balance' : '${formatEpic(st.balance!.awaitingConfirmation)} EPIC'} is still confirming and cannot be sent yet.', style: ts.small),
        ],
        SizedBox(height: Sp.x5),
        EField(
          label: 'Message',
          optional: true,
          aside: Text('${_message.text.length} / 256', style: ts.mono(size: Fs.xs, color: c.faint)),
          help: 'The recipient sees this message.',
          child: EInput(
            controller: _message,
            maxLines: 3,
            semanticLabel: 'Message',
            inputFormatters: [LengthLimitingTextInputFormatter(256)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (DeskFeatures.dandelion && !file) ...[
          SizedBox(height: Sp.x5),
          EDetails(
            title: 'Privacy · Dandelion++ ${_dandelion ? 'on' : 'off'}',
            initiallyOpen: _args.privacyOpen,
            child: ESetRow(
              title: 'Dandelion++',
              text: 'Passes the transaction through a few random nodes before it spreads, so the network cannot tell where it came from.',
              control: ESwitch(value: _dandelion, semanticLabel: 'Dandelion++', onChanged: (v) => setState(() => _dandelion = v)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summary(DeskState st, SendResult? res) {
    final c = context.dc;
    final ts = context.ts;
    final spendable = st.balance?.spendable;
    final n = _amountNano;
    final fee = n > 0 ? (_fee ?? 0) : 0;
    final bad = n > 0 && spendable != null && n + fee > spendable;
    final ready = n > 0 && !bad;
    final updating = st.status?.syncProgress != null;
    Widget line(String label, int? v, {bool strong = false, bool risk = false, bool dim = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? ts.strong : ts.bodyDim)),
          if (v == null || v == 0 && label != 'Left to spend')
            Text('—', style: ts.mono(size: Fs.md, color: c.faint))
          else
            EMoney(v, size: strong ? Fs.lg : Fs.md, color: risk ? c.risk : (dim ? c.dim : null), weight: strong ? FontWeight.w600 : null),
        ],
      ),
    );
    final nodeBlocked = _nodeBlock(st) != null;
    final hint = switch (null) {
      _ when res is SendDone => 'Sent. Enter a new amount and recipient to send again.',
      _ when nodeBlocked => 'Waiting for the node to sync.',
      _ when _epicboxBlocked(st) => 'Waiting for Epicbox to connect.',
      _ when _torBlocked(st) => st.settings.tor ? 'Waiting for Tor to connect.' : 'Turn on Tor to send to an .onion address.',
      _ when _submitted && !_toEdited && _recipientError(_method, _to.text) != null => 'Fix the fields marked in red.',
      _ when _submitted && !_amountEdited && _amountError(spendable) != null => 'Fix the fields marked in red.',
      _ when _reviewing => 'Checking the fee for this amount.',
      _ => 'Nothing is sent until confirmed.',
    };
    return EPanel(
      title: 'Summary',
      padding: EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line('Amount', n > 0 ? n : null, risk: bad),
          line('Network fee', fee > 0 ? fee : null),
          Divider(height: Sp.x4, color: c.line),
          line('Total', ready ? n + fee : null, strong: true),
          line('Left to spend', ready && spendable != null ? spendable - n - fee : null, dim: true),
          if (updating) Text('Balance updating while the wallet scans.', style: ts.caption),
          SizedBox(height: Sp.x4),
          EButton.primary(
            label: 'Review send',
            icon: EIcons.send,
            expand: true,
            busy: _reviewing,
            onPressed: _canSend(st) && !_reviewing ? _review : null,
          ),
          SizedBox(height: Sp.x3),
          Semantics(liveRegion: true, child: Text(hint, style: ts.small, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Contacts matching what is typed in To: a short list right under the field.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.contacts, required this.onPick});

  final List<Contact> contacts;
  final ValueChanged<Contact> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      label: 'Matching contacts',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.s2,
          borderRadius: BorderRadius.circular(Rad.sm),
          border: Border.all(color: c.lineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, x) in contacts.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              Semantics(
                button: true,
                label: '${x.name}, ${shortAddress(x.address)}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onPick(x),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                    child: Row(
                      children: [
                        EAvatar(x.name, size: 24.u),
                        SizedBox(width: Sp.x3),
                        Flexible(child: Text(x.name, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: Sp.x2),
                        ETag(_kindLabel(contactMethod(x)), tone: contactMethod(x) == TxMethod.epicbox ? ETone.gold : ETone.neutral, icon: _kindIcon(contactMethod(x))),
                        SizedBox(width: Sp.x3),
                        Expanded(
                          child: Text(shortAddress(x.address), style: ts.mono(size: Fs.xs, color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.draft, required this.onConfirm, this.startBusy = false});

  final _Draft draft;
  final Future<SendResult> Function() onConfirm;
  final bool startBusy;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late bool _busy = widget.startBusy;

  Future<void> _go() async {
    if (_busy) return;
    setState(() => _busy = true);
    SendResult r;
    try {
      r = await widget.onConfirm();
    } on Object catch (e) {
      // The payment may have left before the error: never offer to send it again blind.
      logWarn('desk', 'send ended with ${e.runtimeType}');
      r = const SendFailed('Not confirmed. Check Activity before sending again.', inActivity: true);
    }
    if (mounted) Navigator.of(context).pop(r);
  }

  // The same marking as EAddress: the key's first and last six characters, the relay dim.
  Widget _address(BuildContext context, String to) {
    final c = context.dc;
    final base = context.ts.mono(size: Fs.sm, color: c.dim);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    final at = to.indexOf('@');
    final key = at > 0 ? to.substring(0, at) : to;
    final rest = at > 0 ? to.substring(at) : '';
    if (key.length <= 14 || key.startsWith('http')) return SelectableText(to, style: base);
    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: key.substring(0, 6), style: hl),
          TextSpan(text: key.substring(6, key.length - 6)),
          TextSpan(text: key.substring(key.length - 6), style: hl),
          TextSpan(text: rest),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final ts = context.ts;
    final c = context.dc;
    final via = switch (d.method) {
      TxMethod.epicbox => 'Epicbox (the recipient can be offline)',
      TxMethod.http => 'Direct over HTTP (the recipient’s wallet must be online)',
      TxMethod.tor => 'Direct over Tor (the recipient’s wallet must be online)',
      TxMethod.file => 'Transaction file',
    };
    return EDialog(
      title: 'Check and send',
      description: 'A send cannot be undone once it is posted.',
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: Text(formatEpic(d.amount), style: ts.h1.copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
              SizedBox(width: Sp.x2),
              Text('EPIC', style: ts.lead),
            ],
          ),
          SizedBox(height: Sp.x4),
          EFacts([
            if (d.to != null)
              (
                'To',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.contactName != null) Text(d.contactName!, style: ts.strong),
                    _address(context, d.to!),
                    SizedBox(height: Sp.x1),
                    Text('Check the highlighted characters against what the recipient gave.', style: ts.caption),
                  ],
                ),
              ),
            ('Via', Text(via, style: ts.body)),
            ('Network fee', EMoney(d.fee)),
            ('Total', EMoney(d.total, weight: FontWeight.w600)),
            if (DeskFeatures.dandelion && d.method != TxMethod.file) ('Privacy', Text(d.dandelion ? 'Dandelion++ on' : 'Dandelion++ off', style: ts.body)),
            if (d.message.isNotEmpty) ('Message', Text(d.message, style: ts.body)),
          ], labelWidth: 100.u),
          if (_busy) ...[
            SizedBox(height: Sp.x4),
            Row(
              children: [
                const ESpinner(),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Text(
                    switch (d.method) {
                      TxMethod.file => 'Creating the file.',
                      TxMethod.tor => 'Reaching the recipient over Tor… This can take up to about 2 minutes; keep this window open.',
                      _ => 'Sending. This can take a few seconds; keep this window open.',
                    },
                    style: ts.small.copyWith(color: c.dim),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        EButton(label: 'Back', kind: EBtnKind.ghost, size: EBtnSize.sm, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: _busy ? 'Sending' : 'Send ${formatEpic(d.amount)} EPIC', icon: EIcons.send, busy: _busy, onPressed: _busy ? null : _go),
      ],
    );
  }
}

/// Asked before a send over plain `http` to another computer.
class PlainHttpDialog extends StatelessWidget {
  const PlainHttpDialog({super.key});

  @override
  Widget build(BuildContext context) => EDialog(
    title: 'Not encrypted. Send anyway?',
    description: 'Plain HTTP to another computer. Anyone on the way can read the transaction. https:// is encrypted.',
    icon: EIcons.alert,
    tone: ETone.warn,
    actions: [
      EButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
      EButton.primary(label: 'Send anyway', onPressed: () => Navigator.of(context).pop(true)),
    ],
  );
}
