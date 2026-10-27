// Payment requests by file, both ways (DESIGN §3), against the fakes: the issuer's "Save as a
// file for anyone", the payer's Review of a request file behind the PIN and its answer file,
// and the issuer finishing the answer. The file is untrusted: nothing is paid without the PIN,
// and its message is plain text.

import 'dart:convert';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/invoice_request_screen.dart';
import 'package:epic_wallet/src/ui/invoice_review_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/experimental.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

const String _pin = '123456';

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

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => false;

  @override
  Future<bool> configured() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

/// A request (I1) someone else made, as its file reads.
const String _requestJson = '{"id":"req-file-1","sta":"I1"}';

class _Harness {
  _Harness() {
    store.values['wallet.mainnet.backedUp'] = '1';
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    session.clock = () => now;
    // The PIN check goes through the service that opened the session.
    session.owner = service;
  }

  DateTime now = DateTime(2026, 10, 25, 12);
  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);

  WalletConfig get config => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: 'https://node');

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

  /// Makes [_requestJson] a request for [amount] whose issuer wrote [message].
  void knowRequest({num amount = 12.5, String? message = 'Invoice 118, two bags of beans'}) {
    service.slateInfos[_requestJson] = SlateInfo(
      slateId: 'req-file-1',
      amount: _epic(amount),
      fee: BigInt.zero,
      stage: SlateStage.request,
      messages: [if (message != null) SlateMessage(role: SlateRole.receiver, text: message)],
    );
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          pushPlatformProvider.overrideWithValue(_NoPush()),
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

  /// Opens [json] as a transaction file, as Receive does.
  Future<void> open(WidgetTester tester, String json) =>
      pump(tester, SlateFileScreen(file: SlateFile(name: 'from-mail.tx', json: json)));

  /// Approve and save answer, then the PIN.
  Future<void> approve(WidgetTester tester) async {
    await tester.tap(find.byKey(requestFileApproveKey));
    await tester.pumpAndSettle();
    expect(find.text(_l.invoicePinReason), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, _pin);
    await tester.pumpAndSettle();
  }
}

String? _notice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.text;

void main() {
  group('issuer: Save as a file for anyone', () {
    testWidgets('with no paying contact the file is the choice, and the summary says who can pay', (tester) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen());
      // No paired contact pays requests: the file is chosen, and the button saves it.
      expect(find.text(_l.reqToFile), findsOneWidget);
      expect(find.byKey(requestSaveFileKey), findsOneWidget);
      expect(find.text(_l.reqSaveFile), findsOneWidget);
      await tester.enterText(find.byKey(requestAmountKey), '42.5');
      await tester.pump();
      expect(find.text(_l.reqFileSummary(epicExact(_l, _epic(42.5)))), findsOneWidget);
    });

    testWidgets('with a paying contact the file is the picker\'s last row; the contact means Send request', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(name: 'Anna', paymentsAddress: 'es${'P' * 50}@epicbox.epiccash.com');
      await h.pump(tester, const InvoiceRequestScreen());
      expect(find.byKey(requestSaveFileKey), findsNothing);
      await tester.tap(find.byKey(requestPayerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(requestToFileKey), findsOneWidget);
      await tester.tap(find.byKey(requestToFileKey));
      await tester.pumpAndSettle();
      expect(find.byKey(requestSaveFileKey), findsOneWidget);
      await tester.tap(find.byKey(requestPayerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Anna')));
      await tester.pumpAndSettle();
      expect(find.byKey(requestSaveFileKey), findsNothing);
      expect(find.text(_l.reqNewSend), findsOneWidget);
    });

    testWidgets('a wallet without request files offers no file', (tester) async {
      final h = _Harness();
      h.session.requestFilesSupported = false;
      await h.pump(tester, const InvoiceRequestScreen());
      expect(find.text(_l.reqToFile), findsNothing);
      expect(find.byKey(requestSaveFileKey), findsNothing);
      await tester.tap(find.byKey(requestPayerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(requestToFileKey), findsNothing);
    });

    testWidgets('Save as file shows the request file to save; it waits in Requests sent, By file', (tester) async {
      final h = _Harness();
      await h.pump(tester, const InvoiceRequestScreen());
      await tester.enterText(find.byKey(requestAmountKey), '42.5');
      await tester.enterText(find.byKey(requestMessageKey), 'Beans');
      await tester.pump();
      await tester.tap(find.byKey(requestSaveFileKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqFileTitle), findsOneWidget);
      expect(find.text(_l.reqFileLead), findsOneWidget);
      final issued = h.session.issuedRequests.single;
      expect(issued.amount, _epic(42.5));
      expect(issued.message, 'Beans');
      await tester.tap(find.text(_l.slateSaveToDevice));
      await tester.pumpAndSettle();
      final saved = h.files.saved.single;
      expect(saved.name, endsWith('.tx'));
      expect((jsonDecode(saved.json) as Map)['fake_invoice'], 'issued-1');
      await tester.tap(find.text(_l.commonDone));
      await tester.pumpAndSettle();
      // Requests sent: the row names no contact.
      expect(find.text(_l.reqByFile), findsOneWidget);
      final invoices = await h.session.issuedInvoices();
      expect(invoices.single.byFile, isTrue);
      expect(invoices.single.state, IssuedInvoiceState.waiting);
    });

    testWidgets('its details say Anyone with the file and wait for the answer file', (tester) async {
      final h = _Harness();
      await h.session.pairing.requestFile(amount: _epic(3));
      final tx = h.session.transactionsValue.single;
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.reqToAnyone), findsOneWidget);
      expect(find.byKey(requestFileWaitingKey), findsOneWidget);
    });
  });

  group('payer: a request file', () {
    testWidgets('opens the Review with the warn card and no name; Approve asks for the PIN, then Answer saved', (tester) async {
      final h = _Harness()..knowRequest();
      await h.open(tester, _requestJson);
      expect(find.text(_l.reqFromFileTitle), findsOneWidget);
      expect(find.byKey(requestFileWarnKey), findsOneWidget);
      expect(find.text(_l.reqFromFileWarn), findsOneWidget);
      expect(find.text(_l.reqFileMessageLabel), findsOneWidget);
      expect(find.text('Invoice 118, two bags of beans'), findsOneWidget);
      expect(find.text(_l.invoicesCheckEpicbox), findsNothing, reason: 'nothing goes over the relay');
      expect(h.session.paidRequestFiles, isEmpty);

      await h.approve(tester);
      expect(find.text(_l.reqAnswerTitle), findsOneWidget);
      expect(find.text(_l.reqAnswerLead), findsOneWidget);
      final paid = h.session.paidRequestFiles['req-file-1']!;
      expect(paid.amount, _epic(12.5), reason: 'the amount shown is the amount signed');
      await tester.tap(find.text(_l.slateSaveToDevice));
      await tester.pumpAndSettle();
      expect(h.files.saved.single.name, responseFileName('req-file-1'));
      expect(h.files.saved.single.json, paid.json);
      // The payment waits for the issuer, as a Sent row.
      final tx = h.session.transactionsValue.singleWhere((t) => t.slateId == 'req-file-1');
      expect(tx.kind, TxKind.sent);
      expect(tx.status, TxStatus.awaitingRecipient);
    });

    testWidgets('a cancelled PIN pays nothing; Not now closes and stores nothing', (tester) async {
      final h = _Harness()..knowRequest();
      await h.open(tester, _requestJson);
      await tester.tap(find.byKey(requestFileApproveKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.commonCancel));
      await tester.pumpAndSettle();
      expect(h.session.paidRequestFiles, isEmpty);
      await tester.tap(find.byKey(requestFileNotNowKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqFromFileTitle), findsNothing);
      expect(h.session.paidRequestFiles, isEmpty);
      expect(h.session.transactionsValue, isEmpty);
      expect(h.files.saved, isEmpty);
    });

    testWidgets('its message is plain text: bidi controls gone, cut at 120 with an ellipsis, never a link', (tester) async {
      final h = _Harness()..knowRequest(message: '\u202Epay https://evil.example ${'x' * 300}');
      await h.open(tester, _requestJson);
      final text = tester.widget<Text>(find.byKey(requestFileMessageKey));
      expect(text.data, isNotNull);
      expect(text.data, isNot(contains('\u202E')));
      expect(text.data!.runes.length, lessThanOrEqualTo(120));
      expect(text.data, endsWith('…'));
      expect(text.textSpan, isNull, reason: 'no rich text, so no recognizer');
      expect(find.ancestor(of: find.byKey(requestFileMessageKey), matching: find.byType(InkWell)), findsNothing);
      expect(find.ancestor(of: find.byKey(requestFileMessageKey), matching: find.byType(GestureDetector)), findsNothing);
    });

    testWidgets('one this wallet paid before opens read-only: already paid', (tester) async {
      final h = _Harness()..knowRequest();
      await h.session.payRequestFile(slateJson: _requestJson, amount: _epic(12.5));
      await h.open(tester, _requestJson);
      expect(find.text(_l.reqFileAlreadyPaid), findsOneWidget);
      expect(find.byKey(requestFileApproveKey), findsNothing);
    });

    testWidgets('with Invoices off it opens nothing and says Invoices are experimental', (tester) async {
      final h = _Harness()..knowRequest();
      h.store.values.remove(phoneAdvancedPrefsKey);
      await h.open(tester, _requestJson);
      expect(find.text(_l.expInvoicesOffTitle), findsOneWidget);
      expect(find.text(_l.expOpenAdvanced), findsOneWidget);
      expect(find.text(_l.reqFromFileTitle), findsNothing);
      expect(find.text(_l.slateAcceptPayment), findsNothing);
      expect(h.session.paidRequestFiles, isEmpty);
    });

    testWidgets('on a core without request files it is not a file this wallet takes', (tester) async {
      final h = _Harness()..knowRequest();
      h.session.requestFilesSupported = false;
      await h.open(tester, _requestJson);
      expect(find.text(_l.slateNotTransactionFile), findsOneWidget);
      expect(find.byKey(requestFileApproveKey), findsNothing);
    });

    testWidgets('sealed by a paired contact: the paired header, no warn card; the answer is sealed back', (tester) async {
      final h = _Harness()..knowRequest();
      final anna = h.session.pairing.seedPaired(name: 'Anna', paymentsAddress: 'es${'A' * 50}@epicbox.epiccash.com');
      final sealed = await h.session.pairing.sealSlate(id: anna.id, slateJson: _requestJson);
      await h.open(tester, sealed);
      expect(find.text(_l.reqRequests('Anna')), findsOneWidget);
      expect(find.byKey(requestFileWarnKey), findsNothing);
      expect(find.text(_l.reqFromFileTitle), findsNothing);
      await h.approve(tester);
      expect(find.text(_l.reqAnswerTitle), findsOneWidget);
      await tester.tap(find.text(_l.slateSaveToDevice));
      await tester.pumpAndSettle();
      expect(h.files.saved.single.name, sealedFileName('req-file-1'));
      expect(h.files.saved.single.json, startsWith('BEGINEPICSEALED'));
    });

    testWidgets('sealed, opened as LEPIC opens it (no slate handed out): the Review, paid sealed', (tester) async {
      final h = _Harness()..knowRequest();
      h.session.pairing.handsOutSealedSlate = false;
      final anna = h.session.pairing.seedPaired(name: 'Anna', paymentsAddress: 'es${'A' * 50}@epicbox.epiccash.com');
      final sealed = await h.session.pairing.sealSlate(id: anna.id, slateJson: _requestJson);
      await h.open(tester, sealed);
      // It used to say it was not a payment file (12b).
      expect(find.text(_l.slateNotTransactionFile), findsNothing);
      expect(find.text(_l.reqRequests('Anna')), findsOneWidget);
      expect(find.textContaining('Invoice 118'), findsOneWidget);
      await h.approve(tester);
      expect(h.session.pairing.calls, contains('paySealedRequest'));
      expect(find.text(_l.reqAnswerTitle), findsOneWidget);
      await tester.tap(find.text(_l.slateSaveToDevice));
      await tester.pumpAndSettle();
      expect(h.files.saved.single.json, startsWith('BEGINEPICSEALED'));
    });
  });

  group('issuer: the answer file', () {
    /// A request saved as a file here and the payer's answer to it.
    Future<String> answered(_Harness h) async {
      final slate = await h.session.pairing.requestFile(amount: _epic(7));
      const answer = '{"id":"answer","sta":"I2"}';
      h.service.slateInfos[answer] = SlateInfo(slateId: slate.slateId, amount: _epic(7), fee: _epic(0.01), stage: SlateStage.requestAnswer);
      return answer;
    }

    testWidgets('runs Finish payment with the request lead and the request turns paid', (tester) async {
      final h = _Harness();
      final answer = await answered(h);
      await h.open(tester, answer);
      expect(find.text(_l.slateIncomingRequestAnswer(epicExact(_l, _epic(7)))), findsOneWidget);
      await tester.tap(find.text(_l.slateFinishPayment));
      await tester.pumpAndSettle();
      expect(find.text(_l.slatePostedHeadline(epicExact(_l, _epic(7)))), findsOneWidget);
      expect((await h.session.issuedInvoices()).single.state, IssuedInvoiceState.paid);
    });

    testWidgets('an answer to a withdrawn request is refused: the request has ended', (tester) async {
      final h = _Harness();
      final answer = await answered(h);
      await h.session.withdrawInvoice(slateId: (await h.session.issuedInvoices()).single.slateId);
      await h.open(tester, answer);
      expect(find.text(_l.reqFileEnded), findsOneWidget);
      expect(find.text(_l.slateFinishPayment), findsNothing);
      expect(find.text(_l.slateIncomingResponseHint), findsNothing, reason: 'no "finish it" above a refusal');
    });

    testWidgets('an answer to a request this wallet does not have: the risk card and Close', (tester) async {
      final h = _Harness();
      const answer = '{"id":"stray","sta":"I2"}';
      h.service.slateInfos[answer] = SlateInfo(slateId: 'not-here', amount: _epic(7), fee: BigInt.zero, stage: SlateStage.requestAnswer);
      await h.open(tester, answer);
      expect(find.byKey(requestAnswerUnknownKey), findsOneWidget);
      expect(find.text(_l.reqAnswerUnknown), findsOneWidget);
      expect(find.text(_l.slateFinishPayment), findsNothing);
      expect(h.session.finalizedSlates, isEmpty);
      expect(_notice(tester), isNull);
    });
  });

  test('the round trip on one fake core: issue, pay, finish', () async {
    final h = _Harness();
    final slate = await h.session.pairing.requestFile(amount: _epic(5), message: 'hi');
    final info = await h.service.inspectSlate(json: slate.json);
    expect(info.stage, SlateStage.request);
    final paid = await h.session.payRequestFile(slateJson: slate.json, amount: _epic(5));
    expect((await h.service.inspectSlate(json: paid.json)).stage, SlateStage.requestAnswer);
    await h.session.finalizeAndPost(slateJson: paid.json);
    expect((await h.session.issuedInvoice(slateId: slate.slateId))!.state, IssuedInvoiceState.paid);
    await expectLater(
      h.session.payRequestFile(slateJson: slate.json, amount: _epic(5)),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.invoiceAlreadyPaid)),
    );
  });
}
