// SPDX-License-Identifier: Apache-2.0
// The desktop scan dialog: each camera problem says why in place with its buttons, Paste reads the
// clipboard on the press, Close works while the camera starts, a code or all the parts of an
// animated code end the scan, a refused code says so, a dark picture clears by itself, and Scan
// beside a field is greyed out with one quiet line when there is no camera to scan with.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/camera/camera_presence.dart';
import 'package:epic_wallet/src/desktop/screens/scan/desk_scan.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/ui/qr_camera.dart';

final _l = englishStrings;

/// A camera whose start never returns, until [release].
class _SlowCamera extends FakeQrCamera {
  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<void> start() async {
    starts++;
    await _gate.future;
  }
}

/// A camera whose picture problem the test sets while it runs.
class _LiveCamera extends FakeQrCamera {
  QrCameraState? _shown;

  @override
  QrCameraState get value => _shown ?? super.value;

  void show(QrCameraProblem? problem) {
    _shown = QrCameraState(problem: problem);
    notifyListeners();
  }
}

/// Parts of three: each text is one part, the third done; "bad" is refused.
class _ThreeParts implements DeskPartReader<String> {
  final Set<String> seen = {};

  @override
  Future<DeskPartStep<String>> read(String text) async {
    if (text == 'bad') return DeskPartRefused((l) => l.scanPhraseFoundQr);
    seen.add(text);
    if (seen.length == 3) return DeskPartDone(seen.join(','));
    return DeskPartWaiting(seen.length, 3);
  }
}

String? _clip;

void _fakeClipboard(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') return _clip == null ? null : {'text': _clip};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

class _Result {
  bool closed = false;
  DeskScanResult<String>? value;
}

/// A page with one button that opens the scan with [camera] and keeps what it returned.
Future<_Result> _open(WidgetTester tester, FakeQrCamera camera, {DeskPartReader<String>? reader}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final result = _Result();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [qrCameraFactoryProvider.overrideWithValue(() => camera)],
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result.value = await deskScanParts<String>(context, title: _l.scanQrTitle, reader: reader ?? const DeskSingleReader());
                result.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return result;
}

/// Two frames: the read the camera's code started resumes in a microtask, then the line rebuilds.
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Finder _button(String label) => find.widgetWithText(EButton, label);

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(_button(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() {
    deskScanOsOverride = null;
    _clip = null;
  });

  group('each problem says why, with Try again, Paste and Close', () {
    final cases = <(QrCameraProblem, DeskScanOs, String)>[
      (QrCameraProblem.denied, DeskScanOs.windows, _l.deskScanDeniedWindows),
      (QrCameraProblem.denied, DeskScanOs.macos, _l.deskScanDeniedMac),
      (QrCameraProblem.denied, DeskScanOs.linux, _l.deskScanDeniedLinux),
      (QrCameraProblem.unsupported, DeskScanOs.linux, _l.deskScanUnsupportedLinux),
      (QrCameraProblem.unsupported, DeskScanOs.windows, _l.deskScanUnsupportedWindows),
      (QrCameraProblem.unsupported, DeskScanOs.macos, _l.deskScanUnsupportedOther),
      (QrCameraProblem.busy, DeskScanOs.linux, _l.deskScanBusy),
      (QrCameraProblem.failed, DeskScanOs.linux, _l.deskScanFailed),
      (QrCameraProblem.noPicture, DeskScanOs.linux, _l.deskScanNoPicture),
      (QrCameraProblem.unplugged, DeskScanOs.linux, _l.deskScanUnplugged),
      (QrCameraProblem.readerFailed, DeskScanOs.linux, _l.deskScanReaderFailed),
    ];
    for (final (problem, os, line) in cases) {
      testWidgets('${problem.name} on ${os.name}', (tester) async {
        deskScanOsOverride = os;
        final camera = FakeQrCamera(problem: problem);
        final result = await _open(tester, camera);
        expect(find.text(line), findsOneWidget);
        // Hidden, keeping its place, so the dialog does not change height.
        expect(find.text(_l.deskScanAim).hitTestable(), findsNothing);
        expect(_button(_l.deskScanTryAgain), findsOneWidget);
        expect(_button(_l.commonPaste), findsOneWidget);
        expect(_button(_l.commonClose), findsOneWidget);
        expect(camera.starts, 1);

        // Nothing retries by itself; Try again starts once more.
        await tester.pump(const Duration(seconds: 5));
        expect(camera.starts, 1);
        camera.problem = null;
        await _press(tester, _l.deskScanTryAgain);
        expect(camera.starts, 2);
        expect(find.text(line), findsNothing);
        expect(find.text(_l.deskScanAim), findsOneWidget);
        expect(_button(_l.deskScanTryAgain), findsNothing);

        await _press(tester, _l.commonClose);
        expect(result.closed, isTrue);
        expect(result.value, isNull);
        expect(camera.disposed, isTrue);
      });
    }
  });

  testWidgets('Paste reads the clipboard on the press and returns it', (tester) async {
    _fakeClipboard(tester);
    final camera = FakeQrCamera(problem: QrCameraProblem.busy);
    final result = await _open(tester, camera);

    // An empty clipboard keeps the dialog open.
    await _press(tester, _l.commonPaste);
    expect(result.closed, isFalse);

    _clip = '  epic:esXabc  ';
    await _press(tester, _l.commonPaste);
    expect(result.closed, isTrue);
    expect(result.value, isA<DeskPasted<String>>().having((r) => r.text, 'text', 'epic:esXabc'));
  });

  testWidgets('Close works while the camera starts', (tester) async {
    final camera = _SlowCamera();
    final result = await _open(tester, camera);
    expect(find.text(_l.deskScanStarting), findsOneWidget);
    await _press(tester, _l.commonClose);
    expect(result.closed, isTrue);
    expect(result.value, isNull);
    // The start that returns after the close changes nothing.
    camera.release();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single code returns what it read', (tester) async {
    final camera = FakeQrCamera();
    final result = await _open(tester, camera);
    expect(find.text(_l.deskScanAim), findsOneWidget);
    camera.emit('epic:esXabc');
    camera.emit('epic:esXabc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result.closed, isTrue);
    expect(result.value, isA<DeskScanned<String>>().having((r) => r.value, 'value', 'epic:esXabc'));
  });

  testWidgets('an animated code counts its parts, then returns', (tester) async {
    final camera = FakeQrCamera();
    final reader = _ThreeParts();
    final result = await _open(tester, camera, reader: reader);
    camera.emit('a');
    camera.emit('a');
    await _frames(tester);
    expect(find.text(_l.qrScanProgress(1, 3)), findsOneWidget);
    expect(find.byType(EProgress), findsOneWidget);
    camera.emit('b');
    await _frames(tester);
    expect(find.text(_l.qrScanProgress(2, 3)), findsOneWidget);
    expect(result.closed, isFalse);
    camera.emit('c');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result.closed, isTrue);
    expect(result.value, isA<DeskScanned<String>>().having((r) => r.value, 'value', 'a,b,c'));
  });

  testWidgets('a recovery phrase is refused in place and the scan goes on', (tester) async {
    final camera = FakeQrCamera();
    final result = await _open(tester, camera);
    camera.emit(List.filled(12, 'abandon').join(' '));
    await _frames(tester);
    expect(find.text(_l.scanPhraseFoundQr), findsOneWidget);
    expect(result.closed, isFalse);
    camera.emit('epic:esXabc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result.value, isA<DeskScanned<String>>());
  });

  testWidgets('a dark picture says so over the picture and clears by itself', (tester) async {
    final camera = _LiveCamera();
    final result = await _open(tester, camera);
    camera.show(QrCameraProblem.dark);
    await tester.pump();
    expect(find.text(_l.deskScanDark), findsOneWidget);
    expect(find.text('camera'), findsOneWidget, reason: 'the picture stays');
    expect(_button(_l.deskScanTryAgain), findsNothing);
    camera.show(null);
    await tester.pump();
    expect(find.text(_l.deskScanDark), findsNothing);
    expect(find.text(_l.deskScanAim), findsOneWidget);
    // Codes still read while it was dark.
    camera.show(QrCameraProblem.dark);
    camera.emit('epic:esXabc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result.value, isA<DeskScanned<String>>());
  });

  group('Scan beside a field', () {
    Future<void> pumpField(WidgetTester tester, CameraPresence presence) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cameraProbeProvider.overrideWithValue(FakeCameraProbe(presence))],
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(
              body: Column(children: [DeskScanButton(onScan: () {}), const DeskNoCameraLine()]),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    EIconButton scan(WidgetTester tester) => tester.widget<EIconButton>(find.byType(EIconButton));

    testWidgets('no camera: greyed out, one line', (tester) async {
      await pumpField(tester, CameraPresence.none);
      expect(scan(tester).onPressed, isNull);
      expect(find.text(_l.deskScanNoCamera), findsOneWidget);
    });

    testWidgets('unsupported: greyed out, what the system lacks', (tester) async {
      deskScanOsOverride = DeskScanOs.linux;
      await pumpField(tester, CameraPresence.unsupported);
      expect(scan(tester).onPressed, isNull);
      expect(find.text(_l.deskScanUnsupportedLinux), findsOneWidget);
    });

    testWidgets('a camera: offered, no line', (tester) async {
      await pumpField(tester, CameraPresence.present);
      expect(scan(tester).onPressed, isNotNull);
      expect(find.text(_l.deskScanNoCamera), findsNothing);
    });

    testWidgets('denied: offered, the scan says why', (tester) async {
      await pumpField(tester, CameraPresence.denied);
      expect(scan(tester).onPressed, isNotNull);
      expect(find.text(_l.deskScanNoCamera), findsNothing);
    });
  });
}
