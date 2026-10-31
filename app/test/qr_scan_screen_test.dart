// SPDX-License-Identifier: Apache-2.0
// The camera screen that reads an animated payment QR: the count rises with each new part, a
// code that is no payment is said so and the rest kept, a part of another payment starts
// over, a silent camera is told to hold steady, and a refused camera has a way out.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_scan_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _json(int parts, [String tag = 'a']) =>
    '{"id":"$tag","pad":"${tag * (qrFragmentLen * parts - 20)}"}';

class _Harness {
  final service = FakeWalletService();
  final camera = FakeQrCamera();
  QrScanResult? result;
  bool popped = false;

  Future<List<String>> parts(String json) =>
      service.encodeQrSlate(json: json, maxFragmentLen: qrFragmentLen);

  Future<void> pump(
    WidgetTester tester, {
    QrScanKind kind = QrScanKind.payment,
    double textScale = 1,
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          qrCameraFactoryProvider.overrideWithValue(() => camera),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await scanQrSlate(context, kind);
                    popped = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Hands [text] to the reader and lets its async decoding finish.
  Future<void> see(WidgetTester tester, String text) async {
    camera.emit(text);
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  testWidgets('aims first, then reads parts in any order and finishes with the payment', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text('Scan payment QR'), findsOneWidget);
    expect(h.camera.started, isTrue);
    expect(
      find.text('Point the camera at the QR code on their phone.'),
      findsOneWidget,
    );
    final json = _json(3);
    final parts = await h.parts(json);

    await h.see(tester, parts[1]);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(
      find.text('Scanned 1 of 3. Keep the code in the frame.'),
      findsOneWidget,
    );
    // The camera sees the same frame again and again.
    await h.see(tester, parts[1]);
    expect(find.text('1 of 3'), findsOneWidget);
    await h.see(tester, parts[2]);
    expect(find.text('2 of 3'), findsOneWidget);
    await h.see(tester, parts[0]);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('Code read'), findsOneWidget);
    expect(h.popped, isFalse);

    await tester.pump(qrCompleteFor);
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.popped, isTrue);
    expect((h.result! as QrScanned).json, json);
    await tester.pumpAndSettle();
    expect(h.camera.disposed, isTrue);
  });

  testWidgets('the reply scanner words its hints for a reply', (tester) async {
    final h = _Harness();
    await h.pump(tester, kind: QrScanKind.reply);
    expect(find.text('Scan their reply'), findsOneWidget);
    expect(
      find.text('Point the camera at the reply on their phone.'),
      findsOneWidget,
    );
    await h.see(tester, 'https://example.com');
    expect(
      find.text('That is not a reply QR. Ask them to show the reply on their phone.'),
      findsOneWidget,
    );
    await tester.pump(qrNoticeFor);
  });

  testWidgets('a code that is no payment is said so, the count is kept, the line goes back', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    final parts = await h.parts(_json(3));
    await h.see(tester, parts[0]);
    await h.see(tester, 'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@epicbox.epiccash.com');
    expect(
      find.text('That is not a payment QR. Ask them to show the payment QR.'),
      findsOneWidget,
    );
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.pump(qrNoticeFor);
    await tester.pump();
    expect(
      find.text('Scanned 1 of 3. Keep the code in the frame.'),
      findsOneWidget,
    );
    await h.see(tester, parts[1]);
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('a part of another payment says so and reading starts over', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    final mine = await h.parts(_json(3));
    final other = await h.parts(_json(3, 'b'));
    await h.see(tester, mine[0]);
    await h.see(tester, mine[1]);
    expect(find.text('2 of 3'), findsOneWidget);
    await h.see(tester, other[0]);
    expect(
      find.text('This code belongs to a different payment. Starting over.'),
      findsOneWidget,
    );
    await tester.pump(qrOtherPaymentFor);
    await tester.pump();
    expect(find.text('2 of 3'), findsNothing);
    await h.see(tester, other[1]);
    expect(find.text('1 of 3'), findsOneWidget);
    // Nothing was handed back.
    expect(h.popped, isFalse);
  });

  testWidgets('four seconds without a new part says to hold steady', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    final parts = await h.parts(_json(3));
    await h.see(tester, parts[0]);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold steady, or move a little closer.'), findsNothing);
    // A part already known does not count as new.
    await h.see(tester, parts[0]);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Hold steady, or move a little closer.'), findsOneWidget);
    await h.see(tester, parts[1]);
    expect(
      find.text('Scanned 2 of 3. Keep the code in the frame.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('torch and zoom follow the camera', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text('1×'), findsOneWidget);
    await tester.tap(find.text('1×'));
    await tester.pump();
    expect(h.camera.value.zoomed, isTrue);
    expect(find.text('2×'), findsOneWidget);
    expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
    await tester.tap(find.byTooltip('Torch'));
    await tester.pump();
    expect(h.camera.value.torchOn, isTrue);
    expect(find.byIcon(Icons.flashlight_on), findsOneWidget);
  });

  testWidgets('no torch button on a phone without a torch', (tester) async {
    final h = _Harness();
    final noTorch = FakeQrCamera(torchAvailable: false);
    h.camera.dispose();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(h.service),
          qrCameraFactoryProvider.overrideWithValue(() => noTorch),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QrScanScreen.payment(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Torch'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a refused camera shows three ways out', (tester) async {
    final h = _Harness();
    h.camera.problem = QrCameraProblem.denied;
    await h.pump(tester);
    expect(find.textContaining('Camera access is off'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Open a file instead'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Open a file instead'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.result, isA<QrScanOpenFile>());
  });

  testWidgets('a camera still closing (Home\'s scan handing over) starts on the second try', (
    tester,
  ) async {
    final h = _Harness();
    h.camera.problem = QrCameraProblem.failed;
    await h.pump(tester);
    h.camera.problem = null;
    await tester.pump(qrCameraRetryAfter);
    await tester.pump();
    expect(h.camera.starts, 2);
    expect(find.textContaining('The camera could not start'), findsNothing);
  });

  testWidgets('a camera that failed twice offers Try again, which starts it again', (
    tester,
  ) async {
    final h = _Harness();
    h.camera.problem = QrCameraProblem.failed;
    await h.pump(tester);
    // The first start tries once more, for a camera another scanner was still closing.
    await tester.pump(qrCameraRetryAfter);
    await tester.pump();
    expect(h.camera.starts, 2);
    expect(find.textContaining('The camera could not start'), findsOneWidget);
    expect(find.text('Open settings'), findsNothing);
    final starts = h.camera.starts;
    h.camera.problem = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(h.camera.starts, starts + 1);
    expect(find.textContaining('The camera could not start'), findsNothing);
    expect(
      find.text('Point the camera at the QR code on their phone.'),
      findsOneWidget,
    );
  });

  testWidgets('fits a small phone at large text', (tester) async {
    final h = _Harness();
    await h.pump(tester, size: const Size(1080, 1920), textScale: 1.3);
    final parts = await h.parts(_json(3));
    await h.see(tester, parts[0]);
    expect(tester.takeException(), isNull);
    expect(find.text('1 of 3'), findsOneWidget);
  });
}
