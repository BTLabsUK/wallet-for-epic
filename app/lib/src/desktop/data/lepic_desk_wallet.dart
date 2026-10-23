/// [DeskWalletApi] over the app's wallet core ([WalletService], LEPIC on a computer).
///
/// Desktop wallets are password wallets, as in the Electron wallet: no PIN vault. Several
/// named wallets of one network (mainnet), listed in the [registry] (D9): the first one at
/// `<app support>/wallets/<chain>` ([WalletDirResolver]) with a null [core.WalletConfig.walletId],
/// as 0.1.0 made it, each later one at `<app support>/wallets/<id>/<chain>` with walletId = id.
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

import '../../address_format.dart' show shortAddress;
import '../../btlabs_keys.dart' show btlabsKeyring;
import '../../btlabs_onions.dart';
import '../../btlabs_public.dart';
import '../../builtin_node.dart';
import '../../legacy_gui_profile.dart' as gui;
import '../../legacy_wallets.dart' as legacy;
import '../../log.dart';
import '../../node/node_settings.dart' show NodeSettings;
import '../../network.dart';
import '../../providers.dart' show WalletDirResolver, defaultMinimumConfirmations;
import '../../public_servers.dart';
import '../../net/http.dart' show NetError, httpGet;
import '../../net/tor_net.dart';
import '../../tor_routes.dart';
import '../../relay_directory.dart';
import '../../secret_store_api.dart';
import '../../seed_contacts.dart';
import '../../slate_files.dart' show decodeSlateFile, responseFileName, sendFileName;
import '../../tor_location.dart';
import '../../wallet_registry.dart' as reg;
import '../../history/export.dart' show historyCsv, historyDamaged, historyNewer, historyOtherWallet;
import '../../settings.dart' show HistoryExportSnapshot;
import '../../wallet_service.dart' as core;
import 'addresses.dart';
import 'api.dart';
import 'backup_reminder.dart';
import 'desk_store.dart';
import 'desk_update.dart' show deskAppVersion;
import 'features.dart';
import 'http_address.dart';
import 'invoice_scheduler.dart';
import 'invoices.dart';
import 'models.dart';
import 'phrase_check.dart' show phraseFingerprint;
import 'remember.dart';

/// Built-in public nodes offered in Settings › Node, the default first; status.btlabs.uk can add more.
final List<NodeServer> deskPublicNodes = [
  for (final n in builtInNodes) NodeServer(url: n.url, label: n.operator, operator: n.operator, health: ServiceHealth.checking),
];

/// Built-in public Epicbox servers, the default first; status.btlabs.uk can add more.
/// The Epicbox server 0.1.0 used when none was saved (the desktop's first relay then). An
/// install with a wallet keeps it (D-13); see [LepicDeskWallet._settleRelay].
const String oldDefaultEpicboxHost = 'epicbox.stackwallet.com';

final List<EpicboxServer> deskEpicboxes = [
  for (final r in builtInRelays) EpicboxServer(domain: r.relay.host, port: r.relay.port, operator: r.operator, health: ServiceHealth.checking),
];

/// A short sentence for a wallet error.
/// A second scan asked while one runs.
const String scanRunning = 'A scan is already running.';

/// Why a cancel was refused: LEPIC reports a payment in the pool or on chain as invalid input.
const String cancelRefusedText = 'Not cancelled: the node already has this payment.';

String deskErrorText(Object error) {
  if (error is DeskError) return error.message;
  if (error is! core.WalletError) return 'Something went wrong';
  final detail = error.message.split('\n').first.trim();
  return switch (error.kind) {
    core.WalletErrorKind.wrongPassword => 'Wrong password',
    core.WalletErrorKind.invalidMnemonic => 'Recovery phrase not valid',
    core.WalletErrorKind.walletAlreadyExists => 'A wallet exists already',
    core.WalletErrorKind.walletNotFound => 'No wallet found',
    core.WalletErrorKind.nodeUnreachable => 'Node not answering',
    core.WalletErrorKind.notEnoughFunds => 'Not enough funds',
    core.WalletErrorKind.invalidSlate => 'Not a transaction file for this wallet',
    core.WalletErrorKind.transportFailed => 'Epicbox server not reachable',
    core.WalletErrorKind.httpUrlInvalid => 'Not an http(s) address',
    core.WalletErrorKind.plainHttpNotAllowed => 'Plain HTTP not confirmed',
    core.WalletErrorKind.onionAddressInvalid => 'Not an onion address',
    core.WalletErrorKind.torNotRunning => 'Tor is not connected',
    core.WalletErrorKind.onionUnreachable => 'The recipient’s wallet is not reachable over Tor',
    core.WalletErrorKind.chainBusy || core.WalletErrorKind.walletBusy => 'Wallet busy. Try again in a moment.',
    core.WalletErrorKind.damagedDatabase => 'Wallet database damaged, rebuilding',
    core.WalletErrorKind.paymentExpired => detail.isEmpty ? 'Payment expired' : detail,
    core.WalletErrorKind.invoiceNotFound => 'Invoice not found',
    core.WalletErrorKind.amountMismatch => 'Amount differs from the invoice',
    core.WalletErrorKind.invoiceAlreadyPaid => 'Invoice already paid',
    core.WalletErrorKind.invoiceLockedAboveTip => 'Invoice locked until a later block',
    core.WalletErrorKind.invoiceChanged => 'Invoice changed',
    core.WalletErrorKind.invalidArgument => detail == core.sendUnbuildable || detail == core.nothingToConsolidate ? detail : detail.isEmpty ? 'Not accepted' : 'Not accepted: $detail',
    core.WalletErrorKind.io => detail.isEmpty ? 'Disk error' : 'Disk error: $detail',
    core.WalletErrorKind.other => detail.isEmpty ? 'Something went wrong' : detail,
  };
}

/// Why tor is down or the onion is not published, for the Tor line.
String torFailureText(core.TorFailure? f) => switch (f) {
  core.TorFailure.missing => 'Tor not included in this build',
  core.TorFailure.network => 'Can’t reach the Tor network',
  core.TorFailure.clock => 'The computer’s clock is wrong',
  core.TorFailure.publish || core.TorFailure.keys || core.TorFailure.listener => 'Onion address not published',
  core.TorFailure.start => 'Tor did not start',
  core.TorFailure.stopped || null => 'Tor stopped',
};

/// A call LEPIC ended at a lock ("… was cancelled"); its effect may still be stored.
bool lepicCancelled(Object error) => error is core.WalletError && error.kind == core.WalletErrorKind.other && error.message.endsWith('was cancelled');

DeskError _deskError(Object error) => DeskError(
  deskErrorText(error),
  wrongPassword: error is core.WalletError && error.kind == core.WalletErrorKind.wrongPassword,
  unbuildable: error is core.WalletError && error.kind == core.WalletErrorKind.invalidArgument && error.message == core.sendUnbuildable,
);

class LepicDeskWallet implements DeskWalletApi {
  LepicDeskWallet({
    required this._service,
    required this._walletDir,
    required this._secrets,
    required this._filesDir,
    this.relayDirectory,
    this.nodeDirectory,
    this.preset = mainnetPreset,
    this._settings = const DeskSettings(),
    BigInt? minimumConfirmations,
    this.nodePoll = const Duration(seconds: 30),
    this.nodeTimeout = const Duration(seconds: 15),
    this.torRetryAfter = const Duration(seconds: 60),
    this.closeWait = const Duration(seconds: 30),
    reg.WalletRegistry? registry,
    this._builtInNode,
    legacy.LegacyRoots Function()? legacyRoots,
    this._pickDirectory,
    this._listProcesses,
    this._torBundle,
    bool? torFeature,
    Future<Directory> Function()? rememberDir,
    DateTime Function()? now,
    this._seedFetch,
    Keyring? keyring,
    OnionDirectory? onions,
    this.invoicesEvery = const Duration(minutes: 2),
    this.paymentsEvery = const Duration(seconds: 60),
    this.invoiceFocus = true,
  }) : _keyring = keyring ?? btlabsKeyring,
        onions = onions ?? OnionDirectory(),
        _torFeature = torFeature ?? DeskFeatures.tor,
       _legacyRoots = legacyRoots ?? legacy.LegacyRoots.current,
       _minConfFallback = minimumConfirmations ?? BigInt.from(defaultMinimumConfirmations),
       _registryGiven = registry,
       _remember = RememberedPasswords(
         secrets: _secrets,
         dir: rememberDir ?? () async => Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}remember'),
         now: now,
       ) {
    statusSite.addListener(_statusSiteChanged);
  }

  /// Passwords remembered on this computer, per wallet (F6).
  final RememberedPasswords _remember;

  /// Whether this build offers Tor ([DeskFeatures.tor]); tests turn it on.
  final bool _torFeature;

  final core.WalletService _service;
  final WalletDirResolver _walletDir;
  final SecretStore _secrets;
  late final DeskStore _store = DeskStore(_secrets);
  final Future<Directory> Function() _filesDir;
  final NetworkPreset preset;

  /// Epicbox server health from status.btlabs.uk; null leaves it unknown.
  final RelayDirectory? relayDirectory;
  List<EpicboxServer>? _boxes;
  DateTime? _boxesAt;

  /// When [_importHistoryOnce] last read each wallet's old database (by meta key).
  final Map<String, DateTime> _historyTried = {};

  /// Public nodes from status.btlabs.uk; null keeps the built-in list.
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
  final Duration nodeTimeout;

  /// How long tor may connect before Retry is offered beside "Connecting to Tor…".
  final Duration torRetryAfter;

  /// How long closing the app waits for a payment under way before it locks anyway.
  final Duration closeWait;

  /// How often the invoice address is drained, and the payments address while an issued
  /// invoice waits and the listener is off ([InvoiceScheduler]).
  final Duration invoicesEvery;
  final Duration paymentsEvery;

  /// Drain the invoice address when the window gains focus (off in tests).
  final bool invoiceFocus;

  /// Makes the built-in node of a network (desktop builds with the bundled `epic`, D10); null
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
  String? _password;

  /// Every move of the wallet's node runs alone, in call order ([_nodeLock]): the user's picks,
  /// the built-in node on and off, the fallback (D-7).
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

  /// The node's last answer said it is not ready for transactions (O2): a sync that reached it
  /// does not turn that back into Online.
  bool _nodeNotReady = false;
  ServiceHealth _epicboxHealth = ServiceHealth.off;
  double? _syncProgress;
  DateTime? _lastUpdate;
  String? _notice;
  final Map<String, NodeServer> _checked = {};

  StreamSubscription<core.ListenerEvent>? _listener;

  /// The HTTP listener's events while it runs or starts; its health and, when down, why.
  StreamSubscription<core.HttpListenerEvent>? _http;
  ServiceHealth _httpHealth = ServiceHealth.off;
  String? _httpProblem;

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
  Timer? _torSlowTimer;

  /// A start that stalled on its first bootstrap is retried once by itself (a cold Tor cache
  /// can sit at one percent past LEPIC's stall limit); this is set once that retry ran.
  bool _torAutoRetried = false;

  /// The open wallet's onion, `<56 characters>.onion`.
  String? _onion;
  Timer? _poll;
  Future<void>? _syncing;
  bool _syncAgain = false;
  /// Why the last sync did not reach the node; null when it did.
  DeskError? _syncError;
  final _changes = StreamController<void>.broadcast();

  String get _chain => preset.chain.name;
  String get _nodeKey => 'app.node.$_chain';
  String get _relayKey => 'app.relay.$_chain';

  core.WalletSession get _open => _session ?? (throw const DeskError('The wallet is locked'));

  void _changed() {
    _followTor();
    if (!_changes.isClosed) _changes.add(null);
  }

  /// tor's SOCKS proxy for the app's own requests, from LEPIC's tor events (E-12); null while
  /// tor is not running.
  SocksProxy? _torSocks;

  void _takeSocks(int? port) {
    if (port != null) _torSocks = SocksProxy('127.0.0.1', port);
  }

  /// The app's own requests follow the Tor switch (tor_routes.dart, `TorNet.follow`).
  void _followTor() {
    final state = !_settings.tor
        ? TorState.off
        : switch (_torHealth) {
            ServiceHealth.down => TorState.failed,
            ServiceHealth.off => TorState.starting,
            ServiceHealth.checking when !_torCanSend => TorState.starting,
            _ => TorState.on,
          };
    TorNet.onions = _onionOf;
    TorNet.follow(state, proxy: _torSocks);
  }

  /// BT Labs' onion for [host]:[port] from the signed list in use, else the built-in table.
  OnionTarget? _onionOf(String host, int port) {
    final e = onions.onionFor(host, port);
    return e == null ? torBuiltInOnion(host, port) : (onion: e.onion, port: e.onionPort, tls: e.tls);
  }

  /// Settings › Privacy › Use status.btlabs.uk changed: what the site gave is dropped (off) or
  /// read again (on); the lists reload.
  void _statusSiteChanged() {
    _dirNodes = null;
    _dirNodesAt = null;
    _boxes = null;
    _boxesAt = null;
    _changed();
  }

  // ---- Config and saved wallet data.

  Future<String> _nodeUrl() async => await _secrets.read(_nodeKey) ?? preset.nodeUrl;

  Future<EpicboxRelay> _relay() async {
    await (_relaySettled ??= _settleRelay());
    final saved = await _secrets.read(_relayKey);
    return (saved == null ? null : EpicboxRelay.parse(saved)) ??
        EpicboxRelay(host: _settledHost ?? deskEpicboxes.first.domain);
  }

  Future<void>? _relaySettled;

  /// What [_settleRelay] chose this run, used when saving it failed.
  String? _settledHost;

  /// Once per run: an install that never saved its Epicbox server keeps the one 0.1.0 used
  /// ([oldDefaultEpicboxHost]) when it already holds a wallet, since the server is part of the
  /// wallet's address; only an install without a wallet starts on the new default (D-13). The
  /// choice is saved either way, so a wallet made later keeps it too.
  Future<void> _settleRelay() async {
    try {
      if (await _secrets.read(_relayKey) != null) return;
      final host = await _hadWallet() ? oldDefaultEpicboxHost : deskEpicboxes.first.domain;
      _settledHost = host;
      await _secrets.write(_relayKey, EpicboxRelay(host: host).label);
      logInfo('desk', 'epicbox server settled: $host');
    } on Object catch (e) {
      // Not saved: the next run tries again; this one uses what was chosen, if anything.
      logWarn('desk', 'epicbox server not settled: ${e.runtimeType}');
    }
  }

  /// Whether a wallet was made before this run: the first wallet's folder, or any entry in
  /// `wallets.json` (read directly: [registry] needs [_relay]). An unreadable list counts as one.
  Future<bool> _hadWallet() async {
    final first = await _walletDir(preset.chain);
    if (await _service.walletExists(config: preset.config(dataDir: first, nodeUrl: preset.nodeUrl))) return true;
    final root = _registryGiven?.root ?? Directory(first).parent.parent.path;
    final file = File('$root${Platform.pathSeparator}${reg.WalletRegistry.fileName}');
    if (!await file.exists()) return false;
    try {
      final json = jsonDecode(await file.readAsString());
      return json is! Map || json['wallets'] is! List || (json['wallets'] as List).isNotEmpty;
    } on Object {
      return true;
    }
  }

  /// The config of [entry]; null is the first wallet. The first wallet's folder is exactly
  /// what [WalletDirResolver] answers, as in 0.1.0, and its walletId null.
  /// An added wallet's folder is always `<support>/wallets/<id>/<chain>`, rebuilt from its id:
  /// a folder written into wallets.json by hand is never opened.
  Future<core.WalletConfig> _configOf(reg.WalletEntry? entry, {String? nodeUrl, EpicboxRelay? relay}) async => preset.config(
    dataDir: entry == null || entry.isLegacy ? await _walletDir(preset.chain) : await _addedDir(entry),
    nodeUrl: nodeUrl ?? await _nodeUrl(),
    relay: relay ?? await _relay(),
    walletId: entry?.walletId,
  );

  Future<String> _addedDir(reg.WalletEntry entry) async {
    final sep = Platform.pathSeparator;
    final wallets = Directory(await _walletDir(preset.chain)).parent.path;
    return '$wallets$sep${entry.id}$sep${entry.chain.name}';
  }

  /// The open wallet's config (the first wallet's while locked).
  Future<core.WalletConfig> _makeConfig({String? nodeUrl, EpicboxRelay? relay}) => _configOf(_openEntry, nodeUrl: nodeUrl, relay: relay);

  String _metaKey(String? walletId) => DeskStore.walletMetaKey(_chain, walletId);

  /// The saved data of the wallet with [walletId]; the open one by default.
  Future<Map<String, dynamic>> _meta([String? key]) async {
    final j = await _store.readJson(key ?? _metaKey(_openEntry?.walletId));
    return j is Map<String, dynamic> ? j : <String, dynamic>{};
  }

  Future<void> _setMeta(Map<String, Object?> changes, [String? key]) async {
    key ??= _metaKey(_openEntry?.walletId);
    await _store.writeJson(key, {...await _meta(key), ...changes});
  }

  String get _favouritesKey => DeskStore.favouritesKeyOf(_openEntry?.walletId);

  // ---- The wallet list.

  /// The desktop's wallet list, read once, with the wallet a 0.1.0 install made listed as the
  /// first one. The only way into the registry: Unlock, All wallets and the import all use it.
  Future<reg.WalletRegistry> registry() => _registry ??= _loadRegistry();

  Future<reg.WalletRegistry> _loadRegistry() async {
    try {
      final legacyDir = await _walletDir(preset.chain);
      final r = _registryGiven ?? reg.WalletRegistry(Directory(legacyDir).parent.parent.path);
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
    label: ((await _meta(_metaKey(null)))['name'] as String?) ?? 'Main wallet',
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
      (await _wallets()).where((e) => e.id == id).firstOrNull ?? (throw const DeskError('Wallet not in the list'));

  DeskError _listError(reg.WalletRegistryException e) => e is reg.WalletRegistryVersionException
      ? const DeskError('Update the app to change the list')
      : e is reg.WalletNotListedException
      ? const DeskError('Wallet not in the list')
      : DeskError(e.message.isEmpty ? 'Wallet list not changed' : '${e.message[0].toUpperCase()}${e.message.substring(1)}');

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
    return (await _meta(_metaKey(e.walletId)))['setupPending'] == true;
  }

  @override
  Future<void> setSetupPending(String id, bool pending) async {
    final e = await _entry(id);
    await _setMeta({'setupPending': pending}, _metaKey(e.walletId));
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
    if (entry == null || entry.chain != preset.chain) throw const DeskError('Wallet not in the list');
    final open = _session != null && _openEntry?.id == id;
    // Deleting asks for the wallet's password, so only the open wallet can be deleted.
    if (mode == WalletRemoval.delete && !open) throw const DeskError('Open the wallet to delete it');
    if (open) {
      if (mode == WalletRemoval.delete) {
        if (password == null || password.isEmpty) throw const DeskError('Enter the password');
        try {
          await _open.mnemonic(password: password);
        } on core.WalletError catch (e) {
          throw _deskError(e);
        }
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
          await r.delete(id, service: _service, config: config);
          await _remember.forget(id);
          await _store.delete(_metaKey(entry.walletId));
          await _store.delete(DeskStore.favouritesKeyOf(entry.walletId));
          if (entry.walletId != null) {
            await _store.delete(DeskStore.httpKeyOf(entry.walletId));
          }
          await _store.delete(DeskStore.torKeyOf(entry.walletId));
          await _store.delete(DeskStore.outputsKeyOf(entry.walletId));
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

  @override
  Future<List<WalletEntry>> findRemoved() async {
    final r = await registry();
    final first = await _configOf(null);
    return [
      if (r.byId('${reg.WalletRegistry.legacyPrefix}$_chain') == null && await _service.walletExists(config: first))
        WalletEntry(
          id: '${reg.WalletRegistry.legacyPrefix}$_chain',
          name: ((await _meta(_metaKey(null)))['name'] as String?) ?? 'Wallet 1',
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
      if (found == null) throw const DeskError('Wallet folder not found');
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
  Future<bool> checkPassword(String password) async {
    try {
      await _open.mnemonic(password: password);
      return true;
    } on core.WalletError catch (e) {
      if (e.kind == core.WalletErrorKind.wrongPassword) return false;
      throw _deskError(e);
    }
  }

  @override
  Future<void> forgetRemembered(String id) => _remember.forget(id);

  /// Opens the selected wallet. [remember]: keep the password, forget it, or (null, for the
  /// remembered password itself) leave it and its expiry as they are.
  Future<bool> _unlock(String password, {bool? remember}) async {
    await lock();
    final all = await _wallets();
    final entry = _pick(all, await _lastUsed());
    if (entry == null) throw const DeskError('No wallet found');
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
      if (e.kind != core.WalletErrorKind.damagedDatabase) throw _deskError(e);
      // LEPIC set the damaged database aside; opening again rebuilds it from the vault, and a
      // scan brings the funds back.
      logWarn('desk', 'wallet database damaged; rebuilding');
      _notice = 'Wallet database damaged, rebuilding';
      await _setMeta({'scanPending': true}, metaKey);
      try {
        session = await _service.open(config: config, password: password);
      } on core.WalletError catch (e2) {
        if (e2.kind == core.WalletErrorKind.wrongPassword) return false;
        throw DeskError('Wallet database damaged. ${deskErrorText(e2)}');
      }
    }
    _session = session;
    await _routeEpicbox(session);
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
    final torSwitch = await _store.torSwitch() ?? autostart.tor;
    _settings = _settings.copyWith(
      publicMode: http.publicMode,
      httpPort: http.port,
      httpAutostart: http.autostart,
      tor: false,
      epicboxAutostart: autostart.epicbox,
      torAutostart: _torFeature && torSwitch,
    );
    await _setMeta({'opened': DateTime.now().millisecondsSinceEpoch ~/ 1000});
    await _seedContacts();
    try {
      if (_registry != null) _openEntry = await (await _registry!).markOpened(entry.id);
    } on Object catch (e) {
      logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
    }
    return true;
  }

  /// After an unlock: the node poll and the first sync. The receiving methods start with
  /// [startAutostart], each as its Start with the wallet says.
  void _startOpenWallet() {
    _poll = Timer.periodic(nodePoll, (_) => unawaited(_checkTip()));
    unawaited(_checkTip());
    unawaited(sync());
    _torAutoRetried = false;
    _startInvoices();
  }

  @override
  Future<void> startAutostart() async {
    final session = _open;
    // Tor starts below: the first Epicbox connection waits for it, never going directly first.
    if (_torFeature && _settings.torAutostart && await _findTor() != null) await _expectTor(session);
    if (_settings.epicboxAutostart) {
      try {
        await setEpicboxListening(true);
      } on Object catch (e) {
        logWarn('desk', 'epicbox autostart: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    // The clearnet HTTP listener stays off while Tor is on (tor_routes.dart, torStops).
    if (DeskFeatures.httpDirect && _settings.httpAutostart && !(_torFeature && _settings.torAutostart)) {
      try {
        await setHttpListening(true);
      } on Object catch (e) {
        logWarn('desk', 'http autostart: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
      }
    }
    if (_torFeature && _settings.torAutostart) {
      _settings = _settings.copyWith(tor: true);
      _torAutoRetried = false;
      unawaited(_startTor());
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
    // A send, finalize or split under way finishes first ([busy]); none starts meanwhile.
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
    _poll?.cancel();
    _poll = null;
    _stopInvoices(forget: true);
    await _stopListener();
    await _stopHttp();
    await _stopTor();
    final session = _session;
    _session = null;
    _password = null;
    _onion = null;
    // The next unlock offers the wallet that was open.
    _selectedId ??= _openEntry?.id;
    _openEntry = null;
    _config = null;
    _summary = null;
    _entries = null;
    _syncProgress = null;
    _epicboxHealth = ServiceHealth.off;
    session?.dispose();
  }

  /// Moves to [nodeUrl] and [relay]: saved under the phone's keys once the wallet opens on
  /// them, the listener kept as it was. When it does not open, the wallet opens again on the
  /// old ones and the error says so; when even that fails, the wallet locks
  /// ([DeskError.locked]). Locked: only saved. Callers hold [_nodeLock]; [_switching] is set
  /// before the first await: new payments and scans wait for the switch, those running end first.
  Future<void> _switchTo({required String nodeUrl, required EpicboxRelay relay}) async {
    // The mark comes first: no payment or scan starts from now on (the switch is preferred),
    // so a steady stream of them cannot hold it off. Those under way end, then it runs.
    final switching = _switching = Completer<void>();
    try {
      while (_busy > 0) {
        await whenIdle();
      }
      await _reopenOn(nodeUrl: nodeUrl, relay: relay);
    } finally {
      _switching = null;
      switching.complete();
    }
  }

  Future<void> _reopenOn({required String nodeUrl, required EpicboxRelay relay}) async {
    Future<void> save() async {
      await _secrets.write(_nodeKey, nodeUrl);
      await _secrets.write(_relayKey, relay.label);
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
        throw DeskError('Wallet closed: ${deskErrorText(e2)}. Unlock again.', locked: true);
      }
      await _afterReopen(listening, http, tor);
      throw DeskError('Not changed: ${deskErrorText(e)}');
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
    unawaited(_checkTip());
    unawaited(sync());
  }

  // ---- First run.

  @override
  Future<List<String>> newPhrase({int words = 24}) =>
      throw UnsupportedError('the phrase comes from createWallet');

  void _checkPassword(String password) {
    if (password.length < minPasswordLength) {
      throw const DeskError('Use at least $minPasswordLength characters');
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
  /// [fingerprintOf]: the phrase fingerprint of the made wallet, kept in its list entry
  /// ([reg.WalletEntry.phraseFingerprint]) so a later restore of the same phrase finds it.
  Future<T> _make<T>(
    String name,
    Map<String, Object?> meta,
    Future<T> Function(core.WalletConfig config) create, {
    bool ownEntry = false,
    String Function(T result)? fingerprintOf,
  }) async {
    final entry = await _newWallet(name, ownEntry: ownEntry);
    final config = await _configOf(entry);
    final T result;
    try {
      result = await create(config);
    } on Object {
      if (entry != null) await _unlist(entry);
      rethrow;
    }
    final label = name.trim().isEmpty ? null : name.trim();
    await _store.writeJson(_metaKey(entry?.walletId), {'name': label, 'created': DateTime.now().millisecondsSinceEpoch ~/ 1000, ...meta});
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
    await writeWalletTxt(config.dataDir, label: listed?.label ?? label ?? 'Main wallet', network: _chain, created: DateTime.now());
    if (listed != null) {
      try {
        final r = await registry();
        if (fingerprintOf != null) await r.setPhraseFingerprint(listed.id, fingerprintOf(result));
        await r.setLastUsed(listed.id);
      } on Object catch (e) {
        logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
      }
    }
    return result;
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
      }, fingerprintOf: (words) => phraseFingerprint(words.join(' ')));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  bool checkPhrase(List<String> words) =>
      _service.validateMnemonic(phrase: words.map((w) => w.trim().toLowerCase()).join(' '));

  String _mnemonicOf(List<String> phrase) => phrase.map((w) => w.trim().toLowerCase()).join(' ');

  /// The listed wallet of this network whose kept fingerprint is [mnemonic]'s (O1). Wallets
  /// made before the app kept one (no [reg.WalletEntry.phraseFingerprint]) are never matched:
  /// the wallet core has no way to derive their address from a phrase without making a store.
  Future<WalletEntry?> _sameWallet(String mnemonic) async {
    final fp = phraseFingerprint(mnemonic);
    final same = (await _wallets()).where((e) => e.phraseFingerprint == fp).firstOrNull;
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
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase}) async {
    _checkPassword(password);
    final mnemonic = _mnemonicOf(phrase);
    if (!_service.validateMnemonic(phrase: mnemonic)) throw const DeskError('Recovery phrase not valid');
    final same = await _sameWallet(mnemonic);
    if (same != null) throw DeskError('This wallet is already here: ${same.name}', sameWallet: same);
    try {
      // The scan runs after unlock, in the background, with its progress in the status.
      await _make(name, const {'scanPending': true}, (config) async {
        final session = await _service.create(config: config, mnemonic: mnemonic, password: password);
        session.dispose();
      }, fingerprintOf: (_) => phraseFingerprint(mnemonic));
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  // ---- Import (B01–B32 as LEPIC takes them: wallet.seed only, history from a scan).

  static const _testNetText = 'Test network wallet. Only mainnet wallets can be imported.';

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
      blocked: w.refusal?.text ?? (w.network == legacy.LegacyNetwork.main ? null : _testNetText),
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
  Future<String> _appRoot() async => Directory(await _walletDir(preset.chain)).parent.parent.path;

  Future<List<OldWallet>> _describeOld(List<legacy.LegacyWallet> found) async {
    final root = await _appRoot();
    final own = [
      for (final w in found)
        if (!await legacy.isWithin(w.path, root)) w,
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
      message: found.wallets.isNotEmpty && wallets.isEmpty ? 'This wallet is in the app already.' : found.message,
    );
  }

  legacy.LegacyWallet _oldWallet(String id) => _old[id] ?? (throw const DeskError('Wallet not found. Search again.'));

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
    if (refusal != null) throw DeskError(refusal.text);
    if (w.network != legacy.LegacyNetwork.main) throw const DeskError(_testNetText);
    if (oldPassword.isEmpty) throw const DeskError('Enter the old password');
    final next = newPassword ?? oldPassword;
    if (next.length < minPasswordLength) {
      throw DeskError(
        newPassword == null ? 'The old password is short. Choose a new one of at least $minPasswordLength characters.' : 'Use at least $minPasswordLength characters',
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
      throw const DeskError('The wallet.seed file could not be read');
    }
    if (bytes.isEmpty || bytes.length > legacy.maxSeedBytes) throw const DeskError(legacy.seedTooLargeText);
    final String seed;
    try {
      seed = utf8.decode(bytes);
    } on FormatException {
      throw const DeskError('Not a wallet.seed file');
    }
    final name = _importName(w.displayLabel);
    final fingerprint = sha256.convert(bytes).toString();
    final held = (await _inAppSeeds())[fingerprint];
    if (held != null) throw DeskError('Already in the app as $held');
    // What the older app kept beside the wallet: contacts, node, Epicbox server. Read only.
    final profile = await gui.readGuiImport(_legacyRoots(), w);
    final global = await gui.readGuiGlobal(_legacyRoots());
    core.LegacyHistoryImport? history;
    var contactsAdded = 0;
    reg.WalletEntry? made;
    try {
      // The seed makes the wallet; the old log brings its history, which the scan at the first
      // unlock then reconciles with the chain.
      await _make(name, {'scanPending': true, 'seedFingerprint': fingerprint, 'importedFrom': w.path}, (config) async {
        final session = await _service.importWalletSeed(config: config, seedFile: seed, seedPassword: oldPassword, password: next);
        try {
          history = await _importHistory(session, w.path);
          contactsAdded = await _importContacts(session, profile.contacts);
        } finally {
          session.dispose();
        }
      }, ownEntry: true);
      made = (await registry()).byId(_selectedId ?? '');
    } on core.WalletError catch (e) {
      if (e.kind == core.WalletErrorKind.wrongPassword) throw const DeskError('Wrong old password', wrongPassword: true);
      throw _deskError(e);
    }
    if (made == null) throw const DeskError('Wallet list not saved');
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
    final relay = await _relay();
    final box = profile.epicboxDomain;
    return ImportedWallet(
      id: made.id,
      name: made.label,
      proof: [
        const ImportProof('Seed read'),
        const ImportProof('Wallet created'),
        _historyProof(done),
        if (contactsAdded > 0) ImportProof(contactsAdded == 1 ? '1 contact added' : '$contactsAdded contacts added'),
        for (final n in nodes) ImportProof('Node ${n.label} added to the node list'),
        if (box != null && box != relay.host) ImportProof('The older app used the Epicbox server $box; this app uses ${relay.host}'),
        unchanged ? const ImportProof('Old folder unchanged') : const ImportProof('Old folder changed by another program', ok: false),
      ],
    );
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
    core.LegacyHistoryStatus.imported => ImportProof(
      r!.transactions == 1 ? 'History: 1 transaction' : 'History: ${r.transactions} transactions',
    ),
    core.LegacyHistoryStatus.alreadyImported => const ImportProof('History already imported'),
    core.LegacyHistoryStatus.noHistory => const ImportProof('No history in the old folder; the scan restores the balance'),
    core.LegacyHistoryStatus.oldFormat =>
      const ImportProof('History of Epic Wallet 5.3 or older is not readable; the scan restores the balance', ok: false),
    core.LegacyHistoryStatus.sourceBusy =>
      const ImportProof('History not imported: the older wallet is running. It is imported at the next unlock', ok: false),
    core.LegacyHistoryStatus.otherWallet ||
    core.LegacyHistoryStatus.otherHistory =>
      const ImportProof('History not imported: it belongs to another wallet', ok: false),
    core.LegacyHistoryStatus.unreadable ||
    core.LegacyHistoryStatus.tooLarge ||
    null =>
      const ImportProof('History not imported: the old database could not be read; the scan restores the balance', ok: false),
  };

  /// Adds the older app's contacts of this wallet that the address book lacks. Returns how many.
  Future<int> _importContacts(core.WalletSession session, List<gui.LegacyContact> contacts) async {
    if (contacts.isEmpty) return 0;
    try {
      final have = {for (final c in await session.contacts()) c.address.toLowerCase()};
      var added = 0;
      for (final c in contacts) {
        final raw = (c.epicboxAddress ?? c.httpAddress)?.trim();
        final address = raw == null ? null : parseAddress(raw, this).canonical;
        final name = cleanOperator(c.name) ?? '';
        if (address == null || name.isEmpty || !_contactAddressOk(address) || !have.add(address.toLowerCase())) continue;
        final extra = c.epicboxAddress != null && c.httpAddress != null ? 'HTTP: ${c.httpAddress}' : null;
        final note = [c.note?.trim() ?? '', extra ?? ''].where((t) => t.isNotEmpty).join('\n');
        await session.saveContact(contact: core.Contact(id: '', name: name, address: address, note: note.isEmpty ? null : note));
        added++;
      }
      return added;
    } on core.WalletError catch (e) {
      logWarn('desk', 'import: contacts not added: ${e.kind.name}');
      return 0;
    }
  }

  /// An address the contact form would take: epicbox, http(s) or, with Tor, an onion.
  bool _contactAddressOk(String a) {
    final p = parseAddress(a, this);
    return p.complete && (p.kind != AddressKind.tor || _torFeature);
  }

  /// Adds the old wallet's node and the older app's own nodes to the node list without switching
  /// to them: the node is app-wide here and would move every wallet. Returns those added.
  Future<List<NodeServer>> _importNodes(String? walletNode, List<gui.LegacyNode> myNodes) async {
    final listed = {for (final n in await _listed()) n.url, preset.nodeUrl};
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

  /// A list name of at most 32 characters.
  static String _importName(String label) {
    final t = label.trim();
    return t.length <= 32 ? t : t.substring(0, 32).trim();
  }

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
        await _store.delete(_metaKey(entry.walletId));
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
    final key = _metaKey(_openEntry?.walletId);
    _syncProgress = 0;
    _syncError = null;
    _changed();
    try {
      // The scan due since a restore or a rebuilt database; not while Recheck balance scans.
      if (!_rescanning && (await _meta(key))['scanPending'] == true) {
        var finished = false;
        try {
          await for (final p in session.scan()) {
            if (_session != session) return;
            finished = finished || p.finished;
            if (p.percent != null) _syncProgress = p.percent! / 200;
            _changed();
          }
        } on core.WalletError catch (e) {
          if (e.kind != core.WalletErrorKind.walletBusy) rethrow;
          logInfo('desk', 'due scan skipped: a scan is already running');
        }
        // A scan stopped before its end stays due.
        if (finished) {
          await _setMeta({'scanPending': false}, key);
          _notice = null;
        }
      }
      await for (final p in session.refresh(minimumConfirmations: _minConf)) {
        if (_session != session) return;
        _syncProgress = 0.5 + p.percent / 200;
        final summary = p.summary;
        if (summary != null) {
          _summary = summary;
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
      await _importHistoryOnce(session, key);
      _entries = await session.transactions(refresh: false);
      _lastUpdate = DateTime.now();
      _syncError = _nodeHealth == ServiceHealth.down ? const DeskError('The node did not answer') : null;
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
    if (_session == null) throw const DeskError('The wallet is locked');
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
    _historyTried[key] = DateTime.now();
    final r = await _importHistory(session, from);
    if (r == null || r.status == core.LegacyHistoryStatus.sourceBusy) return;
    await _setMeta({'historyImport': r.status.name}, key);
  }

  Future<void> _checkTip() async {
    final config = _config;
    if (config == null) return;
    try {
      final tip = await _service.nodeTip(config: config).timeout(nodeTimeout);
      final h = tip.height.toInt();
      final grew = h > _tip;
      _tip = h;
      // The local node answers from its first second, at height 0 while it downloads the
      // chain: that is "Syncing" (slow), never "Online · 0" (O2). Its sync progress past
      // height 0 (headers, then blocks, against the network's tip) is wave 6.
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
      if (grew && _summary != null) unawaited(sync());
    } on Object catch (e) {
      if (_nodeHealth != ServiceHealth.down) {
        logWarn('desk', 'node check failed: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
        _nodeHealth = ServiceHealth.down;
        _changed();
      }
    }
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
      name: _openEntry?.label ?? (meta['name'] as String?) ?? 'Main wallet',
      network: _chain,
      folder: folder,
      created: _time(meta['created']) ?? DateTime.now(),
      appFolder: Directory(await _walletDir(preset.chain)).parent.parent.path,
    );
  }

  @override
  Future<Balance> balance() async {
    final s = _summary ?? await _open.summary(refresh: false, minimumConfirmations: _minConf);
    _summary ??= s;
    return Balance(
      spendable: s.spendable.toInt(),
      awaitingConfirmation: s.awaitingConfirmation.toInt(),
      locked: s.locked.toInt(),
      // An unpaid issued invoice is in no figure: LEPIC files its output apart (P-1, W-25).
      awaitingFinalization: s.awaitingFinalization.toInt(),
      immature: s.immature.toInt(),
      minConfirmations: _minConf.toInt(),
      reportedTotal: s.total.toInt(),
    );
  }

  @override
  Future<List<Tx>> transactions() async {
    final entries = _entries ?? await _open.transactions(refresh: false);
    _entries = entries;
    final contacts = await _open.contacts();
    final names = {for (final c in contacts) c.address: c.name};
    return [for (final (i, e) in entries.indexed) deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1 - i, contactName: names[e.counterparty])];
  }

  /// Every output, spent ones included, from the wallet's database (as of the last refresh).
  @override
  Future<List<Output>> outputs() async {
    try {
      final list = await _open.outputs();
      return [for (final o in list) deskOutput(o, minConf: _minConf.toInt())];
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
          address: c.address,
          note: c.note,
          favourite: favourites.contains(c.id),
          lastUsed: lastUsed(c.address),
          invoiceAddress: c.invoiceAddress,
        ),
    ];
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
    final box = (_boxes ?? deskEpicboxes).where((b) => b.domain == relay.host).firstOrNull ?? EpicboxServer(domain: relay.host, port: relay.port);
    return ServiceStatus(
      node: node,
      nodeHealth: _nodeHealth,
      nodeHeight: _tip,
      epicbox: box,
      epicboxHealth: _epicboxHealth,
      httpListener: _httpHealth,
      httpProblem: _httpHealth == ServiceHealth.down ? _httpProblem : null,
      tor: _torHealth,
      torProgress: _torHealth == ServiceHealth.checking && !_torCanSend ? _torProgress : null,
      torProblem: _torHealth == ServiceHealth.down || _torHealth == ServiceHealth.slow ? _torProblem : null,
      torCanSend: _torCanSend,
      torIncluded: await _findTor() != null,
      epicboxViaTor: _epicboxOverTor && _settings.tor && await _findTor() != null,
      torSlowStart: _torHealth == ServiceHealth.checking &&
          !_torCanSend &&
          _torStartedAt != null &&
          DateTime.now().difference(_torStartedAt!) >= torRetryAfter,
      syncProgress: _syncProgress,
      lastUpdate: _lastUpdate,
      notice: _notice,
    );
  }

  @override
  Future<List<NodeServer>> nodes() async {
    final all = await _listed(readDirectory: true);
    // Each node is checked once in the background; the lists show it when the check is in.
    for (final n in all) {
      if (_checked.containsKey(n.url) || !_checking.add(n.url)) continue;
      unawaited(checkNode(n.url).whenComplete(() {
        _checking.remove(n.url);
        _changed();
      }));
    }
    return all;
  }

  /// Public nodes and My nodes, with the last check of each. Only the node list itself
  /// ([readDirectory]) reads status.btlabs.uk; the status line uses what is known.
  Future<List<NodeServer>> _listed({bool readDirectory = false}) async {
    final own = await _store.readJson(DeskStore.nodesKey);
    NodeServer withCheck(NodeServer n) {
      final c = _checked[n.url];
      return c == null ? n : NodeServer(url: n.url, label: n.label, operator: n.operator, health: c.health, latencyMs: c.latencyMs, height: c.height, version: c.version, own: n.own);
    }

    return [
      for (final n in _publicNodes(read: readDirectory)) withCheck(n),
      if (own is List)
        for (final o in own.whereType<Map<String, dynamic>>())
          if (o['url'] is String) withCheck(NodeServer(url: o['url'] as String, label: (o['label'] as String?) ?? '', own: true, health: ServiceHealth.checking)),
    ];
  }

  /// The built-in public nodes, then any only status.btlabs.uk lists. The directory is read in
  /// the background; the lists update when it answers.
  List<NodeServer> _publicNodes({bool read = true}) {
    if (read) _readNodeDirectory();
    return [
      for (final n in mergePublicNodes(_dirNodes))
        NodeServer(url: n.url, label: n.operator, operator: n.operator, health: ServiceHealth.checking),
    ];
  }

  void _readNodeDirectory() {
    final dir = nodeDirectory;
    final chain = preset.statusChain;
    final at = _dirNodesAt;
    if (dir == null || chain == null || _dirNodesLoading) return;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) return;
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
    if (dir == null || preset.statusChain == null) return deskEpicboxes;
    if (_boxes != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) return _boxes!;
    try {
      final listed = await dir.relays(preset.statusChain!).timeout(nodeTimeout);
      if (!statusSite.on) return deskEpicboxes;
      _boxes = [
        for (final r in mergePublicRelays(listed))
          EpicboxServer(
            domain: r.relay.host,
            port: r.relay.port,
            operator: r.operator,
            health: switch (r.status?.healthy) { true => ServiceHealth.ok, false => ServiceHealth.down, null => ServiceHealth.checking },
            latencyMs: r.status?.latencyMs,
          ),
      ];
      _boxesAt = DateTime.now();
      return _boxes!;
    } on Object catch (e) {
      logWarn('desk', 'epicbox status: ${e.runtimeType}');
      return _boxes ?? deskEpicboxes;
    }
  }

  @override
  Future<DeskSettings> settings() async => _settings;

  @override
  Future<String> epicboxAddress() => _open.epicboxAddress();

  @override
  Future<String> httpAddress() async {
    final port = _httpPort;
    if (_httpHealth != ServiceHealth.ok || port == null) return '';
    if (_httpExposure != core.HttpExposure.internet) return 'http://127.0.0.1:$port';
    final lan = await lanAddress();
    return lan == null ? '' : 'http://$lan:$port';
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
    final t = to.trim();
    if (!RegExp(r'^es[0-9A-Za-z]{38,58}(@[\w.-]+(:\d+)?)?$').hasMatch(t)) return false;
    // LEPIC checks the key's checksum; it wants the server, any server will do for that.
    return _service.validateEpicboxAddress(address: t.contains('@') ? t : '$t@epicbox.stackwallet.com');
  }

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
      if (stored != null) throw DeskError('Not posted', notPostedTx: stored);
      throw _deskError(e);
    }
  });

  @override
  Future<void> repostTx(int id) => _running(() async {
    if (!await _repost(_open, id)) throw const DeskError('Node not answering');
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
    if (_locking) throw const DeskError('The wallet is locking', locked: true);
    while (_switching != null) {
      await _switching!.future;
      if (_locking) throw const DeskError('The wallet is locking', locked: true);
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
    // An onion pasted under Direct goes over Tor.
    final method = _torFeature && r.method == TxMethod.http && isOnionAddress(r.to ?? '') ? TxMethod.tor : r.method;
    // The rows before a direct send, to tell a send LEPIC stored from one it refused.
    Set<int?>? before;
    try {
      final message = r.message?.trim().isEmpty ?? true ? null : r.message!.trim();
      switch (method) {
        case TxMethod.epicbox:
          final to = (r.to ?? '').trim();
          if (!_service.validateEpicboxAddress(address: to)) return const SendFailed('Not an Epicbox address');
          final e = await session.sendEpicbox(amount: BigInt.from(amount), minimumConfirmations: _minConf, address: to, message: message, options: r.options);
          await _reload();
          return SendDone(_txFor(e));
        case TxMethod.file:
          final slate = await session.createSendSlate(amount: BigInt.from(amount), minimumConfirmations: _minConf, message: message, options: r.options);
          final File file;
          try {
            final dir = await _filesDir();
            await dir.create(recursive: true);
            file = File('${dir.path}${Platform.pathSeparator}${sendFileName(slate.slateId)}');
            await file.writeAsString(slate.json, flush: true);
          } on FileSystemException catch (e) {
            // The payment exists in the wallet; only its file is missing.
            logWarn('desk', 'slate file not written: ${e.osError?.errorCode ?? '?'}');
            await _reload();
            return const SendFailed('File not saved. The payment waits in Activity; cancel it there to unlock the funds.', inActivity: true);
          }
          await _reload();
          final tx = _txs().where((t) => t.slateId == slate.slateId).firstOrNull ??
              Tx(id: -1, slateId: slate.slateId, direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: amount, fee: 0, created: DateTime.now(), counterparty: file.path);
          return SendFileReady(tx, file.path);
        case TxMethod.http:
          final to = (r.to ?? '').trim();
          final problem = httpAddressProblem(to);
          if (problem != null) return SendFailed(problem);
          // Send asks before plain HTTP leaves this computer; LEPIC refuses it otherwise.
          if (plainHttpNeedsConsent(to) && !r.allowPlainHttp) return const SendFailed('Plain HTTP not confirmed');
          before = {for (final e in await session.transactions(refresh: false)) e.id};
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
          if (!isOnionAddress(to)) return const SendFailed('Not an onion address');
          if (!_settings.tor) return const SendFailed('Tor is off. Turn on Tor to send to an onion address.');
          if (!_torCanSend) return const SendFailed('Tor is still connecting. Try again in a moment.');
          before = {for (final e in await session.transactions(refresh: false)) e.id};
          final sent = await session.sendTor(amount: BigInt.from(amount), minimumConfirmations: _minConf, onion: to, message: message, options: r.options);
          return await _directDone(session, sent, method, amount, to);
      }
    } on core.WalletError catch (e) {
      await _reload();
      // LEPIC stores an HTTP send and locks its inputs before it delivers: whatever fails after
      // that leaves the payment in Activity.
      final seen = before;
      var stored = false;
      if (seen != null) {
        try {
          stored = (await session.transactions(refresh: false)).any((t) => !seen.contains(t.id) && t.kind == core.TxKind.sent);
        } on core.WalletError {
          // Unknown: say what is safe, that it may wait in Activity.
          stored = true;
        }
      }
      const waits = 'The payment waits in Activity; cancel it there to unlock the funds.';
      if (e.kind == core.WalletErrorKind.transportFailed) {
        if (method == TxMethod.http || method == TxMethod.tor) {
          return stored
              ? const SendFailed('The recipient’s wallet did not answer or refused. $waits', inActivity: true)
              : const SendFailed('The recipient’s wallet did not answer or refused.');
        }
        return const SendFailed('Not delivered. $waits', inActivity: true);
      }
      // Ended by a lock (the app's own lock waits; the wallet can still close under it): the
      // send may have been stored as sent, so the next unlock's Activity tells.
      if (lepicCancelled(e)) return const SendFailed('Interrupted by the lock. It may have gone out: check Activity after unlocking.', inActivity: true);
      if (stored) return SendFailed('${deskErrorText(e).replaceFirst(RegExp(r'\.$'), '')}. $waits', inActivity: true);
      return SendFailed(deskErrorText(e));
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
        return const SendFailed('Signed by both wallets, but the node refused it. Cancel it in Activity to unlock the funds.', inActivity: true);
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
      throw const DeskError('File not readable');
    } on FormatException {
      throw const DeskError('Not a transaction file');
    }
  }

  /// Signs the slate in [fileName] (a path) and writes the answer beside it, as
  /// `<name>.response` (epic-wallet's `receive -i`); in the app's files folder when that folder
  /// cannot be written.
  @override
  Future<ReceivedFile> receiveFile(String fileName) => _running(() => _receiveFile(fileName));

  Future<ReceivedFile> _receiveFile(String fileName) async {
    final json = await _readSlate(fileName);
    try {
      final answer = await _open.receiveSlate(slateJson: json);
      final response = await _writeResponse(fileName, answer.json);
      await _reload();
      final tx = _txs().where((t) => t.slateId == answer.slateId).firstOrNull ??
          Tx(id: -1, slateId: answer.slateId, direction: TxDirection.received, state: TxState.posted, method: TxMethod.file, amount: 0, fee: 0, created: DateTime.now(), counterparty: fileName);
      return ReceivedFile(tx, response);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  /// Writes the response beside [fileName], or in the app's files folder when that fails.
  /// Returns the path written.
  Future<String> _writeResponse(String fileName, String json) async {
    final beside = responseFileName(fileName);
    try {
      await File(beside).writeAsString(json, flush: true);
      return beside;
    } on FileSystemException catch (e) {
      logWarn('desk', 'response not written beside the slate: ${e.osError?.errorCode ?? '?'}');
    }
    try {
      final dir = await _filesDir();
      await dir.create(recursive: true);
      final path = '${dir.path}${Platform.pathSeparator}${File(beside).uri.pathSegments.last}';
      await File(path).writeAsString(json, flush: true);
      return path;
    } on FileSystemException {
      throw const DeskError('Response file not saved');
    }
  }

  @override
  Future<Tx> finalizeFile(String fileName) => _running(() async {
    final json = await _readSlate(fileName);
    try {
      final e = await _open.finalizeAndPost(slateJson: json);
      await _reload();
      return _txFor(e);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  });

  @override
  Future<void> cancelTx(int id) => _running(() async {
    if (id < 0) throw const DeskError('This payment cannot be cancelled');
    try {
      await _open.cancelTransaction(txId: id);
    } on core.WalletError catch (e) {
      // The core asks the node first and refuses a payment it already has (in its pool or a block).
      if (e.kind == core.WalletErrorKind.invalidArgument) throw const DeskError(cancelRefusedText);
      throw _deskError(e);
    }
    await _reload();
  });

  @override
  Future<String> exportProof(int id) => throw UnsupportedError('payment proofs (DeskFeatures.paymentProofs)');

  @override
  Future<String> saveContact(Contact contact) async {
    try {
      final stored = await _open.saveContact(contact: core.Contact(id: contact.id, name: contact.name, address: contact.address, note: contact.note, invoiceAddress: contact.invoiceAddress));
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

  // ---- Seed contacts (F31, spec 9).

  /// Reads the website's list ([fetchSeeds] in the app); null reads nothing (tests).
  final Future<String?> Function(Uri url)? _seedFetch;

  /// The keys that may sign btlabs.json (the test keyring in tests).
  final Keyring _keyring;

  /// BT Labs' onion mapping: built in, replaced by a verified btlabs.json that lists onions.
  final OnionDirectory onions;

  /// The website's list, read once per app start (or from the 7-day cache); null until then.
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
            await session.saveContact(contact: core.Contact(id: c.id, name: s.name, address: s.address, note: s.note, invoiceAddress: c.invoiceAddress));
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

  /// The last accepted file's seed contacts, re-checked (signer still trusted, signature and
  /// digest as stored); null when there is none or it no longer checks out.
  Future<List<SeedContact>?> _cachedWebSeeds() async {
    if (_webSeeds != null) return _webSeeds;
    final j = await _store.readJson(_btlabsCacheKey);
    if (j is! Map || j['envelope'] is! String) return null;
    final state = ManifestState.fromJson(j['state']);
    if (state == null) return null;
    final file = await loadCachedBtlabsPublic(j['envelope'] as String, keyring: _keyring, state: state);
    if (file != null) {
      onions.adopt(file);
      await _applyOnions(_session);
    }
    return file == null ? null : seedContactsFrom(file, validAddress: isEpicboxAddress);
  }

  /// Reads btlabs.json unless the last good read is under 7 days old (or the last try under a
  /// day); applies it to the open wallet when it verifies and is newer than what the app has.
  /// Anything else changes nothing.
  Future<void> _refreshWebSeeds() async {
    try {
      final raw = await _store.readJson(_btlabsCacheKey);
      final j = raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
      bool fresh(Object? ms, Duration d) {
        if (ms is! int) return false;
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
        return !age.isNegative && age < d; // a clock set back counts as stale
      }

      if (fresh(j['at'], const Duration(days: 7)) || fresh(j['tried'], const Duration(days: 1))) return;
      // One refresher per app run (_seedFetchStarted), so this read-modify-write cannot race.
      await _store.writeJson(_btlabsCacheKey, {...j, 'tried': DateTime.now().millisecondsSinceEpoch});
      final body = await _seedFetch!(Uri.parse(btlabsPublicUrl));
      if (body == null) return;
      final stored = ManifestState.fromJson(j['state']);
      final r = await verifyBtlabsPublic(body, keyring: _keyring, state: stored, now: DateTime.now().toUtc());
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
    // Tor is the open wallet's, changed only through setTor.
    _settings = settings.copyWith(tor: old.tor);
    final moved = settings.httpPort != old.httpPort || settings.publicMode != old.publicMode;
    if (_session != null && (moved || settings.httpAutostart != old.httpAutostart)) {
      await _store.saveHttpPrefs(_openEntry?.walletId, HttpPrefs(publicMode: settings.publicMode, port: settings.httpPort, autostart: settings.httpAutostart));
    }
    if (_session != null && (settings.epicboxAutostart != old.epicboxAutostart || settings.torAutostart != old.torAutostart)) {
      await _store.saveAutostart(_openEntry?.walletId, AutostartPrefs(epicbox: settings.epicboxAutostart, tor: settings.torAutostart));
    }
    if (settings.torAutostart != old.torAutostart) await _store.saveTorSwitch(settings.torAutostart);
    if (moved && _session != null && (_http != null || _httpHealth == ServiceHealth.down)) {
      await _stopHttp();
      if (settings.directHttp) await setHttpListening(true);
    }
  }

  @override
  Future<void> useNode(String url) async {
    await _stopScanForUser();
    await _useNode(url);
  }

  Future<void> _useNode(String url) => _nodeLock(() async {
    logInfo('desk', 'node ${Uri.tryParse(url)?.host ?? '?'}');
    await _switchTo(nodeUrl: url, relay: await _relay());
    if (await _builtInOn()) {
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'false');
      await _node?.stop();
    }
  });

  String get _beforeBuiltInKey => 'app.node.$_chain.beforeBuiltIn';

  Future<bool> _builtInOn() async =>
      _builtInNode != null && await _secrets.read(builtInNodeSettingKey(preset.chain)) == 'true';

  Future<BuiltInNode> _theNode() async {
    final make = _builtInNode;
    if (make == null) throw const DeskError('No local node in this build');
    final node = _node ??= await make(preset.chain);
    // The user's node settings (data folder, peers) apply to every start, also at launch.
    node.options = await NodeSettings(_secrets, preset.chain).toOptions();
    return node;
  }

  @override
  Future<void> useBuiltInNode(bool on) async {
    await _stopScanForUser();
    // The setting and the saved node change only once the wallet runs on the new node, so a
    // failed start or move leaves both as they were.
    if (on) {
      // A fallback decision while it starts is applied once the setting is on (D-7).
      final seq = _fallbackSeq;
      final node = await _theNode();
      try {
        await node.start();
      } on NodeStartException catch (e) {
        throw DeskError(e.message);
      }
      await _nodeLock(() async {
        // A stop that came in while it was starting wins.
        if (!node.wantsRunning) throw const DeskError('Local node stopped');
        final current = await _nodeUrl();
        // While it syncs, the public node the user agreed to (D-7).
        final target = await nodeWhileSyncing?.call() ?? node.url;
        if (current != target) {
          try {
            await _switchTo(nodeUrl: target, relay: await _relay());
          } on Object {
            if (!await _builtInOn()) await node.stop();
            rethrow;
          }
          // A lock while reopening returns without moving; a stop while moving undoes it.
          if (await _nodeUrl() != target) throw const DeskError('Not changed: the wallet was locked');
          if (!node.wantsRunning) {
            await _switchTo(nodeUrl: current, relay: await _relay());
            throw const DeskError('Local node stopped');
          }
          await _secrets.write(_beforeBuiltInKey, current);
        }
        await _secrets.write(builtInNodeSettingKey(preset.chain), 'true');
        logInfo('desk', 'built-in node on');
      });
      // The status reads "Syncing" from now on while the node is at height 0 (O2).
      unawaited(_checkTip());
      if (_fallbackSeq != seq) unawaited(_applyFallback(_fallbackSeq));
      return;
    }
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

  /// The public node to use until the local node is synced (D-7), or null for the local node.
  /// Set by the node layer (main_desktop.dart).
  Future<String?> Function()? nodeWhileSyncing;

  /// D-7: the fallback decision changed. With the local node in use, the wallet moves to the
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

  /// At launch: starts the built-in node again when it was left on. A failure is logged and
  /// shown as a notice; the wallet then reports its node as not responding.
  Future<void> resumeBuiltInNode() async {
    if (!await _builtInOn()) return;
    // "Start with the app" off: the user starts it from Settings › Node.
    if (!await NodeSettings(_secrets, preset.chain).startWithApp()) return;
    try {
      await (await _theNode()).start();
    } on Object catch (e) {
      logWarn('desk', 'built-in node did not start: ${e is NodeStartException ? e.failure.name : e.runtimeType}');
      _notice = 'Local node not started: ${e is NodeStartException ? e.message : 'unknown error'}';
      _changed();
    }
  }

  @override
  Future<NodeServer> checkNode(String url) async {
    final known = (await _listed()).where((n) => n.url == url).firstOrNull;
    final base = known ?? NodeServer(url: url, label: Uri.tryParse(url)?.host ?? url, own: true);
    final watch = Stopwatch()..start();
    NodeServer r;
    try {
      final tip = await _service.nodeTip(config: await _makeConfig(nodeUrl: url)).timeout(nodeTimeout);
      r = NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.ok, latencyMs: watch.elapsedMilliseconds, height: tip.height.toInt(), version: tip.nodeVersion, own: base.own);
    } on Object {
      r = NodeServer(url: url, label: base.label, operator: base.operator, health: ServiceHealth.down, own: base.own);
    }
    _checked[url] = r;
    return r;
  }

  @override
  Future<void> addNode(NodeServer node) async {
    final own = await _store.readJson(DeskStore.nodesKey);
    final list = [
      if (own is List)
        for (final o in own.whereType<Map<String, dynamic>>())
          if (o['url'] != node.url) o,
      {'url': node.url, 'label': node.label},
    ];
    await _store.writeJson(DeskStore.nodesKey, list);
    _checked[node.url] = node;
  }

  @override
  Future<void> useEpicbox(String domain) async {
    final relay = EpicboxRelay.parse(domain);
    if (relay == null) throw const DeskError('Not a server name');
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
    final session = _open;
    _epicboxHealth = ServiceHealth.checking;
    _changed();
    _listener = session.startListener().listen(
      (e) {
        switch (e.kind) {
          case core.ListenerEventKind.connected:
            _epicboxHealth = ServiceHealth.ok;
          case core.ListenerEventKind.disconnected:
            _epicboxHealth = ServiceHealth.down;
          case core.ListenerEventKind.received || core.ListenerEventKind.finalized || core.ListenerEventKind.expired:
            unawaited(_reload());
          case core.ListenerEventKind.stopped:
            _epicboxHealth = ServiceHealth.off;
            _listener = null;
          case core.ListenerEventKind.repeated || core.ListenerEventKind.error || core.ListenerEventKind.delayed:
            logInfo('desk', 'listener ${e.kind.name}');
        }
        _changed();
      },
      onError: (Object e) {
        logWarn('desk', 'listener ended: ${e is core.WalletError ? e.kind.name : e.runtimeType}');
        _epicboxHealth = ServiceHealth.down;
        _listener = null;
        _changed();
      },
    );
  }

  @override
  Future<void> setHttpListening(bool on) async {
    if (!on) return _stopHttp();
    if (_http != null) return;
    // Off while Tor is on: it would answer on this computer's own address. Tor off starts it
    // again when its switch ([DeskSettings.directHttp]) is on.
    if (_settings.tor) return;
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
    void ended(ServiceHealth health, String? problem) {
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
            ended(ServiceHealth.down, 'Port ${e.port ?? port} in use');
          case core.HttpListenerEventKind.bindFailed:
            ended(ServiceHealth.down, 'Port ${e.port ?? port} not available');
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
        ended(ServiceHealth.down, 'Stopped with an error');
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
    _epicboxOverTor = on;
    await _session?.setEpicboxOverTor(on);
    _changed();
  }

  /// Hands [session] the Epicbox over Tor choice and the onion routes in use.
  Future<void> _routeEpicbox(core.WalletSession session) async {
    await session.setEpicboxOverTor(_epicboxOverTor);
    await _applyOnions(session);
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
  Future<void> setTor(bool on) async {
    _open;
    _settings = _settings.copyWith(tor: on);
    await _store.saveTorOn(_openEntry?.walletId, on);
    logInfo('desk', 'tor ${on ? 'on' : 'off'}');
    if (!on) {
      // A stop the user asked for: Epicbox may go direct again.
      await _stopTor();
      if (DeskFeatures.httpDirect && _settings.directHttp && _session != null) await setHttpListening(true);
      return;
    }
    // The clearnet HTTP listener stays off while Tor is on (tor_routes.dart, torStops).
    await _stopHttp();
    // On again after a failure, or while a start hangs, is Retry; the Epicbox connection keeps
    // waiting for the new tor.
    if (_torHealth == ServiceHealth.down || (_torHealth == ServiceHealth.checking && !_torCanSend)) {
      final session = _session;
      if (session != null) await _expectTor(session);
      await _stopTor();
    }
    _torAutoRetried = false;
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
    if (generation != _generation || _session != session || _tor != null || !_settings.tor) return;
    _torCanSend = false;
    _torProgress = null;
    if (bundle == null) {
      _torHealth = ServiceHealth.down;
      _torProblem = torFailureText(core.TorFailure.missing);
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
      _tor = null;
      _torHealth = ServiceHealth.down;
      _torProblem = problem ?? 'Tor stopped';
      _torCanSend = false;
      _torProgress = null;
      _torStartedAt = null;
      _torSocks = null;
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
            _torCanSend = true;
            _torStartedAt = null;
            if (_torHealth != ServiceHealth.slow) _torHealth = ServiceHealth.checking;
          case core.TorEventKind.ready:
            _takeSocks(e.socksPort);
            _torHealth = ServiceHealth.ok;
            _torCanSend = true;
            _torProblem = null;
            final onion = e.onion;
            if (onion != null) _onion = core.onionHost(onion);
          case core.TorEventKind.failed:
            logWarn('desk', 'tor failed: ${e.failure?.name ?? '?'}');
            if (e.failure == core.TorFailure.network && !_torCanSend && !_torAutoRetried) {
              // A stall on the first bootstrap: one more try before "failed".
              _torAutoRetried = true;
              logInfo('desk', 'tor stalled connecting; starting it once more');
              unawaited(_restartTor(session, sub));
              return;
            }
            _torStartedAt = null;
            // Listener and keys leave tor running for sends; any other failure stops it.
            final forSends = e.failure == core.TorFailure.listener || e.failure == core.TorFailure.keys;
            _torHealth = forSends ? ServiceHealth.slow : ServiceHealth.down;
            _torProblem = torFailureText(e.failure);
            if (!forSends) _torCanSend = false;
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

  /// Stops the tor that [sub] watches and starts it again, showing "Connecting" throughout.
  Future<void> _restartTor(core.WalletSession session, StreamSubscription<core.TorEvent> sub) async {
    if (_tor != sub) return;
    _tor = null;
    await _expectTor(session);
    try {
      await session.stopTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop tor: ${e.kind.name}');
    }
    await sub.cancel();
    if (_session != session || !_settings.tor) return;
    await _startTor();
  }

  /// Tor (re)starts next: the Epicbox connection waits for it and a stop before it keeps it
  /// waiting (LEPIC's `expectTor`).
  Future<void> _expectTor(core.WalletSession session) async {
    try {
      await session.expectTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'expect tor: ${e.kind.name}');
    }
  }

  Future<void> _stopTor() async {
    final sub = _tor;
    _tor = null;
    _torStartedAt = null;
    _torSlowTimer?.cancel();
    final was = _torHealth;
    _torHealth = ServiceHealth.off;
    _torProblem = null;
    _torProgress = null;
    _torCanSend = false;
    if (sub == null) {
      if (was == ServiceHealth.off) return;
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
    _changed();
  }

  /// Set while Recheck balance scans: the due scan in [_sync] waits for the next sync.
  bool _rescanning = false;
  bool _rescanStopAsked = false;
  Completer<void>? _rescanEnded;

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false}) async* {
    // Admitted like [_running]: the checks and the count follow each other with no await.
    var waitedForStop = false;
    while (true) {
      if (_locking) throw const DeskError('The wallet is locking', locked: true);
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
    if (_rescanning) throw const DeskError(scanRunning);
    final session = _open;
    final key = _metaKey(_openEntry?.walletId);
    _rescanning = true;
    _rescanStopAsked = false;
    final ended = _rescanEnded = Completer<void>();
    var finished = false;
    // A scan counts as a running operation: the fallback waits for it (D-7).
    _busy++;
    try {
      await for (final p in session.scan(deleteUnconfirmed: deleteUnconfirmed)) {
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
      if (e.kind == core.WalletErrorKind.walletBusy) throw const DeskError(scanRunning);
      throw _deskError(e);
    } finally {
      _rescanning = false;
      _opEnded();
      if (!ended.isCompleted) ended.complete();
    }
    // A stopped scan leaves a due scan due; either way the balance is read again.
    if (finished) {
      await _setMeta({'scanPending': false}, key);
      _notice = null;
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

  /// Re-encrypts the open wallet under [next], then forgets its remembered password (F6). A
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
        core.WalletErrorKind.invalidArgument => const DeskError('Use at least $minPasswordLength characters'),
        core.WalletErrorKind.chainBusy || core.WalletErrorKind.walletBusy => _deskError(e),
        _ => const DeskError('Password not changed. The current password still opens the wallet.'),
      };
    }
    logInfo('desk', 'password changed');
    if (id != null) await _remember.forget(id);
  }

  // ---- History backup (F34) and its reminder (F33). The archive, the sealing and the merge
  // are the shared ones (`history/`, the core session), so a phone file opens here and back.

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
    try {
      return await _open.exportHistory();
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
    );
  }

  @override
  Future<HistoryImport> importHistory(Uint8List data) async {
    if (data.length > maxDeskHistoryBytes) throw const HistoryFileError(HistoryFileProblem.tooLarge, 'The file is too large to be one.');
    try {
      final r = await _open.importHistory(data: data);
      logInfo('desk', 'history imported: ${r.merged} merged, ${r.added} added, ${r.contactsAdded} contacts');
      await _reload();
      return HistoryImport(merged: r.merged, added: r.added, skipped: r.skipped, contactsAdded: r.contactsAdded);
    } on core.WalletError catch (e) {
      logWarn('desk', 'history import refused: ${e.kind.name}');
      throw historyFileError(e);
    }
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

  // ---- Invoices over Epicbox (docs/invoices/flow.md). The shared session's invoice calls,
  // mapped onto the desktop's own types (invoices.dart), not renamed. LEPIC keeps the invoice
  // address, the trusted list and the waiting invoices; the session keeps labels and what
  // became of each invoice in `wfe_meta.json`. Nothing here pays but [payInvoice], whose only
  // caller is Review's Approve, after the password; no event, drain or timer leads to it (P-2).

  /// Drains on a timer and on focus while a wallet is open ([_startInvoices]).
  InvoiceScheduler? _invoiceTimers;
  StreamSubscription<core.InvoiceEvent>? _invoiceSub;
  StreamSubscription<core.IssuerEvent>? _issuerSub;
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

  /// Messages from senders not on the trusted list ignored unread since the unlock.
  int _invoiceDropped = 0;
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
  Stream<InvoiceNotice> invoiceNotices() => _invoiceNotices.stream;

  /// After an unlock or a reopen on another server: the session's invoice events and the
  /// scheduler, on that session only.
  void _startInvoices() {
    _stopInvoices();
    final session = _session;
    if (session == null || !session.supportsInvoices) return;
    unawaited(_loadInvoiceExpiry().then((_) => _changed(), onError: (Object e) => logWarn('invoices', 'expiry not read: $e')));
    _invoiceSub = session.invoiceEvents().listen((e) => unawaited(_onInvoiceEvent(session, e)));
    _issuerSub = session.issuerEvents().listen((e) => unawaited(_onIssuerEvent(session, e)));
    _invoiceTimers = InvoiceScheduler(
      drainInvoices: () => _drainInvoices(session),
      drainPayments: () => _drainPayments(session),
      paymentsWanted: _paymentsWanted,
      invoicesEvery: invoicesEvery,
      paymentsEvery: paymentsEvery,
      watchFocus: invoiceFocus,
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
    if (!forget) return;
    _invoiceDropped = 0;
    _invoiceCheckedAt = null;
    _invoiceCheck = InvoiceCheck.ok;
    _invoiceProblem = null;
    _waitingSeen.clear();
    _endedUnpaid.clear();
    _cancelledInputs.clear();
    _invoiceFees.clear();
  }

  /// Whether the scheduler's timers run (tests).
  @visibleForTesting
  bool get invoiceTimersRunning => _invoiceTimers?.running ?? false;

  /// An issued invoice waits for its payer and nothing listens on the payments address.
  bool _paymentsWanted() => _listener == null && (_entries ?? const <core.TxEntry>[]).any((e) => e.awaitingPayer);

  /// Drains the invoice address (the session sweeps after it) and records the check.
  Future<void> _drainInvoices(core.WalletSession session) async {
    final r = await session.drainInvoices();
    if (_session != session) return;
    _invoiceDropped += r.dropped;
    _invoiceCheckedAt = DateTime.now();
    if (r.parked > 0 || r.notices > 0 || r.finalized > 0) await _reload();
    _changed();
  }

  /// Drains the payments address: payments for issued invoices are finalized and posted.
  Future<void> _drainPayments(core.WalletSession session) async {
    final r = await session.drainPayments();
    if (_session != session) return;
    if (r.received > 0 || r.finalized > 0 || r.bounced > 0) await _reload();
    _changed();
  }

  /// A payer: an invoice parked, posted, withdrawn or expired. Never pays anything.
  Future<void> _onInvoiceEvent(core.WalletSession session, core.InvoiceEvent e) async {
    if (_session != session) return;
    final seen = _waitingSeen[e.slateId];
    final now = DateTime.now();
    switch (e.kind) {
      case core.InvoiceEventKind.withdrawn when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.withdrawn, answeredAt: now);
        _invoiceNotices.add(InvoiceNotice(InvoiceNoticeKind.withdrawn, slateId: e.slateId, who: seen.label));
      case core.InvoiceEventKind.expired when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.expired, answeredAt: now);
        _invoiceNotices.add(InvoiceNotice(InvoiceNoticeKind.expired, slateId: e.slateId, who: seen.label));
      case core.InvoiceEventKind.declined when seen != null:
        _endedUnpaid[e.slateId] = seen.copyWith(state: PayState.declined, answeredAt: now);
      // Unverified (the session tells each slate once): inform only, act on nothing.
      case core.InvoiceEventKind.unknownInvoicePayment:
        _invoiceNotices.add(InvoiceNotice(InvoiceNoticeKind.unknownPayment, slateId: e.slateId));
        return;
      case core.InvoiceEventKind.unknownSendAnswer:
        _invoiceNotices.add(InvoiceNotice(InvoiceNoticeKind.unknownAnswer, slateId: e.slateId));
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
    await _reload();
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
    final who = _contactFor(await _contactsOr(), payer)?.name ?? (payer.isEmpty ? '' : shortAddress(payer, compact: true));
    _invoiceNotices.add(InvoiceNotice(kind, slateId: e.slateId, who: who, amount: amount));
  }

  Future<List<Contact>> _contactsOr() async {
    try {
      return await contacts();
    } on Object {
      return const [];
    }
  }

  /// The contact [address] belongs to, by key: their invoice address or their payments address.
  static Contact? _contactFor(List<Contact> contacts, String address) {
    if (address.isEmpty) return null;
    final key = addressKey(address);
    return contacts.where((c) => (c.invoiceAddress != null && addressKey(c.invoiceAddress!) == key) || addressKey(c.address) == key).firstOrNull;
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
    var address = '';
    try {
      address = await session.invoiceAddress();
    } on core.WalletError catch (e) {
      // No relay set: LEPIC has no invoice address yet.
      logWarn('invoices', 'invoice address: ${e.kind.name}');
    }
    int? index;
    try {
      index = await session.invoiceAddressIndex();
    } on core.WalletError catch (e) {
      logWarn('invoices', 'invoice address index: ${e.kind.name}');
    }
    final services = await session.trustedServices();
    final people = await _contactsOr();
    final entries = _entries ?? await session.transactions(refresh: false);
    final minConf = _minConf.toInt();
    // The label is the user's, from the trusted list by key; never a name from the invoice (P-6).
    String labelOf(String sender) => core.serviceLabel(services, sender) ?? shortAddress(sender, compact: true);
    String storedAddress(String sender) =>
        services.where((s) => core.epicboxKey(s.address) == core.epicboxKey(sender)).firstOrNull?.address ?? sender;

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
          senderAddress: storedAddress(p.senderAddress),
          label: labelOf(p.senderAddress),
          amount: amount,
          fee: fee ?? 0,
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
          senderAddress: storedAddress(record.senderAddress),
          label: labelOf(record.senderAddress),
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
          spendToSelf: e.status == core.TxStatus.cancelled && (_cancelledInputs[slateId]?.isNotEmpty ?? false),
        ),
      );
    }

    final sent = [
      for (final r in await session.issuedInvoices())
        _request(r, entries.where((e) => e.id == r.txId).firstOrNull, people, minConf: minConf),
    ];

    return InvoiceBook(
      now: now,
      invoiceAddress: address,
      invoiceIndex: index,
      trusted: [
        for (final s in services)
          TrustedSender(
            address: s.address,
            label: s.label ?? shortAddress(s.address, compact: true),
            since: s.since ?? DateTime.fromMillisecondsSinceEpoch(0),
            contactId: _contactFor(people, s.address)?.id,
          ),
      ],
      toPay: [...waiting, ...paid, for (final i in _endedUnpaid.values) if (!waiting.any((w) => w.slateId == i.slateId)) i],
      sent: sent,
      expiry: _invoiceExpiry,
      dropped: _invoiceDropped,
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

  IssuedRequest _request(core.IssuedInvoice r, core.TxEntry? e, List<Contact> people, {required int minConf}) {
    final tx = e == null ? null : deskTx(e, tip: _tip, minConf: minConf, fallbackId: -1);
    return IssuedRequest(
      slateId: r.slateId,
      txId: r.txId,
      payerAddress: r.payerAddress,
      payerName: _contactFor(people, r.payerAddress)?.name,
      amount: r.amount.toInt(),
      message: _line(r.message),
      issuedAt: r.issuedAt,
      expiresAt: r.issuedAt.add(_invoiceExpiry),
      state: requestState(r.state, e, tip: _tip, minConf: minConf),
      confirmations: tx?.confirmations ?? 0,
    );
  }

  /// One check of the invoice address and, with the listener off, the payments address.
  @override
  Future<InvoiceBook> checkInvoices() async {
    final session = _open;
    _invoiceCheck = InvoiceCheck.checking;
    try {
      await _drainInvoices(session);
      if (_listener == null) await _drainPayments(session);
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
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft) async {
    final session = _open;
    try {
      // A request the relay did not take is cancelled by the session: nothing was sent.
      final r = await session.issueInvoice(amount: BigInt.from(draft.amount), address: draft.payerAddress.trim(), message: draft.message);
      await _reload();
      final e = (_entries ?? const <core.TxEntry>[]).where((t) => t.id == r.txId).firstOrNull;
      final request = _request(r, e, await _contactsOr(), minConf: _minConf.toInt());
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
    if (txId == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice');
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
    if (txId == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice');
    try {
      await _running(() => _open.cancelTransaction(txId: txId));
    } on core.WalletError catch (e) {
      throw _cancelError(e);
    }
    await _reload();
  }

  /// A refused cancel in the screens' terms: the node has it, or the node cannot be asked.
  static InvoiceError _cancelError(core.WalletError e) => switch (e.kind) {
    core.WalletErrorKind.invalidArgument => const InvoiceError(InvoiceProblem.onItsWay, 'Already on its way: it cannot be cancelled.'),
    core.WalletErrorKind.nodeUnreachable => const InvoiceError(InvoiceProblem.cannotCheck, 'Cannot check the network now.'),
    _ => invoiceError(e),
  };

  /// The only call that pays an invoice (P-2): Review's Approve, after the password, which is
  /// checked here first. [amount] is the invoice's own; LEPIC refuses any other.
  @override
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password}) => _running(() async {
    final session = _open;
    if (!await checkPassword(password)) throw const InvoiceError(InvoiceProblem.wrongPassword, 'Wrong password');
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
    return book.invoice(slateId) ?? (throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice'));
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

  /// The user's cancel of an invoice payment (P-3): LEPIC asks the node first and refuses one
  /// in the pool or on chain. Never automatic.
  @override
  Future<void> cancelInvoicePayment(String slateId) async {
    final entries = _entries ?? await _open.transactions(refresh: false);
    final txId = entries
        .where((e) => e.slateId == slateId && e.flow == core.TxFlow.invoice && (e.kind == core.TxKind.sent || e.kind == core.TxKind.sentCancelled))
        .firstOrNull
        ?.id;
    if (txId == null) throw const InvoiceError(InvoiceProblem.invalid, 'No such payment');
    // The coins it locks, read first: after the cancel they are this wallet's again, and
    // "Spend them to myself now" spends exactly these (D-2).
    var inputs = const <String>[];
    try {
      inputs = [
        for (final o in await _open.outputs())
          if (o.txId == txId && o.status == core.WalletOutputStatus.locked) o.commitment,
      ];
    } on core.WalletError catch (e) {
      logWarn('invoices', 'locked outputs not read: ${e.kind.name}');
    }
    try {
      await _running(() => _open.cancelTransaction(txId: txId));
    } on core.WalletError catch (e) {
      throw _cancelError(e);
    }
    _cancelledInputs[slateId] = inputs;
    await _reload();
  }

  /// The coins of each invoice payment cancelled in this session, by slate id.
  final Map<String, List<String>> _cancelledInputs = {};

  @override
  Future<SelfSend> spendCancelledToSelf(String slateId) async {
    final commitments = _cancelledInputs[slateId];
    if (commitments == null || commitments.isEmpty) throw const DeskError('Nothing to spend');
    final sent = await _selfSend(() => _open.spendOutputsToSelf(commitments: commitments, minimumConfirmations: _minConf));
    _cancelledInputs.remove(slateId);
    return sent;
  }

  @override
  Future<String> rotateInvoiceAddress() async {
    try {
      final address = await _open.rotateInvoiceAddress();
      _changed();
      return address;
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
  }

  @override
  Future<void> trustSender(String address, String label, {String? contactId}) async {
    try {
      await _open.addTrustedService(address: address.trim(), label: label);
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    _changed();
  }

  @override
  Future<void> untrustSender(String address) async {
    try {
      await _open.removeTrustedService(address: address.trim());
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
    _changed();
  }

  @override
  Future<void> setInvoiceExpiry(Duration expiry) async {
    _invoiceExpiry = expiry > maxInvoiceExpiry ? maxInvoiceExpiry : expiry;
    await _setMeta({_invoiceExpiryKey: _invoiceExpiry.inSeconds});
    _changed();
  }

  @override
  Future<PeerCapability> peerCapability(String address) async {
    try {
      return switch (await _open.peerCapability(address: address.trim())) {
        core.PeerCapability.unknown => PeerCapability.unknown,
        core.PeerCapability.lepic => PeerCapability.lepic,
        core.PeerCapability.noInvoices => PeerCapability.noInvoices,
      };
    } on core.WalletError catch (e) {
      throw invoiceError(e);
    }
  }

  // ---- Helpers.

  Future<void> _reload() async {
    final session = _session;
    if (session == null) return;
    try {
      _summary = await session.summary(refresh: false, minimumConfirmations: _minConf);
      _entries = await session.transactions(refresh: false);
    } on core.WalletError catch (e) {
      logWarn('desk', 'reload: ${e.kind.name}');
    }
    _changed();
  }

  List<Tx> _txs() => [
    for (final (i, e) in (_entries ?? const <core.TxEntry>[]).indexed) deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1 - i),
  ];

  Tx _txFor(core.TxEntry e) =>
      _txs().where((t) => t.id == e.id && e.id != null).firstOrNull ?? deskTx(e, tip: _tip, minConf: _minConf.toInt(), fallbackId: -1);

  /// Stops background work for good (the app is closing).
  Future<void> dispose() async {
    statusSite.removeListener(_statusSiteChanged);
    await _lock(waitAtMost: closeWait);
    await _node?.stop();
    await _changes.close();
    await _invoiceNotices.close();
  }
}

DateTime? _time(Object? unix) => unix is int ? DateTime.fromMillisecondsSinceEpoch(unix * 1000) : null;

/// One output as the Outputs page shows it. An unspent output under [minConf] confirmations
/// is confirming, a mining reward below its lock height immature; an unconfirmed one (not on
/// chain yet, or a reward still being mined) is unconfirmed.
Output deskOutput(core.WalletOutput o, {required int minConf}) {
  final status = switch (o.status) {
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
  );
}

/// One history row as the desktop UI shows it. [tip] is the node's height, for confirmations.
/// Rows without a local id (imported, restored) get [fallbackId], below 0.
Tx deskTx(core.TxEntry e, {required int tip, required int minConf, required int fallbackId, String? contactName}) {
  final sent = e.kind == core.TxKind.sent || e.kind == core.TxKind.sentCancelled;
  final fee = e.fee?.toInt() ?? 0;
  final height = e.blockHeight?.toInt();
  final confirmations = height == null || tip < height ? 0 : tip - height + 1;
  final state = switch (e.status) {
    core.TxStatus.cancelled => TxState.cancelled,
    core.TxStatus.awaitingRecipient => TxState.waitingRecipient,
    core.TxStatus.awaitingConfirmation => height == null ? TxState.posted : TxState.confirming,
    core.TxStatus.confirmed => confirmations > 0 && confirmations < minConf ? TxState.confirming : TxState.confirmed,
  };
  final to = e.counterparty;
  final method = switch (e.transport) {
    'tor' => TxMethod.tor,
    'http' => TxMethod.http,
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
    confirmations: confirmations,
    confirmationsNeeded: minConf,
    counterparty: to,
    // A split or consolidate: both sides are this wallet (F13).
    contactName: e.transport == 'self' ? 'This wallet' : contactName,
    message: core.messageBy(e.messages, core.SlateRole.sender) ?? core.messageBy(e.messages, core.SlateRole.receiver),
    height: height,
    kernel: e.kernelExcess,
    coinbase: e.kind == core.TxKind.coinbase,
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
    flow: e.flow == core.TxFlow.invoice ? TxFlow.invoice : TxFlow.payment,
    confirmedAt: e.blockTimeUnix == null ? null : DateTime.fromMillisecondsSinceEpoch(e.blockTimeUnix! * 1000),
    detail: e.statusDetail,
  );
}

/// Where a paid invoice stands (flow.md §4.4), from its payment and what the session recorded
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
  return PayState.delivered;
}

/// Where an issued invoice stands (flow.md §3.3), from the session's state and, once paid,
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
}, deskErrorText(e));

/// History backups are small; a file far larger is not one (the phone's limit).
const int maxDeskHistoryBytes = 32 << 20;

/// A history file the core refused, in the backup design's words (F34).
Object historyFileError(core.WalletError e) {
  if (e.kind != core.WalletErrorKind.invalidArgument) return _deskError(e);
  final m = e.message;
  final chains = RegExp(r'^This history file is from (\w+), but this wallet is on (\w+)').firstMatch(m);
  if (chains != null) return HistoryFileError(HistoryFileProblem.otherChain, 'The file is from ${chains[1]}; this wallet is on ${chains[2]}.');
  return switch (m) {
    historyOtherWallet => const HistoryFileError(HistoryFileProblem.otherWallet, 'The file was exported from a wallet with a different recovery phrase.'),
    historyNewer => const HistoryFileError(HistoryFileProblem.newer, 'A newer version of the app made this file. Update the app, then import it.'),
    historyDamaged => const HistoryFileError(HistoryFileProblem.damaged, 'The file is incomplete or was changed.'),
    _ => const HistoryFileError(HistoryFileProblem.notOurs, 'The file was not made by Epic Wallet.'),
  };
}

/// Writes `WALLET.txt` into the wallet folder [dir] (M19): what the folder is and that it is
/// not a backup. No address, no id, no path, no secret. A failure is logged, never shown.
Future<void> writeWalletTxt(String dir, {required String label, required String network, required DateTime created}) async {
  String two(int v) => v.toString().padLeft(2, '0');
  final day = '${created.year}-${two(created.month)}-${two(created.day)}';
  final text = [
    'Epic Wallet (BT Labs) wallet folder',
    'Label:     $label',
    'Network:   $network',
    'Created:   $day',
    'App:       $deskAppVersion',
    '',
    'wallet.vault    the seed, encrypted with the wallet password (Argon2id)',
    'wallet.sqlite3  outputs and payment history',
    '',
    'This folder is not a backup. Restore with the recovery phrase.',
    'A copy of this folder is only as safe as the password.',
    'Payment details and contacts: Settings > This wallet > Export history backup.',
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
