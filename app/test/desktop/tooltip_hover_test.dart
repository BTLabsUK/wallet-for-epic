// SPDX-License-Identifier: Apache-2.0
// Desktop tooltips (widgets/tip.dart ETip) show on a mouse hover after the theme's wait and at
// once on a click, and go when the pointer leaves: the bar's status icons and lock, an icon
// button, and the ⓘ, whose hover shows its text while a click opens the popover.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _away = Offset(640, 600);

void main() {

  Future<TestGesture> mouse(WidgetTester tester) async {
    final m = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await m.addPointer(location: _away);
    addTearDown(m.removePointer);
    return m;
  }

  Future<void> host(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: Align(alignment: Alignment.topLeft, child: Padding(padding: const EdgeInsets.all(24), child: child))),
      ),
    );
    await tester.pumpAndSettle();
  }

  String tipOf(WidgetTester tester, Finder f) =>
      tester.widget<Tooltip>(find.descendant(of: f, matching: find.byType(Tooltip)).first).message!;

  testWidgets('the bar: node, Epicbox and lock show their tip on hover and hide it on leaving', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(overrides: [deskStartProvider.overrideWithValue(DeskRoute.overview)], child: const DeskApp()),
    );
    await tester.pumpAndSettle();
    final m = await mouse(tester);
    for (final id in ['status-node', 'status-epicbox', 'lock']) {
      final f = find.byKey(ValueKey('bar-$id'));
      expect(f, findsOneWidget, reason: id);
      final tip = tipOf(tester, f);
      await m.moveTo(tester.getCenter(f));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(tip), findsNothing, reason: '$id: not before the wait');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(tip), findsOneWidget, reason: '$id hover: $tip');
      await m.moveTo(_away);
      await tester.pumpAndSettle();
      expect(find.text(tip), findsNothing, reason: '$id: gone on leaving');
    }
  });

  testWidgets('an icon button: hover shows its name; a click shows it again at once', (tester) async {
    var copies = 0;
    await host(tester, EIconButton(icon: Icons.copy, label: 'Copy address', onPressed: () => copies++));
    final button = find.byType(EIconButton);
    final m = await mouse(tester);
    await m.moveTo(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Copy address'), findsOneWidget, reason: 'hover');
    // A click hides every tip on the press (Flutter); this one comes back on the release and
    // stays while the pointer is over it.
    await m.down(tester.getCenter(button));
    await tester.pump();
    await m.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(copies, 1);
    expect(find.text('Copy address'), findsOneWidget, reason: 'after the click');
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Copy address'), findsOneWidget, reason: 'held while hovered');
    await m.moveTo(_away);
    await tester.pumpAndSettle();
    expect(find.text('Copy address'), findsNothing, reason: 'gone on leaving');
  });

  testWidgets('a click with no hover first shows the tip at once', (tester) async {
    await host(tester, EIconButton(icon: Icons.qr_code, label: 'Show QR', onPressed: () {}));
    final m = await mouse(tester);
    // Straight from outside to a press: no time for the hover wait.
    await m.moveTo(tester.getCenter(find.byType(EIconButton)));
    await m.down(tester.getCenter(find.byType(EIconButton)));
    await tester.pump();
    await m.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Show QR'), findsOneWidget);
  });

  testWidgets('the ⓘ: hover shows its text; a click opens the popover without the tip', (tester) async {
    const text = 'The node checks every payment against the chain.';
    await host(tester, const EInfoHint(text, title: 'Node'));
    final icon = find.byType(EInfoHint);
    final m = await mouse(tester);
    await m.moveTo(tester.getCenter(icon));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(text), findsOneWidget, reason: 'hover');
    await m.down(tester.getCenter(icon));
    await tester.pump();
    await m.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('info-popover-text')), findsOneWidget, reason: 'the popover');
    expect(find.text(text), findsOneWidget, reason: 'the popover alone, no tip over it');
  });
}
