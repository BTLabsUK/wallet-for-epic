// Send's four methods (spec 7): a selector with Epicbox, HTTP, Tor and File, a strip with a
// picture and one plain line, the shape of the method's address under To. The method follows
// the address (desktop spec 8.4): a paste, a pick or a whole address of another kind moves it,
// typing never does half way, and nothing moves it back. HTTP sends straight to their wallet:
// delivered, it waits only for a block and cannot be cancelled; not reached, the amount is on
// hold with Try again and Cancel payment. Each review states its cancel rule. Receive shows
// the same strip per tab, and Tor's honest line.

import 'dart:async';

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/method_strip.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid address for [FakeWalletService.validateEpicboxAddress].
final String _bob = '${'b' * 52}@epicbox.epiccash.com';

const String _name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const String _onion = '$_name.onion';

const String _https = 'https://wallet.example.com:3415';
const String _lan = 'http://10.0.1.24:3415';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

WalletSummary _summary() => WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: _epic(40),
  spendable: _epic(40),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

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

/// The fake, but a direct send their wallet answered is finalized and posted, as LEPIC's:
/// confirming, no longer waiting for the recipient.
class _DirectSession extends FakeWalletSession {
  _DirectSession() : super(summary: _summary());

  void _answered(int txId) {
    final i = transactionsValue.indexWhere((t) => t.id == txId);
    final tx = transactionsValue[i];
    transactionsValue[i] = fakeTx(
      id: tx.id,
      slateId: tx.slateId,
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: tx.createdAtUnix,
      amountDebited: tx.amountDebited,
      fee: tx.fee,
      counterparty: tx.counterparty,
    );
  }

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
  }) async {
    final sent = await super.sendHttp(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      url: url,
      allowPlainHttp: allowPlainHttp,
      message: message,
      options: options,
    );
    _answered(sent.txId);
    return sent;
  }

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) async {
    final sent = await super.resendHttp(
      txId: txId,
      url: url,
      allowPlainHttp: allowPlainHttp,
    );
    _answered(sent.txId);
    return sent;
  }
}

class _Harness {
  _Harness() {
    allowPinCheck(session);
  }

  final session = _DirectSession();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Widget? body,
    double height = 2340,
  }) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(sendPinStore()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          demoModeProvider.overrideWithValue(false),
          torBundleFinderProvider.overrideWithValue(() async => _bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          phoneTorTimingProvider.overrideWithValue(
            const PhoneTorTiming(
              backoff: [Duration(hours: 1)],
              sendWait: Duration(hours: 1),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            // Spinners never settle; a still icon stands in for them.
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AdvancedOptions(enabled: false, child: child!),
          ),
          home: SlotScaffold(
            appBar: AppBar(),
            body: body ?? SendView(onDone: () {}),
          ),
        ),
      ),
    );
    await _settle(tester);
    container = ProviderScope.containerOf(
      tester.element(find.byType(SlotScaffold).first),
    );
    // The Tor controller reads the bundle and the onion with real async.
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) break;
      await _settle(tester);
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  /// Through recipient and amount to the review.
  Future<void> toReview(WidgetTester tester, String address) async {
    await _enter(tester, 'To', address);
    await _tap(tester, _continue);
    await _enter(tester, 'Amount (EPIC)', '1');
    await _tap(tester, _continue);
    expect(find.text('Review'), findsOneWidget);
  }
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

/// Frames and a slice of real time: the Tor controller's work completes on microtasks the
/// test clock does not flush.
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

Future<void> _reach(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reach(tester, finder);
  await tester.tap(finder);
  await _settle(tester);
  if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
    await answerPin(tester, settle: false);
    await _settle(tester);
  }
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reach(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await _settle(tester);
}

/// The method the selector shows.
TransferMethod _method(WidgetTester tester) => tester
    .widget<SegmentedButton<TransferMethod>>(find.byKey(sendMethodsKey))
    .selected
    .single;

/// The segment named [label] in Send's selector.
Finder _segment(String label) =>
    find.descendant(of: find.byKey(sendMethodsKey), matching: find.text(label));

/// Types [text] into To one character at a time, as a keyboard does, and returns the method
/// after each character.
Future<List<TransferMethod>> _type(WidgetTester tester, String text) async {
  final field = find.widgetWithText(TextField, 'To');
  final seen = <TransferMethod>[];
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
    await tester.pump();
    seen.add(_method(tester));
  }
  return seen;
}

/// How many times the method changed along [seen], starting from [from].
int _switches(TransferMethod from, List<TransferMethod> seen) {
  var n = 0;
  var last = from;
  for (final m in seen) {
    if (m != last) n++;
    last = m;
  }
  return n;
}

void _clipboard(WidgetTester tester, String? Function() text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async =>
        call.method == 'Clipboard.getData' ? {'text': text()} : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

void main() {
  group('selector and strip', () {
    testWidgets('four segments, Epicbox first; each with its strip and shape', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      for (final label in ['Epicbox', 'HTTP', 'Tor', 'File']) {
        expect(_segment(label), findsOneWidget, reason: label);
      }
      final xs = [
        for (final label in ['Epicbox', 'HTTP', 'Tor', 'File'])
          tester.getCenter(_segment(label)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(_method(tester), TransferMethod.epicbox);
      expect(
        tester.getSize(find.byKey(sendMethodsKey)).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.text('The recipient can be offline.'), findsOneWidget);
      expect(
        find.text(
          'The Epicbox server holds the payment until they open their wallet.',
        ),
        findsOneWidget,
      );
      expect(find.text('esXXXX…XXXX@epicbox.epiccash.com'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('Address or contact'), findsOneWidget);

      await _tap(tester, _segment('HTTP'));
      expect(_method(tester), TransferMethod.http);
      expect(find.text('Straight to their wallet.'), findsOneWidget);
      expect(
        find.text('It must be open and reachable at its HTTP address.'),
        findsOneWidget,
      );
      expect(find.text('http://host:3415'), findsOneWidget);

      await _tap(tester, _segment('Tor'));
      expect(find.text('Straight to their wallet, over Tor.'), findsOneWidget);
      expect(
        find.text('Slower and more private. Their wallet must be open.'),
        findsOneWidget,
      );
      expect(find.text('xxxxxxxx…xxxx.onion'), findsOneWidget);

      await _tap(tester, _segment('File'));
      expect(find.text('No connection needed.'), findsOneWidget);
      expect(
        find.text(
          'Hand the file over, get their response file back, then finalize it here.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      expect(
        find.text('Can be cancelled until the response file is finalized.'),
        findsOneWidget,
      );

      // Back to an address method: the form again.
      await _tap(tester, _segment('Epicbox'));
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    });

    testWidgets('the ? beside the shape opens help on the address kinds', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.byTooltip('Address kinds'));
      expect(find.byType(HelpScreen), findsOneWidget);
      expect(
        find.text(
          'An Epicbox address starts with es and ends in @ and the server. An '
          'HTTP address is a web address. A Tor address ends in .onion.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a pasted name finds the contact', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Alice', address: _bob, note: null),
      );
      await h.pump(tester);
      await _enter(tester, 'To', 'ali');
      await _tap(tester, find.text('Alice'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'To'))
            .controller!
            .text,
        _bob,
      );
    });
  });

  group('the method follows the address', () {
    testWidgets('typing es stays on Epicbox', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final seen = await _type(tester, 'es');
      expect(seen, everyElement(TransferMethod.epicbox));
      expect(find.byKey(sendSwitchedTagKey), findsNothing);
    });

    testWidgets(
      'a whole Epicbox address pasted under Tor moves it to Epicbox',
      (tester) async {
        String? clip;
        _clipboard(tester, () => clip);
        final semantics = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester);
        await _tap(tester, _segment('Tor'));
        expect(_method(tester), TransferMethod.tor);
        clip = _bob;
        await _tap(tester, find.text('Paste'));
        expect(_method(tester), TransferMethod.epicbox);
        // The field keeps the text, and the tag says why.
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'To'))
              .controller!
              .text,
          _bob,
        );
        expect(find.text('Via Epicbox'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Epicbox address. Method set to Epicbox.'),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'a bare onion typed by hand moves it to Tor once, at the 56th character',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester);
        final seen = await _type(tester, _name);
        expect(_switches(TransferMethod.epicbox, seen), 1);
        expect(seen.indexOf(TransferMethod.tor), _name.length - 1);
        expect(
          find.descendant(
            of: find.byKey(sendSwitchedTagKey),
            matching: find.text('Over Tor'),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Tor address. Method set to Tor.'),
          findsOneWidget,
        );
        semantics.dispose();
        // The tag goes after 3 s; the method stays.
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester
              .widget<AnimatedOpacity>(find.byKey(sendSwitchedTagKey))
              .opacity,
          0,
        );
        // Never back: one more character breaks the onion, Tor stays.
        final more = await _type(tester, '${_name}x');
        expect(more.last, TransferMethod.tor);
      },
    );

    testWidgets('http://10.0.1.24 typed moves it to HTTP once the host is '
        'whole', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      const url = 'http://10.0.1.24';
      final seen = await _type(tester, url);
      expect(_switches(TransferMethod.epicbox, seen), 1);
      expect(seen.last, TransferMethod.http);
      // Not while the host is half typed.
      expect(
        seen[url.indexOf('192.168.') + '192.168.'.length - 1],
        TransferMethod.epicbox,
      );
      expect(find.text('Over HTTP'), findsOneWidget);
    });

    testWidgets('a Tor contact picked moves it to Tor', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Tor Tom', address: _onion, note: null),
      );
      await h.pump(tester);
      await _tap(tester, find.text('Contacts'));
      await _tap(tester, find.text('Tor Tom'));
      expect(_method(tester), TransferMethod.tor);
      expect(find.text('Over Tor'), findsWidgets);
    });

    testWidgets('choosing a method by hand never clears the field', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _bob);
      await _tap(tester, _segment('HTTP'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'To'))
            .controller!
            .text,
        _bob,
      );
      await _tap(tester, _continue);
      expect(
        find.text('An HTTP address starts with http:// or https://.'),
        findsOneWidget,
      );
    });
  });

  group('HTTP send', () {
    testWidgets('delivered: the tracker waits for a block, with no Cancel', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _https);
      expect(find.text('HTTP, straight to their wallet'), findsOneWidget);
      expect(
        find.text('Cannot be cancelled once their wallet accepts it.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(h.session.httpSends, hasLength(1));
      expect(h.session.httpSends.single.url, _https);
      expect(h.session.httpSends.single.allowPlainHttp, isFalse);
      expect(h.session.epicboxSends, isEmpty);
      expect(find.text('Delivered · Waiting for a block'), findsOneWidget);
      expect(find.textContaining('Cancel'), findsNothing);
    });

    testWidgets('not reached: on hold, Try again delivers it again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _https);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'their wallet did not answer',
      );
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(
        find.text(
          'Their wallet was not reached. The amount is on hold until you cancel '
          'it, or for at most 14 days.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(sendTryAgainKey), findsOneWidget);
      expect(find.byKey(sendCancelPaymentKey), findsOneWidget);
      expect(find.text('Send 1 EPIC'), findsNothing);

      h.session.sendError = null;
      await _tap(tester, find.byKey(sendTryAgainKey));
      expect(h.session.httpSends, hasLength(2));
      expect(h.session.httpSends.last.txId, isNotNull);
      expect(find.text('Delivered · Waiting for a block'), findsOneWidget);
    });

    testWidgets('not reached: Cancel payment frees it, back to the amount', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _https);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'their wallet did not answer',
      );
      await _tap(tester, find.text('Send 1 EPIC'));
      await _tap(tester, find.byKey(sendCancelPaymentKey));
      expect(h.session.cancelledTxIds, hasLength(1));
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('plain HTTP to another device asks first', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.toReview(tester, _lan);
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(find.text('Not encrypted. Send anyway?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(h.session.httpSends, isEmpty);
      expect(find.text('Review'), findsOneWidget);

      await _tap(tester, find.text('Send 1 EPIC'));
      await _tap(tester, find.text('Send anyway'));
      expect(h.session.httpSends.single.allowPlainHttp, isTrue);
    });
  });

  group('review', () {
    for (final (address, method, rule) in [
      (_bob, 'Epicbox', 'Can be cancelled while it waits for the recipient.'),
      (_onion, 'Tor', 'Cannot be cancelled once their wallet accepts it.'),
    ]) {
      testWidgets('the method row and the cancel rule: $method', (
        tester,
      ) async {
        final h = _Harness();
        await h.pump(tester);
        await h.toReview(tester, address);
        expect(find.text('Method'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ListView).last,
            matching: find.text(method),
          ),
          findsOneWidget,
        );
        expect(find.text(rule), findsOneWidget);
      });
    }
  });

  group('details', () {
    test('an HTTP or Tor send their wallet accepted waits for a block', () {
      final l = englishStrings;
      for (final to in [_https, 'http://$_onion']) {
        final tx = fakeTx(
          id: 3,
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          amountDebited: _epic(1),
          counterparty: to,
        );
        expect(
          txExplanation(l, tx, BigInt.from(2500000)),
          'Delivered · Waiting for a block',
        );
      }
      // An epicbox send says it was published, as before.
      final epicbox = fakeTx(
        id: 4,
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        amountDebited: _epic(1),
        counterparty: _bob,
      );
      expect(
        txExplanation(l, epicbox, BigInt.from(2500000)),
        isNot('Delivered · Waiting for a block'),
      );
    });
  });

  group('receive', () {
    testWidgets('a strip per tab; the captions and Tor honest line', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, body: const ReceiveView(), height: 3600);
      expect(find.text('Share it to get paid.'), findsOneWidget);
      expect(
        find.text(
          'Works while the app is closed: the Epicbox server holds payments '
          'until the wallet is back.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'When reading it out, check the first six and last six characters.',
        ),
        findsOneWidget,
      );
      expect(find.text('HTTP'), findsNothing);

      await _tap(tester, find.text('Tor'));
      expect(find.text('Slower and more private.'), findsOneWidget);
      expect(
        find.text(
          'Works only while the app is open or briefly in the background.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tor receiving works while the app is open or briefly in the '
          'background.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Some wallets show the address without .onion; both are the same '
          'address.',
        ),
        findsOneWidget,
      );

      await _tap(tester, find.text('File'));
      expect(find.text('Hand a file back and forth.'), findsOneWidget);
      expect(
        find.text('Works with no connection between the wallets.'),
        findsOneWidget,
      );
    });

    testWidgets('receiving help says there is no HTTP on the phone', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, body: const HelpScreen(topic: HelpTopic.receiving));
      expect(
        find.textContaining(
          'Receiving over HTTP is not on the phone. Senders use the Epicbox or '
          'Tor address.',
        ),
        findsOneWidget,
      );
    });
  });
}
