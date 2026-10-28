// SPDX-License-Identifier: Apache-2.0
// The user's own node: the address classes; the own-node info asked directly
// (no directory lookup, mempool, the reference tip never from the node, Syncing / Behind); the
// owner secret (checked, kept per URL, never sent to a public node or over Tor, a later refusal,
// redacted in logs, not in the saved prefs); and Settings › Node at 1280 and 2474 wide.
import 'dart:convert';

import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/own_node.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/redact.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Dir implements NodeDirectory, NetworkDirectory {
  _Dir({this.tip});

  final int? tip;
  int nodeCalls = 0;

  @override
  Future<List<NodeStatus>> nodes(String chain) async {
    nodeCalls++;
    return const [];
  }

  @override
  Future<NetworkStatus> network(String chain) async {
    if (tip == null) throw StateError('down');
    return NetworkStatus(tipHeight: tip, releasedNodeVersion: '4.1.1');
  }
}

/// A node answering the foreign API at [height()].
NodeApiClient Function(String) _node(int Function() height, {bool ready = true, int pool = 3}) => (url) => NodeApiClient(
  url,
  transport: (uri, body, headers, t) async {
    final method = (jsonDecode(body) as Map)['method'];
    final ok = switch (method) {
      'get_tip' => {'height': height(), 'last_block_pushed': 'ab', 'total_difficulty': {}},
      'ready_for_txs' => {'ready_for_txs': ready},
      'get_version' => {'node_version': '4.1.1', 'block_header_version': 6},
      'get_header' => {'height': height(), 'timestamp': '2026-10-22T14:16:03+00:00'},
      'get_pool_size' => pool,
      _ => throw StateError('$method'),
    };
    return (status: 200, body: jsonEncode({'result': {'Ok': ok}}));
  },
);

void main() {
  group('address classes', () {
    test('this computer, home network, VPN, own server, public', () {
      expect(nodeClassOf('http://127.0.0.1:3413'), NodeClass.thisComputer);
      expect(nodeClassOf('http://localhost:3413'), NodeClass.thisComputer);
      expect(nodeClassOf('http://[::1]:3413'), NodeClass.thisComputer);
      for (final u in ['http://10.0.1.24:3413', 'http://10.0.0.5:3413', 'http://172.20.1.1:3413', 'http://Alice-node.lan:3413', 'http://node.local:3413', 'http://[fe80::1]:3413']) {
        expect(nodeClassOf(u), NodeClass.homeNetwork, reason: u);
      }
      expect(nodeClassOf('http://100.101.1.2:3413'), NodeClass.vpn);
      expect(nodeClassOf('https://box.tail1234.ts.net'), NodeClass.vpn);
      expect(nodeClassOf('https://node.btlabs.uk'), NodeClass.public);
      expect(nodeClassOf('https://bt-node.example', unlisted: true), NodeClass.ownServer);
      expect(nodeClassOf('https://node.btlabs.uk', mine: true), NodeClass.ownServer);
      expect(nodeClassOf('http://8.8.8.8:3413'), NodeClass.public);
      expect(NodeClass.vpn.own && NodeClass.vpn.local, isTrue);
      expect(NodeClass.ownServer.own && !NodeClass.ownServer.local, isTrue);
    });
  });

  group('own-node info', () {
    test('asked directly: no directory lookup, mempool, the tip from the status site', () async {
      final dir = _Dir(tip: 3764980);
      final s = NodeInfoService(nodes: dir, network: dir, clientFor: _node(() => 3764975));
      final i = await s.info('http://10.0.1.24:3413', chain: 'mainnet');
      expect(dir.nodeCalls, 0, reason: 'status.btlabs.uk cannot see a home node');
      expect(i.nodeClass, NodeClass.homeNetwork);
      expect(i.source, NodeInfoSource.limited);
      expect(i.poolSize, 3);
      expect(i.blocksBehind, 5);
      expect(i.tipFrom, TipReference.statusSite);
      expect(i.head, NodeHead.synced);
    });

    test('no status site: the public nodes\' median tip; a height that moves is Syncing, one that does not is Behind', () async {
      var h = 3700000;
      final dir = _Dir();
      final s = NodeInfoService(nodes: dir, network: dir, clientFor: _node(() => h), publicTip: (_) async => (tip: 3764975, nodes: 4));
      final first = await s.info('http://10.0.1.24:3413', chain: 'mainnet');
      expect(first.tipFrom, TipReference.publicNodes);
      expect(first.tipNodes, 4);
      expect(first.head, NodeHead.behind);
      h += 500;
      expect((await s.info('http://10.0.1.24:3413', chain: 'mainnet')).head, NodeHead.syncing);
      expect((await s.info('http://10.0.1.24:3413', chain: 'mainnet')).head, NodeHead.behind);
    });

    test('not ready for transactions is Syncing; an unlisted https node is an own server', () async {
      final dir = _Dir(tip: 3764975);
      final s = NodeInfoService(nodes: dir, network: dir, clientFor: _node(() => 3764975, ready: false));
      expect((await s.info('http://127.0.0.1:3413', chain: 'mainnet')).head, NodeHead.syncing);
      final srv = await s.info('https://bt-node.example', chain: 'mainnet');
      expect(dir.nodeCalls, 1);
      expect(srv.nodeClass, NodeClass.ownServer);
    });
  });

  group('owner secret', () {
    /// An owner API that takes [secret]; records the Authorization headers it saw.
    ({List<String?> auth, NodeApiClient Function(String, Future<String?> Function()) client}) owner({String secret = 's3cret', bool down = false}) {
      final auth = <String?>[];
      return (
        auth: auth,
        client: (url, read) => NodeApiClient(
          url,
          secret: read,
          transport: (uri, body, headers, t) async {
            auth.add(headers['Authorization']);
            if (down) throw StateError('down');
            final want = 'Basic ${base64.encode(utf8.encode('epic:$secret'))}';
            final method = (jsonDecode(body) as Map)['method'];
            if (method != 'get_status' && headers['Authorization'] != want) return (status: 401, body: '');
            final ok = switch (method) {
              'get_status' => {'protocol_version': 1000, 'user_agent': 'MW/Epic 4.1.1', 'connections': 9, 'tip': {'height': 100, 'last_block_pushed': 'ab', 'total_difficulty': {}}, 'sync_status': 'no_sync'},
              'get_connected_peers' => <Object>[],
              'get_peers' => <Object>[],
              _ => throw StateError('$method'),
            };
            return (status: 200, body: jsonEncode({'result': {'Ok': ok}}));
          },
        ),
      );
    }

    test('kept per URL under one key; a wrong one is refused and not kept', () async {
      final store = MemorySecretStore();
      final o = owner();
      final a = OwnNodeAccess(store, clientFor: o.client, torOn: () => false);
      expect(ownerSecretKey('http://10.0.1.24:3413/'), 'node.ownerSecret.http://10.0.1.24:3413');
      expect(ownerSecretKey('https://Node.Example'), 'node.ownerSecret.https://node.example:443');
      expect(await a.add('http://10.0.1.24:3413', 'wrong'), OwnerCheck.refused);
      expect(store.values, isEmpty);
      expect(await a.add('http://10.0.1.24:3413', 's3cret\nsecond line'), OwnerCheck.ok);
      expect(store.values, {'node.ownerSecret.http://10.0.1.24:3413': 's3cret'});
      final st = await a.status('http://10.0.1.24:3413');
      expect(st.peers, 9);
      expect(st.synced, isTrue);
      await a.remove('http://10.0.1.24:3413');
      expect(store.values, isEmpty);
    });

    test('a node that does not answer keeps the secret', () async {
      final store = MemorySecretStore();
      final a = OwnNodeAccess(store, clientFor: owner(down: true).client, torOn: () => false);
      expect(await a.add('http://127.0.0.1:3413', 's3cret'), OwnerCheck.noAnswer);
      expect(await a.has('http://127.0.0.1:3413'), isTrue);
    });

    test('never to a public node; an own https server not while Tor is on; a home node is fine with Tor', () async {
      expect(ownerSecretMayTravel('https://node.btlabs.uk', mine: false, torOn: false), isFalse);
      expect(ownerSecretMayTravel('http://8.8.8.8:3413', mine: false, torOn: false), isFalse);
      expect(ownerSecretMayTravel('https://node.btlabs.uk', mine: true, torOn: false), isTrue);
      expect(ownerSecretMayTravel('https://node.btlabs.uk', mine: true, torOn: true), isFalse);
      expect(ownerSecretMayTravel('http://10.0.1.24:3413', mine: false, torOn: true), isTrue, reason: 'local addresses bypass Tor');
      // https goes straight to its host, which Tor would carry: never while the switch is on.
      expect(ownerSecretMayTravel('https://10.0.1.24:3413', mine: false, torOn: true), isFalse);
      expect(ownerSecretMayTravel('https://box.tail1234.ts.net', mine: false, torOn: true), isFalse);
      expect(ownerSecretMayTravel('https://10.0.1.24:3413', mine: false, torOn: false), isTrue);
      // Plain http only where the relay takes it: a .ts.net name is not one.
      expect(ownerSecretMayTravel('http://box.tail1234.ts.net:3413', mine: false, torOn: false), isFalse);
      final o = owner();
      final a = OwnNodeAccess(MemorySecretStore({ownerSecretKey('https://node.btlabs.uk'): 's3cret'}), clientFor: o.client, torOn: () => false);
      expect(await a.add('https://node.btlabs.uk', 's3cret'), OwnerCheck.refused);
      await expectLater(a.status('https://node.btlabs.uk'), throwsA(isA<OwnerUnavailable>().having((e) => e.why, 'why', OwnerOff.torOn)));
      expect(o.auth, isEmpty, reason: 'nothing was sent');
      expect(ownerSecretPlainOnLan('http://10.0.1.24:3413'), isTrue);
      // 100.64/10 is a VPN only while one runs; otherwise the carrier's network: warned.
      expect(ownerSecretPlainOnLan('http://100.101.1.2:3413'), isTrue);
      expect(ownerSecretPlainOnLan('http://127.0.0.1:3413'), isFalse);
    });

    test('a rotated secret: refused since the first 401, not a down node', () async {
      final store = MemorySecretStore({ownerSecretKey('http://10.0.1.24:3413'): 'old'});
      final at = DateTime(2026, 10, 27, 14, 2);
      final a = OwnNodeAccess(store, clientFor: owner().client, torOn: () => false, clock: () => at);
      await expectLater(
        a.status('http://10.0.1.24:3413'),
        throwsA(isA<OwnerUnavailable>().having((e) => e.why, 'why', OwnerOff.refused).having((e) => e.since, 'since', at)),
      );
    });

    test('redacted in logs; not in the saved prefs', () {
      final header = 'Authorization: Basic ${base64.encode(utf8.encode('epic:s3cretValue123'))}';
      expect(redact(header), isNot(contains(base64.encode(utf8.encode('epic:s3cretValue123')))));
      final prefs = const SettingsPrefs().copyWith(mineNodes: {'https://node.btlabs.uk'}, plainHttpSeen: {'http://10.0.1.24:3413'});
      expect(jsonEncode(prefs.toJson()), isNot(contains('ownerSecret')));
    });
  });

  group('Settings › Node panel', () {
    late MockDeskNode node;
    late ProviderContainer container;

    setUp(() {
      node = MockDeskNode();
      container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskNodeProvider.overrideWithValue(node)]);
    });

    tearDown(() => container.dispose());

    Future<void> show(WidgetTester tester, Size size, NodeDemo demo) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SettingsNodeScreen(arg: demo))),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> end(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 16));
    }

    testWidgets('1280: tier 1 facts asked directly, Owner access not set up; Add… opens the dialog with the LAN warning', (tester) async {
      await show(tester, const Size(1280, 1000), NodeDemo.own);
      expect(find.textContaining('Own node · home network'), findsWidgets);
      expect(find.text('Mempool'), findsOneWidget);
      expect(find.text('3 waiting'), findsOneWidget);
      expect(find.text('Asked directly every 15 s · tip from status.btlabs.uk'), findsOneWidget);
      expect(find.text('Not set up'), findsOneWidget);
      await tester.tap(find.text('Add…'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Owner access to 10.0.1.24:3413'), findsOneWidget);
      expect(find.text('The secret travels unencrypted on the home network'), findsOneWidget);
      expect(find.text('Pick the file…'), findsNothing, reason: 'the file picker is for this computer only');
      await tester.enterText(find.byType(EditableText).last, 'wrong');
      await tester.tap(find.text('Add').last);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('The node refused this secret'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).last, node.ownerSecret);
      await tester.tap(find.text('Add').last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(await node.hasOwnerSecret(ownDemoUrl), isTrue);
      await end(tester);
    });

    testWidgets('1280 with access: Status and Peers as tabs', (tester) async {
      await show(tester, const Size(1280, 1000), NodeDemo.ownAccess);
      // A home-network node over plain http: the row says the secret goes unencrypted.
      expect(find.text('Added · goes to the node unencrypted (plain http), readable on that network'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Peers'), findsWidgets);
      expect(find.text('Address'), findsNothing, reason: 'the peers table is behind its tab');
      await end(tester);
    });

    testWidgets('2474: status beside the peers table, no tabs; a rotated secret is a warn row', (tester) async {
      await show(tester, const Size(2474, 1338), NodeDemo.ownAccess);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Status'), findsNothing);
      final facts = tester.getRect(find.text('Mempool').first);
      final table = tester.getRect(find.text('Address'));
      expect(table.left, greaterThan(facts.right), reason: 'side by side');
      expect(tester.getSize(find.byType(SettingsNodeScreen)).width, 2474);
      node.ownerRefuses = true;
      container.invalidate(deskOwnStatusProvider);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Refused since 14:02'), findsOneWidget);
      expect(find.text('Update…'), findsOneWidget);
      expect(find.text('Synced'), findsWidgets, reason: 'a refused secret is not a node down');
      await end(tester);
    });

    testWidgets('syncing: the fallback offer per node, remembered', (tester) async {
      await show(tester, const Size(1280, 1000), NodeDemo.ownSyncing);
      expect(find.text('Use a public node until this node is synced?'), findsOneWidget);
      await tester.tap(find.text('Wait for this node'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(settingsPrefsProvider).ownFallback[ownDemoUrl], isFalse);
      expect(find.text('Use a public node until this node is synced?'), findsNothing);
      await end(tester);
    });

    testWidgets('down with a public node standing in: Try now and Use for good', (tester) async {
      await show(tester, const Size(1280, 1000), NodeDemo.ownDown);
      expect(find.text('Own node not answering'), findsOneWidget);
      expect(find.text('Try now'), findsOneWidget);
      expect(find.text('Keep node.btlabs.uk'), findsOneWidget);
      await end(tester);
    });
  });
}
