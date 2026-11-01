// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/demo_screens.dart' show testCoinsKey;
import 'package:epic_wallet/src/ui/handshake.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/send_tracker.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart' show TimelineState;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final String _bob = '${'b' * 52}@epicbox.epiccash.com';

WalletSummary _summary({BigInt? spendable, BigInt? onHold}) => WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: (spendable ?? BigInt.zero) + (onHold ?? BigInt.zero),
  spendable: spendable ?? BigInt.zero,
  awaitingConfirmation: onHold ?? BigInt.zero,
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

class _Harness {
  _Harness({WalletSummary? summary})
    : session = FakeWalletSession(
        summary: summary ?? _summary(spendable: _epic(40)),
      );

  final FakeWalletSession session;
  late ProviderContainer container;
  int done = 0;

  Future<void> pump(
    WidgetTester tester, {
    bool demo = false,
    bool reducedMotion = false,
    double textScale = 1,
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    allowPinCheck(session);
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
          demoModeProvider.overrideWithValue(demo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
          ),
          home: SlotScaffold(
            appBar: AppBar(),
            body: SendView(onDone: () => done++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(SendView)),
    );
  }

  /// The wallet now lists the payment as [status], as after a refresh.
  Future<void> payment(
    WidgetTester tester,
    TxStatus status, {
    BigInt? height,
  }) async {
    session.transactionsValue = [
      fakeTx(
        slateId: 'send-1',
        kind: TxKind.sent,
        status: status,
        amountDebited: _epic(1) + session.fee,
        fee: session.fee,
        counterparty: _bob,
        blockHeight: height,
      ),
    ];
    await container.read(homeProvider.notifier).reload();
    await tester.pumpAndSettle();
  }
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await answerPin(tester);
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  // Screens are lazy lists: scroll until the field is built.
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester) async {
  await _enter(tester, 'To', _bob);
  await _tap(tester, _continue);
  await _enter(tester, 'Amount (EPIC)', '1');
  await _tap(tester, _continue);
  await _tap(tester, find.text('Send 1.00000000\u00a0EPIC'));
}

/// The labels of the tracker's steps in [state].
List<String> _steps(WidgetTester tester, TimelineState state) => [
  for (final steps in tester.widgetList<RoundSteps>(find.byType(RoundSteps)))
    for (final step in steps.steps)
      if (step.state == state) step.label,
];

void main() {
  group('sendTrackerAt', () {
    final tip = BigInt.from(2500000);
    TxEntry tx(TxStatus status, {BigInt? height, bool repostable = false}) =>
        fakeTx(
          slateId: 'x',
          kind: TxKind.sent,
          status: status,
          blockHeight: height,
          repostable: repostable,
        );

    test('follows the payment from their wallet to confirmed', () {
      expect(
        sendTrackerAt(tx(TxStatus.awaitingRecipient), tip, target: 3),
        SendTrack.waitingRecipient,
      );
      expect(
        sendTrackerAt(tx(TxStatus.awaitingConfirmation), tip, target: 3),
        SendTrack.confirming,
      );
      expect(
        sendTrackerAt(
          tx(TxStatus.confirmed, height: tip - BigInt.one),
          tip,
          target: 3,
        ),
        SendTrack.confirming,
      );
      expect(
        sendTrackerAt(
          tx(TxStatus.confirmed, height: tip - BigInt.two),
          tip,
          target: 3,
        ),
        SendTrack.completed,
      );
      expect(
        sendTrackerAt(tx(TxStatus.cancelled), tip, target: 3),
        SendTrack.cancelled,
      );
      expect(
        sendTrackerAt(
          tx(TxStatus.awaitingConfirmation, repostable: true),
          tip,
          target: 3,
        ),
        SendTrack.notPosted,
      );
    });

    test('the current step of each place', () {
      expect(sendTrackerStep(SendTrack.waitingRecipient), 1);
      expect(sendTrackerStep(SendTrack.confirming), 3);
      expect(sendTrackerStep(SendTrack.completed), 4);
    });
  });

  group('steps', () {
    testWidgets('recipient, amount, review, send, tracker, and back again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);

      await _enter(tester, 'To', _bob);
      await _tap(tester, _continue);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      await _tap(tester, find.byTooltip('Back'));
      expect(find.text('1 of 3'), findsOneWidget);
      // The address stays.
      expect(find.text('New recipient'), findsOneWidget);

      await _tap(tester, _continue);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, _continue);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
      await _tap(tester, find.byTooltip('Back'));
      expect(find.text('2 of 3'), findsOneWidget);
      await _tap(tester, _continue);
      await _tap(tester, find.text('Send 1.00000000\u00a0EPIC'));

      // The tracker: no step count, no way back to a form that could send twice.
      expect(find.text('3 of 3'), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
      expect(_steps(tester, TimelineState.done), ['Payment started']);
      expect(_steps(tester, TimelineState.current), [
        'Recipient signed',
      ]);
      expect(_steps(tester, TimelineState.todo), [
        'Posted to the network',
        'Confirming',
        'Completed',
      ]);
      await _tap(tester, find.text('Done'));
      expect(h.done, 1);
    });

    testWidgets('How it works opens the handshake from every step', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final info = find.byTooltip('How it works');
      expect(info, findsOneWidget);
      // It loops, so it never settles while open.
      await tester.tap(info);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HandshakeSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(HandshakeSheet))).pop();
      await tester.pumpAndSettle();

      await _enter(tester, 'To', _bob);
      await _tap(tester, _continue);
      expect(info, findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, _continue);
      expect(info, findsOneWidget);
      await _tap(tester, find.text('Send 1.00000000\u00a0EPIC'));
      expect(info, findsOneWidget);
    });
  });

  group('tracker', () {
    testWidgets('advances as the payment does, to confirmed', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _send(tester);
      await h.payment(tester, TxStatus.awaitingRecipient);
      expect(_steps(tester, TimelineState.current), [
        'Recipient signed',
      ]);

      // Their wallet signed; ours finished it and handed it to the network.
      await h.payment(tester, TxStatus.awaitingConfirmation);
      expect(_steps(tester, TimelineState.done), [
        'Payment started',
        'Recipient signed',
        'Posted to the network',
      ]);
      expect(
        _steps(tester, TimelineState.current).single,
        startsWith('Confirming 0/'),
      );
      expect(find.textContaining('finishes it when it opens'), findsNothing);
      expect(find.text('What if it never finishes?'), findsNothing);

      await h.payment(tester, TxStatus.confirmed, height: BigInt.one);
      expect(_steps(tester, TimelineState.done), [
        'Payment started',
        'Recipient signed',
        'Posted to the network',
        'Confirmed',
        'Completed',
      ]);
      expect(_steps(tester, TimelineState.current), isEmpty);
    });

    testWidgets('their wallet offline: it stays at step 2, quietly', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _send(tester);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(minutes: 1));
        await h.payment(tester, TxStatus.awaitingRecipient);
        expect(_steps(tester, TimelineState.current), [
          'Recipient signed',
        ]);
      }
      expect(
        find.text(
          'Their wallet signs it when it opens. '
          '1.0080\u00a0EPIC stays locked until then.',
        ),
        findsOneWidget,
      );
      // The one-day rule waits behind the expandable.
      expect(find.textContaining('after 1 day'), findsNothing);
    });

    testWidgets('a cancelled payment says so in one line', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _send(tester);
      await h.payment(tester, TxStatus.cancelled);
      expect(find.text('This payment was cancelled.'), findsOneWidget);
      expect(find.byType(RoundSteps), findsNothing);
    });

    testWidgets('the current step is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await h.pump(tester);
      await _send(tester);
      final live = find.ancestor(
        of: find.text('Recipient signed'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
      );
      expect(live, findsOneWidget);
      handle.dispose();
    });

    testWidgets('each step tells screen readers done, now or later', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await h.pump(tester);
      await _send(tester);
      expect(find.bySemanticsLabel('Payment started, done'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Recipient signed, now')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Posted to the network, later'), findsOne);
      expect(find.bySemanticsLabel('Confirming, later'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fits a 360 dp phone at text scale 2', (tester) async {
      final h = _Harness();
      await h.pump(tester, textScale: 2, size: const Size(1080, 2400));
      await _send(tester);
      expect(tester.takeException(), isNull);
      await h.payment(tester, TxStatus.awaitingConfirmation);
      expect(tester.takeException(), isNull);
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the current mark pulses, and is still under reduced motion', (
      tester,
    ) async {
      sendPulseMoves = true;
      addTearDown(() => sendPulseMoves = false);
      final h = _Harness();
      await h.pump(tester, reducedMotion: true);
      await _send(tester);
      // Settles: nothing loops.
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(const SizedBox());
      final moving = _Harness();
      await moving.pump(tester);
      await _enter(tester, 'To', _bob);
      await _tap(tester, _continue);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, _continue);
      await tester.tap(find.text('Send 1.00000000\u00a0EPIC'));
      await tester.pumpAndSettle();
      await answerPin(tester, settle: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('fields', () {
    EditableTextState editable(WidgetTester tester, Key key) =>
        tester.state<EditableTextState>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(EditableText),
          ),
        );

    testWidgets('each step builds its own text field, never another\'s', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final recipient = editable(tester, sendRecipientFieldKey);
      await _tap(tester, find.text('Direct · File'));
      expect(find.byKey(sendRecipientFieldKey), findsNothing);
      final fileAmount = editable(tester, sendFileAmountFieldKey);
      expect(identical(fileAmount, recipient), isFalse);
      expect(
        fileAmount.widget.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      // Typing lands.
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(fileAmount.widget.controller.text, '1');

      await _tap(tester, find.byTooltip('Back'));
      final again = editable(tester, sendRecipientFieldKey);
      expect(identical(again, fileAmount), isFalse);
      await _enter(tester, 'To', _bob);
      await _tap(tester, _continue);
      final amount = editable(tester, sendAmountFieldKey);
      expect(identical(amount, again), isFalse);
      await _tap(tester, find.text('Add a message'));
      expect(find.byKey(sendNoteFieldKey), findsOneWidget);
      expect(
        {
          sendRecipientFieldKey,
          sendAmountFieldKey,
          sendFileAmountFieldKey,
          sendNoteFieldKey,
          sendFileNoteFieldKey,
          sendReplyFieldKey,
        }.length,
        6,
      );
    });
  });

  group('no coins', () {
    testWidgets('an empty wallet gets one line, not a form', (tester) async {
      final h = _Harness(summary: FakeWalletSession.emptySummary);
      await h.pump(tester);
      expect(find.text('No coins to send yet.'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      expect(find.byKey(testCoinsKey), findsNothing);
    });

    testWidgets('in the demo, with the test coins button', (tester) async {
      final h = _Harness(summary: FakeWalletSession.emptySummary);
      await h.pump(tester, demo: true);
      expect(find.text('No coins to send yet.'), findsOneWidget);
      expect(find.byKey(testCoinsKey), findsOneWidget);
    });

    testWidgets('coins only on hold: the form, and a line about them', (
      tester,
    ) async {
      final h = _Harness(summary: _summary(onHold: _epic(10)));
      await h.pump(tester);
      expect(find.text('No coins to send yet.'), findsNothing);
      await _enter(tester, 'To', _bob);
      await _tap(tester, _continue);
      expect(find.text('+10.0000\u00a0EPIC coming in'), findsOneWidget);
    });
  });
}
