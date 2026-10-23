import 'dart:async';

import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/server_picker.dart' show serverRowKey;
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mainnetDir = '/fake/wallets/mainnet';
const _pin = '123456';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// Relay health as status.btlabs.uk would report it.
class _FakeRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => chain == 'mainnet'
      ? const [
          RelayStatus(
            relay: EpicboxRelay(host: 'epicbox.epicnet.us'),
            healthy: true,
            verified: true,
            operator: 'epicnet.us',
            uptime24h: 1,
          ),
          RelayStatus(
            relay: EpicboxRelay(host: 'epicbox.epiccash.com'),
            healthy: true,
            verified: true,
            operator: 'Epic Cash',
          ),
        ]
      : const [];
}

/// No price, as when CoinGecko cannot be reached.
class _NoPrice implements PriceSource {
  const _NoPrice();

  @override
  Future<double?> price(String currency) async => null;
}

/// Everything the app keeps outside the wallet, in memory.
class _Device {
  _Device({
    bool biometrics = false,
    this.sealedMainnet = false,
    bool advanced = false,
  }) : bio = MemoryBiometricStore(available: biometrics) {
    if (advanced) store.values['app.advanced'] = 'true';
    if (sealedMainnet) {
      store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    }
  }

  final bool sealedMainnet;
  final store = MemorySecretStore();
  final MemoryBiometricStore bio;
  final files = FakeSlateFiles();
}

/// Pumps a second of frames, for screens with a spinner that never settles.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeWalletService service,
  _Device device, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        // The network picker is for development builds; this flow picks Usernet.
        devNetworksProvider.overrideWithValue(true),
        walletServiceProvider.overrideWithValue(service),
        walletDirProvider.overrideWithValue(
          (chain) async => '/fake/wallets/${chain.name}',
        ),
        secretStoreProvider.overrideWithValue(device.store),
        biometricStoreProvider.overrideWithValue(device.bio),
        updatePlatformProvider.overrideWithValue(null),
        pushPlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_FakeRelays()),
        slateFilesProvider.overrideWithValue(device.files),
        priceSourceProvider.overrideWithValue(const _NoPrice()),
      ],
      child: const WalletApp(),
    ),
  );
  settle ? await tester.pumpAndSettle() : await _pumpFrames(tester);
}

/// Scrolls the current screen's list until [finder] is built, then into view.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            // The balance tiles are a ListView too, but they run sideways.
            of: find
                .byWidgetPredicate(
                  (w) => w is ListView && w.scrollDirection == Axis.vertical,
                )
                .last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
}

/// Closes every notice: a docked one moves the content down, so taps by position would miss.
Future<void> _clearNotices(WidgetTester tester) async {
  ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
      .read(noticeProvider.notifier)
      .clear();
  await tester.pumpAndSettle();
}

/// Reduced motion for the rest of the test: a wallet with three kinds pending has a pending
/// line wider than the screen, which would scroll on and never let the screen settle.
void _holdStill(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text));

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// [_enter] without waiting for animations to end.
Future<void> _enterNow(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await _pumpFrames(tester);
}

/// Starts on a mainnet wallet with a PIN and unlocks it.
Future<void> _unlockToHome(WidgetTester tester) async {
  expect(find.text('Unlock wallet'), findsOneWidget);
  await _enter(tester, 'PIN', _pin);
}

FakeWalletService _existing({FakeWalletSession? session}) =>
    FakeWalletService(existingWallets: {_mainnetDir}, session: session);

FakeWalletSession _fundedSession() => FakeWalletSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2499990),
    minimumConfirmations: BigInt.from(3),
    total: _epic(16),
    spendable: _epic(12.5),
    awaitingConfirmation: _epic(1),
    awaitingFinalization: BigInt.zero,
    immature: _epic(0.5),
    locked: _epic(2),
    validatedWithNode: false,
  ),
  transactions: [
    fakeTx(
      id: 2,
      slateId: 'b',
      kind: TxKind.sent,
      status: TxStatus.awaitingRecipient,
      cancellable: true,
      createdAtUnix: 1790000100,
      confirmed: false,
      amountCredited: _epic(3.992),
      amountDebited: _epic(5),
      fee: _epic(0.008),
      numInputs: 1,
      numOutputs: 1,
    ),
    fakeTx(
      id: 1,
      slateId: 'a',
      kind: TxKind.received,
      createdAtUnix: 1790000000,
      confirmed: true,
      amountCredited: _epic(5),
      amountDebited: BigInt.zero,
      numInputs: 0,
      numOutputs: 1,
    ),
  ],
);

void main() {
  group('first run', () {
    testWidgets(
      'creates the wallet under the PIN, with biometrics holding the PIN',
      (tester) async {
        final service = FakeWalletService()..createGate = Completer<void>();
        final device = _Device(biometrics: true);
        await _pumpApp(tester, service, device, settle: false);

        expect(find.text('Welcome'), findsOneWidget);
        // Nothing exists before the PIN: LEPIC creates the wallet under it.
        expect(service.existingWallets, isEmpty);

        await _enterNow(tester, 'PIN', _pin);
        await _enterNow(tester, 'Repeat PIN', '654321');
        expect(find.textContaining('do not match'), findsOneWidget);

        await _enterNow(tester, 'PIN', _pin);
        await _enterNow(tester, 'Repeat PIN', _pin);
        expect(find.text('Unlock with fingerprint or face?'), findsOneWidget);
        await tester.tap(find.text('Use biometrics'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Securing your wallet…'), findsOneWidget);
        expect(find.byKey(balanceFigureKey), findsNothing);

        service.createGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(balanceFigureKey), findsOneWidget);
        expect(find.text('Back up your recovery phrase.'), findsOneWidget);

        expect(service.createdConfig?.chain, Chain.mainnet);
        expect(service.createdConfig?.dataDir, _mainnetDir);
        expect(service.createdMnemonic, isNull);
        expect(service.createdPin, _pin);
        // Only the sealed text is stored; the biometric copy is the PIN.
        expect(device.store.values, {
          'wallet.mainnet.pinSealed': fakeSealedPassword(_pin),
          'wallet.mainnet.pinBiometrics': '1',
        });
        expect(device.bio.values, {'wallet.mainnet.pin': _pin});
      },
    );

    testWidgets('skips the biometric question where there are none', (
      tester,
    ) async {
      final service = FakeWalletService();
      final device = _Device();
      await _pumpApp(tester, service, device);
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(device.bio.values, isEmpty);
      expect(device.store.values['wallet.mainnet.pinBiometrics'], isNull);
    });

    testWidgets(
      'a wallet without its sealed text is kept until the user removes it',
      (tester) async {
        // The app stopped after LEPIC created the wallet and before the text was stored, or the
        // store did not answer.
        final service = _existing();
        final device = _Device();
        await _pumpApp(tester, service, device);

        expect(find.text('Welcome'), findsNothing);
        expect(find.textContaining('Nothing was deleted'), findsOneWidget);
        expect(service.deletedWallets, isEmpty);

        // Removing it is the user's step.
        await _tapText(tester, 'Forgot PIN?');
        await _tapText(tester, 'I have my recovery phrase');
        await _tap(tester, find.widgetWithText(FilledButton, 'Delete wallet'));
        expect(service.deletedWallets, [_mainnetDir]);
        expect(find.text('Welcome'), findsOneWidget);
        await _enter(tester, 'PIN', _pin);
        await _enter(tester, 'Repeat PIN', _pin);
        expect(find.byKey(balanceFigureKey), findsOneWidget);
        expect(service.createdPin, _pin);
        expect(
          device.store.values['wallet.mainnet.pinSealed'],
          fakeSealedPassword(_pin),
        );
      },
    );

    testWidgets(
      'sealed text without its wallet is kept, and nothing is deleted',
      (tester) async {
        // The wallet's entries are not where the app looks (a moved data directory).
        final service = FakeWalletService();
        final device = _Device(sealedMainnet: true);
        final before = Map.of(device.store.values);
        await _pumpApp(tester, service, device);

        expect(find.text('Welcome'), findsNothing);
        expect(find.textContaining('Nothing was deleted'), findsOneWidget);
        expect(device.store.values, before);
        expect(service.deletedWallets, isEmpty);
      },
    );

    testWidgets('an install of 1.2.x stays, and first run starts beside it', (
      tester,
    ) async {
      final service = FakeWalletService();
      final device = _Device(biometrics: true);
      final old = {
        'wallet.mainnet.sealed': 'sealed by the old core',
        'wallet.mainnet.biometrics': '1',
      };
      device.store.values.addAll({...old, 'wallet.mainnet.backedUp': '1'});
      device.bio.values['wallet.mainnet.password'] = 'old password';
      await _pumpApp(tester, service, device);

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Unlock wallet'), findsNothing);
      for (final e in old.entries) {
        expect(device.store.values[e.key], e.value);
      }
      expect(device.bio.values, {'wallet.mainnet.password': 'old password'});
      expect(device.bio.prompts, 0);

      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      await _tapText(tester, 'Not now');
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      // The old wallet's backed-up flag does not carry over to the new one.
      expect(find.text('Back up your recovery phrase.'), findsOneWidget);
      for (final e in old.entries) {
        expect(device.store.values[e.key], e.value);
      }
      expect(device.bio.values['wallet.mainnet.password'], 'old password');
    });

    testWidgets('restore creates the wallet from the phrase under the PIN', (
      tester,
    ) async {
      final service = FakeWalletService();
      final device = _Device(advanced: true);
      await _pumpApp(tester, service, device);
      await _tapText(tester, 'I already have a wallet: restore it');

      await _enter(tester, 'Recovery phrase', 'not a valid phrase');
      await _tapText(tester, 'Continue');
      expect(
        find.textContaining('recovery phrase is not valid'),
        findsOneWidget,
      );

      await _enter(
        tester,
        'Recovery phrase',
        '  ${service.phrase.toUpperCase()} ',
      );
      await _tapText(tester, 'Block height');
      await _enter(tester, 'Start height (optional)', '1000');
      await _tapText(tester, 'Continue');
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      await _tapText(tester, 'Not now');

      expect(service.deletedWallets, isEmpty);
      expect(service.createdMnemonic == service.phrase, isTrue);
      expect(service.createdPin, _pin);
      expect(service.session.scanCalls, 1);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(find.text('Back up your recovery phrase.'), findsNothing);
      expect(
        device.store.values['wallet.mainnet.pinSealed'],
        fakeSealedPassword(_pin),
      );
    });

    testWidgets('network settings switch the first run to usernet', (
      tester,
    ) async {
      final service = FakeWalletService();
      await _pumpApp(tester, service, _Device());
      await _tap(tester, find.bySemanticsLabel('Node and Epicbox'));
      await _tapText(tester, 'Usernet');
      final urlField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Node URL'),
      );
      expect(urlField.controller!.text, 'http://127.0.0.1:23413');
      await _tapText(tester, 'Save');

      expect(find.text('Welcome (Usernet, test coins)'), findsOneWidget);
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(service.createdConfig?.chain, Chain.usernet);
      expect(service.createdConfig?.epicboxPort, 3423);
    });
  });

  testWidgets('network settings pick a mainnet relay from the monitor', (
    tester,
  ) async {
    final service = FakeWalletService();
    final device = _Device();
    await _pumpApp(tester, service, device);
    await _tap(tester, find.bySemanticsLabel('Node and Epicbox'));

    await _reveal(tester, find.text('epicbox.epicnet.us'));
    expect(find.text('epicbox.epicnet.us'), findsOneWidget);
    expect(
      find.textContaining('EpicNet · 100.0 % up', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('server changes your address'), findsNothing);
    await _tapText(tester, 'epicbox.epicnet.us');
    expect(find.textContaining('server changes your address'), findsOneWidget);

    await _enter(
      tester,
      'Other epicbox server (host or host:port)',
      'not a host!',
    );
    await _tap(tester, find.byTooltip('Use this server'));
    expect(find.textContaining('Enter a host'), findsOneWidget);
    await _enter(
      tester,
      'Other epicbox server (host or host:port)',
      'relay.example.org:8443',
    );
    await _tap(tester, find.byTooltip('Use this server'));
    expect(find.text('relay.example.org:8443'), findsOneWidget);
    expect(find.byKey(serverRowKey('relay.example.org:8443')), findsOneWidget);

    await _tapText(tester, 'epicbox.epicnet.us');
    await _tapText(tester, 'Save');
    expect(device.store.values['app.relay.mainnet'], 'epicbox.epicnet.us');
    await _enter(tester, 'PIN', _pin);
    await _enter(tester, 'Repeat PIN', _pin);
    // The relay comes from the config the wallet opens with, which is what the address and
    // the listener use.
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(balanceFigureKey)),
    );
    final config = container.read(walletConfigProvider)!;
    expect(config.epicboxDomain, 'epicbox.epicnet.us');
    expect(config.epicboxPort, 443);
  });

  group('unlock', () {
    testWidgets("a wrong PIN shows LEPIC's count, then its wait", (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);

      await _enter(tester, 'PIN', '000000');
      expect(
        find.text('Wrong PIN. 2 tries left before a pause.'),
        findsOneWidget,
      );
      expect(find.byKey(balanceFigureKey), findsNothing);
      await _enter(tester, 'PIN', '000000');
      await _enter(tester, 'PIN', '000000');
      expect(service.pinFailureCount, 3);
      expect(
        find.text('Wrong PIN. The next try is checked after 30 seconds.'),
        findsOneWidget,
      );
      // LEPIC does the waiting, inside the next try, so the field stays usable.
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'PIN'),
      );
      expect(field.enabled, isTrue);
      await _enter(tester, 'PIN', '000000');
      expect(
        find.text('Wrong PIN. The next try is checked after 60 seconds.'),
        findsOneWidget,
      );
    });

    testWidgets('the count survives a restart', (tester) async {
      final service = _existing()..pinFailureCount = 9;
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      expect(
        find.text('Wrong PIN. The next try is checked after 32 minutes.'),
        findsOneWidget,
      );
      await _unlockToHome(tester);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
      expect(service.pinFailureCount, 0);
    });

    testWidgets('the right PIN opens the wallet', (tester) async {
      final service = _existing();
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
    });

    testWidgets('biometrics unlock on start when enabled', (tester) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      device.store.values['wallet.mainnet.pinBiometrics'] = '1';
      device.bio.values['wallet.mainnet.pin'] = _pin;
      await _pumpApp(tester, service, device);
      expect(device.bio.prompts, 1);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
    });

    testWidgets('a dismissed biometric prompt leaves the PIN', (tester) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      device.store.values['wallet.mainnet.pinBiometrics'] = '1';
      device.bio.values['wallet.mainnet.pin'] = _pin;
      device.bio.succeed = false;
      await _pumpApp(tester, service, device);
      expect(find.byKey(balanceFigureKey), findsNothing);
      expect(find.text('Use biometrics'), findsOneWidget);
      await _unlockToHome(tester);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
    });

    testWidgets('a biometric copy that no longer opens turns biometrics off', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      device.store.values['wallet.mainnet.pinBiometrics'] = '1';
      device.bio.values['wallet.mainnet.pin'] = '999999';
      await _pumpApp(tester, service, device);
      expect(find.byKey(balanceFigureKey), findsNothing);
      expect(
        find.text('Wrong PIN. 2 tries left before a pause.'),
        findsOneWidget,
      );
      expect(find.text('Use biometrics'), findsNothing);
      expect(device.bio.values, isEmpty);
      await _unlockToHome(tester);
      expect(find.byKey(balanceFigureKey), findsOneWidget);
    });

    testWidgets('forgot PIN deletes the wallet only after confirmation', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _tapText(tester, 'Forgot PIN?');
      final delete = find.widgetWithText(FilledButton, 'Delete wallet');
      expect(tester.widget<FilledButton>(delete).onPressed, isNull);
      await _tapText(tester, 'Keep wallet');
      expect(service.deletedWallets, isEmpty);

      await _tapText(tester, 'Forgot PIN?');
      await _tapText(tester, 'I have my recovery phrase');
      await _tap(tester, delete);
      expect(service.deletedWallets, [_mainnetDir]);
      expect(device.store.values['wallet.mainnet.pinSealed'], isNull);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('renders balances, sync state and transactions', (
      tester,
    ) async {
      _holdStill(tester);
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, '12.5');
      final handle = tester.ensureSemantics();
      await tester.pump();
      // Offline shows once it lasts (walletStatusProvider).
      await tester.pump(statusSettle);
      expect(find.bySemanticsLabel(RegExp('^Node, Offline')), findsOneWidget);
      handle.dispose();
      // Total 16, spendable 12.5: the rest is in the tiles under the figure; the row scrolls.
      for (final (kind, label, value) in [
        (BalanceKind.confirming, 'Confirming', '1'),
        (BalanceKind.locked, 'Locked in sends', '2'),
        (BalanceKind.total, 'Total', '16'),
      ]) {
        // The row builds the tiles near the edge only: drag until this one is there.
        for (var i = 0; i < 10; i++) {
          if (find.byKey(balanceTileKey(kind)).evaluate().isNotEmpty) break;
          await tester.drag(find.byKey(balanceTilesKey), const Offset(-100, 0));
          await tester.pumpAndSettle();
        }
        expect(
          find.descendant(
            of: find.byKey(balanceTileKey(kind)),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
        expect(
          find.descendant(
            of: find.byKey(balanceTileKey(kind)),
            matching: find.text(value),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      // Nothing waits to finish, so that tile is left out.
      expect(
        find.byKey(balanceTileKey(BalanceKind.waitingSender)),
        findsNothing,
      );

      await _reveal(tester, find.text('+5 EPIC'));
      expect(find.text('Incoming payment'), findsOneWidget);
      expect(find.text('-1 EPIC'), findsOneWidget);
      expect(find.textContaining('Waiting for recipient'), findsOneWidget);
      expect(find.textContaining('Received'), findsOneWidget);
      // No actions on rows: cancel lives in the details.
      expect(find.byTooltip('Cancel payment'), findsNothing);
    });

    testWidgets('an unconfirmed send is cancelled from its details', (
      tester,
    ) async {
      _holdStill(tester);
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      await _tap(tester, find.byKey(const ValueKey('tx-s:b')));
      // No address was recorded, so this is a send by transaction file.
      expect(find.textContaining('their transaction file'), findsOneWidget);
      expect(find.text('Fee'), findsOneWidget);
      expect(find.text('0.008 EPIC'), findsOneWidget);
      final cancel = find.widgetWithText(OutlinedButton, 'Cancel payment');
      await _tap(tester, cancel);
      await _tapText(tester, 'Keep');
      expect(session.cancelledTxIds, isEmpty);
      await _tap(tester, cancel);
      await _tap(tester, find.widgetWithText(FilledButton, 'Cancel payment'));
      expect(session.cancelledTxIds, [2]);
      expect(find.text('Payment cancelled'), findsOneWidget);

      // A confirmed receive has no cancel.
      await _clearNotices(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('tx-s:a')));
      expect(find.text('Completed.'), findsOneWidget);
      expect(cancel, findsNothing);
    });

    testWidgets(
      'backup asks for agreement, then the PIN, shows the phrase, Done marks it',
      (tester) async {
        final service = _existing();
        final device = _Device(sealedMainnet: true);
        await _pumpApp(tester, service, device);
        await _unlockToHome(tester);

        await tester.tap(find.text('Back up'));
        await _pumpFrames(tester);
        // No PIN, and no phrase, until the user agrees to keep any copy private.
        expect(find.text('Enter your PIN'), findsNothing);
        final show = find.widgetWithText(FilledButton, 'Show recovery phrase');
        expect(tester.widget<FilledButton>(show).onPressed, isNull);
        await tester.tap(
          find.text('I will keep any copy of the phrase private'),
        );
        await tester.pump();
        await tester.tap(show);
        await _pumpFrames(tester);
        expect(find.text('Enter your PIN'), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          _pin,
        );
        await tester.pumpAndSettle();

        final words = service.phrase.split(' ');
        expect(find.text('1. ${words.first}'), findsOneWidget);
        await _tapText(tester, 'Done');

        expect(find.text('Recovery phrase backed up'), findsOneWidget);
        expect(find.text('Back up your recovery phrase.'), findsNothing);
        expect(device.store.values['wallet.mainnet.backedUp'], '1');
      },
    );

    testWidgets('biometric unlock can be turned on from settings', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, find.byKey(settingsGroupKey(SettingsSection.security)));
      await _tapText(tester, 'Unlock with biometrics');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        _pin,
      );
      await tester.pumpAndSettle();
      expect(device.bio.values['wallet.mainnet.pin'], _pin);
      expect(device.store.values['wallet.mainnet.pinBiometrics'], '1');
      expect(find.text('Biometric unlock turned on'), findsOneWidget);
    });

    testWidgets('a full rescan from settings streams progress', (tester) async {
      final service = _existing();
      await _pumpApp(
        tester,
        service,
        _Device(advanced: true, sealedMainnet: true),
      );
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, find.byKey(settingsGroupKey(SettingsSection.wallet)));
      await _tapText(tester, 'Rescan the chain');
      await _tapText(tester, 'The whole chain');
      await _tapText(tester, 'Rescan');
      expect(service.session.scanCalls, 1);
      await _clearNotices(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(balanceFigureKey), findsOneWidget);
    });

    testWidgets('a failed scan shows the core message on home too', (
      tester,
    ) async {
      final service = _existing();
      service.session.scanEvents = const [
        ScanProgress(percent: 10, message: 'Scanning', finished: false),
        ScanProgress(message: 'Scan failed: node unreachable', finished: true),
      ];
      await _pumpApp(
        tester,
        service,
        _Device(advanced: true, sealedMainnet: true),
      );
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, find.byKey(settingsGroupKey(SettingsSection.wallet)));
      await _tapText(tester, 'Rescan the chain');
      await _tapText(tester, 'The whole chain');
      await _tapText(tester, 'Rescan');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('The scan failed. node unreachable'), findsOneWidget);
      expect(find.byType(ErrorText), findsWidgets);
    });

    testWidgets('lock disposes the open wallet and asks for the PIN', (
      tester,
    ) async {
      final service = _existing();
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('Lock wallet'));
      expect(service.session.disposeCalls, 1);
      expect(find.text('Unlock wallet'), findsOneWidget);
    });

    testWidgets('a payment arriving over epicbox refreshes home and says so', (
      tester,
    ) async {
      _holdStill(tester);
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Epicbox, Connecting')),
        findsOneWidget,
      );

      session.listenerEvents.add(
        const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
      );
      await tester.pumpAndSettle();
      await tester.pump(statusSettle);
      expect(find.bySemanticsLabel(RegExp('^Epicbox, Online')), findsOneWidget);
      // Balances the node did not check count as the node being offline, and say why.
      expect(find.bySemanticsLabel(RegExp('^Node, Offline')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(nodeStatusKey).first).hint,
        startsWith('Not validated with node. Balances may be out of date.'),
      );

      session.summaryValue = FakeWalletSession.emptySummary;
      session.listenerEvents.add(
        ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 's',
          message: 'Received 3 EPIC from zz…',
          amount: _epic(3),
        ),
      );
      await tester.pumpAndSettle();
      // A notice in words, not the listener's raw message.
      expect(
        find.text('3 EPIC on the way. It completes when the sender finishes.'),
        findsOneWidget,
      );
      expect(find.text('Received 3 EPIC from zz…'), findsNothing);
      expect(tester.widget<Text>(find.byKey(balanceFigureKey)).data, '0');

      await _clearNotices(tester);
      await _tap(tester, find.byTooltip('Lock wallet'));
      expect(session.disposeCalls, 1);
    });

    testWidgets('a file shared from another app opens after unlock', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      const incoming = '{"id":"shared"}';
      service.slateInfos[incoming] = SlateInfo(
        slateId: 'shared',
        amount: _epic(2),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.text('Unlock wallet')),
      );
      container
          .read(incomingSlateProvider.notifier)
          .deliver(const SlateFile(name: 'shared.tx', json: incoming));
      await _unlockToHome(tester);
      await tester.pumpAndSettle();
      expect(find.text('Someone is sending you 2 EPIC.'), findsOneWidget);
    });
  });
}
