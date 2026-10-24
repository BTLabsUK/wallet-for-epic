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
  _Directory({this.nodeList, this.net, this.relayLists});

  final List<NodeStatus>? nodeList;
  final NetworkStatus? net;

  /// Relay lists by chain name; a chain not here is no answer.
  final Map<String, List<RelayStatus>>? relayLists;

  @override
  Future<NetworkStatus> network(String chain) async =>
      net ?? (throw const NetError('down'));

  @override
  Future<List<NodeStatus>> nodes(String chain) async =>
      nodeList ?? (throw const NetError('down'));

  @override
  Future<List<RelayStatus>> relays(String chain) async =>
      relayLists?[chain] ?? (throw const NetError('down'));
}

/// The saved choice: mainnet, its default node, a relay that is not the default.
MemorySecretStore _store() => MemorySecretStore({
  'app.network': 'mainnet',
  'app.node.mainnet': 'https://node.btlabs.uk',
  'app.relay.mainnet': 'epicbox.stackwallet.com',
});

/// The providers every pump replaces (Riverpod exports no name for the list's type).
// ignore: strict_top_level_inference
_overrides(
  MemorySecretStore store,
  _Directory? directory, {
  FakeWalletService? service,
}) => [
  secretStoreProvider.overrideWithValue(store),
  walletServiceProvider.overrideWithValue(service ?? FakeWalletService()),
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
  FakeWalletService? service,
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
      overrides: _overrides(store, directory, service: service),
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

/// Types [text] into the Other server field and taps Add.
Future<void> _add(WidgetTester tester, String text) async {
  // The list is lazy: the field at its end is built once scrolled to.
  await tester.scrollUntilVisible(find.byKey(serverAddFieldKey), 200, scrollable: _list);
  await tester.enterText(find.byKey(serverAddFieldKey), text);
  await tester.tap(find.byKey(serverAddKey));
  await tester.pumpAndSettle();
}

/// Whether a text field has the focus (the keyboard would be up).
bool _typing() =>
    FocusManager.instance.primaryFocus?.context?.widget is EditableText;

/// The line at the sheet's foot with [text].
Finder _foot(String text) =>
    find.descendant(of: find.byKey(serverFootLineKey), matching: find.text(text));

/// The check on a row.
Finder _check(String value) =>
    find.descendant(of: find.byKey(serverRowKey(value)), matching: find.byIcon(Icons.check));

/// The whole list in view, so every row is built.
Future<void> tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 7000);
  await tester.pumpAndSettle();
}

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
    testWidgets('no directory answer: the node in use under My nodes, the rest public, health unknown', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, store: _store());
      expect(find.text('Node'), findsOneWidget);
      expect(find.text('MY NODES'), findsOneWidget);
      expect(find.text('PUBLIC NODES'), findsOneWidget);
      // Each head says what its group is and what a tap does.
      expect(find.text('The one in use and the ones you added.'), findsOneWidget);
      expect(find.text('Tap one to switch to it.'), findsOneWidget);
      expect(
        find.text('status.btlabs.uk not reachable; health unknown'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_row('https://node.btlabs.uk')).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
      expect(_inRow('https://node.btlabs.uk', 'Current'), findsOneWidget);
      expect(_inRow('https://node.btlabs.uk', 'BT Labs'), findsOneWidget);
      // The node in use has no button: nothing on it would do anything.
      expect(find.byKey(serverMenuKey('https://node.btlabs.uk')), findsNothing);
      for (final host in [
        'https://node.epicnet.us:3413',
        'https://epic-node.iniaku.my.id',
      ]) {
        await tester.scrollUntilVisible(_row(host), 200, scrollable: _list);
        expect(_row(host), findsOneWidget);
        expect(find.byKey(serverMenuKey(host)), findsNothing);
      }
      await tester.scrollUntilVisible(find.text('Height'), -200, scrollable: _list);
      // The current node's card, from the node's own answer.
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('2,500,000'), findsOneWidget);
      expect(find.text('3.6.0'), findsOneWidget);
      expect(find.text('Peers'), findsNothing);
    });

    testWidgets('directory health: at tip, behind, not responding, unknown', (
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
      await tall(tester);
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
      // A node the monitor answered without: the words say so, not just grey bars.
      expect(
        _inRow('https://epic.stackwallet.com:3413', 'Health unknown'),
        findsOneWidget,
      );
      expect(_inRow('https://node.btlabs.uk', 'Health unknown'), findsNothing);
      expect(find.text('Peers'), findsOneWidget);
      expect(find.text('2,500,000 · at tip'), findsOneWidget);
      expect(
        find.text(
          'Nodes agree on 2,500,000 · 5 of 6 nodes up · last block 40 s ago',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a typed-in node in My nodes has a bin; the node in use and public rows have none', (
      tester,
    ) async {
      const url = 'https://my.node.example:3413';
      final store = _store()..values['app.myNodes.mainnet'] = jsonEncode([url]);
      await _pump(tester, ServerKind.node, store: store);
      expect(find.text('MY NODES'), findsOneWidget);
      expect(_row(url), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(serverMenuKey(url)),
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byKey(serverMenuKey('https://node.btlabs.uk')), findsNothing);
      expect(find.byKey(serverMenuKey('https://node.epicnet.us:3413')), findsNothing);
      // No arrow anywhere, no star: nothing that would do nothing.
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('Add: a typed node is tested, joins My nodes, and is offered for a switch', (
      tester,
    ) async {
      final store = _store();
      var saved = 0;
      await _pump(tester, ServerKind.node, store: store, onSaved: () => saved++);
      expect(find.text('Other node, host or host:port'), findsOneWidget);
      // Empty: Add answers with the error line, saves nothing.
      await _add(tester, '');
      expect(
        find.text('Enter a node address such as node.example.com:3413'),
        findsOneWidget,
      );
      expect(store.values['app.myNodes.mainnet'], isNull);
      await _add(tester, 'my.node.example:3413');
      const url = 'https://my.node.example:3413';
      expect(_foot('Added to My nodes.'), findsOneWidget);
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [url]);
      await tall(tester);
      expect(
        tester.getTopLeft(_row(url)).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC NODES')).dy),
      );
      expect(find.byKey(serverMenuKey(url)), findsOneWidget);
      expect(_check(url), findsOneWidget);
      expect(find.text('Switch to my.node.example:3413'), findsOneWidget);
      // The field is clear again, the line goes after a few seconds.
      expect(tester.widget<TextField>(find.byKey(serverAddFieldKey)).controller!.text, '');
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(serverFootLineKey), findsNothing);
      // Cancel keeps it saved; a tap offers it again, and Switch makes it current.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(_row(url), findsOneWidget);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(store.values['app.node.mainnet'], url);
      expect(store.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
      expect(jsonDecode(store.values['app.myNodes.mainnet']!), [url]);
    });

    testWidgets('Add: a node that does not answer is not saved; a listed one is picked, the one in use says so', (
      tester,
    ) async {
      final store = _store();
      final service = FakeWalletService()..nodeTipFails = const NetError('refused');
      await _pump(tester, ServerKind.node, store: store, service: service);
      await _add(tester, 'dead.node.example');
      expect(find.textContaining('No answer.'), findsOneWidget);
      expect(store.values['app.myNodes.mainnet'], isNull);
      expect(find.byKey(serverFootLineKey), findsNothing);
      // Typing again clears the error.
      await tester.enterText(find.byKey(serverAddFieldKey), 'node.epicnet.us:3413');
      await tester.pumpAndSettle();
      expect(find.textContaining('No answer.'), findsNothing);
      // A public node: picked, not added again.
      await tester.tap(find.byKey(serverAddKey));
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
      expect(store.values['app.myNodes.mainnet'], isNull);
      expect(find.byKey(serverFootLineKey), findsNothing);
      // The node in use: nothing to switch to, and the sheet says so.
      await _add(tester, 'node.btlabs.uk');
      expect(_foot('Already in use.'), findsOneWidget);
      expect(find.byKey(serverSwitchKey), findsNothing);
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

    testWidgets('a tap asks first; the node in use answers; Switch saves the url and keeps the relay', (
      tester,
    ) async {
      final store = _store();
      var saved = 0;
      const url = 'https://node.epicnet.us:3413';
      await _pump(tester, ServerKind.node, store: store, onSaved: () => saved++);
      expect(find.byKey(serverSwitchKey), findsNothing);
      // The current node asks nothing, but the tap is answered.
      await tester.tap(_row('https://node.btlabs.uk'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(_foot('Already in use.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(serverFootLineKey), findsNothing);
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
      // A tap on the current node with a choice pending takes the choice back.
      await tester.scrollUntilVisible(_row('https://node.btlabs.uk'), -200, scrollable: _list);
      await tester.tap(_row('https://node.btlabs.uk'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(find.byKey(serverFootLineKey), findsNothing);
      await tester.scrollUntilVisible(_row(url), 200, scrollable: _list);
      await tester.tap(_row(url));
      await tester.pumpAndSettle();
      // Cancel takes it back too.
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

    testWidgets('the search filters both groups; no match says so', (tester) async {
      await _pump(tester, ServerKind.node, store: _store());
      final search = find.byType(TextField).first;
      expect(find.text('Find a node'), findsOneWidget);
      await tester.enterText(search, 'epicnet');
      await tester.pumpAndSettle();
      expect(_row('https://node.epicnet.us:3413'), findsOneWidget);
      expect(_row('https://node.btlabs.uk'), findsNothing);
      expect(find.text('MY NODES'), findsNothing);
      await tester.enterText(search, 'nothing-like-this');
      await tester.pumpAndSettle();
      expect(find.text('No match.'), findsOneWidget);
      expect(find.byType(ServerList), findsOneWidget);
    });
  });

  group('epicbox sheet', () {
    testWidgets('the warning, the Default tag on the real default, Current under My servers', (
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
      expect(find.text('MY SERVERS'), findsOneWidget);
      expect(_inRow('epicbox.stackwallet.com', 'Current'), findsOneWidget);
      expect(
        tester.getTopLeft(_row('epicbox.stackwallet.com')).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC SERVERS')).dy),
      );
      expect(find.text('The one in use and the ones you added.'), findsOneWidget);
      expect(find.text('Tap one to switch to it.'), findsOneWidget);
      // The one field is the Other server field, with Add beside it.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(serverAddKey), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.byKey(serverMenuKey('epicbox.stackwallet.com')), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
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
      await _pump(tester, ServerKind.relay, store: store, onSaved: () => saved++);
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

    testWidgets('Add: a typed relay joins My servers and is offered; bad text answers; listed ones are picked', (
      tester,
    ) async {
      final store = _store();
      await _pump(tester, ServerKind.relay, store: store);
      await _add(tester, 'not a host');
      expect(find.text('Enter a host such as epicbox.example.com'), findsOneWidget);
      expect(store.values['app.myRelays.mainnet'], isNull);
      await _add(tester, 'relay.example.org:4443');
      expect(find.text('Enter a host such as epicbox.example.com'), findsNothing);
      expect(_foot('Added to My servers.'), findsOneWidget);
      expect(find.text('Switch to relay.example.org:4443'), findsOneWidget);
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), ['relay.example.org:4443']);
      await tall(tester);
      expect(
        tester.getTopLeft(_row('relay.example.org:4443')).dy,
        lessThan(tester.getTopLeft(find.text('PUBLIC SERVERS')).dy),
      );
      expect(find.byKey(serverMenuKey('relay.example.org:4443')), findsOneWidget);
      expect(_check('relay.example.org:4443'), findsOneWidget);
      // Enter in the field adds too.
      await tester.enterText(find.byKey(serverAddFieldKey), 'relay.other.org');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), [
        'relay.example.org:4443',
        'relay.other.org',
      ]);
      expect(find.text('Switch to relay.other.org'), findsOneWidget);
      // A public relay typed in is picked, not added; the one in use says so.
      await _add(tester, 'epicbox.epicnet.us');
      expect(find.text('Switch to epicbox.epicnet.us'), findsOneWidget);
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), hasLength(2));
      await _add(tester, 'epicbox.stackwallet.com');
      expect(_foot('Already in use.'), findsOneWidget);
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(jsonDecode(store.values['app.myRelays.mainnet']!), hasLength(2));
    });

    testWidgets('the push relay shows its floonet health on mainnet; unlisted relays say unknown', (
      tester,
    ) async {
      const stack = EpicboxRelay(host: 'epicbox.stackwallet.com');
      const floo = EpicboxRelay(host: 'flooepicbox.btlabs.uk');
      await _pump(
        tester,
        ServerKind.relay,
        store: _store(),
        directory: _Directory(
          relayLists: {
            'mainnet': const [
              RelayStatus(relay: stack, healthy: true, verified: false, uptime24h: 1, latencyMs: 540),
            ],
            'floonet': const [
              RelayStatus(relay: floo, healthy: true, verified: false, uptime24h: 1, latencyMs: 90),
            ],
          },
        ),
      );
      await tall(tester);
      expect(_inRow('epicbox.stackwallet.com', '100.0 % up'), findsOneWidget);
      expect(_inRow('flooepicbox.btlabs.uk', '100.0 % up'), findsOneWidget);
      expect(_inRow('flooepicbox.btlabs.uk', '90 ms'), findsOneWidget);
      expect(_inRow('flooepicbox.btlabs.uk', 'BT Labs'), findsOneWidget);
      expect(_inRow('flooepicbox.btlabs.uk', 'Health unknown'), findsNothing);
      // One the monitor answered without.
      expect(_inRow('epicbox.epicnet.us', 'Health unknown'), findsOneWidget);
      expect(find.text('status.btlabs.uk not reachable; health unknown'), findsNothing);
    });

    testWidgets('no floonet answer: the push relay is unknown, the list still shows', (
      tester,
    ) async {
      const stack = EpicboxRelay(host: 'epicbox.stackwallet.com');
      await _pump(
        tester,
        ServerKind.relay,
        store: _store(),
        directory: _Directory(
          relayLists: {
            'mainnet': const [
              RelayStatus(relay: stack, healthy: true, verified: false, latencyMs: 540),
            ],
          },
        ),
      );
      await tall(tester);
      expect(_inRow('epicbox.stackwallet.com', '540 ms'), findsOneWidget);
      expect(_inRow('flooepicbox.btlabs.uk', 'Health unknown'), findsOneWidget);
    });
  });

  // The model of My nodes and My servers: the server in use and the typed-in ones; the public
  // list has every other public server. The node in use is btlabs and the relay in use
  // stackwallet (see [_store]).
  group('my servers', () {
    const pubA = 'https://node.epicnet.us:3413';
    const pubB = 'https://node.epiccash.com:3413';
    const custom = 'https://my.node.example:3413';
    const custom2 = 'https://other.node.example';
    const relA = 'epicbox.epicnet.us';
    const relB = 'epicbox.iniaku.my.id';
    const relCustom = 'relay.example.org';
    const relCustom2 = 'relay.other.org:4443';

    MemorySecretStore seeded(String key, List<String> list) =>
        _store()..values[key] = jsonEncode(list);

    List<Object?> saved(MemorySecretStore store, String key) =>
        jsonDecode(store.values[key]!) as List<Object?>;

    double head(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('a public relay switched to takes the place in My servers; the old one goes back to Public', (
      tester,
    ) async {
      final store = _store();
      await _pump(tester, ServerKind.relay, store: store);
      await tester.tap(_row(relA));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myRelays.mainnet'), [relA]);
      expect(store.values['app.relay.mainnet'], relA);
      // A new app: relA is current under My servers, stackwallet back under Public.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(find.text('MY SERVERS'), findsOneWidget);
      expect(tester.getTopLeft(_row(relA)).dy, lessThan(head(tester, 'PUBLIC SERVERS')));
      expect(_inRow(relA, 'Current'), findsOneWidget);
      expect(_check(relA), findsOneWidget);
      expect(find.byKey(serverMenuKey(relA)), findsNothing);
      expect(
        tester.getTopLeft(_row('epicbox.stackwallet.com')).dy,
        greaterThan(head(tester, 'PUBLIC SERVERS')),
      );
      expect(find.byKey(serverMenuKey('epicbox.stackwallet.com')), findsNothing);
      expect(_check('epicbox.stackwallet.com'), findsNothing);
      // Then a second public one: the store holds it alone, relA is back under Public.
      await tester.tap(_row(relB));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myRelays.mainnet'), [relB]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(tester.getTopLeft(_row(relB)).dy, lessThan(head(tester, 'PUBLIC SERVERS')));
      expect(tester.getTopLeft(_row(relA)).dy, greaterThan(head(tester, 'PUBLIC SERVERS')));
    });

    testWidgets('nodes: a public node switched to is current under My nodes; the old one goes back', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [custom]);
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
      final h = head(tester, 'PUBLIC NODES');
      // Current first, then the typed-in one; btlabs is public again.
      expect(tester.getTopLeft(_row(pubA)).dy, lessThan(tester.getTopLeft(_row(custom)).dy));
      expect(tester.getTopLeft(_row(custom)).dy, lessThan(h));
      expect(tester.getTopLeft(_row('https://node.btlabs.uk')).dy, greaterThan(h));
      expect(_check(pubA), findsOneWidget);
      expect(find.byKey(serverMenuKey(pubA)), findsNothing);
      expect(find.byKey(serverMenuKey(custom)), findsOneWidget);
      expect(find.byKey(serverMenuKey('https://node.btlabs.uk')), findsNothing);
    });

    testWidgets('a typed-in server switched to is current without a bin; the public one goes back', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(find.byKey(serverMenuKey(relCustom)), findsOneWidget);
      await tester.tap(_row(relCustom));
      await tester.pumpAndSettle();
      expect(_check(relCustom), findsOneWidget);
      expect(_check('epicbox.stackwallet.com'), findsNothing);
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.relay.mainnet'], relCustom);
      expect(saved(store, 'app.myRelays.mainnet'), [relCustom]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(_inRow(relCustom, 'Current'), findsOneWidget);
      expect(find.byKey(serverMenuKey(relCustom)), findsNothing);
      expect(
        tester.getTopLeft(_row('epicbox.stackwallet.com')).dy,
        greaterThan(head(tester, 'PUBLIC SERVERS')),
      );
      // No button anywhere now: every row is the one in use or a public one.
      expect(find.byType(PopupMenuButton<bool>), findsNothing);
    });

    testWidgets('the bin deletes a typed-in relay from a popup, says so, no dialog', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relCustom, 'epicbox.stackwallet.com']);
      await _pump(tester, ServerKind.relay, store: store);
      final bin = find.byKey(serverMenuKey(relCustom));
      expect(tester.getSize(bin).height, greaterThanOrEqualTo(48));
      expect(find.byTooltip('Delete'), findsOneWidget);
      await tester.tap(bin);
      await tester.pumpAndSettle();
      expect(find.byKey(serverMenuItemKey(relCustom)), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<bool>, 'Delete'), findsOneWidget);
      // Dismissing the popup keeps the relay.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(saved(store, 'app.myRelays.mainnet'), hasLength(2));
      await _menu(tester, relCustom);
      expect(find.byType(AlertDialog), findsNothing);
      expect(saved(store, 'app.myRelays.mainnet'), ['epicbox.stackwallet.com']);
      expect(_row(relCustom), findsNothing);
      expect(_foot('Deleted relay.example.org.'), findsOneWidget);
      // No relay switch was asked for.
      expect(find.byKey(serverSwitchKey), findsNothing);
    });

    testWidgets('deleting the relay offered for a switch takes the offer back', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tester.tap(_row(relCustom));
      await tester.pumpAndSettle();
      expect(find.byKey(serverSwitchKey), findsOneWidget);
      await _menu(tester, relCustom);
      expect(find.byKey(serverSwitchKey), findsNothing);
      expect(_check('epicbox.stackwallet.com'), findsOneWidget);
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

    testWidgets('nodes: the bin deletes a typed-in node and says so', (tester) async {
      final store = seeded('app.myNodes.mainnet', [custom, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      await _menu(tester, custom);
      expect(saved(store, 'app.myNodes.mainnet'), [custom2]);
      expect(_row(custom), findsNothing);
      expect(_foot('Deleted my.node.example:3413.'), findsOneWidget);
      expect(store.values['app.node.mainnet'], 'https://node.btlabs.uk');
    });

    testWidgets('no control that does nothing: bins only on typed-in servers not in use', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(find.byType(PopupMenuButton<bool>), findsNWidgets(2));
      expect(find.byKey(serverMenuKey(custom)), findsOneWidget);
      expect(find.byKey(serverMenuKey(custom2)), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byTooltip('In use. Pick another server first.'), findsNothing);
      // A stored public node not in use is a public row, without a bin.
      final h = head(tester, 'PUBLIC NODES');
      expect(tester.getTopLeft(_row(pubA)).dy, greaterThan(h));
      expect(find.byKey(serverMenuKey(pubA)), findsNothing);
      for (final url in [
        'https://node.btlabs.uk',
        pubB,
        'https://epic.stackwallet.com:3413',
        'https://epic-node.iniaku.my.id',
      ]) {
        expect(_row(url), findsOneWidget);
        expect(find.byKey(serverMenuKey(url)), findsNothing);
      }
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('relays: every button is a bin on a typed-in relay not in use', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      expect(find.byType(PopupMenuButton<bool>), findsOneWidget);
      expect(find.byKey(serverMenuKey(relCustom)), findsOneWidget);
      expect(find.byKey(serverMenuKey(relA)), findsNothing);
      expect(tester.getTopLeft(_row(relA)).dy, greaterThan(head(tester, 'PUBLIC SERVERS')));
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('older lists: public servers stored but not in use show under Public', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [pubA, custom, pubB, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      final h = head(tester, 'PUBLIC NODES');
      for (final url in [pubA, pubB]) {
        expect(_row(url), findsOneWidget);
        expect(tester.getTopLeft(_row(url)).dy, greaterThan(h));
        expect(find.byKey(serverMenuKey(url)), findsNothing);
      }
      for (final url in [custom, custom2]) {
        expect(tester.getTopLeft(_row(url)).dy, lessThan(h));
        expect(find.byKey(serverMenuKey(url)), findsOneWidget);
      }
    });

    testWidgets('a tap on a My-list entry moves the check to it; Switch makes it current', (
      tester,
    ) async {
      final store = seeded('app.myNodes.mainnet', [custom, custom2]);
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(_check('https://node.btlabs.uk'), findsOneWidget);
      for (final url in [custom, custom2]) {
        await tester.tap(_row(url));
        await tester.pumpAndSettle();
        expect(_check(url), findsOneWidget);
        expect(_check('https://node.btlabs.uk'), findsNothing);
        expect(find.text('Switch to ${url.replaceFirst('https://', '')}'), findsOneWidget);
      }
      await tester.tap(find.byKey(serverSwitchKey));
      await tester.pumpAndSettle();
      expect(store.values['app.node.mainnet'], custom2);
      expect(saved(store, 'app.myNodes.mainnet'), [custom, custom2]);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, ServerKind.node, store: store);
      await tall(tester);
      expect(_check(custom2), findsOneWidget);
      expect(_check(custom), findsNothing);
      // The one in use first, without a bin; the other keeps its bin.
      expect(tester.getTopLeft(_row(custom2)).dy, lessThan(tester.getTopLeft(_row(custom)).dy));
      expect(find.byKey(serverMenuKey(custom2)), findsNothing);
      expect(find.byKey(serverMenuKey(custom)), findsOneWidget);
    });

    testWidgets('a tap on a server in either group asks first', (tester) async {
      final store = seeded('app.myNodes.mainnet', [custom, custom2]);
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
      expect(saved(store, 'app.myNodes.mainnet'), [custom, custom2]);
    });

    testWidgets('relays: a tap on a server in the list asks to switch, with the address line', (
      tester,
    ) async {
      final store = seeded('app.myRelays.mainnet', [relA, relCustom, relCustom2]);
      await _pump(tester, ServerKind.relay, store: store);
      await tall(tester);
      await tester.tap(_row(relCustom2));
      await tester.pumpAndSettle();
      expect(find.text('Switch to $relCustom2'), findsOneWidget);
      // The address-change line stays on the Epicbox switch.
      expect(find.text('Your address changes; senders need the new one.'), findsOneWidget);
      expect(store.values['app.relay.mainnet'], 'epicbox.stackwallet.com');
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

    // The stores keep at most one public server (the one a switch moved in); older lists
    // are read down to that.
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
        await tester.scrollUntilVisible(_row('epicbox.epicnet.us'), 100, scrollable: _sheetList);
        await tester.pumpAndSettle();
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
      // The field let go of the keyboard (the lazy list may have let go of the field too);
      // the test's view keeps the inset, as a phone would until the keyboard has gone, and
      // the strip is above it either way.
      expect(_typing(), isFalse);
      _expectReachable(tester, inset: 260);
    });

    for (final (kind, size, typed, added, switchTo) in [
      (ServerKind.relay, const Size(360, 640), 'relay.example.org', 'Added to My servers.', 'Switch to relay.example.org'),
      (ServerKind.relay, const Size(412, 915), 'relay.example.org', 'Added to My servers.', 'Switch to relay.example.org'),
      (ServerKind.node, const Size(360, 640), 'my.node.example:3413', 'Added to My nodes.', 'Switch to my.node.example:3413'),
      (ServerKind.node, const Size(412, 915), 'my.node.example:3413', 'Added to My nodes.', 'Switch to my.node.example:3413'),
    ]) {
      testWidgets('the Other server field and Add stay above the keyboard; Add answers, the strip is in reach (${kind.name}, ${size.width.round()})', (
        tester,
      ) async {
        await _pumpPhone(tester, kind, size: size, bottom: 48);
        final field = find.byKey(serverAddFieldKey);
        await tester.scrollUntilVisible(field, 100, scrollable: _sheetList);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await _keyboard(tester, 260);
        final limit = size.height - 260;
        // The field and its Add button are whole above the keyboard, Add at least 48 dp.
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(limit));
        final add = tester.getRect(find.byKey(serverAddKey));
        expect(add.bottom, lessThanOrEqualTo(limit));
        expect(add.height, greaterThanOrEqualTo(48));
        expect(add.width, greaterThanOrEqualTo(48));
        await tester.enterText(field, typed);
        await tester.tap(find.byKey(serverAddKey));
        await tester.pumpAndSettle();
        expect(_foot(added), findsOneWidget);
        expect(tester.getRect(find.byKey(serverFootLineKey)).bottom, lessThanOrEqualTo(limit));
        expect(find.text(switchTo), findsOneWidget);
        _expectReachable(tester, inset: 260);
        // Add let go of the keyboard.
        expect(_typing(), isFalse);
      });
    }
  });
}
