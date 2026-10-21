import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'contact_picker.dart';
import 'file_panels.dart';

/// Where the Send page is, so the tour reaches every state without taps.
enum SendStep { form, errors, review, sending, done, fileReady, failed }

/// Argument of the Send route. A [Contact] is accepted too (prefills the recipient).
class SendArgs {
  const SendArgs({this.method = TxMethod.epicbox, this.recipient, this.amount, this.message, this.step = SendStep.form, this.contact});

  final TxMethod method;
  final String? recipient;
  final String? amount;
  final String? message;
  final SendStep step;
  final Contact? contact;
}

/// The summary of a send, shown in the review.
class _Draft {
  const _Draft({required this.method, required this.to, required this.contactName, required this.amount, required this.fee, required this.message, required this.sendAll});

  final TxMethod method;
  final String? to;
  final String? contactName;
  final int amount;
  final int fee;
  final String message;
  final bool sendAll;

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
      if (!RegExp(r'^https?://\S+$', caseSensitive: false).hasMatch(t)) return 'Enter an http(s) address.';
      return null;
    case TxMethod.tor:
      if (t.isEmpty) return 'Add an address to send to.';
      if (!RegExp(r'^(https?://)?[^\s/@]+\.onion(:\d+)?(/\S*)?$', caseSensitive: false).hasMatch(t)) return 'Enter a .onion address.';
      return null;
  }
}

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
  TxMethod _method = TxMethod.epicbox;
  bool _submitted = false;
  bool _all = false;
  int? _fee;
  int _feeFor = -1;
  SendResult? _result;
  String? _failure;

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
    final contact = args.contact;
    _method = contact != null ? contactMethod(contact) : args.method;
    _to.text = args.recipient ?? contact?.address ?? '';
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
    state: m == TxMethod.file ? TxState.waitingRecipient : TxState.posted,
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
    final fee = await ref.read(deskApiProvider).estimateFee(n);
    if (!mounted || _feeFor != n) return;
    setState(() => _fee = fee);
  }

  void _changed() {
    setState(() {
      _all = false;
      if (_result is SendDone) _result = null;
      _failure = null;
    });
    unawaited(_loadFee());
  }

  Future<void> _sendAll() async {
    final spendable = ref.read(deskProvider).balance?.spendable;
    if (spendable == null || spendable <= 0) return;
    final fee = await ref.read(deskApiProvider).estimateFee(spendable);
    if (!mounted) return;
    final n = spendable - fee;
    setState(() {
      _all = true;
      _fee = fee;
      _feeFor = n;
      _amount.text = formatEpic(n < 0 ? 0 : n).replaceAll(',', '');
    });
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
    _changed();
  }

  Future<void> _pick() async {
    final c = await showContactPicker(context);
    if (c == null || !mounted) return;
    setState(() {
      _method = contactMethod(c);
      _to.text = c.address;
    });
    _changed();
  }

  Contact? _contactOf(List<Contact>? contacts) {
    final v = _to.text.trim();
    if (v.isEmpty || contacts == null) return null;
    for (final c in contacts) {
      if (c.address == v) return c;
    }
    return null;
  }

  Future<void> _review() async {
    setState(() => _submitted = true);
    final bal = ref.read(deskProvider).balance;
    await _loadFee();
    if (!mounted) return;
    if (_recipientError(_method, _to.text) != null || _amountError(bal?.spendable) != null) return;
    await _openReview();
  }

  Future<void> _openReview({bool startBusy = false}) async {
    // The summary's estimate may still be on its way: the review always shows the real fee.
    if (_fee == null) {
      final fee = await ref.read(deskApiProvider).estimateFee(_amountNano);
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
    );
    final notifier = ref.read(deskProvider.notifier);
    final res = await showEDialog<SendResult>(
      context,
      dismissible: false,
      builder: (_) => _ReviewDialog(
        draft: draft,
        startBusy: startBusy,
        onConfirm: () => notifier.send(SendRequest(method: draft.method, amount: draft.amount, to: draft.to, message: draft.message.isEmpty ? null : draft.message, sendAll: draft.sendAll)),
      ),
    );
    if (!mounted || res == null) return;
    setState(() {
      switch (res) {
        case SendFailed(:final message):
          _failure = message;
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
    return EPage(
      title: 'Send',
      width: EPageWidth.mid,
      child: res is SendFileReady
          ? _fileReady(res, nav)
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 720;
                final form = _form(st);
                final summary = _summary(st, res);
                if (!wide) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: Sp.x6), summary]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: form),
                    const SizedBox(width: Sp.x8),
                    SizedBox(width: 300, child: summary),
                  ],
                );
              },
            ),
    );
  }

  Widget _fileReady(SendFileReady r, DeskNav nav) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Ctl.narrow),
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

  Widget _form(DeskState st) {
    final ts = context.ts;
    final c = context.dc;
    final spendable = st.balance?.spendable;
    final contact = _contactOf(st.contacts);
    final file = _method == TxMethod.file;
    final direct = _method == TxMethod.http || _method == TxMethod.tor;
    final toErr = _submitted ? _recipientError(_method, _to.text) : null;
    final amErr = _submitted ? _amountError(spendable) : null;
    final res = _result;
    final ebDown = _method == TxMethod.epicbox && st.status?.epicboxHealth == ServiceHealth.down;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (res is SendDone) ...[
          ENotice(
            title: 'Sent',
            text: 'The payment was posted to the network.',
            tone: ETone.ok,
            icon: EIcons.okCircle,
            actions: [
              EButton(label: 'View transaction', size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, res.tx.id)),
            ],
          ),
          const SizedBox(height: Sp.x5),
        ],
        if (_failure != null) ...[
          ENotice(
            title: 'Send failed',
            text: _failure,
            tone: ETone.risk,
            icon: EIcons.error,
            actions: [EButton(label: 'Review again', size: EBtnSize.inline, onPressed: _review)],
          ),
          const SizedBox(height: Sp.x5),
        ],
        if (ebDown) ...[
          const ENotice(title: 'Epicbox relay not answering', text: 'Epicbox sends wait until it answers. Direct sends are not affected.', tone: ETone.warn, icon: EIcons.antenna),
          const SizedBox(height: Sp.x5),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: ESegmented<TxMethod>(
            segments: const [
              ESegment(TxMethod.epicbox, 'Epicbox', icon: EIcons.antenna),
              ESegment(TxMethod.http, 'Direct', icon: EIcons.web),
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
          const SizedBox(height: Sp.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: ESegmented<TxMethod>(
              segments: const [ESegment(TxMethod.http, 'HTTP'), ESegment(TxMethod.tor, 'Tor')],
              value: _method,
              onChanged: (m) => setState(() => _method = m),
            ),
          ),
        ],
        const SizedBox(height: Sp.x2),
        Text(
          switch (_method) {
            TxMethod.epicbox => 'The recipient can be offline; it arrives when they open their wallet.',
            TxMethod.http => 'The recipient’s wallet must be online.',
            TxMethod.tor => 'Through Tor to an .onion address. The recipient’s wallet must be online.',
            TxMethod.file => 'Creates a transaction file to hand over; no address needed.',
          },
          style: ts.small,
        ),
        const SizedBox(height: Sp.x6),
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
              onChanged: (_) => _changed(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_to.text.isNotEmpty)
                    EIconButton(icon: EIcons.close, label: 'Clear recipient', size: EBtnSize.inline, onPressed: () {
                      _to.clear();
                      _changed();
                    })
                  else
                    EIconButton(icon: EIcons.paste, label: 'Paste', size: EBtnSize.inline, onPressed: _paste),
                  const SizedBox(width: Sp.x1),
                  EButton(label: 'Contacts', icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                ],
              ),
            ),
          ),
          if (_method == TxMethod.tor && !st.settings.tor) ...[
            const SizedBox(height: Sp.x3),
            ENotice(
              title: 'Tor is off',
              text: 'Turn it on to send to an .onion address.',
              tone: ETone.warn,
              icon: EIcons.shield,
              actions: [
                EButton(
                  label: 'Turn on Tor',
                  size: EBtnSize.inline,
                  onPressed: () => ref.read(deskProvider.notifier).saveSettings(st.settings.copyWith(tor: true)),
                ),
              ],
            ),
          ],
          if (contact != null) ...[
            const SizedBox(height: Sp.x2),
            Row(
              children: [
                EAvatar(contact.name, size: 20),
                const SizedBox(width: Sp.x2),
                Flexible(child: Text('${contact.name} from contacts', style: ts.small, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          const SizedBox(height: Sp.x5),
        ],
        EField(
          label: 'Amount',
          error: amErr,
          aside: spendable == null
              ? Text('Available —', style: ts.small)
              : ELink(label: 'Available ${formatEpic(spendable)} EPIC', onPressed: _sendAll),
          child: EInput(
            controller: _amount,
            mono: true,
            invalid: amErr != null,
            hint: '0',
            semanticLabel: 'Amount in EPIC',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            onChanged: (_) => _changed(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EPIC', style: ts.small.copyWith(color: c.dim)),
                const SizedBox(width: Sp.x2),
                EButton(label: 'All', size: EBtnSize.inline, onPressed: spendable == null ? null : _sendAll),
              ],
            ),
          ),
        ),
        if ((st.balance?.awaitingConfirmation ?? 0) > 0) ...[
          const SizedBox(height: Sp.x2),
          Text('${formatEpic(st.balance!.awaitingConfirmation)} EPIC is still confirming and cannot be sent yet.', style: ts.small),
        ],
        const SizedBox(height: Sp.x5),
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
    Widget line(String label, int? v, {bool strong = false, bool risk = false, bool dim = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.x2),
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
    final hint = switch (null) {
      _ when _submitted && (_recipientError(_method, _to.text) != null || _amountError(spendable) != null) => 'Fix the fields marked in red.',
      _ when res is SendDone => 'Sent. Enter a new amount and recipient to send again.',
      _ => 'Nothing is sent until confirmed.',
    };
    return EPanel(
      title: 'Summary',
      padding: const EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line('Amount', n > 0 ? n : null, risk: bad),
          line('Network fee', fee > 0 ? fee : null),
          Divider(height: Sp.x4, color: c.line),
          line('Total', ready ? n + fee : null, strong: true),
          line('Left to spend', ready && spendable != null ? spendable - n - fee : null, dim: true),
          const SizedBox(height: Sp.x4),
          EButton.primary(label: 'Review send', icon: EIcons.send, expand: true, onPressed: _review),
          const SizedBox(height: Sp.x3),
          Text(hint, style: ts.small, textAlign: TextAlign.center),
        ],
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
    setState(() => _busy = true);
    final r = await widget.onConfirm();
    if (mounted) Navigator.of(context).pop(r);
  }

  Widget _address(BuildContext context, String to) {
    final c = context.dc;
    final base = context.ts.mono(size: Fs.sm, color: c.dim);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    final at = to.indexOf('@');
    final key = at > 0 ? to.substring(0, at) : to;
    final rest = at > 0 ? to.substring(at) : '';
    if (key.length <= 13) return SelectableText(to, style: base);
    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: key.substring(0, 5), style: hl),
          TextSpan(text: key.substring(5, key.length - 4)),
          TextSpan(text: key.substring(key.length - 4), style: hl),
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
      TxMethod.epicbox => 'Epicbox',
      TxMethod.http => 'Direct over HTTP',
      TxMethod.tor => 'Direct over Tor',
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
              const SizedBox(width: Sp.x2),
              Text('EPIC', style: ts.lead),
            ],
          ),
          const SizedBox(height: Sp.x4),
          EFacts([
            if (d.to != null)
              (
                'To',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.contactName != null) Text(d.contactName!, style: ts.strong),
                    _address(context, d.to!),
                    const SizedBox(height: Sp.x1),
                    Text('Check the highlighted characters against what the recipient gave.', style: ts.caption),
                  ],
                ),
              ),
            ('Via', Text(via, style: ts.body)),
            ('Network fee', EMoney(d.fee)),
            ('Total', EMoney(d.total, weight: FontWeight.w600)),
            if (d.message.isNotEmpty) ('Message', Text(d.message, style: ts.body)),
          ], labelWidth: 100),
          if (_busy) ...[
            const SizedBox(height: Sp.x4),
            Row(
              children: [
                const ESpinner(),
                const SizedBox(width: Sp.x3),
                Expanded(child: Text(d.method == TxMethod.file ? 'Creating the file.' : 'Sending. This can take a few seconds; keep this window open.', style: ts.small.copyWith(color: c.dim))),
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
