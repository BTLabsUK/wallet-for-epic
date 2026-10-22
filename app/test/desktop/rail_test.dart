// The sidebar rail (spec §5, §16): Node, a divider, Epicbox, HTTP, Tor; every row 40 u in
// every state, so the rail never changes height; the Node row's twelve states; no address,
// URL or port on a row.
import 'package:epic_wallet/src/desktop/app/rail.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mock wallet with a fixed status ([status] null: nothing known yet).
class _Wallet extends MockDeskWallet {
  _Wallet(this.fixed) : super(delay: Duration.zero);

  final ServiceStatus? fixed;

  @override
  Future<ServiceStatus> status() async => fixed ?? await super.status();
}

ServiceStatus _status({
  ServiceHealth node = ServiceHealth.ok,
  ServiceHealth epicbox = ServiceHealth.ok,
  ServiceHealth http = ServiceHealth.off,
  ServiceHealth tor = ServiceHealth.off,
  String? httpProblem,
  int? torProgress,
}) => ServiceStatus(
  node: const NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs'),
  nodeHealth: node,
  nodeHeight: 2914414,
  epicbox: const EpicboxServer(domain: 'epicbox.stackwallet.com'),
  epicboxHealth: epicbox,
  httpListener: http,
  httpProblem: httpProblem,
  tor: tor,
  torProgress: torProgress,
  torCanSend: tor == ServiceHealth.ok,
);

final _fixtures = <String, ServiceStatus?>{
  'all ok': _status(),
  'http on, tor checking': _status(http: ServiceHealth.ok, tor: ServiceHealth.checking, torProgress: 40),
  'node slow, epicbox down, http down, tor down': _status(
    node: ServiceHealth.slow,
    epicbox: ServiceHealth.down,
    http: ServiceHealth.down,
    httpProblem: 'Port 3415 in use',
    tor: ServiceHealth.down,
  ),
  'all off': _status(node: ServiceHealth.off, epicbox: ServiceHealth.off),
  'node down': _status(node: ServiceHealth.down),
  'nothing known': null,
};

void main() {
  Future<ProviderContainer> show(WidgetTester tester, ServiceStatus? status, {bool compact = false, bool refresh = true, double textScale = 1}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet(status))]);
    addTearDown(container.dispose);
    if (refresh) await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
          home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: compact ? 72 : 200, child: ServiceRows(compact: compact)))),
        ),
      ),
    );
    // A millisecond runs riverpod's zero-delay dispose task of a previous container.
    await tester.pump(const Duration(milliseconds: 1));
    return container;
  }

  group('rail height', () {
    testWidgets('identical for every status, every row 40 u, nothing sensitive on a row', (tester) async {
      Size? first;
      for (final e in _fixtures.entries) {
        await show(tester, e.value, refresh: e.value != null);
        final rail = find.byKey(const ValueKey('rail'));
        expect(rail, findsOneWidget, reason: e.key);
        final size = tester.getSize(rail);
        first ??= size;
        expect(size, first, reason: '${e.key}: the rail changed height');
        final rows = find.byType(RailRow);
        expect(rows, findsNWidgets(2 + (DeskFeatures.httpDirect ? 1 : 0) + (DeskFeatures.tor ? 1 : 0)), reason: e.key);
        for (final r in rows.evaluate()) {
          expect(tester.getSize(find.byWidget(r.widget)).height, 40.u, reason: e.key);
        }
        for (final t in find.descendant(of: rail, matching: find.byType(Text)).evaluate()) {
          final s = (t.widget as Text).data ?? (t.widget as Text).textSpan?.toPlainText() ?? '';
          expect(s, isNot(contains('http://')), reason: e.key);
          expect(s, isNot(contains('.onion')), reason: e.key);
          expect(s, isNot(contains('@')), reason: e.key);
          expect(s, isNot(matches(RegExp(r'Port \d'))), reason: e.key);
        }
      }
      // Lets riverpod's zero-delay dispose task of the last container run before the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('nothing known yet: the rows say Checking with no bars', (tester) async {
      await show(tester, null, refresh: false);
      expect(find.text('Node'), findsOneWidget);
      expect(find.text('Epicbox'), findsOneWidget);
      final bars = tester.widgetList<ESignalBars>(find.byType(ESignalBars)).map((b) => b.state);
      expect(bars.every((s) => s == EState.off), isTrue);
    });

    testWidgets('compact: same rows, same height, icons with bars', (tester) async {
      await show(tester, _status(), compact: true);
      for (final r in find.byType(RailRow).evaluate()) {
        expect(tester.getSize(find.byWidget(r.widget)).height, 40.u);
      }
      expect(find.text('Node'), findsNothing);
      expect(find.byIcon(EIcons.node), findsOneWidget);
    });

    testWidgets('a click opens that service’s settings section', (tester) async {
      final c = await show(tester, _status());
      await tester.tap(find.text('Epicbox'));
      await tester.pump();
      expect(c.read(settingsPrefsProvider).jump?.section, SettingsJump.epicbox);
      await tester.tap(find.text('Node'));
      await tester.pump();
      expect(c.read(settingsPrefsProvider).jump?.section, SettingsJump.node);
    });

    testWidgets('hosts drop the row name and never show a scheme or port', (tester) async {
      await show(tester, _status());
      expect(find.text('btlabs.uk'), findsOneWidget);
      expect(find.text('stackwallet.com'), findsOneWidget);
    });

    testWidgets('at 1.5× OS text scale the rows stay 40 u and nothing overflows', (tester) async {
      await show(tester, _status(http: ServiceHealth.ok, tor: ServiceHealth.checking, torProgress: 40), textScale: 1.5);
      for (final r in find.byType(RailRow).evaluate()) {
        expect(tester.getSize(find.byWidget(r.widget)).height, 40.u);
      }
      expect(tester.takeException(), isNull);
      await show(tester, _status(), compact: true, textScale: 1.5);
      for (final r in find.byType(RailRow).evaluate()) {
        expect(tester.getSize(find.byWidget(r.widget)).height, 40.u);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('a node down for under 30 s is not yet Not answering; after 30 s it is, since HH:MM', (tester) async {
      var now = DateTime(2026, 10, 22, 14, 2, 0);
      railClock = () => now;
      addTearDown(() => railClock = DateTime.now);
      await show(tester, _status(node: ServiceHealth.down));
      RailItem node() => tester.widget<RailRow>(find.byType(RailRow).first).item;
      expect(node().word, isNot('Not answering'), reason: 'a blip never flashes red');
      expect(node().marker, isNull);
      now = now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      expect(node().word, 'Not answering');
      expect(node().marker, 'no answer');
      expect(node().lines.first, 'node.btlabs.uk · since 14:02');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('the local node with the wallet on a public node', () {
    const public = 'https://node.epiccash.com:3413';
    test('starting, stopped and failed name the node in use; the local address does not', () {
      for (final phase in [LocalNodePhase.starting, LocalNodePhase.stopped, LocalNodePhase.error]) {
        final v = localNodeView(mockLocalNode(phase, failure: phase == LocalNodePhase.error ? NodeFailure.exited : null), fallbackUrl: public);
        expect(v.host, 'epiccash.com', reason: phase.name);
        expect(v.marker, isNotNull, reason: phase.name);
        expect(v.lines.last, anyOf('Using node.epiccash.com until it is synced.', 'Using node.epiccash.com meanwhile.'), reason: phase.name);
        expect(localNodeView(mockLocalNode(phase), fallbackUrl: 'http://127.0.0.1:3413').host, 'Local node', reason: phase.name);
      }
      expect(localNodeView(mockLocalNode(LocalNodePhase.synced), fallbackUrl: 'http://127.0.0.1:3413').lines.length, 2);
    });

    testWidgets('the rail reads the wallet’s actual node URL from the status', (tester) async {
      final c = await show(tester, _status(node: ServiceHealth.slow));
      c.read(settingsPrefsProvider.notifier).set(c.read(settingsPrefsProvider).copyWith(builtin: true));
      await tester.pump();
      // The local node's stream yields its first state a microtask later.
      await tester.pump();
      final node = tester.widget<RailRow>(find.byType(RailRow).first).item;
      expect(node.second, startsWith('btlabs.uk'), reason: 'the status says the wallet reads node.btlabs.uk');
      expect(node.lines, contains('Using node.btlabs.uk meanwhile.'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('the Node row (§16)', () {
    const url = 'https://node.epiccash.com:3413';
    final since = DateTime(2026, 10, 22, 14, 2);
    final fixtures = <String, (NodeView, String, EState, String?)>{
      'remote at tip, version current': (remoteNodeView(url, mockNodeInfo(url, latencyMs: 722)), 'Synced', EState.ok, null),
      'remote older version': (remoteNodeView(url, mockNodeInfo(url, version: '4.1.0')), 'Synced', EState.warn, null),
      'remote behind': (remoteNodeView(url, mockNodeInfo(url, behind: 12)), 'Behind', EState.warn, '12 behind'),
      'remote no answer': (remoteNodeView(url, mockNodeInfo(url, state: NodeHealthState.down), downSince: since), 'Not answering', EState.risk, 'no answer'),
      'nothing known': (remoteNodeView(url, null), 'Checking', EState.off, null),
      'local starting': (localNodeView(mockLocalNode(LocalNodePhase.starting)), 'Starting', EState.warn, 'starting'),
      'local syncing, fallback': (
        localNodeView(
          mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: 3764975, eta: const Duration(hours: 3)),
          fallbackUrl: defaultFallbackNodeUrl,
        ),
        'Syncing',
        EState.warn,
        '12 %',
      ),
      'local syncing, no fallback': (localNodeView(mockLocalNode(LocalNodePhase.syncing, overall: 0.12)), 'Syncing', EState.warn, '12 %'),
      'local synced': (localNodeView(mockLocalNode(LocalNodePhase.synced)), 'Synced', EState.ok, null),
      'local stalled': (localNodeView(mockLocalNode(LocalNodePhase.error, stalled: true)), 'Stalled', EState.risk, 'stalled'),
      'local failed': (localNodeView(mockLocalNode(LocalNodePhase.error, failure: NodeFailure.portInUse)), 'Failed', EState.risk, 'failed'),
      'local stopped': (localNodeView(mockLocalNode(LocalNodePhase.stopped)), 'Stopped', EState.off, 'stopped'),
    };

    test('words, states and markers', () {
      for (final e in fixtures.entries) {
        final (v, word, state, marker) = e.value;
        expect(v.word, word, reason: e.key);
        expect(v.state, state, reason: e.key);
        expect(v.marker, marker, reason: e.key);
        if (marker != null) expect(marker.length, lessThanOrEqualTo(9), reason: e.key);
      }
      expect(fixtures['remote at tip, version current']!.$1.host, 'epiccash.com');
      expect(fixtures['remote at tip, version current']!.$1.lines, ['node.epiccash.com · 3,764,975 · at tip', '722 ms · v4.1.1']);
      expect(fixtures['remote older version']!.$1.lines.last, '24 ms · v4.1.0 · 4.1.1 is out');
      expect(fixtures['remote behind']!.$1.lines.first, 'node.epiccash.com · 3,764,963 of 3,764,975');
      expect(fixtures['remote no answer']!.$1.lines, ['node.epiccash.com · since 14:02', 'The node is not answering.']);
      expect(fixtures['local syncing, fallback']!.$1.host, 'epiccash.com');
      expect(fixtures['local syncing, fallback']!.$1.lines, [
        'Local node · 12 % · about 3 h left',
        'Headers · 1,480,200 of 3,764,975 · 14 peers',
        'Using node.epiccash.com until it is synced.',
      ]);
      expect(fixtures['local syncing, no fallback']!.$1.host, 'Local node');
      expect(fixtures['local syncing, no fallback']!.$1.lines.last, 'Nothing can be sent until it is synced.');
      expect(fixtures['local synced']!.$1.lines.first, 'Local node · 3,764,975 · at tip');
      expect(fixtures['local stopped']!.$1.lines.last, 'Start it under Settings › Node.');
    });

    testWidgets('every state keeps the row at 40 u and the marker whole', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final e in fixtures.entries) {
        final item = nodeRailItem(e.value.$1);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            // The test font draws every glyph as wide as its size, about twice the real width.
            home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: 360, child: RailRow(item: item, onTap: () {})))),
          ),
        );
        await tester.pump();
        expect(tester.getSize(find.byType(RailRow)).height, 40.u, reason: e.key);
        expect(tester.getSize(find.byType(RailRow)).width, 360, reason: e.key);
        if (item.marker != null) {
          final t = find.text(' · ${item.marker}');
          expect(t, findsOneWidget, reason: e.key);
          expect(tester.getTopRight(t).dx, lessThanOrEqualTo(360 - 8.u), reason: '${e.key}: the marker is cut');
        }
        expect(tester.takeException(), isNull, reason: e.key);
      }
    });

    testWidgets('a long host with a marker: the host gets the ellipsis, the marker stays', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final v = remoteNodeView('https://a-very-long-node-host-name.example-network.org', mockNodeInfo('x', behind: 1234));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: 360, child: RailRow(item: nodeRailItem(v), onTap: () {})))),
        ),
      );
      await tester.pump();
      final marker = find.text(' · 1,234 behind');
      expect(marker, findsOneWidget);
      expect(tester.getTopRight(marker).dx, lessThanOrEqualTo(360 - 8.u));
      final host = find.text(v.host);
      expect(tester.getSize(host).width, lessThan(360 - tester.getSize(marker).width - 40));
      expect(tester.takeException(), isNull);
    });
  });
}
