// SPDX-License-Identifier: Apache-2.0
// Settings › Node › Privacy › Use status.btlabs.uk on the desktop: off, the wallet asks the site
// nothing and lists the built-in nodes and Epicbox servers; turning it off drops what the site
// gave without a restart. The password is a throwaway
// test value.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_privacy.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

final String _sample = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

/// The sample with one node only the site knows.
String _withExtraNode() {
  const extra = '{"kind": "node", "endpoint": "https://new.example:3413", "state": "healthy", "operator": "New op"}';
  return _sample.replaceFirst('"nodes":[', '"nodes":[$extra,');
}

void main() {
  late Directory support;
  late List<String> hosts;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-status-site-');
    hosts = [];
  });
  tearDown(() async {
    statusSite.on = true;
    await support.delete(recursive: true);
  });

  LepicDeskWallet make() {
    final directory = HttpRelayDirectory(
      get: (url, {timeout = defaultHttpTimeout}) async {
        hosts.add(url.host);
        return HttpReply(200, _withExtraNode());
      },
    );
    return LepicDeskWallet(
      service: core.FakeWalletService(password: _password),
      walletDir: (chain) async => (await Directory(WalletRegistry.firstWalletDir(support.path, chain)).create(recursive: true)).path,
      secrets: MemorySecretStore(),
      filesDir: () async => support,
      relayDirectory: directory,
      nodeDirectory: directory,
      nodePoll: const Duration(hours: 1),
      nodeTimeout: const Duration(seconds: 1),
    );
  }

  test('the setting is on by default and saved', () {
    expect(const DeskSettings().useStatusSite, isTrue);
    expect(deskSettingsFromJson(const {}).useStatusSite, isTrue);
    expect(deskSettingsFromJson(const {'useStatusSite': 'x'}).useStatusSite, isTrue);
    final off = deskSettingsFromJson(deskSettingsToJson(const DeskSettings(useStatusSite: false)));
    expect(off.useStatusSite, isFalse);
  });

  test('off: no request to the site, the built-in nodes and servers', () async {
    statusSite.on = false;
    final w = make();
    addTearDown(w.dispose);
    await w.nodes();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await w.nodes()).map((n) => n.url), deskPublicNodes.map((n) => n.url));
    expect((await w.epicboxes()).map((b) => b.domain), deskEpicboxes.map((b) => b.domain));
    expect(hosts, isEmpty);
  });

  test('turned off at runtime: what the site gave is dropped at once', () async {
    final w = make();
    addTearDown(w.dispose);
    final listed = w.changes().first;
    await w.nodes();
    await listed.timeout(const Duration(seconds: 2));
    expect((await w.nodes()).map((n) => n.url), contains('https://new.example:3413'));
    expect((await w.epicboxes()).first.health, ServiceHealth.ok);
    expect(hosts, hasLength(1));

    final dropped = w.changes().first;
    statusSite.on = false;
    await dropped.timeout(const Duration(seconds: 2));
    expect((await w.nodes()).map((n) => n.url), deskPublicNodes.map((n) => n.url));
    expect((await w.epicboxes()).map((b) => b.health), everyElement(ServiceHealth.checking));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(hosts, hasLength(1));

    // On again: read afresh, past both caches.
    final back = w.changes().first;
    statusSite.on = true;
    await back.timeout(const Duration(seconds: 2));
    await w.nodes();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await w.nodes()).map((n) => n.url), contains('https://new.example:3413'));
    expect(hosts, hasLength(2));
  });

  testWidgets('Settings › Privacy shows the status site switch; turning it off applies at once', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final w = make();
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(w)]);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await w.createWallet(name: 'Main', password: _password);
      expect(await w.unlock(_password), isTrue);
      await container.read(deskProvider.notifier).refresh();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsPrivacyScreen())),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Status site'), findsOneWidget);
    expect(find.text('Use status.btlabs.uk'), findsOneWidget);
    // Label only; the sentence is the info icon's tooltip.
    expect(find.byTooltip('Shows which nodes and Epicbox servers are online. Only downloads a public list; nothing from the wallet is sent.'), findsOneWidget);
    expect(find.textContaining('Server health'), findsNothing);

    final toggle = find.descendant(of: find.byType(PrivacyGroup), matching: find.byType(ESwitch));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(deskProvider).settings.useStatusSite, isFalse);
    expect(statusSite.on, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(w.dispose);
    await tester.pump(const Duration(seconds: 10));
  });
}
