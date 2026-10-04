// Runs against the real cores: epic-wallet for the core API and history tests, LEPIC for the
// PIN vault and the first run. Needs no node: the node URL points at a closed port.
//
// Never print the phrase or password; compare them only.
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/updater.dart';
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
    // The first-run and PIN tests run on LEPIC; only it has the PIN vault.
    await initLepic();
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
