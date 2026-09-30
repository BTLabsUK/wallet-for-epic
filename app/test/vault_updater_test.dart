import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletVault', () {
    late DateTime now;
    late MemorySecretStore store;
    late WalletVault vault;

    setUp(() {
      now = DateTime(2026, 9, 27, 12);
      store = MemorySecretStore();
      vault = WalletVault(
        store: store,
        biometrics: MemoryBiometricStore(),
        crypto: FakeVaultCrypto(),
        clock: () => now,
      );
    });

    test('keeps one pending password until sealed', () async {
      expect(await vault.stage(Chain.mainnet), VaultStage.empty);
      final first = await vault.pendingPassword(Chain.mainnet);
      expect(await vault.pendingPassword(Chain.mainnet), first);
      expect(await vault.stage(Chain.mainnet), VaultStage.pending);
      await vault.seal(
        Chain.mainnet,
        pin: '123456',
        password: first,
        useBiometrics: false,
      );
      expect(await vault.stage(Chain.mainnet), VaultStage.sealed);
      expect(await vault.unlockWithPin(Chain.mainnet, '123456'), first);
      expect(await vault.stage(Chain.usernet), VaultStage.empty);
    });

    test('rejects PINs that are not six digits', () async {
      expect(isValidPin('12345'), isFalse);
      expect(isValidPin('12345a'), isFalse);
      expect(isValidPin('１２３４５６'), isFalse);
      await expectLater(
        vault.seal(
          Chain.mainnet,
          pin: '1234',
          password: 'x',
          useBiometrics: false,
        ),
        throwsArgumentError,
      );
    });

    test(
      'locks out after five wrong PINs, doubling, and resets on success',
      () async {
        await vault.seal(
          Chain.mainnet,
          pin: '123456',
          password: 'pw',
          useBiometrics: false,
        );
        Future<PinRejected> wrong() async {
          try {
            await vault.unlockWithPin(Chain.mainnet, '000000');
          } on PinRejected catch (r) {
            return r;
          }
          fail('wrong PIN accepted');
        }

        for (var left = 4; left >= 1; left--) {
          expect((await wrong()).attemptsLeft, left);
        }
        expect((await wrong()).lockedUntil, now.add(firstLockout));
        // Even the right PIN waits out the lockout.
        await expectLater(
          vault.unlockWithPin(Chain.mainnet, '123456'),
          throwsA(isA<PinRejected>()),
        );
        now = now.add(firstLockout);
        expect((await wrong()).lockedUntil, now.add(firstLockout * 2));
        now = now.add(maxLockout);
        expect(await vault.unlockWithPin(Chain.mainnet, '123456'), 'pw');
        expect((await wrong()).attemptsLeft, 4);
      },
    );

    test('lockout never exceeds the maximum', () async {
      store.values['wallet.mainnet.sealed'] = 'sealed|123456|pw';
      store.values['wallet.mainnet.failed'] = '60';
      try {
        await vault.unlockWithPin(Chain.mainnet, '000000');
      } on PinRejected catch (r) {
        expect(r.lockedUntil, now.add(maxLockout));
      }
    });

    test('biometrics store a copy and fall back when dismissed', () async {
      final bio = vault.biometrics as MemoryBiometricStore;
      expect(
        await vault.seal(
          Chain.mainnet,
          pin: '123456',
          password: 'pw',
          useBiometrics: true,
        ),
        isTrue,
      );
      expect(await vault.unlockWithBiometrics(Chain.mainnet), 'pw');
      bio.succeed = false;
      expect(await vault.unlockWithBiometrics(Chain.mainnet), isNull);
      expect(await vault.biometricsEnabled(Chain.mainnet), isTrue);
      await vault.forget(Chain.mainnet);
      expect(store.values, isEmpty);
      expect(bio.values, isEmpty);
    });

    test('changes the PIN and keeps biometrics working', () async {
      await vault.seal(
        Chain.mainnet,
        pin: '123456',
        password: 'pw',
        useBiometrics: true,
      );
      await vault.changePin(
        Chain.mainnet,
        currentPin: '123456',
        newPin: '654321',
      );
      expect(await vault.unlockWithPin(Chain.mainnet, '654321'), 'pw');
      await expectLater(
        vault.unlockWithPin(Chain.mainnet, '123456'),
        throwsA(isA<PinRejected>()),
      );
      expect(await vault.biometricsEnabled(Chain.mainnet), isTrue);
      expect(await vault.unlockWithBiometrics(Chain.mainnet), 'pw');
    });

    test('a wrong current PIN changes nothing and counts as a try', () async {
      await vault.seal(
        Chain.mainnet,
        pin: '123456',
        password: 'pw',
        useBiometrics: false,
      );
      try {
        await vault.changePin(
          Chain.mainnet,
          currentPin: '000000',
          newPin: '654321',
        );
        fail('wrong PIN accepted');
      } on PinRejected catch (r) {
        expect(r.attemptsLeft, freePinAttempts - 1);
      }
      await expectLater(
        vault.changePin(Chain.mainnet, currentPin: '123456', newPin: '12'),
        throwsArgumentError,
      );
      expect(await vault.unlockWithPin(Chain.mainnet, '123456'), 'pw');
    });
  });

  group('parseUpdateManifest', () {
    const app = InstalledApp(
      packageName: 'com.blacktyger.epic_wallet',
      versionCode: 2001,
      versionName: '1.0.0',
      abis: ['arm64-v8a', 'armeabi-v7a'],
    );
    final url = Uri.parse('https://example.org/releases/latest/update.json');
    final hash = 'a' * 64;

    String manifest({
      String package = 'com.blacktyger.epic_wallet',
      List<Map<String, Object?>>? apks,
    }) => jsonEncode({
      'schema': 1,
      'packageName': package,
      'versionName': '1.0.1',
      'notes': 'Fixes',
      'apks':
          apks ??
          [
            {
              'abi': 'x86_64',
              'versionCode': 4002,
              'url': 'app-x86_64-release.apk',
              'sha256': hash,
              'size': 10,
            },
            {
              'abi': 'arm64-v8a',
              'versionCode': 2002,
              'url': 'app-arm64-v8a-release.apk',
              'sha256': hash,
              'size': 10,
            },
          ],
    });

    test('picks the APK for the preferred ABI and resolves its URL', () {
      final update = parseUpdateManifest(manifest(), app, url)!;
      expect(update.versionName, '1.0.1');
      expect(update.notes, 'Fixes');
      expect(update.apk.abi, 'arm64-v8a');
      expect(
        update.apk.url.toString(),
        'https://example.org/releases/latest/app-arm64-v8a-release.apk',
      );
    });

    test('returns null when not newer or no ABI fits', () {
      final same = manifest(
        apks: [
          {
            'abi': 'arm64-v8a',
            'versionCode': 2001,
            'url': 'a.apk',
            'sha256': hash,
            'size': 1,
          },
        ],
      );
      expect(parseUpdateManifest(same, app, url), isNull);
      final other = manifest(
        apks: [
          {
            'abi': 'x86_64',
            'versionCode': 4009,
            'url': 'a.apk',
            'sha256': hash,
            'size': 1,
          },
        ],
      );
      expect(parseUpdateManifest(other, app, url), isNull);
    });

    test('refuses other apps, bad JSON, bad hashes and plain http', () {
      expect(
        () => parseUpdateManifest(manifest(package: 'evil.app'), app, url),
        throwsA(isA<UpdateError>()),
      );
      expect(
        () => parseUpdateManifest('{', app, url),
        throwsA(isA<UpdateError>()),
      );
      final bad = manifest(
        apks: [
          {
            'abi': 'arm64-v8a',
            'versionCode': 2002,
            'url': 'a.apk',
            'sha256': 'nothex',
            'size': 1,
          },
          {
            'abi': 'universal',
            'versionCode': 2002,
            'url': 'http://example.org/a.apk',
            'sha256': hash,
            'size': 1,
          },
        ],
      );
      expect(parseUpdateManifest(bad, app, url), isNull);
    });
  });

  group('downloadApk', () {
    late HttpServer server;
    late Directory dir;
    final payload = List<int>.generate(100000, (i) => i % 251);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('wfe-update-');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..add(payload)
          ..close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      await dir.delete(recursive: true);
    });

    ReleaseApk apk({String? hash, int? size}) => ReleaseApk(
      abi: 'arm64-v8a',
      versionCode: 2002,
      url: Uri.parse('http://127.0.0.1:${server.port}/a.apk'),
      sha256: hash ?? sha256.convert(payload).toString(),
      size: size ?? payload.length,
    );

    test('writes a verified file and reports progress', () async {
      final target = File('${dir.path}/a.apk');
      var last = 0.0;
      await downloadApk(
        HttpClient(),
        apk(),
        target,
        onProgress: (p) => last = p,
      );
      expect(await target.readAsBytes(), payload);
      expect(last, 1.0);
    });

    test('rejects a wrong checksum or size and leaves no file', () async {
      final target = File('${dir.path}/a.apk');
      await expectLater(
        downloadApk(HttpClient(), apk(hash: 'b' * 64), target),
        throwsA(isA<UpdateError>()),
      );
      await expectLater(
        downloadApk(HttpClient(), apk(size: 10), target),
        throwsA(isA<UpdateError>()),
      );
      expect(dir.listSync(), isEmpty);
    });
  });

  group('relays', () {
    test('parses host and port, and refuses junk', () {
      final a = EpicboxRelay.parse(' Epicbox.EpicNet.us ')!;
      expect(a.host, 'epicbox.epicnet.us');
      expect(a.port, 443);
      expect(a.label, 'epicbox.epicnet.us');
      final b = EpicboxRelay.parse('127.0.0.1:3423')!;
      expect(b.label, '127.0.0.1:3423');
      expect(EpicboxRelay.parse('wss://x'), isNull);
      expect(EpicboxRelay.parse('x:70000'), isNull);
    });

    test('reads the monitor, healthy and official first', () {
      final list = parseRelayStatus(
        jsonEncode({
          'epicbox': [
            {
              'endpoint': 'wss://down.example:443/',
              'state': 'down',
              'verified': true,
            },
            {
              'endpoint': 'wss://community.example:443/',
              'state': 'healthy',
              'verified': false,
              'latency_ms': 10,
            },
            {
              'endpoint': 'wss://official.example:8443/',
              'state': 'healthy',
              'verified': true,
              'latency_ms': 700,
              'operator': 'Epic Cash',
              'uptime': {'24h': 0.99},
            },
            {'endpoint': 'https://not-a-relay.example/', 'state': 'healthy'},
          ],
        }),
      );
      expect(list.map((r) => r.relay.label), [
        'official.example:8443',
        'community.example',
        'down.example',
      ]);
      expect(list.first.operator, 'Epic Cash');
      expect(list.first.uptime24h, 0.99);
      expect(() => parseRelayStatus('[]'), throwsFormatException);
    });
  });
}
