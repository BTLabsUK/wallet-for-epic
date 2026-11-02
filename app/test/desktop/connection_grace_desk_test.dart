// SPDX-License-Identifier: Apache-2.0
// The connection grace on the desktop (item 11): during it a server that does not answer reads
// Connecting on the status icons, and its notice (Epicbox down) waits; after it the notice shows,
// one line with the switch named by its server.
import 'package:epic_wallet/src/connection_grace.dart';
import 'package:epic_wallet/src/desktop/app/rail.dart' show RailItem;
import 'package:epic_wallet/src/desktop/app/status_popover.dart' show graceRailItems;
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart' show SettingsJump;
import 'package:epic_wallet/src/desktop/screens/transfer/epicbox_notice.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RailItem _item(SettingsJump jump, EState state, {bool byMode = false}) =>
    RailItem(icon: EIcons.node, name: jump.name, word: 'Not answering', state: state, second: 'host', lines: const ['why'], open: 'Open', jump: jump, byMode: byMode);

void main() {
  test('during the grace: node, Epicbox and Tor problems read Connecting; HTTP, off and by-mode stay', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final items = [
      _item(SettingsJump.node, EState.risk),
      _item(SettingsJump.epicbox, EState.warn),
      _item(SettingsJump.tor, EState.risk),
      _item(SettingsJump.http, EState.risk),
      _item(SettingsJump.epicbox, EState.off),
      _item(SettingsJump.node, EState.risk, byMode: true),
    ];
    final g = graceRailItems(l, items, grace: true);
    for (final i in g.take(3)) {
      expect(i.state, EState.active);
      expect(i.word, 'Connecting');
      expect(i.lines, isEmpty, reason: 'no warning lines meanwhile');
    }
    expect(g[3].state, EState.risk, reason: 'the HTTP listener is this computer');
    expect(g[4].state, EState.off);
    expect(g[5].state, EState.risk);
    expect(graceRailItems(l, items, grace: false), same(items));
  });

  testWidgets('the Epicbox notice waits out the grace, then shows', (tester) async {
    final container = ProviderContainer(overrides: [connectionGraceLengthProvider.overrideWithValue(const Duration(seconds: 20))]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: EpicboxDownNotice())),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('epicbox-down')), findsNothing);
    await tester.pump(const Duration(seconds: 21));
    expect(find.byKey(const ValueKey('epicbox-down')), findsOneWidget);
    expect(find.text('Epicbox server not answering'), findsOneWidget);
  });
}
