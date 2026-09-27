// Runs against the real Rust core. Needs no node: the node URL points at a closed port.
//
// Never print the phrase or password; compare them only.
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
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
      fail('Timed out after $timeout waiting for $finder');
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());

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
  });

  testWidgets('UI create flow through the real core', (tester) async {
    final dir = await _tempDir('ui');
    addTearDown(() => dir.delete(recursive: true));

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletDirProvider.overrideWithValue((chain) async {
            final chainDir = Directory('${dir.path}/${chain.name}');
            await chainDir.create(recursive: true);
            return chainDir.path;
          }),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _enter(tester, 'Node URL', _unreachableNode);
    await _tap(tester, find.text('Continue'));
    await _pumpUntil(tester, find.text('Create a new wallet'));
    await _tap(tester, find.text('Create a new wallet'));
    await tester.pumpAndSettle();

    // Read the words the screen shows, as a user would copy them to paper.
    final words = <String>[];
    for (var i = 1; i <= 24; i++) {
      final label = find.textContaining(RegExp('^$i\\. '));
      await _pumpUntil(tester, label);
      words.add(tester.widget<Text>(label).data!.split(' ').last);
    }
    await _tap(tester, find.text('I have written them down'));
    await tester.pumpAndSettle();

    for (var i = 0; i < words.length; i++) {
      final field = find.byKey(ValueKey('confirm-word-$i'));
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field, words[i]);
      }
    }
    await _tap(tester, find.text('Confirm'));
    await tester.pumpAndSettle();

    await _enter(tester, 'Password', _password);
    await _enter(tester, 'Repeat password', _password);
    await _tap(tester, find.widgetWithText(FilledButton, 'Create wallet'));

    await _pumpUntil(tester, find.textContaining('@epicbox.epiccash.com'));
    await _pumpUntil(tester, find.text('Spendable'));
    await _reveal(tester, find.text('No transactions yet.'));
    expect(find.text('No transactions yet.'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final session = container.read(sessionProvider)!;
    final stored = await session.mnemonic(password: _password);
    expect(stored == words.join(' '), isTrue, reason: 'stored phrase differs');

    container.read(sessionProvider.notifier).lock();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
