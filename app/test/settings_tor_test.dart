// SPDX-License-Identifier: Apache-2.0
// Settings › Network & privacy: Tor is a Connection mode (Tor only), not a switch; the Tor
// only row is disabled where the app has no Tor.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/network_mode_phone.dart' show networkModeRowKey;
import 'package:epic_wallet/src/ui/tor_ui.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/tor_build.dart';
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
  _Harness({this.bundle = _bundle}) : advanced = AdvancedPrefs.none;

  final TorBundle? bundle;

  /// What the Advanced page holds: the network mode locks the Tor switch.
  final AdvancedPrefs advanced;
  final session = FakeWalletSession();
  final store = MemorySecretStore();
  final network = StreamController<bool>.broadcast();
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    bool privacy = false,
    SettingsSection? section,
  }) async {
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
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AdvancedOptions(prefs: advanced, child: child!),
          home: SettingsScreen(privacy: privacy, section: section),
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

void main() {
  // Tor's own behaviour: nothing of it is in the build without Tor.
  if (!torBuilt) {
    test('Tor', () {}, skip: 'no Tor in this build');
    return;
  }
  group('network modes', () {
    ListTile row(WidgetTester tester, NetworkMode m) =>
        tester.widget<ListTile>(find.byKey(networkModeRowKey(m)));
    NetworkMode? selected(WidgetTester tester) =>
        tester.widget<RadioGroup<NetworkMode>>(find.byType(RadioGroup<NetworkMode>)).groupValue;

    testWidgets('Standard: Tor only is one of the rows, off, and there is no Tor switch', (tester) async {
      final h = _Harness();
      await h.pump(tester, privacy: true);
      await _reach(tester, find.byKey(networkModeRowKey(NetworkMode.torOnly)));
      expect(row(tester, NetworkMode.torOnly).enabled, isTrue);
      expect(selected(tester), NetworkMode.standard);
      expect(find.byKey(torReceivingSwitchKey), findsNothing);
      expect(find.byKey(torLockedLineKey), findsNothing);
      expect(find.byKey(settingsPrivacyKey), findsNothing);
      expect(find.text('Tor for all connections'), findsNothing);
      expect(h.container.read(phoneTorProvider).receiving, isFalse);
    });

    testWidgets('Tor only: its row is the one chosen', (tester) async {
      final h = _Harness();
      await h.pump(tester, privacy: true);
      await h.container.read(appSettingsProvider.future);
      await h.container.read(appSettingsProvider.notifier).setNetworkMode(NetworkMode.torOnly);
      await tester.pumpAndSettle();
      await _reach(tester, find.byKey(networkModeRowKey(NetworkMode.torOnly)));
      expect(selected(tester), NetworkMode.torOnly);
      expect(find.byKey(torReceivingSwitchKey), findsNothing);
      expect(find.byKey(torLockedLineKey), findsNothing);
    });

    testWidgets('Kill switch: its row is the one chosen, with no Tor switch', (tester) async {
      final h = _Harness();
      await h.pump(tester, privacy: true);
      await h.container.read(appSettingsProvider.future);
      await h.container.read(appSettingsProvider.notifier).setNetworkMode(NetworkMode.killSwitch);
      await tester.pumpAndSettle();
      await _reach(tester, find.byKey(networkModeRowKey(NetworkMode.killSwitch)));
      expect(selected(tester), NetworkMode.killSwitch);
      expect(find.byKey(torReceivingSwitchKey), findsNothing);
      expect(h.session.torStarts, isEmpty);
    });
  });

  testWidgets('opened for privacy, the Connection mode rows are in view', (tester) async {
    final h = _Harness();
    await h.pump(tester, privacy: true);
    final view = tester.getRect(find.byType(ListView));
    final row = tester.getRect(find.byKey(networkModeRowKey(NetworkMode.standard)));
    expect(row.top, greaterThanOrEqualTo(view.top));
    expect(row.bottom, lessThanOrEqualTo(view.bottom));
    expect(h.container.read(phoneTorProvider).receiving, isFalse);
  });

  testWidgets('no Tor only where the app has no Tor', (tester) async {
    final h = _Harness(bundle: null);
    await h.pump(tester, privacy: true);
    expect(find.byKey(torReceivingSwitchKey), findsNothing);
    final tile = tester.widget<ListTile>(find.byKey(networkModeRowKey(NetworkMode.torOnly)));
    expect(tile.enabled, isFalse, reason: 'Tor only is disabled while Tor is unavailable');
  });
}
