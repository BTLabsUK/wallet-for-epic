// SPDX-License-Identifier: Apache-2.0
// Requesting a payment (I-06), against FakeWalletSession: Receive's card, the request form,
// the requests in the Invoices list, the request block in a transaction's details, withdraw
// with its confirm, and the notices of each issuer event. Nothing on this side pays.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/invoice_request_screen.dart';
import 'package:epic_wallet/src/ui/invoices_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A fake epicbox address: `es`, 50 copies of [c], then [relay].
String _address(String c, [String relay = 'epicbox.epiccash.com']) =>
    'es${c * 50}@$relay';

/// The payer's address.
final String _payer = _address('P');

/// This wallet's payments address, valid so the own-address check can see it.
final String _own = _address('W');

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  _Config(this.config);

  final WalletConfig config;

  @override
  WalletConfig? build() => config;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  _Harness() {
    store.values['wallet.mainnet.backedUp'] = '1';
    session.clock = () => now;
    session.owner = service;
    session.address = _own;
  }

  DateTime now = DateTime(2026, 10, 5, 12);
  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore();
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);
  final copied = <String>[];
  String? clipboard;

  WalletConfig get config => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: 'https://node',
  );

  static final WalletSummary _summary = WalletSummary(
    lastConfirmedHeight: BigInt.from(2500000),
    minimumConfirmations: BigInt.from(3),
    total: _epic(100),
    spendable: _epic(100),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  );

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  /// One request to the payer, as the form sends it.
  Future<IssuedInvoice> issue({num amount = 2.5, String? message}) => session
      .issueToContact(amount: _epic(amount), address: _payer, message: message);

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool tall = false,
  }) async {
    tester.view.physicalSize = Size(1080, tall ? 7200 : 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        if (call.method == 'Clipboard.getData') {
          return clipboard == null ? null : {'text': clipboard};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          // On from the first frame, before the stored settings load.
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          slateFilesProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => now),
          invoiceClockProvider.overrideWithValue(() => now),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(() => _Config(config)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// [_payer] as a verified paired contact named [name] whose wallet pays requests.
  PairingRecord pairPayer({String name = 'Alice'}) =>
      session.pairing.seedPaired(name: name, paymentsAddress: _payer);

  /// Picks [name] under To.
  Future<void> pick(WidgetTester tester, {String name = 'Alice'}) async {
    await tester.tap(find.byKey(requestPayerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(name)));
    await tester.pumpAndSettle();
  }

  /// Fills the form and taps Send request.
  Future<void> request(
    WidgetTester tester, {
    String amount = '2.5',
    String message = '',
  }) async {
    await pick(tester);
    await tester.enterText(find.byKey(requestAmountKey), amount);
    if (message.isNotEmpty) {
      await tester.enterText(find.byKey(requestMessageKey), message);
    }
    await tester.pump();
    await tester.tap(find.text(_l.reqNewSend));
    await tester.pumpAndSettle();
  }
}

String? _notice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first))
        .read(noticeProvider)
        ?.text;

NoticeLevel? _noticeLevel(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first))
        .read(noticeProvider)
        ?.level;

/// Text inside a row's rich line.
Finder _rich(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('Receive card', () {
    testWidgets('is hidden when the wallet has no invoices', (tester) async {
      final h = _Harness();
      h.session.invoicesSupported = false;
      await h.pump(tester, const SlotScaffold(body: ReceiveView()));
      expect(find.byKey(receiveRequestKey), findsNothing);
      expect(find.text(_l.receiveRequestTitle), findsNothing);
    });

    testWidgets('opens the request form', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SlotScaffold(body: ReceiveView()));
      expect(find.byKey(receiveRequestKey), findsOneWidget);
      await tester.ensureVisible(find.text(_l.receiveRequestTitle));
      await tester.tap(find.text(_l.receiveRequestTitle));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqNewTitle), findsOneWidget);
      expect(find.text(_l.reqNewLead), findsOneWidget);
    });
  });

  group('form', () {
    testWidgets('without a paired payer: says so, and the file is the choice (DESIGN 3.2)', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      expect(find.text(_l.reqNoPayers), findsOneWidget);
      expect(find.text(_l.reqToFile), findsOneWidget);
      expect(find.text(_l.reqNewSend), findsNothing);
      await tester.enterText(find.byKey(requestAmountKey), '2.5');
      await tester.pump();
      await tester.tap(find.byKey(requestSaveFileKey));
      await tester.pumpAndSettle();
      // The request file, to save or share (DESIGN §3.2).
      expect(find.text(_l.reqFileTitle), findsOneWidget);
      await tester.tap(find.text(_l.slateSaveToDevice));
      await tester.pumpAndSettle();
      expect(h.files.saved, hasLength(1));
      expect(_notice(tester), _l.slateSaved(h.files.saved.single.name));
    });

    testWidgets('a wallet that asks paired contacts only offers no file', (tester) async {
      final h = _Harness()..pairPayer();
      h.session.requestFilesSupported = false;
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      expect(find.byKey(requestSaveFileKey), findsNothing);
      expect(find.text(_l.reqNewLeadContacts), findsOneWidget);
      expect(find.text(_l.reqNewLead), findsNothing);
    });

    testWidgets('a contact not verified is not offered under To', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(name: 'Tom', state: PairingState.paired, paymentsAddress: _payer);
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      expect(find.text(_l.reqNoPayers), findsOneWidget);
    });

    testWidgets('asks for the payer and the amount before sending', (
      tester,
    ) async {
      final h = _Harness()..pairPayer();
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      await tester.tap(find.text(_l.reqNewSend));
      await tester.pumpAndSettle();
      // A contact, the QR code or a file: the placeholder names both kinds (#1102).
      expect(find.text(_l.reqPickContactOrMethod), findsWidgets);
      expect(_l.reqPickContactOrMethod, 'Choose a contact or method');
      expect(find.text(_l.sendAmountZero), findsOneWidget);
      await h.request(tester, amount: '0');
      expect(find.text(_l.sendAmountZero), findsOneWidget);
      expect(h.session.issuedRequests, isEmpty);
    });

    testWidgets('stops the message at 256 bytes and counts them', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      // Three bytes each: 90 of them would be 270.
      await tester.enterText(find.byKey(requestMessageKey), '€' * 85);
      await tester.pump();
      expect(find.text(_l.sendMessageCounter(255, 256)), findsOneWidget);
      await tester.enterText(find.byKey(requestMessageKey), '€' * 90);
      await tester.pump();
      final field = tester.widget<TextField>(find.byKey(requestMessageKey));
      expect(field.controller!.text, '€' * 85, reason: 'refused, not cut');
    });

    testWidgets('requests from the paired contact, says so, and opens the request in the list', (
      tester,
    ) async {
      final h = _Harness()..pairPayer();
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      await h.request(tester, message: 'Dinner on Friday');
      expect(h.session.issuedRequests.single, (
        amount: _epic(2.5),
        to: _payer,
        message: 'Dinner on Friday',
      ));
      expect(_notice(tester), _l.reqSent('Alice'));
      expect(_noticeLevel(tester), NoticeLevel.success);
      expect(find.text(_l.invoicesTitle), findsOneWidget);
      final segments = tester.widget<SegmentedButton<InvoicesSegment>>(
        find.byKey(invoicesSegmentsKey),
      );
      expect(segments.selected, {InvoicesSegment.sent});
      expect(find.text(epicText(_l, _epic(2.5))), findsOneWidget);
      // Nothing leaves the wallet, so no PIN.
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(h.session.invoicePayments, 0);
    });

    testWidgets('sums up the request above Send request once it is complete', (
      tester,
    ) async {
      final h = _Harness()..pairPayer();
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      expect(find.byKey(requestSummaryKey), findsNothing);
      await h.pick(tester);
      await tester.enterText(find.byKey(requestAmountKey), '2.5');
      await tester.pump();
      expect(
        find.text(_l.invoicesRequestSummary('Alice', epicExact(_l, _epic(2.5)))),
        findsOneWidget,
      );
    });

    testWidgets('a request the relay did not take stays on the form', (
      tester,
    ) async {
      final h = _Harness()..pairPayer();
      h.session.issueError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay closed the socket',
      );
      await h.pump(tester, const InvoiceRequestScreen(), tall: true);
      await h.request(tester);
      expect(_noticeLevel(tester), NoticeLevel.error);
      expect(find.text(_l.reqNewTitle), findsOneWidget);
      expect(h.session.issuedRequests, isEmpty);
    });
  });

  group('list', () {
    testWidgets('shows each state of a sent request', (tester) async {
      final h = _Harness();
      final waiting = await h.issue(amount: 1);
      final paid = await h.issue(amount: 2);
      final declined = await h.issue(amount: 3);
      final withdrawn = await h.issue(amount: 4);
      final expired = await h.issue(amount: 5);
      await h.session.payIssued(paid.slateId);
      await h.session.declineIssued(declined.slateId);
      await h.session.withdrawInvoice(slateId: withdrawn.slateId);
      await h.session.expireIssued(expired.slateId);
      await h.pump(tester, const InvoicesScreen(), tall: true);
      // Nothing to pay, so it opens on Sent, with the counts on the segments.
      expect(
        find.bySemanticsLabel(
          _l.invoicesSegmentCount(_l.invoicesToPaySection, 0),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          _l.invoicesSegmentCount(_l.invoicesSegmentSent, 5),
        ),
        findsOneWidget,
      );
      expect(find.text(_l.invoicesSentEmpty), findsNothing);
      expect(find.text(shortAddress(_payer)), findsNWidgets(5));
      for (final (amount, state) in [
        (1, '${_l.invoicesWaitingPayment}\u00a0· ${_l.invoiceTimeLeftHours(24, 0)}'),
        (2, _l.issuedPaid),
        (3, _l.issuedDeclined),
        (4, _l.issuedWithdrawn),
        (5, _l.issuedExpired),
      ]) {
        final tile = find.ancestor(
          of: find.text(epicText(_l, _epic(amount))),
          matching: find.byType(InkWell),
        );
        expect(
          find.descendant(of: tile, matching: _rich(state)),
          findsOneWidget,
          reason: '$amount EPIC',
        );
      }
      // Only the waiting one can be withdrawn.
      expect(find.text(_l.issuedWithdraw), findsOneWidget);
      expect(waiting.withdrawable, isTrue);
    });

    testWidgets('counts the time left down', (tester) async {
      final h = _Harness();
      await h.issue();
      await h.pump(tester, const InvoicesScreen());
      expect(_rich(_l.invoiceTimeLeftHours(24, 0)), findsOneWidget);
      h.now = h.now.add(const Duration(hours: 23, minutes: 30));
      await tester.pump(const Duration(seconds: 30));
      expect(_rich(_l.invoiceTimeLeftMinutes(30)), findsOneWidget);
    });

    testWidgets('withdraw asks first, then withdraws', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      await h.pump(tester, const HomeScreen());
      await tester.tap(
        find.byKey(homeDestinationKey(HomeDestination.invoices)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.issuedWithdraw));
      await tester.pumpAndSettle();
      expect(find.text(_l.issuedWithdrawTitle), findsOneWidget);
      expect(
        find.text(_l.issuedWithdrawBody(shortAddress(_payer))),
        findsOneWidget,
      );
      await tester.tap(find.text(_l.issuedWithdrawKeep));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, isEmpty);
      await tester.tap(find.text(_l.issuedWithdraw));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DangerButton, _l.issuedWithdraw).last);
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [request.txId]);
      expect(_rich(_l.issuedWithdrawn), findsOneWidget);
      expect(find.text(_l.issuedWithdraw), findsNothing);
      expect(_notice(tester), _l.issuerNoticeWithdrawn);
      expect(_noticeLevel(tester), NoticeLevel.warning);
    });

    testWidgets('opens a request in its details', (tester) async {
      final h = _Harness();
      await h.issue(message: 'Dinner on Friday');
      await h.pump(tester, const InvoicesScreen());
      await tester.tap(find.text(shortAddress(_payer)));
      await tester.pumpAndSettle();
      expect(find.text(_l.issuedDetailsSection), findsOneWidget);
    });
  });

  group('details', () {
    Future<void> details(
      WidgetTester tester,
      _Harness h,
      IssuedInvoice request,
    ) => h.pump(
      tester,
      TxDetailsScreen(txKey: 's:${request.slateId}'),
      tall: true,
    );

    testWidgets(
      'a waiting request shows the payer, message, time and Withdraw',
      (tester) async {
        final h = _Harness();
        final request = await h.issue(message: 'Dinner on Friday');
        await details(tester, h, request);
        expect(find.text(_l.issuedDetailsSection), findsOneWidget);
        // One "Requested from" row names the payer, with the address.
        expect(find.text(_l.txDetailsRequestedFrom), findsOneWidget);
        expect(find.text('Dinner on Friday'), findsOneWidget);
        expect(
          find.text(
            '${_l.issuedDetailsWaiting} · ${_l.invoiceTimeLeftHours(24, 0)}',
          ),
          findsOneWidget,
        );
        // Withdraw replaces the plain cancel, which would not keep the state.
        expect(find.text(_l.txDetailsCancelPayment), findsNothing);
        await tester.tap(find.text(_l.issuedWithdraw));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(DangerButton, _l.issuedWithdraw).last);
        await tester.pumpAndSettle();
        expect(h.session.cancelledTxIds, [request.txId]);
        expect(find.text(_l.issuedDetailsWithdrawn), findsOneWidget);
        expect(find.text(_l.issuedWithdraw), findsNothing);
      },
    );

    for (final (name, settle, text) in [
      (
        'paid',
        (FakeWalletSession s, String id) => s.payIssued(id),
        _l.issuedDetailsPaid,
      ),
      (
        'declined',
        (FakeWalletSession s, String id) => s.declineIssued(id),
        _l.issuedDetailsDeclined,
      ),
      (
        'expired',
        (FakeWalletSession s, String id) => s.expireIssued(id),
        _l.issuedDetailsExpired,
      ),
      (
        'bounced',
        (FakeWalletSession s, String id) => s.bounceIssued(id),
        _l.issuedDetailsBounced,
      ),
    ]) {
      testWidgets('a $name request says so and cannot be withdrawn', (
        tester,
      ) async {
        final h = _Harness();
        final request = await h.issue();
        await settle(h.session, request.slateId);
        await details(tester, h, request);
        expect(find.text(text), findsOneWidget);
        expect(find.text(_l.issuedWithdraw), findsNothing);
      });
    }

    testWidgets('a waiting request reads as a request, not a receive', (
      tester,
    ) async {
      final h = _Harness();
      final request = await h.issue();
      await details(tester, h, request);
      // Status card and timeline: requested, then waiting for the payer.
      expect(find.text(_l.txDetailsWaitingPayer), findsOneWidget);
      expect(find.text(_l.txStepRequested), findsOneWidget);
      expect(find.text(_l.txStatusWaitingPayer), findsWidgets);
      expect(find.text(_l.txDetailsRequestedFrom), findsOneWidget);
      for (final receive in [
        _l.txStepArrived,
        _l.txStatusWaitingSender,
        _l.txDetailsWaitingSender,
        _l.txDetailsReceivedFrom,
      ]) {
        expect(find.text(receive), findsNothing, reason: receive);
      }
    });

    testWidgets('a paid request steps on to confirming', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      await h.session.payIssued(request.slateId);
      await details(tester, h, request);
      expect(find.text(_l.txStepRequested), findsOneWidget);
      expect(find.text(_l.txStepPaid), findsOneWidget);
      expect(find.text(_l.txStatusWaitingPayer), findsNothing);
      expect(find.text(_l.txStepArrived), findsNothing);
      expect(find.text(_l.txDetailsRequestedFrom), findsOneWidget);
    });

    testWidgets('an ended request says nothing arrived', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      await h.session.bounceIssued(request.slateId);
      await details(tester, h, request);
      expect(find.text(_l.txDetailsRequestEnded), findsOneWidget);
      expect(find.text(_l.txDetailsCancelledIncoming), findsNothing);
    });

    testWidgets('its row in a list waits for the payer', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      final tx = h.session.transactionsValue.single;
      await h.pump(tester, Scaffold(body: TxTile(tx: tx)));
      expect(find.textContaining(_l.txStatusWaitingPayer), findsOneWidget);
      expect(find.textContaining(_l.txStatusWaitingSender), findsNothing);
      expect(
        tester.getSemantics(find.byKey(ValueKey('tx-${tx.key}'))).label,
        startsWith(
          _l.txSpokenRequestingFrom(
            epicText(_l, request.amount),
            shortAddress(_payer, ownServer: 'epicbox.epiccash.com'),
          ),
        ),
      );
    });

    testWidgets('a waiting request counts its time left down', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      await details(tester, h, request);
      h.now = h.now.add(const Duration(hours: 23, minutes: 30));
      await tester.pump(const Duration(seconds: 30));
      expect(
        find.text(
          '${_l.issuedDetailsWaiting} · ${_l.invoiceTimeLeftMinutes(30)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('follows a state change while open', (tester) async {
      final h = _Harness();
      final request = await h.issue();
      await details(tester, h, request);
      expect(find.text(_l.issuedWithdraw), findsOneWidget);
      await h.session.payIssued(request.slateId);
      await tester.pumpAndSettle();
      expect(find.text(_l.issuedDetailsPaid), findsOneWidget);
      expect(find.text(_l.issuedWithdraw), findsNothing);
    });

    testWidgets('a transaction that is no request has no request block', (
      tester,
    ) async {
      final h = _Harness();
      h.session.transactionsValue = [
        fakeTx(
          id: 1,
          slateId: 'plain',
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: 1790000000,
          amountCredited: _epic(1),
          cancellable: true,
        ),
      ];
      await h.pump(tester, const TxDetailsScreen(txKey: 's:plain'), tall: true);
      expect(find.text(_l.issuedDetailsSection), findsNothing);
      expect(find.text(_l.txDetailsCancelPayment), findsOneWidget);
    });
  });

  group('notices', () {
    Future<(_Harness, IssuedInvoice)> onHome(WidgetTester tester) async {
      final h = _Harness();
      final request = await h.issue();
      await h.pump(tester, const HomeScreen());
      h.container(tester).read(noticeProvider.notifier).clear();
      await tester.pumpAndSettle();
      return (h, request);
    }

    testWidgets('paid is a success with View', (tester) async {
      final (h, request) = await onHome(tester);
      await h.session.payIssued(request.slateId);
      await tester.pumpAndSettle();
      expect(_notice(tester), _l.issuerNoticePaid);
      expect(_noticeLevel(tester), NoticeLevel.success);
      await tester.tap(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text(_l.homeNoticeView),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l.issuedDetailsPaid), findsOneWidget);
    });

    testWidgets('declined is a warning', (tester) async {
      final (h, request) = await onHome(tester);
      await h.session.declineIssued(request.slateId);
      await tester.pumpAndSettle();
      expect(_notice(tester), _l.issuerNoticeDeclined);
      expect(_noticeLevel(tester), NoticeLevel.warning);
    });

    testWidgets('expired is information', (tester) async {
      final (h, request) = await onHome(tester);
      await h.session.expireIssued(request.slateId);
      await tester.pumpAndSettle();
      expect(_notice(tester), _l.issuerNoticeExpired);
      expect(_noticeLevel(tester), NoticeLevel.info);
    });

    testWidgets('bounced names the payer, with the payment file advice, once', (
      tester,
    ) async {
      final (h, request) = await onHome(tester);
      await h.session.bounceIssued(request.slateId);
      await tester.pumpAndSettle();
      final payer = payerName(const [], request.payerAddress);
      expect(_notice(tester), _l.issuerNoticeBouncedFrom(payer));
      expect(_noticeLevel(tester), NoticeLevel.warning);
      expect(_l.issuerNoticeBouncedFrom(payer), contains('transaction file'));
      // Withdrawn by the app, once; nothing paid.
      expect(h.session.invoicePayments, 0);
      expect(h.session.cancelledTxIds, [request.txId]);
      h.container(tester).read(noticeProvider.notifier).clear();
      await tester.pumpAndSettle();
      await h.session.bounceIssued(request.slateId);
      await tester.pumpAndSettle();
      expect(
        find.byKey(noticeKey),
        findsNothing,
        reason: 'a repeat is the same',
      );
      expect(h.session.cancelledTxIds, [request.txId]);
    });
  });
}
