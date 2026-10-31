// SPDX-License-Identifier: Apache-2.0
/// The Epicbox server offer on the desktop (wallet levels, Shallow only): the phone's rules
/// (`levels/relay_switch.dart`) on the desktop's state. The status [DeskState.status] reads the
/// server in use down; once that has lasted [relaySwitchAfter] and another server of the
/// Epicbox list (`settings.toml`, [deskServerListProvider]) is listed healthy by the status site
/// ([DeskWalletApi.epicboxes]), [deskRelayOfferProvider] holds the offer. Nothing moves until the
/// user accepts ([DeskRelaySwitch.accept], through [DeskController.useEpicbox]); Not now
/// ([DeskRelaySwitch.keepWaiting]) holds it back until the server answers again or
/// [relayKeepWaitingFor] passes.
///
/// After a move [deskRelayMovedProvider] holds the new address for the open wallet: Receive
/// shows it as new and the "Now on" notice stays until the user closes it
/// ([deskRelayMovedNoticeProvider]). A wallet closed, switched or locked starts with none.
///
/// The old server is not read after the move: draining it needs LEPIC E-15
/// (`drain_epicbox_at`), which the pinned core does not have, so the desktop records nothing and
/// no text promises that payments to the old address arrive.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../levels/relay_switch.dart';
import '../../levels/relay_switch_providers.dart' show RelaySwitchResult;
import '../../log.dart';
import '../../network.dart' show EpicboxRelay;
import 'clock.dart';
import 'desk_levels.dart';
import 'models.dart';
import 'net_mode_view.dart';
import 'server_lists.dart';
import 'state.dart';

/// How often the offer is looked at again while the server stays down.
const Duration deskRelayRecheck = Duration(minutes: 1);

/// How long the status site may take to say which servers are healthy.
const Duration _healthWait = Duration(seconds: 10);

/// The open wallet, for resetting the offer and the move (null: none open).
String? _walletOf(DeskState s) => s.account?.folder;

/// Whether [s] reads the Epicbox server in use down: not answering, or blocked by the network.
bool deskEpicboxDown(DeskState s) => s.status?.epicboxHealth == ServiceHealth.down;

/// The offer, or null. Only [DeskRelaySwitch.accept] moves the wallet.
final deskRelayOfferProvider = NotifierProvider<DeskRelaySwitch, RelaySwitchOffer?>(DeskRelaySwitch.new);

/// The last move the user accepted, for the open wallet; null when none.
final deskRelayMovedProvider = NotifierProvider<DeskRelayMoved, RelaySwitchResult?>(DeskRelayMoved.new);

/// Whether the "Now on" notice of the last move is still open: set by the move, closed by OK or
/// Show new address ([DeskRelayMovedNotice.close]); the move itself stays for Receive.
final deskRelayMovedNoticeProvider = NotifierProvider<DeskRelayMovedNotice, bool>(DeskRelayMovedNotice.new);

/// Whether the relay notice has anything to show: an offer at Shallow, or an open "Now on".
final deskRelayNoticeShownProvider = Provider<bool>(
  (ref) =>
      ref.watch(deskLevelFeaturesProvider.select((f) => f.relaySwitchPrompt)) &&
      (ref.watch(deskRelayOfferProvider) != null || (ref.watch(deskRelayMovedNoticeProvider) && ref.watch(deskRelayMovedProvider) != null)),
);

class DeskRelayMoved extends Notifier<RelaySwitchResult?> {
  @override
  RelaySwitchResult? build() {
    // Another wallet (an unlock, a switch, a lock) has no move to show. The move itself reopens
    // the session, so the wallet's folder is the key, not the session.
    ref.watch(deskProvider.select(_walletOf));
    return null;
  }

  void set(RelaySwitchResult result) => state = result;
}

class DeskRelayMovedNotice extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(deskProvider.select(_walletOf));
    return false;
  }

  void open() => state = true;

  void close() => state = false;
}

class DeskRelaySwitch extends Notifier<RelaySwitchOffer?> {
  Timer? _timer;

  /// Since when the status reads the server in use down; null while it does not.
  DateTime? _since;

  /// When the user chose Not now during this outage.
  DateTime? _keptWaitingAt;

  bool _checking = false;
  bool _moving = false;

  /// Counts the builds: a check that began for a replaced wallet drops its answer.
  int _build = 0;

  DateTime _now() => ref.read(deskClockProvider)();

  @override
  RelaySwitchOffer? build() {
    ref.watch(deskProvider.select(_walletOf));
    ++_build;
    // Shallow only ([LevelFeatures.relaySwitchPrompt]): the other levels pick servers by hand.
    final prompt = ref.watch(deskLevelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    _since = null;
    _keptWaitingAt = null;
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    if (!prompt) return null;
    ref.listen(deskProvider.select(deskEpicboxDown), (_, down) => _follow(down));
    // A server already down when the wallet opened counts from now.
    final gen = _build;
    Future<void>.delayed(Duration.zero, () {
      if (ref.mounted && gen == _build) _follow(deskEpicboxDown(ref.read(deskProvider)));
    });
    return null;
  }

  void _follow(bool down) {
    if (!down) {
      // Answering again (or stopped): the outage and its Not now are over.
      _since = null;
      _keptWaitingAt = null;
      _timer?.cancel();
      _timer = null;
      if (state != null) state = null;
      return;
    }
    _since ??= _now();
    _arm();
  }

  void _arm() {
    if (_since == null || _timer != null) return;
    final left = relaySwitchAfter - _now().difference(_since!);
    _timer = Timer(left.isNegative ? Duration.zero : left, _fire);
  }

  void _fire() {
    _timer = null;
    if (!ref.mounted || _since == null) return;
    unawaited(_check().whenComplete(() {
      if (ref.mounted && _since != null) _timer ??= Timer(deskRelayRecheck, _fire);
    }));
  }

  /// Not now: no offer until the server answers again or [relayKeepWaitingFor] passes.
  void keepWaiting() {
    _keptWaitingAt = _now();
    state = null;
  }

  Future<void> _check() async {
    if (_checking) return;
    final st = ref.read(deskProvider);
    final status = st.status;
    if (status == null || st.account == null || _since == null) return;
    final gen = _build;
    _checking = true;
    try {
      final mode = deskNetMode(st);
      final tor = deskNetTor(st);
      final epicboxOn = st.settings.payments.epicbox;
      // Nothing is asked while no server may be offered.
      if (relaySwitchHold(mode: mode, tor: tor, epicboxOn: epicboxOn) != null) {
        if (state != null) state = null;
        return;
      }
      final listed = await _health(st);
      if (gen != _build || !ref.mounted) return;
      final now = ref.read(deskProvider);
      final inUse = EpicboxRelay(host: status.epicbox.domain, port: status.epicbox.port);
      final offer = relaySwitchOffer(
        inUse: inUse,
        unreachableSince: _since,
        now: _now(),
        candidates: deskRelayCandidates(ref.read(deskServerListProvider(ServerKind.relay)), listed),
        health: (r) => deskRelayHealth(listed, r),
        mode: mode,
        tor: tor,
        epicboxOn: epicboxOn,
        // The desktop knows no onions of its own servers: in Tor only, only while Epicbox goes
        // over Tor at all.
        overTor: (r) => relayOverTor(r, hasOnion: (_, _) => false),
        keptWaitingAt: _keptWaitingAt,
        address: now.epicboxAddress,
      );
      if (offer != state) {
        if (offer != null) logInfo('network', 'relay ${inUse.label} down; offering ${offer.to.label}');
        state = offer;
      }
    } finally {
      _checking = false;
    }
  }

  /// The status site's view of the servers, or what the state last held when it does not answer.
  Future<List<EpicboxServer>> _health(DeskState st) async {
    try {
      return await ref.read(deskApiProvider).epicboxes().timeout(_healthWait);
    } on Object {
      return st.epicboxes ?? const [];
    }
  }

  /// The user accepted the offer: [moveTo] the offered server. Null when there is no offer.
  Future<RelaySwitchResult?> accept() async {
    final offer = state;
    if (offer == null) return null;
    return moveTo(RelayCandidate(relay: offer.to, name: offer.name));
  }

  /// The wallet moves to [to] (the node stays): the offer's move, also the user's own pick in
  /// the Shallow status popover. [deskRelayMovedProvider] holds the new address. Null when a
  /// move is running or the wallet is already there; a refused move throws and nothing changes.
  Future<RelaySwitchResult?> moveTo(RelayCandidate to) async {
    if (_moving) return null;
    final st = ref.read(deskProvider);
    final status = st.status;
    final from = status == null ? null : EpicboxRelay(host: status.epicbox.domain, port: status.epicbox.port);
    if (from != null && from.host.toLowerCase() == to.relay.host.toLowerCase() && from.port == to.relay.port) return null;
    final was = state?.from ?? from ?? to.relay;
    final fallback = state?.to == to.relay ? state!.address : addressAtRelay(st.epicboxAddress, to.relay);
    _moving = true;
    try {
      await ref.read(deskProvider.notifier).useEpicbox(to.relay.label);
      // The controller read the new address after the move; a wallet that did not give one
      // keeps the one worked out from the old address.
      final given = ref.mounted ? ref.read(deskProvider).epicboxAddress : null;
      final address = given != null && given.toLowerCase().endsWith('@${to.relay.label.toLowerCase()}') ? given : fallback;
      final result = RelaySwitchResult(from: was, relay: to.relay, name: to.name, address: address);
      if (ref.mounted) {
        _since = null;
        _keptWaitingAt = null;
        _timer?.cancel();
        _timer = null;
        ref.read(deskRelayMovedProvider.notifier).set(result);
        ref.read(deskRelayMovedNoticeProvider.notifier).open();
        state = null;
      }
      logInfo('network', 'relay moved by the user: ${was.label} -> ${to.relay.label}');
      return result;
    } finally {
      _moving = false;
    }
  }
}

/// The servers an offer may name: the Epicbox list of the settings file in its order (the
/// status site's list when that is not read yet), each named by its address, never its operator.
List<RelayCandidate> deskRelayCandidates(ServerList? list, List<EpicboxServer> listed) {
  final entries = list?.entries ?? const <String>[];
  final relays = entries.isNotEmpty
      ? [for (final e in entries) ?EpicboxRelay.parse(e)]
      : [for (final b in listed) EpicboxRelay(host: b.domain, port: b.port)];
  return [for (final r in relays) RelayCandidate(relay: r, name: r.label)];
}

/// [relay]'s health as the status site listed it: healthy only when listed answering.
/// The built-in servers read "checking" until the site answers, so they are never offered unseen.
RelayHealth deskRelayHealth(List<EpicboxServer> listed, EpicboxRelay relay) {
  for (final b in listed) {
    if (b.domain.toLowerCase() == relay.host.toLowerCase() && b.port == relay.port) {
      return switch (b.health) {
        ServiceHealth.ok => RelayHealth.healthy,
        ServiceHealth.down => RelayHealth.down,
        _ => RelayHealth.unknown,
      };
    }
  }
  return RelayHealth.unknown;
}
