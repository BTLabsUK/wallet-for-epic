// SPDX-License-Identifier: Apache-2.0
// A node on the local network (a tester, 26.10.15: http://10.0.0.138:4413 "Not
// responding"; a tester's LAN node at 10.0.1.16:3413 and alice-node.lan:3413 "no answer"). LEPIC refuses plain
// http to anything but loopback, so the app hands such a node to LEPIC through a loopback relay
// (a .local/.lan name looked up once, every address local); loopback goes directly; https,
// public addresses, onions and other names go as they are. A CGNAT (tailnet) address is relayed
// only once the user agreed for that node, and the relay answers only requests that carry its
// token.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/net/lan_node_relay.dart';
import 'package:epic_wallet/src/net/local_address.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

WalletConfig _config(String nodeUrl) => WalletConfig(dataDir: '/wallets/main', chain: Chain.mainnet, nodeUrl: nodeUrl, epicboxDomain: 'epicbox.epiccash.com', epicboxPort: 443);

/// LEPIC's rule for a node URL (lepic-node parse_node_url): https, or plain http to loopback.
bool _lepicTakes(String url) {
  final u = Uri.parse(url);
  return u.scheme == 'https' || (u.scheme == 'http' && (u.host == 'localhost' || isLoopbackIp(u.host)));
}

/// An IPv4 address of this computer that [take] accepts, or null.
Future<InternetAddress?> _ownAddress(bool Function(String) take) async {
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final a in i.addresses) {
      if (!a.isLoopback && take(a.address)) return a;
    }
  }
  return null;
}

void main() {
  late Directory home;
  setUp(() {
    home = Directory.systemTemp.createTempSync('wfe_lan_');
    lanNodesFile = () async => File('${home.path}/lan_nodes.json');
    resetLanNodeAgreements();
  });
  tearDown(() async {
    await closeLanNodeRelays();
    resetLanNodeAgreements();
    home.deleteSync(recursive: true);
  });

  // What LEPIC is given for each kind of address: relayed (http://127.0.0.1:<relay port>), direct
  // (LEPIC takes it as it is: loopback), unchanged (https, public, onion, other names: LEPIC
  // judges them as before, plain http to them refused).
  const relayed = [
    'http://10.0.0.138:4413',
    'http://10.0.1.16:3413',
    'http://10.0.0.5:3413',
    'http://172.16.0.9:3413',
    'http://172.31.255.1:3413',
    'http://169.254.10.20:3413',
    'http://[fd00::5]:3413',
    'http://[fc12::1]:3413',
    'http://[fe80::1]:3413',
    'http://[fe80::1%25eth0]:3413',
    'http://Alice-node.lan:3413',
    'http://mynode.local:3413',
    // CGNAT / Tailscale tailnet, 100.64.0.0/10.
    'http://100.64.3.9:3413',
    'http://100.64.20.30:4413',
    'http://100.127.255.254:3413',
  ];
  const direct = ['http://127.0.0.1:3413', 'http://127.0.0.2:3413', 'http://localhost:3413', 'http://[::1]:3413'];
  const unchanged = [
    'https://node.btlabs.uk',
    'https://node.epiccash.com:3413',
    'https://10.0.0.138:4413',
    'http://203.0.113.5:3413',
    'http://172.32.0.1:3413',
    // Just outside 100.64.0.0/10.
    'http://100.63.255.255:3413',
    'http://100.128.0.1:3413',
    'http://node.example:3413',
    'http://abc.onion:3413',
    // A .lan name that resolves to a public address, or not at all.
    'http://public.lan:3413',
    'http://gone.local:3413',
  ];
  final lookups = <String>[];

  setUp(() async {
    lookups.clear();
    for (final url in relayed.where(needsPlainHttpConsent)) {
      await allowPlainHttpNode(url);
    }
    lanNodeLookup = (host) async {
      lookups.add(host);
      return switch (host.toLowerCase()) {
        'alice-node.lan' => ['10.0.1.16'],
        'mynode.local' => ['fe80::2', '10.100.10.20'],
        'public.lan' => ['10.0.1.30', '203.0.113.7'],
        _ => throw const SocketException('no such host'),
      };
    };
  });

  test('every local-network address and .local/.lan name is relayed; loopback goes directly', () async {
    for (final url in relayed) {
      final given = (await LepicWalletService.lepicConfigOf(_config(url))).nodeUrl;
      expect(_lepicTakes(given), isTrue, reason: '$url → $given');
      expect(Uri.parse(given).host, '127.0.0.1', reason: url);
      expect(Uri.parse(given).port, isNot(Uri.parse(url).port), reason: url);
    }
    for (final url in direct) {
      expect((await LepicWalletService.lepicConfigOf(_config(url))).nodeUrl, url);
      expect(_lepicTakes(url), isTrue, reason: url);
    }
    // One relay per node.
    final a = (await LepicWalletService.lepicConfigOf(_config('http://10.0.0.138:4413'))).nodeUrl;
    final b = (await LepicWalletService.lepicConfigOf(_config('http://10.0.0.138:4413'))).nodeUrl;
    expect(a, b);
  });

  test('https, public, onion and other names go as they are; a name is looked up only when .local or .lan', () async {
    for (final url in unchanged) {
      expect((await LepicWalletService.lepicConfigOf(_config(url))).nodeUrl, url, reason: url);
    }
    expect(lookups, ['public.lan', 'gone.local']);
  });

  test('a tailnet (CGNAT) node goes through the relay only once agreed for', () async {
    resetLanNodeAgreements();
    final other = File('${home.path}/other.json')..writeAsStringSync('{"plainHttp":[]}');
    lanNodesFile = () async => other;
    const tail = 'http://100.64.21.31:3413';
    expect(needsPlainHttpConsent(tail), isTrue);
    expect(needsPlainHttpConsent('http://10.0.0.5:3413'), isFalse);
    expect(needsPlainHttpConsent('https://100.64.21.31:3413'), isFalse);
    expect(await lanNodeUrl(tail), tail, reason: 'LEPIC refuses it as before');
    await allowPlainHttpNode(tail);
    expect(Uri.parse(await lanNodeUrl(tail)).host, '127.0.0.1');
    // Kept: a new run reads the agreement back.
    resetLanNodeAgreements();
    expect(await plainHttpNodeAllowed(tail), isTrue);
  });

  test('on the first run with agreements the tailnet nodes in use count as agreed', () async {
    resetLanNodeAgreements();
    lanNodesFile = () async => File('${home.path}/first.json');
    expect(Uri.parse(await lanNodeUrl('http://100.64.3.9:3413')).host, '127.0.0.1');
    expect(await plainHttpNodeAllowed('http://100.64.3.9:3413'), isTrue);
    // A later run: only what was agreed.
    resetLanNodeAgreements();
    expect(await lanNodeUrl('http://100.64.20.30:4413'), 'http://100.64.20.30:4413');
    expect(await plainHttpNodeAllowed('http://100.64.3.9:3413'), isTrue);
  });

  test('the relay answers only requests that carry its token', () async {
    final node = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    node.listen((r) async {
      r.response.write('path ${r.uri.path}');
      await r.response.close();
    });
    addTearDown(() => node.close(force: true));
    // Loopback goes directly, so reach the relay through a local name that resolves to it.
    lanNodeLookup = (host) async => ['127.0.0.1'];
    final via = await lanNodeUrl('http://box.lan:${node.port}');
    final relayed = Uri.parse(via);
    expect(relayed.pathSegments.single, hasLength(22), reason: '128 random bits');
    final client = HttpClient();
    addTearDown(client.close);
    final ok = await (await client.getUrl(Uri.parse('$via/v2/foreign'))).close();
    expect(await utf8.decoder.bind(ok).join(), 'path /v2/foreign');
    final guessed = relayed.replace(path: '/v2/foreign');
    final refused = await (await client.getUrl(guessed)).close();
    expect(refused.statusCode, HttpStatus.forbidden);
    await refused.drain<void>();
  });

  test('a .lan name is looked up once and the relay goes to the address found', () async {
    final via = await lanNodeUrl('http://Alice-node.lan:3413');
    expect(lookups, ['alice-node.lan'], reason: 'a URL host is lowercase');
    expect(Uri.parse(via).host, '127.0.0.1');
    // Same address, same relay: http://10.0.1.16:3413 typed directly shares it.
    expect(await lanNodeUrl('http://10.0.1.16:3413'), via);
  });

  test('which nodes count as local for the node list', () {
    for (final url in [...relayed, ...direct]) {
      expect(isLocalNodeUrl(url), isTrue, reason: url);
    }
    for (final url in unchanged.where((u) => !u.contains('.lan') && !u.contains('.local') && !u.startsWith('https://192.'))) {
      expect(isLocalNodeUrl(url), isFalse, reason: url);
    }
  });

  for (final (what, take) in [('a local-network', isLocalIp), ('a tailnet (CGNAT)', isCgnatIp)]) {
    test('the relay carries the answers of a node at $what address, and closes when the node does not answer', () async {
      final lan = await _ownAddress(take);
      if (lan == null) {
        markTestSkipped('no $what address on this computer');
        return;
      }
      final node = await HttpServer.bind(lan, 0);
      node.listen((r) async {
        final body = jsonDecode(await utf8.decoder.bind(r).join()) as Map<String, dynamic>;
        r.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'Ok': {'height': 3769328},
              },
            }),
          );
        await r.response.close();
      });
      addTearDown(() => node.close(force: true));

      final via = await lanNodeUrl('http://${lan.address}:${node.port}');
      expect(Uri.parse(via).host, '127.0.0.1');
      final client = HttpClient();
      addTearDown(client.close);
      for (var i = 0; i < 2; i++) {
        final req = await client.postUrl(Uri.parse('$via/v2/foreign'));
        req.write(jsonEncode({'jsonrpc': '2.0', 'id': i, 'method': 'get_tip', 'params': []}));
        final res = await req.close();
        final answer = jsonDecode(await utf8.decoder.bind(res).join()) as Map<String, dynamic>;
        expect(answer['result'], {
          'Ok': {'height': 3769328},
        });
      }

      // Nothing listens there any more: the relay closes the connection, as a node that is down.
      final port = node.port;
      await node.close(force: true);
      final dead = await lanNodeUrl('http://${lan.address}:$port');
      await expectLater(() async {
        final req = await client.postUrl(Uri.parse('$dead/v2/foreign'));
        await (await req.close()).drain<void>();
      }(), throwsA(isA<HttpException>()));
    });
  }
}
