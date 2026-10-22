// Settings › Receiving: the "Tor receiving" switch, the same one as on Receive and bound to
// the same controller, with the status and the one honest line; not under Advanced (F28),
// and absent where the app has no Tor.

import 'dart:async';

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
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

  Future<void> pump(WidgetTester tester) async {
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
              AdvancedOptions(enabled: false, child: child!),
          home: const SettingsScreen(),
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
}

void main() {
  testWidgets('a Receiving section with the Tor switch, no Advanced needed', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text('Receiving'), findsOneWidget);
    expect(find.text('Tor receiving'), findsOneWidget);
    expect(find.textContaining('Tor receiving is off'), findsOneWidget);
    expect(
      find.text(
        'Slower and more private. Blocked or not allowed in some countries.',
      ),
      findsOneWidget,
    );
    // It sits with the everyday settings, right after Display.
    final display = tester.getTopLeft(find.text('Display')).dy;
    final receiving = tester.getTopLeft(find.text('Receiving')).dy;
    expect(receiving, greaterThan(display));
    expect(find.text('Notifications'), findsNothing);
    for (final word in ['Listener', 'listener', 'Advanced Tor']) {
      expect(find.textContaining(word), findsNothing);
    }

    await tester.tap(find.byKey(torReceivingSwitchKey));
    await tester.pumpAndSettle();
    expect(h.session.torStarts, hasLength(1));
    expect(h.container.read(phoneTorProvider).receiving, isTrue);
    expect(find.textContaining('Connecting to Tor… 0%'), findsOneWidget);
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

  testWidgets('no Receiving section where the app has no Tor', (tester) async {
    final h = _Harness(bundle: null);
    await h.pump(tester);
    expect(find.text('Receiving'), findsNothing);
    expect(find.byKey(torReceivingSwitchKey), findsNothing);
  });
}
