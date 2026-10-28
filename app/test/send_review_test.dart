import 'dart:async';

import 'package:epic_wallet/src/known_relays.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/file_exchange_help.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final String _bob = '${'b' * 52}@epicbox.epiccash.com';
final String _carol = '${'c' * 52}@relay.example.org';

const EpicboxRelay _bobRelay = EpicboxRelay(host: 'epicbox.epiccash.com');

RelayStatus _status(EpicboxRelay relay, {required bool healthy}) =>
    RelayStatus(relay: relay, healthy: healthy, verified: true);

final _tip = NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

/// The fake, with a node whose answer each test chooses, and its calls counted.
class _NodeService extends FakeWalletService {
  _NodeService({super.session});

  /// The next tip requests wait for this, when set.
  Completer<NodeTip>? pending;
  Object? error;
  int tipCalls = 0;

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) async {
    tipCalls++;
    final p = pending;
    if (p != null) return p.future;
    if (error case final e?) throw e;
    return _tip;
  }
}

class _Relays implements RelayDirectory {
  List<RelayStatus> list = const [];
  Object? error;

  @override
  Future<List<RelayStatus>> relays(String chain) async {
    if (error case final e?) throw e;
    return list;
  }
}

/// A relay handshake that answers when the test says.
class _PendingProbe implements RelayProbe {
  final answer = Completer<bool>();

  @override
  Future<bool> reachable(EpicboxRelay relay) => answer.future;
}

class _Price implements PriceSource {
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
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: mainnetPreset.nodeUrl,
  );
}

/// A relay that refuses the send without the wallet storing it, so there is nothing to find.
class _LostSession extends FakeWalletSession {
  _LostSession({required WalletSummary super.summary, this.leaves});

  /// Something the failed send changed that is not its payment, so nothing can be told.
  final TxEntry? leaves;

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) async {
    epicboxSends.add((amount: amount, to: address));
    if (leaves case final tx?) transactionsValue.add(tx);
    throw const WalletError(
      kind: WalletErrorKind.transportFailed,
      message: 'relay sent nothing in time',
    );
  }
}

/// A cancel that fails. With [finalizes], the reply came first: the payment is finished and
/// on its way to the network.
class _RaceSession extends FakeWalletSession {
  _RaceSession({required WalletSummary super.summary, required this.finalizes});

  final bool finalizes;

  @override
  Future<void> cancelTransaction({required int txId}) async {
    if (finalizes) {
      final i = transactionsValue.indexWhere((t) => t.id == txId);
      final tx = transactionsValue[i];
      transactionsValue[i] = fakeTx(
        id: tx.id,
        slateId: tx.slateId,
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        amountDebited: tx.amountDebited,
        fee: tx.fee,
        counterparty: tx.counterparty,
      );
    }
    throw const WalletError(
      kind: WalletErrorKind.invalidArgument,
      message: 'only a payment waiting for the recipient can be cancelled',
    );
  }
}

final WalletSummary _forty = WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: _epic(50),
  spendable: _epic(40),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

/// Sends that wait for [gate].
class _SlowSession extends FakeWalletSession {
  _SlowSession({required WalletSummary super.summary});

  final gate = Completer<void>();

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) async {
    await gate.future;
    return super.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: message,
      options: options,
    );
  }
}

class _Harness {
  _Harness({FakeWalletSession? session})
    : session = session ?? FakeWalletSession(summary: _forty) {
    allowPinCheck(this.session);
    service = _NodeService(session: this.session)
      ..slateInfos[this.session.responseSlate.json] = SlateInfo(
        slateId: this.session.sendSlate.slateId,
        amount: _epic(1.5),
        fee: this.session.fee,
        stage: SlateStage.response,
      );
  }

  final FakeWalletSession session;

  late final _NodeService service;
  final relays = _Relays();
  RelayProbe probe = FakeRelayProbe();
  final files = FakeSlateFiles();

  /// The app's settings and the PIN; Outputs' strategy and Split change live here.
  final store = sendPinStore();

  Future<void> pump(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
    Brightness? brightness,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          slateFilesProvider.overrideWithValue(files),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_Price()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(relays),
          relayProbeProvider.overrideWithValue(probe),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
          ),
          home: SlotScaffold(
            appBar: AppBar(),
            body: SendView(onDone: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> connect(WidgetTester tester) async {
    session.listenerEvents.add(
      const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
    );
    await tester.pumpAndSettle();
  }
}

/// Screens are lazy lists: scrolls until [finder] is built.
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
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reach(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await answerPin(tester);
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reach(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// The recipient step: [to] in the address field, then Continue to the amount.
Future<void> _recipient(WidgetTester tester, String to) async {
  await _enter(tester, 'To', to);
  await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
}

/// Goes through the recipient and amount steps for [to] and opens the review.
Future<void> _review(WidgetTester tester, String to, {String? note}) async {
  await _recipient(tester, to);
  await _enter(tester, 'Amount (EPIC)', '1.5');
  if (note != null) {
    await _tap(tester, find.text('Add a message'));
    await _enter(tester, 'Message', note);
  }
  await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
}

Finder get _sendButton => find.widgetWithText(FilledButton, 'Send 1.5 EPIC');

Finder get _fileButton =>
    find.widgetWithText(FilledButton, 'Pay with a file instead');

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

void main() {
  group('sendPreflight', () {
    const connected = ListenerState(connected: true);
    const connecting = ListenerState();
    final healthy = AsyncData([_status(_bobRelay, healthy: true)]);

    test(
      'a node answer allows the send; no answer yet or a failure does not',
      () {
        for (final (node, outcome, canSend) in [
          (AsyncData(_tip), CheckOutcome.passed, true),
          (const AsyncLoading<NodeTip>(), CheckOutcome.running, false),
          (
            AsyncError<NodeTip>(TimeoutException('8 s'), StackTrace.empty),
            CheckOutcome.failed,
            false,
          ),
        ]) {
          final checks = sendPreflight(
            node: node,
            listener: connected,
            relays: healthy,
            relay: _bobRelay,
          );
          expect(checks.node, outcome);
          expect(checks.canSend, canSend);
          expect(checks.warns, isFalse);
        }
      },
    );

    test('a listener that is not connected warns without blocking', () {
      for (final listener in [
        connecting,
        const ListenerState(lost: true),
        const ListenerState(stopped: true),
      ]) {
        final checks = sendPreflight(
          node: AsyncData(_tip),
          listener: listener,
          relays: healthy,
          relay: _bobRelay,
        );
        expect(checks.listener, CheckOutcome.failed);
        expect(checks.warns, isTrue);
        expect(checks.canSend, isTrue);
      }
    });

    test('the recipient relay: healthy passes, unhealthy warns', () {
      final up = sendPreflight(
        node: AsyncData(_tip),
        listener: connected,
        relays: healthy,
        relay: _bobRelay,
      );
      expect(up.relay, _bobRelay);
      expect(up.relayOutcome, CheckOutcome.passed);
      final down = sendPreflight(
        node: AsyncData(_tip),
        listener: connected,
        relays: AsyncData([_status(_bobRelay, healthy: false)]),
        relay: _bobRelay,
      );
      expect(down.relayOutcome, CheckOutcome.failed);
      expect(down.warns, isTrue);
      expect(down.canSend, isTrue);
      final loading = sendPreflight(
        node: AsyncData(_tip),
        listener: connected,
        relays: const AsyncLoading(),
        relay: _bobRelay,
      );
      expect(loading.relayOutcome, CheckOutcome.running);
      expect(loading.canSend, isTrue);
    });

    test('a relay the monitor does not list, or no monitor, is skipped without a probe', () {
      for (final (relays, relay) in [
        (
          AsyncData([
            _status(
              const EpicboxRelay(host: 'epicbox.epicnet.us'),
              healthy: false,
            ),
          ]),
          _bobRelay,
        ),
        (
          AsyncError<List<RelayStatus>>(StateError('down'), StackTrace.empty),
          _bobRelay,
        ),
        (healthy, null),
        // The same host on another port is another relay.
        (healthy, const EpicboxRelay(host: 'epicbox.epiccash.com', port: 444)),
      ]) {
        final checks = sendPreflight(
          node: AsyncData(_tip),
          listener: connected,
          relays: relays,
          relay: relay,
        );
        expect(checks.relay, isNull);
        expect(checks.relayOutcome, isNull);
        expect(checks.warns, isFalse);
      }
    });

    test(
      'a relay the monitor does not list, or no monitor: the probe decides',
      () {
        for (final relays in [
          healthy,
          AsyncError<List<RelayStatus>>(StateError('down'), StackTrace.empty),
        ]) {
          const other = EpicboxRelay(host: 'relay.example.org');
          for (final (probe, outcome) in [
            (const AsyncLoading<bool>(), CheckOutcome.running),
            (const AsyncData(true), CheckOutcome.passed),
            (const AsyncData(false), CheckOutcome.failed),
            (
              AsyncError<bool>(StateError('x'), StackTrace.empty),
              CheckOutcome.failed,
            ),
          ]) {
            final checks = sendPreflight(
              node: AsyncData(_tip),
              listener: connected,
              relays: relays,
              relay: relays is AsyncError ? _bobRelay : other,
              probe: probe,
            );
            expect(checks.relayOutcome, outcome);
            expect(checks.canSend, isTrue);
          }
        }
        // The monitor's word stands where it lists the relay.
        final listed = sendPreflight(
          node: AsyncData(_tip),
          listener: connected,
          relays: AsyncData([_status(_bobRelay, healthy: false)]),
          relay: _bobRelay,
          probe: const AsyncData(true),
        );
        expect(listed.relayOutcome, CheckOutcome.failed);
      },
    );

    test(
      'the probe speaks ws to a loopback relay, as LEPIC does, else wss',
      () {
        for (final host in ['localhost', '127.0.0.1', '127.8.9.10', '::1']) {
          expect(
            relayProbeUri(EpicboxRelay(host: host, port: 3420)).scheme,
            'ws',
            reason: host,
          );
        }
        for (final host in ['epicbox.epiccash.com', '128.0.0.1', '10.0.0.1']) {
          expect(
            relayProbeUri(EpicboxRelay(host: host)).scheme,
            'wss',
            reason: host,
          );
        }
        expect(
          relayProbeUri(
            const EpicboxRelay(host: 'relay.example.org', port: 8443),
          ).toString(),
          'wss://relay.example.org:8443',
        );
      },
    );

    test('recipientRelay reads the relay after the @', () {
      expect(recipientRelay(_bob), _bobRelay);
      expect(
        recipientRelay('${'d' * 52}@flooepicbox.btlabs.uk:443'),
        const EpicboxRelay(host: 'flooepicbox.btlabs.uk'),
      );
      expect(
        recipientRelay('${'d' * 52}@relay.example.org:8443'),
        const EpicboxRelay(host: 'relay.example.org', port: 8443),
      );
      expect(recipientRelay('d' * 52), isNull);
    });
  });

  group('file route', () {
    testWidgets('File in the selector, with the file help', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      // The method selector up front, Epicbox chosen, and one address field.
      expect(find.byKey(sendMethodsKey), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('esXXXX…XXXX@epicbox.epiccash.com'), findsOneWidget);

      await _tap(tester, find.text('Direct · File'));
      expect(find.text('Direct · File Transfer'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      expect(find.text('Make transaction file'), findsOneWidget);
      // A file carries the note as an address payment does.
      await _tap(tester, find.text('Add a message'));
      expect(find.widgetWithText(TextField, 'Message'), findsOneWidget);

      // The help loops its animation, so it never settles while open. Reaching the note scrolled
      // the step's header under the app bar: scroll back to the top first.
      await tester.drag(find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first, const Offset(0, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('How paying by file works'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final help = tester.widget<FileExchangeHelp>(
        find.byType(FileExchangeHelp),
      );
      expect(help.role, FileExchangeRole.sender);
      Navigator.of(tester.element(find.byType(FileExchangeHelp))).pop();
      await tester.pumpAndSettle();

      await _tap(tester, find.byTooltip('Back'));
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
    });

    testWidgets('round trip: make the file, finish with the reply', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make transaction file'));
      expect(h.session.sentAmounts, [_epic(1.5)]);
      // No review checks: nothing goes over a relay.
      expect(h.service.tipCalls, 0);
      // The tracker: made, waiting for the reply, then the network.
      expect(find.text('File made'), findsOneWidget);
      expect(find.text('1.5 EPIC locked'), findsOneWidget);
      expect(find.text('Waiting for the response file'), findsOneWidget);
      expect(find.text('Posted to the network'), findsOneWidget);
      expect(find.text('Open response file'), findsOneWidget);
      expect(find.textContaining('slate'), findsNothing);

      await _tap(tester, find.text('Copy and paste instead'));
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        h.session.responseSlate.json,
      );
      await _tap(tester, find.text('Finish payment'));
      expect(h.session.finalizedSlates, [h.session.responseSlate.json]);
      expect(find.text('Waiting for the response file'), findsNothing);
      expect(find.text('Their wallet signed'), findsOneWidget);
      expect(find.text('Posted to the network'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(3));
      expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    });

    testWidgets('a file send signs the note in and keeps it', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Add a message'));
      await _enter(tester, 'Message', ' For rent ');
      await _tap(tester, find.text('Make transaction file'));
      expect(h.session.sentMessages, ['For rent']);
      expect(h.session.notes, {'s:${h.session.sendSlate.slateId}': 'For rent'});
    });

    testWidgets('a file send without a note signs none in', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Direct · File'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make transaction file'));
      expect(h.session.sentMessages, [null]);
      expect(h.session.notes, isEmpty);
    });

    for (final step in ['recipient', 'amount', 'file', 'review']) {
      testWidgets('$step step: 48 dp targets and text scale 2', (tester) async {
        final handle = tester.ensureSemantics();
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: false)];
        await h.pump(tester, textScale: 2);
        switch (step) {
          case 'amount':
            await _recipient(tester, _bob);
          case 'file':
            await _tap(tester, find.text('Direct · File'));
          case 'review':
            await _review(tester, _bob);
        }
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('review checks', () {
    testWidgets('all pass: one "Ready to send" line, and the send goes', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(find.text('Ready to send'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(_fileButton, findsNothing);
      expect(_enabled(tester, _sendButton), isTrue);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends.single.to, _bob);
    });

    testWidgets('the review shows the fee and the total, nothing else', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob, note: 'For rent');
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.text('New recipient'), findsOneWidget);
      expect(find.text('1.5 EPIC'), findsOneWidget);
      expect(find.text('Network fee'), findsOneWidget);
      expect(find.text('0.008 EPIC'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('1.508 EPIC'), findsOneWidget);
      // What stays: 40 spendable minus the total. The fake locks nothing beyond the total,
      // so no "until change confirms" line.
      expect(find.text('Balance after'), findsOneWidget);
      expect(find.text('38.492 EPIC'), findsOneWidget);
      expect(find.text('Spendable until change confirms'), findsNothing);
      // Two rows only: no note, no relay, no method.
      expect(find.text('For rent'), findsNothing);
      expect(find.textContaining('Goes through'), findsNothing);
      expect(find.text('Message'), findsNothing);
    });

    testWidgets('the checks run beside the fee, and each review asks again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(h.service.tipCalls, 1);
      await _tap(tester, find.text('Edit'));
      expect(find.widgetWithText(TextField, 'Amount (EPIC)'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      expect(h.service.tipCalls, 2);
    });

    testWidgets('a node that does not answer blocks Send until it does', (
      tester,
    ) async {
      final h = _Harness();
      h.service.error = const WalletError(
        kind: WalletErrorKind.nodeUnreachable,
        message: 'refused',
      );
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(find.text('Cannot reach the network right now.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
      await tester.tap(_sendButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.session.epicboxSends, isEmpty);

      h.service.error = null;
      await _tap(tester, find.text('Retry'));
      expect(find.text('Ready to send'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isTrue);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets('a node silent for 8 s fails; Send waits meanwhile', (
      tester,
    ) async {
      final h = _Harness();
      h.service.pending = Completer<NodeTip>();
      await h.pump(tester);
      await h.connect(tester);
      await _recipient(tester, _bob);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Checking…'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Checking…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Cannot reach the network right now.'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
    });

    testWidgets('reduced motion shows a still icon while a check runs', (
      tester,
    ) async {
      final h = _Harness();
      h.service.pending = Completer<NodeTip>();
      await h.pump(tester, reducedMotion: true);
      await _recipient(tester, _bob);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Checking…'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      h.service.pending!.complete(_tip);
      await tester.pumpAndSettle();
      expect(find.text('Not connected yet. You can still send.'), findsOne);
    });

    testWidgets('our listener not connected: a quiet line, and it sends', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _review(tester, _bob);
      expect(find.text('Not connected yet. You can still send.'), findsOne);
      expect(_fileButton, findsNothing);
      expect(_enabled(tester, _sendButton), isTrue);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets(
      'their relay down at the monitor offers the file, keeping amount and note',
      (tester) async {
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: false)];
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _bob, note: 'For rent');
        expect(find.text("Their Epicbox server (epicbox.epiccash.com) is not answering."), findsOneWidget);
        expect(_sendButton, findsNothing);
        expect(_enabled(tester, _fileButton), isTrue);
        // Sending is still possible.
        expect(find.text('Send anyway'), findsOneWidget);

        await _tap(tester, _fileButton);
        expect(find.text('Direct · File Transfer'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, 'Amount (EPIC)'),
              )
              .controller!
              .text,
          '1.5',
        );
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Message'))
              .controller!
              .text,
          'For rent',
        );
        await _tap(tester, find.text('Make transaction file'));
        expect(h.session.sentAmounts, [_epic(1.5)]);
        expect(h.session.sentMessages, ['For rent']);
        expect(h.session.epicboxSends, isEmpty);
      },
    );

    testWidgets('Send anyway goes over the relay all the same', (tester) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: false)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, find.text('Send anyway'));
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets(
      'a send the relay refuses: cancel the stored payment, then pay by file',
      (tester) async {
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: true)];
        h.session.sendError = const WalletError(
          kind: WalletErrorKind.transportFailed,
          message: 'relay sent nothing in time',
        );
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _bob, note: 'For rent');
        await _tap(tester, _sendButton);
        // LEPIC stored it with its coins on hold; the review says so, in plain words.
        expect(h.session.transactionsValue, hasLength(1));
        expect(find.textContaining('relay sent nothing'), findsNothing);
        expect(
          find.text(
            'Their Epicbox server (epicbox.epiccash.com) refused it. The amount stays locked until you cancel '
            'it, or for up to 1 day.',
          ),
          findsOneWidget,
        );
        // No second payment: neither Send anyway nor a plain file offer.
        expect(find.text('Send anyway'), findsNothing);
        expect(_fileButton, findsNothing);
        expect(_sendButton, findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        await _tap(tester, find.text('Cancel and pay with a file'));
        expect(h.session.cancelledTxIds, [
          h.session.transactionsValue.single.id,
        ]);
        expect(find.text('Direct · File Transfer'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, 'Amount (EPIC)'),
              )
              .controller!
              .text,
          '1.5',
        );
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Message'))
              .controller!
              .text,
          'For rent',
        );
        await _tap(tester, find.text('Make transaction file'));
        expect(h.session.sentAmounts, [_epic(1.5)]);
        expect(h.session.epicboxSends, hasLength(1));
      },
    );

    testWidgets(
      'after Max, the cancel frees the coins and the file takes all again',
      (tester) async {
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: true)];
        h.session.sendError = const WalletError(
          kind: WalletErrorKind.transportFailed,
          message: 'relay sent nothing in time',
        );
        await h.pump(tester);
        await h.connect(tester);
        await _recipient(tester, _bob);
        await _tap(tester, find.text('Max'));
        await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Send 39.992 EPIC'),
        );
        await _tap(tester, find.text('Cancel and pay with a file'));
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, 'Amount (EPIC)'),
              )
              .controller!
              .text,
          '39.992',
        );
        await _tap(tester, find.text('Make transaction file'));
        expect(find.byType(ErrorText), findsNothing);
        expect(h.session.sentAmounts, [_epic(39.992)]);
      },
    );

    testWidgets('a refused send that stored nothing offers the file', (
      tester,
    ) async {
      final h = _Harness(session: _LostSession(summary: _forty));
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, _sendButton);
      // Balance and payments as before: nothing is held, so a file cannot pay twice.
      expect(find.text("Their Epicbox server (epicbox.epiccash.com) is not answering."), findsOneWidget);
      expect(find.text('Cancel and pay with a file'), findsNothing);
      expect(find.text('Send anyway'), findsNothing);
      expect(_sendButton, findsNothing);
      await _tap(tester, _fileButton);
      await _tap(tester, find.text('Make transaction file'));
      expect(h.session.epicboxSends, hasLength(1));
      expect(h.session.sentAmounts, [_epic(1.5)]);
    });

    testWidgets(
      'a refused send that changed something else says so, sends no more',
      (tester) async {
        final h = _Harness(
          session: _LostSession(
            summary: _forty,
            leaves: fakeTx(
              id: 9,
              slateId: 'other',
              kind: TxKind.sent,
              status: TxStatus.awaitingRecipient,
              amountDebited: _epic(3),
              counterparty: _carol,
            ),
          ),
        );
        h.relays.list = [_status(_bobRelay, healthy: true)];
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _bob);
        await _tap(tester, _sendButton);
        expect(
          find.text(
            "Their Epicbox server (epicbox.epiccash.com) refused it. Check Wallet before you send again.",
          ),
          findsOneWidget,
        );
        expect(_fileButton, findsNothing);
        expect(find.text('Cancel and pay with a file'), findsNothing);
        expect(_sendButton, findsNothing);
        await _tap(tester, find.widgetWithText(FilledButton, 'Done'));
        expect(h.session.epicboxSends, hasLength(1));
        expect(h.session.sentAmounts, isEmpty);
      },
    );

    testWidgets('a cancel that loses to their reply shows the tracker', (
      tester,
    ) async {
      final race = _RaceSession(summary: _forty, finalizes: true);
      race.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay sent nothing in time',
      );
      final h = _Harness(session: race);
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, _sendButton);
      await _tap(tester, find.text('Cancel and pay with a file'));
      // Their wallet answered first: the payment is going ahead.
      expect(find.text('Direct · File Transfer'), findsNothing);
      expect(find.text('Posted to the network'), findsOneWidget);
      expect(find.textContaining('Confirming 0/'), findsOneWidget);
      expect(h.session.sentAmounts, isEmpty);
    });

    testWidgets('a cancel that fails otherwise shows the error, then Done', (
      tester,
    ) async {
      final race = _RaceSession(summary: _forty, finalizes: false);
      race.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay sent nothing in time',
      );
      final h = _Harness(session: race);
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, _sendButton);
      await _tap(tester, find.text('Cancel and pay with a file'));
      // The error ends the list, below the fold when the bottom area is tall.
      await _reach(tester, find.byType(ErrorText));
      expect(find.byType(ErrorText), findsOneWidget);
      expect(find.text('Cancel and pay with a file'), findsNothing);
      expect(find.text('Leave it for now'), findsNothing);
      expect(find.text('Direct · File Transfer'), findsNothing);
      await _tap(tester, find.widgetWithText(FilledButton, 'Done'));
      expect(h.session.sentAmounts, isEmpty);
    });

    testWidgets('a recipient handed over while a refused send is held waits', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: true)];
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay sent nothing in time',
      );
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, _sendButton);
      ProviderScope.containerOf(tester.element(find.byType(SendView)))
          .read(sendRecipientProvider.notifier)
          .hand(_carol);
      await tester.pumpAndSettle();
      // Still the held payment, with no way to a second send.
      expect(find.text('Cancel and pay with a file'), findsOneWidget);
      expect(find.text('1 of 3'), findsNothing);
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets('Review shows that it is sending, and Back waits', (
      tester,
    ) async {
      final slow = _SlowSession(summary: _forty);
      final h = _Harness(session: slow);
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await tester.tap(_sendButton);
      await tester.pumpAndSettle();
      await answerPin(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Sending…'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.arrow_back),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      // One spinner only: the button's. The Sending… line keeps a still glyph.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      slow.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Waiting for their wallet'), findsOneWidget);
    });

    testWidgets('other send errors stay in words, without the file offer', (
      tester,
    ) async {
      final h = _Harness();
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      await _tap(tester, _sendButton);
      expect(find.textContaining('Not enough spendable EPIC'), findsOneWidget);
      expect(_fileButton, findsNothing);
    });

    testWidgets('a relay the monitor lists is not probed', (tester) async {
      final h = _Harness();
      final probe = FakeRelayProbe(answer: false);
      h.probe = probe;
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(find.text('Ready to send'), findsOneWidget);
      expect(probe.probed, isEmpty);
    });

    testWidgets('an unlisted relay is probed: it answers', (tester) async {
      final h = _Harness();
      final probe = FakeRelayProbe();
      h.probe = probe;
      h.relays.list = [_status(_bobRelay, healthy: false)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _carol);
      expect(probe.probed, [const EpicboxRelay(host: 'relay.example.org')]);
      expect(find.text('Ready to send'), findsOneWidget);
      expect(_fileButton, findsNothing);
      expect(_enabled(tester, _sendButton), isTrue);
      // linux-14: a relay the app does not know is named in a warning, and does not block.
      expect(
        find.descendant(
          of: find.byKey(sendUnknownRelayKey),
          matching: find.text(
            "relay.example.org is not a server this app knows. Check the address before you send.",
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a relay the app lists, or the user keeps, raises no warning', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(find.byKey(sendUnknownRelayKey), findsNothing);
      expect(
        isKnownRelay(
          const EpicboxRelay(host: 'Relay.Example.org'),
          extra: const [EpicboxRelay(host: 'relay.example.org')],
        ),
        isTrue,
      );
      expect(isKnownRelay(const EpicboxRelay(host: 'epicbox.stackwalle')), isFalse);
      expect(isKnownRelay(const EpicboxRelay(host: 'epicbox.stackwallet.com')), isTrue);
      expect(isKnownRelay(const EpicboxRelay(host: 'flooepicbox.btlabs.uk')), isTrue);
      expect(isKnownRelay(const EpicboxRelay(host: 'epicbox.epiccash.com', port: 444)), isFalse);
    });

    testWidgets(
      'an unlisted relay that does not answer offers the file first',
      (tester) async {
        final h = _Harness();
        h.probe = FakeRelayProbe(answer: false);
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _carol);
        expect(find.text("Their Epicbox server (relay.example.org) is not answering."), findsOneWidget);
        expect(_enabled(tester, _fileButton), isTrue);
        expect(_sendButton, findsNothing);
        await _tap(tester, _fileButton);
        expect(find.text('Direct · File Transfer'), findsOneWidget);
        expect(h.session.epicboxSends, isEmpty);
      },
    );

    testWidgets('while the probe runs: a quiet Checking line, Send waits', (
      tester,
    ) async {
      final h = _Harness();
      final probe = _PendingProbe();
      h.probe = probe;
      await h.pump(tester);
      await h.connect(tester);
      await _recipient(tester, _carol);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Checking…'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
      probe.answer.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Ready to send'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isTrue);
    });

    testWidgets('no monitor answer: the relay itself is probed', (
      tester,
    ) async {
      final h = _Harness();
      final probe = FakeRelayProbe(answer: false);
      h.probe = probe;
      h.relays.error = StateError('monitor down');
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(probe.probed, [_bobRelay]);
      expect(find.text("Their Epicbox server (epicbox.epiccash.com) is not answering."), findsOneWidget);
    });
  });

  // The Outputs settings reach the phone's send; strategy All always has one change output.
  group('Outputs settings', () {
    WalletOutput out(String c, num value) => WalletOutput(
      commitment: c * 66,
      value: _epic(value),
      status: WalletOutputStatus.unspent,
      category: OutputCategory.spendable,
      isCoinbase: false,
      height: BigInt.from(2499000),
      lockHeight: BigInt.zero,
      confirmations: BigInt.from(10),
    );

    /// Sends 1.5 EPIC to Bob from a wallet of two outputs (30 and 10 EPIC) with the strategy
    /// and Split change set on Outputs; returns the harness after the send.
    Future<_Harness> send(
      WidgetTester tester, {
      required String strategy,
      required bool splitChange,
      void Function(_Harness h)? atReview,
    }) async {
      final h = _Harness();
      h.session.outputsValue = [out('a', 30), out('b', 10)];
      h.store.values['app.send_strategy'] = strategy;
      h.store.values['app.split_change'] = '$splitChange';
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      atReview?.call(h);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends.single.to, _bob);
      return h;
    }

    testWidgets('All with Split change on: one change output, and the review says so', (
      tester,
    ) async {
      final l = lookupAppLocalizations(const Locale('en'));
      final h = await send(
        tester,
        strategy: 'all',
        splitChange: true,
        atReview: (_) {
          expect(find.byKey(sendUsesAllOutputsKey), findsOneWidget);
          expect(find.text(l.sendUsesAllOutputs(2)), findsOneWidget);
          expect(find.text('Uses all 2 outputs · change 1 output'), findsOneWidget);
        },
      );
      const one = SendOptions(strategy: SelectionStrategy.all);
      expect(h.session.estimateOptions.toSet(), {one});
      expect(h.session.sentOptions.single, one);
    });

    testWidgets('Smallest with Split change on splits the change when few outputs stay', (
      tester,
    ) async {
      final h = await send(
        tester,
        strategy: 'smallest',
        splitChange: true,
        atReview: (_) => expect(find.byKey(sendUsesAllOutputsKey), findsNothing),
      );
      // The 10 EPIC output pays; one output stays, so 8.49 EPIC of change comes back in 3.
      expect(
        h.session.sentOptions.single,
        const SendOptions(strategy: SelectionStrategy.smallest, changeOutputs: 3),
      );
    });

    testWidgets('Split change off keeps one change output', (tester) async {
      final h = await send(tester, strategy: 'smallest', splitChange: false);
      expect(h.session.sentOptions.single, const SendOptions());
    });
  });
}
