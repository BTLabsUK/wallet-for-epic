// SPDX-License-Identifier: Apache-2.0
// The sidebar rail: Node, Epicbox, HTTP, Tor with a divider between every two; every row 40 u in
// every state, so the rail never changes height; the Node row's twelve states; no address,
// URL or port on a row.
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/app/desk_failover.dart' show nodeBlipWindow, nodeBlipWindowProvider;
import 'package:epic_wallet/src/desktop/app/service_rows.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

final _l = englishStrings;

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
  HttpProblem? httpProblem,
  int? torProgress,
}) => ServiceStatus(
  node: const NodeServer(url: 'https://node.lab.invalid', label: 'BT Labs'),
  nodeHealth: node,
  nodeHeight: 2914414,
  epicbox: const EpicboxServer(domain: 'box.stack.invalid'),
  epicboxHealth: epicbox,
  httpListener: http,
  httpProblem: httpProblem,
  httpProblemPort: httpProblem == null ? null : 3415,
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
    httpProblem: HttpProblem.portInUse,
    tor: ServiceHealth.down,
  ),
  'all off': _status(node: ServiceHealth.off, epicbox: ServiceHealth.off),
  'node down': _status(node: ServiceHealth.down),
  'nothing known': null,
};

void main() {
  // [blip] keeps the node's blip window (nodeBlipWindow); the others see a node down at once.
  Future<ProviderContainer> show(WidgetTester tester, ServiceStatus? status, {bool refresh = true, double textScale = 1, bool blip = false}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      deskApiProvider.overrideWithValue(_Wallet(status)),
      if (!blip) nodeBlipWindowProvider.overrideWithValue(Duration.zero),
    ]);
    addTearDown(container.dispose);
    if (refresh) await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
          home: const Scaffold(body: Align(alignment: Alignment.topLeft, child: ServiceRows())),
        ),
      ),
    );
    // A millisecond runs riverpod's zero-delay dispose task of a previous container.
    await tester.pump(const Duration(milliseconds: 1));
    return container;
  }

  List<ServiceItem> items(WidgetTester tester) => [for (final r in tester.widgetList<ServiceRow>(find.byType(ServiceRow))) r.item];

  group('the services', () {
    testWidgets('one 40 u row per service for every status', (tester) async {
      for (final e in _fixtures.entries) {
        await show(tester, e.value, refresh: e.value != null);
        final rows = find.byType(ServiceRow);
        expect(rows, findsNWidgets(3 + (DeskFeatures.tor ? 1 : 0)), reason: e.key);
        for (final r in rows.evaluate()) {
          expect(tester.getSize(find.byWidget(r.widget)).height, 40.u, reason: e.key);
        }
      }
      // Lets riverpod's zero-delay dispose task of the last container run before the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('nothing known yet: Checking, with no healthy light', (tester) async {
      await show(tester, null, refresh: false);
      expect(items(tester).map((i) => i.name), containsAll([_l.deskRailNode, 'Epicbox']));
      final bars = tester.widgetList<EStatusGlyph>(find.byType(EStatusGlyph)).map((b) => b.state);
      // Not known yet is the blue ring (state_language.dart), never a healthy dot.
      expect(bars, isNot(contains(EState.ok)));
      expect(bars.where((s) => s == EState.active).length, greaterThanOrEqualTo(2));
    });

    testWidgets('a click opens that service\u2019s settings section', (tester) async {
      final c = await show(tester, _status());
      Finder row(String name) => find.byWidgetPredicate((w) => w is ServiceRow && w.item.name == name);
      await tester.tap(row('Epicbox'));
      await tester.pump();
      expect(c.read(settingsPrefsProvider).jump?.section, SettingsJump.epicbox);
      await tester.tap(row(_l.deskRailNode));
      await tester.pump();
      expect(c.read(settingsPrefsProvider).jump?.section, SettingsJump.node);
    });

    testWidgets('hosts drop the scheme and the port', (tester) async {
      await show(tester, _status());
      final seconds = items(tester).map((i) => i.second);
      expect(seconds, contains('lab.invalid'));
      expect(seconds, contains('box.stack.invalid'));
    });

    testWidgets('at 1.5\u00d7 OS text scale the rows stay 40 u and nothing overflows', (tester) async {
      await show(tester, _status(http: ServiceHealth.ok, tor: ServiceHealth.checking, torProgress: 40), textScale: 1.5);
      for (final r in find.byType(ServiceRow).evaluate()) {
        expect(tester.getSize(find.byWidget(r.widget)).height, 40.u);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('a node down for under the blip window is not yet Not answering; after it, it is, since HH:MM', (tester) async {
      var now = DateTime(2026, 10, 22, 14, 2, 0);
      serviceClock = () => now;
      addTearDown(() => serviceClock = DateTime.now);
      await show(tester, _status(node: ServiceHealth.down), blip: true);
      ServiceItem node() => tester.widget<ServiceRow>(find.byType(ServiceRow).first).item;
      expect(node().word, isNot('Not answering'), reason: 'a blip never flashes red');
      expect(node().marker, isNull);
      now = now.add(nodeBlipWindow + const Duration(seconds: 1));
      await tester.pump(nodeBlipWindow + const Duration(seconds: 1));
      expect(node().word, _l.deskNodeNotAnswering);
      expect(node().marker, _l.deskNodeMarkerNoAnswer);
      expect(node().lines.first, 'node.lab.invalid · since 14:02');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('the local node with the wallet on a public node', () {
    const public = 'https://node.epic.invalid:3413';
    test('starting, stopped and failed name the node in use; the local address does not', () {
      for (final phase in [LocalNodePhase.starting, LocalNodePhase.stopped, LocalNodePhase.error]) {
        final v = localNodeView(englishStrings, mockLocalNode(phase, failure: phase == LocalNodePhase.error ? NodeFailure.exited : null), fallbackUrl: public);
        expect(v.host, 'epic.invalid', reason: phase.name);
        expect(v.marker, isNotNull, reason: phase.name);
        expect(v.lines.last, anyOf('Using node.epic.invalid until it is synced.', 'Using node.epic.invalid meanwhile.'), reason: phase.name);
        expect(localNodeView(englishStrings, mockLocalNode(phase), fallbackUrl: 'http://127.0.0.1:3413').host, 'Local node', reason: phase.name);
      }
      expect(localNodeView(englishStrings, mockLocalNode(LocalNodePhase.synced), fallbackUrl: 'http://127.0.0.1:3413').lines.length, 2);
    });

    testWidgets('the rail reads the wallet’s actual node URL from the status', (tester) async {
      final c = await show(tester, _status(node: ServiceHealth.slow));
      c.read(settingsPrefsProvider.notifier).set(c.read(settingsPrefsProvider).copyWith(builtin: true));
      await tester.pump();
      // The local node's stream yields its first state a microtask later.
      await tester.pump();
      final node = tester.widget<ServiceRow>(find.byType(ServiceRow).first).item;
      expect(node.second, startsWith('lab.invalid'), reason: 'the status says the wallet reads node.lab.invalid');
      expect(node.lines, contains('Using node.lab.invalid meanwhile.'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('the Node row (§16)', () {
    const url = 'https://node.epic.invalid:3413';
    final since = DateTime(2026, 10, 22, 14, 2);
    final fixtures = <String, (NodeView, String, EState, String?)>{
      'remote at tip, version current': (remoteNodeView(englishStrings, url, mockNodeInfo(url, latencyMs: 722)), 'Synced', EState.ok, null),
      // Synced is green whatever the version; the version line carries the warning.
      'remote older version': (remoteNodeView(englishStrings, url, mockNodeInfo(url, version: '4.1.0')), 'Synced', EState.ok, null),
      'remote behind': (remoteNodeView(englishStrings, url, mockNodeInfo(url, behind: 12)), 'Behind', EState.warn, '12 behind'),
      'remote no answer': (remoteNodeView(englishStrings, url, mockNodeInfo(url, state: NodeHealthState.down), downSince: since), 'Not answering', EState.risk, 'no answer'),
      'nothing known': (remoteNodeView(englishStrings, url, null), 'Checking', EState.active, null),
      'local starting': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.starting)), 'Starting', EState.active, 'starting'),
      'local syncing, fallback': (
        localNodeView(englishStrings, 
          mockLocalNode(LocalNodePhase.syncing, overall: 0.12, done: 1480200, total: 3764975, eta: const Duration(hours: 3)),
          fallbackUrl: defaultFallbackNodeUrl,
        ),
        'Syncing',
        EState.active,
        '12%',
      ),
      'local syncing, no fallback': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.syncing, overall: 0.12)), 'Syncing', EState.active, '12%'),
      'local synced': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.synced)), 'Synced', EState.ok, null),
      'local stalled': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.error, stalled: true)), 'Stalled', EState.risk, 'stalled'),
      'local failed': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.error, failure: NodeFailure.portInUse)), 'Failed', EState.risk, 'failed'),
      'local stopped': (localNodeView(englishStrings, mockLocalNode(LocalNodePhase.stopped)), 'Stopped', EState.off, 'stopped'),
    };

    test('words, states and markers', () {
      for (final e in fixtures.entries) {
        final (v, word, state, marker) = e.value;
        expect(v.word, word, reason: e.key);
        expect(v.state, state, reason: e.key);
        expect(v.marker, marker, reason: e.key);
        if (marker != null) expect(marker.length, lessThanOrEqualTo(9), reason: e.key);
      }
      expect(fixtures['remote at tip, version current']!.$1.host, 'epic.invalid');
      expect(fixtures['remote at tip, version current']!.$1.lines, ['node.epic.invalid\u00A0· 3,764,975\u00A0· synced', '722 ms\u00A0· v4.1.1']);
      expect(fixtures['remote older version']!.$1.lines.last, '24 ms\u00A0· v4.1.0\u00A0· 4.1.1 is out');
      expect(fixtures['remote behind']!.$1.lines.first, 'node.epic.invalid\u00A0· 3,764,963 of 3,764,975');
      expect(fixtures['remote no answer']!.$1.lines, ['node.epic.invalid · since 14:02', 'The node is not answering.']);
      expect(fixtures['local syncing, fallback']!.$1.host, 'epic.invalid');
      expect(fixtures['local syncing, fallback']!.$1.lines, [
        'Local node\u00A0· 12%\u00A0· about 3 h left',
        'Headers · 1,480,200 of 3,764,975\u00A0· 14 peers',
        'Using node.epic.invalid until it is synced.',
      ]);
      expect(fixtures['local syncing, no fallback']!.$1.host, 'Local node');
      expect(fixtures['local syncing, no fallback']!.$1.lines.last, 'Nothing can be sent until it is synced.');
      expect(fixtures['local synced']!.$1.lines.first, 'Local node\u00A0· 3,764,975\u00A0· synced');
      expect(fixtures['local stopped']!.$1.lines.last, 'Start it under Settings\u00a0›\u00a0Node.');
    });
  });

  test('the rail takes the node height the wallet read; the behind check keeps the network tip', () {
    // P14: node info is asked every 5 min, not every poll; the wallet's own height stands in.
    const url = 'https://node.lab.invalid';
    final behind = mockNodeInfo(url, behind: 12);
    final tip = behind.networkHeight!;
    // The node caught up since: at tip by the wallet's height.
    expect(remoteNodeView(englishStrings, url, behind.withNodeHeight(tip)).word, _l.netStatusSynced);
    // Partly caught up: still behind by what is left.
    final part = behind.withNodeHeight(tip - 11);
    expect(part.blocksBehind, 11);
    expect(remoteNodeView(englishStrings, url, part).word, _l.deskNodeBehind);
    // An older wallet height changes nothing, and a node past the last known tip is at it.
    expect(identical(behind.withNodeHeight(tip - 20), behind), isTrue);
    expect(behind.withNodeHeight(tip + 3).blocksBehind, 0);
  });
}
