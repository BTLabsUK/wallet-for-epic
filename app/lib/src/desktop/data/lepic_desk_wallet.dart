// SPDX-License-Identifier: Apache-2.0
/// [DeskWalletApi] over the app's wallet core ([WalletService], LEPIC on a computer).
///
/// Desktop wallets are password wallets, as in the Electron wallet: no PIN vault. Several
/// named wallets of one network (mainnet), listed in the [registry]: the first one at
/// `<app support>/wallets/<chain>` ([WalletDirResolver]) with a null [core.WalletConfig.walletId],
/// as 0.1.0 made it, each later one at `<app support>/wallets/<id>/<chain>` with walletId = id
/// ([reg.WalletRegistry.firstWalletDir], [reg.WalletRegistry.walletDirOf]).
/// Each wallet's own data (name, scan due, favourites) is saved under its own keys
/// ([DeskStore.walletMetaKey], [DeskStore.favouritesKeyOf]), the first wallet's unchanged from
/// 0.1.0. The node and Epicbox server are shared by all wallets of the network, saved under the
/// phone's keys (`NetworkChoiceNotifier`), so both UIs agree.
///
/// While unlocked the adapter keeps the session, the password (to reopen the wallet when the
/// node or the Epicbox server changes; never logged, dropped on lock), the last summary and
/// transactions, the node's tip and the listener's state. Background work (sync, node checks,
/// listener events) fires [changes]; [status] reads the fields.
library;

export 'desk_errors.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../../data_folder_io.dart' show appDataDirectory;

import '../../address_format.dart' show shortAddress;
import '../../advanced.dart' show NetworkMode;
import '../../btlabs_keys.dart' show btlabsKeyring;
import '../../first_run_servers.dart' show firstRunServersSettled;
import '../../devices/device_history.dart' show mergeDeviceHistory;
import '../../devices/device_model.dart' show DeviceBook;
import '../../devices/device_service.dart' show DeviceHost, ForwardKind, ForwardedNotice, SessionDeviceHost;
import '../../name_service/name_service_service.dart' show ListingDrain, NameServiceHost, SessionNameServiceHost, netOfChain;
import '../../name_service/verify.dart' show NameServiceVerifier;
import '../../name_service/receipts.dart' show LinkPaymentRecords;
import '../../devices/device_store.dart' show DeviceStore;
import '../../btlabs_onions.dart';
import '../../btlabs_public.dart';
import '../../builtin_node.dart';
import '../../legacy/gui_contacts.dart' show AddressChecks;
import '../../legacy/gui_rules.dart' show cleanGuiLabel;
import '../../legacy_gui_profile.dart' as gui;
import '../../legacy_wallets.dart' as legacy;
import '../../l10n.dart' show AppLocalizations;
import '../desk_l10n.dart' show deskStrings;
import '../../log.dart';
import '../../onion_notice.dart' show markOnionNoticeSeen;
import '../../node/node_settings.dart' show NodeSettings;
import '../../name_service/name_service.dart' show NameServiceMembership, LinkOutcome, Payreq, openLink;
import '../../name_service/base58.dart' show netFloonet, netMainnet;
import '../../scan/scan_router.dart' show PaymentLink;
import '../../message_checks.dart' show MessageChecks;
import '../../notice_digest.dart' show HeldKind, HeldNotice, raiseNotice;
import '../../models.dart' show Chain, Epic1Via;
import '../../known_relays.dart' show recipientRelay;
import '../../network.dart';
import '../../ui/network_mode_text.dart' show networkModeName;
import '../../network_gate.dart';
import '../../pairing_text.dart' show pairingName;
import '../../providers.dart' show WalletDirResolver, defaultMinimumConfirmations;
import '../../public_servers.dart';
import '../../net/http.dart' show NetError, httpGet;
import '../../net/tor_net.dart';
import '../../recipient.dart' show RecipientKind, parseRecipient;
import '../../send_route.dart' show plainHttpHeldNow;
import '../../net/tor_switch.dart';
import '../../tor_routes.dart';
import '../../relay_block.dart';
import '../../relay_directory.dart';
import '../../secret_store_api.dart';
import '../../server_list.dart' show ServerKind;
import '../../server_list_file.dart';
import '../../server_list_store.dart' show builtInRelaysFor;
import '../../settings_file/host_settings.dart' hide EpicboxServer, NodeServer;
import '../../settings_file/settings_providers.dart' show DevSettingsMissing, installedSettingsFile, openAppSettings, writeHostSettings;
import '../../seed_contacts.dart';
import '../../sender_cancel.dart' show SenderCancelRelease;
import '../../cancel_final.dart' show CancelFinal, CancelResult, cancelFinal, cancelSettled, cancelSpendsBack, cancelledMayComplete;
import '../../stall_retry.dart' show StallRetry, invoicePaymentStalled;
import '../../slate_files.dart' show decodeSlateFile, isSealedText, replyFileName, sealedFileName, sendFileName, uniqueFileName;
import '../../tor_location.dart';
import '../../updater.dart' show updateStateKey;
import '../../wallet_registry.dart' as reg;
import '../../watch_mode.dart' show BlockWait, BlockWatch, postingNow;
import '../../history/export.dart' show historyCsv, historyDamaged, historyNewer, historyOtherWallet;
import '../../settings.dart' show HistoryExportSnapshot;
import '../../trust/contact_trust.dart' show peerCompatRetention;
import '../../trust/policy.dart' show PeerCompat;
import '../../epic1.dart' show Epic1Wallet, Epic1Of;
import '../../boosts.dart' show Boosts, PollDriver, Poller;
import '../../wallet_service.dart' as core;
import '../../wallet/held_coins.dart';
import '../../wallet/stored_send.dart';
import '../../wallet/upkeep.dart';
import 'addresses.dart';
import 'api.dart';
import 'backup_reminder.dart';
import 'backup_settings_desk.dart';
import 'desk_errors.dart';
import 'desk_store.dart';
import 'desk_update.dart' show deskAppVersion;
import 'features.dart';
import 'gui_contact_import.dart';
import 'http_address.dart';
import 'invoice_scheduler.dart';
import 'invoices.dart';
import 'models.dart';
import 'node_view.dart' show startFailureLine;
import 'phrase_check.dart' show phraseFingerprint;
import 'remember.dart';

/// The public nodes of the shipped settings, offered in Settings › Node in its order; the status
/// site can add more.
List<NodeServer> get deskPublicNodes => [
  for (final n in builtInNodes) NodeServer(url: n.url, label: n.operator, operator: n.operator, health: ServiceHealth.checking),
];

/// The public Epicbox servers of the shipped settings, in its order; the status site can add
/// more.
List<EpicboxServer> get deskEpicboxes => [
  for (final r in builtInRelays) EpicboxServer(domain: r.relay.host, port: r.relay.port, operator: r.operator, health: ServiceHealth.checking),
];

/// A call LEPIC ended at a lock; its effect may still be stored.
bool lepicCancelled(Object error) => error is core.WalletError && error.kind == core.WalletErrorKind.cancelled;

DeskError _deskError(Object error) {
  final kind = error is core.WalletError ? error.kind : null;
  return DeskError.l10n(
    (l) => deskErrorText(error, l),
    wrongPassword: kind == core.WalletErrorKind.wrongPassword,
    unbuildable: kind == core.WalletErrorKind.invalidArgument && (error as core.WalletError).message == core.sendUnbuildable,
    nothingToMerge: kind == core.WalletErrorKind.invalidArgument && (error as core.WalletError).message == core.nothingToConsolidate,
    notEnoughFunds: kind == core.WalletErrorKind.notEnoughFunds,
    nodeUnreachable: kind == core.WalletErrorKind.nodeUnreachable,
    unsupported: kind == core.WalletErrorKind.unsupported,
  );
}

class LepicDeskWallet implements DeskWalletApi {
  LepicDeskWallet({
    required this._service,
    required this._walletDir,
    required this._secrets,
    required this._filesDir,
    this.relayDirectory,
    this.nodeDirectory,
    this._preset = mainnetPreset,
    this._settings = const DeskSettings(),
    BigInt? minimumConfirmations,
    Duration? nodePoll,
    Duration? nodeRecheck,
    Duration? nodeStale,
    Duration? nodeTimeout,
    Duration? nodeTorTimeout,
    this.torNodeGrace = const Duration(minutes: 2),
    this.torRetryAfter = const Duration(seconds: 60),
    List<Duration>? torStartBackoff,
    this.closeWait = const Duration(seconds: 30),
    reg.WalletRegistry? registry,
    this._builtInNode,
    legacy.LegacyRoots Function()? legacyRoots,
    this._pickDirectory,
    this._listProcesses,
    this._torBundle,
    bool? torFeature,
    bool torSwitch = false,
    Future<Directory> Function()? rememberDir,
    DateTime Function()? now,
    this._seedFetch,
    Keyring? keyring,
    OnionDirectory? onions,
    this.paymentsEvery = const Duration(seconds: 60),
    HttpReachCache? httpReach,
  }) : nodePoll = nodePoll ?? appConfig.nodePoll,
       nodeRecheck = nodeRecheck ?? appConfig.nodeRecheck,
       nodeStale = nodeStale ?? appConfig.nodeStaleAfter,
       nodeTimeout = nodeTimeout ?? appConfig.nodeCheckTimeout,
       nodeTorTimeout = nodeTorTimeout ?? appConfig.nodeTorCheckTimeout,
       torStartBackoff = torStartBackoff ?? appConfig.torStartBackoff,
       _reach = httpReach ?? HttpReachCache(),
       _keyring = keyring ?? btlabsKeyring,
        onions = onions ?? OnionDirectory(),
        _torFeature = torFeature ?? DeskFeatures.tor,
        _torSaved = torSwitch,
       _legacyRoots = legacyRoots ?? legacy.LegacyRoots.current,
       _minConfFallback = minimumConfirmations ?? BigInt.from(defaultMinimumConfirmations),
       _registryGiven = registry,
       _remember = RememberedPasswords(
         secrets: _secrets,
         dir: rememberDir ?? () async => Directory('${(await appDataDirectory()).path}${Platform.pathSeparator}remember'),
         now: now,
       ) {
    statusSite.addListener(_statusSiteChanged);
    NetGate.set(_settings.advanced.networkMode);
    NetGate.setPayments(_settings.payments);
    NetGate.setExperimental(_settings.advanced);
    _followTor();
  }

  /// Whether the wallet of [config] opens with the Tor switch on: its session then waits for
  /// tor from the first connection, also when no tor bundle is found (blocked, never direct).
  /// `main_desktop.dart` hands it to the wallet core (`wantTorAtOpen`).
  Future<bool> torWantedAt(core.WalletConfig config) async =>
      _torFeature &&
      !NetGate.killSwitch &&
      (NetGate.torOnly || (await _store.torSwitch() ?? (await _store.autostart(config.walletId)).tor));

  /// Passwords remembered on this computer, per wallet.
  final RememberedPasswords _remember;

  /// The public IP and port check for HTTP From the internet.
  final HttpReachCache _reach;

  /// Whether this build offers Tor ([DeskFeatures.tor]); tests turn it on.
  final bool _torFeature;

  /// The Tor switch as saved ([DeskSettings.torAutostart]), known from launch: while it is on
  /// and tor is not running yet (locked, or unlocked before tor starts), the app's own
  /// requests wait for tor instead of going directly.
  bool _torSaved;

  final core.WalletService _service;
  final WalletDirResolver _walletDir;
  final SecretStore _secrets;
  late final DeskStore _store = DeskStore(_secrets);
  final Future<Directory> Function() _filesDir;

  /// The network in use: mainnet, or the test network a dev build chose ([useNetwork]).
  NetworkPreset get preset => _preset;
  NetworkPreset _preset;

  /// Where [useNetwork] keeps its choice for the next start ([savedPreset]).
  static const String networkKey = 'desk.network';

  /// The network a dev build chose last time ([useNetwork]); mainnet when none.
  static Future<NetworkPreset> savedPreset(SecretStore secrets) async {
    final name = await secrets.read(networkKey);
    return networkPresets.where((p) => p.chain.name == name).firstOrNull ?? mainnetPreset;
  }

  @override
  String get network => _preset.chain.name;

  @override
  Future<void> useNetwork(String network) async {
    final next = networkPresets.where((p) => p.chain.name == network).firstOrNull ?? mainnetPreset;
    if (next.chain == _preset.chain) return;
    if (_session != null) throw DeskError.l10n((l) => l.deskErrWalletLocked);
    // The network's own settings file: its lists, node and Epicbox server. A dev chain without
    // one does not start (DevSettingsMissing names the file and the script).
    try {
      // Without a settings file open (tests, the mock), the settings in use stay.
      if (installedSettingsFile != null) await openAppSettings(store: _secrets, devChain: devChainOf(next.chain));
    } on DevSettingsMissing catch (e) {
      // A dev build only, in English: the message names the file and the script.
      throw DeskError('$e');
    }
    _preset = next;
    _registry = null;
    _dirNodes = null;
    _dirNodesAt = null;
    _boxes = null;
    _boxesAt = null;
    _boxesFailedAt = null;
    await _secrets.write(networkKey, network);
    _changed();
  }

  /// Epicbox server health from the status site; null leaves it unknown.
  final RelayDirectory? relayDirectory;
  List<EpicboxServer>? _boxes;
  DateTime? _boxesAt;
  /// When reading the relay list last failed: not read again for a while, so a blocked or
  /// failing read is not repeated by every caller.
  DateTime? _boxesFailedAt;

  /// When [_importHistoryOnce] last read each wallet's old database (by meta key).
  final Map<String, DateTime> _historyTried = {};

  /// What the old wallet's history waits for: the sender or method it records against what the
  /// user typed, with the wallet's meta key and old folder. Asked once the shell shows it.
  ({String key, String from, List<ImportConflict> conflicts})? _oldHistoryAsk;

  /// Wallets whose choices the user postponed (Cancel): not asked again until the app restarts.
  final Set<String> _oldHistoryHeld = {};

  /// Public nodes from the status site; null keeps the built-in list.
  final NodeDirectory? nodeDirectory;
  List<NodeStatus>? _dirNodes;
  DateTime? _dirNodesAt;
  bool _dirNodesLoading = false;
  final Set<String> _checking = {};
  final BigInt _minConfFallback;

  /// The confirmations sends, estimates and the list count with: the balance's own (LEPIC's),
  /// so Send spends exactly what the balance calls spendable; before a balance, the fallback.
  BigInt get _minConf {
    final counted = _summary?.minimumConfirmations;
    return counted != null && counted > BigInt.zero ? counted : _minConfFallback;
  }
  final Duration nodePoll;

  /// How old the node list's checks may get before the list asks every node again.
  final Duration nodeRecheck;

  /// A check older than this gives no height: the list says nothing about "behind" rather
  /// than compare a stale height with a fresh one.
  final Duration nodeStale;

  final Duration nodeTimeout;

  /// How long a node may take over Tor: LEPIC's own node timeout there, as a first onion
  /// circuit can take most of a minute.
  final Duration nodeTorTimeout;

  /// After tor connects, how long a failed node check over Tor is not counted: the first
  /// circuits are still being built.
  final Duration torNodeGrace;

  /// How long tor may connect before Retry is offered beside "Connecting to Tor…".
  final Duration torRetryAfter;

  /// A start that failed before connecting is tried again after each of these, by itself,
  /// before "failed" and Retry show.
  final List<Duration> torStartBackoff;

  /// How long closing the app waits for a payment under way before it locks anyway.
  final Duration closeWait;

  /// How often the payments address is drained while an issued invoice waits and the
  /// listener is off ([InvoiceScheduler]).
  final Duration paymentsEvery;

  /// Makes the built-in node of a network (desktop builds with the bundled `epic`); null
  /// where there is none.
  final Future<BuiltInNode> Function(core.Chain chain)? _builtInNode;
  BuiltInNode? _node;
  DeskSettings _settings;

  /// Finds the bundled tor (`tor_location.dart`); null, or an answer of null, is a build
  /// without it: Tor cannot be turned on.
  final Future<TorBundle?> Function()? _torBundle;
  Future<TorBundle?>? _torBundleFound;
  Future<TorBundle?> _findTor() => _torBundleFound ??= _torBundle?.call() ?? Future<TorBundle?>.value();

  core.WalletSession? _session;
  core.WalletConfig? _config;

  /// Kill switch: nothing may ask the node (Node only asks only it).
  bool get _nodeOff => NetGate.killSwitch;
  String? _password;

  /// Every move of the wallet's node runs alone, in call order ([_nodeLock]): the user's picks,
  /// the built-in node on and off, the fallback.
  Future<void> _nodeMoves = Future<void>.value();

  /// Set while [_switchTo] reopens the wallet: a send or a scan starting then waits for it.
  Completer<void>? _switching;

  /// The latest fallback decision ([applyNodeFallback]) and its number: an older one still
  /// queued is dropped.
  ({bool usePublic, String? publicUrl})? _fallback;
  int _fallbackSeq = 0;

  Future<T> _nodeLock<T>(Future<T> Function() move) {
    final r = _nodeMoves.then((_) => move());
    _nodeMoves = r.then<void>((_) {}, onError: (Object _) {});
    return r;
  }

  /// A scan counts as a running operation like a payment: the lock and the node moves wait.
  void _opEnded() {
    if (--_busy == 0) {
      _idle?.complete();
      _idle = null;
    }
  }

  final reg.WalletRegistry? _registryGiven;

  /// Where the import looks for old wallets; the real home folder in the app.
  final legacy.LegacyRoots Function() _legacyRoots;

  /// The system's folder dialog; null leaves "Choose a folder" with nothing to show.
  final Future<String?> Function()? _pickDirectory;
  final legacy.ProcessLister? _listProcesses;

  /// Old wallets of this import run by [OldWallet.id], and the wallets it made (list ids).
  final Map<String, legacy.LegacyWallet> _old = {};
  final List<String> _imported = [];
  Future<reg.WalletRegistry>? _registry;

  /// The wallet open now; null while locked.
  reg.WalletEntry? _openEntry;

  /// The wallet [unlock] opens; null is the one opened last.
  String? _selectedId;

  /// Bumped by [lock]: a session opened under an older value is closed at once.
  int _generation = 0;

  core.WalletSummary? _summary;
  List<core.TxEntry>? _entries;
  int _tip = 0;
  ServiceHealth _nodeHealth = ServiceHealth.checking;

  /// When the node last answered, to a tip check or a sync; a check over Tor failing soon
  /// after is not counted.
  DateTime? _nodeReachedAt;

  /// A tip check is under way: the poll does not start another.
  bool _tipBusy = false;

  /// When tor last connected; null while it is starting, restarting or off.
  DateTime? _torConnectedAt;

  /// The node's last answer said it is not ready for transactions: a sync that reached it
  /// does not turn that back into Online.
  bool _nodeNotReady = false;
  ServiceHealth _epicboxHealth = ServiceHealth.off;

  /// Counts the listener's refused handshakes (relay_block.dart); [_epicboxBlocked] once the
  /// network is shown to block the relay. Steady until a connection, a stop or a switch of relay
  /// ([_clearBlocked]); the listener keeps trying by itself.
  final RelayBlockWatch _blockWatch = RelayBlockWatch();
  bool _epicboxBlocked = false;

  /// The relay to offer while blocked ([relayInstead]); null when none is left.
  EpicboxRelay? _blockedInstead;

  /// Relays this network blocked since the wallet opened: never offered again.
  final Set<EpicboxRelay> _blockedRelays = {};
  double? _syncProgress;
  DateTime? _lastUpdate;
  String? _notice;
  final Map<String, NodeServer> _checked = {};

  /// When each [_checked] node answered. Heights are compared across the list ("12 behind"):
  /// a check kept for good froze the others while a node checked later moved on.
  final Map<String, DateTime> _checkedAt = {};

  /// Whether each [_checked] node was asked through tor. A latency is shown only while the way
  /// is still the same: a direct figure never stands in for one over Tor.
  final Map<String, bool> _checkedOverTor = {};

  bool _overTorNow(String url) => TorSwitch.on && !isLoopbackUrl(Uri.tryParse(url) ?? Uri());

  bool _checkedSameWay(String url) => (_checkedOverTor[url] ?? false) == _overTorNow(url);

  StreamSubscription<core.ListenerEvent>? _listener;

  /// The HTTP listener's events while it runs or starts; its health and, when down, why.
  StreamSubscription<core.HttpListenerEvent>? _http;
  ServiceHealth _httpHealth = ServiceHealth.off;
  HttpProblem? _httpProblem;

  /// The port and reach the running HTTP listener started with.
  int? _httpPort;
  core.HttpExposure? _httpExposure;

  /// The wallet's tor while it runs or starts: its health, progress, whether sends work, and,
  /// when down or not published, why.
  StreamSubscription<core.TorEvent>? _tor;
  ServiceHealth _torHealth = ServiceHealth.off;
  int? _torProgress;
  String? _torProblem;
  bool _torCanSend = false;

  /// When this tor start began; null once it connected, failed or stopped.
  DateTime? _torStartedAt;

  /// The session was told tor comes ([_expectTor]): a stop with tor never started must end
  /// that wait. Without it no stray stopTor reaches a wallet that never wanted Tor.
  bool _torExpected = false;
  Timer? _torSlowTimer;

  /// Restarts run by itself since tor last connected ([torStartBackoff]): tor that did not
  /// start (its control connection failed), stalled on its first bootstrap (a cold Tor cache
  /// can sit at one percent past LEPIC's stall limit), or stopped or lost the network later.
  int _torStartRetries = 0;

  /// The open wallet's onion, `<56 characters>.onion`.
  String? _onion;

  /// The node poll, every [nodePoll] and faster while the node is boosted (watch_mode.dart);
  /// null when the node is not polled.
  PollDriver? _tipDriver;
  Future<void>? _syncing;
  bool _syncAgain = false;
  /// Why the last sync did not reach the node; null when it did.
  DeskError? _syncError;
  final _changes = StreamController<void>.broadcast();

  String get _chain => preset.chain.name;

  core.WalletSession get _open => _session ?? (throw DeskError.l10n((l) => l.deskErrWalletLocked));

  void _changed() {
    _followTor();
    _watchBlocks();
    if (!_changes.isClosed) _changes.add(null);
  }

  /// tor's SOCKS proxy for the app's own requests, from LEPIC's tor events; null while
  /// tor is not running.
  SocksProxy? _torSocks;

  void _takeSocks(int? port) {
    if (port != null) _torSocks = SocksProxy('127.0.0.1', port);
  }

  /// The app's own requests follow the Tor switch (tor_routes.dart, `TorNet.follow`).
  void _followTor() {
    final state = !_settings.tor
        ? (_torFeature && _torSaved ? TorState.starting : TorState.off)
        : switch (_torHealth) {
            ServiceHealth.down => TorState.failed,
            ServiceHealth.off => TorState.starting,
            ServiceHealth.checking when !_torCanSend => TorState.starting,
            _ => TorState.on,
          };
    TorNet.onions = _onionOf;
    TorNet.follow(state, proxy: _torSocks);
  }

  /// The onion for [host]:[port] from the signed list in use, else the settings file's.
  OnionTarget? _onionOf(String host, int port) {
    final e = onions.onionFor(host, port);
    return e == null ? torBuiltInOnion(host, port) : (onion: e.onion, port: e.onionPort, tls: e.tls);
  }

  /// Settings › Privacy › Use the status site changed: what the site gave is dropped (off) or
  /// read again (on); the lists reload.
  void _statusSiteChanged() {
    _dirNodes = null;
    _dirNodesAt = null;
    _boxes = null;
    _boxesAt = null;
    _boxesFailedAt = null;
    _changed();
  }

  // ---- Config and saved wallet data.

  /// The node every wallet uses: `node.use` of the settings file.
  Future<String> _nodeUrl() async => hostSettings.nodeUse;

  /// The public Epicbox servers of the network in use (its settings file's shipped list).
  List<EpicboxServer> get _builtInBoxes => deskEpicboxes;

  /// The Epicbox server every wallet uses: `epicbox.use` of the settings file. A wallet has no
  /// server of its own; a change moves every wallet's address ([applyUseChange]).
  Future<EpicboxRelay> _relay() async => _useRelay();

  EpicboxRelay _useRelay() {
    final use = hostSettings.epicboxUse;
    return EpicboxRelay.parse(use) ?? EpicboxRelay(host: use);
  }

  /// The config of [entry]; null is the first wallet. The first wallet's folder is exactly
  /// what [WalletDirResolver] answers, as in 0.1.0, and its walletId null.
  /// An added wallet's folder is always [reg.WalletRegistry.walletDirOf], rebuilt from its id:
  /// a folder written into wallets.json by hand is never opened.
  Future<core.WalletConfig> _configOf(reg.WalletEntry? entry, {String? nodeUrl, EpicboxRelay? relay}) async {
    // A fresh install's first wallet is made on the servers first run picked. A config for a
    // node named here (a node check, first run's own among them) does not wait.
    if (nodeUrl == null) await firstRunServersSettled();
    return _configOfNow(entry, nodeUrl: nodeUrl, relay: relay);
  }

  Future<core.WalletConfig> _configOfNow(reg.WalletEntry? entry, {String? nodeUrl, EpicboxRelay? relay}) async => preset.config(
    dataDir: entry == null || entry.isLegacy ? await _walletDir(preset.chain) : await _addedDir(entry),
    nodeUrl: nodeUrl ?? await _nodeUrl(),
    relay: relay ?? await _relay(),
    walletId: entry?.walletId,
  );

  Future<String> _addedDir(reg.WalletEntry entry) async {
    final root = reg.WalletRegistry.rootOf(await _walletDir(preset.chain), preset.chain);
    return reg.WalletRegistry.walletDirOf(root, entry.chain, entry.id);
  }

  /// The open wallet's config (the first wallet's while locked).
  Future<core.WalletConfig> _makeConfig({String? nodeUrl, EpicboxRelay? relay}) => _configOf(_openEntry, nodeUrl: nodeUrl, relay: relay);

  String _metaKey(String? walletId) => DeskStore.walletMetaKey(_chain, walletId);

  /// The saved data of the wallet with [walletId]; the open one by default.
  Future<Map<String, dynamic>> _meta([String? key]) async {
    final j = await _store.readJson(key ?? _metaKey(_openEntry?.walletId));
    return j is Map<String, dynamic> ? j : <String, dynamic>{};
  }

  /// Merges [changes] into the saved data under [key] (the open wallet's by default), after
  /// every write to that key before it: a read, merge and write never overlap another.
  Future<void> _setMeta(Map<String, Object?> changes, [String? key]) {
    final k = key ?? _metaKey(_openEntry?.walletId);
    return _metaTurn(k, () async => _store.writeJson(k, {...await _meta(k), ...changes}));
  }

  /// The last write to each meta key, so the next one waits for it ([_metaTurn]).
  final Map<String, Future<void>> _metaWrites = {};

  /// Runs [write] to the meta [key] once the writes to it before have ended, failed or not.
  Future<void> _metaTurn(String key, Future<void> Function() write) {
    final run = (_metaWrites[key] ?? Future<void>.value()).then((_) => write());
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _metaWrites[key] = tail;
    unawaited(tail.then((_) {
      if (identical(_metaWrites[key], tail)) _metaWrites.remove(key);
    }));
    return run;
  }

  String get _favouritesKey => DeskStore.favouritesKeyOf(_openEntry?.walletId);

  // ---- The wallet list.

  /// The desktop's wallet list, read once, with the wallet a 0.1.0 install made listed as the
  /// first one. The only way into the registry: Unlock, All wallets and the import all use it.
  Future<reg.WalletRegistry> registry() => _registry ??= _loadRegistry();

  Future<reg.WalletRegistry> _loadRegistry() async {
    try {
      final legacyDir = await _walletDir(preset.chain);
      final r = _registryGiven ?? reg.WalletRegistry(reg.WalletRegistry.rootOf(legacyDir, preset.chain));
      // Removed from the list only: it stays off until All wallets adds it back.
      final unlisted = await _firstUnlisted();
      await r.load(skipLegacy: unlisted ? {preset.chain} : const {});
      if (!unlisted) {
        try {
          await _adoptFirst(r);
        } on reg.WalletRegistryException catch (e) {
          // A list this version may not write (newer file): read-only, _wallets adds wallet 1.
          logWarn('desk', 'first wallet not listed: ${e.runtimeType}');
        }
      }
      return r;
    } on Object {
      _registry = null;
      rethrow;
    }
  }

  Future<bool> _firstUnlisted() async => (await _meta(_metaKey(null)))['unlisted'] == true;

  /// The first wallet as an entry that is not in the file.
  Future<reg.WalletEntry> _firstEntry(core.WalletConfig config) async => reg.WalletEntry(
    id: '${reg.WalletRegistry.legacyPrefix}$_chain',
    label: ((await _meta(_metaKey(null)))['name'] as String?) ?? 'Main wallet', // l10n-ok: the default name is stored with the wallet
    chain: preset.chain,
    dataDir: config.dataDir,
    createdAt: DateTime.now(),
  );

  /// Lists the first wallet when LEPIC finds one in its folder, under the name it had.
  Future<reg.WalletEntry?> _adoptFirst(reg.WalletRegistry r, {bool known = false}) async {
    final config = await _configOf(null);
    final added = await r.adoptLegacy(preset.chain, exists: (_) async => known || await _service.walletExists(config: config));
    if (added == null) return null;
    final name = (await _meta(_metaKey(null)))['name'];
    if (name is String) {
      try {
        return await r.rename(added.id, name);
      } on reg.WalletRegistryException {
        // An old name the list does not take; "Wallet 1" stays.
      }
    }
    return added;
  }

  /// [registry]'s wallets of this network, or null when the list cannot be read.
  Future<List<reg.WalletEntry>?> _inList() async {
    try {
      return [for (final e in (await registry()).list()) if (e.chain == preset.chain) e];
    } on Object catch (e) {
      logWarn('desk', 'wallet list not readable: ${e.runtimeType}');
      return null;
    }
  }

  /// Without a readable list, the first wallet alone, as 0.1.0 showed it: it always opens.
  Future<List<reg.WalletEntry>> _wallets() async {
    final listed = await _inList();
    final legacyId = '${reg.WalletRegistry.legacyPrefix}$_chain';
    if (listed != null && listed.any((e) => e.id == legacyId)) return listed;
    // Not listed (a list this version cannot write, or unreadable): the first wallet still
    // opens, unless it was taken off the list on purpose.
    if (await _firstUnlisted()) return listed ?? const [];
    final config = await _configOf(null);
    if (!await _service.walletExists(config: config)) return listed ?? const [];
    return [await _firstEntry(config), ...?listed];
  }

  /// The wallet [unlock] opens: the open one, else the selected one, else the one opened last.
  reg.WalletEntry? _pick(List<reg.WalletEntry> all, String? lastUsed) {
    for (final id in [_openEntry?.id, _selectedId, lastUsed]) {
      final e = all.where((e) => e.id == id).firstOrNull;
      if (e != null) return e;
    }
    return all.firstOrNull;
  }

  Future<String?> _lastUsed() async => _registry == null ? null : (await _registry!).lastUsedId;

  Future<reg.WalletEntry> _entry(String id) async =>
      (await _wallets()).where((e) => e.id == id).firstOrNull ?? (throw DeskError.l10n((l) => l.deskErrWalletNotListed));

  DeskError _listError(reg.WalletRegistryException e) => e is reg.WalletRegistryVersionException
      ? DeskError.l10n((l) => l.deskErrUpdateApp)
      : e is reg.WalletNotListedException
      ? DeskError.l10n((l) => l.deskErrWalletNotListed)
      : e.message.isEmpty ? DeskError.l10n((l) => l.deskErrListNotChanged) : DeskError('${e.message[0].toUpperCase()}${e.message.substring(1)}');

  @override
  Future<List<WalletEntry>> wallets() async {
    final all = await _wallets();
    final open = _openEntry;
    final current = open != null && all.any((e) => e.id == open.id) ? open : _pick(all, await _lastUsed());
    final missing = _registry == null ? null : await _registry!;
    return [
      for (final e in all)
        WalletEntry(
          id: e.id,
          name: e.label,
          folder: e.isLegacy ? (await _configOf(null)).dataDir : e.dataDir,
          network: _chain,
          current: e.id == current?.id,
          lastOpened: e.lastOpenedAt ?? (e.isLegacy ? _time((await _meta(_metaKey(null)))['opened']) : null),
          missing: missing != null && missing.folderMissing(e),
        ),
    ];
  }

  @override
  Future<bool> setupPending(String id) async {
    final e = await _entry(id);
    if ((await _meta(_metaKey(e.walletId)))['setupPending'] != true) return false;
    return !File(await _setupDoneFile(e)).existsSync();
  }

  @override
  Future<void> setSetupPending(String id, bool pending) async {
    final e = await _entry(id);
    final done = File(await _setupDoneFile(e));
    if (pending && done.existsSync()) await done.delete();
    try {
      await _setMeta({'setupPending': pending}, _metaKey(e.walletId));
    } on Object catch (error) {
      if (pending) rethrow;
      // The store refused: a file in the wallet's folder says the setup was done or
      // skipped, so a store that keeps failing does not bring Setup back at every start.
      logWarn('desk', 'setup mark not cleared in the store: ${error.runtimeType}; noted in the wallet folder');
      await done.writeAsString('', flush: true);
    }
  }

  /// [setupPending]'s second answer, when the store could not clear the mark.
  Future<String> _setupDoneFile(reg.WalletEntry e) async =>
      '${e.isLegacy ? (await _configOf(null)).dataDir : e.dataDir}${Platform.pathSeparator}$setupDoneFileName';

  /// The file [_setupDoneFile] writes into the wallet's folder.
  static const setupDoneFileName = 'SETUP-DONE';

  @override
  Future<bool> setupRestored(String id) async {
    final e = await _entry(id);
    return (await _meta(_metaKey(e.walletId)))['setupFlow'] == 'restored';
  }

  @override
  Future<void> setSetupRestored(String id) async {
    final e = await _entry(id);
    await _setMeta({'setupFlow': 'restored'}, _metaKey(e.walletId));
  }

  @override
  Future<void> selectWallet(String id) async {
    await _entry(id);
    _selectedId = id;
  }

  @override
  Future<void> renameWallet(String id, String label) async {
    final r = await registry();
    final reg.WalletEntry entry;
    try {
      entry = await r.rename(id, label);
    } on reg.WalletRegistryException catch (e) {
      throw _listError(e);
    }
    await _setMeta({'name': entry.label}, _metaKey(entry.walletId));
    if (_openEntry?.id == id) _openEntry = entry;
    await writeWalletTxt(
      entry.isLegacy ? (await _configOf(null)).dataDir : entry.dataDir,
      label: entry.label,
      network: _chain,
      created: _time((await _meta(_metaKey(entry.walletId)))['created']) ?? DateTime.now(),
    );
  }

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    final r = await registry();
    final entry = r.byId(id);
    if (entry == null || entry.chain != preset.chain) throw DeskError.l10n((l) => l.deskErrWalletNotListed);
    final open = _session != null && _openEntry?.id == id;
    // Deleting asks for the wallet's password, so only the open wallet can be deleted.
    if (mode == WalletRemoval.delete && !open) throw DeskError.l10n((l) => l.deskErrOpenToDelete);
    if (open) {
      if (mode == WalletRemoval.delete) {
        if (password == null || password.isEmpty) throw DeskError.l10n((l) => l.deskErrEnterPassword);
        final bool right;
        try {
          right = await _open.checkPassword(password: password);
        } on core.WalletError catch (e) {
          throw _deskError(e);
        }
        if (!right) throw DeskError.l10n((l) => l.deskErrWrongPassword, wrongPassword: true);
      }
    }
    final config = await _configOf(entry);
    try {
      // The wallet locks even when the removal fails, so the screen and the wallet agree.
      switch (mode) {
        case WalletRemoval.list:
          await r.forget(id);
          await _remember.forget(id);
          if (entry.isLegacy) await _setMeta({'unlisted': true}, _metaKey(null));
        case WalletRemoval.delete:
          // LEPIC deletes no folder a wallet still holds open: the wallet locks first (its
          // listeners, HTTP, Tor and any scan stopped), then the delete waits for the core to
          // let go of the folder.
          if (open) await lock();
          await _deleteWhenFree(r, id, config);
          await _remember.forget(id);
          final metaKey = _metaKey(entry.walletId);
          await _metaTurn(metaKey, () => _store.delete(metaKey));
          await _store.delete(DeskStore.favouritesKeyOf(entry.walletId));
          if (entry.walletId != null) {
            await _store.delete(DeskStore.httpKeyOf(entry.walletId));
          }
          await _store.delete(DeskStore.torKeyOf(entry.walletId));
          await _store.delete(DeskStore.outputsKeyOf(entry.walletId));
          await _store.delete(DeskStore.autostartKeyOf(entry.walletId));
          // Its linked devices, keyed as devices_state.dart keys them: by the list's id.
          await DeviceStore(_secrets, chain: _preset.chain == core.Chain.floonet ? core.Chain.floonet : core.Chain.mainnet, walletId: id).clear();
          await _removeWalletTxt(config.dataDir, legacy: entry.isLegacy);
      }
    } on reg.WalletRegistryException catch (e) {
      throw _listError(e);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    } finally {
      if (open) await lock();
    }
    if (_selectedId == id) _selectedId = null;
    logInfo('desk', 'wallet ${mode == WalletRemoval.list ? 'removed from the list' : 'deleted'}');
  }

  /// WALLET.txt is the app's own file in a deleted wallet's folder ([writeWalletTxt]): it goes
  /// too, then the folders the registry kept for it, each only while empty.
  Future<void> _removeWalletTxt(String dir, {required bool legacy}) async {
    try {
      for (final name in ['WALLET.txt', 'WALLET.txt.tmp', setupDoneFileName]) {
        final f = File('$dir${Platform.pathSeparator}$name');
        if (!FileSystemEntity.isLinkSync(f.path) && f.existsSync()) await f.delete();
      }
      await Directory(dir).delete(); // only when empty
      if (!legacy) await Directory(dir).parent.delete();
    } on FileSystemException {
      // Not empty (wallet_data, other files) or already gone.
    }
  }

  /// Deletes [id] once the core has let go of its folder: a closed session and a stopped scan
  /// end on the core's side a moment after the lock, and until then LEPIC answers "busy".
  Future<void> _deleteWhenFree(reg.WalletRegistry r, String id, core.WalletConfig config) async {
    final until = DateTime.now().add(deleteWaitAtMost);
    while (true) {
      try {
        return await r.delete(id, service: _service, config: config);
      } on core.WalletError catch (e) {
        if (e.kind != core.WalletErrorKind.walletBusy || DateTime.now().isAfter(until)) rethrow;
        logInfo('desk', 'delete waits for the core to close the wallet');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// How long a delete waits for the core to close the wallet ([_deleteWhenFree]).
  @visibleForTesting
  static Duration deleteWaitAtMost = const Duration(seconds: 30);

  @override
  Future<List<WalletEntry>> findRemoved() async {
    final r = await registry();
    final first = await _configOf(null);
    return [
      if (r.byId('${reg.WalletRegistry.legacyPrefix}$_chain') == null && await _service.walletExists(config: first))
        WalletEntry(
          id: '${reg.WalletRegistry.legacyPrefix}$_chain',
          name: ((await _meta(_metaKey(null)))['name'] as String?) ?? 'Wallet 1', // l10n-ok: the default name is stored with the wallet
          folder: first.dataDir,
          network: _chain,
        ),
      for (final e in await r.rescan())
        if (e.chain == preset.chain)
          WalletEntry(id: e.id, name: ((await _meta(_metaKey(e.walletId)))['name'] as String?) ?? e.label, folder: e.dataDir, network: _chain),
    ];
  }

  @override
  Future<void> addBack(String id) async {
    final r = await registry();
    try {
      if (id == '${reg.WalletRegistry.legacyPrefix}$_chain') {
        await _setMeta({'unlisted': false}, _metaKey(null));
        await _adoptFirst(r);
        return;
      }
      final found = (await r.rescan()).where((e) => e.id == id).firstOrNull;
      if (found == null) throw DeskError.l10n((l) => l.deskErrFolderNotFound);
      final added = await r.restore(found);
      final name = (await _meta(_metaKey(added.walletId)))['name'];
      if (name is String) await r.rename(added.id, name);
    } on reg.WalletRegistryException catch (e) {
      throw _listError(e);
    }
  }

  // ---- Opening a wallet.

  @override
  Future<bool> unlock(String password, {bool remember = false}) => _unlock(password, remember: remember);

  @override
  Future<bool> unlockRemembered() async {
    final entry = _pick(await _wallets(), await _lastUsed());
    if (entry == null) return false;
    final password = await _remember.recall(entry.id);
    if (password == null) return false;
    final ok = await _unlock(password);
    if (!ok) await _remember.forget(entry.id);
    _openedRemembered = ok;
    logInfo('desk', ok ? 'unlocked with the remembered password' : 'remembered password refused');
    return ok;
  }

  @override
  Future<bool> isRemembered(String id) => _remember.isRemembered(id);

  bool _notRemembered = false;
  bool _openedRemembered = false;

  @override
  bool get notRemembered => _notRemembered;

  @override
  bool get openedRemembered => _session != null && _openedRemembered;

  @override
  MessageChecks? get messageChecks => _session?.checks;

  @override
  Future<LinkOutcome> openPaymentLink(PaymentLink link, {required NameServiceMembership membership, required int nowSeconds}) {
    final session = _open;
    return openLink(
      request: link.request,
      error: link.error,
      net: session.chain == Chain.mainnet ? netMainnet : netFloonet,
      nowSeconds: nowSeconds,
      verifier: _service.verifyListingSignature,
      membership: membership,
      memory: session.linkMemory(),
    );
  }

  @override
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId}) =>
      _open.recordLinkPayment(request, paidAt, txId: txId);

  @override
  LinkPaymentRecords linkPaymentRecords({void Function()? onChange}) => _open.linkPaymentRecords(onChange: onChange);

  @override
  Future<bool> checkPassword(String password) async {
    try {
      return await _open.checkPassword(password: password);
    } on core.WalletError catch (e) {
      if (e.kind == core.WalletErrorKind.wrongPassword) return false;
      throw _deskError(e);
    }
  }

  @override
  Future<void> forgetRemembered(String id) => _remember.forget(id);

  @override
  Stream<core.StoreMigrationProgress> get storeMigration => _service.storeMigrationProgress;

  /// Opens the selected wallet. [remember]: keep the password, forget it, or (null, for the
  /// remembered password itself) leave it and its expiry as they are.
  Future<bool> _unlock(String password, {bool? remember}) async {
    await lock();
    final all = await _wallets();
    final entry = _pick(all, await _lastUsed());
    if (entry == null) throw DeskError.l10n((l) => l.deskErrWalletNotFound);
    final ok = await _openEntryWith(entry, password);
    _notRemembered = false;
    _openedRemembered = false;
    if (!ok) {
      await _remember.failed(entry.id);
    } else if (remember == true) {
      _notRemembered = !await _remember.remember(entry.id, password);
    } else if (remember == false) {
      await _remember.forget(entry.id, quiet: true);
    } else {
      await _remember.succeeded(entry.id);
    }
    if (ok) _startOpenWallet();
    return ok;
  }

  Future<bool> _openEntryWith(reg.WalletEntry entry, String password) async {
    final config = await _configOf(entry);
    final metaKey = _metaKey(entry.walletId);
    core.WalletSession session;
    try {
      session = await _service.open(config: config, password: password);
    } on core.WalletError catch (e) {
      if (e.kind == core.WalletErrorKind.wrongPassword) return false;
      // The records do not open with this wallet's key: nothing was touched; Unlock words it in
      // the password's error slot and stays ready.
      if (e.kind == core.WalletErrorKind.wrongKey) rethrow;
      // The store holds no vault for a listed wallet (keychain entries removed): its files stay,
      // and its recovery phrase seals a new vault through Forgot password.
      if (e.kind == core.WalletErrorKind.walletNotFound) {
        logWarn('desk', 'the secret store holds no vault for this wallet');
        throw DeskError.l10n((l) => l.deskErrKeyMissing(entry.label), keyMissing: true);
      }
      if (e.kind != core.WalletErrorKind.damagedDatabase) throw _deskError(e);
      // LEPIC set the damaged database aside; opening again rebuilds it from the vault, and a
      // scan brings the funds back.
      logWarn('desk', 'wallet database damaged; rebuilding');
      _notice = deskStrings.deskErrDbDamaged;
      // A rebuild scans the whole chain: never from a start height kept since a restore.
      await _setMeta({'scanPending': true, 'scanFrom': null, 'historyOffer': true}, metaKey);
      try {
        session = await _service.open(config: config, password: password);
      } on core.WalletError catch (e2) {
        if (e2.kind == core.WalletErrorKind.wrongPassword) return false;
        throw DeskError.l10n((l) => l.deskErrDbDamagedDetail(deskErrorText(e2, l)));
      }
    }
    _session = session;
    _sessionRevision++;
    session.heldOutputs = _deviceHeld;
    // What the wallet learned about keys silent since: dropped on every open.
    unawaited(
      session
          .forgetPeers(olderThan: peerCompatRetention)
          .catchError((Object e) => logDebug('desk', 'peers not pruned: ${e.runtimeType}')),
    );
    // Every unlock asks the core whether a restore's scan is still owed, also for a wallet whose
    // app was closed before the scan-due note was written.
    _restoreFailed = false;
    _restoreUnfinished = false;
    _dueAfterHeight = null;
    _restoreDue = await _restoreFlag(session) || (await _meta(metaKey))['scanPending'] == true;
    await _routeEpicbox(session);
    if (!NetGate.restricted) unawaited(_resendUndelivered(session));
    _config = config;
    _password = password;
    _openEntry = entry;
    _selectedId = null;
    // The HTTP listener's reach, port and autostart are this wallet's own.
    final http = await _store.httpPrefs(entry.walletId);
    // Start with the wallet for Epicbox and Tor are the wallet's own as well. Tor itself is
    // off until startAutostart or the switch turns it on (DeskSettings.tor is the now-state).
    final autostart = await _store.autostart(entry.walletId);
    // The Tor switch is app-wide once set: a wallet never opens without Tor that was on.
    // Tor only: every wallet opens with it on (network_gate.dart).
    final torSwitch = NetGate.torOnly || (await _store.torSwitch() ?? autostart.tor);
    _settings = _settings.copyWith(
      publicMode: http.publicMode,
      httpPort: http.port,
      httpAutostart: http.autostart,
      httpReachAck: http.reachAck,
      tor: false,
      epicboxAutostart: autostart.epicbox,
      torAutostart: _torFeature && torSwitch,
    );
    _torSaved = torSwitch;
    // Tor starts with startAutostart, after the first node check and sync: those wait for it
    // instead of asking the node directly first, also when no tor bundle is found: the Tor
    // switch on never lets anything go out directly (the session opened waiting, torWanted).
    if (_settings.torAutostart) await _expectTor(session);
    await _setMeta({'opened': DateTime.now().millisecondsSinceEpoch ~/ 1000});
    await _seedContacts();
    if (entry.walletFingerprint == null) await _keepWalletFingerprint(entry, session);
    await _dropPhraseFingerprint(entry.id);
    try {
      if (_registry != null) _openEntry = await (await _registry!).markOpened(entry.id);
    } on Object catch (e) {
      logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
    }
    return true;
  }

  /// After an unlock: the node poll and the first sync. The receiving methods start with
  /// [startAutostart], each as its Start with the wallet says.
  /// Kill switch: only the wallet's own files are read; [_applyMode] starts the rest on leaving
  /// it. Node only asks the node in use and starts nothing else.
  void _startOpenWallet() {
    _torStartRetries = 0;
    if (_nodeOff) {
      unawaited(_loadLocal());
      return;
    }
    _startPoll();
    unawaited(_checkTip());
    unawaited(sync());
    if (!NetGate.epicboxOff) _startInvoices();
  }

  @override
  Future<void> startAutostart() async {
    final session = _open;
    // Kill switch starts nothing; Node only only the user's Tor switch, which carries the node.
    // Leaving them starts what Start with the wallet says.
    if (NetGate.killSwitch) return;
    if (NetGate.nodeOnly) {
      if (_torFeature && _settings.torAutostart) {
        _settings = _settings.copyWith(tor: true);
        _torStartRetries = 0;
        unawaited(_startTor());
      }
      return;
    }
    // Tor starts below: the first Epicbox connection waits for it, never going directly first,
    // also when no tor bundle is found: it then stays blocked instead of going directly.
    if (_torFeature && _settings.torAutostart) await _expectTor(session);
    // The Epicbox switch off (Settings › Transactions): no listener, whatever Start with the
    // wallet says.
    if (_settings.epicboxAutostart && _settings.payments.epicbox) {
      try {
        await setEpicboxListening(true);
      } on Object catch (e) {
        logWarn('desk', 'epicbox autostart: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    // Link · HTTP on (Settings › Transactions) starts the listener at unlock; it stays off
    // while Tor is on (tor_routes.dart, torStops).
    if (_settings.payments.linkHttp && !(_torFeature && _settings.torAutostart)) {
      try {
        await setHttpListening(true);
      } on Object catch (e) {
        logWarn('desk', 'http autostart: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    if (_torFeature && _settings.torAutostart) {
      _settings = _settings.copyWith(tor: true);
      _torStartRetries = 0;
      unawaited(_startTor());
    } else {
      await _syncTorPay();
    }
  }

  @override
  Future<void> lock() => _lock();

  /// One lock at a time: a second call joins the first. [waitAtMost]: how long a running
  /// payment may hold the lock up (the app closing); past it the lock goes ahead and the core
  /// ends the call. A scan is stopped first: it has no effect worth waiting for.
  Future<void> _lock({Duration? waitAtMost}) {
    void cap() {
      if (waitAtMost == null) return;
      _lockTimer?.cancel();
      _lockTimer = Timer(waitAtMost, () {
        final force = _lockForce;
        if (force != null && !force.isCompleted) {
          logWarn('desk', 'closing: a payment still ran after ${waitAtMost.inSeconds} s; locking anyway');
          force.complete();
        }
      });
    }

    final running = _lockRun;
    if (running != null) {
      cap();
      return running;
    }
    // Set before the first await: no payment starts meanwhile.
    _locking = true;
    _lockForce = Completer<void>();
    cap();
    return _lockRun = _runLock().whenComplete(() {
      _lockTimer?.cancel();
      _lockTimer = null;
      _lockForce = null;
      _lockRun = null;
      _locking = false;
    });
  }

  Future<void>? _lockRun;
  Completer<void>? _lockForce;
  Timer? _lockTimer;

  Future<void> _runLock() async {
    await _stopScanForUser();
    // The scan due since a restore stays due; left running it would hold the wallet's folder
    // after the lock, and a delete right after would find the wallet busy.
    if (_scanningDue) {
      try {
        _session?.cancelScan();
      } on core.WalletError catch (e) {
        logWarn('desk', 'stop due scan: ${e.kind.name}');
      }
    }
    // A send, finalize or split under way finishes first ([busy]); none starts meanwhile.
    if (_busy > 0) logInfo('desk', 'lock waits for $_busy call(s) under way');
    await Future.any<void>([whenIdle(), _lockForce!.future]);
    await _lockNow();
  }

  /// A balance scan can run for minutes and its effect is only a read: a lock or a node move
  /// the user asked for ends it instead of waiting.
  Future<void> _stopScanForUser() async {
    if (_rescanning) await stopRescan();
  }

  Future<void> _lockNow() async {
    _generation++;
    _stopPoll();
    _stopInvoices(forget: true);
    await _stopListener();
    await _stopHttp();
    await _stopTor();
    final session = _session;
    _session = null;
    _deviceHeld = const {};
    _password = null;
    _onion = null;
    // The next unlock offers the wallet that was open.
    _selectedId ??= _openEntry?.id;
    _openEntry = null;
    _config = null;
    _summary = null;
    _entries = null;
    _stall = StallRetry();
    _senderCancel = SenderCancelRelease();
    _cancels = CancelFinal();
    _cancelFinal = const {};
    _cancelSettled.clear();
    _syncProgress = null;
    _epicboxHealth = ServiceHealth.off;
    _clearBlocked();
    _blockedRelays.clear();
    session?.dispose();
  }

  /// Moves to [nodeUrl] and [relay]: saved under the phone's keys once the wallet opens on
  /// them, the listener kept as it was. When it does not open, the wallet opens again on the
  /// old ones and the error says so; when even that fails, the wallet locks
  /// ([DeskError.locked]). Locked: only saved. Callers hold [_nodeLock]; [_switching] is set
  /// before the first await: new payments and scans wait for the switch, those running end first.
  Future<void> _switchTo({required String nodeUrl, required EpicboxRelay relay, bool save = true}) async {
    // The mark comes first: no payment or scan starts from now on (the switch is preferred),
    // so a steady stream of them cannot hold it off. Those under way end, then it runs.
    final switching = _switching = Completer<void>();
    try {
      while (_busy > 0) {
        await whenIdle();
      }
      await _reopenOn(nodeUrl: nodeUrl, relay: relay, keep: save);
    } finally {
      _switching = null;
      switching.complete();
    }
  }

  /// [keep] false: the move is for this session only (node failover); nothing is saved.
  Future<void> _reopenOn({required String nodeUrl, required EpicboxRelay relay, bool keep = true}) async {
    // Every wallet's: the first of each list in the settings file.
    Future<void> save() async {
      if (!keep) return;
      final values = useServerValues(hostSettings, node: nodeUrl, relay: relay.label);
      if (values.isNotEmpty) await writeHostSettings(values);
    }

    final password = _password;
    final old = _config;
    if (_session == null || password == null || old == null) return save();
    final generation = _generation;
    final listening = _listener != null;
    final http = _http != null;
    final tor = _tor != null;
    final config = await _makeConfig(nodeUrl: nodeUrl, relay: relay);
    await _stopListener();
    await _stopHttp();
    await _stopTor();
    _stopInvoices();
    final polling = _tipDriver != null;
    _stopPoll();
    _session?.dispose();
    _session = null;
    // A lock() while opening wins: the new session closes at once.
    Future<bool> openOn(core.WalletConfig c) async {
      final session = await _service.open(config: c, password: password);
      if (generation != _generation) {
        session.dispose();
        return false;
      }
      _session = session;
      _sessionRevision++;
      if (polling) _startPoll();
      // The coins the linked devices hold stay held through the reopen.
      session.heldOutputs = _deviceHeld;
      _config = c;
      await _routeEpicbox(session);
      return true;
    }

    try {
      if (!await openOn(config)) return;
    } on Object catch (e) {
      logWarn('desk', 'reopen on the new server failed: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      if (generation != _generation) return;
      try {
        if (!await openOn(old)) return;
      } on Object catch (e2) {
        logWarn('desk', 'reopen on the old server failed: ${e2 is core.WalletError ? e2.kind.name : e2.runtimeType}');
        await lock();
        throw DeskError.l10n((l) => l.deskErrWalletClosed(deskErrorText(e2, l)), locked: true);
      }
      await _afterReopen(listening, http, tor);
      throw DeskError.l10n((l) => l.deskErrNotChanged(deskErrorText(e, l)));
    }
    await save();
    await _afterReopen(listening, http, tor);
  }

  Future<void> _afterReopen(bool listening, bool http, bool tor) async {
    _nodeHealth = ServiceHealth.checking;
    _startInvoices();
    final session = _session;
    if (tor && session != null) await _expectTor(session);
    if (listening) await setListening(true);
    if (http) await setHttpListening(true);
    if (tor) unawaited(_startTor());
    if (!tor) unawaited(_syncTorPay());
    unawaited(_checkTip());
    unawaited(sync());
  }

  // ---- First run.

  @override
  Future<List<String>> newPhrase({int words = 24}) =>
      throw UnsupportedError('the phrase comes from createWallet');

  void _checkPassword(String password) {
    if (!passwordLongEnough(password)) {
      throw DeskError.l10n((l) => l.deskErrPasswordShort(minPasswordLength));
    }
  }

  /// Where a new wallet goes: the first wallet's folder when this computer has none (a null
  /// entry), else a new list entry with its own folder. The open wallet stays open.
  Future<reg.WalletEntry?> _newWallet(String name, {bool ownEntry = false}) async {
    final label = name.trim().isEmpty ? null : name.trim();
    if (!ownEntry && (await _wallets()).isEmpty && !await _service.walletExists(config: await _configOf(null))) return null;
    try {
      return await (await registry()).add(chain: preset.chain, label: label);
    } on reg.WalletRegistryException catch (e) {
      throw _listError(e);
    }
  }

  /// Makes the wallet in [create] at [_newWallet]'s place, lists it and selects it. A wallet
  /// that was not made leaves no entry.
  /// [ownEntry]: always a new entry, never the first wallet's folder (imports).
  /// [walletFingerprintOf]: the core's fingerprint of the made wallet, kept in its list entry
  /// ([reg.WalletEntry.walletFingerprint]) so a later restore of the same phrase finds it.
  Future<T> _make<T>(
    String name,
    Map<String, Object?> meta,
    Future<T> Function(core.WalletConfig config) create, {
    bool ownEntry = false,
    String? Function(T result)? walletFingerprintOf,
  }) async {
    final entry = await _newWallet(name, ownEntry: ownEntry);
    final config = await _configOf(entry);
    final label = name.trim().isEmpty ? null : name.trim();
    final metaKey = _metaKey(entry?.walletId);
    // Written before the core makes the wallet: an app closed halfway still finds the scan
    // due at the next unlock.
    await _metaTurn(metaKey, () => _store.writeJson(metaKey, {'name': label, 'created': DateTime.now().millisecondsSinceEpoch ~/ 1000, ...meta}));
    final T result;
    try {
      result = await create(config);
    } on Object {
      if (entry != null) {
        await _unlist(entry);
      } else {
        await _unmakeFirst(config);
      }
      await _store.delete(metaKey);
      rethrow;
    }
    var listed = entry;
    if (entry == null) {
      try {
        final r = await registry();
        listed = await _adoptFirst(r, known: true) ?? r.byId('${reg.WalletRegistry.legacyPrefix}$_chain');
      } on Object catch (e) {
        logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
      }
    }
    _selectedId = listed?.id;
    // Made on this version: the notice about the changed Tor address is not for it.
    try {
      await markOnionNoticeSeen(_secrets, chain: _chain, walletId: listed?.walletId ?? entry?.walletId);
    } on Object catch (e) {
      logWarn('desk', 'onion notice marker not saved: ${e.runtimeType}');
    }
    await writeWalletTxt(config.dataDir, label: listed?.label ?? label ?? 'Main wallet', network: _chain, created: DateTime.now()); // l10n-ok: default wallet name, stored
    if (listed != null) {
      try {
        final r = await registry();
        final wallet = walletFingerprintOf?.call(result);
        if (wallet != null) await r.setWalletFingerprint(listed.id, wallet);
        await r.setLastUsed(listed.id);
      } on Object catch (e) {
        logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
      }
    }
    return result;
  }

  /// Takes back what the core wrote for a first wallet it did not finish making (a vault
  /// without its database, say), so the next start does not take it for a wallet. Only
  /// the first wallet's folder, which held no wallet before ([_newWallet]).
  Future<void> _unmakeFirst(core.WalletConfig config) async {
    try {
      await _service.deleteWallet(config: config);
      logInfo('desk', 'half-made first wallet removed');
    } on Object catch (e) {
      logWarn('desk', 'half-made first wallet not removed: ${e.runtimeType}');
    }
  }

  /// Takes back an entry whose wallet was not made: the entry, a half-made `lepic` folder
  /// (through the registry's checked delete path), and the folders while empty.
  Future<void> _unlist(reg.WalletEntry entry) async {
    try {
      final r = await registry();
      try {
        await r.delete(entry.id, service: _service, config: await _configOf(entry));
        return;
      } on Object catch (e) {
        logWarn('desk', 'half-made wallet folder not removed: ${e.runtimeType}');
      }
      await r.forget(entry.id);
      final made = await _addedDir(entry);
      for (final dir in [Directory(made), Directory(made).parent]) {
        await dir.delete(); // only when empty
      }
    } on Object catch (e) {
      logWarn('desk', 'new wallet entry not taken back: ${e.runtimeType}');
    }
  }

  @override
  Future<List<String>> createWallet({String name = '', required String password}) async {
    _checkPassword(password);
    try {
      return await _make(name, const {}, (config) async {
        final session = await _service.create(config: config, password: password);
        try {
          final phrase = await session.mnemonic(password: password);
          return phrase.split(RegExp(r'\s+'));
        } finally {
          session.dispose();
        }
      }, walletFingerprintOf: (words) => _walletFingerprint(words.join(' ')));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// A wallet made before the list kept the core's fingerprint, or an import from before:
  /// kept now, so a restore of its phrase finds it. A failure is logged only.
  Future<void> _keepWalletFingerprint(reg.WalletEntry entry, core.WalletSession session) async {
    try {
      final fp = await session.fingerprint();
      await (await registry()).setWalletFingerprint(entry.id, fp);
    } on Object catch (e) {
      logWarn('desk', 'wallet fingerprint not kept: ${e.runtimeType}');
    }
  }

  /// Drops the old phrase hash that earlier builds kept in the wallet list, once the core's
  /// fingerprint is there to match a restore instead ([reg.WalletRegistry.dropPhraseFingerprint]).
  /// A failure is logged only; the next unlock tries again.
  Future<void> _dropPhraseFingerprint(String id) async {
    try {
      await (await registry()).dropPhraseFingerprint(id);
    } on Object catch (e) {
      logWarn('desk', 'old phrase fingerprint not dropped: ${e.runtimeType}');
    }
  }

  @override
  bool checkPhrase(List<String> words) =>
      _service.validateMnemonic(phrase: words.map((w) => w.trim().toLowerCase()).join(' '));

  String _mnemonicOf(List<String> phrase) => phrase.map((w) => w.trim().toLowerCase()).join(' ');

  /// The core's fingerprint of [mnemonic] on this network; null when the core cannot give one.
  String? _walletFingerprint(String mnemonic) {
    try {
      return _service.walletFingerprint(mnemonic: mnemonic, chain: preset.chain);
    } on core.WalletError catch (e) {
      logWarn('desk', 'wallet fingerprint not derived: ${e.kind.name}');
      return null;
    }
  }

  /// The listed wallet of this network that is [mnemonic]'s: the same core
  /// fingerprint ([reg.WalletEntry.walletFingerprint], kept for created, restored and imported
  /// wallets, and for older ones at their next unlock), or for an entry with only that, the
  /// same phrase fingerprint. A wallet never unlocked since it was made before either is kept
  /// is not matched.
  Future<WalletEntry?> _sameWallet(String mnemonic) async {
    final fp = phraseFingerprint(mnemonic);
    final wallet = _walletFingerprint(mnemonic);
    final same = (await _wallets())
        .where((e) => (wallet != null && e.walletFingerprint == wallet) || e.phraseFingerprint == fp)
        .firstOrNull;
    if (same == null) return null;
    return (await wallets()).where((w) => w.id == same.id).firstOrNull;
  }

  @override
  Future<WalletEntry?> walletWithPhrase(List<String> words) async {
    final mnemonic = _mnemonicOf(words);
    if (!_service.validateMnemonic(phrase: mnemonic)) return null;
    return _sameWallet(mnemonic);
  }

  @override
  Future<bool?> phraseIsOf(String id, List<String> phrase) async {
    final entry = await _entry(id);
    final mnemonic = _mnemonicOf(phrase);
    final wallet = entry.walletFingerprint;
    if (wallet != null) return wallet == _walletFingerprint(mnemonic);
    final kept = entry.phraseFingerprint;
    return kept == null ? null : kept == phraseFingerprint(mnemonic);
  }

  @override
  Future<void> resetPassword(String id, {required List<String> phrase, required String newPassword}) async {
    _checkPassword(newPassword);
    final mnemonic = _mnemonicOf(phrase);
    if (!_service.validateMnemonic(phrase: mnemonic)) throw DeskError.l10n((l) => l.deskErrPhraseInvalid, wrongPhrase: true);
    final entry = await _entry(id);
    if (_session != null && _openEntry?.id == id) await lock();
    final config = await _configOf(entry);
    logInfo('desk', 'password reset asked');
    final until = DateTime.now().add(deleteWaitAtMost);
    while (true) {
      try {
        await _service.resetPassword(config: config, mnemonic: mnemonic, newPassword: newPassword);
        break;
      } on core.WalletError catch (e) {
        // A wallet just locked is let go by the core a moment later.
        if (e.kind == core.WalletErrorKind.walletBusy && DateTime.now().isBefore(until)) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }
        logWarn('desk', 'password reset: ${e.kind.name}');
        throw switch (e.kind) {
          core.WalletErrorKind.invalidArgument => DeskError.l10n((l) => l.deskErrPasswordShort(minPasswordLength)),
          // Nothing in the wallet's files can confirm the phrase (no database a wallet used, or a
          // damaged one): the way out is a restore from the phrase.
          core.WalletErrorKind.walletNotFound => DeskError.l10n((l) => '${l.deskOnbForgotNoCheck} ${l.deskOnbForgotRestoreHint(entry.label)}', resetUnverifiable: true),
          core.WalletErrorKind.damagedDatabase => DeskError.l10n((l) => l.deskErrDbDamagedDetail(l.deskOnbForgotRestoreHint(entry.label)), resetUnverifiable: true),
          core.WalletErrorKind.phraseMismatch => DeskError.l10n((l) => l.deskOnbForgotOtherWallet(entry.label), wrongPhrase: true),
          core.WalletErrorKind.invalidMnemonic => DeskError.l10n((l) => l.deskErrPhraseInvalid, wrongPhrase: true),
          _ => _deskError(e),
        };
      }
    }
    logInfo('desk', 'password reset');
    await _remember.forget(id);
    _selectedId = id;
    // The core checked the phrase against this wallet: a wallet made before the app kept
    // fingerprints gets one now, so a restore of the same phrase finds it.
    final fp = entry.walletFingerprint == null ? _walletFingerprint(mnemonic) : null;
    if (fp != null) {
      try {
        await (await registry()).setWalletFingerprint(id, fp);
      } on Object catch (e) {
        logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
      }
    }
    await _dropPhraseFingerprint(id);
  }

  @override
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase, BigInt? startHeight}) async {
    _checkPassword(password);
    final mnemonic = _mnemonicOf(phrase);
    if (!_service.validateMnemonic(phrase: mnemonic)) throw DeskError.l10n((l) => l.deskErrPhraseInvalid);
    final same = await _sameWallet(mnemonic);
    if (same != null) throw DeskError.l10n((l) => l.deskErrAlreadyHere(same.name), sameWallet: same);
    try {
      // The scan runs after unlock, in the background, with its progress in the status.
      await _make(name, {'scanPending': true, 'historyOffer': true, if (startHeight != null) 'scanFrom': startHeight.toInt()}, (config) async {
        final session = await _service.create(config: config, mnemonic: mnemonic, password: password, restoreFromHeight: startHeight);
        session.dispose();
      }, walletFingerprintOf: (_) => _walletFingerprint(mnemonic));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  // ---- Import (as LEPIC takes them: wallet.seed only, history from a scan).

  static String _testNetText(AppLocalizations l) => l.deskErrTestNet;

  /// Why an old wallet cannot be imported ([legacy.LegacyRefusal.text] is the English).
  static String _refusalText(AppLocalizations l, legacy.LegacyRefusal r) => switch (r) {
    legacy.LegacyRefusal.links => l.deskErrOldLinks,
    legacy.LegacyRefusal.incomplete => l.deskErrOldIncomplete,
    legacy.LegacyRefusal.seedTooLarge => l.deskErrOldSeedTooLarge,
  };

  OldWallet _oldOf(legacy.LegacyWallet w, Map<String, legacy.SameWallet> same) {
    final s = same[w.path];
    return OldWallet(
      id: w.path,
      name: w.displayLabel,
      folder: w.path,
      group: switch (w.source) {
        legacy.LegacySource.gui => OldWalletGroup.gui,
        legacy.LegacySource.cli => OldWalletGroup.cli,
        legacy.LegacySource.picked => OldWalletGroup.picked,
      },
      network: w.network.guiName,
      lastUsed: w.lastUsed,
      sizeBytes: w.sizeBytes,
      sameAs: s?.text,
      inApp: s?.inApp ?? false,
      blocked: w.refusal != null ? _refusalText(deskStrings, w.refusal!) : (w.network == legacy.LegacyNetwork.main ? null : _testNetText(deskStrings)),
    );
  }

  /// Seed fingerprint → name of each wallet in the list that an import made.
  Future<Map<String, String>> _inAppSeeds() async {
    final out = <String, String>{};
    for (final e in await _inList() ?? const <reg.WalletEntry>[]) {
      final fp = (await _meta(_metaKey(e.walletId)))['seedFingerprint'];
      if (fp is String) out[fp] = e.label;
    }
    return out;
  }

  /// The app's own folder: never offered as an old wallet.
  Future<String> _appRoot() async => reg.WalletRegistry.rootOf(await _walletDir(preset.chain), preset.chain);

  /// A test network's old wallet is listed by development builds only: release builds name
  /// no network, and its folder (`~/.epic/floo`) would.
  static bool _offered(legacy.LegacyWallet w) => w.network == legacy.LegacyNetwork.main || DeskFeatures.testNetworks;

  Future<List<OldWallet>> _describeOld(List<legacy.LegacyWallet> found) async {
    final root = await _appRoot();
    final own = [
      for (final w in found)
        if (_offered(w) && !await legacy.isWithin(w.path, root)) w,
    ];
    for (final w in own) {
      _old[w.path] = w;
    }
    final same = legacy.findSameWallets([..._old.values], inApp: await _inAppSeeds());
    return [for (final w in own) _oldOf(w, same)];
  }

  @override
  Future<List<OldWallet>> findOldWallets() async {
    _old.clear();
    _imported.clear();
    final scan = await legacy.findLegacyWallets(roots: _legacyRoots());
    logInfo('desk', 'import: ${scan.wallets.length} old wallets found');
    return _describeOld(scan.wallets);
  }

  @override
  Future<FolderFind?> pickFolder() async {
    final pick = _pickDirectory;
    if (pick == null) return null;
    final path = await pick();
    if (path == null) return null;
    final found = await legacy.inspectFolder(path);
    final wallets = await _describeOld(found.wallets);
    return FolderFind(
      folder: found.picked,
      wallets: wallets,
      message: found.wallets.isNotEmpty && wallets.isEmpty
          ? (found.wallets.any(_offered) ? deskStrings.deskErrWalletInApp : deskStrings.deskErrTestNet)
          : found.message,
    );
  }

  legacy.LegacyWallet _oldWallet(String id) => _old[id] ?? (throw DeskError.l10n((l) => l.deskErrWalletNotFoundSearch));

  @override
  Future<OldWalletUse> checkOldWallet(String id) async =>
      switch (await legacy.checkInUse(_oldWallet(id), listProcesses: _listProcesses)) {
        legacy.InUse.free => OldWalletUse.free,
        legacy.InUse.inUse => OldWalletUse.inUse,
        legacy.InUse.unknown => OldWalletUse.unknown,
      };

  @override
  Future<ImportedWallet> importOldWallet(String id, {required String oldPassword, String? newPassword}) async {
    final w = _oldWallet(id);
    final refusal = w.refusal;
    if (refusal != null) throw DeskError.l10n((l) => _refusalText(l, refusal));
    if (w.network != legacy.LegacyNetwork.main) throw DeskError.l10n(_testNetText);
    if (oldPassword.isEmpty) throw DeskError.l10n((l) => l.deskErrEnterOldPassword);
    final next = newPassword ?? oldPassword;
    if (next.length < minPasswordLength) {
      throw DeskError.l10n(
        (l) => newPassword == null ? l.deskErrOldPasswordShort(minPasswordLength) : l.deskErrPasswordShort(minPasswordLength),
        newPasswordNeeded: true,
      );
    }
    // The wallet's own files: a node running in the same folder changes its chain_data.
    final walletData = '${w.path}${Platform.pathSeparator}wallet_data';
    final before = await legacy.folderHash(walletData);
    final List<int> bytes;
    try {
      bytes = await File(w.seedPath).readAsBytes();
    } on FileSystemException {
      throw DeskError.l10n((l) => l.deskErrSeedUnreadable);
    }
    if (bytes.isEmpty || bytes.length > legacy.maxSeedBytes) throw DeskError.l10n((l) => l.deskErrOldSeedTooLarge);
    final String seed;
    try {
      seed = utf8.decode(bytes);
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotSeedFile);
    }
    final fingerprint = sha256.convert(bytes).toString();
    final held = (await _inAppSeeds())[fingerprint];
    if (held != null) throw DeskError.l10n((l) => l.deskErrAlreadyInApp(held));
    // What the older app kept beside the wallet: its name, contacts, node, Epicbox server.
    // Read only.
    final profile = await gui.readGuiImport(_legacyRoots(), w);
    final global = await gui.readGuiGlobal(w);
    final name = _importName(profile.label ?? w.displayLabel);
    String? walletFp;
    core.LegacyHistoryImport? history;
    var contacts = const ContactImport();
    reg.WalletEntry? made;
    try {
      // The seed makes the wallet; the old log brings its history, which the scan at the first
      // unlock then reconciles with the chain.
      await _make(name, {'scanPending': true, 'seedFingerprint': fingerprint, 'importedFrom': w.path}, (config) async {
        final session = await _service.importWalletSeed(config: config, seedFile: seed, seedPassword: oldPassword, password: next);
        try {
          // The same keys restored or imported before (another seed file of the same phrase):
          // that wallet is the one to use, not a second copy.
          walletFp = await _fingerprintOf(session);
          final fp = walletFp;
          final twin = fp == null ? null : (await _inList())?.where((e) => e.walletFingerprint == fp).firstOrNull;
          if (twin != null) throw DeskError.l10n((l) => l.deskErrAlreadyInApp(twin.label));
          history = await _importHistory(session, w.path);
          contacts = await _importContacts(session, profile);
        } finally {
          session.dispose();
        }
      }, ownEntry: true, walletFingerprintOf: (_) => walletFp);
      made = (await registry()).byId(_selectedId ?? '');
    } on core.WalletError catch (e) {
      if (e.kind == core.WalletErrorKind.wrongPassword) throw DeskError.l10n((l) => l.deskErrWrongOldPassword, wrongPassword: true);
      throw _deskError(e);
    }
    if (made == null) throw DeskError.l10n((l) => l.deskErrListNotSaved);
    _imported.add(made.id);
    final done = history;
    // A busy source is not recorded, so the sync tries again, as the proof line says.
    if (done != null && done.status != core.LegacyHistoryStatus.sourceBusy) {
      await _setMeta({'historyImport': done.status.name}, _metaKey(made.walletId));
    }
    final nodes = await _importNodes(profile.nodeUrl, global.myNodes['mainnet'] ?? const []);
    final unchanged = await legacy.folderHash(walletData) == before;
    if (!unchanged) logWarn('desk', 'import: the old folder changed during the import');
    logInfo('desk', 'import: wallet made');
    // The older app's Epicbox server is part of the old address. Kept (for every wallet: the
    // server is shared) unless the Done step's choice says otherwise (keepOldRelay).
    final relay = await _relay();
    final box = profile.epicboxDomain;
    final old = box == null ? null : EpicboxRelay(host: box, port: profile.epicboxPort ?? 443);
    final otherRelay = old != null && old.label != relay.label;
    if (otherRelay) {
      _oldRelays[made.id] = old.label;
      _appRelays[made.id] = relay.label;
      await keepOldRelay(made.id, keep: true);
    }
    return ImportedWallet(
      id: made.id,
      name: made.label,
      oldRelay: otherRelay ? old.label : null,
      appRelay: relay.label,
      newPassword: newPassword != null,
      proof: [
        ImportProof.l10n((l) => l.deskErrProofSeedRead),
        ImportProof.l10n((l) => l.deskErrProofWalletCreated),
        _historyProof(done),
        ...contacts.proof(),
        for (final n in nodes) ImportProof.l10n((l) => l.deskErrProofNode(n.label)),
        unchanged ? ImportProof.l10n((l) => l.deskErrProofFolderUnchanged) : ImportProof.l10n((l) => l.deskErrProofFolderChanged, ok: false),
      ],
    );
  }

  /// The older app's Epicbox server of each wallet this run imported, by list id.
  final Map<String, String> _oldRelays = {};

  /// The Epicbox server in use before each of those imports: "Use" goes back to it.
  final Map<String, String> _appRelays = {};

  /// Servers the import put in the Epicbox list (taken out again by "Use" or Cancel).
  final Set<String> _relaysListed = {};

  /// The core's fingerprint of [session]'s wallet; null when the core cannot give one.
  Future<String?> _fingerprintOf(core.WalletSession session) async {
    try {
      return await session.fingerprint();
    } on core.WalletError catch (e) {
      logWarn('desk', 'wallet fingerprint not read: ${e.kind.name}');
      return null;
    }
  }

  @override
  Future<void> keepOldRelay(String id, {required bool keep}) async {
    final old = _oldRelays[id];
    final entry = (await registry()).byId(id);
    if (old == null || entry == null) return;
    // The server is every wallet's (the first of the Epicbox list): keeping the old one moves
    // them all to it.
    final back = _appRelays[id];
    final use = keep ? old : back;
    // In use means first of the list: a server not listed joins it, and goes again with Cancel.
    final wasListed = serverListOf(hostSettings, ServerKind.relay).has(ServerKind.relay, old);
    if (use != null && use != _useRelay().label) await writeHostSettings(useServerValues(hostSettings, relay: use));
    logInfo('desk', keep ? 'import: keeps the older Epicbox server' : "import: uses the app's Epicbox server");
    if (keep) {
      if (await _listRelay(old) || !wasListed) _relaysListed.add(old);
    } else if (_relaysListed.remove(old)) {
      await _unlistRelay(old);
    }
  }

  /// Puts [label] in the Epicbox list; false when it was listed already.
  Future<bool> _listRelay(String label) async {
    const kind = ServerKind.relay;
    final list = serverListOf(hostSettings, kind);
    if (list.has(kind, label)) return false;
    await writeHostSettings(serverListValues(kind, list.add(kind, label)));
    return true;
  }

  Future<void> _unlistRelay(String label) async {
    const kind = ServerKind.relay;
    final list = serverListOf(hostSettings, kind);
    await writeHostSettings(serverListValues(kind, list.remove(kind, label).list));
  }

  /// The old wallet's history, or null when the core failed; a failure never fails the import.
  Future<core.LegacyHistoryImport?> _importHistory(core.WalletSession session, String from) async {
    try {
      final r = await session.importLegacyHistory(sourceDir: from);
      logInfo('desk', 'import: history ${r.status.name}, ${r.transactions} transactions, ${r.skipped} skipped');
      return r;
    } on core.WalletError catch (e) {
      logWarn('desk', 'import: history not imported: ${e.kind.name}');
      return null;
    }
  }

  static ImportProof _historyProof(core.LegacyHistoryImport? r) => switch (r?.status) {
    core.LegacyHistoryStatus.imported => ImportProof.l10n(
      (l) => l.deskErrProofHistory(r!.transactions),
    ),
    core.LegacyHistoryStatus.alreadyImported => ImportProof.l10n((l) => l.deskErrProofHistoryAlready),
    core.LegacyHistoryStatus.noHistory => ImportProof.l10n((l) => l.deskErrProofHistoryNone),
    core.LegacyHistoryStatus.oldFormat =>
      ImportProof.l10n((l) => l.deskErrProofHistoryOld, ok: false),
    core.LegacyHistoryStatus.sourceBusy =>
      ImportProof.l10n((l) => l.deskErrProofHistoryBusy, ok: false),
    core.LegacyHistoryStatus.otherWallet ||
    core.LegacyHistoryStatus.otherHistory =>
      ImportProof.l10n((l) => l.deskErrProofHistoryOther, ok: false),
    core.LegacyHistoryStatus.unreadable ||
    core.LegacyHistoryStatus.tooLarge ||
    null =>
      ImportProof.l10n((l) => l.deskErrProofHistoryUnreadable, ok: false),
  };

  /// The older app's contacts of this wallet into the shared address book, with the checks the
  /// contact form uses (gui_contact_import.dart).
  Future<ContactImport> _importContacts(core.WalletSession session, gui.LegacyGuiImport profile) => importGuiContacts(
    session,
    profile,
    AddressChecks(
      epicbox: isEpicboxAddress,
      onion: isOnionAddress,
      http: (url) => parseAddress(url, this).complete,
    ),
  );

  /// Adds the old wallet's node and the older app's own nodes to the node list without switching
  /// to them: the node is app-wide here and would move every wallet. Returns those added.
  Future<List<NodeServer>> _importNodes(String? walletNode, List<gui.LegacyNode> myNodes) async {
    final listed = {for (final n in await _listed()) n.url, await _nodeUrl()};
    final added = <NodeServer>[];
    final wanted = [
      if (walletNode != null) (address: walletNode, label: Uri.tryParse(walletNode)?.host ?? walletNode),
      for (final n in myNodes) (address: n.address, label: n.label.trim().isNotEmpty ? n.label.trim() : (Uri.tryParse(n.address)?.host ?? n.address)),
    ];
    for (final n in wanted) {
      final uri = Uri.tryParse(n.address);
      if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty || isLoopbackHost(uri.host)) continue;
      if (!listed.add(n.address)) continue;
      final node = NodeServer(url: n.address, label: n.label);
      await addNode(node);
      added.add(node);
    }
    return added;
  }

  /// A list name of at most 32 characters, cleaned as the GUI cleaned its labels: an old label
  /// with a control or direction character (the list refuses those) or an emoji at the cut
  /// still imports. Empty: the list's own "Wallet N".
  static String _importName(String label) => cleanGuiLabel(label.replaceAll(RegExp('[\u2028\u2029]'), ' '));

  @override
  Future<void> cancelImport() async {
    final r = await registry();
    for (final id in [..._imported]) {
      final entry = r.byId(id);
      if (entry == null) {
        _imported.remove(id);
        continue;
      }
      if (_openEntry?.id == id) await lock();
      try {
        await r.delete(id, service: _service, config: await _configOf(entry));
        final metaKey = _metaKey(entry.walletId);
        await _metaTurn(metaKey, () => _store.delete(metaKey));
        await _store.delete(DeskStore.favouritesKeyOf(entry.walletId));
        if (entry.walletId != null) {
          await _store.delete(DeskStore.httpKeyOf(entry.walletId));
        }
        // Kept on failure, so Cancel can try again.
        _imported.remove(id);
      } on Object catch (e) {
        logWarn('desk', 'import: wallet not removed: ${e.runtimeType}');
      }
      if (_selectedId == id) _selectedId = null;
    }
    for (final label in [..._relaysListed]) {
      _relaysListed.remove(label);
      await _unlistRelay(label);
    }
  }

  // ---- Background work.

  /// Brings the balance and history up to date: a pending scan (restore, rebuilt database)
  /// first, then a refresh against the node. One at a time; a call during a run runs once more.
  Future<void> sync() {
    final running = _syncing;
    if (running != null) {
      _syncAgain = true;
      // Done once the run this call asked for is done too.
      return running.then((_) => _syncing ?? Future<void>.value());
    }
    return _syncing = _sync().whenComplete(() {
      _syncing = null;
      if (_syncAgain && _session != null) {
        _syncAgain = false;
        unawaited(sync());
      }
    });
  }

  Future<void> _sync() async {
    final session = _session;
    if (session == null) return;
    if (_nodeOff) return _loadLocal();
    final key = _metaKey(_openEntry?.walletId);
    _syncProgress = 0;
    _syncError = null;
    _changed();
    try {
      // The scan due since a restore or a rebuilt database (the core's flag, or the note the
      // app wrote before the core made the wallet); not while Recheck balance scans.
      final due = await _meta(key);
      if (_session != session) return;
      _restoreDue = await _restoreFlag(session) || due['scanPending'] == true;
      if (_session != session) return;
      if (!_rescanning && _restoreDue && !_restoreUnfinished) {
        // A restore scans from its start height (Restore's month or height, recorded by the
        // core too), which finishes it. Should the core's flag stay (a restore by an older
        // version owes block 0), the scan with no height (from the restore's start, resuming a
        // stopped one) follows by itself. A rebuild never reuses the height ([_scanEnded]).
        final from = due['scanFrom'];
        var start = from is int ? BigInt.from(from) : null;
        _restoreFailed = false;
        while (true) {
          var finished = false;
          _scanningDue = true;
          _duePercent = null;
          _changed();
          try {
            await for (final p in session.scan(startHeight: start)) {
              if (_session != session) return;
              finished = finished || p.finished;
              if (p.percent != null) {
                _syncProgress = p.percent! / 200;
                _duePercent = p.percent;
              }
              _changed();
            }
          } on core.WalletError catch (e) {
            if (e.kind != core.WalletErrorKind.walletBusy) {
              _restoreFailed = true;
              rethrow;
            }
            logInfo('desk', 'due scan skipped: a scan is already running');
          } finally {
            _scanningDue = false;
          }
          if (_session != session) return;
          // A scan stopped before its end stays due.
          if (!finished) break;
          await _scanEnded(session, key);
          if (_session != session || !_restoreDue) break;
          if (start == null) {
            // The core still owes the scan from the restore's start after one ran to its end:
            // no loop of scans; the restore state offers Try again.
            logWarn('desk', 'restore scan finished, the core still wants one');
            _restoreUnfinished = true;
            break;
          }
          // The funds after the typed height are in; the earlier blocks come now.
          _dueAfterHeight = start.toInt();
          start = null;
        }
      }
      // Locked meanwhile: the session is gone, and a call on it would fail outside any catch.
      if (_session != session) return;
      await for (final p in session.refresh(minimumConfirmations: _minConf)) {
        if (_session != session) return;
        _syncProgress = 0.5 + p.percent / 200;
        final summary = p.summary;
        if (summary != null) {
          _summary = summary;
          if (summary.validatedWithNode) _nodeReachedAt = DateTime.now();
          _nodeHealth = !summary.validatedWithNode
              ? ServiceHealth.down
              : _nodeNotReady
              ? ServiceHealth.slow
              : ServiceHealth.ok;
          final h = summary.lastConfirmedHeight.toInt();
          if (h > _tip) _tip = h;
        }
        _changed();
      }
      if (_session != session) return;
      await _importHistoryOnce(session, key);
      if (_session != session) return;
      final run = ++_reloads;
      final entries = await session.transactions(refresh: false);
      await _readRewardLocks(session, entries);
      if (run == _reloads) _entries = entries;
      _lastUpdate = DateTime.now();
      _syncError = _nodeHealth == ServiceHealth.down ? DeskError.l10n((l) => l.deskErrNodeNoAnswer) : null;
    } on core.WalletError catch (e) {
      logWarn('desk', 'sync: ${e.kind.name}');
      if (e.kind == core.WalletErrorKind.nodeUnreachable) _nodeHealth = ServiceHealth.down;
      _syncError = _deskError(e);
    } finally {
      if (_session == session) _syncProgress = null;
      _changed();
    }
  }

  @override
  Future<void> syncNow() async {
    if (_session == null) throw DeskError.l10n((l) => l.deskErrWalletLocked);
    // Also the restore state's Try again: the scan the core still owes runs once more.
    _restoreUnfinished = false;
    await sync();
    final e = _syncError;
    if (e != null) throw e;
  }

  /// Brings the history across for a wallet an earlier build imported with its seed only.
  /// Retried at the next sync while the older wallet is running or the core fails.
  Future<void> _importHistoryOnce(core.WalletSession session, String key) async {
    final meta = await _meta(key);
    final from = meta['importedFrom'];
    if (from is! String || meta['historyImport'] != null) return;
    // The sync runs at every block; the old database is read at most once an hour.
    final last = _historyTried[key];
    if (last != null && DateTime.now().difference(last) < const Duration(hours: 1)) return;
    if (_oldHistoryAsk != null || _oldHistoryHeld.contains(key)) return;
    _historyTried[key] = DateTime.now();
    final r = await _importHistory(session, from);
    if (r == null || r.status == core.LegacyHistoryStatus.sourceBusy) return;
    if (!r.applied) {
      // Typed details differ from the old wallet's: nothing is recorded as done until the user
      // chose, so Cancel leaves the import to be asked again.
      logInfo('desk', 'old history waits for ${r.conflicts.length} choices');
      _oldHistoryAsk = (key: key, from: from, conflicts: r.conflicts);
      return;
    }
    await _setMeta({'historyImport': r.status.name}, key);
  }

  @override
  List<ImportConflict> get oldHistoryConflicts => _oldHistoryAsk?.conflicts ?? const [];

  @override
  Future<void> resolveOldHistory(Map<String, bool>? useOldWallet) async {
    final ask = _oldHistoryAsk;
    if (ask == null) return;
    _oldHistoryAsk = null;
    if (useOldWallet == null) {
      _oldHistoryHeld.add(ask.key);
      return;
    }
    try {
      final r = await _open.importLegacyHistory(sourceDir: ask.from, useOldWallet: useOldWallet);
      logInfo('desk', 'old history imported: ${r.replaced} replaced');
      if (r.applied) await _setMeta({'historyImport': r.status.name}, ask.key);
    } on core.WalletError catch (e) {
      logWarn('desk', 'old history choices not applied: ${e.kind.name}');
      throw _deskError(e);
    }
    await _reload();
  }

  /// The wait notes last shown, so a window that passes with no block (and so no sync) still
  /// shows its note.
  int? _waitsShown;

  void _startPoll() {
    _tipDriver?.stop();
    _tipDriver = PollDriver(_open.boosts, Poller.node, base: nodePoll, tick: _tipTick)..start();
  }

  void _stopPoll() {
    _tipDriver?.stop();
    _tipDriver = null;
  }

  /// Boosts the node for the payments that took a step or saw a block ([BlockWatch.boostNode]).
  /// Each change ([_changed]) calls it.
  void _watchBlocks() {
    final entries = _entries;
    if (_tipDriver == null || entries == null) return;
    final tip = BigInt.from(_tip);
    _blockWaits
      ..saw(entries, tip)
      ..boostNode(_session?.boosts, entries, tip, minConfirmations: _minConf.toInt());
  }

  Future<bool> _tipTick() async {
    final answered = await _checkTip();
    final entries = _entries;
    if (entries != null) {
      final waits = Object.hashAll(entries.map(_waitOf));
      if (_waitsShown != null && waits != _waitsShown) _changed();
      _waitsShown = waits;
    }
    return answered;
  }

  /// Asks the node for its tip. False when it did not answer: the poll then waits longer.
  Future<bool> _checkTip() async {
    final config = _config;
    if (config == null || _tipBusy || _nodeOff) return true;
    // Over Tor, LEPIC holds the check until tor is connected; a failure meanwhile is not counted.
    final overTor = _nodeOverTor(config.nodeUrl);
    _tipBusy = true;
    try {
      final tip = await _nodeTip(config);
      if (tip == null) return true;
      _nodeReachedAt = DateTime.now();
      // Back after failing twice in a row: the payments it refused meanwhile are posted again
      // at once.
      if ((_tipDriver?.failures ?? 0) >= 2) _stall.nodeBack();
      final h = tip.height.toInt();
      final grew = h > _tip;
      _tip = h;
      // The local node answers from its first second, at height 0 while it downloads the
      // chain: that is "Syncing" (slow), never "Online · 0". Its sync progress past
      // height 0 (headers, then blocks, against the network's tip) is later work.
      // A node that says it is not ready for transactions is syncing too, whatever its height;
      // one that does not say (null) is judged as before.
      _nodeNotReady = tip.readyForTxs == false;
      final syncing = _nodeNotReady || (h == 0 && await _builtInOn());
      final health = syncing ? ServiceHealth.slow : ServiceHealth.ok;
      if (_nodeHealth != health) {
        _nodeHealth = health;
        _changed();
      }
      // A new block: confirmations move, payments may have landed.
      if (grew && _summary != null) {
        unawaited(sync());
      } else if ((_entries ?? const <core.TxEntry>[]).any((e) => postingNow(e, DateTime.now(), _blockWaits))) {
        // Being posted: read the list again, so "Not on the network" does not wait for a block.
        unawaited(_reload());
      }
      unawaited(_retryStalled());
      unawaited(_releaseSenderCancelled());
      return true;
    } on Object catch (e) {
      final why = e is core.WalletError ? e.kind.name : e.runtimeType;
      if (overTor && _torGrace()) {
        logInfo('desk', 'node check over Tor failed: $why; not counted while tor settles or the node syncs');
        return false;
      }
      if (_nodeHealth != ServiceHealth.down) {
        logWarn('desk', 'node check failed: $why');
        _nodeHealth = ServiceHealth.down;
        _changed();
      }
      return false;
    } finally {
      _tipBusy = false;
    }
  }

  /// Whether [url] is asked over Tor: the Tor switch is on and the node is not on this computer.
  bool _nodeOverTor(String url) => _torFeature && _settings.tor && !isLoopbackUrl(Uri.tryParse(url) ?? Uri());

  /// A failed check over Tor is not counted: tor is not connected, connected under
  /// [torNodeGrace] ago, or the node answered (a sync reached it) within [nodeTorTimeout].
  bool _torGrace() {
    final now = DateTime.now();
    final connected = _torConnectedAt;
    if (!_torCanSend || connected == null || now.difference(connected) < torNodeGrace) return true;
    final reached = _nodeReachedAt;
    return reached != null && now.difference(reached) < nodeTorTimeout;
  }

  /// Tor connected (again): a node that went down over the old circuits is checked afresh.
  void _torConnected() {
    if (_torConnectedAt != null) return;
    _torConnectedAt = DateTime.now();
    final url = _config?.nodeUrl;
    if (url == null || !_nodeOverTor(url)) return;
    if (_nodeHealth == ServiceHealth.down) _nodeHealth = ServiceHealth.checking;
    unawaited(_checkTip());
  }

  @override
  Stream<void> changes() => _changes.stream;

  // ---- Reading.

  @override
  Future<WalletAccount> account() async {
    final meta = await _meta();
    final folder = _config?.dataDir ?? (await _makeConfig()).dataDir;
    return WalletAccount(
      id: _openEntry?.id,
      name: _openEntry?.label ?? (meta['name'] as String?) ?? 'Main wallet', // l10n-ok
      network: _chain,
      folder: folder,
      created: _time(meta['created']) ?? DateTime.now(),
      appFolder: reg.WalletRegistry.rootOf(await _walletDir(preset.chain), preset.chain),
    );
  }

  @override
  Future<Balance> balance() async {
    final s = _summary ?? await _open.summary(refresh: false, minimumConfirmations: _minConf);
    _summary ??= s;
    // The coins another device is spending are spendable to the core and held here: Locked.
    final held = await _heldValue();
    return Balance(
      spendable: s.spendable.toInt() - held,
      awaitingConfirmation: s.awaitingConfirmation.toInt(),
      locked: s.locked.toInt() + held,
      // An unpaid issued invoice is in no figure: LEPIC files its output apart.
      awaitingFinalization: s.awaitingFinalization.toInt(),
      immature: s.immature.toInt(),
      minConfirmations: _minConf.toInt(),
      reportedTotal: s.total.toInt(),
      held: held,
    );
  }

  /// What the coins other devices hold are worth among the spendable ones, in nano.
  Future<int> _heldValue() async {
    final held = _heldBy();
    if (held.isEmpty) return 0;
    try {
      return (await heldSpendable(_open, held.keys.toSet())).toInt();
    } on core.WalletError {
      return 0;
    }
  }

  @override
  Future<List<Tx>> transactions() async {
    final raw = _entries ?? await _open.transactions(refresh: false);
    _entries = raw;
    await _readRewardLocks(_open, raw);
    final entries = _withDevices(raw);
    final contacts = await _open.contacts();
    // Any of a contact's addresses names it, as the address reads in a row (an onion with or
    // without its http://).
    final names = {
      for (final c in contacts)
        for (final a in c.addresses) parseRecipient(a).address: c.name,
    };
    // A payment through a pairing has no address: the contact it is attached to names it.
    final paired = entries.any((e) => e.pairingId != null) ? await _pairingNames(contacts) : const <String, String>{};
    return [
      for (final (i, e) in entries.indexed)
        deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1 - i, contactName: names[parseRecipient(e.counterparty ?? '').address] ?? paired[e.pairingId], cancelFinal: _cancelFinal[e.id], lockHeight: _rewardLockOf(e)),
    ];
  }

  /// Each mining reward's first spendable height, by its output's commitment: the core's lock
  /// height, which carries the network's maturity. Read from the outputs once per new reward;
  /// a spent reward's stays, its row keeps showing when it matured.
  final Map<String, int> _rewardLocks = {};

  /// Reward commitments the outputs did not have (the entry stays without a lock height), so a
  /// reward is looked up once and not on every reload.
  final Set<String> _rewardLockMisses = {};

  Future<void> _readRewardLocks(core.WalletSession session, List<core.TxEntry> entries) async {
    bool unknown(String c) => !_rewardLocks.containsKey(c) && !_rewardLockMisses.contains(c);
    final rewards = entries.where((e) => e.kind == core.TxKind.coinbase);
    if (!rewards.any((e) => e.outputCommits.any(unknown))) return;
    try {
      for (final o in await session.outputs()) {
        if (o.isCoinbase) _rewardLocks[o.commitment] = o.lockHeight.toInt();
      }
      for (final e in rewards) {
        _rewardLockMisses.addAll(e.outputCommits.where(unknown));
      }
    } on core.WalletError catch (e) {
      logWarn('desk', 'reward locks: ${e.kind.name}');
    }
  }

  int? _rewardLockOf(core.TxEntry e) {
    if (e.kind != core.TxKind.coinbase) return null;
    for (final c in e.outputCommits) {
      if (_rewardLocks[c] case final h?) return h;
    }
    return null;
  }

  /// Each pairing's name, by id: its address-book contact's, else the one it shows; none
  /// while the core does not pair.
  Future<Map<String, String>> _pairingNames(List<core.Contact> contacts) async {
    final api = pairing;
    if (!api.supported) return const {};
    try {
      return {
        for (final r in await api.pairings())
          if (pairingName(r, contacts) case final name when name.isNotEmpty) r.id: name,
      };
    } on core.WalletError catch (e) {
      logWarn('desk', 'pairing names: ${e.kind.name}');
      return const {};
    }
  }

  /// Every output, spent ones included, from the wallet's database (as of the last refresh).
  @override
  Future<List<Output>> outputs() async {
    try {
      final list = await _open.outputs();
      final held = _heldBy();
      return [for (final o in list) deskOutput(o, minConf: _minConf.toInt(), heldBy: held[o.commitment])];
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<List<Contact>> contacts() async {
    final favourites = await _favourites();
    final txs = _entries ?? const <core.TxEntry>[];
    DateTime? lastUsed(String address) {
      final t = txs.where((t) => t.counterparty == address).map((t) => t.timeUnix).fold<int>(0, (a, b) => b > a ? b : a);
      return t == 0 ? null : DateTime.fromMillisecondsSinceEpoch(t * 1000);
    }

    return [
      for (final c in await _open.contacts())
        Contact(
          id: c.id,
          name: c.name,
          epicbox: c.epicbox,
          http: c.http,
          tor: c.tor,
          epic1: c.epic1,
          note: c.note,
          label: c.label,
          favourite: favourites.contains(c.id),
          lastUsed: [for (final a in c.addresses) lastUsed(a)].nonNulls.fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a),
        ),
    ];
  }

  /// The desktop keeps a wallet's stars itself ([_favouritesKey]); a history backup carries the
  /// session's, so the session is given these first, for an export to seal and an import to add to.
  Future<void> _starsToSession(core.WalletSession session) async {
    final mine = await _favourites();
    final theirs = (await session.favouriteContacts()).toSet();
    for (final id in mine.difference(theirs)) {
      await session.setFavouriteContact(id: id, favourite: true);
    }
    for (final id in theirs.difference(mine)) {
      await session.setFavouriteContact(id: id, favourite: false);
    }
  }

  Future<Set<String>> _favourites() async {
    final j = await _store.readJson(_favouritesKey);
    return j is List ? {for (final v in j) '$v'} : <String>{};
  }

  @override
  Future<ServiceStatus> status() async {
    final config = _config;
    final nodeUrl = config?.nodeUrl ?? await _nodeUrl();
    final relay = config == null ? await _relay() : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
    final node = (await _listed()).where((n) => n.url == nodeUrl).firstOrNull ?? NodeServer(url: nodeUrl, label: Uri.tryParse(nodeUrl)?.host ?? nodeUrl);
    final box = (_boxes ?? _builtInBoxes).where((b) => b.domain == relay.host).firstOrNull ?? EpicboxServer(domain: relay.host, port: relay.port);
    return ServiceStatus(
      node: node,
      nodeHealth: _nodeHealth,
      nodeHeight: _tip,
      epicbox: box,
      epicboxHealth: _epicboxHealth,
      // No wallet has a server of its own: every wallet uses `epicbox.use`.
      epicboxOwn: false,
      httpListener: _httpHealth,
      httpProblem: _httpHealth == ServiceHealth.down ? _httpProblem : null,
      httpProblemPort: _httpHealth == ServiceHealth.down && _httpProblem != null ? _httpPort : null,
      tor: _torHealth,
      torProgress: _torHealth == ServiceHealth.checking && !_torCanSend ? _torProgress : null,
      torProblem: _torHealth == ServiceHealth.down || _torHealth == ServiceHealth.slow ? _torProblem : null,
      torCanSend: _torCanSend,
      torIncluded: await _findTor() != null,
      epicboxViaTor: _epicboxOverTor && _settings.tor && await _findTor() != null,
      epicboxBlocked: _epicboxBlocked && _epicboxHealth == ServiceHealth.down,
      epicboxInstead: _epicboxBlocked && _epicboxHealth == ServiceHealth.down ? _blockedInstead : null,
      torSlowStart: _torHealth == ServiceHealth.checking &&
          !_torCanSend &&
          _torStartedAt != null &&
          DateTime.now().difference(_torStartedAt!) >= torRetryAfter,
      syncProgress: _syncProgress,
      scanning: _scanningDue || _rescanning,
      restoreScan: _restoreView,
      lastUpdate: _lastUpdate,
      notice: _notice,
      recordsPlain: _session?.storeOpen == core.StoreOpenOutcome.plainFallback,
      contactsClosed: !(_session?.contactsAvailable ?? true),
    );
  }

  @override
  Future<List<NodeServer>> nodes() async {
    final all = await _listed(readDirectory: true);
    // Each node is checked in the background; the lists show it when the check is in. Once a
    // check is older than [nodeRecheck], every node is asked again together, so the heights
    // the rows are compared by stay of one moment.
    final now = DateTime.now();
    bool known(String url) => _checked.containsKey(url) && _checkedSameWay(url);
    // A node still being asked does not count: its old check would ask the others in a loop.
    final again = all.any((n) {
      final at = _checkedAt[n.url];
      return _checked.containsKey(n.url) && !_checking.contains(n.url) && (at == null || now.difference(at) >= nodeRecheck);
    });
    for (final n in all) {
      if ((known(n.url) && !again) || !_checking.add(n.url)) continue;
      unawaited(checkNode(n.url).whenComplete(() {
        _checking.remove(n.url);
        _changed();
      }));
    }
    return all;
  }

  /// Public nodes and the nodes the user added (the settings file's nodes without an
  /// operator), with the last check of each. Only the node list itself ([readDirectory]) reads
  /// the status site; the status line uses what is known.
  Future<List<NodeServer>> _listed({bool readDirectory = false}) async {
    final public = _publicNodes(read: readDirectory);
    final publicUrls = {for (final n in public) n.url};
    NodeServer withCheck(NodeServer n) {
      final c = _checked[n.url];
      if (c == null) return n;
      final latency = _checkedSameWay(n.url) ? c.latencyMs : null;
      final at = _checkedAt[n.url];
      final height = at != null && DateTime.now().difference(at) < nodeStale ? c.height : null;
      return NodeServer(url: n.url, label: n.label, operator: n.operator, health: c.health, latencyMs: latency, height: height, version: c.version, own: n.own, icon: n.icon, listedAs: n.listedAs);
    }

    return [
      for (final n in public) withCheck(n),
      for (final n in hostSettings.nodeServers)
        if (n.operator == null && !publicUrls.contains(n.url))
          withCheck(NodeServer(url: n.url, label: Uri.tryParse(n.url)?.host ?? n.url, own: true, health: ServiceHealth.checking)),
    ];
  }

  /// The settings' public nodes, then any only the status site lists. The directory is read in
  /// the background; the lists update when it answers.
  List<NodeServer> _publicNodes({bool read = true}) {
    if (read) _readNodeDirectory();
    return [
      for (final n in mergePublicNodes(_dirNodes))
        NodeServer(url: n.url, label: n.operator, operator: n.operator, health: ServiceHealth.checking, icon: n.status?.icon, listedAs: n.status?.operator),
    ];
  }

  void _readNodeDirectory() {
    final dir = nodeDirectory;
    final chain = preset.statusChain;
    final at = _dirNodesAt;
    if (dir == null || chain == null || _dirNodesLoading) return;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) return;
    // Tor still connecting: the built-in list for now, the directory at a later call.
    if (TorNet.mode == TorNetMode.waiting) return;
    _dirNodesLoading = true;
    unawaited(
      dir
          .nodes(chain)
          .timeout(nodeTimeout)
          .then((list) {
            if (!statusSite.on) return;
            _dirNodes = list;
            _changed();
          }, onError: (Object e) => logWarn('desk', 'node directory: ${e.runtimeType}'))
          .whenComplete(() {
            _dirNodesLoading = false;
            _dirNodesAt = DateTime.now();
          }),
    );
  }

  @override
  Future<List<EpicboxServer>> epicboxes() async {
    final dir = relayDirectory;
    final at = _boxesAt;
    if (dir == null || preset.statusChain == null) return _builtInBoxes;
    if (_boxes != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) return _boxes!;
    // Tor still connecting: the list known now, read again by a later call once it is up.
    if (TorNet.mode == TorNetMode.waiting) return _boxes ?? _builtInBoxes;
    final failed = _boxesFailedAt;
    if (failed != null && DateTime.now().difference(failed) < const Duration(seconds: 30)) return _boxes ?? _builtInBoxes;
    try {
      final listed = await dir.relays(preset.statusChain!).timeout(nodeTimeout);
      if (!statusSite.on) return _builtInBoxes;
      _boxes = [
        for (final r in mergePublicRelays(listed))
          EpicboxServer(
            domain: r.relay.host,
            port: r.relay.port,
            operator: r.operator,
            health: switch (r.status?.healthy) { true => ServiceHealth.ok, false => ServiceHealth.down, null => ServiceHealth.checking },
            latencyMs: r.status?.latencyMs,
            icon: r.status?.icon,
            listedAs: r.status?.operator,
          ),
      ];
      _boxesAt = DateTime.now();
      _boxesFailedAt = null;
      return _boxes!;
    } on Object catch (e) {
      _boxesFailedAt = DateTime.now();
      logWarn('desk', 'epicbox status: ${e.runtimeType}');
      return _boxes ?? _builtInBoxes;
    }
  }

  @override
  Future<DeskSettings> settings() async => _settings;

  @override
  Future<String> epicboxAddress() async {
    final session = _open;
    // No Epicbox server in the list: LEPIC's is a placeholder (noEpicboxDomain), no address.
    if (_config?.epicboxDomain.isEmpty ?? false) return '';
    return session.epicboxAddress();
  }

  @override
  Future<String> httpAddress() async {
    final port = _httpPort;
    // Node only and Kill switch: no Link listener, so no address.
    if (_httpHealth != ServiceHealth.ok || port == null || NetGate.restricted) return '';
    // Local only binds 127.0.0.1, From the internet 0.0.0.0: this computer reaches both here.
    // The public address is httpReach's; the LAN address is never handed out as it.
    return 'http://127.0.0.1:$port';
  }

  @override
  Future<HttpReach?> httpReach({bool recheck = false}) async {
    final port = _httpPort;
    if (_httpExposure != core.HttpExposure.internet || port == null) return null;
    // Never asked while Tor is on (a Tor exit would answer for itself): the check needs Tor off.
    if (_settings.tor) return HttpReach(port: port, needsTorOff: true, checkedAt: DateTime.now());
    if (_httpHealth != ServiceHealth.ok) return null;
    // Node only and Kill switch ask nothing on the internet: the LAN address only.
    if (NetGate.restricted) return _reach.readLan(port);
    return _reach.read(port, recheck: recheck);
  }

  @override
  Future<String> torAddress() async {
    try {
      return 'http://${_onion ??= core.onionHost(await _open.onionAddress())}';
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  bool isOnionAddress(String to) => _service.validateOnionAddress(address: to.trim());

  @override
  bool isEpicboxAddress(String to) {
    // A chat-linked address (`https://<address>@<relay>/`) is the address.
    final read = parseRecipient(to);
    final t = read.kind == RecipientKind.epicbox ? read.address : to.trim();
    // `es` on mainnet, `zz` on a test network (LNX-6).
    if (!RegExp(r'^(es|zz)[0-9A-Za-z]{38,58}(@[\w.-]+(:\d+)?)?$').hasMatch(t)) return false;
    // LEPIC checks the key's checksum; it wants the server: an address without one names the
    // settings' `epicbox.default`.
    return _service.validateEpicboxAddress(address: t.contains('@') ? t : '$t@$defaultEpicboxHost');
  }

  @override
  bool epicboxAddressOtherChain(String to) => _service.epicboxAddressOtherChain(address: to.trim());

  // ---- Acting.

  @override
  Future<int> estimateFee(int amount) async {
    try {
      final f = await _open.estimateFee(amount: BigInt.from(amount), minimumConfirmations: _minConf);
      return f.fee.toInt();
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options}) async {
    try {
      final f = await _open.estimateFee(amount: BigInt.from(amount), minimumConfirmations: _minConf, options: options);
      return SendEstimate.fromFee(f);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<OutputPrefs> outputPrefs() => _store.outputPrefs(_openEntry?.walletId);

  @override
  Future<void> saveOutputPrefs(OutputPrefs prefs) => _store.saveOutputPrefs(_openEntry?.walletId, prefs);

  @override
  Future<int> minimumConfirmations() async {
    try {
      return await _open.minimumConfirmations();
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<void> setMinimumConfirmations(int count) async {
    final session = _open;
    try {
      await session.setMinimumConfirmations(count);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    // The core re-split the balance: count with the new number from here (sends, the list) and
    // read the balance, outputs and payments again without waiting for the node.
    if (_session != session) return;
    _summary = _summary?.copyWith(minimumConfirmations: BigInt.from(count));
    await _reload();
  }

  @override
  Future<SendEstimate> estimateSplit(int outputs) async {
    try {
      return SendEstimate.fromFee(await _open.estimateSplit(outputs: outputs, minimumConfirmations: _minConf));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<SelfSend> splitOutputs(int outputs) => _selfSend(() => _open.splitOutputs(outputs: outputs, minimumConfirmations: _minConf));

  @override
  Future<SendEstimate> estimateConsolidate() async {
    try {
      return SendEstimate.fromFee(await _open.estimateConsolidate(minimumConfirmations: _minConf));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<SelfSend> consolidateOutputs() => _selfSend(() => _open.consolidateOutputs(minimumConfirmations: _minConf));

  /// Runs a split or consolidate and brings balance and history up to date, failed or not:
  /// a self-send the node did not take is stored with its inputs locked.
  /// One the node did not take is stored as a new send: the error then names it
  /// ([DeskError.notPostedTx]) so it can be posted again or cancelled.
  Future<SelfSend> _selfSend(Future<core.SelfSentTx> Function() run) => _running(() async {
    final session = _open;
    Set<int?>? before;
    try {
      before = {for (final e in await session.transactions(refresh: false)) e.id};
      final t = await run();
      await _reload();
      return SelfSend(txId: t.txId, receivedTxId: t.receivedTxId, amount: t.amount.toInt(), fee: t.fee.toInt(), inputCount: t.inputCount, outputCount: t.outputCount);
    } on core.WalletError catch (e) {
      await _reload();
      final stored = before == null
          ? null
          : (await session.transactions(refresh: false)).where((x) => !before!.contains(x.id) && x.id != null).map((x) => x.id!).fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      if (stored != null) throw DeskError.l10n((l) => l.deskErrNotPosted, notPostedTx: stored);
      throw _deskError(e);
    }
  });

  @override
  Future<void> repostTx(int id) => _running(() async {
    if (!await _repost(_open, id)) throw DeskError.l10n((l) => l.deskErrNodeNotAnswering, nodeUnreachable: true);
  });

  @override
  Future<String> finishedPayment(int id) async {
    try {
      return await _open.finishedPaymentText(txId: id);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<List<String>> encodeQrSlate(String json) async {
    try {
      return await _service.encodeQrSlate(json: json, maxFragmentLen: core.qrFragmentLen, singleCodeMaxLen: core.qrSingleCodeMaxLen);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<core.QrSlateProgress> decodeQrSlate(List<String> parts) => _service.decodeQrSlate(parts: parts);

  @override
  Future<String> slateFileText(String path) async {
    try {
      return decodeSlateFile(await File(path).readAsBytes());
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    } on FileSystemException {
      throw DeskError.l10n((l) => l.deskErrFileNotReadable);
    }
  }

  @override
  Future<core.FinishedPayment> inspectFinished(String text) => _open.inspectFinished(text);

  @override
  Future<void> postFinished(String text) => _running(() async {
    if (NetGate.killSwitch) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    await _open.postFinished(text);
  });

  /// At unlock: sends each undelivered Epicbox send again once (the app was killed before the
  /// first attempt, or the relay refused it). A failure leaves it for the user's Send again.
  Future<void> _resendUndelivered(core.WalletSession session) async {
    try {
      final txs = await session.transactions(refresh: false);
      final sent = await resendUndelivered(session, txs, tag: 'desk', stillOpen: () => _session == session);
      if (sent && _session == session) await _reload();
    } on Object catch (err) {
      logWarn('desk', 'resend at unlock: ${err is core.WalletError ? err.kind.name : err.runtimeType}');
    }
  }

  @override
  Future<void> resendTx(int id) => _running(() async {
    final session = _open;
    try {
      final e = (await session.transactions(refresh: false)).where((t) => t.id == id).firstOrNull;
      if (e == null) throw DeskError.l10n((l) => l.deskErrTxNotFound);
      final to = e.counterparty ?? '';
      switch (e.transport) {
        case 'http':
          // Never through a Tor exit, whatever was allowed when it was sent.
          if (plainHttpHeldNow(to)) throw DeskError.l10n((l) => l.sendPlainHttpOffWithTor);
          // The user allowed plain HTTP to this address when sending.
          final sent = await session.resendHttp(txId: id, url: to, allowPlainHttp: plainHttpNeedsConsent(to));
          if (!sent.posted && !await _repost(session, id)) throw DeskError.l10n((l) => l.deskErrNodeRefused);
        case 'tor':
          if (!_torFeature) throw DeskError.l10n((l) => l.sendTorNotInVersion);
          if (!_torRuns) throw DeskError.l10n((l) => l.deskErrTorOffSend);
          final sent = await session.resendTor(txId: id, onion: to);
          if (!sent.posted && !await _repost(session, id)) throw DeskError.l10n((l) => l.deskErrNodeRefused);
        default:
          try {
            await session.resendEpicbox(key: e.key);
          } on core.WalletError catch (err) {
            final relay = recipientRelay(to);
            if (err.kind != core.WalletErrorKind.transportFailed || relay == null) rethrow;
            logWarn('desk', 'resend: ${err.kind.name} (${relay.label})');
            throw DeskError.l10n((l) => l.deskErrRelayNoAnswer(relay.label));
          }
      }
    } on core.WalletError catch (e) {
      logWarn('desk', 'resend: ${e.kind.name}');
      throw _deskError(e);
    }
    await _reload();
  });

  /// Calls that change the wallet (send, receive and finalize a file, split, consolidate,
  /// repost, cancel, scan) running now; the fallback and the user's node moves wait for them too. LEPIC ends running calls at lock, maybe after storing their
  /// effect, so [lock] waits for them instead.
  int _busy = 0;
  Completer<void>? _idle;

  /// A lock waits for [_busy]: no new payment starts until it is done.
  bool _locking = false;

  @override
  bool get busy => _busy - (_rescanning ? 1 : 0) > 0;

  /// Done once no such call runs.
  Future<void> whenIdle() => _busy == 0 ? Future<void>.value() : (_idle ??= Completer<void>()).future;

  /// Runs [call] on the session once no switch is under way; counted while it runs. The check
  /// and the count follow each other with no await, so a switch or a lock never overtakes it.
  Future<T> _running<T>(Future<T> Function() call) async {
    if (_locking) throw DeskError.l10n((l) => l.deskErrWalletLocking, locked: true);
    while (_switching != null) {
      await _switching!.future;
      if (_locking) throw DeskError.l10n((l) => l.deskErrWalletLocking, locked: true);
    }
    _busy++;
    try {
      return await call();
    } finally {
      _opEnded();
    }
  }

  @override
  Future<SendEstimate> estimateMax() async {
    try {
      return SendEstimate.fromFee(await _open.estimateMax(minimumConfirmations: _minConf));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<SendResult> send(SendRequest r) => _running(() => _send(r));

  Future<SendResult> _send(SendRequest r) async {
    final session = _open;
    // Send all sends the reviewed amount: when it no longer fits, LEPIC refuses (not enough
    // funds) and the user reviews again, rather than paying an amount they did not see.
    final amount = r.amount;
    // The build without Tor reaches no onion, whatever the method (Send says so first).
    if (!_torFeature && r.pairingId == null && addressKindOf(r.to ?? '') == AddressKind.tor) return SendFailed.l10n((l) => l.sendTorNotInVersion);
    // An onion pasted under Direct goes over Tor.
    final method = _torFeature && r.method == TxMethod.http && isOnionAddress(r.to ?? '') ? TxMethod.tor : r.method;
    // The rows before a direct send, to tell a send LEPIC stored from one it refused.
    SendBefore? before;
    try {
      final message = r.message?.trim().isEmpty ?? true ? null : r.message!.trim();
      switch (method) {
        // Through a paired contact's mailbox, sealed (RFC 9.1): LEPIC checks the pairing first
        // and queues the payment in its outbox, also while Epicbox is off.
        case TxMethod.epicbox when r.pairingId != null:
          final e = await session.pairing.sendViaMailbox(id: r.pairingId!, amount: BigInt.from(amount), minimumConfirmations: _minConf, message: message, options: r.options);
          await _reload();
          return SendDone(_txFor(e));
        case TxMethod.epicbox:
          final to = (r.to ?? '').trim();
          if (!_service.validateEpicboxAddress(address: to)) return SendFailed.l10n((l) => l.deskErrNotEpicboxAddress);
          final e = await session.sendEpicbox(amount: BigInt.from(amount), minimumConfirmations: _minConf, address: to, message: message, options: r.options);
          await _reload();
          return SendDone(_txFor(e));
        case TxMethod.file:
          final slate = await session.createSendSlate(amount: BigInt.from(amount), minimumConfirmations: _minConf, message: message, options: r.options);
          // Sealed for a paired contact (RFC 9.2): only its wallet opens the file.
          final sealed = r.sealFor == null ? null : await session.pairing.sealSlate(id: r.sealFor!, slateJson: slate.json);
          final File file;
          try {
            file = await _writeSendFile(sealed == null ? sendFileName(slate.slateId) : sealedFileName(slate.slateId), sealed ?? slate.json);
          } on FileSystemException catch (e) {
            // The payment exists in the wallet; only its file is missing.
            logWarn('desk', 'slate file not written: ${e.osError?.errorCode ?? '?'}');
            await _reload();
            return SendFailed.l10n((l) => l.deskErrFileNotSaved, inActivity: true);
          }
          await _reload();
          final tx = _txs().where((t) => t.slateId == slate.slateId).firstOrNull ??
              Tx(id: -1, slateId: slate.slateId, direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: amount, fee: 0, created: DateTime.now(), counterparty: file.path);
          return SendFileReady(tx, file.path, sealedFor: sealed == null ? null : r.sealFor);
        case TxMethod.http:
          final to = (r.to ?? '').trim();
          if (httpAddressProblem(to) != null) return SendFailed.l10n((l) => httpAddressProblem(to, l)!);
          // Plain HTTP never goes through a Tor exit (tor_routes.dart, torStops).
          if (plainHttpHeldNow(to)) return SendFailed.l10n((l) => l.sendPlainHttpOffWithTor);
          // The review is the consent to plain HTTP (Send says "Not encrypted"); LEPIC refuses it otherwise.
          if (plainHttpNeedsConsent(to) && !r.allowPlainHttp) return SendFailed.l10n((l) => l.deskErrPlainHttp);
          before = await SendBefore.take(session);
          final sent = await session.sendHttp(
            amount: BigInt.from(amount),
            minimumConfirmations: _minConf,
            url: to,
            allowPlainHttp: r.allowPlainHttp && plainHttpNeedsConsent(to),
            message: message,
            options: r.options,
          );
          return await _directDone(session, sent, method, amount, to);
        case TxMethod.tor:
          final to = (r.to ?? '').trim();
          if (!isOnionAddress(to)) return SendFailed.l10n((l) => l.deskErrNotOnion);
          if (!_torRuns) return SendFailed.l10n((l) => l.deskErrTorOffSend);
          if (!_torCanSend) return SendFailed.l10n((l) => l.deskErrTorConnecting);
          before = await SendBefore.take(session);
          final sent = await session.sendTor(amount: BigInt.from(amount), minimumConfirmations: _minConf, onion: to, message: message, options: r.options);
          return await _directDone(session, sent, method, amount, to);
      }
    } on core.WalletError catch (e) {
      await _reload();
      // LEPIC stores an HTTP send and locks its inputs before it delivers: whatever fails after
      // that leaves the payment in Activity.
      // Rows that cannot be read again count as stored: say what is safe, that it may wait.
      final stored = before != null && (await before.leftBehind(to: (r.to ?? '').trim(), amount: BigInt.from(amount), match: SentToMatch.host)).stored;
      // A mailbox send that fails leaves nothing behind: LEPIC refuses before it locks the
      // coins, or cancels what it made.
      if (r.pairingId != null) return SendFailed.l10n((l) => deskErrorText(e, l));
      if (e.kind == core.WalletErrorKind.transportFailed) {
        if (method == TxMethod.http || method == TxMethod.tor) {
          return stored
              ? SendFailed.l10n((l) => l.deskErrRecipientNoAnswerWaits, inActivity: true)
              : SendFailed.l10n((l) => l.deskErrRecipientNoAnswer);
        }
        // The relay is named: a mistyped domain is the usual reason it never answers.
        final relay = recipientRelay((r.to ?? '').trim());
        return relay == null
            ? SendFailed.l10n((l) => l.deskErrNotDelivered, inActivity: true)
            : SendFailed.l10n((l) => l.deskErrNotDeliveredRelay(relay.label), inActivity: true);
      }
      // Ended by a lock (the app's own lock waits; the wallet can still close under it): the
      // send may have been stored as sent, so the next unlock's Activity tells.
      if (lepicCancelled(e)) return SendFailed.l10n((l) => l.deskErrInterruptedLock, inActivity: true);
      if (stored) return SendFailed.l10n((l) => l.deskErrStoredWaits(deskErrorText(e, l).replaceFirst(RegExp(r'\.$'), '')), inActivity: true);
      return SendFailed.l10n((l) => deskErrorText(e, l));
    }
  }

  /// A direct send the other wallet answered: done, or posted again once when the node did not
  /// take it.
  Future<SendResult> _directDone(core.WalletSession session, core.HttpSent sent, TxMethod method, int amount, String to) async {
    await _reload();
    final tx = _txs().where((t) => t.id == sent.txId).firstOrNull ??
        Tx(id: sent.txId, slateId: sent.slateId, direction: TxDirection.sent, state: TxState.posted, method: method, amount: amount, fee: 0, created: DateTime.now(), counterparty: to);
    if (!sent.posted) {
      if (!await _repost(session, sent.txId)) {
        return SendFailed.l10n((l) => l.deskErrNodeRefused, inActivity: true);
      }
      return SendDone(_txs().where((t) => t.id == sent.txId).firstOrNull ?? tx);
    }
    return SendDone(tx);
  }

  /// Posts a finished HTTP send again, once, when the node did not take it. True when it did.
  Future<bool> _repost(core.WalletSession session, int txId) async {
    final String? key;
    try {
      key = (await session.transactions(refresh: false)).where((t) => t.id == txId).firstOrNull?.key;
    } on core.WalletError catch (e) {
      logWarn('desk', 'repost: ${e.kind.name}');
      return false;
    }
    if (key == null) return false;
    try {
      await session.repostTransaction(key: key);
    } on core.WalletError catch (e) {
      logWarn('desk', 'repost: ${e.kind.name}');
      return false;
    }
    await _reload();
    return true;
  }

  Future<String> _readSlate(String path) async {
    try {
      return decodeSlateFile(await File(path).readAsBytes());
    } on FileSystemException {
      throw DeskError.l10n((l) => l.deskErrFileNotReadable, unreadable: true);
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    }
  }

  /// Writes a file send's [text] as [name] in the app's files folder, never over another file.
  Future<File> _writeSendFile(String name, String text) async {
    final dir = await _filesDir();
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}${uniqueFileName(name, (n) => File('${dir.path}${Platform.pathSeparator}$n').existsSync())}');
    await file.writeAsString(text, flush: true);
    return file;
  }

  @override
  Future<String> plainFile(String slateId) => _running(() async {
    final String plain;
    try {
      plain = await _open.pairing.plainSlate('s:$slateId');
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    try {
      return (await _writeSendFile(sendFileName(slateId), plain)).path;
    } on FileSystemException catch (e) {
      logWarn('desk', 'plain slate file not written: ${e.osError?.errorCode ?? '?'}');
      throw DeskError.l10n((l) => l.deskErrFileNotSaved);
    }
  });

  /// Signs the slate in [fileName] (a path) and writes the answer beside it, named after it
  /// ([replyFileName]); in the app's files folder when that folder cannot be written.
  @override
  Future<ReceivedFile> receiveFile(String fileName) => _running(() => _receiveFile(fileName));

  Future<ReceivedFile> _receiveFile(String fileName) async => _receiveJson(await _readSlate(fileName), fileName);

  @override
  Future<ReceivedFile> receiveText(String text) => _running(() async {
    final String json;
    try {
      json = decodeSlateFile(utf8.encode(text));
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    }
    // The answer goes where a file of that name in the files folder would put it.
    return _receiveJson(json, '${(await _filesDir()).path}${Platform.pathSeparator}pasted', pasted: true);
  });

  /// Signs [json], read from [fileName], and writes the answer beside it.
  Future<ReceivedFile> _receiveJson(String json, String fileName, {bool pasted = false}) async {
    if (isSealedText(json)) return _receiveSealed(json, fileName);
    try {
      final answer = await _open.receiveSlate(slateJson: json);
      final response = await _writeResponse(fileName, answer.slateId, answer.json, named: !pasted);
      await _reload();
      final tx = _txs().where((t) => t.slateId == answer.slateId).firstOrNull ??
          Tx(id: -1, slateId: answer.slateId, direction: TxDirection.received, state: TxState.posted, method: TxMethod.file, amount: 0, fee: 0, created: DateTime.now(), counterparty: fileName);
      return ReceivedFile(tx, response);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// Signs the sealed [text] read from [fileName] through the pairing it came from (RFC 9.2):
  /// the answer is sealed back to that contact when it can be, and the sender is the
  /// pairing's name. Only a sealed file names its sender.
  Future<ReceivedFile> _receiveSealed(String text, String fileName) async {
    final session = _open;
    try {
      final opened = await session.pairing.openSlate(text);
      final reply = await session.pairing.receiveSealed(text);
      final response = await _writeResponse(fileName, reply.slateId, reply.answer, named: false, sealed: reply.sealed);
      await _reload();
      final sender = _pairedName(await session.pairing.pairings(), await _contactsOr(), opened.pairingId);
      final tx = _txs().where((t) => t.slateId == reply.slateId).firstOrNull ??
          Tx(id: -1, slateId: reply.slateId, direction: TxDirection.received, state: TxState.posted, method: TxMethod.file, amount: 0, fee: 0, created: DateTime.now(), pairingId: opened.pairingId, contactName: sender);
      return ReceivedFile(tx, response, sender: sender);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// Writes the response beside [fileName], or in the app's files folder when that fails;
  /// [named]: called after [fileName] ([replyFileName]). Returns the path written.
  Future<String> _writeResponse(String fileName, String slateId, String json, {bool named = true, bool sealed = false}) async {
    final sep = Platform.pathSeparator;
    final dirOf = File(fileName).parent.path;
    // A sealed answer is its own file type (RFC 3.5).
    final name = sealed ? sealedFileName(slateId) : replyFileName(slateId, loaded: named ? fileName.split(RegExp(r'[\\/]')).last : null);
    final beside = '$dirOf$sep${uniqueFileName(name, (n) => File('$dirOf$sep$n').existsSync())}';
    try {
      await File(beside).writeAsString(json, flush: true);
      return beside;
    } on FileSystemException catch (e) {
      logWarn('desk', 'response not written beside the slate: ${e.osError?.errorCode ?? '?'}');
    }
    try {
      final dir = await _filesDir();
      await dir.create(recursive: true);
      final path = '${dir.path}$sep${uniqueFileName(name, (n) => File('${dir.path}$sep$n').existsSync())}';
      await File(path).writeAsString(json, flush: true);
      return path;
    } on FileSystemException {
      throw DeskError.l10n((l) => l.deskErrResponseNotSaved);
    }
  }

  @override
  Future<bool> isResponseText(String text) async {
    try {
      if (isSealedText(text.trim())) {
        final stage = (await _open.pairing.openSlate(text)).stage;
        return stage == core.SlateStage.response || stage == core.SlateStage.requestAnswer;
      }
      final info = await _service.inspectSlate(json: decodeSlateFile(utf8.encode(text)));
      return info.stage == core.SlateStage.response || info.stage == core.SlateStage.requestAnswer;
    } on Object {
      return false;
    }
  }

  @override
  Future<RequestFile?> readRequestFile(String path) async => _readRequest(await _readSlate(path), path);

  @override
  Future<RequestFile?> readRequestText(String text) async {
    final String json;
    try {
      json = decodeSlateFile(utf8.encode(text));
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    }
    return _readRequest(json, '${(await _filesDir()).path}${Platform.pathSeparator}pasted');
  }

  /// [json] as a payment request, or null when it is any other slate (or none: signing says
  /// why). The fee is estimated now; the message is the issuer's, cleaned, never checked.
  Future<RequestFile?> _readRequest(String json, String source) async {
    final core.SlateInfo info;
    try {
      info = await _service.inspectSlate(json: json);
    } on core.WalletError {
      return null;
    }
    if (info.stage != core.SlateStage.request) return null;
    int? fee;
    try {
      fee = (await _open.estimateFee(amount: info.amount, minimumConfirmations: _minConf)).fee.toInt();
    } on core.WalletError {
      // Too little to spend, or the node is away: the Review says so.
    }
    final paid = (_entries ?? const <core.TxEntry>[]).any((t) => t.slateId == info.slateId && t.kind == core.TxKind.sent);
    return RequestFile(
      slateId: info.slateId,
      amount: info.amount.toInt(),
      fee: fee ?? 0,
      feeKnown: fee != null,
      message: _line(core.messageBy(info.messages, core.SlateRole.receiver) ?? info.messages.firstOrNull?.text),
      json: json,
      source: source,
      alreadyPaid: paid,
    );
  }

  /// The only call that pays a request file: its Review's Approve, after the password, which
  /// is checked here first. LEPIC refuses an amount other than the one signed into it.
  @override
  Future<ReceivedFile> payRequestFile(RequestFile file, {required String password}) => _running(() async {
    final session = _open;
    if (!await checkPassword(password)) throw const InvoiceError(InvoiceProblem.wrongPassword, 'Wrong password'); // l10n-ok
    final core.PaidRequestFile paid;
    try {
      paid = await session.payRequestFile(slateJson: file.json, amount: BigInt.from(file.amount));
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    final response = await _writeResponse(file.source, paid.slateId, paid.json);
    await _reload();
    final tx = _txs().where((t) => t.id == paid.txId).firstOrNull ??
        Tx(id: paid.txId, slateId: paid.slateId, direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: paid.amount.toInt(), fee: paid.fee.toInt(), created: DateTime.now());
    return ReceivedFile(tx, response);
  });

  @override
  Future<Tx> finalizeText(String text) => _running(() async {
    final String json;
    try {
      json = decodeSlateFile(utf8.encode(text));
    } on FormatException {
      throw DeskError.l10n((l) => l.deskErrNotTxFile2, wrongType: true);
    }
    return _finalizeJson(json);
  });

  @override
  Future<Tx> finalizeFile(String fileName) => _running(() async => _finalizeJson(await _readSlate(fileName)));

  Future<Tx> _finalizeJson(String json) async {
    // The sealed answer to a sealed send (RFC 9.2) finalizes through its pairing.
    final sealed = isSealedText(json);
    if (!sealed) await _checkRequestAnswer(json);
    try {
      final e = sealed ? await _open.pairing.finalizeSealed(json) : await _open.finalizeAndPost(slateJson: json);
      await _reload();
      return _txFor(e);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// Refuses the answer to a request this wallet no longer has, or that ended or is paid
  /// (DESIGN §3.4), in the screens' words; anything else goes on to finalizing.
  Future<void> _checkRequestAnswer(String json) async {
    final core.IssuedInvoice? issued;
    try {
      final info = await _service.inspectSlate(json: json);
      if (info.stage != core.SlateStage.requestAnswer) return;
      issued = await _open.issuedInvoice(slateId: info.slateId);
    } on core.WalletError {
      return;
    }
    if (issued == null) throw DeskError.l10n((l) => l.reqAnswerUnknown);
    switch (issued.state) {
      case core.IssuedInvoiceState.waiting:
        return;
      case core.IssuedInvoiceState.paid:
        throw DeskError.l10n((l) => l.reqFileAlreadyPaid);
      default:
        throw DeskError.l10n((l) => l.reqFileEnded);
    }
  }

  @override
  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) => _running(() async {
    if (id < 0) throw DeskError.l10n((l) => l.deskErrCannotCancel);
    final CancelResult result;
    try {
      // Read fresh: whether the cancel also spends the coins back follows its state now.
      final entry = (await _open.transactions(refresh: false)).where((e) => e.id == id).firstOrNull;
      if (entry == null) {
        await _open.cancelTransaction(txId: id);
        result = CancelResult.cancelled;
      } else {
        result = await _cancels.cancel(_open, entry, spendBack: spendBack);
      }
    } on core.WalletError catch (e) {
      // The core asks the node first and refuses a payment it already has (in its pool or a block).
      if (e.kind == core.WalletErrorKind.invalidArgument) throw DeskError.l10n((l) => l.deskErrCancelRefused, cancelRefused: true);
      throw _deskError(e);
    }
    await _reload();
    return result;
  });

  @override
  Future<String> exportProof(int id) => throw UnsupportedError('payment proofs (DeskFeatures.paymentProofs)');

  @override
  Future<String> saveContact(Contact contact) async {
    try {
      final stored = await _open.saveContact(
        contact: core.Contact(
          id: contact.id,
          name: contact.name,
          epicbox: contact.epicbox,
          http: contact.http,
          tor: contact.tor,
          epic1: contact.epic1,
          note: contact.note,
          label: contact.label,
        ),
      );
      final favourites = await _favourites();
      contact.favourite ? favourites.add(stored.id) : favourites.remove(stored.id);
      await _store.writeJson(_favouritesKey, favourites.toList());
      return stored.id;
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await _open.deleteContact(id: id);
    // A seeded contact the user deleted never comes back on this computer.
    final session = _session;
    final key = _metaKey(_openEntry?.walletId);
    await _seedLocked(() async {
      if (_session != session) return;
      final seeds = await _seedRecords(key);
      final seeded = seeds.entries.where((e) => e.value['contact'] == id).map((e) => e.key).toList();
      if (seeded.isEmpty) return;
      for (final k in seeded) {
        seeds[k] = {...seeds[k]!, 'deleted': true};
      }
      await _setMeta({'seeds': seeds}, key);
    });
    final favourites = await _favourites();
    if (favourites.remove(id)) await _store.writeJson(_favouritesKey, favourites.toList());
  }

  // ---- Seed contacts.

  /// Reads the website's list ([fetchSeeds] in the app); null reads nothing (tests).
  final Future<String?> Function(Uri url)? _seedFetch;

  /// The keys that may sign btlabs.json (the test keyring in tests).
  final Keyring _keyring;

  /// BT Labs' onion mapping: built in, replaced by a verified btlabs.json that lists onions.
  final OnionDirectory onions;

  /// The website's list, read once per app start (or the last good copy); null until then.
  List<SeedContact>? _webSeeds;
  bool _seedFetchStarted = false;

  /// One seed read-modify-write at a time (open, the website's refresh, a delete), so two
  /// never interleave and none writes into a wallet opened after it started.
  /// The running one, null when idle. Nothing is chained onto a future made at construction:
  /// that one belongs to whatever zone built the wallet (a widget test's fake clock), and a
  /// callback on it would wait for that clock.
  Future<void>? _seedRunning;

  Future<void> _seedLocked(Future<void> Function() body) async {
    while (_seedRunning != null) {
      await _seedRunning;
    }
    final done = Completer<void>();
    _seedRunning = done.future;
    try {
      await body();
    } finally {
      _seedRunning = null;
      done.complete();
    }
  }

  /// The website's seed contacts file, or null when it did not answer with one.
  static Future<String?> fetchSeeds(Uri url) async {
    try {
      final r = await httpGet(url, timeout: const Duration(seconds: 5), maxBytes: btlabsMaxEnvelopeBytes);
      return r.status == 200 ? r.body : null;
    } on NetError {
      return null; // Over the size cap, or no answer.
    }
  }

  /// Per wallet: seed id → the contact it made, its name, address and note as last written,
  /// deleted.
  Future<Map<String, Map<String, dynamic>>> _seedRecords([String? key]) async {
    final j = (await _meta(key))['seeds'];
    return {
      if (j is Map)
        for (final e in j.entries)
          if (e.value is Map) '${e.key}': Map<String, dynamic>.from(e.value as Map),
    };
  }

  /// The website may update only the contacts the app ships with (by id); it never adds one.
  static List<SeedContact> _knownSeeds(List<SeedContact>? web) {
    final ids = {for (final c in bundledSeedContacts) c.id};
    return [...?web?.where((c) => ids.contains(c.id))];
  }

  /// On every open: a seed contact the wallet never had is added now (the bundled one at
  /// once, never waiting for the network); one the user did not edit follows the website's
  /// copy; one the user deleted or edited is left alone. A failure changes nothing.
  Future<void> _seedContacts() async {
    try {
      final web = await _cachedWebSeeds();
      await _applySeeds([...bundledSeedContacts, ..._knownSeeds(web)]);
    } on Object catch (e) {
      logWarn('desk', 'seed contacts not applied: ${e.runtimeType}');
    }
    if (!_seedFetchStarted && _seedFetch != null) {
      _seedFetchStarted = true;
      unawaited(_refreshWebSeeds());
    }
  }

  static Map<String, Object?> _seedRecord(String contact, SeedContact s) =>
      {'contact': contact, 'name': s.name, 'address': s.address, 'note': s.note, 'deleted': false};

  /// Applies [list] to the wallet open now; stops without writing when another one opens or
  /// the wallet locks meanwhile.
  Future<void> _applySeeds(List<SeedContact> list) {
    final session = _session;
    if (session == null) return Future.value();
    final key = _metaKey(_openEntry?.walletId);
    return _seedLocked(() async {
      if (_session != session) return;
      // A later entry (the website's) wins over an earlier one (the bundled) with the same id.
      final byId = {for (final c in list) c.id: c};
      final seeds = await _seedRecords(key);
      final stored = {for (final c in await session.contacts()) c.id: c};
      final claimed = {for (final r in seeds.values) r['contact']};
      var changed = false;
      for (final s in byId.values) {
        if (_session != session) return;
        final rec = seeds[s.id];
        if (rec == null) {
          // A contact with this address already (the user's, or one a failed earlier write
          // inserted) becomes the seed's: no second row.
          final same = stored.values.where((c) => c.address == s.address && !claimed.contains(c.id)).firstOrNull;
          if (same != null) {
            // Recorded with the seed's values: a name or note the user chose counts as edited.
            seeds[s.id] = _seedRecord(same.id, s);
          } else {
            final saved = await session.saveContact(contact: core.Contact(id: '', name: s.name, address: s.address, note: s.note));
            seeds[s.id] = _seedRecord(saved.id, s);
          }
          claimed.add(seeds[s.id]!['contact']);
          changed = true;
        } else if (rec['deleted'] != true) {
          final c = stored[rec['contact']];
          // Untouched: every field as the app last wrote it (a record without name and note
          // predates them and is judged by its address).
          final untouched = c != null &&
              c.address == rec['address'] &&
              (!rec.containsKey('name') || c.name == rec['name']) &&
              (!rec.containsKey('note') || c.note == rec['note']);
          if (untouched && (c.address != s.address || c.name != s.name || c.note != s.note)) {
            await session.saveContact(contact: core.Contact(id: c.id, name: s.name, address: s.address, note: s.note, label: c.label));
            seeds[s.id] = _seedRecord(c.id, s);
            changed = true;
          }
        }
      }
      if (changed && _session == session) {
        await _setMeta({'seeds': seeds}, key);
        _changed();
      }
    });
  }

  static const _btlabsCacheKey = 'desk.btlabsPublic';

  /// The keys the last accepted update.json revoked (its stored state, [updateStateKey]): they
  /// sign no btlabs.json either.
  Future<Set<String>> _updateRevoked() async {
    try {
      return ManifestState.fromJson(await _store.readJson(updateStateKey))?.revoked ?? const {};
    } on Object {
      return const {};
    }
  }

  /// The last accepted file's seed contacts, re-checked (signer still trusted, signature and
  /// digest as stored); null when there is none or it no longer checks out.
  Future<List<SeedContact>?> _cachedWebSeeds() async {
    if (_webSeeds != null) return _webSeeds;
    final j = await _store.readJson(_btlabsCacheKey);
    if (j is! Map || j['envelope'] is! String) return null;
    final state = ManifestState.fromJson(j['state']);
    if (state == null) return null;
    final file = await loadCachedBtlabsPublic(j['envelope'] as String, keyring: _keyring, state: state, alsoRevoked: await _updateRevoked());
    if (file == null) return null;
    onions.adopt(file);
    await _applyOnions(_session);
    final list = seedContactsFrom(file, validAddress: isEpicboxAddress);
    useSignedDonation(list);
    useSignedLinks(file);
    return list;
  }

  /// Reads btlabs.json once per app run, in the background; applies it to the open wallet when
  /// it verifies and is not older than what the app has. Node only and Kill switch read
  /// nothing; with Tor on it goes through tor or not at all (`httpGet`). Anything else changes
  /// nothing: the last good copy stays in use.
  Future<void> _refreshWebSeeds() async {
    try {
      final raw = await _store.readJson(_btlabsCacheKey);
      final j = raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
      if (NetGate.restricted) return;
      // One refresher per app run (_seedFetchStarted), so this read-modify-write cannot race.
      await _store.writeJson(_btlabsCacheKey, {...j, 'tried': DateTime.now().millisecondsSinceEpoch});
      // No signed file in app-config.toml: nothing to read.
      final signed = btlabsPublicUrl;
      if (signed == null) return;
      final body = await _seedFetch!(Uri.parse(signed));
      if (body == null) return;
      final stored = ManifestState.fromJson(j['state']);
      final r = await verifyBtlabsPublic(body, keyring: _keyring, state: stored, now: DateTime.now().toUtc(), alsoRevoked: await _updateRevoked());
      switch (r) {
        case Rejected(:final reason):
          logInfo('desk', 'btlabs.json not used: ${reason.code}');
          return;
        case Accepted(:final manifest, :final state):
          // Also when unchanged: the payload is byte-identical and just verified, so storing
          // this body repairs a cached envelope that no longer checks out.
          final now = DateTime.now().millisecondsSinceEpoch;
          await _store.writeJson(_btlabsCacheKey, {'at': now, 'tried': now, 'envelope': body, 'state': state.toJson()});
          onions.adopt(manifest);
          await _applyOnions(_session);
          final list = seedContactsFrom(manifest, validAddress: isEpicboxAddress);
          useSignedDonation(list);
          useSignedLinks(manifest);
          _webSeeds = list;
          await _applySeeds([...bundledSeedContacts, ..._knownSeeds(list)]);
      }
    } on Object catch (e) {
      logInfo('desk', 'btlabs.json not read: ${e.runtimeType}');
    }
  }

  /// A change of the HTTP listener's port or reach restarts it when it runs or failed; the
  /// switch itself goes through [setHttpListening].
  @override
  Future<void> saveSettings(DeskSettings settings) async {
    final old = _settings;
    final mode = netModeOf(settings.advanced.networkMode);
    // Tor only keeps the Tor switch on (network_gate.dart).
    if (mode == NetworkMode.torOnly && !settings.torAutostart) settings = settings.copyWith(torAutostart: true);
    // Link · HTTP (Settings › Transactions) is the one HTTP switch: the listener runs now and
    // at unlock while it is on ([DeskSettings.directHttp] and [DeskSettings.httpAutostart]
    // follow it, for the data layer and older builds).
    settings = settings.copyWith(directHttp: settings.payments.linkHttp, httpAutostart: settings.payments.linkHttp);
    // Tor is the open wallet's, changed only through setTor.
    _settings = settings.copyWith(tor: old.tor);
    final moved = settings.httpPort != old.httpPort || settings.publicMode != old.publicMode;
    if (_session != null && (moved || settings.httpAutostart != old.httpAutostart || settings.httpReachAck != old.httpReachAck)) {
      await _store.saveHttpPrefs(
        _openEntry?.walletId,
        HttpPrefs(publicMode: settings.publicMode, port: settings.httpPortChosen, autostart: settings.httpAutostart, reachAck: settings.httpReachAck),
      );
    }
    if (_session != null && (settings.epicboxAutostart != old.epicboxAutostart || settings.torAutostart != old.torAutostart)) {
      await _store.saveAutostart(_openEntry?.walletId, AutostartPrefs(epicbox: settings.epicboxAutostart, tor: settings.torAutostart));
    }
    if (settings.torAutostart != old.torAutostart) await _store.saveTorSwitch(settings.torAutostart);
    _torSaved = settings.torAutostart;
    _followTor();
    if (moved && _session != null && (_http != null || _httpHealth == ServiceHealth.down)) {
      await _stopHttp();
      if (settings.directHttp && !NetGate.restricted) await setHttpListening(true);
    }
    NetGate.setExperimental(settings.advanced);
    final was = netModeOf(old.advanced.networkMode);
    if (mode != was) await _applyMode(was, mode);
    if (settings.payments.epicbox != old.payments.epicbox) await _applyEpicboxSwitch(settings.payments.epicbox);
    if (settings.payments.linkHttp != old.payments.linkHttp && !moved) await _applyLinkHttpSwitch(settings.payments.linkHttp);
    if (settings.payments.linkTor != old.payments.linkTor) {
      logInfo('desk', 'link tor switch ${settings.payments.linkTor ? 'on' : 'off'}');
      await _syncTorPay();
    } else if (settings.torAutostart != old.torAutostart && _session != null) {
      await _routeTor(_session!);
    }
  }

  /// The Link · HTTP switch (Settings › Transactions) changed while running: on starts the
  /// clearnet listener (unless Tor is on or the mode holds it, as [setHttpListening] says),
  /// off stops it. The gate reads the switch for sends ([NetGate.checkMethod]).
  Future<void> _applyLinkHttpSwitch(bool on) async {
    logInfo('desk', 'link http switch ${on ? 'on' : 'off'}');
    if (_session == null) return;
    if (!on) return _stopHttp();
    if (NetGate.restricted) return;
    try {
      await setHttpListening(true);
    } on Object catch (e) {
      logWarn('desk', 'link http on: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
    }
  }

  /// The Epicbox switch (Settings › Transactions) changed while running: off stops the
  /// listener and the invoice timers (nothing connects to a relay until it is on again); on
  /// starts the invoices again and, with Start with the wallet, the listener. One gate with
  /// the network mode (network_gate.dart): the sends and invoice calls read it there.
  Future<void> _applyEpicboxSwitch(bool on) async {
    NetGate.setPayments(_settings.payments);
    logInfo('desk', 'epicbox switch ${on ? 'on' : 'off'}');
    final session = _session;
    if (session == null) return;
    if (!on) {
      _stopInvoices();
      await _stopListener();
      _epicboxHealth = ServiceHealth.off;
      _changed();
      return;
    }
    if (NetGate.restricted) return;
    _startInvoices();
    if (_settings.epicboxAutostart) {
      try {
        await setEpicboxListening(true);
      } on Object catch (e) {
        logWarn('desk', 'epicbox on: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    _changed();
  }

  /// What ran when Node only or Kill switch began, started again when it ends.
  ({bool listening, bool http, bool tor})? _beforeOffline;

  /// A new network mode, while running: Node only stops everything but the node (and the
  /// user's Tor, which carries it); Kill switch stops everything, Tor, the node poll and the
  /// built-in node included, and keeps the wallet open on its own files; Tor only turns the
  /// Tor switch on and Tor with it; leaving them starts again what ran (or, when they began
  /// locked, what Start with the wallet says) without a restart. Locked, only the mode
  /// changes; the unlock reads it.
  Future<void> _applyMode(NetworkMode was, NetworkMode now) async {
    NetGate.set(now);
    logInfo('desk', 'network mode ${now.name}');
    final session = _session;
    final wasOff = was == NetworkMode.nodeOnly || was == NetworkMode.killSwitch;
    if (now == NetworkMode.nodeOnly || now == NetworkMode.killSwitch) {
      if (session != null) {
        _beforeOffline ??= (listening: _listener != null, http: _http != null, tor: _settings.tor);
        _stopInvoices();
        await _stopListener();
        await _stopHttp();
        _epicboxHealth = ServiceHealth.off;
        if (now == NetworkMode.killSwitch) {
          await _stopTor();
          _settings = _settings.copyWith(tor: false);
          _stopPoll();
          await _stopScanForUser();
          _nodeHealth = ServiceHealth.off;
          await _reopenForKillSwitch();
        } else if (was == NetworkMode.killSwitch) {
          await _reopenForKillSwitch();
          // Node only after Kill switch: the node again, over Tor when the switch is on.
          final tor = _torFeature && (_beforeOffline?.tor ?? _settings.torAutostart);
          _startPoll();
          unawaited(_checkTip());
          unawaited(sync());
          if (tor) {
            _settings = _settings.copyWith(tor: true);
            _torStartRetries = 0;
            unawaited(_startTor());
          }
        } else if (_tor != null && _settings.tor) {
          // Into Node only with tor running: it published the onion, so it starts again
          // without it (startTor(publishOnion:)), carrying the node only.
          await _restartTorForOnion();
        }
        // Tor for payments stops: Node only and Kill switch block it.
        if (!_settings.tor) await _syncTorPay();
      }
      // Kill switch: no connection at all, so the built-in node stops too (leaving it starts
      // it again when it was on). Node only keeps it: it is then the node in use.
      if (now == NetworkMode.killSwitch) await _node?.stop();
      _followTor();
      _changed();
      return;
    }
    // Out of Tor only into Normal: Tor for every connection was the mode's, and no other
    // control turns it on any more (the Tor switch is gone), so it goes with the mode.
    // Link · Tor keeps its own tor.
    if (was == NetworkMode.torOnly && now == NetworkMode.standard) {
      _torSaved = false;
      if (_settings.torAutostart) {
        _settings = _settings.copyWith(torAutostart: false);
        await _store.saveTorSwitch(false);
      }
      if (_settings.tor && session != null) await setTor(false);
    }
    if (now == NetworkMode.torOnly) {
      _torSaved = true;
      if (!_settings.torAutostart) {
        _settings = _settings.copyWith(torAutostart: true);
        await _store.saveTorSwitch(true);
      }
      _epicboxOverTor = true;
      await _session?.setEpicboxOverTor(true);
      // Its clearnet listener goes; the onion one comes with Tor.
      await _stopHttp();
    }
    if (wasOff) {
      if (was == NetworkMode.killSwitch) await _reopenForKillSwitch();
      // Out of Node only with tor running: it started without the onion, so it starts again
      // with it.
      if (was == NetworkMode.nodeOnly && _tor != null) await _restartTorForOnion();
      final before = _beforeOffline;
      _beforeOffline = null;
      if (session != null) {
        final tor = _torFeature && (now == NetworkMode.torOnly || (before?.tor ?? _settings.torAutostart));
        if (tor) _settings = _settings.copyWith(tor: true);
        _startPoll();
        if (before == null) {
          // Opened while Node only or Kill switch: as an unlock would have started it.
          _startInvoices();
          unawaited(_resendUndelivered(session));
          unawaited(_checkTip());
          unawaited(sync());
          await startAutostart();
        } else {
          await _afterReopen(before.listening, before.http && !tor, tor);
        }
      }
      // Stopped by Kill switch, or left on and not running: started again.
      unawaited(resumeBuiltInNode());
    } else if (now == NetworkMode.torOnly && session != null && _torFeature && !_settings.tor) {
      await setTor(true);
    }
    if (session != null) await _syncTorPay();
    _followTor();
    _changed();
  }

  /// Opens the session again on the same servers, as an offline one in Kill switch and an
  /// online one after it ([core.WalletConfig.offline]), once the wallet core takes it
  /// ([core.walletOfflineSessions]). Its connections were stopped before; a refusal is logged
  /// and the app's gate holds either way.
  Future<void> _reopenForKillSwitch() async {
    final config = _config;
    if (!core.walletOfflineSessions || _session == null || config == null || config.offline == NetGate.killSwitch) return;
    try {
      await _nodeLock(() async => _switchTo(nodeUrl: config.nodeUrl, relay: await _relay(), save: false));
    } on Object catch (e) {
      logWarn('desk', 'kill switch reopen: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
    }
  }

  /// The wallet's own files only (Kill switch): balance and history as last seen.
  Future<void> _loadLocal() async {
    await _reload();
    final h = _summary?.lastConfirmedHeight.toInt() ?? 0;
    if (h > _tip) _tip = h;
  }

  @override
  Future<void> useNode(String url) async {
    await _stopScanForUser();
    await _useNode(url);
  }

  Future<void> _useNode(String url) async {
    final stopping = await _nodeLock(() async {
      logInfo('desk', 'node ${Uri.tryParse(url)?.host ?? '?'}');
      final relay = await _relay();
      if (_session != null && _config?.nodeUrl == url) {
        // Already on it (the public node that stood in while the local node synced): only the
        // choice is saved, the wallet is not reopened.
        final values = useServerValues(hostSettings, node: url, relay: relay.label);
        if (values.isNotEmpty) await writeHostSettings(values);
      } else {
        await _switchTo(nodeUrl: url, relay: relay);
      }
      if (!await _builtInOn()) return null;
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'false');
      logInfo('desk', 'built-in node off');
      return _node;
    });
    // The wallet runs on [url] now; the local node stops behind it (a few seconds, its chain
    // data kept), its state says so. A start meanwhile waits for its exit, and closing the app
    // waits for it too (stopAllBuiltInNodes).
    if (stopping != null) unawaited(stopping.stop());
  }

  @override
  Future<void> useNodeForSession(String url) => _nodeLock(() async {
    if (_session == null || NetGate.restricted || await _builtInOn()) return;
    if (_config?.nodeUrl == url) return;
    logInfo('desk', 'node failover: ${Uri.tryParse(url)?.host ?? '?'} for this session');
    await _switchTo(nodeUrl: url, relay: await _relay(), save: false);
  });

  String get _beforeBuiltInKey => 'app.node.$_chain.beforeBuiltIn';

  Future<bool> _builtInOn() async =>
      _builtInNode != null && await _secrets.read(builtInNodeSettingKey(preset.chain)) == 'true';

  Future<BuiltInNode> _theNode() async {
    final make = _builtInNode;
    if (make == null) throw DeskError.l10n((l) => l.deskErrNoLocalNode);
    final node = _node ??= await make(preset.chain);
    // The user's node settings (data folder, peers) apply to every start, also at launch.
    node.options = await NodeSettings(_secrets, preset.chain).toOptions();
    return node;
  }

  @override
  Future<void> useBuiltInNode(bool on) async {
    // The built-in node would not be the node in use before it runs: Node only and Kill switch
    // refuse it.
    if (on && NetGate.restricted) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    await _stopScanForUser();
    // The setting and the saved node change only once the wallet runs on the new node, so a
    // failed start or move leaves both as they were.
    if (on) {
      // A fallback decision while it starts is applied once the setting is on.
      final seq = _fallbackSeq;
      final node = await _theNode();
      try {
        await node.start();
      } on NodeStartException catch (e) {
        throw DeskError.l10n((l) => l.deskErrLocalNodeNotStarted(startFailureLine(l, e)));
      }
      await _nodeLock(() async {
        // A stop that came in while it was starting wins.
        if (!node.wantsRunning) throw DeskError.l10n((l) => l.deskErrLocalNodeStopped);
        final current = await _nodeUrl();
        // While it syncs, the public node the user agreed to.
        final target = await nodeWhileSyncing?.call() ?? node.url;
        if (current != target) {
          try {
            await _switchTo(nodeUrl: target, relay: await _relay());
          } on Object {
            if (!await _builtInOn()) await node.stop();
            rethrow;
          }
          // A lock while reopening returns without moving; a stop while moving undoes it.
          if (await _nodeUrl() != target) throw DeskError.l10n((l) => l.deskErrNotChangedLocked);
          if (!node.wantsRunning) {
            await _switchTo(nodeUrl: current, relay: await _relay());
            throw DeskError.l10n((l) => l.deskErrLocalNodeStopped);
          }
          await _secrets.write(_beforeBuiltInKey, current);
        }
        await _secrets.write(builtInNodeSettingKey(preset.chain), 'true');
        logInfo('desk', 'built-in node on');
      });
      // The status reads "Syncing" from now on while the node is at height 0.
      unawaited(_checkTip());
      if (_fallbackSeq != seq) unawaited(_applyFallback(_fallbackSeq));
      return;
    }
    _dropStartNotice();
    await _nodeLock(() async {
      // Not on yet (a start still pending): only the node stops; the wallet never moved.
      if (!await _builtInOn()) {
        await _node?.stop();
        return;
      }
      final back = await _secrets.read(_beforeBuiltInKey) ?? preset.nodeUrl;
      if (await _nodeUrl() != back) await _switchTo(nodeUrl: back, relay: await _relay());
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'false');
      logInfo('desk', 'built-in node off');
      await _node?.stop();
    });
  }

  /// The public node to use until the local node is synced, or null for the local node.
  /// Set by the node layer (main_desktop.dart).
  Future<String?> Function()? nodeWhileSyncing;

  /// The fallback decision changed. With the local node in use, the wallet moves to the
  /// agreed public node while it syncs and back to the local node once it is synced. Only the
  /// latest decision moves it, after any send, finalize or scan running has ended.
  Future<void> applyNodeFallback({required bool usePublic, String? publicUrl}) {
    _fallback = (usePublic: usePublic, publicUrl: publicUrl);
    return _applyFallback(++_fallbackSeq);
  }

  Future<void> _applyFallback(int seq) async {
    while (true) {
      await whenIdle();
      final done = await _nodeLock(() async {
        final want = _fallback;
        if (seq != _fallbackSeq || want == null) return true;
        if (!await _builtInOn()) return true;
        final node = await _theNode();
        final publicUrl = want.publicUrl;
        final target = want.usePublic && publicUrl != null ? publicUrl : node.url;
        if (await _nodeUrl() == target) return true;
        final relay = await _relay();
        // Checked with no await before _switchTo marks the switch: no send slips in between.
        if (_busy > 0) return false;
        logInfo('desk', want.usePublic ? 'node fallback on' : 'node fallback off');
        try {
          await _switchTo(nodeUrl: target, relay: relay);
        } on Object catch (e) {
          logWarn('desk', 'node fallback: ${e.runtimeType}');
        }
        return true;
      });
      if (done) return;
    }
  }

  /// The built-in node's address changed (its ports were set, and it restarted on them): with
  /// the built-in node on, the wallet moves to its new address, or stays on the public node
  /// the last fallback decision named. Off, nothing happens.
  @override
  Future<void> followBuiltInNode() {
    _fallback ??= (usePublic: false, publicUrl: null);
    return _applyFallback(++_fallbackSeq);
  }

  /// At launch: starts the built-in node again when it was left on. A failure is logged and
  /// shown as a notice; the wallet then reports its node as not responding.
  Future<void> resumeBuiltInNode() async {
    // Node only too (it is the node in use then); Kill switch starts no node.
    if (NetGate.killSwitch || !await _builtInOn()) return;
    // "Start with the app" off: the user starts it from Settings › Node.
    if (!await NodeSettings(_secrets, preset.chain).startWithApp()) return;
    try {
      await (await _theNode()).start();
    } on Object catch (e) {
      logWarn('desk', 'built-in node did not start: ${e is NodeStartException ? e.failure.name : e.runtimeType}');
      _notice = deskStrings.deskErrLocalNodeNotStarted(e is NodeStartException ? startFailureLine(deskStrings, e) : deskStrings.deskErrUnknown);
      _changed();
      // The notice describes that failed start only: it goes when the node is started later
      // (also an earlier run's node adopted) or stopped, not when the page is left.
      _startNotice = _notice;
      _nodeNoticeSub?.cancel();
      _nodeNoticeSub = _node?.states.listen((s) {
        if (s.kind != NodeStatusKind.failed) _dropStartNotice();
      });
    }
  }

  String? _startNotice;

  void _dropStartNotice() {
    _nodeNoticeSub?.cancel();
    _nodeNoticeSub = null;
    if (_startNotice != null && _notice == _startNotice) {
      _notice = null;
      _changed();
    }
    _startNotice = null;
  }

  StreamSubscription<BuiltInNodeState>? _nodeNoticeSub;

  /// The tip of the node [config] names. With a wallet open it is asked through the wallet
  /// (LEPIC's nodeTipFor), which takes it over Tor while Tor is on. With none open, the core's
  /// own nodeTip always goes directly, so with the Tor switch on nothing is asked (null, shown
  /// as not known yet) unless the node is on this computer.
  Future<core.NodeTip?> _nodeTip(core.WalletConfig config) async {
    final session = _session;
    if (session != null) {
      final wait = _nodeOverTor(config.nodeUrl) && nodeTorTimeout > nodeTimeout ? nodeTorTimeout : nodeTimeout;
      return session.nodeTipFor(config: config).timeout(wait);
    }
    // No wallet open, so no tor: with the Tor switch on (or Tor only, before it is saved) a
    // node not on this computer is not asked directly.
    if (_torFeature && (NetGate.torOnly || (await _store.torSwitch() ?? _settings.torAutostart)) && !isLoopbackUrl(Uri.tryParse(config.nodeUrl) ?? Uri())) {
      return null;
    }
    return _service.nodeTip(config: config).timeout(nodeTimeout);
  }

  @override
  Future<NodeServer> checkNode(String url) async {
    final known = (await _listed()).where((n) => n.url == url).firstOrNull;
    final base = known ?? NodeServer(url: url, label: Uri.tryParse(url)?.host ?? url, own: true);
    final overTor = _overTorNow(url);
    final watch = Stopwatch()..start();
    NodeServer r;
    try {
      final tip = await _nodeTip(await _makeConfig(nodeUrl: url));
      if (tip == null) return NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.checking, own: base.own, icon: base.icon, listedAs: base.listedAs);
      r = NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.ok, latencyMs: watch.elapsedMilliseconds, height: tip.height.toInt(), version: tip.nodeVersion, own: base.own, icon: base.icon, listedAs: base.listedAs);
    } on NetBlocked {
      // Node only or Kill switch: not asked, so off, not down.
      return NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.off, own: base.own, icon: base.icon, listedAs: base.listedAs);
    } on Object {
      r = NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.down, own: base.own, icon: base.icon, listedAs: base.listedAs);
    }
    _checked[url] = r;
    _checkedAt[url] = DateTime.now();
    _checkedOverTor[url] = overTor;
    return r;
  }

  @override
  Future<void> addNode(NodeServer node) async {
    // Into the settings file's Node list, as one the user added (no operator).
    const kind = ServerKind.node;
    final list = serverListOf(hostSettings, kind);
    if (!list.has(kind, node.url)) {
      await writeHostSettings(serverListValues(kind, list.add(kind, node.url, own: true)));
    }
    _checked[node.url] = node;
    _checkedAt[node.url] = DateTime.now();
    _checkedOverTor[node.url] = _overTorNow(node.url);
  }

  @override
  Future<void> useEpicbox(String domain) async {
    final relay = EpicboxRelay.parse(domain);
    if (relay == null) throw DeskError.l10n((l) => l.deskErrNotServerName);
    logInfo('desk', 'epicbox ${relay.label}');
    await _stopScanForUser();
    await _nodeLock(() async => _switchTo(nodeUrl: await _nodeUrl(), relay: relay));
  }

  @override
  Future<void> setListening(bool on) async {
    if (!on) {
      await _stopListener();
      return _stopHttp();
    }
    if (_settings.directHttp) await setHttpListening(true);
    await setEpicboxListening(true);
  }

  @override
  Future<void> setEpicboxListening(bool on) async {
    if (!on) return _stopListener();
    if (_listener != null) return;
    if (NetGate.restricted) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    if (!NetGate.epicbox) throw DeskError.l10n((l) => l.netBlockEpicboxOff);
    final session = _open;
    _epicboxHealth = ServiceHealth.checking;
    _changed();
    _listener = session.startListener().listen(
      (e) {
        switch (e.kind) {
          case core.ListenerEventKind.connected:
            _epicboxHealth = ServiceHealth.ok;
            _clearBlocked();
          case core.ListenerEventKind.disconnected:
            _epicboxHealth = ServiceHealth.down;
            _relayMaybeBlocked(e.reason ?? e.message);
          case core.ListenerEventKind.received || core.ListenerEventKind.finalized || core.ListenerEventKind.expired:
            unawaited(_reload());
          case core.ListenerEventKind.stopped:
            _epicboxHealth = ServiceHealth.off;
            _listener = null;
            _clearBlocked();
          case core.ListenerEventKind.repeated || core.ListenerEventKind.error || core.ListenerEventKind.delayed:
            logInfo('desk', 'listener ${e.kind.name}');
        }
        _changed();
      },
      onError: (Object e) {
        logWarn('desk', 'listener ended: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
        _epicboxHealth = ServiceHealth.down;
        _listener = null;
        _clearBlocked();
        _changed();
      },
    );
  }

  /// One failed connection of the Epicbox listener, with its [reason]. Only a direct connection
  /// counts: over Tor the network never sees the relay's name, so "this network blocks it"
  /// would be wrong. Once blocked it stays so until [_clearBlocked]; the health stays down, so
  /// the line does not flip between Connecting and Not answering.
  void _relayMaybeBlocked(String? reason) {
    if (_epicboxOverTor && _settings.tor) return _clearBlocked();
    if (_epicboxBlocked || !_blockWatch.failed(reason)) return;
    final c = _config;
    if (c == null) return;
    final blocked = EpicboxRelay(host: c.epicboxDomain, port: c.epicboxPort);
    _epicboxBlocked = true;
    _blockedInstead = null;
    _blockedRelays.add(blocked);
    logInfo('desk', 'epicbox relay blocked by the network');
    unawaited(_offerInstead(blocked));
  }

  void _clearBlocked() {
    _blockWatch.reset();
    _epicboxBlocked = false;
    _blockedInstead = null;
  }

  /// Sets [_blockedInstead]: the first other relay the monitor saw up, else the first built-in
  /// it did not list; the monitor not answering leaves only the built-in ones.
  Future<void> _offerInstead(EpicboxRelay blocked) async {
    List<RelayStatus>? listed;
    final dir = relayDirectory;
    if (dir != null && preset.statusChain != null && statusSite.on) {
      try {
        listed = await dir.relays(preset.statusChain!).timeout(nodeTimeout);
      } on Object catch (e) {
        logWarn('desk', 'epicbox instead: ${e.runtimeType}');
      }
    }
    if (!_epicboxBlocked) return;
    _blockedInstead = relayInstead(blocked, mergePublicRelays(listed, builtIn: builtInRelaysFor(preset)), skip: _blockedRelays);
    _changed();
  }

  @override
  Future<void> setHttpListening(bool on) async {
    if (!on) return _stopHttp();
    if (_http != null) return;
    // Off while Tor is on, and in Tor only: it would answer on this computer's own address.
    // Tor off starts it again when its switch ([DeskSettings.directHttp]) is on.
    if (_settings.tor || NetGate.torOnly) return;
    // Node only and Kill switch: no Link listener at all.
    if (NetGate.restricted) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    final session = _open;
    final port = _settings.httpPort;
    // From the internet only after the user chose it in the guide (DeskSettings.publicMode).
    final exposure = _settings.publicMode ? core.HttpExposure.internet : core.HttpExposure.localOnly;
    _httpHealth = ServiceHealth.checking;
    _httpProblem = null;
    _httpPort = port;
    _httpExposure = exposure;
    _changed();
    logInfo('desk', 'http listener start ${exposure.name}');
    late final StreamSubscription<core.HttpListenerEvent> sub;
    void ended(ServiceHealth health, HttpProblem? problem) {
      if (_http != sub) return;
      _http = null;
      _httpHealth = health;
      _httpProblem = problem;
    }

    sub = session.startHttpListener(exposure: exposure, port: port).listen(
      (e) {
        if (_http != sub) return;
        switch (e.kind) {
          case core.HttpListenerEventKind.started:
            _httpHealth = ServiceHealth.ok;
            _httpPort = e.port ?? port;
          case core.HttpListenerEventKind.portInUse:
            _httpPort = e.port ?? port;
            ended(ServiceHealth.down, HttpProblem.portInUse);
          case core.HttpListenerEventKind.bindFailed:
            _httpPort = e.port ?? port;
            ended(ServiceHealth.down, HttpProblem.portUnavailable);
          case core.HttpListenerEventKind.received:
            unawaited(_reload());
          case core.HttpListenerEventKind.refused:
            // Never the sender or its address: only that a payment was refused, and why.
            logInfo('desk', 'http listener refused: ${e.refusal?.name ?? '?'}');
          case core.HttpListenerEventKind.stopped:
            ended(ServiceHealth.off, null);
        }
        _changed();
      },
      onError: (Object e) {
        logWarn('desk', 'http listener ended: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
        ended(ServiceHealth.down, HttpProblem.stopped);
        _changed();
      },
      onDone: () {
        // A second start gets a stream that ends at once; a stop ends it after `stopped`.
        if (_http != sub) return;
        ended(_httpHealth == ServiceHealth.ok || _httpHealth == ServiceHealth.checking ? ServiceHealth.off : _httpHealth, _httpProblem);
        _changed();
      },
    );
    _http = sub;
  }

  Future<void> _stopHttp() async {
    final sub = _http;
    _http = null;
    final was = _httpHealth;
    _httpHealth = ServiceHealth.off;
    _httpProblem = null;
    if (sub == null) {
      if (was != ServiceHealth.off) _changed();
      return;
    }
    try {
      await _session?.stopHttpListener();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop http listener: ${e.kind.name}');
    }
    await sub.cancel();
    _changed();
  }

  /// Epicbox over Tor: on until set; every wallet opened takes it ([_routeEpicbox]).
  bool _epicboxOverTor = true;

  @override
  Future<void> setEpicboxOverTor(bool on) async {
    // Tor only keeps Epicbox on tor: off would let it go direct.
    if (!on && NetGate.torOnly) return;
    _epicboxOverTor = on;
    _clearBlocked();
    final session = _session;
    if (session != null) await _routeTor(session);
    _changed();
  }

  /// Hands [session] the Epicbox over Tor choice and the onion routes in use, and the node
  /// and HTTP sends' route ([_routeTor]).
  Future<void> _routeEpicbox(core.WalletSession session) async {
    await _routeTor(session);
    await _applyOnions(session);
  }

  // ---- Tor for payments (item 2).

  /// Link · Tor on starts tor for payments alone: the onion listener and sends to onions. The
  /// Tor switch (Network & privacy) and Tor only still decide the node, Epicbox and Direct
  /// http(s) sends; Node only and Kill switch start no tor for it.
  bool get _torPayWanted => _torFeature && _settings.payments.linkTor && !NetGate.restricted;

  /// The Tor switch carries every connection: on now, saved on (it comes on at unlock), or
  /// Tor only.
  bool get _torAll => _settings.tor || (_torFeature && _settings.torAutostart) || NetGate.torOnly;

  /// Tor runs or should: for the switch or for payments.
  bool get _torRuns => _settings.tor || _torPayWanted;

  /// The session's routes through tor while it runs: the node, Epicbox (with its own setting)
  /// and Direct http(s) sends only while the switch carries every connection.
  Future<void> _routeTor(core.WalletSession session) async {
    final all = _torAll;
    final epicbox = _epicboxOverTor && all;
    final same = identical(session, _routed);
    _routed = session;
    if (!same || _routedAll != all) {
      _routedAll = all;
      try {
        await session.setNodeAndHttpOverTor(all);
      } on Object catch (e) {
        // A core without the call keeps tor carrying every route, as before.
        logWarn('desk', 'tor routes: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    if (!same || _routedEpicbox != epicbox) {
      _routedEpicbox = epicbox;
      await session.setEpicboxOverTor(epicbox);
    }
  }

  /// The session [_routeTor] last set, and what it set: a route is handed over once per change.
  core.WalletSession? _routed;
  bool? _routedAll;
  bool? _routedEpicbox;

  /// Starts or stops tor for payments as Link · Tor, the Tor switch and the mode say, with the
  /// routes set first: a tor for payments never carries the node or Epicbox.
  Future<void> _syncTorPay() async {
    final session = _session;
    if (session == null || !_torFeature) return;
    await _routeTor(session);
    // The switch owns a tor it started.
    if (_settings.tor) return;
    if (_torPayWanted) {
      if (_tor == null && _torHealth == ServiceHealth.off) {
        logInfo('desk', 'tor for payments');
        _torStartRetries = 0;
        unawaited(_startTor());
      }
    } else if (_tor != null || _torHealth != ServiceHealth.off) {
      await _stopTor();
    }
    _followTor();
    _changed();
  }

  /// Retry of Tor for payments after it failed (the state line's Retry).
  @override
  Future<void> retryTorPay() async {
    if (_settings.tor || !_torPayWanted) return;
    await _stopTor();
    await _syncTorPay();
  }

  /// Gives LEPIC the TLS hosts of [onions] that have an onion, for connections through tor.
  Future<void> _applyOnions(core.WalletSession? session) async {
    if (session == null) return;
    try {
      await session.setOnionRoutes(onionRoutesOf(onions));
    } on core.WalletError catch (e) {
      logWarn('desk', 'onion routes not set: ${e.kind.name}');
    }
  }

  @override
  ///
  /// Tor only refuses off; Offline refuses on (no tor starts).
  Future<void> setTor(bool on) async {
    _open;
    // The build without Tor has no switch: nothing starts, and off is already so.
    if (!_torFeature) {
      if (on) logInfo('desk', 'tor: not in this build');
      return;
    }
    if (!on && NetGate.torOnly) throw DeskError.l10n((l) => l.deskSetAdvModeTorOnlyText);
    if (on && NetGate.killSwitch) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    _settings = _settings.copyWith(tor: on);
    _clearBlocked();
    await _store.saveTorOn(_openEntry?.walletId, on);
    logInfo('desk', 'tor ${on ? 'on' : 'off'}');
    final session = _session;
    if (!on) {
      if (_torPayWanted && session != null && _torHealth != ServiceHealth.down) {
        // Link · Tor keeps tor for payments: only the routes go back to direct.
        await _routeTor(session);
        _followTor();
        _changed();
      } else {
        // A stop the user asked for: Epicbox may go direct again.
        await _stopTor();
        await _syncTorPay();
      }
      if (_settings.directHttp && _session != null) await setHttpListening(true);
      return;
    }
    // The clearnet HTTP listener stays off while Tor is on (tor_routes.dart, torStops).
    await _stopHttp();
    // A tor running for payments now carries every connection too.
    if (session != null) await _routeTor(session);
    // On again after a failure, or while a start hangs, is Retry; the Epicbox connection keeps
    // waiting for the new tor.
    if (_torHealth == ServiceHealth.down || (_torHealth == ServiceHealth.checking && !_torCanSend)) {
      final session = _session;
      if (session != null) await _expectTor(session);
      await _stopTor();
    }
    _torStartRetries = 0;
    await _startTor();
  }

  /// Starts the open wallet's tor from the bundle, unless it runs. Without the bundle the
  /// Tor line says so and nothing starts.
  Future<void> _startTor() async {
    final session = _session;
    // Locked before it started (it runs unawaited after unlock and reopen).
    if (_tor != null || session == null) return;
    final generation = _generation;
    final bundle = await _findTor();
    // Locked, switched, turned off or started meanwhile.
    if (generation != _generation || _session != session || _tor != null || !_torRuns || NetGate.killSwitch) return;
    _torCanSend = false;
    _torProgress = null;
    if (bundle == null) {
      _torHealth = ServiceHealth.down;
      _torProblem = torFailureText(deskStrings, core.TorFailure.missing);
      _changed();
      return;
    }
    _torHealth = ServiceHealth.checking;
    _torProgress = 0;
    _torProblem = null;
    _torStartedAt = DateTime.now();
    _torSlowTimer?.cancel();
    // Nothing else changes while a start hangs; this shows Retry when it is due.
    _torSlowTimer = Timer(torRetryAfter, _changed);
    _changed();
    logInfo('desk', 'tor start');
    late final StreamSubscription<core.TorEvent> sub;
    void ended(String? problem) {
      if (_tor != sub) return;
      // Ended by itself, not after a failure that shows: started again after a pause.
      if (_torHealth != ServiceHealth.down && _torRestartLater(session, sub, 'tor ended')) return; // l10n-ok: log reason
      _tor = null;
      _torHealth = ServiceHealth.down;
      _torProblem = problem ?? deskStrings.deskErrTorStopped;
      _torCanSend = false;
      _torProgress = null;
      _torStartedAt = null;
      _torSocks = null;
      _torConnectedAt = null;
    }

    sub = session.startTor(torBinary: bundle.binary, libDir: bundle.libDir).listen(
      (e) {
        if (_tor != sub) return;
        switch (e.kind) {
          case core.TorEventKind.starting:
            _torHealth = ServiceHealth.checking;
            _torProgress = e.progress ?? _torProgress;
          case core.TorEventKind.bootstrapped || core.TorEventKind.publishing:
            _takeSocks(e.socksPort);
            _torStartRetries = 0;
            _torCanSend = true;
            _torStartedAt = null;
            if (_torHealth != ServiceHealth.slow) _torHealth = ServiceHealth.checking;
            _torConnected();
          case core.TorEventKind.ready:
            _takeSocks(e.socksPort);
            _torHealth = ServiceHealth.ok;
            _torCanSend = true;
            _torProblem = null;
            _torConnected();
            final onion = e.onion;
            if (onion != null) _onion = core.onionHost(onion);
          case core.TorEventKind.failed:
            logWarn('desk', 'tor failed: ${e.failure?.name ?? '?'}');
            // Tor did not start, lost the network or stopped: started again by itself,
            // showing Connecting (nothing goes direct meanwhile), before "failed" and Retry.
            final restartable = switch (e.failure) {
              core.TorFailure.start || core.TorFailure.network || core.TorFailure.stopped || null => true,
              _ => false,
            };
            if (restartable && _torRestartLater(session, sub, 'tor failed')) return; // l10n-ok: log reason
            _torStartedAt = null;
            // Listener and keys leave tor running for sends; any other failure stops it.
            final forSends = e.failure == core.TorFailure.listener || e.failure == core.TorFailure.keys;
            _torHealth = forSends ? ServiceHealth.slow : ServiceHealth.down;
            _torProblem = torFailureText(deskStrings, e.failure);
            if (!forSends) {
              _torCanSend = false;
              _torConnectedAt = null;
            }
          case core.TorEventKind.sending:
            return;
          case core.TorEventKind.received:
            unawaited(_reload());
          case core.TorEventKind.refused:
            // Never the sender or its address: only that a payment was refused, and why.
            logInfo('desk', 'tor refused: ${e.refusal?.name ?? '?'}');
          case core.TorEventKind.stopped:
            ended(_torHealth == ServiceHealth.down ? _torProblem : null);
        }
        _changed();
      },
      onError: (Object e) {
        logWarn('desk', 'tor ended: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
        ended(null);
        _changed();
      },
      onDone: () {
        if (_tor != sub) return;
        ended(_torHealth == ServiceHealth.down ? _torProblem : null);
        _changed();
      },
    );
    _tor = sub;
  }

  /// Restarts the tor that [sub] watches after the next pause of [torStartBackoff], showing
  /// Connecting meanwhile; false once the pauses since it last connected are used up.
  bool _torRestartLater(core.WalletSession session, StreamSubscription<core.TorEvent> sub, String why) {
    if (_torStartRetries >= torStartBackoff.length || !_torRuns) return false;
    final wait = torStartBackoff[_torStartRetries++];
    logInfo('desk', '$why; starting it again in ${wait.inSeconds} s ($_torStartRetries/${torStartBackoff.length})');
    _torHealth = ServiceHealth.checking;
    _torProblem = null;
    _torCanSend = false;
    _torProgress = 0;
    _torSocks = null;
    _torStartedAt = null;
    _torConnectedAt = null;
    unawaited(_restartTor(session, sub, after: wait));
    return true;
  }

  /// Stops the tor that [sub] watches and starts it again [after] a pause, showing
  /// "Connecting" throughout.
  Future<void> _restartTor(
    core.WalletSession session,
    StreamSubscription<core.TorEvent> sub, {
    Duration after = Duration.zero,
  }) async {
    if (_tor != sub) return;
    _tor = null;
    await _expectTor(session);
    try {
      await session.stopTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop tor: ${e.kind.name}');
    }
    await sub.cancel();
    if (after > Duration.zero) await Future<void>.delayed(after);
    // Locked, switched off, or started again by the user meanwhile.
    if (_session != session || !_torRuns || _tor != null) return;
    await _startTor();
  }

  /// Tor (re)starts next: the Epicbox connection waits for it and a stop before it keeps it
  /// waiting (LEPIC's `expectTor`).
  Future<void> _expectTor(core.WalletSession session) async {
    _torExpected = true;
    try {
      await session.expectTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'expect tor: ${e.kind.name}');
    }
  }

  /// Tor again under the mode's onion rule ([torPublishesOnion]); the switch stays as it is.
  Future<void> _restartTorForOnion() async {
    await _stopTor();
    _torStartRetries = 0;
    unawaited(_startTor());
  }

  Future<void> _stopTor() async {
    final sub = _tor;
    _tor = null;
    final expected = _torExpected;
    _torExpected = false;
    _torStartedAt = null;
    _torConnectedAt = null;
    _torSlowTimer?.cancel();
    final was = _torHealth;
    _torHealth = ServiceHealth.off;
    _torProblem = null;
    _torProgress = null;
    _torCanSend = false;
    if (sub == null) {
      if (was == ServiceHealth.off) {
        // Never started, but the session may have opened waiting for it (torWantedAt): the
        // stop ends that wait. Nothing to end when it was never told tor comes.
        if (!expected) return;
        try {
          await _session?.stopTor();
        } on core.WalletError catch (e) {
          logWarn('desk', 'stop tor: ${e.kind.name}');
        }
        return;
      }
      // Tor ended by itself: LEPIC keeps the Epicbox connection waiting for it until stopped.
      try {
        await _session?.stopTor();
      } on core.WalletError catch (e) {
        logWarn('desk', 'stop tor: ${e.kind.name}');
      }
      _changed();
      return;
    }
    try {
      await _session?.stopTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop tor: ${e.kind.name}');
    }
    await sub.cancel();
    _changed();
  }

  Future<void> _stopListener() async {
    final sub = _listener;
    if (sub == null) return;
    _listener = null;
    try {
      await _session?.stopListener();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop listener: ${e.kind.name}');
    }
    await sub.cancel();
    _epicboxHealth = ServiceHealth.off;
    _clearBlocked();
    _changed();
  }

  /// Set while Recheck balance scans: the due scan in [_sync] waits for the next sync.
  bool _rescanning = false;

  /// The scan due since a restore runs ([_sync]).
  bool _scanningDue = false;

  /// The open wallet still owes the scan a restore or a rebuilt database needs: the core's
  /// flag ([core.WalletSession.restoreScanRequired]) or the app's scan-due note. Read at every
  /// unlock and after every scan.
  bool _restoreDue = false;

  /// How far the due scan running now is, and the height a restore scanned from before it.
  int? _duePercent;
  int? _dueAfterHeight;

  /// The due scan stopped with an error; Try again ([syncNow]) runs it again.
  bool _restoreFailed = false;

  /// A scan with no height ran to its end and the core still wants one: not run again by
  /// itself this session (a loop of whole-chain scans), only by Try again.
  bool _restoreUnfinished = false;

  /// The core's restore flag; false when the core cannot say (the scan-due note still counts).
  Future<bool> _restoreFlag(core.WalletSession session) async {
    try {
      return await session.restoreScanRequired();
    } on core.WalletError catch (e) {
      logWarn('desk', 'restore flag: ${e.kind.name}');
      return false;
    }
  }

  /// After any scan that ran to its end (the due scan, a Recheck): the scan-due note and the
  /// start height go (a height is used once, by the restore that typed it), and the core
  /// says whether the scan from block 0 is still owed.
  Future<void> _scanEnded(core.WalletSession session, String key) async {
    await _setMeta({'scanPending': false, 'scanFrom': null}, key);
    _notice = null;
    _restoreDue = await _restoreFlag(session);
    if (!_restoreDue) _dueAfterHeight = null;
  }

  /// [ServiceStatus.restoreScan].
  RestoreScan? get _restoreView {
    if (_session == null) return null;
    if (_scanningDue) return RestoreScan(RestoreScanState.running, percent: _duePercent, fromHeight: _dueAfterHeight);
    if (!_restoreDue) return null;
    if (_nodeOff) return const RestoreScan(RestoreScanState.waiting, offline: true);
    if (_restoreFailed && _nodeHealth == ServiceHealth.down) return const RestoreScan(RestoreScanState.waiting);
    if (_restoreFailed || _restoreUnfinished) return const RestoreScan(RestoreScanState.failed);
    return RestoreScan(RestoreScanState.running, fromHeight: _dueAfterHeight);
  }
  bool _rescanStopAsked = false;
  Completer<void>? _rescanEnded;

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight}) async* {
    // Recheck balance asks the node: Offline only a local one.
    if (_nodeOff) throw DeskError.l10n((l) => l.statusOffByMode(networkModeName(l, NetGate.mode)));
    // Admitted like [_running]: the checks and the count follow each other with no await.
    var waitedForStop = false;
    while (true) {
      if (_locking) throw DeskError.l10n((l) => l.deskErrWalletLocking, locked: true);
      if (_switching != null) {
        await _switching!.future;
        continue;
      }
      // A scan LEPIC was told to stop still holds the wallet until its stream ends: wait for that.
      final old = _rescanEnded;
      if (_rescanning && _rescanStopAsked && old != null && !waitedForStop) {
        waitedForStop = true;
        await old.future.timeout(const Duration(seconds: 30), onTimeout: () {});
        continue;
      }
      break;
    }
    if (_rescanning) throw DeskError.l10n((l) => l.deskErrScanRunning);
    final session = _open;
    final key = _metaKey(_openEntry?.walletId);
    _rescanning = true;
    _rescanStopAsked = false;
    final ended = _rescanEnded = Completer<void>();
    var finished = false;
    // A scan counts as a running operation: the fallback waits for it.
    _busy++;
    try {
      await for (final p in session.scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed)) {
        finished = finished || p.finished;
        final r = p.result;
        yield ScanStep(
          p.message,
          percent: p.percent,
          finished: p.finished,
          counts: r == null
              ? null
              : ScanCounts(found: r.found, restored: r.restored, revived: r.revived, unlocked: r.unlocked, deleted: r.deleted, resumed: r.resumed),
        );
      }
    } on core.WalletError catch (e) {
      // LEPIC refuses a second scan of the same wallet (the due scan of a sync, say).
      if (e.kind == core.WalletErrorKind.walletBusy) throw DeskError.l10n((l) => l.deskErrScanRunning);
      throw _deskError(e);
    } finally {
      _rescanning = false;
      _opEnded();
      if (!ended.isCompleted) ended.complete();
    }
    // A stopped scan leaves a due scan due; either way the balance is read again (and the
    // scan from block 0 a restore still owes runs then by itself).
    if (finished && _session == session) {
      await _scanEnded(session, key);
      _restoreUnfinished = false;
      _restoreFailed = false;
    }
    logInfo('desk', finished ? 'rescan finished' : 'rescan stopped');
    // The scan itself ended; a sync that breaks afterwards is not a failed scan.
    try {
      await sync();
    } on Object catch (e) {
      logWarn('desk', 'sync after rescan: ${e.runtimeType}');
    }
  }

  @override
  Future<void> stopRescan() async {
    logInfo('desk', 'rescan stop asked');
    _rescanStopAsked = _rescanning;
    try {
      _session?.cancelScan();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop rescan: ${e.kind.name}');
    }
  }

  @override
  Future<List<String>> revealPhrase(String password) async {
    try {
      final phrase = await _open.mnemonic(password: password);
      return phrase.split(RegExp(r'\s+'));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// Re-encrypts the open wallet under [next], then forgets its remembered password. A
  /// wrong [current] throws a [DeskError] with `wrongPassword`; any other failure leaves the
  /// old password working.
  @override
  Future<void> changePassword(String current, String next) async {
    _checkPassword(next);
    final session = _open;
    final id = _openEntry?.id;
    logInfo('desk', 'password change asked');
    try {
      await session.changePassword(currentPassword: current, newPassword: next);
    } on core.WalletError catch (e) {
      logWarn('desk', 'password change: ${e.kind.name}');
      throw switch (e.kind) {
        core.WalletErrorKind.wrongPassword => _deskError(e),
        core.WalletErrorKind.invalidArgument => DeskError.l10n((l) => l.deskErrPasswordShort(minPasswordLength)),
        core.WalletErrorKind.chainBusy || core.WalletErrorKind.walletBusy => _deskError(e),
        _ => DeskError.l10n((l) => l.deskErrPasswordNotChanged),
      };
    }
    logInfo('desk', 'password changed');
    if (id != null) await _remember.forget(id);
  }

  // ---- History backup and its reminder. The archive, the sealing and the merge
  // are the shared ones (`history/`, the core session), so a phone file opens here and back.

  @override
  Future<void> dismissHistoryImportOffer() => _setMeta({'historyOffer': false});

  @override
  Future<HistoryBackupState> historyBackupState() async {
    final session = _open;
    final txs = await session.transactions(refresh: false);
    final meta = await _meta();
    int? secs(String k) => (meta[k] as num?)?.toInt();
    final snap = meta['historyExportSnapshot'];
    final snapshot = snap is Map<String, dynamic> ? HistoryExportSnapshot.fromJson(snap) : null;
    final exportedAt = secs('historyExportedAt');
    final now = DateTime.now();
    var firstSeenAt = secs('historyReminderFirstSeenAt');
    final unbacked = deskUnbackedPayments(txs, exportedAt: exportedAt, snapshot: snapshot);
    if (firstSeenAt == null && unbacked > 0) {
      // The 30 days of a wallet with no export and no dismissal start here.
      firstSeenAt = now.millisecondsSinceEpoch ~/ 1000;
      await _setMeta({'historyReminderFirstSeenAt': firstSeenAt});
    }
    return HistoryBackupState(
      importOffer: meta['historyOffer'] == true,
      lastExport: exportedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(exportedAt * 1000),
      unbacked: unbacked,
      reminder: deskPaymentsNotInBackup(
        txs,
        now: now,
        exportedAt: exportedAt,
        dismissedAt: secs('historyReminderDismissedAt'),
        firstSeenAt: firstSeenAt,
        snapshot: snapshot,
      ),
      payments: txs.where((t) => !(t.source == core.TxSource.restored && t.note == null)).length,
      contacts: (await session.contacts()).length,
      network: _chain,
    );
  }

  @override
  Future<Uint8List> exportHistory() async {
    final session = _open;
    Map<String, Object?>? settings;
    try {
      settings = (await backupSettings()).mine;
    } on Object catch (e) {
      // The history matters more: the file goes without settings.
      logWarn('desk', 'backup settings not read: ${e.runtimeType}');
    }
    try {
      await _starsToSession(session);
      return await session.exportHistory(walletName: _openEntry?.label, settings: settings);
    } on core.WalletError catch (e) {
      logWarn('desk', 'history export: ${e.kind.name}');
      throw _deskError(e);
    }
  }

  @override
  Future<String> exportHistoryCsv({DateTime? from, DateTime? to}) async {
    final txs = await _open.transactions(refresh: false);
    final start = from == null ? null : DateTime(from.year, from.month, from.day).millisecondsSinceEpoch ~/ 1000;
    final end = to == null ? null : DateTime(to.year, to.month, to.day + 1).millisecondsSinceEpoch ~/ 1000;
    return historyCsv(
      [
        for (final t in txs)
          if ((start == null || t.timeUnix >= start) && (end == null || t.timeUnix < end)) t,
      ],
      _tip > 0 ? BigInt.from(_tip) : null,
      target: _minConf.toInt(),
    );
  }

  @override
  Future<HistoryImport> importHistory(Uint8List data, {Map<String, bool>? useBackup}) async {
    if (data.length > maxDeskHistoryBytes) throw HistoryFileError.l10n(HistoryFileProblem.tooLarge, (l) => l.deskErrHistTooLarge);
    try {
      final session = _open;
      await _starsToSession(session);
      final r = await session.importHistory(data: data, useBackup: useBackup);
      if (!r.applied) {
        logInfo('desk', 'history import waits for ${r.conflicts.length} choices');
        return HistoryImport(conflicts: r.conflicts, applied: false);
      }
      // The file's stars, which the session put in its archive, join this wallet's.
      final stars = await _favourites();
      final before = stars.length;
      stars.addAll(await session.favouriteContacts());
      if (stars.length != before && _session == session) await _store.writeJson(_favouritesKey, stars.toList());
      logInfo('desk', 'history imported: ${r.merged} merged, ${r.added} added, ${r.contactsAdded} contacts, ${r.replaced} replaced');
      // A restored wallet's offer to import is answered.
      await _setMeta({'historyOffer': false});
      await _reload();
      return HistoryImport(
        merged: r.merged,
        added: r.added,
        skipped: r.skipped,
        contactsAdded: r.contactsAdded,
        replaced: r.replaced,
        pairingsAdded: r.pairingsAdded,
        pairingsOtherDevice: r.pairingsOtherDevice,
        notesAdded: r.notesAdded,
        labelsAdded: r.labelsAdded,
        detailsAdded: r.detailsAdded,
        invoicesAdded: r.invoicesAdded,
        starsAdded: r.starsAdded,
        walletName: r.walletName,
        settings: r.settings,
      );
    } on core.WalletError catch (e) {
      logWarn('desk', 'history import refused: ${e.kind.name}');
      throw historyFileError(e);
    }
  }

  @override
  Future<void> setTxLabel(String key, String? label) async {
    try {
      await _open.setTxLabel(key: key, label: label);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    await _reload();
  }

  @override
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note}) async {
    try {
      await _open.setTxDetails(key: key, counterparty: counterparty, transport: transport, note: note);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    await _reload();
  }

  @override
  Future<DeskBackupSettings> backupSettings() async {
    final entry = _openEntry;
    final secs = (await _meta())[_invoiceExpiryKey];
    final expiry = secs is int && secs > 0 ? Duration(seconds: secs > maxInvoiceExpiry.inSeconds ? maxInvoiceExpiry.inSeconds : secs) : defaultInvoiceExpiry;
    final autostart = await _store.autostart(entry?.walletId);
    return DeskBackupSettings(
      chain: _chain,
      mine: deskBackupMap(
        _settings.copyWith(epicboxAutostart: autostart.epicbox, torAutostart: autostart.tor),
        hosts: hostSettings,
        outputs: await _store.outputPrefs(entry?.walletId),
        invoiceExpiry: expiry,
        seedsDeleted: [
          for (final e in (await _seedRecords()).entries)
            if (e.value['deleted'] == true) e.key,
        ],
      ),
      defaults: deskBackupMap(
        const DeskSettings(),
        hosts: shippedHostSettings,
        outputs: const OutputPrefs(),
        invoiceExpiry: defaultInvoiceExpiry,
        seedsDeleted: const [],
      ),
    );
  }

  @override
  Future<void> restoreBackupItems({List<String>? seedsDeleted}) async {
    final entry = _openEntry;
    final session = _session;
    if (seedsDeleted == null || seedsDeleted.isEmpty || session == null) return;
    final key = _metaKey(entry?.walletId);
    final gone = <String>[];
    await _seedLocked(() async {
      if (_session != session) return;
      final seeds = await _seedRecords(key);
      final stored = {for (final c in await session.contacts()) c.id: c};
      var changed = false;
      for (final id in seedsDeleted) {
        // Only the contacts the app ships with have records.
        final seed = bundledSeedContacts.where((c) => c.id == id).firstOrNull;
        final rec = seeds[id];
        if (seed == null || rec?['deleted'] == true) continue;
        if (rec == null) {
          seeds[id] = {..._seedRecord('', seed), 'contact': null, 'deleted': true};
        } else {
          // Deleted again only when it is still as the app wrote it: an edit makes it the user's.
          final c = stored[rec['contact']];
          final untouched = c != null &&
              c.address == rec['address'] &&
              (!rec.containsKey('name') || c.name == rec['name']) &&
              (!rec.containsKey('note') || c.note == rec['note']);
          if (untouched) {
            await session.deleteContact(id: c.id);
            gone.add(c.id);
          }
          seeds[id] = {...rec, 'deleted': true};
        }
        changed = true;
      }
      if (changed && _session == session) await _setMeta({'seeds': seeds}, key);
    });
    if (gone.isNotEmpty) {
      final favourites = await _favourites();
      final before = favourites.length;
      favourites.removeAll(gone);
      if (favourites.length != before && _session == session) await _store.writeJson(_favouritesKey, favourites.toList());
    }
    _changed();
  }

  @override
  Future<void> markHistoryExported(DateTime when) async {
    final txs = await _open.transactions(refresh: false);
    await _setMeta({
      'historyExportedAt': when.millisecondsSinceEpoch ~/ 1000,
      'historyExportSnapshot': HistoryExportSnapshot.of(txs).toJson(),
    });
  }

  @override
  Future<void> dismissHistoryReminder(DateTime when) => _setMeta({'historyReminderDismissedAt': when.millisecondsSinceEpoch ~/ 1000});

  // ---- Invoices over Epicbox. The shared session's invoice calls,
  // mapped onto the desktop's own types (invoices.dart), not renamed. LEPIC keeps the
  // pairings and the waiting invoices; the session keeps what became of each invoice in
  // `wfe_meta.json`. Nothing here pays but [payInvoice], whose only
  // caller is Review's Approve, after the password; no event, collect, drain or timer leads
  // to it. Contact invoices come with the shell's collect of the contacts' mailboxes, as
  // events ([_onInvoiceEvent]).

  /// Drains the payments address on a timer while a wallet is open ([_startInvoices]).
  InvoiceScheduler? _invoiceTimers;
  StreamSubscription<core.InvoiceEvent>? _invoiceSub;
  StreamSubscription<core.IssuerEvent>? _issuerSub;
  StreamSubscription<core.PairingEvent>? _pairingSub;
  final _invoiceNotices = StreamController<InvoiceNotice>.broadcast();

  /// How long invoices stay payable here (Settings › Invoices); kept per wallet in the
  /// wallet's saved data under [_invoiceExpiryKey] and read back when the invoices start.
  Duration _invoiceExpiry = defaultInvoiceExpiry;
  static const _invoiceExpiryKey = 'invoiceExpirySecs';

  Future<void> _loadInvoiceExpiry() async {
    final session = _session;
    final secs = (await _meta())[_invoiceExpiryKey];
    if (_session != session) return;
    _invoiceExpiry = secs is int && secs > 0 ? Duration(seconds: secs > maxInvoiceExpiry.inSeconds ? maxInvoiceExpiry.inSeconds : secs) : defaultInvoiceExpiry;
  }

  DateTime? _invoiceCheckedAt;
  InvoiceCheck _invoiceCheck = InvoiceCheck.ok;
  String? _invoiceProblem;

  /// The fee of paying each waiting invoice, estimated once per slate id: a book read does not
  /// ask the core again.
  final Map<String, int> _invoiceFees = {};

  /// The waiting invoices as last read, so an event that ends one can still name it.
  final Map<String, IncomingInvoice> _waitingSeen = {};

  /// Invoices that ended here before they were paid (declined, withdrawn, expired): LEPIC
  /// deletes them, so the answered list keeps them for this session.
  final Map<String, IncomingInvoice> _endedUnpaid = {};

  @override
  bool get supportsInvoices => _session?.supportsInvoices ?? true;

  @override
  bool get supportsRequestFiles => _session?.supportsRequestFiles ?? false;

  int _sessionRevision = 0;

  @override
  int get sessionRevision => _sessionRevision;

  @override
  Stream<InvoiceNotice> invoiceNotices() => _invoiceNotices.stream;

  /// A notice for the open screens; none once the app closed ([dispose]): a collect or an event
  /// still running then would otherwise throw on the closed stream.
  void _notify(InvoiceNotice notice) {
    if (!_invoiceNotices.isClosed) _invoiceNotices.add(notice);
  }

  /// Routine news of [session]'s slate [slateId]: [notice] waits for the end of its run
  /// ([NoticeBatch]). None just ends the slate in the batch.
  void _hold(core.WalletSession session, HeldKind kind, String slateId, [InvoiceNotice? notice]) => raiseNotice(
    session.checks.notices,
    HeldNotice(kind, slateId: slateId, show: notice == null ? null : () => _notify(notice)),
  );

  /// After an unlock or a reopen on another server: the session's invoice events and the
  /// scheduler, on that session only.
  void _startInvoices() {
    _stopInvoices();
    final session = _session;
    if (session == null) return;
    // A payment the contacts' collect finalized and posted (a mailbox send's answer): the list
    // is read again. The listener's "finalized" comes before the post, so the read it starts
    // can find the payment not yet posted ("Not on the network", LNX3-4).
    if (session.pairing.supported) {
      _pairingSub = session.pairing.events().listen((e) {
        final again = e.kind == core.PairingEventKind.paymentFinalized || e.kind == core.PairingEventKind.eventsMissed;
        if (again && _session == session) unawaited(_reload());
      });
    }
    if (!session.supportsInvoices) return;
    unawaited(_loadInvoiceExpiry().then((_) => _changed(), onError: (Object e) => logWarn('invoices', 'expiry not read: $e')));
    _invoiceSub = session.invoiceEvents().listen((e) => unawaited(_onInvoiceEvent(session, e)));
    _issuerSub = session.issuerEvents().listen((e) => unawaited(_onIssuerEvent(session, e)));
    _invoiceTimers = InvoiceScheduler(
      drainPayments: () => _drainPayments(session),
      paymentsWanted: _paymentsWanted,
      paymentsEvery: paymentsEvery,
    )..start();
  }

  /// On lock and before a reopen: timers off, events dropped. [forget] (lock) also drops what
  /// this session learned.
  void _stopInvoices({bool forget = false}) {
    _invoiceTimers?.stop();
    _invoiceTimers = null;
    unawaited(_invoiceSub?.cancel());
    _invoiceSub = null;
    unawaited(_issuerSub?.cancel());
    _issuerSub = null;
    unawaited(_pairingSub?.cancel());
    _pairingSub = null;
    if (!forget) return;
    _invoiceCheckedAt = null;
    _invoiceCheck = InvoiceCheck.ok;
    _invoiceProblem = null;
    _waitingSeen.clear();
    _endedUnpaid.clear();
    _invoiceFees.clear();
  }

  /// Whether the scheduler's timers run (tests).
  @visibleForTesting
  bool get invoiceTimersRunning => _invoiceTimers?.running ?? false;

  /// An issued invoice waits for its payer and nothing listens on the payments address.
  bool _paymentsWanted() => _listener == null && (_entries ?? const <core.TxEntry>[]).any((e) => e.awaitingPayer);

  /// Collects the contacts' mailboxes (the session sweeps after it) and records the check.
  Future<void> _collectInvoices(core.WalletSession session) async {
    final r = await session.collectInvoices();
    if (_session != session) return;
    _invoiceCheckedAt = DateTime.now();
    if (r.parked > 0 || r.notices > 0) {
      await _reload();
    } else {
      // Only the Invoices page's "Checked at" moved.
      _changed();
    }
  }

  /// Drains the payments address: payments for issued invoices are finalized and posted.
  Future<void> _drainPayments(core.WalletSession session) async {
    final r = await session.drainPayments();
    if (_session != session) return;
    // Nothing came: nothing to show, so no refresh either.
    if (r.received > 0 || r.finalized > 0 || r.bounced > 0) await _reload();
  }

  /// A payer: an invoice parked, posted, withdrawn or expired. Never pays anything.
  Future<void> _onInvoiceEvent(core.WalletSession session, core.InvoiceEvent e) async {
    // What reached this device only, for the linked device.
    if (e.kind == core.InvoiceEventKind.paymentPosted || e.kind == core.InvoiceEventKind.paymentCancelled || e.kind == core.InvoiceEventKind.paymentDeclined || e.kind == core.InvoiceEventKind.received) {
      _forward?.call(e);
    }
    if (_session != session) return;
    final ended = switch (e.kind) {
      core.InvoiceEventKind.withdrawn => HeldKind.withdrawn,
      core.InvoiceEventKind.expired => HeldKind.expired,
      core.InvoiceEventKind.declined => HeldKind.declined,
      core.InvoiceEventKind.paymentCancelled || core.InvoiceEventKind.paymentDeclined => HeldKind.cancelled,
      _ => null,
    };
    if (ended != null) _hold(session, ended, e.slateId);
    final seen = _waitingSeen[e.slateId];
    final now = DateTime.now();
    switch (e.kind) {
      case core.InvoiceEventKind.withdrawn when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.withdrawn, answeredAt: now);
        _hold(session, HeldKind.withdrawn, e.slateId, InvoiceNotice(InvoiceNoticeKind.withdrawn, slateId: e.slateId, who: seen.label));
      case core.InvoiceEventKind.expired when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.expired, answeredAt: now);
        _hold(session, HeldKind.expired, e.slateId, InvoiceNotice(InvoiceNoticeKind.expired, slateId: e.slateId, who: seen.label));
      case core.InvoiceEventKind.declined when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.declined, answeredAt: now);
      // Unverified (the session tells each slate once): inform only, act on nothing.
      case core.InvoiceEventKind.unknownInvoicePayment:
        _notify(InvoiceNotice(InvoiceNoticeKind.unknownPayment, slateId: e.slateId));
        return;
      case core.InvoiceEventKind.unknownSendAnswer:
        _notify(InvoiceNotice(InvoiceNoticeKind.unknownAnswer, slateId: e.slateId));
        return;
      case core.InvoiceEventKind.receiveSuperseded:
        _notify(InvoiceNotice(InvoiceNoticeKind.receiveSuperseded, slateId: e.slateId));
        await _reload();
        return;
      // Not an invoice: the sender of an Epicbox payment reports it posted. The row says so at
      // once, then one chain check ([sync] runs once more if one is running). No notice: the
      // desktop has none for incoming payments.
      case core.InvoiceEventKind.paymentPosted:
        logInfo('desk', 'sender reports a payment posted');
        await _reload();
        if (_session == session) unawaited(sync());
        return;
      // Not an invoice: the sender of a payment this wallet answered reports it cancelled. The
      // row says so at once, and the payment is cleared if the network does not have it.
      case core.InvoiceEventKind.paymentCancelled:
        logInfo('desk', 'sender reports a payment cancelled');
        await _reload();
        if (_session == session) await _releaseSenderCancelled();
        return;
      // Not an invoice: the receiver of a send refused it. The core cancelled the send.
      case core.InvoiceEventKind.paymentDeclined:
        logInfo('desk', 'receiver declined a send');
        await _reload();
        return;
      case _:
        break;
    }
    if (e.kind != core.InvoiceEventKind.received) _waitingSeen.remove(e.slateId);
    await _reload();
  }

  /// An issuer: an issued invoice paid, declined, expired, sent back or withdrawn. The session
  /// raises each once (a repeated bounce withdraws and tells once).
  Future<void> _onIssuerEvent(core.WalletSession session, core.IssuerEvent e) async {
    if (_session != session) return;
    // Held now, in the run that brought it: the words are looked up when it shows.
    final held = switch (e.kind) {
      core.IssuerEventKind.paid => HeldKind.paid,
      core.IssuerEventKind.expired => HeldKind.expired,
      _ => null,
    };
    if (held != null) {
      raiseNotice(session.checks.notices, HeldNotice(held, slateId: e.slateId, show: () => unawaited(_tellIssuer(session, e))));
    }
    await _reload();
    // "Paid" comes when the invoice is finalized; its post follows in the same collect. Read
    // again once it is out, so the row never sits on "Not posted" (LNX3-4).
    if (e.kind == core.IssuerEventKind.paid) {
      unawaited(Future<void>.delayed(const Duration(seconds: 5), () async {
        if (_session == session) await _reload();
      }));
    }
    if (held == null) await _tellIssuer(session, e);
  }

  /// The notice of an issuer's event, with the amount and the payer's name.
  Future<void> _tellIssuer(core.WalletSession session, core.IssuerEvent e) async {
    final kind = switch (e.kind) {
      core.IssuerEventKind.paid => InvoiceNoticeKind.paid,
      core.IssuerEventKind.declined => InvoiceNoticeKind.declined,
      core.IssuerEventKind.expired => InvoiceNoticeKind.issuedExpired,
      core.IssuerEventKind.bounced => InvoiceNoticeKind.bounced,
      core.IssuerEventKind.withdrawn => null,
    };
    if (kind == null) return;
    var amount = 0;
    var payer = e.payerAddress ?? '';
    try {
      final issued = await session.issuedInvoice(slateId: e.slateId);
      if (issued != null) {
        amount = issued.amount.toInt();
        if (payer.isEmpty) payer = issued.payerAddress;
      }
    } on core.WalletError catch (error) {
      logWarn('invoices', 'issued invoice not read for a notice: ${error.kind.name}');
    }
    if (_session != session) return;
    final people = await _contactsOr();
    var pairingId = e.pairingId;
    if (pairingId == null) {
      try {
        pairingId = (await session.issuedInvoice(slateId: e.slateId))?.pairingId;
      } on core.WalletError catch (_) {
        // Named by its address, if any.
      }
    }
    final paired = pairingId == null ? null : _pairedName(await session.pairing.pairings(), people, pairingId);
    if (_session != session) return;
    final who = paired ?? _contactFor(people, payer)?.name ?? (payer.isEmpty ? '' : shortAddress(payer, compact: true));
    _notify(InvoiceNotice(kind, slateId: e.slateId, who: who, amount: amount));
  }

  Future<List<Contact>> _contactsOr() async {
    try {
      return await contacts();
    } on Object {
      return const [];
    }
  }

  /// The contact [address] belongs to: one of its addresses, by key.
  static Contact? _contactFor(List<Contact> contacts, String address) {
    if (address.isEmpty) return null;
    final key = addressKey(address);
    return contacts.where((c) => c.addresses.any((a) => addressKey(a) == key)).firstOrNull;
  }

  /// The name the app shows for the pairing [id]: its contact's, else the name it chose.
  static String? _pairedName(List<core.PairingRecord> pairings, List<Contact> contacts, String? id) {
    if (id == null) return null;
    final r = pairings.where((p) => p.id == id).firstOrNull;
    if (r == null) return null;
    final contact = contacts.where((c) => c.id == r.contactId).firstOrNull;
    final name = contact?.name ?? pairingName(r, const <core.Contact>[]);
    return name.isEmpty ? null : name;
  }

  @override
  Future<InvoiceBook> invoices() async {
    final session = _open;
    try {
      return await _invoiceBook(session);
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
  }

  Future<InvoiceBook> _invoiceBook(core.WalletSession session) async {
    final now = DateTime.now();
    final pairings = await session.pairing.pairings();
    final people = await _contactsOr();
    final entries = _entries ?? await session.transactions(refresh: false);
    final minConf = _minConf.toInt();
    // The name is the user's contact's, or the pairing's own; never a name from the invoice.
    String labelOf(String? pairingId, String sender) =>
        _pairedName(pairings, people, pairingId) ?? shortAddress(sender, compact: true);

    final waiting = <IncomingInvoice>[];
    for (final p in await session.pendingInvoices()) {
      final amount = p.amount.toInt();
      var fee = _invoiceFees[p.slateId];
      if (fee == null) {
        try {
          fee = _invoiceFees[p.slateId] = (await session.estimateFee(amount: p.amount, minimumConfirmations: _minConf)).fee.toInt();
        } on core.WalletError catch (e) {
          // Not enough funds: Review says so from the balance; the next read asks again.
          logDebug('invoices', 'fee not estimated: ${e.kind.name}');
        }
      }
      waiting.add(
        IncomingInvoice(
          slateId: p.slateId,
          senderAddress: p.senderAddress,
          label: labelOf(p.pairingId, p.senderAddress),
          pairingId: p.pairingId,
          reference: _line(p.reference),
          amount: amount,
          fee: fee ?? 0,
          feeKnown: fee != null,
          message: _line(p.message),
          receivedAt: p.receivedAt,
          expiresAt: p.expiresAt,
          state: PayState.waiting,
        ),
      );
    }
    _waitingSeen
      ..clear()
      ..addAll({for (final i in waiting) i.slateId: i});

    final paid = <IncomingInvoice>[];
    for (final e in entries) {
      final slateId = e.slateId;
      final outgoing = e.kind == core.TxKind.sent || e.kind == core.TxKind.sentCancelled;
      if (e.flow != core.TxFlow.invoice || !outgoing || slateId == null) continue;
      final record = await session.paidInvoice(slateId: slateId);
      if (record == null) continue;
      final tx = deskTx(e, tip: _tip, minConf: minConf, fallbackId: -1);
      paid.add(
        IncomingInvoice(
          slateId: slateId,
          senderAddress: record.senderAddress,
          label: labelOf(record.pairingId, record.senderAddress),
          pairingId: record.pairingId,
          reference: _line(record.reference),
          amount: record.amount.toInt(),
          fee: tx.fee,
          message: _line(record.message),
          receivedAt: tx.created,
          expiresAt: tx.created.add(_invoiceExpiry),
          state: payState(e, record.status, tip: _tip, minConf: minConf, overdueAt: tx.created.add(_invoiceExpiry), now: now),
          confirmations: tx.confirmations,
          txId: e.id,
          answeredAt: tx.created,
          kernel: record.kernelExcess,
          cancelNotFinal: _cancelFinal[e.id] == false,
        ),
      );
    }

    // A request a history backup brought back has no local id: its row is found by slate id,
    // with the id Activity gives it ([_txs]).
    final sent = [
      for (final r in await session.issuedInvoices())
        if (r.txId != null)
          _request(r, entries.where((e) => e.id == r.txId).firstOrNull, people, minConf: minConf, pairings: pairings)
        else if (entries.indexWhere((e) => e.source != core.TxSource.wallet && e.slateId == r.slateId && e.isRequest) case final i when i >= 0)
          _request(r, entries[i], people, minConf: minConf, pairings: pairings, fallbackId: entries[i].id ?? -1 - i),
    ];

    return InvoiceBook(
      now: now,
      toPay: [...waiting, ...paid, for (final i in _endedUnpaid.values) if (!waiting.any((w) => w.slateId == i.slateId)) i],
      sent: sent,
      expiry: _invoiceExpiry,
      lastCheck: _invoiceCheckedAt,
      check: _invoiceCheck,
      checkProblem: _invoiceProblem,
    );
  }

  /// Untrusted text as one plain line, or null when nothing is left (P-14).
  static String? _line(String? text) {
    final s = cleanInvoiceText(text);
    return s.isEmpty ? null : s;
  }

  IssuedRequest _request(
    core.IssuedInvoice r,
    core.TxEntry? e,
    List<Contact> people, {
    required int minConf,
    List<core.PairingRecord> pairings = const [],
    int fallbackId = -1,
  }) {
    final tx = e == null ? null : deskTx(e, tip: _tip, minConf: minConf, fallbackId: fallbackId);
    return IssuedRequest(
      slateId: r.slateId,
      txId: r.txId ?? fallbackId,
      payerAddress: r.payerAddress,
      payerName: _pairedName(pairings, people, r.pairingId) ?? _contactFor(people, r.payerAddress)?.name,
      amount: r.amount.toInt(),
      message: _line(r.message),
      issuedAt: r.issuedAt,
      expiresAt: r.issuedAt.add(_invoiceExpiry),
      state: requestState(r.state, e, tip: _tip, minConf: minConf),
      confirmations: tx?.confirmations ?? 0,
      byFile: r.byFile,
      inPerson: e?.epic1Via == Epic1Via.inPerson,
    );
  }

  /// One collect of the contacts' mailboxes and, with the listener off, the payments address.
  @override
  Future<InvoiceBook> checkInvoices() async {
    final session = _open;
    _invoiceCheck = InvoiceCheck.checking;
    try {
      await _collectInvoices(session);
      // Nothing issued, nothing to drain: the Epicbox listener stays the user's choice.
      if (_paymentsWanted()) await _drainPayments(session);
      _invoiceCheck = InvoiceCheck.ok;
      _invoiceProblem = null;
    } on core.WalletError catch (e) {
      _invoiceCheck = InvoiceCheck.failed;
      _invoiceProblem = deskErrorText(e);
      throw invoiceError(e);
    }
    return invoices();
  }

  @override
  Future<RequestFileMade> requestFile({required int amount, String? message}) async {
    try {
      final slate = await _open.pairing.requestFile(amount: BigInt.from(amount), message: message);
      await _reload();
      return RequestFileMade(slateId: slate.slateId, json: slate.json);
    } on core.WalletError catch (e) {
      throw invoiceError(e, issuing: true);
    }
  }

  @override
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft) async {
    final session = _open;
    try {
      // A request the relay did not take is cancelled by the session: nothing was sent.
      final r = await session.pairing.requestPayment(id: draft.pairingId, amount: BigInt.from(draft.amount), message: draft.message);
      await _reload();
      final e = (_entries ?? const <core.TxEntry>[]).where((t) => t.id == r.txId).firstOrNull;
      final request = _request(r, e, await _contactsOr(), minConf: _minConf.toInt(), pairings: await session.pairing.pairings());
      return draft.payerName == null || request.payerName != null
          ? request
          : IssuedRequest(
              slateId: request.slateId,
              txId: request.txId,
              payerAddress: request.payerAddress,
              payerName: draft.payerName,
              amount: request.amount,
              message: request.message,
              issuedAt: request.issuedAt,
              expiresAt: request.expiresAt,
              state: request.state,
            );
    } on core.WalletError catch (e) {
      throw invoiceError(e, issuing: true);
    }
  }

  @override
  Future<void> withdrawRequest(String slateId) async {
    try {
      await _open.withdrawInvoice(slateId: slateId);
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    await _reload();
  }

  @override
  Future<void> repostRequest(String slateId) async {
    final txId = (_entries ?? await _open.transactions(refresh: false)).where((e) => e.slateId == slateId && e.isRequest).firstOrNull?.id;
    if (txId == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice'); // l10n-ok: InvoiceError.message is for logs; screens word the problem
    try {
      await repostTx(txId);
    } on DeskError catch (e) {
      throw InvoiceError(InvoiceProblem.nodeDown, e.message);
    }
  }

  /// The receiver-side cancel of a paid request's payment that was never posted (flow §3.3):
  /// LEPIC asks the node first and refuses one in the pool or on chain. Never automatic.
  @override
  Future<void> cancelRequestPayment(String slateId) async {
    final entries = _entries ?? await _open.transactions(refresh: false);
    final txId = entries.where((e) => e.slateId == slateId && e.isRequest).firstOrNull?.id;
    if (txId == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice'); // l10n-ok
    try {
      await _running(() => _open.cancelTransaction(txId: txId));
    } on core.WalletError catch (e) {
      throw _cancelError(e);
    }
    await _reload();
  }

  /// A refused cancel in the screens' terms: the node has it, or the node cannot be asked.
  static InvoiceError _cancelError(core.WalletError e) => switch (e.kind) {
    core.WalletErrorKind.invalidArgument => const InvoiceError(InvoiceProblem.onItsWay, 'Already on its way: it cannot be cancelled.'), // l10n-ok
    core.WalletErrorKind.nodeUnreachable => const InvoiceError(InvoiceProblem.cannotCheck, 'Cannot check the network now.'), // l10n-ok
    _ => invoiceError(e),
  };

  /// The only call that pays an invoice: Review's Approve, after the password, which is
  /// checked here first. [amount] is the invoice's own; LEPIC refuses any other.
  @override
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password}) => _running(() async {
    final session = _open;
    if (!await checkPassword(password)) throw const InvoiceError(InvoiceProblem.wrongPassword, 'Wrong password'); // l10n-ok
    final waiting = _waitingSeen[slateId];
    final core.PaidInvoice paid;
    try {
      paid = await session.payInvoice(slateId: slateId, amount: BigInt.from(amount));
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    _waitingSeen.remove(slateId);
    await _reload();
    final e = (_entries ?? const <core.TxEntry>[]).where((t) => t.id == paid.txId).firstOrNull;
    final state = e == null
        ? (paid.status == core.InvoiceStatus.replyFailed ? PayState.notDelivered : PayState.delivered)
        : payState(e, paid.status, tip: _tip, minConf: _minConf.toInt());
    final now = DateTime.now();
    return IncomingInvoice(
      slateId: slateId,
      senderAddress: waiting?.senderAddress ?? paid.senderAddress,
      label: waiting?.label ?? shortAddress(paid.senderAddress, compact: true),
      amount: paid.amount.toInt(),
      fee: e?.fee?.toInt() ?? waiting?.fee ?? 0,
      message: _line(paid.message),
      receivedAt: waiting?.receivedAt ?? now,
      expiresAt: waiting?.expiresAt ?? now,
      state: state,
      txId: paid.txId,
      answeredAt: now,
    );
  });

  @override
  Future<IncomingInvoice> retryInvoiceReply(String slateId) async {
    final session = _open;
    try {
      // Sends the stored reply again; signs nothing.
      await session.resendInvoiceReply(slateId: slateId);
    } on core.WalletError catch (e) {
      throw e.kind == core.WalletErrorKind.transportFailed ? InvoiceError(InvoiceProblem.relayDown, deskErrorText(e)) : invoiceError(e);
    }
    await _reload();
    final book = await invoices();
    return book.invoice(slateId) ?? (throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice')); // l10n-ok
  }

  @override
  Future<void> declineInvoice(String slateId) async {
    try {
      await _open.declineInvoice(slateId: slateId);
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    final seen = _waitingSeen.remove(slateId);
    if (seen != null) _endedUnpaid[slateId] = seen.copyWith(state: PayState.declined, answeredAt: DateTime.now());
    _changed();
  }

  /// The user's cancel of an invoice payment: LEPIC asks the node first and refuses one
  /// in the pool or on chain. The issuer holds the signed payment, so the cancel also spends
  /// its coins back to this wallet ([CancelFinal]). Never automatic.
  @override
  Future<CancelResult> cancelInvoicePayment(String slateId, {bool spendBack = true}) async {
    final entries = await _open.transactions(refresh: false);
    final entry = entries
        .where((e) => e.slateId == slateId && e.flow == core.TxFlow.invoice && (e.kind == core.TxKind.sent || e.kind == core.TxKind.sentCancelled))
        .firstOrNull;
    if (entry?.id == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such payment'); // l10n-ok
    final CancelResult result;
    try {
      result = await _running(() => _cancels.cancel(_open, entry!, spendBack: spendBack));
    } on core.WalletError catch (e) {
      throw _cancelError(e);
    }
    await _reload();
    return result;
  }

  // The open wallet's pairing; nothing while locked.
  @override
  core.PairingApi get pairing => _session?.pairing ?? const core.NoPairing();

  @override
  Epic1Wallet? get epic1 => _session?.epic1;

  @override
  Boosts? get boosts => _session?.boosts;

  @override
  Future<PeerCompat?> peerCompat(String address) => _service.peerCompat(address);

  @override
  Future<void> forgetPeers({required Duration olderThan}) => _open.forgetPeers(olderThan: olderThan);

  /// Where the book of linked devices is read from ([useDevices]).
  DeviceBook? Function()? _deviceBook;

  /// The coins the linked devices hold, given to every session this wallet opens.
  Set<String> _deviceHeld = const {};

  /// The open wallet's host for its linked devices. It follows the wallet through a reopen (a
  /// node or Epicbox change, node failover), so one service keeps the link under way and the
  /// book the lists show; a service per session lost a link the reopen came in the middle of,
  /// and the other device listed this one while this one did not list it. While this wallet is
  /// closed or another is open it reaches nothing.
  @override
  DeviceHost? deviceHost({required bool Function() online}) {
    if (_session == null) return null;
    return _DeskDeviceHost(this, _openEntry?.id, online);
  }

  /// The open wallet's name services host; like [deviceHost] it follows the wallet through a reopen.
  @override
  NameServiceHost? nameServiceHost({required bool Function() online}) {
    if (_session == null) return null;
    return _DeskNameServiceHost(this, _openEntry?.id, online);
  }

  /// The open session of the wallet [id], or null while it is not open.
  core.WalletSession? _sessionOf(String? id) => _openEntry?.id == id ? _session : null;

  @override
  void useDevices(DeviceBook? Function()? book) => _deviceBook = book;

  /// Where notices that reached this device only go for the linked device ([noticeForwarder]).
  void Function(core.InvoiceEvent e)? _forward;

  @override
  set noticeForwarder(void Function(core.InvoiceEvent e)? forward) => _forward = forward;

  @override
  Future<void> applyForwarded(ForwardedNotice notice) async {
    final session = _session;
    if (session == null) return;
    switch (notice.kind) {
      case ForwardKind.posted:
        logInfo('desk', 'the linked device heard a payment posted');
        await _reload();
        if (_session == session) unawaited(sync());
      case ForwardKind.cancelled:
        logInfo('desk', 'the linked device heard a payment cancelled');
        await _reload();
      case ForwardKind.declined:
        logInfo('desk', 'the linked device heard a send declined');
        await _reload();
      case ForwardKind.invoice:
        _notify(InvoiceNotice(InvoiceNoticeKind.requestOnDevice, slateId: notice.slateId, who: notice.device));
    }
  }

  /// [entries] with the other devices' payments merged in; the same list for every reader, so
  /// the rows keep their fallback ids.
  List<core.TxEntry> _withDevices(List<core.TxEntry> entries) {
    final book = _deviceBook?.call();
    return book == null ? entries : mergeDeviceHistory(entries, book);
  }

  /// The coins other devices hold here: commitment → the device's name.
  Map<String, String> _heldBy() {
    final book = _deviceBook?.call();
    if (book == null) return const {};
    return {
      for (final h in book.holds)
        if (h.state.holds)
          for (final c in h.commitments) c: book.device(h.deviceId)?.name ?? h.deviceName ?? '',
    };
  }

  @override
  Future<void> setInvoiceExpiry(Duration expiry) async {
    _invoiceExpiry = expiry > maxInvoiceExpiry ? maxInvoiceExpiry : expiry;
    await _setMeta({_invoiceExpiryKey: _invoiceExpiry.inSeconds});
    _changed();
  }

  // ---- Helpers.

  /// The open wallet's automatic reposts and resends; a new one per unlock.
  StallRetry _stall = StallRetry();

  /// Posts again a payment the chain has not taken and sends again a paid invoice's answer, when
  /// the shared policy says it is due (stall_retry.dart). Runs with each node check.
  Future<void> _retryStalled() async {
    final session = _session;
    final entries = _entries;
    if (session == null || entries == null) return;
    if (await retryStalled(_stall, session, entries, DateTime.now(), tag: 'desk') && _session == session) await _reload();
  }

  /// The open wallet's release of incoming payments their senders cancelled; a new one per unlock.
  SenderCancelRelease _senderCancel = SenderCancelRelease();

  /// The open wallet's cancels, with the spends back still owed (cancel_final.dart); a new one
  /// per unlock.
  CancelFinal _cancels = CancelFinal();

  /// For each cancelled payment the other side may have been able to finish ([cancelSpendsBack]
  /// of its kind), whether the cancel is final ([cancelFinal]), by local id; read with the list.
  Map<int, bool> _cancelFinal = const {};

  /// Local ids of the cancels [cancelSettled] found final on the chain this session: their
  /// outputs are not read again.
  final Set<int> _cancelSettled = {};

  /// Clears each incoming payment its sender cancelled that still waits (sender_cancel.dart),
  /// then reads the list again. Runs on the sender's notice and with each node check, so one
  /// that failed (no node, locked) goes again.
  Future<void> _releaseSenderCancelled() async {
    final session = _session;
    final entries = _entries;
    if (session == null || entries == null) return;
    if (await releaseSenderCancelled(_senderCancel, session, entries, tag: 'desk') && _session == session) await _reload();
    // A cancel whose spend back failed goes again with the node.
    if (await retrySpendBack(_cancels, session, tag: 'desk') && _session == session) await _reload();
  }

  /// [_cancelFinal] for [entries]: the outputs are read only when one not yet settled on the
  /// chain needs them.
  Future<Map<int, bool>> _cancelFinalOf(core.WalletSession session, List<core.TxEntry> entries) async {
    final cancelled = entries.where((e) => e.id != null && cancelledMayComplete(e)).toList();
    final settled = {for (final e in cancelled) if (_cancelSettled.contains(e.id)) e.id!: true};
    final open = cancelled.where((e) => !_cancelSettled.contains(e.id)).toList();
    if (open.isEmpty) return settled;
    try {
      final outputs = await session.outputs();
      for (final e in open) {
        if (cancelSettled(e, outputs)) _cancelSettled.add(e.id!);
      }
      return {...settled, for (final e in open) e.id!: cancelFinal(e, outputs)};
    } on core.WalletError catch (e) {
      logWarn('desk', 'cancel final: ${e.kind.name}');
      return settled;
    }
  }

  /// Counts [_reload]s, so one that started earlier and ends later keeps what a later one read.
  int _reloads = 0;

  Future<void> _reload() async {
    final session = _session;
    if (session == null) return;
    final run = ++_reloads;
    try {
      final summary = await session.summary(refresh: false, minimumConfirmations: _minConf);
      final entries = await session.transactions(refresh: false);
      final finals = await _cancelFinalOf(session, entries);
      await _readRewardLocks(session, entries);
      // A later read is under way or done: it saw the newer state (a posted payment, LNX3-4).
      if (run != _reloads) return;
      _summary = summary;
      _entries = entries;
      _cancelFinal = finals;
    } on core.WalletError catch (e) {
      logWarn('desk', 'reload: ${e.kind.name}');
    }
    _changed();
  }

  /// The tip each payment waiting for a block was first seen at, for its wait note.
  final BlockWatch _blockWaits = BlockWatch();

  BlockWait _waitOf(core.TxEntry e) => _blockWaits.waitOf(e, now: DateTime.now(), tip: BigInt.from(_tip));

  List<Tx> _txs() {
    final entries = _withDevices(_entries ?? const <core.TxEntry>[]);
    _blockWaits.saw(entries, BigInt.from(_tip));
    return [
      for (final (i, e) in entries.indexed) deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1 - i, wait: _waitOf(e), cancelFinal: _cancelFinal[e.id], lockHeight: _rewardLockOf(e)),
    ];
  }

  Tx _txFor(core.TxEntry e) =>
      _txs().where((t) => t.id == e.id && e.id != null).firstOrNull ?? deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1, wait: _waitOf(e), cancelFinal: _cancelFinal[e.id], lockHeight: _rewardLockOf(e));

  /// Stops background work for good (the app is closing).
  Future<void> dispose() async {
    final watch = Stopwatch()..start();
    // Each step's time goes to the log, so a slow close says where it waited.
    void step(String what) => logInfo('desk', 'closing: $what after ${watch.elapsedMilliseconds} ms');
    statusSite.removeListener(_statusSiteChanged);
    await _lock(waitAtMost: closeWait);
    step('wallet locked'); // l10n-ok: log text
    await _nodeNoticeSub?.cancel();
    await _node?.stop();
    step('node stopped'); // l10n-ok: log text
    // Not awaited: a broadcast stream's close ends only once every listener got its done
    // event, and Riverpod pauses a provider nobody watches (the invoice notices on the unlock
    // screen), so after a lock the close never ended and closing waited its 40 s (LNX-4).
    unawaited(_changes.close());
    unawaited(_invoiceNotices.close());
    step('done');
  }
}

DateTime? _time(Object? unix) => unix is int ? DateTime.fromMillisecondsSinceEpoch(unix * 1000) : null;

/// One output as the Outputs page shows it. An unspent output under [minConf] confirmations
/// is confirming, a mining reward below its lock height immature; an unconfirmed one (not on
/// chain yet, or a reward still being mined) is unconfirmed.
Output deskOutput(core.WalletOutput o, {required int minConf, String? heldBy}) {
  final status = switch (o.status) {
    // Spendable here, left out of every send while a payment of a linked device holds it.
    core.WalletOutputStatus.unspent when heldBy != null && o.category == core.OutputCategory.spendable => OutputStatus.locked,
    core.WalletOutputStatus.spent => OutputStatus.spent,
    core.WalletOutputStatus.locked => OutputStatus.locked,
    core.WalletOutputStatus.unconfirmed => OutputStatus.unconfirmed,
    core.WalletOutputStatus.unspent => switch (o.category) {
      core.OutputCategory.spendable => OutputStatus.unspent,
      core.OutputCategory.immature => OutputStatus.immature,
      core.OutputCategory.awaitingConfirmation => OutputStatus.confirming,
      core.OutputCategory.locked => OutputStatus.locked,
      core.OutputCategory.awaitingFinalization || core.OutputCategory.unpaidInvoice || null => OutputStatus.unconfirmed,
    },
  };
  final onChain = o.status != core.WalletOutputStatus.unconfirmed;
  return Output(
    commitment: o.commitment,
    value: o.value.toInt(),
    status: status,
    height: onChain ? o.height.toInt() : null,
    confirmations: o.confirmations.toInt(),
    confirmationsNeeded: minConf,
    lockHeight: o.isCoinbase ? o.lockHeight.toInt() : null,
    isCoinbase: o.isCoinbase,
    awaitingFinalization: o.category == core.OutputCategory.awaitingFinalization,
    unpaidInvoice: o.category == core.OutputCategory.unpaidInvoice,
    hasCategory: o.category != null,
    mmrIndex: o.mmrIndex?.toInt(),
    txId: o.txId,
    heldBy: heldBy,
  );
}

/// One history row as the desktop UI shows it. [tip] is the node's height, for confirmations.
/// Rows without a local id (imported, restored) get [fallbackId], below 0.
Tx deskTx(core.TxEntry e, {required int tip, required int minConf, required int fallbackId, String? contactName, DateTime? now, BlockWait wait = BlockWait.none, bool? cancelFinal, int? lockHeight}) {
  final sent = e.kind == core.TxKind.sent || e.kind == core.TxKind.sentCancelled;
  final fee = e.fee?.toInt() ?? 0;
  final height = e.blockHeight?.toInt();
  final confirmations = height == null || tip < height ? 0 : tip - height + 1;
  final state = switch (e.status) {
    core.TxStatus.cancelled => TxState.cancelled,
    core.TxStatus.awaitingRecipient => TxState.waitingRecipient,
    // A request nobody paid yet is not on its way to the chain: it waits for the payer, as the
    // mock keeps it (windows-05 read "posted" in its technical details).
    core.TxStatus.awaitingConfirmation when e.awaitingPayer => TxState.waitingRecipient,
    // One a history backup brought back still open: never paid as far as anyone here knows,
    // so an asked amount, not a payment on its way.
    core.TxStatus.awaitingConfirmation when e.isRequest && height == null && e.source != core.TxSource.wallet =>
      TxState.waitingRecipient,
    // A payment answered here waits for its sender to finalize and post it: not on the network
    // yet (it read "Waiting for a block"). A paid request is this wallet's to post, so posted.
    core.TxStatus.awaitingConfirmation when height == null && e.kind == core.TxKind.received && !e.isRequest => TxState.waitingRecipient,
    core.TxStatus.awaitingConfirmation => height == null ? TxState.posted : TxState.confirming,
    // In a block and short of the wallet's confirmations: confirming, a block above this
    // wallet's height too (a linked payment its kernel dated before the wallet caught up).
    core.TxStatus.confirmed => height != null && tip > 0 && confirmations < minConf ? TxState.confirming : TxState.confirmed,
  };
  final to = e.counterparty;
  final method = switch (e.transport) {
    'tor' => TxMethod.tor,
    'http' => TxMethod.http,
    // A restored row has no wallet record of how it came: only the user's words say.
    'file' when e.source == core.TxSource.restored => TxMethod.file,
    // Through a pairing's mailbox: Epicbox, though LEPIC keeps it with no address, as a file
    // exchange until its answer is in.
    _ when e.pairingId != null && to == null => TxMethod.epicbox,
    _ when to != null && to.toLowerCase().contains('.onion') => TxMethod.tor,
    _ when to == null => e.source == core.TxSource.wallet && e.kind != core.TxKind.coinbase ? TxMethod.file : TxMethod.epicbox,
    _ when to.startsWith('http') => TxMethod.http,
    _ => TxMethod.epicbox,
  };
  final amount = sent ? e.amountDebited.toInt() - e.amountCredited.toInt() - fee : e.amountCredited.toInt() - e.amountDebited.toInt();
  return Tx(
    id: e.id ?? fallbackId,
    slateId: e.slateId ?? '',
    direction: sent ? TxDirection.sent : TxDirection.received,
    state: state,
    method: method,
    amount: amount < 0 ? 0 : amount,
    fee: sent ? fee : 0,
    created: DateTime.fromMillisecondsSinceEpoch(e.timeUnix * 1000),
    startedAt: DateTime.fromMillisecondsSinceEpoch(e.createdAtUnix * 1000),
    confirmations: confirmations,
    confirmationsNeeded: minConf,
    counterparty: to,
    // A split or consolidate: both sides are this wallet.
    contactName: e.transport == 'self' ? null : contactName,
    toSelf: e.transport == 'self',
    message: core.messageBy(e.messages, core.SlateRole.sender) ?? core.messageBy(e.messages, core.SlateRole.receiver),
    messageBySender: core.messageBy(e.messages, core.SlateRole.sender) != null || core.messageBy(e.messages, core.SlateRole.receiver) == null,
    height: height,
    kernel: e.kernelExcess,
    outputCommits: e.outputCommits,
    expiryHeight: e.ttlCutoffHeight?.toInt(),
    coinbase: e.kind == core.TxKind.coinbase,
    lockHeight: e.kind == core.TxKind.coinbase ? lockHeight : null,
    otherWallet: e.origin == core.TxOrigin.otherWallet,
    unverified: e.unverified,
    epic1Via: e.epic1Via,
    sealed: e.sealed,
    foundByScan: e.source == core.TxSource.restored,
    foundDuring: switch (e.foundDuring) {
      core.TxFoundDuring.restore => FoundDuring.restore,
      core.TxFoundDuring.rescan => FoundDuring.rescan,
      null => null,
    },
    datedByBlock: e.datedByBlock,
    fromBackup: e.source == core.TxSource.imported,
    cancellable: e.cancellable && !e.isRequest,
    notPosted: e.repostable,
    posting: e.posting,
    cancelFinal: cancelFinal,
    undelivered: e.undelivered,
    flow: e.flow == core.TxFlow.invoice ? TxFlow.invoice : TxFlow.payment,
    key: e.key,
    transport: e.transport,
    label: e.label,
    note: e.note,
    manualFields: e.manualFields,
    manualEditedAt: e.manualEditedAtUnix == null ? null : DateTime.fromMillisecondsSinceEpoch(e.manualEditedAtUnix! * 1000),
    confirmedAt: e.blockTimeUnix == null ? null : DateTime.fromMillisecondsSinceEpoch(e.blockTimeUnix! * 1000),
    detail: e.statusDetail,
    senderPosted: core.senderReportsPosted(e, now: now ?? DateTime.now()),
    senderCancelled: core.senderCancelled(e),
    receiverDeclined: core.receiverDeclined(e),
    pairingId: e.pairingId,
    blockWait: wait,
    credited: e.amountCredited.toInt(),
    deviceName: e.origin == core.TxOrigin.linkedDevice ? e.deviceName : null,
    deviceEnding: e.origin == core.TxOrigin.linkedDevice ? e.deviceEnding : null,
    deviceWhy: e.origin == core.TxOrigin.linkedDevice ? e.deviceWhy : null,
    receivedOn: e.origin == core.TxOrigin.otherWallet ? e.deviceName : null,
  );
}

/// Where a paid invoice stands, from its payment and what the session recorded
/// of the reply and the service's notices. A payment still waiting at [overdueAt] is past its
/// time: LEPIC never marks an invoice payment releasable, and by then the service's invoice has
/// expired, so the user may cancel it (LEPIC still asks the node first).
PayState payState(core.TxEntry e, core.InvoiceStatus status, {required int tip, required int minConf, DateTime? overdueAt, DateTime? now}) {
  if (e.status == core.TxStatus.cancelled) return PayState.cancelled;
  if (status == core.InvoiceStatus.replyFailed) return PayState.notDelivered;
  final height = e.blockHeight?.toInt();
  if (height != null) return (tip < height ? 0 : tip - height + 1) >= minConf ? PayState.completed : PayState.confirming;
  if (e.status == core.TxStatus.confirmed) return PayState.completed;
  if (status == core.InvoiceStatus.withdrawn) return PayState.withdrawnAfterPay;
  // Its time to live passed without the kernel: the user may cancel it.
  final ttl = e.ttlCutoffHeight?.toInt();
  if (e.releasable || (ttl != null && tip > ttl)) return PayState.pastTtl;
  if (status == core.InvoiceStatus.posted) return PayState.posted;
  if (overdueAt != null && !(now ?? DateTime.now()).isBefore(overdueAt)) return PayState.pastTtl;
  // Not on the network a while after paying, though sent again by itself (stall_retry.dart).
  if (now != null && invoicePaymentStalled(e, now)) return PayState.stalled;
  return PayState.delivered;
}

/// Where an issued invoice stands, from the session's state and, once paid,
/// its transaction.
RequestState requestState(core.IssuedInvoiceState state, core.TxEntry? e, {required int tip, required int minConf}) {
  switch (state) {
    case core.IssuedInvoiceState.waiting:
      return RequestState.waiting;
    case core.IssuedInvoiceState.declined:
      return RequestState.declined;
    case core.IssuedInvoiceState.withdrawn:
      return RequestState.withdrawn;
    case core.IssuedInvoiceState.expired:
      return RequestState.expired;
    case core.IssuedInvoiceState.bounced:
      return RequestState.bounced;
    case core.IssuedInvoiceState.paid:
      if (e == null) return RequestState.paid;
      if (e.status == core.TxStatus.cancelled) return RequestState.cancelled;
      if (e.repostable) return RequestState.notPosted;
      final height = e.blockHeight?.toInt();
      if (height != null) return (tip < height ? 0 : tip - height + 1) >= minConf ? RequestState.completed : RequestState.confirming;
      if (e.status == core.TxStatus.confirmed) return RequestState.completed;
      // Posted, in the pool.
      if (e.status == core.TxStatus.awaitingConfirmation) return RequestState.confirming;
      return RequestState.paid;
  }
}

/// An invoice call's failure in the screens' terms. [issuing]: a relay that did not take a new
/// invoice means nothing was sent.
InvoiceError invoiceError(core.WalletError e, {bool issuing = false}) => InvoiceError(switch (e.kind) {
  core.WalletErrorKind.wrongPassword => InvoiceProblem.wrongPassword,
  core.WalletErrorKind.transportFailed => issuing ? InvoiceProblem.notDelivered : InvoiceProblem.relayDown,
  core.WalletErrorKind.nodeUnreachable => InvoiceProblem.nodeDown,
  core.WalletErrorKind.paymentExpired => InvoiceProblem.expired,
  core.WalletErrorKind.invoiceNotFound || core.WalletErrorKind.invoiceAlreadyPaid => InvoiceProblem.alreadyAnswered,
  core.WalletErrorKind.invoiceLockedAboveTip => InvoiceProblem.lockedAboveTip,
  core.WalletErrorKind.amountMismatch => InvoiceProblem.amountMismatch,
  _ => InvoiceProblem.invalid,
}, deskErrorText(e), cause: e.kind.name);

/// History backups are small; a file far larger is not one (the phone's limit).
const int maxDeskHistoryBytes = 32 << 20;

/// A history file the core refused, in the backup design's words.
Object historyFileError(core.WalletError e) {
  if (e.kind != core.WalletErrorKind.invalidArgument) return _deskError(e);
  final m = e.message;
  final chains = RegExp(r'^This history file is from ').firstMatch(m);
  if (chains != null) return HistoryFileError.l10n(HistoryFileProblem.otherChain, (l) => l.deskErrHistChains);
  return switch (m) {
    historyOtherWallet => HistoryFileError.l10n(HistoryFileProblem.otherWallet, (l) => l.deskErrHistOtherWalletText),
    historyNewer => HistoryFileError.l10n(HistoryFileProblem.newer, (l) => l.deskErrHistNewerText),
    historyDamaged => HistoryFileError.l10n(HistoryFileProblem.damaged, (l) => l.deskErrHistDamagedText),
    _ => HistoryFileError.l10n(HistoryFileProblem.notOurs, (l) => l.deskErrHistNotOursText),
  };
}

/// Writes `WALLET.txt` into the wallet folder [dir]: what the folder is and that it is
/// not a backup. No address, no id, no path, no secret. A failure is logged, never shown.
Future<void> writeWalletTxt(String dir, {required String label, required String network, required DateTime created}) async {
  String two(int v) => v.toString().padLeft(2, '0');
  final day = '${created.year}-${two(created.month)}-${two(created.day)}';
  final text = [
    'BT Wallet (BT Labs) wallet folder', // l10n-ok: WALLET.txt is a file in the wallet folder, English
    'Label:     $label', // l10n-ok
    if (network != 'mainnet') 'Network:   $network', // l10n-ok: mainnet, the only network a user sees, is never named
    'Created:   $day', // l10n-ok
    'App:       $deskAppVersion', // l10n-ok
    '',
    'wallet.vault    the seed, encrypted with the wallet password (Argon2id)', // l10n-ok
    'wallet.sqlite3  outputs and payment history', // l10n-ok
    '',
    'This folder is not a backup. Restore with the recovery phrase.', // l10n-ok
    'A copy of this folder is only as safe as the password.', // l10n-ok
    'Payment details and contacts: Settings > This wallet > Export wallet data.', // l10n-ok
    '',
  ].join('\n');
  try {
    // Whole or not at all: a temporary file renamed over it.
    final target = '$dir${Platform.pathSeparator}WALLET.txt';
    final tmp = File('$target.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(target);
  } on Object catch (e) {
    logWarn('desk', 'WALLET.txt not written: ${e.runtimeType}');
  }
}

/// [LepicDeskWallet.nameServiceHost]: the session of one wallet, whichever is open now; its calls
/// fail while the wallet reopens, so a run of the name services waits for the next one.
class _DeskNameServiceHost implements NameServiceHost {
  _DeskNameServiceHost(this._wallet, this._id, this._online) : _last = _wallet._sessionOf(_id)!;

  final LepicDeskWallet _wallet;
  final String? _id;
  final bool Function() _online;
  core.WalletSession _last;

  SessionNameServiceHost get _host {
    _last = _wallet._sessionOf(_id) ?? _last;
    return SessionNameServiceHost(
      _last,
      net: netOfChain(_wallet.preset.chain),
      verifier: _wallet._service.verifyListingSignature,
      online: _online,
    );
  }

  @override
  core.PairingApi get pairing => _host.pairing;

  @override
  Boosts get boosts => _host.boosts;

  @override
  bool get online => _online();

  @override
  int get net => netOfChain(_wallet.preset.chain);

  @override
  NameServiceVerifier get verifier => _wallet._service.verifyListingSignature;

  @override
  Future<String> listingAddress(String serviceKeyHex, int generation) => _host.listingAddress(serviceKeyHex, generation);

  @override
  Future<Uint8List> sign(String serviceKeyHex, int generation, String domain, Uint8List message) =>
      _host.sign(serviceKeyHex, generation, domain, message);

  @override
  Future<core.PaymentsDrainReport> drain(String serviceKeyHex, int generation) => _host.drain(serviceKeyHex, generation);

  @override
  Future<List<core.ListingDrainResult>> drainMany(List<ListingDrain> listings) => _host.drainMany(listings);
}

/// [LepicDeskWallet.deviceHost]: the session of one wallet, whichever is open now. While the
/// wallet reopens, or once it closed, it keeps the last one: its calls fail, so a run of the
/// devices waits for the next one. An engine that answered "no pairings" there would end the
/// link under way and forget every linked device as removed.
class _DeskDeviceHost implements DeviceHost {
  _DeskDeviceHost(this._wallet, this._id, this._online) : _last = _wallet._sessionOf(_id)!;

  final LepicDeskWallet _wallet;
  final String? _id;
  final bool Function() _online;
  core.WalletSession _last;

  core.WalletSession get _session => _last = _wallet._sessionOf(_id) ?? _last;

  SessionDeviceHost get _host => SessionDeviceHost(_session, online: _online, minimumConfirmations: _wallet._minConf);

  @override
  core.PairingApi get pairing => _session.pairing;

  @override
  Boosts get boosts => _session.boosts;

  @override
  bool get online => _online();

  @override
  Future<String> walletKey() => _host.walletKey();

  @override
  Future<void> cancelTransaction(int txId) => _host.cancelTransaction(txId);

  @override
  Future<String> signProof(List<int> message) => _host.signProof(message);

  @override
  Future<bool> verifyProof(List<int> message, String signature) => _host.verifyProof(message, signature);

  @override
  Stream<core.UnmatchedNotice> unmatchedNotices() => _host.unmatchedNotices();

  @override
  Future<bool> applyForwardedNotice(String sender, String notice) => _host.applyForwardedNotice(sender, notice);

  @override
  Future<List<core.WalletOutput>> outputs() => _host.outputs();

  @override
  Future<List<core.TxEntry>> transactions() => _host.transactions();

  @override
  Future<int?> tipHeight() => _host.tipHeight();

  @override
  Future<core.KernelLocation?> kernelOnChain(String excess, {int? minHeight}) => _host.kernelOnChain(excess, minHeight: minHeight);

  @override
  set heldOutputs(Set<String> commitments) {
    if (_wallet._openEntry?.id != _id) return;
    _wallet._deviceHeld = commitments;
    _wallet._session?.heldOutputs = commitments;
  }
}
