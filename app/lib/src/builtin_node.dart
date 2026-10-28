// SPDX-License-Identifier: Apache-2.0
/// The opt-in built-in Epic node of the desktop build: a bundled `epic` binary the wallet starts
/// itself, with its own folder, config and API on loopback. Off unless the user turns it on; phones
/// never have it. Pure Dart over dart:io, with the process starter, clock, port checker, disk probe
/// and node API injectable so tests need no real node.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'models.dart' show Chain;
import 'node/node_api_types.dart';

/// Settings-store key that holds whether the built-in node is on for [chain] ("true"/"false").
String builtInNodeSettingKey(Chain chain) => 'node.builtin.${chain.name}';

/// Why the built-in node is not running.
enum NodeFailure {
  binaryMissing,
  portInUse,
  diskLow,
  spawnFailed,
  exited,
  restartFailed,

  /// A node left by an earlier run holds the ports and will not stop.
  orphanStuck,
}

enum NodeStatusKind {
  off,
  starting,
  syncing,
  running,
  stalled,
  stopped,
  failed,
}

/// One state of the built-in node, as streamed by [BuiltInNode.states].
class BuiltInNodeState {
  const BuiltInNodeState(
    this.kind, {
    this.height,
    this.highest,
    this.phase,
    this.failure,
    this.reason,
    this.connections,
    this.diskUnknown = false,
    this.readyForTxs,
    this.status,
    this.version,
  });

  const BuiltInNodeState.off() : this(NodeStatusKind.off);

  final NodeStatusKind kind;

  /// The node's own tip, when it answered.
  final int? height;

  /// The highest height its peers report, while syncing.
  final int? highest;

  /// The node's sync phase (`header_sync`, `txhashset_download`, `body_sync`, ...), while syncing.
  final String? phase;

  /// The peers the node is connected to, when it said.
  final int? connections;

  /// The free disk space could not be read (a UNC or relative path on Windows), so the low-disk
  /// check is off for this node.
  final bool diskUnknown;

  /// The node's `ready_for_txs` answer: true only when it is fully synced. Null when it did not
  /// answer it (a node before 4.1.0, or no answer at all).
  final bool? readyForTxs;

  /// The last owner `get_status`, parsed: the sync stage detail. Null when the node did not give
  /// one (no secret yet) or it did not parse.
  final NodeStatusInfo? status;

  /// The node's version ("4.1.0"): foreign `get_version`, else the user agent of [status].
  final String? version;

  final NodeFailure? failure;

  /// A short reason for [NodeStatusKind.failed], in English for the log and the screen.
  final String? reason;

  bool get isActive =>
      kind == NodeStatusKind.starting ||
      kind == NodeStatusKind.syncing ||
      kind == NodeStatusKind.running ||
      kind == NodeStatusKind.stalled;

  @override
  bool operator ==(Object other) =>
      other is BuiltInNodeState &&
      other.kind == kind &&
      other.height == height &&
      other.highest == highest &&
      other.phase == phase &&
      other.failure == failure &&
      other.reason == reason &&
      other.connections == connections &&
      other.diskUnknown == diskUnknown &&
      other.readyForTxs == readyForTxs &&
      _sameStatus(other.status, status) &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    kind,
    height,
    highest,
    phase,
    failure,
    reason,
    connections,
    diskUnknown,
    readyForTxs,
    status?.syncStatus,
    status?.tip.height,
    version,
  );

  @override
  String toString() =>
      'BuiltInNodeState($kind, height: $height, highest: $highest, phase: $phase, '
      'failure: $failure, reason: $reason, connections: $connections, '
      'diskUnknown: $diskUnknown, readyForTxs: $readyForTxs, '
      'status: ${status?.syncStatus}, version: $version)';
}

/// Field by field: the parsed status has no `==` of its own, and a poll that reads the same
/// status must not count as a change.
bool _sameStatus(NodeStatusInfo? a, NodeStatusInfo? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  final x = a.syncInfo;
  final y = b.syncInfo;
  return a.syncStatus == b.syncStatus &&
      a.connections == b.connections &&
      a.protocolVersion == b.protocolVersion &&
      a.userAgent == b.userAgent &&
      a.tip.height == b.tip.height &&
      a.tip.lastBlockHash == b.tip.lastBlockHash &&
      (identical(x, y) ||
          (x != null &&
              y != null &&
              x.currentHeight == y.currentHeight &&
              x.highestHeight == y.highestHeight &&
              x.downloadedBytes == y.downloadedBytes &&
              x.totalBytes == y.totalBytes &&
              x.kernels == y.kernels &&
              x.kernelsTotal == y.kernelsTotal &&
              x.rangeProofs == y.rangeProofs &&
              x.rangeProofsTotal == y.rangeProofsTotal));
}

/// What the app may set in the node's toml; applied at the next start (the node reads its toml
/// only then). Null and empty mean "the node's default".
class NodeTomlOptions {
  const NodeTomlOptions({
    this.chainDataPath,
    this.preferredPeers = const [],
    this.maxInbound,
    this.maxOutbound,
  });

  /// Where the chain data lives; null is `<node folder>/chain_data`.
  final String? chainDataPath;

  /// `peers_preferred`: "ip:port" or "[v6]:port". Invalid entries are dropped when rendered.
  final List<String> preferredPeers;

  /// `peer_max_inbound_count`.
  final int? maxInbound;

  /// `peer_max_outbound_count`.
  final int? maxOutbound;

  NodeTomlOptions copyWith({
    String? Function()? chainDataPath,
    List<String>? preferredPeers,
    int? Function()? maxInbound,
    int? Function()? maxOutbound,
  }) => NodeTomlOptions(
    chainDataPath: chainDataPath != null ? chainDataPath() : this.chainDataPath,
    preferredPeers: preferredPeers ?? this.preferredPeers,
    maxInbound: maxInbound != null ? maxInbound() : this.maxInbound,
    maxOutbound: maxOutbound != null ? maxOutbound() : this.maxOutbound,
  );

  @override
  bool operator ==(Object other) =>
      other is NodeTomlOptions &&
      other.chainDataPath == chainDataPath &&
      other.maxInbound == maxInbound &&
      other.maxOutbound == maxOutbound &&
      _sameList(other.preferredPeers, preferredPeers);

  @override
  int get hashCode => Object.hash(
    chainDataPath,
    Object.hashAll(preferredPeers),
    maxInbound,
    maxOutbound,
  );

  @override
  String toString() =>
      'NodeTomlOptions(chainDataPath: $chainDataPath, preferredPeers: $preferredPeers, '
      'maxInbound: $maxInbound, maxOutbound: $maxOutbound)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// True for a peer address the node accepts in `peers_preferred`: "1.2.3.4:3414" or
/// "[2001:db8::1]:3414", port 1..65535. Host names are not (the node wants a socket address).
bool isPeerAddress(String addr) {
  final m = RegExp(r'^(?:\[([0-9A-Fa-f:.]+)\]|(\d{1,3}(?:\.\d{1,3}){3})):(\d{1,5})$')
      .firstMatch(addr.trim());
  if (m == null) return false;
  final port = int.parse(m[3]!);
  if (port < 1 || port > 65535) return false;
  final ip = InternetAddress.tryParse(m[1] ?? m[2]!);
  if (ip == null) return false;
  return m[1] != null
      ? ip.type == InternetAddressType.IPv6
      : ip.type == InternetAddressType.IPv4;
}

/// Thrown by [BuiltInNode.start] when it refuses to start. The node is left in
/// [NodeStatusKind.failed] with the same [failure].
class NodeStartException implements Exception {
  const NodeStartException(this.failure, this.message, {this.port});

  final NodeFailure failure;
  final String message;

  /// The API port, for [NodeFailure.portInUse].
  final int? port;

  @override
  String toString() => message;
}

/// A process the node started, as far as this class needs it.
abstract interface class NodeProcess {
  int get pid;

  Future<int> get exitCode;

  /// Last lines of its output, for a failure message.
  List<String> get tail;

  /// Asks it to stop: SIGINT on Unix, `taskkill /PID` without /F on Windows.
  void terminate();

  /// Ends it now.
  void kill();
}

typedef ProcessStarter = Future<NodeProcess> Function(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
});

/// True when something answers on 127.0.0.1:[port].
typedef PortChecker = Future<bool> Function(int port);

/// Free bytes on the volume of [directory], or null when unknown.
typedef DiskProbe = Future<int?> Function(String directory);

/// One JSON-RPC call to the node's own API on loopback. Returns the `Ok` payload, or null when the
/// node does not answer, answers an error, or refuses the secret. [owner] calls `/v2/owner` with
/// Basic auth (user `epic`, [secret]); otherwise `/v2/foreign`.
typedef NodeApi = Future<Map<String, dynamic>?> Function(
  int port,
  String method, {
  required bool owner,
  String? secret,
});

/// The ports a chain's node uses, as the Electron GUI 6.1 used them.
class NodePorts {
  const NodePorts(this.api, this.p2p, this.walletListener, this.stratum);

  factory NodePorts.of(Chain chain) {
    final base = switch (chain) {
      Chain.mainnet => 3413,
      Chain.floonet => 13413,
      Chain.usernet => 23413,
    };
    return NodePorts(base, base + 1, base + 2, base + 3);
  }

  final int api;
  final int p2p;
  final int walletListener;
  final int stratum;
}

/// The node's `epic-server.toml`, ported from the Electron GUI's resources/epic-server.toml
/// (comments dropped). `{{NAME}}` is replaced by [BuiltInNode.renderToml]; strings are quoted
/// there. `{{P2P_EXTRA}}` holds the [NodeTomlOptions] p2p lines, and is empty without them. Disables the TUI, binds the API to loopback and keeps the log in the node folder.
const String nodeTomlTemplate = '''
[server]
db_root = {{DB_ROOT}}
api_http_addr = {{API_ADDR}}
api_secret_path = {{API_SECRET}}
chain_type = {{CHAIN_TYPE}}
chain_validation_mode = "Disabled"
archive_mode = false
skip_pow_validation = true
skip_sync_wait = false
header_sync_timeout = 10
run_tui = false
run_test_miner = false

[server.p2p_config]
host = "0.0.0.0"
port = {{P2P_PORT}}
seeding_type = {{SEEDING}}
capabilities = "HEADER_HIST | TXHASHSET_HIST | PEER_LIST | TX_KERNEL_HASH | HEADER_FASTSYNC"{{P2P_EXTRA}}

[server.pool_config]
accept_fee_base = 100000
max_pool_size = 50000
max_stempool_size = 50000
mineable_max_weight = 40000

[server.dandelion_config]
epoch_secs = 600
embargo_secs = 180
aggregation_secs = 30
stem_probability = 90
always_stem_our_txs = true

[server.stratum_mining_config]
enable_stratum_server = false
stratum_server_addr = {{STRATUM_ADDR}}
attempt_time_per_block = 15
cuckatoo_minimum_share_difficulty = 3
randomx_minimum_share_difficulty = 4000
progpow_minimum_share_difficulty = 200000
wallet_listener_url = {{WALLET_LISTENER}}
burn_reward = false

[server.webhook_config]
nthreads = 4
timeout = 10

[logging]
log_to_stdout = true
stdout_log_level = "Info"
log_to_file = true
file_log_level = "Info"
log_file_path = {{LOG_FILE}}
log_file_append = true
log_max_size = 5242880
log_max_files = 3
''';

const String _tomlName = 'epic-server.toml';
const String _tomlHashName = 'epic-server.toml.sha256';
const String _secretName = '.api_secret';
const String _pidName = 'node.pid';

/// Sync phases in which a node is working even when its height stands still: never restarted.
/// The same list as the Electron GUI's nodeService.js (safeSyncStates).
const Set<String> safeSyncStates = {
  'txhashset_download',
  'syncing',
  'txhashset_rangeproofs_validation',
  'txhashset_kernels_validation',
};

/// What the node needs to know about, and do to, a process it did not start: a node left over by
/// a crashed or closed app. Injectable so tests need no real processes.
abstract interface class ProcessInspector {
  /// True when a process with [pid] runs.
  Future<bool> isAlive(int pid);

  /// Absolute path of the executable of [pid], or null when it cannot be told.
  Future<String?> executable(int pid);

  /// The command line of [pid]: one element per argument where the OS gives them separately
  /// (Linux), else one element holding the whole line. Null when it cannot be told.
  Future<List<String>?> commandLine(int pid);

  /// Asks [pid] to stop: SIGINT on Unix, `taskkill /PID` without /F on Windows.
  void terminate(int pid);

  /// Ends [pid] now (SIGKILL; TerminateProcess on Windows).
  void kill(int pid);
}

/// Thrown inside a launch that [BuiltInNode.stop] has overtaken.
class _LaunchCancelled implements Exception {
  const _LaunchCancelled();
}

final Set<BuiltInNode> _liveNodes = {};

/// Stops every built-in node this process started and waits until they have exited. For the
/// desktop shell's exit hook (`AppLifecycleListener(onExitRequested: ...)`): a node left running
/// by a closing app is only found again by the next start's pid-file check.
Future<void> stopAllBuiltInNodes() async {
  await Future.wait([for (final n in _liveNodes.toList()) n.stop()]);
}

class BuiltInNode {
  BuiltInNode({
    required this.root,
    required this.binary,
    required this.chain,
    this.minFreeBytes = 5 * 1024 * 1024 * 1024,
    this.pollInterval = const Duration(seconds: 5),
    this.maxPollInterval = const Duration(seconds: 30),
    this.stallAfter = const Duration(minutes: 3),
    this.diskCheckEvery = const Duration(minutes: 5),
    this.killAfter = const Duration(seconds: 15),
    this.killWait = const Duration(seconds: 5),
    this.exitPoll = const Duration(milliseconds: 100),
    this.autoPoll = true,
    ProcessStarter? startProcess,
    DateTime Function()? clock,
    PortChecker? portInUse,
    DiskProbe? freeBytes,
    NodeApi? api,
    ProcessInspector? inspector,
    void Function(String message)? log,
    bool? isWindows,
  }) : _start = startProcess ?? _startRealProcess,
       _clock = clock ?? DateTime.now,
       _portInUse = portInUse ?? _realPortInUse,
       _freeBytes = freeBytes ?? realFreeBytes,
       _api = api ?? _realApi,
       _windows = isWindows ?? Platform.isWindows,
       _inspector =
           inspector ?? _RealInspector(isWindows ?? Platform.isWindows),
       _log = log ?? ((m) => stderr.writeln('[node] $m'));

  /// `<app support>/node`; the chain's folder is below it.
  final String root;

  /// Path to the bundled `epic` executable.
  final String binary;

  final Chain chain;

  /// The node is refused, or stopped, when the volume holds less than this.
  final int minFreeBytes;
  final Duration pollInterval;
  final Duration maxPollInterval;

  /// How long a restart condition must hold (or the node stay silent) before the node is restarted.
  final Duration stallAfter;

  /// How often the free disk space is probed while running. On Windows each probe is a PowerShell
  /// process, which is why it is not frequent.
  final Duration diskCheckEvery;

  /// How long a polite stop is given before the process is killed. On Windows at most 10 s:
  /// `taskkill /PID` without /F is sent once, then the process is terminated (LMDB, the node's
  /// store, recovers from that).
  final Duration killAfter;

  /// How long to wait for the exit after a kill.
  final Duration killWait;

  /// How often an exit is looked for while waiting for one.
  final Duration exitPoll;

  /// Poll on a timer after [start]. Tests turn it off and call [poll].
  final bool autoPoll;

  final ProcessStarter _start;
  final DateTime Function() _clock;
  final PortChecker _portInUse;
  final DiskProbe _freeBytes;
  final NodeApi _api;
  final bool _windows;
  final ProcessInspector _inspector;
  final void Function(String) _log;

  final StreamController<BuiltInNodeState> _controller =
      StreamController<BuiltInNodeState>.broadcast();
  BuiltInNodeState _state = const BuiltInNodeState.off();

  NodeProcess? _process;
  Timer? _timer;
  bool _stopping = false;
  bool _polling = false;
  bool _restarted = false;

  /// The launch (or watchdog restart) in flight, which [start] returns and [stop] awaits.
  Future<void>? _launching;

  /// Cleared by [stop]; a launch that finds it cleared kills what it spawned.
  bool _wantRunning = false;

  /// False once [stop] was asked for, even while a start it cancels is still unwinding.
  bool get wantsRunning => _wantRunning;

  /// Bumped by every [start] and [stop]; a launch of an older generation is cancelled.
  int _gen = 0;
  int _failures = 0;
  DateTime? _badSince;
  DateTime? _lastAnswer;
  DateTime? _lastDiskCheck;
  String? _secret;
  bool _diskUnknown = false;
  bool _diskUnknownLogged = false;
  late int _apiPort = NodePorts.of(chain).api;
  late int _p2pPort = NodePorts.of(chain).p2p;

  /// What the app wants in the toml; a change applies at the next start (see [restartNeeded]).
  NodeTomlOptions options = const NodeTomlOptions();

  NodeTomlOptions? _applied;
  bool _userToml = false;
  String? _userDbRoot;
  DateTime? _startedAt;
  String? _version;
  Future<void>? _restarting;
  int _stopCalls = 0;
  bool _disposed = false;

  /// The options the running process was started with; null while none runs.
  NodeTomlOptions? get appliedOptions => _process == null ? null : _applied;

  /// The node runs with other [options] than the current ones: they apply after [restart]. Never
  /// with the user's own toml, which no option changes.
  bool get restartNeeded =>
      _process != null && _wantRunning && !_userToml && options != _applied;

  /// The toml in the folder is the user's own (edited by hand): kept as it is, so [options] do
  /// not apply. Known once the folder was prepared (at the first start).
  bool get userToml => _userToml;

  /// When the running process was spawned (a watchdog restart or [restart] spawns a new one);
  /// null while none runs.
  DateTime? get startedAt => _process == null ? null : _startedAt;

  /// True after [dispose]: the state stream is closed.
  bool get isDisposed => _disposed;

  NodePorts get ports => NodePorts.of(chain);

  /// The node's API on loopback, for the wallet's node setting. LEPIC accepts plain http on
  /// loopback only, which is where this is. Follows the port of a toml the user edited.
  String get url => 'http://127.0.0.1:$_apiPort';

  String get folderName => switch (chain) {
    Chain.mainnet => 'main',
    Chain.floonet => 'floo',
    Chain.usernet => 'user',
  };

  String get folder => _join(root, folderName);
  String get tomlPath => _join(folder, _tomlName);

  /// The chain data folder: the `db_root` of the user's own toml, else [options]'
  /// `chainDataPath`, else `<folder>/chain_data`. Follows [options] at once, also while the
  /// node still runs on the old one ([appliedOptions]).
  String get chainDataPath =>
      _userToml && _userDbRoot != null ? _userDbRoot! : _dbRoot(options);

  String _dbRoot(NodeTomlOptions o) {
    final custom = o.chainDataPath;
    return custom != null && custom.trim().isNotEmpty
        ? custom
        : _join(folder, 'chain_data');
  }

  String get logPath => _join(folder, 'epic-server.log');

  /// The node's API secret file (owner API, Basic auth `epic:<secret>`).
  String get secretPath => _join(folder, _secretName);

  /// The pid of the node this object started and still runs, else null.
  int? get pid => _process?.pid;

  BuiltInNodeState get state => _state;

  /// Every state change, after which [state] is the new one.
  Stream<BuiltInNodeState> get states => _controller.stream;

  String _join(String dir, String name) =>
      dir.endsWith(Platform.pathSeparator) || dir.endsWith('/')
      ? '$dir$name'
      : '$dir${Platform.pathSeparator}$name';

  void _set(BuiltInNodeState s) {
    if (s == _state) return;
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  /// The toml for this chain with the folder's absolute paths. `foundation_path` is left out: the
  /// node then uses the foundation data built into the binary (the GUI shipped a foundation.json
  /// next to it; this build ships none, and a path to a missing file is wrong).
  String renderToml() => _render(options);

  String _render(NodeTomlOptions o) {
    final p = ports;
    final values = <String, String>{
      'DB_ROOT': _q(_dbRoot(o)),
      'API_ADDR': _q('127.0.0.1:${p.api}'),
      'API_SECRET': _q(secretPath),
      'CHAIN_TYPE': _q(switch (chain) {
        Chain.mainnet => 'Mainnet',
        Chain.floonet => 'Floonet',
        Chain.usernet => 'UserTesting',
      }),
      'P2P_PORT': '${p.p2p}',
      'SEEDING': _q(chain == Chain.usernet ? 'None' : 'DNSSeed'),
      'STRATUM_ADDR': _q('127.0.0.1:${p.stratum}'),
      'WALLET_LISTENER': _q('http://127.0.0.1:${p.walletListener}'),
      'LOG_FILE': _q(logPath),
      'P2P_EXTRA': _p2pExtra(o),
    };
    return nodeTomlTemplate.replaceAllMapped(
      RegExp(r'\{\{([A-Z0-9_]+)\}\}'),
      (m) => values[m[1]!] ?? m[0]!,
    );
  }

  /// The [options] lines of `[server.p2p_config]`, each starting with a newline; empty without
  /// options, so the default toml stays as it always was.
  String _p2pExtra(NodeTomlOptions o) {
    final peers = <String>[];
    for (final raw in o.preferredPeers) {
      final addr = raw.trim();
      if (isPeerAddress(addr)) {
        if (!peers.contains(addr)) peers.add(addr);
      } else {
        _log('preferred peer "$raw" is not ip:port; left out');
      }
    }
    final b = StringBuffer();
    if (peers.isNotEmpty) {
      b.write('\npeers_preferred = [${peers.map(_q).join(', ')}]');
    }
    if (o.maxInbound case final n? when n >= 0) {
      b.write('\npeer_max_inbound_count = $n');
    }
    if (o.maxOutbound case final n? when n >= 0) {
      b.write('\npeer_max_outbound_count = $n');
    }
    return b.toString();
  }

  static String _q(String s) => jsonEncode(s);

  static String _hash(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  /// Creates the folder (owner only on Unix), the toml and the API secret. The toml is rewritten
  /// (atomically) only when it is still what this class wrote; a toml the user edited is kept as
  /// it is. Returns true when the user's own toml is in use.
  ///
  /// The hash file lists every text this class may have written: before the toml is replaced the
  /// new hash is added to it, after that the old one is dropped. A crash in between leaves a toml
  /// that is still recognised as ours.
  Future<bool> prepareFolder() => _prepare(options);

  Future<bool> _prepare(NodeTomlOptions o) async {
    await Directory(folder).create(recursive: true);
    await _chmod('700', folder);
    final toml = File(tomlPath);
    final hashFile = File(_join(folder, _tomlHashName));
    final wanted = _render(o);
    var userEdited = false;
    if (await toml.exists()) {
      final current = await toml.readAsString();
      final written = await hashFile.exists()
          ? (await hashFile.readAsString())
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toSet()
          : <String>{};
      if (!written.contains(_hash(current))) {
        userEdited = true;
      } else if (current != wanted) {
        await _writeAtomic(hashFile, '${_hash(current)}\n${_hash(wanted)}\n');
        await _writeAtomic(toml, wanted);
        await _writeAtomic(hashFile, _hash(wanted));
      } else if (written.length != 1) {
        await _writeAtomic(hashFile, _hash(wanted));
      }
    } else {
      await _writeAtomic(hashFile, _hash(wanted));
      await _writeAtomic(toml, wanted);
    }
    final secret = File(secretPath);
    if (!await secret.exists()) {
      await _writeAtomic(secret, _randomSecret(), mode: '600');
    }
    await _readPorts();
    _userToml = userEdited;
    return userEdited;
  }

  /// The API and P2P ports of the toml in use (a user's toml may move them).
  Future<void> _readPorts() async {
    final defaults = ports;
    _apiPort = defaults.api;
    _p2pPort = defaults.p2p;
    _userDbRoot = null;
    try {
      final text = await File(tomlPath).readAsString();
      final db = RegExp(
        r'''^\s*db_root\s*=\s*("(?:[^"\\]|\\.)*"|'[^']*')''',
        multiLine: true,
      ).firstMatch(text);
      if (db != null) {
        final v = db[1]!;
        try {
          _userDbRoot = v.startsWith("'")
              ? v.substring(1, v.length - 1)
              : jsonDecode(v) as String;
        } on Object {
          // a TOML escape JSON does not know: not followed
        }
      }
      final api = RegExp(
        r'^\s*api_http_addr\s*=\s*"[^"]*:(\d+)"',
        multiLine: true,
      ).firstMatch(text);
      if (api != null) _apiPort = int.parse(api[1]!);
      final p2p = text.indexOf('[server.p2p_config]');
      if (p2p >= 0) {
        final m = RegExp(
          r'^\s*port\s*=\s*(\d+)',
          multiLine: true,
        ).firstMatch(text.substring(p2p));
        if (m != null) _p2pPort = int.parse(m[1]!);
      }
    } on Object {
      // unreadable or odd: the defaults
    }
  }

  Future<void> _chmod(String mode, String path) async {
    if (_windows) return;
    try {
      await Process.run('chmod', [mode, path]);
    } on Object {
      // best effort: the folder is the user's own
    }
  }

  Future<void> _writeAtomic(File file, String text, {String? mode}) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    if (mode != null) await _chmod(mode, tmp.path);
    await tmp.rename(file.path);
  }

  static String _randomSecret() {
    const abc =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return String.fromCharCodes(
      List.generate(20, (_) => abc.codeUnitAt(r.nextInt(abc.length))),
    );
  }

  /// Starts the node. While a start is pending, calls return that same start. Throws
  /// [NodeStartException] when the binary is missing, a port is already answering (another node: it
  /// is left alone) or the disk is under the floor. A [stop] that overtakes the start ends it
  /// quietly with nothing left running.
  Future<void> start() {
    final pending = _launching;
    if (pending != null && _wantRunning) return pending;
    if (_process != null && _wantRunning) return Future.value();
    _liveNodes.add(this);
    _wantRunning = true;
    final gen = ++_gen;
    _restarted = false;
    return _track(() async {
      if (pending != null) {
        try {
          await pending;
        } on Object {
          // the cancelled launch is over either way
        }
      }
      await _launch(gen);
    });
  }

  Future<void> _track(Future<void> Function() body) {
    late final Future<void> f;
    f = body().whenComplete(() {
      if (identical(_launching, f)) _launching = null;
    });
    _launching = f;
    return f;
  }

  bool _cancelled(int gen) => gen != _gen || !_wantRunning;

  void _check(int gen) {
    if (_cancelled(gen)) throw const _LaunchCancelled();
  }

  Future<void> _launch(int gen) async {
    _set(const BuiltInNodeState(NodeStatusKind.starting));
    try {
      await _launchSteps(gen);
    } on _LaunchCancelled {
      return;
    } on NodeStartException catch (e) {
      if (_cancelled(gen)) return;
      _set(
        BuiltInNodeState(
          NodeStatusKind.failed,
          failure: e.failure,
          reason: e.message,
        ),
      );
      rethrow;
    }
  }

  Future<void> _launchSteps(int gen) async {
    final exists = await File(binary).exists();
    _check(gen);
    if (!exists) {
      throw NodeStartException(
        NodeFailure.binaryMissing,
        'The built-in node is missing: $binary',
      );
    }
    final applying = options;
    await _prepare(applying);
    _check(gen);
    await _reclaimOrphan(gen);
    for (final port in [_apiPort, _p2pPort]) {
      final busy = await _portInUse(port);
      _check(gen);
      if (busy) {
        throw NodeStartException(
          NodeFailure.portInUse,
          'Port $port in use',
          port: port,
        );
      }
    }
    final free = await _freeBytes(folder);
    _check(gen);
    _noteDisk(free);
    if (free != null && free < minFreeBytes) {
      throw NodeStartException(NodeFailure.diskLow, _lowDiskMessage(free));
    }
    final args = [
      if (chain != Chain.mainnet) '--${chain.name}',
      'server',
      '--config_file',
      tomlPath,
      'run',
    ];
    final NodeProcess process;
    try {
      process = await _start(binary, args, workingDirectory: folder);
    } on Object catch (e) {
      throw NodeStartException(
        NodeFailure.spawnFailed,
        'The built-in node did not start: $e',
      );
    }
    if (_cancelled(gen)) {
      // stop() came while it was spawning: leave nothing running
      await _terminate(process);
      throw const _LaunchCancelled();
    }
    _stopping = false;
    _process = process;
    _applied = applying;
    _failures = 0;
    _badSince = null;
    final now = _clock();
    _startedAt = now;
    _version = null;
    _lastAnswer = now;
    _lastDiskCheck = now;
    _secret = null;
    try {
      await _writeAtomic(File(_join(folder, _pidName)), '${process.pid}\n');
    } on Object {
      // without it a leftover node is only found by its port
    }
    unawaited(process.exitCode.then((code) => _onExit(process, code)));
    if (autoPoll) _schedule();
  }

  /// Free space unknown (a UNC or relative path on Windows): the node starts anyway, the state
  /// says so and it is logged once.
  void _noteDisk(int? free) {
    _diskUnknown = free == null;
    if (_diskUnknown && !_diskUnknownLogged) {
      _diskUnknownLogged = true;
      _log('free disk space of $folder is unknown; the low-disk check is off');
    }
  }

  // -- a node left over by an earlier run ----------------------------------------------------

  /// Reads node.pid. A pid that is alive and is our binary running our toml is an orphan of an
  /// earlier run: it is stopped (politely, then killed after re-checking it is still the same
  /// process), so that the start is not blocked by it. Any other pid is not ours: only the stale
  /// pid file goes.
  Future<void> _reclaimOrphan(int gen) async {
    final file = File(_join(folder, _pidName));
    int? orphan;
    try {
      orphan = int.tryParse((await file.readAsString()).trim());
    } on Object {
      return;
    }
    _check(gen);
    if (orphan == null || orphan <= 0) {
      await _deleteQuietly(file);
      return;
    }
    if (orphan == _process?.pid || !await _inspector.isAlive(orphan)) {
      await _deleteQuietly(file);
      return;
    }
    if (!await _isOurs(orphan)) {
      // someone else's process under a reused pid: touch nothing but the stale file
      await _deleteQuietly(file);
      return;
    }
    _log('stopping a built-in node left by an earlier run (pid $orphan)');
    _inspector.terminate(orphan);
    var gone = await _waitGone(orphan, _grace);
    _check(gen);
    if (!gone) {
      if (!await _isOurs(orphan)) {
        // it exited and its pid was reused meanwhile
        await _deleteQuietly(file);
        return;
      }
      _inspector.kill(orphan);
      gone = await _waitGone(orphan, killWait);
      _check(gen);
    }
    if (!gone) {
      throw NodeStartException(
        NodeFailure.orphanStuck,
        'A built-in node left by an earlier run (pid $orphan) will not stop',
      );
    }
    await _deleteQuietly(file);
  }

  Duration get _grace => _windows && killAfter > const Duration(seconds: 10)
      ? const Duration(seconds: 10)
      : killAfter;

  Future<bool> _waitGone(int pid, Duration limit) async {
    final until = DateTime.now().add(limit);
    while (true) {
      if (!await _inspector.isAlive(pid)) return true;
      if (!DateTime.now().isBefore(until)) return false;
      await Future<void>.delayed(exitPoll);
    }
  }

  Future<bool> _isOurs(int pid) async {
    final exe = await _inspector.executable(pid);
    // The same binary, or one of the same name: an AppImage mounts at a new /tmp/.mount_*
    // each run, so the node an earlier run left is the same program at another path. The
    // command line below, naming this node's own toml, is what makes it ours.
    if (exe == null || !(_sameFile(exe, binary) || _sameName(exe, binary))) return false;
    final cmd = await _inspector.commandLine(pid);
    if (cmd == null) return false;
    final tokens = cmd.expand((a) => a.split(RegExp(r'\s+'))).toSet();
    if (!tokens.contains('server') || !tokens.contains('run')) return false;
    final joined = cmd.join(' ');
    return joined.contains('--config_file $tomlPath') ||
        joined.contains('--config_file "$tomlPath"');
  }

  bool _sameFile(String a, String b) {
    String norm(String p) {
      var s = p;
      try {
        s = File(p).resolveSymbolicLinksSync();
      } on Object {
        // as given
      }
      if (_windows) s = s.replaceAll('/', r'\').toLowerCase();
      return s;
    }

    return a == b || norm(a) == norm(b);
  }

  bool _sameName(String a, String b) {
    String name(String p) {
      var s = p.replaceAll(r'\', '/');
      if (s.endsWith(' (deleted)')) s = s.substring(0, s.length - ' (deleted)'.length);
      s = s.substring(s.lastIndexOf('/') + 1);
      return _windows ? s.toLowerCase() : s;
    }

    return name(a) == name(b);
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      await f.delete();
    } on Object {
      // already gone
    }
  }

  String _lowDiskMessage(int free) =>
      'Not enough free disk space: ${_gb(free)} GB free, ${_gb(minFreeBytes)} GB needed';

  static String _gb(int bytes) =>
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

  void _onExit(NodeProcess process, int code) {
    if (!identical(_process, process) || _stopping) return;
    _process = null;
    _timer?.cancel();
    unawaited(_deleteQuietly(File(_join(folder, _pidName))));
    final tail = process.tail.isEmpty ? '' : ': ${process.tail.last}';
    _set(
      BuiltInNodeState(
        NodeStatusKind.failed,
        failure: NodeFailure.exited,
        reason: 'The built-in node exited with code $code$tail',
      ),
    );
  }

  /// The delay before the next poll: [pollInterval], doubling (up to [maxPollInterval]) while the
  /// node does not answer.
  Duration get nextPollDelay => Duration(
    milliseconds: min(
      pollInterval.inMilliseconds * (1 << min(_failures, 6)),
      maxPollInterval.inMilliseconds,
    ),
  );

  void _schedule() {
    _timer?.cancel();
    if (_process == null || _stopping) return;
    _timer = Timer(nextPollDelay, () async {
      await poll();
      if (autoPoll) _schedule();
    });
  }

  BuiltInNodeState _running(
    NodeStatusKind kind, {
    int? height,
    int? highest,
    String? phase,
    int? connections,
    _Reading? reading,
  }) => BuiltInNodeState(
    kind,
    height: height,
    highest: highest,
    phase: phase,
    connections: connections,
    diskUnknown: _diskUnknown,
    readyForTxs: reading?.readyForTxs,
    status: reading?.status,
    version: _version,
  );

  /// One status check: the disk floor, the node's API, the stall watchdog. The timer calls it
  /// every [pollInterval] while the node runs.
  Future<void> poll() async {
    final process = _process;
    if (process == null || _stopping || _polling) return;
    _polling = true;
    try {
      final now = _clock();
      if (_lastDiskCheck == null ||
          now.difference(_lastDiskCheck!) >= diskCheckEvery) {
        _lastDiskCheck = now;
        final free = await _freeBytes(folder);
        _noteDisk(free);
        if (!identical(_process, process) || _stopping) return;
        if (free != null && free < minFreeBytes) {
          await _stopProcess();
          _set(
            BuiltInNodeState(
              NodeStatusKind.failed,
              failure: NodeFailure.diskLow,
              reason: _lowDiskMessage(free),
            ),
          );
          return;
        }
      }
      final reading = await _read();
      if (!identical(_process, process) || _stopping) return;
      final at = _clock();
      if (reading == null) {
        _failures++;
        if (at.difference(_lastAnswer!) >= stallAfter) await _stalled();
        return;
      }
      _failures = 0;
      _lastAnswer = at;
      if (reading.wantsRestart) {
        _badSince ??= at;
        if (at.difference(_badSince!) >= stallAfter) {
          await _stalled();
          return;
        }
      } else {
        _badSince = null;
      }
      // ready_for_txs decides when the node says it; an older node (null) is judged by its
      // sync status as before.
      final synced = reading.readyForTxs ?? reading.phase == 'no_sync';
      _set(
        synced
            ? _running(
                NodeStatusKind.running,
                height: reading.height,
                connections: reading.connections,
                reading: reading,
              )
            : _running(
                NodeStatusKind.syncing,
                height: reading.height,
                highest: reading.highest,
                phase: reading.phase,
                connections: reading.connections,
                reading: reading,
              ),
      );
    } finally {
      _polling = false;
    }
  }

  /// A stalled node is restarted once per [start]; the second time it is only reported. The
  /// restart is the pending launch, so [stop] and [dispose] wait for it.
  Future<void> _stalled() {
    if (_restarted) {
      _set(_running(NodeStatusKind.stalled, height: _state.height));
      return Future.value();
    }
    _restarted = true;
    final gen = _gen;
    return _track(() async {
      await _stopProcess();
      if (_cancelled(gen)) return;
      try {
        await _launch(gen);
      } on NodeStartException catch (e) {
        _set(
          BuiltInNodeState(
            NodeStatusKind.failed,
            failure: NodeFailure.restartFailed,
            reason: 'Restarting the built-in node failed: ${e.message}',
          ),
        );
      }
    });
  }

  /// Foreign `ready_for_txs` first (readiness), owner `get_status` for the sync detail and the
  /// watchdog, foreign `get_tip` when there is no status; `get_version` once per process.
  Future<_Reading?> _read() async {
    final port = _apiPort;
    final ready = _parsed(
      await _api(port, 'ready_for_txs', owner: false),
      parseReadyForTxs,
    );
    _secret ??= await readSecret();
    _Reading? reading;
    if (_secret != null) {
      final s = await _api(port, 'get_status', owner: true, secret: _secret);
      if (s != null) {
        final info = s['sync_info'];
        final tip = s['tip'];
        final current = _int(info is Map ? info['current_height'] : null);
        final height = _int(tip is Map ? tip['height'] : null) ?? current ?? 0;
        reading = _Reading(
          height,
          _int(info is Map ? info['highest_height'] : null),
          s['sync_status'] as String?,
          connections: _int(s['connections']),
          currentHeight: current,
          readyForTxs: ready,
          status: _parsed(s, parseStatus),
        );
      }
    }
    if (reading == null) {
      final tip = await _api(port, 'get_tip', owner: false);
      if (tip == null && ready == null) return null;
      reading = _Reading(
        _int(tip?['height']) ?? 0,
        null,
        null,
        readyForTxs: ready,
      );
    }
    _version ??=
        _parsed(
          await _api(port, 'get_version', owner: false),
          parseVersion,
        )?.nodeVersion ??
        reading.status?.version;
    return reading;
  }

  /// [parse] of an `Ok` payload, or null when there is none or it has another shape.
  static T? _parsed<T>(Map<String, dynamic>? ok, T Function(Object?) parse) {
    if (ok == null) return null;
    try {
      return parse(ok);
    } on NodeRpcException {
      return null;
    }
  }

  static int? _int(Object? v) => v is num ? v.toInt() : null;

  /// The node's API secret ([secretPath], first line), or null while there is none. For the
  /// owner API (peers); never logged.
  Future<String?> readSecret() async {
    try {
      final text = (await File(secretPath).readAsString()).trim();
      final line = text.split(RegExp(r'\r?\n')).first.trim();
      return line.isEmpty ? null : line;
    } on Object {
      return null;
    }
  }

  /// Stops the node this object started: waits for a start or restart in flight (a process it
  /// spawned is stopped), asks the node to stop, kills it after [killAfter]. Never touches any
  /// other process, and does nothing when this object started none.
  Future<void> stop() {
    _stopCalls++;
    return _stop();
  }

  /// Stops the node, then starts it again (with the current [options]). Restarts asked for while
  /// one is in flight join it. A [stop] that comes during the restart wins: nothing is started
  /// after it, and a start already under way is cancelled as by any stop. Throws as [start].
  Future<void> restart() {
    final pending = _restarting;
    if (pending != null) return pending;
    late final Future<void> f;
    f = () async {
      final stops = _stopCalls;
      await _stop();
      if (_stopCalls != stops || _disposed) return;
      await start();
    }().whenComplete(() {
      if (identical(_restarting, f)) _restarting = null;
    });
    return _restarting = f;
  }

  Future<void> _stop() async {
    _wantRunning = false;
    _gen++;
    _timer?.cancel();
    final pending = _launching;
    if (pending != null) {
      try {
        await pending;
      } on Object {
        // a failed start has nothing to stop
      }
    }
    if (_process == null) {
      if (_state.isActive) _set(const BuiltInNodeState(NodeStatusKind.stopped));
      return;
    }
    await _stopProcess();
    _set(const BuiltInNodeState(NodeStatusKind.stopped));
  }

  /// Stops [_process] and removes the pid file once the exit is confirmed.
  Future<void> _stopProcess() async {
    final process = _process;
    _timer?.cancel();
    if (process == null) return;
    _stopping = true;
    _process = null;
    final exited = await _terminate(process);
    if (exited) {
      await _deleteQuietly(File(_join(folder, _pidName)));
    } else {
      _log('the built-in node (pid ${process.pid}) did not exit after a kill');
    }
    _stopping = false;
  }

  /// Polite stop, then (after [killAfter], at most 10 s on Windows) a kill; waits [killWait] for
  /// the exit. True when the process is confirmed gone.
  Future<bool> _terminate(NodeProcess process) async {
    var exited = false;
    try {
      process.terminate();
      await process.exitCode.timeout(_grace);
      exited = true;
    } on TimeoutException {
      // fall through to the kill
    } on Object {
      // fall through to the kill
    }
    if (exited) return true;
    try {
      process.kill();
      await process.exitCode.timeout(killWait);
      return true;
    } on Object {
      return false;
    }
  }

  /// Stops the node and closes the state stream. For app exit.
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    _liveNodes.remove(this);
    await _controller.close();
  }
}

class _Reading {
  const _Reading(
    this.height,
    this.highest,
    this.phase, {
    this.connections,
    this.currentHeight,
    this.readyForTxs,
    this.status,
  });

  final int height;
  final int? highest;
  final String? phase;
  final int? connections;
  final int? currentHeight;
  final bool? readyForTxs;
  final NodeStatusInfo? status;

  /// The Electron GUI's watchdog rules (nodeService.js, watchdog()). Never in a safe sync state;
  /// else: no peers outside awaiting_peers, synced with tip 0, no highest height outside
  /// awaiting_peers, or body_sync at the tip that does not finish. A height that stands still
  /// (header sync keeps the tip at 0 for a long time) is not a reason by itself.
  bool get wantsRestart {
    final p = phase;
    if (p == null || safeSyncStates.contains(p)) return false;
    if (connections == 0 && p != 'awaiting_peers') return true;
    if (p == 'no_sync' && height == 0) return true;
    if (highest == 0 && p != 'awaiting_peers') return true;
    if (p == 'body_sync' &&
        currentHeight != null &&
        height == currentHeight &&
        highest == currentHeight) {
      return true;
    }
    return false;
  }
}

// -- the real implementations ------------------------------------------------------------------

class _RealInspector implements ProcessInspector {
  _RealInspector(this._windows);

  final bool _windows;

  /// ExecutablePath and CommandLine of [pid] (one per line), or null when it does not run.
  Future<List<String>?> _win(int pid) async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-Command',
        '\$p = Get-CimInstance Win32_Process -Filter "ProcessId=$pid"; '
            'if (\$p) { \$p.ExecutablePath; \$p.CommandLine }',
      ]);
      final lines = (r.stdout as String)
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      return lines.isEmpty ? null : lines;
    } on Object {
      return null;
    }
  }

  Future<bool> _psOk(int pid) async {
    try {
      return (await Process.run('ps', ['-p', '$pid'])).exitCode == 0;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> isAlive(int pid) async {
    if (_windows) return await _win(pid) != null;
    if (Platform.isLinux) return Directory('/proc/$pid').exists();
    return _psOk(pid);
  }

  @override
  Future<String?> executable(int pid) async {
    try {
      if (_windows) return (await _win(pid))?.first.trim();
      if (Platform.isLinux) {
        // A binary whose file or mount is gone (an earlier AppImage run) keeps its path.
        final t = await Link('/proc/$pid/exe').target();
        return t.endsWith(' (deleted)') ? t.substring(0, t.length - ' (deleted)'.length) : t;
      }
      final r = await Process.run('ps', ['-o', 'comm=', '-p', '$pid']);
      final out = (r.stdout as String).trim();
      return r.exitCode == 0 && out.isNotEmpty ? out : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<List<String>?> commandLine(int pid) async {
    try {
      if (_windows) {
        final l = await _win(pid);
        return l != null && l.length > 1 ? [l[1].trim()] : null;
      }
      if (Platform.isLinux) {
        final bytes = await File('/proc/$pid/cmdline').readAsBytes();
        return utf8
            .decode(bytes, allowMalformed: true)
            .split('\u0000')
            .where((a) => a.isNotEmpty)
            .toList();
      }
      final r = await Process.run('ps', [
        '-ww',
        '-o',
        'command=',
        '-p',
        '$pid',
      ]);
      final out = (r.stdout as String).trim();
      return r.exitCode == 0 && out.isNotEmpty ? [out] : null;
    } on Object {
      return null;
    }
  }

  @override
  void terminate(int pid) {
    if (_windows) {
      // Without /F: asks the process to close, as Ctrl+C would. Sent once.
      Process.run('taskkill', ['/PID', '$pid']);
    } else {
      Process.killPid(pid, ProcessSignal.sigint);
    }
  }

  @override
  void kill(int pid) {
    // TerminateProcess on Windows, SIGKILL elsewhere
    Process.killPid(pid, ProcessSignal.sigkill);
  }
}

class _IoNodeProcess implements NodeProcess {
  _IoNodeProcess(this._process, this._windows) {
    void collect(Stream<List<int>> s) => s
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          tail.add(line);
          if (tail.length > 20) tail.removeAt(0);
        }, onError: (_) {});
    collect(_process.stdout);
    collect(_process.stderr);
  }

  final Process _process;
  final bool _windows;

  @override
  final List<String> tail = [];

  @override
  int get pid => _process.pid;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  void terminate() {
    if (_windows) {
      // Without /F: asks the process to close, as Ctrl+C would.
      Process.run('taskkill', ['/PID', '$pid']);
    } else {
      Process.killPid(pid, ProcessSignal.sigint);
    }
  }

  @override
  void kill() {
    // TerminateProcess on Windows, SIGKILL elsewhere
    _process.kill(ProcessSignal.sigkill);
  }
}

Future<NodeProcess> _startRealProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  return _IoNodeProcess(process, Platform.isWindows);
}

Future<bool> _realPortInUse(int port) async {
  try {
    final s = await Socket.connect(
      InternetAddress.loopbackIPv4,
      port,
      timeout: const Duration(seconds: 1),
    );
    s.destroy();
    return true;
  } on Object {
    return false;
  }
}

/// Free bytes on the volume of [directory] (`df` on Unix, the drive via PowerShell on Windows),
/// or null when it cannot be told: the default [DiskProbe].
Future<int?> realFreeBytes(String directory) async {
  try {
    if (Platform.isWindows) {
      final drive = directory.length > 1 && directory[1] == ':'
          ? directory[0]
          : null;
      if (drive == null) return null;
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-Command',
        '(Get-PSDrive -Name $drive).Free',
      ]);
      return int.tryParse((r.stdout as String).trim());
    }
    final r = await Process.run('df', ['-Pk', directory]);
    if (r.exitCode != 0) return null;
    final lines = (r.stdout as String).trim().split('\n');
    if (lines.length < 2) return null;
    final cols = lines.last.trim().split(RegExp(r'\s+'));
    final kb = int.tryParse(cols.length > 3 ? cols[3] : '');
    return kb == null ? null : kb * 1024;
  } on Object {
    return null;
  }
}

Future<Map<String, dynamic>?> _realApi(
  int port,
  String method, {
  required bool owner,
  String? secret,
}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3)
    ..userAgent = null;
  try {
    final request = await client
        .postUrl(
          Uri.parse('http://127.0.0.1:$port/v2/${owner ? 'owner' : 'foreign'}'),
        )
        .timeout(const Duration(seconds: 5));
    request.headers.contentType = ContentType.json;
    request.followRedirects = false; // never carry the secret elsewhere
    if (owner && secret != null) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Basic ${base64.encode(utf8.encode('epic:$secret'))}',
      );
    }
    request.write(
      jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': []}),
    );
    final response = await request.close().timeout(const Duration(seconds: 5));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(body);
    final result = json is Map ? json['result'] : null;
    final ok = result is Map ? result['Ok'] : null;
    return ok is Map ? ok.cast<String, dynamic>() : null;
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}
