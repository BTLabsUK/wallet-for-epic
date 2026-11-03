// SPDX-License-Identifier: Apache-2.0
// Settings › Node and Settings › Receiving list every public node and Epicbox server: the
// built-in ones when status.btlabs.uk is down, plus any it adds. The password is a throwaway
// test value.
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/public_servers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

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
  int reads = 0;

  @override
  Future<List<RelayStatus>> relays(String chain) async {
    reads++;
    return [
      ...parseRelayStatus(_sample),
      const RelayStatus(relay: EpicboxRelay(host: 'box.example'), healthy: true, verified: false, operator: 'Box op'),
    ];
  }

  @override
  Future<List<NodeStatus>> nodes(String chain) async => [
    ...parseNodeStatus(_sample),
    const NodeStatus(url: 'https://new.example:3413', healthy: true, verified: false, operator: 'New op'),
  ];
}

List<String> get _hosts => [for (final n in hostSettings.nodeServers) Uri.parse(n.url).host];
List<String> get _boxes => [for (final s in hostSettings.epicboxServers) s.host];

void main() {
  late Directory support;

  // The built-in lists are the shipped file's, which also names the servers the sample status lists as removed.
  useShippedSettings();

  setUp(() async => support = await Directory.systemTemp.createTemp('desk-public-servers-'));
  tearDown(() => support.delete(recursive: true));

  LepicDeskWallet make(Object directory, {Set<String>? existing}) => LepicDeskWallet(
    service: core.FakeWalletService(password: _password, existingWallets: existing),
    walletDir: (chain) async => (await Directory(WalletRegistry.firstWalletDir(support.path, chain)).create(recursive: true)).path,
    secrets: MemorySecretStore(),
    filesDir: () async => support,
    relayDirectory: directory as RelayDirectory,
    nodeDirectory: directory as NodeDirectory,
    nodePoll: const Duration(hours: 1),
    nodeTimeout: const Duration(seconds: 1),
  );

  test('the monitor down: the built-in nodes and relays', () async {
    final w = make(_Down());
    addTearDown(w.dispose);
    await w.nodes();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final nodes = await w.nodes();
    expect(nodes.map((n) => n.url), deskPublicNodes.map((n) => n.url));
    expect(nodes.first.url, hostSettings.nodeServers.first.url);
    expect(nodes.map((n) => n.operator), [for (final s in hostSettings.nodeServers) s.operator]);
    final boxes = await w.epicboxes();
    expect(boxes.map((b) => b.domain), _boxes);
    // A fresh install: the new default.
    expect((await w.status()).epicbox.domain, defaultEpicboxHost);
  });

  test('the default Epicbox server is one constant: preset, first relay, status', () {
    expect(defaultEpicboxHost, hostSettings.epicboxUse);
    expect(mainnetPreset.epicboxDomain, defaultEpicboxHost);
    expect(builtInRelays.first.relay.host, defaultEpicboxHost);
    expect(deskEpicboxes.first.domain, defaultEpicboxHost);
  });

  test('a node and a relay the monitor adds show after the built-in ones', () async {
    final w = make(_Sample());
    addTearDown(w.dispose);
    final changed = w.changes().first;
    expect(await w.nodes(), hasLength(deskPublicNodes.length));
    await changed.timeout(const Duration(seconds: 2));
    final nodes = await w.nodes();
    expect(nodes.map((n) => n.url), containsAllInOrder([...deskPublicNodes.map((n) => n.url), 'https://new.example:3413']));
    expect(nodes.first.url, hostSettings.nodeServers.first.url);
    expect(nodes.firstWhere((n) => n.url == 'https://new.example:3413').operator, 'New op');
    final boxes = await w.epicboxes();
    expect(boxes.map((b) => b.domain), containsAllInOrder([..._boxes, 'box.example']));
    expect(boxes.firstWhere((b) => b.domain == 'box.example').operator, 'Box op');
    expect(hostSettings.nodeUrls, isNot(contains('https://new.example:3413')), reason: 'never into the list');
    expect(boxes.first.health, ServiceHealth.ok);
  });

  test('Tor still connecting at start: the built-in lists, the directory read once Tor is up', () async {
    final dir = _Sample();
    final w = make(dir);
    addTearDown(w.dispose);
    TorNet.waitForTor();
    addTearDown(TorNet.useDirect);
    expect((await w.nodes()).map((n) => n.url), deskPublicNodes.map((n) => n.url));
    expect((await w.epicboxes()).map((b) => b.domain), _boxes);
    expect(dir.reads, 0, reason: 'nothing asked while Tor connects');
    TorNet.useDirect();
    expect((await w.epicboxes()).map((b) => b.domain), containsAllInOrder([..._boxes, 'box.example']));
    expect(dir.reads, 1);
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

  testWidgets('the node picker lists all the public nodes, offline', (tester) async {
    final w = make(_Down());
    await pumpScreen(tester, const SettingsNodeScreen(arg: NodeShot.comboOpen), w);
    expect(tester.takeException(), isNull);
    for (final h in _hosts) {
      // The §18 row shows the host without its port; the port is in the row's tooltip.
      expect(find.textContaining(h.replaceFirst(RegExp(r':\d+$'), ''), findRichText: true), findsWidgets, reason: h);
    }
    expect(find.textContaining(hostSettings.nodeServers.first.operator!, findRichText: true), findsWidgets);
    await done(tester, w);
  });

  testWidgets('the Epicbox picker lists all the public servers, offline', (tester) async {
    final w = make(_Down());
    await pumpScreen(tester, const SettingsReceivingScreen(arg: ReceivingShot.comboOpen), w);
    expect(tester.takeException(), isNull);
    for (final b in _boxes) {
      expect(find.textContaining(b, findRichText: true), findsWidgets, reason: b);
    }
    await done(tester, w);
  });
}
