// NodeInfoService: the monitor's view when it lists the node, else limited info from the node.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:epic_wallet/src/node/node_info.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:flutter_test/flutter_test.dart';

final _status = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

class _Monitor implements NodeDirectory, NetworkDirectory {
  bool down = false;

  @override
  Future<List<NodeStatus>> nodes(String chain) async {
    if (down) throw const SocketException('down');
    return parseNodeStatus(_status);
  }

  @override
  Future<NetworkStatus> network(String chain) async {
    if (down) throw const SocketException('down');
    return parseNetworkStatus(_status);
  }
}

/// A node answering the foreign API; [ready] null: an older node without ready_for_txs.
NodeApiClient Function(String) _node({int height = 3764980, bool? ready = true, bool down = false}) =>
    (url) => NodeApiClient(
      url,
      transport: (uri, body, headers, t) async {
        if (down) throw const SocketException('refused');
        final method = (jsonDecode(body) as Map)['method'];
        if (method == 'ready_for_txs' && ready == null) {
          return (status: 200, body: jsonEncode({'error': {'code': -32601, 'message': 'Method not found'}}));
        }
        final ok = switch (method) {
          'get_tip' => {'height': height, 'last_block_pushed': 'ab', 'total_difficulty': {}},
          'ready_for_txs' => {'ready_for_txs': ready},
          'get_version' => {'node_version': '4.1.0', 'block_header_version': 6},
          'get_header' => {'height': height, 'timestamp': '2026-10-22T14:16:03+00:00'},
          _ => throw StateError('$method'),
        };
        return (status: 200, body: jsonEncode({'result': {'Ok': ok}}));
      },
    );

void main() {
  final at = DateTime.utc(2026, 10, 22, 14, 20);

  test('a listed node: the monitor\'s state, lag, version against the release, uptime, peers', () async {
    final s = NodeInfoService(nodes: _Monitor(), network: _Monitor(), clientFor: _node(down: true), clock: () => at);
    final i = await s.info('https://node.btlabs.uk', chain: 'mainnet');
    expect(i.source, NodeInfoSource.directory);
    expect(i.state, NodeHealthState.healthy);
    expect(i.height, isNotNull);
    expect(i.blocksBehind, 0);
    expect(i.atTip, isTrue);
    expect(i.operator, 'btlabs');
    expect(i.version, isNotNull);
    expect(i.releasedVersion, isNotNull);
    expect(i.latencyFromMonitor, isTrue);
    expect(i.uptime24h, inInclusiveRange(0, 1));
    expect(i.network?.tipHeight, isNotNull);
    expect(i.at, at);
  });

  test('a node the monitor does not list gets limited info, with the network context', () async {
    final s = NodeInfoService(nodes: _Monitor(), network: _Monitor(), clientFor: _node(height: 3764900));
    final i = await s.info('http://127.0.0.1:3413', chain: 'mainnet');
    final tip = parseNetworkStatus(_status).tipHeight!;
    expect(i.source, NodeInfoSource.limited);
    expect(i.state, NodeHealthState.healthy);
    expect(i.height, 3764900);
    expect(i.blocksBehind, tip - 3764900);
    expect(i.readyForTxs, isTrue);
    expect(i.version, '4.1.0');
    expect(i.tipTime, DateTime.utc(2026, 10, 22, 14, 16, 3));
    expect(i.latencyMs, isNotNull);
    expect(i.latencyFromMonitor, isFalse);
  });

  test('the monitor down: limited info without the network context', () async {
    final m = _Monitor()..down = true;
    final s = NodeInfoService(nodes: m, network: m, clientFor: _node());
    final i = await s.info('https://node.btlabs.uk', chain: 'mainnet');
    expect(i.source, NodeInfoSource.limited);
    expect(i.network, isNull);
    expect(i.blocksBehind, isNull);
  });

  test('a syncing node is degraded, an old node has no ready flag and is judged by its tip age', () async {
    final m = _Monitor()..down = true;
    NodeInfoService service(NodeApiClient Function(String) node, {DateTime? now}) =>
        NodeInfoService(nodes: m, clientFor: node, clock: () => now ?? at);
    var i = await service(_node(ready: false)).info('http://127.0.0.1:3413', chain: 'mainnet');
    expect(i.state, NodeHealthState.degraded);
    i = await service(_node(height: 0)).info('http://127.0.0.1:3413', chain: 'mainnet');
    expect(i.state, NodeHealthState.degraded);
    // The fake's last block is 14:16:03; the clock is 14:20.
    i = await service(_node(ready: null)).info('http://127.0.0.1:3413', chain: 'mainnet');
    expect(i.readyForTxs, isNull);
    expect(i.state, NodeHealthState.healthy);
    i = await service(_node(ready: null), now: at.add(const Duration(hours: 1))).info('http://127.0.0.1:3413', chain: 'mainnet');
    expect(i.state, NodeHealthState.degraded, reason: 'last block over 30 min old');
  });

  test('limited info with the network tip: more than 10 behind is degraded', () async {
    final tip = parseNetworkStatus(_status).tipHeight!;
    final s = NodeInfoService(nodes: _Monitor(), network: _Monitor(), clientFor: _node(height: tip - 11), clock: () => at);
    expect((await s.info('http://127.0.0.1:3413', chain: 'mainnet')).state, NodeHealthState.degraded);
  });

  test('nothing answers: source none, state down', () async {
    final m = _Monitor()..down = true;
    final i = await NodeInfoService(nodes: m, clientFor: _node(down: true)).info('http://127.0.0.1:3413', chain: 'mainnet');
    expect(i.source, NodeInfoSource.none);
    expect(i.state, NodeHealthState.down);
    expect(i.error, NodeRpcError.unreachable.name);
  });

  test('a listed node that answers: this computer\'s latency, median of the last three', () async {
    final s = NodeInfoService(nodes: _Monitor(), network: _Monitor(), clientFor: _node(), clock: () => at);
    for (var i = 0; i < 4; i++) {
      await s.info('https://node.btlabs.uk', chain: 'mainnet');
    }
    final i = await s.info('https://node.btlabs.uk', chain: 'mainnet');
    expect(i.latencyFromMonitor, isFalse);
    expect(i.latencyMs, s.measuredLatency('https://node.btlabs.uk'));
    expect(i.monitorLatencyMs, isNotNull);
    expect(i.directoryReachedAt, at);
  });

  test('the monitor goes down: the last time it answered stays', () async {
    final m = _Monitor();
    var now = at;
    final s = NodeInfoService(nodes: m, network: m, clientFor: _node(), clock: () => now);
    await s.info('https://node.btlabs.uk', chain: 'mainnet');
    m.down = true;
    now = at.add(const Duration(minutes: 5));
    final i = await s.info('https://node.btlabs.uk', chain: 'mainnet');
    expect(i.source, NodeInfoSource.limited);
    expect(i.directoryReachedAt, at);
  });

  test('usernet skips the monitor', () async {
    final i = await NodeInfoService(nodes: _Monitor(), clientFor: _node()).info('https://node.btlabs.uk', chain: null);
    expect(i.source, NodeInfoSource.limited);
  });

  test('compareVersions and updateAvailable', () {
    expect(compareVersions('4.1.0', '4.1.1'), -1);
    expect(compareVersions('4.1.1', '4.1.1'), 0);
    expect(compareVersions('4.1.0-1', '4.1.0'), 1);
    expect(compareVersions('v3.6.0', '4.1.0'), -1);
    expect(compareVersions('x', '4.1.0'), isNull);
    final i = NodeInfo(url: 'u', source: NodeInfoSource.directory, at: at, version: '4.1.0', releasedVersion: '4.1.1');
    expect(i.updateAvailable, isTrue);
  });

  test('Tor on: a direct latency from before is never shown; the next one is over Tor', () async {
    var tor = false;
    var answers = true;
    final s = NodeInfoService(
      nodes: _Monitor(),
      network: _Monitor(),
      clientFor: (url) => _node(down: !answers)(url),
      overTor: () => tor,
      clock: () => at,
    );
    const url = 'https://node.btlabs.uk';
    final direct = await s.info(url, chain: 'mainnet');
    expect(direct.latencyOverTor, isFalse);
    expect(direct.latencyFromMonitor, isFalse);

    tor = true;
    answers = false;
    final waiting = await s.info(url, chain: 'mainnet');
    expect(s.measuredLatency(url), isNull, reason: 'the direct figure stays with the direct route');
    expect(waiting.latencyFromMonitor, isTrue);
    expect(waiting.latencyOverTor, isFalse);

    answers = true;
    final overTor = await s.info(url, chain: 'mainnet');
    expect(overTor.latencyOverTor, isTrue);
    expect(overTor.latencyFromMonitor, isFalse);
    expect(overTor.latencyMs, s.measuredLatency(url));

    tor = false;
    expect(s.measuredLatency(url), direct.latencyMs, reason: 'Tor off again: the direct figures');
  });

  test('Tor on but not connected: no direct latency probe reaches the node', () async {
    // 127.0.0.2 is not this computer's loopback name, so it counts as a remote node.
    final server = await HttpServer.bind(InternetAddress('127.0.0.2'), 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((r) {
      requests++;
      r.response.close();
    });
    TorNet.waitForTor();
    TorSwitch.on = true;
    addTearDown(() {
      TorNet.useDirect();
      TorSwitch.on = false;
    });
    final url = 'http://127.0.0.2:${server.port}';
    final i = await NodeInfoService(nodes: _Monitor()).info(url, chain: 'mainnet');
    expect(requests, 0);
    expect(i.latencyMs, isNull);
    expect(i.latencyOverTor, isFalse);
  });
}
