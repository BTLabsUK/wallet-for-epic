// SPDX-License-Identifier: Apache-2.0
// The parsers of a node's replies, with the captured fixtures and hand-made variants.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _ok(String name) =>
    ((jsonDecode(File('test/fixtures/node/$name.json').readAsStringSync()) as Map)['result'] as Map)['Ok'];

Object? _flat(String name) => jsonDecode(File('test/fixtures/node/$name.json').readAsStringSync());

Matcher get _bad => throwsA(isA<NodeRpcException>().having((e) => e.kind, 'kind', NodeRpcError.badResponse));

Map<String, Object?> _status(String sync, [Object? info]) => {
  'protocol_version': 2,
  'user_agent': 'MW/Epic 4.1.0',
  'connections': 3,
  'tip': {'height': 10},
  'sync_status': sync,
  'sync_info': ?info,
};

void main() {
  group('fixtures', () {
    test('version, flat and wrapped', () {
      expect(parseVersion(_ok('get_version')).nodeVersion, '4.1.0');
      expect(parseVersion(_ok('get_version')).blockHeaderVersion, 6);
      expect(parseVersion(_flat('v1_version')).nodeVersion, '4.1.0');
    });

    test('tip', () {
      final t = parseTip(_ok('get_tip'));
      expect(t.height, 0);
      expect(t.lastBlockHash, startsWith('4540'));
      expect(t.totalDifficulty.keys, containsAll(['cuckaroo', 'cuckatoo', 'progpow', 'randomx']));
    });

    test('ready_for_txs', () => expect(parseReadyForTxs(_ok('ready_for_txs')), isFalse));

    test('status, wrapped and flat', () {
      final s = parseStatus(_ok('get_status'));
      expect(s.syncStatus, 'header_sync');
      expect(s.syncInfo!.currentHeight, 7168);
      expect(s.syncInfo!.highestHeight, 8704);
      expect(s.connections, 5);
      expect(s.version, '4.1.0');
      expect(parseStatus(_flat('v1_status')).userAgent, 'MW/Epic 4.1.0');
    });

    test('connected peers', () {
      final p = parseConnectedPeers(_ok('get_connected_peers'));
      expect(p, isNotEmpty);
      expect(p.first.addr, '203.0.113.10:3414');
      expect(p.first.direction, PeerDirection.outbound);
      expect(p.first.onionAddr, isNull);
      expect(p.first.capabilities, contains('HEADER_HIST'));
    });

    test('stored peers: healthy with times, unknown with 0 as null', () {
      final p = parseStoredPeers(_ok('get_peers'));
      expect(p, hasLength(5));
      expect(p.first.flag, PeerFlag.healthy);
      expect(p.first.lastConnected, DateTime.fromMillisecondsSinceEpoch(1792678689 * 1000, isUtc: true));
      expect(p.first.lastBanned, isNull);
      expect(p[3].flag, PeerFlag.unknown);
      expect(p[3].lastConnected, isNull);
    });
  });

  group('sync_info variants', () {
    test('no info', () {
      for (final s in ['no_sync', 'awaiting_peers', 'shutdown', 'compacting', 'syncing']) {
        final st = parseStatus(_status(s));
        expect(st.syncStatus, s);
        expect(st.syncInfo, isNull);
      }
    });

    test('header_sync and body_sync', () {
      for (final s in ['header_sync', 'body_sync']) {
        final i = parseStatus(_status(s, {'current_height': 5, 'highest_height': 9})).syncInfo!;
        expect([i.currentHeight, i.highestHeight], [5, 9]);
        expect(i.downloadedBytes, isNull);
      }
    });

    test('txhashset_download', () {
      final i = parseStatus(_status('txhashset_download', {'downloaded_size': 10, 'total_size': 40})).syncInfo!;
      expect([i.downloadedBytes, i.totalBytes], [10, 40]);
    });

    test('rangeproofs and kernels validation', () {
      final r = parseStatus(_status('txhashset_rangeproofs_validation', {'rproofs': 1, 'rproofs_total': 2})).syncInfo!;
      expect([r.rangeProofs, r.rangeProofsTotal], [1, 2]);
      final k = parseStatus(_status('txhashset_kernels_validation', {'kernels': 3, 'kernels_total': 4})).syncInfo!;
      expect([k.kernels, k.kernelsTotal], [3, 4]);
    });
  });

  test('a banned stored peer with ManualBan and last_banned', () {
    final p = parseStoredPeers([
      {
        'addr': '198.51.100.7:3414',
        'ban_reason': 'ManualBan',
        'flags': 'Banned',
        'last_banned': 1792000000,
        'last_connected': 0,
        'capabilities': '',
        'user_agent': 'MW/Epic 4.0.3',
      },
    ]).single;
    expect(p.banned, isTrue);
    expect(p.banReason, 'ManualBan');
    expect(p.lastBanned, DateTime.fromMillisecondsSinceEpoch(1792000000 * 1000, isUtc: true));
    expect(p.lastConnected, isNull);
  });

  test('difficulty above 2^53 keeps every digit; the {"num":..} wrapper is read', () {
    final big = jsonDecode('{"height":1,"total_difficulty":{"progpow":8100000000000000001,"randomx":5}}');
    expect(parseTip(big).totalDifficulty['progpow'], 8100000000000000001);
    final wrapped = jsonDecode('{"height":1,"total_difficulty":{"num":{"randomx":7}}}');
    expect(parseTip(wrapped).totalDifficulty, {'randomx': 7});
  });

  test('header time', () {
    expect(parseHeaderTime({'timestamp': '2026-10-22T03:29:15+00:00'}), DateTime.utc(2026, 10, 22, 3, 29, 15));
    expect(parseHeaderTime({'height': 1}), isNull);
  });

  group('wrong shapes are badResponse', () {
    test('version', () {
      expect(() => parseVersion([]), _bad);
      expect(() => parseVersion({'node_version': 4}), _bad);
    });
    test('tip', () => expect(() => parseTip({'height': 'x'}), _bad));
    test('ready_for_txs', () {
      expect(() => parseReadyForTxs({'ready_for_txs': 'yes'}), _bad);
      expect(() => parseReadyForTxs(null), _bad);
    });
    test('header', () => expect(() => parseHeaderTime('x'), _bad));
    test('status', () {
      expect(() => parseStatus({'protocol_version': 2}), _bad);
      expect(() => parseStatus(_status('x')..remove('tip')), _bad);
    });
    test('peers', () {
      expect(() => parseConnectedPeers({}), _bad);
      expect(() => parseConnectedPeers([1]), _bad);
      expect(() => parseConnectedPeers([{'direction': 'Inbound'}]), _bad);
      expect(() => parseStoredPeers('x'), _bad);
      expect(() => parseStoredPeers([{'flags': 'Healthy'}]), _bad);
    });
  });
}
