// SPDX-License-Identifier: Apache-2.0
// Runs against the real cores: epic-wallet for the core API and history tests, LEPIC for the
// PIN vault and the first run. Needs no node: the node URL points at a closed port.
//
// Never print the phrase or password; compare them only.
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart' show openAppSettings;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _unreachableNode = 'http://127.0.0.1:9';

Future<Directory> _tempDir(String name) async {
  final base = await getTemporaryDirectory();
  // macOS without the sandbox: path_provider names ~/Library/Caches/<bundle id> but does not
  // create it.
  await base.create(recursive: true);
  return base.createTemp('wfe-it-$name-');
}

WalletConfig _config(String dataDir) =>
    mainnetPreset.config(dataDir: dataDir, nodeUrl: _unreachableNode);

/// Pumps frames until [finder] matches, since native calls finish in real time.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      final shown = find
          .byType(RichText)
          .evaluate()
          .map((e) => (e.widget as RichText).text.toPlainText())
          .where((t) => t.trim().isNotEmpty)
          .join(' | ');
      fail(
        'Timed out after $timeout waiting for $finder; on screen: $shown; '
        'home: ${find.byType(HomeScreen).evaluate().isNotEmpty}',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
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

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initLepic();
    await openAppSettings(store: MemorySecretStore());
  });


  testWidgets('PIN vault through LEPIC: create, wrong PIN, phrase, change', (
    tester,
  ) async {
    final dir = await _tempDir('pin');
    addTearDown(() => dir.delete(recursive: true));
    final config = _config(dir.path);
    final lepic = LepicWalletService(secrets: MemorySecretStore());
    WalletError? failure(Object e) => e is WalletError ? e : null;

    final created = await lepic.createWithPin(config: config, pin: '123456');
    final sealed = created.sealedPassword;
    created.session.dispose();
    expect(await lepic.walletExists(config: config), isTrue);

    final wrong = await lepic
        .openWithPin(config: config, pin: '000000', sealedPassword: sealed)
        .then<Object>((s) => s, onError: (Object e) => e);
    expect(failure(wrong)?.kind, WalletErrorKind.wrongPassword);
    expect(await lepic.pinFailures(config: config), 1);

    var session = await lepic.openWithPin(
      config: config,
      pin: '123456',
      sealedPassword: sealed,
    );
    expect(await lepic.pinFailures(config: config), 0);
    final phrase = await session.mnemonicWithPin(
      pin: '123456',
      sealedPassword: sealed,
    );
    expect(phrase.split(' '), hasLength(24));

    final changed = await session.changePin(
      sealedPassword: sealed,
      oldPin: '123456',
      newPin: '654321',
    );
    expect(changed == sealed, isFalse);
    await session.confirmPinChange(sealedPassword: changed);
    session.dispose();

    final old = await lepic
        .openWithPin(config: config, pin: '123456', sealedPassword: sealed)
        .then<Object>((s) => s, onError: (Object e) => e);
    expect(failure(old)?.kind, WalletErrorKind.wrongPassword);
    session = await lepic.openWithPin(
      config: config,
      pin: '654321',
      sealedPassword: changed,
    );
    session.dispose();

    await lepic.deleteWallet(config: config);
    expect(await lepic.walletExists(config: config), isFalse);
  });

  // tools/build-apple.sh sets WFE_TEST_NO_KEYCHAIN: on macOS this store is the login keychain.
  testWidgets(
    'platform secure storage round-trips',
    skip: const bool.fromEnvironment('WFE_TEST_NO_KEYCHAIN'),
    (tester) async {
      const store = PlatformSecretStore();
      const key = 'integration-test.probe';
      await store.write(key, 'value');
      expect(await store.read(key), 'value');
      await store.delete(key);
      expect(await store.read(key), isNull);
    },
  );

  testWidgets('first run through the real core: PIN, then home', (
    tester,
  ) async {
    final dir = await _tempDir('ui');
    addTearDown(() => dir.delete(recursive: true));
    final store = MemorySecretStore();
    await store.write('app.node.mainnet', _unreachableNode);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletDirProvider.overrideWithValue((chain) async {
            final chainDir = Directory('${dir.path}/${chain.name}');
            await chainDir.create(recursive: true);
            return chainDir.path;
          }),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(
            MemoryBiometricStore(available: false),
          ),
          updatePlatformProvider.overrideWithValue(null),
        ],
        child: const WalletApp(),
      ),
    );

    // Welcome first: Create a new wallet opens the PIN setup.
    final create = find.text('Create a new wallet');
    await _pumpUntil(tester, create);
    await tester.tap(create);
    await tester.pump();
    await _pumpUntil(tester, find.widgetWithText(TextField, 'PIN'));
    await _enter(tester, 'PIN', '123456');
    await _pumpUntil(tester, find.widgetWithText(TextField, 'Repeat PIN'));
    await _enter(tester, 'Repeat PIN', '123456');

    await _pumpUntil(tester, find.byKey(balanceFigureKey));
    // Home's own notice: the PIN screen keeps a dock of its own, showing the same notice,
    // until its route's transition ends.
    expect(
      find.descendant(of: find.byType(HomeScreen), matching: find.text('Phrase not backed up')),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(await store.read('wallet.mainnet.pinSealed'), isNotNull);
    final session = container.read(sessionProvider)!;
    final phrase = await container
        .read(vaultProvider)
        .mnemonic(session, container.read(walletConfigProvider)!, '123456');
    expect(phrase.split(' '), hasLength(24));

    container.read(sessionProvider.notifier).lock();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
