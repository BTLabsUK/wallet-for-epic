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

/// The recipient step: [to] in the address field, then Continue to the amount.
Future<void> _recipient(WidgetTester tester, String to) async {
  await _enter(tester, 'Epic address', to);
  await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
}

/// Goes through the recipient and amount steps for [to] and opens the review.
Future<void> _review(WidgetTester tester, String to, {String? note}) async {
  await _recipient(tester, to);
  await _enter(tester, 'Amount (EPIC)', '1.5');
  if (note != null) {
    await _tap(tester, find.text('Add a note'));
    await _enter(tester, 'Note', note);
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

  group('file route', () {
    testWidgets('a quiet row on the first step, with the file help', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // No choice of method up front: one address field.
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      expect(find.widgetWithText(TextField, 'Epic address'), findsOneWidget);
      expect(find.textContaining('epicbox', findRichText: true), findsNothing);

      await _tap(tester, find.text('No address? Use a payment file'));
      expect(find.text('Pay with a file'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Epic address'), findsNothing);
      expect(find.text('Make payment file'), findsOneWidget);
      // A file carries the note as an address payment does.
      await _tap(tester, find.text('Add a note'));
      expect(find.widgetWithText(TextField, 'Note'), findsOneWidget);

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

      await _tap(tester, find.byTooltip('Back'));
      expect(find.widgetWithText(TextField, 'Epic address'), findsOneWidget);
    });

    testWidgets('round trip: make the file, finish with the reply', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('No address? Use a payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
      expect(h.session.sentAmounts, [_epic(1.5)]);
      // No review checks: nothing goes over a relay.
      expect(h.service.tipCalls, 0);
      // The tracker: made, waiting for the reply, then the network.
      expect(find.text('File made'), findsOneWidget);
      expect(find.text('1.5 EPIC on hold'), findsOneWidget);
      expect(find.text('Waiting for their reply'), findsOneWidget);
      expect(find.text('Sent to the network'), findsOneWidget);
      expect(find.text('Open their reply'), findsOneWidget);
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
      expect(find.text('Waiting for their reply'), findsNothing);
      expect(find.text('Their wallet signed'), findsOneWidget);
      expect(find.text('Sent to the network'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(3));
      expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    });

    testWidgets('a file send signs the note in and keeps it', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('No address? Use a payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Add a note'));
      await _enter(tester, 'Note', ' For rent ');
      await _tap(tester, find.text('Make payment file'));
      expect(h.session.sentMessages, ['For rent']);
      expect(h.session.notes, {'s:${h.session.sendSlate.slateId}': 'For rent'});
    });

    testWidgets('a file send without a note signs none in', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('No address? Use a payment file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
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
            await _tap(tester, find.text('No address? Use a payment file'));
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
      expect(find.text("Can't reach the network right now."), findsOneWidget);
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
      expect(find.text("Can't reach the network right now."), findsOneWidget);
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
        expect(find.text("Their relay isn't answering."), findsOneWidget);
        expect(_sendButton, findsNothing);
        expect(_enabled(tester, _fileButton), isTrue);
        // Sending is still possible.
        expect(find.text('Send anyway'), findsOneWidget);

        await _tap(tester, _fileButton);
        expect(find.text('Pay with a file'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Amount (EPIC)'))
              .controller!
              .text,
          '1.5',
        );
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Note'))
              .controller!
              .text,
          'For rent',
        );
        await _tap(tester, find.text('Make payment file'));
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
      'a send the relay refuses offers the file, with the amount kept',
      (tester) async {
        final h = _Harness();
        h.relays.list = [_status(_bobRelay, healthy: true)];
        h.session.sendError = const WalletError(
          kind: WalletErrorKind.transportFailed,
          message: 'failed to lookup address information: unknown host',
        );
        await h.pump(tester);
        await h.connect(tester);
        await _review(tester, _bob);
        await _tap(tester, _sendButton);
        expect(find.text("Their relay isn't answering."), findsOneWidget);
        // Not the raw transport error.
        expect(find.textContaining('lookup'), findsNothing);
        expect(_enabled(tester, _fileButton), isTrue);

        await _tap(tester, _fileButton);
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Amount (EPIC)'))
              .controller!
              .text,
          '1.5',
        );
        await _tap(tester, find.text('Make payment file'));
        expect(h.session.sentAmounts, [_epic(1.5)]);
      },
    );

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
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);
      expect(_fileButton, findsNothing);
    });

    testWidgets('an unlisted relay or no monitor answer is skipped', (
      tester,
    ) async {
      final h = _Harness();
      h.relays.list = [_status(_bobRelay, healthy: false)];
      await h.pump(tester);
      await h.connect(tester);
      await _review(tester, _carol);
      expect(find.text('Ready to send'), findsOneWidget);
      expect(_fileButton, findsNothing);
      await _tap(tester, find.byTooltip('Back'));
      await _tap(tester, find.byTooltip('Back'));

      h.relays.error = StateError('monitor down');
      await _enter(tester, 'Epic address', _bob);
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      expect(find.text('Ready to send'), findsOneWidget);
      expect(_enabled(tester, _sendButton), isTrue);
    });
  });
}
