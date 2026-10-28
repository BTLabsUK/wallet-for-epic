// SPDX-License-Identifier: Apache-2.0
// Settings › Node and Settings › Receiving list every public node and Epicbox server: the
// built-in ones when status.btlabs.uk is down, plus any it adds. The password is a throwaway
// test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/public_servers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

final String _sample = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

/// The monitor down: every read fails.
class _Down implements RelayDirectory, NodeDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => throw const NetError('offline');

  @override
  Future<List<NodeStatus>> nodes(String chain) async => throw const NetError('offline');
}

/// The sample, plus one node and one relay the app does not know.
class _Sample implements RelayDirectory, NodeDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => [
    ...parseRelayStatus(_sample),
    const RelayStatus(relay: EpicboxRelay(host: 'box.example'), healthy: true, verified: false, operator: 'Box op'),
  ];

  @override
  Future<List<NodeStatus>> nodes(String chain) async => [
    ...parseNodeStatus(_sample),
    const NodeStatus(url: 'https://new.example:3413', healthy: true, verified: false, operator: 'New op'),
  ];
}

const _hosts = ['node.btlabs.uk', 'node.epicnet.us:3413', 'node.epiccash.com:3413', 'epic.stackwallet.com:3413', 'epic-node.iniaku.my.id'];
const _boxes = ['epicbox.epiccash.com', 'epicbox.stackwallet.com', 'epicbox.epicnet.us', 'epicbox.iniaku.my.id'];

void main() {
  late Directory support;

  setUp(() async => support = await Directory.systemTemp.createTemp('desk-public-servers-'));
  tearDown(() => support.delete(recursive: true));

  LepicDeskWallet make(Object directory, {Set<String>? existing}) => LepicDeskWallet(
    service: core.FakeWalletService(password: _password, existingWallets: existing),
    walletDir: (chain) async => (await Directory('${support.path}/wallets/${chain.name}').create(recursive: true)).path,
    secrets: MemorySecretStore(),
    filesDir: () async => support,
    relayDirectory: directory as RelayDirectory,
    nodeDirectory: directory as NodeDirectory,
    nodePoll: const Duration(hours: 1),
    nodeTimeout: const Duration(seconds: 1),
  );

  test('the monitor down: the five built-in nodes and four relays', () async {
    final w = make(_Down());
    addTearDown(w.dispose);
    await w.nodes();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final nodes = await w.nodes();
    expect(nodes.map((n) => n.url), deskPublicNodes.map((n) => n.url));
    expect(nodes.first.url, 'https://node.btlabs.uk');
    expect(nodes.map((n) => n.operator), ['BT Labs', 'EpicNet', 'Epic Cash', 'Cypher Stack', 'Iniaku pool']);
    final boxes = await w.epicboxes();
    expect(boxes.map((b) => b.domain), _boxes);
    // A fresh install: the new default.
    expect((await w.status()).epicbox.domain, defaultEpicboxHost);
  });

  test('an install with a wallet and no saved server keeps the server 0.1.0 used', () async {
    final w = make(_Down(), existing: {'${support.path}/wallets/mainnet'});
    addTearDown(w.dispose);
    expect((await w.status()).epicbox.domain, 'epicbox.stackwallet.com');
  });

  test('the default Epicbox server is one constant: preset, first relay, status', () {
    expect(defaultEpicboxHost, 'epicbox.epiccash.com');
    expect(mainnetPreset.epicboxDomain, defaultEpicboxHost);
    expect(builtInRelays.first.relay.host, defaultEpicboxHost);
    expect(deskEpicboxes.first.domain, defaultEpicboxHost);
  });

  test('a node and a relay the monitor adds show after the built-in ones', () async {
    final w = make(_Sample());
    addTearDown(w.dispose);
    final changed = w.changes().first;
    expect(await w.nodes(), hasLength(5));
    await changed.timeout(const Duration(seconds: 2));
    final nodes = await w.nodes();
    expect(nodes, hasLength(6));
    expect(nodes.first.url, 'https://node.btlabs.uk');
    expect(nodes.last.url, 'https://new.example:3413');
    expect(nodes.last.operator, 'New op');
    final boxes = await w.epicboxes();
    expect(boxes.map((b) => b.domain), [..._boxes, 'box.example']);
    expect(boxes.last.operator, 'Box op');
    expect(boxes.first.health, ServiceHealth.ok);
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen, LepicDeskWallet w) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(w)]);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await w.createWallet(name: 'Main', password: _password);
      expect(await w.unlock(_password), isTrue);
      await container.read(deskProvider.notifier).refresh();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> done(WidgetTester tester, LepicDeskWallet w) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(w.dispose);
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('the node picker lists all five public nodes, offline', (tester) async {
    final w = make(_Down());
    await pumpScreen(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen), w);
    expect(tester.takeException(), isNull);
    for (final h in _hosts) {
      // The §18 row shows the host without its port; the port is in the row's tooltip.
      expect(find.textContaining(h.replaceFirst(RegExp(r':\d+$'), ''), findRichText: true), findsWidgets, reason: h);
    }
    expect(find.textContaining('Iniaku pool', findRichText: true), findsWidgets);
    await done(tester, w);
  });

  testWidgets('the Epicbox picker lists all four public servers, offline', (tester) async {
    final w = make(_Down());
    await pumpScreen(tester, const SettingsReceivingScreen(arg: ReceivingDemo.comboOpen), w);
    expect(tester.takeException(), isNull);
    for (final b in _boxes) {
      expect(find.textContaining(b, findRichText: true), findsWidgets, reason: b);
    }
    await done(tester, w);
  });
}
