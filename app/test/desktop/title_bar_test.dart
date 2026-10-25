// The window's own title bar and the one close rule: ✕, the window's close request (Alt+F4)
// and Quit close the app with no send running; mid-send they ask, and "Close when it
// finishes" closes once the send is done. No "close now".
import 'dart:async';

import 'package:epic_wallet/src/desktop/app/close_guard.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/desk_window.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart' show ResizeEdge;

class _Window extends DeskWindow {
  final calls = <String>[];
  final _state = ValueNotifier(const DeskWindowState());
  Future<void> Function()? close;

  @override
  bool get frameless => true;

  @override
  bool get drawsFrame => true;

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

  Future<ProviderContainer> pump(WidgetTester tester, {DeskRoute start = DeskRoute.overview}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    window = _Window();
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

  testWidgets('an open wallet: brand menu, wallet, status, lock and the window controls', (tester) async {
    await pump(tester);
    for (final id in ['brand', 'wallet', 'status', 'lock', 'min', 'max', 'close']) {
      expect(bar(id), findsOneWidget, reason: id);
    }
    // The brand opens the app menu with Lock and Quit and their shortcuts.
    await tester.tap(bar('brand'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-menu-lock')), findsOneWidget);
    expect(find.text('Ctrl+Q'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-menu-lock')), findsNothing);
  });

  testWidgets('Unlock keeps only the brand and the window controls', (tester) async {
    await pump(tester, start: DeskRoute.unlock);
    expect(bar('brand'), findsNothing, reason: 'no menu on Unlock');
    for (final id in ['wallet', 'status', 'lock']) {
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
    expect(find.byTooltip('Restore'), findsOneWidget);
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
    expect(find.text('Closing'), findsOneWidget);
  });

  testWidgets('close mid-send asks; Keep open keeps the app open after the send too', (tester) async {
    final container = await pump(tester);
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    // The system's close (Alt+F4, the taskbar) goes the same way as ✕.
    unawaited(window.close!());
    await tester.pumpAndSettle();
    expect(find.text('A send is in progress'), findsOneWidget);
    expect(find.text('Keep open'), findsOneWidget);
    expect(find.text('Close when it finishes'), findsOneWidget);
    expect(deskHoldExit(), isTrue, reason: 'the exit listener answers cancel meanwhile');
    await tester.tap(find.text('Keep open'));
    await tester.pumpAndSettle();
    done.complete();
    await send;
    await tester.pumpAndSettle();
    expect(quits, 0);
  });

  testWidgets('Close when it finishes: the app closes once the send is done', (tester) async {
    final container = await pump(tester);
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    await tester.tap(bar('close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close when it finishes'));
    await tester.pumpAndSettle();
    expect(quits, 0);
    expect(find.byTooltip('Closes when the send finishes'), findsOneWidget);
    // Ctrl+Q mid-send asks too, never quits at once.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('A send is in progress'), findsOneWidget);
    await tester.tap(find.text('Close when it finishes'));
    await tester.pumpAndSettle();
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
}
