// SPDX-License-Identifier: Apache-2.0
// The desktop help popover (widgets/popover.dart) behind every info and help icon
// (EInfoHint): opens at once on a click, on Enter and on Space; closes on Esc, on a click
// outside and on its ✕; shows the title and the text at a capped width; stays inside the
// window; gives the focus back to the icon.
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _text =
    'Tor hides your address from the Epicbox server and the node. Direct is faster and needs no Tor. '
    'Tor only refuses every direct connection, so nothing leaves without it. '
    'Offline keeps the wallet to this machine and the local network.';

final Finder _popover = find.byKey(const ValueKey('info-popover-text'));
final Finder _close = find.byKey(const ValueKey('info-popover-close'));

void main() {
  Future<void> host(WidgetTester tester, Widget child, {Size size = const Size(1280, 800), Alignment at = Alignment.topLeft}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: Align(alignment: at, child: Padding(padding: const EdgeInsets.all(24), child: child))),
      ),
    );
    await tester.pumpAndSettle();
  }

  final icon = find.byType(EInfoHint);

  testWidgets('a click opens it at once with the title, the icon and the text; ✕ closes it', (tester) async {
    await host(tester, const EInfoHint(_text, title: 'Network', icon: Icons.cell_tower));
    expect(_popover, findsNothing);
    await tester.tap(icon);
    await tester.pump();
    // One frame: no hover wait.
    expect(_popover, findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Network'), findsOneWidget);
    expect(find.byIcon(Icons.cell_tower), findsOneWidget);
    expect(find.text(_text), findsOneWidget);
    expect(_close, findsOneWidget);
    // The button is named for screen readers.
    expect(find.bySemanticsLabel('Network'), findsWidgets);

    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(_popover, findsNothing);
  });

  testWidgets('without a title: the text alone with ✕, and the icon keeps a generic name', (tester) async {
    await host(tester, const EInfoHint(_text));
    expect(find.bySemanticsLabel('More information'), findsOneWidget);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    expect(find.text(_text), findsOneWidget);
    expect(_close, findsOneWidget);
  });

  testWidgets('Enter and Space open it from the keyboard; Esc closes it; the focus comes back to the icon', (tester) async {
    await host(tester, const EInfoHint(_text, title: 'Network'));
    final node = tester.widget<FocusableActionDetector>(find.descendant(of: icon, matching: find.byType(FocusableActionDetector))).focusNode!;
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isTrue);
    // The ring shows on focus.
    expect(find.descendant(of: icon, matching: find.byType(FocusRing)), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_popover, findsOneWidget);
    expect(node.hasFocus, isFalse, reason: 'the focus moved into the popover');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_popover, findsNothing);
    expect(node.hasFocus, isTrue, reason: 'the focus is back on the icon');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_popover, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_popover, findsNothing);
  });

  testWidgets('a click outside closes it; a small mouse move does not', (tester) async {
    await host(tester, const EInfoHint(_text, title: 'Network'));
    await tester.tap(icon);
    await tester.pumpAndSettle();
    expect(_popover, findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(icon));
    await mouse.moveTo(tester.getCenter(icon) + const Offset(40, 40));
    await mouse.moveTo(tester.getCenter(icon) + const Offset(300, 300));
    await tester.pump(const Duration(seconds: 1));
    expect(_popover, findsOneWidget);

    await tester.tapAt(const Offset(1100, 700));
    await tester.pumpAndSettle();
    expect(_popover, findsNothing);
  });

  testWidgets('a reading width, under the icon and to the right, inside the window', (tester) async {
    await host(tester, const EInfoHint(_text, title: 'Network'));
    await tester.tap(icon);
    await tester.pumpAndSettle();
    final card = find.byType(EInfoPopover);
    final rect = tester.getRect(card);
    expect(rect.width, lessThanOrEqualTo(infoPopoverMaxWidth));
    expect(rect.width, greaterThan(300));
    expect(rect.height, lessThanOrEqualTo(infoPopoverMaxHeight));
    final at = tester.getRect(icon);
    expect(rect.top, greaterThanOrEqualTo(at.bottom));
    expect(rect.left, closeTo(at.left, 1));
    // The text wraps to several lines.
    expect(rect.height, greaterThan(60));
  });

  testWidgets('near the bottom-right corner it flips above and to the left, and never leaves the window', (tester) async {
    await host(tester, const EInfoHint(_text, title: 'Network'), at: Alignment.bottomRight);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(EInfoPopover));
    final at = tester.getRect(icon);
    expect(rect.bottom, lessThanOrEqualTo(at.top));
    expect(rect.right, closeTo(at.right, 1));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(1280));
    expect(rect.bottom, lessThanOrEqualTo(800));
  });

  testWidgets('a long text in a short window: the height is capped and the text scrolls', (tester) async {
    final long = List.filled(30, _text).join(' ');
    await host(tester, EInfoHint(long, title: 'Network'), size: const Size(1000, 500));
    await tester.tap(icon);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(EInfoPopover));
    expect(rect.height, lessThanOrEqualTo(500 * 0.6 + 1));
    expect(rect.bottom, lessThanOrEqualTo(500));
    final scroll = tester.widget<SingleChildScrollView>(find.descendant(of: find.byType(EInfoPopover), matching: find.byType(SingleChildScrollView)));
    expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
    expect(_close, findsOneWidget);
  });

  testWidgets('a settings row: the hint icon opens the popover with the row title', (tester) async {
    await host(tester, const SizedBox(width: 600, child: ESetRow(title: 'Status site', hint: _text, hintTitle: 'Status site', control: SizedBox())));
    expect(find.byWidgetPredicate((w) => w is EInfoHint && w.text == _text), findsOneWidget);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    expect(find.text(_text), findsOneWidget);
    expect(find.text('Status site'), findsNWidgets(2));
  });
}
