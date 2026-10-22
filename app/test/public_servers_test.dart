// The public node and relay lists: status.btlabs.uk's answer (a copy captured on 2026-10-22),
// the built-in lists and their merge, and the directory's timeout and cache.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/public_servers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:flutter_test/flutter_test.dart';

final String _sample = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

NodeStatus _node(String url, {String? operator}) => NodeStatus(url: url, healthy: true, verified: false, operator: operator);

void main() {
  group('parse', () {
    test('reads the five public nodes of the sample, in its order', () {
      final nodes = parseNodeStatus(_sample);
      expect(nodes.map((n) => n.url), [
        'https://node.btlabs.uk',
        'https://epic-node.iniaku.my.id', // :443 dropped, as Uri does
        'https://node.epiccash.com:3413',
        'https://node.epicnet.us:3413',
        'https://epic.stackwallet.com:3413',
      ]);
      expect(nodes.map((n) => n.operator), ['btlabs', 'Iniaku pool', 'Epic Cash', 'epicnet.us', 'Cypher Stack']);
      expect(nodes.first.healthy, isTrue);
      expect(nodes.first.height, greaterThan(3700000));
      expect(nodes.first.latencyMs, isNotNull);
    });

    test('reads the four relays of the sample', () {
      expect(parseRelayStatus(_sample).map((r) => r.relay.host).toSet(), {
        'epicbox.stackwallet.com',
        'epicbox.epicnet.us',
        'epicbox.epiccash.com',
        'epicbox.iniaku.my.id',
      });
    });

    test('drops entries that are not an https node, and cleans operator names', () {
      final nodes = parseNodeStatus(jsonEncode({
        'nodes': [
          {'endpoint': 'https://ok.example:3413', 'state': 'down'},
          {'endpoint': 'wss://relay.example/'},
          {'endpoint': 'https://user:pw@x.example'},
          {'endpoint': 'https://x.example/path'},
          {'endpoint': 'https://pool.example', 'kind': 'pool'},
          'junk',
          {'endpoint': 'http://plain.example:3413/', 'operator': 'Plain'},
          {'endpoint': 'https://blank.example', 'operator': '  '},
          {'endpoint': 'https://bidi.example', 'operator': 'Pool\u202e\u0007 A'},
        ],
      }));
      expect(nodes.map((n) => n.url), ['https://ok.example:3413', 'https://blank.example', 'https://bidi.example'], reason: 'https only');
      expect(nodes.first.healthy, isFalse);
      expect(nodes[1].operator, isNull);
      expect(nodes.last.operator, 'Pool A');
      expect(() => parseNodeStatus('[]'), throwsFormatException);
      expect(() => parseNodeStatus('{}'), throwsFormatException);
    });
  });

  group('merge', () {
    test('the monitor down: the built-in lists, BT Labs and Epic Cash first (D-13)', () {
      final nodes = mergePublicNodes(null);
      expect(nodes.map((n) => n.url), builtInNodes.map((n) => n.url));
      expect(nodes, hasLength(5));
      expect(nodes.first.url, 'https://node.btlabs.uk');
      expect(nodes.every((n) => n.status == null), isTrue);
      final relays = mergePublicRelays(null);
      expect(relays, hasLength(4));
      expect(relays.first.relay.host, 'epicbox.epiccash.com');
    });

    test('the sample matches every built-in server, one row each', () {
      final nodes = mergePublicNodes(parseNodeStatus(_sample));
      expect(nodes.map((n) => n.url), builtInNodes.map((n) => n.url));
      expect(nodes.every((n) => n.status != null), isTrue);
      // :443 on https is the same node as no port.
      expect(nodes.last.url, 'https://epic-node.iniaku.my.id');
      expect(nodes.last.operator, 'Iniaku pool');
      final relays = mergePublicRelays(parseRelayStatus(_sample));
      expect(relays.map((r) => r.relay), builtInRelays.map((r) => r.relay));
      expect(relays.every((r) => r.status != null), isTrue);
    });

    test('a node only the monitor lists comes after, with its operator', () {
      final nodes = mergePublicNodes([
        _node('https://new.example:3413', operator: 'New op'),
        _node('https://NODE.btlabs.uk:443'),
        _node('https://bare.example'),
        _node('https://new.example:3413', operator: 'Twice'),
      ]);
      expect(nodes.map((n) => n.url), [...builtInNodes.map((n) => n.url), 'https://new.example:3413', 'https://bare.example']);
      expect(nodes.first.status, isNotNull);
      expect(nodes[5].operator, 'New op');
      expect(nodes[6].operator, 'bare.example');
    });

    test('a relay only the monitor lists comes after, with its operator', () {
      final relays = mergePublicRelays([
        const RelayStatus(relay: EpicboxRelay(host: 'box.example', port: 8443), healthy: true, verified: false, operator: 'Box op'),
        const RelayStatus(relay: EpicboxRelay(host: 'epicbox.epiccash.com'), healthy: false, verified: true),
      ]);
      expect(relays, hasLength(5));
      expect(relays.last.relay, const EpicboxRelay(host: 'box.example', port: 8443));
      expect(relays.last.operator, 'Box op');
      expect(relays.first.status?.healthy, isFalse);
    });
  });

  group('directory', () {
    test('gives up after its timeout', () async {
      final dir = HttpRelayDirectory(
        timeout: const Duration(milliseconds: 50),
        get: (url, {timeout = defaultHttpTimeout}) => Completer<HttpReply>().future,
      );
      await expectLater(dir.nodes('mainnet'), throwsA(isA<TimeoutException>()));
    });

    test('asks once for nodes and relays while fresh, again after', () async {
      var now = DateTime(2026, 10, 22);
      final asked = <Uri>[];
      final dir = HttpRelayDirectory(
        now: () => now,
        get: (url, {timeout = defaultHttpTimeout}) async {
          asked.add(url);
          return HttpReply(200, _sample);
        },
      );
      expect(await dir.nodes('mainnet'), hasLength(5));
      expect(await dir.relays('mainnet'), hasLength(4));
      expect(asked, hasLength(1));
      expect(asked.single.toString(), relayStatusUrl);
      await dir.nodes('floonet');
      expect(asked.last.queryParameters['chain'], 'floonet');
      now = now.add(const Duration(minutes: 2));
      await dir.nodes('mainnet');
      expect(asked, hasLength(3));
    });

    test('keeps a failure for a while too', () async {
      var calls = 0;
      final dir = HttpRelayDirectory(get: (url, {timeout = defaultHttpTimeout}) async {
        calls++;
        return const HttpReply(503, '');
      });
      await expectLater(dir.nodes('mainnet'), throwsA(isA<NetError>()));
      await expectLater(dir.relays('mainnet'), throwsA(isA<NetError>()));
      expect(calls, 1);
    });
  });
}
