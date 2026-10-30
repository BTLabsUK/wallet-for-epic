// SPDX-License-Identifier: Apache-2.0
// NetGate.dial (network_gate.dart), the one check before every outbound connection: each kind
// of connection in each mode. Normal and Tor only let everything through here (Tor only routes
// in TorNet); Node only only the node in use's host (and tor, which carries it while the Tor
// switch is on); Kill switch nothing, loopback included.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final was = NetGate.nodeInUse;
  tearDown(() {
    NetGate.nodeInUse = was;
    NetGate.set(NetworkMode.standard);
  });

  void dials(NetDial kind, String host, {required bool allowed}) {
    expect(NetGate.allows(kind, host), allowed, reason: '${NetGate.mode.name} ${kind.name} $host');
    if (allowed) {
      expect(() => NetGate.dial(kind, host), returnsNormally);
    } else {
      expect(() => NetGate.dial(kind, host), throwsA(isA<NetBlocked>().having((e) => e.mode, 'mode', NetGate.mode)));
    }
  }

  const hosts = ['node.example', 'status.example', '127.0.0.1', 'localhost', '10.100.10.20'];

  test('Normal: every kind to every host; Tor only: all but the system browser (tor routes the rest)', () {
    for (final m in [NetworkMode.standard, NetworkMode.torOnly]) {
      NetGate.set(m);
      for (final k in NetDial.values) {
        for (final h in hosts) {
          dials(k, h, allowed: m == NetworkMode.standard || k != NetDial.browser);
        }
      }
    }
  });

  test('Kill switch: nothing, loopback and tor included', () {
    NetGate.nodeInUse = () => 'http://127.0.0.1:3413';
    NetGate.set(NetworkMode.killSwitch);
    for (final k in NetDial.values) {
      for (final h in hosts) {
        dials(k, h, allowed: false);
      }
    }
  });

  test('Node only, a public node: its host only, for every kind that reaches a host; tor yes; the browser never', () {
    NetGate.nodeInUse = () => 'https://Node.Example:3413';
    NetGate.set(NetworkMode.nodeOnly);
    for (final k in [NetDial.http, NetDial.webSocket, NetDial.lookup, NetDial.nodeRelay, NetDial.builtInNode]) {
      dials(k, 'node.example', allowed: true);
      dials(k, 'https://node.example:3413/v2/foreign', allowed: true);
      dials(k, 'status.example', allowed: false);
      dials(k, '127.0.0.1', allowed: false);
    }
    dials(NetDial.tor, 'tor', allowed: true);
    dials(NetDial.browser, 'node.example', allowed: false);
    expect(NetGate.nodeHosts, {'node.example'});
  });

  test('Node only, a node on this computer: its loopback spellings; a LAN node: its own host', () {
    NetGate.nodeInUse = () => 'http://localhost:3413';
    NetGate.set(NetworkMode.nodeOnly);
    for (final h in ['127.0.0.1', 'localhost', '::1', '[::1]', '127.0.0.2']) {
      dials(NetDial.http, h, allowed: true);
    }
    dials(NetDial.builtInNode, '127.0.0.1', allowed: true);
    dials(NetDial.http, '10.100.10.20', allowed: false);
    NetGate.nodeInUse = () => 'http://10.100.10.20:3413';
    dials(NetDial.nodeRelay, '10.100.10.20', allowed: true);
    dials(NetDial.http, '10.100.10.20', allowed: true);
    dials(NetDial.http, '127.0.0.1', allowed: false);
    dials(NetDial.builtInNode, '127.0.0.1', allowed: false);
  });

  test('Node only without a node: nothing but tor', () {
    NetGate.nodeInUse = () => '';
    NetGate.set(NetworkMode.nodeOnly);
    for (final k in NetDial.values) {
      dials(k, 'node.example', allowed: k == NetDial.tor);
    }
  });

  test('a change fires once', () async {
    final changes = <NetworkMode>[];
    final sub = NetGate.changes.listen(changes.add);
    addTearDown(sub.cancel);
    NetGate.set(NetworkMode.killSwitch);
    NetGate.set(NetworkMode.killSwitch);
    NetGate.set(NetworkMode.nodeOnly);
    expect(changes, [NetworkMode.killSwitch, NetworkMode.nodeOnly]);
    expect(NetworkMode.killSwitch.restricted && NetworkMode.nodeOnly.restricted, isTrue);
    expect(NetworkMode.torOnly.restricted || NetworkMode.standard.restricted, isFalse);
  });
}
