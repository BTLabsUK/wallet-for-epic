import 'dart:convert';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/server_switch.dart';
import 'package:epic_wallet/src/ui/server_picker.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
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

/// The providers every pump replaces (Riverpod exports no name for the list's type).
// ignore: strict_top_level_inference
_overrides(MemorySecretStore store, _Directory? directory) => [
  secretStoreProvider.overrideWithValue(store),
  walletServiceProvider.overrideWithValue(FakeWalletService()),
  relayDirectoryProvider.overrideWithValue(directory ?? _Directory()),
  homeProvider.overrideWith(_Home.new),
  listenerProvider.overrideWith(_Listener.new),
  walletConfigProvider.overrideWith(_Config.new),
  // The current node's card shows the tip the open wallet asks through its Tor; these
  // tests open no wallet, so the tip stands in for its answer.
  nodeTipProvider.overrideWith(
    (ref) async => NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0'),
  ),
];

Future<void> _pump(
  WidgetTester tester,
  ServerKind kind, {
  required MemorySecretStore store,
  _Directory? directory,
  void Function()? onSaved,
  Future<bool> Function(WidgetRef ref, {required String nodeUrl, required EpicboxRelay relay})?
  liveSwitch,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _overrides(store, directory),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ServerPickerSheet(
            kind: kind,
            afterSave: (_) => onSaved?.call(),
            liveSwitch:
                liveSwitch ??
                (ref, {required nodeUrl, required relay}) async {
                  // No wallet open in these tests: save and hand over, as the real one does.
                  await switchServersLive(ref, nodeUrl: nodeUrl, relay: relay);
                  return false;
                },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _list = find.byType(Scrollable).first;

/// Opens a My-list row's popup (the down arrow or the bin) and taps its one item.
Future<void> _menu(WidgetTester tester, String value) async {
  await tester.ensureVisible(find.byKey(serverMenuKey(value)));
  await tester.tap(find.byKey(serverMenuKey(value)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(serverMenuItemKey(value)));
  await tester.pumpAndSettle();
}

/// Whether a row's popup button is there and enabled.
bool _menuEnabled(WidgetTester tester, String value) =>
    tester.widget<PopupMenuButton<bool>>(find.byKey(serverMenuKey(value))).enabled;

/// Opens the real sheet ([showNodePicker] or [showEpicboxPicker]) over a screen on a phone of
/// [size] dp with a 24 dp status bar and a [bottom] dp gesture or navigation bar.
Future<void> _pumpPhone(
  WidgetTester tester,
  ServerKind kind, {
  required Size size,
  required double bottom,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(top: 24 * 3, bottom: bottom * 3);
  tester.view.viewPadding = FakeViewPadding(top: 24 * 3, bottom: bottom * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _overrides(_store(), null),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => kind == ServerKind.node
                    ? showNodePicker(context)
                    : showEpicboxPicker(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// A keyboard [height] dp tall opens: Android folds the bar into its inset.
Future<void> _keyboard(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height * 3);
  tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 0);
  await tester.pumpAndSettle();
}

/// The sheet's own list, under the screen's.
final Finder _sheetList = find
    .descendant(of: find.byType(ServerPickerSheet), matching: find.byType(Scrollable))
    .first;

/// The Switch button is whole, full width, at least 48 dp tall, above the bottom [inset] (the
/// bar or the keyboard), and the first thing under a tap at its centre; Cancel is above the
/// inset too.
void _expectReachable(WidgetTester tester, {required double inset}) {
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final limit = screen.height - inset;
  final button = find.byKey(serverSwitchKey);
  final rect = tester.getRect(button);
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(rect.width, greaterThanOrEqualTo(screen.width - 40));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(limit));
  expect(tester.getRect(find.text('Cancel')).bottom, lessThanOrEqualTo(limit));
  final hit = tester.hitTestOnBinding(rect.center);
  expect(hit.path.map((e) => e.target), contains(tester.renderObject(button)));
}

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

    testWidgets('a node in My nodes survives a rebuild with a down arrow; public rows have none', (
      tester,
    ) async {
      const url = 'https://node.epicnet.us:3413';
      final store = _store()..values['app.myNodes.mainnet'] = jsonEncode([url]);
      await _pump(tester, ServerKind.node, store: store);
      expect(find.text('MY NODES'), findsOneWidget);
      expect(find.byKey(serverMenuKey(url)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(serverMenuKey(url)),
          matching: find.byIcon(Icons.arrow_downward),
        ),
        findsOneWidget,
      );
      // In My nodes only, not twice; the public rows have no button, and nothing is a star.
      expect(_row(url), findsOneWidget);
      expect(find.byKey(serverMenuKey('https://node.btlabs.uk')), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
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

    testWidgets('with a wallet open the switch is live: the sheet closes, no relaunch', (
      tester,
    ) async {
      final store = _store();
      var saved = 0;
      var live = 0;
      const url = 'https://node.epicnet.us:3413';
      await _pump(
        tester,
        ServerKind.node,
        store: store,
        onSaved: () => saved++,
        liveSwitch: (ref, {required nodeUrl, required relay}) async {
          live++;
          expect(nodeUrl, url);
          expect(relay.label, 'epicbox.stackwallet.com');
          return true;
        },
      );
      await tester.scrollUntilVisible(_row(url), 200, scrollable: _list);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      // Not pumpAndSettle: the success notice's timer runs after the switch.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(live, 1);
      expect(saved, 0);
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
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

    testWidgets('the current row is neutral, never the accent; its check green while up', (
      tester,
    ) async {
      await _pump(tester, ServerKind.relay, store: _store());
      final row = find.byKey(serverRowKey('epicbox.stackwallet.com'));
      final t = tester.element(row).tokens;
      final ink = tester.widget<Ink>(
        find.descendant(of: row, matching: find.byType(Ink)),
      );
      final box = ink.decoration! as BoxDecoration;
      expect(box.color, t.selected);
      expect(box.border!.top.color, t.selectedLine);
      expect(box.color, isNot(t.accentSoft));
      // No health answer: the check is dim, not green and not gold; Current in the text colour.
      final check = tester.widget<Icon>(
        find.descendant(of: row, matching: find.byIcon(Icons.check)),
      );
      expect(check.color, t.dim);
      final rich = tester.widget<RichText>(
        _inRow('epicbox.stackwallet.com', 'Current'),
      );
      TextStyle? currentStyle;
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text == 'Current') {
          currentStyle = span.style;
          return false;
        }
        return true;
      });
      expect(currentStyle?.color, t.text);
      expect(currentStyle?.fontWeight, FontWeight.w600);
      // Another row has no fill and no check.
      final other = find.byKey(serverRowKey(defaultEpicboxHost));
      final otherBox =
          tester.widget<Ink>(find.descendant(of: other, matching: find.byType(Ink))).decoration!
              as BoxDecoration;
      expect(otherBox.color, isNull);
      expect(find.descendant(of: other, matching: find.byIcon(Icons.check)), findsNothing);
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

  group('my servers', () {
    testWidgets('a picked relay is remembered after the switch, once', (
      tester,
    ) async {
      final store = _store();
      await _pump(tester, ServerKind.relay, store: store);
      expect(find.text('MY SERVERS'), findsNothing);
      await tester.tap(_row('epicbox.epicnet.us'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), [
        'epicbox.epicnet.us',
      ]);
      // A new app: in My servers, not again under Public servers.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.relay, store: store);
      expect(find.text('MY SERVERS'), findsOneWidget);
      expect(_row('epicbox.epicnet.us'), findsOneWidget);
      expect(
        tester.getTopLeft(_row('epicbox.epicnet.us')).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC SERVERS')).dy),
      );
    });

    testWidgets('a typed relay is remembered after the switch', (
      tester,
    ) async {
      final store = _store();
      await _pump(tester, ServerKind.relay, store: store);
      await tester.enterText(find.byType(TextField), 'relay.example.org:4443');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.relay.mainnet'], 'relay.example.org:4443');
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), [
        'relay.example.org:4443',
      ]);
    });

    testWidgets('the bin deletes a typed-in relay from a popup, no dialog', (
      tester,
    ) async {
      final store = _store()
        ..values['app.myRelays.mainnet'] = jsonEncode([
          'relay.example.org',
          'epicbox.stackwallet.com',
        ]);
      await _pump(tester, ServerKind.relay, store: store);
      final bin = find.byKey(serverMenuKey('relay.example.org'));
      expect(tester.getSize(bin).height, greaterThanOrEqualTo(48));
      expect(find.byTooltip('Delete'), findsOneWidget);
      await tester.tap(bin);
      await tester.pumpAndSettle();
      expect(find.byKey(serverMenuItemKey('relay.example.org')), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<bool>, 'Delete'), findsOneWidget);
      // Dismissing the popup keeps the relay.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), hasLength(2));
      await _menu(tester, 'relay.example.org');
      expect(find.byType(AlertDialog), findsNothing);
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), [
        'epicbox.stackwallet.com',
      ]);
      expect(_row('relay.example.org'), findsNothing);
      // No relay switch was asked for.
      expect(find.byKey(serverSwitchKey), findsNothing);
    });

    testWidgets('the push relay is listed with its bell and can be picked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, ServerKind.relay, store: _store());
      const push = 'flooepicbox.btlabs.uk';
      await tester.scrollUntilVisible(_row(push), 200, scrollable: _list);
      expect(
        find.descendant(
          of: _row(push),
          matching: find.byIcon(Icons.notifications_outlined),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(
        tester.getSemantics(_row(push)).label,
        contains('Supports notifications'),
      );
      await tester.tap(_row(push));
      await tester.pumpAndSettle();
      expect(find.text('Switch to $push'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nodes: a picked node is remembered; the bin deletes a typed-in one', (
      tester,
    ) async {
      final store = _store();
      const url = 'https://node.epicnet.us:3413';
      await _pump(tester, ServerKind.node, store: store);
      await tester.scrollUntilVisible(_row(url), 200, scrollable: _list);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [url]);
      // Now on that node, with a typed-in node in the list as well.
      store.values['app.myNodes.mainnet'] = jsonEncode([
        url,
        'https://my.node.example:3413',
      ]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      await _menu(tester, 'https://my.node.example:3413');
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [url]);
    });

    test('My relays keeps six, dropping the oldest but never the one in use', () async {
      final store = MemorySecretStore({});
      final container = ProviderContainer(
        overrides: [secretStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final mine = container.read(myRelaysProvider(Chain.mainnet).notifier);
      for (var i = 0; i < 6; i++) {
        await mine.add('r$i.example.org');
      }
      await mine.add('r6.example.org', inUse: 'r0.example.org');
      expect(container.read(myRelaysProvider(Chain.mainnet)).value, [
        'r0.example.org',
        'r2.example.org',
        'r3.example.org',
        'r4.example.org',
        'r5.example.org',
        'r6.example.org',
      ]);
      // Already there: nothing moves.
      await mine.add('r3.example.org:443');
      expect(container.read(myRelaysProvider(Chain.mainnet)).value, hasLength(6));
    });
  });

  // The model of My nodes and My relays: at most one public server, any number of typed-in
  // ones. The node in use is btlabs and the relay in use stackwallet (see [_store]).
  group('my list holds one public server', () {
    const pubA = 'https://node.epicnet.us:3413';
    const pubB = 'https://node.epiccash.com:3413';
    const custom = 'https://my.node.example:3413';
    const custom2 = 'https://other.node.example';
    const relA = 'epicbox.epicnet.us';
    const relB = 'epicbox.iniaku.my.id';
    const relCustom = 'relay.example.org';
    const relCustom2 = 'relay.other.org:4443';

    // The whole list in view, so every row is built.
    Future<void> tall(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 7000);
      await tester.pumpAndSettle();
    }

    MemorySecretStore seeded(String key, List<String> list) =>
        _store()..values[key] = jsonEncode(list);

    List<Object?> saved(MemorySecretStore store, String key) =>
        jsonDecode(store.values[key]!) as List<Object?>;

    // Rule 1: one public server at most, however many typed-in ones.
    testWidgets('rule 1: nodes — an older list with two public ones shows one', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom, pubB, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      // Neither public node is in use: the last added stays, with both typed-in ones.
      expect(find.byKey(serverMenuKey(pubA)), findsNothing);
      expect(find.byKey(serverMenuKey(pubB)), findsOneWidget);
      expect(find.byKey(serverMenuKey(custom)), findsOneWidget);
      expect(find.byKey(serverMenuKey(custom2)), findsOneWidget);
      expect(
        tester.getTopLeft(_row(pubB)).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
      expect(
        tester.getTopLeft(_row(pubA)).dy,
        greaterThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
    });

    testWidgets('rule 1: relays — an older list with two public ones shows one', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom, relB]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(find.byKey(serverMenuKey(relA)), findsNothing);
      expect(find.byKey(serverMenuKey(relB)), findsOneWidget);
      expect(find.byKey(serverMenuKey(relCustom)), findsOneWidget);
      expect(
        tester.getTopLeft(_row(relA)).dy,
        greaterThan(tester.getTopLeft(find.text('PUBLIC SERVERS')).dy),
      );
    });

    testWidgets('rule 1: the public node in use is the one that stays', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, pubB])
        ..values['app.node.mainnet'] = pubA;
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(find.byKey(serverMenuKey(pubA)), findsOneWidget);
      expect(find.byKey(serverMenuKey(pubB)), findsNothing);
    });

    // Rule 2: a switch to a public server moves it into the list and the old one out.
    testWidgets('rule 2: nodes — switching to a public node replaces the public one', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubB, custom]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      await tester.tap(_row(pubA));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myNodes.mainnet'), [custom, pubA]);
      expect(store.values['app.node.mainnet'], pubA);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(find.byKey(serverMenuKey(pubA)), findsOneWidget);
      expect(find.byKey(serverMenuKey(pubB)), findsNothing);
      expect(
        tester.getTopLeft(_row(pubB)).dy,
        greaterThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
    });

    testWidgets('rule 2: a typed-in node leaves the public one in the list', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubB]);
      await _pump(tester, ServerKind.node, store: store);
      await tester.enterText(find.byType(TextField), 'my.node.example:3413');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverUseTypedKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myNodes.mainnet'), [pubB, custom]);
    });

    testWidgets('rule 2: relays — switching to a public relay replaces the public one', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relB, relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      await tester.tap(_row(relA));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myRelays.mainnet'), [relCustom, relA]);
      expect(store.values['app.relay.mainnet'], relA);
    });

    // Rules 3 and 5: the down arrow sends a public server back to the public list, the bin
    // deletes a typed-in one; each is a popup, with no dialog after it.
    testWidgets('rules 3 and 5: nodes — the down arrow on a public node, then the bin on a typed-in one', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(find.byTooltip('Remove from my list'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      await tester.tap(find.byKey(serverMenuKey(pubA)));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PopupMenuItem<bool>, 'Remove from my list'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(serverMenuItemKey(pubA)));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(saved(store, 'app.myNodes.mainnet'), [custom]);
      // Back in the public list, without a button.
      expect(find.byKey(serverMenuKey(pubA)), findsNothing);
      expect(
        tester.getTopLeft(_row(pubA)).dy,
        greaterThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
      await tester.tap(find.byKey(serverMenuKey(custom)));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PopupMenuItem<bool>, 'Delete'), findsOneWidget);
      await tester.tap(find.byKey(serverMenuItemKey(custom)));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myNodes.mainnet'), isEmpty);
      expect(_row(custom), findsNothing);
      // The public node was not switched to by any of it.
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
      expect(find.byKey(serverSwitchKey), findsNothing);
    });

    testWidgets('rules 3 and 5: relays — the down arrow on a public relay, then the bin on a typed-in one', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      await _menu(tester, relA);
      expect(saved(store, 'app.myRelays.mainnet'), [relCustom]);
      expect(
        tester.getTopLeft(_row(relA)).dy,
        greaterThan(tester.getTopLeft(find.text('PUBLIC SERVERS')).dy),
      );
      await _menu(tester, relCustom);
      expect(saved(store, 'app.myRelays.mainnet'), isEmpty);
      expect(_row(relCustom), findsNothing);
    });

    // The server in use stays in the list: its arrow or bin is disabled, with the reason as
    // its tooltip, and nothing moves.
    testWidgets('in use: the public node in use has a disabled down arrow', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom])
        ..values['app.node.mainnet'] = pubA;
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(_menuEnabled(tester, pubA), isFalse);
      expect(find.byTooltip('In use. Pick another server first.'), findsOneWidget);
      expect(_menuEnabled(tester, custom), isTrue);
      await tester.tap(find.byKey(serverMenuKey(pubA)), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(serverMenuItemKey(pubA)), findsNothing);
      expect(saved(store, 'app.myNodes.mainnet'), [pubA, custom]);
      expect(_inRow(pubA, 'Current'), findsOneWidget);
    });

    testWidgets('in use: a typed-in node in use has a disabled bin', (tester) async {
      final store = seeded('app.myNodes.mainnet', [custom, pubA])
        ..values['app.node.mainnet'] = custom;
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(_menuEnabled(tester, custom), isFalse);
      expect(
        find.descendant(
          of: find.byKey(serverMenuKey(custom)),
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
      expect(_menuEnabled(tester, pubA), isTrue);
      expect(saved(store, 'app.myNodes.mainnet'), [custom, pubA]);
    });

    testWidgets('in use: the relay in use, public or typed in, has the arrow or bin disabled', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [
        relCustom,
        'epicbox.stackwallet.com',
      ]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(_menuEnabled(tester, 'epicbox.stackwallet.com'), isFalse);
      expect(_menuEnabled(tester, relCustom), isTrue);
      expect(find.byTooltip('In use. Pick another server first.'), findsOneWidget);
      // A typed-in relay in use: the bin, disabled.
      store.values['app.relay.mainnet'] = relCustom;
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(_menuEnabled(tester, relCustom), isFalse);
      expect(_menuEnabled(tester, 'epicbox.stackwallet.com'), isTrue);
      expect(saved(store, 'app.myRelays.mainnet'), [relCustom, 'epicbox.stackwallet.com']);
    });

    // A tap on a My-list entry, public or typed in, selects it: the check moves to it and
    // the strip offers the switch.
    testWidgets('a tap on a My-list entry moves the check to it, and Switch makes it current', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      Finder check(String url) =>
          find.descendant(of: _row(url), matching: find.byIcon(Icons.check));
      expect(check('https://node.btlabs.uk'), findsOneWidget);
      for (final url in [custom, pubA]) {
        await tester.tap(_row(url));
        await tester.pumpAndSettle();
        expect(check(url), findsOneWidget);
        expect(check('https://node.btlabs.uk'), findsNothing);
        expect(find.text('Switch to ${url.replaceFirst('https://', '')}'), findsOneWidget);
      }
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.node.mainnet'], pubA);
      // The list is as it was: the public entry stays, the typed-in one too.
      expect(saved(store, 'app.myNodes.mainnet'), [pubA, custom]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(check(pubA), findsOneWidget);
      expect(check(custom), findsNothing);
      expect(_menuEnabled(tester, pubA), isFalse);
      expect(_menuEnabled(tester, custom), isTrue);
    });

    testWidgets('relays — a tap on a typed-in My-list entry moves the check to it', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relCustom, 'epicbox.stackwallet.com']);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      Finder check(String v) =>
          find.descendant(of: _row(v), matching: find.byIcon(Icons.check));
      expect(check('epicbox.stackwallet.com'), findsOneWidget);
      await tester.tap(_row(relCustom));
      await tester.pumpAndSettle();
      expect(check(relCustom), findsOneWidget);
      expect(check('epicbox.stackwallet.com'), findsNothing);
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.relay.mainnet'], relCustom);
      expect(saved(store, 'app.myRelays.mainnet'), [relCustom, 'epicbox.stackwallet.com']);
    });

    // A tap on a Public-list entry, then Switch: it moves up into the list as the current
    // one, with the check, and the public entry the list had goes back to Public.
    testWidgets('a switch from the Public list swaps it with the public entry in My list', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubB, custom])
        ..values['app.node.mainnet'] = pubB;
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      final publicHead = tester.getTopLeft(find.text('PUBLIC NODES')).dy;
      expect(tester.getTopLeft(_row(pubB)).dy, lessThan(publicHead));
      expect(tester.getTopLeft(_row(pubA)).dy, greaterThan(publicHead));
      await tester.tap(_row(pubA));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.node.mainnet'], pubA);
      expect(saved(store, 'app.myNodes.mainnet'), [custom, pubA]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      final head = tester.getTopLeft(find.text('PUBLIC NODES')).dy;
      expect(tester.getTopLeft(_row(pubA)).dy, lessThan(head));
      expect(tester.getTopLeft(_row(pubB)).dy, greaterThan(head));
      expect(
        find.descendant(of: _row(pubA), matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(_menuEnabled(tester, pubA), isFalse);
      // The old public entry is in Public: no button, no check.
      expect(find.byKey(serverMenuKey(pubB)), findsNothing);
      expect(
        find.descendant(of: _row(pubB), matching: find.byIcon(Icons.check)),
        findsNothing,
      );
    });

    // Rule 4: a button only where it means something; a down arrow on a public entry, a bin
    // on a typed-in one, a star nowhere.
    testWidgets('rule 4: no button on public rows, a down arrow or a bin on My nodes rows', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      for (final url in [
        'https://node.btlabs.uk',
        pubB,
        'https://epic.stackwallet.com:3413',
        'https://epic-node.iniaku.my.id',
      ]) {
        expect(_row(url), findsOneWidget);
        expect(find.byKey(serverMenuKey(url)), findsNothing);
      }
      Finder icon(String url, IconData data) => find.descendant(
        of: find.byKey(serverMenuKey(url)),
        matching: find.byIcon(data),
      );
      expect(icon(pubA, Icons.arrow_downward), findsOneWidget);
      expect(icon(custom, Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('rule 4: no button on public relay rows, no star anywhere', (tester) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(find.byKey(serverMenuKey(relB)), findsNothing);
      expect(find.byKey(serverMenuKey('flooepicbox.btlabs.uk')), findsNothing);
      expect(find.byKey(serverMenuKey(relA)), findsOneWidget);
      expect(find.byKey(serverMenuKey(relCustom)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    // Rule 6: with several servers in the list a tap still asks first.
    testWidgets('rule 6: a tap on a server in the list asks to switch', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      await tester.tap(_row(custom));
      await tester.pumpAndSettle();
      expect(find.text('Switch to my.node.example:3413'), findsOneWidget);
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
      await tester.tap(_row(pubA));
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(saved(store, 'app.myNodes.mainnet'), [pubA, custom, custom2]);
    });

    testWidgets('rule 6: relays — a tap on a server in the list asks to switch', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom, relCustom2]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      await tester.tap(_row(relCustom2));
      await tester.pumpAndSettle();
      expect(find.text('Switch to $relCustom2'), findsOneWidget);
      // The address-change line stays on the Epicbox switch.
      expect(find.text(AppLocalizations.of(tester.element(find.byType(ServerPickerSheet))).serverRelaySwitchNote), findsOneWidget);
      expect(store.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
    });

    // Migration: the notifiers read an older list down to one public server.
    for (final (name, key, list, inUseKey, inUse, expected, provider) in [
      (
        'nodes, the one in use stays',
        'app.myNodes.mainnet',
        [pubA, custom, pubB],
        'app.node.mainnet',
        pubA,
        [pubA, custom],
        myNodesProvider(Chain.mainnet),
      ),
      (
        'nodes, none in use: the last added stays',
        'app.myNodes.mainnet',
        [pubA, custom, pubB],
        'app.node.mainnet',
        'https://node.btlabs.uk',
        [custom, pubB],
        myNodesProvider(Chain.mainnet),
      ),
      (
        'relays, the one in use stays',
        'app.myRelays.mainnet',
        [relA, relCustom, relB],
        'app.relay.mainnet',
        relA,
        [relA, relCustom],
        myRelaysProvider(Chain.mainnet),
      ),
      (
        'relays, none in use: the last added stays',
        'app.myRelays.mainnet',
        [relA, relCustom, relB],
        'app.relay.mainnet',
        'epicbox.stackwallet.com',
        [relCustom, relB],
        myRelaysProvider(Chain.mainnet),
      ),
    ]) {
      test('migration: $name', () async {
        final store = seeded(key, list)..values[inUseKey] = inUse;
        final container = ProviderContainer(
          overrides: [secretStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        expect(await container.read(provider.future), expected);
      });
    }

    test('adding a public server drops the public one; the cap still holds', () async {
      final store = MemorySecretStore({});
      final container = ProviderContainer(
        overrides: [secretStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final mine = container.read(myRelaysProvider(Chain.mainnet).notifier);
      bool isPublic(String v) => v == relA || v == relB;
      for (var i = 0; i < 5; i++) {
        await mine.add('r$i.example.org', isPublic: isPublic);
      }
      await mine.add(relA, isPublic: isPublic);
      await mine.add(relB, isPublic: isPublic);
      expect(container.read(myRelaysProvider(Chain.mainnet)).value, [
        'r0.example.org',
        'r1.example.org',
        'r2.example.org',
        'r3.example.org',
        'r4.example.org',
        relB,
      ]);
      await mine.add('r5.example.org', isPublic: isPublic);
      expect(container.read(myRelaysProvider(Chain.mainnet)).value, hasLength(6));
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

  group('on a phone the confirm strip is in reach', () {
    for (final (name, size, bottom) in [
      ('360×640 with a 48 dp navigation bar', const Size(360, 640), 48.0),
      ('360×800 with a 24 dp gesture bar', const Size(360, 800), 24.0),
      ('412×915 with a 48 dp navigation bar', const Size(412, 915), 48.0),
    ]) {
      testWidgets('Epicbox sheet, $name', (tester) async {
        await _pumpPhone(tester, ServerKind.relay, size: size, bottom: bottom);
        await tester.tap(_row('epicbox.epicnet.us'));
        await tester.pumpAndSettle();
        expect(find.text('Switch to epicbox.epicnet.us'), findsOneWidget);
        _expectReachable(tester, inset: bottom);
      });

      testWidgets('Node sheet, $name', (tester) async {
        await _pumpPhone(tester, ServerKind.node, size: size, bottom: bottom);
        const url = 'https://node.epicnet.us:3413';
        await tester.scrollUntilVisible(_row(url), 100, scrollable: _sheetList);
        await tester.pumpAndSettle();
        await tester.tap(_row(url));
        await tester.pumpAndSettle();
        expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
        _expectReachable(tester, inset: bottom);
      });
    }

    testWidgets('a pick closes the keyboard, and the strip stays above one that is open', (
      tester,
    ) async {
      await _pumpPhone(tester, ServerKind.node, size: const Size(360, 640), bottom: 48);
      final field = find.byType(TextField).first;
      await tester.tap(field);
      await _keyboard(tester, 260);
      await tester.enterText(field, 'epicnet');
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus,
          isTrue);
      const url = 'https://node.epicnet.us:3413';
      await tester.scrollUntilVisible(_row(url), 100, scrollable: _sheetList);
      await tester.pumpAndSettle();
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      // The field let go of the keyboard; the test's view keeps the inset, as a phone would
      // until the keyboard has gone, and the strip is above it either way.
      expect(tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus,
          isFalse);
      _expectReachable(tester, inset: 260);
    });

    testWidgets('the Other server field: Use closes the keyboard, the strip is in reach', (
      tester,
    ) async {
      await _pumpPhone(tester, ServerKind.relay, size: const Size(360, 640), bottom: 48);
      // The sheet's one field, built once the list is scrolled down to it.
      final field = find.byType(TextField);
      await tester.scrollUntilVisible(field, 100, scrollable: _sheetList);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await _keyboard(tester, 260);
      await tester.enterText(field, 'relay.example.org');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Switch to relay.example.org'), findsOneWidget);
      _expectReachable(tester, inset: 260);
    });
  });
}
