/// The node screens' window on the node service layer (`lib/src/node/node.dart`): the local
/// node's state and controls, its peers and folder, node info for any node (F27) and the
/// public-node fallback (D-7). [DeskNodeApi] is the one interface the screens use; the app
/// overrides [deskNodeProvider] with [LepicDeskNode] (main_desktop.dart), the mock, the tour and
/// the tests use [MockDeskNode].
///
/// Nothing here starts a node or downloads anything by being read: only [DeskNodeApi.start]
/// does, after the user agreed (O2).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../builtin_node.dart' show NodeTomlOptions, NodeFailure;
import '../../models.dart' show Chain;
import '../../net/local_address.dart' show nodeClassOf;
import '../../node/node.dart';
import '../../providers.dart' show secretStoreProvider;
import '../../relay_directory.dart' show NodeHealthState, NetworkStatus;
import '../../secret_store_api.dart' show MemorySecretStore;
import '../screens/settings/prefs.dart' show settingsPrefsProvider;
import 'own_node.dart';

export '../../builtin_node.dart' show NodeTomlOptions, NodeFailure;
export '../../node/node.dart';
export '../../relay_directory.dart' show NodeHealthState, NetworkStatus;
export '../../net/local_address.dart' show NodeClass, nodeClassOf;
export 'own_node.dart' show OwnerCheck, OwnerOff, OwnerUnavailable, OwnNodeStatus;

abstract interface class DeskNodeApi {
  Chain get chain;

  /// The local node as it changes; the current state first.
  Stream<LocalNodeState> states();
  Future<void> start();
  Future<void> stop();
  Future<void> restart();

  Future<FallbackChoice> fallbackChoice();
  Future<void> setFallbackChoice(FallbackChoice choice);
  Future<bool> startWithApp();
  Future<void> setStartWithApp(bool on);

  /// Preferred peers and the two maxima; changes apply at the next start.
  Future<NodeTomlOptions> options();
  Future<void> setPeerOptions({List<String>? preferred, int? maxInbound, int? maxOutbound});

  Future<List<String>> logTail({int lines = 200});
  Future<String> logPath();

  /// The peers, now and every 10 s while listened to.
  Stream<PeerSnapshot> peers();

  /// Peer counts of this session (30 s samples).
  List<PeerCountSample> peerHistory();
  Future<void> ban(String addr);
  Future<void> unban(String addr);

  /// Bytes freed. The node stays stopped.
  Future<int> deleteChainData();
  Future<MovePlan> planMove(String folder);
  Future<void> changeDataFolder(String folder, FolderChange how, {void Function(int done, int total)? progress});
  Future<List<ChainDataInfo>> chainDataCandidates();
  Future<void> reuseChainData(ChainDataInfo source, ReuseMode how);

  /// A node already answering on this computer (default the standard port).
  Future<LocalNodeProbe> probe({String? url});
  Future<LocalNodeFacts> facts();

  /// What the app can tell about any node (F27). [mine]: the user marked a listed node as theirs.
  Future<NodeInfo> nodeInfo(String url, {bool mine = false});

  /// Owner access to an own node (own-node spec §3–§4), by node URL.
  Future<bool> hasOwnerSecret(String url);
  Future<OwnerCheck> addOwnerSecret(String url, String secret);
  Future<void> removeOwnerSecret(String url);

  /// Throws [OwnerUnavailable] when there is no secret, the node refused it, or it may not travel.
  Future<OwnNodeStatus> ownerStatus(String url, {int? networkHeight});
  Future<PeerSnapshot> ownPeers(String url);
  List<PeerCountSample> ownPeerHistory(String url);
  Future<void> ownBan(String url, String addr);
  Future<void> ownUnban(String url, String addr);
}

final deskNodeProvider = Provider<DeskNodeApi>((ref) => MockDeskNode());

/// The local node's state; loading until the controller is up, an error where the build has none.
final deskLocalNodeProvider = StreamProvider<LocalNodeState>((ref) => ref.watch(deskNodeProvider).states());

/// The D-7 answer, saved through [DeskFallback.set].
final deskFallbackProvider = AsyncNotifierProvider<DeskFallback, FallbackChoice>(DeskFallback.new);

class DeskFallback extends AsyncNotifier<FallbackChoice> {
  @override
  Future<FallbackChoice> build() => ref.watch(deskNodeProvider).fallbackChoice();

  Future<void> set(FallbackChoice c) async {
    // The first read of the stored answer may still be out (the wizard's Save is often the
    // first to ask): it would land over this answer.
    try {
      await future;
    } on Object {
      // Unreadable: the answer below replaces it.
    }
    state = AsyncData(c);
    await ref.read(deskNodeProvider).setFallbackChoice(c);
  }

  /// Yes or no for the node in use ([FallbackChoice.nodeUrl] stays).
  Future<void> answer(bool yes) => set(
    FallbackChoice(yes ? FallbackConsent.accepted : FallbackConsent.declined, nodeUrl: state.value?.nodeUrl ?? defaultFallbackNodeUrl, at: DateTime.now()),
  );

  /// Another public node for the fallback; an earlier answer stays.
  Future<void> node(String url) => set(FallbackChoice(state.value?.consent ?? FallbackConsent.unasked, nodeUrl: url, at: state.value?.at));
}

/// What the wallet does about its node now (D-7), from the state and the answer.
final deskFallbackDecisionProvider = Provider<FallbackDecision?>((ref) {
  final l = ref.watch(deskLocalNodeProvider).value;
  final c = ref.watch(deskFallbackProvider).value;
  return l == null || c == null ? null : decideFallback(l, c);
});

/// The peers while the Peers tab is open.
final deskPeersProvider = StreamProvider.autoDispose<PeerSnapshot>((ref) => ref.watch(deskNodeProvider).peers());

/// [NodeInfo] of a node URL; `ref.invalidate` to check again. A node the user marked as
/// theirs is asked as an own node.
final deskNodeInfoProvider = FutureProvider.autoDispose.family<NodeInfo, String>((ref, url) {
  final mine = ref.watch(settingsPrefsProvider.select((p) => p.mineNodes.contains(url)));
  return ref.watch(deskNodeProvider).nodeInfo(url, mine: mine);
});

/// Whether an owner secret is stored for a node URL.
final deskOwnerSecretProvider = FutureProvider.autoDispose.family<bool, String>((ref, url) => ref.watch(deskNodeProvider).hasOwnerSecret(url));

/// An own node's owner status. Errors with [OwnerUnavailable] when there is no access. Read
/// again by `ref.invalidate` (the panel and the shell ask every 15 s; a provider keeps no timer,
/// so a test's container has none pending).
final deskOwnStatusProvider = FutureProvider.autoDispose.family<OwnNodeStatus, ({String url, int? tip})>((ref, k) {
  ref.watch(deskOwnerSecretProvider(k.url));
  return ref.watch(deskNodeProvider).ownerStatus(k.url, networkHeight: k.tip);
});

/// An own node's peers while its Peers tab is open; read again by `ref.invalidate`.
final deskOwnPeersProvider = FutureProvider.autoDispose.family<PeerSnapshot, String>((ref, url) => ref.watch(deskNodeProvider).ownPeers(url));

/// The host of a node URL as the screens print it: no scheme, no port, no slash.
String nodeHost(String url) {
  final u = Uri.tryParse(url.contains('://') ? url : 'http://$url');
  return u == null || u.host.isEmpty ? url : u.host;
}

/// How long the local node is not synced, without a break, before the wallet leaves it for the
/// public node (D-7). A synced node can drop out of "synced" for a moment (no peers, a few
/// blocks behind); each move reopens the wallet.
const Duration fallbackLeaveAfter = Duration(seconds: 60);

/// The fallback decisions as the wallet acts on them (D-7): to the local node as soon as it is
/// synced, to the public node only once it has been wanted for [leaveAfter] without a break.
/// [FallbackAction.ask] moves nothing. [apply] gets each decision that moves the wallet.
class FallbackSwitch {
  FallbackSwitch(this._apply, {this.leaveAfter = fallbackLeaveAfter, Timer Function(Duration, void Function())? timer})
    : _timer = timer ?? Timer.new;

  final void Function(FallbackDecision d) _apply;
  final Duration leaveAfter;
  final Timer Function(Duration, void Function()) _timer;

  /// The last decision handed on.
  FallbackDecision? _sent;
  FallbackDecision? _pending;
  Timer? _wait;

  void update(FallbackDecision d) {
    switch (d.action) {
      case FallbackAction.ask:
        _stopWaiting();
      case FallbackAction.useLocal:
        _stopWaiting();
        if (_sent?.action != FallbackAction.useLocal) _send(d);
      case FallbackAction.usePublic:
        // Already there: only another public node moves it.
        if (_sent?.action == FallbackAction.usePublic) {
          _stopWaiting();
          if (_sent?.nodeUrl != d.nodeUrl) _send(d);
          return;
        }
        _pending = d;
        _wait ??= _timer(leaveAfter, () {
          _wait = null;
          final p = _pending;
          _pending = null;
          if (p != null) _send(p);
        });
    }
  }

  void _send(FallbackDecision d) {
    _sent = d;
    _apply(d);
  }

  void _stopWaiting() {
    _wait?.cancel();
    _wait = null;
    _pending = null;
  }

  void dispose() => _stopWaiting();
}

/// The real node layer, on the app's providers. [onDecision] moves the wallet's node when the
/// fallback decision changes (D-7), through [FallbackSwitch].
class LepicDeskNode implements DeskNodeApi {
  /// [fallbackTimer] is for tests (a fake clock).
  LepicDeskNode(this._ref, {required this.chain, this.onDecision, Timer Function(Duration, void Function())? fallbackTimer})
    : _switchTimer = fallbackTimer {
    _ref.onDispose(_switch.dispose);
  }

  final Timer Function(Duration, void Function())? _switchTimer;

  final Ref _ref;
  @override
  final Chain chain;
  final Future<void> Function(FallbackDecision d)? onDecision;

  FallbackChoice? _choice;

  /// Counts [setFallbackChoice] calls, so a read that was out meanwhile keeps the new answer.
  int _choiceSeq = 0;
  LocalNodeState? _state;
  FallbackDecision? _decision;
  late final FallbackSwitch _switch = FallbackSwitch((d) => unawaited(onDecision?.call(d)), timer: _switchTimer);

  Future<LocalNodeController> get _c => _ref.read(localNodeControllerProvider(chain).future);
  Future<NodeMaintenance> get _m => _ref.read(nodeMaintenanceProvider(chain).future);
  NodeSettings get _settings => _ref.read(nodeSettingsProvider(chain));

  void _decide() {
    final s = _state, c = _choice;
    if (s == null || c == null) return;
    final d = decideFallback(s, c);
    if (d == _decision) return;
    _decision = d;
    _switch.update(d);
  }

  /// The public node for a wallet moving to the local node now, or null for the local node:
  /// the decision on the node's state and the answer as they are (D-7).
  Future<String?> nodeWhileSyncing() async {
    final d = decideFallback((await _c).state, await fallbackChoice());
    return d.action == FallbackAction.usePublic ? d.nodeUrl : null;
  }

  @override
  Stream<LocalNodeState> states() async* {
    final c = await _c;
    if (_choice == null) await fallbackChoice();
    _state = c.state;
    _decide();
    yield c.state;
    await for (final s in c.states) {
      _state = s;
      _decide();
      yield s;
    }
  }

  @override
  Future<void> start() async => (await _c).start();

  @override
  Future<void> stop() async => (await _c).stop();

  @override
  Future<void> restart() async => (await _c).restart();

  @override
  Future<FallbackChoice> fallbackChoice() async {
    final seq = _choiceSeq;
    final read = await _settings.fallbackChoice();
    // An answer saved while this read was out is newer than what it read.
    if (seq != _choiceSeq) return _choice ?? read;
    return _choice = read;
  }

  @override
  Future<void> setFallbackChoice(FallbackChoice choice) async {
    _choiceSeq++;
    await _settings.setFallbackChoice(choice);
    _choice = choice;
    _decide();
  }

  @override
  Future<bool> startWithApp() => _settings.startWithApp();

  @override
  Future<void> setStartWithApp(bool on) => _settings.setStartWithApp(on);

  @override
  Future<NodeTomlOptions> options() => _settings.toOptions();

  @override
  Future<void> setPeerOptions({List<String>? preferred, int? maxInbound, int? maxOutbound}) async {
    final c = await _c;
    final o = await _settings.toOptions();
    await c.setOptions(
      NodeTomlOptions(
        chainDataPath: o.chainDataPath,
        preferredPeers: preferred ?? o.preferredPeers,
        maxInbound: maxInbound ?? o.maxInbound,
        maxOutbound: maxOutbound ?? o.maxOutbound,
      ),
    );
  }

  @override
  Future<List<String>> logTail({int lines = 200}) async => (await _c).logTail(lines: lines);

  @override
  Future<String> logPath() async => (await _c).logPath;

  @override
  Stream<PeerSnapshot> peers() async* {
    final service = await _ref.read(peerServiceProvider(chain).future);
    while (true) {
      try {
        yield await service.refresh();
      } on Object {
        // a missed read: the last snapshot stays
      }
      await Future<void>.delayed(peerReadEvery);
    }
  }

  PeerService? _peers;

  @override
  List<PeerCountSample> peerHistory() {
    unawaited(_ref.read(peerServiceProvider(chain).future).then((p) => _peers = p));
    return _peers?.history ?? const [];
  }

  @override
  Future<void> ban(String addr) async => (await _ref.read(peerServiceProvider(chain).future)).ban(addr);

  @override
  Future<void> unban(String addr) async => (await _ref.read(peerServiceProvider(chain).future)).unban(addr);

  @override
  Future<int> deleteChainData() async => (await _m).deleteChainData();

  @override
  Future<MovePlan> planMove(String folder) async => (await _m).planMove(folder);

  @override
  Future<void> changeDataFolder(String folder, FolderChange how, {void Function(int done, int total)? progress}) async =>
      (await _m).changeDataFolder(folder, how: how, progress: progress);

  @override
  Future<List<ChainDataInfo>> chainDataCandidates() => _ref.read(chainDataCandidatesProvider(chain).future);

  @override
  Future<void> reuseChainData(ChainDataInfo source, ReuseMode how) async => (await _m).reuseChainData(source, how: how);

  @override
  Future<LocalNodeProbe> probe({String? url}) async {
    if (url == null) return _ref.read(localNodeProbeProvider(chain).future);
    return detectLocalNode(chain, url: url);
  }

  @override
  Future<LocalNodeFacts> facts() => _ref.read(localNodeFactsProvider(chain).future);

  @override
  Future<NodeInfo> nodeInfo(String url, {bool mine = false}) => _ref.read(nodeInfoServiceProvider).info(url, chain: statusChainOf(chain), mine: mine);

  late final OwnNodeAccess _own = OwnNodeAccess(
    _ref.read(secretStoreProvider),
    mine: (url) => _ref.read(settingsPrefsProvider).mineNodes.contains(url),
  );

  @override
  Future<bool> hasOwnerSecret(String url) => _own.has(url);

  @override
  Future<OwnerCheck> addOwnerSecret(String url, String secret) => _own.add(url, secret);

  @override
  Future<void> removeOwnerSecret(String url) => _own.remove(url);

  @override
  Future<OwnNodeStatus> ownerStatus(String url, {int? networkHeight}) => _own.status(url, networkHeight: networkHeight);

  @override
  Future<PeerSnapshot> ownPeers(String url) => _own.peers(url);

  @override
  List<PeerCountSample> ownPeerHistory(String url) => _own.peerHistory(url);

  @override
  Future<void> ownBan(String url, String addr) => _own.ban(url, addr);

  @override
  Future<void> ownUnban(String url, String addr) => _own.unban(url, addr);
}

/// Canned node data for the mock wallet, the tour and the tests. [show] puts any state on
/// screen; the controls move it the way the real node would, without waiting.
class MockDeskNode implements DeskNodeApi {
  MockDeskNode({LocalNodeState? state, FallbackChoice choice = const FallbackChoice.unasked(), this.peerCount = 14})
    : _state = state ?? mockLocalNode(LocalNodePhase.stopped),
      _choice = choice; // ignore: prefer_initializing_formals

  @override
  Chain get chain => Chain.mainnet;
  LocalNodeState _state;
  FallbackChoice _choice;
  final _ctl = StreamController<LocalNodeState>.broadcast();
  final List<String> calls = [];
  int peerCount;
  bool _startWithApp = true;
  NodeTomlOptions _options = const NodeTomlOptions();
  final Set<String> _banned = {'203.0.113.9:3414'};
  int _deleted = 0;

  LocalNodeState get state => _state;

  void show(LocalNodeState s) {
    _state = s;
    _ctl.add(s);
  }

  @override
  Stream<LocalNodeState> states() async* {
    yield _state;
    yield* _ctl.stream;
  }

  @override
  Future<void> start() async {
    calls.add('start');
    show(mockLocalNode(LocalNodePhase.starting));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    show(mockLocalNode(LocalNodePhase.stopped));
  }

  @override
  Future<void> restart() async {
    calls.add('restart');
    show(mockLocalNode(LocalNodePhase.starting));
  }

  @override
  Future<FallbackChoice> fallbackChoice() async => _choice;

  @override
  Future<void> setFallbackChoice(FallbackChoice choice) async {
    calls.add('fallback ${choice.consent.name} ${choice.nodeUrl}');
    _choice = choice;
  }

  @override
  Future<bool> startWithApp() async => _startWithApp;

  @override
  Future<void> setStartWithApp(bool on) async => _startWithApp = on;

  @override
  Future<NodeTomlOptions> options() async => _options;

  @override
  Future<void> setPeerOptions({List<String>? preferred, int? maxInbound, int? maxOutbound}) async {
    calls.add('options');
    _options = NodeTomlOptions(
      chainDataPath: _options.chainDataPath,
      preferredPeers: preferred ?? _options.preferredPeers,
      maxInbound: maxInbound ?? _options.maxInbound,
      maxOutbound: maxOutbound ?? _options.maxOutbound,
    );
    if (_state.phase != LocalNodePhase.stopped && _state.phase != LocalNodePhase.error) show(_with(_state, restartNeeded: true));
  }

  @override
  Future<List<String>> logTail({int lines = 200}) async => mockNodeLog;

  @override
  Future<String> logPath() async => '${_state.dataFolder}/epic-server.log';

  @override
  Stream<PeerSnapshot> peers() async* {
    yield _snapshot();
  }

  PeerSnapshot _snapshot() {
    final at = DateTime(2026, 10, 22, 14, 2);
    final connected = [
      for (var i = 0; i < peerCount; i++)
        if (!_banned.contains(_peerAddr(i)))
          PeerView(
            ConnectedPeer(
              addr: _peerAddr(i),
              direction: i % 3 == 2 ? PeerDirection.outbound : PeerDirection.inbound,
              userAgent: i == 5 ? 'MW/Epic 3.6.0' : 'MW/Epic 4.1.1', // l10n-ok: mock peer user agent
              protocolVersion: 1000,
              height: 3764975 - (i % 4) * 2,
            ),
            firstSeen: at.subtract(Duration(minutes: i * 7)),
          ),
    ];
    return PeerSnapshot(
      at: at,
      connected: connected,
      banned: [
        for (final b in _banned) StoredPeer(addr: b, flag: PeerFlag.banned, banReason: b.startsWith('203') ? 'BadBlock' : 'ManualBan', lastBanned: DateTime(2026, 10, 22, 13, 52)),
      ],
    );
  }

  static String _peerAddr(int i) => '${[95, 135, 51, 172, 88, 65][i % 6]}.${(i * 37) % 250 + 1}.${(i * 11) % 200 + 3}.${(i * 53) % 250 + 2}:3414';

  @override
  List<PeerCountSample> peerHistory() => [
    for (var i = 0; i < 24; i++) PeerCountSample(DateTime(2026, 10, 22, 13).add(Duration(seconds: 30 * i)), inbound: 4 + (i ~/ 3) % 6, outbound: 5 + i % 3),
  ];

  @override
  Future<void> ban(String addr) async {
    calls.add('ban $addr');
    _banned.add(addr);
  }

  @override
  Future<void> unban(String addr) async {
    calls.add('unban $addr');
    _banned.remove(addr);
  }

  @override
  Future<int> deleteChainData() async {
    calls.add('delete');
    _deleted = _state.chainDataBytes ?? 0;
    show(_with(mockLocalNode(LocalNodePhase.stopped), bytes: 0));
    return _deleted;
  }

  @override
  Future<MovePlan> planMove(String folder) async => MovePlan(
    from: _state.chainDataPath,
    to: '$folder/chain_data',
    bytesNeeded: _state.chainDataBytes ?? 0,
    freeOnTarget: 118 * _gb,
    sameVolume: false,
    problems: const [],
  );

  @override
  Future<void> changeDataFolder(String folder, FolderChange how, {void Function(int done, int total)? progress}) async {
    calls.add('folder ${how.name} $folder');
  }

  @override
  Future<List<ChainDataInfo>> chainDataCandidates() async => mockChainCandidates;

  @override
  Future<void> reuseChainData(ChainDataInfo source, ReuseMode how) async => calls.add('reuse ${how.name} ${source.path}');

  /// What [probe] finds; none by default.
  LocalNodeProbe? probeAnswer;

  @override
  Future<LocalNodeProbe> probe({String? url}) async =>
      probeAnswer ?? LocalNodeProbe(url: url ?? 'http://127.0.0.1:3413', answers: false);

  @override
  Future<LocalNodeFacts> facts() async =>
      LocalNodeFacts(chainBytes: 5 * _gb, chainBytesMeasured: false, freeBytes: 118 * _gb, minFreeBytes: 2 * _gb, firewallPrompt: false);

  /// Node info by host; unknown hosts answer as healthy and at the tip.
  final Map<String, NodeInfo> infos = {};

  @override
  Future<NodeInfo> nodeInfo(String url, {bool mine = false}) async =>
      infos[nodeHost(url)] ?? (nodeClassOf(url, mine: mine).own ? mockOwnNodeInfo(url, mine: mine) : mockNodeInfo(url));

  /// Owner secrets by URL; [ownerSecret] is the one the mock node takes.
  final MemorySecretStore ownerSecrets = MemorySecretStore();
  String ownerSecret = 'mock-secret';

  /// The own node's owner status: [ownStatus] null answers as synced with [peerCount] peers.
  OwnNodeStatus? ownStatus;

  /// The owner API refuses the stored secret (it was rotated).
  bool ownerRefuses = false;

  @override
  Future<bool> hasOwnerSecret(String url) async => ownerSecrets.values.containsKey(ownerSecretKey(url));

  @override
  Future<OwnerCheck> addOwnerSecret(String url, String secret) async {
    calls.add('owner add $url');
    if (secret.trim() != ownerSecret) return OwnerCheck.refused;
    await ownerSecrets.write(ownerSecretKey(url), secret.trim());
    return OwnerCheck.ok;
  }

  @override
  Future<void> removeOwnerSecret(String url) async {
    calls.add('owner remove $url');
    await ownerSecrets.delete(ownerSecretKey(url));
  }

  Future<void> _ownerReady(String url) async {
    if (!await hasOwnerSecret(url)) throw const OwnerUnavailable(OwnerOff.notSet);
    if (ownerRefuses) throw OwnerUnavailable(OwnerOff.refused, since: DateTime(2026, 10, 22, 14, 2));
  }

  @override
  Future<OwnNodeStatus> ownerStatus(String url, {int? networkHeight}) async {
    await _ownerReady(url);
    return ownStatus ??
        OwnNodeStatus(at: DateTime(2026, 10, 22, 14, 2), syncStatus: 'no_sync', progress: null, peers: peerCount, version: '4.1.1', height: mockTip);
  }

  @override
  Future<PeerSnapshot> ownPeers(String url) async {
    await _ownerReady(url);
    return _snapshot();
  }

  @override
  List<PeerCountSample> ownPeerHistory(String url) => peerHistory();

  @override
  Future<void> ownBan(String url, String addr) => ban(addr);

  @override
  Future<void> ownUnban(String url, String addr) => unban(addr);
}

const int _gb = 1000 * 1000 * 1000;

const String mockDataFolder = '~/.epic_cash_desktop/node/main';

/// The mock's network tip.
const int mockTip = 3764975;

/// A local node state of the mock: [phase] with the usual numbers, [stage] while syncing.
LocalNodeState mockLocalNode(
  LocalNodePhase phase, {
  SyncStage stage = SyncStage.headers,
  double? overall,
  int? done,
  int? total,
  Duration? eta,
  NodeFailure? failure,
  String? reason,
  bool stalled = false,
  bool restartNeeded = false,
  bool userToml = false,
  ChainDataOrigin origin = ChainDataOrigin.own,
  int? bytes,
}) {
  final at = DateTime(2026, 10, 22, 14, 2);
  final syncing = phase == LocalNodePhase.syncing;
  final live = phase != LocalNodePhase.stopped && phase != LocalNodePhase.error;
  return LocalNodeState(
    phase: phase,
    dataFolder: mockDataFolder,
    chainDataPath: origin == ChainDataOrigin.pointed ? '~/.epic/main/chain_data' : '$mockDataFolder/chain_data',
    at: at,
    progress: syncing || phase == LocalNodePhase.starting
        ? SyncProgress(
            phase == LocalNodePhase.starting ? SyncStage.waitingForPeers : stage,
            overall: phase == LocalNodePhase.starting ? null : overall,
            done: done,
            total: total,
          )
        : null,
    eta: syncing ? eta : null,
    stageRate: stage == SyncStage.chainStateDownload && syncing ? 2.4e6 : null,
    height: phase == LocalNodePhase.synced ? mockTip : (syncing && stage == SyncStage.blocks ? done : (stalled ? 1480200 : null)),
    networkHeight: mockTip,
    blocksBehind: phase == LocalNodePhase.synced ? 0 : null,
    readyForTxs: phase == LocalNodePhase.synced,
    version: '4.1.1',
    startedAt: live || stalled ? at.subtract(const Duration(hours: 2, minutes: 14)) : null,
    uptime: live || stalled ? const Duration(hours: 2, minutes: 14) : null,
    chainDataBytes: bytes ?? (phase == LocalNodePhase.stopped && bytes == 0 ? 0 : (5.2 * _gb).round()),
    chainDataBytesAtStart: (4.9 * _gb).round(),
    freeBytes: 118 * _gb,
    peers: live ? 14 : null,
    failure: failure,
    reason: reason,
    stalled: stalled,
    restartNeeded: restartNeeded,
    userToml: userToml,
    chainDataOrigin: origin,
  );
}

LocalNodeState _with(LocalNodeState s, {bool? restartNeeded, int? bytes}) => LocalNodeState(
  phase: s.phase,
  dataFolder: s.dataFolder,
  chainDataPath: s.chainDataPath,
  at: s.at,
  progress: s.progress,
  eta: s.eta,
  stageRate: s.stageRate,
  height: s.height,
  networkHeight: s.networkHeight,
  blocksBehind: s.blocksBehind,
  readyForTxs: s.readyForTxs,
  version: s.version,
  startedAt: s.startedAt,
  uptime: s.uptime,
  chainDataBytes: bytes ?? s.chainDataBytes,
  chainDataBytesAtStart: s.chainDataBytesAtStart,
  freeBytes: s.freeBytes,
  peers: s.peers,
  failure: s.failure,
  reason: s.reason,
  stalled: s.stalled,
  restartNeeded: restartNeeded ?? s.restartNeeded,
  userToml: s.userToml,
  chainDataOrigin: s.chainDataOrigin,
);

/// An own node of the mock (asked directly): at the tip, 6 ms, 3 waiting, unless told otherwise.
NodeInfo mockOwnNodeInfo(String url, {bool mine = false, NodeHead head = NodeHead.synced, int behind = 0, int? pool = 3, bool siteTip = true}) {
  final down = head == NodeHead.down;
  final syncing = head == NodeHead.syncing;
  return NodeInfo(
    url: url,
    source: down ? NodeInfoSource.none : NodeInfoSource.limited,
    at: DateTime(2026, 10, 22, 14, 2),
    nodeClass: nodeClassOf(url, mine: mine),
    head: head,
    state: down ? NodeHealthState.down : (head == NodeHead.synced ? NodeHealthState.healthy : NodeHealthState.degraded),
    height: down ? null : mockTip - behind,
    networkHeight: mockTip,
    blocksBehind: down ? null : behind,
    version: down ? null : '4.1.1',
    releasedVersion: '4.1.1',
    latencyMs: down ? null : 6,
    readyForTxs: down ? null : !syncing,
    tipTime: down ? null : DateTime(2026, 10, 22, 14),
    poolSize: down ? null : pool,
    tipFrom: siteTip ? TipReference.statusSite : TipReference.publicNodes,
    tipNodes: siteTip ? null : 4,
  );
}

/// A remote node of the mock, healthy and at the tip unless told otherwise.
NodeInfo mockNodeInfo(
  String url, {
  NodeInfoSource source = NodeInfoSource.directory,
  NodeHealthState state = NodeHealthState.healthy,
  int behind = 0,
  String version = '4.1.1',
  int? latencyMs = 24,
}) {
  final down = state == NodeHealthState.down;
  final directory = source == NodeInfoSource.directory;
  return NodeInfo(
    url: url,
    source: source,
    at: DateTime(2026, 10, 22, 14, 2),
    state: state,
    height: down ? null : mockTip - behind,
    networkHeight: directory ? mockTip : null,
    blocksBehind: down || !directory ? null : behind,
    version: down ? null : version,
    releasedVersion: directory ? '4.1.1' : null,
    latencyMs: down ? null : latencyMs,
    directoryReachedAt: directory ? DateTime(2026, 10, 22, 14, 1) : null,
    uptime24h: directory ? 0.997 : null,
    peers: directory ? 63 : null,
    operator: directory ? 'Epic Cash' : null, // l10n-ok: mock operator name
    listing: directory ? 'official' : null,
    readyForTxs: directory ? null : true,
    tipTime: directory ? null : DateTime(2026, 10, 22, 14),
    network: directory
        ? NetworkStatus(
            tipHeight: mockTip,
            tipAgeSeconds: 40,
            releasedNodeVersion: '4.1.1',
            nodesHealthy: 5,
            nodesTotal: 6,
            epicboxHealthy: 4,
            epicboxTotal: 4,
            forked: false,
          )
        : null,
  );
}

final List<ChainDataInfo> mockChainCandidates = [
  ChainDataInfo(
    path: '~/.epic/main/chain_data',
    source: ChainDataSource.cli,
    chain: Chain.mainnet,
    bytes: (4.8 * _gb).round(),
    headerBytes: 240000000,
    txhashsetBytes: 3000000000,
    modified: DateTime(2026, 9, 30),
    lock: FolderLock.free,
    usable: true,
  ),
  ChainDataInfo(
    path: '~/.epic-gui/node/main/chain_data',
    source: ChainDataSource.gui,
    chain: Chain.mainnet,
    bytes: (5.0 * _gb).round(),
    headerBytes: 240000000,
    txhashsetBytes: 3100000000,
    modified: DateTime(2026, 10, 21),
    lock: FolderLock.locked,
    usable: true,
  ),
];

const List<String> mockNodeLog = [
  '20261022 13:58:01.112 INFO epic_servers::epic::server - Starting server, genesis block: 0000…', // l10n-ok: mock node log (log lines are English)
  '20261022 13:58:01.530 INFO epic_p2p::serv - P2P server started on 0.0.0.0:3414', // l10n-ok: mock node log (log lines are English)
  '20261022 13:58:04.882 INFO epic_servers::epic::sync::syncer - sync: waiting for peers', // l10n-ok: mock node log (log lines are English)
  '20261022 13:58:12.301 WARN epic_p2p::peers - connect to 51.38.4.1:3414 timed out', // l10n-ok: mock node log (log lines are English)
  '20261022 13:58:19.004 INFO epic_servers::epic::sync::header_sync - header sync: 1480200 of 3764975', // l10n-ok: mock node log (log lines are English)
  '20261022 14:01:44.770 ERROR epic_p2p::protocol - bad block from 203.0.113.9:3414, banning', // l10n-ok: mock node log (log lines are English)
  '20261022 14:02:00.010 INFO epic_servers::epic::sync::header_sync - header sync: 1482900 of 3764975', // l10n-ok: mock node log (log lines are English)
];
