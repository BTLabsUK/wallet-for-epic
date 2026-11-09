// SPDX-License-Identifier: Apache-2.0
// Sync in background (lib/src/desktop/app/tray/desk_tray.dart): the window's close hides the
// window to the tray while the built-in node runs, the tray's Open and icon bring it back, its
// Quit closes down as the window's close did, and its switches are the settings' own.
import 'dart:async';

import 'package:epic_wallet/src/desktop/app/close_guard.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/desk_window.dart';
import 'package:epic_wallet/src/desktop/app/tray/tray_host.dart';
import 'package:epic_wallet/src/desktop/app/tray/tray_menu.dart';
import 'package:epic_wallet/src/desktop/data/desk_node.dart' show deskLocalNodeProvider;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Window extends DeskWindow {
  final shown = ValueNotifier(true);
  Future<void> Function()? close;

  @override
  ValueListenable<bool> get visible => shown;

  @override
  set onCloseRequested(Future<void> Function()? run) => close = run;

  @override
  Future<void> hide() async => shown.value = false;

  @override
  Future<void> show() async => shown.value = true;
}

class _Tray extends TrayHost {
  _Tray({this.there = true});

  final bool there;
  final views = <TrayView>[];
  bool inTray = false;

  @override
  ValueListenable<bool> get available => ValueNotifier(there);

  @override
  Future<bool> check() async => there;

  // No pictures: the icon's drawing needs the engine, which a widget test does not run.
  @override
  Future<({List<int> icons, int menu})> sizes() async => (icons: const <int>[], menu: 0);

  @override
  Future<void> show(TrayView view) async {
    views.add(view);
    inTray = true;
  }

  @override
  Future<void> remove() async => inTray = false;

  TrayItem item(String id) => views.last.items.singleWhere((i) => i.id == id);
}

LocalNodeState _node(LocalNodePhase phase) =>
    LocalNodeState(phase: phase, dataFolder: '/data', chainDataPath: '/data/chain_data', at: DateTime(2026, 11, 9), height: 1000);

class _Rig {
  _Rig(this.container, this.window, this.tray, this.nodes);

  final ProviderContainer container;
  final _Window window;
  final _Tray tray;
  final StreamController<LocalNodeState> nodes;
  int quits = 0;

  /// The window's close; its lock and quit run on the test's clock, so it is pumped, not awaited.
  Future<void> close(WidgetTester tester) async {
    unawaited(window.close!());
    await _settle(tester);
  }

  Future<void> activate(WidgetTester tester, String id) async {
    tray.onActivate!(id);
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<_Rig> _open(WidgetTester tester, {LocalNodePhase phase = LocalNodePhase.syncing, bool background = true, bool tray = true}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final window = _Window();
  final host = _Tray(there: tray);
  final nodes = StreamController<LocalNodeState>.broadcast();
  addTearDown(nodes.close);
  late final _Rig rig;
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      deskWindowProvider.overrideWithValue(window),
      deskTrayHostProvider.overrideWithValue(host),
      deskLocalNodeProvider.overrideWith((ref) async* {
        yield _node(phase);
        yield* nodes.stream;
      }),
      deskQuitProvider.overrideWithValue(() async => rig.quits++),
    ],
    retry: (_, _) => null,
  );
  rig = _Rig(container, window, host, nodes);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  final s = container.read(deskProvider).settings;
  await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(tourSeen: true)));
  container.read(settingsPrefsProvider.notifier).set(container.read(settingsPrefsProvider).copyWith(builtin: true, nodeBackground: background));
  container.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(milliseconds: 600));
  // The node's first state reaches the provider.
  container.listen(deskLocalNodeProvider, (_, _) {});
  await _settle(tester);
  return rig;
}

void main() {
  testWidgets('closing with the node syncing hides the window to the tray; the icon brings it back', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    expect(rig.quits, 0);
    expect(rig.window.shown.value, isFalse);
    expect(rig.tray.inTray, isTrue);
    expect(rig.tray.views.last.items.map((i) => i.id), containsAllInOrder([TrayIds.background, TrayIds.epicbox, TrayIds.open, TrayIds.lock, TrayIds.quit]));
    expect(rig.tray.item(TrayIds.background).checked, isTrue);

    rig.tray.onClick!();
    await _settle(tester);
    expect(rig.window.shown.value, isTrue);
    expect(rig.tray.inTray, isFalse);
    expect(rig.quits, 0);

    // Again, and back by the menu's Open wallet.
    await rig.close(tester);
    expect(rig.window.shown.value, isFalse);
    await rig.activate(tester, TrayIds.open);
    expect(rig.window.shown.value, isTrue);
    expect(rig.tray.inTray, isFalse);
  });

  testWidgets('Quit in the tray closes down as the window\'s close does', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    await rig.activate(tester, TrayIds.quit);
    expect(rig.quits, 1);
  });

  testWidgets('closing with nothing running in the background quits as before, with no icon', (tester) async {
    for (final (phase, background, tray) in [
      (LocalNodePhase.stopped, true, true),
      (LocalNodePhase.error, true, true),
      (LocalNodePhase.synced, false, true),
      // No tray to come back by (GNOME without AppIndicator).
      (LocalNodePhase.synced, true, false),
    ]) {
      final rig = await _open(tester, phase: phase, background: background, tray: tray);
      await rig.close(tester);
      expect(rig.quits, 1, reason: '$phase background=$background tray=$tray');
      expect(rig.tray.views, isEmpty);
      expect(rig.window.shown.value, isTrue);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Sync in background is the setting: off in the tray turns the setting off and brings the window back', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    await rig.activate(tester, TrayIds.background);
    expect(rig.container.read(settingsPrefsProvider).nodeBackground, isFalse);
    expect(rig.window.shown.value, isTrue);
    expect(rig.tray.inTray, isFalse);
    // And the other way: Settings' switch on again, the next close goes to the tray.
    rig.container.read(settingsPrefsProvider.notifier).set(rig.container.read(settingsPrefsProvider).copyWith(nodeBackground: true));
    await rig.close(tester);
    expect(rig.window.shown.value, isFalse);
    expect(rig.tray.item(TrayIds.background).checked, isTrue);
  });

  testWidgets('the node stopping while hidden brings the window back; a failed node stays in the tray, marked', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    rig.nodes.add(_node(LocalNodePhase.error));
    await _settle(tester);
    expect(rig.window.shown.value, isFalse);
    expect(rig.tray.views.last.attention, isTrue);
    rig.nodes.add(_node(LocalNodePhase.stopped));
    await _settle(tester);
    expect(rig.window.shown.value, isTrue);
    expect(rig.tray.inTray, isFalse);
  });

  testWidgets('the Epicbox switch in the tray is the wallet\'s listener, and the menu follows it', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    final was = rig.tray.item(TrayIds.epicbox).checked!;
    expect(rig.tray.item(TrayIds.epicbox).enabled, isTrue);
    await rig.activate(tester, TrayIds.epicbox);
    final health = rig.container.read(deskProvider).status!.epicboxHealth;
    expect(health == ServiceHealth.off, was);
    expect(rig.tray.item(TrayIds.epicbox).checked, !was);
    expect(rig.window.shown.value, isFalse);
  });

  testWidgets('Lock wallet in the tray locks; the node line stays and the Epicbox switch is disabled', (tester) async {
    final rig = await _open(tester);
    await rig.close(tester);
    await rig.activate(tester, TrayIds.lock);
    expect(rig.container.read(deskNavProvider).route.bare, isTrue);
    expect(rig.window.shown.value, isFalse);
    expect(rig.tray.item(TrayIds.lock).enabled, isFalse);
    expect(rig.tray.item(TrayIds.epicbox).enabled, isFalse);
    expect(deskHideToTray, isNotNull);
  });
}
