// Receive's Tor tab: an equal receiving method beside Epicbox (F8). The onion address in the
// same card as the epicbox address, a QR code of it, one "Tor receiving" switch with its
// status (off, connecting with progress, on, failed with Retry), and the one honest line
// about Tor. Where the app has no Tor the tab does not exist.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _address =
    'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@epicbox.epiccash.com';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Harness {
  _Harness({this.bundle = _bundle}) {
    session.address = _address;
  }

  final TorBundle? bundle;
  final session = FakeWalletSession();
  final service = FakeWalletService();
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;
  final copied = <String>[];

  PhoneTorState get tor => container.read(phoneTorProvider);

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
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
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          torBundleFinderProvider.overrideWithValue(() async => bundle),
          networkChangesProvider.overrideWithValue(network.stream),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: AdvancedOptions(enabled: false, child: child!),
          ),
          home: const SlotScaffold(body: ReceiveView()),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.pumpAndSettle();
    // The controller reads the bundle and the onion on real async: wait for it.
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
    // Unmounting disposes the controller: its timers end with the test.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  Future<void> torTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(receiveTabsKey),
        matching: find.text('Tor'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> emit(
    WidgetTester tester,
    TorEventKind kind, {
    int? progress,
    TorFailure? failure,
  }) async {
    // What torStatus answers afterwards: the controller asks it on a resume.
    session.torStatusValue = switch (kind) {
      TorEventKind.starting => TorStatus(
        kind: TorStatusKind.starting,
        progress: progress,
      ),
      TorEventKind.bootstrapped => const TorStatus(
        kind: TorStatusKind.bootstrapped,
      ),
      TorEventKind.publishing => const TorStatus(
        kind: TorStatusKind.publishing,
      ),
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      TorEventKind.failed when failure == TorFailure.listener => TorStatus(
        kind: TorStatusKind.bootstrapped,
        failure: failure,
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
    await tester.pumpAndSettle();
  }

  Future<void> switchOn(WidgetTester tester) async {
    await tester.tap(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
  }
}

/// The Tor address code's opacity: dim until the address is reachable.
double _qrOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byKey(receiveTorQrKey)).opacity;

Finder _status(String text) => find.descendant(
  of: find.byKey(torStatusKey),
  matching: find.textContaining(text),
);

void main() {
  group('tabs', () {
    testWidgets('three equal tabs, Epicbox first and by default', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(
        find.byKey(receiveTabsKey),
      );
      expect(tabs.selected, {ReceiveTab.epicbox});
      expect(
        [for (final s in tabs.segments) (s.value, (s.label! as Text).data)],
        [
          (ReceiveTab.epicbox, 'Epicbox'),
          (ReceiveTab.tor, 'Tor'),
          (ReceiveTab.file, 'File'),
        ],
      );
      // Epicbox stays the main one: its card is what shows first.
      expect(find.byKey(receiveAddressKey), findsOneWidget);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
    });

    testWidgets('no Tor tab where the app has no Tor', (tester) async {
      final h = _Harness(bundle: null);
      await h.pump(tester);
      expect(h.tor.phase, PhoneTorPhase.unavailable);
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(
        find.byKey(receiveTabsKey),
      );
      expect(
        [for (final s in tabs.segments) s.value],
        [ReceiveTab.epicbox, ReceiveTab.file],
      );
      expect(find.text('Tor'), findsNothing);
      // A remembered Tor choice falls back to Epicbox.
      h.container.read(receiveTabProvider.notifier).choose(ReceiveTab.tor);
      await tester.pumpAndSettle();
      expect(find.byKey(receiveAddressKey), findsOneWidget);
    });
  });

  group('Tor tab', () {
    testWidgets(
      'off: the onion address, its QR code, the switch off, the line',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        await h.torTab(tester);
        expect(find.text('Tor address'), findsOneWidget);
        expect(find.text(h.session.onion), findsOneWidget);
        final qr = tester.widget<MarkedQr>(find.byType(MarkedQr));
        expect(qr.data, h.session.onion);
        expect(find.bySemanticsLabel('QR code of your Tor address'), findsOne);
        final sw = tester.widget<SwitchListTile>(
          find.byKey(torReceivingSwitchKey),
        );
        expect(sw.value, isFalse);
        expect(find.text('Tor receiving'), findsOneWidget);
        expect(_status('Tor receiving is off'), findsOneWidget);
        expect(
          find.text(
            'Tor receiving works while the app is open or briefly in the '
            'background.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(torRetryKey), findsNothing);
        // The code shows, dimmed: the address is not reachable until Tor receiving is on.
        expect(_qrOpacity(tester), 0.4);
        // The whole method is "receiving": none of the struck-out words.
        for (final word in ['Listener', 'listener', 'Advanced', 'Direct']) {
          expect(find.textContaining(word), findsNothing);
        }
        // No epicbox-only parts.
        expect(find.byKey(receiveEpicboxKey), findsNothing);
        expect(find.byKey(receiveRequestKey), findsNothing);
      },
    );

    testWidgets('a tap on the card copies the address', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torTab(tester);
      await tester.tap(find.byKey(receiveTorAddressKey));
      await tester.pumpAndSettle();
      expect(h.copied, [h.session.onion]);
      expect(find.text('Address copied'), findsOneWidget);
    });

    testWidgets('the switch starts tor; connecting shows progress; then on', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      expect(h.session.torStarts, hasLength(1));
      expect(h.tor.receiving, isTrue);
      expect(_status('Connecting to Tor… 0%'), findsOneWidget);
      await h.emit(tester, TorEventKind.starting, progress: 45);
      expect(_status('Connecting to Tor… 45%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(torReceivingSwitchKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.value, closeTo(0.45, 0.001));
      await h.emit(tester, TorEventKind.bootstrapped);
      expect(_status('Publishing your Tor address…'), findsOneWidget);
      await h.emit(tester, TorEventKind.ready);
      expect(_status('Tor receiving is on'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_qrOpacity(tester), 1);
      // The switch is the one control: off stops tor.
      await tester.tap(find.byKey(torReceivingSwitchKey));
      await tester.pumpAndSettle();
      // The controller awaits the stream's cancel, which completes on a root-zone microtask
      // the test clock never flushes: a slice of real time lets it through.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(h.session.torStops, 1);
      expect(_status('Tor receiving is off'), findsOneWidget);
    });

    testWidgets('failed: the reason in one line and Retry', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
      await h.emit(tester, TorEventKind.stopped);
      expect(h.tor.phase, PhoneTorPhase.failed);
      expect(_status('Could not reach the Tor network'), findsOneWidget);
      expect(find.textContaining('minutes'), findsNothing);
      final retry = find.byKey(torRetryKey);
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(h.session.torStarts, hasLength(2));
      expect(_status('Connecting to Tor'), findsOneWidget);
    });

    testWidgets('connected but not reachable: the reason and Retry', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.listener);
      expect(h.tor.phase, PhoneTorPhase.connected);
      expect(_status('Your Tor address is not reachable yet.'), findsOneWidget);
      expect(find.byKey(torRetryKey), findsOneWidget);
    });

    testWidgets('fits and reads at text scale 2', (tester) async {
      final h = _Harness();
      await h.pump(tester, textScale: 2);
      await h.torTab(tester);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.starting, progress: 30);
      expect(tester.takeException(), isNull);
      expect(find.byKey(torReceivingSwitchKey), findsOneWidget);
      final handle = tester.ensureSemantics();
      final size = tester.getSize(find.byKey(torReceivingSwitchKey));
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });
}
