// SPDX-License-Identifier: Apache-2.0
/// Node failover on the phone (`node_failover.dart` has the rules): watches the node status
/// Home shows ([walletStatusProvider]) and, once the node in use has not answered for
/// [nodeFailoverAfter], moves the open wallet to the next working node of the user's list for
/// this session ([switchNodeForSession]). [nodeFailoverProvider] holds the move, or null while
/// the wallet is on the chosen node; the app says it in a notice (`app.dart`) and the status
/// card names the chosen node beside the one in use.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart';
import 'btlabs_onions.dart';
import 'connection_state.dart';
import 'log.dart';
import 'node_failover.dart';
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
import 'ui/status.dart' show NodeState;

/// While the shown status reads offline, how much longer before the move: the shown status
/// already waited [statusSettle], so the node has not answered for [nodeFailoverAfter].
Duration get _afterShown => nodeFailoverAfter - statusSettle;

/// How often a move held back (a payment being sent, nothing working) is tried again while the
/// node still does not answer; with nothing working, longer each time ([failoverRetryAfter]).
Duration get nodeFailoverRetry => appConfig.nodeFailoverAfter;

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

/// The watcher: alive for the app's life (`app.dart`), it times the node's silence and moves.
final nodeFailoverWatchProvider = NotifierProvider<NodeFailoverWatch, void>(
  NodeFailoverWatch.new,
);

class NodeFailoverWatch extends Notifier<void> {
  Timer? _timer;

  /// A move is running: a second one waits for the next offline.
  bool _moving = false;

  /// Tries in a row that found no other node answering.
  int _failed = 0;

  /// The app is on screen (`app.dart` says when it is not): no node is asked meanwhile.
  bool _onScreen = true;

  @override
  void build() {
    // A new wallet starts over.
    ref.watch(sessionProvider);
    _failed = 0;
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    ref.listen(walletStatusProvider.select((s) => s.node.state), (_, node) => _follow(node));
    final network = ref.watch(networkChangesProvider).listen((available) {
      if (available) _startOver();
    });
    ref.onDispose(network.cancel);
  }

  bool get _offline => ref.read(walletStatusProvider).node.state == NodeState.offline;

  void _follow(NodeState node) {
    if (node != NodeState.offline) {
      _failed = 0;
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_onScreen) _timer ??= Timer(_afterShown, _fire);
  }

  void _fire() {
    _timer = null;
    if (!ref.mounted || !_onScreen) return;
    unawaited(_tryMove().then((tryAgain) {
      if (!tryAgain || !ref.mounted || !_onScreen) return;
      if (_offline) _timer ??= Timer(failoverRetryAfter(_failed, nodeFailoverRetry), _fire);
    }));
  }

  /// A new network: a retry that waits longer than the first comes at the first wait again.
  /// The first move keeps its time.
  void _startOver() {
    if (_failed == 0) return;
    _failed = 0;
    if (!_onScreen || _moving) return;
    _timer?.cancel();
    _timer = _offline ? Timer(nodeFailoverRetry, _fire) : null;
  }

  /// The app left the screen: nothing is asked until it is back.
  void paused() {
    _onScreen = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Back on screen: a node still not answering is tried again after the first wait.
  void resumed() {
    _onScreen = true;
    _failed = 0;
    if (!ref.mounted || _moving) return;
    if (_offline) _timer ??= Timer(nodeFailoverRetry, _fire);
  }

  /// One try: true when it should be tried again while the node stays offline.
  Future<bool> _tryMove() async {
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null || _moving) return false;
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
    if (hold != null) {
      // Nothing is asked while held: the next try comes at the first wait.
      _failed = 0;
      if (hold != FailoverHold.off) logInfo('network', 'node failover held: ${hold.name}');
      return hold == FailoverHold.busy || hold == FailoverHold.waitingForTor;
    }
    _moving = true;
    try {
      final choice = await ref.read(networkChoiceProvider.future);
      if (!ref.mounted) return false;
      final chosen = ref.read(nodeFailoverProvider)?.chosen ?? choice.nodeUrl;
      final list = await ref.read(serverListProvider((ServerKind.node, config.chain)).future);
      final listed = await _monitor(choice.preset);
      if (!ref.mounted) return false;
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
      for (final url in candidates) {
        if (!ref.mounted || ref.read(sessionProvider) != session) return false;
        // Still not answering, and nothing being sent: a payment going out waits for no move.
        if (ref.read(walletStatusProvider).node.state != NodeState.offline) return false;
        if (ref.read(autoLockHoldProvider) > 0) return true;
        if (!await _answers(session, config, url)) continue;
        if (!ref.mounted || ref.read(autoLockHoldProvider) > 0) return ref.mounted;
        try {
          if (!await switchNodeForSession(ref, url)) return false;
        } on Object catch (e) {
          logWarn('network', 'node failover refused: ${e.runtimeType}');
          continue;
        }
        ref.read(nodeFailoverProvider.notifier).moved(NodeFailover(chosen: chosen, inUse: url));
        return false;
      }
      logInfo('network', 'node failover: no other node answers; staying');
      _failed++;
      return true;
    } finally {
      _moving = false;
    }
  }

  /// The monitor's view of the public nodes, or none when it does not answer.
  Future<List<directory.NodeStatus>> _monitor(NetworkPreset preset) async {
    final sub = ref.listen(publicNodeStatusProvider(preset).future, (_, _) {});
    try {
      return await sub.read().timeout(nodeFailoverProbe);
    } on Object {
      return const [];
    } finally {
      sub.close();
    }
  }

  /// Whether [url] answers a tip request through the open wallet (so it follows its Tor).
  Future<bool> _answers(WalletSession session, WalletConfig config, String url) async {
    try {
      await session
          .nodeTipFor(
            config: WalletConfig(
              dataDir: config.dataDir,
              chain: config.chain,
              nodeUrl: url,
              epicboxDomain: config.epicboxDomain,
              epicboxPort: config.epicboxPort,
              walletId: config.walletId,
            ),
          )
          .timeout(nodeFailoverProbe);
      return true;
    } on Object {
      return false;
    }
  }
}
