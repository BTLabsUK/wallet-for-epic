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

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../builtin_node.dart';
import '../../legacy_gui_profile.dart' as gui;
import '../../legacy_wallets.dart' as legacy;
import '../../lepic_wallet_service.dart' show sendUnbuildable;
import '../../log.dart';
import '../../node/node_settings.dart' show NodeSettings;
import '../../network.dart';
import '../../providers.dart' show WalletDirResolver, defaultMinimumConfirmations;
import '../../public_servers.dart';
import '../../relay_directory.dart';
import '../../secret_store_api.dart';
import '../../slate_files.dart' show decodeSlateFile, responseFileName, sendFileName;
import '../../tor_location.dart';
import '../../wallet_registry.dart' as reg;
import '../../wallet_service.dart' as core;
import 'api.dart';
import 'desk_store.dart';
import 'features.dart';
import 'http_address.dart';
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
    core.WalletErrorKind.invalidArgument => detail == sendUnbuildable ? detail : detail.isEmpty ? 'Not accepted' : 'Not accepted: $detail',
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

DeskError _deskError(Object error) => DeskError(
  deskErrorText(error),
  wrongPassword: error is core.WalletError && error.kind == core.WalletErrorKind.wrongPassword,
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
    reg.WalletRegistry? registry,
    this._builtInNode,
    legacy.LegacyRoots Function()? legacyRoots,
    this._pickDirectory,
    this._listProcesses,
    this._torBundle,
    bool? torFeature,
    Future<Directory> Function()? rememberDir,
    DateTime Function()? now,
  }) : _torFeature = torFeature ?? DeskFeatures.tor,
       _legacyRoots = legacyRoots ?? legacy.LegacyRoots.current,
       _minConfFallback = minimumConfirmations ?? BigInt.from(defaultMinimumConfirmations),
       _registryGiven = registry,
       _remember = RememberedPasswords(
         secrets: _secrets,
         dir: rememberDir ?? () async => Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}remember'),
         now: now,
       );

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
    if (!_changes.isClosed) _changes.add(null);
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
    _config = config;
    _password = password;
    _openEntry = entry;
    _selectedId = null;
    // The HTTP listener's reach, port and autostart are this wallet's own.
    final http = await _store.httpPrefs(entry.walletId);
    // Tor too: off unless this wallet turned it on.
    final tor = _torFeature && await _store.torOn(entry.walletId);
    _settings = _settings.copyWith(
      publicMode: http.publicMode,
      httpPort: http.port,
      httpAutostart: http.autostart,
      tor: tor,
    );
    await _setMeta({'opened': DateTime.now().millisecondsSinceEpoch ~/ 1000});
    try {
      if (_registry != null) _openEntry = await (await _registry!).markOpened(entry.id);
    } on Object catch (e) {
      logWarn('desk', 'wallet list not saved: ${e.runtimeType}');
    }
    return true;
  }

  /// After an unlock: the node poll, the first sync and, when this wallet has it on, tor.
  void _startOpenWallet() {
    _poll = Timer.periodic(nodePoll, (_) => unawaited(_checkTip()));
    unawaited(_checkTip());
    unawaited(sync());
    _torAutoRetried = false;
    if (_settings.tor) unawaited(_startTor());
  }

  @override
  Future<void> lock() async {
    _generation++;
    _poll?.cancel();
    _poll = null;
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
  /// ([DeskError.locked]). Locked: only saved.
  Future<void> _switchTo({required String nodeUrl, required EpicboxRelay relay}) async {
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
        final address = (c.epicboxAddress ?? c.httpAddress)?.trim();
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
  bool _contactAddressOk(String a) =>
      isEpicboxAddress(a) ||
      (RegExp(r'^https?:', caseSensitive: false).hasMatch(a) && httpAddressProblem(a) == null) ||
      (_torFeature && isOnionAddress(a));

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
      awaitingFinalization: s.awaitingFinalization.toInt(),
      immature: s.immature.toInt(),
      minConfirmations: _minConf.toInt(),
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

  /// Outputs are not in LEPIC's API yet ([DeskFeatures.coins]).
  @override
  Future<List<Output>> outputs() async => const [];

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
        Contact(id: c.id, name: c.name, address: c.address, note: c.note, favourite: favourites.contains(c.id), lastUsed: lastUsed(c.address)),
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
  Future<(int, int)> estimateMax() async {
    try {
      final f = await _open.estimateMax(minimumConfirmations: _minConf);
      return (f.amount.toInt(), f.fee.toInt());
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<SendResult> send(SendRequest r) async {
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
          final e = await session.sendEpicbox(amount: BigInt.from(amount), minimumConfirmations: _minConf, address: to, message: message);
          await _reload();
          return SendDone(_txFor(e));
        case TxMethod.file:
          final slate = await session.createSendSlate(amount: BigInt.from(amount), minimumConfirmations: _minConf, message: message);
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
          );
          return await _directDone(session, sent, method, amount, to);
        case TxMethod.tor:
          final to = (r.to ?? '').trim();
          if (!isOnionAddress(to)) return const SendFailed('Not an onion address');
          if (!_settings.tor) return const SendFailed('Tor is off. Turn on Tor to send to an onion address.');
          if (!_torCanSend) return const SendFailed('Tor is still connecting. Try again in a moment.');
          before = {for (final e in await session.transactions(refresh: false)) e.id};
          final sent = await session.sendTor(amount: BigInt.from(amount), minimumConfirmations: _minConf, onion: to, message: message);
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
  Future<ReceivedFile> receiveFile(String fileName) async {
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
  Future<Tx> finalizeFile(String fileName) async {
    final json = await _readSlate(fileName);
    try {
      final e = await _open.finalizeAndPost(slateJson: json);
      await _reload();
      return _txFor(e);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<void> cancelTx(int id) async {
    if (id < 0) throw const DeskError('This payment cannot be cancelled');
    try {
      await _open.cancelTransaction(txId: id);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    await _reload();
  }

  @override
  Future<String> exportProof(int id) => throw UnsupportedError('payment proofs (DeskFeatures.paymentProofs)');

  @override
  Future<String> saveContact(Contact contact) async {
    try {
      final stored = await _open.saveContact(contact: core.Contact(id: contact.id, name: contact.name, address: contact.address, note: contact.note));
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
    final favourites = await _favourites();
    if (favourites.remove(id)) await _store.writeJson(_favouritesKey, favourites.toList());
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
    if (moved && _session != null && (_http != null || _httpHealth == ServiceHealth.down)) {
      await _stopHttp();
      if (settings.directHttp) await setHttpListening(true);
    }
  }

  @override
  Future<void> useNode(String url) async {
    logInfo('desk', 'node ${Uri.tryParse(url)?.host ?? '?'}');
    await _switchTo(nodeUrl: url, relay: await _relay());
    if (await _builtInOn()) {
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'false');
      await _node?.stop();
    }
  }

  String get _beforeBuiltInKey => 'app.node.$_chain.beforeBuiltIn';

  Future<bool> _builtInOn() async =>
      _builtInNode != null && await _secrets.read(builtInNodeSettingKey(preset.chain)) == 'true';

  Future<BuiltInNode> _theNode() async {
    final make = _builtInNode;
    if (make == null) throw const DeskError('No built-in node in this build');
    final node = _node ??= await make(preset.chain);
    // The user's node settings (data folder, peers) apply to every start, also at launch.
    node.options = await NodeSettings(_secrets, preset.chain).toOptions();
    return node;
  }

  @override
  Future<void> useBuiltInNode(bool on) async {
    // The setting and the saved node change only once the wallet runs on the new node, so a
    // failed start or move leaves both as they were.
    if (on) {
      final node = await _theNode();
      try {
        await node.start();
      } on NodeStartException catch (e) {
        throw DeskError(e.message);
      }
      // A stop that came in while it was starting wins.
      if (!node.wantsRunning) throw const DeskError('Built-in node stopped');
      final current = await _nodeUrl();
      if (current != node.url) {
        try {
          await _switchTo(nodeUrl: node.url, relay: await _relay());
        } on Object {
          if (!await _builtInOn()) await node.stop();
          rethrow;
        }
        // A lock while reopening returns without moving; a stop while moving undoes it.
        if (await _nodeUrl() != node.url) throw const DeskError('Not changed: the wallet was locked');
        if (!node.wantsRunning) {
          await _switchTo(nodeUrl: current, relay: await _relay());
          throw const DeskError('Built-in node stopped');
        }
        await _secrets.write(_beforeBuiltInKey, current);
      }
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'true');
      logInfo('desk', 'built-in node on');
      // The status reads "Syncing" from now on while the node is at height 0 (O2).
      unawaited(_checkTip());
      return;
    }
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
      _notice = 'Built-in node not started: ${e is NodeStartException ? e.message : 'unknown error'}';
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
    await _switchTo(nodeUrl: await _nodeUrl(), relay: relay);
  }

  @override
  Future<void> setListening(bool on) async {
    if (!on) {
      await _stopListener();
      return _stopHttp();
    }
    if (_settings.directHttp) await setHttpListening(true);
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

  @override
  Future<void> setTor(bool on) async {
    _open;
    _settings = _settings.copyWith(tor: on);
    await _store.saveTorOn(_openEntry?.walletId, on);
    logInfo('desk', 'tor ${on ? 'on' : 'off'}');
    if (!on) return _stopTor();
    // On again after a failure, or while a start hangs, is Retry.
    if (_torHealth == ServiceHealth.down || (_torHealth == ServiceHealth.checking && !_torCanSend)) await _stopTor();
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
    }

    sub = session.startTor(torBinary: bundle.binary, libDir: bundle.libDir).listen(
      (e) {
        if (_tor != sub) return;
        switch (e.kind) {
          case core.TorEventKind.starting:
            _torHealth = ServiceHealth.checking;
            _torProgress = e.progress ?? _torProgress;
          case core.TorEventKind.bootstrapped || core.TorEventKind.publishing:
            _torCanSend = true;
            _torStartedAt = null;
            if (_torHealth != ServiceHealth.slow) _torHealth = ServiceHealth.checking;
          case core.TorEventKind.ready:
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
    try {
      await session.stopTor();
    } on core.WalletError catch (e) {
      logWarn('desk', 'stop tor: ${e.kind.name}');
    }
    await sub.cancel();
    if (_session != session || !_settings.tor) return;
    await _startTor();
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
      if (was != ServiceHealth.off) _changed();
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
    final session = _open;
    final key = _metaKey(_openEntry?.walletId);
    // A scan LEPIC was told to stop still holds the wallet until its stream ends: wait for that.
    final old = _rescanEnded;
    if (_rescanning && _rescanStopAsked && old != null) {
      await old.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    }
    if (_rescanning) throw const DeskError(scanRunning);
    _rescanning = true;
    _rescanStopAsked = false;
    final ended = _rescanEnded = Completer<void>();
    var finished = false;
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
    await lock();
    await _node?.stop();
    await _changes.close();
  }
}

DateTime? _time(Object? unix) => unix is int ? DateTime.fromMillisecondsSinceEpoch(unix * 1000) : null;

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
    contactName: contactName,
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
    confirmedAt: e.blockTimeUnix == null ? null : DateTime.fromMillisecondsSinceEpoch(e.blockTimeUnix! * 1000),
    detail: e.statusDetail,
  );
}
