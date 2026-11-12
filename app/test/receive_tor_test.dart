// SPDX-License-Identifier: Apache-2.0
// Receive's Tor address page: receiving straight to this wallet at its onion address, over Tor
//. With the Tor switch off it says Link · Tor receiving needs Tor, with Turn on Tor; with Tor
// on, the onion address in the same card as the epicbox address, a QR code of it dimmed until
// reachable, and Tor's state in the same words as everywhere (Starting, Connected, Not connected
// with the reason and Retry). The switch itself lives in Settings › Privacy. Where the app
// has no Tor the row does not exist.

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
import 'package:epic_wallet/src/ui/theme/logo_qr.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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

  /// Opens "Other ways to receive" and the Tor address page.
  Future<void> torTab(WidgetTester tester) async {
    await tester.ensureVisible(find.text(_l.phoneRecvOther));
    await tester.tap(find.text(_l.phoneRecvOther));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.phoneSettingsTorAddress));
    // Bounded frames: the page's progress bar never settles while Tor starts.
    for (var i = 0; i < 16; i++) {
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

  /// Opens "Other ways to receive" and With a file.
  Future<void> fileTab(WidgetTester tester) async {
    await tester.ensureVisible(find.text(_l.phoneRecvOther));
    await tester.tap(find.text(_l.phoneRecvOther));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.phoneSettingsWithFile));
    await tester.pumpAndSettle();
  }

  /// Turn on Tor, on the Tor address page with Tor off.
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
  group('Other ways', () {
    testWidgets('Tor address is listed where the app has Tor; off, it says Off and offers Turn on', (tester) async {
      final plain = _Harness();
      await plain.pump(tester);
      await tester.tap(find.text(_l.phoneRecvOther));
      await tester.pumpAndSettle();
      expect(find.text(_l.phoneSettingsTorAddress), findsOneWidget);
      expect(find.text(_l.phoneSettingsWithFile), findsOneWidget);
      expect(find.text(_l.phoneRecvOff), findsOneWidget);
      await tester.tap(find.text(_l.phoneSettingsTorAddress));
      await tester.pumpAndSettle();
      expect(find.byKey(receiveTurnOnLinkTorKey), findsOneWidget);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      // Epicbox stays the main one: its card is what shows first.
      expect(find.byKey(receiveAddressKey), findsOneWidget);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      await tester.tap(find.text(_l.phoneRecvOther));
      await tester.pumpAndSettle();
      expect(find.text(_l.phoneSettingsTorAddress), findsOneWidget);
      // Link · Tor is on but Tor itself is not running: the row still says Off.
      expect(find.text(_l.phoneRecvOff), findsOneWidget);
    });

    testWidgets('Epicbox off: Link · Tor needing Tor does not point to the Epicbox address', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await h.pump(tester);
      await h.torTab(tester);
      expect(find.byKey(receiveTurnOnTorKey), findsOneWidget);
      expect(find.text(_l.receiveDirectMeanwhile), findsNothing);
    });

    testWidgets('no Tor address where the app has no Tor: the phone only sends over Link · HTTP', (tester) async {
      final h = _Harness(bundle: null);
      await h.pump(tester);
      expect(h.tor.phase, PhoneTorPhase.unavailable);
      await tester.tap(find.text(_l.phoneRecvOther));
      await tester.pumpAndSettle();
      expect(find.text(_l.phoneSettingsTorAddress), findsNothing);
      expect(find.text(_l.phoneSettingsWithFile), findsOneWidget);
      // No Tor to turn on.
      expect(find.byKey(receiveTurnOnLinkTorKey), findsNothing);
    });

    testWidgets('With a file is always listed, whatever Settings › Transactions says', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(linkTor: true, directFile: false));
      await h.pump(tester);
      await tester.tap(find.text(_l.phoneRecvOther));
      await tester.pumpAndSettle();
      expect(find.text(_l.phoneSettingsWithFile), findsOneWidget);
      expect(find.text(_l.phoneSettingsTorAddress), findsOneWidget);
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
      expect(find.byType(LogoQr), findsNothing);
      expect(find.text(_l.receiveDirectNeedsTor), findsOneWidget);
      expect(find.text('Link receiving is off in Node only.'), findsOneWidget);
      expect(find.text(_l.receiveDirectMeanwhile), findsNothing);
      expect(find.byKey(receiveTurnOnTorKey), findsNothing);
      expect(h.session.torStarts, isEmpty);
    });

    testWidgets('File: Open file and Paste run, with the note that the node is used', (tester) async {
      final h = _Harness(advanced: offline, payments: _directOn);
      await h.pump(tester);
      await h.fileTab(tester);
      for (final label in ['Open file', 'Paste']) {
        expect(
          tester
              .widget<KitButton>(find.widgetWithText(KitButton, label))
              .onPressed,
          isNotNull,
          reason: label,
        );
      }
      expect(find.text(_l.netBlockNodeOnly), findsNothing);
      expect(find.text(_l.netOfflineNodeLine), findsWidgets);
    });

    testWidgets('Epicbox off: no address on the screen, the other ways stay in the sheet', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, linkTor: true));
      await h.pump(tester);
      expect(find.byKey(receiveAddressKey), findsNothing);
      expect(find.byType(LogoQr), findsNothing);
      expect(find.text(_l.phoneRecvOther), findsOneWidget);
    });

    testWidgets('every method off: no address, and With a file still opens', (tester) async {
      final h = _Harness(payments: const PaymentPrefs(epicbox: false, directFile: false, directQr: false));
      await h.pump(tester);
      expect(find.byKey(receiveAddressKey), findsNothing);
      await h.fileTab(tester);
      expect(find.text(_l.receiveFileOpen), findsOneWidget);
    });

    testWidgets('Standard: no offline line', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('Link receiving is off in Node only.'), findsNothing);
      expect(find.byKey(receiveEpicboxOffModeKey), findsNothing);
    });
  });

  group('Tor address page', () {
    testWidgets('Tor off: Link receiving needs Tor; no switch on Receive', (
      tester,
    ) async {
      final h = _Harness(payments: _directOn);
      await h.pump(tester);
      await h.torTab(tester);
      expect(find.text(_l.receiveDirectNeedsTor), findsOneWidget);
      expect(
        find.text(_l.receiveDirectMeanwhile),
        findsOneWidget,
      );
      expect(find.byKey(receiveTurnOnTorKey), findsOneWidget);
      expect(find.byKey(torSettingsLinkKey), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byKey(receiveTorAddressKey), findsNothing);
      expect(find.byType(LogoQr), findsNothing);
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
      expect(find.bySemanticsLabel(_l.receiveTorAddressLabel), findsOne);
      expect(find.text(h.session.onion), findsOneWidget);
      final qr = tester.widget<LogoQr>(find.byType(LogoQr));
      expect(qr.data, h.session.onion);
      expect(find.bySemanticsLabel(_l.receiveTorQrLabel), findsOne);
      expect(
        find.text(
          _l.receiveTorCaption,
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
      expect(find.text(_l.receiveAddressCopied), findsOneWidget);
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
