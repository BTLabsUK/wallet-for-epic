// SPDX-License-Identifier: Apache-2.0
// A payment request shown as a QR (Direct · QR Payment), against the fakes: whoever asks makes
// it from Receive (Invoices on), shows it, scans the payer's answer and gets a
// receipt; the payer scans it with no switch on, approves behind the PIN and shows the answer
// back at once. A request that expired or does not fit this network pays nothing.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/invoice_request_screen.dart';
import 'package:epic_wallet/src/ui/invoice_review_screen.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_scan_screen.dart' show qrCompleteFor, qrPostedFor;
import 'package:epic_wallet/src/ui/qr_show_screen.dart';
import 'package:epic_wallet/src/ui/request_qr_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Mainnet extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: mainnetPreset.nodeUrl);
}

/// A request (I1) a shop made, as its code reads once scanned.
const String _requestJson = '{"id":"req-qr-1","sta":"I1"}';

class _Harness {
  _Harness() {
    allowPinCheck(session, service);
  }

  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(2500000),
      minimumConfirmations: BigInt.from(3),
      total: _epic(100),
      spendable: _epic(100),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
  );
  late final service = FakeWalletService(session: session);
  final camera = FakeQrCamera();
  final store = sendPinStore()..values['app.payment_prefs'] = '|epicbox';

  /// Makes [_requestJson] a request for [amount] with the shop's [message].
  void knowRequest({num amount = 12.5, String message = 'Table 4, two coffees'}) {
    service.slateInfos[_requestJson] = SlateInfo(
      slateId: 'req-qr-1',
      amount: _epic(amount),
      fee: BigInt.zero,
      stage: SlateStage.request,
      messages: [SlateMessage(role: SlateRole.receiver, text: message)],
    );
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 3300);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          qrCameraFactoryProvider.overrideWithValue(() => camera),
          phonePaymentsProvider.overrideWithValue(true),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  /// Show QR, then the 3 · 2 · 1 count.
  Future<void> showCode(WidgetTester tester) async {
    await tester.tap(find.byKey(qrShowButtonKey));
    for (var i = 0; i < qrCountdownSeconds + 1; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// The scan screen opening and its camera starting.
  Future<void> cameraUp(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// The read code's check, Posting… and Posted, then the screens closing.
  Future<void> finished(WidgetTester tester) async {
    await tester.pump(qrCompleteFor);
    await tester.pump();
    await tester.pump(qrPostedFor);
    await tester.pumpAndSettle();
  }

  /// Feeds every part of [json] to the camera.
  Future<void> scan(WidgetTester tester, String json) async {
    for (final text in await service.encodeQrSlate(json: json, maxFragmentLen: qrFragmentLen)) {
      camera.emit(text);
      await tester.pump();
      await tester.pump();
    }
  }
}

/// The phone's Home with one button that opens the request flow, as Receive's QR card does.
class _Entry extends ConsumerWidget {
  const _Entry();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: FilledButton(onPressed: () => openQrRequest(context), child: const Text('entry')),
    ),
  );
}

void main() {
  group('whoever asks', () {
    testWidgets('the entry opens the form that shows the request as a QR', (tester) async {
      final h = _Harness();
      await h.pump(tester, const _Entry());
      await tester.tap(find.text('entry'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceRequestScreen), findsOneWidget);
      expect(find.descendant(of: find.byKey(requestPayerKey), matching: find.text(_l.reqToQr)), findsOneWidget);
      expect(find.byKey(requestShowQrKey), findsOneWidget);
      expect(find.byKey(requestSaveFileKey), findsNothing);
    });

    testWidgets('makes the request, shows its code, finishes on the payer\'s answer and shows the receipt', (tester) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen(asQr: true));
      await tester.enterText(find.byKey(requestAmountKey), '12.5');
      await tester.enterText(find.byKey(requestMessageKey), 'Table 4');
      await tester.pump();
      expect(find.text(_l.reqQrSummary(epicExact(_l, _epic(12.5)))), findsOneWidget);
      await tester.tap(find.byKey(requestShowQrKey));
      await tester.pumpAndSettle();

      // The code opens by itself, hidden until shown.
      expect(find.byType(QrShowScreen), findsOneWidget);
      expect(find.text(_l.qrShowTitleRequest), findsOneWidget);
      expect(find.text(_l.qrStatusRequestHidden), findsOneWidget);
      final request = tester.widget<RequestQrScreen>(find.byType(RequestQrScreen, skipOffstage: false));
      expect(request.amount, _epic(12.5));
      expect(h.session.issuedRequests.single.message, 'Table 4');

      await h.showCode(tester);
      expect(find.text(_l.qrStatusRequestShowing), findsOneWidget);

      // The payer pays it (another wallet; the same fake core here) and shows the answer.
      final paid = await h.session.payRequestFile(slateJson: request.slate.json, amount: _epic(12.5));
      await tester.tap(find.byKey(qrNextButtonKey));
      await h.cameraUp(tester);
      await h.scan(tester, paid.json);
      await h.finished(tester);

      expect(find.byType(QrShowScreen), findsNothing);
      expect(find.byKey(requestQrPaidKey), findsOneWidget);
      expect(find.text(_l.reqQrPaidHeadline(epicExact(_l, _epic(12.5)))), findsOneWidget);
      expect(find.text('Table 4'), findsOneWidget);
      expect((await h.session.issuedInvoice(slateId: request.slate.slateId))!.state, IssuedInvoiceState.paid);

      // New request: the form again, for the next payer.
      await tester.tap(find.byKey(requestQrNewKey));
      await tester.pumpAndSettle();
      expect(find.byKey(requestShowQrKey), findsOneWidget);
      // The note stays for the next payer; the amount starts empty.
      expect(tester.widget<TextField>(find.byKey(requestMessageKey)).controller!.text, 'Table 4');
      expect(tester.widget<TextField>(find.byKey(requestAmountKey)).controller!.text, isEmpty);
    });

    testWidgets('an answer to another request is refused on the request screen; nothing is finished', (tester) async {
      final h = _Harness();
      final other = await h.session.pairing.requestFile(amount: _epic(3));
      final otherAnswer = await h.session.payRequestFile(slateJson: other.json, amount: _epic(3));
      await h.pump(tester, const InvoiceRequestScreen(asQr: true));
      await tester.enterText(find.byKey(requestAmountKey), '5');
      await tester.pump();
      await tester.tap(find.byKey(requestShowQrKey));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(requestQrScanKey));
      await h.cameraUp(tester);
      await h.scan(tester, otherAnswer.json);
      await h.finished(tester);
      expect(find.byKey(requestQrErrorKey), findsOneWidget);
      expect(find.text(_l.reqQrWrongReply), findsOneWidget);
      expect(h.session.finalizedSlates, isEmpty);
    });
  });

  group('the payer', () {
    testWidgets('a scanned request needs no switch: Review, PIN, then the answer QR opens by itself', (tester) async {
      final h = _Harness()..knowRequest();
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _requestJson), pasted: true, scanned: true));
      expect(find.text(_l.reqFromQrTitle), findsOneWidget);
      expect(find.text(_l.reqFromQrWarn), findsOneWidget);
      expect(find.text(_l.reqQrMessageLabel), findsOneWidget);
      expect(find.text('Table 4, two coffees'), findsOneWidget);
      expect(find.text(_l.reqApproveShowAnswer), findsOneWidget);

      await tester.tap(find.byKey(requestFileApproveKey));
      await tester.pumpAndSettle();
      await answerPin(tester);
      expect(h.session.paidRequestFiles['req-qr-1']!.amount, _epic(12.5));
      expect(find.byType(QrShowScreen), findsOneWidget);
      expect(find.text(_l.qrStatusPaidHidden), findsOneWidget);
      expect(find.text(_l.qrShowSubPaid(epicExact(_l, _epic(12.5)))), findsOneWidget);

      await h.showCode(tester);
      expect(find.text(_l.qrStatusPaidShowing), findsOneWidget, reason: 'signed is not posted: it waits for whoever asked');
      await tester.tap(find.byKey(qrNextButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(QrShowScreen), findsNothing);
      expect(find.byType(RequestFileReviewScreen), findsNothing);
    });

    testWidgets('back from the answer QR without Done: Show reply as QR shows it again', (tester) async {
      final h = _Harness()..knowRequest();
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _requestJson), pasted: true, scanned: true));
      await tester.tap(find.byKey(requestFileApproveKey));
      await tester.pumpAndSettle();
      await answerPin(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(_l.reqQrAnswerTitle), findsOneWidget);
      await tester.tap(find.byKey(requestQrShowAnswerKey));
      await tester.pumpAndSettle();
      expect(find.byType(QrShowScreen), findsOneWidget);
    });

    testWidgets('a request for another network pays nothing and says so', (tester) async {
      final h = _Harness()..knowRequest();
      h.session.payRequestFileError = const WalletError(kind: WalletErrorKind.invoiceNotForThisChain, message: 'ttl ends too far ahead');
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _requestJson), pasted: true, scanned: true));
      await tester.tap(find.byKey(requestFileApproveKey));
      await tester.pumpAndSettle();
      await answerPin(tester);
      expect(find.text(_l.reqOtherChain), findsOneWidget);
      expect(find.byKey(requestFileApproveKey), findsNothing);
      expect(h.session.paidRequestFiles, isEmpty);
    });

    testWidgets('an expired request pays nothing and says so', (tester) async {
      final h = _Harness()..knowRequest();
      h.session.payRequestFileError = const WalletError(kind: WalletErrorKind.paymentExpired, message: 'expired');
      await h.pump(tester, const SlateFileScreen(file: SlateFile(name: scannedSlateName, json: _requestJson), pasted: true, scanned: true));
      await tester.tap(find.byKey(requestFileApproveKey));
      await tester.pumpAndSettle();
      await answerPin(tester);
      expect(find.text(_l.reqExpired), findsOneWidget);
      expect(find.byKey(requestFileApproveKey), findsNothing);
      expect(h.session.paidRequestFiles, isEmpty);
    });
  });
}
