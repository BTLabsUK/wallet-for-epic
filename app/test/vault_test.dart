// SPDX-License-Identifier: Apache-2.0
// The PIN vault: the PIN key and failure count under a Keystore key (pin_wrap.dart, WAL-03),
// its migration from an older app's plain entries, a lost Keystore key, the optional
// passphrase, and biometrics after a write (WAL-11).
//
// The first group runs everywhere. The second goes end to end through LEPIC (its PIN count,
// waits and sealing), offline, and needs the Linux library:
//
//   WFE_DEMO_LEPIC_LIB=.../liblepic_ffi.so flutter test test/vault_test.dart
import 'dart:io';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/pin_wrap.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

final String? _lib = Platform.environment['WFE_DEMO_LEPIC_LIB'];

const _id = 'lepic:mainnet:id-0123:';
const _key = '${_id}lepic.pin-key';
const _pending = '${_id}lepic.pin-key-pending';
const _failures = '${_id}lepic.pin-failures';

void main() {
  group('HardwarePinStore', () {
    late MemorySecretStore inner;
    late MemoryKeyWrap wrap;
    late HardwarePinStore store;

    setUp(() {
      inner = MemorySecretStore();
      wrap = MemoryKeyWrap();
      store = HardwarePinStore(inner, wrap, _id);
    });

    bool sealed(String key) => inner.values[key]?.startsWith('wfe-hw1:') ?? false;

    test('an older app\'s plain entries read as they are until the first count write', () async {
      inner.values[_key] = 'plain-key';
      inner.values['${_id}other'] = 'kept';
      expect(await store.read(_key), 'plain-key');
      expect(await store.read(_failures), isNull);
      expect(await store.isSealed(), isFalse);
      expect(wrap.created, 0);

      // LEPIC counts an attempt before it tries the PIN: that write seals every PIN entry.
      await store.write(_failures, '1');
      expect(sealed(_key), isTrue);
      expect(sealed(_failures), isTrue);
      expect(inner.values[_key], isNot(contains('plain-key')));
      expect(await store.read(_key), 'plain-key');
      expect(await store.read(_failures), '1');
      expect(await store.isSealed(), isTrue);
      // Other entries pass through untouched.
      expect(await store.read('${_id}other'), 'kept');
      expect(inner.values['${_id}other'], 'kept');
    });

    test('a higher count rotates the key; an older copy of the store no longer opens', () async {
      await store.write(_key, 'k');
      final copy = Map.of(inner.values);
      expect(await store.read(_failures), '0');

      await store.write(_failures, '1');
      await store.write(_failures, '2');
      expect(wrap.keys, hasLength(1), reason: 'older keys are deleted');
      expect(await store.read(_failures), '2');

      // A count of zero (a right PIN) stays under the same key.
      final before = wrap.created;
      await store.delete(_failures);
      expect(wrap.created, before);
      expect(await store.read(_failures), '0');

      inner.values
        ..clear()
        ..addAll(copy);
      await expectLater(store.read(_key), throwsA(isA<PinKeyLost>()));
      await expectLater(store.read(_failures), throwsA(isA<PinKeyLost>()));
    });

    test('a count removed or made plain beside a sealed key reads as edited', () async {
      await store.write(_key, 'k');
      inner.values.remove(_failures);
      expect(await store.read(_failures), '$tamperedPinFailures');
      inner.values[_failures] = '0';
      expect(await store.read(_failures), '$tamperedPinFailures');
      // LEPIC's next count is sealed again.
      await store.write(_failures, '1');
      expect(await store.read(_failures), '1');
      inner.values[_pending] = 'plain-pending';
      expect(await store.read(_pending), isNull);
    });

    test('sealed text is bound to its entry', () async {
      await store.write(_key, 'k');
      await store.write(_failures, '1');
      inner.values[_failures] = inner.values[_key]!;
      await expectLater(store.read(_failures), throwsA(isA<PinKeyLost>()));
    });

    test('a Keystore that lost its keys gives PinKeyLost, not a free attempt', () async {
      await store.write(_key, 'k');
      wrap.loseAll();
      await expectLater(store.read(_key), throwsA(isA<PinKeyLost>()));
      await expectLater(store.write(_failures, '1'), throwsA(isA<PinKeyLost>()));
      expect(sealed(_key), isTrue, reason: 'nothing was overwritten');
    });

    test('a Keystore that makes no key leaves an older wallet working, plain', () async {
      inner.values[_key] = 'plain-key';
      wrap.failCreate = true;
      await store.write(_failures, '1');
      expect(inner.values[_failures], '1');
      expect(await store.read(_key), 'plain-key');
      // Once sealed, no key is a failure: the entries never go back to plain.
      wrap.failCreate = false;
      await store.write(_failures, '2');
      wrap.failCreate = true;
      await expectLater(store.write(_failures, '3'), throwsA(isA<KeyWrapUnavailable>()));
      expect(await store.read(_failures), '2');
    });

    test('a rotation cut short still opens, and the next one tidies up', () async {
      await store.write(_key, 'k');
      await store.write(_pending, 'p');
      final aliases = await wrap.aliases(store.aliasPrefix);
      // As if the app stopped after the count was written under a new key.
      final next = '${store.aliasPrefix}9';
      await wrap.create(next);
      inner.values[_failures] = 'wfe-hw1:9:${await wrap.seal(next, _failures, '4')}';
      expect(await store.read(_failures), '4');
      expect(await store.read(_key), 'k');
      expect(await store.read(_pending), 'p');
      await store.write(_failures, '5');
      expect(await wrap.aliases(store.aliasPrefix), ['${store.aliasPrefix}10']);
      expect(aliases, isNot(contains('${store.aliasPrefix}10')));
      expect(await store.read(_pending), 'p');
    });

    test('forgetting the PIN key deletes the Keystore keys', () async {
      await store.write(_key, 'k');
      await store.write(_failures, '1');
      await store.delete(_key);
      await store.delete(_pending);
      await store.delete(_failures);
      expect(wrap.keys, isEmpty);
      expect(inner.values, isEmpty);
    });
  });

  group('passphrase rules', () {
    test('a passphrase is long, not only digits, and not padded', () {
      expect(isValidPassphrase('correct horse'), isTrue);
      expect(isValidPassphrase('short'), isFalse);
      expect(isValidPassphrase('1234567890123'), isFalse);
      expect(isValidPassphrase(' padded words '), isFalse);
      expect(isValidPin('123456'), isTrue);
      expect(isValidPassphrase('123456'), isFalse);
    });
  });

  group('WalletVault over LEPIC', () {
    late Directory root;
    late MemorySecretStore secrets;
    late MemoryKeyWrap wrap;
    late MemoryBiometricStore bio;
    late WalletConfig config;
    final sessions = <WalletSession>[];

    setUpAll(() async {
      if (_lib != null) await initLepic(libraryPath: _lib);
    });

    setUp(() {
      if (_lib == null) return;
      // The test settings' made-up onions are no v3 addresses, which LEPIC refuses.
      final cfg = testConfigText().replaceAll(RegExp(r'^onions = \[.*?^\]', multiLine: true, dotAll: true), 'onions = []');
      hostSettings = HostSettings.fromText(testSettingsText(), config: AppConfig.fromText(cfg));
      root = Directory.systemTemp.createTempSync('wfe-vault-');
      secrets = MemorySecretStore();
      wrap = MemoryKeyWrap();
      bio = MemoryBiometricStore();
      config = floonetPreset.config(dataDir: root.path, nodeUrl: 'http://127.0.0.1:1');
    });

    tearDown(() {
      if (_lib == null) return;
      for (final s in sessions) {
        s.dispose();
      }
      sessions.clear();
      root.deleteSync(recursive: true);
    });

    WalletVault vault({bool hardware = true}) => WalletVault(
      store: secrets,
      biometrics: bio,
      service: LepicWalletService(
        secrets: secrets,
        oneWalletPerChain: true,
        keyWrap: hardware ? wrap : null,
      ),
      legacyFiles: (_) async => false,
    );

    Future<WalletSession> keep(Future<WalletSession> session) async {
      final s = await session;
      sessions.add(s);
      return s;
    }

    Future<PinRejected> rejected(WalletVault v, String pin) async {
      try {
        await keep(v.unlock(config, pin));
      } on PinRejected catch (r) {
        return r;
      }
      fail('PIN $pin was accepted');
    }

    bool keySealed() => secrets.values.entries.any(
      (e) => e.key.endsWith('lepic.pin-key') && e.value.startsWith('wfe-hw1:'),
    );

    test('a wrong PIN is PinRejected with LEPIC\'s count and wait, end to end', () async {
      final v = vault();
      (await v.create(config, pin: '123456')).session.dispose();
      expect(keySealed(), isTrue);

      for (var n = 1; n <= freePinAttempts; n++) {
        final r = await rejected(v, '000000');
        expect(r.failures, n);
        expect(r.attemptsLeft, freePinAttempts - n);
        expect(r.nextWait, pinDelay(n));
      }
      // The next try would wait: the count survives in the sealed store.
      expect(await v.nextPinWait(config), pinDelay(freePinAttempts));
      expect(pinDelay(freePinAttempts), greaterThan(Duration.zero));
      expect(
        await vault().nextPinWait(config),
        pinDelay(freePinAttempts),
        reason: 'a new service (a restart) reads the same count',
      );
    }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 2)));

    test('a wallet of the older app opens, and its first unlock moves the key', () async {
      // Created as the app before this change kept it: everything plain.
      final created = await vault(hardware: false).create(config, pin: '123456');
      created.session.dispose();
      expect(keySealed(), isFalse);
      expect(wrap.created, 0);

      final v = vault();
      (await v.unlock(config, '123456')).dispose();
      expect(keySealed(), isTrue, reason: 'migrated on the first unlock');
      expect(await v.nextPinWait(config), Duration.zero);
      // Still the same PIN, and a wrong one still counts.
      expect((await rejected(v, '111111')).failures, 1);
      await keep(v.unlock(config, '123456'));
    }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 2)));

    test('a lost Keystore key sends the user to the recovery phrase', () async {
      final v = vault();
      (await v.create(config, pin: '123456')).session.dispose();
      wrap.loseAll();
      await expectLater(v.unlock(config, '123456'), throwsA(isA<PinKeyLost>()));
      // Nothing was deleted: the wallet and its sealed text are still there.
      expect(await v.prepare(config), VaultStage.ready);
    }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 2)));

    test('a passphrase replaces the PIN, and a PIN replaces it again', () async {
      final v = vault();
      final created = (await v.create(config, pin: '123456')).session;
      // No flag at all, as on an older install: never.
      expect(secrets.values.keys.where((k) => k.contains('pinPassphrase')), isEmpty);
      expect(await v.usesPassphrase(config.chain), isFalse);
      expect(await v.passphraseEverUsed(config.chain), isFalse);
      await v.changePin(created, config, currentPin: '123456', newPin: 'correct horse battery');
      expect(await v.usesPassphrase(config.chain), isTrue);
      expect(await v.passphraseEverUsed(config.chain), isTrue);
      await expectLater(
        v.changePin(created, config, currentPin: 'correct horse battery', newPin: 'short'),
        throwsArgumentError,
      );
      created.dispose();
      expect((await rejected(v, '123456')).failures, 1);
      final session = await keep(v.unlock(config, 'correct horse battery'));
      await v.changePin(session, config, currentPin: 'correct horse battery', newPin: '654321');
      expect(await v.usesPassphrase(config.chain), isFalse);
      // Back on a PIN the switch stays offered: the flag outlives the passphrase.
      expect(await v.passphraseEverUsed(config.chain), isTrue);
      session.dispose();
      sessions.remove(session);
      await keep(v.unlock(config, '654321'));
      // Removing the wallet removes the flag with it.
      await v.forget(config.chain);
      expect(await v.passphraseEverUsed(config.chain), isFalse);
    }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 3)));

    test('after a biometric write in this process, biometrics wait for a restart', () async {
      final v = vault();
      final created = await v.create(config, pin: '123456', useBiometrics: true);
      sessions.add(created.session);
      expect(created.biometrics, isTrue);
      bio.readable = false; // as PlatformBiometricStore after its write
      final prompts = bio.prompts;
      expect(await v.biometricsEnabled(config.chain), isTrue);
      expect(await v.biometricsReady(config.chain), isFalse);
      expect(await v.readBiometricPin(config.chain), isNull);
      expect(bio.prompts, prompts, reason: 'no prompt, and nothing read');
      expect(await v.biometricsEnabled(config.chain), isTrue, reason: 'still on after a restart');
      bio.readable = true;
      expect(await v.readBiometricPin(config.chain), '123456');
    }, skip: _lib == null, timeout: const Timeout(Duration(minutes: 2)));
  });
}
