/// Node failover on the desktop (`node_failover.dart` has the rules): once the wallet's node has
/// read down ([ServiceStatus.nodeHealth], what the rail shows) for [nodeFailoverAfter], the
/// open wallet moves to the next working node of the user's list for this session
/// ([DeskWalletApi.useNodeForSession]). [deskFailoverProvider] holds the move, or null while the
/// wallet is on the chosen node; the shell says it in a toast and the rail and Settings › Node
/// name the chosen node under the one in use.
///
/// The user's own node: while a public node stands in for it, it is asked
/// again every [ownAskBackEvery] and the wallet moves back after [ownBackAfter] good answers in
/// a row, a home node coming back being the normal case. An own node that is syncing moves the
/// wallet to a public node only when the user said so for that node (the fallback question on its
/// panel), and back once it accepts transactions.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../net/local_address.dart' show nodeClassOf;
import '../data/desk_node.dart' show deskNodeProvider, deskNodeInfoProvider, deskOwnStatusProvider, NodeHead;
import '../../net/tor_net.dart' show torBuiltInOnion;
import '../../node_failover.dart';
import '../data/models.dart';
import '../data/server_lists.dart';
import '../data/state.dart';
import '../data/tor_view.dart';
import '../screens/settings/prefs.dart' show settingsPrefsProvider;

export '../../node_failover.dart' show NodeFailover;

/// How often a move held back (Tor starting, nothing working) is tried again while the node
/// stays down.
const Duration deskFailoverRetry = Duration(seconds: 30);

/// How often the chosen own node is asked while a public node stands in for it, or while it
/// may be syncing.
const Duration ownAskBackEvery = Duration(seconds: 15);

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

/// The watcher: alive while the shell shows (`shell.dart`), it times the node's silence and moves.
final deskFailoverWatchProvider = NotifierProvider<DeskFailoverWatch, void>(DeskFailoverWatch.new);

class DeskFailoverWatch extends Notifier<void> {
  Timer? _timer;
  bool _moving = false;
  int _good = 0;

  @override
  void build() {
    ref.watch(deskProvider.select((s) => s.account?.id));
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    ref.listen(deskProvider.select((s) => s.status?.nodeHealth), (_, h) => _follow(h));
    _follow(ref.read(deskProvider).status?.nodeHealth);
  }

  bool get _down => ref.read(deskProvider).status?.nodeHealth == ServiceHealth.down;

  void _follow(ServiceHealth? health) {
    if (health != ServiceHealth.down) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer(nodeFailoverAfter, _fire);
  }

  void _fire() {
    _timer = null;
    if (!ref.mounted) return;
    unawaited(_tryMove().then((again) {
      if (again && ref.mounted && _down) _timer ??= Timer(deskFailoverRetry, _fire);
    }));
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

  /// The shell's 15 s ask ([ownAskBackEvery]).
  Future<void> askOwn() => _askOwn();

  /// Asks the chosen own node: back after [ownBackAfter] good answers while a public node
  /// stands in; to a public node while it syncs, when the user said so for it.
  Future<void> _askOwn({bool now = false}) async {
    final own = _ownChosen;
    if (own == null || _moving || !ref.mounted) {
      _good = 0;
      return;
    }
    final moved = ref.read(deskFailoverProvider);
    final NodeHead? head;
    try {
      final info = await ref.read(deskNodeProvider).nodeInfo(own, mine: ref.read(settingsPrefsProvider).mineNodes.contains(own));
      head = info.head;
      // The rail, the slot and the panel read it again too.
      ref.invalidate(deskNodeInfoProvider(own));
      ref.invalidate(deskOwnStatusProvider);
    } on Object {
      _good = 0;
      return;
    }
    if (!ref.mounted) return;
    if (moved == null) {
      _good = 0;
      if (head == NodeHead.syncing && ref.read(settingsPrefsProvider).ownFallback[own] == true) {
        await _tryMove(syncing: true);
      }
      return;
    }
    // Back once it answers (down) or accepts transactions (syncing) again, or when the user no
    // longer wants a public node while it syncs.
    final waitedOut = moved.syncing && ref.read(settingsPrefsProvider).ownFallback[own] == false;
    final good = moved.syncing ? head == NodeHead.synced : head != null && head != NodeHead.down;
    _good = good ? _good + 1 : 0;
    if (!waitedOut && (now ? _good < 1 : _good < ownBackAfter)) return;
    _good = 0;
    _moving = true;
    try {
      await ref.read(deskProvider.notifier).useNodeForSession(own);
      logInfo('desk', 'node failover: back on the own node');
    } on Object catch (e) {
      logWarn('desk', 'node failover: back refused: ${e.runtimeType}');
    } finally {
      _moving = false;
    }
  }

  /// One try: true when it should be tried again while the node stays down. [syncing]: the
  /// chosen own node is syncing and the user wants a public node meanwhile.
  Future<bool> _tryMove({bool syncing = false}) async {
    final st = ref.read(deskProvider);
    final status = st.status;
    if (st.account == null || status == null || _moving) return false;
    final adv = st.settings.advanced;
    final current = status.node.url;
    // The built-in node is the user's own, also while a public node stands in as it syncs.
    final hold = ref.read(settingsPrefsProvider).builtin
        ? FailoverHold.localNode
        : failoverHold(
            on: adv.nodeFailover,
            mode: adv.networkMode,
            tor: torStateOf(st.settings, status),
            nodeUrl: current,
          );
    if (hold != null) {
      if (hold != FailoverHold.off) logInfo('desk', 'node failover held: ${hold.name}');
      return hold == FailoverHold.waitingForTor;
    }
    _moving = true;
    try {
      final chosen = ref.read(deskFailoverProvider)?.chosen ?? current;
      final nodes = st.nodes ?? const <NodeServer>[];
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
      final api = ref.read(deskApiProvider);
      for (final url in candidates) {
        if (!ref.mounted || !(_down || syncing) || ref.read(deskProvider).account?.id != st.account?.id) return false;
        try {
          final checked = await api.checkNode(url).timeout(nodeFailoverProbe);
          if (checked.health != ServiceHealth.ok) continue;
        } on Object {
          continue;
        }
        if (!ref.mounted || !(_down || syncing)) return false;
        try {
          await ref.read(deskProvider.notifier).useNodeForSession(url);
        } on Object catch (e) {
          logWarn('desk', 'node failover refused: ${e.runtimeType}');
          continue;
        }
        if (!ref.mounted) return false;
        final now = ref.read(deskProvider).status?.node.url;
        if (now == null || !sameServer(ServerKind.node, now, url)) return false;
        ref.read(deskFailoverProvider.notifier).moved(NodeFailover(chosen: chosen, inUse: url, at: DateTime.now(), syncing: syncing));
        return false;
      }
      logInfo('desk', 'node failover: no other node answers; staying');
      return true;
    } finally {
      _moving = false;
    }
  }
}
