// SPDX-License-Identifier: Apache-2.0
// The window's own title bar and the one close rule: ✕, the window's close request (Alt+F4)
// and Quit close the app with no send running; mid-send they ask, and "Close when it
// finishes" closes once the send is done. No "close now".
import 'dart:async';

import 'package:epic_wallet/src/desktop/app/close_guard.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/desk_window.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart' show ResizeEdge;

final _l = englishStrings;

class _Window extends DeskWindow {
  _Window({this.frame = true});

  /// The app draws the border and all edges (Linux); false: the system's frame (Windows).
  final bool frame;
  final calls = <String>[];
  final _state = ValueNotifier(const DeskWindowState());
  Future<void> Function()? close;

  @override
  bool get frameless => true;

  @override
  bool get drawsFrame => frame;

  @override
  ValueListenable<DeskWindowState> get state => _state;

  @override
  set onCloseRequested(Future<void> Function()? run) => close = run;

  @override
  Future<void> minimize() async => calls.add('min');

  @override
  Future<void> toggleMaximize() async {
    calls.add('max');
    _state.value = _state.value.copyWith(maximized: !_state.value.maximized);
  }

  @override
  Future<void> startDragging() async => calls.add('drag');

  @override
  Future<void> startResizing(ResizeEdge edge) async => calls.add('resize ${edge.name}');

  @override
  Future<void> destroy() async => calls.add('destroy');

  void blur() => _state.value = _state.value.copyWith(focused: false);
}

void main() {
  late _Window window;
  late int quits;

  Future<ProviderContainer> pump(WidgetTester tester, {DeskRoute start = DeskRoute.overview, bool frame = true}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    window = _Window(frame: frame);
    quits = 0;
    final container = ProviderContainer(
      overrides: [
        deskWindowProvider.overrideWithValue(window),
        deskQuitProvider.overrideWithValue(() async => quits++),
        deskStartProvider.overrideWithValue(start),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await tester.pumpAndSettle();
    return container;
  }

  Finder bar(String id) => find.byKey(ValueKey('bar-$id'));

  // A send under way shows a moving bar in the sidebar, which never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // The brand's upper row (its lower row is the build label, its own button).
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tapAt(tester.getTopLeft(bar('brand')) + const Offset(10, 8));
    await tester.pumpAndSettle();
  }

  testWidgets('an open wallet: brand menu, wallet, status, lock and the window controls', (tester) async {
    await pump(tester);
    for (final id in ['brand', 'wallet', 'status-node', 'status-epicbox', 'lock', 'min', 'max', 'close']) {
      expect(bar(id), findsOneWidget, reason: id);
    }
    // The brand opens the app menu with Lock and Quit and their shortcuts.
    await openMenu(tester);
    expect(find.byKey(const ValueKey('bar-menu-lock')), findsOneWidget);
    expect(find.text('Ctrl+Q'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-menu-lock')), findsNothing);
  });

  testWidgets('Keyboard shortcuts lists the settings search: Ctrl+K anywhere, / in Settings', (tester) async {
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text(_l.deskBarShortcuts));
    await tester.pumpAndSettle();
    final dialog = find.byType(EDialog);
    expect(find.descendant(of: dialog, matching: find.text(_l.deskBarKeySearch)), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Ctrl+K')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text(_l.deskBarKeySearchHere)), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('/')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('Unlock keeps only the brand and the window controls', (tester) async {
    await pump(tester, start: DeskRoute.unlock);
    expect(bar('brand'), findsNothing, reason: 'no menu on Unlock');
    for (final id in ['wallet', 'status-node', 'status-epicbox', 'lock']) {
      expect(bar(id), findsNothing, reason: id);
    }
    for (final id in ['min', 'max', 'close']) {
      expect(bar(id), findsOneWidget, reason: id);
    }
  });

  testWidgets('the controls drive the window; maximise turns into restore', (tester) async {
    await pump(tester);
    await tester.tap(bar('min'));
    await tester.tap(bar('max'));
    await tester.pumpAndSettle();
    expect(window.calls, ['min', 'max']);
    expect(find.byTooltip(_l.deskBarRestore), findsOneWidget);
    // Unfocused: nothing breaks, the bar stays.
    window.blur();
    await tester.pumpAndSettle();
    expect(bar('close'), findsOneWidget);
  });

  testWidgets('close with no send running: locks and quits', (tester) async {
    await pump(tester);
    await tester.tap(bar('close'));
    // Closing shows its spinner until the process ends, so no settling.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(quits, 1);
    expect(find.text(_l.deskBarClosing), findsOneWidget);
  });

  testWidgets('close mid-send asks; Keep open keeps the app open after the send too', (tester) async {
    final container = await pump(tester);
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    // The system's close (Alt+F4, the taskbar) goes the same way as ✕.
    unawaited(window.close!());
    await settle(tester);
    expect(find.text(_l.deskBarSendRunningTitle), findsOneWidget);
    expect(find.text(_l.deskBarKeepOpen), findsOneWidget);
    expect(find.text(_l.deskBarCloseAfterSend), findsOneWidget);
    expect(deskHoldExit(), isTrue, reason: 'the exit listener answers cancel meanwhile');
    await tester.tap(find.text('Keep open'));
    await settle(tester);
    done.complete();
    await send;
    await settle(tester);
    expect(quits, 0);
  });

  testWidgets('Close when it finishes: the app closes once the send is done', (tester) async {
    final container = await pump(tester);
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    await tester.tap(bar('close'));
    await settle(tester);
    await tester.tap(find.text('Close when it finishes'));
    await settle(tester);
    expect(quits, 0);
    expect(find.byTooltip('Closes when the send finishes'), findsOneWidget);
    // Ctrl+Q mid-send asks too, never quits at once.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.text('A send is in progress'), findsOneWidget);
    await tester.tap(find.text('Close when it finishes'));
    await settle(tester);
    expect(quits, 0);
    done.complete();
    await send;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(quits, 1);
  });

  testWidgets('the bar moves the window; double-click maximises; edges resize', (tester) async {
    await pump(tester);
    // An empty part of the bar, right of the wallet chip.
    final at = tester.getCenter(bar('wallet')) + const Offset(300, 0);
    await tester.dragFrom(at, const Offset(60, 40));
    await tester.pumpAndSettle();
    expect(window.calls, contains('drag'));
    await tester.dragFrom(const Offset(640, 798), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(window.calls, contains('resize bottom'));
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(window.calls, contains('max'));
  });

  testWidgets('the sidebar slot rests on Help and Report a problem; the wallet shows once, in the bar', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('now-help')), findsOneWidget);
    expect(find.byKey(const ValueKey('now-report')), findsOneWidget);
    expect(find.text('Main wallet'), findsOneWidget, reason: 'the sidebar no longer repeats the wallet');
    expect(find.text('Wallet by BT Labs'), findsNothing);
  });

  testWidgets('no build label in the sidebar (item 7); Copy build info puts the build on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pump(tester);
    expect(find.byKey(const ValueKey('bar-build')), findsNothing);
    await openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('bar-menu-build')));
    await tester.pumpAndSettle();
    expect(copied, startsWith('BT Wallet '));
    expect(copied, contains('core '));
    expect(find.text(_l.deskBarBuildCopied), findsOneWidget);
  });

  testWidgets('the send ends while "A send is in progress" is open: it goes by itself, the dialog under it stays', (tester) async {
    final container = await pump(tester);
    // A dialog of the page under the question (the send's review, in the app).
    var underClosed = false;
    unawaited(
      showDialog<void>(context: deskNavigatorKey.currentContext!, builder: (_) => const Text('under')).then((_) => underClosed = true),
    );
    await tester.pumpAndSettle();
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    await tester.tap(bar('close'));
    await settle(tester);
    expect(find.text('A send is in progress'), findsOneWidget);
    done.complete();
    await send;
    await settle(tester);
    expect(find.text('A send is in progress'), findsNothing);
    expect(find.text('under'), findsOneWidget);
    expect(underClosed, isFalse);
    expect(quits, 0);
  });

  testWidgets('F10 opens the app menu, the keyboard way into the bar', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-menu-quit')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-menu-quit')), findsNothing);
  });

  testWidgets('Windows: the top edge resizes (the hidden caption took the system one)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump(tester, frame: false);
    await tester.dragFrom(const Offset(640, 1), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(window.calls, contains('resize top'));
    debugDefaultTargetPlatformOverride = null;
  });
}
