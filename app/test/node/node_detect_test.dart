// SPDX-License-Identifier: Apache-2.0
// A node already answering on this computer, and the facts of the explanation step.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/node/chain_data.dart';
import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_detect.dart';
import 'package:flutter_test/flutter_test.dart';

NodeApiClient Function(String) _node({bool down = false, bool? ready = false, int height = 1200}) =>
    (url) => NodeApiClient(
      url,
      transport: (uri, body, headers, t) async {
        if (down) throw const SocketException('refused');
        final ok = switch ((jsonDecode(body) as Map)['method']) {
          'get_tip' => {'height': height, 'total_difficulty': {}},
          'ready_for_txs' => {'ready_for_txs': ready},
          'get_version' => {'node_version': '3.6.0'},
          final m => throw StateError('$m'),
        };
        return (status: 200, body: jsonEncode({'result': {'Ok': ok}}));
      },
    );

ChainDataInfo _chain(int bytes, {bool usable = true, Chain chain = Chain.mainnet}) => ChainDataInfo(
  path: '/x/chain_data',
  source: ChainDataSource.cli,
  chain: chain,
  bytes: bytes,
  headerBytes: 100000,
  txhashsetBytes: 0,
  modified: null,
  lock: FolderLock.free,
  usable: usable,
);

void main() {
  test('a node answering on the standard port: version, height, ready, not ours', () async {
    final p = await detectLocalNode(Chain.mainnet, clientFor: _node());
    expect(p.url, 'http://127.0.0.1:3413');
    expect(p.answers, isTrue);
    expect(p.otherNode, isTrue);
    expect(p.version, '3.6.0');
    expect(p.height, 1200);
    expect(p.readyForTxs, isFalse);
    expect(p.latencyMs, isNotNull);
  });

  test('nothing on the port, and a typed address', () async {
    final p = await detectLocalNode(Chain.floonet, url: 'http://127.0.0.1:13999', clientFor: _node(down: true));
    expect(p.url, 'http://127.0.0.1:13999');
    expect(p.answers, isFalse);
    expect(p.otherNode, isFalse);
    expect((await detectLocalNode(Chain.floonet, clientFor: _node(down: true))).url, 'http://127.0.0.1:13413');
  });

  group('facts', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('wfe-detect-'));
    tearDown(() => tmp.delete(recursive: true));

    test('mainnet without found chain data: the estimate; free space of the nearest folder', () async {
      String? asked;
      final f = await localNodeFacts(
        Chain.mainnet,
        folder: '${tmp.path}/node',
        freeBytes: (d) async {
          asked = d;
          return 20 * 1024 * 1024 * 1024;
        },
        isWindows: true,
      );
      expect(asked, tmp.path);
      expect(f.chainBytes, mainnetChainBytesEstimate);
      expect(f.chainBytesMeasured, isFalse);
      expect(f.firewallPrompt, isTrue);
      expect(f.enoughSpace, isTrue);
    });

    test('found usable chain data of the same chain gives the real size and the reuse list', () async {
      final f = await localNodeFacts(
        Chain.mainnet,
        folder: tmp.path,
        freeBytes: (_) async => 6 * 1024 * 1024 * 1024,
        found: [_chain(4 << 30), _chain(9 << 30, usable: false), _chain(1 << 30, chain: Chain.floonet)],
        isWindows: false,
      );
      expect(f.chainBytes, 4 << 30);
      expect(f.chainBytesMeasured, isTrue);
      expect(f.reusable, hasLength(1));
      expect(f.firewallPrompt, isFalse);
      expect(f.enoughSpace, isFalse);
    });

    test('unknown free space', () async {
      final f = await localNodeFacts(Chain.mainnet, folder: tmp.path, freeBytes: (_) async => null);
      expect(f.enoughSpace, isNull);
    });
  });
}
