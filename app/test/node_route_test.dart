// SPDX-License-Identifier: Apache-2.0
// The route of a node check with no wallet open (first run, a node typed in): LEPIC has no tor
// of its own then, so the app states how it goes. Tor carrying: through its SOCKS proxy; the
// Tor switch on without it, or Tor only: refused, nothing direct; off: direct.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const far = 'https://node.example:3413';
  const lan = 'http://192.168.1.20:3413';

  setUp(() {
    TorNet.useDirect();
    TorSwitch.on = false;
    NetGate.set(NetworkMode.standard);
  });
  tearDown(() {
    TorNet.useDirect();
    TorSwitch.on = false;
    NetGate.set(NetworkMode.standard);
  });

  test('tor off: directly', () {
    expect(nodeRouteFor(far).socks, isNull);
  });

  test('tor carrying: through its proxy, a node on this network still directly', () {
    TorSwitch.on = true;
    TorNet.useTor(const SocksProxy('127.0.0.1', 9150));
    expect(nodeRouteFor(far).socks, '127.0.0.1:9150');
    expect(nodeRouteFor(lan).socks, isNull);
  });

  test('the Tor switch on but tor not carrying yet: a far node is refused, a local one asked', () {
    TorSwitch.on = true;
    TorNet.waitForTor();
    expect(() => nodeRouteFor(far), throwsA(isA<NetBlocked>()));
    expect(nodeRouteFor(lan).socks, isNull);
  });

  test('Tor only: never directly to a far node', () {
    NetGate.set(NetworkMode.torOnly);
    expect(() => nodeRouteFor(far), throwsA(isA<NetBlocked>()));
  });
}
