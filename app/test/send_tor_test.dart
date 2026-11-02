// SPDX-License-Identifier: Apache-2.0
// Send to a Tor address: an onion in any form is a Link recipient: the recipient
// card says "Over Tor". With the Tor switch off it needs Tor: Turn on Tor, and the review
// waits until Tor is on. Then it reaches their wallet ("Reaching their wallet over Tor…", no
// time promised) and lands on the tracker like any send. A failure to reach them leaves the
// payment stored and waiting: Try again delivers it again, Cancel payment frees the coins.
// Tor that stops at the review: nothing sends, Retry is offered.

import 'dart:async';

import 'package:epic_wallet/src/payment_prefs.dart';
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
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/send_tracker.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart' show TimelineState;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

const String _name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const String _onion = '$_name.onion';

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

class _Harness {
  _Harness({this.bundle = _bundle})
    : session = FakeWalletSession(summary: _summary());

  final TorBundle? bundle;
  final FakeWalletSession session;
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;
  int done = 0;

  PhoneTorState get tor => container.read(phoneTorProvider);

  Future<void> pump(WidgetTester tester) async {
    allowPinCheck(session);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          // Link · Tor on in Settings › Transactions: these sends are about Tor itself.
          secretStoreProvider.overrideWithValue(
            sendPinStore()
              ..values['app.payment_prefs'] = const PaymentPrefs(
                linkHttp: true,
                linkTor: true,
              ).encode(),
          ),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          torBundleFinderProvider.overrideWithValue(() async => bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          // pumpAndSettle moves the fake clock by minutes while a spinner turns: the
          // controller's stall and restart timers must not fire on their own here.
          phoneTorTimingProvider.overrideWithValue(
            PhoneTorTiming(
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
    await opened(tester);
    // Unmounting disposes the controller: its timers end with the test.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  /// Waits for the controller to have read the bundle and the onion (real async), so the
  /// test acts on a controller that can start tor.
  Future<void> opened(WidgetTester tester) async {
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) return;
      await _settle(tester);
    }
    fail(
      'the Tor controller never opened: ${container.read(phoneTorProvider)}',
    );
  }

  /// Tor's next event, with what `torStatus` answers afterwards.
  Future<void> emit(
    WidgetTester tester,
    TorEventKind kind, {
    int? progress,
    TorFailure? failure,
  }) async {
    session.torStatusValue = switch (kind) {
      TorEventKind.starting => TorStatus(
        kind: TorStatusKind.starting,
        progress: progress,
      ),
      TorEventKind.bootstrapped => const TorStatus(
        kind: TorStatusKind.bootstrapped,
      ),
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      _ => TorStatus.off,
    };
    session.torEvents.add(
      TorEvent(
        kind: kind,
        progress: progress,
        failure: failure,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await _settle(tester);
  }

  /// Through recipient and amount to the review.
  Future<void> toReview(WidgetTester tester, {String address = _onion}) async {
    await _enter(tester, 'To', address);
    await _tap(tester, _continue);
    await _enter(tester, 'Amount (EPIC)', '1');
    await _tap(tester, _continue);
    expect(find.text('Review'), findsOneWidget);
  }

  /// The payment as the wallet lists it once their wallet answered over Tor and it was
  /// posted: `sendTor` finalizes it, so it is confirming, not waiting.
  void answered() {
    final i = session.transactionsValue.indexWhere(
      (t) => t.kind == TxKind.sent && t.status == TxStatus.awaitingRecipient,
    );
    final tx = session.transactionsValue[i];
    session.transactionsValue[i] = fakeTx(
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
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

/// Pumps a second of frames and lets a slice of real time pass, twice: the controller's work
/// and the fake's stream cancel complete on root-zone microtasks the test clock does not
/// flush, and a spinner on Send while tor connects would never let `pumpAndSettle` settle.
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
  if (find.widgetWithText(TextField, 'PIN').evaluate().isNotEmpty) {
    await answerPin(tester, settle: false);
    await _settle(tester);
  }
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

List<String> _steps(WidgetTester tester, TimelineState state) => [
  for (final steps in tester.widgetList<RoundSteps>(find.byType(RoundSteps)))
    for (final step in steps.steps)
      if (step.state == state) step.label,
];


/// Scrolls Send's list until [finder] is built and in sight: the balance header above the
/// page leaves the rows under the review past a short phone's first page, and the list is
/// lazy, so a row out of sight is not in the tree at all.
Future<void> _reveal(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(
  finder,
  200,
  scrollable: find
      .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
      .first,
);

void main() {
  // Tor's own behaviour: nothing of it is in the build without Tor.
  if (!torBuilt) {
    test('Tor', () {}, skip: 'no Tor in this build');
    return;
  }
  group('recipient', () {
    testWidgets('an onion in any form becomes one Tor recipient', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      for (final form in [
        _name,
        'http://$_onion/',
        _onion.toUpperCase(),
        '$_onion:3415',
      ]) {
        await _enter(tester, 'To', form);
        // The method line under the field names the way and, with Tor off, that it starts.
        expect(find.text('Link · Tor'), findsOneWidget, reason: form);
        expect(find.text('Tor starts when you send.'), findsOneWidget, reason: form);
        expect(
          find.textContaining('.onion', findRichText: true),
          findsWidgets,
          reason: form,
        );
      }
      // A paste normalises the text in the field too.
      await _tap(tester, _continue);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.textContaining('wfe7q3…abcdid.onion'), findsOneWidget);
    });

    testWidgets('a cut onion is refused with its own sentence', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _name.substring(2));
      await _tap(tester, _continue);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Over Tor'), findsNothing);
    });

    testWidgets('where the app has no Tor, an onion cannot be paid', (
      tester,
    ) async {
      final h = _Harness(bundle: null);
      await h.pump(tester);
      await _enter(tester, 'To', _onion);
      await _tap(tester, _continue);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(
        find.text(
          'This app cannot send over Tor, so a Tor address cannot be paid here.',
        ),
        findsOneWidget,
      );
    });
  });

  group('send', () {
    testWidgets('tor off: Turn on Tor, then it reaches them and tracks', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _enter(tester, 'To', _onion);
      expect(find.text('Tor starts when you send.'), findsOneWidget);
      expect(find.byKey(sendTurnOnTorKey), findsNothing);
      await h.toReview(tester);
      // Tor starts as the review opens; the send waits for it.
      expect(h.session.torStarts, hasLength(1));
      await h.emit(tester, TorEventKind.starting, progress: 60);
      await h.emit(tester, TorEventKind.ready);
      expect(find.text('Over Tor'), findsOneWidget);
      expect(find.text('Ready to send over Tor'), findsOneWidget);
      // No epicbox check on a Tor payment.
      expect(find.text('Not connected yet. You can still send.'), findsNothing);
      expect(find.textContaining('minute'), findsNothing);

      h.session.torSendGate = Completer<void>();
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      expect(h.session.torSends, hasLength(1));
      expect(h.session.torSends.single.onion, _onion);
      expect(
        find.textContaining('Reaching their wallet over Tor…'),
        findsOneWidget,
      );
      expect(find.textContaining('minute'), findsNothing);
      // Back waits while it runs.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_back),
            )
            .onPressed,
        isNull,
      );

      h.answered();
      h.session.torSendGate!.complete();
      await _settle(tester);
      // Their wallet signed and the payment is out: it is confirming already.
      expect(_steps(tester, TimelineState.done), [
        'Payment started',
        'Recipient signed',
        'Posted to the network',
      ]);
      expect(_steps(tester, TimelineState.current).single, contains('onfirm'));
      expect(find.text('1.0\u00a0EPIC'), findsOneWidget);
      expect(find.textContaining('wfe7q3…abcdid.onion'), findsOneWidget);
      // Tor stays up for the session; nothing was stopped.
      expect(h.session.torStops, 0);
      await _tap(tester, find.text('Done'));
      expect(h.done, 1);
    });

    testWidgets('tor already on: ready line, then straight to reaching them', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.container.read(phoneTorProvider.notifier).setReceiving(true);
      await h.emit(tester, TorEventKind.ready);
      await h.toReview(tester);
      expect(find.text('Ready to send over Tor'), findsOneWidget);
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      expect(h.session.torStarts, hasLength(1));
      expect(h.session.torSends, hasLength(1));
    });

    testWidgets('their wallet not reached: Try again delivers it again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.container.read(phoneTorProvider.notifier).setReceiving(true);
      await h.emit(tester, TorEventKind.ready);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.onionUnreachable,
        message: 'not reached',
      );
      await h.toReview(tester);
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      await _reveal(tester, find.textContaining('Their wallet was not reached over Tor.'));
      expect(
        find.textContaining('Their wallet was not reached over Tor.'),
        findsOneWidget,
      );
      expect(find.textContaining('stays locked until you cancel it'), findsOne);
      expect(find.byKey(sendTryAgainKey), findsOneWidget);
      expect(find.byKey(sendCancelPaymentKey), findsOneWidget);
      expect(find.text('Send 1.0\u00a0EPIC'), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
      // The coins are on hold, as after a refused epicbox send.
      expect(h.session.transactionsValue, hasLength(1));

      // Their wallet is back: the same payment goes again, no second one.
      h.session.sendError = null;
      await _tap(tester, find.byKey(sendTryAgainKey));
      expect(h.session.torSends, hasLength(2));
      expect(h.session.torSends.last.txId, isNotNull);
      expect(h.session.transactionsValue, hasLength(1));
      expect(find.byType(RoundSteps), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('their wallet not reached: Cancel payment frees the coins', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.container.read(phoneTorProvider.notifier).setReceiving(true);
      await h.emit(tester, TorEventKind.ready);
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'closed',
      );
      await h.toReview(tester);
      await _tap(tester, find.text('Send 1.0\u00a0EPIC'));
      expect(find.byKey(sendTryAgainKey), findsOneWidget);
      await _tap(tester, find.byKey(sendCancelPaymentKey));
      expect(h.session.cancelledTxIds, [101]);
      // Back on the amount with the recipient kept, ready for another go.
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.textContaining('wfe7q3…abcdid.onion'), findsOneWidget);
    });

    testWidgets('tor stops at the review: nothing sends, Retry', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.container.read(phoneTorProvider.notifier).setReceiving(true);
      await h.emit(tester, TorEventKind.ready);
      await h.toReview(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
      await h.emit(tester, TorEventKind.stopped);
      expect(h.tor.phase, PhoneTorPhase.failed);
      expect(find.text('Tor is not connected.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Send 1.0\u00a0EPIC'),
            )
            .onPressed,
        isNull,
      );
      expect(h.session.torSends, isEmpty);
      expect(h.session.transactionsValue, isEmpty);
      final starts = h.session.torStarts.length;
      await _tap(tester, find.text('Retry'));
      expect(h.session.torStarts.length, greaterThan(starts));
    });
  });
}
