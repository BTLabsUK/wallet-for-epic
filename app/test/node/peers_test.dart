// SPDX-License-Identifier: Apache-2.0
// PeerService over a fake node: merge with the store, first seen, order, banned list, history.
import 'dart:convert';

import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/peers.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _live(String addr, {String dir = 'Outbound', int height = 100}) => {
  'addr': addr,
  'capabilities': 'HEADER_HIST',
  'direction': dir,
  'height': height,
  'onion_addr': null,
  'total_difficulty': {'progpow': 8159013528374826400},
  'user_agent': 'MW/Epic 4.1.0',
  'version': 2,
};

Map<String, Object?> _stored(String addr, {String flags = 'Healthy', int banned = 0, int connected = 0}) => {
  'addr': addr,
  'ban_reason': flags == 'Banned' ? 'ManualBan' : 'None',
  'capabilities': '',
  'flags': flags,
  'last_banned': banned,
  'last_connected': connected,
  'local_timestamp': 0,
  'user_agent': '',
};

class _Node {
  List<Map<String, Object?>> live = [];
  List<Map<String, Object?>> stored = [];
  final calls = <(String, Object?)>[];
  bool down = false;

  Future<({int status, String body})> call(Uri url, String body, Map<String, String> headers, Duration t) async {
    if (down) throw const NodeRpcException(NodeRpcError.unreachable, 'down');
    final req = jsonDecode(body) as Map;
    calls.add((req['method'] as String, req['params']));
    expect(headers['Authorization'], startsWith('Basic '));
    final ok = switch (req['method']) {
      'get_connected_peers' => live,
      'get_peers' => stored,
      'ban_peer' || 'unban_peer' => null,
      _ => throw StateError('unexpected ${req['method']}'),
    };
    return (status: 200, body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {'Ok': ok}}));
  }
}

void main() {
  late _Node node;
  late DateTime now;
  late PeerService peers;

  setUp(() {
    node = _Node();
    now = DateTime.utc(2026, 10, 22, 12);
    peers = PeerService(
      NodeApiClient('http://127.0.0.1:3413', secret: () => 'x', transport: node.call),
      clock: () => now,
      historyLimit: 3,
    );
  });

  test('connected peers are merged with the store and ordered: outbound, height, address', () async {
    node.live = [
      _live('203.0.113.5:3414', dir: 'Inbound', height: 900),
      _live('203.0.113.2:3414', height: 100),
      _live('203.0.113.1:3414', height: 300),
    ];
    node.stored = [_stored('203.0.113.2:3414', connected: 1792670000)];
    final s = await peers.refresh();
    expect(s.connected.map((p) => p.addr), ['203.0.113.1:3414', '203.0.113.2:3414', '203.0.113.5:3414']);
    expect(s.connected[1].stored?.lastConnected, DateTime.fromMillisecondsSinceEpoch(1792670000000, isUtc: true));
    expect(s.connected[0].stored, isNull);
    expect(s.inbound, 1);
    expect(s.outbound, 2);
    expect(s.maxHeight, 900);
  });

  test('first seen survives one missed read and starts again after two', () async {
    node.live = [_live('203.0.113.1:3414')];
    final t0 = now;
    await peers.refresh();
    now = now.add(const Duration(seconds: 10));
    expect((await peers.refresh()).connected.single.firstSeen, t0);
    node.live = [];
    await peers.refresh();
    node.live = [_live('203.0.113.1:3414')];
    now = now.add(const Duration(seconds: 10));
    expect((await peers.refresh()).connected.single.firstSeen, t0, reason: 'one miss');
    node.live = [];
    await peers.refresh();
    await peers.refresh();
    node.live = [_live('203.0.113.1:3414')];
    now = now.add(const Duration(seconds: 10));
    expect((await peers.refresh()).connected.single.firstSeen, now, reason: 'two misses');
  });

  test('reads every 10 s add a graph sample every 30 s', () async {
    final service = PeerService(
      NodeApiClient('http://127.0.0.1:3413', secret: () => 'x', transport: node.call),
      clock: () => now,
    );
    for (var i = 0; i < 7; i++) {
      await service.refresh();
      now = now.add(const Duration(seconds: 10));
    }
    expect(service.history.map((h) => h.at.second), [0, 30, 0]);
  });

  test('banned peers come from the store, most recently banned first', () async {
    node.stored = [
      _stored('203.0.113.7:3414', flags: 'Banned', banned: 100),
      _stored('203.0.113.8:3414'),
      _stored('203.0.113.9:3414', flags: 'Banned', banned: 200),
    ];
    final s = await peers.refresh();
    expect(s.banned.map((p) => p.addr), ['203.0.113.9:3414', '203.0.113.7:3414']);
    expect(s.banned.first.banReason, 'ManualBan');
    expect(s.maxHeight, isNull);
  });

  test('history keeps the last samples up to the limit', () async {
    for (var i = 0; i < 5; i++) {
      node.live = [for (var j = 0; j <= i; j++) _live('203.0.113.$j:3414')];
      await peers.refresh();
      now = now.add(const Duration(seconds: 30));
    }
    expect(peers.history.map((h) => h.total), [3, 4, 5]);
    expect(peers.history.first.at, DateTime.utc(2026, 10, 22, 12, 1));
  });

  test('ban and unban send the address; a bad address sends nothing', () async {
    await peers.ban('203.0.113.1:3414');
    await peers.unban('[2001:db8::1]:3414');
    expect(node.calls.map((c) => '${c.$1} ${jsonEncode(c.$2)}'), [
      'ban_peer ["203.0.113.1:3414"]',
      'unban_peer ["[2001:db8::1]:3414"]',
    ]);
    await expectLater(
      peers.ban('not a peer'),
      throwsA(isA<NodeRpcException>().having((e) => e.kind, 'kind', NodeRpcError.invalidArgument)),
    );
    expect(node.calls, hasLength(2));
  });

  test('a node that does not answer throws and adds no sample', () async {
    node.down = true;
    await expectLater(peers.refresh(), throwsA(isA<NodeRpcException>()));
    expect(peers.history, isEmpty);
    expect(peers.last, isNull);
  });
}
