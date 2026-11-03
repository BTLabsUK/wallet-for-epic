// SPDX-License-Identifier: Apache-2.0
// The picker row: the columns at 640 u, no operator under 420 u, no version under
// 480 u, a long host never pushes the latency past the edge; the neutral order of a shuffled list; one
// ServerRow class serves nodes and relays; no node row carries a default tag.
import 'dart:io';

import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/server_row.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _node = ServerInfo(value: 'https://node.epiccash.com:3413', host: 'node.epiccash.com', operator: 'Epic Cash', behind: 0, latencyMs: 24, version: '4.1.1');
const _behind = ServerInfo(value: 'b', host: 'node.btlabs.uk', operator: 'BT Labs', state: EState.warn, behind: 12, latencyMs: 18, version: '4.1.0', versionOld: true);
const _down = ServerInfo(value: 'c', host: 'node.pool.example.org', operator: 'Pool op', state: EState.risk);
const _relay = ServerInfo(value: 'epicbox.epiccash.com', host: 'epicbox.epiccash.com', operator: 'Epic Cash', latencyMs: 40, version: '1', isDefault: true);

Future<void> _pump(WidgetTester tester, double width, Widget row) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDeskTheme(Brightness.dark),
      home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: row))),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('640 u: every column, 36 u tall', (tester) async {
    await _pump(tester, 640, ServerRow(kind: ServerKind.node, info: _behind, onTap: () {}));
    expect(tester.getSize(find.byType(ServerRow)).height, 36.u);
    expect(find.text('node.btlabs.uk'), findsOneWidget);
    expect(find.text('BT Labs'), findsOneWidget);
    expect(find.text('12 behind'), findsOneWidget);
    expect(find.text('18 ms'), findsOneWidget);
    expect(find.text('v4.1.0'), findsOneWidget);
    expect(tester.widget<ESignalBars>(find.byType(ESignalBars)).state, EState.warn);
    expect(tester.takeException(), isNull);
  });

  testWidgets('419 u: no operator; 360 u: no version either, the host gets the ellipsis', (tester) async {
    await _pump(tester, 419, ServerRow(kind: ServerKind.node, info: _behind, onTap: () {}));
    expect(find.text('BT Labs'), findsNothing);
    expect(find.text('v4.1.0'), findsNothing, reason: '419 is also under 480');
    expect(find.text('12 behind'), findsOneWidget);
    final tipAt419 = tester.getSize(find.text('12 behind')).width;

    await _pump(tester, 360, ServerRow(kind: ServerKind.node, info: _behind, onTap: () {}));
    expect(find.text('v4.1.0'), findsNothing);
    expect(tester.getSize(find.text('12 behind')).width, tipAt419);
    // The latency column keeps its width (the text scales down inside it when it is longer).
    expect(tester.getSize(find.ancestor(of: find.text('18 ms'), matching: find.byType(SizedBox)).first).width, 68.u);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 60-character host never pushes the latency past the edge', (tester) async {
    final long = ServerInfo(value: 'x', host: 'a' * 60, latencyMs: 9, version: '4.1.1', behind: 0);
    await _pump(tester, 360, ServerRow(kind: ServerKind.node, info: long, onTap: () {}));
    expect(tester.getTopRight(find.text('9 ms')).dx, lessThanOrEqualTo(360));
    expect(tester.getSize(find.byType(ServerRow)).width, 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a down row: one risk bar, greyed words, "no answer", still a button', (tester) async {
    var tapped = false;
    await _pump(tester, 640, ServerRow(kind: ServerKind.node, info: _down, onTap: () => tapped = true));
    expect(tester.widget<ESignalBars>(find.byType(ESignalBars)).state, EState.risk);
    expect(find.text(_l.deskKitNodeNoAnswer), findsOneWidget);
    expect(find.text('–'), findsWidgets, reason: 'tip and version unknown');
    await tester.tap(find.byType(InkWell).first);
    expect(tapped, isTrue);
  });

  testWidgets('a relay row shows the default tag; a node row never does', (tester) async {
    await _pump(tester, 640, ServerRow(kind: ServerKind.relay, info: _relay, onTap: () {}));
    expect(find.text(_l.deskSlDefault), findsOneWidget);
    expect(find.text('synced'), findsNothing, reason: 'no tip column on a relay');
    await _pump(tester, 640, ServerRow(kind: ServerKind.node, info: ServerInfo(value: _node.value, host: _node.host, behind: 0, isDefault: true), onTap: () {}));
    expect(find.text('Default'), findsNothing);
    expect(find.text(_l.deskKitAtTip), findsOneWidget);
  });

  test('neutral order: state, then latency, then the source order', () {
    const a = ServerInfo(value: 'a', host: 'a', state: EState.ok, latencyMs: 200);
    const b = ServerInfo(value: 'b', host: 'b', state: EState.ok, latencyMs: 24);
    const c = ServerInfo(value: 'c', host: 'c', state: EState.risk);
    const d = ServerInfo(value: 'd', host: 'd', state: EState.warn, latencyMs: 10);
    const e = ServerInfo(value: 'e', host: 'e', state: EState.ok, latencyMs: 24);
    const f = ServerInfo(value: 'f', host: 'f', state: EState.ok);
    final shuffled = [f, c, a, e, d, b];
    final ordered = neutralOrder(shuffled, state: (r) => r.state, latency: (r) => r.latencyMs);
    expect(ordered.map((r) => r.value).toList(), ['e', 'b', 'a', 'f', 'd', 'c'], reason: 'e before b: the source order breaks the tie');
  });

  test('serverRows: behind from the highest height, old from the released version, no default', () {
    final rows = serverRows([
      const NodeServer(url: 'https://node.epiccash.com:3413', label: 'Epic Cash', operator: 'Epic Cash', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1'),
      const NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs', operator: 'BT Labs', health: ServiceHealth.ok, latencyMs: 18, height: 2914414, version: '4.1.1'),
      const NodeServer(url: 'https://epic.stackwallet.com:3413', label: 'Cypher Stack', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 210, height: 2914414, version: '4.1.0'),
      const NodeServer(url: 'https://node.pool.example.org', label: 'Pool op', operator: 'Pool op', health: ServiceHealth.down, version: '4.1.1'),
    ], released: '4.1.1');
    expect(rows.map((r) => r.host).toList(), ['node.btlabs.uk', 'epic.stackwallet.com', 'node.epiccash.com', 'node.pool.example.org']);
    expect(rows[1].versionOld, isTrue);
    expect(rows[1].state, EState.warn);
    expect(rows[2].behind, 1);
    expect(rows[3].down, isTrue);
    expect(rows.any((r) => r.isDefault), isFalse);
  });

  test('one ServerRow class under lib/src/desktop; no host literal other than the fallback default in user-facing code', () {
    final files = Directory('lib/src/desktop').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    var defs = 0;
    for (final f in files) {
      final s = f.readAsStringSync();
      defs += RegExp(r'class ServerRow\b').allMatches(s).length;
      // The mock's data and the node layer are not user-facing copy.
      if (f.path.endsWith('mock_wallet.dart') || f.path.endsWith('desk_node.dart')) continue;
      expect(s.contains('node.btlabs.uk'), isFalse, reason: '${f.path}: no node is the wallet’s own');
    }
    expect(defs, 1);
  });
}
