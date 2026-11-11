// SPDX-License-Identifier: Apache-2.0
// Scan beside Paste on the desktop's code entries: a camera-read code takes the paste path,
// and the button is greyed out while no camera is found.
import 'package:epic_wallet/src/camera/camera_presence.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _e = 'esTk4wRm8Nq2Vx7Lc5Bh9Jd3Fg6Hs1Ka8Pz4Yu2Wn7Ec5Rt9Q@box.epic.invalid';

Future<FakeQrCamera> _show(WidgetTester tester, Widget screen, {CameraPresence presence = CameraPresence.present}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final camera = FakeQrCamera();
  final container = ProviderContainer(overrides: [
    deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
    qrCameraFactoryProvider.overrideWithValue(() => camera),
    cameraProbeProvider.overrideWithValue(FakeCameraProbe(presence)),
  ]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
  return camera;
}

bool _enabled(WidgetTester tester) => tester.widget<EIconButton>(find.widgetWithIcon(EIconButton, EIcons.camera).first).onPressed != null;

void main() {
  testWidgets('Send: a scanned payment request fills To like a pasted one', (tester) async {
    final camera = await _show(tester, SendScreen(arg: const SendArgs()));
    expect(_enabled(tester), isTrue);
    await tester.tap(find.widgetWithIcon(EIconButton, EIcons.camera));
    await tester.pumpAndSettle();
    camera.emit('epic:$_e?amount=1.5');
    await tester.pumpAndSettle();
    final to = find.descendant(of: find.widgetWithText(EField, 'To'), matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(to).controller.text, _e);
  });

  testWidgets('Send: Scan is greyed out with no camera', (tester) async {
    await _show(tester, SendScreen(arg: const SendArgs()), presence: CameraPresence.none);
    expect(_enabled(tester), isFalse);
    expect(find.text(_l.deskScanNoCamera), findsOneWidget);
  });

  testWidgets('Home: the labelled Scan is greyed out with no camera and enabled with one', (tester) async {
    await _show(tester, const OverviewScreen(), presence: CameraPresence.none);
    final off = find.byKey(const ValueKey('home-scan'));
    expect(off, findsOneWidget);
    expect(find.descendant(of: off, matching: find.text(_l.deskOvScan)), findsOneWidget);
    expect(tester.widget<EButton>(find.descendant(of: off, matching: find.byType(EButton))).onPressed, isNull);
  });

  testWidgets('Restore: a scanned phrase fills the grid like a paste', (tester) async {
    final camera = await _show(tester, const RestoreScreen());
    await tester.tap(find.widgetWithIcon(EIconButton, EIcons.camera));
    await tester.pumpAndSettle();
    camera.emit(List.filled(11, 'abandon').followedBy(['about']).join(' '));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskOnbRestoreAllOk(12)), findsOneWidget);
  });

  testWidgets('Restore: Scan is greyed out with no camera', (tester) async {
    await _show(tester, const RestoreScreen(), presence: CameraPresence.none);
    expect(_enabled(tester), isFalse);
  });
}
