// SPDX-License-Identifier: Apache-2.0
// The status pill leads with the connection mode (own glyph and name) when the mode is not Normal;
// Normal shows no mode. Kill switch is the mode alone, with no dot and no state word.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/kit/kit_connection_dot.dart';
import 'package:epic_wallet/src/ui/kit/kit_status_pill.dart';
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart';
import 'package:epic_wallet/src/ui/net_view.dart';
import 'package:epic_wallet/src/ui/network_mode_text.dart' show networkModeName;
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _app(
  NetworkMode mode, {
  bool ready = true,
  bool showState = true,
  String? label,
  TextDirection direction = TextDirection.ltr,
  double? width,
}) => MaterialApp(
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
          child: SizedBox(
            width: width,
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: KitStatusPill(
                ready: ready,
                label: label,
                modeMark: netModeMark(mode),
                modeName: mode == NetworkMode.standard ? null : networkModeName(_en, mode),
                showState: showState,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

final _pill = find.byType(KitStatusPill);
final _dot = find.byType(KitConnectionDot);
Finder _icon(IconData icon) => find.descendant(of: _pill, matching: find.byIcon(icon));

const _modes = [NetworkMode.torOnly, NetworkMode.nodeOnly, NetworkMode.killSwitch];

void main() {
  testWidgets('Normal: no mode mark, no mode word, the pill as before', (tester) async {
    await tester.pumpWidget(_app(NetworkMode.standard));
    expect(find.descendant(of: _pill, matching: find.byType(Icon)), findsNothing);
    for (final m in _modes) {
      expect(find.text(networkModeName(_en, m)), findsNothing);
    }
    expect(_dot, findsOneWidget);
    expect(find.bySemanticsLabel('Ready'), findsOneWidget);
    expect(tester.getSize(_pill).height, Kit.pill);
  });

  for (final m in _modes) {
    for (final ready in [true, false]) {
      testWidgets('${m.name}: its own icon and name lead, then the state (ready=$ready)', (tester) async {
        final name = networkModeName(_en, m);
        await tester.pumpWidget(_app(m, ready: ready, showState: m != NetworkMode.killSwitch));
        final icon = netModeMark(m)!;
        expect(_icon(icon), findsOneWidget);
        expect(find.text(name), findsOneWidget);
        final on = tester.getRect(_pill);
        final mark = tester.getRect(_icon(icon));
        expect(on.contains(mark.topLeft) && on.contains(mark.bottomRight), isTrue);
        expect(mark.center.dy, moreOrLessEquals(on.center.dy, epsilon: 0.5));
        expect(on.height, Kit.pill);
        if (m == NetworkMode.killSwitch) {
          expect(_dot, findsNothing);
          expect(find.bySemanticsLabel(name), findsOneWidget);
        } else {
          expect(tester.getRect(find.text(name)).right < tester.getRect(_dot).left, isTrue);
          expect(find.bySemanticsLabel(ready ? '$name, Ready' : '$name, Reconnecting'), findsOneWidget);
        }
      });
    }
  }

  testWidgets('the three modes show three different icons', (tester) async {
    expect({for (final m in _modes) netModeMark(m)}.length, 3);
    expect(netModeMark(NetworkMode.standard), isNull);
  });

  testWidgets('the dot keeps its place when a mode joins; the pill grows toward the start', (tester) async {
    await tester.pumpWidget(_app(NetworkMode.standard));
    final off = tester.getRect(_pill);
    final dotOff = tester.getRect(_dot);
    await tester.pumpWidget(_app(NetworkMode.nodeOnly));
    final on = tester.getRect(_pill);
    expect(on.right, off.right);
    expect(tester.getRect(_dot), dotOff);
    expect(on.left < off.left, isTrue);
  });

  testWidgets('right to left: the mode sits at the start, after the dot on screen', (tester) async {
    await tester.pumpWidget(_app(NetworkMode.nodeOnly, direction: TextDirection.rtl));
    final on = tester.getRect(_pill);
    final mark = tester.getRect(_icon(netModeMark(NetworkMode.nodeOnly)!));
    expect(on.contains(mark.topLeft) && on.contains(mark.bottomRight), isTrue);
    final word = tester.getRect(find.text(networkModeName(_en, NetworkMode.nodeOnly)));
    expect(word.left > tester.getRect(_dot).right && mark.left > word.right, isTrue);
  });

  testWidgets('a narrow row cuts the state, never the mode mark', (tester) async {
    await tester.pumpWidget(_app(NetworkMode.torOnly, label: 'Syncing 45%', width: 132));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_pill).width, 132);
    expect(
      tester.getSize(_icon(netModeMark(NetworkMode.torOnly)!)),
      const Size.square(KitStatusPill.modeMarkSize),
    );
  });
}
