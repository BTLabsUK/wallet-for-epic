// SPDX-License-Identifier: Apache-2.0
// NodeApiClient over a fake transport: auth, error mapping, failovers, validation, body cap.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_api_types.dart';
import 'package:flutter_test/flutter_test.dart';

String _fix(String name) => File('test/fixtures/node/$name.json').readAsStringSync();

class _Call {
  _Call(this.url, this.body, this.headers);
  final Uri url;
  final String body;
  final Map<String, String> headers;
  String? get method => body.isEmpty ? null : (jsonDecode(body) as Map)['method'] as String?;
  Object? get params => body.isEmpty ? null : (jsonDecode(body) as Map)['params'];
}

class _Fake {
  _Fake(this.reply);
  final FutureOr<({int status, String body})> Function(_Call call) reply;
  final calls = <_Call>[];

  Future<({int status, String body})> call(Uri url, String body, Map<String, String> headers, Duration t) async {
    final c = _Call(url, body, headers);
    calls.add(c);
    return reply(c);
  }
}

({int status, String body}) _r(String body, [int status = 200]) => (status: status, body: body);

String _ok(Object? v) => jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {'Ok': v}});

Matcher _kind(NodeRpcError k) => throwsA(isA<NodeRpcException>().having((e) => e.kind, 'kind', k));

NodeApiClient _client(_Fake f, {String url = 'http://127.0.0.1:3413', String? secret = 's3cret'}) =>
    NodeApiClient(url, secret: () => secret, transport: f.call);

void main() {
  group('requests', () {
    test('foreign call: JSON-RPC body, no Authorization', () async {
      final f = _Fake((_) => _r(_fix('get_tip')));
      final tip = await _client(f).tip();
      expect(tip.height, 0);
      final c = f.calls.single;
      expect(c.url.toString(), 'http://127.0.0.1:3413/v2/foreign');
      expect(c.method, 'get_tip');
      expect(c.params, isEmpty);
      expect(c.headers.containsKey('Authorization'), isFalse);
    });

    test('owner call sends Basic epic:<secret>, secret read per call (async ok)', () async {
      final f = _Fake((_) => _r(_fix('get_status')));
      var n = 0;
      final client = NodeApiClient(
        'http://localhost:3413/',
        secret: () async => 'k${n++}',
        transport: f.call,
      );
      await client.status();
      await client.status();
      expect(f.calls.first.url.toString(), 'http://localhost:3413/v2/owner');
      expect(f.calls.first.headers['Authorization'], 'Basic ${base64.encode(utf8.encode('epic:k0'))}');
      expect(f.calls.last.headers['Authorization'], 'Basic ${base64.encode(utf8.encode('epic:k1'))}');
    });

    test('no secret yet: no header, and a 401 is unauthorized without the secret in the message', () async {
      final f = _Fake((_) => _r('', 401));
      final client = _client(f, secret: null);
      await expectLater(client.connectedPeers(), _kind(NodeRpcError.unauthorized));
      expect(f.calls.single.headers.containsKey('Authorization'), isFalse);
      final g = _Fake((_) => _r('', 401));
      try {
        await _client(g).connectedPeers();
      } on NodeRpcException catch (e) {
        expect(e.toString(), isNot(contains('s3cret')));
        expect(e.toString(), isNot(contains(base64.encode(utf8.encode('epic:s3cret')))));
      }
    });

    test('the other calls use their method and parameters', () async {
      final f = _Fake((c) => switch (c.method) {
        'ready_for_txs' => _r(_ok({'ready_for_txs': true})),
        'get_header' => _r(_ok({'timestamp': '2026-10-22T03:29:15Z'})),
        'get_connected_peers' => _r(_fix('get_connected_peers')),
        'get_peers' => _r(_fix('get_peers')),
        _ => _r(_ok(null)),
      });
      final c = _client(f);
      expect(await c.readyForTxs(), isTrue);
      expect(await c.headerTime(12), DateTime.utc(2026, 10, 22, 3, 29, 15));
      expect(f.calls.last.params, [12, null, null]);
      expect(f.calls.last.headers.containsKey('Authorization'), isFalse);
      expect(await c.connectedPeers(), isNotEmpty);
      expect(await c.peers(), hasLength(5));
      expect(f.calls.last.params, [null]);
      await c.peers(addr: '203.0.113.10:3414');
      expect(f.calls.last.params, ['203.0.113.10:3414']);
      await c.banPeer('1.2.3.4:3414');
      expect(f.calls.last.method, 'ban_peer');
      await c.unbanPeer('[2001:db8::1]:3414');
      expect(f.calls.last.method, 'unban_peer');
      expect(f.calls.last.params, ['[2001:db8::1]:3414']);
      expect(f.calls.last.headers.containsKey('Authorization'), isTrue);
    });
  });

  group('errors', () {
    test('transport failure is unreachable', () async {
      final f = _Fake((_) => throw const SocketException('refused'));
      await expectLater(_client(f).tip(), _kind(NodeRpcError.unreachable));
    });

    test('TimeoutException is timeout; a transport that never answers too', () async {
      await expectLater(_client(_Fake((_) => throw TimeoutException('x'))).tip(), _kind(NodeRpcError.timeout));
      final slow = NodeApiClient(
        'http://127.0.0.1:1',
        timeout: const Duration(milliseconds: 20),
        transport: (_, _, _, _) => Completer<({int status, String body})>().future,
      );
      await expectLater(slow.tip(), _kind(NodeRpcError.timeout));
    });

    test('HTTP 404 is methodNotFound, other statuses badResponse', () async {
      await expectLater(_client(_Fake((_) => _r('', 404))).tip(), _kind(NodeRpcError.methodNotFound));
      await expectLater(_client(_Fake((_) => _r('', 500))).tip(), _kind(NodeRpcError.badResponse));
    });

    test('JSON-RPC -32601 and -32602', () async {
      String err(int code) => jsonEncode({'jsonrpc': '2.0', 'id': 1, 'error': {'code': code, 'message': 'm'}});
      await expectLater(_client(_Fake((_) => _r(err(-32601)))).tip(), _kind(NodeRpcError.methodNotFound));
      await expectLater(_client(_Fake((_) => _r(err(-32602)))).tip(), _kind(NodeRpcError.invalidArgument));
      await expectLater(_client(_Fake((_) => _r(err(-32000)))).tip(), _kind(NodeRpcError.badResponse));
    });

    test('Err is nodeError with the text', () async {
      final f = _Fake((_) => _r(jsonEncode({'result': {'Err': {'Internal': 'NotFoundErr: peer'}}})));
      await expectLater(
        _client(f).unbanPeer('1.2.3.4:3414'),
        throwsA(isA<NodeRpcException>()
            .having((e) => e.kind, 'kind', NodeRpcError.nodeError)
            .having((e) => e.message, 'message', 'NotFoundErr: peer')),
      );
    });

    test('malformed replies are badResponse', () async {
      for (final body in ['not json', '[]', '{}', '{"result":5}', '{"result":{}}', '{"result":{"Ok":[]}}']) {
        await expectLater(_client(_Fake((_) => _r(body))).tip(), _kind(NodeRpcError.badResponse), reason: body);
      }
    });

    test('a reply over the cap is badResponse', () async {
      final big = 'x' * (maxReplyBytes + 1);
      await expectLater(_client(_Fake((_) => _r(big))).connectedPeers(), _kind(NodeRpcError.badResponse));
    });
  });

  group('failovers', () {
    test('version: foreign, then GET /v1/version on methodNotFound or badResponse', () async {
      for (final first in [_r('', 404), _r('garbage')]) {
        final f = _Fake((c) => c.url.path == '/v1/version' ? _r(_fix('v1_version')) : first);
        final v = await _client(f).version();
        expect(v.nodeVersion, '4.1.0');
        expect(f.calls.last.body, isEmpty, reason: 'GET');
        expect(f.calls.last.headers.containsKey('Authorization'), isFalse);
      }
    });

    test('version: unreachable does not fail over', () async {
      final f = _Fake((_) => throw const SocketException('x'));
      await expectLater(_client(f).version(), _kind(NodeRpcError.unreachable));
      expect(f.calls, hasLength(1));
    });

    test('status: owner, then GET /v1/status with auth on methodNotFound', () async {
      final f = _Fake((c) => c.url.path == '/v1/status' ? _r(_fix('v1_status')) : _r('', 404));
      final s = await _client(f).status();
      expect(s.userAgent, 'MW/Epic 4.1.0');
      expect(f.calls.last.url.path, '/v1/status');
      expect(f.calls.last.headers['Authorization'], startsWith('Basic '));
    });

    test('status: 401 does not fail over', () async {
      final f = _Fake((_) => _r('', 401));
      await expectLater(_client(f).status(), _kind(NodeRpcError.unauthorized));
      expect(f.calls, hasLength(1));
    });

    test('readyForTxs is null on an old node, in both forms', () async {
      expect(await _client(_Fake((_) => _r('', 404))).readyForTxs(), isNull);
      final e = jsonEncode({'error': {'code': -32601, 'message': 'Method not found'}});
      expect(await _client(_Fake((_) => _r(e))).readyForTxs(), isNull);
      await expectLater(_client(_Fake((_) => _r('', 401))).readyForTxs(), _kind(NodeRpcError.unauthorized));
    });
  });

  group('validation', () {
    test('good peer addresses are sent', () async {
      final f = _Fake((_) => _r(_ok(null)));
      for (final a in ['1.2.3.4:1', '255.255.255.255:65535', '[::1]:3414', '[2001:db8::1]:80']) {
        await _client(f).banPeer(a);
      }
      expect(f.calls, hasLength(4));
    });

    test('bad ones fail with invalidArgument and send nothing', () async {
      final f = _Fake((_) => _r(_ok(null)));
      final c = _client(f);
      for (final a in [
        '', '1.2.3.4', '1.2.3.4:', '1.2.3.4:0', '1.2.3.4:65536', '1.2.3.4:-1', '1.2.3.4:80a', 'host.example:80',
        '::1:80', '[::1]', '[::1]80', '[1.2.3.4]:80', '[::1:80', '1.2.3:80', '300.1.1.1:80', ' 1.2.3.4:80',
        '1.2.3.4:80\n', '[fe80::1%eth0]:80', '1.2.3.4:3414; rm',
      ]) {
        await expectLater(c.banPeer(a), _kind(NodeRpcError.invalidArgument), reason: a);
        await expectLater(c.unbanPeer(a), _kind(NodeRpcError.invalidArgument), reason: a);
      }
      await expectLater(c.peers(addr: 'nope'), _kind(NodeRpcError.invalidArgument));
      expect(f.calls, isEmpty);
    });

    test('plain http only to this computer, the home network or a VPN, through the relay', () async {
      final f = _Fake((_) => _r(_fix('get_tip')));
      final relayed = <String>[];
      final before = relayUrl;
      // The relay: a local-network node is handed over as a loopback port; a .lan name that
      // looks up to a public address comes back as it was (and is refused).
      relayUrl = (u) async {
        relayed.add(u);
        return u.contains('evil.lan') ? u : Uri.parse(u).replace(host: '127.0.0.1', port: 40000).toString();
      };
      addTearDown(() => relayUrl = before);
      for (final u in ['http://node.example', 'http://8.8.8.8:3413', 'http://evil.lan:3413', 'ftp://127.0.0.1', 'node.example', '']) {
        await expectLater(_client(f, url: u).tip(), _kind(NodeRpcError.invalidArgument), reason: u);
      }
      expect(f.calls, isEmpty);
      for (final u in ['https://node.example', 'https://node.example:3413/', 'http://127.0.0.1:3413', 'http://127.5.5.5',
        'http://[::1]:3413', 'http://LOCALHOST:3413', 'http://192.168.1.24:3413', 'http://100.101.1.2:3413', 'http://alice-node.lan:3413']) {
        await _client(f, url: u).tip();
      }
      expect(f.calls, hasLength(9));
      expect(f.calls[1].url.toString(), 'https://node.example:3413/v2/foreign');
      // The home-network, VPN and .lan nodes went through the relay, nothing else did.
      expect(relayed, ['http://evil.lan:3413', 'http://192.168.1.24:3413', 'http://100.101.1.2:3413', 'http://alice-node.lan:3413']);
      expect(f.calls[6].url.toString(), 'http://127.0.0.1:40000/v2/foreign');
    });

    test('get_pool_size is the mempool count', () async {
      final f = _Fake((_) => _r(jsonEncode({'result': {'Ok': 3}})));
      expect(await _client(f).poolSize(), 3);
      expect(jsonDecode(f.calls.single.body)['method'], 'get_pool_size');
    });

    test('baseUrl is exposed', () => expect(_client(_Fake((_) => _r(''))).baseUrl, 'http://127.0.0.1:3413'));
  });
}
