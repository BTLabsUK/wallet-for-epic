// SPDX-License-Identifier: Apache-2.0
// The first onboarding step of a fresh install (the Welcome, ui/first_run_screen.dart): no view picker, it
// fits the smallest and a common phone without scrolling or overflow, the Tor only row sits
// under Create and Restore, and Create stores the basic view and goes straight to the PIN.
// Change level (Settings › Advanced › Wallet view) keeps the picker.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/levels/level_providers.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/ui/first_run_screen.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_icons.dart';
import 'package:epic_wallet/src/ui/kit/kit_row.dart';
import 'package:epic_wallet/src/ui/levels/change_level_screen.dart';
import 'package:epic_wallet/src/ui/levels/level_picker.dart';
import 'package:epic_wallet/src/ui/pin.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // A fresh install: the step is to answer and nothing connects.
  NetGate.holdFirstStart();
  addTearDown(() {
    NetGate.releaseFirstStart();
    NetGate.set(NetworkMode.standard);
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService()),
        walletDirProvider.overrideWithValue((chain) async => '/fake/wallets/${chain.name}'),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false)),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
      ],
      child: const WalletApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Whether the Welcome's Tor only switch is on.
bool _torOn(WidgetTester tester) => tester.widget<KitRow>(find.byKey(firstRunTorOnlyKey)).toggled ?? false;

void main() {
  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('fits ${size.width.toInt()}×${size.height.toInt()} unscrolled; Create leads to the PIN in the basic view', (
      tester,
    ) async {
      final container = await _pump(tester, size);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      // No view picker as a first step.
      expect(find.byKey(levelStopKey(WalletLevel.casual)), findsNothing);

      // Everything in view (an overflow would have failed the pump). The buttons and the Tor
      // only row are pinned; on the smallest phone the heading above them may scroll a little.
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(FirstRunScreen), matching: find.byType(Scrollable)).first,
      );
      if (size.height >= 800) expect(scrollable.position.maxScrollExtent, 0);
      for (final key in [firstRunCreateKey, firstRunRestoreKey, if (torBuilt) firstRunTorOnlyKey]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: '$key below the screen');
      }
      // Create and Restore work at once; the Tor only row sits under them, off.
      KitButton create() => tester.widget<KitButton>(find.byKey(firstRunCreateKey));
      expect(create().onPressed, isNotNull);
      if (torBuilt) {
        expect(
          tester.getRect(find.byKey(firstRunTorOnlyKey)).top,
          greaterThan(tester.getRect(find.byKey(firstRunRestoreKey)).bottom),
        );
        expect(_torOn(tester), isFalse);
        await tester.tap(find.byKey(firstRunTorOnlyKey));
        await tester.pumpAndSettle();
        expect(_torOn(tester), isTrue);
      }

      await tester.tap(find.byKey(firstRunCreateKey));
      await tester.pumpAndSettle();
      // Straight to the PIN: the old Create / Restore choice is skipped.
      expect(find.byType(FirstRunScreen), findsOneWidget);
      expect(find.byType(PinSetupView), findsOneWidget);
      expect(find.byKey(firstRunCreateKey), findsNothing);
      expect(container.read(currentLevelProvider), WalletLevel.justSendReceive);
      expect(NetGate.firstStartHold, isFalse);
      if (torBuilt) {
        expect(container.read(appSettingsProvider).value?.advanced.networkMode, NetworkMode.torOnly);
      }

      // Back returns to the first step with the answer kept.
      await tester.tap(find.byIcon(KitIcons.back));
      await tester.pumpAndSettle();
      expect(find.byType(FirstRunScreen), findsOneWidget);
      if (torBuilt) expect(_torOn(tester), isTrue);
    });
  }

  testWidgets('large text on the smallest phone scrolls instead of overflowing', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, const Size(320, 568));
    expect(find.byType(FirstRunScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(firstRunRestoreKey), 100);
    expect(find.byKey(firstRunRestoreKey), findsOneWidget);
  });

  testWidgets('Change level shows the level in force and Save stores the new one', (tester) async {
    final container = await _pump(tester, const Size(390, 844));
    await container.read(walletLevelProvider.notifier).setLevel(WalletLevel.justSendReceive);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const ChangeLevelScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Send, receive, done. The wallet minds the rest.'), findsOneWidget);
    await tester.tap(find.byKey(levelStopKey(WalletLevel.everything)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(levelSaveKey));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeLevelScreen), findsNothing);
    expect(container.read(currentLevelProvider), WalletLevel.everything);
  });
}
