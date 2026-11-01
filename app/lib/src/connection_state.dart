// SPDX-License-Identifier: Apache-2.0
/// The node and Epicbox statuses the phone shows, settled: a status that leaves online for
/// offline, or for syncing, shows only once it has lasted [statusSettle]. Short node drops that
/// mend, and short refreshes, show nothing; a lost Epicbox connection reads connecting while
/// it is retried; a way back to online or connecting shows at once.
/// The header icons, the network status card and Receive all read [walletStatusProvider], so
/// they never disagree and nothing debounces twice.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'net/tor_switch.dart';
import 'phone_tor.dart';
import 'tor_phone.dart' show phoneTorState;
import 'tor_routes.dart';
import 'providers.dart';
import 'ui/status.dart';

/// How long node offline, node syncing and Epicbox offline must last before they show.
/// LEPIC's listener retries a dropped connection after 0.5–1 s and again 1–2 s later, so a
/// blip mends within it; a relay or node that is really gone shows after 5 s.
const Duration statusSettle = Duration(seconds: 5);

/// How long after tor came up the relay's first connection over it may take before a lost
/// one reads as offline again (android-09): a tor just up often fails its first connection to
/// an onion, and builds a circuit to the relay in up to about half a minute.
const Duration torRelayGrace = Duration(seconds: 60);

/// The statuses as they are this moment, from the node's tip, the refresh, the balances and
/// the listener ([walletStatus]). The UI reads [walletStatusProvider] instead.
final rawWalletStatusProvider = Provider<WalletStatus>((ref) {
  final home = ref.watch(homeProvider);
  final data = home.value;
  final syncing = data != null && (home.isLoading || data.syncing);
  return walletStatus(
    tip: ref.watch(nodeTipProvider),
    syncing: syncing,
    percent: syncing ? ref.watch(syncProgressProvider) : null,
    summary: data?.summary,
    listener: ref.watch(listenerProvider),
    // The phone's Tor controller runs from Home on; the status never starts it itself.
    waitingForTor:
        ref.exists(phoneTorProvider) &&
        torWay(TorRoute.epicbox, phoneTorState(ref.watch(phoneTorProvider))) ==
            TorWay.wait,
  );
});

/// [rawWalletStatusProvider], settled by [statusSettle].
final walletStatusProvider =
    NotifierProvider<WalletStatusNotifier, WalletStatus>(
      WalletStatusNotifier.new,
    );

class WalletStatusNotifier extends Notifier<WalletStatus> {
  /// Runs while the raw node status is offline or syncing and the shown one is not yet.
  Timer? _node;

  /// Runs while the raw Epicbox status is offline and the shown one is not yet.
  Timer? _epicbox;

  /// The relay's connection waited for Tor and has not been up over it since ([_heldForTor]).
  bool _torWaited = false;

  /// Runs from tor up until [torRelayGrace] while [_torWaited].
  Timer? _torGrace;

  /// Counts the builds. The notifier lives on across rebuilds, so `ref.mounted` stays true
  /// after a new wallet replaced a build: a settle queued by the old one checks this.
  int _build = 0;

  @override
  WalletStatus build() {
    // A new wallet starts over; within one, the raw status only feeds this.
    ref.watch(sessionProvider);
    final gen = ++_build;
    ref.onDispose(() {
      _node?.cancel();
      _epicbox?.cancel();
      _torGrace?.cancel();
      _node = _epicbox = _torGrace = null;
      _torWaited = false;
    });
    // The raw status may be rebuilt while a widget builds, when no provider may change: the
    // settled one follows a microtask later.
    ref.listen(
      rawWalletStatusProvider,
      (_, raw) => scheduleMicrotask(() {
        if (gen == _build && ref.mounted) _settle(_heldForTor(raw));
      }),
    );
    final raw = _heldForTor(ref.read(rawWalletStatusProvider));
    // Nothing shown yet: what waits for the settle time starts as connecting.
    final first = _settle(raw, (
      node: NodeStatus(NodeState.connecting, height: raw.node.height),
      epicbox: raw.epicbox == null ? null : EpicboxState.connecting,
    ));
    _loggedEpicbox = first.epicbox;
    return first;
  }

  /// Shows [raw] where it may show now, keeps [shown] (the current state) where it must
  /// first last, and starts or stops the timers to match. Returns the new state.
  WalletStatus _settle(WalletStatus raw, [WalletStatus? shown]) {
    final before = shown ?? state;
    final node = _waits(raw.node.state, before.node.state)
        ? before.node
        : raw.node;
    // A lost connection is retried at once: until offline has lasted, it reads connecting,
    // never the online it no longer is.
    final epicbox = _epicboxWaits(raw.epicbox, before.epicbox)
        ? EpicboxState.connecting
        : raw.epicbox;

    if (identical(node, raw.node)) {
      _node?.cancel();
      _node = null;
    } else {
      _node ??= Timer(statusSettle, () {
        _node = null;
        if (!ref.mounted) return;
        _show(node: _heldForTor(ref.read(rawWalletStatusProvider)).node);
      });
    }
    if (epicbox == raw.epicbox) {
      _epicbox?.cancel();
      _epicbox = null;
    } else {
      _epicbox ??= Timer(statusSettle, () {
        _epicbox = null;
        if (!ref.mounted) return;
        _show(epicbox: _heldForTor(ref.read(rawWalletStatusProvider)).epicbox);
      });
    }

    final next = (node: node, epicbox: epicbox);
    if (shown == null) _logFlips(before, next);
    if (shown == null) state = next;
    return next;
  }

  /// android-09: turning Tor on, or opening a wallet with it on, drops the relay connection on
  /// purpose, and the first connection over a tor just up often fails once. From the wait for
  /// Tor until the relay is up over it, at most [torRelayGrace] after tor came up, a lost
  /// connection reads as connecting, as while tor starts ([rawWalletStatusProvider]).
  WalletStatus _heldForTor(WalletStatus raw) {
    // The phone's Tor controller runs from Home on; the status never starts it itself.
    final way = ref.exists(phoneTorProvider)
        ? torWay(TorRoute.epicbox, phoneTorState(ref.read(phoneTorProvider)))
        : null;
    if (way == TorWay.wait) {
      _torWaited = true;
      _torGrace?.cancel();
      _torGrace = null;
      return raw;
    }
    if (!_torWaited) return raw;
    if (way != TorWay.overTor ||
        raw.epicbox == EpicboxState.online ||
        raw.epicbox == null) {
      _torWaited = false;
      _torGrace?.cancel();
      _torGrace = null;
      return raw;
    }
    _torGrace ??= Timer(torRelayGrace, () {
      _torGrace = null;
      _torWaited = false;
      if (ref.mounted) _settle(ref.read(rawWalletStatusProvider));
    });
    return raw.epicbox == EpicboxState.offline
        ? (node: raw.node, epicbox: EpicboxState.connecting)
        : raw;
  }

  void _show({NodeStatus? node, EpicboxState? epicbox}) {
    final next = (
      node: node ?? state.node,
      epicbox: node != null ? state.epicbox : epicbox,
    );
    _logFlips(state, next);
    state = next;
  }

  /// A node status that must last before it shows: offline or syncing, while the shown one is
  /// neither. Once one shows, the next (syncing to offline, a new percent) shows at once.
  static bool _waits(NodeState raw, NodeState shown) {
    bool slow(NodeState s) => s == NodeState.offline || s == NodeState.syncing;
    return slow(raw) && !slow(shown);
  }

  static bool _epicboxWaits(EpicboxState? raw, EpicboxState? shown) =>
      raw == EpicboxState.offline &&
      shown != EpicboxState.offline &&
      shown != null;

  /// The Epicbox status the log last named: a drop that mends reads connecting and online
  /// again, which it does not name twice.
  EpicboxState? _loggedEpicbox;

  /// One log line when a shown status turns offline or back, with what it rests on.
  void _logFlips(WalletStatus before, WalletStatus after) {
    final node = after.node.state;
    if (node != before.node.state &&
        (node == NodeState.offline || before.node.state == NodeState.offline)) {
      logInfo(
        'status',
        'node ${node.name} (source: node tip and refresh'
            '${after.node.validated ? '' : ', balances not checked'})',
      );
    }
    final epicbox = after.epicbox;
    if (epicbox != before.epicbox &&
        epicbox != _loggedEpicbox &&
        (epicbox == EpicboxState.offline ||
            epicbox == EpicboxState.online ||
            epicbox == null)) {
      _loggedEpicbox = epicbox;
      logInfo(
        'status',
        'epicbox ${epicbox?.name ?? 'stopped'} (source: listener socket)',
      );
    }
  }
}

/// When the node is asked again after the network returns or the app resumes while it reads
/// offline: at once, then twice more while a new network settles (DNS, a first route).
const List<Duration> nodeRecheckDelays = [
  Duration.zero,
  Duration(seconds: 3),
  Duration(seconds: 10),
];

/// Clears a stale node offline after a network change or a resume without waiting for the
/// next minute's refresh: asks the node's tip ([nodeRecheckDelays]) and, once it answers,
/// refreshes the balances so the ones the node could not check are checked again. Alive for
/// the app's life (`WalletApp`); does nothing while the node reads anything but offline.
///
/// While the Tor switch is on the node is asked once tor has renewed its connections after
/// the network change ([torRenewalsProvider]), whatever the node reads: the renewal closes
/// every connection through tor, so a question asked before it fails, and one asked after it
/// goes out on the new circuits at once (android-04).
final nodeRecheckProvider = NotifierProvider<NodeRecheckNotifier, void>(
  NodeRecheckNotifier.new,
);

class NodeRecheckNotifier extends Notifier<void> {
  /// Bumped by each recheck and by a new wallet: an older run stops.
  int _run = 0;

  @override
  void build() {
    final session = ref.watch(sessionProvider);
    ref.onDispose(() => _run++);
    if (session == null) return;
    final network = ref.watch(networkChangesProvider).listen((available) {
      if (available && !TorSwitch.on) unawaited(recheck('network'));
    });
    ref.onDispose(network.cancel);
    ref.listen(torRenewalsProvider, (_, _) {
      unawaited(recheck('tor renewed', evenOnline: true));
    });
  }

  bool get _offline =>
      ref.read(rawWalletStatusProvider).node.state == NodeState.offline;

  /// [evenOnline]: asks a node that reads online too.
  Future<void> recheck(String why, {bool evenOnline = false}) async {
    if (ref.read(sessionProvider) == null || !(evenOnline || _offline)) return;
    final run = ++_run;
    logInfo('status', 'node recheck on $why');
    for (final delay in nodeRecheckDelays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (!ref.mounted || run != _run) return;
      ref.invalidate(nodeTipProvider);
      // Held while asked: nothing else may watch the tip at this moment.
      final tip = ref.listen(nodeTipProvider.future, (_, _) {});
      try {
        await tip.read();
      } catch (_) {
        continue;
      } finally {
        tip.close();
      }
      if (!ref.mounted || run != _run) return;
      logInfo('status', 'node answers again');
      if (ref.exists(homeProvider) && _offline) {
        unawaited(
          ref.read(homeProvider.notifier).reload().catchError((Object _) {}),
        );
      }
      return;
    }
    logInfo('status', 'node still unreachable; the minute refresh tries again');
  }
}
