// SPDX-License-Identifier: Apache-2.0
// The phone's Node and Epicbox sheets: one list per kind, a field at the top that starts empty,
// filters and adds, a Node row that switches at once, an Epicbox row that asks first, a bin on
// every row with Undo, "Restore removed servers", the directory's servers
// joining the list, the operators' icons, and the sheet on small phones.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/connection_state.dart' show WalletStatusNotifier, walletStatusProvider;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/server_icons.dart';
import 'package:epic_wallet/src/server_list_file.dart';
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:epic_wallet/src/server_switch.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/ui/server_picker.dart' show showEpicboxPicker, showNodePicker;
import 'package:epic_wallet/src/ui/server_tile.dart' show ServerTileView;
import 'package:epic_wallet/src/ui/status.dart'
    show EpicboxState, NodeState, WalletStatus, serverHost;
import 'package:epic_wallet/src/ui/status.dart' as status show NodeStatus;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

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
      mainnetPreset.config(dataDir: '/fake', nodeUrl: 'https://node.lab.invalid');
}

class _Listener extends ListenerNotifier {
  @override
  ListenerState build() => const ListenerState(connected: true);
}

/// A listener that lost its relay, and counts Retry's restarts.
class _LostListener extends ListenerNotifier {
  int restarts = 0;

  @override
  ListenerState build() => const ListenerState(lost: true);

  @override
  Future<void> restart({bool quiet = false}) async => restarts++;
}

class _OpenSession extends SessionNotifier {
  @override
  WalletSession? build() => FakeWalletSession();
}

/// The shown status with the Epicbox connection down (it lasted the settle time).
class _NotConnected extends WalletStatusNotifier {
  @override
  WalletStatus build() =>
      (node: const status.NodeStatus(NodeState.online), epicbox: EpicboxState.offline);
}

/// status.lab.invalid: the lists when given, else no answer.
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

const _btlabs = 'https://node.lab.invalid';
const _epicnet = 'https://node.net.invalid:3413';
const _epiccash = 'https://node.epic.invalid:3413';
const _stack = 'box.stack.invalid';

/// The public lists these tests were written against, as the settings file holds them.
const _nodeServers = [
  (_btlabs, 'BT Labs'),
  (_epicnet, 'EpicNet'),
  (_epiccash, 'Epic Cash'),
  ('https://node.stack.invalid:3413', 'Cypher Stack'),
  ('https://epic-node.pool.example.org', 'Pool'),
];
const _relayServers = [
  ('box.epic.invalid', 'Epic Cash'),
  (_stack, 'Cypher Stack'),
  ('box.net.invalid', 'EpicNet'),
  ('epicbox.pool.example.org', 'Pool'),
  ('box.lab.invalid', 'BT Labs'),
];

/// The settings in use: mainnet, its default node, a relay that is not the default (first of its
/// list), the lists above (or [lists] by kind). Set as the process-wide (and shipped) settings; the sheet's
/// writes then change its container's settings ([_settings]).
MemorySecretStore _store([Map<ServerKind, ServerList> lists = const {}, Map<String, String> extra = const {}]) {
  final base = testSettings().withValues({
    'node.servers': [for (final (u, _) in _nodeServers) u],
    'epicbox.servers': [for (final (h, _) in _relayServers) h],
    'operators': {...testSettings().config.operators, 'pool.example.org': 'Pool'},
  });
  shippedHostSettings = base;
  // The relay in use is the first of the list.
  var s = base.withValues(useServerValues(base, relay: _stack));
  for (final MapEntry(key: kind, value: list) in lists.entries) {
    s = s.withValues(serverListValues(kind, list));
  }
  hostSettings = s;
  return MemorySecretStore({'app.network': 'mainnet', ...extra});
}

/// The settings the sheet's container holds now.
HostSettings _settings(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first)).read(hostSettingsProvider);

ServerList _saved(WidgetTester tester, ServerKind kind) => serverListOf(_settings(tester), kind);

/// A monitor icon on the monitor's own host.
ServerIcon _icon(String hash) => ServerIcon(
  hash: hash,
  urls: {128: Uri.parse('https://status.lab.invalid/api/v1/icons/$hash-128.png')},
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

  /// The Epicbox listener: connected unless a test says otherwise.
  ListenerNotifier Function() listener = _Listener.new;

  List<Override> get overrides => [
    secretStoreProvider.overrideWithValue(store),
    walletServiceProvider.overrideWithValue(service),
    relayDirectoryProvider.overrideWithValue(directory ?? _Directory()),
    relayProbeProvider.overrideWithValue(probe),
    homeProvider.overrideWith(_Home.new),
    listenerProvider.overrideWith(listener),
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

Future<void> _pump(WidgetTester tester, ServerKind kind, _Env env, {bool tall = true, RelaySelection? selection}) async {
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
            selection: selection,
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
const _placeholder = 'Paste or type to filter or add';

/// The Epicbox confirm that a row tap opens.
Finder _confirm() => find.byType(AlertDialog);
Finder _confirmSwitch() => find.byKey(serverListSwitchKey);
Finder _footAction(String label) =>
    find.descendant(of: find.byKey(serverListFootKey), matching: find.text(label));
const _notAddress = 'Not a server address. Use host or host:port.';

void main() {
  group('the list', () {
    testWidgets('node: the built-in nodes in order; the field is empty with its placeholder, '
        'the one in use shows in its row only', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      expect(find.text('Node'), findsOneWidget);
      expect(_fieldText(tester), '');
      expect(find.text(_placeholder), findsOneWidget);
      expect(find.text('In use. Edit it to switch, or type to filter the list.'), findsNothing);
      expect(_order(tester, [_btlabs, _epicnet, _epiccash]), [_btlabs, _epicnet, _epiccash]);
      expect(_row('https://node.stack.invalid:3413'), findsOneWidget);
      expect(_row('https://epic-node.pool.example.org'), findsOneWidget);
      expect(_inRow(_btlabs, 'In use'), findsOneWidget);
      expect(_check(_btlabs), findsOneWidget);
      expect(_check(_epicnet), findsNothing);
      // Nothing typed: no Add, no restore, no match line, a bin on every row.
      expect(find.byKey(serverListAddKey), findsNothing);
      expect(find.text(_noMatch), findsNothing);
      expect(find.byKey(serverListRemoveKey(_btlabs)), findsOneWidget);
      expect(find.byKey(serverListRemoveKey(_epicnet)), findsOneWidget);
      // The list is saved under its own key.
      expect(_saved(tester, ServerKind.node).entries.first, _btlabs);
    });

    testWidgets('epicbox: the list, the default tagged, the field empty, the one in use checked', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      expect(find.text('Epicbox'), findsOneWidget);
      expect(_fieldText(tester), '');
      expect(find.text(_placeholder), findsOneWidget);
      expect(_row(defaultEpicboxHost), findsOneWidget);
      expect(_inRow(defaultEpicboxHost, 'Default'), findsOneWidget);
      expect(_inRow(_stack, 'In use'), findsOneWidget);
      expect(_check(_stack), findsOneWidget);
      expect(_row('box.lab.invalid'), findsOneWidget, reason: 'the push relay');
    });

    testWidgets('epicbox: the address warning on the sheet; a tap opens the confirm with the '
        'title, the line and Cancel / Switch', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      expect(
        find.text('Your Epicbox address changes. Share the new one.'),
        findsOneWidget,
      );
      expect(_confirm(), findsNothing);
      await tester.tap(_row('box.net.invalid'));
      await tester.pumpAndSettle();
      expect(_confirm(), findsOneWidget);
      expect(find.text('Switch to box.net.invalid?'), findsOneWidget);
      expect(
        find.descendant(of: _confirm(), matching: find.text('Your Epicbox address changes. Share the new one.')),
        findsOneWidget,
      );
      expect(find.byKey(serverListCancelKey), findsOneWidget);
      expect(_confirmSwitch(), findsOneWidget);
      expect(env.live, isEmpty);
    });

    testWidgets('epicbox: Cancel keeps the relay; Switch switches', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await tester.tap(_row('box.net.invalid'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(serverListCancelKey));
      await tester.pumpAndSettle();
      expect(_confirm(), findsNothing);
      expect(env.live, isEmpty);
      expect(env.saved, 0);
      expect(_settings(tester).epicboxUse, _stack);

      await tester.tap(_row('box.net.invalid'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmSwitch());
      await tester.pumpAndSettle();
      expect(_confirm(), findsNothing);
      expect(env.saved, 1);
      expect(_settings(tester).epicboxUse, 'box.net.invalid');
      expect(_settings(tester).nodeUse, _btlabs);
      await _timers(tester);
    });

    testWidgets('node: a tap switches at once with no confirm; the foot says so', (tester) async {
      final env = _Env()..liveAnswer = true;
      await _pump(tester, ServerKind.node, env);
      expect(find.text('Your Epicbox address changes. Share the new one.'), findsNothing);
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(_confirm(), findsNothing);
      expect(env.live.single, (nodeUrl: _epicnet, relay: _stack));
      expect(_foot('Switched to node.net.invalid:3413'), findsOneWidget);
      expect(_fieldText(tester), '');
      await _timers(tester);
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
      expect(_row('https://node.stack.invalid:3413'), findsOneWidget);
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
      await _pump(tester, ServerKind.node, _Env()..liveAnswer = true);
      await _type(tester, 'node.net');
      expect(_row(_epicnet), findsOneWidget);
      expect(find.byKey(serverListAddKey), findsOneWidget);
      expect(find.text('Not in the list.'), findsOneWidget);
      expect(find.text(_noMatch), findsNothing);
      // A listed address has no Add row; Done on the field picks it.
      await _type(tester, 'node.net.invalid:3413');
      expect(find.byKey(serverListAddKey), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_foot('Switched to node.net.invalid:3413'), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('a node tap saves the node and keeps the relay; the server in use answers', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      await tester.tap(_row(_btlabs));
      await tester.pumpAndSettle();
      expect(_foot('Already in use.'), findsOneWidget);
      expect(env.saved, 0);
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(env.saved, 1);
      expect(_settings(tester).nodeUse, _epicnet);
      expect(_settings(tester).epicboxUse, _stack);
      await _timers(tester);
    });

    testWidgets('with a wallet open the switch is live: the sheet is not restarted', (
      tester,
    ) async {
      final env = _Env()..liveAnswer = true;
      await _pump(tester, ServerKind.relay, env);
      await tester.tap(_row('box.net.invalid'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmSwitch());
      await tester.pumpAndSettle();
      expect(env.live.single, (nodeUrl: _btlabs, relay: 'box.net.invalid'));
      expect(env.saved, 0);
      expect(_foot('Switched to box.net.invalid'), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('epicbox: the server up but this wallet not connected says so, and Retry '
        'restarts the listener', (tester) async {
      final env = _Env(
        directory: _Directory(
          relayList: const [
            RelayStatus(relay: EpicboxRelay(host: _stack), healthy: true, verified: true),
          ],
        ),
      );
      final listener = _LostListener();
      env.listener = () => listener;
      await tester.pumpWidget(const SizedBox());
      _tallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            ...env.overrides,
            sessionProvider.overrideWith(_OpenSession.new),
            walletStatusProvider.overrideWith(_NotConnected.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ServerListSheet(kind: ServerKind.relay, afterSave: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final line = find.byKey(serverNotConnectedKey);
      expect(line, findsOneWidget);
      expect(
        find.descendant(of: line, matching: find.text('Server up · not connected')),
        findsOneWidget,
      );
      // Right under the server in use, whose health still reads healthy.
      expect(tester.getTopLeft(line).dy, greaterThan(tester.getTopLeft(_row(_stack)).dy));
      await tester.tap(find.descendant(of: line, matching: find.text('Retry')));
      await tester.pump();
      expect(listener.restarts, 1);
    });

    testWidgets('epicbox: connected, or no wallet open, shows no such line', (tester) async {
      final env = _Env(
        directory: _Directory(
          relayList: const [
            RelayStatus(relay: EpicboxRelay(host: _stack), healthy: true, verified: true),
          ],
        ),
      );
      await _pump(tester, ServerKind.relay, env);
      expect(find.byKey(serverNotConnectedKey), findsNothing);
    });

    testWidgets('a tap closes the keyboard', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      await tester.tap(_field());
      await tester.pump();
      expect(_typing(), isTrue);
      await tester.enterText(_field(), 'epicnet');
      await tester.pumpAndSettle();
      await tester.tap(_row(_epicnet));
      await tester.pumpAndSettle();
      expect(_typing(), isFalse);
      expect(env.saved, 1);
      await _timers(tester);
    });
  });

  group('add', () {
    testWidgets('a good node is tested by its tip, added, and offered for a switch', (
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
      expect(_saved(tester, ServerKind.node).entries.last, 'https://node.example.org');
      expect(_foot('Added node.example.org.'), findsOneWidget);
      expect(_footAction('Switch'), findsOneWidget);
      // The field is empty again; the filter is closed.
      expect(_fieldText(tester), '');
      expect(_row(_btlabs), findsOneWidget);
      expect(find.byKey(serverListAddKey), findsNothing);
      // The wallet still uses the old node until Switch.
      expect(_settings(tester).nodeUse, _btlabs);

      await tester.tap(_footAction('Switch'));
      await tester.pumpAndSettle();
      expect(_settings(tester).nodeUse, 'https://node.example.org');
      expect(env.saved, 1);
      await _timers(tester);
    });

    testWidgets('a good relay is probed, added and offered for a switch, which asks first', (
      tester,
    ) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await _type(tester, 'relay.example.org:4443');
      await _tapAdd(tester);

      expect(env.probe.probed.single.label, 'relay.example.org:4443');
      expect(_row('relay.example.org:4443'), findsOneWidget);
      expect(_saved(tester, ServerKind.relay).entries.last, 'relay.example.org:4443');
      expect(_foot('Added relay.example.org:4443.'), findsOneWidget);
      expect(_settings(tester).epicboxUse, _stack);

      await tester.tap(_footAction('Switch'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to relay.example.org:4443?'), findsOneWidget);
      await tester.tap(_confirmSwitch());
      await tester.pumpAndSettle();
      expect(_settings(tester).epicboxUse, 'relay.example.org:4443');
      await _timers(tester);
    });

    for (final kind in ServerKind.values) {
      testWidgets('${kind.name}: text that is no address gets the plain message and nothing is '
          'added or tested', (tester) async {
        final env = _Env();
        await _pump(tester, kind, env);
        final before = _saved(tester, kind).entries;
        await _type(tester, 'not a host!');
        await _tapAdd(tester);

        expect(find.text(_notAddress), findsOneWidget);
        expect(_saved(tester, kind).entries, before);
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
      final before = _saved(tester, ServerKind.node).entries;
      await _type(tester, 'node.example.org');
      await _tapAdd(tester);

      expect(env.service.nodeTipCalls, 1);
      expect(find.textContaining('No answer.'), findsOneWidget);
      expect(_row('https://node.example.org'), findsNothing);
      expect(_saved(tester, ServerKind.node).entries, before);
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
      final before = _saved(tester, ServerKind.relay).entries;
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);

      expect(env.probe.probed, hasLength(1));
      expect(find.text('No answer from this server. Nothing added.'), findsOneWidget);
      expect(_row('relay.example.org'), findsNothing);
      expect(_saved(tester, ServerKind.relay).entries, before);
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
      expect(_foot('Removed node.net.invalid:3413.'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Undo')),
        findsOneWidget,
      );
      final list = _saved(tester, ServerKind.node);
      expect(list.entries, isNot(contains(_epicnet)));

      await tester.tap(
        find.descendant(of: find.byKey(serverListFootKey), matching: find.text('Undo')),
      );
      await tester.pumpAndSettle();
      expect(_row(_epicnet), findsOneWidget);
      expect(_order(tester, [_btlabs, _epicnet, _epiccash]), [_btlabs, _epicnet, _epiccash]);
      expect(
        _saved(tester, ServerKind.node).entries,
        list.entries.toList()..insert(1, _epicnet),
      );
      await _timers(tester);
      expect(find.byKey(serverListFootKey), findsNothing, reason: 'the line goes away by itself');
    });

    testWidgets('without Undo the row stays out once the line is gone', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await tester.tap(find.byKey(serverListRemoveKey('box.net.invalid')));
      await tester.pumpAndSettle();
      expect(_foot('Removed box.net.invalid.'), findsOneWidget);
      await _timers(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(serverListFootKey), findsNothing);
      expect(_row('box.net.invalid'), findsNothing);
      expect(_saved(tester, ServerKind.relay).entries, isNot(contains('box.net.invalid')));
    });

    testWidgets('the server in use refuses: "In use. Switch first."', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.node, env);
      final before = _saved(tester, ServerKind.node);
      // The row in use has no live Remove: the button is disabled and says why.
      final remove = tester.widget<IconButton>(find.byKey(serverListRemoveKey(_btlabs)));
      expect(remove.onPressed, isNull);
      expect(remove.tooltip, 'Switch first');
      await tester.tap(find.byKey(serverListRemoveKey(_btlabs)), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_row(_btlabs), findsOneWidget);
      expect(_saved(tester, ServerKind.node), before);
      await _timers(tester);
    });

  });

  group('the directory', () {
    testWidgets('no answer from the monitor: the built-in list still shows, health unknown', (
      tester,
    ) async {
      await _pump(tester, ServerKind.node, _Env());
      expect(_row(_epicnet), findsOneWidget);
      expect(find.text('status.lab.invalid not reachable; health unknown'), findsOneWidget);
    });
  });

  group('a node on the local network', () {
    const lan = 'http://10.0.0.138:4413';

    testWidgets('is asked from this phone, never judged by the monitor: no answer reads "Not '
        'reachable from this computer"; a public node the monitor finds down "Not answering"', (
      tester,
    ) async {
      final env = _Env(
        store: _store({ServerKind.node: ServerList(entries: [for (final (u, _) in _nodeServers) u, lan], added: const {'10.0.0.138:4413'})}),
        directory: _Directory(
          nodeList: const [
            NodeStatus(url: _epicnet, healthy: false, verified: true, state: NodeHealthState.down),
            // The monitor's word on a local address is never taken.
            NodeStatus(url: lan, healthy: true, verified: false, state: NodeHealthState.healthy),
          ],
        ),
      );
      env.service.nodeTipFails = const NetError('connection refused');
      await _pump(tester, ServerKind.node, env);
      expect(env.service.nodeTipCalls, 1, reason: 'the local node is checked from here, once');
      expect(_inRow(lan, 'Not reachable from this phone'), findsOneWidget);
      expect(_inRow(lan, 'Not answering'), findsNothing);
      expect(_inRow(lan, 'Healthy'), findsNothing);
      expect(_inRow(_epicnet, 'Not answering'), findsOneWidget);
      expect(_inRow(_epicnet, 'Not reachable'), findsNothing);
      await _timers(tester);
    });

    testWidgets('one that answers its check is not marked down', (tester) async {
      final env = _Env(store: _store({ServerKind.node: ServerList(entries: [for (final (u, _) in _nodeServers) u, lan], added: const {'10.0.0.138:4413'})}));
      await _pump(tester, ServerKind.node, env);
      expect(env.service.nodeTipCalls, 1);
      expect(_inRow(lan, 'Not reachable'), findsNothing);
      expect(_inRow(lan, 'Not answering'), findsNothing);
      await _timers(tester);
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
      expect(env.fetched.every((u) => u.scheme == 'https' && u.host == 'status.lab.invalid'), isTrue);
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
      // The user's own server, which the monitor knows (the status site never adds it).
      final env = _Env(
        store: _store({
          ServerKind.relay: ServerList(entries: [_stack, for (final (h, _) in _relayServers) if (h != _stack) h, 'relay.monitor.example']),
        }),
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
              relay: const EpicboxRelay(host: 'box.net.invalid'),
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
      expect(image('box.net.invalid'), findsOneWidget);
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
            'no overflow; a row below the fold is reachable; the confirm is in reach; Add answers',
            (tester) async {
              final env = _Env();
              await open(tester, kind, env, size: size, scale: scale);
              expect(find.byType(ServerListSheet), findsOneWidget);
              expect(tester.takeException(), isNull);

              // The epicnet row sits below the fold on the small phone.
              final target = kind == ServerKind.node ? _epicnet : 'box.net.invalid';
              await tester.scrollUntilVisible(_row(target), 100, scrollable: list);
              // Built in the list's cache is not yet on the screen.
              await tester.ensureVisible(_row(target));
              await tester.pumpAndSettle();
              if (kind == ServerKind.node) {
                // A tap would switch and restart the app flow here; the bin's foot line with
                // its Undo must be in reach instead.
                await tester.tap(find.byKey(serverListRemoveKey(target)));
                await tester.pumpAndSettle();
                final undo = tester.getRect(_footAction('Undo'));
                expect(undo.bottom, lessThanOrEqualTo(size.height));
                expect(undo.top, greaterThanOrEqualTo(0));
                await _timers(tester);
              } else {
                await tester.tap(_row(target));
                await tester.pumpAndSettle();
                // Switch and Cancel are in view at once.
                final button = tester.getRect(_confirmSwitch());
                expect(button.height, greaterThanOrEqualTo(36));
                expect(button.bottom, lessThanOrEqualTo(size.height));
                expect(button.top, greaterThanOrEqualTo(0));
                await tester.tap(find.byKey(serverListCancelKey));
                await tester.pumpAndSettle();
                expect(_confirm(), findsNothing);
              }

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
            ServerKind.node: ServerList(
              entries: [
                for (final (u, _) in _nodeServers) u,
                for (var i = 0; i < 12; i++) 'https://node$i.example.org',
              ],
            ),
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

  group('selection mode', () {
    const epiccash = 'box.epic.invalid';
    const floo = 'box.lab.invalid';
    const epicnet = 'box.net.invalid';
    const pool = 'epicbox.pool.example.org';
    const defaults = [epiccash, _stack, floo];
    final calls = <List<String>>[];

    Future<void> pumpSelection(WidgetTester tester, _Env env, List<String> chosen) async {
      calls.clear();
      await _pump(
        tester,
        ServerKind.relay,
        env,
        selection: RelaySelection(
          limit: 3,
          chosen: chosen,
          defaults: defaults,
          onChanged: calls.add,
          title: 'Connection servers',
          note: 'Choose up to 3.',
        ),
      );
    }

    Finder box(String value) => find.descendant(of: _row(value), matching: find.byType(Checkbox));
    bool ticked(WidgetTester tester, String value) => tester.widget<Checkbox>(box(value)).value!;

    testWidgets('a checkbox per row, the defaults first and badged, the count and the note', (tester) async {
      await pumpSelection(tester, _Env(), [epiccash, _stack]);
      expect(find.text('Connection servers'), findsOneWidget);
      expect(find.byKey(serverListNoteKey), findsOneWidget);
      expect(find.text('Choose up to 3.'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(_order(tester, [epiccash, _stack, floo, epicnet, pool]), [epiccash, _stack, floo, epicnet, pool]);
      expect(ticked(tester, epiccash), isTrue);
      expect(ticked(tester, _stack), isTrue);
      expect(ticked(tester, floo), isFalse);
      expect(find.descendant(of: _row(floo), matching: find.text('Default')), findsOneWidget);
      expect(find.descendant(of: _row(epicnet), matching: find.text('Default')), findsNothing);
      // The one-server picker's warning and Current card are not here.
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byKey(serverListResetKey), findsOneWidget, reason: 'floo is a default and not chosen');
    });

    testWidgets('a tick applies at once with a foot line and Undo; the fourth is refused', (tester) async {
      await pumpSelection(tester, _Env(), [epiccash, _stack]);
      await tester.tap(_row(epicnet));
      await tester.pumpAndSettle();
      expect(calls.last, [epiccash, _stack, epicnet]);
      expect(ticked(tester, epicnet), isTrue);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(_foot('Chosen. Wallets that also use $epicnet find you there.'), findsOneWidget);

      await tester.tap(_row(pool));
      await tester.pumpAndSettle();
      expect(calls.length, 1, reason: 'a refused tick changes nothing');
      expect(ticked(tester, pool), isFalse);
      expect(_foot('3 of 3 chosen. Untick one to choose another.'), findsOneWidget);

      await tester.tap(_row(epicnet));
      await tester.pumpAndSettle();
      expect(calls.last, [epiccash, _stack]);
      expect(_foot('Unticked $epicnet.'), findsOneWidget);
      await tester.tap(_footAction('Undo'));
      await tester.pumpAndSettle();
      expect(calls.last, [epiccash, _stack, epicnet]);
      expect(ticked(tester, epicnet), isTrue);
      await _timers(tester);
    });

    testWidgets('the last one stays; a chosen row is not removed', (tester) async {
      await pumpSelection(tester, _Env(), [epiccash]);
      await tester.tap(_row(epiccash));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(_foot('Keep at least one.'), findsOneWidget);

      await tester.tap(find.byKey(serverListRemoveKey(epiccash)));
      await tester.pumpAndSettle();
      expect(_foot('Chosen. Untick first.'), findsOneWidget);
      expect(_row(epiccash), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('Reset to defaults shows while the set differs, then goes; Undo brings the set back', (tester) async {
      await pumpSelection(tester, _Env(), [epicnet, _stack]);
      expect(find.byKey(serverListResetKey), findsOneWidget);
      await tester.tap(find.byKey(serverListResetKey));
      await tester.pumpAndSettle();
      expect(calls.last, defaults);
      expect(find.byKey(serverListResetKey), findsNothing);
      expect(_foot('Reset to defaults.'), findsOneWidget);
      await tester.tap(_footAction('Undo'));
      await tester.pumpAndSettle();
      expect(calls.last, [epicnet, _stack]);
      expect(find.byKey(serverListResetKey), findsOneWidget);
      await _timers(tester);
    });

    testWidgets('a typed server is tested, added "Added by you" and ticked while there is room', (tester) async {
      final env = _Env();
      await pumpSelection(tester, env, [epiccash]);
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);
      expect(calls.last, [epiccash, 'relay.example.org']);
      expect(_foot('Added relay.example.org. Wallets that also use it find you there.'), findsOneWidget);
      expect(find.descendant(of: _row('relay.example.org'), matching: find.text('Added by you')), findsOneWidget);
      expect(_saved(tester, ServerKind.relay).isAddedByUser(ServerKind.relay, 'relay.example.org'), isTrue);
      await _timers(tester);
    });

    testWidgets('a typed server at the limit is added but not ticked', (tester) async {
      await pumpSelection(tester, _Env(), defaults);
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);
      expect(calls, isEmpty);
      expect(ticked(tester, 'relay.example.org'), isFalse);
      expect(_foot('Added relay.example.org. Untick one to choose it.'), findsOneWidget);
      await _timers(tester);
    });
  });

  group('the origin of a row', () {
    testWidgets('a typed server is "Added by you" on the Epicbox page; a listed one is not', (tester) async {
      final env = _Env();
      await _pump(tester, ServerKind.relay, env);
      await _type(tester, 'relay.example.org');
      await _tapAdd(tester);
      expect(find.descendant(of: _row('relay.example.org'), matching: find.text('Added by you')), findsOneWidget);
      expect(find.descendant(of: _row('box.net.invalid'), matching: find.text('Added by you')), findsNothing);
      await _timers(tester);
    });
  });

  test('serverHost reads the host of a node address', () {
    expect(serverHost(_epicnet), 'node.net.invalid:3413');
    expect(serverHost(_btlabs), 'node.lab.invalid');
  });
}
