import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/api.dart' show DeskWalletApi;
import '../../data/http_address.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../../smart_outputs.dart';
import '../../widgets/kit.dart';
import 'contact_picker.dart';
import 'epicbox_notice.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import 'file_panels.dart';
import 'send_advanced.dart';
import 'send_summary_rows.dart';

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
    this.switched = false,
    this.strategy,
    this.smart,
    this.advancedOpen = false,
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

  /// [recipient] was just pasted: the method follows it and the switch tag shows.
  final bool switched;

  /// This send's strategy and Split change (Advanced); null is the Outputs default.
  final SelectionStrategy? strategy;
  final bool? smart;
  final bool advancedOpen;
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
    this.summary,
    this.options,
    this.strategy = SelectionStrategy.smallest,
    this.defaultStrategy = SelectionStrategy.smallest,
    this.extraFee = 0,
  });

  final TxMethod method;
  final String? to;
  final String? contactName;
  final int amount;
  final int fee;
  final String message;
  final bool sendAll;
  final bool dandelion;

  /// What the send spends, locks and leaves (F11); null without an estimate.
  final SendSummary? summary;

  /// The strategy and change outputs the estimate was made with; the send uses the same.
  final SendOptions? options;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  /// What splitting the change adds to the fee.
  final int extraFee;

  int get total => amount + fee;
}

/// Amount text to nanoepic: null when it is not a number, [_tooLong] for more than 8 decimals.
const int _tooLong = epicTooLong;
int? _parseAmount(String raw) => parseEpic(raw);

/// What is wrong with the recipient for method [m], or null (spec 7: one parser for every kind).
String? _recipientError(TxMethod m, String v, DeskWalletApi api) {
  final t = v.trim();
  if (m == TxMethod.file) return null;
  if (t.isEmpty) return 'Add an address to send to.';
  final p = parseAddress(t, api);
  switch (m) {
    case TxMethod.file:
      return null;
    case TxMethod.epicbox:
      return p.kind == AddressKind.epicbox && p.complete ? null : 'This is not a valid Epicbox address.';
    case TxMethod.http:
      if (p.kind == AddressKind.epicbox || p.kind == AddressKind.tor) return 'This is not an HTTP address.';
      final problem = httpAddressProblem(p.kind == AddressKind.http ? p.canonical : t);
      return problem == null ? null : '$problem.';
    case TxMethod.tor:
      return p.kind == AddressKind.tor && p.complete ? null : 'This is not a valid Tor address.';
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
  // The estimate with this send's strategy and Split change (F11, F12): [_fee] is its fee.
  SmartSendPlan? _plan;
  // Advanced: this send's choices; null takes the Outputs default.
  late SelectionStrategy? _strategyOverride = _args.strategy;
  late bool? _smartOverride = _args.smart;
  // The auto-switch (spec 8.4): the To text before this change, and the tag's method while
  // it shows (3 s).
  String _lastTo = '';
  TxMethod? _switchedTo;
  bool _tagOn = false;
  Timer? _tagTimer;
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
    _autoSwitch(forced: true, tag: args.switched);
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
    _tagTimer?.cancel();
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
    // The local node at height 0 is still downloading the chain (O2): no send until it has it.
    if (s.nodeHealth == ServiceHealth.slow && s.nodeHeight == 0) return -1;
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

  OutputPrefs get _prefs => ref.read(deskOutputPrefsProvider).value ?? const OutputPrefs();

  /// Sending everything spends every output.
  SelectionStrategy get _strategy => _all ? SelectionStrategy.all : (_strategyOverride ?? _prefs.strategy);

  bool get _smart => _smartOverride ?? _prefs.smartOutputs;

  /// The send of [n] as it would go out now: LEPIC's estimate with the strategy, and again
  /// with the change split when SmartOutputs says so (the app never works out a fee).
  Future<SmartSendPlan> _planFor(int n) async {
    final api = ref.read(deskApiProvider);
    if (_all) {
      const all = SendOptions(strategy: SelectionStrategy.all);
      final e = await api.estimateSend(n, options: all);
      return SmartSendPlan(base: e, decision: const SmartOutputsDecision(1, SmartOutputsReason.noChange, outputsLeft: 0), estimate: e, options: all);
    }
    int? spendable;
    try {
      spendable = (await ref.read(deskOutputsProvider.future)).where((o) => o.spendable).length;
    } on Object {
      // Without the list the change is not split.
    }
    return planSend(
      estimate: (o) => api.estimateSend(n, options: o),
      strategy: _strategy,
      smartOutputsOn: _smart && spendable != null,
      spendableOutputs: spendable ?? 0,
      splitRefused: deskSplitRefused,
    );
  }

  /// Estimates again at once (Advanced changed, the defaults or the balance moved).
  void _replan() {
    _feeFor = -1;
    unawaited(_loadFee());
  }

  Future<void> _loadFee() async {
    final n = _amountNano;
    if (n <= 0) {
      setState(() {
        _fee = null;
        _plan = null;
        _feeFor = -1;
      });
      return;
    }
    if (n == _feeFor) return;
    _feeFor = n;
    SmartSendPlan? plan;
    try {
      plan = await _planFor(n);
    } on Object {
      // More than can be sent, or the wallet is busy: the amount check says which.
      plan = null;
    }
    if (!mounted || _feeFor != n) return;
    setState(() {
      _plan = plan;
      _fee = plan?.estimate.fee;
    });
  }

  /// The method follows the address (spec 8.4): a complete address of another kind, or any
  /// address that was pasted ([forced], or one change adding 8 or more characters), moves it to
  /// that kind. Text still being typed never does, and nothing switches back when the text
  /// becomes incomplete. The field keeps its text.
  void _autoSwitch({bool forced = false, bool tag = true}) {
    final text = _to.text;
    final added = text.length - _lastTo.length;
    _lastTo = text;
    if (_method == TxMethod.file) return;
    final p = parseAddress(text, ref.read(deskApiProvider));
    final m = methodForKind(p.kind);
    if (m == null || m == _method || !_offered(m)) return;
    if (!(forced || added >= 8 || p.complete)) return;
    _method = m;
    if (tag) _showSwitched(m);
  }

  static bool _offered(TxMethod m) => switch (m) {
    TxMethod.http => DeskFeatures.httpDirect,
    TxMethod.tor => DeskFeatures.tor,
    _ => true,
  };

  /// "Over Tor" next to To for 3 s, read out once.
  void _showSwitched(TxMethod m) {
    _switchedTo = m;
    _tagOn = true;
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _tagOn = false);
    });
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

  void _changed({bool to = false, bool amount = false, bool pasted = false}) {
    setState(() {
      if (amount) {
        _all = false;
        _amountEdited = true;
        _allError = null;
      }
      if (to) {
        _toEdited = true;
        _suggestOff = false;
        _autoSwitch(forced: pasted);
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
      final max = spendable > 0 ? await ref.read(deskApiProvider).estimateMax() : null;
      final (n, fee) = (max?.amount ?? 0, max?.fee ?? 0);
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
        _plan = SmartSendPlan(
          base: max!,
          decision: const SmartOutputsDecision(1, SmartOutputsReason.noChange, outputsLeft: 0),
          estimate: max,
          options: const SendOptions(strategy: SelectionStrategy.all),
        );
        _amount.text = formatEpic(n, minDecimals: 0).replaceAll(',', '');
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
    _changed(to: true, pasted: true);
  }

  void _use(Contact c) {
    setState(() {
      final m = contactMethod(c);
      if (m != _method) {
        _method = m;
        _showSwitched(m);
      }
      _to.text = c.address;
      _lastTo = c.address;
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

  Future<void> _startEpicbox() async {
    setState(() => _starting = true);
    try {
      await ref.read(deskProvider.notifier).setEpicboxListening(true);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Epicbox not turned on', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// "This is the wallet's own address." when the Epicbox recipient is this wallet (M18): the
  /// part before @ the same, exactly (it is case-sensitive), and the server this wallet's or
  /// left out (":443" is the same server).
  String? _ownAddressError(DeskState st) {
    final own = st.epicboxAddress;
    if (_method != TxMethod.epicbox || own == null || own.isEmpty) return null;
    final (key, host) = _epicboxParts(_to.text);
    final (ownKey, ownHost) = _epicboxParts(own);
    return key == ownKey && (host == null || host == ownHost) ? "This is the wallet's own address." : null;
  }

  /// The key and the server (lower-case, without ":443"; null when missing) of an Epicbox address.
  static (String, String?) _epicboxParts(String address) {
    final a = address.trim();
    final at = a.indexOf('@');
    if (at < 0) return (a, null);
    var host = a.substring(at + 1).toLowerCase();
    if (host.endsWith(':443')) host = host.substring(0, host.length - 4);
    return (a.substring(0, at), host.isEmpty ? null : host);
  }

  String? _toError(DeskState st) => _ownAddressError(st) ?? _recipientError(_method, _to.text, ref.read(deskApiProvider));

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
    if (_toError(st) != null || _amountError(st.balance?.spendable) != null) return;
    await _openReview();
  }

  Future<void> _openReview({bool startBusy = false}) async {
    // The summary's estimate may still be on its way: the review always shows the real fee.
    if (_fee == null || _plan?.estimate.amount != _amountNano) {
      final SmartSendPlan plan;
      try {
        plan = await _planFor(_amountNano);
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
      setState(() {
        _plan = plan;
        _fee = plan.estimate.fee;
      });
    }
    final contacts = ref.read(deskProvider).contacts;
    final n = _amountNano;
    final plan = _plan;
    final balance = ref.read(deskProvider).balance;
    final draft = _Draft(
      method: _method,
      to: _method == TxMethod.file ? null : _to.text.trim(),
      contactName: _contactOf(contacts)?.name,
      amount: n,
      fee: _fee ?? 0,
      message: _message.text.trim(),
      sendAll: _all,
      dandelion: _dandelion,
      summary: plan == null || balance == null ? null : SendSummary.of(balance: balance.total, spendable: balance.spendable, estimate: plan.estimate),
      options: plan?.options,
      strategy: _strategy,
      defaultStrategy: _prefs.strategy,
      extraFee: plan == null ? 0 : plan.estimate.fee - plan.base.fee,
    );
    // Plain HTTP to another computer: the slate travels unencrypted, so ask first.
    final plain = draft.method == TxMethod.http && plainHttpNeedsConsent(draft.to!);
    if (plain) {
      final ok = await showEDialog<bool>(context, builder: (_) => const PlainHttpDialog());
      if (!mounted || ok != true) return;
    }
    final notifier = ref.read(deskProvider.notifier);
    // F6: opened with the remembered password, a send above the set amount asks the password.
    final api = ref.read(deskApiProvider);
    final askAbove = ref.read(settingsPrefsProvider).askAboveOf(ref.read(deskProvider).account?.id);
    final ask = api.openedRemembered && draft.amount > askAbove;
    final res = await showEDialog<SendResult>(
      context,
      dismissible: false,
      builder: (_) => _ReviewDialog(
        draft: draft,
        startBusy: startBusy,
        checkPassword: ask ? api.checkPassword : null,
        onConfirm: () => notifier.send(
          SendRequest(
            method: draft.method,
            amount: draft.amount,
            to: draft.to,
            message: draft.message.isEmpty ? null : draft.message,
            sendAll: draft.sendAll,
            dandelion: draft.dandelion,
            allowPlainHttp: plain,
            // As estimated: the strategy, the change outputs; a send-all spends every output.
            options: draft.options ?? (draft.sendAll ? const SendOptions(strategy: SelectionStrategy.all) : null),
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
    // The Outputs defaults and the balance feed the estimate: a change estimates again.
    ref.watch(deskOutputPrefsProvider);
    ref.listen(deskOutputPrefsProvider, (_, _) => _replan());
    ref.listen(deskProvider.select((s) => s.balance), (_, _) => _replan());
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
        text: 'Epicbox sends work once Epicbox receiving is on. Send by file meanwhile.',
        tone: ETone.warn,
        icon: EIcons.antenna,
        actions: [
          if (eb == ServiceHealth.off)
            EButton(label: 'Turn on Epicbox receiving', icon: EIcons.epicbox, size: EBtnSize.inline, busy: _starting, onPressed: _starting ? null : _startEpicbox),
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
    final toErr = _submitted && !_toEdited ? _toError(st) : null;
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
        ESegmented<TxMethod>(
          size: EBtnSize.md,
          stretch: true,
          segments: const [
            ESegment(TxMethod.epicbox, 'Epicbox', icon: EIcons.epicbox),
            if (DeskFeatures.httpDirect) ESegment(TxMethod.http, 'HTTP', icon: EIcons.http),
            if (DeskFeatures.tor) ESegment(TxMethod.tor, 'Tor', icon: EIcons.tor),
            ESegment(TxMethod.file, 'File', icon: EIcons.file),
          ],
          value: _method,
          onChanged: (m) => setState(() {
            _method = m;
            _failure = null;
          }),
        ),
        SizedBox(height: Sp.x4),
        _MethodStrip(_method),
        SizedBox(height: Sp.x6),
        if (!file) ...[
          EField(
            label: 'To',
            labelTrailing: _SwitchTag(method: _switchedTo, shown: _tagOn),
            error: toErr,
            help: toErr == null ? 'Paste an address, or type a contact’s name.' : null,
            child: EInput(
              controller: _to,
              mono: true,
              invalid: toErr != null,
              hint: 'Address or contact',
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
              text: st.status?.torIncluded ?? true ? 'Turn it on to send to a Tor address.' : 'Tor is not in this build.',
              tone: ETone.warn,
              icon: EIcons.tor,
              actions: [
                if (st.status?.torIncluded ?? true)
                  EButton(label: 'Turn on Tor receiving', size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : _turnOnTor),
              ],
            ),
          ] else if (_method == TxMethod.tor && st.status != null && !st.status!.torCanSend) ...[
            SizedBox(height: Sp.x3),
            Semantics(
              liveRegion: true,
              child: ENotice(
                title: st.status!.tor == ServiceHealth.down ? 'Tor is not connected' : 'Tor is connecting',
                text: st.status!.tor == ServiceHealth.down
                    ? '${methodStateLine(TxMethod.tor, st.status!, st.settings).text}. Sending over Tor needs it.'
                    : '${methodStateLine(TxMethod.tor, st.status!, st.settings).text}. Sending over Tor starts once it is connected.',
                tone: st.status!.tor == ServiceHealth.down ? ETone.risk : ETone.neutral,
                icon: EIcons.tor,
                actions: [
                  if (st.status!.tor == ServiceHealth.down)
                    EButton(label: 'Retry', size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : _turnOnTor),
                ],
              ),
            ),
          ],
          if (contact != null) ...[
            SizedBox(height: Sp.x2),
            _PickedCard(
              contact: contact,
              onClear: () {
                _to.clear();
                _changed(to: true);
              },
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
        SizedBox(height: Sp.x5),
        SendAdvanced(
          strategy: _strategy,
          defaultStrategy: _prefs.strategy,
          split: _smart,
          sendAll: _all,
          initiallyOpen: _args.advancedOpen,
          onStrategy: (v) {
            setState(() => _strategyOverride = v);
            _replan();
          },
          onSplit: (v) {
            setState(() => _smartOverride = v);
            _replan();
          },
          onOutputs: () => ref.read(deskNavProvider.notifier).go(DeskRoute.outputs),
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

  /// What the summary shows now: the amounts and the one line under Review send.
  Widget _summary(DeskState st, SendResult? res) {
    final spendable = st.balance?.spendable;
    final n = _amountNano;
    final fee = n > 0 ? (_fee ?? 0) : 0;
    final nodeBlocked = _nodeBlock(st) != null;
    final hint = switch (null) {
      _ when res is SendDone => 'Sent. Enter a new amount and recipient to send again.',
      _ when nodeBlocked => 'Waiting for the node to sync.',
      _ when _epicboxBlocked(st) => 'Waiting for Epicbox to connect.',
      _ when _torBlocked(st) => st.settings.tor ? 'Waiting for Tor to connect.' : 'Turn on Tor to send to a Tor address.',
      _ when _submitted && !_toEdited && _toError(st) != null => 'Fix the fields marked in red.',
      _ when _submitted && !_amountEdited && _amountError(spendable) != null => 'Fix the fields marked in red.',
      _ when _reviewing => 'Checking the fee for this amount.',
      _ => 'Nothing is sent until confirmed.',
    };
    final plan = _plan?.estimate.amount == n && n > 0 ? _plan : null;
    final balance = st.balance;
    return _SendSummary(
      amount: n,
      fee: fee,
      spendable: spendable,
      summary: plan == null || balance == null ? null : SendSummary.of(balance: balance.total, spendable: balance.spendable, estimate: plan.estimate),
      extraFee: plan == null ? 0 : plan.estimate.fee - plan.base.fee,
      strategy: _strategy,
      defaultStrategy: _prefs.strategy,
      updating: st.status?.syncProgress != null,
      hint: hint,
      reviewing: _reviewing,
      onReview: _canSend(st) && !_reviewing ? _review : null,
    );
  }
}

/// The Send page's summary panel: amount, fee, total, balance after, Review send and the
/// line under it. One widget so the summary rows can grow (outputs, wave 5) without the form.
class _SendSummary extends StatelessWidget {
  const _SendSummary({
    required this.amount,
    required this.fee,
    required this.spendable,
    required this.updating,
    required this.hint,
    required this.reviewing,
    required this.onReview,
    this.summary,
    this.extraFee = 0,
    this.strategy = SelectionStrategy.smallest,
    this.defaultStrategy = SelectionStrategy.smallest,
  });

  /// What the send spends, locks and leaves (F11, F12); null until it is estimated.
  final SendSummary? summary;

  /// What splitting the change adds to the fee.
  final int extraFee;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  /// In nano EPIC; 0 when nothing valid is entered.
  final int amount;
  final int fee;
  final int? spendable;

  /// The wallet scans: the balance after is not final.
  final bool updating;
  final String hint;
  final bool reviewing;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final n = amount;
    final bad = n > 0 && spendable != null && n + fee > spendable!;
    final ready = n > 0 && !bad;
    Widget line(String label, int? v, {bool strong = false, bool risk = false, bool dim = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? ts.strong : ts.bodyDim)),
          if (v == null || v == 0 && label != 'Balance after')
            Text('—', style: ts.mono(size: Fs.md, color: c.faint))
          else
            EMoney(v, size: strong ? Fs.lg : Fs.md, color: risk ? c.risk : (dim ? c.dim : null), weight: strong ? FontWeight.w600 : null),
        ],
      ),
    );
    return EPanel(
      title: 'Summary',
      padding: EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line('Amount', n > 0 ? n : null, risk: bad),
          line('Network fee', fee > 0 ? fee : null),
          ExpandFade(
            open: ready && (summary?.changeOutputs ?? 0) > 1,
            child: summary == null || summary!.changeOutputs < 2
                ? const SizedBox.shrink()
                : SendSplitLine(outputs: summary!.changeOutputs, extraFee: extraFee, change: summary!.change),
          ),
          Divider(height: Sp.x4, color: c.line),
          line('Total', ready ? n + fee : null, strong: true),
          SendLockRows(summary: ready ? summary : null, strategy: strategy, defaultStrategy: defaultStrategy),
          if (updating) Text('Balance updating while the wallet scans.', style: ts.caption),
          SizedBox(height: Sp.x4),
          EButton.primary(label: 'Review send', icon: EIcons.send, expand: true, busy: reviewing, onPressed: onReview),
          SizedBox(height: Sp.x3),
          Semantics(liveRegion: true, child: Text(hint, style: ts.small, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Under the selector: the method's picture, what it does in bold and what it needs (spec 8.2).
/// The art goes above the text in a narrow column; a method change crossfades.
class _MethodStrip extends StatelessWidget {
  const _MethodStrip(this.method);

  final TxMethod method;

  static (String, String) words(TxMethod m) => switch (m) {
    TxMethod.epicbox => ('The recipient can be offline.', 'The Epicbox server holds the payment until they open their wallet.'),
    TxMethod.http => ('Straight to their wallet.', 'It must be open and reachable at its HTTP address.'),
    TxMethod.tor => ('Straight to their wallet, over Tor.', 'Slower and more private. Their wallet must be open.'),
    TxMethod.file => ('No connection needed.', 'Hand the file over, get their response file back, then finalize it here.'),
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final (title, line) = words(method);
    return EPanel(
      padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : Motion.cross,
        switchInCurve: Motion.easeOut,
        switchOutCurve: Motion.easeIn,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
        child: LayoutBuilder(
          key: ValueKey(method),
          builder: (context, box) {
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: ts.strong),
                SizedBox(height: 2.u),
                Text(line, style: ts.small),
              ],
            );
            if (box.maxWidth < 440.u) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HeroArt(method), SizedBox(height: Sp.x2), text]);
            }
            return Row(children: [HeroArt(method), SizedBox(width: 20.u), Expanded(child: text)]);
          },
        ),
      ),
    );
  }
}

/// "Over Tor" next to To after the method followed the address: in over 120 ms, out over
/// 200 ms after 3 s, and read out once.
class _SwitchTag extends StatelessWidget {
  const _SwitchTag({required this.method, required this.shown});

  final TxMethod? method;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final m = method;
    if (m == null) return const SizedBox.shrink();
    final (word, kind) = switch (m) {
      TxMethod.tor => ('Over Tor', 'Tor'),
      TxMethod.http => ('Over HTTP', 'HTTP'),
      TxMethod.file => ('File', 'File'),
      TxMethod.epicbox => ('Via Epicbox', 'Epicbox'),
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: EdgeInsets.only(left: Sp.x2),
      child: Semantics(
        liveRegion: true,
        label: shown ? '$kind address. Method set to $kind.' : null,
        excludeSemantics: true,
        child: AnimatedOpacity(
          key: const ValueKey('send-switch-tag'),
          opacity: shown ? 1 : 0,
          duration: reduce ? Duration.zero : Duration(milliseconds: shown ? 120 : 200),
          child: SizedBox(height: 22.u, child: ETag(word, tone: ETone.gold, icon: methodIcon(m))),
        ),
      ),
    );
  }
}

/// The contact the To field holds: name and kind, the short address, Clear (spec 7.1).
class _PickedCard extends StatelessWidget {
  const _PickedCard({required this.contact, required this.onClear});

  final Contact contact;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      key: const ValueKey('send-picked'),
      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      child: Row(
        children: [
          EAvatar(contact.name, size: 28.u),
          SizedBox(width: Sp.x3),
          Expanded(child: EAddressLines(name: contact.name, address: contact.address)),
          SizedBox(width: Sp.x2),
          EButton.ghost(label: 'Clear', size: EBtnSize.inline, onPressed: onClear),
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
        constraints: BoxConstraints(maxWidth: 560.u),
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
                label: '${x.name}, ${x.address}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onPick(x),
                  child: Container(
                    height: 44.u,
                    padding: EdgeInsets.symmetric(horizontal: Sp.x3),
                    child: Row(
                      children: [
                        EAvatar(x.name, size: 28.u),
                        SizedBox(width: Sp.x3),
                        Expanded(child: Text(x.name, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: Sp.x2),
                        EKindTag(addressKindOf(x.address)),
                        SizedBox(width: Sp.x3),
                        Flexible(child: EShortAddress(x.address, tooltip: false)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Divider(height: 1, color: c.line),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
              child: Text(contacts.length == 1 ? '1 contact matches' : '${contacts.length} contacts match', style: ts.caption),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.draft, required this.onConfirm, this.startBusy = false, this.checkPassword});

  final _Draft draft;
  final Future<SendResult> Function() onConfirm;
  final bool startBusy;

  /// Set when this send asks the wallet's password first (F6); true when it is right.
  final Future<bool> Function(String password)? checkPassword;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late bool _busy = widget.startBusy;
  final _password = TextEditingController();
  String? _wrong;

  bool get _asks => widget.checkPassword != null && !widget.startBusy;

  /// Send is ready: no password asked, or one typed.
  bool get _ready => !_busy && (!_asks || _password.text.isNotEmpty);

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (!_ready) return;
    setState(() => _busy = true);
    if (_asks) {
      bool ok;
      try {
        ok = await widget.checkPassword!(_password.text);
      } on Object catch (e) {
        logWarn('desk', 'send password check ended with ${e.runtimeType}');
        ok = false;
      }
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _wrong = 'Wrong password.';
        });
        _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
        return;
      }
      _password.clear();
    }
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

  // The same marking as EAddress: the key's first and last six characters, the server dim.
  Widget _address(BuildContext context, String to) {
    final c = context.dc;
    final base = context.ts.mono(size: Fs.sm, color: c.dim);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    final at = to.indexOf('@');
    final onion = at < 0 && to.toLowerCase().endsWith('.onion');
    final cut = at > 0 ? at : (onion ? to.length - 6 : to.length);
    final key = to.substring(0, cut);
    final rest = to.substring(cut);
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
      TxMethod.http => 'HTTP (their wallet must be open)',
      TxMethod.tor => 'Tor (their wallet must be open)',
      TxMethod.file => 'Transaction file',
    };
    final sum = d.summary;
    final lines = sum == null ? null : reviewOutputLines(sum, strategy: d.strategy, defaultStrategy: d.defaultStrategy, extraFee: d.extraFee);
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
            (
              'Network fee',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EMoney(d.fee),
                  if (lines?.feeSecondLine != null) Text(lines!.feeSecondLine!, style: ts.small),
                ],
              ),
            ),
            ('Total', EMoney(d.total, weight: FontWeight.w600)),
            ...?lines?.facts,
            if (DeskFeatures.dandelion && d.method != TxMethod.file) ('Privacy', Text(d.dandelion ? 'Dandelion++ on' : 'Dandelion++ off', style: ts.body)),
            if (d.message.isNotEmpty) ('Message', Text(d.message, style: ts.body)),
          ], labelWidth: 100.u),
          if (_asks && !_busy) ...[
            SizedBox(height: Sp.x4),
            // Enter in the password sends once it is filled (wave 2 rules).
            EForm(
              onSubmit: _ready ? _go : null,
              child: EField(
                label: 'Password',
                help: 'Opened with the remembered password: this send asks it.',
                error: _wrong,
                child: EPasswordInput(
                  controller: _password,
                  autofocus: true,
                  invalid: _wrong != null,
                  onChanged: (_) => setState(() => _wrong = null),
                ),
              ),
            ),
          ],
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
                      TxMethod.tor => 'Reaching their wallet over Tor… This can take a while. Keep the app open.',
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
        EButton.primary(label: _busy ? 'Sending' : 'Send ${formatEpic(d.amount)} EPIC', icon: EIcons.send, busy: _busy, onPressed: _ready ? _go : null),
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
