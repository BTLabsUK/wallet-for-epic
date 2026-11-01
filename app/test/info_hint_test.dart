// SPDX-License-Identifier: Apache-2.0
// The phone's info icons (android-18): every one opens an info sheet with the row's name and
// the whole explanation, inside the safe area, closed by Close, a tap outside or Back.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _title = 'Split change';
const _text =
    'When a send would leave fewer than 3 spendable outputs and its change is at least 1 EPIC, '
    'the change comes back as up to 4 outputs, so the next sends do not wait for confirmations. '
    'Each extra output costs 0.004 EPIC.';

/// A 360 × 640 phone with a 48 dp three-button navigation bar at the bottom.
const double _navBar = 48;

Future<void> _pump(WidgetTester tester, Widget row, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(360 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(bottom: _navBar * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildWalletTheme(protocolDark, Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: ListView(children: [row])),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the icon opens a sheet with the title and the whole text, above the navigation bar', (
    tester,
  ) async {
    var value = false;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => HintSwitchTile(
          icon: Icons.call_split,
          title: _title,
          hint: _text,
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(find.byType(Tooltip), findsNothing);
    await tester.tap(find.byType(InfoHint));
    await tester.pumpAndSettle();
    final sheet = find.byType(InfoSheet);
    expect(sheet, findsOneWidget);
    // The icon's tap opened the sheet, not the switch.
    expect(value, isFalse);
    expect(find.descendant(of: sheet, matching: find.text(_title)), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.byIcon(Icons.call_split)), findsOneWidget);
    final text = find.descendant(of: sheet, matching: find.text(_text));
    expect(text, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse);
    // Everything, Close included, stays above the navigation bar.
    final close = find.widgetWithText(TextButton, 'Close');
    expect(tester.getRect(close).bottom, lessThanOrEqualTo(640 - _navBar));
    // The text's visible part too (the test font is wide, so here it scrolls).
    final scroll = find.descendant(of: sheet, matching: find.byType(SingleChildScrollView));
    expect(tester.getRect(scroll).bottom, lessThanOrEqualTo(640 - _navBar));
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('a tap outside and Back close it', (tester) async {
    await _pump(tester, const TitleWithHint(_title, hint: _text));
    await tester.tap(find.byType(InfoHint));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsOneWidget);
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsNothing);
    await tester.tap(find.byType(InfoHint));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    await nav.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsNothing);
  });

  testWidgets('a long text at a large text scale scrolls, with Close in reach', (tester) async {
    await _pump(
      tester,
      const TitleWithHint(_title, hint: '$_text $_text $_text $_text'),
      textScale: 2,
    );
    await tester.tap(find.byType(InfoHint));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final close = find.widgetWithText(TextButton, 'Close');
    expect(close, findsOneWidget);
    expect(tester.getRect(close).bottom, lessThanOrEqualTo(640 - _navBar));
    expect(
      find.descendant(of: find.byType(InfoSheet), matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
  });

  testWidgets('the icon is a button for a screen reader, named after the row', (tester) async {
    await _pump(tester, const TitleWithHint(_title, hint: _text));
    // The list item merges the row's text into the node; the icon's own label and hint are in it.
    final node = tester.getSemantics(find.byType(InfoHint));
    expect(node.label, contains(_title));
    expect(node.hint, _text);
    expect(node.flagsCollection.isButton, isTrue);
  });

  testWidgets('a 48 dp target on its own, the row\'s size inside a row target; the icon 18 dp', (tester) async {
    await _pump(tester, const Align(alignment: AlignmentDirectional.centerStart, child: InfoHint(_text, title: _title)));
    expect(tester.getSize(find.byType(InfoHint)), const Size.square(48));
    expect(tester.getSize(find.byIcon(Icons.info_outline)), const Size.square(18));
    await _pump(tester, const TitleWithHint(_title, hint: _text));
    expect(tester.getSize(find.byType(InfoHint)), const Size.square(InfoHint.inRow));
    expect(tester.getSize(find.byIcon(Icons.info_outline)), const Size.square(18));
  });
}
