// SPDX-License-Identifier: Apache-2.0
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/tor_routes.dart';

void main() {
  const a = EpicboxRelay(host: 'relay-a.test');
  const b = EpicboxRelay(host: 'relay-b.test');
  const c = EpicboxRelay(host: 'relay-c.test', port: 8443);
  const candidates = [
    RelayCandidate(relay: a, name: 'A'),
    RelayCandidate(relay: b, name: 'B'),
    RelayCandidate(relay: c, name: 'C'),
  ];
  final t0 = DateTime.utc(2026, 10, 31, 12);
  RelayHealth allHealthy(EpicboxRelay _) => RelayHealth.healthy;

  RelaySwitchOffer? offer({
    Duration after = const Duration(minutes: 3),
    RelayHealth Function(EpicboxRelay)? health,
    NetworkMode mode = NetworkMode.standard,
    TorState tor = TorState.off,
    bool epicboxOn = true,
    DateTime? keptWaitingAt,
  }) => relaySwitchOffer(
    inUse: a,
    unreachableSince: t0,
    now: t0.add(after),
    candidates: candidates,
    health: health ?? allHealthy,
    mode: mode,
    tor: tor,
    epicboxOn: epicboxOn,
    keptWaitingAt: keptWaitingAt,
    overTor: (r) => relayOverTor(r, hasOnion: (_, _) => false),
    address: 'key123@relay-a.test',
  );

  test('no offer before 2 minutes, nor while the relay answers', () {
    expect(offer(after: const Duration(minutes: 1, seconds: 59)), isNull);
    expect(
      relaySwitchOffer(inUse: a, unreachableSince: null, now: t0, candidates: candidates, health: allHealthy),
      isNull,
    );
  });

  test('after 2 minutes the next healthy relay, never the one in use, with the new address', () {
    final o = offer(after: relaySwitchAfter)!;
    expect(o.from, a);
    expect(o.to, b);
    expect(o.name, 'B');
    expect(o.address, 'key123@relay-b.test');
  });

  test('skips unhealthy and unknown relays; none without a healthy one', () {
    final o = offer(health: (r) => r == c ? RelayHealth.healthy : RelayHealth.down)!;
    expect(o.to, c);
    expect(o.address, 'key123@relay-c.test:8443');
    expect(offer(health: (r) => r == b ? RelayHealth.unknown : RelayHealth.down), isNull);
  });

  test('none in Node only, Kill switch, with Epicbox off, or while Tor starts', () {
    expect(offer(mode: NetworkMode.nodeOnly), isNull);
    expect(offer(mode: NetworkMode.killSwitch), isNull);
    expect(offer(epicboxOn: false), isNull);
    expect(offer(mode: NetworkMode.torOnly, tor: TorState.starting), isNull);
    expect(offer(mode: NetworkMode.torOnly, tor: TorState.on), isNotNull);
  });

  test('Keep waiting holds the offer for 30 minutes', () {
    expect(offer(after: const Duration(minutes: 10), keptWaitingAt: t0.add(const Duration(minutes: 3))), isNull);
    expect(offer(after: const Duration(minutes: 34), keptWaitingAt: t0.add(const Duration(minutes: 3))), isNotNull);
  });

  test('the drain record lives 30 days, survives a round trip and drops the relay moved back to', () {
    var list = recordDrainedRelay(const [], from: a, to: b, now: t0);
    list = decodeDrainedRelays(encodeDrainedRelays(list));
    expect(list.single.relay, a);
    expect(liveDrainedRelays(list, t0.add(const Duration(days: 29)), inUse: b), hasLength(1));
    expect(liveDrainedRelays(list, t0.add(relayDrainWindow), inUse: b), isEmpty);
    expect(liveDrainedRelays(list, t0, inUse: a), isEmpty);
    expect(recordDrainedRelay(list, from: b, to: a, now: t0).single.relay, b);
    expect(decodeDrainedRelays('not json'), isEmpty);
  });
}
