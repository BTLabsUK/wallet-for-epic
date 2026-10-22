// The Overview header and the controls that did nothing in 0.1.0: Refresh asks the wallet to
// sync with the node (spinner until done, the error shown), the eye hides every amount, Show
// the tour opens the tour on Overview, Ctrl+L locks.
import 'dart:async';

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mock, with a Refresh held until [gate] and failing with [error], and its lock counted.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  Completer<void>? gate;
  Object? error;
  int syncs = 0;
  int locks = 0;

  @override
  Future<void> syncNow() async {
    syncs++;
    await gate?.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> lock() async {
    locks++;
  }
}

Future<ProviderContainer> _open(WidgetTester tester, _Wallet api, DeskRoute route) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(route);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('Refresh syncs with the node, spins until done, and says when it failed', (tester) async {
    final api = _Wallet()..gate = Completer<void>();
    await _open(tester, api, DeskRoute.overview);
    final refresh = find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Refresh');

    await tester.tap(refresh);
    await _settle(tester);
    expect(api.syncs, 1);
    expect(refresh, findsNothing, reason: 'a spinner while it runs');
    expect(find.byType(ESpinner), findsWidgets);

    api.error = const DeskError('The node did not answer');
    api.gate!.complete();
    await _settle(tester);
    expect(refresh, findsOneWidget, reason: 'the spinner ends on a failure too');
    expect(find.text('Not updated'), findsOneWidget);
    expect(find.text('The node did not answer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the eye hides every amount on Overview and Activity, and shows them again', (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.overview);
    final eye = find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Hide amounts');
    expect(find.bySemanticsLabel('Hidden amount'), findsNothing);

    await tester.tap(eye);
    await _settle(tester);
    expect(container.read(deskProvider).settings.hideAmounts, isTrue);
    expect(find.bySemanticsLabel('Hidden amount'), findsWidgets);
    expect(find.textContaining('••••••', findRichText: true), findsWidgets);

    container.read(deskNavProvider.notifier).go(DeskRoute.activity);
    await _settle(tester);
    expect(find.textContaining('••••••', findRichText: true), findsWidgets);

    await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Show amounts'));
    await _settle(tester);
    expect(container.read(deskProvider).settings.hideAmounts, isFalse);
    expect(find.textContaining('••••••', findRichText: true), findsNothing);
  });

  testWidgets('Show the tour opens the tour on Overview', (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.settingsAppearance);
    container.read(deskTourProvider.notifier).close();
    await tester.tap(find.text('Show the tour'));
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
    expect(container.read(deskTourProvider).open, isTrue);
    expect(find.byType(DeskTourOverlay), findsOneWidget);
  });

  testWidgets("Receive's HTTP QR button expands that QR under the address and hides it again", (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.overview);
    await tester.runAsync(() async {
      await container.read(deskProvider.notifier).setListening(true);
      await container.read(deskProvider.notifier).setHttp(true);
    });
    container.read(deskNavProvider.notifier).go(DeskRoute.receive);
    await _settle(tester);
    expect(find.byKey(const ValueKey('rx-qr-image-http')), findsNothing, reason: 'no QR on open');
    final button = find.byKey(const ValueKey('rx-qr-http'));
    await tester.ensureVisible(button);
    await _settle(tester);
    await tester.tap(button);
    await _settle(tester);
    expect(find.byKey(const ValueKey('rx-qr-image-http')), findsOneWidget);
    await tester.tap(button);
    await _settle(tester);
    expect(find.byKey(const ValueKey('rx-qr-image-http')), findsNothing);
  });

  testWidgets('Enter in the tour is Next', (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    expect(find.text(deskTourSteps[0].title), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text(deskTourSteps[1].title), findsOneWidget);
  });

  testWidgets('a dropdown closes on Escape and on a click outside, choosing nothing', (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.settingsAppearance);
    final scale = container.read(deskProvider).settings.scale;
    final field = find.descendant(of: find.byWidgetPredicate((w) => w is ESelect && w.semanticLabel == 'Interface scale'), matching: find.byType(InkWell));
    final item = find.text('150%');

    await tester.tap(field);
    await _settle(tester);
    expect(item, findsOneWidget, reason: 'the list is open');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(item, findsNothing, reason: 'Escape closed it');

    await tester.tap(field);
    await _settle(tester);
    expect(item, findsOneWidget);
    // A click on the sidebar while it is open closes the list and does not go to Activity.
    await tester.tap(find.byWidgetPredicate((w) => w is ENavItem && w.label == 'Activity'));
    await _settle(tester);
    expect(item, findsNothing);
    expect(container.read(deskNavProvider).route, DeskRoute.settingsAppearance);
    expect(container.read(deskProvider).settings.scale, scale);
  });

  testWidgets("the node list closes on a click outside without pressing what is under it", (tester) async {
    final container = await _open(tester, _Wallet(), DeskRoute.settingsNode);
    await tester.tap(find.byType(TextField).first);
    await _settle(tester);
    expect(find.byType(ListView), findsWidgets);
    final lists = find.byType(ListView).evaluate().length;
    await tester.tap(find.byWidgetPredicate((w) => w is ENavItem && w.label == 'Activity'));
    await _settle(tester);
    expect(find.byType(ListView).evaluate().length, lessThan(lists), reason: 'the list closed');
    expect(container.read(deskNavProvider).route, DeskRoute.settingsNode);
  });

  testWidgets('Ctrl+L locks the wallet', (tester) async {
    final api = _Wallet();
    final container = await _open(tester, api, DeskRoute.overview);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester);
    expect(api.locks, 1);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
  });
}
