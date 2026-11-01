// SPDX-License-Identifier: Apache-2.0
// The screen that shows a payment or its reply as an animated QR code: hidden until shown,
// 3 · 2 · 1, the code for 40 s, then covered again; covered at once when the app leaves; the
// whole route blocks screenshots.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_scan_screen.dart';
import 'package:epic_wallet/src/ui/qr_show_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three parts of a payment.
final String _json =
    '{"id":"slate-1","pad":"${'a' * (qrFragmentLen * 3 - 30)}"}';

class _Harness {
  final service = FakeWalletService();
  final camera = FakeQrCamera();
  final secure = <bool>[];
  QrShowResult? result;
  bool popped = false;

  Future<void> pump(
    WidgetTester tester, {
    bool reply = false,
    bool reduced = false,
    double textScale = 1,
    Size size = const Size(1080, 2340),
    bool scanEnabled = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('epic_wallet/secure_screen'),
      (call) async {
        if (call.method == 'setSecure') secure.add(call.arguments as bool);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('epic_wallet/secure_screen'),
        null,
      ),
    );
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
              disableAnimations: reduced,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final r = reply
                        ? await showReplyQr(
                            context,
                            json: _json,
                            amount: BigInt.from(150000000),
                          )
                        : await showPaymentQr(
                            context,
                            json: _json,
                            amount: BigInt.from(150000000),
                            scanEnabled: scanEnabled,
                          );
                    result = r;
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
  }
}

Future<void> _tick(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  Finder show() => find.byKey(qrShowButtonKey);

  testWidgets('hidden first; Show QR counts 3, 2, 1, then shows the code', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text('Payment QR'), findsOneWidget);
    expect(find.text('Hidden until you show it'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);
    expect(find.text('1.50000000\u00a0EPIC to a phone next to you'), findsOneWidget);
    expect(find.textContaining('Part '), findsNothing);

    await tester.tap(show());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Part 1 of 3'), findsOneWidget);
    expect(find.textContaining('40 s'), findsOneWidget);
    // The code itself is painted, and the cover's words are gone from the card.
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byKey(qrCardKey),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.painter.runtimeType.toString());
    expect(painters, contains('_QrPainter'));
    expect(
      find.descendant(
        of: find.byKey(qrCardKey),
        matching: find.text('Hidden until you show it'),
      ),
      findsNothing,
    );
    expect(find.text('Scan their reply'), findsOneWidget);
    expect(find.text('Hold the other phone’s camera to this code.'), findsOneWidget);
    // The frames cycle at six a second: part 2 after 167 ms.
    await tester.pump(const Duration(milliseconds: qrFrameMs));
    expect(find.textContaining('Part 2 of 3'), findsOneWidget);
  });

  testWidgets('after 40 s it hides, and Show again starts the countdown again', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await _tick(tester, 39);
    expect(find.textContaining('Part '), findsOneWidget);
    expect(find.textContaining('1 s'), findsOneWidget);
    await _tick(tester, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hidden after 40 s'), findsOneWidget);
    expect(find.textContaining('Part '), findsNothing);
    expect(find.text('Show again'), findsOneWidget);
    expect(find.text('Scan their reply'), findsOneWidget);

    await tester.tap(show());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the last ten seconds turn the seconds amber', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await _tick(tester, 29);
    Color? colorOf(String text) {
      Color? found;
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        rich.text.visitChildren((span) {
          if (span is TextSpan && span.text == text) found = span.style?.color;
          return true;
        });
      }
      return found;
    }

    final calm = colorOf('11 s');
    await _tick(tester, 1);
    expect(colorOf('10 s'), isNot(calm));
  });

  testWidgets('leaving the app covers the code and stays covered', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    expect(find.textContaining('Part '), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Part '), findsNothing);
    expect(find.text('Hidden while the app was away'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hidden while the app was away'), findsOneWidget);
    expect(find.text('Show again'), findsOneWidget);
    // Frames stopped with it: no timer is left running.
    await _tick(tester, 5);
    expect(find.textContaining('Part '), findsNothing);
  });

  testWidgets('going away during the countdown also covers it', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hidden while the app was away'), findsOneWidget);
    await _tick(tester, 5);
    expect(find.textContaining('Part '), findsNothing);
  });

  testWidgets('Hide covers the code at once', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await tester.tap(find.byKey(qrHideButtonKey));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hidden until you show it'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);
    await _tick(tester, 45);
    expect(find.text('Hidden until you show it'), findsOneWidget);
  });

  testWidgets('screenshots are blocked while the route is open', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    // Tests run as Android.
    expect(h.secure, [true]);
    await tester.tap(show());
    await _tick(tester, 3);
    // The line about screenshots shows with the code, on Android only.
    expect(find.text('Screenshots are off on this screen'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(h.secure, [true, false]);
  });

  testWidgets('Scan their reply goes to the camera and returns what it read', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await tester.tap(find.byKey(qrNextButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scan their reply'), findsWidgets);
    expect(find.text('camera'), findsOneWidget);
    final reply = '{"id":"slate-2","step":"response"}';
    final parts = await h.service.encodeQrSlate(
      json: reply,
      maxFragmentLen: qrFragmentLen,
    );
    for (final p in parts) {
      h.camera.emit(p);
    }
    await tester.pump();
    await tester.pump();
    await tester.pump(qrCompleteFor);
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.popped, isTrue);
    expect((h.result! as QrShowScanned).json, reply);
  });

  testWidgets('backing out of the scan leaves the code covered', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await tester.tap(find.byKey(qrNextButtonKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(tester.element(find.byType(QrScanScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.popped, isFalse);
    expect(find.text('Hidden while the app was away'), findsOneWidget);
    expect(find.text('Show again'), findsOneWidget);
  });

  testWidgets('Open a file instead on the camera hands the choice back', (
    tester,
  ) async {
    final h = _Harness();
    h.camera.problem = QrCameraProblem.denied;
    await h.pump(tester);
    await tester.tap(show());
    await _tick(tester, 3);
    await tester.tap(find.byKey(qrNextButtonKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open a file instead'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.result, isA<QrShowOpenFile>());
  });

  testWidgets('a blocked network mode switches the scan button off', (tester) async {
    final h = _Harness();
    await h.pump(tester, scanEnabled: false);
    await tester.tap(show());
    await _tick(tester, 3);
    expect(
      tester.widget<FilledButton>(find.byKey(qrNextButtonKey)).onPressed,
      isNull,
    );
  });

  testWidgets('the reply flavour: Reply QR, a reply cover, Done closes it', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, reply: true);
    expect(find.text('Reply QR'), findsOneWidget);
    expect(find.text('To the sender of 1.50000000\u00a0EPIC'), findsOneWidget);
    expect(
      find.text('Show it to the sender’s phone. Only their wallet can use it.'),
      findsOneWidget,
    );
    // The reply gets the same countdown and 40 s.
    await tester.tap(show());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3'), findsOneWidget);
    await _tick(tester, 3);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.byKey(qrNextButtonKey));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.result, isA<QrShowDone>());
  });

  testWidgets('reduced motion still counts, cycles and hides', (tester) async {
    final h = _Harness();
    await h.pump(tester, reduced: true);
    await tester.tap(show());
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await _tick(tester, 3);
    expect(find.textContaining('Part 1 of 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: qrFrameMs));
    expect(find.textContaining('Part 2 of 3'), findsOneWidget);
    await _tick(tester, 40);
    expect(find.text('Hidden after 40 s'), findsOneWidget);
  });

  testWidgets('fits a 360 x 640 phone at large text without overflowing', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester, size: const Size(1080, 1920), textScale: 1.3);
    await tester.tap(show());
    await _tick(tester, 3);
    expect(tester.takeException(), isNull);
    expect(find.byKey(qrCardKey), findsOneWidget);
    final card = tester.getSize(find.byKey(qrCardKey));
    expect(card.width, 270);
    // The seconds and the part stay reachable: the body scrolls, the title is not clipped.
    await tester.dragUntilVisible(
      find.textContaining('Part '),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -80),
    );
    expect(find.textContaining('Part '), findsOneWidget);
  });
}
