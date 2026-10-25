// A node on the local network (Marvelloz, 26.10.15: http://10.0.0.138:4413 "Not
// responding"). LEPIC refuses plain http to anything but loopback, so the app hands such a node
// to LEPIC through a loopback relay; https, loopback and public nodes go as they are.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/net/lan_node_relay.dart';
import 'package:epic_wallet/src/net/local_address.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

WalletConfig _config(String nodeUrl) => WalletConfig(
  dataDir: '/wallets/main',
  chain: Chain.mainnet,
  nodeUrl: nodeUrl,
  epicboxDomain: 'epicbox.epiccash.com',
  epicboxPort: 443,
);

/// LEPIC's rule for a node URL (lepic-node parse_node_url): https, or plain http to loopback.
bool _lepicTakes(String url) {
  final u = Uri.parse(url);
  return u.scheme == 'https' || (u.scheme == 'http' && (u.host == '127.0.0.1' || u.host == 'localhost' || u.host == '::1'));
}

/// A local-network IPv4 address of this computer, or null.
Future<InternetAddress?> _lanAddress() async {
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final a in i.addresses) {
      if (!a.isLoopback && isLocalIp(a.address)) return a;
    }
  }
  return null;
}

void main() {
  tearDown(closeLanNodeRelays);

  test('a plain-http node on the local network reaches LEPIC as a loopback node', () async {
    for (final url in ['http://10.0.0.138:4413', 'http://10.0.0.123:3413', 'http://10.0.0.5:3413', 'http://[fd00::5]:3413']) {
      final given = (await LepicWalletService.lepicConfigOf(_config(url))).nodeUrl;
      expect(_lepicTakes(given), isTrue, reason: '$url → $given');
      expect(Uri.parse(given).host, '127.0.0.1', reason: url);
    }
    // One relay per node.
    final a = (await LepicWalletService.lepicConfigOf(_config('http://10.0.0.138:4413'))).nodeUrl;
    final b = (await LepicWalletService.lepicConfigOf(_config('http://10.0.0.138:4413'))).nodeUrl;
    expect(a, b);
  });

  test('https, loopback, public and named nodes go as they are', () async {
    for (final url in [
      'https://node.btlabs.uk',
      'https://node.epiccash.com:3413',
      'http://127.0.0.1:3413',
      'http://localhost:3413',
      'https://10.0.0.138:4413',
      'http://203.0.113.5:3413',
      'http://mynode.lan:3413',
    ]) {
      expect((await LepicWalletService.lepicConfigOf(_config(url))).nodeUrl, url);
    }
  });

  test('the relay carries the node\'s answers, and closes when the node does not answer', () async {
    final lan = await _lanAddress();
    if (lan == null) {
      markTestSkipped('no local-network address on this computer');
      return;
    }
    final node = await HttpServer.bind(lan, 0);
    node.listen((r) async {
      final body = jsonDecode(await utf8.decoder.bind(r).join()) as Map<String, dynamic>;
      r.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': {'Ok': {'height': 3769328}}}));
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
      expect(answer['result'], {'Ok': {'height': 3769328}});
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
