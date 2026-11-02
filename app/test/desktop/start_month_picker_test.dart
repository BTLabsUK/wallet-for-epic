// SPDX-License-Identifier: Apache-2.0
// The month picker (item 6): one field opening a popover under it. The 26.10.25 dialog opened
// on 2019, whose January to August are not offered yet looked offered: clicks there did
// nothing. Here: a click on an offered month picks it, one not offered is visibly off and
// does nothing, the keys work (arrows, PageUp/PageDown, Enter, Esc), Tab stays inside, and
// the field says whether it is open.
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder _field = find.byKey(EStartMonthField.fieldKey);
Finder _month(int y, int m) => find.byKey(EStartMonthPicker.monthKey(StartMonth(y, m)));
final Finder _popover = find.byType(EStartMonthPicker);

void main() {
  Future<List<StartMonth>> host(WidgetTester tester, {StartMonth? initial}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <StartMonth>[];
    var month = initial;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: StatefulBuilder(
                builder: (context, set) => ERowControl(
                  child: EStartMonthField(
                    month: month,
                    onChanged: (m) => set(() {
                      month = m;
                      picked.add(m);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return picked;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(_field, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(_popover, findsOneWidget);
  }

  testWidgets('a mouse click on an offered month picks it and closes the popover', (tester) async {
    final picked = await host(tester);
    expect(find.text('Pick a month'), findsOneWidget);
    await open(tester);
    expect(find.text('2019'), findsOneWidget, reason: 'nothing chosen: the first year');
    await tester.tap(find.byKey(EStartMonthPicker.laterKey), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    await tester.tap(_month(2020, 3), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(picked, [const StartMonth(2020, 3)]);
    expect(_popover, findsNothing);
    expect(find.text('March 2020'), findsOneWidget);
  });

  testWidgets('a month before September 2019 is off: shown faint, a click does nothing', (tester) async {
    final picked = await host(tester);
    await open(tester);
    await tester.tap(_month(2019, 3), kind: PointerDeviceKind.mouse, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    expect(_popover, findsOneWidget);
    expect(tester.getSemantics(_month(2019, 3)), isSemantics(isEnabled: false));
    expect(tester.getSemantics(_month(2019, 9)), isSemantics(isEnabled: true));
    // No later month than this one either.
    final now = DateTime.now();
    if (now.month < 12) {
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      for (var y = 2019; y < now.year; y++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      }
      await tester.pumpAndSettle();
      expect(tester.getSemantics(_month(now.year, now.month + 1)), isSemantics(isEnabled: false));
    }
  });

  testWidgets('opens on the chosen month; arrows, PageUp, Enter pick; the caption follows', (tester) async {
    final picked = await host(tester, initial: const StartMonth(2021, 6));
    await open(tester);
    expect(find.text('2021'), findsOneWidget);
    expect(tester.getSemantics(_month(2021, 6)), isSemantics(isSelected: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // July
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // November
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp); // November 2020
    await tester.pumpAndSettle();
    expect(find.text('2020'), findsOneWidget);
    expect(find.textContaining('Scanning starts from block'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, [const StartMonth(2020, 11)]);
    expect(_popover, findsNothing);
  });

  testWidgets('Esc closes without a pick; the focus is back on the field', (tester) async {
    final picked = await host(tester, initial: const StartMonth(2021, 6));
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_popover, findsNothing);
    expect(picked, isEmpty);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'start month field');
  });

  testWidgets('Tab goes round the arrows and the month and stays in the popover', (tester) async {
    await host(tester, initial: const StartMonth(2021, 6));
    await open(tester);
    final seen = <FocusNode>{};
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final f = FocusManager.instance.primaryFocus!;
      expect(f.context == null ? false : find.descendant(of: _popover, matching: find.byElementPredicate((e) => e == f.context)).evaluate().isNotEmpty, isTrue,
          reason: 'the focus never leaves the popover (Tab ${i + 1}: ${f.debugLabel})');
      seen.add(f);
    }
    expect(seen.length, greaterThanOrEqualTo(3), reason: 'both arrows and the month');
  });

  testWidgets('the field says whether the popover is open', (tester) async {
    final handle = tester.ensureSemantics();
    await host(tester);
    expect(tester.getSemantics(_field), isSemantics(isExpanded: false));
    await open(tester);
    // Under the popover's route the field's node is not in the tree a reader walks; its
    // properties say open.
    final props = tester.widget<Semantics>(find.ancestor(of: _field, matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.expanded != null)).first).properties;
    expect(props.expanded, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(_field), isSemantics(isExpanded: false));
    handle.dispose();
  });

  testWidgets('the popover sits under the field, right edges level, inside the window', (tester) async {
    await host(tester);
    await open(tester);
    final f = tester.getRect(_field);
    final p = tester.getRect(_popover);
    expect(p.top, greaterThan(f.bottom - 1));
    expect((p.right - f.right).abs(), lessThan(1));
    expect(p.left, greaterThanOrEqualTo(0));
    for (var m = 9; m <= 12; m++) {
      expect(tester.getSize(_month(2019, m)).height, greaterThanOrEqualTo(44), reason: 'a 44 px cell');
    }
  });
}
