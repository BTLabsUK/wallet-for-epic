// SPDX-License-Identifier: Apache-2.0
/// The local node as one object for the app: start, stop, restart and settings of the built-in
/// node, with its state derived for display ([LocalNodeState]): sync progress and ETA, the
/// network height, uptime, chain data size and free disk, and the node's log.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../builtin_node.dart';
import '../models.dart' show Chain;
import 'local_node_state.dart';
import 'node_settings.dart';
import 'sync_progress.dart';

/// Wraps one (shared) [BuiltInNode]. Disposing the controller never stops the node.
class LocalNodeController {
  LocalNodeController(
    this.node, {
    required this.settings,
    Future<int> Function(String dir)? dirSize,
    DiskProbe? freeBytes,
    this.directoryTip,
    this.peersHeight,
    DateTime Function()? clock,
    this.diskEvery = const Duration(minutes: 5),
    this.networkEvery = const Duration(minutes: 1),
  }) : _dirSize = dirSize ?? simpleDirSize,
       _freeBytes = freeBytes ?? realFreeBytes,
       _clock = clock ?? DateTime.now {
    _sub = node.states.listen(_onNode);
    _state = _derive();
  }

  final BuiltInNode node;
  final NodeSettings settings;

  /// How often the chain data size and the free disk space are measured.
  final Duration diskEvery;

  /// How often the network's height (directory, peers) is asked for while the node runs.
  final Duration networkEvery;

  final Future<int> Function(String dir) _dirSize;
  final DiskProbe _freeBytes;
  /// The network tip by the node directory (the status site), when known.
  final Future<int?> Function()? directoryTip;
  /// The connected peers' typical height (their median; see peers.dart).
  final Future<int?> Function()? peersHeight;
  final DateTime Function() _clock;

  final StreamController<LocalNodeState> _out =
      StreamController<LocalNodeState>.broadcast();
  final EtaEstimator _eta = EtaEstimator();
  final SyncEta _syncEta = SyncEta();
  SyncStage? _syncStage;
  late final StreamSubscription<BuiltInNodeState> _sub;
  late LocalNodeState _state;
  Timer? _diskTimer;
  Timer? _networkTimer;
  bool _disposed = false;
  bool _measuring = false;
  bool _asking = false;
  int? _chainDataBytes;
  int? _chainDataBytesAtStart;
  int? _free;
  int? _directoryHeight;
  int? _peersHeight;
  ChainDataOrigin _origin = ChainDataOrigin.own;

  /// The current state; [states] streams every new one.
  LocalNodeState get state => _state;

  Stream<LocalNodeState> get states => _out.stream;

  String get logPath => node.logPath;

  /// Reads the settings into the node's options and starts measuring the disk. Starts no node.
  Future<void> load() async {
    final options = await settings.toOptions();
    _origin = await settings.chainDataOrigin();
    if (_disposed) return;
    node.options = options;
    _emit();
    _diskTimer ??= Timer.periodic(diskEvery, (_) => unawaited(_measure()));
    _networkTimer ??= Timer.periodic(networkEvery, (_) {
      if (node.state.isActive) unawaited(_askNetwork());
    });
    unawaited(_measure());
    if (node.state.isActive) unawaited(_askNetwork());
  }

  /// [state] is up to date when these return (the node's own event follows a moment later).
  Future<void> start() => _then(node.start());

  Future<void> stop() => _then(node.stop());

  Future<void> restart() => _then(node.restart());

  Future<void> _then(Future<void> f) async {
    try {
      await f;
    } finally {
      _emit();
    }
  }

  Chain get chain => node.chain;

  /// Measures the chain data size and the free disk space now (after a delete, move or reuse).
  Future<void> refreshDisk() => _measure();

  /// The chain data folder from the next start; null is the node's own `chain_data`. [origin]
  /// says whose data it is (another node's folder is never deleted). The size measured so far
  /// belonged to the old folder, so the session's growth starts again.
  Future<void> setChainDataPath(String? path, {ChainDataOrigin? origin}) async {
    final o = path == null ? ChainDataOrigin.own : (origin ?? ChainDataOrigin.moved);
    await settings.setChainDataOrigin(o);
    _origin = o;
    await setOptions(node.options.copyWith(chainDataPath: () => path));
    _chainDataBytes = null;
    _chainDataBytesAtStart = null;
    await _measure();
  }

  /// Max incoming and outgoing peers (`peer_max_inbound_count`, `peer_max_outbound_count`; the
  /// node's default is 128 each); null is the default. Applies at the next start.
  Future<void> setMaxPeers({int? inbound, int? outbound}) => setOptions(
    node.options.copyWith(maxInbound: () => inbound, maxOutbound: () => outbound),
  );

  /// Preferred peers ("ip:port"); invalid ones are left out of the toml. Applies at the next
  /// start.
  Future<void> setPreferredPeers(List<String> peers) =>
      setOptions(node.options.copyWith(preferredPeers: peers));

  /// Saves [options] and hands them to the node; a running node needs a restart to use them
  /// ([LocalNodeState.restartNeeded]).
  Future<void> setOptions(NodeTomlOptions options) async {
    await settings.saveOptions(options);
    if (_disposed) return;
    node.options = options;
    _emit();
  }

  void _onNode(BuiltInNodeState s) {
    if (_disposed) return;
    final status = s.status;
    if (status != null) {
      final p = progressOf(
        status,
        networkHeight: networkTipOf(peersHeight: _peersHeight, directoryTip: _directoryHeight),
      );
      _syncStage = p.stage;
      if (p.done != null) {
        _eta.add(_clock(), p.stage, p.done!, p.total);
      } else {
        _eta.reset();
      }
    } else if (!s.isActive) {
      _eta.reset();
      _syncEta.reset();
      _syncStage = null;
    }
    // The first answer of a node: ask for the network's height now, not a minute later.
    if (s.isActive && _directoryHeight == null && _peersHeight == null) {
      unawaited(_askNetwork());
    }
    _emit();
  }

  Future<void> _measure() async {
    if (_measuring || _disposed) return;
    _measuring = true;
    try {
      final path = node.chainDataPath;
      int? size;
      try {
        size = await _dirSize(path);
      } on Object {
        // unreadable: keep the last
      }
      int? free;
      try {
        free = await _freeBytes(await _existing(path));
      } on Object {
        // unknown
      }
      if (_disposed) return;
      if (size != null) {
        _chainDataBytes = size;
        _chainDataBytesAtStart ??= size;
      }
      _free = free ?? _free;
      _emit();
    } finally {
      _measuring = false;
    }
  }

  /// Drops the directory's tip (the status site turned off); the peers' height stays.
  void forgetDirectoryTip() {
    if (_directoryHeight == null || _disposed) return;
    _directoryHeight = null;
    _emit();
  }

  Future<void> _askNetwork() async {
    if (_asking || _disposed) return;
    _asking = true;
    try {
      Future<int?> ask(Future<int?> Function()? f) async {
        if (f == null) return null;
        try {
          return await f();
        } on Object {
          return null;
        }
      }

      final (dir, peers) = await (
        ask(directoryTip),
        ask(peersHeight),
      ).wait;
      if (_disposed) return;
      _directoryHeight = dir ?? _directoryHeight;
      _peersHeight = peers ?? _peersHeight;
      _emit();
    } finally {
      _asking = false;
    }
  }

  /// [path], or its nearest folder that exists (the chain data folder may not exist yet).
  static Future<String> _existing(String path) async {
    var dir = Directory(path);
    while (!await dir.exists()) {
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return dir.path;
  }

  Duration? _etaTotal() {
    final stage = _syncStage;
    if (stage == null) return null;
    final now = _clock();
    return _syncEta.update(now, stage, _eta.eta(now: now));
  }

  LocalNodeState _derive() => deriveLocalNodeState(
    node.state,
    now: _clock(),
    dataFolder: node.folder,
    chainDataPath: node.chainDataPath,
    directoryTip: _directoryHeight,
    peersHeight: _peersHeight,
    eta: _eta.eta(now: _clock()),
    stageRate: _eta.ratePerSecond(now: _clock()),
    etaTotal: _etaTotal(),
    chainDataBytes: _chainDataBytes,
    chainDataBytesAtStart: _chainDataBytesAtStart,
    freeBytes: _free,
    startedAt: node.startedAt,
    restartNeeded: node.restartNeeded,
    userToml: node.userToml,
    chainDataOrigin: _origin,
  );

  void _emit() {
    if (_disposed) return;
    _state = _derive();
    _out.add(_state);
  }

  /// The last [lines] lines of the node's log, reading at most [maxBytes] from its end. Empty
  /// when there is no log yet.
  Future<List<String>> logTail({
    int lines = 200,
    int maxBytes = 256 * 1024,
  }) async {
    final file = File(logPath);
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final length = await raf.length();
      final from = max(0, length - maxBytes);
      await raf.setPosition(from);
      final bytes = await raf.read(length - from);
      var all = utf8
          .decode(bytes, allowMalformed: true)
          .split('\n')
          .map((l) => l.endsWith('\r') ? l.substring(0, l.length - 1) : l)
          .toList();
      // Started mid-line: the first piece is not a whole line.
      if (from > 0 && all.isNotEmpty) all = all.sublist(1);
      if (all.isNotEmpty && all.last.isEmpty) all.removeLast();
      return all.length > lines ? all.sublist(all.length - lines) : all;
    } on FileSystemException {
      return const [];
    } finally {
      await raf?.close();
    }
  }

  /// Stops the timers and the state stream. The node keeps running (the wallet may use it).
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _diskTimer?.cancel();
    _networkTimer?.cancel();
    _diskTimer = null;
    _networkTimer = null;
    await _sub.cancel();
    await _out.close();
  }
}

/// Bytes of the files under [dir], links not followed; 0 when it does not exist.
Future<int> simpleDirSize(String dir) async {
  final d = Directory(dir);
  if (!await d.exists()) return 0;
  var total = 0;
  await for (final e in d.list(recursive: true, followLinks: false).handleError(
    (Object _) {},
  )) {
    if (e is File) {
      try {
        total += await e.length();
      } on FileSystemException {
        // gone meanwhile
      }
    }
  }
  return total;
}
