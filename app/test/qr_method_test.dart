// QR as a phone payment method: where it is offered (Send, Receive, Settings › Transactions),
// File moved behind Advanced and kept on phones that had it, the status line that says where a
// payment stands, and the whole exchange on the fake wallet: the sender makes the payment and
// shows it, the receiver scans, accepts and shows the reply, the sender scans it and posts.

import 'package:epic_wallet/src/demo.dart';
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
  _Harness({this.scanner = true, this.prefs = '|epicbox'}) {
    session = FakeWalletSession(summary: _summary())
      ..sendSlate = Slate(slateId: 'slate-1', json: _paymentJson)
      ..responseSlate = Slate(slateId: 'slate-1', json: _replyJson);
    allowPinCheck(session, service);
  }

  final bool scanner;

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
    demoModeProvider.overrideWithValue(false),
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
    container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
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

Finder _segment(String label) => find.descendant(
  of: find.byKey(sendMethodsKey),
  matching: find.text(label),
);

Future<void> _tick(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  group('where it is offered', () {
    testWidgets('Send: Epicbox · QR on a new phone, File and Direct not', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, SendView(onDone: () {}));
      expect(_segment('Epicbox'), findsOneWidget);
      expect(_segment('QR'), findsOneWidget);
      expect(_segment('File'), findsNothing);
      expect(_segment('Direct'), findsNothing);
    });

    testWidgets('Send: the order is Epicbox · Direct · QR · File', (tester) async {
      final h = _Harness(prefs: 'direct,file|epicbox');
      await h.pump(tester, SendView(onDone: () {}));
      final names = ['Epicbox', 'Direct', 'QR', 'File'];
      final xs = [
        for (final n in names) tester.getTopLeft(_segment(n)).dx,
      ];
      expect(xs, [...xs]..sort());
    });

    testWidgets('Send: no QR where the camera does not work, or when QR is off', (
      tester,
    ) async {
      var h = _Harness(scanner: false);
      await h.pump(tester, SendView(onDone: () {}));
      expect(find.byKey(sendMethodsKey), findsNothing);
      h = _Harness(prefs: 'file,noqr|epicbox');
      await h.pump(tester, SendView(onDone: () {}));
      expect(_segment('QR'), findsNothing);
      expect(_segment('File'), findsOneWidget);
    });

    testWidgets('Send starts on QR when Settings says so', (tester) async {
      final h = _Harness(prefs: '|qr');
      await h.pump(tester, SendView(onDone: () {}));
      expect(find.text('Pay with a QR code'), findsOneWidget);
      expect(find.text('Make payment QR'), findsOneWidget);
    });

    testWidgets('Receive: a QR tab with its card and the scan button', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveView());
      expect(find.byKey(receiveTabsKey), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.text('QR'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Standing next to the sender?'), findsOneWidget);
      expect(find.byKey(receiveScanQrKey), findsOneWidget);
      expect(find.text('File'), findsNothing);
    });

    testWidgets('Receive: scanning waits for the network mode like a file does', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        const ReceiveView(),
        advanced: const AdvancedPrefs(networkMode: NetworkMode.offline),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(receiveTabsKey),
          matching: find.text('QR'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byKey(receiveScanQrKey)).onPressed,
        isNull,
      );
    });
  });

  group('the status line', () {
    final tip = BigInt.from(100);
    TxEntry received(TxStatus status, {BigInt? height}) => fakeTx(
      slateId: 'slate-1',
      kind: TxKind.received,
      status: status,
      blockHeight: height,
    );

    String say(
      QrShowPhase phase, {
      bool reply = false,
      TxEntry? tx,
    }) => qrShowStatus(
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
        'Hidden. Show again if they did not finish scanning.',
      );
      expect(say(QrShowPhase.away), say(QrShowPhase.timedOut));
    });

    test('the receiver follows the received payment to Received', () {
      expect(say(QrShowPhase.hidden, reply: true), 'Show this to the sender.');
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
        say(
          QrShowPhase.timedOut,
          reply: true,
          tx: waiting,
        ),
        'Hidden. Show again if they did not finish scanning.',
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
    Future<AppSettings> load(MemorySecretStore store, {bool phone = true}) async {
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

    test('a phone with a wallet and nothing chosen keeps File, saved on', () async {
      final store = withWallet();
      final s = await load(store);
      expect(s.payments.file, isTrue);
      expect(s.payments.qr, isTrue);
      expect(store.values['app.payment_prefs'], 'file|epicbox');
      expect(store.values['app.qr_method_seen'], '1');
    });

    test('a phone whose stored choice has File on keeps it', () async {
      final store = withWallet({'app.payment_prefs': 'direct,file|direct'});
      final s = await load(store);
      expect(s.payments.file, isTrue);
      expect(s.payments.direct, isTrue);
      expect(s.payments.defaultMethod, PayMethod.direct);
      expect(store.values['app.payment_prefs'], 'direct,file|direct');
    });

    test('a phone that had turned File off keeps it off', () async {
      final store = withWallet({'app.payment_prefs': 'direct|epicbox'});
      final s = await load(store);
      expect(s.payments.file, isFalse);
      expect(s.payments.qr, isTrue);
    });

    test('a new install gets QR and no File, and stays so after its wallet is made', () async {
      final store = MemorySecretStore();
      final s = await load(store);
      expect(s.payments.file, isFalse);
      expect(s.payments.qr, isTrue);
      expect(store.values.containsKey('app.payment_prefs'), isFalse);
      // The wallet is created later; the next start does not migrate it.
      store.values['wallet.mainnet.pinSealed'] = 'sealed';
      final again = await load(store);
      expect(again.payments.file, isFalse);
    });

    test('the desktop is left alone: File on, nothing written', () async {
      final store = withWallet();
      final s = await load(store, phone: false);
      expect(s.payments.file, isTrue);
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
      await tester.tap(_segment('QR'));
      await tester.pumpAndSettle();
      expect(find.text('Pay with a QR code'), findsOneWidget);

      await tester.enterText(find.byKey(sendFileAmountFieldKey), '1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make payment QR'));
      await tester.pumpAndSettle();
      await answerPin(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // The code opens by itself, hidden, with what to do.
      expect(find.text('Payment QR'), findsOneWidget);
      expect(find.text('Show this to the recipient.'), findsOneWidget);
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
      expect(find.text('Scan their reply'), findsWidgets);
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
      expect(find.text('Sent to the network'), findsOneWidget);
    });

    testWidgets('Send: a reply of another payment is said so and nothing is posted', (
      tester,
    ) async {
      final h = _Harness();
      final other = '{"id":"slate-9","step":"response"}';
      h.service.slateInfos[other] = SlateInfo(
        slateId: 'slate-9',
        amount: _epic(1),
        fee: BigInt.from(8000000),
        stage: SlateStage.response,
      );
      await h.pump(tester, SendView(onDone: () {}));
      await tester.tap(_segment('QR'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(sendFileAmountFieldKey), '1');
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
        find.text('This reply is for a different payment. Scan the reply for this send.'),
        findsOneWidget,
      );
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
          matching: find.text('QR'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(receiveScanQrKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Scan payment QR'), findsWidgets);
      await h.scan(tester, await h.parts(json));
      expect(find.text('Got it'), findsOneWidget);
      await tester.pump(qrCompleteFor);
      await tester.pumpAndSettle();

      // The payment screen of a scanned payment.
      expect(find.text('Scanned payment'), findsOneWidget);
      expect(find.text('Accept it, then show the reply to the sender.'), findsOneWidget);
      await tester.tap(find.text('Accept payment'));
      await tester.pumpAndSettle();
      expect(find.text('Accepted. Show the reply to the sender.'), findsOneWidget);
      expect(find.byKey(showReplyQrKey), findsOneWidget);

      await tester.tap(find.byKey(showReplyQrKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Reply QR'), findsOneWidget);
      expect(find.text('Show this to the sender.'), findsOneWidget);
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
        find.text('Payment received. Waiting for the sender to scan and post it.'),
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
      expect(find.text('Received.'), findsOneWidget);

      // Done closes the reply and the payment screen behind it.
      await tester.tap(find.byKey(qrNextButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Reply QR'), findsNothing);
      expect(find.text('Accepted. Show the reply to the sender.'), findsNothing);
      expect(h.session.receivedSlates, [json]);
    });
  });
}
