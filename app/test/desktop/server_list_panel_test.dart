// SPDX-License-Identifier: Apache-2.0
// The desktop's Node and Epicbox lists (server_list_panel.dart, server_lists.dart): the field
// at the top starts empty and filters; a Node row switches at once, an Epicbox row asks in a
// dialog; Add shows when nothing matches, says plainly
// when the text is no address, tests the server and offers the switch, and adds nothing when
// the test fails; the bin with Undo, the refusal on the row in use, Restore only while a public
// server is removed; the directory's new servers join and removed ones stay out; the first
// list carries the old My nodes and removedNodes; icons with initials as the fallback; only the
// rows scroll; in Setup a pick chooses.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/server_lists.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/server_icons.dart';
import 'package:epic_wallet/src/ui/server_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fixture PNG for an icon URL, by its hash.
Future<Uint8List?> _fixtureIcon(Uri url) async {
  final hash = RegExp(r'([0-9a-f]{20})-\d+\.png$').firstMatch(url.path)?.group(1);
  final f = File('test/fixtures/icons/$hash-128.png');
  return f.existsSync() ? f.readAsBytesSync() : null;
}

/// The mock wallet with its own LAN node (http://10.0.1.24:3413) not answering its check.
class _LanDown extends MockDeskWallet {
  _LanDown() : super(delay: Duration.zero);

  @override
  Future<List<NodeServer>> nodes() async => [
    for (final n in await super.nodes())
      n.url.contains('192.168.') ? NodeServer(url: n.url, label: n.label, health: ServiceHealth.down, own: true) : n,
  ];
}

const _btlabs = 'https://node.btlabs.uk';
const _epicnet = 'https://node.epicnet.us:3413';
const _epiccash = 'https://node.epiccash.com:3413';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late MemorySecretStore secrets;
  late FakeRelayProbe probe;

  ProviderContainer make({Map<String, dynamic>? prefs}) => ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      deskNodeProvider.overrideWithValue(MockDeskNode()),
      deskStoreProvider.overrideWithValue(DeskStore(secrets)),
      deskBootProvider.overrideWithValue(DeskBoot(prefs: prefs)),
      relayProbeProvider.overrideWithValue(probe),
      serverIconFetchProvider.overrideWithValue(_fixtureIcon),
    ],
  );

  setUp(() {
    secrets = MemorySecretStore();
    probe = FakeRelayProbe();
    container = make();
  });

  tearDown(() => container.dispose());

  Future<void> settle(WidgetTester tester, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
  }

  Future<void> show(WidgetTester tester, Widget screen, {Size size = const Size(1280, 1100)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
      ),
    );
    await settle(tester, 10);
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
  }

  final field = find.descendant(of: find.byKey(const ValueKey('server-list-field')), matching: find.byType(EditableText));
  Finder row(String value) => find.byKey(ValueKey('server-row-$value'));
  String helper(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('server-list-helper'))).data!;
  List<String> nodes() => container.read(deskServerListProvider(ServerKind.node))!.entries;

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(field, text);
    await settle(tester, 2);
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await settle(tester);
  }

  group('selection mode', () {
    const epiccash = 'epicbox.epiccash.com';
    const stack = 'epicbox.stackwallet.com';
    const floo = 'epicbox.btlabs.uk';
    const epicnet = 'epicbox.epicnet.us';
    const defaults = [epiccash, stack, floo];
    final calls = <List<String>>[];

    Future<void> pumpSelection(WidgetTester tester, List<String> chosen) => show(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 520,
          child: ServerListPanel(
            kind: ServerKind.relay,
            label: 'Connection servers',
            value: '',
            fieldText: chosen.join(', '),
            servers: [for (final v in [...defaults, epicnet]) PanelServer.bare(ServerKind.relay, v)],
            source: const DeskServerSource(public: [epiccash, stack, epicnet, floo]),
            onChoose: (_) async {},
            onTest: (_) async => null,
            openInitially: true,
            selection: RelaySelection(
              limit: 3,
              chosen: chosen,
              defaults: defaults,
              onChanged: calls.add,
              title: 'Connection servers',
              note: 'Choose up to 3.',
            ),
          ),
        ),
      ),
    );

    bool ticked(WidgetTester tester, String value) {
      final box = find.descendant(of: row(value), matching: find.byIcon(Icons.check));
      return box.evaluate().isNotEmpty;
    }

    testWidgets('a click ticks at once with a foot line and Undo; the fourth is refused; the last stays', (tester) async {
      calls.clear();
      await pumpSelection(tester, [epiccash, stack]);
      expect(find.text('Choose up to 3.'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(ticked(tester, epiccash), isTrue);
      expect(ticked(tester, floo), isFalse);
      // The defaults come first, in their order; Default is on each.
      expect(tester.getTopLeft(row(floo)).dy, lessThan(tester.getTopLeft(row(epicnet)).dy));
      expect(find.descendant(of: row(floo), matching: find.text('Default')), findsOneWidget);
      expect(find.descendant(of: row(epicnet), matching: find.text('Default')), findsNothing);

      await tap(tester, row(floo));
      expect(calls.last, [epiccash, stack, floo]);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.text('Chosen $floo.'), findsOneWidget);

      await tap(tester, row(epicnet));
      expect(calls.length, 1, reason: 'a refused tick changes nothing');
      expect(find.text('3 of 3 chosen. Untick one to choose another.'), findsOneWidget);

      await tap(tester, row(floo));
      expect(calls.last, [epiccash, stack]);
      await tap(tester, find.byKey(const ValueKey('server-list-undo')));
      expect(calls.last, [epiccash, stack, floo]);

      await tap(tester, row(stack));
      await tap(tester, row(floo));
      expect(calls.last, [epiccash]);
      await tap(tester, row(epiccash));
      expect(find.text('Keep at least one.'), findsOneWidget);
      expect(calls.last, [epiccash]);

      await tap(tester, find.byKey(ValueKey('server-row-remove-$epiccash')));
      expect(find.text('Chosen. Untick first.'), findsOneWidget);
      await end(tester);
    });

    testWidgets('Reset to defaults shows while the set differs', (tester) async {
      calls.clear();
      await pumpSelection(tester, [epicnet, stack]);
      expect(find.byKey(const ValueKey('server-list-reset')), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('server-list-reset')));
      expect(calls.last, defaults);
      expect(find.byKey(const ValueKey('server-list-reset')), findsNothing);
      expect(find.text('Reset to defaults.'), findsOneWidget);
      await end(tester);
    });
  });

  testWidgets('the field starts empty with its placeholder; typing filters by host or operator', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    final edit = tester.widget<EditableText>(field);
    expect(edit.controller.text, '', reason: 'the node in use shows in its row, never in the field');
    expect(find.text('Paste or type to filter or add'), findsOneWidget);
    expect(find.byKey(const ValueKey('server-list-helper')), findsNothing);
    for (final v in [_btlabs, _epicnet, _epiccash, 'http://10.0.1.24:3413']) {
      expect(row(v), findsOneWidget, reason: v);
    }

    await type(tester, 'cypher');
    expect(row('https://epic.stackwallet.com:3413'), findsOneWidget);
    expect(row(_btlabs), findsNothing);
    expect(helper(tester), '1 match.');
    expect(find.byKey(const ValueKey('server-list-add')), findsNothing, reason: 'something matches and it is no address');

    await type(tester, 'zzz');
    expect(find.text('No match.'), findsOneWidget, reason: 'one No match line, never two');
    expect(find.byKey(const ValueKey('server-list-add')), findsOneWidget, reason: 'Add shows as soon as nothing matches');
    await end(tester);
  });

  testWidgets('Add: a good node is tested, added, and the switch offered; Switch moves the wallet', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    await type(tester, 'node.example.org:3413');
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    expect(nodes(), contains('https://node.example.org:3413'));
    expect(row('https://node.example.org:3413'), findsOneWidget);
    expect(find.text('Added node.example.org:3413.'), findsOneWidget);
    expect(tester.widget<EditableText>(field).controller.text, '');
    await tap(tester, find.byKey(const ValueKey('server-list-line-switch')));
    await settle(tester, 10);
    expect(container.read(deskProvider).status!.node.url, 'https://node.example.org:3413');
    await end(tester);
  });

  testWidgets('Add: text that is no address says so plainly; a node that does not answer adds nothing', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    final before = [...nodes()];
    await type(tester, 'my home node');
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    expect(helper(tester), 'Not a server address. Use host or host:port.');
    expect(nodes(), before);

    await type(tester, 'bad.example.org:3413');
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    await settle(tester);
    expect(helper(tester), 'No answer from this node. Nothing added.');
    expect(nodes(), before);
    expect(find.byKey(const ValueKey('server-list-switch')), findsNothing);
    await end(tester);
  });

  testWidgets('a Node row switches at once, with no dialog; the foot says so and the field stays empty', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    await tap(tester, row(_epicnet));
    await settle(tester, 10);
    expect(find.byType(Dialog), findsNothing);
    expect(container.read(deskProvider).status!.node.url, _epicnet);
    expect(find.text('Switched to node.epicnet.us:3413'), findsOneWidget);
    expect(tester.widget<EditableText>(field).controller.text, '');
    await end(tester);
  });

  testWidgets('the bin removes with Undo; Restore shows only while a public server is removed', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    final at = nodes().indexOf(_epiccash);
    expect(find.byKey(const ValueKey('server-list-restore')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('server-row-remove-$_epiccash')));
    expect(row(_epiccash), findsNothing);
    expect(find.text('Removed node.epiccash.com:3413.'), findsOneWidget);
    expect(find.text('Restore removed servers · 1 removed'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('server-list-undo')));
    expect(nodes().indexOf(_epiccash), at, reason: 'back where it was');
    expect(find.byKey(const ValueKey('server-list-restore')), findsNothing);

    await tap(tester, find.byKey(const ValueKey('server-row-remove-$_epiccash')));
    await tap(tester, find.byKey(const ValueKey('server-list-restore')));
    expect(nodes(), contains(_epiccash));
    expect(find.byKey(const ValueKey('server-list-restore')), findsNothing);
    expect(find.text('Removed servers restored.'), findsOneWidget);
    await end(tester);
  });

  testWidgets('the row in use has no live bin: In use. Switch first.', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    // The bin is shown disabled and says why.
    final bin = tester.widget<EIconButton>(find.byKey(const ValueKey('server-row-remove-$_btlabs')));
    expect(bin.onPressed, isNull);
    expect(bin.label, 'In use. Switch first.');
    expect(nodes(), contains(_btlabs));
    expect(container.read(deskProvider).status!.node.url, _btlabs, reason: 'never a silent switch');
    await end(tester);
  });

  testWidgets('a local node that does not answer its check reads "Not reachable from this computer"; a public one "Not responding"', (tester) async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        deskApiProvider.overrideWithValue(_LanDown()),
        deskNodeProvider.overrideWithValue(MockDeskNode()),
        deskStoreProvider.overrideWithValue(DeskStore(secrets)),
        deskBootProvider.overrideWithValue(const DeskBoot()),
        relayProbeProvider.overrideWithValue(probe),
        serverIconFetchProvider.overrideWithValue(_fixtureIcon),
      ],
    );
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    Finder says(String value, String text) => find.descendant(of: row(value), matching: find.textContaining(text, findRichText: true));
    expect(says('http://10.0.1.24:3413', 'Not reachable from this computer'), findsOneWidget);
    expect(says('http://10.0.1.24:3413', 'Not responding'), findsNothing);
    expect(says('https://epic-node.iniaku.my.id', 'Not responding'), findsOneWidget);
    expect(says('https://epic-node.iniaku.my.id', 'Not reachable'), findsNothing);
    await end(tester);
  });

  testWidgets('an icon where the monitor has one, the monitor name\'s initials where not', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);
    expect(find.descendant(of: row(_btlabs), matching: find.byKey(ServerTileView.imageKey)), findsOneWidget);
    expect(find.descendant(of: row(_epicnet), matching: find.byKey(ServerTileView.imageKey)), findsNothing);
    expect(find.descendant(of: row(_epicnet), matching: find.text('EU')), findsOneWidget, reason: 'status.btlabs.uk names it epicnet.us');
    expect(find.descendant(of: row(_epicnet), matching: find.text('EpicNet', findRichText: true)), findsNothing);
    await end(tester);
  });

  testWidgets('only the rows scroll: the field stays put', (tester) async {
    await show(tester, const SettingsNodeScreen(arg: NodeDemo.comboOpen), size: const Size(1280, 560));
    final fieldAt = tester.getTopLeft(field);
    final list = find.ancestor(of: row(_btlabs), matching: find.byType(Scrollable)).first;
    final scrollable = tester.state<ScrollableState>(list);
    await tester.drag(list, const Offset(0, -120));
    await settle(tester, 2);
    expect(tester.getTopLeft(field), fieldAt);
    expect(scrollable.position.pixels, greaterThan(0), reason: 'the rows moved');
    await end(tester);
  });

  testWidgets('Epicbox: a pick opens the confirm; Cancel keeps the relay; a relay that does not answer adds nothing; Switch switches', (tester) async {
    // Transactions has the payment methods and Send above the Epicbox panel now: a taller
    // window keeps the panel's foot (Added …, Switch) on screen.
    await show(tester, const SettingsReceivingScreen(arg: ReceivingDemo.comboOpen), size: const Size(1280, 1500));
    const warning = 'Changing the server changes your Epicbox address. Share the new one.';
    expect(find.text(warning), findsOneWidget);
    final before = container.read(deskProvider).status!.epicbox.domain;
    await tap(tester, row('epicbox.stackwallet.com'));
    expect(find.byType(EDialog), findsOneWidget);
    expect(find.text('Switch to epicbox.stackwallet.com?'), findsOneWidget);
    expect(find.text('Your Epicbox address will change. Share the new one.'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('server-list-cancel')));
    expect(find.byType(EDialog), findsNothing);
    expect(container.read(deskProvider).status!.epicbox.domain, before, reason: 'Cancel keeps the relay');

    tester.state<ServerListPanelState>(find.byType(ServerListPanel)).open();
    await settle(tester);
    probe.answer = false;
    await type(tester, 'relay.example.org');
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    await settle(tester);
    expect(probe.probed.single.host, 'relay.example.org');
    expect(helper(tester), 'No answer from this server. Nothing added.');
    expect(container.read(deskServerListProvider(ServerKind.relay))!.entries, isNot(contains('relay.example.org')));

    probe.answer = true;
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    await settle(tester);
    expect(container.read(deskServerListProvider(ServerKind.relay))!.entries, contains('relay.example.org'));
    await tap(tester, find.byKey(const ValueKey('server-list-line-switch')));
    expect(find.text('Switch to relay.example.org?'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('server-list-switch')));
    await settle(tester, 10);
    expect(container.read(deskProvider).status!.epicbox.domain, 'relay.example.org');
    await end(tester);
  });

  testWidgets('chooseOnly (Setup): a pick chooses at once; Add tests, then chooses', (tester) async {
    final chosen = <String>[];
    final tested = <String>[];
    await show(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 520,
          child: ServerListPanel(
            kind: ServerKind.node,
            label: 'Node server',
            value: '',
            fieldText: 'Pick a node',
            servers: const [PanelServer(value: _btlabs, host: 'node.btlabs.uk')],
            source: const DeskServerSource(public: [_btlabs]),
            chooseOnly: true,
            openInitially: true,
            onChoose: (v) async => chosen.add(v),
            onTest: (v) async {
              tested.add(v);
              return null;
            },
          ),
        ),
      ),
    );
    await tap(tester, row(_btlabs));
    expect(chosen, [_btlabs]);
    expect(find.byKey(const ValueKey('server-list-switch')), findsNothing, reason: 'no Switch step');
    expect(field, findsNothing, reason: 'closed');

    await tap(tester, find.text('Pick a node'));
    await type(tester, '10.0.1.30:3413');
    await tap(tester, find.byKey(const ValueKey('server-list-add')));
    expect(tested, ['http://10.0.1.30:3413'], reason: 'the local network answers plain http');
    expect(chosen.last, 'http://10.0.1.30:3413');
    await end(tester);
  });

  group('the stored list', () {
    test('directory servers join as they are seen; removed ones stay out until restored', () async {
      final n = container.read(deskServerListProvider(ServerKind.relay).notifier);
      await n.sync(const DeskServerSource(public: ['a.example', 'b.example'], inUse: 'a.example'));
      expect(n.state!.entries, ['a.example', 'b.example']);
      await n.remove('b.example');
      await n.sync(const DeskServerSource(public: ['a.example', 'b.example', 'c.example'], inUse: 'a.example'));
      expect(n.state!.entries, ['a.example', 'c.example']);
      expect(n.state!.restorable(ServerKind.relay, ['a.example', 'b.example', 'c.example']), ['b.example']);
      await n.restore(['a.example', 'b.example', 'c.example']);
      expect(n.state!.entries, ['a.example', 'c.example', 'b.example']);
      expect(await DeskStore(secrets).serverList(ServerKind.relay, 'mainnet'), n.state, reason: 'kept in the desk store');
    });

    test('a store that cannot be written: the list still shows, sync never throws (WIN-4)', () async {
      secrets = _RefusingStore();
      final c = make();
      addTearDown(c.dispose);
      final n = c.read(deskServerListProvider(ServerKind.relay).notifier);
      await n.sync(const DeskServerSource(public: ['a.example'], inUse: 'a.example'));
      expect(n.state!.entries, ['a.example']);
    });

    test('the first list carries the old My nodes and removedNodes; later starts read what was kept', () async {
      final old = [
        const NodeServer(url: _btlabs, label: 'BT Labs'),
        const NodeServer(url: _epiccash, label: 'Epic Cash'),
        const NodeServer(url: 'http://10.0.1.24:3413', label: 'Home node', own: true),
        const NodeServer(url: 'http://10.0.0.9:3413', label: 'Office', own: true),
      ];
      final n = container.read(deskServerListProvider(ServerKind.node).notifier);
      await n.sync(nodeSource(old, removedNodes: {_epiccash, 'http://10.0.0.9:3413'}, inUse: _btlabs));
      expect(n.state!.entries, [_btlabs, 'http://10.0.1.24:3413'], reason: 'own nodes kept, removed ones out');
      expect(n.state!.restorable(ServerKind.node, [_btlabs, _epiccash]), [_epiccash]);

      // The next start reads the kept list: nothing seeds again.
      final again = make();
      addTearDown(again.dispose);
      final m = again.read(deskServerListProvider(ServerKind.node).notifier);
      await m.sync(nodeSource(old, inUse: _btlabs));
      expect(m.state!.entries, [_btlabs, 'http://10.0.1.24:3413']);
    });

    test('an own node keeps its label as the row\'s operator', () {
      final rows = nodePanelRows(const [NodeServer(url: 'http://10.0.1.24:3413', label: 'Home node', own: true)], labels: const {'http://10.0.1.24:3413': 'Garage'});
      expect(rows.single.operator, 'Garage');
      expect(nodePanelRows(const [NodeServer(url: 'http://10.0.1.24:3413', label: 'Home node', own: true)]).single.operator, 'Home node');
    });
  });
}

/// A secret store whose writes fail, as a read-only store file does on Windows.
class _RefusingStore extends MemorySecretStore {
  @override
  Future<void> write(String key, String value) async => throw const FileSystemException('MoveFileEx failed (5)');
}
