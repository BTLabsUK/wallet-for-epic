// SPDX-License-Identifier: Apache-2.0
// Receive's Link tab: receiving straight to this wallet at its onion address, over Tor
//. With the Tor switch off it says Link · Tor receiving needs Tor, with Turn on Tor; with Tor
// on, the onion address in the same card as the epicbox address, a QR code of it dimmed until
// reachable, and Tor's state in the same words as everywhere (Starting, Connected, Not connected
// with the reason and Retry). The switch itself lives in Settings › Privacy. Where the app
// has no Tor the tab does not exist.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/settings.dart' show networkModeProvider;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
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
  _Harness({
    this.bundle = _bundle,
    this.advanced = AdvancedPrefs.none,
    this.payments = PaymentPrefs.defaults,
  }) {
    session.address = _address;
  }

  final TorBundle? bundle;

  /// What the Advanced page holds.
  final AdvancedPrefs advanced;

  /// Settings › Transactions; Link on shows the Link tab.
  final PaymentPrefs payments;
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
          secretStoreProvider.overrideWithValue(
            store..values['app.payment_prefs'] = payments.encode(),
          ),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          torBundleFinderProvider.overrideWithValue(() async => bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          networkModeProvider.overrideWithValue(advanced.networkMode),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: AdvancedOptions(prefs: advanced, child: child!),
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
        // Under 360 dp the tabs are icons alone: the name is the tooltip.
        matching: find.byTooltip('Link'),
      ),
    );
    // Bounded frames: the Link · HTTP card's Starting spinner never settles while the fake
    // session leaves the listener unanswered.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
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

  /// Turn on Tor, on the Link tab with Tor off.
  Future<void> switchOn(WidgetTester tester) async {
    await tester.tap(find.byKey(receiveTurnOnTorKey));
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

/// Settings › Transactions › Link · Tor on, as the Link tab's onion needs it.
const _directOn = PaymentPrefs(linkTor: true);

void main() {
  // Tor's own behaviour: nothing of it is in the build without Tor.
  if (!torBuilt) {
    test('Tor', () {}, skip: 'no Tor in this build');
    return;
  }
  group('tabs', () {
    testWidgets('Epicbox, Link and File from the start; Link on fills the Link tab', (
      tester,
    ) async {
      final plain = _Harness();
      await plain.pump(tester);
      // The Link tab stays whatever Settings says; off, it offers Turn on.
      expect(
        [
          for (final s in tester
              .widget<SegmentedButton<ReceiveTab>>(find.byKey(receiveTabsKey))
              .segments)
            s.value,
        ],
        [ReceiveTab.epicbox, ReceiveTab.direct, ReceiveTab.file],
      );
      await plain.torTab(tester);
      expect(find.byKey(receiveTurnOnLinkTorKey), findsOneWidget);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(
        find.byKey(receiveTabsKey),
      );
      expect(tabs.selected, {ReceiveTab.epicbox});
      expect(
        [
          for (final s in tabs.segments)
            // The whole name: a long one wraps in two lines on the tab (PH-1).
            (s.value, s.tooltip),
        ],
        [
          (ReceiveTab.epicbox, 'Epicbox'),
          (ReceiveTab.direct, 'Link'),
          (ReceiveTab.file, 'Direct · File'),
        ],
      );
      // Epicbox stays the main one: its card is what shows first.
      expect(find.byKey(receiveAddressKey), findsOneWidget);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
    });

    testWidgets('Epicbox off: Link · Tor needing Tor does not point to the Epicbox address', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await h.pump(tester);
      expect(find.byKey(receiveTurnOnTorKey), findsOneWidget);
      expect(find.text('Meanwhile, share the Epicbox address.'), findsNothing);
    });

    testWidgets('the Link tab stays where the app has no Tor: Link · HTTP is still a way', (tester) async {
      final h = _Harness(bundle: null);
      await h.pump(tester);
      expect(h.tor.phase, PhoneTorPhase.unavailable);
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(
        find.byKey(receiveTabsKey),
      );
      expect(
        [for (final s in tabs.segments) s.value],
        [ReceiveTab.epicbox, ReceiveTab.direct, ReceiveTab.file],
      );
      // No Tor to turn on.
      h.container.read(receiveTabProvider.notifier).choose(ReceiveTab.direct);
      await tester.pumpAndSettle();
      expect(find.byKey(receiveTurnOnLinkTorKey), findsNothing);
    });
  });

  group('File follows Settings › Transactions', () {
    List<ReceiveTab> tabsOf(WidgetTester tester) => [
      for (final s in tester
          .widget<SegmentedButton<ReceiveTab>>(find.byKey(receiveTabsKey))
          .segments)
        s.value,
    ];

    testWidgets('File off: its tab goes; Link on keeps the choice', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(linkTor: true, directFile: false));
      await h.pump(tester);
      expect(tabsOf(tester), [ReceiveTab.epicbox, ReceiveTab.direct]);
    });

    testWidgets('File off and nothing else: Epicbox and the Link tab', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(directFile: false));
      await h.pump(tester);
      expect(tabsOf(tester), [ReceiveTab.epicbox, ReceiveTab.direct]);
      expect(find.byKey(receiveAddressKey), findsOneWidget);
    });

    testWidgets('the File tab in use stays when the switch goes off', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(linkTor: true, directFile: false));
      await h.pump(tester);
      h.container.read(receiveTabProvider.notifier).choose(ReceiveTab.file);
      await tester.pumpAndSettle();
      expect(tabsOf(tester), [ReceiveTab.epicbox, ReceiveTab.direct, ReceiveTab.file]);
      expect(tester.widget<SegmentedButton<ReceiveTab>>(find.byKey(receiveTabsKey)).selected, {ReceiveTab.file});
    });

    testWidgets('a file payment waiting for its reply keeps File', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(linkTor: true, directFile: false));
      h.session.transactionsValue = [
        fakeTx(
          id: 1,
          slateId: 'waiting',
          kind: TxKind.sent,
          status: TxStatus.awaitingRecipient,
          transport: 'file',
          amountDebited: BigInt.from(10000000000),
        ),
      ];
      await h.pump(tester);
      expect(tabsOf(tester), [ReceiveTab.epicbox, ReceiveTab.direct, ReceiveTab.file]);
    });

    testWidgets('a finished or Epicbox payment does not keep it', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(linkTor: true, directFile: false));
      h.session.transactionsValue = [
        fakeTx(
          id: 1,
          slateId: 'done',
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          transport: 'file',
        ),
        fakeTx(
          id: 2,
          slateId: 'box',
          kind: TxKind.sent,
          status: TxStatus.awaitingRecipient,
          transport: 'epicbox',
        ),
      ];
      await h.pump(tester);
      expect(tabsOf(tester), [ReceiveTab.epicbox, ReceiveTab.direct]);
    });
  });

  group('Node only', () {
    const offline = AdvancedPrefs(networkMode: NetworkMode.nodeOnly);

    testWidgets('Epicbox: the address to hand out, and the line that it cannot receive', (
      tester,
    ) async {
      final h = _Harness(advanced: offline, payments: _directOn);
      await h.pump(tester);
      expect(find.byKey(receiveAddressKey), findsOneWidget);
      // The address stays; Epicbox reads Off (Node only) and says payments wait on the server.
      expect(find.byKey(receiveEpicboxOffModeKey), findsOneWidget);
      expect(find.text('Epicbox is off in Node only.'), findsOneWidget);
      expect(find.text('Off (Node only)'), findsOneWidget);
      expect(find.text('Payments to this address wait on the Epicbox server and arrive when you leave Node only.'), findsOneWidget);
    });

    testWidgets('Link with Tor off: no onion to hand out, the needs-Tor and offline lines, no Turn on Tor', (tester) async {
      final h = _Harness(advanced: offline, payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      expect(find.byType(MarkedQr), findsNothing);
      expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
      expect(find.text('Link receiving is off in Node only.'), findsOneWidget);
      expect(find.text('Meanwhile, share the Epicbox address.'), findsNothing);
      expect(find.byKey(receiveTurnOnTorKey), findsNothing);
      expect(h.session.torStarts, isEmpty);
    });

    testWidgets('File: Open file and Paste run, with the note that the node is used', (tester) async {
      final h = _Harness(advanced: offline, payments: _directOn);
      await h.pump(tester);
      h.container.read(receiveTabProvider.notifier).choose(ReceiveTab.file);
      await tester.pumpAndSettle();
      for (final label in ['Open file', 'Paste']) {
        expect(
          tester
              .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, label))
              .onPressed,
          isNotNull,
          reason: label,
        );
      }
      expect(find.text('Off in Node only.'), findsNothing);
      expect(find.text('Uses the node'), findsWidgets);
    });

    testWidgets('Epicbox off: no Epicbox tab, the first method that is on shows', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await h.pump(tester);
      expect(find.byKey(receiveAddressKey), findsNothing);
      expect(find.byKey(receiveTurnOnTorKey), findsOneWidget, reason: 'the Link tab is first');
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(find.byKey(receiveTabsKey));
      expect(tabs.segments.map((s) => s.value), isNot(contains(ReceiveTab.epicbox)));
    });

    testWidgets('every method off: the Link tab alone, offering to turn its methods on', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, directFile: false, directQr: false));
      await h.pump(tester);
      // One tab is no choice: the strip is gone, the Link page shows the switches.
      expect(find.byKey(receiveTabsKey), findsNothing);
      expect(find.byKey(receiveAddressKey), findsNothing);
    });

    testWidgets('Standard: no offline line', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('Link receiving is off in Node only.'), findsNothing);
      expect(find.byKey(receiveEpicboxOffModeKey), findsNothing);
    });
  });

  group('Link tab', () {
    testWidgets('Tor off: Link receiving needs Tor; no switch on Receive', (
      tester,
    ) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      expect(find.text('Link · Tor needs Tor.'), findsOneWidget);
      expect(
        find.text('Meanwhile, share the Epicbox address.'),
        findsOneWidget,
      );
      expect(find.byKey(receiveTurnOnTorKey), findsOneWidget);
      expect(find.byKey(torSettingsLinkKey), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      expect(find.byType(MarkedQr), findsNothing);
      // None of the words that were struck out.
      for (final word in ['Listener', 'listener', 'Advanced', 'Epic address']) {
        expect(find.textContaining(word), findsNothing);
      }
      // No epicbox-only parts.
      expect(find.byKey(receiveEpicboxKey), findsNothing);
      expect(find.byKey(receiveRequestKey), findsNothing);
    });

    testWidgets('Turn on Tor: starting, then on; the address and its code', (
      tester,
    ) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      expect(h.session.torStarts, hasLength(1));
      expect(h.tor.receiving, isTrue);
      expect(_status('Tor\u00A0· Starting'), findsOneWidget);
      expect(find.text('Link · Tor address'), findsOneWidget);
      expect(find.text(h.session.onion), findsOneWidget);
      final qr = tester.widget<MarkedQr>(find.byType(MarkedQr));
      expect(qr.data, h.session.onion);
      expect(find.bySemanticsLabel('QR code of your Tor address'), findsOne);
      expect(find.byWidgetPredicate((w) => w is InfoHint && w.text == 'Works while the app is open.'), findsOneWidget);
      expect(
        find.text(
          'Some wallets show the address without .onion; both are the same '
          'address.',
        ),
        findsOneWidget,
      );
      // The code shows, dimmed: the address is not reachable yet.
      expect(_qrOpacity(tester), 0.4);
      await h.emit(tester, TorEventKind.starting, progress: 45);
      expect(_status('Tor\u00A0· Starting'), findsOneWidget);
      await h.emit(tester, TorEventKind.bootstrapped);
      expect(_status('Tor\u00A0· Connected'), findsOneWidget);
      expect(_qrOpacity(tester), 0.4);
      await h.emit(tester, TorEventKind.ready);
      expect(_status('Tor\u00A0· Connected'), findsOneWidget);
      expect(_qrOpacity(tester), 1);
      expect(find.byKey(torRetryKey), findsNothing);
    });

    testWidgets('a tap on the card copies the address', (tester) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      await tester.tap(find.byKey(receiveTorAddressKey));
      await tester.pumpAndSettle();
      expect(h.copied, [h.session.onion]);
      expect(find.text('Address copied'), findsOneWidget);
    });

    testWidgets('not connected: the reason in one line and Retry', (
      tester,
    ) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
      await h.emit(tester, TorEventKind.stopped);
      expect(h.tor.phase, PhoneTorPhase.failed);
      expect(_status('Tor\u00A0· Not connected'), findsOneWidget);
      expect(_status('Tor could not connect. Retry, or turn Tor off.'), findsOneWidget);
      expect(find.textContaining('minutes'), findsNothing);
      final retry = find.byKey(torRetryKey);
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(h.session.torStarts, hasLength(2));
      expect(_status('Tor\u00A0· Starting'), findsOneWidget);
    });

    testWidgets('connected but not reachable: the reason and Retry', (
      tester,
    ) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.failed, failure: TorFailure.listener);
      expect(h.tor.phase, PhoneTorPhase.connected);
      expect(_status('Your Tor address is not reachable yet.'), findsOneWidget);
      expect(find.byKey(torRetryKey), findsOneWidget);
    });

    testWidgets('fits and reads at text scale 2', (tester) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester, textScale: 2);
      await h.torTab(tester);
      expect(tester.takeException(), isNull);
      await h.switchOn(tester);
      await h.emit(tester, TorEventKind.starting, progress: 30);
      expect(tester.takeException(), isNull);
      expect(find.byKey(torStatusKey), findsOneWidget);
    });
  });
}
