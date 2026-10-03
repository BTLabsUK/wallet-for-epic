// Runs against the real Rust core. Needs no node: the node URL points at a closed port.
//
// Never print the phrase or password; compare them only.
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/core_backend.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _unreachableNode = 'http://127.0.0.1:9';
const _password = 'integration test password';

Future<Directory> _tempDir(String name) async {
  final base = await getTemporaryDirectory();
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
    await RustLib.init();
    // The first-run test goes through walletServiceProvider, so WFE_CORE=lepic runs it on LEPIC.
    if (coreBackend == CoreBackend.lepic) await initLepic();
  });

  const service = RustWalletService();

  testWidgets('core API: create, wrong password, open, address, phrase', (
    tester,
  ) async {
    final dir = await _tempDir('api');
    addTearDown(() => dir.delete(recursive: true));
    final config = _config(dir.path);

    final phrase = service.generateMnemonic(wordCount: 24);
    expect(phrase.split(' ').length, 24);
    expect(service.validateMnemonic(phrase: phrase), isTrue);
    expect(service.validateMnemonic(phrase: 'not a real phrase'), isFalse);

    expect(await service.walletExists(config: config), isFalse);
    final created = await service.create(
      config: config,
      mnemonic: phrase,
      password: _password,
    );
    created.dispose();
    expect(await service.walletExists(config: config), isTrue);

    await expectLater(
      service.open(config: config, password: 'wrong password'),
      throwsA(
        isA<WalletError>().having(
          (e) => e.kind,
          'kind',
          WalletErrorKind.wrongPassword,
        ),
      ),
    );

    final wallet = await service.open(config: config, password: _password);
    addTearDown(wallet.dispose);
    expect(await wallet.epicboxAddress(), endsWith('@epicbox.epiccash.com'));
    final stored = await wallet.mnemonic(password: _password);
    expect(stored == phrase, isTrue, reason: 'stored phrase differs');

    final summary = await wallet.summary(
      refresh: false,
      minimumConfirmations: minimumConfirmations,
    );
    expect(summary.total, BigInt.zero);
    expect(await wallet.transactions(refresh: false), isEmpty);

    // The node in _config is unreachable: the refresh still ends with the local balances.
    final steps = await wallet
        .refresh(minimumConfirmations: minimumConfirmations)
        .toList();
    expect(steps.last.percent, 100);
    expect(steps.last.summary?.validatedWithNode, isFalse);
  });

  testWidgets('history: contacts and an export that only the same seed opens', (
    tester,
  ) async {
    final dirA = await _tempDir('hist-a');
    final dirB = await _tempDir('hist-b');
    final dirC = await _tempDir('hist-c');
    addTearDown(() async {
      for (final d in [dirA, dirB, dirC]) {
        await d.delete(recursive: true);
      }
    });
    final phrase = service.generateMnemonic(wordCount: 24);

    final a = await service.create(
      config: _config(dirA.path),
      mnemonic: phrase,
      password: _password,
    );
    final saved = await a.saveContact(
      contact: const Contact(id: '', name: 'Bob', address: 'bob@relay.example'),
    );
    expect(saved.id, isNotEmpty);
    final file = await a.exportHistory();
    expect(String.fromCharCodes(file.take(4)), 'WFEH');
    a.dispose();

    final b = await service.create(
      config: _config(dirB.path),
      mnemonic: phrase,
      password: 'another password',
    );
    addTearDown(b.dispose);
    final report = await b.importHistory(data: file);
    expect(report.contactsAdded, 1);
    expect((await b.importHistory(data: file)).contactsAdded, 0);
    expect((await b.contacts()).single.name, 'Bob');

    final c = await service.create(
      config: _config(dirC.path),
      password: _password,
    );
    addTearDown(c.dispose);
    await expectLater(
      c.importHistory(data: file),
      throwsA(
        isA<WalletError>()
            .having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)
            .having((e) => e.message, 'message', contains('different wallet')),
      ),
    );
  });

  testWidgets('vault: seal and open through the real core', (tester) async {
    const crypto = RustVaultCrypto();
    final password = crypto.generatePassword();
    expect(password, hasLength(64));
    final sealed = await crypto.seal(pin: '123456', password: password);
    expect(sealed.contains(password), isFalse);
    expect(
      await crypto.open(pin: '123456', sealed: sealed) == password,
      isTrue,
    );
    await expectLater(
      crypto.open(pin: '654321', sealed: sealed),
      throwsA(
        isA<WalletError>().having(
          (e) => e.kind,
          'kind',
          WalletErrorKind.wrongPassword,
        ),
      ),
    );
  });

  testWidgets('platform secure storage round-trips', (tester) async {
    const store = PlatformSecretStore();
    const key = 'integration-test.probe';
    await store.write(key, 'value');
    expect(await store.read(key), 'value');
    await store.delete(key);
    expect(await store.read(key), isNull);
  });

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

    await _pumpUntil(tester, find.widgetWithText(TextField, 'PIN'));
    await _enter(tester, 'PIN', '123456');
    await _pumpUntil(tester, find.widgetWithText(TextField, 'Repeat PIN'));
    await _enter(tester, 'Repeat PIN', '123456');

    await _pumpUntil(tester, find.text('Spendable'));
    expect(find.text('Back up your recovery phrase.'), findsOneWidget);
    expect(await store.read('wallet.mainnet.pending'), isNull);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final password = await container
        .read(vaultProvider)
        .unlockWithPin(Chain.mainnet, '123456');
    final session = container.read(sessionProvider)!;
    final phrase = await session.mnemonic(password: password);
    expect(phrase.split(' '), hasLength(24));

    container.read(sessionProvider.notifier).lock();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
