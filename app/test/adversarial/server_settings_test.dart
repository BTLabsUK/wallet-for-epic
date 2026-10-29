// SPDX-License-Identifier: Apache-2.0
// Server settings a pasted or typed value controls: Connection servers must never point the
// pairing words at this device or its local network in any spelling, nor leak an onion name with
// Tor off; a node address must never hide its host; the local node relay must serve only the
// wallet.

import 'dart:io';

import 'package:epic_wallet/src/connection_servers.dart';
import 'package:epic_wallet/src/net/lan_node_relay.dart';
import 'package:epic_wallet/src/server_list.dart';
import 'package:flutter_test/flutter_test.dart';

const _chosen = ['epicbox.epiccash.com'];

({List<String>? next, SelectionRefusal? refusal}) _add(String typed, {bool torOn = false}) {
  final value = typedRelayLabel(typed);
  if (value == null) return (next: null, refusal: null);
  return toggleSelection(ServerKind.relay, _chosen, value, 3, torOn: torOn);
}

void main() {
  group('connection servers', () {
    // Each one reaches this device or its own network; most are spelt to look like a name.
    const local = [
      '127.0.0.1',
      '127.0.0.1:8080',
      '127.1:443',
      '0.0.0.0:443',
      '0.0.0.0',
      '2130706433:443',
      '0x7f000001:443',
      '0x7f.0.0.1',
      '017700000001:443',
      '10.0.0.5',
      '10.0.1.1:443',
      '172.16.0.1',
      '169.254.169.254',
      'localhost:443',
      'LOCALHOST:443',
      'wfe.localhost',
    ];
    for (final typed in local) {
      test('never_meets_on_the_local_address_$typed', () {
        final r = _add(typed);
        expect(r.next, isNull, reason: 'became ${r.next}');
      });
    }

    test('a_stored_set_drops_a_local_address_in_any_spelling', () {
      final stored = cleanConnectionServers([...local, 'epicbox.stackwallet.com']);
      expect(stored, ['epicbox.stackwallet.com']);
    });

    test('an_onion_server_needs_tor_in_every_spelling', () {
      final onion = '${'a' * 55}d.onion';
      for (final typed in [onion, onion.toUpperCase(), 'wss://$onion', 'https://$onion/', '$onion:443']) {
        expect(_add(typed).next, isNull, reason: typed);
        expect(_add(typed, torOn: true).next, isNotNull, reason: typed);
      }
    });

    test('a_value_with_a_path_user_or_scheme_trick_is_no_server', () {
      for (final typed in [
        'epicbox.epiccash.com@127.0.0.1',
        'epicbox.epiccash.com/../x',
        'epicbox.epiccash.com:0',
        'epicbox.epiccash.com:65536',
        'javascript:alert(1)',
        'file:///etc/hosts',
        'epicbox.epiccash.com\u0000.evil.com',
        'epicbox.epiccash.com evil.com',
      ]) {
        expect(typedRelayLabel(typed), isNull, reason: typed);
      }
    });
  });

  group('node addresses', () {
    test('a_typed_node_never_hides_its_host', () {
      for (final typed in [
        'https://node.btlabs.uk@evil.com',
        'https://node.btlabs.uk:x@evil.com',
        'https://evil.com?node.btlabs.uk',
        'https://evil.com/node.btlabs.uk',
        'ftp://node.btlabs.uk',
        'javascript://node.btlabs.uk',
        'https://node.btlabs.uk evil.com',
      ]) {
        expect(typedNodeUrl(typed), isNull, reason: typed);
      }
      // What is kept is exactly the host the user sees.
      expect(typedNodeUrl('HTTPS://Node.BTLabs.UK/'), 'https://node.btlabs.uk');
    });
  });

  group('local node relay', () {
    tearDown(closeLanNodeRelays);

    test('the_relay_refuses_every_request_without_its_exact_token', () async {
      final node = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      node.listen((r) async {
        r.response.write('node ${r.uri.path}');
        await r.response.close();
      });
      addTearDown(() => node.close(force: true));
      lanNodeLookup = (host) async => ['127.0.0.1'];
      final via = Uri.parse(await lanNodeUrl('http://box.lan:${node.port}'));
      final token = via.pathSegments.single;
      final client = HttpClient();
      addTearDown(client.close);
      Future<int> get(String path) async {
        final r = await (await client.getUrl(via.replace(path: path))).close();
        await r.drain<void>();
        return r.statusCode;
      }

      expect(await get('/$token/v2/foreign'), HttpStatus.ok);
      for (final path in [
        '/',
        '/v2/foreign',
        '/${token}x/v2/foreign',
        '/${token.toUpperCase()}/v2/foreign',
        '/${token.substring(1)}/v2/foreign',
        '/x/$token/v2/foreign',
        '/%2F$token/v2/foreign',
      ]) {
        expect(await get(path), HttpStatus.forbidden, reason: path);
      }
    });

    test('a_public_or_cgnat_plain_http_node_is_never_relayed_without_consent', () async {
      resetLanNodeAgreements();
      final dir = Directory.systemTemp.createTempSync('wfe-lan-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File('${dir.path}/lan_nodes.json')..writeAsStringSync('{"plainHttp":[]}');
      lanNodesFile = () async => f;
      for (final url in ['http://8.8.8.8:3413', 'http://${'100.64'}.0.9:3413', 'http://[::ffff:${'100.64'}.0.9]:3413', 'http://node.example.com:3413']) {
        expect(await lanNodeUrl(url), url, reason: url);
      }
    });
  });
}
