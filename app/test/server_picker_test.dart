import 'dart:convert';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/server_picker.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Home extends HomeNotifier {
  @override
  Future<HomeData> build() async => HomeData(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(2500000),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.zero,
      spendable: BigInt.zero,
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
    transactions: const [],
  );
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() =>
      mainnetPreset.config(dataDir: '/fake', nodeUrl: 'https://node.btlabs.uk');
}

class _Listener extends ListenerNotifier {
  @override
  ListenerState build() => const ListenerState(connected: true);
}

/// status.btlabs.uk: the lists when given, else no answer (as the fake service has none).
class _Directory implements RelayDirectory, NodeDirectory, NetworkDirectory {
  _Directory({this.nodeList, this.net});

  final List<NodeStatus>? nodeList;
  final NetworkStatus? net;

  @override
  Future<NetworkStatus> network(String chain) async =>
      net ?? (throw const NetError('down'));

  @override
  Future<List<NodeStatus>> nodes(String chain) async =>
      nodeList ?? (throw const NetError('down'));

  @override
  Future<List<RelayStatus>> relays(String chain) async =>
      throw const NetError('down');
}

/// The saved choice: mainnet, its default node, a relay that is not the default.
MemorySecretStore _store() => MemorySecretStore({
  'app.network': 'mainnet',
  'app.node.mainnet': 'https://node.btlabs.uk',
  'app.relay.mainnet': 'epicbox.stackwallet.com',
});

Future<void> _pump(
  WidgetTester tester,
  ServerKind kind, {
  required MemorySecretStore store,
  _Directory? directory,
  void Function()? onSaved,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        relayDirectoryProvider.overrideWithValue(directory ?? _Directory()),
        homeProvider.overrideWith(_Home.new),
        listenerProvider.overrideWith(_Listener.new),
        walletConfigProvider.overrideWith(_Config.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ServerPickerSheet(
            kind: kind,
            afterSave: (_) => onSaved?.call(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _list = find.byType(Scrollable).first;

Finder _row(String value) => find.byKey(serverRowKey(value));

Finder _inRow(String value, String text) => find.descendant(
  of: _row(value),
  matching: find.textContaining(text, findRichText: true),
);

void main() {
  group('node sheet', () {
    testWidgets('no directory answer: built-in nodes, health unknown', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, store: _store());
      expect(find.text('Node'), findsOneWidget);
      expect(find.text('PUBLIC NODES'), findsOneWidget);
      expect(find.text('MY NODES'), findsNothing);
      expect(
        find.text('status.btlabs.uk not reachable; health unknown'),
        findsOneWidget,
      );
      for (final host in [
        'https://node.btlabs.uk',
        'https://node.epicnet.us:3413',
        'https://epic-node.iniaku.my.id',
      ]) {
        await tester.scrollUntilVisible(_row(host), 200, scrollable: _list);
        expect(_row(host), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        _row('https://node.btlabs.uk'),
        -200,
        scrollable: _list,
      );
      expect(_inRow('https://node.btlabs.uk', 'Current'), findsOneWidget);
      expect(_inRow('https://node.btlabs.uk', 'BT Labs'), findsOneWidget);
      // The current node's card, from the node's own answer.
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('2,500,000'), findsOneWidget);
      expect(find.text('3.6.0'), findsOneWidget);
      expect(find.text('Peers'), findsNothing);
    });

    testWidgets('directory health: at tip, behind, not responding', (
      tester,
    ) async {
      await _pump(
        tester,
        ServerKind.node,
        store: _store(),
        directory: _Directory(
          nodeList: const [
            NodeStatus(
              url: 'https://node.btlabs.uk',
              healthy: true,
              verified: true,
              operator: 'BT Labs',
              state: NodeHealthState.healthy,
              tipLag: 0,
              latencyMs: 24,
              nodeVersion: '4.1.1',
              peers: 12,
              uptime24h: 0.998,
            ),
            NodeStatus(
              url: 'https://node.epicnet.us:3413',
              healthy: false,
              verified: false,
              state: NodeHealthState.degraded,
              tipLag: 12,
            ),
            NodeStatus(
              url: 'https://node.epiccash.com:3413',
              healthy: false,
              verified: false,
              state: NodeHealthState.down,
            ),
          ],
          net: const NetworkStatus(
            tipHeight: 2500000,
            nodesHealthy: 5,
            nodesTotal: 6,
            tipAgeSeconds: 40,
          ),
        ),
      );
      expect(
        find.text('status.btlabs.uk not reachable; health unknown'),
        findsNothing,
      );
      expect(_inRow('https://node.btlabs.uk', 'at tip'), findsOneWidget);
      expect(_inRow('https://node.btlabs.uk', '24 ms'), findsOneWidget);
      expect(_inRow('https://node.epicnet.us:3413', '−12'), findsOneWidget);
      expect(
        _inRow('https://node.epiccash.com:3413', 'Not responding'),
        findsOneWidget,
      );
      expect(find.text('Peers'), findsOneWidget);
      expect(find.text('2,500,000 · at tip'), findsOneWidget);
      expect(
        find.text(
          'Nodes agree on 2,500,000 · 5 of 6 nodes up · last block 40 s ago',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the star adds to My nodes and survives a rebuild', (
      tester,
    ) async {
      final store = _store();
      const url = 'https://node.epicnet.us:3413';
      await _pump(tester, ServerKind.node, store: store);
      await tester.scrollUntilVisible(
        find.byKey(serverStarKey(url)),
        200,
        scrollable: _list,
      );
      expect(find.byTooltip('Add to my nodes'), findsWidgets);
      await tester.tap(find.byKey(serverStarKey(url)));
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [url]);
      await tester.scrollUntilVisible(
        find.text('MY NODES'),
        -200,
        scrollable: _list,
      );
      expect(find.text('MY NODES'), findsOneWidget);
      // A new app: the store is all that is left.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      expect(find.text('MY NODES'), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byKey(serverStarKey(url))).isSelected,
        isTrue,
      );
      // In My nodes only, not twice.
      expect(_row(url), findsOneWidget);
    });

    testWidgets('a typed address is tested, then offered', (tester) async {
      final store = _store();
      var saved = 0;
      await _pump(
        tester,
        ServerKind.node,
        store: store,
        onSaved: () => saved++,
      );
      await tester.enterText(find.byType(TextField), 'my.node.example:3413');
      await tester.pumpAndSettle();
      expect(find.text('Use https://my.node.example:3413'), findsOneWidget);
      // A host the list has is no new address.
      await tester.enterText(find.byType(TextField), 'node.btlabs.uk');
      await tester.pumpAndSettle();
      expect(find.byKey(serverUseTypedKey), findsNothing);
      await tester.enterText(find.byType(TextField), 'my.node.example:3413');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverUseTypedKey));
      await tester.pumpAndSettle();
      expect(find.text('Block 2,500,000 · v3.6.0'), findsOneWidget);
      expect(find.text('Switch to my.node.example:3413'), findsOneWidget);
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(store.values['app.node.mainnet'], 'https://my.node.example:3413');
      expect(store.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [
        'https://my.node.example:3413',
      ]);
    });

    testWidgets('a tap asks first; Switch saves the url and keeps the relay', (
      tester,
    ) async {
      final store = _store();
      var saved = 0;
      const url = 'https://node.epicnet.us:3413';
      await _pump(
        tester,
        ServerKind.node,
        store: store,
        onSaved: () => saved++,
      );
      expect(find.byKey(serverSwitchKey), findsNothing);
      // The current node asks nothing.
      await tester.tap(_row('https://node.btlabs.uk'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      await tester.scrollUntilVisible(_row(url), 200, scrollable: _list);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
      expect(
        find.text(
          'The wallet reconnects. Balances are checked again against the new node.',
        ),
        findsOneWidget,
      );
      // Cancel takes it back.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(store.values['app.node.mainnet'], url);
      expect(store.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
    });
  });

  group('epicbox sheet', () {
    testWidgets('the warning, the Default tag on the real default, Current', (
      tester,
    ) async {
      await _pump(tester, ServerKind.relay, store: _store());
      expect(find.text('Epicbox'), findsOneWidget);
      expect(
        find.text(
          'Your address includes this server. Switching changes your address; senders need the new one.',
        ),
        findsOneWidget,
      );
      expect(_inRow(defaultEpicboxHost, 'Default'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(_inRow('epicbox.stackwallet.com', 'Current'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('switching keeps the node and says the address changes', (
      tester,
    ) async {
      final store = _store();
      var saved = 0;
      await _pump(
        tester,
        ServerKind.relay,
        store: store,
        onSaved: () => saved++,
      );
      await tester.tap(_row('epicbox.epicnet.us'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to epicbox.epicnet.us'), findsOneWidget);
      expect(
        find.text('Your address changes; senders need the new one.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(store.values['app.relay.mainnet'], 'epicbox.epicnet.us');
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
    });

    testWidgets('another server typed in is offered', (tester) async {
      await _pump(tester, ServerKind.relay, store: _store());
      await tester.enterText(find.byType(TextField), 'relay.example.org:4443');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Switch to relay.example.org:4443'), findsOneWidget);
    });
  });

  test('typedNodeUrl', () {
    expect(typedNodeUrl('node.example.org'), 'https://node.example.org');
    expect(
      typedNodeUrl('HTTP://Node.example.org:3413/'),
      'http://node.example.org:3413',
    );
    expect(typedNodeUrl('btlabs'), isNull);
    expect(typedNodeUrl('ftp://node.example.org'), isNull);
    expect(typedNodeUrl('https://u@node.example.org'), isNull);
  });
}
