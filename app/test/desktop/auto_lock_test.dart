// SPDX-License-Identifier: Apache-2.0
// Auto-lock on the desktop (Settings › Account › Security): the open wallet locks after the
// chosen minutes without a key or the mouse (15 by default, 1 to 60), any input starts the
// time again, and off never locks by itself while Lock wallet still works.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int locks = 0;

  @override
  Future<void> lock() async {
    locks++;
  }
}

/// A wallet whose chain scan runs while [scanning] (a restore's first scan, Recheck balance).
class _Scanning extends _Wallet {
  bool scanning = true;

  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: s.tor,
      scanning: scanning,
    );
  }
}

Future<ProviderContainer> _open(WidgetTester tester, _Wallet api, {int? minutes, bool on = true, DeskRoute route = DeskRoute.overview}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)], retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  final s = container.read(deskProvider).settings;
  await tester.runAsync(
    () => container.read(deskProvider.notifier).saveSettings(s.copyWith(autoLockMinutes: minutes ?? s.autoLockMinutes, autoLockOn: on, tourSeen: true)),
  );
  container.read(deskNavProvider.notifier).reset(route);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Future<void> _idle(WidgetTester tester, Duration d) async {
  await tester.pump(d);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('by default it locks after 15 minutes without input', (tester) async {
    final api = _Wallet();
    final container = await _open(tester, api);
    expect((container.read(deskProvider).settings.autoLockMinutes, container.read(deskProvider).settings.autoLockOn), (15, true));
    await _idle(tester, const Duration(minutes: 14));
    expect(api.locks, 0);
    await _idle(tester, const Duration(minutes: 1));
    expect(api.locks, 1);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
  });

  testWidgets('a running chain scan keeps the wallet open; once it ends the idle time locks (item 25)', (tester) async {
    final api = _Scanning();
    final container = await _open(tester, api);
    await _idle(tester, const Duration(minutes: 31));
    expect(api.locks, 0, reason: 'a restore must finish its first scan');
    api.scanning = false;
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await _idle(tester, const Duration(minutes: 15));
    expect(api.locks, 1);
  });

  testWidgets('a key or the mouse starts the idle time again', (tester) async {
    final api = _Wallet();
    await _open(tester, api);
    await _idle(tester, const Duration(minutes: 10));
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await _idle(tester, const Duration(minutes: 10));
    expect(api.locks, 0, reason: 'a key at 10 minutes moved the lock to 25');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(600, 400));
    await mouse.moveTo(const Offset(640, 420));
    await _idle(tester, const Duration(minutes: 14));
    expect(api.locks, 0, reason: 'the mouse at 20 minutes moved it to 35');
    await _idle(tester, const Duration(minutes: 1));
    expect(api.locks, 1);
  });

  testWidgets('the shortest choice locks after one minute, the longest after an hour', (tester) async {
    final quick = _Wallet();
    await _open(tester, quick, minutes: 1);
    await _idle(tester, const Duration(seconds: 50));
    expect(quick.locks, 0);
    await _idle(tester, const Duration(seconds: 10));
    expect(quick.locks, 1);

    final slow = _Wallet();
    await _open(tester, slow, minutes: 60);
    await _idle(tester, const Duration(minutes: 59));
    expect(slow.locks, 0);
    await _idle(tester, const Duration(minutes: 1));
    expect(slow.locks, 1);
  });

  testWidgets('off never locks by itself; Lock wallet still does', (tester) async {
    final api = _Wallet();
    final container = await _open(tester, api, on: false);
    await _idle(tester, const Duration(hours: 3));
    expect(api.locks, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _idle(tester, Duration.zero);
    expect(api.locks, 1);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
  });

  testWidgets('Settings › Security: Never in the list turns it off, a time turns it back on', (tester) async {
    final api = _Wallet();
    final container = await _open(tester, api, route: DeskRoute.settingsSecurity);
    final list = find.byKey(const ValueKey('auto-lock-minutes'));
    await tester.ensureVisible(list);
    await _idle(tester, Duration.zero);
    ESelect<int> select() => tester.widget<ESelect<int>>(list);
    expect(select().value, 15);
    expect(select().items.last.title, _l.autoLockNever);
    select().onChanged(select().items.last.value);
    await _idle(tester, Duration.zero);
    expect(container.read(deskProvider).settings.autoLockOn, isFalse);
    expect(select().value, select().items.last.value);
    select().onChanged(5);
    await _idle(tester, Duration.zero);
    expect(container.read(deskProvider).settings.autoLockOn, isTrue);
    expect(container.read(deskProvider).settings.autoLockMinutes, 5);
  });
}
