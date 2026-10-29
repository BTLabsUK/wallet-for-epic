// SPDX-License-Identifier: Apache-2.0
// Remember on this computer: the sealed password, its expiry and every forget rule, on
// RememberedPasswords with an injected clock, and through LepicDeskWallet over the fake core.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/remember.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';

/// The OS store, which can stop answering for the remembered keys (a locked keyring, a slow
/// D-Bus).
class _Store extends MemorySecretStore {
  bool readFails = false;
  bool writeFails = false;

  @override
  Future<String?> read(String key) => readFails && key.startsWith('desk.remember') ? Future.error(StateError('keyring locked')) : super.read(key);

  @override
  Future<void> write(String key, String value) => writeFails && key.startsWith('desk.remember') ? Future.error(StateError('keyring locked')) : super.write(key, value);
}

void main() {
  group('Unlock', unlockScreenTests);

  late Directory support;
  late _Store secrets;
  var now = DateTime(2026, 10, 22, 12);

  setUp(() async {
    support = await Directory.systemTemp.createTemp('desk-remember-test-');
    secrets = _Store();
    now = DateTime(2026, 10, 22, 12);
  });

  tearDown(() => support.delete(recursive: true));

  Directory dir() => Directory('${support.path}/remember');
  RememberedPasswords make() => RememberedPasswords(secrets: secrets, dir: () async => dir(), now: () => now);
  List<File> files() => dir().existsSync() ? dir().listSync().whereType<File>().toList() : [];

  group('RememberedPasswords', () {
    test('seals the password: the file never holds it, the key is only in the OS store', () async {
      final r = make();
      expect(await r.remember('w1', _password), isTrue);
      expect(files(), hasLength(1));
      expect(files().single.readAsStringSync(), isNot(contains(_password)));
      expect(secrets.values.keys, ['desk.remember.w1']);
      expect(await r.recall('w1'), _password);
      expect(await r.isRemembered('w1'), isTrue);
      expect(await r.isRemembered('w2'), isFalse);
    });

    test('expires after 30 days', () async {
      final r = make();
      await r.remember('w1', _password);
      now = now.add(const Duration(days: 29, hours: 23));
      expect(await r.recall('w1'), _password);
      now = now.add(const Duration(hours: 2));
      expect(await r.isRemembered('w1'), isFalse);
      expect(await r.recall('w1'), isNull);
      expect(files(), isEmpty);
      expect(secrets.values, isEmpty);
    });

    test('a longer expiry written into the file breaks the seal', () async {
      final r = make();
      await r.remember('w1', _password);
      final f = files().single;
      f.writeAsStringSync(f.readAsStringSync().replaceFirst(RegExp(r'"until":\d+'), '"until":${now.add(const Duration(days: 365)).millisecondsSinceEpoch}'));
      expect(await r.recall('w1'), isNull);
      expect(files(), isEmpty);
    });

    test('either half missing opens nothing', () async {
      final r = make();
      await r.remember('w1', _password);
      await secrets.delete('desk.remember.w1');
      expect(await r.recall('w1'), isNull);
    });

    test('forgotten after 5 wrong passwords in a row; a right one starts the count again', () async {
      final r = make();
      await r.remember('w1', _password);
      for (var i = 0; i < 4; i++) {
        await r.failed('w1');
      }
      await r.succeeded('w1');
      for (var i = 0; i < 4; i++) {
        await r.failed('w1');
      }
      expect(await r.isRemembered('w1'), isTrue);
      await r.failed('w1');
      expect(await r.isRemembered('w1'), isFalse);
      expect(secrets.values, isEmpty);
    });

    test('an OS store that does not answer keeps the seal for the next try', () async {
      final r = make();
      await r.remember('w1', _password);
      secrets.readFails = true;
      await expectLater(r.recall('w1'), throwsA(isA<RememberUnavailable>()));
      expect(await r.isRemembered('w1'), isTrue);
      expect(files(), hasLength(1));
      secrets.readFails = false;
      expect(await r.recall('w1'), _password);
    });

    test('kept again while valid, it keeps the expiry of when it was set', () async {
      final r = make();
      await r.remember('w1', _password);
      now = now.add(const Duration(days: 20));
      expect(await r.remember('w1', _password), isTrue);
      now = now.add(const Duration(days: 9, hours: 23));
      expect(await r.recall('w1'), _password);
      now = now.add(const Duration(hours: 2));
      expect(await r.recall('w1'), isNull);
      // Expired, kept again: 30 days from now.
      expect(await r.remember('w1', _password), isTrue);
      now = now.add(const Duration(days: 29));
      expect(await r.recall('w1'), _password);
    });

    test('Forget this computer removes both halves', () async {
      final r = make();
      await r.remember('w1', _password);
      await r.remember('w2', _password);
      await r.forget('w1');
      expect(await r.isRemembered('w1'), isFalse);
      expect(await r.recall('w2'), _password);
      expect(secrets.values.keys, ['desk.remember.w2']);
    });
  });

  group('LepicDeskWallet', () {
    late core.FakeWalletService service;
    late LepicDeskWallet wallet;
    late String id;

    setUp(() async {
      service = core.FakeWalletService(password: _password);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final d = Directory(WalletRegistry.firstWalletDir(support.path, chain));
          await d.create(recursive: true);
          return d.path;
        },
        secrets: secrets,
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        rememberDir: () async => dir(),
        now: () => now,
      );
      await wallet.createWallet(name: 'Main', password: _password);
      id = (await wallet.wallets()).single.id;
    });

    tearDown(() => wallet.dispose());

    test('Remember keeps it; the next start opens without the password; off forgets', () async {
      expect(await wallet.unlockRemembered(), isFalse);
      expect(await wallet.unlock(_password, remember: true), isTrue);
      expect(await wallet.isRemembered(id), isTrue);
      await wallet.lock();
      expect(await wallet.unlockRemembered(), isTrue);
      expect((await wallet.account()).id, id);
      await wallet.lock();
      expect(await wallet.unlock(_password), isTrue);
      expect(await wallet.isRemembered(id), isFalse);
    });

    test('the remembered password does not extend its own expiry', () async {
      await wallet.unlock(_password, remember: true);
      now = now.add(const Duration(days: 20));
      expect(await wallet.unlockRemembered(), isTrue);
      now = now.add(const Duration(days: 11));
      expect(await wallet.unlockRemembered(), isFalse);
    });

    test('unlocking with the box ticked again keeps the first expiry', () async {
      await wallet.unlock(_password, remember: true);
      now = now.add(const Duration(days: 20));
      await wallet.lock();
      expect(await wallet.unlock(_password, remember: true), isTrue);
      now = now.add(const Duration(days: 11));
      expect(await wallet.isRemembered(id), isFalse);
    });

    test('a key store that refuses: the wallet opens, not remembered, and says so', () async {
      secrets.writeFails = true;
      expect(await wallet.unlock(_password, remember: true), isTrue);
      expect(wallet.notRemembered, isTrue);
      expect(await wallet.isRemembered(id), isFalse);
      secrets.writeFails = false;
      await wallet.lock();
      expect(await wallet.unlock(_password, remember: true), isTrue);
      expect(wallet.notRemembered, isFalse);
    });

    test('a key store that does not answer: unavailable, still remembered', () async {
      await wallet.unlock(_password, remember: true);
      await wallet.lock();
      secrets.readFails = true;
      await expectLater(wallet.unlockRemembered(), throwsA(isA<RememberUnavailable>()));
      secrets.readFails = false;
      expect(await wallet.isRemembered(id), isTrue);
      expect(await wallet.unlockRemembered(), isTrue);
    });

    test('opened with the remembered password, it says so; the password checks', () async {
      await wallet.unlock(_password, remember: true);
      expect(wallet.openedRemembered, isFalse);
      expect(await wallet.checkPassword(_password), isTrue);
      await wallet.lock();
      expect(await wallet.unlockRemembered(), isTrue);
      expect(wallet.openedRemembered, isTrue);
      await wallet.lock();
      expect(wallet.openedRemembered, isFalse);
    });

    test('Remove from list forgets it', () async {
      await wallet.unlock(_password, remember: true);
      await wallet.removeWallet(id, WalletRemoval.list);
      expect(await wallet.isRemembered(id), isFalse);
      expect(secrets.values.keys.where((k) => k.startsWith('desk.remember')), isEmpty);
    });

    test('5 wrong passwords forget it', () async {
      await wallet.unlock(_password, remember: true);
      await wallet.lock();
      for (var i = 0; i < 5; i++) {
        expect(await wallet.unlock('wrong-password'), isFalse);
      }
      expect(await wallet.isRemembered(id), isFalse);
      expect(await wallet.unlockRemembered(), isFalse);
    });

    test('Forget this computer and Delete wallet forget it', () async {
      await wallet.unlock(_password, remember: true);
      await wallet.forgetRemembered(id);
      expect(await wallet.isRemembered(id), isFalse);
      await wallet.unlock(_password, remember: true);
      await wallet.removeWallet(id, WalletRemoval.delete, password: _password);
      expect(await wallet.isRemembered(id), isFalse);
      expect(secrets.values.keys.where((k) => k.startsWith('desk.remember')), isEmpty);
    });
  });
}

/// The mock, with the remembered password unreadable or the wallet list failing once.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: const Duration(milliseconds: 5));

  bool storeSilent = false;
  int listFails = 0;

  @override
  Future<List<WalletEntry>> wallets() async {
    if (listFails > 0) {
      listFails--;
      throw const DeskError('Wallet list not readable');
    }
    return super.wallets();
  }

  @override
  Future<bool> unlockRemembered() async {
    if (storeSilent && await isRemembered('')) throw const RememberUnavailable();
    return super.unlockRemembered();
  }
}

/// The Unlock screen on the mock: the checkbox and its tooltip, and the open at start.
void unlockScreenTests() {
  final containers = <ProviderContainer>[];
  Future<ProviderContainer> pump(WidgetTester tester, MockDeskWallet api) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    containers.add(container);
    container.read(deskNavProvider.notifier).reset(DeskRoute.unlock);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: UnlockScreen())),
    ));
    return container;
  }

  Future<void> run(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (final c in containers) {
      c.dispose();
    }
    containers.clear();
    await tester.pump(const Duration(minutes: 5));
  }

  Future<void> rememberOnce(WidgetTester tester, MockDeskWallet api) async {
    await tester.runAsync(() async {
      await api.unlock('secret-pass', remember: true);
      await api.lock();
    });
  }

  testWidgets('a key store that refuses: the wallet opens and a toast says it was not remembered', (tester) async {
    rememberAutoTried = true;
    final api = _Wallet()..storeRefuses = true;
    final container = await pump(tester, api);
    await run(tester);
    await tester.enterText(find.byType(TextField), 'secret-pass');
    await tester.tap(find.text('Remember on this computer'));
    await tester.tap(find.widgetWithText(EButton, 'Unlock'));
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
    expect(find.text('Not remembered'), findsOneWidget);
    expect(find.text('This computer’s key store is unavailable.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a key store that does not answer at start: the form asks, the wallet stays remembered', (tester) async {
    final api = _Wallet()..storeSilent = true;
    await rememberOnce(tester, api);
    rememberAutoTried = false;
    final container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    expect(find.text('Remembered password unavailable. Enter the password.'), findsOneWidget);
    expect(await tester.runAsync(() => api.isRemembered('')), isTrue);
    expect(tester.widget<ECheckbox>(find.widgetWithText(ECheckbox, 'Remember on this computer')).value, isTrue);
    await done(tester);
  });

  testWidgets('the wrong password that forgets the remembered one unticks the box', (tester) async {
    final api = _Wallet();
    await rememberOnce(tester, api);
    // All but the last allowed wrong password, straight to the wallet.
    await tester.runAsync(() async {
      for (var i = 0; i < maxRememberFails - 1; i++) {
        await api.unlock('wrong');
      }
    });
    expect(await tester.runAsync(() => api.isRemembered('')), isTrue);
    rememberAutoTried = true;
    await pump(tester, api);
    await run(tester);
    ECheckbox box() => tester.widget<ECheckbox>(find.widgetWithText(ECheckbox, 'Remember on this computer'));
    expect(box().value, isTrue, reason: 'a remembered wallet shows the box ticked');
    await tester.enterText(find.byType(EditableText).first, 'wrong');
    await tester.tap(find.widgetWithText(EButton, 'Unlock'));
    for (var w = 0; w < 30 && find.widgetWithText(EButton, 'Unlock').evaluate().isEmpty; w++) {
      await run(tester);
    }
    await run(tester);
    expect(await tester.runAsync(() => api.isRemembered('')), isFalse);
    expect(box().value, isFalse, reason: 'the next right password must not remember it again unasked');
    await done(tester);
  });

  testWidgets('the open at start is tried on the first load only, even when that load failed', (tester) async {
    final api = _Wallet()..listFails = 1;
    await rememberOnce(tester, api);
    rememberAutoTried = false;
    var container = await pump(tester, api);
    await run(tester);
    expect(find.text('Wallet list not readable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    await done(tester);
  });

  testWidgets('off by default, with the truth in its tooltip; ticked, the next start opens by itself', (tester) async {
    rememberAutoTried = false;
    final api = MockDeskWallet(delay: const Duration(milliseconds: 5));
    var container = await pump(tester, api);
    await run(tester);
    final box = tester.widget<ECheckbox>(find.widgetWithText(ECheckbox, 'Remember on this computer'));
    expect(box.value, isFalse);
    expect(find.byTooltip(rememberWho(englishStrings)), findsOneWidget);
    expect(rememberWho(englishStrings), contains('can open this wallet'));
    await tester.enterText(find.byType(TextField), 'secret-pass');
    await tester.tap(find.text('Remember on this computer'));
    await tester.pump();
    expect(find.text('For 30 days. ${rememberWho(englishStrings)}'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'Unlock'));
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);

    // A new start of the app, same computer.
    await tester.pumpWidget(const SizedBox());
    rememberAutoTried = false;
    container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);

    // After a Lock, Unlock asks.
    await tester.pumpWidget(const SizedBox());
    container = await pump(tester, api);
    await run(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.unlock);
    expect(tester.widget<ECheckbox>(find.widgetWithText(ECheckbox, 'Remember on this computer')).value, isTrue);
    await tester.pumpWidget(const SizedBox());
    for (final c in containers) {
      c.dispose();
    }
    await tester.pump(const Duration(minutes: 5));
  });
}
