// SPDX-License-Identifier: Apache-2.0
/// The Epicbox relay offer on the phone (`relay_switch.dart` has the rules): watches the
/// Epicbox status Home shows ([walletStatusProvider]) and, once the relay in use has not
/// answered for [relaySwitchAfter] and another relay of the list is seen healthy, holds an
/// offer in [relaySwitchProvider]. Nothing moves until the user accepts
/// ([RelaySwitchNotifier.accept]); "Keep waiting" ([RelaySwitchNotifier.keepWaiting]) holds the
/// offer back until the relay answers again or [relayKeepWaitingFor] passes.
///
/// After a move the old relay is drained for [relayDrainWindow] ([relayDrainWatchProvider]),
/// so payments sent to the old address still arrive.
///
/// Both notifiers run while something listens: `app.dart` keeps them alive beside node
/// failover and calls [RelaySwitchNotifier.paused] / [RelaySwitchNotifier.resumed].
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../btlabs_onions.dart';
import '../connection_state.dart';
import '../log.dart';
import '../network.dart';
import '../network_gate.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../relay_directory.dart' show RelayStatus, relayStatusProvider;
import '../server_switch.dart';
import '../settings.dart';
import '../secret_store_api.dart' show SecretStore;
import '../settings_file/host_settings.dart' show EpicboxServer;
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../ui/status.dart' show EpicboxState;
import '../wallet_service.dart';
import 'level_providers.dart' show levelFeaturesProvider;
import 'relay_switch.dart';

/// How often the offer is looked at again while the relay stays down (the other relays' health
/// changes, a Keep waiting runs out).
const Duration relaySwitchRecheck = Duration(minutes: 1);

/// How long the status site may take to say which relays are healthy.
const Duration _healthWait = Duration(seconds: 10);

/// What a move did, for Receive: the relay now in use, its name and the wallet's address there.
class RelaySwitchResult {
  const RelaySwitchResult({required this.from, required this.relay, required this.name, required this.address});

  /// The relay the wallet left, drained for [relayDrainWindow].
  final EpicboxRelay from;
  final EpicboxRelay relay;
  final String name;

  /// The new address (`<key>@<relay>`); null when the wallet did not give it.
  final String? address;
}

/// The offer, or null. Screens watch it; only [RelaySwitchNotifier.accept] moves the wallet.
final relaySwitchProvider = NotifierProvider<RelaySwitchNotifier, RelaySwitchOffer?>(RelaySwitchNotifier.new);

/// The last move the user accepted, until the screen that shows it clears it.
final relaySwitchResultProvider = NotifierProvider<RelaySwitchResultNotifier, RelaySwitchResult?>(
  RelaySwitchResultNotifier.new,
);

class RelaySwitchResultNotifier extends Notifier<RelaySwitchResult?> {
  @override
  RelaySwitchResult? build() {
    // A new wallet (an unlock, the next start) has no move to show.
    ref.watch(sessionProvider);
    return null;
  }

  void set(RelaySwitchResult result) => state = result;

  void clear() => state = null;
}

class RelaySwitchNotifier extends Notifier<RelaySwitchOffer?> {
  Timer? _timer;

  /// Since when the shown Epicbox status reads offline or blocked; null while it does not.
  DateTime? _since;

  /// When the user chose Keep waiting during this outage.
  DateTime? _keptWaitingAt;

  bool _onScreen = true;
  bool _checking = false;
  bool _moving = false;

  /// Counts the builds: a check that began for a replaced wallet drops its answer.
  int _build = 0;

  DateTime _now() => ref.read(clockProvider)();

  @override
  RelaySwitchOffer? build() {
    ref.watch(sessionProvider);
    ++_build;
    // Level 1 only ([LevelFeatures.relaySwitchPrompt]): the other levels pick servers by hand.
    final prompt = ref.watch(levelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    _since = null;
    _keptWaitingAt = null;
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    if (!prompt) return null;
    ref.listen(walletStatusProvider.select((s) => s.epicbox), (_, epicbox) => _follow(epicbox));
    // A relay already down when the wallet opened counts from now (after the build: the state
    // is not set yet).
    final gen = _build;
    Future<void>.delayed(Duration.zero, () {
      if (ref.mounted && gen == _build) _follow(ref.read(walletStatusProvider).epicbox);
    });
    return null;
  }

  static bool _down(EpicboxState? s) => s == EpicboxState.offline || s == EpicboxState.blocked;

  void _follow(EpicboxState? epicbox) {
    if (!_down(epicbox)) {
      // Answering again (or stopped): the outage and its Keep waiting are over.
      _since = null;
      _keptWaitingAt = null;
      _timer?.cancel();
      _timer = null;
      if (state != null) state = null;
      return;
    }
    // The shown status already waited [statusSettle] before it read offline.
    _since ??= _now().subtract(statusSettle);
    _arm();
  }

  void _arm() {
    if (!_onScreen || _since == null || _timer != null) return;
    final left = relaySwitchAfter - _now().difference(_since!);
    _timer = Timer(left.isNegative ? Duration.zero : left, _fire);
  }

  void _fire() {
    _timer = null;
    if (!ref.mounted || !_onScreen || _since == null) return;
    unawaited(_check().whenComplete(() {
      if (ref.mounted && _since != null && _onScreen) _timer ??= Timer(relaySwitchRecheck, _fire);
    }));
  }

  /// The app left the screen: no relay health is asked until it is back. The outage keeps its
  /// start, so the offer can come at once on return.
  void paused() {
    _onScreen = false;
    _timer?.cancel();
    _timer = null;
  }

  void resumed() {
    _onScreen = true;
    if (ref.mounted) _arm();
  }

  /// Not now: no offer until the relay answers again or [relayKeepWaitingFor] passes.
  void keepWaiting() {
    _keptWaitingAt = _now();
    state = null;
  }

  Future<void> _check() async {
    if (_checking) return;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    final since = _since;
    if (session == null || config == null || since == null) return;
    final gen = _build;
    _checking = true;
    try {
      final mode = ref.read(networkModeProvider);
      final tor = ref.exists(phoneTorProvider) ? phoneTorState(ref.read(phoneTorProvider)) : TorState.off;
      // Nothing is asked while no relay may be offered.
      if (relaySwitchHold(mode: mode, tor: tor, epicboxOn: NetGate.epicbox) != null) {
        if (state != null) state = null;
        return;
      }
      final inUse = EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
      final candidates = relayCandidatesOf(ref.read(hostSettingsProvider).epicboxServers);
      final choice = await ref.read(networkChoiceProvider.future);
      final listed = await _health(choice.preset);
      String? address;
      try {
        address = await session.epicboxAddress();
      } on Object {
        address = null;
      }
      if (gen != _build || !ref.mounted || ref.read(sessionProvider) != session) return;
      final onions = onionLookupOf(ref.read(onionDirectoryProvider));
      final offer = relaySwitchOffer(
        inUse: inUse,
        unreachableSince: _since,
        now: _now(),
        candidates: candidates,
        health: (r) => relayHealthOf(listed, r),
        mode: mode,
        tor: tor,
        epicboxOn: NetGate.epicbox,
        overTor: (r) => relayOverTor(r, hasOnion: (h, p) => onions(h, p) != null),
        keptWaitingAt: _keptWaitingAt,
        address: address,
      );
      if (offer != state) {
        if (offer != null) logInfo('network', 'relay ${inUse.label} down; offering ${offer.to.label}');
        state = offer;
      }
    } finally {
      _checking = false;
    }
  }

  /// The status site's view of the relays, or none when it does not answer.
  Future<List<RelayStatus>> _health(NetworkPreset preset) async {
    final sub = ref.listen(relayStatusProvider(preset).future, (_, _) {});
    try {
      return await sub.read().timeout(_healthWait);
    } on Object {
      return const [];
    } finally {
      sub.close();
    }
  }

  /// The user accepted the offer: the open wallet moves to the offered relay (the node stays),
  /// the old relay is recorded for draining, and [relaySwitchResultProvider] holds the new
  /// address for Receive. Null when there is no offer, no wallet is open or one is running; a
  /// refused switch throws the [WalletError] and nothing changes.
  ///
  /// Takes the screen's [widgetRef]: the move goes through [switchServersLive], as a relay the
  /// user picks in the list does.
  Future<RelaySwitchResult?> accept(WidgetRef widgetRef) async {
    final offer = state;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (offer == null || session == null || config == null || _moving) return null;
    _moving = true;
    try {
      // The node in use stays: on a failover node too, so the wallet keeps a node that answers.
      final live = await switchServersLive(
        widgetRef,
        nodeUrl: config.nodeUrl,
        nodeApiSecret: config.nodeApiSecret,
        relay: offer.to,
      );
      await recordRelayMove(ref.read(secretStoreProvider), from: offer.from, to: offer.to, now: _now());
      String? address = offer.address;
      if (live && ref.mounted && ref.read(sessionProvider) == session) {
        try {
          address = await session.epicboxAddress();
        } on Object {
          // The offer's own guess stands.
        }
      }
      final result = RelaySwitchResult(from: offer.from, relay: offer.to, name: offer.name, address: address);
      if (ref.mounted) {
        state = null;
        _since = null;
        _keptWaitingAt = null;
        _timer?.cancel();
        _timer = null;
        ref.read(relaySwitchResultProvider.notifier).set(result);
      }
      logInfo('network', 'relay moved by the user: ${offer.from.label} -> ${offer.to.label}');
      return result;
    } finally {
      _moving = false;
    }
  }
}

/// The relays an offer may name: the Epicbox list of the settings file, in order, each named
/// by `[operators]` or its host.
List<RelayCandidate> relayCandidatesOf(Iterable<EpicboxServer> servers) => [
  for (final s in servers) RelayCandidate(relay: EpicboxRelay(host: s.host, port: s.port), name: s.operator ?? s.host),
];

/// [relay]'s health as [listed] (the status site) says: healthy only after a completed handshake.
RelayHealth relayHealthOf(List<RelayStatus> listed, EpicboxRelay relay) {
  for (final s in listed) {
    if (s.relay.host.toLowerCase() == relay.host.toLowerCase() && s.relay.port == relay.port) {
      return s.healthy ? RelayHealth.healthy : RelayHealth.down;
    }
  }
  return RelayHealth.unknown;
}

/// One read-change-write of [drainedRelaysKey] at a time.
Future<void> _storeTurn = Future.value();

Future<T> _inStoreTurn<T>(Future<T> Function() run) {
  final next = _storeTurn.then((_) => run());
  _storeTurn = next.then((_) {}, onError: (_) {});
  return next;
}

/// Records the move from [from] to [to] at [now] under [drainedRelaysKey].
Future<void> recordRelayMove(SecretStore store, {required EpicboxRelay from, required EpicboxRelay to, required DateTime now}) =>
    _inStoreTurn(() async {
      final before = decodeDrainedRelays(await store.read(drainedRelaysKey));
      await store.write(drainedRelaysKey, encodeDrainedRelays(recordDrainedRelay(before, from: from, to: to, now: now)));
    });

/// The drainer: while a wallet is open, every [relayDrainEvery] it reads the wallet's old
/// address on each relay it moved off in the last [relayDrainWindow] that the status site does
/// not list as down. A core that cannot ([DrainEpicboxAt.drainEpicboxAt] answers null) is left
/// alone for the session.
final relayDrainWatchProvider = NotifierProvider<RelayDrainWatch, void>(RelayDrainWatch.new);

class RelayDrainWatch extends Notifier<void> {
  bool _running = false;
  bool _unsupported = false;
  Timer? _next;

  @override
  void build() {
    final session = ref.watch(sessionProvider);
    _unsupported = false;
    ref.onDispose(() {
      _next?.cancel();
      _next = null;
    });
    if (session == null) return;
    Future<void>.delayed(Duration.zero, drain);
  }

  /// One pass over the live records, unless one is running.
  Future<void> drain() async {
    if (!ref.mounted || _running || _unsupported) return;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return;
    final mode = ref.read(networkModeProvider);
    final tor = ref.exists(phoneTorProvider) ? phoneTorState(ref.read(phoneTorProvider)) : TorState.off;
    if (relaySwitchHold(mode: mode, tor: tor, epicboxOn: NetGate.epicbox) != null) return;
    _running = true;
    _next?.cancel();
    _next = null;
    // The next pass only while an old relay is still to read: no timer otherwise.
    var again = false;
    try {
      final store = ref.read(secretStoreProvider);
      final now = ref.read(clockProvider)();
      final inUse = EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
      final live = await _inStoreTurn(() async {
        final raw = await store.read(drainedRelaysKey);
        final all = decodeDrainedRelays(raw);
        final kept = liveDrainedRelays(all, now, inUse: inUse);
        // Expired records, and the relay moved back to, go.
        if (raw != null && kept.length != all.length) await store.write(drainedRelaysKey, encodeDrainedRelays(kept));
        return kept;
      });
      if (live.isEmpty) return;
      again = true;
      final listed = await _listed();
      for (final r in live) {
        if (!ref.mounted || ref.read(sessionProvider) != session) return;
        if (relayHealthOf(listed, r.relay) == RelayHealth.down) continue;
        try {
          final report = await session.drainEpicboxAt(domain: r.relay.host, port: r.relay.port);
          if (report == null) {
            _unsupported = true;
            logInfo('network', 'old relay drain: not supported by this core (LEPIC E-15)');
            return;
          }
          if ((report.received > 0 || report.finalized > 0) && ref.mounted) ref.invalidate(homeProvider);
        } on Object catch (e) {
          logWarn('network', 'old relay drain failed (${r.relay.label}): ${e.runtimeType}');
        }
      }
    } finally {
      _running = false;
      if (again && !_unsupported && ref.mounted && ref.read(sessionProvider) != null) {
        _next = Timer(relayDrainEvery, () => unawaited(drain()));
      }
    }
  }

  Future<List<RelayStatus>> _listed() async {
    final choice = ref.read(networkChoiceProvider).value;
    if (choice == null) return const [];
    final sub = ref.listen(relayStatusProvider(choice.preset).future, (_, _) {});
    try {
      return await sub.read().timeout(_healthWait);
    } on Object {
      return const [];
    } finally {
      sub.close();
    }
  }
}
