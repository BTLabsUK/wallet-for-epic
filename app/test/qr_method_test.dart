// SPDX-License-Identifier: Apache-2.0
// QR as a phone payment method: where it is offered (Send, Receive, Settings › Transactions),
// File moved behind Advanced and kept on phones that had it, the status line that says where a
// payment stands, and the whole exchange on the fake wallet: the sender makes the payment and
// shows it, the receiver scans, accepts and shows the reply, the sender scans it and posts.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/qr_slate.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/handshake.dart';
import 'package:epic_wallet/src/ui/net_block.dart' show offlineNodeNoteKey;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_scan_screen.dart';
import 'package:epic_wallet/src/ui/qr_show_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/experimental.dart';
import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A payment that takes three parts.
final String _paymentJson =
    '{"id":"slate-1","pad":"${'a' * (qrFragmentLen * 3 - 30)}"}';
final String _replyJson =
    '{"id":"slate-1","step":"response","pad":"${'b' * (qrFragmentLen * 2 - 40)}"}';

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Mainnet extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: mainnetPreset.nodeUrl,
  );
}

WalletSummary _summary({int height = 2499990}) => WalletSummary(
  lastConfirmedHeight: BigInt.from(height),
  minimumConfirmations: BigInt.from(3),
  total: _epic(40),
  spendable: _epic(40),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

class _Harness {
  _Harness({this.scanner = true, this.prefs = '|epicbox', this.invoicesOn = false}) {
    session = FakeWalletSession(summary: _summary())
      ..sendSlate = Slate(slateId: 'slate-1', json: _paymentJson)
      ..responseSlate = Slate(slateId: 'slate-1', json: _replyJson);
    allowPinCheck(session, service);
  }

  final bool scanner;

  /// The experimental Invoices switch.
  final bool invoicesOn;

  /// The stored payments value: QR on, File off (a phone's new wallet).
  final String? prefs;
  final service = FakeWalletService();
  final camera = FakeQrCamera();
  late final FakeWalletSession session;
  late ProviderContainer container;

  /// A mainnet wallet sealed under the test PIN, with [prefs] stored.
  MemorySecretStore store() {
    final s = sendPinStore();
    if (prefs != null) s.values['app.payment_prefs'] = prefs!;
    if (invoicesOn) s.values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
    return s;
  }

  List<Override> get overrides => [
    relayProbeProvider.overrideWithValue(FakeRelayProbe()),
    walletServiceProvider.overrideWithValue(service),
    secretStoreProvider.overrideWithValue(store()),
    slateFilesProvider.overrideWithValue(FakeSlateFiles()),
    qrScannerProvider.overrideWithValue(FakeQrScanner(supported: scanner)),
    qrCameraFactoryProvider.overrideWithValue(() => camera),
    phonePaymentsProvider.overrideWithValue(true),
    priceSourceProvider.overrideWithValue(_NoPrice()),
    sessionProvider.overrideWith(() => _Open(session)),
    walletConfigProvider.overrideWith(_Mainnet.new),
    relayDirectoryProvider.overrideWithValue(_NoRelays()),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    AdvancedPrefs advanced = AdvancedPrefs.none,
  }) async {
    tester.view.physicalSize = const Size(1080, 3300);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AdvancedOptions(prefs: advanced, child: child!),
          ),
          home: SlotScaffold(appBar: AppBar(), body: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  Future<List<String>> parts(String json) =>
      service.encodeQrSlate(json: json, maxFragmentLen: qrFragmentLen);

  /// Feeds [texts] to the camera, one at a time, letting the decoder answer each.
  Future<void> scan(WidgetTester tester, List<String> texts) async {
    for (final text in texts) {
      camera.emit(text);
      await tester.pump();
      await tester.pump();
    }
  }
}

/// The ways under an empty To field: Pay in person (QR) and Pay with a file.
Finder _way(String label) => find.widgetWithText(TextButton, label);

const _linkAddress = 'https://wallet.example.com:3415';

Future<void> _tick(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

String _howCaption(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(handshakeCaptionKey)).data!;

Future<void> _openHow(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_l.sendHowItWorks));
  await tester.pumpAndSettle();
}

void main() {
  group('How it works opens the explanation of the method', () {
    testWidgets(
      'QR Payment on Send: the five QR steps, phone to phone, no relay',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, SendView(onDone: () {}));
        await tester.tap(_way('Pay in person'));
        await tester.pumpAndSettle();
        await _openHow(tester);
        expect(find.byType(HandshakeSheet), findsOneWidget);
        expect(_howCaption(tester), '1. ${_l.handshakeQr1}');
        final steps = handshakeSteps(HandshakeFlow.qr);
        expect(steps, hasLength(5));
        for (final step in steps) {
          expect(step.caption(_l).toLowerCase(), isNot(contains('relay')));
        }
        expect(find.text(_l.handshakeRelay), findsNothing);
        expect(find.textContaining('relay'), findsNothing);
        expect(find.textContaining('Their wallet sends it back'), findsNothing);
      },
    );

    testWidgets('Epicbox, Link and File each open their own tab on Send', (
      tester,
    ) async {
      final h = _Harness(prefs: 'v2,http,tor,file|epicbox');
      await h.pump(tester, SendView(onDone: () {}));
      await _openHow(tester);
      expect(_howCaption(tester), '1. ${_l.handshakePay1}');
      await tester.tap(find.text(_l.commonClose));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, _l.sendToLabel), _linkAddress);
      await tester.pumpAndSettle();
      await _openHow(tester);
      expect(_howCaption(tester), '1. ${_l.handshakeLink1}');
      expect(find.text(_l.handshakeRelay), findsNothing);
      await tester.tap(find.text(_l.commonClose));
      await tester.pumpAndSettle();

      // The file way has its own help in the header instead (one help icon per header).
      await tester.tap(find.byKey(sendRecipientClearKey));
      await tester.pumpAndSettle();
      await tester.tap(_way('Pay with a file'));
      await tester.pumpAndSettle();
      expect(find.byTooltip(_l.sendHowItWorks), findsNothing);
      await tester.tap(find.byTooltip(_l.sendFileHelpTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(HandshakeSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Receive › QR Code: the receiver side, no relay', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveView());
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.byTooltip(_l.methodShortQr),
        ),
      );
      await tester.pumpAndSettle();
      await _openHow(tester);
      expect(_howCaption(tester), '1. ${_l.handshakeQrR1}');
      expect(find.textContaining('relay'), findsNothing);
      expect(find.text(_l.handshakeRelay), findsNothing);
    });
  });

  group('where it is offered', () {
    testWidgets('Send: Pay in person on a new phone, Pay with a file not', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, SendView(onDone: () {}));
      expect(find.byKey(sendMethodsKey), findsNothing);
      expect(_way('Pay in person'), findsOneWidget);
      expect(_way('Pay with a file'), findsNothing);
    });

    testWidgets('Send: the ways are Pay in person, then Pay with a file', (
      tester,
    ) async {
      final h = _Harness(prefs: 'v2,http,tor,file|epicbox');
      await h.pump(tester, SendView(onDone: () {}));
      final names = ['Pay in person', 'Pay with a file'];
      final xs = [for (final n in names) tester.getTopLeft(_way(n)).dx];
      expect(xs, [...xs]..sort());
    });

    testWidgets(
      'Send: no QR where the camera does not work, or when QR is off',
      (tester) async {
        var h = _Harness(scanner: false);
        await h.pump(tester, SendView(onDone: () {}));
        expect(_way('Pay in person'), findsNothing);
        h = _Harness(prefs: 'file,noqr|epicbox');
        await h.pump(tester, SendView(onDone: () {}));
        expect(_way('Pay in person'), findsNothing);
        expect(_way('Pay with a file'), findsOneWidget);
      },
    );

    testWidgets('Receive: a QR tab with its card and the scan button', (
      tester,
    ) async {
      final h = _Harness(invoicesOn: true);
      await h.pump(tester, const ReceiveView());
      expect(find.byKey(receiveTabsKey), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.byTooltip(_l.methodShortQr),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l.receiveQrTitle), findsOneWidget);
      expect(find.byKey(receiveScanQrKey), findsOneWidget);
      // Asking for an amount, shown as a QR, sits under the scan (Invoices on).
      expect(find.byKey(receiveQrRequestKey), findsOneWidget);
      expect(find.text(_l.methodShortFile), findsNothing);
    });

    testWidgets('Receive: with Invoices off the QR tab has no Request button', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveView());
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.byTooltip(_l.methodShortQr),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(receiveScanQrKey), findsOneWidget);
      expect(find.byKey(receiveQrRequestKey), findsNothing);
    });

    // Offline lets QR Payment use the node in use, like a file; on a node that is not local
    // the note under the button says so.
    testWidgets(
      'Receive: scanning runs Offline on the node in use, with the node note',
      (tester) async {
        final h = _Harness();
        await h.pump(
          tester,
          const ReceiveView(),
          advanced: const AdvancedPrefs(networkMode: NetworkMode.nodeOnly),
        );
        await tester.tap(
          find.descendant(
            of: find.byKey(receiveTabsKey),
            matching: find.byTooltip(_l.methodShortQr),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byKey(receiveScanQrKey)).onPressed,
          isNotNull,
        );
        expect(find.byKey(offlineNodeNoteKey), findsOneWidget);
      },
    );
  });

  group('the status line', () {
    final tip = BigInt.from(100);
    TxEntry received(TxStatus status, {BigInt? height}) => fakeTx(
      slateId: 'slate-1',
      kind: TxKind.received,
      status: status,
      blockHeight: height,
    );

    String say(QrShowPhase phase, {bool reply = false, TxEntry? tx}) =>
        qrShowStatus(
          _l,
          reply: reply,
          phase: phase,
          tx: tx,
          tip: tip,
          target: 3,
        ).text;

    test('the sender: show this, wait for the scan, show again', () {
      expect(say(QrShowPhase.hidden), 'Show this to the recipient.');
      expect(
        say(QrShowPhase.showing),
        'Waiting for the recipient to scan. Then scan their reply.',
      );
      expect(
        say(QrShowPhase.timedOut),
        'Hidden',
      );
      expect(say(QrShowPhase.away), say(QrShowPhase.timedOut));
    });

    test('the receiver follows the received payment to Received', () {
      expect(say(QrShowPhase.hidden, reply: true), 'Hidden');
      expect(
        say(QrShowPhase.showing, reply: true),
        'Waiting for the sender to scan.',
      );
      final waiting = received(TxStatus.awaitingConfirmation);
      expect(
        say(QrShowPhase.showing, reply: true, tx: waiting),
        'Payment received. Waiting for the sender to scan and post it.',
      );
      expect(
        say(QrShowPhase.timedOut, reply: true, tx: waiting),
        'Hidden',
      );
      final posted = received(
        TxStatus.awaitingConfirmation,
        height: BigInt.from(100),
      );
      expect(
        say(QrShowPhase.showing, reply: true, tx: posted),
        'Posted. Confirming 1/3',
      );
      final done = received(TxStatus.confirmed, height: BigInt.from(98));
      final status = qrShowStatus(
        _l,
        reply: true,
        phase: QrShowPhase.timedOut,
        tx: done,
        tip: tip,
        target: 3,
      );
      expect(status.text, 'Received.');
      expect(status.tone, QrStatusTone.ok);
    });
  });

  group('the first start of this version', () {
    Future<AppSettings> load(
      MemorySecretStore store, {
      bool phone = true,
    }) async {
      final container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(store),
          phonePaymentsProvider.overrideWithValue(phone),
        ],
      );
      addTearDown(container.dispose);
      return container.read(appSettingsProvider.future);
    }

    MemorySecretStore withWallet([Map<String, String> more = const {}]) =>
        MemorySecretStore({'wallet.mainnet.pinSealed': 'sealed', ...more});

    test(
      'a phone with a wallet and nothing chosen keeps File, saved on',
      () async {
        final store = withWallet();
        final s = await load(store);
        expect(s.payments.directFile, isTrue);
        expect(s.payments.directQr, isTrue);
        expect(store.values['app.payment_prefs'], 'v2,file|epicbox');
        expect(store.values['app.qr_method_seen'], '1');
      },
    );

    test('a phone whose stored choice has File on keeps it', () async {
      final store = withWallet({'app.payment_prefs': 'direct,file|direct'});
      final s = await load(store);
      expect(s.payments.directFile, isTrue);
      // The one Link switch sent to web and onion addresses alike: both Link methods on.
      expect(s.payments.linkTor, isTrue);
      expect(s.payments.linkHttp, isTrue);
      expect(s.payments.startMethod.family, MethodFamily.link);
      expect(
        PaymentPrefs.decode(store.values['app.payment_prefs'], phone: true),
        s.payments,
      );
    });

    test('a phone that had turned File off keeps it off', () async {
      final store = withWallet({'app.payment_prefs': 'direct|epicbox'});
      final s = await load(store);
      expect(s.payments.directFile, isFalse);
      expect(s.payments.directQr, isTrue);
    });

    test('a new install gets QR and no File, and stays so after its wallet is made', () async {
      final store = MemorySecretStore();
      final s = await load(store);
      expect(s.payments.directFile, isFalse);
      expect(s.payments.directQr, isTrue);
      expect(s.payments.linkHttp, isFalse);
      expect(s.payments.linkTor, isFalse);
      expect(store.values.containsKey('app.payment_prefs'), isFalse);
      // The wallet is created later; the next start does not migrate it.
      store.values['wallet.mainnet.pinSealed'] = 'sealed';
      final again = await load(store);
      expect(again.payments.directFile, isFalse);
    });

    test('the desktop is left alone: File on, nothing written', () async {
      final store = withWallet();
      final s = await load(store, phone: false);
      expect(s.payments.directFile, isTrue);
      expect(store.values.containsKey('app.payment_prefs'), isFalse);
      expect(store.values.containsKey('app.qr_method_seen'), isFalse);
    });
  });

  group('the QR exchange on the fake wallet', () {
    testWidgets('Send: make the payment, show it, scan the reply, post it', (
      tester,
    ) async {
      final h = _Harness();
      h.service.slateInfos[_replyJson] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1),
        fee: BigInt.from(8000000),
        stage: SlateStage.response,
      );
      await h.pump(tester, SendView(onDone: () {}));
      await tester.tap(_way('Pay in person'));
      await tester.pumpAndSettle();
      expect(find.text(_l.methodDirectQr), findsOneWidget);

      await tester.enterText(find.byKey(sendFileAmountFieldKey), '1');
      // Past the fee estimate's debounce: Make payment QR waits for it.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make payment QR'));
      await tester.pumpAndSettle();
      await answerPin(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // The code opens by itself, hidden, with what to do.
      expect(find.text(_l.qrShowTitlePayment), findsOneWidget);
      expect(find.text(_l.qrStatusSendHidden), findsOneWidget);
      expect(h.session.sentAmounts, [_epic(1)]);
      await tester.tap(find.byKey(qrShowButtonKey));
      await _tick(tester, 3);
      expect(
        find.text('Waiting for the recipient to scan. Then scan their reply.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(qrNextButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_l.qrScanReply), findsWidgets);
      final replyParts = await h.parts(_replyJson);
      final n = partCountOf(replyParts.first);
      await h.scan(tester, replyParts.take(1).toList());
      expect(
        find.text('Scanned 1 of $n. Keep the code in the frame.'),
        findsOneWidget,
      );
      await h.scan(tester, replyParts.skip(1).toList());
      await tester.pump(qrCompleteFor);
      // Posting, then Posted, then back on Send with the payment on its way.
      await tester.pump();
      await tester.pump(qrPostedFor);
      await tester.pumpAndSettle();
      expect(h.session.finalizedSlates, [_replyJson]);
      expect(find.text('Confirming 0/3'), findsOneWidget);
      expect(find.text(_l.txStepPosted), findsOneWidget);
    });

    testWidgets(
      'Send: a reply of another payment is said so and nothing is posted',
      (tester) async {
        final h = _Harness();
        final other = '{"id":"slate-9","step":"response"}';
        h.service.slateInfos[other] = SlateInfo(
          slateId: 'slate-9',
          amount: _epic(1),
          fee: BigInt.from(8000000),
          stage: SlateStage.response,
        );
        await h.pump(tester, SendView(onDone: () {}));
        await tester.tap(_way('Pay in person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(sendFileAmountFieldKey), '1');
        // Past the fee estimate's debounce: Make payment QR waits for it.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Make payment QR'));
        await tester.pumpAndSettle();
        await answerPin(tester);
        await tester.pump(const Duration(milliseconds: 300));
        // Back to the step under the code, then scan from there.
        Navigator.of(tester.element(find.byType(QrShowScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byKey(sendScanReplyKey), findsOneWidget);
        await tester.tap(find.byKey(sendScanReplyKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await h.scan(tester, await h.parts(other));
        await tester.pump(qrCompleteFor);
        await tester.pumpAndSettle();
        expect(h.session.finalizedSlates, isEmpty);
        expect(
          find.text(
            _l.slateWrongPaymentQr,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Receive: with File on, the reply can also be saved', (
      tester,
    ) async {
      final h = _Harness(prefs: 'file|epicbox');
      final json = _paymentJson;
      h.service.slateInfos[json] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1),
        fee: BigInt.from(8000000),
        stage: SlateStage.send,
      );
      await h.pump(tester, const ReceiveView());
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.byTooltip(_l.methodShortQr),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(receiveScanQrKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await h.scan(tester, await h.parts(json));
      await tester.pump(qrCompleteFor);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.slateAcceptPayment));
      await tester.pumpAndSettle();
      expect(find.byKey(showReplyQrKey), findsOneWidget);
      expect(find.text(_l.slateSaveToDevice), findsOneWidget);
    });

    testWidgets('Receive: scan, accept, show the reply, follow the payment', (
      tester,
    ) async {
      final h = _Harness();
      final json = _paymentJson;
      h.service.slateInfos[json] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1),
        fee: BigInt.from(8000000),
        stage: SlateStage.send,
      );
      await h.pump(tester, const ReceiveView());
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.byTooltip(_l.methodShortQr),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(receiveScanQrKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_l.qrScanPayment), findsWidgets);
      await h.scan(tester, await h.parts(json));
      expect(find.text(_l.qrScanGot), findsOneWidget);
      await tester.pump(qrCompleteFor);
      await tester.pumpAndSettle();

      // The payment screen of a scanned payment.
      expect(find.text(_l.slateScannedPaymentTitle), findsOneWidget);
      expect(
        find.text(_l.slateIncomingSendHintQr),
        findsOneWidget,
      );
      // Titled for the method, with no word of files.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_l.methodDirectQr),
        ),
        findsOneWidget,
      );
      expect(find.text(_l.slateFileTitle), findsNothing);
      await tester.tap(find.text(_l.slateAcceptPayment));
      await tester.pumpAndSettle();
      expect(
        find.text(_l.slateAcceptedHeadlineQr),
        findsOneWidget,
      );
      expect(find.byKey(showReplyQrKey), findsOneWidget);
      // The home notice stays quiet while this screen is open.
      expect(qrPaymentScreensOpen, 1);
      // File is off on this phone: no Save, Share or Copy under the reply QR.
      expect(find.text(_l.slateSaveToDevice), findsNothing);
      expect(find.text(_l.slateCopyReply), findsNothing);

      await tester.tap(find.byKey(showReplyQrKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_l.qrShowTitleReply), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      await tester.tap(find.byKey(qrShowButtonKey));
      await _tick(tester, 3);
      expect(find.text('Waiting for the sender to scan.'), findsOneWidget);

      // The received payment shows in the wallet's history, then the sender posts it.
      h.session.transactionsValue = [
        fakeTx(
          slateId: 'slate-1',
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
        ),
      ];
      await h.container.read(homeProvider.notifier).reload();
      await tester.pump();
      expect(
        find.text(
          'Payment received. Waiting for the sender to scan and post it.',
        ),
        findsOneWidget,
      );
      h.session.transactionsValue = [
        fakeTx(
          slateId: 'slate-1',
          kind: TxKind.received,
          status: TxStatus.awaitingConfirmation,
          blockHeight: BigInt.from(2499990),
        ),
      ];
      await h.container.read(homeProvider.notifier).reload();
      await tester.pump();
      expect(find.text('Posted. Confirming 1/3'), findsOneWidget);
      // Posted: the hidden card and its Show again give way to the done card, Done is primary.
      expect(find.byKey(qrDoneCardKey), findsOneWidget);
      expect(find.text(_l.qrShowAgain), findsNothing);
      expect(find.byKey(qrShowButtonKey), findsNothing);
      expect(find.byKey(qrNextButtonKey), findsOneWidget);
      expect(tester.widget(find.byKey(qrNextButtonKey)), isA<FilledButton>());
      h.session.transactionsValue = [
        fakeTx(
          slateId: 'slate-1',
          kind: TxKind.received,
          status: TxStatus.confirmed,
          blockHeight: BigInt.from(2499980),
        ),
      ];
      await h.container.read(homeProvider.notifier).reload();
      await tester.pump();
      expect(find.text(_l.qrStatusReceived), findsOneWidget);
      expect(find.byKey(qrDoneCardKey), findsOneWidget);

      // Done closes the reply and the payment screen behind it.
      await tester.tap(find.byKey(qrNextButtonKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.qrShowTitleReply), findsNothing);
      expect(
        find.text(_l.slateAcceptedHeadlineQr),
        findsNothing,
      );
      expect(h.session.receivedSlates, [json]);
    });
  });

  // next-fixes 12: 5 EPIC with 0.892 available, and "Make payment QR" took the tap before the
  // fee estimate came back.
  group('Make payment QR waits for the amount check', () {
    Finder make() => find.widgetWithText(FilledButton, 'Make payment QR');
    Finder amount() => find.widgetWithText(TextField, 'Amount (EPIC)');

    testWidgets('more than spendable: off on the keystroke, with the reason', (tester) async {
      final h = _Harness(prefs: '|qr');
      h.session.summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(2499990),
        minimumConfirmations: BigInt.from(3),
        total: _epic(0.892),
        spendable: _epic(0.892),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await h.pump(tester, SendView(onDone: () {}));
      await tester.enterText(amount(), '5');
      // One frame: inside the estimate's debounce, nothing asked of the wallet yet.
      await tester.pump();
      expect(find.byKey(sendNotEnoughKey), findsOneWidget);
      expect(find.text(_l.errorNotEnoughFunds), findsOneWidget);
      expect(tester.widget<FilledButton>(make()).onPressed, isNull);
      await tester.tap(make(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, _l.pinLabel), findsNothing);
      expect(h.session.sentAmounts, isEmpty);
      expect(tester.widget<FilledButton>(make()).onPressed, isNull);
    });

    testWidgets('within the balance: off until the estimate for it has come', (tester) async {
      final h = _Harness(prefs: '|qr');
      await h.pump(tester, SendView(onDone: () {}));
      await tester.enterText(amount(), '0.5');
      await tester.pump();
      expect(find.byKey(sendNotEnoughKey), findsNothing);
      expect(tester.widget<FilledButton>(make()).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(make()).onPressed, isNotNull);
      // A new amount waits again.
      await tester.enterText(amount(), '0.6');
      await tester.pump();
      expect(tester.widget<FilledButton>(make()).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(make()).onPressed, isNotNull);
    });
  });
}
