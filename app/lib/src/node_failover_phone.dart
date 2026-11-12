// SPDX-License-Identifier: Apache-2.0
/// Node failover on the phone: the adapter between the app and the engine both apps run
/// (`node_failover_engine.dart`; `node_failover.dart` has the rules). It feeds the engine what
/// the node status sees ([rawWalletStatusProvider], the refreshes), and gives it a way to ask a
/// node, a way to move the open wallet for this session ([switchNodeForSession]) and the plan of
/// a round. [nodeFailoverProvider] holds the move, or null while the wallet is on the chosen
/// node; the status card names the chosen node beside the one in use. The search shows in the
/// status ([nodeFailoverSearchProvider]): connecting while it runs, offline when nothing answers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart';
import 'btlabs_onions.dart';
import 'connection_state.dart';
import 'log.dart';
import 'net/tor_switch.dart';
import 'node_failover.dart';
import 'node_failover_engine.dart';
import 'phone_tor.dart';
import 'providers.dart';
import 'network.dart' show NetworkPreset;
import 'relay_directory.dart' as directory show NodeHealthState, NodeStatus, nodeStatusFor;
import 'server_list_store.dart';
import 'server_switch.dart';
import 'settings.dart';
import 'tor_phone.dart';
import 'tor_routes.dart';
import 'wallet_service.dart';
import 'settings_file/host_settings.dart' show appConfig;
import 'ui/server_picker.dart' show publicNodeStatusProvider;
import 'ui/status.dart' show NodeState, WalletStatus;

/// The move node failover made for this session, or null on the chosen node. Screens watch
/// this; [nodeFailoverWatchProvider] makes the moves.
final nodeFailoverProvider = NotifierProvider<NodeFailoverState, NodeFailover?>(
  NodeFailoverState.new,
);

class NodeFailoverState extends Notifier<NodeFailover?> {
  @override
  NodeFailover? build() {
    // A new wallet (an unlock, the next start) opens on the chosen node.
    ref.watch(sessionProvider);
    // A node the user picks is the chosen one from then on.
    ref.listen(walletConfigProvider, (_, config) {
      final moved = state;
      if (moved != null && (config == null || !sameServer(ServerKind.node, config.nodeUrl, moved.inUse))) {
        state = null;
      }
    });
    ref.listen(networkChoiceProvider, (_, choice) {
      final moved = state;
      final url = choice.value?.nodeUrl;
      if (moved != null && url != null && !sameServer(ServerKind.node, url, moved.chosen)) state = null;
    });
    return null;
  }

  void moved(NodeFailover to) => state = to;
}

/// The watcher: alive for the app's life (`app.dart`), one engine per open wallet.
final nodeFailoverWatchProvider = NotifierProvider<NodeFailoverWatch, void>(
  NodeFailoverWatch.new,
);

class NodeFailoverWatch extends Notifier<void> {
  FailoverEngine? _engine;

  /// The app is on screen (`app.dart` says when it is not): no node is asked meanwhile.
  bool _onScreen = true;

  /// Counts the builds. The notifier lives on across rebuilds, so `ref.mounted` stays true
  /// after a new wallet replaced a build; [_current] tells whether one is still the newest.
  int _build = 0;

  bool _current(int gen) => gen == _build && ref.mounted;

  /// Follows the Tor phase once the phone's Tor controller runs (the watcher never starts it).
  ProviderSubscription<Object?>? _tor;

  @override
  void build() {
    // A new wallet starts over.
    final session = ref.watch(sessionProvider);
    final gen = ++_build;
    _engine?.dispose();
    _engine = null;
    _tor = null;
    if (session == null) return;
    final engine = FailoverEngine(
      probe: (url) => _probe(session, url),
      switchTo: (url, {required behind}) => _switchTo(gen, url, behind: behind),
      plan: () => _plan(gen, session),
      timings: () => failoverTimings,
      stay: () => _stay(gen),
      onState: (s) {
        if (_current(gen)) ref.read(nodeFailoverSearchProvider.notifier).set(s);
      },
      log: (line) => logInfo('network', line),
      freshConnections: () => ref.read(sessionProvider)?.dropNodeConnections(),
    );
    _engine = engine;
    if (!_onScreen) engine.pause();
    ref.onDispose(engine.dispose);

    // The status may be rebuilt while a widget builds, when no provider may change: what it
    // says reaches the engine a microtask later.
    void later(void Function() run) => scheduleMicrotask(() {
      if (_current(gen)) run();
    });
    ref.listen(
      rawWalletStatusProvider.select((s) => (s.node.state, s.node.behind != null)),
      (_, _) => later(_feed),
    );
    // Each answer or failure of the tip ask counts, also one that leaves the status as it was.
    ref.listen(nodeTipProvider, (_, tip) {
      if (!tip.isLoading) later(_feed);
    });
    ref.listen(homeProvider, (before, now) {
      if (before == null || !homeRefreshing(before) || homeRefreshing(now)) return;
      later(() {
        // A node behind the wallet leaves its balances unchecked: that is behind, not down.
        if (ref.read(rawWalletStatusProvider).node.behind != null) return;
        _engine?.refreshEnded(validated: !now.hasError && (now.value?.summary.validatedWithNode ?? false));
      });
    });
    ref.listen(
      appSettingsProvider.select((s) => s.value?.advanced.nodeFailover),
      (before, now) {
        if (before == false && now == true) later(() => _engine?.kick('failover on'));
      },
    );
    ref.listen(autoLockHoldProvider, (before, now) {
      if ((before ?? 0) > 0 && now == 0) later(() => _engine?.kick('payment done'));
    });
    ref.listen(networkModeProvider, (_, _) => later(() => _engine?.kick('network mode')));
    later(() {
      _feed();
      _engine?.kick('wallet opened');
    });
  }

  /// Tells the engine what the node status reads now.
  void _feed() {
    final engine = _engine;
    if (engine == null) return;
    _followTor();
    final node = ref.read(rawWalletStatusProvider).node;
    switch (node.state) {
      case NodeState.offline when node.behind != null:
        engine.nodeBehind();
      case NodeState.offline:
        engine.nodeFailed();
      case NodeState.online || NodeState.syncing:
        engine.nodeAnswered();
      case _:
    }
  }

  void _followTor() {
    if (_tor != null || !ref.exists(phoneTorProvider)) return;
    final gen = _build;
    _tor = ref.listen(phoneTorProvider.select((s) => s.phase), (_, _) {
      scheduleMicrotask(() {
        if (_current(gen)) _engine?.kick('tor');
      });
    });
  }

  /// The app left the screen: nothing is asked until it is back.
  void paused() {
    _onScreen = false;
    _engine?.pause();
  }

  /// Back on screen: a node still not answering is asked again at once.
  void resumed() {
    _onScreen = true;
    _engine?.resume();
  }

  /// A network change, a resume, tor renewed: a waiting round runs now.
  void kick(String why) => _engine?.kick(why);

  /// The user picked a node: what failover was doing is dropped.
  void userPicked() => _engine?.userPicked();

  /// [url]'s tip through the open wallet (so it follows its Tor), through the gate.
  Future<FailoverAnswer> _probe(WalletSession session, String url) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) throw StateError('No wallet open');
    final tip = await askNodeTip(
      ref.read(walletServiceProvider),
      session,
      WalletConfig(
        dataDir: config.dataDir,
        chain: config.chain,
        nodeUrl: url,
        epicboxDomain: config.epicboxDomain,
        epicboxPort: config.epicboxPort,
        walletId: config.walletId,
      ),
    );
    return FailoverAnswer(height: tip.height.toInt(), ready: tip.readyForTxs);
  }

  Future<bool> _switchTo(int gen, String url, {required bool behind}) async {
    if (!_current(gen)) return false;
    final choice = await ref.read(networkChoiceProvider.future);
    if (!_current(gen)) return false;
    final chosen = ref.read(nodeFailoverProvider)?.chosen ?? choice.nodeUrl;
    try {
      if (!await switchNodeForSession(ref, url)) return false;
    } on Object catch (e) {
      logWarn('network', 'node failover refused: ${e.runtimeType}');
      return false;
    }
    if (!_current(gen)) return true;
    // Back on the chosen node there is no move to name.
    if (!sameServer(ServerKind.node, url, chosen)) {
      ref.read(nodeFailoverProvider.notifier).moved(NodeFailover(chosen: chosen, inUse: url, behind: behind));
    }
    return true;
  }

  void _stay(int gen) {
    if (!_current(gen)) return;
    ref.invalidate(nodeTipProvider);
    if (ref.exists(homeProvider)) {
      unawaited(ref.read(homeProvider.notifier).reload().catchError((Object _) {}));
    }
  }

  Future<FailoverPlan?> _plan(int gen, WalletSession session) async {
    final config = ref.read(walletConfigProvider);
    if (!_current(gen) || ref.read(sessionProvider) != session || config == null) return null;
    _followTor();
    final settings = ref.read(appSettingsProvider).value;
    final mode = ref.read(networkModeProvider);
    final tor = ref.exists(phoneTorProvider) ? phoneTorState(ref.read(phoneTorProvider)) : TorState.off;
    final hold = failoverHold(
      on: settings?.advanced.nodeFailover ?? const AdvancedPrefs().nodeFailover,
      mode: mode,
      tor: tor,
      nodeUrl: config.nodeUrl,
      busy: ref.read(autoLockHoldProvider) > 0,
    );
    if (hold != null && hold != FailoverHold.off) logInfo('network', 'node failover held: ${hold.name}');
    final scope = failoverScope(hold, mode);
    final WalletStatus raw = ref.read(rawWalletStatusProvider);
    final height = raw.node.tip?.height.toInt();
    if (scope != FailoverScope.all) {
      return FailoverPlan(inUse: config.nodeUrl, chosen: config.nodeUrl, candidates: const [], scope: scope, overTor: TorSwitch.on, height: height);
    }
    final choice = await ref.read(networkChoiceProvider.future);
    if (!_current(gen)) return null;
    final chosen = ref.read(nodeFailoverProvider)?.chosen ?? choice.nodeUrl;
    final list = await ref.read(serverListProvider((ServerKind.node, config.chain)).future);
    final listed = await _monitor(choice.preset);
    if (!_current(gen)) return null;
    final onions = onionLookupOf(ref.read(onionDirectoryProvider));
    final candidates = failoverCandidates(
      entries: list.entries,
      current: config.nodeUrl,
      chosen: chosen,
      mode: mode,
      overTor: (url) => failoverOverTor(url, hasOnion: (h, p) => onions(h, p) != null),
      health: (url) => switch (directory.nodeStatusFor(listed, url)?.state) {
        directory.NodeHealthState.healthy => FailoverHealth.healthy,
        directory.NodeHealthState.down => FailoverHealth.down,
        _ => FailoverHealth.unknown,
      },
    );
    return FailoverPlan(
      inUse: config.nodeUrl,
      chosen: chosen,
      candidates: candidates,
      scope: scope,
      overTor: TorSwitch.on,
      height: height,
    );
  }

  /// The monitor's view of the public nodes, or none when it does not answer at once: it only
  /// orders the list, so a round does not wait for it longer than the prefer window.
  Future<List<directory.NodeStatus>> _monitor(NetworkPreset preset) async {
    final sub = ref.listen(publicNodeStatusProvider(preset).future, (_, _) {});
    try {
      return await sub.read().timeout(appConfig.nodeFailoverPrefer);
    } on Object {
      return const [];
    } finally {
      sub.close();
    }
  }
}
