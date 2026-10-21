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
}

enum NodeStatusKind { off, starting, syncing, running, stalled, stopped, failed }

/// One state of the built-in node, as streamed by [BuiltInNode.states].
class BuiltInNodeState {
  const BuiltInNodeState(
    this.kind, {
    this.height,
    this.highest,
    this.phase,
    this.failure,
    this.reason,
  });

  const BuiltInNodeState.off() : this(NodeStatusKind.off);

  final NodeStatusKind kind;

  /// The node's own tip, when it answered.
  final int? height;

  /// The highest height its peers report, while syncing.
  final int? highest;

  /// The node's sync phase (`header_sync`, `txhashset_download`, `body_sync`, ...), while syncing.
  final String? phase;

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
      other.reason == reason;

  @override
  int get hashCode =>
      Object.hash(kind, height, highest, phase, failure, reason);

  @override
  String toString() =>
      'BuiltInNodeState($kind, height: $height, highest: $highest, phase: $phase, '
      'failure: $failure, reason: $reason)';
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

typedef ProcessStarter =
    Future<NodeProcess> Function(
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
typedef NodeApi =
    Future<Map<String, dynamic>?> Function(
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
/// there. Disables the TUI, binds the API to loopback and keeps the log in the node folder.
const String nodeTomlTemplate = '''
[server]
db_root = {{DB_ROOT}}
api_http_addr = {{API_ADDR}}
api_secret_path = {{API_SECRET}}
foundation_path = {{FOUNDATION}}
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
capabilities = "HEADER_HIST | TXHASHSET_HIST | PEER_LIST | TX_KERNEL_HASH | HEADER_FASTSYNC"

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
const Set<String> safeSyncStates = {
  'txhashset_download',
  'syncing',
  'txhashset_rangeproofs_validation',
  'txhashset_kernels_validation',
};

class BuiltInNode {
  BuiltInNode({
    required this.root,
    required this.binary,
    required this.chain,
    this.minFreeBytes = 5 * 1024 * 1024 * 1024,
    this.pollInterval = const Duration(seconds: 5),
    this.maxPollInterval = const Duration(seconds: 30),
    this.stallAfter = const Duration(minutes: 3),
    this.diskCheckEvery = const Duration(seconds: 30),
    this.killAfter = const Duration(seconds: 15),
    this.autoPoll = true,
    ProcessStarter? startProcess,
    DateTime Function()? clock,
    PortChecker? portInUse,
    DiskProbe? freeBytes,
    NodeApi? api,
    bool? isWindows,
  }) : _start = startProcess ?? _startRealProcess,
       _clock = clock ?? DateTime.now,
       _portInUse = portInUse ?? _realPortInUse,
       _freeBytes = freeBytes ?? _realFreeBytes,
       _api = api ?? _realApi,
       _windows = isWindows ?? Platform.isWindows;

  /// `<app support>/node`; the chain's folder is below it.
  final String root;

  /// Path to the bundled `epic` executable.
  final String binary;

  final Chain chain;

  /// The node is refused, or stopped, when the volume holds less than this.
  final int minFreeBytes;
  final Duration pollInterval;
  final Duration maxPollInterval;
  final Duration stallAfter;
  final Duration diskCheckEvery;
  final Duration killAfter;

  /// Poll on a timer after [start]. Tests turn it off and call [poll].
  final bool autoPoll;

  final ProcessStarter _start;
  final DateTime Function() _clock;
  final PortChecker _portInUse;
  final DiskProbe _freeBytes;
  final NodeApi _api;
  final bool _windows;

  final StreamController<BuiltInNodeState> _controller =
      StreamController<BuiltInNodeState>.broadcast();
  BuiltInNodeState _state = const BuiltInNodeState.off();

  NodeProcess? _process;
  Timer? _timer;
  bool _stopping = false;
  bool _polling = false;
  bool _restarted = false;
  int _failures = 0;
  int? _lastHeight;
  DateTime? _lastChange;
  DateTime? _lastAnswer;
  DateTime? _lastDiskCheck;
  String? _secret;

  NodePorts get ports => NodePorts.of(chain);

  /// The node's API on loopback, for the wallet's node setting. LEPIC accepts plain http on
  /// loopback only, which is where this is.
  String get url => 'http://127.0.0.1:${ports.api}';

  String get folderName => switch (chain) {
    Chain.mainnet => 'main',
    Chain.floonet => 'floo',
    Chain.usernet => 'user',
  };

  String get folder => _join(root, folderName);
  String get tomlPath => _join(folder, _tomlName);
  String get chainDataPath => _join(folder, 'chain_data');
  String get logPath => _join(folder, 'epic-server.log');

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

  /// The toml for this chain with the folder's absolute paths.
  String renderToml() {
    final p = ports;
    final values = <String, String>{
      'DB_ROOT': _q(chainDataPath),
      'API_ADDR': _q('127.0.0.1:${p.api}'),
      'API_SECRET': _q(_join(folder, _secretName)),
      'FOUNDATION': _q(_join(folder, 'foundation.json')),
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
    };
    return nodeTomlTemplate.replaceAllMapped(
      RegExp(r'\{\{([A-Z0-9_]+)\}\}'),
      (m) => values[m[1]!] ?? m[0]!,
    );
  }

  static String _q(String s) => jsonEncode(s);

  static String _hash(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  /// Creates the folder, the toml and the API secret. The toml is rewritten (atomically) only when
  /// it is still what this class wrote last; a toml the user edited is kept as it is. Returns true
  /// when the user's own toml is in use.
  Future<bool> prepareFolder() async {
    await Directory(folder).create(recursive: true);
    final toml = File(tomlPath);
    final hashFile = File(_join(folder, _tomlHashName));
    final wanted = renderToml();
    var userEdited = false;
    if (await toml.exists()) {
      final current = await toml.readAsString();
      final written = await hashFile.exists()
          ? (await hashFile.readAsString()).trim()
          : null;
      if (written == null || written != _hash(current)) {
        userEdited = true;
      } else if (current != wanted) {
        await _writeAtomic(toml, wanted);
        await hashFile.writeAsString(_hash(wanted));
      }
    } else {
      await _writeAtomic(toml, wanted);
      await hashFile.writeAsString(_hash(wanted));
    }
    final secret = File(_join(folder, _secretName));
    if (!await secret.exists()) {
      await _writeAtomic(secret, _randomSecret());
      if (!_windows) {
        try {
          await Process.run('chmod', ['600', secret.path]);
        } on Object {
          // best effort: the folder is the user's own
        }
      }
    }
    return userEdited;
  }

  static Future<void> _writeAtomic(File file, String text) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(text, flush: true);
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

  /// Starts the node. Throws [NodeStartException] when the binary is missing, the API port is
  /// already answering (another node: it is left alone) or the disk is under the floor.
  Future<void> start() async {
    if (_process != null) return;
    _restarted = false;
    await _launch();
  }

  Future<void> _launch() async {
    _set(const BuiltInNodeState(NodeStatusKind.starting));
    try {
      if (!await File(binary).exists()) {
        throw NodeStartException(
          NodeFailure.binaryMissing,
          'The built-in node is missing: $binary',
        );
      }
      final port = ports.api;
      if (await _portInUse(port)) {
        throw NodeStartException(
          NodeFailure.portInUse,
          'Port $port in use',
          port: port,
        );
      }
      await prepareFolder();
      final free = await _freeBytes(folder);
      if (free != null && free < minFreeBytes) {
        throw NodeStartException(
          NodeFailure.diskLow,
          _lowDiskMessage(free),
        );
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
      _stopping = false;
      _process = process;
      _failures = 0;
      _lastHeight = null;
      final now = _clock();
      _lastChange = now;
      _lastAnswer = now;
      _lastDiskCheck = now;
      _secret = null;
      try {
        await File(_join(folder, _pidName)).writeAsString('${process.pid}\n');
      } on Object {
        // the pid file is a courtesy to a person looking at the folder
      }
      unawaited(process.exitCode.then((code) => _onExit(process, code)));
      if (autoPoll) _schedule();
    } on NodeStartException catch (e) {
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

  String _lowDiskMessage(int free) =>
      'Not enough free disk space: ${_gb(free)} GB free, ${_gb(minFreeBytes)} GB needed';

  static String _gb(int bytes) =>
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

  void _onExit(NodeProcess process, int code) {
    if (!identical(_process, process) || _stopping) return;
    _process = null;
    _timer?.cancel();
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
      if (reading.height != _lastHeight) {
        _lastHeight = reading.height;
        _lastChange = at;
      }
      if (safeSyncStates.contains(reading.phase)) _lastChange = at;
      if (at.difference(_lastChange!) >= stallAfter) {
        await _stalled();
        return;
      }
      _set(
        reading.phase == 'no_sync'
            ? BuiltInNodeState(NodeStatusKind.running, height: reading.height)
            : BuiltInNodeState(
                NodeStatusKind.syncing,
                height: reading.height,
                highest: reading.highest,
                phase: reading.phase,
              ),
      );
    } finally {
      _polling = false;
    }
  }

  /// A stalled node is restarted once per [start]; the second time it is only reported.
  Future<void> _stalled() async {
    if (_restarted) {
      _set(BuiltInNodeState(NodeStatusKind.stalled, height: _lastHeight));
      return;
    }
    _restarted = true;
    await _stopProcess();
    try {
      await _launch();
    } on NodeStartException catch (e) {
      _set(
        BuiltInNodeState(
          NodeStatusKind.failed,
          failure: NodeFailure.restartFailed,
          reason: 'Restarting the built-in node failed: ${e.message}',
        ),
      );
    }
  }

  Future<_Reading?> _read() async {
    final port = ports.api;
    _secret ??= await _readSecret();
    if (_secret != null) {
      final s = await _api(port, 'get_status', owner: true, secret: _secret);
      if (s != null) {
        final info = s['sync_info'];
        final tip = s['tip'];
        final height =
            _int(tip is Map ? tip['height'] : null) ??
            _int(info is Map ? info['current_height'] : null) ??
            0;
        return _Reading(
          height,
          _int(info is Map ? info['highest_height'] : null),
          s['sync_status'] as String?,
        );
      }
    }
    final tip = await _api(port, 'get_tip', owner: false);
    if (tip == null) return null;
    return _Reading(_int(tip['height']) ?? 0, null, null);
  }

  static int? _int(Object? v) => v is num ? v.toInt() : null;

  Future<String?> _readSecret() async {
    try {
      final text = (await File(_join(folder, _secretName)).readAsString())
          .trim();
      return text.isEmpty ? null : text;
    } on Object {
      return null;
    }
  }

  /// Stops the node this object started: asks it to stop, kills it after [killAfter]. Never touches
  /// any other process, and does nothing when this object started none.
  Future<void> stop() async {
    _timer?.cancel();
    if (_process == null) {
      if (_state.isActive) _set(const BuiltInNodeState(NodeStatusKind.stopped));
      return;
    }
    await _stopProcess();
    _set(const BuiltInNodeState(NodeStatusKind.stopped));
  }

  Future<void> _stopProcess() async {
    final process = _process;
    _timer?.cancel();
    if (process == null) return;
    _stopping = true;
    _process = null;
    try {
      process.terminate();
      await process.exitCode.timeout(
        killAfter,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    } on Object {
      process.kill();
    }
    try {
      await File(_join(folder, _pidName)).delete();
    } on Object {
      // already gone
    }
    _stopping = false;
  }

  /// Stops the node and closes the state stream. For app exit.
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

class _Reading {
  const _Reading(this.height, this.highest, this.phase);

  final int height;
  final int? highest;
  final String? phase;
}

// -- the real implementations ------------------------------------------------------------------

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
    if (_windows) {
      Process.run('taskkill', ['/PID', '$pid', '/F', '/T']);
    } else {
      Process.killPid(pid, ProcessSignal.sigkill);
    }
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

Future<int?> _realFreeBytes(String directory) async {
  try {
    if (Platform.isWindows) {
      final drive = directory.length > 1 && directory[1] == ':'
          ? directory[0]
          : null;
      if (drive == null) return null;
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
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
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client
        .postUrl(
          Uri.parse(
            'http://127.0.0.1:$port/v2/${owner ? 'owner' : 'foreign'}',
          ),
        )
        .timeout(const Duration(seconds: 5));
    request.headers.contentType = ContentType.json;
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
