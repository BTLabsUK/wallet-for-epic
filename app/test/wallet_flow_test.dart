import 'dart:async';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mainnetDir = '/fake/wallets/mainnet';
const _password = 'correct horse';
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

/// Everything the app keeps outside the wallet, in memory.
class _Device {
  _Device({bool biometrics = false, this.sealedMainnet = false})
    : bio = MemoryBiometricStore(available: biometrics) {
    if (sealedMainnet) {
      store.values['wallet.mainnet.sealed'] = 'sealed|$_pin|$_password';
    }
  }

  final bool sealedMainnet;
  final store = MemorySecretStore();
  final MemoryBiometricStore bio;
  final crypto = FakeVaultCrypto();
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
        walletServiceProvider.overrideWithValue(service),
        walletDirProvider.overrideWithValue(
          (chain) async => '/fake/wallets/${chain.name}',
        ),
        secretStoreProvider.overrideWithValue(device.store),
        biometricStoreProvider.overrideWithValue(device.bio),
        vaultCryptoProvider.overrideWithValue(device.crypto),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_FakeRelays()),
        slateFilesProvider.overrideWithValue(device.files),
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
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
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
  expect(find.text('Unlock Mainnet wallet'), findsOneWidget);
  await _enter(tester, 'PIN', _pin);
}

FakeWalletService _existing({FakeWalletSession? session}) =>
    FakeWalletService(existingWallets: {_mainnetDir}, session: session);

FakeWalletSession _fundedSession() => FakeWalletSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2499990),
    minimumConfirmations: BigInt.from(10),
    total: _epic(16),
    spendable: _epic(12.5),
    awaitingConfirmation: _epic(1),
    awaitingFinalization: BigInt.zero,
    immature: _epic(0.5),
    locked: _epic(2),
    validatedWithNode: false,
  ),
  transactions: [
    TxEntry(
      id: 2,
      slateId: 'b',
      kind: TxKind.sent,
      createdAtUnix: 1790000100,
      confirmed: false,
      amountCredited: _epic(3.992),
      amountDebited: _epic(5),
      fee: _epic(0.008),
      numInputs: 1,
      numOutputs: 1,
    ),
    TxEntry(
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
      'creates the wallet while the user picks a PIN and biometrics',
      (tester) async {
        final service = FakeWalletService()..createGate = Completer<void>();
        final device = _Device(biometrics: true);
        await _pumpApp(tester, service, device, settle: false);

        expect(find.text('Welcome (Mainnet)'), findsOneWidget);
        expect(find.text('Creating wallet…'), findsOneWidget);
        // The password exists before the wallet does, so an interrupted run can resume.
        expect(device.store.values['wallet.mainnet.pending'], isNotNull);

        await _enterNow(tester, 'PIN', _pin);
        await _enterNow(tester, 'Repeat PIN', '654321');
        expect(find.textContaining('do not match'), findsOneWidget);

        await _enterNow(tester, 'PIN', _pin);
        await _enterNow(tester, 'Repeat PIN', _pin);
        expect(find.text('Unlock with fingerprint or face?'), findsOneWidget);
        await tester.tap(find.text('Use biometrics'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Finishing your wallet…'), findsOneWidget);
        expect(find.text('Spendable'), findsNothing);

        service.createGate!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Spendable'), findsOneWidget);
        expect(find.text('Back up your wallet'), findsOneWidget);

        expect(service.createdConfig?.chain, Chain.mainnet);
        expect(service.createdConfig?.dataDir, _mainnetDir);
        expect(service.createdMnemonic, isNull);
        expect(service.password, 'generated-password-0');
        expect(device.store.values['wallet.mainnet.pending'], isNull);
        expect(
          device.store.values['wallet.mainnet.sealed'],
          'sealed|$_pin|generated-password-0',
        );
        expect(
          device.bio.values['wallet.mainnet.password'],
          'generated-password-0',
        );
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
      expect(find.text('Spendable'), findsOneWidget);
      expect(device.bio.values, isEmpty);
      expect(device.store.values['wallet.mainnet.biometrics'], isNull);
    });

    testWidgets('an interrupted first run reopens the same wallet', (
      tester,
    ) async {
      final service = FakeWalletService(
        existingWallets: {_mainnetDir},
        password: 'kept-password',
      );
      final device = _Device();
      device.store.values['wallet.mainnet.pending'] = 'kept-password';
      await _pumpApp(tester, service, device);

      expect(find.text('Wallet created'), findsOneWidget);
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      expect(find.text('Spendable'), findsOneWidget);
      expect(service.createdConfig, isNull);
      expect(
        device.store.values['wallet.mainnet.sealed'],
        'sealed|$_pin|kept-password',
      );
    });

    testWidgets('restore replaces the wallet made in the background', (
      tester,
    ) async {
      final service = FakeWalletService();
      final device = _Device();
      await _pumpApp(tester, service, device);
      await _tapText(tester, 'I already have a wallet: restore it');
      expect(service.existingWallets, contains(_mainnetDir));

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
      await _enter(tester, 'Start height (optional)', '1000');
      await _tapText(tester, 'Continue');
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);

      expect(service.deletedWallets, [_mainnetDir]);
      expect(service.createdMnemonic == service.phrase, isTrue);
      expect(service.session.scanCalls, 1);
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Back up your wallet'), findsNothing);
      expect(
        device.store.values['wallet.mainnet.sealed'],
        startsWith('sealed|$_pin|'),
      );
    });

    testWidgets('network settings switch the first run to usernet', (
      tester,
    ) async {
      final service = FakeWalletService();
      await _pumpApp(tester, service, _Device());
      await _tap(tester, find.byTooltip('Network settings'));
      await _tapText(tester, 'Usernet');
      final urlField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Node URL'),
      );
      expect(urlField.controller!.text, 'http://127.0.0.1:23413');
      await _tapText(tester, 'Save');

      expect(find.text('Welcome (Usernet)'), findsOneWidget);
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      expect(find.text('Spendable'), findsOneWidget);
      expect(service.createdConfig?.chain, Chain.usernet);
      expect(service.createdConfig?.epicboxPort, 3423);
      // The mainnet wallet created first was closed, so usernet could open.
      expect(service.session.disposeCalls, greaterThanOrEqualTo(1));
    });
  });

  testWidgets('network settings pick a mainnet relay from the monitor', (
    tester,
  ) async {
    final service = FakeWalletService();
    final device = _Device();
    await _pumpApp(tester, service, device);
    await _tap(tester, find.byTooltip('Network settings'));

    expect(find.text('epicbox.epicnet.us'), findsOneWidget);
    expect(find.textContaining('Up · epicnet.us · official'), findsOneWidget);
    expect(find.textContaining('changes your epicbox address'), findsNothing);
    await _tapText(tester, 'epicbox.epicnet.us');
    expect(find.textContaining('changes your epicbox address'), findsOneWidget);

    await _enter(tester, 'Other relay (host or host:port)', 'not a host!');
    await _tap(tester, find.byTooltip('Use this relay'));
    expect(find.textContaining('Enter a host'), findsOneWidget);
    await _enter(
      tester,
      'Other relay (host or host:port)',
      'relay.example.org:8443',
    );
    await _tap(tester, find.byTooltip('Use this relay'));
    expect(find.text('relay.example.org:8443'), findsOneWidget);
    expect(find.text('Not monitored'), findsOneWidget);

    await _tapText(tester, 'epicbox.epicnet.us');
    await _tapText(tester, 'Save');
    expect(device.store.values['app.relay.mainnet'], 'epicbox.epicnet.us');
    await _enter(tester, 'PIN', _pin);
    await _enter(tester, 'Repeat PIN', _pin);
    // The wallet made before the change is reopened; the relay comes from the config it opens
    // with, which is what the address and the listener use.
    final container = ProviderScope.containerOf(
      tester.element(find.text('Spendable')),
    );
    final config = container.read(walletConfigProvider)!;
    expect(config.epicboxDomain, 'epicbox.epicnet.us');
    expect(config.epicboxPort, 443);
  });

  group('unlock', () {
    testWidgets('a wrong PIN counts down, then locks out', (tester) async {
      final service = _existing();
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);

      await _enter(tester, 'PIN', '000000');
      expect(
        find.text('Wrong PIN. 4 tries left before a pause.'),
        findsOneWidget,
      );
      expect(find.text('Spendable'), findsNothing);
      for (var i = 0; i < 4; i++) {
        await _enter(tester, 'PIN', '000000');
      }
      expect(find.textContaining('Too many wrong PINs'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'PIN'),
      );
      expect(field.enabled, isFalse);
    });

    testWidgets('the right PIN opens the wallet', (tester) async {
      final service = _existing();
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      expect(find.text('Spendable'), findsOneWidget);
    });

    testWidgets('biometrics unlock on start when enabled', (tester) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      device.store.values['wallet.mainnet.biometrics'] = '1';
      device.bio.values['wallet.mainnet.password'] = _password;
      await _pumpApp(tester, service, device);
      expect(device.bio.prompts, 1);
      expect(find.text('Spendable'), findsOneWidget);
    });

    testWidgets('a dismissed biometric prompt leaves the PIN', (tester) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      device.store.values['wallet.mainnet.biometrics'] = '1';
      device.bio.values['wallet.mainnet.password'] = _password;
      device.bio.succeed = false;
      await _pumpApp(tester, service, device);
      expect(find.text('Spendable'), findsNothing);
      expect(find.text('Use biometrics'), findsOneWidget);
      await _unlockToHome(tester);
      expect(find.text('Spendable'), findsOneWidget);
    });

    testWidgets('a password wallet from before PINs moves to a PIN', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device();
      await _pumpApp(tester, service, device);
      expect(find.text('Unlock Mainnet wallet'), findsOneWidget);

      await _enter(tester, 'Password', 'guess');
      await _tapText(tester, 'Unlock');
      expect(find.text('Wrong password.'), findsOneWidget);

      await _enter(tester, 'Password', _password);
      await _tapText(tester, 'Unlock');
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      expect(find.text('Spendable'), findsOneWidget);
      expect(
        device.store.values['wallet.mainnet.sealed'],
        'sealed|$_pin|$_password',
      );
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
      expect(device.store.values['wallet.mainnet.sealed'], isNull);
      expect(find.text('Welcome (Mainnet)'), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('renders balances, node tip, address and transactions', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      expect(find.text('12.5 EPIC'), findsOneWidget);
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      expect(find.text('1 EPIC'), findsOneWidget);
      expect(find.text('2 EPIC'), findsOneWidget);
      expect(find.text('0.5 EPIC'), findsOneWidget);
      expect(find.textContaining('Not validated with node'), findsOneWidget);
      expect(find.text('Node tip height: 2500000'), findsOneWidget);
      expect(find.text(session.address), findsOneWidget);
      expect(find.byTooltip('Copy address'), findsOneWidget);

      await _reveal(tester, find.text('Received  +5 EPIC'));
      expect(find.text('Received  +5 EPIC'), findsOneWidget);
      expect(find.text('Sent  -1 EPIC'), findsOneWidget);
      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.textContaining('Confirmed'), findsOneWidget);
      expect(find.textContaining('Fee 0.008 EPIC'), findsOneWidget);

      await _tap(tester, find.byTooltip('Show QR code'));
      expect(
        find.bySemanticsLabel('QR code of the epicbox address'),
        findsOneWidget,
      );
      await _tapText(tester, 'Close');

      // Only the unconfirmed send can be cancelled, after confirming.
      expect(find.byTooltip('Cancel transaction'), findsOneWidget);
      await _tap(tester, find.byTooltip('Cancel transaction'));
      await _tapText(tester, 'Keep');
      expect(session.cancelledTxIds, isEmpty);
      await _tap(tester, find.byTooltip('Cancel transaction'));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Cancel transaction'),
      );
      expect(session.cancelledTxIds, [2]);
    });

    testWidgets('backup asks for the PIN, shows the phrase, checks words', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _unlockToHome(tester);

      await tester.tap(find.text('Back up now'));
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
      await _tapText(tester, 'I have written them down');
      final fields = <int>[
        for (var i = 0; i < words.length; i++)
          if (find.byKey(ValueKey('confirm-word-$i')).evaluate().isNotEmpty) i,
      ];
      expect(fields, hasLength(3));
      for (final i in fields) {
        await tester.enterText(
          find.byKey(ValueKey('confirm-word-$i')),
          'wrong',
        );
      }
      await _tapText(tester, 'Confirm');
      expect(find.textContaining('do not match'), findsOneWidget);
      for (final i in fields) {
        await tester.enterText(
          find.byKey(ValueKey('confirm-word-$i')),
          words[i],
        );
      }
      await _tapText(tester, 'Confirm');

      expect(find.text('Recovery phrase confirmed'), findsOneWidget);
      expect(find.text('Back up your wallet'), findsNothing);
      expect(device.store.values['wallet.mainnet.backedUp'], '1');
    });

    testWidgets('biometric unlock can be turned on from the menu', (
      tester,
    ) async {
      final service = _existing();
      final device = _Device(biometrics: true, sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('More'));
      await _tapText(tester, 'Turn on biometric unlock');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        _pin,
      );
      await tester.pumpAndSettle();
      expect(device.bio.values['wallet.mainnet.password'], _password);
      expect(find.text('Biometric unlock turned on'), findsOneWidget);
    });

    testWidgets('full rescan streams progress', (tester) async {
      final service = _existing();
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('More'));
      await _tapText(tester, 'Full rescan');
      await _tapText(tester, 'Rescan');
      expect(service.session.scanCalls, 1);
      expect(find.text('Spendable'), findsOneWidget);
    });

    testWidgets('a failed scan shows the core message as an error', (
      tester,
    ) async {
      final service = _existing();
      service.session.scanEvents = const [
        ScanProgress(percent: 10, message: 'Scanning', finished: false),
        ScanProgress(message: 'Scan failed: node unreachable', finished: true),
      ];
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('More'));
      await _tapText(tester, 'Full rescan');
      await _tapText(tester, 'Rescan');
      expect(find.text('Scan failed: node unreachable'), findsOneWidget);
      expect(find.byType(ErrorText), findsWidgets);
    });

    testWidgets('lock disposes the open wallet and asks for the PIN', (
      tester,
    ) async {
      final service = _existing();
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);

      await _tap(tester, find.byTooltip('More'));
      await _tapText(tester, 'Lock wallet');
      expect(service.session.disposeCalls, 1);
      expect(find.text('Unlock Mainnet wallet'), findsOneWidget);
    });

    testWidgets('send by file: share .tx, open .response, finalize', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _unlockToHome(tester);
      await _tapText(tester, 'Send');
      await _tapText(tester, 'File');

      expect(find.textContaining('Sending takes two steps'), findsOneWidget);

      await _enter(tester, 'Amount (EPIC)', '100');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);

      await _enter(tester, 'Amount (EPIC)', '1.123456789');
      expect(find.text('At most 8 decimal places'), findsOneWidget);

      await _enter(tester, 'Amount (EPIC)', '1.5');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Fee: 0.008 EPIC. Total: 1.508 EPIC.'), findsOneWidget);

      await _tapText(tester, 'Create transaction file');
      expect(session.sentAmounts, [_epic(1.5)]);
      final files = device.files;
      expect(files.exported.single.name, 'slate-1.tx');
      expect(files.exported.single.json, session.sendSlate.json);

      // A response for another transaction is refused before anything is signed.
      files.picks.add(
        const SlateFile(name: 'other.tx.response', json: '{"other":1}'),
      );
      service.slateInfos['{"other":1}'] = SlateInfo(
        slateId: 'other',
        amount: _epic(9),
        fee: BigInt.one,
        stage: SlateStage.response,
      );
      await _tapText(tester, 'Open response file');
      expect(
        find.textContaining('for a different transaction'),
        findsOneWidget,
      );
      expect(find.text('Finalize and post'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      files.picks.add(
        SlateFile(
          name: 'slate-1.tx.response',
          json: session.responseSlate.json,
        ),
      );
      service.slateInfos[session.responseSlate.json] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1.5),
        fee: session.fee,
        stage: SlateStage.response,
      );
      await _tapText(tester, 'Open response file');
      expect(
        find.textContaining("answer to your send of 1.5 EPIC"),
        findsOneWidget,
      );
      await _tapText(tester, 'Finalize and post');
      expect(session.finalizedSlates, [session.responseSlate.json]);
      expect(find.text('Transaction of 1.5 EPIC posted.'), findsOneWidget);

      await _tapText(tester, 'Done');
      expect(find.text('Spendable'), findsOneWidget);
    });

    testWidgets(
      'send over epicbox checks the address and waits for the relay',
      (tester) async {
        final session = _fundedSession();
        final service = _existing(session: session);
        await _pumpApp(tester, service, _Device(sealedMainnet: true));
        await _unlockToHome(tester);
        expect(session.listenerStarts, 1);
        await _tapText(tester, 'Send');

        expect(
          find.textContaining('Not connected to the relay yet'),
          findsOneWidget,
        );
        session.listenerEvents.add(
          const ListenerEvent(
            kind: ListenerEventKind.connected,
            message: 'addr@epicbox.epiccash.com',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Not connected to the relay yet'),
          findsNothing,
        );

        await _enter(tester, 'Recipient epicbox address', 'esBare');
        await _enter(tester, 'Amount (EPIC)', '1.5');
        await tester.pump(const Duration(milliseconds: 500));
        await _tap(tester, find.widgetWithText(FilledButton, 'Send'));
        expect(
          find.textContaining('Enter a full epicbox address'),
          findsOneWidget,
        );
        expect(session.epicboxSends, isEmpty);

        final to = '${'a' * 52}@epicbox.epiccash.com';
        await _enter(tester, 'Recipient epicbox address', to);
        await _tap(tester, find.widgetWithText(FilledButton, 'Send'));
        expect(session.epicboxSends.single.to, to);
        expect(session.epicboxSends.single.amount, _epic(1.5));
        expect(find.text('1.5 EPIC sent to the relay.'), findsOneWidget);
      },
    );

    testWidgets('send over HTTP posts at once, and shows transport errors', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      await _tapText(tester, 'Send');
      await _tapText(tester, 'HTTP');

      await _enter(tester, 'Recipient wallet URL', '203.0.113.5:3415');
      await _enter(tester, 'Amount (EPIC)', '2');
      await tester.pump(const Duration(milliseconds: 500));
      await _tap(tester, find.widgetWithText(FilledButton, 'Send'));
      expect(find.textContaining('Enter the full address'), findsOneWidget);

      session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'the recipient did not answer',
      );
      await _enter(tester, 'Recipient wallet URL', 'http://203.0.113.5:3415');
      await _tap(tester, find.widgetWithText(FilledButton, 'Send'));
      expect(
        find.textContaining('Could not reach the recipient'),
        findsOneWidget,
      );

      session.sendError = null;
      await _tap(tester, find.widgetWithText(FilledButton, 'Send'));
      expect(session.httpSends.single.to, 'http://203.0.113.5:3415');
      expect(find.text('Transaction of 2 EPIC posted.'), findsOneWidget);
    });

    testWidgets('a payment arriving over epicbox refreshes home and says so', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      expect(
        find.textContaining('Epicbox address · connecting'),
        findsOneWidget,
      );

      session.listenerEvents.add(
        const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Epicbox address · listening'),
        findsOneWidget,
      );

      session.summaryValue = FakeWalletSession.emptySummary;
      session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.received,
          slateId: 's',
          message: 'Received 3 EPIC from zz…',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Received 3 EPIC from zz…'), findsOneWidget);
      expect(find.text('0 EPIC'), findsWidgets);

      await _tap(tester, find.byTooltip('More'));
      await _tapText(tester, 'Lock wallet');
      expect(session.disposeCalls, 1);
    });

    testWidgets('receive by file: open .tx, sign, share .response', (
      tester,
    ) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      final device = _Device(sealedMainnet: true);
      await _pumpApp(tester, service, device);
      await _unlockToHome(tester);
      await _tapText(tester, 'Receive');
      expect(find.text(session.address), findsOneWidget);
      expect(find.textContaining('arrive by themselves'), findsOneWidget);

      device.files.picks.add(const SlateFile(name: 'photo.jpg', json: 'nope'));
      await _tapText(tester, 'Open transaction file');
      expect(find.text('That file is not a transaction file.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      const incoming = '{"id":"incoming"}';
      service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: _epic(3),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      device.files.picks.add(
        const SlateFile(name: 'from-bob.tx', json: incoming),
      );
      await _tapText(tester, 'Open transaction file');
      expect(find.text('Someone is sending you 3 EPIC.'), findsOneWidget);
      await _tapText(tester, 'Sign and share response');
      expect(session.receivedSlates, [incoming]);
      expect(device.files.exported.single.name, 'from-bob.tx.response');
      expect(device.files.exported.single.json, session.responseSlate.json);
      expect(
        find.text('Signed. Return from-bob.tx.response to the sender.'),
        findsOneWidget,
      );
    });

    testWidgets('receive: paste slate text as a fallback', (tester) async {
      final session = _fundedSession();
      final service = _existing(session: session);
      await _pumpApp(tester, service, _Device(sealedMainnet: true));
      await _unlockToHome(tester);
      await _tapText(tester, 'Receive');
      await _tapText(tester, 'Paste slate text instead');

      await _tapText(tester, 'Sign slate');
      expect(find.text('Paste the slate you received.'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        '{"id":"incoming"}',
      );
      await _tapText(tester, 'Sign slate');
      expect(session.receivedSlates, ['{"id":"incoming"}']);
      expect(find.text(session.responseSlate.json), findsOneWidget);
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
        tester.element(find.text('Unlock Mainnet wallet')),
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
