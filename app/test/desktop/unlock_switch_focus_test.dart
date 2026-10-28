// A tester (26.10.20): a wallet remembered on this computer opens from the wallet switch without
// the password, as at start; one not remembered still asks. And the Unlock page's password
// field has the focus and a showing caret when it opens, with no click.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/remember.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _main = 'legacy-mainnet';
const _savings = '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f';

void main() {
  final containers = <ProviderContainer>[];
  Future<ProviderContainer> pump(WidgetTester tester, MockDeskWallet api) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(api), deskStartProvider.overrideWithValue(DeskRoute.unlock)],
    );
    containers.add(container);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    return container;
  }

  // The mock's waits are real timers in fake time; a send-free app still has moving parts.
  Future<void> run(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> rememberBoth(WidgetTester tester, MockDeskWallet api, {bool savings = true}) async {
    await tester.runAsync(() async {
      for (final id in [_main, if (savings) _savings]) {
        await api.selectWallet(id);
        await api.unlock('secret-pass', remember: true);
        await api.lock();
      }
      await api.selectWallet(_main);
    });
  }

  Future<void> switchTo(WidgetTester tester, String name) async {
    // With a mouse, as on the desktop: the menu items take the focus on hover.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('bar-wallet'))));
    await run(tester);
    await mouse.down(tester.getCenter(find.byKey(const ValueKey('bar-wallet'))));
    await mouse.up();
    await run(tester);
    final item = tester.getCenter(find.text(name).last);
    await mouse.moveTo(item);
    await run(tester);
    await mouse.down(item);
    await mouse.up();
    await mouse.removePointer();
    await run(tester);
    await run(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (final c in containers) {
      c.dispose();
    }
    containers.clear();
    await tester.pump(const Duration(minutes: 5));
  }

  // The caret shows before any typing, and blinks: on and off over a few half-periods.
  Future<void> expectBlinking(WidgetTester tester, EditableTextState field) async {
    final seen = <bool>{};
    for (var i = 0; i < 6; i++) {
      seen.add(field.cursorCurrentlyVisible);
      await tester.pump(field.cursorBlinkInterval);
    }
    expect(seen, {true, false}, reason: 'the caret blinks');
  }

  EditableTextState password(WidgetTester tester) => tester.state<EditableTextState>(find.byType(EditableText).first);

  testWidgets('two remembered wallets: the switch opens the other one without asking', (tester) async {
    final api = MockDeskWallet(delay: const Duration(milliseconds: 5));
    await rememberBoth(tester, api);
    rememberAutoTried = false;
    final container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview, reason: 'the last wallet opens at start');
    await switchTo(tester, 'Savings');
    expect(container.read(deskNavProvider).route, DeskRoute.overview, reason: 'a remembered wallet opens from the switch');
    final current = await tester.runAsync(() => api.wallets());
    expect(current!.firstWhere((w) => w.current).id, _savings);
    expect(api.openedRemembered, isTrue);
    await done(tester);
  });

  testWidgets('a target not remembered asks, with the password field focused and its caret showing', (tester) async {
    final api = MockDeskWallet(delay: const Duration(milliseconds: 5));
    await rememberBoth(tester, api, savings: false);
    rememberAutoTried = false;
    final container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
    // Something on the page had the focus before the switch.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await run(tester);
    await switchTo(tester, 'Savings');
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    expect(find.widgetWithText(EButton, 'Unlock'), findsOneWidget);
    final field = password(tester);
    expect(field.widget.focusNode.hasPrimaryFocus, isTrue, reason: 'the password field has the focus after the switch');
    expect(field.widget.showCursor, isTrue);
    expect(field.widget.cursorColor.a, greaterThan(0));
    await expectBlinking(tester, field);
    await done(tester);
  });

  testWidgets('first Unlock: the password field has the focus and a blinking caret', (tester) async {
    rememberAutoTried = false;
    final api = MockDeskWallet(delay: const Duration(milliseconds: 5));
    await pump(tester, api);
    await run(tester);
    final field = password(tester);
    expect(field.widget.focusNode.hasPrimaryFocus, isTrue);
    expect(field.renderEditable.selection?.isValid, isTrue, reason: 'a caret needs a place in the text');
    await expectBlinking(tester, field);
    await done(tester);
  });
}
