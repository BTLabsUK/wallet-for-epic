// SPDX-License-Identifier: Apache-2.0
/// Node failover on the desktop: the adapter between the desktop wallet and the engine both
/// apps run (`node_failover_engine.dart`; `node_failover.dart` has the rules). It feeds the
/// engine what the node status reads ([ServiceStatus.nodeHealth], the refreshes, the behind
/// reading), and gives it a way to ask a node ([DeskWalletApi.checkNode], through the open
/// wallet), a way to move the open wallet for this session ([DeskWalletApi.useNodeForSession])
/// and the plan of a round. [deskFailoverProvider] holds the move, or null while the wallet is on
/// the chosen node; the rail and Settings › Node name the chosen node under the one in use. The
/// search shows in the node's health ([deskNodeHealthProvider]): connecting while a round runs,
/// not answering when no node answers.
///
/// A node that answers but reads behind: [DeskFailoverWatch.askBehind] reads the network's tip
/// for it every [behindAskEvery]; the engine leaves it after `node.failover_after_s` for a node
/// that answers ahead of it. Never off a node the user added or runs.
///
/// The user's own node: while a public node stands in for it, it is asked again every
/// [ownAskBackEvery] and the wallet moves back after [ownBackAfter] good answers in a row, a home
/// node coming back being the normal case. An own node that is syncing moves the wallet to a
/// public node only when the user said so for that node (the fallback question on its panel),
/// and back once it accepts transactions.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../net/local_address.dart' show nodeClassOf;
import '../data/desk_node.dart' show deskNodeProvider, deskNodeInfoProvider, deskOwnStatusProvider, NodeHead, NodeInfo;
import '../../net/tor_net.dart' show torBuiltInOnion;
import '../../node_failover.dart';
import '../../node_failover_engine.dart';
import '../data/models.dart';
import '../data/node_switch.dart' show deskNodePicksProvider, deskNodeSwitchProvider;
import '../data/server_lists.dart';
import '../data/state.dart';
import '../data/tor_view.dart';
import '../../settings_file/host_settings.dart' show appConfig;
import '../screens/settings/prefs.dart' show settingsPrefsProvider;

export '../../node_failover.dart' show NodeFailover;
export '../../node_failover_engine.dart' show FailoverSearch;

/// How often the chosen own node is asked while a public node stands in for it, or while it
/// may be syncing.
Duration get ownAskBackEvery => appConfig.ownNodeAsk;

/// How often the node in use is read against the network's tip: the monitor's answer is kept
/// this long (`status.fresh_s`), so asking sooner shows nothing new.
Duration get behindAskEvery => appConfig.statusFresh;

/// Good answers in a row before the wallet moves back to the own node.
const int ownBackAfter = 2;

/// The move node failover made for this session, or null on the chosen node. Screens watch
/// this; [deskFailoverWatchProvider] makes the moves.
final deskFailoverProvider = NotifierProvider<DeskFailoverState, NodeFailover?>(DeskFailoverState.new);

class DeskFailoverState extends Notifier<NodeFailover?> {
  @override
  NodeFailover? build() {
    // Another wallet, or the next unlock, opens on the chosen node.
    ref.watch(deskProvider.select((s) => s.account?.id));
    // A node the user picks is the chosen one from then on.
    ref.listen(deskProvider.select((s) => s.status?.node.url), (_, url) {
      final moved = state;
      if (moved != null && url != null && !sameServer(ServerKind.node, url, moved.inUse)) state = null;
    });
    return null;
  }

  void moved(NodeFailover to) => state = to;
}

/// What the engine is doing, for the node's health ([deskNodeHealthProvider]).
final deskFailoverSearchProvider = NotifierProvider<DeskFailoverSearch, FailoverSearch>(DeskFailoverSearch.new);

class DeskFailoverSearch extends Notifier<FailoverSearch> {
  @override
  FailoverSearch build() {
    ref.watch(deskProvider.select((s) => s.account?.id));
    return FailoverSearch.idle;
  }

  void set(FailoverSearch s) => state = s;
}

/// The node's health as every place shows it: the wallet's reading ([raw]) with the engine's
/// search counted in. While a round looks for a node that answers, a node read down is
/// connecting ([ServiceHealth.checking]); once a round found none, it is down.
ServiceHealth shownNodeHealth(ServiceHealth raw, FailoverSearch search) => switch (search) {
  FailoverSearch.searching when raw == ServiceHealth.down => ServiceHealth.checking,
  FailoverSearch.noneAnswer when raw == ServiceHealth.checking => ServiceHealth.down,
  _ => raw,
};

/// [shownNodeHealth] of the open wallet's node; null with no status yet.
final deskNodeHealthProvider = Provider<ServiceHealth?>((ref) {
  final raw = ref.watch(deskProvider.select((s) => s.status?.nodeHealth));
  if (raw == null) return null;
  return shownNodeHealth(raw, ref.watch(deskFailoverSearchProvider));
});

/// The watcher: alive while the shell shows (`shell.dart`), one engine per open wallet.
final deskFailoverWatchProvider = NotifierProvider<DeskFailoverWatch, void>(DeskFailoverWatch.new);

class DeskFailoverWatch extends Notifier<void> {
  FailoverEngine? _engine;

  /// Counts the builds: [_current] tells whether one is still the newest.
  int _build = 0;

  bool _current(int gen) => gen == _build && ref.mounted;

  /// Bumped by every node the user picks: a move started before it is not recorded.
  int _picks = 0;

  /// Good answers in a row of the own node while a public node stands in.
  int _good = 0;
  bool _askingOwn = false;

  /// The chosen own node is syncing and the user wants a public node meanwhile: it counts as not
  /// answering until it accepts transactions.
  bool _ownSyncing = false;

  @override
  void build() {
    final account = ref.watch(deskProvider.select((s) => s.account?.id));
    final gen = ++_build;
    _engine?.dispose();
    _engine = null;
    _lag = null;
    _good = 0;
    _ownSyncing = false;
    if (account == null) return;
    final engine = FailoverEngine(
      probe: _probe,
      switchTo: (url, {required behind}) => _switchTo(gen, url, behind: behind),
      plan: () => _plan(gen),
      timings: () => failoverTimings,
      stay: () => _stay(gen),
      onState: (s) {
        if (_current(gen)) ref.read(deskFailoverSearchProvider.notifier).set(s);
      },
      log: (line) => logInfo('desk', line),
      freshConnections: () => ref.read(deskApiProvider).dropNodeConnections(),
    );
    _engine = engine;
    ref.onDispose(engine.dispose);

    // The status may change while a widget builds, when no provider may change: what it says
    // reaches the engine a microtask later.
    void later(void Function() run) => scheduleMicrotask(() {
      if (_current(gen)) run();
    });
    ref.listen(deskProvider.select((s) => (s.status?.nodeHealth, s.status?.node.url, s.status?.nodeHeight)), (_, _) => later(_feed));
    // A refresh ended: unvalidated twice in a row, the next round treats the node as down.
    ref.listen(deskProvider.select((s) => s.status?.syncProgress != null), (was, now) {
      if (was != true || now) return;
      later(() {
        final status = ref.read(deskProvider).status;
        if (status == null || _behind) return;
        _engine?.refreshEnded(validated: status.nodeHealth != ServiceHealth.down);
      });
    });
    ref.listen(deskProvider.select((s) => torStateOf(s.settings, s.status)), (_, _) => later(() => _engine?.kick('tor')));
    // A pick the user made: what failover was doing is dropped at once.
    ref.listen(deskNodePicksProvider, (_, _) => userPicked());
    ref.listen(deskProvider.select((s) => s.settings.advanced.networkMode), (_, _) => later(() => _engine?.kick('network mode'))); // l10n-ok
    ref.listen(deskProvider.select((s) => s.settings.advanced.nodeFailover), (was, now) {
      if (was == false && now) later(() => _engine?.kick('failover on')); // l10n-ok
    });
    // A node added or taken out, here or in the settings file: a waiting round runs now.
    ref.listen(deskServerListProvider(ServerKind.node).select((l) => l?.entries), (was, now) {
      if (was != null && now != null && !listEquals(was, now)) later(() => _engine?.kick('node list')); // l10n-ok
    });
    later(() {
      _feed();
      _engine?.kick('wallet opened'); // l10n-ok
    });
  }

  /// Tells the engine what the node status reads now.
  void _feed() {
    final engine = _engine;
    final status = ref.read(deskProvider).status;
    if (engine == null || status == null) return;
    if (_ownSyncing && sameServer(ServerKind.node, status.node.url, _ownChosen ?? '')) {
      engine.nodeFailed();
      return;
    }
    switch (status.nodeHealth) {
      case ServiceHealth.down:
        engine.nodeFailed();
      case ServiceHealth.ok || ServiceHealth.slow:
        if (_behind) {
          engine.nodeBehind();
        } else {
          engine.nodeAnswered();
        }
      case _:
    }
  }

  /// The window came back (`shell.dart`): a node still not answering is asked again at once.
  /// Hidden to the tray the wallet keeps working, so nothing pauses meanwhile.
  void resumed() => kick('resume');

  /// A waiting round runs now.
  void kick(String why) => _engine?.kick(why);

  /// The user picked a node: what failover was doing is dropped.
  void userPicked() {
    _picks++;
    _ownSyncing = false;
    _good = 0;
    _engine?.userPicked();
  }

  /// Why the wallet may not move off the node in use now, or null.
  FailoverHold? _hold(DeskState st, ServiceStatus status) {
    // The built-in node is the user's own, also while a public node stands in as it syncs.
    if (ref.read(settingsPrefsProvider).builtin) return FailoverHold.localNode;
    final adv = st.settings.advanced;
    return failoverHold(
      on: adv.nodeFailover,
      mode: adv.networkMode,
      tor: torStateOf(st.settings, status),
      nodeUrl: status.node.url,
      busy: ref.read(deskApiProvider).busy,
    );
  }

  /// One tip ask through the open wallet (it follows its Tor and the gate); the engine bounds it.
  Future<FailoverAnswer> _probe(String url) async {
    final checked = await ref.read(deskApiProvider).checkNode(url);
    if (checked.health != ServiceHealth.ok && checked.health != ServiceHealth.slow) throw StateError('no answer');
    // The own node syncing while the user wants a public node meanwhile does not count.
    final syncingOwn = _ownSyncing && sameServer(ServerKind.node, url, _ownChosen ?? '');
    return FailoverAnswer(height: checked.height ?? 0, ready: syncingOwn ? false : null);
  }

  Future<FailoverPlan?> _plan(int gen) async {
    if (!_current(gen)) return null;
    final st = ref.read(deskProvider);
    final status = st.status;
    // No wallet, or a switch the user started: nothing is asked until it ends.
    if (st.account == null || status == null || ref.read(deskNodeSwitchProvider) != null) return null;
    final adv = st.settings.advanced;
    final current = status.node.url;
    final hold = _hold(st, status);
    if (hold != null && hold != FailoverHold.off) logInfo('desk', 'node failover held: ${hold.name}');
    final scope = failoverScope(hold, adv.networkMode);
    final overTor = st.settings.tor;
    if (scope != FailoverScope.all) {
      return FailoverPlan(inUse: current, chosen: current, candidates: const [], scope: scope, overTor: overTor, height: status.nodeHeight);
    }
    final chosen = ref.read(deskFailoverProvider)?.chosen ?? current;
    // Off the Node page the list keeps its last read, so the health that orders the candidates
    // is read again here; not waited for longer than the prefer window, it only orders them.
    var nodes = st.nodes ?? const <NodeServer>[];
    try {
      nodes = await ref.read(deskApiProvider).nodes().timeout(appConfig.nodeFailoverPrefer);
    } on Object {
      // Locked meanwhile, or no answer: the last read orders them.
    }
    if (!_current(gen)) return null;
    final entries = ref.read(deskServerListProvider(ServerKind.node))?.entries ?? [for (final n in nodes) n.url];
    final candidates = failoverCandidates(
      entries: entries,
      current: current,
      chosen: chosen,
      mode: adv.networkMode,
      overTor: (url) => failoverOverTor(url, hasOnion: (h, p) => torBuiltInOnion(h, p) != null),
      health: (url) => switch (nodes.where((n) => sameServer(ServerKind.node, n.url, url)).firstOrNull?.health) {
        ServiceHealth.ok => FailoverHealth.healthy,
        ServiceHealth.down => FailoverHealth.down,
        _ => FailoverHealth.unknown,
      },
    );
    return FailoverPlan(inUse: current, chosen: chosen, candidates: candidates, scope: scope, overTor: overTor, height: status.nodeHeight);
  }

  Future<bool> _switchTo(int gen, String url, {required bool behind}) async {
    if (!_current(gen) || ref.read(deskNodeSwitchProvider) != null) return false;
    final st = ref.read(deskProvider);
    final current = st.status?.node.url;
    if (st.account == null || current == null) return false;
    final picks = _picks;
    final chosen = ref.read(deskFailoverProvider)?.chosen ?? current;
    final syncing = _ownSyncing || (behind && ref.read(deskFailoverProvider)?.syncing == true);
    try {
      await ref.read(deskProvider.notifier).useNodeForSession(url);
    } on Object catch (e) {
      logWarn('desk', 'node failover refused: ${e.runtimeType}');
      return false;
    }
    // The user picked a node meanwhile: that one stands.
    if (!_current(gen) || picks != _picks) return false;
    final now = ref.read(deskProvider).status?.node.url;
    if (now == null || !sameServer(ServerKind.node, now, url)) return false;
    _ownSyncing = false;
    if (!sameServer(ServerKind.node, url, chosen)) {
      ref.read(deskFailoverProvider.notifier).moved(NodeFailover(chosen: chosen, inUse: url, at: DateTime.now(), syncing: syncing, behind: behind));
    }
    if (behind) logInfo('desk', 'node failover: left a node that was behind');
    return true;
  }

  /// The node in use answered a round: the wallet reads it again.
  void _stay(int gen) {
    if (!_current(gen)) return;
    unawaited(ref.read(deskProvider.notifier).syncNow().catchError((Object _) {}));
  }

  /// The last read of the node in use against the network's tip.
  NodeInfo? _lag;
  bool _askingBehind = false;

  /// May the wallet leave the node in use for being behind? Never one the user added or runs,
  /// and never while the rules hold it. Being in the middle of a payment only delays the move.
  bool get _mayLeaveBehind {
    final st = ref.read(deskProvider);
    final status = st.status;
    final prefs = ref.read(settingsPrefsProvider);
    if (st.account == null || status == null || prefs.builtin) return false;
    final url = status.node.url;
    if (status.node.own || nodeClassOf(url, mine: prefs.mineNodes.contains(url)).own) return false;
    final adv = st.settings.advanced;
    return failoverHold(on: adv.nodeFailover, mode: adv.networkMode, tor: torStateOf(st.settings, status), nodeUrl: url) == null;
  }

  /// The last read still says the node in use is behind, its height since counted in.
  bool get _behind {
    final status = ref.read(deskProvider).status;
    final info = _lag;
    if (status == null || info == null || !sameServer(ServerKind.node, info.url, status.node.url) || info.nodeClass.own) return false;
    return _mayLeaveBehind && failoverBehind(info.withNodeHeight(status.nodeHeight).blocksBehind);
  }

  /// The shell's ask ([behindAskEvery]): reads the node in use against the network's tip and
  /// tells the engine whether it is behind.
  Future<void> askBehind() async {
    if (!ref.mounted || _askingBehind) return;
    final gen = _build;
    if (!_mayLeaveBehind) {
      _lag = null;
      _feed();
      return;
    }
    final url = ref.read(deskProvider).status!.node.url;
    _askingBehind = true;
    try {
      final info = await ref.read(deskNodeProvider).nodeInfo(url);
      if (!_current(gen)) return;
      final was = _behind;
      _lag = info;
      _feed();
      // The rail's word follows now, not at its own next read.
      if (_behind != was) ref.invalidate(deskNodeInfoProvider(url));
    } on Object {
      // No reading: the last one stands until the next.
    } finally {
      _askingBehind = false;
    }
  }

  /// The chosen node when it is the user's own (not the built-in node), else null.
  String? get _ownChosen {
    final st = ref.read(deskProvider);
    final chosen = ref.read(deskFailoverProvider)?.chosen ?? st.status?.node.url;
    if (chosen == null || ref.read(settingsPrefsProvider).builtin) return null;
    final mine = ref.read(settingsPrefsProvider).mineNodes.contains(chosen);
    return nodeClassOf(chosen, mine: mine).own ? chosen : null;
  }

  /// "Try now" on the panel: one good answer moves back.
  Future<void> tryBack() => _askOwn(now: true);

  /// The shell's ask ([ownAskBackEvery]).
  Future<void> askOwn() => _askOwn();

  /// Asks the chosen own node: back after [ownBackAfter] good answers while a public node
  /// stands in; to a public node while it syncs, when the user said so for it.
  Future<void> _askOwn({bool now = false}) async {
    final own = _ownChosen;
    final gen = _build;
    if (own == null || _askingOwn || !ref.mounted) {
      _good = 0;
      if (own == null) _ownSyncing = false;
      return;
    }
    final moved = ref.read(deskFailoverProvider);
    final NodeHead? head;
    _askingOwn = true;
    try {
      final info = await ref.read(deskNodeProvider).nodeInfo(own, mine: ref.read(settingsPrefsProvider).mineNodes.contains(own));
      head = info.head;
      // The rail, the slot and the panel read it again too.
      ref.invalidate(deskNodeInfoProvider(own));
      ref.invalidate(deskOwnStatusProvider);
    } on Object {
      _good = 0;
      return;
    } finally {
      _askingOwn = false;
    }
    if (!_current(gen)) return;
    if (moved == null) {
      _good = 0;
      // Syncing, and the user wants a public node meanwhile: the own node counts as not
      // answering, and a round looks for one (never while the rules hold the wallet on it).
      final st = ref.read(deskProvider);
      final status = st.status;
      final wanted = head == NodeHead.syncing && ref.read(settingsPrefsProvider).ownFallback[own] == true;
      final may = status != null && _hold(st, status) == null;
      final was = _ownSyncing;
      _ownSyncing = wanted && may;
      if (_ownSyncing != was) _feed();
      return;
    }
    // Back once it answers (down) or accepts transactions (syncing) again, or when the user no
    // longer wants a public node while it syncs.
    final waitedOut = moved.syncing && ref.read(settingsPrefsProvider).ownFallback[own] == false;
    final good = moved.syncing ? head == NodeHead.synced : head != null && head != NodeHead.down;
    _good = good ? _good + 1 : 0;
    if (!waitedOut && (now ? _good < 1 : _good < ownBackAfter)) return;
    // A round or a switch the user started runs: the next ask moves back.
    if (_engine?.running == true || ref.read(deskNodeSwitchProvider) != null) return;
    _good = 0;
    _ownSyncing = false;
    try {
      await ref.read(deskProvider.notifier).useNodeForSession(own);
      logInfo('desk', 'node failover: back on the own node');
    } on Object catch (e) {
      logWarn('desk', 'node failover: back refused: ${e.runtimeType}');
    }
  }
}
