// SPDX-License-Identifier: Apache-2.0
// Switch server in the Shallow status popovers: the level has no server settings, so the
// Network and Epicbox popovers list the other servers of the list by address with their health;
// a click on a healthy one moves the wallet (useEpicbox with the "Now on" notice, or useNode),
// one not answering cannot be picked. Deep end keeps its settings button and no list.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/relay_offer.dart';
import 'package:epic_wallet/src/desktop/app/server_switch.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/server_lists.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

/// The mock with the last server of each list not answering, recording the moves.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> boxes = [];
  final List<String> nodesUsed = [];

  @override
  Future<List<EpicboxServer>> epicboxes() async {
    final all = await super.epicboxes();
    return [
      for (var i = 0; i < all.length; i++)
        i == all.length - 1 ? EpicboxServer(domain: all[i].domain, port: all[i].port, health: ServiceHealth.down) : all[i],
    ];
  }

  @override
  Future<void> useEpicbox(String domain) {
    boxes.add(domain);
    return super.useEpicbox(domain);
  }

  @override
  Future<void> useNode(String url) {
    nodesUsed.add(url);
    return super.useNode(url);
  }
}

Future<(ProviderContainer, _Wallet)> _pump(WidgetTester tester, WalletLevel level) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = _Wallet();
  final container = ProviderContainer(
    overrides: [
      deskStartProvider.overrideWithValue(DeskRoute.overview),
      deskApiProvider.overrideWithValue(wallet),
      deskLevelProvider.overrideWithValue(level),
      deskLevelUiProvider.overrideWithValue(DeskLevelFeatures.of(level, prefs: const AdvancedPrefs(), wallets: 1)),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(seconds: 1));
  return (container, wallet);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('bar-status-$id')));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byKey(ValueKey('status-pop-$id')), findsOneWidget);
  expect(find.text('For support'), findsNothing);
  expect(find.text('Copy details'), findsNothing);
  await tester.tap(find.byKey(ValueKey('status-switch-$id')));
  // The list unfolds over a few frames.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

EInkWell _row(WidgetTester tester, String id, String value) => tester.widget<EInkWell>(find.byKey(ValueKey('status-switch-$id-$value')));

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('Shallow Epicbox: other servers by address, healthy first; a healthy one moves and opens Now on', (tester) async {
    final (container, wallet) = await _pump(tester, WalletLevel.justSendReceive);
    final st = container.read(deskProvider);
    final servers = deskEpicboxSwitchServers(st, container.read(deskServerListProvider(ServerKind.relay)));
    expect(servers, isNotEmpty);
    expect(servers.any((s) => s.value == st.status!.epicbox.domain), isFalse, reason: 'not the server in use');
    expect(servers.first.health, RelayHealth.healthy);
    expect(servers.last.health, RelayHealth.down);

    await _open(tester, 'epicbox');
    for (final s in servers) {
      expect(find.descendant(of: find.byKey(ValueKey('status-switch-epicbox-${s.value}')), matching: find.text(s.name)), findsOneWidget);
    }
    expect(find.text(_l.serverHealthy), findsWidgets);
    expect(find.text(_l.deskNodeNotAnswering), findsOneWidget);
    expect(find.text(_l.slSwitchBody), findsOneWidget, reason: 'said plainly where the server is chosen');
    expect(_row(tester, 'epicbox', servers.last.value).onTap, isNull, reason: 'a server not answering cannot be picked');

    final pick = servers.first;
    await tester.tap(find.byKey(ValueKey('status-switch-epicbox-${pick.value}')));
    await _settle(tester);
    expect(wallet.boxes, [pick.value]);
    final moved = container.read(deskRelayMovedProvider);
    expect(moved, isNotNull);
    expect(moved!.address, endsWith('@${pick.value}'));
    // A toast on Overview says it once (item 16).
    expect(find.text('Now on ${pick.name}. Your new address is ready.'), findsOneWidget);
    expect(container.read(deskRelayMovedNoticeProvider), isFalse);
    await _end(tester);
  });

  testWidgets('Shallow Network: other nodes by address; a healthy one is used, one not answering cannot be picked', (tester) async {
    final (container, wallet) = await _pump(tester, WalletLevel.justSendReceive);
    final servers = deskNodeSwitchServers(container.read(deskProvider), container.read(deskServerListProvider(ServerKind.node)));
    expect(servers, isNotEmpty);
    final healthy = servers.firstWhere((s) => s.health == RelayHealth.healthy);
    expect(servers.first, healthy);

    await _open(tester, 'node');
    expect(find.descendant(of: find.byKey(ValueKey('status-switch-node-${healthy.value}')), matching: find.text(healthy.name)), findsOneWidget);
    expect(healthy.name, isNot(contains('://')), reason: 'the address, no scheme');
    expect(find.text('Switching gives you a new Epicbox address.'), findsNothing, reason: 'a node move keeps the address');
    for (final s in servers.where((s) => s.health == RelayHealth.down)) {
      expect(_row(tester, 'node', s.value).onTap, isNull);
    }
    await tester.tap(find.byKey(ValueKey('status-switch-node-${healthy.value}')));
    await _settle(tester);
    expect(wallet.nodesUsed, [healthy.value]);
    await _end(tester);
  });

  testWidgets('Deep end: no Switch server, the settings button stays', (tester) async {
    await _pump(tester, WalletLevel.everything);
    await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('status-switch-epicbox')), findsNothing);
    expect(find.byKey(const ValueKey('status-open-epicbox')), findsOneWidget);
    expect(find.byType(EButton), findsWidgets);
    await _end(tester);
  });
}
