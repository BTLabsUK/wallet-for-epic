// SPDX-License-Identifier: Apache-2.0
// An update in the sidebar's slot (app/now_slot.dart) and in Settings › About › Updates
// (app/update_notice.dart): nothing without an update; Update available is a line by itself →
// Downloading 42 % → "Epic Cash … is ready" (Restart now / Later) → … is ready · Restart now; a failed
// step says so and offers the next way; a copy that cannot install updates opens the download
// page at every step and says so; About carries the button for the step and the page's address.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/btlabs_public.dart' show WalletDesktopFile, walletDesktopDownloads;
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/desk_update_apply.dart' show DeskUpdateApplier, DmgApplier, deskUpdateApplierProvider;
import 'package:epic_wallet/src/desktop/data/files.dart' show deskOpenUrlProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _v = '99.1.0';
const _manual = 'This copy cannot install updates itself.';
final _file = WalletDesktopFile(url: Uri.parse('${walletDesktopDownloads}EpicCashDesktop-$_v-x86_64.AppImage'), sha256: 'a' * 64, size: 100);

DeskUpdateState _state(DeskUpdatePhase phase, {bool inApp = true, double? progress, String? problem}) => DeskUpdateState(
  phase,
  version: _v,
  page: deskReleasesUrl,
  file: inApp ? _file : null,
  progress: progress,
  problem: problem,
  download: phase == DeskUpdatePhase.ready ? File('/nowhere/$_v') : null,
);

/// The controller in a given state; records the steps asked of it.
class _Fake extends DeskUpdateController {
  _Fake(this.initial, {this.restartOk = false, this.downloadEnds});

  final DeskUpdateState initial;
  final bool restartOk;

  /// The state a download ends in; null: it stays as it was.
  final DeskUpdateState? downloadEnds;
  int downloads = 0, restarts = 0, retries = 0;

  /// Runs inside restart(), while the button's widget may be on its way out.
  Future<void> Function()? beforeReturn;

  @override
  DeskUpdateState build() => initial;

  @override
  Future<void> download() async {
    downloads++;
    if (downloadEnds != null) state = downloadEnds!;
  }

  @override
  Future<bool> restart() async {
    restarts++;
    await beforeReturn?.call();
    return restartOk;
  }

  @override
  Future<bool> retry() async {
    retries++;
    return restartOk;
  }

  @override
  Future<void> check() async {}

  @override
  Future<void> detect() async {}
}

void main() {
  late _Fake fake;
  late List<String> opened;
  late int quits;
  const shell = DeskShell(at: DeskLocation(DeskRoute.overview));
  const about = Scaffold(body: SettingsAboutScreen());

  /// Bounded: a busy button's spinner, or the locked wallet after a quit, never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<ProviderContainer> pump(
    WidgetTester tester,
    DeskUpdateState s, {
    Widget home = shell,
    Size size = const Size(1280, 800),
    bool restartOk = false,
    DeskUpdateState? downloadEnds,
    DeskUpdateApplier? applier,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    fake = _Fake(s, restartOk: restartOk, downloadEnds: downloadEnds);
    opened = [];
    quits = 0;
    final container = ProviderContainer(overrides: [
      deskUpdateProvider.overrideWith(() => fake),
      deskOpenUrlProvider.overrideWithValue((url) async {
        opened.add(url);
        return true;
      }),
      deskQuitProvider.overrideWithValue(() async => quits++),
      if (applier != null) deskUpdateApplierProvider.overrideWithValue(applier),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: home),
    ));
    await settle(tester);
    return container;
  }

  Finder line() => find.byKey(const ValueKey('now-update'));
  Finder act() => find.byKey(const ValueKey('about-update-act'));
  Finder ready() => find.byKey(const ValueKey('update-ready'));
  String tip(WidgetTester tester) => tester.widget<Tooltip>(find.descendant(of: line(), matching: find.byType(Tooltip)).first).message!;

  /// Taps [target] and lets the restart's real awaits (the quit) run.
  Future<void> tapAndRun(WidgetTester tester, Finder target) async {
    // About is taller than the test window since the Contact row came in: scroll to it first.
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(target);
      await tester.pump();
      // Real time, bounded: under a loaded full run 300 ms was not always enough.
      for (var i = 0; i < 20 && quits == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await settle(tester);
  }

  testWidgets('no update: no line in the slot', (tester) async {
    for (final phase in [DeskUpdatePhase.idle, DeskUpdatePhase.checking, DeskUpdatePhase.latest, DeskUpdatePhase.failed]) {
      await pump(tester, DeskUpdateState(phase));
      expect(line(), findsNothing, reason: '$phase');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Update available is a line by itself (no dot to find first); a click downloads, and the checked download asks to restart; Later keeps Restart now in the slot', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available), downloadEnds: _state(DeskUpdatePhase.ready));
    expect(line(), findsOneWidget);
    expect(find.byKey(const ValueKey('now-update-dot')), findsNothing);
    expect(find.descendant(of: line(), matching: find.text('Update available')), findsOneWidget);
    expect(find.descendant(of: line(), matching: find.text(_v)), findsOneWidget);
    expect(tip(tester), contains('Download $_v'));
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(fake.downloads, 1);
    expect(opened, isEmpty);
    expect(ready(), findsOneWidget);
    expect(find.text('Restart to update'), findsOneWidget);
    expect(find.text('The wallet locks and the app opens again.'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Later'));
    await tester.pumpAndSettle();
    expect(ready(), findsNothing);
    expect(fake.restarts, 0);
    expect(find.descendant(of: line(), matching: find.text('Restart now')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('macOS: the checked disk image opens and the app closes; the user replaces the app', (tester) async {
    const hint = 'The app closes and the disk image opens: drag Epic Cash Desktop into Applications, replace the old one, then open it.';
    await pump(tester, _state(DeskUpdatePhase.available), downloadEnds: _state(DeskUpdatePhase.ready), restartOk: true, applier: const DmgApplier());
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(ready(), findsOneWidget);
    expect(find.descendant(of: ready(), matching: find.text('$_v is ready')), findsOneWidget);
    expect(find.descendant(of: ready(), matching: find.text(hint)), findsOneWidget);
    expect(find.text('Restart now'), findsNothing);
    await tester.tap(find.widgetWithText(EButton, 'Later'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: line(), matching: find.text('Open the disk image')), findsOneWidget);
    expect(tip(tester), contains(hint));
    await tapAndRun(tester, line());
    expect((fake.restarts, quits), (1, 1));
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('the ready dialog: Restart now restarts and quits', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available), downloadEnds: _state(DeskUpdatePhase.ready), restartOk: true);
    await tester.tap(line());
    await tester.pumpAndSettle();
    await tapAndRun(tester, find.widgetWithText(EButton, 'Restart now'));
    expect(fake.restarts, 1);
    expect(quits, 1);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('no ready dialog during a send, nor after a download that failed', (tester) async {
    final container = await pump(tester, _state(DeskUpdatePhase.available), downloadEnds: _state(DeskUpdatePhase.ready));
    final done = Completer<void>();
    final send = container.read(deskSendingProvider.notifier).during(() => done.future);
    await tester.pump();
    await tester.tap(line());
    // The send's line moves without end: no settling while it shows.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(fake.downloads, 1);
    expect(ready(), findsNothing, reason: 'a send is under way');
    expect(find.descendant(of: line(), matching: find.text('Restart now')), findsOneWidget);
    done.complete();
    await send;
    await tester.pumpWidget(const SizedBox());

    await pump(tester, _state(DeskUpdatePhase.available), downloadEnds: _state(DeskUpdatePhase.available, problem: 'The download stopped.'));
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(ready(), findsNothing);
    expect(find.descendant(of: line(), matching: find.text('Could not download the update')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('a copy that cannot install updates: the line opens the download page and says so', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available, inApp: false));
    expect(find.descendant(of: line(), matching: find.text('Update available')), findsOneWidget);
    expect(tip(tester), allOf(contains('Opens the download page'), contains(_manual)));
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(fake.downloads, 0);
    expect(opened, [deskReleasesUrl]);
    expect(ready(), findsNothing);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('the narrow rail keeps the line as an icon with its words in the tooltip', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available), size: const Size(900, 800));
    expect(line(), findsOneWidget);
    expect(tip(tester), contains('Update available · $_v'));
    expect(find.descendant(of: line(), matching: find.byIcon(EIcons.download)), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('Update ready: the line restarts; one that fails does not quit', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.ready), restartOk: true);
    expect(find.descendant(of: line(), matching: find.text('Restart now')), findsOneWidget);
    await tapAndRun(tester, line());
    expect(fake.restarts, 1);
    expect(quits, 1);
    await tester.pumpWidget(const SizedBox());

    await pump(tester, _state(DeskUpdatePhase.ready));
    await tapAndRun(tester, line());
    expect(fake.restarts, 1);
    expect(quits, 0);
    await tester.pumpWidget(const SizedBox());
  }, skip: !inAppUpdates);

  testWidgets('Settings › About: the page address is always there, to open or copy', (tester) async {
    await pump(tester, const DeskUpdateState(DeskUpdatePhase.latest), home: about);
    expect(find.text('Download page'), findsOneWidget);
    expect(find.text('examples.btlabs.uk/epic-cash-wallets'), findsOneWidget);
    final row = find.ancestor(of: find.text('Download page'), matching: find.byType(ESetRow));
    expect(find.descendant(of: row, matching: find.byType(LinkCopyButton)), findsOneWidget);
    expect(find.widgetWithText(EButton, 'Check now'), findsOneWidget);
    expect(act(), findsNothing);
    await tester.ensureVisible(find.descendant(of: row, matching: find.widgetWithText(EButton, 'Open')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: row, matching: find.widgetWithText(EButton, 'Open')));
    await tester.pumpAndSettle();
    expect(opened, [deskReleasesUrl]);
  }, skip: !inAppUpdates);

  testWidgets('Settings › About: each step has its button, and it does the step', (tester) async {
    for (final (s, title, label, inApp, checks) in [
      (_state(DeskUpdatePhase.available), 'Update available: $_v', 'Download and install', true, true),
      (_state(DeskUpdatePhase.available, problem: 'The download stopped.'), 'Could not download the update', 'Try again', true, true),
      (_state(DeskUpdatePhase.ready), '$_v is ready', 'Restart to update', true, false),
      (_state(DeskUpdatePhase.ready, problem: 'The new version could not be put in place.'), 'Could not install the update', 'Open the download page', true, true),
      (_state(DeskUpdatePhase.unfinished, inApp: false), 'Update did not finish. Try again.', 'Try again', false, false),
      (_state(DeskUpdatePhase.available, inApp: false), 'Update available: $_v', 'Open the download page', false, true),
    ]) {
      final why = '${s.phase} ${s.problem} ${s.file != null}';
      await pump(tester, s, home: about, downloadEnds: _state(DeskUpdatePhase.ready));
      expect(find.text(title), findsOneWidget, reason: why);
      expect(tester.widget<EButton>(act()).label, label, reason: why);
      expect(find.widgetWithText(EButton, 'Check now'), checks ? findsOneWidget : findsNothing, reason: why);
      expect(find.textContaining(_manual), inApp ? findsNothing : findsOneWidget, reason: why);
      await tapAndRun(tester, act());
      switch (label) {
        case 'Download and install' || 'Try again' when s.phase == DeskUpdatePhase.available:
          expect(fake.downloads, 1, reason: why);
          expect(ready(), findsOneWidget, reason: '$why: the checked download asks to restart');
        case 'Restart to update':
          expect(fake.restarts, 1, reason: why);
        case 'Try again':
          expect(fake.retries, 1, reason: why);
        default:
          expect(opened, [deskReleasesUrl], reason: why);
      }
      await tester.pumpWidget(const SizedBox());
    }
  }, skip: !inAppUpdates);

  testWidgets('Settings › About while it downloads: the percent, and the button waits', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.downloading, progress: 0.42), home: about);
    expect(find.text('Downloading 42%'), findsOneWidget);
    final b = tester.widget<EButton>(act());
    expect(b.busy, isTrue);
    expect(b.onPressed, isNull);
  }, skip: !inAppUpdates);

  testWidgets('Restart to update from About: the app still quits when About is gone by then', (tester) async {
    final show = ValueNotifier(true);
    await pump(
      tester,
      _state(DeskUpdatePhase.ready),
      restartOk: true,
      home: Scaffold(body: ValueListenableBuilder<bool>(valueListenable: show, builder: (_, on, _) => on ? const SettingsAboutScreen() : const SizedBox())),
    );
    fake.beforeReturn = () async {
      show.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    };
    await tapAndRun(tester, act());
    expect(act(), findsNothing);
    expect(fake.restarts, 1);
    expect(quits, 1);
  }, skip: !inAppUpdates);

  test('checks 20 s after the wallet opens, then every hour', () {
    expect(deskUpdateFirst, const Duration(seconds: 20));
    expect(deskUpdateEvery, const Duration(hours: 1));
  });
}
