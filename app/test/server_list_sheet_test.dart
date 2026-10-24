// The phone's Node and Epicbox sheets: one list per kind, a field at the top that filters and
// adds, a bin on every row with Undo, "Restore the public list", the directory's servers
// joining the list, the operators' icons, and the sheet on small phones.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/server_icons.dart';
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/server_switch.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/ui/server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'package:epic_wallet/src/ui/server_tile.dart' show ServerTileView;
import 'package:epic_wallet/src/ui/status.dart' show serverHost;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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

/// status.btlabs.uk: the lists when given, else no answer.
class _Directory implements RelayDirectory, NodeDirectory, NetworkDirectory {
  _Directory({this.nodeList, this.relayList});

  final List<NodeStatus>? nodeList;
  final List<RelayStatus>? relayList;

  @override
  Future<NetworkStatus> network(String chain) async => throw const NetError('down');

  @override
  Future<List<NodeStatus>> nodes(String chain) async => nodeList ?? (throw const NetError('down'));

  @override
  Future<List<RelayStatus>> relays(String chain) async {
    // The push relay's floonet lookup has no answer in these tests.
    if (chain != 'mainnet') throw const NetError('down');
    return relayList ?? (throw const NetError('down'));
  }
}

const _btlabs = 'https://node.btlabs.uk';
const _epicnet = 'https://node.epicnet.us:3413';
const _epiccash = 'https://node.epiccash.com:3413';
const _stack = 'epicbox.stackwallet.com';

/// The saved choice: mainnet, its default node, a relay that is not the default.
MemorySecretStore _store([Map<String, String> extra = const {}]) => MemorySecretStore({
  'app.network': 'mainnet',
  'app.node.mainnet': _btlabs,
  'app.relay.mainnet': _stack,
  ...extra,
});

String _listKey(ServerKind kind) => serverListKey(kind, Chain.mainnet);

ServerList _saved(MemorySecretStore store, ServerKind kind) =>
    ServerList.decode(store.values[_listKey(kind)])!;

/// A monitor icon on the monitor's own host.
ServerIcon _icon(String hash) => ServerIcon(
  hash: hash,
  urls: {128: Uri.parse('https://status.btlabs.uk/api/v1/icons/$hash-128.png')},
);

Uint8List _png(String hash) => File('test/fixtures/icons/$hash-128.png').readAsBytesSync();

/// Everything a pump needs; the sheet reads these providers.
class _Env {
  _Env({
    MemorySecretStore? store,
    this.directory,
    FakeWalletService? service,
    FakeRelayProbe? probe,
    this.icons,
  }) : store = store ?? _store(),
       service = service ?? FakeWalletService(),
       probe = probe ?? FakeRelayProbe();

  final MemorySecretStore store;
  final _Directory? directory;
  final FakeWalletService service;
  final FakeRelayProbe probe;

  /// Icon bytes by file name's hash; a hash not here (or no map) is a failed fetch.
  final Map<String, Uint8List>? icons;

  /// The URLs the icon fetch was asked for.
  final List<Uri> fetched = [];

  /// How often the app was restarted (no wallet open) and the live switches asked.
  int saved = 0;
  final List<({String nodeUrl, String relay})> live = [];

  /// Whether the fake live switch answers that the open wallet moved.
  bool liveAnswer = false;

  List<Override> get overrides => [
    secretStoreProvider.overrideWithValue(store),
    walletServiceProvider.overrideWithValue(service),
    relayDirectoryProvider.overrideWithValue(directory ?? _Directory()),
    relayProbeProvider.overrideWithValue(probe),
    homeProvider.overrideWith(_Home.new),
    listenerProvider.overrideWith(_Listener.new),
    walletConfigProvider.overrideWith(_Config.new),
    nodeTipProvider.overrideWith(
      (ref) async => NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0'),
    ),
    serverIconFetchProvider.overrideWithValue((url) async {
      fetched.add(url);
      final hash = url.pathSegments.last.split('-').first;
      return icons?[hash];
    }),
  ];

  Future<bool> _liveSwitch(
    WidgetRef ref, {
    required String nodeUrl,
    required EpicboxRelay relay,
  }) async {
    live.add((nodeUrl: nodeUrl, relay: relay.label));
    if (liveAnswer) return true;
    // No wallet open: save and hand over, as the real one does.
    await switchServersLive(ref, nodeUrl: nodeUrl, relay: relay);
    return false;
  }
}

/// A tall phone view, so every row is built.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pump(WidgetTester tester, ServerKind kind, _Env env, {bool tall = true}) async {
  if (tall) _tallView(tester);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: env.overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ServerListSheet(
            kind: kind,
            afterSave: (_) => env.saved++,
            liveSwitch: env._liveSwitch,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets the foot line's and the notices' timers run out.
Future<void> _timers(WidgetTester tester) => tester.pump(const Duration(seconds: 9));

Finder _row(String value) => find.byKey(serverListRowKey(value));
Finder _inRow(String value, String text) =>
    find.descendant(of: _row(value), matching: find.textContaining(text, findRichText: true));
Finder _foot(String text) =>
    find.descendant(of: find.byKey(serverListFootKey), matching: find.text(text));
Finder _field() => find.byKey(serverListFieldKey);
Finder _check(String value) => find.descendant(of: _row(value), matching: find.byIcon(Icons.check));

String _fieldText(WidgetTester tester) => tester.widget<TextField>(_field()).controller!.text;

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field(), text);
  await tester.pumpAndSettle();
}

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.byKey(serverListAddKey));
  await tester.pumpAndSettle();
}

/// Whether a text field has the focus (the keyboard would be up).
bool _typing() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null &&
      (context.widget is EditableText ||
          context.findAncestorWidgetOfExactType<EditableText>() != null);
}

/// Rows top to bottom as the sheet lists them.
List<String> _order(WidgetTester tester, Iterable<String> values) {
  final at = {
    for (final v in values)
      if (_row(v).evaluate().isNotEmpty) v: tester.getTopLeft(_row(v)).dy,
  };
  return (at.keys.toList()..sort((a, b) => at[a]!.compareTo(at[b]!)));
}

const _noMatch = 'No match.';
const _notAddress = 'Not a server address. Use host or host:port.';

void main() {
  group('the list', () {
    testWidgets('node: the built-in nodes in order, the field holds the one in use', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      expect(find.text('Node'), findsOneWidget);
      expect(_fieldText(tester), 'node.btlabs.uk');
      expect(_order(tester, [_btlabs, _epicnet, _epiccash]), [_btlabs, _epicnet, _epiccash]);
      expect(_row('https://epic.stackwallet.com:3413'), findsOneWidget);
      expect(_row('https://epic-node.iniaku.my.id'), findsOneWidget);
      expect(_inRow(_btlabs, 'Current'), findsOneWidget);
      expect(_check(_btlabs), findsOneWidget);
      expect(_check(_epicnet), findsNothing);
      // Nothing typed: no Add, no restore, no match line, a bin on every row.
      expect(find.byKey(serverListAddKey), findsNothing);
      expect(find.byKey(serverListRestoreKey), findsNothing);
      expect(find.text(_noMatch), findsNothing);
      expect(find.byKey(serverListRemoveKey(_btlabs)), findsOneWidget);
      expect(find.byKey(serverListRemoveKey(_epicnet)), findsOneWidget);
      // The list is saved under its own key.
      expect(_saved(env.store, ServerKind.node).entries.first, _btlabs);
    });

    testWidgets('epicbox: the list, the default tagged, the one in use in the field', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      expect(find.text('Epicbox'), findsOneWidget);
      expect(_fieldText(tester), _stack);
      expect(_row(defaultEpicboxHost), findsOneWidget);
      expect(_inRow(defaultEpicboxHost, 'Default'), findsOneWidget);
      expect(_inRow(_stack, 'Current'), findsOneWidget);
      expect(_check(_stack), findsOneWidget);
      expect(_row('flooepicbox.btlabs.uk'), findsOneWidget, reason: 'the push relay');
    });

    testWidgets('epicbox: the address warning on the sheet and, once a server is picked, the '
        'strip warns again', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      expect(
        find.text('Switching changes your address. Senders need the new one.'),
        findsOneWidget,
      );
      expect(find.text('Your address changes; senders need the new one.'), findsNothing);
      await tester.tap(_row('epicbox.epicnet.us'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to epicbox.epicnet.us'), findsOneWidget);
      expect(find.text('Your address changes; senders need the new one.'), findsOneWidget);
    });

    testWidgets('node: neither the address warning nor its strip note', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      expect(find.text('Switching changes your address. Senders need the new one.'), findsNothing);
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
      expect(find.text('Your address changes; senders need the new one.'), findsNothing);
      expect(
        find.text('The wallet reconnects. Balances are checked again against the new node.'),
        findsOneWidget,
      );
    });

    testWidgets('typing filters by host or operator; closing the filter brings the list back', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, _Env());
      await _type(tester, 'epicnet');
      expect(_row(_epicnet), findsOneWidget);
      expect(_row(_btlabs), findsNothing);
      expect(_row(_epiccash), findsNothing);
      expect(find.text('1 match.'), findsOneWidget);
      // By operator.
      await _type(tester, 'Cypher');
      expect(_row('https://epic.stackwallet.com:3413'), findsOneWidget);
      expect(_row(_epicnet), findsNothing);
      // The clear button empties the field; the list is whole again.
      await tester.tap(find.byKey(serverListClearKey));
      await tester.pumpAndSettle();
      expect(_row(_btlabs), findsOneWidget);
      expect(_row(_epicnet), findsOneWidget);
      expect(find.text('1 match.'), findsNothing);
    });

    testWidgets('nothing matches: one "No match." and the Add row, for any text', (tester) async {
      for (final kind in ServerKind.values) {
        await _pump(tester, kind, _Env());
        await _type(tester, 'zzzzzz');
        expect(find.text(_noMatch), findsOneWidget, reason: kind.name);
        expect(find.byKey(serverListAddKey), findsOneWidget, reason: kind.name);
        expect(find.text('Add zzzzzz'), findsOneWidget);
        // The old second line is gone: "No match" is said once.
        expect(find.textContaining('No match'), findsOneWidget);
      }
    });

    testWidgets('an address no row has is addable even while other rows match its text', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, _Env());
      await _type(tester, 'epicnet.us');
      expect(_row(_epicnet), findsOneWidget);
      expect(find.byKey(serverListAddKey), findsOneWidget);
      expect(find.text('Not in the list.'), findsOneWidget);
      expect(find.text(_noMatch), findsNothing);
      // A listed address has no Add row; Done on the field picks it.
      await _type(tester, 'node.epicnet.us:3413');
      expect(find.byKey(serverListAddKey), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
    });

    testWidgets('a tap on a row asks first; the server in use answers; Cancel takes it back; '
        'Switch saves the node and keeps the relay', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      expect(find.byKey(serverListSwitchKey), findsNothing);
      await tester.tap(_row(_btlabs));
      await tester.pumpAndSettle();
      expect(find.byKey(serverListSwitchKey), findsNothing);
      expect(_foot('Already in use.'), findsOneWidget);
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
      expect(_check(_epicnet), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(serverListSwitchKey), findsNothing);
      expect(env.store.values['app.node.mainnet'], _btlabs);

      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverListSwitchKey));
      await tester.pumpAndSettle();
      expect(env.saved, 1);
      expect(env.store.values['app.node.mainnet'], _epicnet);
      expect(env.store.values['app.relay.mainnet'], _stack);
      await _timers(tester);
    });

    testWidgets('with a wallet open the switch is live: the sheet is not restarted', (
      tester,
    ) async {
      final env = _Env()..liveAnswer = true;
      await _pump(tester, ServerKind.relay, env);
      await tester.tap(_row('epicbox.epicnet.us'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverListSwitchKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(env.live.single, (nodeUrl: _btlabs, relay: 'epicbox.epicnet.us'));
      expect(env.saved, 0);
      await _timers(tester);
    });

    testWidgets('a tap closes the keyboard', (tester) async {
      await _pump(tester, ServerKind.node, _Env());
      await tester.tap(_field());
      await tester.pump();
      expect(_typing(), isTrue);
      await tester.enterText(_field(), 'epicnet');
      await tester.pumpAndSettle();
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(_typing(), isFalse);
      expect(find.text('Switch to node.epicnet.us:3413'), findsOneWidget);
    });
  });

  group('add', () {
    testWidgets('a good node is tested by its tip, added, selected and offered for a switch', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      await _type(tester, 'node.example.org');
      expect(find.byKey(serverListAddKey), findsOneWidget);
      expect(env.service.nodeTipCalls, 0);
      await _tapAdd(tester);

      expect(env.service.nodeTipCalls, 1);
      expect(_row('https://node.example.org'), findsOneWidget);
      expect(_saved(env.store, ServerKind.node).entries.last, 'https://node.example.org');
      expect(_check('https://node.example.org'), findsOneWidget);
      expect(find.text('Switch to node.example.org'), findsOneWidget);
      expect(_foot('Added node.example.org.'), findsOneWidget);
      // The field is back on the server in use; the filter is closed.
      expect(_fieldText(tester), 'node.btlabs.uk');
      expect(_row(_btlabs), findsOneWidget);
      expect(find.byKey(serverListAddKey), findsNothing);
      // The wallet still uses the old node until Switch.
      expect(env.store.values['app.node.mainnet'], _btlabs);

      await tester.tap(find.byKey(serverListSwitchKey));
      await tester.pumpAndSettle();
      expect(env.store.values['app.node.mainnet'], 'https://node.example.org');
      expect(env.saved, 1);
      await _timers(tester);
    });

    testWidgets('a good relay is probed, added, selected and offered for a switch', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await _type(tester, 'relay.example.org:4443');
      await _tapAdd(tester);

      expect(env.probe.probed.single.label, 'relay.example.org:4443');
      expect(_row('relay.example.org:4443'), findsOneWidget);
      expect(_saved(env.store, ServerKind.relay).entries.last, 'relay.example.org:4443');
      expect(_check('relay.example.org:4443'), findsOneWidget);
      expect(find.text('Switch to relay.example.org:4443'), findsOneWidget);
      expect(find.text('Your address changes; senders need the new one.'), findsOneWidget);
      expect(_foot('Added relay.example.org:4443.'), findsOneWidget);
      await tester.tap(find.byKey(serverListSwitchKey));
      await tester.pumpAndSettle();
      expect(env.store.values['app.relay.mainnet'], 'relay.example.org:4443');
      await _timers(tester);
    });

    for (final kind in ServerKind.values) {
      testWidgets('${kind.name}: text that is no address gets the plain message and nothing is '
          'added or tested', (tester) async {
        final env = _Env();
        await _pump(tester, kind, env);
        final before = _saved(env.store, kind).entries;
        await _type(tester, 'not a host!');
        await _tapAdd(tester);

        expect(find.text(_notAddress), findsOneWidget);
        expect(_saved(env.store, kind).entries, before);
        expect(env.service.nodeTipCalls, 0);
        expect(env.probe.probed, isEmpty);
        expect(find.byKey(serverListSwitchKey), findsNothing);
        // Typing again clears the message.
        await _type(tester, 'not a host');
        expect(find.text(_notAddress), findsNothing);
        await _timers(tester);
      });
    }

    testWidgets('node: a node whose tip cannot be read is not added', (tester) async {
      final env = _Env();
      env.service.nodeTipFails = const NetError('timed out');
      await _pump(tester, ServerKind.node, env);
      final before = _saved(env.store, ServerKind.node).entries;
      await _type(tester, 'node.example.org');
      await _tapAdd(tester);

      expect(env.service.nodeTipCalls, 1);
      expect(find.textContaining('No answer.'), findsOneWidget);
      expect(_row('https://node.example.org'), findsNothing);
      expect(_saved(env.store, ServerKind.node).entries, before);
      expect(find.byKey(serverListSwitchKey), findsNothing);
      // The text stays to be edited, with Add still there.
      expect(_fieldText(tester), 'node.example.org');
      expect(find.byKey(serverListAddKey), findsOneWidget);
    });

    testWidgets('epicbox: a server that does not answer the handshake is not added', (
      tester,
    ) async {
      final env = _Env(probe: FakeRelayProbe(answer: false));
      await _pump(tester, ServerKind.relay, env);
      final before = _saved(env.store, ServerKind.relay).entries;
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);

      expect(env.probe.probed, hasLength(1));
      expect(find.text('No answer from this server. Nothing added.'), findsOneWidget);
      expect(_row('relay.example.org'), findsNothing);
      expect(_saved(env.store, ServerKind.relay).entries, before);
      expect(find.byKey(serverListSwitchKey), findsNothing);
      expect(_fieldText(tester), 'relay.example.org');
    });
  });

  group('remove and restore', () {
    testWidgets('the bin removes the row and says so; Undo puts it back at its place', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      await tester.tap(find.byKey(serverListRemoveKey(_epicnet)));
      await tester.pumpAndSettle();

      expect(_row(_epicnet), findsNothing);
      expect(_foot('Removed node.epicnet.us:3413.'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Undo')),
        findsOneWidget,
      );
      final list = _saved(env.store, ServerKind.node);
      expect(list.entries, isNot(contains(_epicnet)));
      expect(list.removed, contains('node.epicnet.us:3413'));
      // The list was removed from the public one: restore shows.
      expect(find.byKey(serverListRestoreKey), findsOneWidget);

      await tester.tap(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Undo')),
      );
      await tester.pumpAndSettle();
      expect(_row(_epicnet), findsOneWidget);
      expect(_order(tester, [_btlabs, _epicnet, _epiccash]), [_btlabs, _epicnet, _epiccash]);
      expect(
        _saved(env.store, ServerKind.node).entries,
        list.entries.toList()..insert(1, _epicnet),
      );
      expect(_saved(env.store, ServerKind.node).removed, isEmpty);
      expect(find.byKey(serverListRestoreKey), findsNothing);
      await _timers(tester);
      expect(find.byKey(serverListFootKey), findsNothing, reason: 'the line goes away by itself');
    });

    testWidgets('without Undo the row stays out once the line is gone', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await tester.tap(find.byKey(serverListRemoveKey('epicbox.epicnet.us')));
      await tester.pumpAndSettle();
      expect(_foot('Removed epicbox.epicnet.us.'), findsOneWidget);
      await _timers(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(serverListFootKey), findsNothing);
      expect(_row('epicbox.epicnet.us'), findsNothing);
      expect(_saved(env.store, ServerKind.relay).entries, isNot(contains('epicbox.epicnet.us')));
    });

    testWidgets('the server in use refuses: "In use. Switch first."', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      final before = _saved(env.store, ServerKind.node);
      await tester.tap(find.byKey(serverListRemoveKey(_btlabs)));
      await tester.pumpAndSettle();
      expect(_foot('In use. Switch first.'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Undo')),
        findsNothing,
      );
      expect(_row(_btlabs), findsOneWidget);
      expect(_saved(env.store, ServerKind.node), before);
      await _timers(tester);
    });

    testWidgets('removing the server picked for a switch takes the offer back', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(find.byKey(serverListSwitchKey), findsOneWidget);
      await tester.tap(find.byKey(serverListRemoveKey(_epicnet)));
      await tester.pumpAndSettle();
      expect(find.byKey(serverListSwitchKey), findsNothing);
      await _timers(tester);
    });

    testWidgets('Restore the public list shows only while a public server is removed, and puts '
        'them back', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      expect(find.byKey(serverListRestoreKey), findsNothing);
      await tester.tap(find.byKey(serverListRemoveKey(_epicnet)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverListRemoveKey(_epiccash)));
      await tester.pumpAndSettle();
      expect(find.text('Restore the public list · 2 removed'), findsOneWidget);

      await tester.tap(find.byKey(serverListRestoreKey));
      await tester.pumpAndSettle();
      expect(_foot('Restored the public list.'), findsOneWidget);
      expect(_row(_epicnet), findsOneWidget);
      expect(_row(_epiccash), findsOneWidget);
      expect(find.byKey(serverListRestoreKey), findsNothing);
      final list = _saved(env.store, ServerKind.node);
      expect(list.removed, isEmpty);
      expect(list.entries, containsAll([_epicnet, _epiccash]));
      await _timers(tester);
    });

    testWidgets('removing a server of your own does not offer to restore the public list', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);
      await tester.tap(find.byKey(serverListRemoveKey('relay.example.org')));
      await tester.pumpAndSettle();
      expect(_row('relay.example.org'), findsNothing);
      expect(find.byKey(serverListRestoreKey), findsNothing);
      await _timers(tester);
    });
  });

  group('the directory', () {
    const added = 'https://node.new.example:3413';
    final newNode = [
      const NodeStatus(
        url: added,
        healthy: true,
        verified: false,
        operator: 'New Ops',
        state: NodeHealthState.healthy,
        tipLag: 0,
      ),
    ];

    testWidgets('a new server of the monitor joins the list; once removed it stays out when '
        'the directory answers again', (tester) async {
      final env = _Env(directory: _Directory(nodeList: newNode));
      await _pump(tester, ServerKind.node, env);
      expect(_row(added), findsOneWidget);
      expect(_saved(env.store, ServerKind.node).entries.last, added);
      expect(_inRow(added, 'New Ops'), findsOneWidget);

      await tester.tap(find.byKey(serverListRemoveKey(added)));
      await tester.pumpAndSettle();
      await _timers(tester);
      expect(_row(added), findsNothing);

      // The sheet opens again; the directory lists it still.
      await _pump(tester, ServerKind.node, env);
      expect(_row(added), findsNothing);
      expect(_saved(env.store, ServerKind.node).entries, isNot(contains(added)));
      expect(find.text('Restore the public list · 1 removed'), findsOneWidget);

      // Restore brings it back.
      await tester.tap(find.byKey(serverListRestoreKey));
      await tester.pumpAndSettle();
      expect(_row(added), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('a built-in server the user removed stays out too, with the directory answering '
        'for it', (tester) async {
      final env = _Env(
        directory: _Directory(
          nodeList: const [
            NodeStatus(
              url: _epicnet,
              healthy: true,
              verified: true,
              operator: 'EpicNet',
              state: NodeHealthState.healthy,
              tipLag: 0,
            ),
          ],
        ),
      );
      await _pump(tester, ServerKind.node, env);
      expect(_inRow(_epicnet, 'at tip'), findsOneWidget);
      await tester.tap(find.byKey(serverListRemoveKey(_epicnet)));
      await tester.pumpAndSettle();
      await _timers(tester);
      await _pump(tester, ServerKind.node, env);
      expect(_row(_epicnet), findsNothing);
      expect(find.text('Restore the public list · 1 removed'), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('epicbox: a monitor relay joins the list as well', (tester) async {
      final env = _Env(
        directory: _Directory(
          relayList: const [
            RelayStatus(
              relay: EpicboxRelay(host: 'epicbox.new.example'),
              healthy: true,
              verified: false,
              operator: 'New Ops',
              latencyMs: 120,
            ),
          ],
        ),
      );
      await _pump(tester, ServerKind.relay, env);
      expect(_row('epicbox.new.example'), findsOneWidget);
      expect(_saved(env.store, ServerKind.relay).entries, contains('epicbox.new.example'));
      expect(_inRow('epicbox.new.example', '120 ms'), findsOneWidget);
    });

    testWidgets('no answer from the monitor: the built-in list still shows, health unknown', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, _Env());
      expect(_row(_epicnet), findsOneWidget);
      expect(find.text('status.btlabs.uk not reachable; health unknown'), findsOneWidget);
    });
  });

  group('lists from older versions', () {
    test('the key names the lists are stored under', () {
      expect(serverListKey(ServerKind.node, Chain.mainnet), 'app.serverList.node.mainnet');
      expect(serverListKey(ServerKind.relay, Chain.floonet), 'app.serverList.relay.floonet');
    });

    testWidgets('My nodes join the built-in nodes, once, in the new key', (tester) async {
      final env = _Env(store: _store({'app.myNodes.mainnet': '["https://my.node.example:3413"]'}));
      await _pump(tester, ServerKind.node, env);
      expect(_row('https://my.node.example:3413'), findsOneWidget);
      expect(
        _order(tester, [_btlabs, 'https://epic-node.iniaku.my.id', 'https://my.node.example:3413']),
        [_btlabs, 'https://epic-node.iniaku.my.id', 'https://my.node.example:3413'],
      );
      final list = _saved(env.store, ServerKind.node);
      expect(list.entries, contains('https://my.node.example:3413'));
      expect(list.entries.where((e) => e == _btlabs), hasLength(1));
    });

    testWidgets('My servers join the built-in relays', (tester) async {
      final env = _Env(store: _store({'app.myRelays.mainnet': '["relay.mine.example"]'}));
      await _pump(tester, ServerKind.relay, env);
      expect(_row('relay.mine.example'), findsOneWidget);
      expect(_row(_stack), findsOneWidget, reason: 'listed once even if both lists name it');
      expect(_saved(env.store, ServerKind.relay).entries, contains('relay.mine.example'));
    });

    testWidgets('a saved new list wins: the old one is not read again', (tester) async {
      final env = _Env(
        store: _store({
          'app.myNodes.mainnet': '["https://my.node.example:3413"]',
          _listKey(ServerKind.node): const ServerList(entries: [_btlabs, _epicnet]).encode(),
        }),
      );
      await _pump(tester, ServerKind.node, env);
      expect(_row('https://my.node.example:3413'), findsNothing);
      expect(_row(_btlabs), findsOneWidget);
      expect(_row(_epicnet), findsOneWidget);
    });

    testWidgets('a broken old list is ignored, a broken new list seeds again', (tester) async {
      final env = _Env(
        store: _store({'app.myNodes.mainnet': 'not json', _listKey(ServerKind.node): '{{'}),
      );
      await _pump(tester, ServerKind.node, env);
      expect(_row(_btlabs), findsOneWidget);
      expect(_saved(env.store, ServerKind.node).entries.first, _btlabs);
    });
  });

  group('tiles', () {
    final iconed = _Directory(
      nodeList: [
        NodeStatus(
          url: _epicnet,
          healthy: true,
          verified: true,
          operator: 'EpicNet',
          state: NodeHealthState.healthy,
          tipLag: 0,
          icon: _icon('41bec7e038f3b806b2db'),
        ),
      ],
    );

    Finder image(String value) =>
        find.descendant(of: _row(value), matching: find.byKey(ServerTileView.imageKey));

    testWidgets('the operator icon shows once its bytes are fetched; other rows keep initials', (
      tester,
    ) async {
      final env = _Env(
        directory: iconed,
        icons: {'41bec7e038f3b806b2db': _png('41bec7e038f3b806b2db')},
      );
      await _pump(tester, ServerKind.node, env);
      expect(image(_epicnet), findsOneWidget);
      expect(image(_btlabs), findsNothing);
      expect(find.descendant(of: _row(_btlabs), matching: find.text('BL')), findsOneWidget);
      // Only the monitor's own host is asked.
      expect(env.fetched, isNotEmpty);
      expect(env.fetched.every((u) => u.scheme == 'https' && u.host == 'status.btlabs.uk'), isTrue);
    });

    testWidgets('a failed fetch (null bytes) leaves the initials', (tester) async {
      final env = _Env(directory: iconed);
      await _pump(tester, ServerKind.node, env);
      expect(env.fetched, isNotEmpty);
      expect(image(_epicnet), findsNothing);
      expect(find.descendant(of: _row(_epicnet), matching: find.text('EN')), findsOneWidget);
    });

    testWidgets('a server with no icon shows its operator initials: "EU" for epicnet.us', (
      tester,
    ) async {
      final env = _Env(
        directory: _Directory(
          relayList: const [
            RelayStatus(
              relay: EpicboxRelay(host: 'relay.monitor.example'),
              healthy: true,
              verified: false,
              operator: 'epicnet.us',
            ),
          ],
        ),
      );
      await _pump(tester, ServerKind.relay, env);
      expect(
        find.descendant(of: _row('relay.monitor.example'), matching: find.text('EU')),
        findsOneWidget,
      );
      expect(find.byKey(ServerTileView.imageKey), findsNothing);
      expect(env.fetched, isEmpty, reason: 'no icon to ask for');
    });

    testWidgets('epicbox rows get their icon the same way', (tester) async {
      final env = _Env(
        directory: _Directory(
          relayList: [
            RelayStatus(
              relay: const EpicboxRelay(host: 'epicbox.epicnet.us'),
              healthy: true,
              verified: true,
              operator: 'EpicNet',
              icon: _icon('73de63f69b0165b85c44'),
            ),
          ],
        ),
        icons: {'73de63f69b0165b85c44': _png('73de63f69b0165b85c44')},
      );
      await _pump(tester, ServerKind.relay, env);
      expect(image('epicbox.epicnet.us'), findsOneWidget);
      expect(image(_stack), findsNothing);
    });
  });

  group('on a phone', () {
    /// Opens the real sheet over a screen of [size] dp with a status bar and a gesture bar, text
    /// at [scale].
    Future<void> open(
      WidgetTester tester,
      ServerKind kind,
      _Env env, {
      required Size size,
      required double scale,
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: env.overrides,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
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

    final list = find.descendant(
      of: find.byKey(serverListListKey),
      matching: find.byType(Scrollable),
    );

    for (final size in const [Size(360, 640), Size(412, 915)]) {
      for (final scale in const [1.0, 2.0]) {
        for (final kind in ServerKind.values) {
          testWidgets(
            '${kind.name} sheet at ${size.width.round()}×${size.height.round()}, text ×${scale.toStringAsFixed(0)}: '
            'no overflow; a row below the fold is reachable; the strip is in reach; Add answers',
            (tester) async {
              final env = _Env();
              await open(tester, kind, env, size: size, scale: scale);
              expect(find.byType(ServerListSheet), findsOneWidget);
              expect(tester.takeException(), isNull);

              // The epicnet row sits below the fold on the small phone.
              final target = kind == ServerKind.node ? _epicnet : 'epicbox.epicnet.us';
              await tester.scrollUntilVisible(_row(target), 100, scrollable: list);
              // Built in the list's cache is not yet on the screen.
              await tester.ensureVisible(_row(target));
              await tester.pumpAndSettle();
              await tester.tap(_row(target));
              await tester.pumpAndSettle();
              final screenHeight = size.height - 16;
              // The strip scrolls inside its cap: bring Switch and Cancel into view.
              await tester.ensureVisible(find.byKey(serverListSwitchKey));
              await tester.pumpAndSettle();
              final button = tester.getRect(find.byKey(serverListSwitchKey));
              expect(button.height, greaterThanOrEqualTo(48));
              expect(button.bottom, lessThanOrEqualTo(screenHeight));
              expect(button.top, greaterThanOrEqualTo(0));
              await tester.ensureVisible(find.text('Cancel'));
              await tester.pumpAndSettle();
              expect(tester.getRect(find.text('Cancel')).bottom, lessThanOrEqualTo(screenHeight));
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              // A filter nothing matches: one "No match." and the Add row in reach.
              // The field is pinned above the list: always there.
              expect(_field(), findsOneWidget);
              await tester.enterText(_field(), 'zzzzzz');
              await tester.pumpAndSettle();
              expect(find.text(_noMatch), findsOneWidget);
              await tester.tap(find.byKey(serverListAddKey));
              await tester.pumpAndSettle();
              expect(find.text(_notAddress), findsOneWidget);
              expect(tester.takeException(), isNull);
              await _timers(tester);
            },
          );
        }
      }
    }

    testWidgets('with the keyboard open the field and the Add row stay above it', (tester) async {
      final env = _Env();
      await open(tester, ServerKind.relay, env, size: const Size(360, 640), scale: 1);
      await tester.tap(_field());
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 0);
      await tester.pumpAndSettle();
      await tester.enterText(_field(), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final add = tester.getRect(find.byKey(serverListAddKey));
      expect(add.bottom, lessThanOrEqualTo(640 - 300));
      await tester.tap(find.byKey(serverListAddKey));
      await tester.pumpAndSettle();
      expect(find.text(_notAddress), findsOneWidget);
      await _timers(tester);
    });
  });

  group('only the list scrolls', () {
    // The title, the field and the Current card stay where they are while the rows move.
    for (final size in const [Size(412, 915), Size(360, 640)]) {
      testWidgets('node sheet at ${size.width.round()}×${size.height.round()}: dragging the list '
          'leaves the field and the Current card in place', (tester) async {
        // Enough servers that the list scrolls on the tall phone too.
        final env = _Env(
          store: _store({
            _listKey(ServerKind.node): ServerList(
              entries: [
                ...builtInValues(ServerKind.node, Chain.mainnet),
                for (var i = 0; i < 12; i++) 'https://node$i.example.org',
              ],
            ).encode(),
          }),
        );
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
        tester.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: env.overrides,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showNodePicker(context),
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

        // A drag on the list first lifts the sheet to full height; that is the sheet moving, not
        // the list. Start from there.
        final rows = find.descendant(
          of: find.byKey(serverListListKey),
          matching: find.byKey(serverListRowKey(_btlabs)),
        );
        await tester.drag(rows, const Offset(0, -300));
        await tester.pumpAndSettle();

        final card = find.text('Height');
        expect(card, findsOneWidget);
        final title = tester.getTopLeft(find.text('Node'));
        final field = tester.getTopLeft(_field());
        final cardAt = tester.getTopLeft(card);
        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: find.byKey(serverListListKey), matching: find.byType(Scrollable)),
        );
        final scrolled = scrollable.position.pixels;

        expect(rows, findsOneWidget);
        await tester.drag(find.byKey(serverListListKey), const Offset(0, -150));
        await tester.pumpAndSettle();

        expect(tester.getTopLeft(find.text('Node')), title);
        expect(tester.getTopLeft(_field()), field);
        expect(tester.getTopLeft(card), cardAt);
        expect(scrollable.position.pixels, greaterThan(scrolled), reason: 'the rows did move');
        await _timers(tester);
      });
    }
  });

  test('serverHost reads the host of a node address', () {
    expect(serverHost(_epicnet), 'node.epicnet.us:3413');
    expect(serverHost(_btlabs), 'node.btlabs.uk');
  });
}
