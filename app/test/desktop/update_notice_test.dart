// The sidebar's update notice (app/update_notice.dart): nothing without an update; Update
// available → Downloading 42 % → Restart to update; a failed step says so and offers the next
// way; a click does the step. Also in the shell, wide and narrow, and in Settings › About.
import 'dart:io';

import 'package:epic_wallet/src/btlabs_public.dart' show WalletDesktopFile, walletDesktopDownloads;
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/app/update_notice.dart';
import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/desktop/data/files.dart' show deskOpenUrlProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _v = '99.1.0';
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
  _Fake(this.initial, {this.restartOk = false});

  final DeskUpdateState initial;
  final bool restartOk;
  int downloads = 0, restarts = 0, retries = 0;

  /// Runs inside restart(), while the button's widget may be on its way out.
  Future<void> Function()? beforeReturn;

  @override
  DeskUpdateState build() => initial;

  @override
  Future<void> download() async => downloads++;

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

  Future<ProviderContainer> pump(WidgetTester tester, DeskUpdateState s, {Widget? home, Size size = const Size(1280, 800), bool restartOk = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    fake = _Fake(s, restartOk: restartOk);
    opened = [];
    quits = 0;
    final container = ProviderContainer(overrides: [
      deskUpdateProvider.overrideWith(() => fake),
      deskOpenUrlProvider.overrideWithValue((url) async {
        opened.add(url);
        return true;
      }),
      deskQuitProvider.overrideWithValue(() async => quits++),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: home ?? const Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: 200, child: DeskUpdateNotice()))),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Finder notice() => find.byKey(const ValueKey('update-notice'));

  testWidgets('nothing shows without an update', (tester) async {
    for (final phase in [DeskUpdatePhase.idle, DeskUpdatePhase.checking, DeskUpdatePhase.latest, DeskUpdatePhase.failed]) {
      await pump(tester, DeskUpdateState(phase));
      expect(notice(), findsNothing, reason: '$phase');
    }
  });

  testWidgets('Update available: a click downloads it', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available));
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text(_v), findsOneWidget);
    await tester.tap(notice());
    await tester.pump();
    expect(fake.downloads, 1);
    expect(opened, isEmpty);
  });

  testWidgets('Update available where it cannot install itself: a click opens the download page', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available, inApp: false));
    expect(find.text('Update available'), findsOneWidget);
    await tester.tap(notice());
    await tester.pump();
    expect(fake.downloads, 0);
    expect(opened, [deskReleasesUrl]);
  });

  testWidgets('Downloading 42 %: a bar, and no click', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.downloading, progress: 0.42));
    expect(find.text('Downloading 42 %'), findsOneWidget);
    expect(tester.widget<EProgress>(find.byType(EProgress)).value, 0.42);
    expect(find.descendant(of: find.byType(DeskUpdateNotice), matching: find.byType(InkWell)), findsNothing);
  });

  testWidgets('a failed download: Try again downloads again', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.available, problem: 'The download stopped.'));
    expect(find.text("Couldn't download the update"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(notice());
    await tester.pump();
    expect(fake.downloads, 1);
  });

  testWidgets('Restart to update: the app still quits when the button is gone by then', (tester) async {
    final show = ValueNotifier(true);
    await pump(
      tester,
      _state(DeskUpdatePhase.ready),
      restartOk: true,
      home: Scaffold(
        body: ValueListenableBuilder<bool>(valueListenable: show, builder: (_, on, _) => on ? const DeskUpdateNotice() : const SizedBox()),
      ),
    );
    fake.beforeReturn = () async {
      show.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    };
    await tester.runAsync(() async {
      await tester.tap(notice());
      await tester.pump();
      // Real time, bounded: under a loaded full run 300 ms was not always enough.
      for (var i = 0; i < 100 && quits == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();
    expect(notice(), findsNothing);
    expect(fake.restarts, 1);
    expect(quits, 1);
  });

  testWidgets('Restart to update: restarts and quits; one that fails does not quit', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.ready), restartOk: true);
    expect(find.text('Restart to update'), findsOneWidget);
    expect(find.text('$_v is ready'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(notice());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(fake.restarts, 1);
    expect(quits, 1);

    await pump(tester, _state(DeskUpdatePhase.ready));
    await tester.tap(notice());
    await tester.pumpAndSettle();
    expect(fake.restarts, 1);
    expect(quits, 0);
  });

  testWidgets('a failed install offers the download page', (tester) async {
    await pump(tester, _state(DeskUpdatePhase.ready, problem: 'The new version could not be put in place.'));
    expect(find.text("Couldn't install the update"), findsOneWidget);
    expect(find.text('Open the download page'), findsOneWidget);
    await tester.tap(notice());
    await tester.pump();
    expect(fake.restarts, 0);
    expect(opened, [deskReleasesUrl]);
  });

  testWidgets("an update that did not finish: Try again runs it again and quits; one that stops does not", (tester) async {
    await pump(tester, _state(DeskUpdatePhase.unfinished, inApp: false), restartOk: true);
    expect(find.text("Update didn't finish. Try again."), findsOneWidget);
    expect(find.text(_v), findsOneWidget);
    expect(find.byIcon(EIcons.alert), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(notice());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(fake.retries, 1);
    expect(quits, 1);

    await pump(tester, _state(DeskUpdatePhase.unfinished, inApp: false));
    await tester.tap(notice());
    await tester.pumpAndSettle();
    expect(fake.retries, 1);
    expect(quits, 0);
  });

  testWidgets('in the sidebar above the statuses, and an icon in the narrow rail', (tester) async {
    const shell = DeskShell(at: DeskLocation(DeskRoute.overview));
    await pump(tester, _state(DeskUpdatePhase.available), home: shell);
    expect(notice(), findsOneWidget);
    expect(tester.getBottomLeft(notice()).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey('rail'))).dy));
    await tester.pumpWidget(const SizedBox());

    await pump(tester, _state(DeskUpdatePhase.available), home: shell, size: const Size(900, 800));
    expect(notice(), findsNothing);
    final icon = find.widgetWithIcon(EIconButton, EIcons.download);
    expect(icon, findsOneWidget);
    expect(tester.widget<EIconButton>(icon).label, startsWith('Update available · $_v'));
    await tester.tap(icon);
    await tester.pump();
    expect(fake.downloads, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings › About says what the check found and offers nothing: the notice is the one place', (tester) async {
    const about = Scaffold(body: SettingsAboutScreen());
    for (final (s, checks) in [
      (_state(DeskUpdatePhase.available), true),
      (_state(DeskUpdatePhase.available, problem: 'The download stopped.'), true),
      (_state(DeskUpdatePhase.downloading, progress: 0.42), false),
      (_state(DeskUpdatePhase.ready), false),
      (_state(DeskUpdatePhase.ready, problem: 'The new version could not be put in place.'), true),
      (_state(DeskUpdatePhase.unfinished, inApp: false), false),
    ]) {
      final why = '${s.phase} ${s.problem}';
      await pump(tester, s, home: about);
      expect(find.text('Update available: $_v'), findsOneWidget, reason: why);
      expect(find.widgetWithText(EButton, 'Check now'), checks ? findsOneWidget : findsNothing, reason: why);
      for (final offer in ['Download $_v', 'Restart to update', 'Try again', 'Get $_v', "Update didn't finish. Try again."]) {
        expect(find.textContaining(offer), findsNothing, reason: '$why: $offer');
      }
      expect(find.byType(EProgress), findsNothing, reason: why);
      await tester.pumpWidget(const SizedBox());
    }
    expect(fake.downloads + fake.restarts + fake.retries, 0);
    expect(opened, isEmpty);
  });
}
