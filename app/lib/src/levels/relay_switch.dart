// SPDX-License-Identifier: Apache-2.0
/// The Epicbox relay offer, the rules (the owner: nothing switches silently): when the relay in
/// use has not answered for [relaySwitchAfter] and another relay of the list is seen healthy,
/// the app OFFERS that relay. Another relay is another address (`<key>@<relay>`), so only the
/// user moves the wallet there; the app never does it by itself.
///
/// Never in Node only or Kill switch (no relay at all), never with Epicbox off, never while Tor
/// is still starting (the relay waits for Tor, it is not gone), and in Tor only only to a relay
/// reachable over Tor, as node failover (`node_failover.dart`).
///
/// After a move the old relay is remembered for [relayDrainWindow] ([DrainedRelay], stored
/// under [drainedRelaysKey]) so payments sent to the old address are still collected there.
///
/// Pure Dart: `relay_switch_providers.dart` watches the phone's status and calls these.
library;

import 'dart:convert';

import '../advanced.dart';
import '../network.dart' show EpicboxRelay;
import '../network_gate.dart';
import '../tor_routes.dart';

/// How long the relay in use must have stopped answering before another one is offered.
const Duration relaySwitchAfter = Duration(minutes: 2);

/// How long a relay that answers again must stay up before its outage is over: one that drops
/// again sooner keeps counting from the first drop.
const Duration relayStableFor = Duration(minutes: 2);

/// How long "Keep waiting" holds the offer back while the relay stays down.
const Duration relayKeepWaitingFor = Duration(minutes: 30);

/// How long an old relay is still drained after the wallet moved off it.
const Duration relayDrainWindow = Duration(days: 7);

/// How often a live old relay is drained while a wallet is open.
const Duration relayDrainEvery = Duration(minutes: 10);

/// The old relays still drained: new and additive, a JSON list of `{host, port, since}`.
const String drainedRelaysKey = 'app.drained_relays';

/// What is known of a relay before it is offered.
enum RelayHealth {
  /// The status site lists it as healthy.
  healthy,

  /// Not listed, or the site did not answer: never offered.
  unknown,

  /// Listed as down: never offered.
  down,
}

/// A relay of the list the offer may name: the relay and the name the UI shows for it, its
/// address ([EpicboxRelay.label]).
class RelayCandidate {
  const RelayCandidate({required this.relay, required this.name});

  final EpicboxRelay relay;
  final String name;
}

/// The offer: move the wallet from [from] to [to].
class RelaySwitchOffer {
  const RelaySwitchOffer({required this.from, required this.to, required this.name, this.address});

  /// The relay in use, not answering.
  final EpicboxRelay from;

  /// The relay offered, seen healthy.
  final EpicboxRelay to;

  /// [to]'s name, for the offer and for Receive after the move.
  final String name;

  /// The wallet's address on [to] (`<key>@<relay>`), or null when the key is not known yet.
  final String? address;

  @override
  bool operator ==(Object other) =>
      other is RelaySwitchOffer && other.from == from && other.to == to && other.address == address;

  @override
  int get hashCode => Object.hash(from, to, address);
}

/// Why no relay may be offered now; null when one may.
enum RelaySwitchHold {
  /// Node only or Kill switch: no relay at all.
  offline,

  /// The Epicbox switch is off.
  epicboxOff,

  /// The relay waits for Tor (starting or failed): it is not gone.
  waitingForTor,
}

/// Why no relay may be offered now, or null.
RelaySwitchHold? relaySwitchHold({required NetworkMode mode, required TorState tor, required bool epicboxOn}) {
  final m = netModeOf(mode);
  if (m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch) return RelaySwitchHold.offline;
  if (!epicboxOn) return RelaySwitchHold.epicboxOff;
  final torWanted = m == NetworkMode.torOnly || tor != TorState.off;
  if (torWanted && tor != TorState.on) return RelaySwitchHold.waitingForTor;
  return null;
}

/// Whether [relay] can be reached over Tor: the Epicbox route goes through Tor while the switch
/// is on ([torCovered]), or BT Labs lists an onion for it ([hasOnion]).
bool relayOverTor(EpicboxRelay relay, {required bool Function(String host, int port) hasOnion}) =>
    torCovered.contains(TorRoute.epicbox) || hasOnion(relay.host, relay.port);

/// `<key>@<relay>`: [address] (the wallet's own, on any relay) moved to [relay]; null when
/// [address] has no key.
String? addressAtRelay(String? address, EpicboxRelay relay) {
  final t = address?.trim() ?? '';
  final at = t.indexOf('@');
  final key = at < 0 ? t : t.substring(0, at);
  return key.isEmpty ? null : '$key@${relay.label}';
}

/// The relay to offer instead of [inUse], or null.
///
/// [unreachableSince]: since when the relay in use has not answered (null while it does).
/// [keptWaitingAt]: when the user last chose "Keep waiting" during this outage.
/// [candidates]: the list from the settings file, in order; the first healthy one that is not
/// [inUse] is offered. In Tor only, only those [overTor] says Tor reaches.
/// [address]: the wallet's own address, to show the one on the new relay.
RelaySwitchOffer? relaySwitchOffer({
  required EpicboxRelay inUse,
  required DateTime? unreachableSince,
  required DateTime now,
  required List<RelayCandidate> candidates,
  required RelayHealth Function(EpicboxRelay relay) health,
  NetworkMode mode = NetworkMode.standard,
  TorState tor = TorState.off,
  bool epicboxOn = true,
  bool Function(EpicboxRelay relay)? overTor,
  DateTime? keptWaitingAt,
  String? address,
}) {
  if (unreachableSince == null || now.difference(unreachableSince) < relaySwitchAfter) return null;
  if (keptWaitingAt != null && now.difference(keptWaitingAt) < relayKeepWaitingFor) return null;
  if (relaySwitchHold(mode: mode, tor: tor, epicboxOn: epicboxOn) != null) return null;
  final torOnly = netModeOf(mode) == NetworkMode.torOnly;
  for (final c in candidates) {
    if (_same(c.relay, inUse)) continue;
    if (torOnly && !(overTor?.call(c.relay) ?? false)) continue;
    if (health(c.relay) != RelayHealth.healthy) continue;
    return RelaySwitchOffer(from: inUse, to: c.relay, name: c.name, address: addressAtRelay(address, c.relay));
  }
  return null;
}

bool _same(EpicboxRelay a, EpicboxRelay b) => a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;

/// An old relay the wallet moved off at [since]: drained until [relayDrainWindow] has passed.
class DrainedRelay {
  const DrainedRelay({required this.relay, required this.since});

  final EpicboxRelay relay;
  final DateTime since;

  /// Still drained at [now].
  bool liveAt(DateTime now) => now.difference(since) < relayDrainWindow;

  Map<String, Object> toJson() => {'host': relay.host, 'port': relay.port, 'since': since.toUtc().toIso8601String()};

  static DrainedRelay? fromJson(Object? json) {
    if (json is! Map) return null;
    final host = json['host'];
    final port = json['port'];
    final since = json['since'];
    if (host is! String || port is! int || since is! String) return null;
    final relay = EpicboxRelay.parse(port == 443 ? host : '$host:$port');
    final at = DateTime.tryParse(since);
    return relay == null || at == null ? null : DrainedRelay(relay: relay, since: at);
  }

  @override
  bool operator ==(Object other) => other is DrainedRelay && other.relay == relay && other.since == since;

  @override
  int get hashCode => Object.hash(relay, since);
}

/// [raw] as stored under [drainedRelaysKey]; entries this build cannot read are dropped, junk
/// reads as none.
List<DrainedRelay> decodeDrainedRelays(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return [for (final e in list) ?DrainedRelay.fromJson(e)];
  } on FormatException {
    return const [];
  }
}

String encodeDrainedRelays(List<DrainedRelay> relays) => jsonEncode([for (final r in relays) r.toJson()]);

/// The records still drained at [now], without [inUse] (a wallet moved back reads it anyway).
List<DrainedRelay> liveDrainedRelays(List<DrainedRelay> relays, DateTime now, {EpicboxRelay? inUse}) => [
  for (final r in relays)
    if (r.liveAt(now) && (inUse == null || !_same(r.relay, inUse))) r,
];

/// [relays] after the wallet moved from [from] to [to] at [now]: [from] is drained from now on
/// (one record per relay, the latest move), [to] no more, and expired records go.
List<DrainedRelay> recordDrainedRelay(
  List<DrainedRelay> relays, {
  required EpicboxRelay from,
  required EpicboxRelay to,
  required DateTime now,
}) => [
  for (final r in liveDrainedRelays(relays, now, inUse: to))
    if (!_same(r.relay, from)) r,
  if (!_same(from, to)) DrainedRelay(relay: from, since: now),
];
