// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../address_field.dart';
import '../../../amount.dart' as shared show formatEpic;
import '../../../amount.dart' show exactDecimals;
import '../../../l10n.dart' show LocalizedFormatException, localDecimal;
import '../../../providers.dart' show defaultMinimumConfirmations;
import '../../../known_relays.dart';
import '../../../log.dart';
import '../../../network.dart' show EpicboxRelay;
import '../../../devices/device_link_code.dart' show isDeviceLinkText;
import '../../../trust_ids.dart';
import '../../data/devices_state.dart' show deskHeldProvider, deskLinkedDevicesOnProvider;
import '../devices/link_flow.dart' show showDeskLinkDevice;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider, deskLevelUiProvider;
import '../../data/net_mode_view.dart';
import '../../data/tor_view.dart';
import '../../../models.dart' show PairingRecord, PairingState, slateMessageMaxBytes;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../../settings_file/host_settings.dart' show appConfig;
import '../../../advanced.dart' show NetworkMode;
import '../../../ui/network_mode_text.dart' show switchPausesSends;
import '../../../send_reach.dart';
import '../../../send_route.dart';
import '../../../ui/send_route_text.dart';
import '../../../network_gate.dart' show NetBlock, NetBlockByMode, NetGate;
import '../../../send_amount_gate.dart';
import '../../../smart_outputs.dart';
import '../../../utf8_limit.dart';
import '../../app/shell.dart' show outputsShown;
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../data/pairing_state.dart' show DeskPairNet, deskContactPairingProvider, deskPairNetProvider, deskPairingByIdProvider, deskPairingNameProvider, deskPairsProvider;
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart' show DeskPaymentSteps;
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
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature, confirmNetworkModeSwitch;
import '../../data/method_names.dart' show methodKindOf;
import '../../../directory/directory.dart' show DirectoryTrust, LinkOpened, LinkOutcome, LinkRefused, directoryMembershipProvider, paymentRefusalsProvider;
import '../../../l10n.dart' show localDay;
import '../../../scan/incoming_link.dart' show linkClockProvider;
import '../../../scan/scan_router.dart';
import '../../../ui/link_send.dart' show amountEdited, linkRefusalText;
import '../wallet/contacts_screen.dart' show ContactsArgs;
import 'link_trust.dart';
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

  /// [TxMethod.file] opens the file form (Pay with a file); any other method is ignored: the
  /// address in To decides how it goes.
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
    this.route,
    this.torStarts = false,
  });

  final TxMethod method;

  /// [to] as Send read it: the method's name, the host as contacted, plain http.
  final RecipientInput? route;

  /// An onion while the Tor switch is off: the review says Tor starts when it sends.
  final bool torStarts;

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

/// The method an address in To goes by; null when To holds no address.
TxMethod? _methodOf(RecipientInput r) => switch (r.kind) {
  RecipientInputKind.epicbox => TxMethod.epicbox,
  RecipientInputKind.onion => TxMethod.tor,
  RecipientInputKind.https || RecipientInputKind.http => TxMethod.http,
  _ => null,
};


/// The Send form as it was left, for the wallet it was filled in: people leave Send to check
/// the balance and come back to it (the owner). Clear in To empties the recipient; a payment
/// made or New send forgets it.
class _KeptSend {
  const _KeptSend({
    required this.wallet,
    required this.to,
    required this.amount,
    required this.message,
    required this.file,
    required this.pairingTo,
    required this.code,
    required this.codeBanner,
    required this.contactId,
  });

  final String? wallet;
  final String? contactId;
  final String to;
  final String amount;
  final String message;
  final bool file;
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
  final _to = AddressFieldController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  late final SendArgs _args;
  // The file form (Pay with a file); otherwise the address in To decides the method.
  bool _file = false;
  bool _submitted = false;
  // To's error shows once the field is left, Enter pressed, an address pasted or Review
  // pressed; typing hides it again.
  bool _toTouched = false;
  // An amount's error goes away as soon as the field is edited, until the next review.
  bool _amountEdited = false;
  final _toFocus = FocusNode();
  // The contact picked, shown as a chip in To; [_to] holds the address used.
  String? _contactId;
  bool _holdBusy = false;
  // The reach check, per clean address: asked once, again only on Try again.
  final Map<String, ReachResult> _reach = {};
  final Set<String> _reachAsked = {};
  // "Checking…" shows only for a slow answer.
  bool _reachSlow = false;
  Timer? _reachTimer;
  String? _readFor;
  RecipientInput _readNow = RecipientInput.empty;
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
  // The To text before this change: one change of 8 or more characters is a paste.
  String _lastTo = '';
  SendResult? _result;
  // The failed payment's message, worded when shown.
  String Function(AppLocalizations l)? _failure;

  /// Wallet levels: Shallow sends from the page itself (no Review step) and by Epicbox alone,
  /// unnamed (no method strip); Deeper and Deep end keep the method strip and Review.
  bool get _reviewStep => ref.read(deskLevelUiProvider).sendReviewStep;
  bool get _strip => ref.read(deskLevelFeaturesProvider).methodStrip;

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

  /// [_pairingTo] goes by its mailbox now (the file form ignores it).
  bool get _viaPairing => _pairingTo != null && !_file;

  /// What To holds, read once per text ([readRecipient]).
  RecipientInput get _read {
    final t = _to.text;
    if (t != _readFor) {
      _readFor = t;
      _readNow = readRecipient(t, defaultRelay: ref.read(hostSettingsProvider).epicboxUse, listenPort: appConfig.httpListenPort);
    }
    return _readNow;
  }

  /// The method this send goes by: File for the file form, Epicbox for a pairing, else the
  /// address's. Shallow sends by Epicbox alone. Epicbox while To holds no address.
  TxMethod get _method {
    if (_file) return TxMethod.file;
    if (_viaPairing || !_strip) return TxMethod.epicbox;
    return _methodOf(_read) ?? TxMethod.epicbox;
  }

  /// A method follows from what is in To (or the file form, or a pairing).
  bool get _hasMethod => _file || _viaPairing || _methodOf(_read) != null;

  /// The contact picked, when it is still in the list.
  Contact? _picked(DeskState st) => _contactId == null ? null : st.contacts?.where((c) => c.id == _contactId).firstOrNull;

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
    final st0 = ref.read(deskProvider);
    _file = args.method == TxMethod.file;
    _pairingTo = args.pairingTo ?? (contact == null ? null : _pairingOf(contact));
    if (contact != null && _pairingTo == null) {
      _contactId = contact.id;
      _to.text = _bestAddress(contact, st0);
    } else {
      _to.text = args.recipient ?? '';
      // A recipient handed in (a link, the tour) is read as a paste.
      if (_to.text.isNotEmpty && !args.suggest) _settleTo(st0);
    }
    _lastTo = _to.text;
    _toFocus.addListener(_onToFocus);
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
        _toTouched = true;
      case SendStep.review || SendStep.sending:
        WidgetsBinding.instance.addPostFrameCallback((_) => _openReview(startBusy: args.step == SendStep.sending));
      // The shot result reads the amount, which needs the language: built in
      // didChangeDependencies, before the first frame.
      case SendStep.done:
        _shotStep = SendStep.done;
      case SendStep.fileReady:
        _file = true;
        _shotStep = SendStep.fileReady;
      case SendStep.failed:
        _failure = (l) => l.deskSendNoAnswer;
        _submitted = true;
      case SendStep.form:
        break;
    }
  }

  /// A shot step whose result is still to be built ([didChangeDependencies]).
  SendStep? _shotStep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final step = _shotStep;
    if (step == null) return;
    _shotStep = null;
    _result = step == SendStep.done
        ? SendDone(_shotTx(TxMethod.epicbox, _args.recipient))
        : SendFileReady(_shotTx(TxMethod.file, null), 'f0e1d2c3.tx');
  }

  Tx _shotTx(TxMethod m, String? to) => Tx(
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
    _file = kept.file;
    _contactId = kept.contactId;
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
      file: _file,
      pairingTo: _pairingTo,
      code: _code,
      codeBanner: _codeBanner,
      contactId: _contactId,
    );
  }

  @override
  void dispose() {
    _keeper.kept = _toKeep;
    _reachTimer?.cancel();
    _toFocus.removeListener(_onToFocus);
    _toFocus.dispose();
    _to.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  int? get _parsed => _parseAmount(context.l10n, _amount.text);
  int get _amountNano => (_parsed ?? 0) > 0 ? _parsed! : 0;

  /// The amount against the spendable balance and the estimate made for it
  /// ([SendAmountGate]): Review send is off while it [SendAmountGate.holds], and the review
  /// opens only when it is ready. The estimate starts on the keystroke ([_loadFee]); one that
  /// failed leaves Review on, whose tap estimates again and says why.
  SendAmountGate _gate(DeskState st) {
    final n = _amountNano;
    final plan = _plan?.estimate.amount == n ? _plan : null;
    return SendAmountGate.check(
      amount: n > 0 ? n : null,
      spendable: st.balance?.spendable,
      estimate: plan == null ? null : (amount: plan.estimate.amount, fee: plan.estimate.fee),
      estimateFailed: n > 0 && plan == null && !_feeBusy,
    );
  }

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
    if (!_byEpicbox || _viaPairing) return false;
    final h = _epicboxHealth(st);
    return h == ServiceHealth.off || h == ServiceHealth.checking;
  }

  TorState _torState(DeskState st) => _args.tor ?? deskNetTor(st);

  /// An address in To that goes by Epicbox, or a pairing's mailbox.
  bool get _byEpicbox => _hasMethod && _method == TxMethod.epicbox;

  /// The Tor switch is on (or the tour says so).
  bool _torOn(DeskState st) => _torState(st) != TorState.off;

  /// What the network mode holds the address in To with ([sendHoldFor]); null when it may go,
  /// for the file form and a pairing (their own notices say what holds them).
  SendHold? _hold(DeskState st) => _file || _viaPairing || !_strip ? null : sendHoldFor(_read, mode: deskNetMode(st), torOn: _torOn(st));

  /// The switch (Settings › Transactions) the address in To needs; null for none yet.
  MethodKind? get _needs => !_strip ? (_read.kind == RecipientInputKind.epicbox ? MethodKind.epicbox : null) : sendMethodKind(_read);

  /// What else holds this send: the mode with no address in To yet (an address's hold is
  /// [_hold]), Tor only waiting for tor, and the method's switch (Settings › Transactions:
  /// [NetBlock.methodOff], [NetBlock.epicboxOff]). A file is never held: Node only lets it use
  /// the node in use ([deskOfflineUsesNode] says so on the screen), Kill switch makes it
  /// without a node.
  NetBlock _netBlock(DeskState st) {
    if (_file) return NetBlock.none;
    // A pairing's mailbox payment waits in the outbox while Epicbox is off ("Queue payment");
    // the mode and Tor still hold it.
    if (_viaPairing) return deskNetBlock(st);
    final kind = _needs;
    return deskNetBlock(
      st,
      epicbox: kind == MethodKind.epicbox,
      // An onion in the build without Tor: no method would send it, its own line says so. An
      // http(s) address is never held by a switch: Link · HTTP's switch is the listener's.
      offered: _onionNoTor || kind == null || kind == MethodKind.linkHttp || st.settings.payments.offers(kind),
    );
  }

  /// An onion in To in the build without Tor: said at once under To, nothing offered for it.
  bool get _onionNoTor => !DeskFeatures.tor && !_file && _read.kind == RecipientInputKind.onion;

  /// The method this send goes by, for its name and its switch.
  MethodKind get _kind => _needs ?? methodKindOf(_method);

  /// How this send's connection goes with the Tor switch as it is now; null for File, for no
  /// address yet and for plain http (never over Tor: direct to this computer and the local
  /// network, else held by [_hold]).
  TorWay? _torWay(DeskState st) {
    if (!_hasMethod) return null;
    final route = switch (_method) {
      TxMethod.epicbox => TorRoute.epicbox,
      TxMethod.tor => TorRoute.onionDirect,
      TxMethod.http => _read.kind == RecipientInputKind.http ? null : TorRoute.httpDirect,
      TxMethod.file => null,
    };
    // An onion goes through the wallet's tor whoever started it: Link · Tor runs one for
    // payments alone (item 2).
    if (route == TorRoute.onionDirect) return torWay(TorRoute.onionDirect, _args.tor ?? deskTorProcess(st));
    return route == null ? null : torWay(route, _torState(st));
  }

  /// An onion while the Tor switch is off: the wallet's own Tor for payments carries it, which
  /// the method line and the review say ("Tor starts when you send.").
  bool _torStarts(DeskState st) =>
      _hasMethod && _method == TxMethod.tor && !_torOn(st) && deskNetMode(st) == NetworkMode.standard && st.settings.payments.linkTor && switch (_torWay(st)) {
        TorWay.overTor || TorWay.wait => true,
        _ => false,
      };

  /// Tor holds this send: starting, not connected, or off for an onion. Nothing falls back.
  bool _torHeld(DeskState st) {
    final way = _torWay(st);
    return way != null && !torGoes(way);
  }

  bool _canSend(DeskState st) => _netBlock(st) == NetBlock.none && _hold(st) == null && _nodeBlock(st) == null && !_epicboxBlocked(st) && !_torHeld(st) && _result is! SendDone;

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

  /// [t] read as a recipient, with this wallet's default relay and listener port.
  RecipientInput _readOf(String t) => readRecipient(t, defaultRelay: ref.read(hostSettingsProvider).epicboxUse, listenPort: appConfig.httpListenPort);

  /// What the mode holds an address [r] with now.
  SendHold? _heldOf(RecipientInput r, DeskState st) => sendHoldFor(r, mode: deskNetMode(st), torOn: _torOn(st));

  /// [r] can be sent to by this build, at this level, with its method switched on (http(s)
  /// needs no switch).
  bool _sendable(RecipientInput r, DeskState st) {
    final k = sendMethodKind(r);
    if (k == null || (k == MethodKind.linkTor && !DeskFeatures.tor) || (!_strip && k != MethodKind.epicbox)) return false;
    // Link · HTTP's switch turns the listener on and off, never a send.
    return k == MethodKind.linkHttp || st.settings.payments.offers(k);
  }

  /// The address of [c] Send uses first: Epicbox, https, Tor, plain http, skipping any the mode
  /// holds or whose method is off ([bestAddressIndex]).
  String _bestAddress(Contact c, DeskState st) {
    final list = c.addresses;
    final i = bestAddressIndex(list, read: _readOf, held: (r) => _heldOf(r, st) != null || !_sendable(r, st));
    return i < 0 ? c.address : list[i];
  }

  /// To left (focus lost, Enter, Review) or pasted into: the text stays as given (the method
  /// line shows the address as it will be contacted); a contact's address becomes its chip; a
  /// Link address is asked once whether a wallet answers. The caller sets the state.
  void _settleTo(DeskState st) {
    if (_to.text.trim().isEmpty) return;
    _toTouched = true;
    if (_contactId == null && _pairingTo == null) _contactId = _contactOf(st.contacts)?.id;
    _askReach(st);
  }

  void _onToFocus() {
    if (_toFocus.hasFocus || !mounted || _file) return;
    setState(() => _settleTo(ref.read(deskProvider)));
  }

  /// To takes the focus once it is built again (after a chip or the file form).
  void _focusTo() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _toFocus.context != null) _toFocus.requestFocus();
  });

  /// Asks the Link address in To once, in the background, whether a wallet answers there
  /// ([checkWalletAnswers]); "Checking…" shows only after 1.5 s without an answer.
  void _askReach(DeskState st) {
    final r = _read;
    final mode = deskNetMode(st);
    if (!_strip || _file || !reachCheckApplies(r, mode: mode) || _heldOf(r, st) != null) return;
    final key = r.address;
    if (!_reachAsked.add(key)) return;
    _reachSlow = false;
    _reachTimer?.cancel();
    _reachTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_reach.containsKey(key)) setState(() => _reachSlow = true);
    });
    unawaited(checkWalletAnswers(r, mode: mode).then((res) {
      if (mounted) setState(() => _reach[key] = res);
    }));
  }

  /// Try again: the address in To is asked once more.
  void _retryReach() {
    final key = _read.address;
    setState(() {
      _reach.remove(key);
      _reachAsked.remove(key);
      _askReach(ref.read(deskProvider));
    });
  }

  /// The reach check's answer for To now; null while there is none.
  ReachResult? get _reachNow => _reach[_read.address];

  /// The hold's one action: the network mode back to Normal, or the Tor switch off.
  Future<void> _fixHold(SendHold h) async {
    final l = context.l10n;
    if (h.fix == SendHoldFix.torOff) {
      await _setTor(false);
      if (mounted && !_torOn(ref.read(deskProvider))) showEToast(context, l.sendHeldTorIsOff, tone: ETone.ok);
      return;
    }
    final st = ref.read(deskProvider);
    final s = st.settings;
    final adv = s.advanced;
    if (adv.networkMode == NetworkMode.standard) return;
    // As Settings › Privacy chooses a mode: a switch that pauses waiting sends asks first
    // (Normal never does, so this only guards a future mode list).
    final waiting = switchPausesSends(NetworkMode.standard) && !switchPausesSends(adv.networkMode) ? deskPendingNetworkSends(st) : 0;
    if (waiting > 0) {
      final ok = await confirmNetworkModeSwitch(context, mode: NetworkMode.standard, waiting: waiting);
      if (ok != true || !mounted) return;
    }
    setState(() => _holdBusy = true);
    try {
      await ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: adv.withMode(NetworkMode.standard)));
      if (mounted) showEToast(context, l.sendHeldModeNormal, tone: ETone.ok);
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _holdBusy = false);
    }
  }

  /// Pay with a file: the file form, the recipient kept for the way back.
  void _openFile() => setState(() {
    _file = true;
    _failure = null;
    _submitted = false;
  });

  /// Back from the file form to sending to an address.
  void _leaveFile() {
    setState(() {
      _file = false;
      _failure = null;
      _submitted = false;
    });
    if (_pairingTo == null && _contactId == null) _focusTo();
  }

  bool _torBusy = false;

  /// Turns the Tor switch on (Turn on Tor, Retry) or off (Turn Tor off, beside a plain http://
  /// recipient only, its caption saying it applies to every connection: D-05).
  Future<void> _setTor(bool on) async {
    setState(() => _torBusy = true);
    final n = ref.read(deskProvider.notifier);
    try {
      // A send to an onion needs Tor for payments (Link · Tor), not every connection over
      // Tor: that is Connection mode › Tor only alone. Tor only keeps its own Tor.
      if (on && !NetGate.torOnly) {
        ref.read(deskProvider).settings.payments.linkTor ? await n.retryTorPay() : await n.setLinkTor(true);
      } else {
        await n.setTor(on);
      }
    } on Object catch (e) {
      if (mounted) showEToast(context, on ? context.l10n.deskSendTorOnFailed : context.l10n.deskSendTorOffFailed, text: deskErrorText(e, context.l10n), tone: ETone.risk);
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
        _lastTo = _to.text;
        // Typing: no error until the field is left.
        _toTouched = false;
        _suggestOff = false;
        _codeError = null;
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
    _pasted(t);
  }

  /// [t] pasted into To (the Paste button, Ctrl+V): read at once, as given.
  void _pasted(String t) {
    _to.text = t;
    _changed(to: true);
    setState(() => _settleTo(ref.read(deskProvider)));
  }

  /// To changed by typing or a paste into it: one change of 8 or more characters is a paste,
  /// and a code in it goes through the router; typing never does (a half-typed `epic:…` would
  /// fill the form under the cursor).
  void _toChanged(String text) {
    if (text.length - _lastTo.length >= 8) {
      if (openPaymentText(text, origin: CodeOrigin.paste)) return;
      return _pasted(text);
    }
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
      _toTouched = false;
      _contactId = null;
      _suggestOff = true;
    });
    void dialog(IconData icon, String title, String body, String shown) =>
        showCodeDialog(context, icon: icon, title: title, text: body, code: shown);
    switch (code) {
      // A recovery phrase never stays in To, nor shows anywhere: To empties, the note says why.
      case RecoveryPhraseCode():
        setState(() {
          _to.text = '';
          _lastTo = '';
          _codeError = (l) => l.scanPhraseFoundPasted;
          _code = null;
          _toTouched = false;
            _contactId = null;
          _suggestOff = true;
        });
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
        showSlateTextDialog(context, onOpen: () => _openSlate(slate));
      case SlateFrames() when pasted:
        fieldError((l) => l.deskSendToQrPayment);
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
      // A payment link is checked first (it takes a signature check): the refusal, the
      // question "paid before", or the form filled; a newer paste drops this answer.
      case PaymentLink():
        setState(() => _to.text = _lastTo);
        unawaited(_openLink(code, origin));
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

  /// The link a paste or a scan opened last; an answer for an older one is dropped.
  int _linkSeq = 0;

  /// The payment link the form was filled from, and the code it filled (the link is current only
  /// while that code is: another code or To moving off it takes the link with it).
  LinkOpened? _link;
  SendCode? _linkCode;

  LinkOpened? get _linkNow => _linkCode != null && identical(_linkCode, _codeNow) ? _link : null;

  /// A payment link: the checks of the open wallet, then a refusal (under To when pasted, else
  /// in a dialog), "You paid this request on ‹date›" with Pay again, or To and Amount filled.
  Future<void> _openLink(PaymentLink link, CodeOrigin origin) async {
    final seq = ++_linkSeq;
    final LinkOutcome outcome;
    try {
      outcome = await ref.read(deskApiProvider).openPaymentLink(
        link,
        membership: ref.read(directoryMembershipProvider),
        nowSeconds: ref.read(linkClockProvider)().millisecondsSinceEpoch ~/ 1000,
      );
    } on Object catch (e) {
      if (mounted && seq == _linkSeq) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
      return;
    }
    if (!mounted || seq != _linkSeq) return;
    final l = context.l10n;
    switch (outcome) {
      case LinkRefused():
        final reason = linkRefusalText(l, outcome);
        if (origin == CodeOrigin.link) {
          showLinkRefusal(context, reason);
        } else {
          setState(() {
            _to.text = link.text.trim();
            _lastTo = _to.text;
            _codeError = (_) => reason;
            _code = null;
            _toTouched = false;
            _contactId = null;
            _suggestOff = true;
          });
        }
      case LinkOpened(:final request) when ref.read(paymentRefusalsProvider).refusesPayments(address: request.card.address):
        showLinkNoPayments(context, ref.read(paymentRefusalsProvider).refusedName(address: request.card.address) ?? '');
      case LinkOpened(:final standing):
        if (standing.paidBefore != null && !await askPayAgain(context, localDay(l, standing.paidBefore!.toLocal()))) return;
        if (!mounted || seq != _linkSeq) return;
        _fillFromLink(outcome, origin);
    }
  }

  /// To from the listing, Amount from the request (a zero amount leaves it to the payer); the
  /// method follows the address, Epicbox. The trust line sits under To, in place of the banner.
  void _fillFromLink(LinkOpened link, CodeOrigin origin) {
    final l = context.l10n;
    final to = link.request.card.address;
    final asked = link.request.amount;
    final code = SendCode(origin: origin, address: to, amount: asked > BigInt.zero ? asked.toInt() : null);
    _fill(to, code, () {
      if (asked > BigInt.zero) _amount.text = localDecimal(l, shared.formatEpic(asked));
    });
    setState(() {
      _codeBanner = false;
      _link = link;
      _linkCode = code;
    });
  }

  /// A transaction text: signed as if its file had been chosen, or finalized when it answers
  /// one of this wallet's sends.
  Future<void> _openSlate(String slate) async {
    final nav = ref.read(deskNavProvider.notifier);
    if (await ref.read(deskApiProvider).isResponseText(slate)) {
      nav.go(DeskRoute.finalize, FinalizeArgs(text: slate));
    } else {
      nav.go(DeskRoute.importTx, ImportArgs(text: slate));
    }
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
      // Link · HTTP's switch is the listener's: an http(s) address is always sendable.
      (m) => (m == MethodKind.linkHttp || payments.offers(m)) && switch (m) {
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
    setState(() {
      // A new code replaces the old one: what the old one put in and is still untouched goes,
      // so its amount and note never ride along to another payee.
      final old = _code;
      if (old != null) {
        if (old.amount != null && _parsed == old.amount) _amount.clear();
        if (old.noteFilled && _message.text == old.note) _message.clear();
      }
      _pairingTo = null;
      _contactId = null;
      _file = false;
      _to.text = to;
      _lastTo = to;
      // The code's address stays as the code wrote it: the banner and the review name it.
      fields();
      _code = code;
      _codeBanner = code.banner;
      _codeError = null;
      _all = false;
      _allError = null;
      _submitted = false;
      _toTouched = false;
      _amountEdited = false;
      _suggestOff = true;
      if (_result is SendDone) _result = null;
      _failure = null;
      final st = ref.read(deskProvider);
      _contactId = _contactOf(st.contacts)?.id;
      _askReach(st);
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
        _contactId = null;
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
    _useAddress(c, _bestAddress(c, ref.read(deskProvider)));
  }

  /// [c] in To as its chip, paid at [address] (one of its addresses).
  void _useAddress(Contact c, String address) {
    _to.text = address;
    _changed(to: true);
    setState(() {
      _pairingTo = null;
      _contactId = c.id;
      _suggestOff = true;
      _toTouched = true;
      _askReach(ref.read(deskProvider));
    });
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

  /// Contacts whose name or address holds what is typed in To, at most four; none once one
  /// was picked.
  List<Contact> _matches(DeskState st) => _suggestOff ? const [] : _nameMatches(st);

  List<Contact> _nameMatches(DeskState st) {
    final q = _to.text.trim().toLowerCase();
    final contacts = st.contacts;
    if (_contactId != null || q.length < 2 || contacts == null || _contactOf(contacts) != null) return const [];
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
    if (_read.kind != RecipientInputKind.epicbox || own == null || own.isEmpty) return null;
    final (key, host) = _epicboxParts(_read.address);
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

  /// The stop for a contact that takes no payments, by its pairing or its Epicbox address:
  /// "‹name› takes no payments." under To, and Continue stays off.
  String? _noPaymentsProblem({String? pairingId, String? address}) {
    final refusals = ref.read(paymentRefusalsProvider);
    return refusals.refusesPayments(pairingId: pairingId, address: address)
        ? context.l10n.contactNoPaymentsNamed(refusals.refusedName(pairingId: pairingId, address: address) ?? '')
        : null;
  }

  String? _toError(DeskState st) {
    // A pairing recipient has no address: its card says whether it can be paid.
    if (_viaPairing) {
      if (_noPaymentsProblem(pairingId: _pairingTo) case final stop?) return stop;
      return ref.read(deskPairingByIdProvider(_pairingTo!))?.paysByMailbox ?? false ? null : context.l10n.deskSendErrNoAddress;
    }
    if (_file) return null;
    final l = context.l10n;
    final r = _read;
    switch (r.kind) {
      case RecipientInputKind.empty:
        return l.deskSendErrNoAddress;
      // Its own notice offers to open it.
      case RecipientInputKind.slate:
        return null;
      // A contact's name while one matches; else no address.
      case RecipientInputKind.text:
        return _nameMatches(st).isNotEmpty ? null : sendProblemText(l, r.problem ?? RecipientProblem.notAddress);
      case RecipientInputKind.invalid:
        return sendProblemText(l, r.problem ?? RecipientProblem.incomplete);
      default:
    }
    // The build without Tor reaches no onion, by any method.
    if (!DeskFeatures.tor && r.kind == RecipientInputKind.onion) return l.sendTorNotInVersion;
    // Shallow sends by Epicbox alone.
    if (!_strip && r.kind != RecipientInputKind.epicbox) return l.deskSendErrEpicbox;
    if (_ownAddressError(st) case final own?) return own;
    if (r.kind == RecipientInputKind.epicbox) {
      if (_noPaymentsProblem(address: r.address) case final stop?) return stop;
    }
    // The key's checksum.
    if (r.kind == RecipientInputKind.epicbox && !parseAddress(r.address, ref.read(deskApiProvider)).complete) return l.deskSendErrEpicbox;
    return null;
  }

  /// LEPIC signs at most [slateMessageMaxBytes] UTF-8 bytes of a message and cuts the rest
  /// (linux-09): longer text is refused here instead of being cut without a word.
  bool get _messageTooLong => utf8Length(_message.text.trim()) > slateMessageMaxBytes;

  Future<void> _review() async {
    final st = ref.read(deskProvider);
    if (!_canSend(st) || _reviewing) return;
    // Enter in Amount takes this way too: nothing while the amount is too much or its estimate
    // is on its way.
    if (_gate(st).holds) return;
    setState(() {
      _submitted = true;
      _settleTo(st);
      _toTouched = true;
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
    // Asked again before the review opens: the estimate for exactly this amount, and amount
    // and fee within what can be spent now; else the field says why.
    if (!_gate(st).ready) {
      setState(() {
        _submitted = true;
        _amountEdited = false;
      });
      return;
    }
    final contacts = st.contacts;
    final n = _amountNano;
    final code = _method == TxMethod.file ? null : _codeNow;
    final link = _method == TxMethod.file ? null : _linkNow;
    // The relay in the address, when the app knows no such server: the public list, the
    // monitor's, and the one this wallet is on.
    final addressRelay = _method == TxMethod.epicbox ? recipientRelay(_read.address) : null;
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
        // The clean form: the field keeps the text as given, the send goes to the method line's.
        to: _method == TxMethod.file || viaPairing ? null : (_read.isAddress ? _read.address : _to.text.trim()),
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
        route: _method == TxMethod.file || viaPairing ? null : _read,
        torStarts: _torStarts(ref.read(deskProvider)),
      );
    }

    // A listing that points to another wallet than when it was paid asks once more.
    if (link != null && link.standing.trust == DirectoryTrust.changedWallet && !await confirmChangedWalletDesk(context, link)) return;
    if (!mounted) return;
    final draft = draftOf(_plan);
    // Plain HTTP to another computer goes through without asking; the wallet needs the flag.
    // The review is the consent: the wallet needs the flag for plain http to another device.
    final plain = draft.route?.plainHttpToOther ?? false;
    // The mode or Tor changed since Review was enabled: the hold's notice says what to do.
    if (_hold(ref.read(deskProvider)) != null) return;
    final notifier = ref.read(deskProvider.notifier);
    // Every send asks the wallet's password, also when it was opened with the remembered one.
    final api = ref.read(deskApiProvider);
    final res = await showEDialog<SendResult>(
      context,
      dismissible: false,
      builder: (_) => _ReviewDialog(
        draft: draft,
        compact: !_reviewStep,
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
            if (link != null) {
              _paidLink = link;
              unawaited(api.recordLinkPayment(link.request, ref.read(linkClockProvider)().millisecondsSinceEpoch ~/ 1000, txId: res.tx.slateId));
            } else {
              _paidLink = null;
            }
            _queuedFor = draft.queued ? draft.contactName : null;
            _sentTo = draft.contactName;
            _to.clear();
            _amount.clear();
            _message.clear();
            _fee = null;
            _submitted = false;
            _code = null;
            _pairingTo = null;
            _contactId = null;
              }
      }
    });
  }

  /// The link the last send paid, for Save as contact on the page after it.
  LinkOpened? _paidLink;

  /// The last send was a mailbox payment queued while Epicbox is off: to whom, for its notice.
  String? _queuedFor;

  /// Clear in To, on the contact's card or the pairing's (Send keeps its draft, so a
  /// filled recipient always has a way out): the recipient goes with what followed from it,
  /// the method it moved, a code's untouched amount and note, the switch tag and the errors,
  /// back to the method Send starts on. Amount and Message typed by hand stay.
  void _clearRecipient() {
    setState(() {
      _to.clear();
      _pairingTo = null;
      _contactId = null;
        _codeError = null;
      _submitted = false;
    });
    _changed(to: true);
    _focusTo();
  }

  void _reset() => setState(() {
    _paidLink = null;
    _result = null;
    _failure = null;
    _code = null;
    _pairingTo = null;
    _contactId = null;
    _file = false;
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
    // A level change redraws the page.
    ref.watch(deskLevelUiProvider);
    ref.watch(deskLevelFeaturesProvider);
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
    // A half-filled form holds Back (mouse, Alt+Left).
    return LayoutBuilder(
      builder: (context, outer) {
        // Two columns need Lay.xl inside the page's padding; below that the summary falls under
        // the form, so Total and Review stay in a bar pinned to the bottom.
        final narrow = outer.maxWidth - 2 * Sp.x8 < Lay.xl;
        final form = res is! SendFileReady && res is! SendDone;
        return DeskStepBack(
      onBack: res is! SendFileReady && (_to.text.isNotEmpty || _amount.text.isNotEmpty || _message.text.isNotEmpty) ? () {} : null,
      child: EPage(
      title: context.l10n.deskSendTitle,
      footer: narrow && form ? _reviewBar(st) : null,
      titleTrailing: res is SendFileReady || !_strip || _netBlock(st).byMode || !DeskFeatures.tor ? null : TorChip(_torWay(st)),
      width: EPageWidth.mid,
      child: res is SendFileReady
          ? _fileReady(res, nav)
          : res is SendDone
          ? _done(res, nav)
          : LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= Lay.xl;
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
          EButton.primary(semanticsId: TrustIds.sendReview, label: s.reviewLabel, icon: EIcons.send, busy: s.reviewing, tooltip: s.reviewTip, onPressed: s.onReview),
        ],
      ),
    );
  }

  /// After a send: the payment's live steps ([DeskPaymentSteps], in the level's words), the way
  /// to a new send and to Activity. A mailbox payment queued while Epicbox is off keeps the
  /// plain result card: nothing has gone out yet.
  Widget _done(SendDone r, DeskNav nav) {
    final l = context.l10n;
    final queued = _queuedFor != null;
    final paid = _paidLink;
    final actions = [
      EButton.primary(semanticsId: TrustIds.sendAnother, label: l.deskSendNewSend, icon: EIcons.send, onPressed: _reset),
      EButton(label: l.deskSendViewTx, onPressed: () => nav.go(DeskRoute.activity, r.tx.id)),
      // A payment from a link: its payee as a contact, the address and the listed name filled.
      if (paid != null)
        EButton(
          key: const ValueKey('send-link-save-contact'),
          label: l.sendSaveContact,
          icon: EIcons.contacts,
          onPressed: () => nav.go(DeskRoute.contacts, ContactsArgs(adding: true, address: paid.request.card.address, name: paid.payeeLabel)),
        ),
    ];
    if (queued) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Max.form),
        child: ResultPanel(
          key: const ValueKey('send-queued'),
          // Queued, not sent yet: the waiting tile, never the done check.
          glyph: const ResultGlyph.waiting(),
          title: l.sendQueuedHeadline,
          text: l.sendQueuedBody(_queuedFor!),
          body: EMoney(r.tx.amount, size: Fs.lg, color: context.dc.txSent),
          // The one result card (UD-007): gold = this screen's next action, outlined = Activity.
          actions: actions,
        ),
      );
    }
    // The payment as the wallet lists it now, so the steps move on their own.
    final live = ref.watch(deskProvider.select((s) => s.txs))?.where((t) => r.tx.slateId.isNotEmpty ? t.slateId == r.tx.slateId : t.id == r.tx.id).firstOrNull ?? r.tx;
    final name = _sentTo ?? live.contactName;
    final amount = formatEpicL(l, r.tx.amount);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Max.form),
      child: ResultPanel(
        key: const ValueKey('send-done'),
        // On its way: the steps under it say how far; the tile says it is under way.
        glyph: const ResultGlyph(icon: EIcons.send, tone: ETone.info),
        title: name == null ? l.lvPayOnItsWay : l.deskLvSendLiveTo(name),
        text: name == null ? l.deskLvSendLiveAmount(amount) : l.deskLvSendLiveAmountTo(amount, name),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DeskPaymentSteps(tx: live),
            SizedBox(height: Sp.x4),
            Text(l.lvPayCloseNote, style: context.ts.small),
          ],
        ),
        actions: actions,
      ),
    );
  }

  /// The name of whom the last send went to, for the page after it; null for an address.
  String? _sentTo;

  Widget _fileReady(SendFileReady r, DeskNav nav) {
    final l = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Max.form),
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

  /// The method-off notice's Turn on (Link · Tor: an http(s) address needs no switch): the
  /// switch alone, as Settings › Transactions does.
  Future<void> _turnOn(MethodKind m) async {
    final n = ref.read(deskProvider.notifier);
    setState(() => _turningOn = true);
    try {
      final s = ref.read(deskProvider).settings;
      await n.saveSettings(s.copyWith(payments: s.payments.withMethod(m, true)));
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskRecvTurnOnFailed(MethodIcons.fullName(context.l10n, m)), text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _turningOn = false);
    }
  }

  /// The mode's note for this send: the hold's sentence (Kill switch, Node only), or Tor only
  /// waiting for tor.
  String _blockTitle(AppLocalizations l, NetBlock net) => switch (net) {
    NetBlock.killSwitch => sendHoldText(l, SendHold.killSwitch),
    NetBlock.nodeOnly => sendHoldText(l, SendHold.nodeOnly),
    _ => netBlockReason(l, net)!,
  };

  /// [contact]'s one address is of [m]'s kind: it can be paid only that way.
  static bool _onlyKind(Contact? contact, MethodKind m) =>
      contact != null && contact.kinds.length == 1 && MethodKind.ofRecipient(contact.kinds.single) == m;

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
        text: _onlyKind(contact, MethodKind.epicbox) ? l.sendContactOnlyEpicbox(contact!.name) : null,
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
        text: _onlyKind(contact, _kind) ? l.sendContactOnlyMethod(contact!.name, MethodIcons.fullName(l, _kind)) : null,
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
    // The hold of the address in To is said under the field, once.
    final hold = _hold(st);
    if (hold != null && (net.byMode || net == NetBlock.waitingForTor)) return null;
    // No address yet: the mode's hold above the form, with its fix and the way that works
    // without a connection.
    if (net.byMode) {
      final h = net == NetBlock.killSwitch ? SendHold.killSwitch : SendHold.nodeOnly;
      return ENotice(
        key: const ValueKey('send-net-blocked'),
        title: sendHoldText(l, h),
        text: l.torTurnOffCaption,
        icon: EIcons.lanOff,
        actions: [
          EButton(key: const ValueKey('send-hold-fix'), label: sendHoldAction(l, h), size: EBtnSize.inline, busy: _holdBusy, onPressed: _holdBusy ? null : () => _fixHold(h)),
          if (!_file) _payByFile(),
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
          // Retry only (D-05): turning Tor off is never the fix an error offers.
          EButton(label: l.commonRetry, icon: EIcons.refresh, size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : () => _setTor(true)),
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
    if (_byEpicbox && !_viaPairing && ref.read(hostSettingsProvider).epicboxServers.isEmpty) {
      return ENotice(
        key: const ValueKey('send-no-epicbox'),
        title: l.deskSlNoEpicboxTitle,
        text: l.deskSlNoEpicboxText,
        tone: ETone.warn,
        icon: EIcons.epicbox,
        actions: [EButton(label: l.deskRecvSettings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving))],
      );
    }
    if (_byEpicbox && eb == ServiceHealth.down) return const EpicboxDownNotice();
    if (_epicboxBlocked(st)) {
      return ENotice(
        title: l.deskSendEpicboxOff,
        text: l.deskSendEpicboxOffTab(MethodIcons.shortName(l, MethodKind.directFile)),
        tone: ETone.warn,
        icon: EIcons.antenna,
        actions: [
          if (eb == ServiceHealth.off)
            EButton(label: l.deskSendEpicboxTurnOn, icon: EIcons.epicbox, size: EBtnSize.inline, busy: _starting, onPressed: _starting ? null : _startEpicbox),
          _payByFile(),
        ],
      );
    }
    // Offline on a local node without peers: the payment waits in its pool.
    if (_hasMethod && _method != TxMethod.epicbox && ref.watch(deskOfflinePeersProvider).value == 0) {
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

  /// The form's panel: To and the lines under it (the method, what holds it), or
  /// the file form's line; then Amount, Message, Advanced and Dandelion.
  Widget _form(DeskState st) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final spendable = st.balance?.spendable;
    final picked = _picked(st);
    final contact = picked ?? _contactOf(st.contacts);
    final file = _file;
    final code = file ? null : _codeNow;
    final toErr = _codeError?.call(l) ?? (_toTouched || _onionNoTor ? _toError(st) : null);
    // More than can be spent is said on the keystroke; the other amount errors after Review.
    final amErr = _allError ?? ((_submitted && !_amountEdited) || _gate(st).notEnough ? _amountError(spendable) : null);
    final matches = file || picked != null ? const <Contact>[] : _matches(st);
    final pairing = _pairingTo == null ? null : ref.watch(deskPairingByIdProvider(_pairingTo!));
    final pairingName = _pairingTo == null ? '' : ref.watch(deskPairingNameProvider(_pairingTo!));
    final shallow = ref.read(deskLevelUiProvider).shallow;
    final empty = _to.text.trim().isEmpty;
    return EPanel(
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (file) ...[
          _FileLine(onBack: _leaveFile),
          SizedBox(height: Sp.x5),
        ] else if (pairing != null) ...[
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
        ] else ...[
          TourTarget(
            id: 'send-methods',
            child: EField(
              label: l.deskSendTo,
              error: toErr,
              // The help while To is empty; then the lines under it say what it holds.
              help: toErr == null && empty ? l.deskSendToHelp : null,
              child: picked != null
                  ? _ContactChip(contact: picked, onClear: _clearRecipient)
                  : EInput(
                      semanticsId: TrustIds.sendTo,
                      controller: _to,
                      focusNode: _toFocus,
                      mono: true,
                      fadeEnd: true,
                      invalid: toErr != null,
                      hint: l.deskSendToHint,
                      semanticLabel: l.deskSendToSem,
                      onChanged: _toChanged,
                      // Enter picks the first matching contact, else goes on to Amount.
                      onSubmitted: matches.isEmpty ? null : (_) => _use(matches.first),
                      trailingTabStop: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_to.text.isNotEmpty)
                            EIconButton(key: const ValueKey('send-to-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, onPressed: _clearRecipient)
                          else
                            EIconButton(icon: EIcons.paste, label: l.commonPaste, size: EBtnSize.inline, tabStop: false, onPressed: _paste),
                          SizedBox(width: Sp.x1),
                          EButton(label: l.deskSendContacts, icon: EIcons.contacts, size: EBtnSize.inline, onPressed: _pick),
                        ],
                      ),
                    ),
            ),
          ),
          if (matches.isNotEmpty) ...[
            SizedBox(height: Sp.x2),
            _Suggestions(contacts: matches, onPick: _use, addressOf: (x) => _bestAddress(x, st), pairingOf: (x) => contactPairingOnly(ref, x)),
          ],
          ..._underTo(st, picked),
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
          // A payment link's trust line: who listed the payee, with the listing code.
          if (_linkNow case final link?) ...[
            SizedBox(height: Sp.x3),
            DeskLinkTrust(link: link),
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
            // A link's request: only an edited amount says so.
            _ when _linkNow != null => amountEdited(_linkNow!, _parsed == null ? null : BigInt.from(_parsed!)) ? l.linkAmountEdited : null,
            null => null,
            final asked when asked == _parsed => l.sendAmountFromCode,
            final asked => l.sendAmountCodeAsked(epicTextL(l, asked)),
          },
          aside: spendable == null
              ? Text(l.deskSendAvailableNone, style: ts.small)
              : Text(
                  l.deskSendAvailable(st.settings.hideAmounts ? '••••••' : formatEpicL(l, spendable)),
                  style: ts.small.copyWith(color: st.status?.syncProgress != null ? context.dc.faint : context.dc.dim),
                ),
          child: EInput(
            semanticsId: TrustIds.sendAmount,
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
                Text(epicUnit, style: ts.small.copyWith(color: c.dim)),
                SizedBox(width: Sp.x2),
                EButton(semanticsId: TrustIds.sendMax, label: l.deskSendAllButton, size: EBtnSize.inline, busy: _allBusy, onPressed: spendable == null || _allBusy ? null : _sendAll),
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
          // Bytes, as LEPIC counts them (an emoji takes 4), shown with no unit; amber from 90 %
          // of the limit, red over it.
          aside: Text(
            l.deskSendMessageCount(utf8Length(_message.text), slateMessageMaxBytes),
            style: ts.mono(size: Fs.xs, color: _messageTooLong ? c.risk : utf8Length(_message.text) * 10 >= slateMessageMaxBytes * 9 ? c.warn : c.faint),
          ),
          help: code != null && code.noteFilled && _message.text == code.note ? l.sendNoteFromCodeHelper : l.deskSendMessageHelp,
          error: _messageTooLong ? l.deskSendMessageTooLongPlain : null,
          child: EInput(
            controller: _message,
            maxLines: 3,
            semanticLabel: l.deskSendMessage,
            inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Advanced › Send options; open when a link brought the user here for it.
        if (!shallow && advancedHas(ref, AdvancedFeature.sendOptions, keep: _args.advancedOpen)) ...[
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
        if (!shallow && DeskFeatures.dandelion && !file) ...[
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
    );
  }

  /// Pay with a file: the quiet way to the file form, under an empty To and in the notices of
  /// a connection that does not go.
  Widget _payByFile() => EButton.ghost(key: const ValueKey('send-pay-file'), label: context.l10n.sendPayByFile, icon: EIcons.file, size: EBtnSize.inline, onPressed: _openFile);

  /// Under To: a transaction text's notice, the method line ("Sends to" while typing), then the one notice that holds it (the mode, Tor, a wallet that did not
  /// answer) with its one action; Pay with a file under an empty field.
  List<Widget> _underTo(DeskState st, Contact? picked) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final r = _read;
    final out = <Widget>[];
    void add(Widget w, {double gap = 0}) => out.addAll([SizedBox(height: gap == 0 ? Sp.x3 : gap), w]);
    if (r.kind == RecipientInputKind.empty) {
      // The mode's notice above has it already.
      if (!_netBlock(st).byMode) add(Align(alignment: AlignmentDirectional.centerStart, child: Transform.translate(offset: Offset(-EButton.labelInset(EBtnSize.inline), 0), child: _payByFile())), gap: Sp.x2);
      return out;
    }
    if (r.kind == RecipientInputKind.slate) {
      add(ENotice(
        key: const ValueKey('send-slate-text'),
        title: l.sendIsSlateText,
        icon: EIcons.file,
        actions: [EButton(label: l.sendOpenSlateText, size: EBtnSize.inline, onPressed: () => _openSlate(r.address))],
      ));
      return out;
    }
    // An http(s) address still being typed: its method from the scheme on, nothing more yet.
    if (r.typing != null && _strip) {
      add(_RouteLine(key: ValueKey('send-route-${r.typing!.name}'), to: r));
      return out;
    }
    if (_methodOf(r) == null || _onionNoTor || (!_strip && r.kind != RecipientInputKind.epicbox)) return out;
    final hold = _hold(st);
    final mode = deskNetMode(st);
    final others = picked == null ? const <String>[] : picked.addresses;
    add(_RouteLine(
      key: ValueKey('send-route-${r.kind.name}'),
      to: r,
      tag: sendRouteTag(l, r, phone: false, overTor: hold == null && sendOverTor(r, mode: mode, torOn: _torOn(st))),
      torStarts: hold == null && _torStarts(st),
      change: others.length < 2
          ? null
          : _AddressMenu(
              name: picked!.name,
              addresses: others,
              current: _to.text,
              read: _readOf,
              held: (x) => _heldOf(x, st),
              onPick: (a) => _useAddress(picked, a),
            ),
    ));
    if (!_toTouched && picked == null && r.address != _to.text.trim()) {
      // Typing: the clean form, faint, which is what is sent.
      add(
        Padding(
          padding: EdgeInsetsDirectional.only(start: _RouteLine.textInset),
          child: Text.rich(
            key: const ValueKey('send-sends-to'),
            TextSpan(children: [
              TextSpan(text: '${l.sendSendsTo} ', style: ts.small.copyWith(color: c.faint)),
              TextSpan(text: r.address, style: ts.mono(size: Fs.xs, color: c.faint)),
            ]),
          ),
        ),
        gap: Sp.x1,
      );
    }
    if (hold != null) {
      add(ENotice(
        key: ValueKey('send-hold-${hold.name}'),
        title: sendHoldText(l, hold),
        text: l.torTurnOffCaption,
        icon: hold.fix == SendHoldFix.torOff ? EIcons.tor : EIcons.lanOff,
        actions: [
          EButton(key: const ValueKey('send-hold-fix'), label: sendHoldAction(l, hold), size: EBtnSize.inline, busy: _holdBusy || _torBusy, onPressed: _holdBusy || _torBusy ? null : () => _fixHold(hold)),
        ],
      ));
      if (hold.offersDirect) {
        add(
          Wrap(
            key: const ValueKey('send-without-connection'),
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Sp.x2,
            children: [Text(l.sendWithoutConnection, style: ts.small), _payByFile()],
          ),
          gap: Sp.x2,
        );
      }
      return out;
    }
    // Link · Tor switched off comes first ([_blockNotice]): Tor alone would not send it.
    final net = _netBlock(st);
    if (DeskFeatures.tor && _torWay(st) == TorWay.needsTor && !net.byMode && net != NetBlock.methodOff) {
      add(ENotice(
        key: const ValueKey('send-needs-tor'),
        title: l.deskSendNeedsTor,
        text: st.status?.torIncluded ?? true ? l.deskSendNeedsTorText : l.deskSendNoTorBuild,
        tone: ETone.warn,
        icon: EIcons.tor,
        actions: [
          if (st.status?.torIncluded ?? true)
            EButton(label: l.deskSendTurnOnTor, size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : () => _setTor(true)),
        ],
      ));
      return out;
    }
    // The reach check: only a failure shows, and "Checking…" for a slow answer.
    final reach = _reachNow;
    final lines = reach == null ? null : sendReachLines(l, r, reach);
    if (lines != null) {
      add(ENotice(
        key: const ValueKey('send-reach'),
        title: lines.$1,
        text: lines.$2,
        tone: ETone.warn,
        actions: [
          if (reach == ReachResult.noAnswer) EButton(key: const ValueKey('send-reach-retry'), label: l.sendReachTryAgain, icon: EIcons.refresh, size: EBtnSize.inline, onPressed: _retryReach),
          _payByFile(),
        ],
      ));
    } else if (reach == null && _reachSlow && _reachAsked.contains(r.address)) {
      add(
        Padding(
          padding: EdgeInsetsDirectional.only(start: _RouteLine.textInset),
          child: Semantics(
            liveRegion: true,
            child: Row(
              key: const ValueKey('send-reach-checking'),
              children: [
                SizedBox.square(dimension: 12.u, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.faint)),
                SizedBox(width: Sp.x2),
                Text(l.sendReachChecking, style: ts.small.copyWith(color: c.faint)),
              ],
            ),
          ),
        ),
        gap: Sp.x2,
      );
    }
    return out;
  }

  /// What the summary shows now: the amounts and the one line under Review send.
  _SendSummary _summary(DeskState st, SendResult? res, {bool review = true}) {
    final l = context.l10n;
    final spendable = st.balance?.spendable;
    final n = _amountNano;
    final fee = n > 0 ? _fee : null;
    final nodeBlocked = _nodeBlock(st) != null;
    final gate = _gate(st);
    // The line under Review, and whether it names a block: then Review is off until it clears.
    final (hint, blocker) = switch (null) {
      _ when res is SendDone => (_queuedFor == null ? l.deskSendHintSent : l.deskSendHintQueued, true),
      // The address in To is held by the mode or Tor: the notice's sentence, once more here.
      _ when _hold(st) != null => (sendHoldText(l, _hold(st)!), true),
      // The network mode first, as the banner: Offline does not poll a node that is not local,
      // so its "not synced" says nothing then (LNX-15).
      _ when _netBlock(st).byMode || _netBlock(st) == NetBlock.waitingForTor => (_blockTitle(l, _netBlock(st)), true),
      _ when _onionNoTor => (l.sendTorNotInVersion, true),
      _ when nodeBlocked && _nodeDown(st) && _noNode => (l.deskSlNoNodeTitle, true),
      _ when nodeBlocked && _nodeDown(st) => (l.deskNodeNotAnsweringLine, true),
      _ when nodeBlocked => (l.deskSendHintNode, true),
      _ when _netBlock(st) == NetBlock.epicboxOff => (l.deskSendHintNeedsMethod(l.methodEpicbox), true),
      _ when _netBlock(st) == NetBlock.methodOff => (l.deskSendHintNeedsMethod(MethodIcons.fullName(l, _kind)), true),
      _ when _epicboxBlocked(st) => (l.deskSendHintEpicbox, true),
      _ when _torWay(st) == TorWay.wait => (l.deskSendHintTorWait, true),
      _ when _torWay(st) == TorWay.blocked => (l.deskSendHintTorBlocked, true),
      _ when _torWay(st) == TorWay.needsTor => (l.deskSendHintNeedsTor, true),
      // No address yet: Review waits for one; a marked field after the field was left.
      _ when !_hasMethod => (_toTouched && _toError(st) != null ? l.deskSendHintFix : l.deskSendErrNoAddress, true),
      _ when _toTouched && _toError(st) != null => (l.deskSendHintFix, true),
      _ when _submitted && !_amountEdited && _amountError(spendable) != null => (l.deskSendHintFix, true),
      _ when gate.notEnough => (l.deskSendHintFix, true),
      _ when _messageTooLong => (l.deskSendHintFix, true),
      _ when _reviewing || gate.checking => (l.deskSendHintChecking, false),
      _ when !_reviewStep => (l.deskLvSendNothingLeaves, false),
      _ => (l.deskSendHintDefault, false),
    };
    final plan = _plan?.estimate.amount == n && n > 0 ? _plan : null;
    final balance = st.balance;
    // Via: the method's name, and under it the relay, the short onion or the host as contacted.
    final r = _read;
    final (String? via, String? viaSub) = switch (null) {
      _ when !_strip => (null, null),
      _ when _file => (MethodIcons.fullName(l, MethodKind.directFile), null),
      _ when _viaPairing => (l.methodEpicbox, ref.watch(deskPairingNameProvider(_pairingTo!))),
      _ when _methodOf(r) == null || _onionNoTor => ('—', null), // l10n-ok: nothing yet
      _ => (sendMethodName(l, r), switch (r.kind) {
        RecipientInputKind.epicbox => r.host,
        RecipientInputKind.onion => shortAddress(r.host, compact: true),
        _ => r.contacted,
      }),
    };
    return _SendSummary(
      via: via,
      viaSub: viaSub,
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
      // The button keeps its name while it is off; the reason is the line under it, and the
      // short one its tip.
      reviewTip: blocker ? switch (_torWay(st)) { TorWay.wait => l.deskSendReviewWaitTor, TorWay.blocked => l.deskSendReviewTorOff, _ => null } : null,
      reviewLabel: switch (_torWay(st)) {
        _ when _viaPairing && ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff => l.sendQueue,
        // Shallow: the button is the Send itself, naming the amount and whom it goes to.
        _ when !_reviewStep => n <= 0
            ? l.deskLvSendButton
            : switch (_viaPairing ? ref.watch(deskPairingNameProvider(_pairingTo!)) : _contactOf(st.contacts)?.name) {
                final who? => keepNumbersWithUnits(l.deskLvSendButtonTo(formatEpicL(l, n), who)),
                null => keepNumbersWithUnits(l.deskLvSendButtonAmount(formatEpicL(l, n))),
              },
        _ => l.deskSendReview,
      },
      reviewing: _reviewing,
      onReview: _canSend(st) && !_reviewing && !blocker && !gate.holds ? _review : null,
      review: review,
      lockRows: _reviewStep,
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
    this.reviewTip,
    this.via,
    this.viaSub,
    this.summary,
    this.extraFee = 0,
    this.strategy = SelectionStrategy.smallest,
    this.defaultStrategy = SelectionStrategy.smallest,
    this.confirmations = defaultMinimumConfirmations,
    this.review = true,
    this.lockRows = true,
  });

  /// The method this send goes by, and under it where it goes; null hides the row (Shallow).
  final String? via;
  final String? viaSub;

  /// Balance after, the lock rows and the split line: Deeper and Deep end. Shallow keeps
  /// Amount, Network fee and Total.
  final bool lockRows;

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

  /// "Review", or the shallow level's "Send 1.5 EPIC to …"; never what holds it.
  final String reviewLabel;

  /// The short reason the button is off ("Waiting for Tor"), on hover; the line under it says it.
  final String? reviewTip;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final n = amount;
    final bad = n > 0 && spendable != null && n + (fee ?? 0) > spendable!;
    final ready = n > 0 && !bad;
    final pending = feeLoading && !bad;
    // The summary's one row ([SummaryLine]); a zero reads as "—", nothing to show yet.
    Widget line(String label, int? v, {bool strong = false, bool risk = false, bool loading = false}) =>
        SummaryLine(label: label, value: v == 0 ? null : v, strong: strong, risk: risk, loading: loading);
    return EPanel(
      title: l.deskSendSummary,
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(l.deskSendAmount, n > 0 ? n : null, risk: bad),
          line(l.deskSendNetworkFee, fee, loading: pending && fee == null),
          if (via != null)
            Padding(
              key: const ValueKey('send-summary-via'),
              padding: EdgeInsets.symmetric(vertical: Sp.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.sendFactVia, style: ts.bodyDim),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(via!, style: ts.body, textAlign: TextAlign.end),
                        if (viaSub != null && viaSub!.isNotEmpty)
                          Text(viaSub!, style: ts.mono(size: Fs.xs, color: c.dim), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ExpandFade(
            open: lockRows && ready && (summary?.changeOutputs ?? 0) > 1,
            child: summary == null || summary!.changeOutputs < 2
                ? const SizedBox.shrink()
                : SendSplitLine(outputs: summary!.changeOutputs, extraFee: extraFee, change: summary!.change),
          ),
          Divider(height: Sp.x4, color: c.line),
          // Never Amount alone as Total: it waits for the fee, "—" when the estimate failed.
          line(l.deskSendTotal, ready && fee != null ? n + fee! : null, strong: true, loading: pending && fee == null),
          if (lockRows) SendLockRows(summary: ready ? summary : null, strategy: strategy, defaultStrategy: defaultStrategy, blocks: confirmations, loading: pending),
          if (updating) Text(l.deskSendUpdating, style: ts.caption),
          SizedBox(height: Sp.x4),
          if (review) ...[
            EButton.primary(semanticsId: TrustIds.sendReview, label: reviewLabel, icon: EIcons.send, expand: true, busy: reviewing, tooltip: reviewTip, onPressed: onReview),
            SizedBox(height: Sp.x3),
          ],
          Semantics(liveRegion: true, child: Text(hint, style: ts.small, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// The method's icon in its small square, for the method line and the file form's line.
class _MethodGlyph extends StatelessWidget {
  const _MethodGlyph(this.icon);

  final IconData icon;

  static double get size => 32.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: size,
      height: size,
      decoration: c.well,
      child: Icon(icon, size: Ctl.iconSm, color: c.accentText),
    );
  }
}

/// The method line under To: the method's icon, its name and tag (This computer, Your network,
/// Over Tor), the host exactly as it will be contacted (the host in bold), "Tor starts when you
/// send." for an onion while the Tor switch is off, and [change] for a contact's other addresses.
class _RouteLine extends StatelessWidget {
  const _RouteLine({super.key, required this.to, this.tag, this.torStarts = false, this.change});

  final RecipientInput to;
  final String? tag;
  final bool torStarts;
  final Widget? change;

  /// Where the line's text starts: the lines under it line up with it.
  static double get textInset => _MethodGlyph.size + Sp.x3;

  static IconData iconOf(RecipientInput r) => switch (r.kind) {
    RecipientInputKind.epicbox => EIcons.epicbox,
    RecipientInputKind.onion => EIcons.tor,
    _ => EIcons.link,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final name = sendMethodName(l, to);
    final mono = ts.mono(size: Fs.xs, color: c.dim);
    final bold = mono.copyWith(color: c.text, fontWeight: FontWeight.w600);
    final where = switch (to.urlKind ?? to.kind) {
      RecipientInputKind.https || RecipientInputKind.http => [
        TextSpan(text: '${to.urlKind == RecipientInputKind.https ? 'https' : 'http'}://'), // l10n-ok: scheme
        TextSpan(text: to.hostShown, style: bold),
        TextSpan(text: ':${to.port}${to.path}'),
      ],
      RecipientInputKind.epicbox => [TextSpan(text: to.host, style: bold)],
      _ => [TextSpan(text: to.host)],
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodGlyph(iconOf(to)),
        SizedBox(width: Sp.x3),
        Expanded(
          child: Semantics(
            container: true,
            label: l.sendRouteSemantics(name, sendContactedText(to)),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Sp.x2,
                  runSpacing: Sp.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name, style: ts.strong),
                    if (tag != null) EBadge(tag!, key: const ValueKey('send-route-tag')),
                  ],
                ),
                Text.rich(TextSpan(style: mono, children: where), key: const ValueKey('send-route-host')),
                if (torStarts) Text(l.sendRouteTorStarts, key: const ValueKey('send-route-tor-starts'), style: ts.small),
              ],
            ),
          ),
        ),
        if (change != null) ...[SizedBox(width: Sp.x2), change!],
      ],
    );
  }
}

/// Change on the method line: a menu of the contact's addresses, the method and the short
/// address each, the one in use checked; one the mode holds is greyed with the reason and
/// cannot be chosen. Arrows move, Enter picks, Esc closes.
class _AddressMenu extends StatelessWidget {
  const _AddressMenu({required this.name, required this.addresses, required this.current, required this.read, required this.held, required this.onPick});

  final String name;
  final List<String> addresses;
  final String current;
  final RecipientInput Function(String) read;
  final SendHold? Function(RecipientInput) held;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    // The menu's right edge on Change's, so it stays inside the form's column (never over the
    // Summary): a fixed width, placed from the button's bottom end.
    final width = 340.u;
    return MenuAnchor(
      consumeOutsideTap: true,
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        minimumSize: WidgetStatePropertyAll(Size(width, 0)),
        maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
      ),
      alignmentOffset: Offset(-width, Sp.x1),
      menuChildren: [
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x2, Sp.x3, Sp.x1),
          child: Text(l.sendRouteAddressesOf(name), style: ts.caption),
        ),
        for (final a in addresses)
          Builder(builder: (context) {
            final r = read(a);
            final hold = held(r);
            final on = a == current;
            final kind = r.isAddress ? sendMethodName(l, r) : a;
            return Semantics(
              checked: on,
              inMutuallyExclusiveGroup: true,
              child: MenuItemButton(
                key: ValueKey('send-address-$a'),
                onPressed: hold == null ? () => onPick(a) : null,
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(280.u, 52.u)),
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
                  backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.s3 : null),
                ),
                leadingIcon: Icon(_RouteLine.iconOf(r), size: Ctl.iconSm, color: hold == null ? c.dim : c.faint),
                trailingIcon: on ? Icon(EIcons.check, size: Ctl.iconSm, color: c.ok) : SizedBox(width: Ctl.iconSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(kind, style: ts.strong.copyWith(color: hold == null ? null : c.faint)),
                    Text(shortAddress(r.isAddress ? r.address : a, compact: true), style: ts.mono(size: Fs.xs, color: hold == null ? c.dim : c.faint)),
                    if (hold != null) Text(sendHoldReason(l, hold), style: ts.small.copyWith(color: c.faint, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            );
          }),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
        child: EButton.ghost(
          key: const ValueKey('send-route-change'),
          label: l.sendRouteChange,
          size: EBtnSize.inline,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// A picked contact in To: the initial, the name and Clear. The method line under it says
/// which of the contact's addresses is used.
class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.contact, required this.onClear});

  final Contact contact;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Container(
      key: const ValueKey('send-picked'),
      constraints: BoxConstraints(minHeight: Ctl.md),
      padding: EdgeInsetsDirectional.only(start: Sp.x2, end: Sp.x1),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineField)),
      child: Row(
        children: [
          EAvatar(contact.name, size: 28.u),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Semantics(
              label: l.deskSaToContactSem(contact.name),
              excludeSemantics: true,
              child: Text(contact.name, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(width: Sp.x2),
          EIconButton(key: const ValueKey('send-to-clear'), icon: EIcons.close, label: l.deskSendClearTo, size: EBtnSize.inline, onPressed: onClear),
        ],
      ),
    );
  }
}

/// The file form's line in To's place: Direct · File Transfer, what it does, and the way back
/// to sending to an address.
class _FileLine extends StatelessWidget {
  const _FileLine({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    return Row(
      key: const ValueKey('send-file-line'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodGlyph(EIcons.file),
        SizedBox(width: Sp.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MethodIcons.fullName(l, MethodKind.directFile), style: ts.strong),
              Text(l.deskSendFileLine1, style: ts.small),
            ],
          ),
        ),
        SizedBox(width: Sp.x2),
        EButton.ghost(key: const ValueKey('send-file-back'), label: l.deskSaToAddress, icon: EIcons.send, size: EBtnSize.inline, onPressed: onBack),
      ],
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
      decoration: c.well,
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

  /// The address a pick fills in (Send's first by [bestAddressIndex]), shown on its row.
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
        constraints: BoxConstraints(maxWidth: Max.dialog),
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
                child: EInkWell(
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
  const _ReviewDialog({required this.draft, required this.onConfirm, this.compact = false, this.startBusy = false, this.checkPassword, this.recheck});

  /// Shallow: the page was the review, so the dialog only asks the password (and still says a
  /// fee that moved or a server the app does not know).
  final bool compact;

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

  /// The address to check: [EAddress]'s marking for every kind, an Epicbox key's or an
  /// onion's first and last six, a link's host:port, so "Check the highlighted characters"
  /// is true for each.
  Widget _address(BuildContext context, String to) => EAddress(to, copy: false);

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
    final route = d.route;
    // The payee's words under the facts; the name not when the contact has it.
    final codeLabel = EPayeeClaims.labelBeside(code?.label, d.contactName);
    // A Direct payment from a code: the host on its own line, where a look-alike shows (§7.3).
    final directHost = code != null && d.to != null && (d.method == TxMethod.http || d.method == TxMethod.tor) ? directHostBesideOf(d.to!) : null;
    final sum = d.summary;
    final lines = sum == null ? null : reviewOutputLines(l, sum, strategy: d.strategy, defaultStrategy: d.defaultStrategy, blocks: d.confirmations, extraFee: d.extraFee, usesAll: l.deskSendUsesAll);
    return EDialog(
      size: DialogWidth.wide,
      title: widget.compact ? l.deskLvSendPasswordTitle : l.deskSendReviewTitle,
      icon: EIcons.send,
      description: widget.compact ? l.deskLvSendNothingLeaves : l.deskSendReviewDesc,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (code != null) ...[
            Row(children: [EBadge(originText(l, code.origin), key: const ValueKey('send-review-origin'), icon: codeOriginIcon(code.origin))]),
            SizedBox(height: Sp.x3),
          ],
          if (widget.compact) ...[
            Text(
              keepNumbersWithUnits(d.contactName == null ? l.deskLvSendButtonAmount(formatEpicL(l, d.amount, decimals: exactDecimals)) : l.deskLvSendButtonTo(formatEpicL(l, d.amount, decimals: exactDecimals), d.contactName!)),
              key: const ValueKey('send-compact-line'),
              style: ts.strong,
            ),
            // An address with no name behind it: the characters to check stay in view.
            if (d.contactName == null && d.to != null) ...[
              SizedBox(height: Sp.x2),
              _address(context, d.to!),
              SizedBox(height: Sp.x1),
              Text(l.deskSendCheckChars, style: ts.caption),
            ],
          ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // The exact amount in the data face, as every amount but the balance headline.
              Flexible(child: Text(formatEpicL(l, d.amount, decimals: exactDecimals), style: ts.mono(size: Fs.h1, weight: FontWeight.w600).copyWith(height: 1.2))),
              SizedBox(width: Sp.x2),
              Text(epicUnit, style: ts.mono(size: Fs.lg, color: c.dim)),
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
            // Via: the method, and whether their wallet has to be open.
            (
              l.sendFactVia,
              Column(
                key: const ValueKey('send-review-via'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route != null && route.isAddress ? sendMethodName(l, route) : via, style: ts.body),
                  if (d.method != TxMethod.file) Text(d.method == TxMethod.epicbox ? l.sendFactOffline : l.sendFactOnline, style: ts.small),
                ],
              ),
            ),
            if (route != null && route.isUrl) (l.sendFactHost, SelectableText(route.contacted, key: const ValueKey('send-review-contacted'), style: ts.mono(size: Fs.sm, color: c.text))),
            // Plain http to another device: a fact, not a warning; the review is the consent.
            if (route != null && route.plainHttpToOther) (l.sendFactConnection, Text(l.sendFactNotEncrypted, key: const ValueKey('send-review-plain'), style: ts.body)),
            if (d.torStarts) (l.sendFactTor, Text(l.sendFactTorStarts, style: ts.body)),
            (
              l.deskSendNetworkFee,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EMoney(d.fee, surface: AmountSurface.exact),
                  if (lines?.feeSecondLine != null) Text(lines!.feeSecondLine!, style: ts.small),
                ],
              ),
            ),
            (l.deskSendTotal, EMoney(d.total, surface: AmountSurface.exact, weight: FontWeight.w600)),
            ...?lines?.facts,
            if (DeskFeatures.dandelion && d.method != TxMethod.file) (l.deskSendFactPrivacy, Text(d.dandelion ? l.deskSendDandelionOn : l.deskSendDandelionOff, style: ts.body)),
            if (d.message.isNotEmpty) (l.deskSendFactMessage, Text(d.message, style: ts.body)),
          ], labelWidth: 100.u),
          ],
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
              text: keepNumbersWithUnits(l.deskSendFeeChangedText(formatEpicL(l, d.fee, decimals: exactDecimals), formatEpicL(l, _feeWas!, decimals: exactDecimals))),
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
      // Pinned under the facts: its focus never scrolls the amount and the recipient away.
      // Enter in the password sends once it is filled.
      foot: _asks && !_busy
          ? EForm(
              onSubmit: _ready ? _go : null,
              child: EField(
                label: l.deskSendPassword,
                help: l.deskSendPasswordHelp,
                error: _wrong,
                child: EPasswordInput(
                  semanticsId: TrustIds.sendPassword,
                  controller: _password,
                  autofocus: true,
                  invalid: _wrong != null,
                  onChanged: (_) => setState(() => _wrong = null),
                ),
              ),
            )
          : null,
      actions: [
        EButton(label: l.deskSendBack, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(semanticsId: TrustIds.sendConfirm, label: _busy ? l.deskSendSending : (d.queued ? l.sendQueue : (widget.compact ? l.deskLvSendConfirm : keepNumbersWithUnits(l.deskSendConfirm(formatEpicL(l, d.amount, decimals: exactDecimals))))), icon: EIcons.send, busy: _busy, onPressed: _ready ? _go : null),
      ],
    );
  }
}

