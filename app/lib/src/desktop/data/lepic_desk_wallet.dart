/// [DeskWalletApi] over the app's wallet core ([WalletService], LEPIC on a computer).
///
/// Desktop wallets are password wallets, as in the Electron wallet: no PIN vault. One wallet
/// per chain in `<app support>/wallets/<chain>` ([WalletDirResolver]), mainnet. The node and
/// Epicbox server are saved under the phone's keys (`NetworkChoiceNotifier`), so both UIs agree.
///
/// While unlocked the adapter keeps the session, the password (to reopen the wallet when the
/// node or the Epicbox server changes; never logged, dropped on lock), the last summary and
/// transactions, the node's tip and the listener's state. Background work (sync, node checks,
/// listener events) fires [changes]; [status] reads the fields.
library;

import 'dart:async';
import 'dart:io';

import '../../bip39_words.dart';
import '../../builtin_node.dart';
import '../../log.dart';
import '../../network.dart';
import '../../providers.dart' show WalletDirResolver;
import '../../relay_directory.dart';
import '../../secret_store_api.dart';
import '../../slate_files.dart' show decodeSlateFile, responseFileName, sendFileName;
import '../../wallet_service.dart' as core;
import 'api.dart';
import 'desk_store.dart';
import 'models.dart';

/// Public nodes offered in Settings › Node, the default first.
const List<NodeServer> deskPublicNodes = [
  NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs', operator: 'BT Labs', health: ServiceHealth.checking),
  NodeServer(url: 'https://node.epicnet.us:3413', label: 'EpicNet', operator: 'EpicNet', health: ServiceHealth.checking),
];

/// Public Epicbox servers, the default first.
const List<EpicboxServer> deskEpicboxes = [
  EpicboxServer(domain: 'epicbox.stackwallet.com', operator: 'Cypher Stack', health: ServiceHealth.checking),
  EpicboxServer(domain: 'epicbox.epicnet.us', operator: 'EpicNet', health: ServiceHealth.checking),
  EpicboxServer(domain: 'epicbox.epiccash.com', operator: 'Epic Cash team', health: ServiceHealth.checking),
];

/// A short sentence for a wallet error.
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
    core.WalletErrorKind.chainBusy || core.WalletErrorKind.walletBusy => 'Wallet busy. Try again in a moment.',
    core.WalletErrorKind.damagedDatabase => 'Wallet database damaged, rebuilding',
    core.WalletErrorKind.paymentExpired => detail.isEmpty ? 'Payment expired' : detail,
    core.WalletErrorKind.invalidArgument => detail.isEmpty ? 'Not accepted' : 'Not accepted: $detail',
    core.WalletErrorKind.io => detail.isEmpty ? 'Disk error' : 'Disk error: $detail',
    core.WalletErrorKind.other => detail.isEmpty ? 'Something went wrong' : detail,
  };
}

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
    this.preset = mainnetPreset,
    this._settings = const DeskSettings(),
    BigInt? minimumConfirmations,
    this.nodePoll = const Duration(seconds: 30),
    this.nodeTimeout = const Duration(seconds: 15),
    this._builtInNode,
  }) : _minConf = minimumConfirmations ?? BigInt.from(10);

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
  final Set<String> _checking = {};
  final BigInt _minConf;
  final Duration nodePoll;
  final Duration nodeTimeout;

  /// Makes the built-in node of a network (desktop builds with the bundled `epic`, D10); null
  /// where there is none.
  final Future<BuiltInNode> Function(core.Chain chain)? _builtInNode;
  BuiltInNode? _node;
  DeskSettings _settings;

  core.WalletSession? _session;
  core.WalletConfig? _config;
  String? _password;

  /// Bumped by [lock]: a session opened under an older value is closed at once.
  int _generation = 0;

  core.WalletSummary? _summary;
  List<core.TxEntry>? _entries;
  int _tip = 0;
  ServiceHealth _nodeHealth = ServiceHealth.checking;
  ServiceHealth _epicboxHealth = ServiceHealth.off;
  double? _syncProgress;
  DateTime? _lastUpdate;
  String? _notice;
  final Map<String, NodeServer> _checked = {};

  StreamSubscription<core.ListenerEvent>? _listener;
  Timer? _poll;
  Future<void>? _syncing;
  bool _syncAgain = false;
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
    final saved = await _secrets.read(_relayKey);
    return (saved == null ? null : EpicboxRelay.parse(saved)) ?? EpicboxRelay(host: deskEpicboxes.first.domain);
  }

  Future<core.WalletConfig> _makeConfig({String? nodeUrl, EpicboxRelay? relay}) async =>
      preset.config(dataDir: await _walletDir(preset.chain), nodeUrl: nodeUrl ?? await _nodeUrl(), relay: relay ?? await _relay());

  Future<Map<String, dynamic>> _meta() async {
    final j = await _store.readJson(DeskStore.walletKey(_chain));
    return j is Map<String, dynamic> ? j : <String, dynamic>{};
  }

  Future<void> _setMeta(Map<String, Object?> changes) async =>
      _store.writeJson(DeskStore.walletKey(_chain), {...await _meta(), ...changes});

  // ---- Wallets and opening one.

  @override
  Future<List<WalletEntry>> wallets() async {
    final config = await _makeConfig();
    if (!await _service.walletExists(config: config)) return const [];
    final meta = await _meta();
    return [
      WalletEntry(
        name: (meta['name'] as String?) ?? 'Main wallet',
        folder: config.dataDir,
        network: _chain,
        current: true,
        lastOpened: _time(meta['opened']),
      ),
    ];
  }

  @override
  Future<bool> unlock(String password) async {
    await lock();
    final config = await _makeConfig();
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
      await _setMeta({'scanPending': true});
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
    await _setMeta({'opened': DateTime.now().millisecondsSinceEpoch ~/ 1000});
    _poll = Timer.periodic(nodePoll, (_) => unawaited(_checkTip()));
    unawaited(_checkTip());
    unawaited(sync());
    return true;
  }

  @override
  Future<void> lock() async {
    _generation++;
    _poll?.cancel();
    _poll = null;
    await _stopListener();
    final session = _session;
    _session = null;
    _password = null;
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
    final config = await _makeConfig(nodeUrl: nodeUrl, relay: relay);
    await _stopListener();
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
      await _afterReopen(listening);
      throw DeskError('Not changed: ${deskErrorText(e)}');
    }
    await save();
    await _afterReopen(listening);
  }

  Future<void> _afterReopen(bool listening) async {
    _nodeHealth = ServiceHealth.checking;
    if (listening) await setListening(true);
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

  @override
  Future<List<String>> createWallet({required String name, required String password}) async {
    _checkPassword(password);
    await lock();
    final config = await _makeConfig();
    try {
      final session = await _service.create(config: config, password: password);
      try {
        final phrase = await session.mnemonic(password: password);
        await _store.writeJson(DeskStore.walletKey(_chain), {
          'name': name.trim().isEmpty ? null : name.trim(),
          'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        return phrase.split(RegExp(r'\s+'));
      } finally {
        session.dispose();
      }
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<bool> checkPhraseWord(String word) async => bip39Words.contains(word.trim().toLowerCase());

  @override
  Future<void> restoreWallet({required String name, required String password, required List<String> phrase}) async {
    _checkPassword(password);
    final mnemonic = phrase.map((w) => w.trim().toLowerCase()).join(' ');
    if (!_service.validateMnemonic(phrase: mnemonic)) throw const DeskError('Recovery phrase not valid');
    await lock();
    final config = await _makeConfig();
    try {
      final session = await _service.create(config: config, mnemonic: mnemonic, password: password);
      session.dispose();
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    // The scan runs after unlock, in the background, with its progress in the status.
    await _store.writeJson(DeskStore.walletKey(_chain), {
      'name': name.trim().isEmpty ? null : name.trim(),
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'scanPending': true,
    });
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
    _syncProgress = 0;
    _changed();
    try {
      if ((await _meta())['scanPending'] == true) {
        await for (final p in session.scan()) {
          if (_session != session) return;
          if (p.percent != null) _syncProgress = p.percent! / 200;
          _changed();
        }
        await _setMeta({'scanPending': false});
        _notice = null;
      }
      await for (final p in session.refresh(minimumConfirmations: _minConf)) {
        if (_session != session) return;
        _syncProgress = 0.5 + p.percent / 200;
        final summary = p.summary;
        if (summary != null) {
          _summary = summary;
          _nodeHealth = summary.validatedWithNode ? ServiceHealth.ok : ServiceHealth.down;
          final h = summary.lastConfirmedHeight.toInt();
          if (h > _tip) _tip = h;
        }
        _changed();
      }
      _entries = await session.transactions(refresh: false);
      _lastUpdate = DateTime.now();
    } on core.WalletError catch (e) {
      logWarn('desk', 'sync: ${e.kind.name}');
      if (e.kind == core.WalletErrorKind.nodeUnreachable) _nodeHealth = ServiceHealth.down;
    } finally {
      if (_session == session) _syncProgress = null;
      _changed();
    }
  }

  Future<void> _checkTip() async {
    final config = _config;
    if (config == null) return;
    try {
      final tip = await _service.nodeTip(config: config).timeout(nodeTimeout);
      final h = tip.height.toInt();
      final grew = h > _tip;
      _tip = h;
      if (_nodeHealth != ServiceHealth.ok) {
        _nodeHealth = ServiceHealth.ok;
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
    final folder = _config?.dataDir ?? await _walletDir(preset.chain);
    return WalletAccount(
      name: (meta['name'] as String?) ?? 'Main wallet',
      network: _chain,
      folder: folder,
      created: _time(meta['created']) ?? DateTime.now(),
      appFolder: Directory(folder).parent.parent.path,
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
    final j = await _store.readJson(DeskStore.favouritesKey);
    return j is List ? {for (final v in j) '$v'} : <String>{};
  }

  @override
  Future<ServiceStatus> status() async {
    final config = _config;
    final nodeUrl = config?.nodeUrl ?? await _nodeUrl();
    final relay = config == null ? await _relay() : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
    final node = (await _listed()).where((n) => n.url == nodeUrl).firstOrNull ?? NodeServer(url: nodeUrl, label: Uri.tryParse(nodeUrl)?.host ?? nodeUrl);
    final box = deskEpicboxes.where((b) => b.domain == relay.host).firstOrNull ?? EpicboxServer(domain: relay.host, port: relay.port);
    return ServiceStatus(
      node: node,
      nodeHealth: _nodeHealth,
      nodeHeight: _tip,
      epicbox: box,
      epicboxHealth: _epicboxHealth,
      httpListener: ServiceHealth.off,
      tor: ServiceHealth.off,
      syncProgress: _syncProgress,
      lastUpdate: _lastUpdate,
      notice: _notice,
    );
  }

  @override
  Future<List<NodeServer>> nodes() async {
    final all = await _listed();
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

  /// Public nodes and My nodes, with the last check of each.
  Future<List<NodeServer>> _listed() async {
    final own = await _store.readJson(DeskStore.nodesKey);
    NodeServer withCheck(NodeServer n) {
      final c = _checked[n.url];
      return c == null ? n : NodeServer(url: n.url, label: n.label, operator: n.operator, health: c.health, latencyMs: c.latencyMs, height: c.height, version: c.version, own: n.own);
    }

    return [
      for (final n in deskPublicNodes) withCheck(n),
      if (own is List)
        for (final o in own.whereType<Map<String, dynamic>>())
          if (o['url'] is String) withCheck(NodeServer(url: o['url'] as String, label: (o['label'] as String?) ?? '', own: true, health: ServiceHealth.checking)),
    ];
  }

  @override
  Future<List<EpicboxServer>> epicboxes() async {
    final dir = relayDirectory;
    final at = _boxesAt;
    if (dir == null || preset.statusChain == null) return deskEpicboxes;
    if (_boxes != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) return _boxes!;
    try {
      final seen = {for (final r in await dir.relays(preset.statusChain!).timeout(nodeTimeout)) r.relay.host: r};
      _boxes = [
        for (final b in deskEpicboxes)
          EpicboxServer(
            domain: b.domain,
            port: b.port,
            operator: b.operator,
            health: switch (seen[b.domain]?.healthy) { true => ServiceHealth.ok, false => ServiceHealth.down, null => ServiceHealth.checking },
            latencyMs: seen[b.domain]?.latencyMs,
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
  Future<String> httpAddress() => throw UnsupportedError('HTTP receive (DeskFeatures.httpDirect)');

  @override
  Future<String> torAddress() => throw UnsupportedError('Tor (DeskFeatures.tor)');

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
    try {
      final message = r.message?.trim().isEmpty ?? true ? null : r.message!.trim();
      switch (r.method) {
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
        case TxMethod.http || TxMethod.tor:
          throw UnsupportedError('direct send (DeskFeatures.httpDirect, DeskFeatures.tor)');
      }
    } on core.WalletError catch (e) {
      await _reload();
      return switch (e.kind) {
        core.WalletErrorKind.transportFailed => const SendFailed('Not delivered. The payment waits in Activity; cancel it there to unlock the funds.', inActivity: true),
        _ => SendFailed(deskErrorText(e)),
      };
    }
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
  Future<void> saveContact(Contact contact) async {
    try {
      final stored = await _open.saveContact(contact: core.Contact(id: contact.id, name: contact.name, address: contact.address, note: contact.note));
      final favourites = await _favourites();
      contact.favourite ? favourites.add(stored.id) : favourites.remove(stored.id);
      await _store.writeJson(DeskStore.favouritesKey, favourites.toList());
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await _open.deleteContact(id: id);
    final favourites = await _favourites();
    if (favourites.remove(id)) await _store.writeJson(DeskStore.favouritesKey, favourites.toList());
  }

  @override
  Future<void> saveSettings(DeskSettings settings) async => _settings = settings;

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
    return _node ??= await make(preset.chain);
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
      if (const {NodeStatusKind.off, NodeStatusKind.stopped, NodeStatusKind.failed}.contains(node.state.kind)) {
        throw const DeskError('Built-in node stopped');
      }
      final current = await _nodeUrl();
      if (current != node.url) {
        try {
          await _switchTo(nodeUrl: node.url, relay: await _relay());
        } on Object {
          if (!await _builtInOn()) await node.stop();
          rethrow;
        }
        await _secrets.write(_beforeBuiltInKey, current);
      }
      await _secrets.write(builtInNodeSettingKey(preset.chain), 'true');
      logInfo('desk', 'built-in node on');
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

  @override
  Stream<ScanStep> rescan() async* {
    final session = _open;
    try {
      await for (final p in session.scan()) {
        yield ScanStep(p.message, percent: p.percent);
      }
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    await _setMeta({'scanPending': false});
    _notice = null;
    await sync();
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

  @override
  Future<void> changePassword(String current, String next) =>
      throw UnsupportedError('password change (DeskFeatures.changePassword)');

  /// Deletes this wallet's own folder, after the password is checked. Only the recovery phrase
  /// brings it back.
  @override
  Future<void> removeWallet(String password) async {
    try {
      await _open.mnemonic(password: password);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    final config = _config ?? await _makeConfig();
    await lock();
    try {
      await _service.deleteWallet(config: config);
    } on core.WalletError catch (e) {
      throw _deskError(e);
    }
    await _store.delete(DeskStore.walletKey(_chain));
    await _store.delete(DeskStore.favouritesKey);
    logInfo('desk', 'wallet deleted');
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
  final method = to == null
      ? (e.source == core.TxSource.wallet && e.kind != core.TxKind.coinbase ? TxMethod.file : TxMethod.epicbox)
      : to.startsWith('http')
      ? TxMethod.http
      : TxMethod.epicbox;
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
    counterparty: to,
    contactName: contactName,
    message: core.messageBy(e.messages, core.SlateRole.sender) ?? core.messageBy(e.messages, core.SlateRole.receiver),
    height: height,
    kernel: e.kernelExcess,
    coinbase: e.kind == core.TxKind.coinbase,
    foundByScan: e.source == core.TxSource.restored,
    confirmedAt: e.blockTimeUnix == null ? null : DateTime.fromMillisecondsSinceEpoch(e.blockTimeUnix! * 1000),
  );
}
