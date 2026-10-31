// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../amount.dart' as shared show formatEpic;
import '../../../amount.dart' show exactDecimals;
import '../../../l10n.dart' show LocalizedFormatException, localDecimal;
import '../../../payment_prefs.dart' show PaymentPrefs;
import '../../../providers.dart' show defaultMinimumConfirmations;
import '../../../known_relays.dart';
import '../../../log.dart';
import '../../../network.dart' show EpicboxRelay;
import '../../../devices/device_link_code.dart' show isDeviceLinkText;
import '../../data/api.dart' show DeskWalletApi;
import '../../data/devices_state.dart' show deskHeldProvider, deskLinkedDevicesOnProvider;
import '../devices/link_flow.dart' show showDeskLinkDevice;
import '../../data/http_address.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../data/tor_view.dart';
import '../../../models.dart' show PairingRecord, PairingState, slateMessageMaxBytes;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../../network_gate.dart' show NetBlock, NetBlockByMode, NetGate;
import '../../../smart_outputs.dart';
import '../../../utf8_limit.dart';
import '../../app/shell.dart' show outputsShown;
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../data/pairing_state.dart' show DeskPairNet, deskContactPairingProvider, deskPairNetProvider, deskPairingByIdProvider, deskPairingNameProvider, deskPairingOnProvider, deskPairsProvider;
import '../../widgets/kit.dart';
import '../pairing/pair_screens.dart' show deskOpenPairingText, showDeskCheckWords;
import '../../widgets/tor_chip.dart';
import '../../../ui/pairing/pairing_parts.dart' show TrustBadge;
import 'contact_picker.dart';
import 'epicbox_notice.dart';
import 'file_panels.dart';
import 'finalize_screen.dart' show FinalizeArgs;
import 'import_tx_screen.dart' show ImportArgs;
import 'send_advanced.dart';
import '../settings/prefs.dart' show SettingsJump, settingsPrefsProvider;
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../data/method_names.dart' show methodKindOf, methodShortLabel;
import '../../../scan/scan_router.dart';
import '../../../scan/scan_text.dart';
import 'send_code.dart';
import 'send_summary_rows.dart';

/// Where the Send page is, so the tour reaches every state without taps.
enum SendStep { form, errors, review, sending, done, fileReady, failed }

/// Argument of the Send route. A [Contact] is accepted too (prefills the recipient).
/// [nodeSync] (0..1) and [epicboxHealth] stand in for the wallet's status in the tour.
class SendArgs {
  const SendArgs({
    this.method,
    this.recipient,
    this.amount,
    this.message,
    this.step = SendStep.form,
    this.contact,
    this.nodeSync,
    this.epicboxHealth,
    this.tor,
    this.privacyOpen = false,
    this.suggest = false,
    this.switched = false,
    this.strategy,
    this.smart,
    this.advancedOpen = false,
    this.code,
    this.codeOrigin = CodeOrigin.link,
    this.pairingTo,
  });

  /// A paired contact with no address, by its pairing id: paid through its mailbox. A
  /// [contact] with no address and a pairing that pays this way opens the same.
  final String? pairingTo;

  /// The method Send opens on; null is the one chosen in Settings › Transactions.
  final TxMethod? method;
  final String? recipient;
  final String? amount;
  final String? message;
  final SendStep step;
  final Contact? contact;
  final double? nodeSync;
  final ServiceHealth? epicboxHealth;

  /// Stands in for the Tor switch's state in the tour.
  final TorState? tor;
  final bool privacyOpen;

  /// Show the contacts matching [recipient] as if it was typed.
  final bool suggest;

  /// [recipient] was just pasted: the method follows it and the switch tag shows.
  final bool switched;

  /// This send's strategy and Split change (Advanced); null is the Outputs default.
  final SelectionStrategy? strategy;
  final bool? smart;
  final bool advancedOpen;

  /// A pasted or linked text Send opens with, read as [_SendScreenState.openPaymentText]
  /// does: the way in for desktop links.
  final String? code;
  final CodeOrigin codeOrigin;
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
    this.unknownRelay,
    this.code,
    this.pairingId,
    this.queued = false,
    this.confirmations = defaultMinimumConfirmations,
  });

  final TxMethod method;

  /// The wallet's minimum confirmations: blocks until the change confirms.
  final int confirmations;

  /// Through the mailbox of this pairing: a contact with no address, [to] null.
  final String? pairingId;

  /// Epicbox is off: the payment waits in the outbox until it is on again.
  final bool queued;
  final String? to;
  final String? contactName;
  final int amount;
  final int fee;
  final String message;
  final bool sendAll;
  final bool dandelion;

  /// What the send spends, locks and leaves; null without an estimate.
  final SendSummary? summary;

  /// The strategy and change outputs the estimate was made with; the send uses the same.
  final SendOptions? options;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  /// The recipient's Epicbox server when the app does not know it: the review warns that the
  /// address may be mistyped (linux-14). A warning, not a block.
  final EpicboxRelay? unknownRelay;

  /// What splitting the change adds to the fee.
  final int extraFee;

  /// The code the form was filled from (a request, or a link's address); null when typed.
  final SendCode? code;

  int get total => amount + fee;
}

/// Amount text in [l]'s language to nanoepic ([parseEpicIn]): null when it is refused.
int? _parseAmount(AppLocalizations l, String raw) {
  try {
    return parseEpicIn(l, raw);
  } on LocalizedFormatException {
    return null;
  }
}

/// What is wrong with the recipient for method [m], or null (one parser for every kind).
String? _recipientError(AppLocalizations l, TxMethod m, String v, DeskWalletApi api) {
  final t = v.trim();
  if (m == TxMethod.file) return null;
  if (t.isEmpty) return l.deskSendErrNoAddress;
  final p = parseAddress(t, api);
  // The build without Tor reaches no onion, by any method.
  if (!DeskFeatures.tor && p.kind == AddressKind.tor) return l.sendTorNotInVersion;
  switch (m) {
    case TxMethod.file:
      return null;
    case TxMethod.epicbox:
      return p.kind == AddressKind.epicbox && p.complete ? null : l.deskSendErrEpicbox;
    // Direct: an http(s) address or an onion; the address decides the route.
    case TxMethod.http || TxMethod.tor:
      if (p.kind == AddressKind.epicbox) return l.deskSendErrNotDirect;
      if (p.kind == AddressKind.tor) return p.complete ? null : l.deskSendErrOnion;
      final problem = httpAddressProblem(p.kind == AddressKind.http ? p.canonical : t, l);
      return problem == null ? null : '$problem.';
  }
}

/// The segment a method shows under: a send to an onion is a Direct send ([TxMethod.http]).
TxMethod _segmentOf(TxMethod m) => m == TxMethod.tor ? TxMethod.http : m;


/// The Send form as it was left, for the wallet it was filled in: people leave Send to check
/// the balance and come back to it (the owner). Clear in To empties the recipient; a payment
/// made or New send forgets it.
class _KeptSend {
  const _KeptSend({
    required this.wallet,
    required this.to,
    required this.amount,
    required this.message,
    required this.method,
    required this.pairingTo,
    required this.code,
    required this.codeBanner,
  });

  final String? wallet;
  final String to;
  final String amount;
  final String message;
  final TxMethod method;
  final String? pairingTo;
  final SendCode? code;
  final bool codeBanner;
}

/// Holds [_KeptSend] while the page is closed. Written from dispose, so it tells no one.
class _SendKeeper {
  _KeptSend? kept;
}

/// A new keeper for every wallet opened: a lock or a switch drops the draft with the rest of
/// the open wallet's data.
final _sendKeeperProvider = Provider<_SendKeeper>((ref) {
  ref.watch(deskProvider.select((s) => s.account?.id));
  return _SendKeeper();
});

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
  // The estimate for [_feeFor] is on its way: the summary shows spinners, never a Total
  // without the fee.
  bool _feeBusy = false;
  // The estimate with this send's strategy and Split change: [_fee] is its fee.
  SmartSendPlan? _plan;
  // Advanced: this send's choices; null takes the Outputs default.
  late SelectionStrategy? _strategyOverride = _args.strategy;
  late bool? _smartOverride = _args.smart;
  // The auto-switch: the To text before this change, and the tag's method while
  // it shows (3 s).
  String _lastTo = '';
  TxMethod? _switchedTo;
  bool _tagOn = false;
  Timer? _tagTimer;
  SendResult? _result;
  // The failed payment's message, worded when shown.
  String Function(AppLocalizations l)? _failure;

  /// The failed payment may exist (waiting in Activity): no Review again.
  bool _failureInActivity = false;

  // The code the form was filled from, whether its banner shows, and the reason a pasted code
  // stays in To instead (a bad or other-network address, a QR Payment part, a pairing link).
  SendCode? _code;
  bool _codeBanner = false;
  String Function(AppLocalizations l)? _codeError;

  /// A paired contact with no address, by its pairing id (DESIGN 1.3): its card takes the
  /// To field's place and the payment goes through its mailbox, sealed.
  String? _pairingTo;

  /// The pairing of a contact with no address, when the wallet pairs; null otherwise.
  String? _pairingOf(Contact c) {
    if (c.addresses.isNotEmpty || !ref.read(deskPairsProvider)) return null;
    return ref.read(deskContactPairingProvider(c.id))?.id;
  }

  /// [_pairingTo] goes by its mailbox now: Epicbox chosen (File and the rest ignore it).
  bool get _viaPairing => _pairingTo != null && _method == TxMethod.epicbox;

  /// A mailbox payment made now waits in the outbox: Epicbox is off (LEPIC queues it).
  bool _queues() => _viaPairing && ref.read(deskPairNetProvider) == DeskPairNet.epicboxOff;

  // Read in initState: dispose writes the draft and may not use ref.
  late final _SendKeeper _keeper;
  late final String? _wallet;

  @override
  void initState() {
    super.initState();
    _keeper = ref.read(_sendKeeperProvider);
    _wallet = ref.read(deskProvider).account?.folder;
    final a = widget.arg;
    SendArgs args = const SendArgs();
    if (a is SendArgs) {
      args = a;
    } else if (a is Contact) {
      args = SendArgs(contact: a);
    }
    _args = args;
    final contact = args.contact;
    final contactTo = contact == null ? null : contactAddress(contact, ref.read(deskProvider).settings.payments);
    _method = contact != null ? contactMethod(contact, contactTo) : args.method ?? _startMethod();
    _pairingTo = args.pairingTo ?? (contact == null ? null : _pairingOf(contact));
    if (_pairingTo != null) _method = TxMethod.epicbox;
    _to.text = args.recipient ?? contactTo ?? '';
    _autoSwitch(forced: true, tag: args.switched);
    _suggestOff = _to.text.isNotEmpty && !args.suggest;
    _amount.text = args.amount ?? '';
    _message.text = args.message ?? '';
    // After the first frame: reading the amount needs the language, not available in initState.
    if (args.amount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadFee());
      });
    }
    if (args.code case final code?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openPaymentText(code, origin: args.codeOrigin);
      });
    }
    // Send opened plainly (the sidebar, Overview) takes the form as it was left.
    final kept = _keeper.kept;
    _keeper.kept = null;
    if (a == null && kept != null && kept.wallet == _wallet) _restore(kept);
    switch (args.step) {
      case SendStep.errors:
        _submitted = true;
      case SendStep.review || SendStep.sending:
        WidgetsBinding.instance.addPostFrameCallback((_) => _openReview(startBusy: args.step == SendStep.sending));
      // The demo result reads the amount, which needs the language: built in
      // didChangeDependencies, before the first frame.
      case SendStep.done:
        _demoStep = SendStep.done;
      case SendStep.fileReady:
        _method = TxMethod.file;
        _demoStep = SendStep.fileReady;
      case SendStep.failed:
        _failure = (l) => l.deskSendNoAnswer;
        _submitted = true;
      case SendStep.form:
        break;
    }
  }

  /// A demo step whose result is still to be built ([didChangeDependencies]).
  SendStep? _demoStep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final step = _demoStep;
    if (step == null) return;
    _demoStep = null;
    _result = step == SendStep.done
        ? SendDone(_demoTx(TxMethod.epicbox, _args.recipient))
        : SendFileReady(_demoTx(TxMethod.file, null), 'f0e1d2c3.tx');
  }

  Tx _demoTx(TxMethod m, String? to) => Tx(
    id: 36,
    slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
    direction: TxDirection.sent,
    state: m == TxMethod.file || m == TxMethod.epicbox ? TxState.waitingRecipient : TxState.posted,
    method: m,
    amount: _parseAmount(context.l10n, _amount.text) ?? 12 * nanoPerEpic,
    fee: 600000,
    created: DateTime.now(),
    counterparty: to,
  );

  void _restore(_KeptSend kept) {
    _to.text = kept.to;
    _lastTo = kept.to;
    _amount.text = kept.amount;
    _message.text = kept.message;
    _method = kept.method;
    _pairingTo = kept.pairingTo;
    _code = kept.code;
    _codeBanner = kept.codeBanner;
    _suggestOff = true;
    if (kept.amount.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadFee());
      });
    }
  }

  /// What the page keeps when it closes: a form with something in it, never a finished one.
  _KeptSend? get _toKeep {
    if (_result != null || (_to.text.isEmpty && _amount.text.isEmpty && _message.text.isEmpty && _pairingTo == null)) return null;
    return _KeptSend(
      wallet: _wallet,
      to: _to.text,
      amount: _all ? '' : _amount.text,
      message: _message.text,
      method: _method,
      pairingTo: _pairingTo,
      code: _code,
      codeBanner: _codeBanner,
    );
  }

  @override
  void dispose() {
    _keeper.kept = _toKeep;
    _tagTimer?.cancel();
    _to.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  int? get _parsed => _parseAmount(context.l10n, _amount.text);
  int get _amountNano => (_parsed ?? 0) > 0 ? _parsed! : 0;

  ServiceHealth? _epicboxHealth(DeskState st) => _args.epicboxHealth ?? st.status?.epicboxHealth;

  /// Null while the node is usable; otherwise how far its sync is (0..1), or -1 when it does not answer.
  double? _nodeBlock(DeskState st) {
    // Offline on a node that is not local: nothing polls it, but a file still runs through it
    // (the Offline rework), with the note that it does (LNX-7).
    if (_method == TxMethod.file && deskOfflineUsesNode(st)) return null;
    // Kill switch asks no node: the file is made from the last confirmed height (a cold send).
    if (_method == TxMethod.file && NetGate.killSwitch) return null;
    if (_args.nodeSync != null) return _args.nodeSync;
    final s = st.status;
    if (s == null) return -1;
    // The local node at height 0 is still downloading the chain: no send until it has it.
    if (s.nodeHealth == ServiceHealth.slow && s.nodeHeight == 0) return -1;
    return s.nodeHealth == ServiceHealth.ok || s.nodeHealth == ServiceHealth.slow ? null : -1;
  }

  /// The node in use does not answer (as opposed to answering while it syncs).
  bool _nodeDown(DeskState st) => st.status?.nodeHealth == ServiceHealth.down;

  /// The Node list of the settings file is empty.
  bool get _noNode => ref.read(hostSettingsProvider).nodeUrls.isEmpty;

  bool _epicboxBlocked(DeskState st) {
    // LEPIC posts a mailbox payment itself, or keeps it in the outbox until it can.
    if (_method != TxMethod.epicbox || _viaPairing) return false;
    final h = _epicboxHealth(st);
    return h == ServiceHealth.off || h == ServiceHealth.checking;
  }

  TorState _torState(DeskState st) => _args.tor ?? deskNetTor(st);

  /// The network mode holds this send: Epicbox and Link in Node only and Kill switch (a Link
  /// send to a local address too: Node only turns Link off), and in Tor only without Tor. A
  /// file is never held: Node only lets it use the node in use ([deskOfflineUsesNode] says so
  /// on the screen), Kill switch makes it without a node. A method whose switch is off (Settings ›
  /// Transactions) holds it too ([NetBlock.methodOff]): a pasted address of that kind picks
  /// the method and the notice says it is off. Until To holds an address, Link is held only
  /// when both its methods are off: the address decides between Link · HTTP and Link · Tor.
  NetBlock _netBlock(DeskState st) => _method == TxMethod.file
      ? NetBlock.none
      // A pairing's mailbox payment waits in the outbox while Epicbox is off ("Queue
      // payment"); Offline and Tor still hold it.
      : _viaPairing
      ? deskNetBlock(st)
      : deskNetBlock(
          st,
          epicbox: _method == TxMethod.epicbox,
          // An onion in the build without Tor: no method would send it, its own line says so.
          offered: _onionNoTor ||
              (_method != TxMethod.epicbox && _to.text.trim().isEmpty
                  ? st.settings.payments.offersFamily(MethodFamily.link)
                  : st.settings.payments.offers(methodKindOf(_method))),
        );

  /// An onion in To in the build without Tor: said at once under To, nothing offered for it.
  bool get _onionNoTor => !DeskFeatures.tor && _method != TxMethod.file && addressKindOf(_to.text) == AddressKind.tor;

  /// The method this send goes by, for its name and its switch.
  MethodKind get _kind => methodKindOf(_method);

  /// How this send's connection goes with the Tor switch as it is now; null for File.
  TorWay? _torWay(DeskState st) {
    final route = switch (_method) {
      TxMethod.epicbox => TorRoute.epicbox,
      TxMethod.tor => TorRoute.onionDirect,
      TxMethod.http => _to.text.trim().isNotEmpty && plainHttpNeedsConsent(_to.text) ? TorRoute.plainHttpDirect : TorRoute.httpDirect,
      TxMethod.file => null,
    };
    return route == null ? null : torWay(route, _torState(st));
  }

  /// Tor holds this send: starting, not connected, or off for an onion. Nothing falls back.
  bool _torHeld(DeskState st) {
    final way = _torWay(st);
    return way != null && !torGoes(way);
  }

  bool _canSend(DeskState st) => _netBlock(st) == NetBlock.none && _nodeBlock(st) == null && !_epicboxBlocked(st) && !_torHeld(st) && _result is! SendDone;

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
      // The list as last read, else the wallet's own: never `deskOutputsProvider.future`, which
      // rebuilds on every refresh (a new Balance each time) and left the estimate, and with it
      // Network fee, Total and the lines under them, waiting for good (D-02).
      final outputs = ref.read(deskOutputsProvider).value ?? await api.outputs();
      spendable = outputs.where((o) => o.spendable).length;
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
    // Review never reuses a plan made for other choices: it estimates again if this one
    // has not arrived.
    _plan = null;
    _fee = null;
    unawaited(_loadFee());
  }

  Future<void> _loadFee() async {
    final n = _amountNano;
    if (n <= 0) {
      setState(() {
        _fee = null;
        _plan = null;
        _feeFor = -1;
        _feeBusy = false;
      });
      return;
    }
    if (n == _feeFor) return;
    setState(() {
      _feeFor = n;
      _feeBusy = true;
    });
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
      _feeBusy = false;
      // A failed estimate is tried again on the next change, even to the same amount.
      if (plan == null) _feeFor = -1;
    });
  }

  /// The method follows the address: a complete address of another kind, or any
  /// address that was pasted ([forced], or one change adding 8 or more characters), moves it to
  /// that kind. Text still being typed never does, and nothing switches back when the text
  /// becomes incomplete. The field keeps its text.
  void _autoSwitch({bool forced = false, bool tag = true}) {
    final text = _to.text;
    final added = text.length - _lastTo.length;
    _lastTo = text;
    if (_method == TxMethod.file) return;
    final p = parseAddress(text, ref.read(deskApiProvider));
    // Under Direct the address decides the route: an onion over Tor, anything else http(s).
    if (_segmentOf(_method) == TxMethod.http) _method = _directRoute(p.kind);
    final m = methodForKind(p.kind);
    if (m == null || _segmentOf(m) == _segmentOf(_method) || !_offered(m)) return;
    if (!(forced || added >= 8 || p.complete)) return;
    _method = m;
    if (tag) _showSwitched(m);
  }

  TxMethod _directRoute(AddressKind k) => k == AddressKind.tor && DeskFeatures.tor ? TxMethod.tor : TxMethod.http;

  /// Settings › Transactions › Send starts on, among the methods this build has.
  TxMethod _startMethod() => switch (ref.read(deskProvider).settings.payments.startMethod) {
    // Node only and Kill switch: Epicbox and Link don't go out, so an empty send starts on File
    // (an address given in To keeps its own method, and the note says why it is held).
    _ when NetGate.restricted && (_args.recipient ?? '').trim().isEmpty => TxMethod.file,
    MethodKind.linkHttp || MethodKind.linkTor => TxMethod.http,
    MethodKind.directFile => TxMethod.file,
    _ => TxMethod.epicbox,
  };

  /// Where an empty form goes when its method was switched off: the start method, or
  /// for one the desktop does not send by (QR Payment) the first it does that is on.
  TxMethod _nextMethod(PaymentPrefs p) {
    final link = p.offersFamily(MethodFamily.link);
    final start = _startMethod();
    if (start != TxMethod.epicbox || p.epicbox) return start;
    return link ? TxMethod.http : (p.directFile ? TxMethod.file : TxMethod.epicbox);
  }

  /// File Transfer is in the selector: its switch is on, or it is the fallback of a failed
  /// Epicbox, or a file send is under way.
  bool _fileShown(DeskState st) {
    final p = st.settings.payments;
    final eb = _epicboxHealth(st);
    return p.directFile || _method == TxMethod.file || (p.epicbox && (eb == ServiceHealth.off || eb == ServiceHealth.down));
  }

  /// The selector's segment for [m] can be chosen now: Epicbox and Link wait for the network
  /// mode (Node only, Kill switch, Tor only without Tor), Epicbox for its switch too (a
  /// pairing's mailbox queues), and a pairing recipient has no Link address. File always can.
  bool _segmentOn(DeskState st, TxMethod m) => switch (_segmentOf(m)) {
    TxMethod.epicbox => deskNetBlock(st) == NetBlock.none && (st.settings.payments.epicbox || _pairingTo != null),
    TxMethod.file => true,
    _ => _pairingTo == null && deskNetBlock(st) == NetBlock.none,
  };

  /// The first method that can be chosen now, in the selector's order; null when none can.
  TxMethod? _firstOn(DeskState st) {
    for (final m in [TxMethod.epicbox, TxMethod.http, if (_fileShown(st)) TxMethod.file]) {
      if (_segmentOn(st, m)) return m == TxMethod.http ? _directRoute(parseAddress(_to.text, ref.read(deskApiProvider)).kind) : m;
    }
    return null;
  }

  bool _moving = false;

  /// A method that cannot be chosen now never stays chosen with a live form (D-06): Send moves
  /// to the first that can, after this frame. Only this screen's choice moves; Settings ›
  /// Transactions › Send starts on stays as it is.
  void _keepMethodOn(DeskState st) {
    if (_moving || _result != null || _segmentOn(st, _method)) return;
    final next = _firstOn(st);
    if (next == null) return;
    _moving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moving = false;
      if (!mounted) return;
      final now = ref.read(deskProvider);
      if (_result != null || _segmentOn(now, _method)) return;
      final m = _firstOn(now);
      if (m == null) return;
      setState(() {
        _method = m;
        _failure = null;
      });
    });
  }

  static bool _offered(TxMethod m) => switch (m) {
    TxMethod.tor => DeskFeatures.tor,
    _ => true,
  };

  /// "Direct" (or the other method) next to To for 3 s, read out once.
  void _showSwitched(TxMethod m) {
    _switchedTo = m;
    _tagOn = true;
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _tagOn = false);
    });
  }

  bool _torBusy = false;

  /// Turns the Tor switch on (Turn on Tor, Retry). Off is only in Settings › Privacy & network.
  Future<void> _setTor(bool on) async {
    setState(() => _torBusy = true);
    try {
      await ref.read(deskProvider.notifier).setTor(on);
    } on Object catch (e) {
      if (mounted) showEToast(context, on ? context.l10n.deskSendTorOnFailed : context.l10n.deskSendTorOffFailed, text: deskErrorText(e, context.l10n), tone: ETone.risk);
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
        _codeError = null;
        _autoSwitch(forced: pasted);
        if (_leaveCode()) amount = true;
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
        setState(() => _allError = context.l10n.deskSendNothingSpendable);
        return;
      }
      setState(() {
        _all = true;
        _amountEdited = true;
        _fee = fee;
        _feeFor = n;
        _feeBusy = false;
        _plan = SmartSendPlan(
          base: max!,
          decision: const SmartOutputsDecision(1, SmartOutputsReason.noChange, outputsLeft: 0),
          estimate: max,
          options: const SendOptions(strategy: SelectionStrategy.all),
        );
        // The field takes the exact amount in its canonical form, never the display cut.
        _amount.text = localDecimal(context.l10n, shared.formatEpic(BigInt.from(n)));
      });
    } catch (_) {
      if (mounted) setState(() => _allError = context.l10n.deskSendAllFailed);
    } finally {
      if (mounted) setState(() => _allBusy = false);
    }
  }

  String? _amountError(int? spendable) {
    final l = context.l10n;
    if (_amount.text.trim().isEmpty) return l.deskSendErrAmountEnter;
    final int p;
    try {
      p = parseEpicIn(l, _amount.text);
    } on AmountFormatException catch (e) {
      return switch (e.problem) {
        AmountProblem.malformed => l.deskSendErrAmountEnter,
        AmountProblem.decimals => l.deskSendErrAmountDecimals,
        AmountProblem.tooLarge => e.text(l),
      };
    } on LocalizedFormatException catch (e) {
      return e.text(l);
    }
    if (p <= 0) return l.deskSendErrAmountZero;
    if (spendable != null && p + (_fee ?? 0) > spendable) {
      // The coins a payment of another linked device holds would have covered it: say so.
      final held = ref.read(deskHeldProvider);
      final heldTotal = held.fold<int>(0, (sum, h) => sum + h.value);
      if (held.isNotEmpty && p + (_fee ?? 0) <= spendable + heldTotal) {
        return l.sendHeldByDevice(formatEpicL(l, heldTotal), held.map((h) => h.device).join(', '));
      }
      return l.deskSendErrAmountMore;
    }
    return null;
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim();
    if (t == null || t.isEmpty || !mounted) return;
    if (openPaymentText(t, origin: CodeOrigin.paste)) return;
    setState(() => _to.text = t);
    _changed(to: true, pasted: true);
  }

  /// To changed by typing or a paste into it: one change of 8 or more characters is a paste,
  /// and a code in it goes through the router; typing never does (a half-typed `epic:…` would
  /// fill the form under the cursor).
  void _toChanged(String text) {
    if (text.length - _lastTo.length >= 8 && openPaymentText(text, origin: CodeOrigin.paste)) return;
    _changed(to: true);
  }

  /// A pasted or linked [text] through the scan router. A payment
  /// request fills To, Amount and Message; a link's address fills To. Pasted, a code Send cannot
  /// take stays in To with the reason under it (a transaction file opens its dialog); from a
  /// link every such code opens a dialog. Nothing is sent: Review send and the password stay the
  /// only way. False when a pasted [text] is no code (an address, a name, half an address): the
  /// caller lets To take it as typed. Desktop links come in here (or by [SendArgs.code]).
  bool openPaymentText(String text, {required CodeOrigin origin}) {
    final l = context.l10n;
    // A device link (Linked devices › Link a device) is no payment code: it opens that flow.
    if (isDeviceLinkText(text) && ref.read(deskLinkedDevicesOnProvider)) {
      setState(() => _to.text = _lastTo);
      unawaited(showDeskLinkDevice(context, pasted: text));
      return true;
    }
    final code = deskClassify(ref.read(deskApiProvider), text);
    final pasted = origin != CodeOrigin.link;
    // Pasted: To keeps the text, the reason under it, for reading and editing.
    void fieldError(String Function(AppLocalizations l) error) => setState(() {
      _to.text = text.trim();
      _lastTo = _to.text;
      _codeError = error;
      _code = null;
      _toEdited = false;
      _suggestOff = true;
    });
    void dialog(IconData icon, String title, String body, String shown) =>
        showCodeDialog(context, icon: icon, title: title, text: body, code: shown);
    switch (code) {
      case PaymentRequest():
        _fillFrom(code, origin);
      case ScannedAddress(:final recipient) when !pasted:
        _fillAddress(recipient.address, origin);
      case ScannedAddress():
        return false;
      case SlateText(text: final slate):
        setState(() => _to.text = _lastTo);
        // Open signs the pasted text as if its file had been chosen (LNX-3); an answer to one
        // of this wallet's sends is finalized instead (LNX-14).
        showSlateTextDialog(
          context,
          onOpen: () async {
            final nav = ref.read(deskNavProvider.notifier);
            if (await ref.read(deskApiProvider).isResponseText(slate)) {
              nav.go(DeskRoute.finalize, FinalizeArgs(text: slate));
            } else {
              nav.go(DeskRoute.importTx, ImportArgs(text: slate));
            }
          },
        );
      case SlateFrames() when pasted:
        fieldError((l) => l.deskSendToQrPayment);
      // Pairing off (Settings › Advanced): says it is experimental and where to turn it on.
      case PairingLink() when !ref.read(deskPairingOnProvider):
        showExperimentalOffDialog(context);
      case PairingLink() when pasted && !ref.read(deskPairsProvider):
        fieldError((l) => l.scanPairingUnavailable);
      case PairingLink(text: final link):
        openPairingLink(link);
      case WrongNetwork() when pasted:
        fieldError((l) => l.scanWrongNetworkBody);
      case WrongNetwork(:final recipient):
        dialog(Icons.public_off, l.scanWrongNetworkTitle, l.scanWrongNetworkBody, recipient.address);
      case UnknownCode(reason: UnknownReason.badAddress) when pasted:
        fieldError((l) => l.scanBadAddress);
      case UnknownCode(reason: UnknownReason.badAddress, text: final t):
        dialog(EIcons.qr, l.scanNotEpicTitle, l.scanBadAddress, t);
      // An `epic:` code refused as a whole (a part twice, too many parts, too long) says so
      // at once, not only at Review (LNX-2).
      case UnknownCode() when pasted && looksLikeCode(text):
        fieldError((l) => l.scanNotEpicBody);
      case UnknownCode() when pasted:
        return false;
      // A link never carries a QR Payment part: one is no Epic code there.
      case UnknownCode(text: final t) || SlateFrames(text: final t):
        dialog(EIcons.qr, l.scanNotEpicTitle, l.scanNotEpicBody, t);
    }
    return true;
  }

  /// A pairing link: Pair with Anna?, the words check or why not; a wallet that does not pair
  /// says so.
  void openPairingLink(String link) => ref.read(deskPairsProvider)
      ? deskOpenPairingText(context, ref, link).catchError((Object e) {
          if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
        })
      : showCodeDialog(context, icon: Icons.handshake_outlined, title: context.l10n.scanPairingTitle, text: context.l10n.scanPairingUnavailable, code: link);

  /// To, Amount and Message from [r]; the method follows the address. A field the code leaves
  /// out keeps what was typed, but a dropped amount empties Amount. The note goes into Message
  /// only when a slate can carry it; it shows in full in the payee block anyway.
  void _fillFrom(PaymentRequest r, CodeOrigin origin) {
    final l = context.l10n;
    final st = ref.read(deskProvider);
    final payments = st.settings.payments;
    final to = r.recipientFor(
      (m) => payments.offers(m) && switch (m) {
        MethodKind.linkTor => DeskFeatures.tor,
        _ => true,
      },
    ).address;
    final atomic = r.amount;
    final note = r.note;
    final noteFits = note != null && utf8Length(note) <= slateMessageMaxBytes;
    final code = SendCode.request(r, origin, address: to, noteFilled: noteFits);
    _fill(to, code, () {
      if (atomic != null) {
        _amount.text = localDecimal(l, shared.formatEpic(atomic));
      } else if (r.problems.contains(RequestProblem.amountInvalid) || r.problems.contains(RequestProblem.amountTooLarge)) {
        _amount.clear();
      }
      if (noteFits) _message.text = note;
    });
  }

  /// A link's bare address: To only, no banner; the review still says where it came from.
  void _fillAddress(String to, CodeOrigin origin) => _fill(to, SendCode(origin: origin, address: to), () {});

  void _fill(String to, SendCode code, VoidCallback fields) {
    final m = methodForKind(parseAddress(to, ref.read(deskApiProvider)).kind);
    setState(() {
      // A new code replaces the old one: what the old one put in and is still untouched goes,
      // so its amount and note never ride along to another payee.
      final old = _code;
      if (old != null) {
        if (old.amount != null && _parsed == old.amount) _amount.clear();
        if (old.noteFilled && _message.text == old.note) _message.clear();
      }
      _pairingTo = null;
      _to.text = to;
      _lastTo = to;
      fields();
      if (m != null && _offered(m)) {
        if (_segmentOf(m) != _segmentOf(_method)) _showSwitched(m);
        _method = m;
      }
      _code = code;
      _codeBanner = code.banner;
      _codeError = null;
      _all = false;
      _allError = null;
      _submitted = false;
      _toEdited = false;
      _amountEdited = false;
      _suggestOff = true;
      if (_result is SendDone) _result = null;
      _failure = null;
    });
    unawaited(_loadFee());
  }

  /// The code while To still holds its address.
  SendCode? get _codeNow => _code != null && _to.text.trim() == _code!.address ? _code : null;

  /// To moved off the code's address: the code goes, and with it the amount and the note it
  /// put in that are still untouched. True when Amount was cleared.
  bool _leaveCode() {
    final code = _code;
    if (code == null || _to.text.trim() == code.address) return false;
    final amount = code.amount != null && _parsed == code.amount;
    if (amount) _amount.clear();
    if (code.noteFilled && _message.text == code.note) _message.clear();
    _code = null;
    return amount;
  }

  void _use(Contact c) {
    // A contact with no address is paid through its pairing.
    if (_pairingOf(c) case final id?) {
      setState(() {
        _pairingTo = id;
        if (_method != TxMethod.file) _method = TxMethod.epicbox;
        _to.clear();
        _lastTo = '';
        _code = null;
        _codeError = null;
        _suggestOff = true;
        _failure = null;
        if (_result is SendDone) _result = null;
      });
      return;
    }
    setState(() {
      _pairingTo = null;
      // The address whose method is on, when the contact has one.
      final to = contactAddress(c, ref.read(deskProvider).settings.payments);
      final m = contactMethod(c, to);
      if (_segmentOf(m) != _segmentOf(_method)) _showSwitched(m);
      _method = m;
      _to.text = to;
      _lastTo = to;
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
      if (c.addresses.contains(v)) return c;
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
      if (mounted) showEToast(context, context.l10n.deskSendEpicboxOnFailed, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// "This is the wallet's own address." when the Epicbox recipient is this wallet: the
  /// part before @ the same, exactly (it is case-sensitive), and the server this wallet's or
  /// left out (":443" is the same server).
  String? _ownAddressError(DeskState st) {
    final own = st.epicboxAddress;
    if (_method != TxMethod.epicbox || own == null || own.isEmpty) return null;
    final (key, host) = _epicboxParts(_to.text);
    final (ownKey, ownHost) = _epicboxParts(own);
    return key == ownKey && (host == null || host == ownHost) ? context.l10n.deskSendErrOwn : null;
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

  String? _toError(DeskState st) {
    // A pairing recipient has no address: its card says whether it can be paid.
    if (_viaPairing) return ref.read(deskPairingByIdProvider(_pairingTo!))?.paysByMailbox ?? false ? null : context.l10n.deskSendErrNoAddress;
    return _ownAddressError(st) ?? _recipientError(context.l10n, _method, _to.text, ref.read(deskApiProvider));
  }

  /// LEPIC signs at most [slateMessageMaxBytes] UTF-8 bytes of a message and cuts the rest
  /// (linux-09): longer text is refused here instead of being cut without a word.
  bool get _messageTooLong => utf8Length(_message.text.trim()) > slateMessageMaxBytes;

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
    if (_toError(st) != null || _amountError(st.balance?.spendable) != null || _messageTooLong) return;
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
            _failure = (l) => deskErrorText(e, l);
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
    final st = ref.read(deskProvider);
    final contacts = st.contacts;
    final n = _amountNano;
    final code = _method == TxMethod.file ? null : _codeNow;
    // The relay in the address, when the app knows no such server: the public list, the
    // monitor's, and the one this wallet is on.
    final addressRelay = _method == TxMethod.epicbox ? recipientRelay(_to.text.trim()) : null;
    final own = st.status?.epicbox;
    final unknownRelay =
        addressRelay != null &&
            !isKnownRelay(
              addressRelay,
              extra: [
                for (final b in st.epicboxes ?? const <EpicboxServer>[]) EpicboxRelay(host: b.domain, port: b.port),
                if (own != null) EpicboxRelay(host: own.domain, port: own.port),
              ],
            )
        ? addressRelay
        : null;
    _Draft draftOf(SmartSendPlan? plan) {
      final balance = ref.read(deskProvider).balance;
      final viaPairing = _viaPairing;
      return _Draft(
        method: _method,
        to: _method == TxMethod.file || viaPairing ? null : _to.text.trim(),
        contactName: viaPairing ? ref.read(deskPairingNameProvider(_pairingTo!)) : _contactOf(contacts)?.name,
        pairingId: viaPairing ? _pairingTo : null,
        queued: _queues(),
        amount: n,
        fee: plan?.estimate.fee ?? _fee ?? 0,
        message: _message.text.trim(),
        sendAll: _all,
        dandelion: _dandelion,
        summary: plan == null || balance == null ? null : SendSummary.of(balance: balance.total, spendable: balance.spendable, estimate: plan.estimate),
        options: plan?.options,
        strategy: _strategy,
        defaultStrategy: _prefs.strategy,
        extraFee: plan == null ? 0 : plan.estimate.fee - plan.base.fee,
        unknownRelay: unknownRelay,
        code: code,
        confirmations: balance?.minConfirmations ?? defaultMinimumConfirmations,
      );
    }

    final draft = draftOf(_plan);
    // Plain HTTP to another computer goes through without asking; the wallet needs the flag.
    final plain = draft.method == TxMethod.http && plainHttpNeedsConsent(draft.to!);
    // Tor came on since Send was enabled: plain HTTP never goes through a Tor exit.
    if (plain && _torWay(ref.read(deskProvider)) == TorWay.off) {
      setState(() {
        _failure = (l) => l.sendPlainHttpOffWithTor;
        _failureInActivity = false;
      });
      return;
    }
    final notifier = ref.read(deskProvider.notifier);
    // Every send asks the wallet's password, also when it was opened with the remembered one.
    final api = ref.read(deskApiProvider);
    final res = await showEDialog<SendResult>(
      context,
      dismissible: false,
      builder: (_) => _ReviewDialog(
        draft: draft,
        startBusy: startBusy,
        checkPassword: api.checkPassword,
        // The core chooses the inputs again when it sends: an output that finished confirming
        // (or was locked) since this estimate changes them and the fee (linux-10). The review
        // estimates once more first and shows what the send will pay.
        recheck: (shown) async {
          final plan = await _planFor(n);
          if (plan.estimate.fee == shown.fee && plan.options == shown.options) return null;
          if (mounted) {
            setState(() {
              _plan = plan;
              _fee = plan.estimate.fee;
            });
          }
          return draftOf(plan);
        },
        onConfirm: (draft) => notifier.send(
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
            pairingId: draft.pairingId,
          ),
        ),
      ),
    );
    if (!mounted || res == null) return;
    setState(() {
      switch (res) {
        case final SendFailed failed:
          _failure = failed.text;
          _failureInActivity = failed.inActivity;
          _result = null;
        default:
          _failure = null;
          _result = res;
          if (res is SendDone) {
            _queuedFor = draft.queued ? draft.contactName : null;
            _to.clear();
            _amount.clear();
            _message.clear();
            _fee = null;
            _submitted = false;
            _code = null;
            _pairingTo = null;
          }
      }
    });
  }

  /// The last send was a mailbox payment queued while Epicbox is off: to whom, for its notice.
  String? _queuedFor;

  /// Clear in To, on the contact's card or the pairing's (Send keeps its draft, so a
  /// filled recipient always has a way out): the recipient goes with what followed from it,
  /// the method it moved, a code's untouched amount and note, the switch tag and the errors,
  /// back to the method Send starts on. Amount and Message typed by hand stay.
  void _clearRecipient() {
    _tagTimer?.cancel();
    setState(() {
      _to.clear();
      _pairingTo = null;
      _method = _nextMethod(ref.read(deskProvider).settings.payments);
      _switchedTo = null;
      _tagOn = false;
      _codeError = null;
      _submitted = false;
    });
    _changed(to: true);
  }

  void _reset() => setState(() {
    _result = null;
    _failure = null;
    _code = null;
    _pairingTo = null;
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
    // Balance has no value equality and every refresh makes a new one: only a changed
    // figure estimates again, or the summary would drop back to "—" on each refresh.
    ref.listen(deskProvider.select((s) => s.balance), (a, b) {
      if (a?.spendable == b?.spendable && a?.total == b?.total && a?.minConfirmations == b?.minConfirmations) return;
      _replan();
    });
    // A method switched off in Settings › Transactions while Send is open: with To empty and
    // nothing sent, Send moves to the method it starts on now, as after a restart. An address
    // in To keeps its method, with the note that it is off.
    ref.listen(deskProvider.select((s) => s.settings.payments), (_, p) {
      if (_result != null || _to.text.trim().isNotEmpty) return;
      final on = switch (_method) {
        // Link stays listed with its switches off: the notice says so and turns it on.
        TxMethod.http || TxMethod.tor => true,
        _ => p.offers(methodKindOf(_method)),
      };
      if (!on) setState(() => _method = _nextMethod(p));
    });
    // A half-filled form holds Back (mouse, Alt+Left).
    return LayoutBuilder(
      builder: (context, outer) {
        // Two columns need 720 u inside the page's padding; below that the summary falls under
        // the form, so Total and Review stay in a bar pinned to the bottom.
        final narrow = outer.maxWidth - 2 * Sp.x8 < 720.u;
        final form = res is! SendFileReady && res is! SendDone;
        return DeskStepBack(
      onBack: res is! SendFileReady && (_to.text.isNotEmpty || _amount.text.isNotEmpty || _message.text.isNotEmpty) ? () {} : null,
      child: EPage(
      title: context.l10n.deskSendTitle,
      footer: narrow && form ? _reviewBar(st) : null,
      titleTrailing: res is SendFileReady || _netBlock(st).byMode || !DeskFeatures.tor ? null : TorChip(_torWay(st)),
      width: EPageWidth.mid,
      child: res is SendFileReady
          ? _fileReady(res, nav)
          : res is SendDone
          ? _done(res, nav)
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 720.u;
                // Tab: the notices' actions, the form's fields, then Review send; Enter in Amount reviews.
                final notices = _notices(st);
                final form = FocusTraversalOrder(order: const NumericFocusOrder(1), child: FocusTraversalGroup(child: _form(st)));
                final summary = FocusTraversalOrder(order: const NumericFocusOrder(2), child: FocusTraversalGroup(child: _summary(st, res, review: !narrow)));
                return EForm(
                  onSubmit: _canSend(st) && !_reviewing ? _review : null,
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (notices.isNotEmpty)
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(0),
                            child: FocusTraversalGroup(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: notices),
                            ),
                          ),
                        // Form and Summary are one unit.
                        if (!wide) ...[form, SizedBox(height: Sp.col), summary] else PanelRow(main: form, side: summary, sideWidth: Ctl.sideSm),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
    );
      },
    );
  }

  /// The narrow page's pinned bar: the total and the Review button, always in view.
  Widget _reviewBar(DeskState st) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final s = _summary(st, _result);
    final n = _amountNano;
    final fee = _fee;
    // Never a Total without the fee: a spinner while it is estimated, "—" when that failed.
    final total = n > 0 && fee != null ? n + fee : 0;
    final pending = n > 0 && fee == null && _feeBusy;
    return Container(
      key: const ValueKey('send-review-bar'),
      padding: EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x3),
      decoration: BoxDecoration(color: c.s1, border: Border(top: BorderSide(color: c.line))),
      child: Row(
        children: [
          Text(l.deskSendTotal, style: ts.bodyDim),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: pending
                  ? const SummaryPending()
                  : total > 0
                  ? FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: EMoney(total, size: Fs.lg, weight: FontWeight.w600)) : Text('—', style: ts.mono(size: Fs.md, color: c.faint)), // l10n-ok: no amount yet
          ),
          ),
          SizedBox(width: Sp.x4),
          EButton.primary(label: s.reviewLabel, icon: EIcons.send, busy: s.reviewing, onPressed: s.onReview),
        ],
      ),
    );
  }

  /// Sent (or queued for a paired contact): the same result card as a file send's.
  Widget _done(SendDone r, DeskNav nav) {
    final l = context.l10n;
    final queued = _queuedFor != null;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Ctl.narrow),
      child: ResultPanel(
        key: queued ? const ValueKey('send-queued') : const ValueKey('send-done'),
        title: queued ? l.sendQueuedHeadline : l.deskSendSent,
        text: switch (r.tx.method) {
          _ when queued => l.sendQueuedBody(_queuedFor!),
          TxMethod.tor || TxMethod.http => l.deskSendDoneViaDirect,
          _ => l.deskSendDoneViaEpicbox,
        },
        body: EMoney(r.tx.amount, size: Fs.lg, color: context.dc.txSent),
        // The one result card (UD-007): gold = this screen's next action, outlined = Activity.
        actions: [
          EButton.primary(label: l.deskSendNewSend, icon: EIcons.send, onPressed: _reset),
          EButton(label: l.deskSendViewTx, onPressed: () => nav.go(DeskRoute.activity, r.tx.id)),
        ],
      ),
    );
  }

  Widget _fileReady(SendFileReady r, DeskNav nav) {
    final l = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Ctl.narrow),
      child: ResultPanel(
        title: l.deskSendFileReadyTitle,
        text: l.deskSendFileReadyText,
        body: FileChip(r.fileName),
        actions: [
          EButton.primary(label: l.deskSendFinalize, icon: EIcons.fileUp, onPressed: () => nav.go(DeskRoute.finalize)),
          EButton(label: l.deskSendViewTx, onPressed: () => nav.go(DeskRoute.activity, r.tx.id)),
          EButton(label: l.deskSendNewSend, onPressed: _reset),
        ],
      ),
    );
  }

  bool _turningOn = false;

  /// The method-off notice's Turn on: Link · HTTP starts its listener with the switch, as
  /// Settings › Transactions does; Link · Tor only shows the onion, so its switch alone.
  Future<void> _turnOn(MethodKind m) async {
    final n = ref.read(deskProvider.notifier);
    setState(() => _turningOn = true);
    try {
      if (m == MethodKind.linkHttp) {
        await n.setHttp(true);
      } else {
        final s = ref.read(deskProvider).settings;
        await n.saveSettings(s.copyWith(payments: s.payments.withMethod(m, true)));
      }
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskRecvTurnOnFailed(MethodIcons.fullName(context.l10n, m)), text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _turningOn = false);
    }
  }

  /// The mode's note for this send: Node only names the method that is off, Kill switch says
  /// nothing connects; both say what still works. Tor only waiting has its own line.
  String _blockTitle(AppLocalizations l, NetBlock net) => switch (net) {
    NetBlock.killSwitch => l.netBlockSendKillSwitch,
    NetBlock.nodeOnly => _method == TxMethod.epicbox ? l.deskSendEpicboxNodeOnly : l.deskSendLinkNodeOnly,
    _ => netBlockReason(l, net)!,
  };

  /// The one notice about what keeps a send from going out, most blocking first.
  Widget? _blockNotice(DeskState st) {
    final l = context.l10n;
    final net = _netBlock(st);
    if (net == NetBlock.epicboxOff) {
      // The Epicbox switch is off: the reason, and that a saved contact has only that address.
      final contact = _contactOf(st.contacts);
      return ENotice(
        key: const ValueKey('send-epicbox-off'),
        title: l.netBlockEpicboxOff,
        text: contact == null || contact.kinds.length > 1 ? null : l.sendContactOnlyEpicbox(contact.name),
        tone: ETone.warn,
        icon: EIcons.epicbox,
        actions: [EButton(label: l.deskRecvSettings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving))],
      );
    }
    if (net == NetBlock.methodOff) {
      // The method's switch is off: the reason, and that a saved contact has only that address.
      final contact = _contactOf(st.contacts);
      return ENotice(
        key: const ValueKey('send-method-off'),
        title: methodOffReason(l, _kind),
        text: contact == null || contact.kinds.length > 1 ? null : l.sendContactOnlyMethod(contact.name, MethodIcons.fullName(l, _kind)),
        tone: ETone.warn,
        icon: MethodIcons.of(_kind),
        actions: [
          // A Link method: one click turns it on here, as its switch would.
          if (_kind.family == MethodFamily.link)
            EButton(label: l.sendTurnOnMethod(MethodIcons.fullName(l, _kind)), icon: MethodIcons.of(_kind), size: EBtnSize.inline, busy: _turningOn, onPressed: _turningOn ? null : () => _turnOn(_kind)),
          EButton(label: l.deskRecvSettings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving)),
        ],
      );
    }
    if (net != NetBlock.none) {
      return ENotice(
        key: const ValueKey('send-net-blocked'),
        title: _blockTitle(l, net),
        text: net == NetBlock.waitingForTor ? l.deskNetSendFileHint : null,
        // A mode is the user's choice: calm, not a warning.
        tone: net.byMode ? ETone.neutral : ETone.warn,
        icon: net.byMode ? EIcons.lanOff : EIcons.tor,
        actions: [EButton(label: l.netChangeLink, size: EBtnSize.inline, onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network))],
      );
    }
    final node = _nodeBlock(st);
    if (st.status != null && node != null && _nodeDown(st) && _noNode) {
      return ENotice(
        key: const ValueKey('send-no-node'),
        title: l.deskSlNoNodeTitle,
        text: l.deskSlNoNodeText,
        tone: ETone.warn,
        icon: EIcons.server,
        actions: [EButton(label: l.deskOvNodeSettings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsNode))],
      );
    }
    if (st.status != null && node != null && _nodeDown(st)) {
      // Not answering (no network, the node off): "not synced" would say something else.
      return ENotice(
        key: const ValueKey('send-node-down'),
        title: l.deskErrNodeNotAnswering,
        text: l.deskOvCantReachNodeText,
        tone: ETone.warn,
        icon: EIcons.server,
      );
    }
    if (st.status != null && node != null) {
      // Syncing is progress, not a fault: the in-progress style and Overview's words (UD-003).
      return ENotice(
        key: const ValueKey('send-node-syncing'),
        title: node >= 0 ? l.deskOvSyncTitle((node * 100).round()) : l.deskSendNodeNotSynced,
        text: l.deskSendNodeSyncing,
        tone: ETone.info,
        icon: EIcons.info,
      );
    }
    if (_method == TxMethod.file && deskOfflineUsesNode(st)) {
      // As Receive and Finalize say it: the file reads and posts through the node in use.
      return ENotice(
        key: const ValueKey('file-offline-node'),
        title: l.advModeNodeOnly,
        text: l.netOfflineNodeHint,
        tone: ETone.info,
        icon: EIcons.info,
      );
    }
    final way = _torWay(st);
    if (way == TorWay.blocked) {
      return ENotice(
        key: const ValueKey('send-tor-blocked'),
        title: l.deskSendTorBlocked,
        text: l.deskSendTorBlockedText,
        tone: ETone.risk,
        icon: EIcons.tor,
        actions: [
          EButton(label: l.commonRetry, size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : () => _setTor(true)),
          // Tor off is never one click: its switch is in Settings › Privacy & network.
          EButton.ghost(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsPrivacy)),
        ],
      );
    }
    if (way == TorWay.wait) {
      return ENotice(
        key: const ValueKey('send-tor-wait'),
        title: l.deskSendTorStarting,
        text: l.deskSendTorStartingText,
        tone: ETone.info,
      );
    }
    final eb = _epicboxHealth(st);
    if (_method == TxMethod.epicbox && !_viaPairing && ref.read(hostSettingsProvider).epicboxServers.isEmpty) {
      return ENotice(
        key: const ValueKey('send-no-epicbox'),
        title: l.deskSlNoEpicboxTitle,
        text: l.deskSlNoEpicboxText,
        tone: ETone.warn,
        icon: EIcons.epicbox,
        actions: [EButton(label: l.deskRecvSettings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving))],
      );
    }
    if (_method == TxMethod.epicbox && eb == ServiceHealth.down) return const EpicboxDownNotice();
    if (_epicboxBlocked(st)) {
      return ENotice(
        title: l.deskSendEpicboxOff,
        text: l.deskSendEpicboxOffText,
        tone: ETone.warn,
        icon: EIcons.antenna,
        actions: [
          if (eb == ServiceHealth.off)
            EButton(label: l.deskSendEpicboxTurnOn, icon: EIcons.epicbox, size: EBtnSize.inline, busy: _starting, onPressed: _starting ? null : _startEpicbox),
        ],
      );
    }
    // Offline on a local node without peers: the payment waits in its pool.
    if (_method != TxMethod.epicbox && ref.watch(deskOfflinePeersProvider).value == 0) {
      return ENotice(key: const ValueKey('send-offline-no-peers'), title: l.deskNetOfflineNoPeers, icon: EIcons.server);
    }
    return null;
  }

  /// What happened and what blocks a send, above both columns (Send done, failed, node, Epicbox).
  List<Widget> _notices(DeskState st) {
    final block = _blockNotice(st);
    final l = context.l10n;
    return [
        if (_failure != null) ...[
          ENotice(
            title: l.deskSendFailedTitle,
            text: _failure!(l),
            tone: ETone.risk,
            icon: EIcons.error,
            actions: [
              // The payment may be waiting already: a second review could pay twice.
              if (_failureInActivity)
                EButton(label: l.deskFinViewActivity, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity))
              else
                EButton(label: l.deskSendReviewAgain, size: EBtnSize.inline, onPressed: _review),
            ],
          ),
          SizedBox(height: Sp.x5),
        ],
        if (block != null) ...[block, SizedBox(height: Sp.x5)],
    ];
  }

  /// The form's panel: the method selector in its header band (level with the Summary's), the
  /// method's strip, then the fields.
  Widget _form(DeskState st) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final spendable = st.balance?.spendable;
    final contact = _contactOf(st.contacts);
    final file = _method == TxMethod.file;
    final code = file ? null : _codeNow;
    final toErr = _codeError?.call(l) ?? ((_submitted && !_toEdited) || _onionNoTor ? _toError(st) : null);
    final amErr = _allError ?? (_submitted && !_amountEdited ? _amountError(spendable) : null);
    final matches = file ? const <Contact>[] : _matches(st);
    // Epicbox and Direct wait for the network mode; File runs in every mode, and in Offline
    // on a node that is not local its tooltip says the node is used.
    final net = deskNetBlock(st);
    final netIdle = net == NetBlock.none;
    final netWhy = netBlockReason(l, net);
    final fileTip = deskOfflineUsesNode(st) ? l.netOfflineNodeHint : null;
    final pairing = _pairingTo == null ? null : ref.watch(deskPairingByIdProvider(_pairingTo!));
    final pairingName = _pairingTo == null ? '' : ref.watch(deskPairingNameProvider(_pairingTo!));
    _keepMethodOn(st);
    // Nothing can be chosen (Node only with File Transfer off): no segment is selected and the
    // fields wait, the notice above says why.
    final noMethod = !_segmentOn(st, _method);
    final epicboxOn = _segmentOn(st, TxMethod.epicbox);
    final off = EBadge.state(l.deskKitMethodOff, on: false);
    return EPanel(
      padding: EdgeInsets.zero,
      title: l.deskSendMethodHeader,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.panel, Sp.panel, Sp.panel, Sp.x3),
          child: TourTarget(
          id: 'send-methods',
          child: ESegmented<TxMethod?>(
          stretch: true,
          segments: [
            // A pairing's mailbox takes a payment with Epicbox off too: it waits in the outbox.
            ESegment(TxMethod.epicbox, MethodIcons.shortName(l, MethodKind.epicbox), icon: MethodIcons.of(MethodKind.epicbox), enabled: epicboxOn, badge: epicboxOn ? null : off, tooltip: netWhy ?? (st.settings.payments.epicbox || pairing != null ? null : l.netBlockEpicboxOff)),
            // Link: http(s) or an onion, the address decides ([TxMethod.tor] is its route), so
            // the segment names the family. Settings › Transactions: the methods on. The
            // method in use stays (a pasted onion picks Link; a file send in progress or the
            // file fallback of a failed Epicbox keeps File Transfer).
            // Listed from the start, its switches on or not: sending by Link needs no
            // listener, and with both off the notice above turns one on.
            // A pairing recipient has no Link address.
            pairing != null
                ? ESegment(TxMethod.http, MethodIcons.familyName(l, MethodFamily.link), icon: MethodIcons.family(MethodFamily.link), enabled: false, tooltip: l.deskSendContactNoLink(pairingName))
                : ESegment(TxMethod.http, MethodIcons.familyName(l, MethodFamily.link), icon: MethodIcons.family(MethodFamily.link), enabled: netIdle, badge: netIdle ? null : off, tooltip: netWhy),
            // The file fallback of a failed Epicbox: only while its switch is on (an Epicbox
            // turned off on purpose is no failure, and File Transfer keeps its own switch).
            if (_fileShown(st))
              ESegment(TxMethod.file, MethodIcons.shortName(l, MethodKind.directFile), icon: MethodIcons.of(MethodKind.directFile), tooltip: fileTip),
          ],
          value: noMethod ? null : _segmentOf(_method),
          onChanged: (m) => setState(() {
            if (m == null) return;
            _method = m == TxMethod.http ? _directRoute(parseAddress(_to.text, ref.read(deskApiProvider)).kind) : m;
            _failure = null;
          }),
          ),
        ),
        ),
        if (!noMethod) Padding(padding: EdgeInsets.fromLTRB(Sp.panel, 0, Sp.panel, Sp.panel), child: _MethodStrip(_segmentOf(_method))),
        Divider(height: 1, thickness: 1, color: c.line),
        // No method can be chosen: the fields wait (dimmed, out of reach) until one can.
        ExcludeFocus(
          excluding: noMethod,
          child: IgnorePointer(
          ignoring: noMethod,
          child: Opacity(
          opacity: noMethod ? 0.4 : 1,
          child: Padding(
          padding: EdgeInsets.all(Sp.panel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        if (!file && pairing != null) ...[
          EField(
            label: l.deskSendTo,
            child: _PairingCard(
              pairing: pairing,
              name: pairingName,
              paused: ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff,
              onCheck: () => unawaited(showDeskCheckWords(context, ref, pairing.id, recheck: true)),
              onClear: _clearRecipient,
            ),
          ),
          SizedBox(height: Sp.x5),
        ] else if (!file) ...[
          EField(
            label: l.deskSendTo,
            labelTrailing: _SwitchTag(method: _switchedTo, shown: _tagOn),
            error: toErr,
            help: toErr == null ? l.deskSendToHelp : null,
            child: EInput(
              controller: _to,
              mono: true,
              fadeEnd: true,
              invalid: toErr != null,
              hint: l.deskSendToHint,
              semanticLabel: l.deskSendToSem,
              leading: EIcons.user,
              onChanged: _toChanged,
              // Enter picks the first matching contact, else goes on to Amount.
              onSubmitted: matches.isEmpty ? null : (_) => _use(matches.first),
              trailingTabStop: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A Tab stop when no contact card below has its own Clear.
                  if (_to.text.isNotEmpty)
                    EIconButton(key: const ValueKey('send-to-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, tabStop: contact == null, onPressed: _clearRecipient)
                  else
                    EIconButton(icon: EIcons.paste, label: l.commonPaste, size: EBtnSize.inline, tabStop: false, onPressed: _paste),
                  SizedBox(width: Sp.x1),
                  EButton(label: l.deskSendContacts, icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                ],
              ),
            ),
          ),
          if (matches.isNotEmpty) ...[
            SizedBox(height: Sp.x2),
            _Suggestions(contacts: matches, onPick: _use, addressOf: (x) => contactAddress(x, st.settings.payments), pairingOf: (x) => contactPairingOnly(ref, x)),
          ],
          // A payment request's banner: it keeps the last code's words while it closes.
          ExpandFade(
            open: code != null && code.banner && _codeBanner,
            child: _code == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(top: Sp.x3),
                    child: CodeBanner(code: _code!, onDismiss: () => setState(() => _codeBanner = false)),
                  ),
          ),
          // Offline: Tor never runs there; the notice above gives the Offline reason (LNX-12).
          // Link · Tor switched off: that comes first, Tor alone would not send it.
          if (DeskFeatures.tor && _torWay(st) == TorWay.needsTor && !_netBlock(st).byMode && _netBlock(st) != NetBlock.methodOff) ...[
            SizedBox(height: Sp.x3),
            ENotice(
              key: const ValueKey('send-needs-tor'),
              title: l.deskSendNeedsTor,
              text: st.status?.torIncluded ?? true ? l.deskSendNeedsTorText : l.deskSendNoTorBuild,
              tone: ETone.warn,
              icon: EIcons.tor,
              actions: [
                if (st.status?.torIncluded ?? true)
                  EButton(label: l.deskSendTurnOnTor, size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : () => _setTor(true)),
              ],
            ),
          ] else if (_method == TxMethod.http && _torState(st) != TorState.off && _torWay(st) == TorWay.clearnet) ...[
            SizedBox(height: Sp.x2),
            Text(l.deskSendHttpClearnet, key: const ValueKey('send-http-clearnet'), style: ts.small),
          ] else if (DeskFeatures.tor && _method == TxMethod.http && _torWay(st) == TorWay.off) ...[
            // Plain http:// to another computer with Tor on: the why is behind the info icon.
            SizedBox(height: Sp.x2),
            Wrap(
              key: const ValueKey('send-plain-http-off'),
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Sp.x2,
              runSpacing: Sp.x1,
              children: [
                Text(l.sendPlainHttpOffWithTor, style: ts.small.copyWith(color: c.warn)),
                EInfoHint(l.sendPlainHttpOffWithTorWhy, title: l.sendPlainHttpOffWithTor, icon: EIcons.alert, size: Ctl.inline),
                EButton.ghost(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsPrivacy)),
              ],
            ),
          ],
          if (contact != null) ...[
            SizedBox(height: Sp.x2),
            _PickedCard(
              contact: contact,
              address: _to.text.trim(),
              onClear: _clearRecipient,
            ),
          ],
          // The payee's words; the name not when the contact has it already.
          if (code != null && (code.note != null || EPayeeClaims.labelBeside(code.label, contact?.name) != null)) ...[
            SizedBox(height: Sp.x2),
            EPayeeClaims(label: EPayeeClaims.labelBeside(code.label, contact?.name), note: code.note),
          ],
          SizedBox(height: Sp.x5),
        ],
        EField(
          label: l.deskSendAmount,
          error: amErr,
          // What the code asked for: "requested by the code" while the field holds it.
          help: switch (code?.amount) {
            null => null,
            final asked when asked == _parsed => l.sendAmountFromCode,
            final asked => l.sendAmountCodeAsked('${formatEpicL(l, asked)} EPIC'),
          },
          aside: spendable == null
              ? Text(l.deskSendAvailableNone, style: ts.small)
              : Text(
                  l.deskSendAvailable(st.settings.hideAmounts ? '••••••' : formatEpicL(l, spendable)),
                  style: ts.small.copyWith(color: st.status?.syncProgress != null ? context.dc.faint : context.dc.dim),
                ),
          child: EInput(
            controller: _amount,
            mono: true,
            invalid: amErr != null,
            hint: '0',
            semanticLabel: l.deskSendAmountSem,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            onChanged: (_) => _changed(amount: true),
            trailingTabStop: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EPIC', style: ts.small.copyWith(color: c.dim)),
                SizedBox(width: Sp.x2),
                EButton(label: l.deskSendAllButton, size: EBtnSize.inline, busy: _allBusy, onPressed: spendable == null || _allBusy ? null : _sendAll),
              ],
            ),
          ),
        ),
        if ((st.balance?.awaitingConfirmation ?? 0) > 0) ...[
          SizedBox(height: Sp.x2),
          Text(st.settings.hideAmounts ? l.deskSendConfirmingHidden : l.deskSendConfirming(formatEpicL(l, st.balance!.awaitingConfirmation)), style: ts.small),
        ],
        SizedBox(height: Sp.x5),
        EField(
          label: l.deskSendMessage,
          optional: true,
          // Bytes, as LEPIC counts them: an emoji takes 4.
          aside: Text(l.deskSendMessageBytes(utf8Length(_message.text), slateMessageMaxBytes), style: ts.mono(size: Fs.xs, color: _messageTooLong ? c.risk : c.faint)),
          help: code != null && code.noteFilled && _message.text == code.note ? l.sendNoteFromCodeHelper : l.deskSendMessageHelp,
          error: _messageTooLong ? l.deskSendMessageTooLong(slateMessageMaxBytes) : null,
          child: EInput(
            controller: _message,
            maxLines: 3,
            semanticLabel: l.deskSendMessage,
            inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Advanced › Send options; open when a link brought the user here for it.
        if (advancedHas(ref, AdvancedFeature.sendOptions, keep: _args.advancedOpen)) ...[
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
          onOutputs: outputsShown(ref) ? () => ref.read(deskNavProvider.notifier).go(DeskRoute.outputs) : null,
        ),
        ],
        if (DeskFeatures.dandelion && !file) ...[
          SizedBox(height: Sp.x5),
          EDetails(
            title: _dandelion ? l.deskSendPrivacyOn : l.deskSendPrivacyOff,
            initiallyOpen: _args.privacyOpen,
            child: ESetRow(
              title: 'Dandelion++', // l10n-ok: protocol name
              text: l.deskSendDandelionText,
              control: ESwitch(value: _dandelion, semanticLabel: 'Dandelion++', onChanged: (v) => setState(() => _dandelion = v)), // l10n-ok: protocol name
            ),
          ),
        ],
            ],
          ),
        ),
        ),
        ),
        ),
      ],
      ),
    );
  }

  /// What the summary shows now: the amounts and the one line under Review send.
  _SendSummary _summary(DeskState st, SendResult? res, {bool review = true}) {
    final l = context.l10n;
    final spendable = st.balance?.spendable;
    final n = _amountNano;
    final fee = n > 0 ? _fee : null;
    final nodeBlocked = _nodeBlock(st) != null;
    final hint = switch (null) {
      _ when res is SendDone => _queuedFor == null ? l.deskSendHintSent : l.deskSendHintQueued,
      // The network mode first, as the banner: Offline does not poll a node that is not local,
      // so its "not synced" says nothing then (LNX-15).
      // Node only: the banner explains, this line names the block only (UD-014).
      _ when _netBlock(st) == NetBlock.nodeOnly => l.deskSendHintNeedsMethod(_method == TxMethod.epicbox ? l.methodEpicbox : MethodIcons.familyName(l, MethodFamily.link)),
      _ when _netBlock(st).byMode || _netBlock(st) == NetBlock.waitingForTor => _blockTitle(l, _netBlock(st)),
      _ when _onionNoTor => l.sendTorNotInVersion,
      _ when nodeBlocked && _nodeDown(st) && _noNode => l.deskSlNoNodeTitle,
      _ when nodeBlocked && _nodeDown(st) => l.deskNodeNotAnsweringLine,
      _ when nodeBlocked => l.deskSendHintNode,
      _ when _netBlock(st) == NetBlock.epicboxOff => l.deskSendHintNeedsMethod(l.methodEpicbox),
      _ when _netBlock(st) == NetBlock.methodOff => l.deskSendHintNeedsMethod(MethodIcons.fullName(l, _kind)),
      _ when _epicboxBlocked(st) => l.deskSendHintEpicbox,
      _ when _torWay(st) == TorWay.wait => l.deskSendHintTorWait,
      _ when _torWay(st) == TorWay.blocked => l.deskSendHintTorBlocked,
      _ when _torWay(st) == TorWay.needsTor => l.deskSendHintNeedsTor,
      _ when _method == TxMethod.http && _torWay(st) == TorWay.off => l.sendPlainHttpOffWithTor,
      _ when _submitted && !_toEdited && _toError(st) != null => l.deskSendHintFix,
      _ when _submitted && !_amountEdited && _amountError(spendable) != null => l.deskSendHintFix,
      _ when _messageTooLong => l.deskSendHintFix,
      _ when _reviewing => l.deskSendHintChecking,
      _ => l.deskSendHintDefault,
    };
    final plan = _plan?.estimate.amount == n && n > 0 ? _plan : null;
    final balance = st.balance;
    return _SendSummary(
      amount: n,
      fee: fee,
      feeLoading: n > 0 && _feeBusy && (fee == null || plan == null),
      spendable: spendable,
      summary: plan == null || balance == null ? null : SendSummary.of(balance: balance.total, spendable: balance.spendable, estimate: plan.estimate),
      extraFee: plan == null ? 0 : plan.estimate.fee - plan.base.fee,
      strategy: _strategy,
      defaultStrategy: _prefs.strategy,
      confirmations: balance?.minConfirmations ?? defaultMinimumConfirmations,
      updating: st.status?.syncProgress != null,
      hint: hint,
      reviewLabel: switch (_torWay(st)) {
        _ when _viaPairing && ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff => l.sendQueue,
        TorWay.wait => l.deskSendReviewWaitTor,
        TorWay.blocked => l.deskSendReviewTorOff,
        _ => l.deskSendReview,
      },
      reviewing: _reviewing,
      onReview: _canSend(st) && !_reviewing ? _review : null,
      review: review,
    );
  }
}

/// The Send page's summary panel: amount, fee, total, balance after, Review send and the
/// line under it. One widget so the summary rows can grow (outputs) without the form.
class _SendSummary extends StatelessWidget {
  const _SendSummary({
    required this.amount,
    required this.fee,
    required this.spendable,
    this.feeLoading = false,
    required this.updating,
    required this.hint,
    required this.reviewing,
    required this.onReview,
    required this.reviewLabel,
    this.summary,
    this.extraFee = 0,
    this.strategy = SelectionStrategy.smallest,
    this.defaultStrategy = SelectionStrategy.smallest,
    this.confirmations = defaultMinimumConfirmations,
    this.review = true,
  });

  /// The Review button sits in the panel; false when the narrow page pins it to the bottom.
  final bool review;

  /// What the send spends, locks and leaves; null until it is estimated.
  final SendSummary? summary;

  /// The wallet's minimum confirmations: blocks until the change confirms.
  final int confirmations;

  /// What splitting the change adds to the fee.
  final int extraFee;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  /// In nano EPIC; 0 when nothing valid is entered.
  final int amount;

  /// LEPIC's estimate; null until it arrives or when it failed.
  final int? fee;

  /// The estimate is on its way: spinners on Network fee, Total and the rows under it.
  final bool feeLoading;
  final int? spendable;

  /// The wallet scans: the balance after is not final.
  final bool updating;
  final String hint;
  final bool reviewing;
  final VoidCallback? onReview;

  /// "Review send", or what holds it ("Waiting for Tor").
  final String reviewLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final n = amount;
    final bad = n > 0 && spendable != null && n + (fee ?? 0) > spendable!;
    final ready = n > 0 && !bad;
    final pending = feeLoading && !bad;
    Widget line(String label, int? v, {bool strong = false, bool risk = false, bool dim = false, bool loading = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? ts.strong : ts.bodyDim)),
          if (loading)
            const SummaryPending()
          else if (v == null || v == 0)
            Text('—', style: ts.mono(size: Fs.md, color: c.faint))
          else
            EMoney(v, size: strong ? Fs.lg : Fs.md, color: risk ? c.risk : (dim ? c.dim : null), weight: strong ? FontWeight.w600 : null),
        ],
      ),
    );
    return EPanel(
      title: l.deskSendSummary,
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(l.deskSendAmount, n > 0 ? n : null, risk: bad),
          line(l.deskSendNetworkFee, fee, loading: pending && fee == null),
          ExpandFade(
            open: ready && (summary?.changeOutputs ?? 0) > 1,
            child: summary == null || summary!.changeOutputs < 2
                ? const SizedBox.shrink()
                : SendSplitLine(outputs: summary!.changeOutputs, extraFee: extraFee, change: summary!.change),
          ),
          Divider(height: Sp.x4, color: c.line),
          // Never Amount alone as Total: it waits for the fee, "—" when the estimate failed.
          line(l.deskSendTotal, ready && fee != null ? n + fee! : null, strong: true, loading: pending && fee == null),
          SendLockRows(summary: ready ? summary : null, strategy: strategy, defaultStrategy: defaultStrategy, blocks: confirmations, loading: pending),
          if (updating) Text(l.deskSendUpdating, style: ts.caption),
          SizedBox(height: Sp.x4),
          if (review) ...[
            EButton.primary(label: reviewLabel, icon: EIcons.send, expand: true, busy: reviewing, onPressed: onReview),
            SizedBox(height: Sp.x3),
          ],
          Semantics(liveRegion: true, child: Text(hint, style: ts.small, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Under the selector: the method's picture, what it does in bold and what it needs.
/// The art goes above the text in a narrow column; a method change crossfades.
class _MethodStrip extends StatelessWidget {
  const _MethodStrip(this.method);

  final TxMethod method;

  static (String, String) words(AppLocalizations l, TxMethod m) => switch (m) {
    TxMethod.epicbox => (l.deskSendEpicboxLine1, l.deskSendEpicboxLine2),
    TxMethod.http || TxMethod.tor => (l.deskSendDirectLine1, DeskFeatures.tor ? l.deskSendDirectLine2 : l.deskNoTorSendDirectLine2),
    TxMethod.file => (l.deskSendFileLine1, l.deskSendFileLine2),
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final (title, line) = words(context.l10n, method);
    // The first section of the form's panel: no frame of its own.
    return AnimatedSwitcher(
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
    );
  }
}

/// "Direct" next to To after the method followed the address: fades in, and out after 3 s,
/// over the same [Motion.cross] both ways; read out once.
class _SwitchTag extends StatelessWidget {
  const _SwitchTag({required this.method, required this.shown});

  final TxMethod? method;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final m = method;
    if (m == null) return const SizedBox.shrink();
    final l = context.l10n;
    final word = methodShortLabel(l, m);
    final said = switch (m) {
      TxMethod.tor || TxMethod.http => l.deskSendSwitchedDirect,
      TxMethod.file => l.deskSendSwitchedFile,
      TxMethod.epicbox => l.deskSendSwitchedEpicbox,
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: EdgeInsets.only(left: Sp.x2),
      child: Semantics(
        liveRegion: true,
        label: shown ? said : null,
        excludeSemantics: true,
        child: AnimatedOpacity(
          key: const ValueKey('send-switch-tag'),
          opacity: shown ? 1 : 0,
          duration: reduce ? Duration.zero : Motion.cross,
          curve: shown ? Motion.easeOut : Motion.easeIn,
          child: SizedBox(height: 22.u, child: EBadge(word, icon: _segmentOf(m) == TxMethod.http ? EIcons.link : methodIcon(_segmentOf(m)))),
        ),
      ),
    );
  }
}

/// The contact the To field holds: name and kind, the short address, Clear.
class _PickedCard extends StatelessWidget {
  const _PickedCard({required this.contact, required this.address, required this.onClear});

  final Contact contact;

  /// The contact's address in To, which a contact with several need not have first (LNX-9).
  final String address;
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
          Expanded(child: EAddressLines(name: contact.name, address: address)),
          SizedBox(width: Sp.x2),
          EButton.ghost(label: context.l10n.deskSendClear, size: EBtnSize.inline, onPressed: onClear),
        ],
      ),
    );
  }
}

/// The To slot for a paired contact with no address (DESIGN 1.3): name, trust badge, "Through
/// Anna's pairing", Clear; under it the mailbox the payment goes through, as a readout, or why
/// it cannot take one (keys changed, a wallet that does not open sealed messages).
class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.pairing, required this.name, required this.paused, required this.onCheck, required this.onClear});

  final PairingRecord pairing;
  final String name;

  /// Epicbox is off: the payment waits in the outbox.
  final bool paused;

  /// Check the words, when the contact's keys changed.
  final VoidCallback onCheck;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final ok = pairing.paysByMailbox;
    return Container(
      key: const ValueKey('send-picked-pairing'),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            child: Row(
              children: [
                EAvatar(name, size: 28.u),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Sp.x2,
                        runSpacing: Sp.x1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [Text(name, style: ts.strong), TrustBadge(pairing, short: true)],
                      ),
                      Text(l.sendRecipientPairing(name), style: ts.small),
                    ],
                  ),
                ),
                SizedBox(width: Sp.x2),
                EButton.ghost(label: l.deskSendClear, size: EBtnSize.inline, onPressed: onClear),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          Padding(
            key: const ValueKey('send-pairing-readout'),
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
            child: Row(
              children: [
                Icon(!ok ? EIcons.alert : (paused ? Icons.pause : EIcons.lock), size: 16.u, color: !ok || paused ? c.warn : c.dim),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: ok
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.sendViaMailbox(name), style: ts.body),
                            Text(paused ? l.contactPausedEpicboxOff : l.sendViaMailboxHint(pairing.homeRelay), style: ts.small),
                          ],
                        )
                      : Text(
                          pairing.state == PairingState.keysChanged ? l.contactSendKeysChanged : l.contactSendNoSealed(name),
                          style: ts.body,
                        ),
                ),
                if (pairing.state == PairingState.keysChanged) ...[
                  SizedBox(width: Sp.x2),
                  EButton.ghost(key: const ValueKey('send-pairing-check'), label: l.noticeCheckWords, size: EBtnSize.inline, onPressed: onCheck),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contacts matching what is typed in To: a short list right under the field.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.contacts, required this.onPick, required this.addressOf, required this.pairingOf});

  final List<Contact> contacts;
  final ValueChanged<Contact> onPick;

  /// The pairing a contact with no address is paid through ([contactPairingOnly]).
  final PairingRecord? Function(Contact) pairingOf;

  /// The address a pick fills in ([contactAddress]), shown on its row.
  final String Function(Contact) addressOf;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      label: context.l10n.deskSendMatching,
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
                label: '${x.name}, ${addressOf(x)}',
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
                        if (pairingOf(x) case final p?)
                          Flexible(child: PairingOnlyLine(name: x.name, pairing: p))
                        else ...[
                          EKindTag(addressKindOf(addressOf(x)), compact: true),
                          SizedBox(width: Sp.x3),
                          Flexible(child: EShortAddress(addressOf(x), tooltip: false)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Divider(height: 1, color: c.line),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
              child: Text(context.l10n.deskSendMatchCount(contacts.length), style: ts.caption),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.draft, required this.onConfirm, this.startBusy = false, this.checkPassword, this.recheck});

  final _Draft draft;
  final Future<SendResult> Function(_Draft draft) onConfirm;
  final bool startBusy;

  /// Estimates the send again right before it goes: the new review when the fee or the
  /// options moved, null when the shown one still holds.
  final Future<_Draft?> Function(_Draft shown)? recheck;

  /// Set when this send asks the wallet's password first; true when it is right.
  final Future<bool> Function(String password)? checkPassword;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late bool _busy = widget.startBusy;
  late _Draft _draft = widget.draft;
  final _password = TextEditingController();
  String? _wrong;

  /// The fee shown before the last check, when that check moved it.
  int? _feeWas;

  bool get _asks => widget.checkPassword != null && !widget.startBusy;

  /// Send is ready: no password asked, or one typed.
  bool get _ready => !_busy && (!_asks || _password.text.isNotEmpty);

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  // From the press on, a send is in progress: closing the app waits for it (close_guard.dart),
  // also while the password is checked.
  Future<void> _go() async {
    if (!_ready) return;
    final sending = ProviderScope.containerOf(context, listen: false).read(deskSendingProvider.notifier);
    await sending.during(_send);
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final recheck = widget.recheck;
    if (recheck != null) {
      final _Draft? fresh;
      try {
        fresh = await recheck(_draft);
      } on Object catch (e) {
        // Nothing left: the send cannot be built as reviewed any more.
        _close(SendFailed.l10n((l) => deskErrorText(e, l)));
        return;
      }
      if (!mounted) return;
      if (fresh != null) {
        setState(() {
          _feeWas = _draft.fee;
          _draft = fresh!;
          _busy = false;
        });
        return;
      }
    }
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
          _wrong = context.l10n.deskSendWrongPassword;
        });
        _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
        return;
      }
      _password.clear();
    }
    SendResult r;
    try {
      r = await widget.onConfirm(_draft);
    } on Object catch (e) {
      // The payment may have left before the error: never offer to send it again blind.
      logWarn('desk', 'send ended with ${e.runtimeType}');
      r = SendFailed.l10n((l) => l.deskSendNotConfirmed, inActivity: true);
    }
    _close(r);
  }

  /// Closes this dialog with [r], also when another one opened over it meanwhile (Close asked
  /// "A send is in progress" during the send): only this route goes.
  void _close(SendResult r) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final nav = Navigator.of(context);
    if (route == null || route.isCurrent) {
      nav.pop(r);
    } else {
      nav.removeRoute(route, r);
    }
  }

  /// A Direct address's host and port (`203.0.113.4:<port>`, `<56 characters>.onion`).
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
    final d = _draft;
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final via = switch (d.method) {
      TxMethod.epicbox => l.deskSendViaEpicbox,
      TxMethod.http => l.deskSendViaDirect,
      TxMethod.tor => l.deskSendViaTor,
      TxMethod.file => l.deskSendViaFile,
    };
    final code = d.code;
    // The payee's words under the facts; the name not when the contact has it.
    final codeLabel = EPayeeClaims.labelBeside(code?.label, d.contactName);
    // A Direct payment from a code: the host on its own line, where a look-alike shows (§7.3).
    final directHost = code != null && d.to != null && (d.method == TxMethod.http || d.method == TxMethod.tor) ? directHostBesideOf(d.to!) : null;
    final sum = d.summary;
    final lines = sum == null ? null : reviewOutputLines(l, sum, strategy: d.strategy, defaultStrategy: d.defaultStrategy, blocks: d.confirmations, extraFee: d.extraFee, usesAll: l.deskSendUsesAll);
    return EDialog(
      title: l.deskSendReviewTitle,
      description: l.deskSendReviewDesc,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (code != null) ...[
            Row(children: [EBadge(originText(l, code.origin), key: const ValueKey('send-review-origin'), icon: codeOriginIcon(code.origin))]),
            SizedBox(height: Sp.x3),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: Text(formatEpicL(l, d.amount, decimals: exactDecimals), style: ts.h1.copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
              SizedBox(width: Sp.x2),
              Text('EPIC', style: ts.lead),
            ],
          ),
          SizedBox(height: Sp.x4),
          EFacts([
            // Through the pairing: the name, never an address (the mailbox is not one).
            if (d.pairingId != null)
              (
                l.deskSendFactTo,
                Column(
                  key: const ValueKey('send-review-pairing'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.contactName ?? '', style: ts.strong),
                    Text(l.sendRecipientPairing(d.contactName ?? ''), style: ts.small),
                  ],
                ),
              ),
            if (d.to != null)
              (
                l.deskSendFactTo,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.contactName != null) Text(d.contactName!, style: ts.strong),
                    if (directHost != null) SelectableText(directHost, key: const ValueKey('send-review-host'), style: ts.mono(size: Fs.lg, color: c.text)),
                    _address(context, d.to!),
                    SizedBox(height: Sp.x1),
                    Text(l.deskSendCheckChars, style: ts.caption),
                  ],
                ),
              ),
            (
              l.deskSendFactVia,
              Text(via, style: ts.body),
            ),
            (
              l.deskSendNetworkFee,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EMoney(d.fee, decimals: exactDecimals),
                  if (lines?.feeSecondLine != null) Text(lines!.feeSecondLine!, style: ts.small),
                ],
              ),
            ),
            (l.deskSendTotal, EMoney(d.total, decimals: exactDecimals, weight: FontWeight.w600)),
            ...?lines?.facts,
            if (DeskFeatures.dandelion && d.method != TxMethod.file) (l.deskSendFactPrivacy, Text(d.dandelion ? l.deskSendDandelionOn : l.deskSendDandelionOff, style: ts.body)),
            if (d.message.isNotEmpty) (l.deskSendFactMessage, Text(d.message, style: ts.body)),
          ], labelWidth: 100.u),
          if (code != null && (code.note != null || codeLabel != null)) ...[
            SizedBox(height: Sp.x4),
            EPayeeClaims(label: codeLabel, note: code.note),
          ],
          if (d.queued && !_busy) ...[
            SizedBox(height: Sp.x4),
            ENotice(key: const ValueKey('send-review-queued'), tone: ETone.info, title: l.sendQueuedEpicboxOff),
          ],
          if (d.unknownRelay case final unknown? when !_busy) ...[
            SizedBox(height: Sp.x4),
            ENotice(
              tone: ETone.warn,
              title: l.deskSendRelayUnknownTitle,
              text: l.deskSendRelayUnknownText(unknown.label),
            ),
          ],
          if (_feeWas != null && !_busy) ...[
            SizedBox(height: Sp.x4),
            ENotice(
              tone: ETone.warn,
              title: l.deskSendFeeChangedTitle,
              text: l.deskSendFeeChangedText(formatEpicL(l, d.fee), formatEpicL(l, _feeWas!)),
            ),
          ],
          if (_asks && !_busy) ...[
            SizedBox(height: Sp.x4),
            // Enter in the password sends once it is filled.
            EForm(
              onSubmit: _ready ? _go : null,
              child: EField(
                label: l.deskSendPassword,
                help: l.deskSendPasswordHelp,
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
          // The Send button turns while it runs; the line beside it stays still (one spinner).
          if (_busy) ...[
            SizedBox(height: Sp.x4),
            Row(
              children: [
                Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Text(
                    switch (d.method) {
                      TxMethod.file => l.deskSendBusyFile,
                      TxMethod.tor => l.deskSendBusyTor,
                      _ => l.deskSendBusy,
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
        EButton(label: l.deskSendBack, kind: EBtnKind.ghost, size: EBtnSize.sm, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: _busy ? l.deskSendSending : (d.queued ? l.sendQueue : l.deskSendConfirm(formatEpicL(l, d.amount))), icon: EIcons.send, busy: _busy, onPressed: _ready ? _go : null),
      ],
    );
  }
}

