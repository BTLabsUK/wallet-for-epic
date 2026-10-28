// The node card (spec §17): one golden with the five states; limited info shows exactly four
// facts and the tag; nothing spins; the Switch action names the healthiest other node; the
// words match the rail's.
//
// Regenerate with `flutter test --no-pub --update-goldens test/desktop/node_card_test.dart`.
import 'dart:io';

import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart' show remoteNodeView, shownLatency;
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  final roboto = File('$dir/Roboto-Regular.ttf');
  if (!roboto.existsSync()) return;
  final loader = FontLoader('Roboto')..addFont(roboto.readAsBytes().then((b) => b.buffer.asByteData()));
  await loader.load();
}

const _url = 'https://node.epiccash.com:3413';
final _now = DateTime(2026, 10, 22, 14, 3);

Widget _card(NodeInfo? info, {ServiceHealth? health, bool torOn = false, DateTime? downSince, SwitchTarget? switchTo, ValueChanged<SwitchTarget>? onSwitch}) =>
    NodeCard(url: _url, info: info, health: health, torOn: torOn, downSince: downSince, switchTo: switchTo, onSwitch: onSwitch, now: _now);

Future<void> _pump(WidgetTester tester, Widget child, {Size size = const Size(1280, 680)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDeskTheme(Brightness.dark),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('five states (golden)', (tester) async {
    final states = <String, Widget>{
      'synced': _card(mockNodeInfo(_url, latencyMs: 722)),
      'behind': _card(mockNodeInfo(_url, behind: 12, state: NodeHealthState.degraded)),
      'old': _card(mockNodeInfo(_url, version: '4.1.0', latencyMs: 1083)),
      'limited': _card(mockNodeInfo(_url, source: NodeInfoSource.limited)),
      'down': _card(
        mockNodeInfo(_url, state: NodeHealthState.down),
        downSince: DateTime(2026, 10, 22, 14, 2),
        switchTo: const SwitchTarget(host: 'node.btlabs.uk', url: 'https://node.btlabs.uk'),
        onSwitch: (_) {},
      ),
    };
    await _pump(
      tester,
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in states.entries) ...[
              Text(e.key, style: const TextStyle(fontSize: 11)),
              Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12), color: const Color(0xFF15181D), child: e.value),
            ],
          ],
        ),
      ),
      size: const Size(1280, 1600),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ESpinner), findsNothing, reason: 'no spinner anywhere on the card');
    await expectLater(find.byType(SingleChildScrollView), matchesGoldenFile('goldens/node_card_states.png'));
  });

  testWidgets('the words match the rail: Synced, Behind, Synced (old), Not answering', (tester) async {
    await _pump(tester, _card(mockNodeInfo(_url)));
    expect(find.textContaining('Synced', findRichText: true), findsOneWidget);
    expect(find.text('at tip'), findsOneWidget);
    expect(find.text('latest'), findsOneWidget);
    expect(find.text('99.7%'), findsOneWidget);
    expect(find.text('listed as official'), findsOneWidget);
    expect(find.textContaining('Nodes agree on 3,764,975 · 5 of 6 nodes up · 4 of 4 Epicbox servers up · last block 40 s ago'), findsOneWidget);
    expect(find.textContaining('status.btlabs.uk, checked 14:02 · latency measured from this computer'), findsOneWidget);

    await _pump(tester, _card(mockNodeInfo(_url, behind: 12, state: NodeHealthState.degraded)));
    expect(find.textContaining('Behind', findRichText: true), findsOneWidget);
    expect(find.text('12 behind'), findsOneWidget);

    await _pump(tester, _card(mockNodeInfo(_url, version: '4.1.0')));
    expect(find.text('4.1.1 is out'), findsOneWidget);

    await _pump(tester, _card(mockNodeInfo(_url, state: NodeHealthState.down), downSince: DateTime(2026, 10, 22, 14, 2)));
    expect(find.textContaining('Not answering', findRichText: true), findsOneWidget);
    expect(find.textContaining('since 14:02', findRichText: true), findsOneWidget);
    expect(find.text('no answer'), findsOneWidget);
  });

  testWidgets('limited info: exactly four facts and the tag; the source line names the last reach', (tester) async {
    await _pump(tester, _card(mockNodeInfo(_url, source: NodeInfoSource.limited)));
    expect(find.text('Limited info'), findsOneWidget);
    for (final f in ['Height', 'Version', 'Accepts transactions', 'Latency']) {
      expect(find.text(f), findsOneWidget, reason: f);
    }
    for (final f in ['Uptime', 'Peers', 'Operator']) {
      expect(find.text(f), findsNothing, reason: f);
    }
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('last block 3 min ago'), findsOneWidget);
    expect(find.textContaining('status.btlabs.uk is not reachable'), findsOneWidget);
    expect(find.textContaining('Status site last reached'), findsNothing, reason: 'never reached this session');
  });

  // The owner's 26.10.x desktop: a 4.1.1 node whose ready_for_txs call failed read "node before 4.1.0".
  testWidgets('limited info, readiness unknown: "node before 4.1.0" only for a node that says so', (tester) async {
    NodeInfo info(String? version) =>
        NodeInfo(url: _url, source: NodeInfoSource.limited, at: _now, height: 3766864, version: version);
    for (final (version, label) in [('4.1.1', 'no answer'), ('4.1.0-1', 'no answer'), (null, 'no answer'), ('3.6.0', 'node before 4.1.0')]) {
      await _pump(tester, _card(info(version)));
      expect(find.text('Unknown'), findsOneWidget, reason: '$version');
      expect(find.textContaining(label), findsOneWidget, reason: '$version');
      if (label == 'no answer') expect(find.textContaining('before 4.1.0'), findsNothing, reason: '$version');
    }
  });

  testWidgets('nothing known yet: every value prints – and nothing spins', (tester) async {
    await _pump(tester, _card(null));
    expect(find.textContaining('Checking', findRichText: true), findsOneWidget);
    expect(find.text('–'), findsWidgets);
    expect(find.byType(ESpinner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('down: the Switch action offers the target and calls back with it', (tester) async {
    SwitchTarget? to;
    await _pump(
      tester,
      _card(
        mockNodeInfo(_url, state: NodeHealthState.down),
        switchTo: const SwitchTarget(host: 'node.btlabs.uk', url: 'https://node.btlabs.uk'),
        onSwitch: (t) => to = t,
      ),
    );
    expect(find.text('Node not answering.'), findsOneWidget);
    expect(find.text('Switch to node.btlabs.uk, the healthiest other node?'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    expect(to?.url, 'https://node.btlabs.uk');
  });

  testWidgets('Settings › Node: a down node offers the lowest-latency healthy node and switches to it', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final node = MockDeskNode();
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)), deskNodeProvider.overrideWithValue(node)]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsNodeScreen(arg: NodeDemo.down))),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Node not answering.'), findsOneWidget);
    // The mock's healthiest node with the lowest latency: the home node (6 ms) is My nodes and comes first.
    expect(find.text('Switch to 10.0.1.24, the healthiest other node?'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(deskProvider).status?.node.url, 'http://10.0.1.24:3413');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Tor on: latency reads over Tor, never from this computer', (tester) async {
    final i = NodeInfo(
      url: _url,
      source: NodeInfoSource.directory,
      at: DateTime(2026, 10, 22, 14, 2),
      state: NodeHealthState.healthy,
      latencyMs: 2400,
      latencyOverTor: true,
    );
    await _pump(tester, _card(i));
    expect(find.text('over Tor'), findsOneWidget);
    expect(find.textContaining('from this computer'), findsNothing);
    expect(find.textContaining('latency measured over Tor'), findsOneWidget);
  });

  testWidgets('the wallet reaches the node over Tor: a failed info probe is not Not answering, nothing to switch', (tester) async {
    // The info probe over Tor timed out while the wallet synced through the node.
    final probe = NodeInfo(url: _url, source: NodeInfoSource.none, at: DateTime(2026, 10, 22, 14, 2), state: NodeHealthState.down);
    await _pump(
      tester,
      _card(probe, health: ServiceHealth.ok, switchTo: const SwitchTarget(host: 'node.epicnet.us', url: 'https://node.epicnet.us'), onSwitch: (_) {}),
    );
    expect(find.textContaining('Not answering', findRichText: true), findsNothing);
    expect(find.textContaining('Switch to'), findsNothing);
    expect(remoteNodeView(englishStrings, _url, probe, health: ServiceHealth.ok).word, 'Synced', reason: 'the rail and the head say the same');
    expect(remoteNodeView(englishStrings, _url, probe, health: ServiceHealth.down).word, 'Not answering');
  });

  testWidgets('Tor turned on: a direct reading is dropped at once, never shown with Tor on', (tester) async {
    // The info from before Tor came on, measured directly; the next over Tor is not in yet.
    final direct = NodeInfo(url: _url, source: NodeInfoSource.limited, at: DateTime(2026, 10, 22, 14, 2), state: NodeHealthState.healthy, height: 2914414, latencyMs: 812);
    await _pump(tester, _card(direct, torOn: true));
    expect(find.textContaining('812'), findsNothing);
    expect(find.textContaining('from this computer'), findsNothing);
    expect(shownLatency(direct, torOn: true), isNull);
    expect(remoteNodeView(englishStrings, _url, direct, torOn: true).lines.join(' '), isNot(contains('812')), reason: 'the rail drops it too');
    // Off, the same reading shows as before.
    await _pump(tester, _card(direct));
    expect(find.text('812 ms'), findsOneWidget);
    expect(find.text('from this computer'), findsOneWidget);
  });

  testWidgets('no figure: no measured label; with Tor on never from this computer', (tester) async {
    // Not answering over Tor: nothing measured.
    final none = NodeInfo(url: _url, source: NodeInfoSource.none, at: DateTime(2026, 10, 22, 14, 2), state: NodeHealthState.down);
    await _pump(tester, _card(none, torOn: true));
    expect(find.textContaining('from this computer'), findsNothing);
    expect(find.textContaining('over Tor'), findsNothing);
    expect(find.textContaining('measured'), findsNothing);
    // Off, no figure: no label either.
    await _pump(tester, _card(none));
    expect(find.textContaining('from this computer'), findsNothing);
    // A directory reading with no figure of its own or the monitor's: no "latency measured".
    final listed = NodeInfo(url: _url, source: NodeInfoSource.directory, at: DateTime(2026, 10, 22, 14, 2), state: NodeHealthState.healthy, height: 2914414);
    await _pump(tester, _card(listed, torOn: true));
    expect(find.textContaining('measured'), findsNothing);
    expect(find.textContaining('status.btlabs.uk, checked 14:02'), findsOneWidget);
  });
}
