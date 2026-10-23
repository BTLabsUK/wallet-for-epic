// Settings › Privacy: the one Tor switch, bound to the phone's Tor controller, with one line
// saying what it covers ("Not connected" and Retry when Tor failed); not under Advanced (F28),
// and absent where the app has no Tor. Push is off while Tor is on.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const TorBundle _bundle = TorBundle(binary: '/data/app/lib/arm64/libtor.so');

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Harness {
  _Harness({this.bundle = _bundle});

  final TorBundle? bundle;
  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {bool privacy = false}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(FakeWalletService()),
          secretStoreProvider.overrideWithValue(store),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          updatePlatformProvider.overrideWithValue(null),
          torBundleFinderProvider.overrideWithValue(() async => bundle),
          networkChangesProvider.overrideWithValue(network.stream),
          pushConfiguredProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AdvancedOptions(enabled: false, child: child!),
          home: SettingsScreen(privacy: privacy),
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
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await network.close();
    });
  }

  /// Tor's next event, with what `torStatus` answers afterwards.
  Future<void> emit(
    WidgetTester tester,
    TorEventKind kind, {
    TorFailure? failure,
  }) async {
    session.torStatusValue = switch (kind) {
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      _ => TorStatus.off,
    };
    session.torEvents.add(
      TorEvent(
        kind: kind,
        failure: failure,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// Scrolls Settings until [finder] is built and in view.
Future<void> _reach(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

SwitchListTile _push(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(settingsPushKey));

void main() {
  testWidgets('Privacy: one Tor switch, what it covers, no Advanced needed', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    final privacy = find.byKey(settingsPrivacyKey);
    expect(privacy, findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Receiving'), findsNothing);
    expect(find.text('Tor receiving'), findsNothing);
    // The switch is the first row under Privacy.
    await _reach(tester, privacy);
    expect(
      tester.getTopLeft(find.byKey(torReceivingSwitchKey)).dy,
      greaterThan(tester.getTopLeft(privacy).dy),
    );
    await tester.ensureVisible(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    // The label only; the explanation is the info icon's tooltip, and no line in the row
    // says what goes over Tor or what does not.
    expect(
      find.descendant(
        of: find.byKey(torReceivingSwitchKey),
        matching: find.text('Tor Network'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(torReceivingSwitchKey),
        matching: find.byTooltip(
          'Network activity goes through the Tor network. Tor hides the wallet’s internet address: each connection passes through several volunteer-run relays, so no server learns where the wallet is.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('go through Tor'), findsNothing);
    expect(find.textContaining('Not over Tor'), findsNothing);
    expect(find.byKey(torStatusKey), findsNothing, reason: 'off: no state line');


    for (final word in ['Listener', 'listener', 'Advanced Tor']) {
      expect(find.textContaining(word), findsNothing);
    }

    await tester.tap(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    // No confirmation: it just turns on.
    expect(find.byType(AlertDialog), findsNothing);
    expect(h.session.torStarts, hasLength(1));
    expect(h.container.read(phoneTorProvider).receiving, isTrue);
    // Starting: the state word alone, under the label.
    expect(
      find.descendant(
        of: find.byKey(torStatusKey),
        matching: find.text('Starting…'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('go through Tor'), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byKey(torReceivingSwitchKey)).value,
      isTrue,
    );
    // The choice is saved for this wallet.
    final config = h.container.read(walletConfigProvider);
    if (config != null) {
      expect(h.store.values[PhoneTor.receivingKey(config)], 'true');
    }
  });

  testWidgets('Tor not connected: the line says so, with Retry', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await h.container.read(phoneTorProvider.notifier).setReceiving(true);
    await tester.pumpAndSettle();
    await h.emit(tester, TorEventKind.failed, failure: TorFailure.network);
    await h.emit(tester, TorEventKind.stopped);
    await tester.ensureVisible(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(torStatusKey),
        matching: find.text('Not connected'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(torRetryKey), findsOneWidget);
    await tester.tap(find.byKey(torRetryKey));
    await tester.pumpAndSettle();
    expect(h.session.torStarts, hasLength(2));
  });

  testWidgets('push is off while Tor is on', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await _reach(tester, find.byKey(settingsPushKey));
    expect(_push(tester).onChanged, isNotNull);
    expect(find.text('Off while Tor is on'), findsNothing);

    await h.container.read(phoneTorProvider.notifier).setReceiving(true);
    await tester.pumpAndSettle();
    await h.emit(tester, TorEventKind.ready);
    await _reach(tester, find.byKey(settingsPushKey));
    expect(_push(tester).onChanged, isNull);
    expect(_push(tester).value, isFalse);
    expect(find.text('Off while Tor is on'), findsOneWidget);
  });

  testWidgets('opened for privacy, the Tor switch is in view', (tester) async {
    final h = _Harness();
    await h.pump(tester, privacy: true);
    final view = tester.getRect(find.byType(ListView));
    final row = tester.getRect(find.byKey(torReceivingSwitchKey));
    expect(row.top, greaterThanOrEqualTo(view.top));
    expect(row.bottom, lessThanOrEqualTo(view.bottom));
    expect(h.container.read(phoneTorProvider).receiving, isFalse);
  });

  testWidgets('no Tor switch where the app has no Tor', (tester) async {
    final h = _Harness(bundle: null);
    await h.pump(tester);
    expect(find.byKey(torReceivingSwitchKey), findsNothing);
  });
}
