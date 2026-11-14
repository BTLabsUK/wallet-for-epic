// SPDX-License-Identifier: Apache-2.0
// Ask for amount with the wallet's address: a still code of the Epicbox address with the amount
// in it, the sender opens it as the normal Epicbox send with the amount filled in. No request
// exists in the wallet, no animated code, no reply to scan. The code reads back as a payment
// request on the sender's side; the invoice code stays one pick away.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/invoice_request_screen.dart';
import 'package:epic_wallet/src/ui/kit/kit_keypad.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/request_qr_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final String _own = 'es${'W' * 50}@epicbox.epiccash.com';

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

class _Harness {
  _Harness({String payments = '|epicbox'}) : store = sendPinStore()..values['app.payment_prefs'] = payments {
    session.address = _own;
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
  final MemorySecretStore store;
  final copied = <String>[];

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 3300);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          qrCameraFactoryProvider.overrideWithValue(FakeQrCamera.new),
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
}

/// A page under the form, so that Done has somewhere to go back to.
class _Entry extends StatelessWidget {
  const _Entry();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen())),
        child: const Text('entry'),
      ),
    ),
  );
}

Future<void> _type(WidgetTester tester, String amount) async {
  for (final c in amount.split('')) {
    await tester.tap(find.descendant(of: find.byType(KitKeypad), matching: find.text(c)));
    await tester.pump();
  }
}

Future<void> _note(WidgetTester tester, String message) async {
  await tester.tap(find.text(_l.phonePayAddNote));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(requestMessageKey), message);
  await tester.tap(find.text(_l.commonDone));
  await tester.pumpAndSettle();
}

AddressVerdict _valid(Recipient _) => AddressVerdict.valid;

void main() {
  group('the form', () {
    testWidgets('asks "From anyone" with the address by default and shows the link', (tester) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen());
      expect(find.descendant(of: find.byKey(requestPayerKey), matching: find.text(_l.phoneRecvFromAnyone)), findsOneWidget);
      expect(find.byKey(requestShowLinkKey), findsOneWidget);
      expect(find.byKey(requestShowQrKey), findsNothing);
      expect(find.byKey(requestSaveFileKey), findsNothing);
    });

    testWidgets('shows one still code of the address with the amount; nothing is requested, nothing to scan back', (tester) async {
      final h = _Harness();
      await h.pump(tester, const _Entry());
      await tester.tap(find.text('entry'));
      await tester.pumpAndSettle();
      await _type(tester, '12.5');
      await _note(tester, 'Table 4');
      await tester.tap(find.byKey(requestShowLinkKey));
      await tester.pumpAndSettle();
      expect(find.byType(RequestLinkScreen), findsOneWidget);
      expect(find.byKey(requestLinkQrKey), findsOneWidget);
      expect(find.byType(RequestQrScreen), findsNothing);
      expect(find.text(_l.qrScanReply), findsNothing);
      expect(h.session.issuedRequests, isEmpty);
      // The link is the code's text: copy puts it on the clipboard.
      await tester.tap(find.text(_l.commonCopy));
      await tester.pumpAndSettle();
      expect(h.copied, contains('epic:$_own?amount=12.5&message=Table%204'));
      // Done closes the page.
      await tester.tap(find.text(_l.commonDone));
      await tester.pumpAndSettle();
      expect(find.byType(RequestLinkScreen), findsNothing);
    });

    testWidgets('the payer picker still offers the animated code', (tester) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen());
      await tester.tap(find.byKey(requestPayerKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.phoneRecvAnyoneAddress), findsOneWidget);
      await tester.tap(find.text(_l.phoneRecvAnyoneCode));
      await tester.pumpAndSettle();
      expect(find.byKey(requestShowQrKey), findsOneWidget);
      expect(find.byKey(requestShowLinkKey), findsNothing);
    });

    testWidgets('with Epicbox off there is no link: the code stays the choice', (tester) async {
      final h = _Harness(payments: PaymentPrefs(epicbox: false, directQr: true).encode());
      await h.pump(tester, const InvoiceRequestScreen());
      expect(find.byKey(requestShowLinkKey), findsNothing);
      expect(find.byKey(requestShowQrKey), findsOneWidget);
    });
  });

  group('Receive', () {
    testWidgets('offers Ask for amount without invoices when the address is there', (tester) async {
      final h = _Harness();
      h.session.invoicesSupported = false;
      await h.pump(tester, const SlotScaffold(body: ReceiveView()));
      expect(find.byKey(receiveRequestKey), findsOneWidget);
    });
  });

  group('the sender', () {
    test('reads the link as a payment request with the amount and the note', () {
      final link = EpicUri.build(_own, amount: _epic(12.5), note: 'Table 4');
      final code = classifyScan(link, check: _valid);
      expect(code, isA<PaymentRequest>());
      final request = code as PaymentRequest;
      expect(request.amount, _epic(12.5));
      expect(request.note, 'Table 4');
      expect(request.method, isNull);
    });
  });
}
