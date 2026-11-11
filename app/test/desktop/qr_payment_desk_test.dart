// SPDX-License-Identifier: Apache-2.0
// QR Payment on the desktop: a payment, a reply, a finished payment and an invoice read as an
// animated QR code where a file or a paste is taken, the reply shown as one, Show QR cycling its
// parts, and Send's To with a part read by the camera or pasted.
import 'dart:async';

import 'package:epic_wallet/src/camera/camera_presence.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/scan/desk_scan.dart' show DeskScanDialog;
import 'package:epic_wallet/src/desktop/screens/transfer/finished_payment.dart' show showPostFinished;
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart' show ReceiveScreen;
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/qr_slate.dart' show QrFrames, qrFrameMs;
import 'package:epic_wallet/src/scan/scan_checks.dart' show CodeOrigin;
import 'package:epic_wallet/src/slate_files.dart' show responseFileName;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/wallet_service.dart' show FakeWalletService, FakeWalletSession, qrFragmentLen;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart' show QrImage;

final _l = englishStrings;

/// A slate long enough for several parts (each part carries [qrFragmentLen] bytes).
String _slate(String sta, {String id = 'f0e1d2c3-b4a5-4697-8879-6a5b4c3d2e1f'}) =>
    '{"version_info":{"version":3,"block_header_version":2},"id":"$id","sta":"$sta","amt":"42000000000","fee":"700000",'
    '"pad":"${'0' * 420}"}';

Future<List<String>> _parts(String json) => FakeWalletService().encodeQrSlate(json: json, maxFragmentLen: qrFragmentLen);

late MockDeskWallet _wallet;
late ProviderContainer _container;
FakeQrCamera? _camera;

Future<void> _open(WidgetTester tester, DeskRoute route, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _wallet = MockDeskWallet(delay: Duration.zero);
  _camera = null;
  _container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_wallet),
      qrCameraFactoryProvider.overrideWithValue(() => _camera = FakeQrCamera()),
      cameraProbeProvider.overrideWithValue(FakeCameraProbe()),
    ],
    retry: (_, _) => null,
  );
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _settle(tester);
}

/// The camera reads [parts], one at a time, until the scan has the whole code and closes.
Future<void> _show(WidgetTester tester, List<String> parts) async {
  final dialog = find.byType(DeskScanDialog<String>);
  expect(dialog, findsOneWidget, reason: 'the scan dialog is open');
  for (final p in parts) {
    if (dialog.evaluate().isEmpty) break;
    _camera!.emit(p);
    await _settle(tester);
  }
  expect(dialog, findsNothing, reason: 'the scan closes once every part is in');
}

/// Closes the QR dialog, which stops its timers.
Future<void> _closeQr(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('desk-qr-close')));
  expect(find.byKey(const ValueKey('desk-qr-dialog')), findsNothing);
}

void main() {
  testWidgets('Import: a scanned payment is signed and its reply opens as a QR code', (tester) async {
    await _open(tester, DeskRoute.importTx);
    final enabled = tester.widget<EButton>(find.descendant(of: find.byKey(const ValueKey('imp-scan')), matching: find.byType(EButton)));
    expect(enabled.onPressed, isNotNull, reason: 'a camera is found');
    await _tap(tester, find.byKey(const ValueKey('imp-scan')));
    final parts = await _parts(_slate('S1'));
    expect(parts.length, greaterThan(1));
    await _show(tester, parts);
    expect(find.byType(DeskScanDialog<String>), findsNothing, reason: 'the scan closes once every part is in');
    expect(find.byKey(const ValueKey('desk-qr-dialog')), findsOneWidget, reason: 'the reply shows as a QR code at once');
    expect(find.text(_l.qrStatusReplyHidden), findsOneWidget);
    await _closeQr(tester);
    expect(find.byKey(const ValueKey('imp-show-qr')), findsOneWidget, reason: 'Show QR stays beside the saved reply');
  });

  testWidgets('Import: a scanned invoice opens its Review', (tester) async {
    await _open(tester, DeskRoute.importTx);
    await _tap(tester, find.byKey(const ValueKey('imp-scan')));
    await _show(tester, await _parts(_slate('I1')));
    expect(find.text(_l.reqTitle), findsWidgets);
    expect(find.byKey(const ValueKey('desk-qr-dialog')), findsNothing, reason: 'nothing is paid before the Review');
  });

  testWidgets('Finalize: a scanned reply is finalized', (tester) async {
    await _open(tester, DeskRoute.finalize);
    await _tap(tester, find.byKey(const ValueKey('fin-scan')));
    await _show(tester, await _parts(_slate('S2', id: '9a8b7c6d-5e4f-4321-8765-0fedcba98765')));
    await _settle(tester);
    expect(find.text(_l.deskFinPosted), findsWidgets);
    expect(find.text(_l.deskFinPostedText), findsOneWidget);
  });

  testWidgets('Receive › Transaction files: a scanned finished payment is posted', (tester) async {
    await _open(tester, DeskRoute.receive);
    await _tap(tester, find.byKey(const ValueKey('rx-files-scan')));
    await _show(tester, await _parts(FakeWalletSession.fakeFinishedText(3)));
    expect(find.textContaining(_l.deskFinPosted), findsOneWidget);
    expect(find.textContaining(_l.deskQrScannedName), findsOneWidget);
  });

  testWidgets('Receive › Transaction files: a scanned payment is signed and its reply shown', (tester) async {
    await _open(tester, DeskRoute.receive);
    await _tap(tester, find.byKey(const ValueKey('rx-files-scan')));
    await _show(tester, await _parts(_slate('S1')));
    expect(find.byKey(const ValueKey('desk-qr-dialog')), findsOneWidget);
    await _closeQr(tester);
    expect(find.textContaining(_l.deskTfSigned(responseFileName('9a8b7c6d-5e4f-4321-8765-0fedcba98765'))), findsOneWidget);
  });

  testWidgets('Post a finished payment: a scanned one shows its summary', (tester) async {
    await _open(tester, DeskRoute.receive);
    unawaited(showPostFinished(tester.element(find.byType(ReceiveScreen))));
    await _settle(tester);
    await _tap(tester, find.byKey(const ValueKey('post-finished-scan')));
    await _show(tester, await _parts(FakeWalletSession.fakeFinishedText(3)));
    expect(find.byKey(const ValueKey('post-finished-summary')), findsOneWidget);
  });

  testWidgets('Show QR: a countdown, then the parts in turn, then it hides itself', (tester) async {
    await _open(tester, DeskRoute.importTx);
    const slateId = '9a8b7c6d-5e4f-4321-8765-0fedcba98765';
    final reply = _slate('S2', id: slateId);
    _wallet.fileTexts[responseFileName(slateId)] = reply;
    final parts = await _parts(reply);
    final count = int.parse(RegExp(r'/\d+-(\d+)/').firstMatch(parts.first)![1]!);
    await _tap(tester, find.byKey(const ValueKey('imp-scan')));
    await _show(tester, await _parts(_slate('S1')));
    await _tap(tester, find.byKey(const ValueKey('desk-qr-show')));
    expect(find.byKey(const ValueKey('desk-qr-countdown')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    // Each frame is drawn ahead (QrFrames): the part shown is the one whose code has its modules.
    final frames = QrFrames.of(parts);
    bool same(QrImage a, QrImage b) {
      if (a.moduleCount != b.moduleCount) return false;
      for (var y = 0; y < a.moduleCount; y++) {
        for (var x = 0; x < a.moduleCount; x++) {
          if (a.isDark(y, x) != b.isDark(y, x)) return false;
        }
      }
      return true;
    }

    String shown() {
      final image = tester.widget<EQr>(find.byKey(const ValueKey('desk-qr-image'))).image!;
      final at = frames.images.indexWhere((f) => same(f, image));
      return at < 0 ? '' : parts[at];
    }

    String label() => tester.widget<Text>(find.byKey(const ValueKey('desk-qr-part'))).data!;
    // Frame by frame through every part, the spare parts after the plain ones included.
    final first = parts.indexOf(shown());
    expect(first, isNot(-1));
    final seen = <String>{};
    for (var i = 0; i < parts.length; i++) {
      final at = (first + i) % parts.length;
      expect(shown(), parts[at]);
      expect(label(), _l.qrPartOf(at % count + 1, count));
      seen.add(shown());
      await tester.pump(const Duration(milliseconds: qrFrameMs));
    }
    expect(seen, parts.toSet());
    expect(find.text(_l.qrStatusReplyShowing), findsOneWidget);
    await tester.pump(const Duration(seconds: 41));
    await tester.pump();
    expect(find.byKey(const ValueKey('desk-qr-timed-out')), findsOneWidget);
    expect(find.byKey(const ValueKey('desk-qr-image')), findsNothing);
    await _closeQr(tester);
  });

  group('Send › To', () {
    testWidgets('a part read by the camera opens the part scan, then the payment is signed', (tester) async {
      final parts = await _parts(_slate('S1'));
      await _open(tester, DeskRoute.send, arg: SendArgs(code: parts.first, codeOrigin: CodeOrigin.qr));
      await _show(tester, parts.skip(1).toList());
      await _settle(tester);
      expect(_container.read(deskNavProvider).route, DeskRoute.importTx);
    });

    testWidgets('a whole one-part code read by the camera opens with no second scan', (tester) async {
      const reply = '{"id":"9a8b7c6d-5e4f-4321-8765-0fedcba98765","sta":"S2"}';
      final parts = await _parts(reply);
      expect(parts, hasLength(1));
      await _open(tester, DeskRoute.send, arg: SendArgs(code: parts.single, codeOrigin: CodeOrigin.qr));
      expect(find.byType(DeskScanDialog<String>), findsNothing);
      expect(_container.read(deskNavProvider).route, DeskRoute.finalize);
    });

    testWidgets('a pasted part says how to bring the payment in', (tester) async {
      final parts = await _parts(_slate('S1'));
      await _open(tester, DeskRoute.send, arg: SendArgs(code: parts.first, codeOrigin: CodeOrigin.paste));
      expect(find.byType(DeskScanDialog<String>), findsNothing);
      expect(find.text(_l.deskSendToQrPayment), findsOneWidget);
      expect(_container.read(deskNavProvider).route, DeskRoute.send);
    });
  });
}
