// SPDX-License-Identifier: Apache-2.0
// While Tor is on the status pill leads with the Tor mark and the word "Tor", inside the pill; the
// dot and the state's word stay where they are. With Tor off the pill is unchanged.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/kit/kit_connection_dot.dart';
import 'package:epic_wallet/src/ui/kit/kit_route_icon.dart';
import 'package:epic_wallet/src/ui/kit/kit_status_pill.dart';
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool tor, {bool ready = true, String? label, TextDirection direction = TextDirection.ltr, double? width}) => MaterialApp(
  theme: buildWalletTheme(protocolLight, Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: width, child: Align(alignment: AlignmentDirectional.topEnd, child: KitStatusPill(ready: ready, tor: tor, label: label))),
        ),
      ),
    ),
  ),
);

final _pill = find.byType(KitStatusPill);
final _mark = find.byType(KitRouteIcon);
final _word = find.text('Tor');
final _dot = find.byType(KitConnectionDot);

void main() {
  testWidgets('no Tor mark while Tor is off', (tester) async {
    await tester.pumpWidget(_app(false));
    expect(_mark, findsNothing);
    expect(_word, findsNothing);
    expect(find.bySemanticsLabel('Ready'), findsOneWidget);
    expect(tester.getSize(_pill).height, Kit.pill);
  });

  for (final ready in [true, false]) {
    testWidgets('the Tor mark and word lead inside the pill, ready=$ready', (tester) async {
      await tester.pumpWidget(_app(false, ready: ready));
      final off = tester.getRect(_pill);
      final dotOff = tester.getRect(_dot);
      await tester.pumpWidget(_app(true, ready: ready));
      final on = tester.getRect(_pill);
      final mark = tester.getRect(_mark);
      final word = tester.getRect(_word);
      final dot = tester.getRect(_dot);
      // Inside the pill, never over its edge: the mark, then the word, then the dot.
      expect(on.contains(mark.topLeft) && on.contains(mark.bottomRight), isTrue);
      expect(mark.right < word.left && word.right < dot.left, isTrue);
      expect(mark.center.dy, moreOrLessEquals(on.center.dy, epsilon: 0.5));
      // Same height and end edge; the dot keeps its place, the pill grows toward the start.
      expect(on.height, off.height);
      expect(on.right, off.right);
      expect(dot, dotOff);
      expect(on.left < off.left, isTrue);
      expect(find.bySemanticsLabel(ready ? 'Tor, Ready' : 'Tor, Reconnecting'), findsOneWidget);
    });
  }

  testWidgets('right to left: the mark and word sit at the start, after the dot on screen', (tester) async {
    await tester.pumpWidget(_app(true, direction: TextDirection.rtl));
    final on = tester.getRect(_pill);
    final mark = tester.getRect(_mark);
    expect(on.contains(mark.topLeft) && on.contains(mark.bottomRight), isTrue);
    final word = tester.getRect(_word);
    expect(word.left > tester.getRect(_dot).right && mark.left > word.right, isTrue);
  });

  testWidgets('a narrow row cuts the state, never the Tor mark or word', (tester) async {
    await tester.pumpWidget(_app(true, label: 'Syncing 45%'));
    final wide = tester.getSize(_word);
    await tester.pumpWidget(_app(true, label: 'Syncing 45%', width: 132));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_pill).width, 132);
    expect(tester.getSize(_mark), const Size.square(KitStatusPill.torMark));
    expect(tester.getSize(_word), wide);
  });
}
