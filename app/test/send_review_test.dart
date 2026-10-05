import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
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
  Future<NodeTip> nodeTip({required WalletConfig config}) async {
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

class _Harness {
  _Harness() {
    service = _NodeService(session: session);
  }

  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(2499990),
      minimumConfirmations: BigInt.from(10),
      total: _epic(50),
      spendable: _epic(40),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
  );
  late final _NodeService service;
  final relays = _Relays();
  final files = FakeSlateFiles();

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
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          slateFilesProvider.overrideWithValue(files),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: true)),
          priceSourceProvider.overrideWithValue(_Price()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(relays),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: AdvancedOptions(
              enabled: false,
              child: child!,
            ),
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
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reach(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Fills the form for [to] and opens the review sheet.
Future<void> _review(WidgetTester tester, String to) async {
  await _enter(tester, 'To', to);
  await _enter(tester, 'Amount (EPIC)', '1.5');
  await _tap(tester, find.text('Review'));
}

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

Finder get _sendButton => find.widgetWithText(FilledButton, 'Send 1.5 EPIC');

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

    test('a relay the monitor does not list, or no monitor, is skipped', () {
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

  group('method choice', () {
    testWidgets('epicbox address and payment file, with Advanced off', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
      expect(find.text('Epicbox address'), findsOneWidget);
      expect(find.text('Payment file'), findsOneWidget);
      expect(find.text('Other ways to send'), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      await _tap(tester, find.text('Payment file'));
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      // A file carries the message as an epicbox send does.
      expect(
        find.widgetWithText(TextField, 'Message to recipient (optional)'),
        findsOneWidget,
      );
      expect(find.textContaining('Make a payment file'), findsOneWidget);
      expect(find.text('Create payment file'), findsOneWidget);

      // The help loops its animation, so it never settles while open.
      await tester.tap(find.byTooltip('How paying by file works'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final help = tester.widget<FileExchangeHelp>(
        find.byType(FileExchangeHelp),
      );
      expect(help.role, FileExchangeRole.sender);
      Navigator.of(tester.element(find.byType(FileExchangeHelp))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(FileExchangeHelp), findsNothing);

      await _tap(tester, find.text('Epicbox address'));
      expect(find.widgetWithText(TextField, 'To'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('a file send skips the review checks and goes to finalize', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create payment file'));
      expect(h.session.sentAmounts, [_epic(1.5)]);
      expect(h.service.tipCalls, 0);
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
      expect(find.text('Sent 1.5 EPIC'), findsOneWidget);
    });

    testWidgets('a file send signs the message in and keeps it as the note', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _enter(tester, 'Message to recipient (optional)', ' For rent ');
      await _tap(tester, find.text('Create payment file'));
      expect(h.session.sentMessages, ['For rent']);
      expect(h.session.notes, {'s:${h.session.sendSlate.slateId}': 'For rent'});
    });

    testWidgets('a file send without a message signs none in', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create payment file'));
      expect(h.session.sentMessages, [null]);
      expect(h.session.notes, isEmpty);
    });

    for (final file in [false, true]) {
      testWidgets(
        '${file ? 'file' : 'epicbox'} form: 48 dp targets and text scale 2',
        (tester) async {
          final handle = tester.ensureSemantics();
          final h = _Harness();
          await h.pump(tester, textScale: 2);
          if (file) await _tap(tester, find.text('Payment file'));
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 3000),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        },
      );
    }
  });

  group('review checks', () {
    testWidgets('all pass: one quiet row each, and the send goes', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: true)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _bob);
      expect(find.text('Fee'), findsOneWidget);
      expect(find.text('The node answers'), findsOneWidget);
      expect(find.text('Connected to epicbox'), findsOneWidget);
      expect(find.text('epicbox.epiccash.com is up'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(3));
      expect(find.text('Retry'), findsNothing);
      expect(_enabled(tester, _sendButton), isTrue);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends.single.to, _bob);
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
      await _tap(tester, find.text('Review'));
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
      expect(
        find.text(
          'The node does not answer, so this payment cannot be sent now.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
      await tester.tap(_sendButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.session.epicboxSends, isEmpty);

      h.service.error = null;
      await _tap(tester, find.text('Retry'));
      expect(find.text('The node answers'), findsOneWidget);
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
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Checking the node…'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Checking the node…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('The node does not answer'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isFalse);
    });

    testWidgets('reduced motion shows a still icon while a check runs', (
      tester,
    ) async {
      final h = _Harness();
      h.service.pending = Completer<NodeTip>();
      await h.pump(tester, reducedMotion: true);
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Checking the node…'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      h.service.pending!.complete(_tip);
      await tester.pumpAndSettle();
      expect(find.text('The node answers'), findsOneWidget);
    });

    testWidgets('epicbox not connected warns and still sends', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _review(tester, _bob);
      expect(
        find.textContaining('Not connected to epicbox yet'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(_enabled(tester, _sendButton), isTrue);
      await _tap(tester, _sendButton);
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets(
      'a recipient relay the monitor sees down warns and still sends',
      (tester) async {
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: false)];
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _bob);
        expect(
          find.textContaining('epicbox.epiccash.com is not answering'),
          findsOneWidget,
        );
        expect(_enabled(tester, _sendButton), isTrue);
        await _tap(tester, _sendButton);
        expect(h.session.epicboxSends, hasLength(1));
      },
    );

    testWidgets('an unlisted relay or no monitor answer is skipped', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: false)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _carol);
      expect(_inSheet(find.textContaining('is up')), findsNothing);
      expect(_inSheet(find.textContaining('not answering')), findsNothing);
      expect(find.byIcon(Icons.warning_amber), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(2));
      await _tap(tester, find.text('Edit'));

      h.relays.error = StateError('monitor down');
      await tester.enterText(find.widgetWithText(TextField, 'To'), _bob);
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Review'));
      expect(_inSheet(find.textContaining('is up')), findsNothing);
      expect(_inSheet(find.textContaining('not answering')), findsNothing);
      expect(find.byIcon(Icons.warning_amber), findsNothing);
      expect(_enabled(tester, _sendButton), isTrue);
    });

    testWidgets('the sheet with warnings at text scale 2', (tester) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: false)];
      await h.pump(tester, textScale: 2);
      await _review(tester, _bob);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.warning_amber), findsNWidgets(2));
    });
  });
}
