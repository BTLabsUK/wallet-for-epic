// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' show SimpleKeyPair;
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/btlabs_public_file.dart' show donation, signedPublicFile, testKeyring;
import 'support/btlabs_sign.dart' show testKeyFromPem;
import 'support/signed_update.dart';

void main() {
  group('WalletVault', () {
    const dir = '/fake/wallets/mainnet';
    final config = mainnetPreset.config(dataDir: dir, nodeUrl: 'http://n');
    late MemorySecretStore store;
    late MemoryBiometricStore bio;
    late FakeWalletService service;
    late WalletVault vault;

    WalletVault makeVault({LegacyFiles? legacyFiles}) => WalletVault(
      store: store,
      biometrics: bio,
      service: service,
      legacyFiles: legacyFiles ?? (_) async => false,
    );

    setUp(() {
      store = MemorySecretStore();
      bio = MemoryBiometricStore();
      service = FakeWalletService();
      vault = makeVault();
    });

    Future<PinRejected> wrong(String pin) async {
      try {
        await vault.unlock(config, pin);
      } on PinRejected catch (r) {
        return r;
      }
      fail('PIN $pin was accepted');
    }

    test('creates under a PIN and keeps only the sealed text', () async {
      expect(await vault.prepare(config), VaultStage.empty);
      await expectLater(
        vault.create(config, pin: '12345'),
        throwsA(isA<ArgumentError>()),
      );
      final created = await vault.create(config, pin: '123456');
      expect(created.biometrics, isFalse);
      // "Not now": the biometric store is never opened, so no system prompt shows.
      expect(bio.prompts, 0);
      expect(bio.deletes, 0);
      expect(service.createdPin, '123456');
      expect(store.values, {
        'wallet.mainnet.pinSealed': fakeSealedPassword('123456'),
      });
      expect(await vault.prepare(config), VaultStage.ready);
      expect(await vault.unlock(config, '123456'), same(service.session));
      // A wallet that opens with a PIN is never replaced.
      await expectLater(
        vault.create(config, pin: '654321'),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.walletAlreadyExists,
          ),
        ),
      );
    });

    test("reports LEPIC's count: tries left, then the wait", () async {
      await vault.create(config, pin: '123456');
      final first = await wrong('000000');
      expect((first.attemptsLeft, first.nextWait), (2, Duration.zero));
      expect((await wrong('000000')).attemptsLeft, 1);
      final third = await wrong('000000');
      expect((third.attemptsLeft, third.nextWait), (0, firstPinDelay));
      expect(await vault.nextPinWait(config), firstPinDelay);
      expect((await wrong('000000')).nextWait, firstPinDelay * 2);
      await vault.unlock(config, '123456');
      expect(await vault.nextPinWait(config), Duration.zero);
      expect(pinDelay(5), const Duration(minutes: 2));
      expect(pinDelay(10), maxPinDelay);
      expect(pinDelay(1 << 30), maxPinDelay);
    });

    test(
      'a wallet without sealed text, or sealed text without a wallet, stays',
      () async {
        // The app stopped between creating the wallet and storing its sealed text, or the
        // store did not answer.
        service.existingWallets.add(dir);
        expect(await vault.prepare(config), VaultStage.stranded);
        expect(service.deletedWallets, isEmpty);
        expect(service.existingWallets, {dir});

        // The wallet's entries are not found where they were (a moved directory), but the
        // sealed text is still there.
        service.existingWallets.clear();
        store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword('123456');
        store.values['wallet.mainnet.backedUp'] = '1';
        final before = Map.of(store.values);
        expect(await vault.prepare(config), VaultStage.stranded);
        expect(store.values, before);
        expect(service.deletedWallets, isEmpty);

        // Neither replaces it: a new wallet would overwrite the sealed text.
        await expectLater(
          vault.create(config, pin: '123456'),
          throwsA(
            isA<WalletError>().having(
              (e) => e.kind,
              'kind',
              WalletErrorKind.walletAlreadyExists,
            ),
          ),
        );
        expect(store.values, before);

        // Removing it is the user's step (Forgot PIN): delete, then forget.
        await service.deleteWallet(config: config);
        await vault.forget(Chain.mainnet);
        expect(await vault.prepare(config), VaultStage.empty);
      },
    );

    test('leaves a 1.2.x install in place, files and entries', () async {
      final tmp = await Directory.systemTemp.createTemp('wfe-vault-');
      addTearDown(() => tmp.delete(recursive: true));
      final legacyConfig = mainnetPreset.config(
        dataDir: tmp.path,
        nodeUrl: 'http://n',
      );
      await Directory('${tmp.path}/wallet_data/db').create(recursive: true);
      final seed = File('${tmp.path}/wallet_data/wallet.seed');
      await seed.writeAsString('old seed');
      await File('${tmp.path}/wfe_meta.json').writeAsString('{"old":1}');
      await Directory('${tmp.path}/lepic').create();
      final legacyEntries = {
        'wallet.mainnet.sealed': 'old sealed password',
        'wallet.mainnet.pending': 'old pending password',
        'wallet.mainnet.biometrics': '1',
        'wallet.mainnet.failed': '2',
        'app.network': 'mainnet',
      };
      store.values.addAll(legacyEntries);
      store.values['wallet.mainnet.backedUp'] = '1';
      bio.values['wallet.mainnet.password'] = 'old password';
      vault = WalletVault(store: store, biometrics: bio, service: service);

      expect(await vault.prepare(legacyConfig), VaultStage.empty);
      expect(await seed.readAsString(), 'old seed');
      expect(await Directory('${tmp.path}/wallet_data/db').exists(), isTrue);
      // The old history is set aside, so the new wallet does not read it as its own.
      expect(await File('${tmp.path}/wfe_meta.json').exists(), isFalse);
      final setAside = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('wfe_meta.json.legacy-'))
          .toList();
      expect(setAside, hasLength(1));
      expect(await setAside.single.readAsString(), '{"old":1}');
      expect(store.values, {...legacyEntries, 'wallet.mainnet.backedUp': '1'});
      expect(bio.values, {'wallet.mainnet.password': 'old password'});

      // A new wallet over it starts without the old flags, and the old files and entries stay.
      await vault.create(legacyConfig, pin: '123456');
      expect(await vault.isBackedUp(Chain.mainnet), isFalse);
      expect(await seed.readAsString(), 'old seed');
      for (final e in legacyEntries.entries) {
        expect(store.values[e.key], e.value);
      }
      expect(bio.values['wallet.mainnet.password'], 'old password');
      expect(bio.prompts, 0);

      // Later launches change nothing.
      await File('${tmp.path}/wfe_meta.json').writeAsString('{"new":1}');
      expect(await vault.prepare(legacyConfig), VaultStage.ready);
      expect(
        await File('${tmp.path}/wfe_meta.json').readAsString(),
        '{"new":1}',
      );
      expect(await seed.readAsString(), 'old seed');
    });

    test('biometrics hold the PIN and fall back when dismissed', () async {
      final created = await vault.create(
        config,
        pin: '123456',
        useBiometrics: true,
      );
      expect(created.biometrics, isTrue);
      expect(bio.values['wallet.mainnet.pin'], '123456');
      expect(await vault.unlockWithBiometrics(config), same(service.session));

      bio.succeed = false;
      expect(await vault.unlockWithBiometrics(config), isNull);
      expect(await vault.biometricsEnabled(Chain.mainnet), isTrue);

      // A copy that no longer opens counts as a wrong PIN and turns biometrics off.
      bio.succeed = true;
      bio.values['wallet.mainnet.pin'] = '999999';
      await expectLater(
        vault.unlockWithBiometrics(config),
        throwsA(isA<PinRejected>()),
      );
      expect(await vault.biometricsEnabled(Chain.mainnet), isFalse);
      expect(bio.values, isEmpty);
      expect(await vault.unlockWithBiometrics(config), isNull);
    });

    test(
      'changes the PIN, confirms it and rewrites the biometric copy',
      () async {
        final session = (await vault.create(
          config,
          pin: '123456',
          useBiometrics: true,
        )).session;
        await expectLater(
          vault.changePin(
            session,
            config,
            currentPin: '000000',
            newPin: '654321',
          ),
          throwsA(isA<PinRejected>()),
        );
        expect(
          store.values['wallet.mainnet.pinSealed'],
          fakeSealedPassword('123456'),
        );
        expect(service.confirmedPinChanges, isEmpty);

        expect(
          await vault.changePin(
            session,
            config,
            currentPin: '123456',
            newPin: '654321',
          ),
          isTrue,
        );
        expect(
          store.values['wallet.mainnet.pinSealed'],
          fakeSealedPassword('654321'),
        );
        expect(service.confirmedPinChanges, [fakeSealedPassword('654321')]);
        expect(bio.values['wallet.mainnet.pin'], '654321');
        await vault.unlock(config, '654321');

        // A dismissed prompt keeps the new PIN but turns biometrics off.
        bio.succeed = false;
        expect(
          await vault.changePin(
            session,
            config,
            currentPin: '654321',
            newPin: '111111',
          ),
          isFalse,
        );
        expect(await vault.biometricsEnabled(Chain.mainnet), isFalse);
        await vault.unlock(config, '111111');
      },
    );

    test('checks a PIN without sealing again', () async {
      final session = (await vault.create(config, pin: '123456')).session;
      await vault.checkPin(session, config, '123456');
      expect(service.confirmedPinChanges, isEmpty);
      await expectLater(
        vault.checkPin(session, config, '000000'),
        throwsA(isA<PinRejected>()),
      );
      expect(
        await vault.mnemonic(session, config, '123456'),
        service.session.phrase,
      );
    });
  });

  group('readUpdateManifest', () {
    const app = InstalledApp(
      packageName: 'uk.btlabs.epiccash.mobile',
      versionCode: 2001,
      versionName: '1.0.0',
      abis: ['arm64-v8a', 'armeabi-v7a'],
    );
    final now = DateTime.utc(2026, 11, 1);

    Future<UpdateManifestRead> read(String envelope, {ManifestState? state}) =>
        readUpdateManifest(
          envelope,
          app,
          keyring: testUpdateKeyring,
          now: now,
          state: state,
        );

    final twoApks = [
      testApk(
        abi: 'x86_64',
        versionCode: 4002,
        url: testApkUrl('app-x86_64-release.apk'),
      ),
      testApk(),
    ];

    test('picks the APK for the preferred ABI of a signed manifest', () async {
      final r = await read(
        await signedUpdate(testUpdatePayload(apks: twoApks)),
      );
      expect(r.rejected, isNull);
      final update = r.update!;
      expect(update.versionName, '1.0.1');
      expect(update.notes, 'Fixes');
      expect(update.apk.abi, 'arm64-v8a');
      expect(update.apk.versionCode, 2002);
      expect(update.apk.sha256, 'a' * 64);
      expect(
        update.apk.url.toString(),
        testApkUrl('app-arm64-v8a-release.apk'),
      );
      expect(r.state!.serial, 1790000000);
    });

    test('offers nothing when not newer or no ABI fits', () async {
      final same = await read(
        await signedUpdate(
          testUpdatePayload(apks: [testApk(versionCode: 2001)]),
        ),
      );
      expect(same.rejected, isNull);
      expect(same.update, isNull);
      final other = await read(
        await signedUpdate(
          testUpdatePayload(apks: [testApk(abi: 'x86_64', versionCode: 4009)]),
        ),
      );
      expect(other.update, isNull);
    });

    test('a 0.1.x install gets 26.10.0; a test build is never offered', () async {
      final calver = await read(
        await signedUpdate(
          testUpdatePayload(versionName: '26.10.0', apks: [testApk(versionCode: 26100000)]),
        ),
      );
      expect(calver.update?.versionName, '26.10.0');
      expect(calver.update?.apk.versionCode, 26100000);
      final rc = await read(
        await signedUpdate(
          testUpdatePayload(versionName: '26.10.1-rc1', apks: [testApk(versionCode: 26100101)]),
        ),
      );
      // FORMAT.md's schema already refuses it (versions are X.Y.Z); pickUpdate refuses it too.
      expect(rc.update, isNull);
      final manifest = WalletUpdate(
        schema: 1,
        serial: 1,
        issuedAt: now,
        expiresAt: now,
        packageName: app.packageName,
        versionName: '26.10.1-rc1',
        notes: '',
        apks: [
          WalletApk(
            abi: 'arm64-v8a',
            versionCode: 26100101,
            url: Uri.parse('https://example.org/app.apk'),
            sha256: 'a' * 64,
            size: 1,
          ),
        ],
        desktop: null,
        revokedKeys: const [],
      );
      expect(pickUpdate(manifest, app), isNull);
    });

    test('refuses a signed manifest for another app', () async {
      final env = await signedUpdate(
        testUpdatePayload(packageName: 'evil.app'),
      );
      await expectLater(read(env), throwsA(isA<UpdateError>()));
    });

    test('the old unsigned update.json is not used', () async {
      final plain = jsonEncode(testUpdatePayload());
      expect((await read(plain)).rejected, RejectReason.malformed);
      expect((await read('{')).rejected, RejectReason.malformed);
    });

    test(
      'a key outside the keyring, a tampered payload, another type: not used',
      () async {
        final stranger = await signedUpdate(
          testUpdatePayload(),
          keys: [await testUpdateStrangerKey()],
        );
        expect((await read(stranger)).rejected, RejectReason.unknownKey);

        // Swap in another APK hash after signing: the signature no longer matches.
        final env = jsonDecode(
          await signedUpdate(testUpdatePayload()),
        ) as Map<String, Object?>;
        final forged = testUpdatePayload(apks: [testApk(sha256: 'b' * 64)]);
        env['payload'] = base64.encode(utf8.encode(jsonEncode(forged)));
        expect(
          (await read(jsonEncode(env))).rejected,
          RejectReason.badSignature,
        );

        final public = await signedUpdate(
          testUpdatePayload(),
          payloadType: btlabsPublicType,
        );
        expect((await read(public)).rejected, RejectReason.wrongType);
      },
    );

    test('one update.json for both variants: Tor reads the top level, no Tor the notor section', () async {
      final payload = testUpdatePayload(
        notor: false,
        versionName: '1.0.1',
        notes: 'With Tor',
        apks: [testApk(versionCode: 3002, url: testApkUrl('epic-cash-mobile-1.0.1-arm64-v8a.apk'))],
      )..['notor'] = <String, Object?>{
          'apks': [testApk(versionCode: 4002, url: testApkUrl('epic-cash-mobile-1.0.1-notor-arm64-v8a.apk'))],
        };
      final env = await signedUpdate(payload);
      Future<UpdateManifestRead> as(String e, {required bool tor}) =>
          readUpdateManifest(e, app, keyring: testUpdateKeyring, now: now, tor: tor);

      final tor = (await as(env, tor: true)).update!;
      expect((tor.apk.versionCode, tor.versionName, tor.notes), (3002, '1.0.1', 'With Tor'));
      expect(tor.apk.url.pathSegments.last, 'epic-cash-mobile-1.0.1-arm64-v8a.apk');
      // Without Tor: the section's files, its version and notes defaulting to the top level.
      final noTor = (await as(env, tor: false)).update!;
      expect((noTor.apk.versionCode, noTor.versionName, noTor.notes), (4002, '1.0.1', 'With Tor'));
      expect(noTor.apk.url.pathSegments.last, 'epic-cash-mobile-1.0.1-notor-arm64-v8a.apk');
      // Its own version and notes when it names them.
      (payload['notor']! as Map<String, Object?>).addAll({'versionName': '1.0.2', 'notes': 'Without Tor'});
      final own = (await as(await signedUpdate(payload), tor: false)).update!;
      expect((own.versionName, own.notes), ('1.0.2', 'Without Tor'));

      // A file without the section: verified (its state is kept), nothing newer without Tor.
      final plain = await signedUpdate(testUpdatePayload(notor: false));
      final none = await as(plain, tor: false);
      expect((none.rejected, none.update, none.state?.serial), (null, null, 1790000000));
      expect((await as(plain, tor: true)).update, isNotNull);

      // A bad section is a bad file, for both.
      payload['notor'] = {'apks': [testApk(url: 'http://example.org/a.apk')]};
      final bad = await signedUpdate(payload);
      expect((await as(bad, tor: true)).rejected, RejectReason.malformed);
      expect((await as(bad, tor: false)).rejected, RejectReason.malformed);
      payload['notor'] = {'apks': <Object?>[]};
      expect((await as(await signedUpdate(payload), tor: false)).rejected, RejectReason.malformed);

      // This build reads its own part by default (testUpdatePayload puts the release there).
      expect((await read(await signedUpdate(testUpdatePayload()))).update?.apk.versionCode, 2002);
    });

    test('an expired manifest is not used', () async {
      final env = await signedUpdate(
        testUpdatePayload(
          issuedAt: '2026-01-01T00:00:00Z',
          expiresAt: '2026-07-01T00:00:00Z',
        ),
      );
      expect((await read(env)).rejected, RejectReason.expired);
    });

    test('an APK outside the update download folder makes the manifest unusable', () async {
      // Audit 26.10.24: held to [updates] downloads as the desktop files are, in both parts.
      for (final url in [
        'https://example.org/a.apk',
        '${walletUpdateDownloads!}sub/a.apk',
        walletUpdateDownloads!,
      ]) {
        final top = testUpdatePayload(notor: false, apks: [testApk(url: url)]);
        expect((await read(await signedUpdate(top))).rejected, RejectReason.malformed, reason: url);
        final notor = testUpdatePayload(notor: false)..['notor'] = {'apks': [testApk(url: url)]};
        expect((await read(await signedUpdate(notor))).rejected, RejectReason.malformed, reason: url);
      }
      expect((await read(await signedUpdate(testUpdatePayload()))).rejected, isNull);
    });

    test('an http APK URL or a bad hash makes the manifest unusable', () async {
      final http = await signedUpdate(
        testUpdatePayload(apks: [testApk(url: 'http://example.org/a.apk')]),
      );
      expect((await read(http)).rejected, RejectReason.malformed);
      final hash = await signedUpdate(
        testUpdatePayload(apks: [testApk(sha256: 'nothex')]),
      );
      expect((await read(hash)).rejected, RejectReason.malformed);
    });

    test(
      'an older manifest after a newer one in the same run is refused',
      () async {
        final newer = await read(
          await signedUpdate(testUpdatePayload(serial: 1790000100)),
        );
        final older = await read(
          await signedUpdate(testUpdatePayload(serial: 1790000000)),
          state: newer.state,
        );
        expect(older.rejected, RejectReason.rollback);
        final again = await read(
          await signedUpdate(testUpdatePayload(serial: 1790000100)),
          state: newer.state,
        );
        expect(again.rejected, isNull);
        expect(again.update, isNotNull);
      },
    );
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

  group('UpdateNotifier', () {
    late HttpServer server;
    late ProviderContainer container;
    var requests = 0;
    // What the manifest says next: a newer version, the installed one, or a server error.
    var reply = 'newer';
    HttpHeaders? headers;
    // The APK the feed serves, and what the installer answers for it.
    final apkBytes = utf8.encode('not an apk');
    late _FakeUpdatePlatform platform;

    // Signed with test key A in setUp (the handler below cannot wait for it). The "same"
    // manifest is the later one, as when the installed release is the newest.
    final manifests = <int, String>{};
    Future<String> manifest(int versionCode) => signedUpdate(
      testUpdatePayload(
        versionName: versionCode == 2002 ? '1.0.1' : '1.0.0',
        notes: null,
        apks: [testApk(versionCode: versionCode, sha256: sha256.convert(apkBytes).toString(), size: apkBytes.length)],
        serial: versionCode == 2002 ? 1790000100 : 1790000200,
      ),
    );

    setUp(() async {
      requests = 0;
      reply = 'newer';
      for (final code in [2001, 2002]) {
        manifests[code] = await manifest(code);
      }
      // 1: the newer app at a lower serial; 0: the newer app re-signed at a higher serial, then
      // its payload changed (the signature no longer matches).
      manifests[1] = await signedUpdate(testUpdatePayload(
        versionName: '1.0.1',
        notes: null,
        apks: [testApk(versionCode: 2002, sha256: sha256.convert(apkBytes).toString(), size: apkBytes.length)],
        serial: 1790000050,
      ));
      final good = jsonDecode(manifests[2002]!) as Map<String, Object?>;
      final payload = jsonDecode(utf8.decode(base64.decode(good['payload']! as String))) as Map<String, Object?>;
      payload['serial'] = 1790000900;
      good['payload'] = base64.encode(utf8.encode(jsonEncode(payload)));
      manifests[0] = jsonEncode(good);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        requests++;
        headers = request.headers;
        final response = request.response;
        if (request.uri.path.endsWith('/app.apk')) {
          response.add(apkBytes);
          response.close();
          return;
        }
        // Sources of the manifest: /gone/ has none, /down/ fails, /old/ has the lower serial,
        // /bad/ one whose payload was changed after signing, /signin/ answers a sign-in page
        // (a private GitLab project).
        switch (request.uri.path.split('/')[1]) {
          case 'gone':
            response.statusCode = HttpStatus.notFound;
            response.close();
            return;
          case 'down':
            response.statusCode = HttpStatus.serviceUnavailable;
            response.close();
            return;
          case 'old':
            response.write(manifests[1]);
            response.close();
            return;
          case 'bad':
            response.write(manifests[0]);
            response.close();
            return;
          case 'signin':
            response.headers.contentType = ContentType.html;
            response.write('<!DOCTYPE html><html><body>Sign in</body></html>');
            response.close();
            return;
        }
        switch (reply) {
          case 'newer':
            response.write(manifests[2002]);
          case 'same':
            response.write(manifests[2001]);
          case 'unsigned':
            response.write(jsonEncode(testUpdatePayload()));
          case 'huge':
            response.write(' ' * 70000);
          case 'missing':
            response.statusCode = HttpStatus.notFound;
          default:
            response.statusCode = HttpStatus.internalServerError;
        }
        response.close();
      });
      platform = _FakeUpdatePlatform();
      // install() downloads into a temporary directory of its own.
      final temp = await Directory.systemTemp.createTemp('wfe_update_test');
      addTearDown(() => temp.delete(recursive: true));
      container = ProviderContainer(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          updateTempDirProvider.overrideWithValue(() async => temp),
          updateManifestUrlProvider.overrideWithValue(
            Uri.parse('http://127.0.0.1:${server.port}/update.json'),
          ),
          updateKeyringProvider.overrideWithValue(testUpdateKeyring),
          updateClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 11, 1),
          ),
          // The manifest names its https URL; the APK comes from the local server.
          updateApkUrlProvider.overrideWithValue(
            (url) => Uri.parse('http://127.0.0.1:${server.port}/app.apk'),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await platform.events.close();
      await server.close(force: true);
    });

    test('checks on every opening, not once per process', () async {
      final updates = container.read(updateProvider.notifier);
      for (var i = 1; i <= 3; i++) {
        await updates.checkOnOpening();
        expect(requests, i);
        expect(container.read(updateProvider).phase, UpdatePhase.available);
        expect(container.read(updateProvider).update?.versionName, '1.0.1');
      }
    });

    test(
      'a quiet failure keeps the update it knew; up to date clears it',
      () async {
        final updates = container.read(updateProvider.notifier);
        final phases = <(UpdatePhase, bool)>[];
        container.listen(
          updateProvider,
          (_, s) => phases.add((s.phase, s.update != null)),
        );
        await updates.checkOnOpening();
        reply = 'error';
        await updates.checkOnOpening();
        expect(container.read(updateProvider).phase, UpdatePhase.available);
        expect(container.read(updateProvider).update?.versionName, '1.0.1');
        reply = 'same';
        await updates.checkOnOpening();
        expect(container.read(updateProvider).phase, UpdatePhase.idle);
        expect(container.read(updateProvider).update, isNull);
        expect(phases, [
          (UpdatePhase.checking, false),
          (UpdatePhase.available, true),
          // The check keeps the update offered while it runs.
          (UpdatePhase.checking, true),
          (UpdatePhase.available, true),
          (UpdatePhase.checking, true),
          (UpdatePhase.idle, false),
        ]);
      },
    );

    test('a failed check from Settings keeps the known update', () async {
      final updates = container.read(updateProvider.notifier);
      await updates.checkOnOpening();
      reply = 'error';
      await updates.check();
      expect(container.read(updateProvider).phase, UpdatePhase.failed);
      expect(container.read(updateProvider).update?.versionName, '1.0.1');
    });

    test('no manifest at the feed says so, not an HTTP error', () async {
      reply = 'missing';
      final updates = container.read(updateProvider.notifier);
      await updates.check();
      final state = container.read(updateProvider);
      expect(state.phase, UpdatePhase.upToDate);
      expect(
        state.text?.call(englishStrings),
        'No update information available.',
      );
      await updates.checkOnOpening();
      expect(container.read(updateProvider).phase, UpdatePhase.idle);
    });

    test(
      'an unsigned manifest offers nothing and says no information',
      () async {
        reply = 'unsigned';
        final updates = container.read(updateProvider.notifier);
        await updates.check();
        final state = container.read(updateProvider);
        expect(state.phase, UpdatePhase.upToDate);
        expect(state.update, isNull);
        expect(
          state.text?.call(englishStrings),
          'No update information available.',
        );
      },
    );

    test(
      'an unsigned manifest after a signed one keeps the known update',
      () async {
        final updates = container.read(updateProvider.notifier);
        await updates.checkOnOpening();
        reply = 'unsigned';
        await updates.checkOnOpening();
        expect(container.read(updateProvider).phase, UpdatePhase.available);
        expect(container.read(updateProvider).update?.versionName, '1.0.1');
      },
    );

    test(
      'the APK comes from the signed URL, through the download seam',
      () async {
        final seen = <Uri>[];
        container.updateOverrides([
          updatePlatformProvider.overrideWithValue(_FakeUpdatePlatform()),
          updateTempDirProvider.overrideWithValue(() async => Directory.systemTemp),
          updateManifestUrlProvider.overrideWithValue(
            Uri.parse('http://127.0.0.1:${server.port}/update.json'),
          ),
          updateKeyringProvider.overrideWithValue(testUpdateKeyring),
          updateClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 11, 1),
          ),
          updateApkUrlProvider.overrideWithValue((url) {
            seen.add(url);
            return Uri.parse('http://127.0.0.1:${server.port}/app.apk');
          }),
        ]);
        await container.read(updateProvider.notifier).check();
        final apk = container.read(updateProvider).update!.apk;
        expect(seen.single.toString(), testApk()['url']);
        expect(apk.url.toString(), 'http://127.0.0.1:${server.port}/app.apk');
        expect(apk.sha256, sha256.convert(apkBytes).toString());
      },
    );

    // Three sources on the local server, in the order of updateManifestSources: BT Labs' own
    // server, the GitLab copy, the GitHub release.
    ProviderContainer sources(String first, String second, [String third = 'gone']) {
      final c = ProviderContainer(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          updateTempDirProvider.overrideWithValue(() async => Directory.systemTemp),
          updateManifestUrlsProvider.overrideWithValue([
            for (final p in [first, second, third]) Uri.parse('http://127.0.0.1:${server.port}/$p/update.json'),
          ]),
          updateKeyringProvider.overrideWithValue(testUpdateKeyring),
          updateClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 1)),
          updateApkUrlProvider.overrideWithValue((url) => url),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('one source down, without the file or private: another source is used', () async {
      // 'signin' is a private GitLab project: a 200 page that is not a manifest.
      for (final down in ['gone', 'down', 'signin']) {
        for (final (a, b, c3) in [(down, 'new', 'gone'), ('new', down, 'gone'), (down, down, 'new')]) {
          final c = sources(a, b, c3);
          await c.read(updateProvider.notifier).check();
          expect(c.read(updateProvider).phase, UpdatePhase.available, reason: '$a, $b, $c3');
        }
      }
    });

    test('every source down: the check failed; down or without the file: nothing newer known', () async {
      final none = sources('down', 'down', 'down');
      await none.read(updateProvider.notifier).check();
      expect(none.read(updateProvider).phase, UpdatePhase.failed);
      final quiet = sources('down', 'signin', 'gone');
      await quiet.read(updateProvider.notifier).check();
      expect(quiet.read(updateProvider).phase, UpdatePhase.upToDate);
    });

    test('several answer: the manifest with the higher serial is used, whichever source has it', () async {
      // /old/ offers 1.0.1 at a lower serial than /new/'s 1.0.1 (serial 1790000100): the
      // stored state is /new/'s either way.
      for (final (a, b, c3) in [('old', 'new', 'old'), ('new', 'old', 'old'), ('old', 'old', 'new')]) {
        final c = sources(a, b, c3);
        await c.read(updateProvider.notifier).check();
        expect(c.read(updateProvider).phase, UpdatePhase.available);
        final stored = await c.read(secretStoreProvider).read(updateStateKey);
        expect(stored, contains('1790000100'), reason: '$a, $b, $c3');
      }
    });

    test('a tampered manifest is refused from any source, even with the higher serial', () async {
      for (final (a, b, c3) in [('bad', 'new', 'gone'), ('new', 'bad', 'gone'), ('gone', 'new', 'bad')]) {
        final c = sources(a, b, c3);
        await c.read(updateProvider.notifier).check();
        expect(c.read(updateProvider).phase, UpdatePhase.available, reason: '$a, $b, $c3');
        final stored = await c.read(secretStoreProvider).read(updateStateKey);
        expect(stored, isNot(contains('1790000900')));
      }
      final all = sources('bad', 'bad', 'bad');
      await all.read(updateProvider.notifier).check();
      expect(all.read(updateProvider).phase, UpdatePhase.upToDate);
    });

    test('the sources live in one list, in the settings file', () {
      expect(updateManifestSources, hostSettings.updateManifests);
      expect(updateManifestUrls.map((u) => '$u'), updateManifestSources);
    });

    test('a manifest past the expiry offers nothing', () async {
      container.updateOverrides([
        updatePlatformProvider.overrideWithValue(_FakeUpdatePlatform()),
        updateTempDirProvider.overrideWithValue(() async => Directory.systemTemp),
        updateManifestUrlProvider.overrideWithValue(
          Uri.parse('http://127.0.0.1:${server.port}/update.json'),
        ),
        updateKeyringProvider.overrideWithValue(testUpdateKeyring),
        updateClockProvider.overrideWithValue(() => DateTime.utc(2027, 5, 1)),
        updateApkUrlProvider.overrideWithValue((url) => url),
      ]);
      await container.read(updateProvider.notifier).check();
      expect(container.read(updateProvider).phase, UpdatePhase.upToDate);
      expect(container.read(updateProvider).update, isNull);
    });

    group('the install permission (Android 8–11 end the app when it is allowed)', () {
      late MemorySecretStore store;
      late Directory temp;

      setUp(() async {
        store = MemorySecretStore();
        temp = await Directory.systemTemp.createTemp('wfe_update_perm');
        addTearDown(() => temp.delete(recursive: true));
      });

      // One app run on the shared store.
      ProviderContainer run(_FakeUpdatePlatform platform) {
        final c = ProviderContainer(
          overrides: [
            updatePlatformProvider.overrideWithValue(platform),
            secretStoreProvider.overrideWithValue(store),
            updateTempDirProvider.overrideWithValue(() async => temp),
            updateManifestUrlProvider.overrideWithValue(Uri.parse('http://127.0.0.1:${server.port}/update.json')),
            updateKeyringProvider.overrideWithValue(testUpdateKeyring),
            updateClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 1)),
            updateApkUrlProvider.overrideWithValue((url) => Uri.parse('http://127.0.0.1:${server.port}/app.apk')),
            updateInstallGraceProvider.overrideWithValue(const Duration(milliseconds: 50)),
          ],
        );
        addTearDown(c.dispose);
        c.listen(updateProvider, (_, _) {});
        return c;
      }

      test('allowed while the app was ended: the next opening downloads and installs it', () async {
        final first = _FakeUpdatePlatform()..canInstall = false;
        final a = run(first);
        await a.read(updateProvider.notifier).checkOnOpening();
        await a.read(updateProvider.notifier).install();
        expect(a.read(updateProvider).phase, UpdatePhase.needsPermission);
        await pumpEventQueue();
        expect(store.values[updatePermissionKey], '2002');
        a.dispose();

        // Android started the app again with the permission; the unlock opens Home.
        final second = _FakeUpdatePlatform();
        final b = run(second);
        await b.read(updateProvider.notifier).checkOnOpening();
        expect(second.installs, 1);
        expect(b.read(updateProvider).phase, UpdatePhase.installing);
        await pumpEventQueue();
        expect(store.values.containsKey(updatePermissionKey), isFalse);
      });

      test('an opening still without the permission installs nothing and keeps the note', () async {
        store.values[updatePermissionKey] = '2002';
        final platform = _FakeUpdatePlatform()..canInstall = false;
        final c = run(platform);
        await c.read(updateProvider.notifier).checkOnOpening();
        expect(platform.installs, 0);
        expect(c.read(updateProvider).phase, UpdatePhase.available);
        expect(store.values[updatePermissionKey], '2002');
      });

      test('a note for another version is dropped, nothing installs', () async {
        store.values[updatePermissionKey] = '1999';
        final platform = _FakeUpdatePlatform();
        final c = run(platform);
        await c.read(updateProvider.notifier).checkOnOpening();
        expect(platform.installs, 0);
        expect(store.values.containsKey(updatePermissionKey), isFalse);
      });

      test('back from the screen without allowing: the check on return keeps "Allow installs"', () async {
        final platform = _FakeUpdatePlatform()..canInstall = false;
        final c = run(platform);
        final updates = c.read(updateProvider.notifier);
        await updates.checkOnOpening();
        await updates.install();
        await Future.wait([updates.resumed(), updates.checkOnOpening()]);
        final state = c.read(updateProvider);
        expect(state.phase, UpdatePhase.needsPermission);
        expect(state.text!(englishStrings), 'Allow installs from Epic Cash Mobile, then return.');
      });

      test('back from the home screen while the install dialog was up: offered again, not stuck', () async {
        final platform = _FakeUpdatePlatform();
        final c = run(platform);
        final updates = c.read(updateProvider.notifier);
        await updates.checkOnOpening();
        await updates.install();
        expect(c.read(updateProvider).phase, UpdatePhase.installing);
        // Android closed its dialog and sent nothing.
        await updates.resumed();
        final state = c.read(updateProvider);
        expect(state.phase, UpdatePhase.available);
        expect(state.text!(englishStrings), 'The update was not installed. You can try again.');
        await updates.install();
        expect(platform.installs, 2);
      });

      test('a word from the installer during the wait wins', () async {
        final platform = _FakeUpdatePlatform();
        final c = run(platform);
        final updates = c.read(updateProvider.notifier);
        await updates.checkOnOpening();
        await updates.install();
        final waiting = updates.resumed();
        platform.events.add((status: 'failed', message: 'INSTALL_FAILED_INSUFFICIENT_STORAGE'));
        await waiting;
        expect(c.read(updateProvider).phase, UpdatePhase.failed);
      });

      test("Android's install dialog closed without installing says so; Install tries again", () async {
        final platform = _FakeUpdatePlatform();
        final c = run(platform);
        final updates = c.read(updateProvider.notifier);
        await updates.checkOnOpening();
        await updates.install();
        expect(c.read(updateProvider).phase, UpdatePhase.installing);
        platform.events.add((status: 'cancelled', message: null));
        await pumpEventQueue();
        final state = c.read(updateProvider);
        expect(state.phase, UpdatePhase.available);
        expect(state.text!(englishStrings), 'The update was not installed. You can try again.');
        await updates.install();
        expect(platform.installs, 2);
      });
    });

    test('the manifest request carries no User-Agent and no cookie', () async {
      await container.read(updateProvider.notifier).check();
      expect(headers!.value(HttpHeaders.userAgentHeader), isNull);
      expect(headers!.value(HttpHeaders.cookieHeader), isNull);
    });

    test('an unreachable feed says so', () async {
      await server.close(force: true);
      await container.read(updateProvider.notifier).check();
      final state = container.read(updateProvider);
      expect(state.phase, UpdatePhase.failed);
      expect(
        state.text?.call(englishStrings),
        englishStrings.updateServerUnreachable,
      );
    });

    test(
      'an update signed with another key asks for a reinstall after the phrase',
      () async {
        final updates = container.read(updateProvider.notifier);
        await updates.check();
        platform.installStatus = 'keyMismatch';
        await updates.install();
        final state = container.read(updateProvider);
        expect(platform.installs, 1);
        expect(state.phase, UpdatePhase.failed);
        expect(state.update?.versionName, '1.0.1');
        expect(
          state.text?.call(englishStrings),
          englishStrings.updateNeedsReinstall,
        );
        expect(
          englishStrings.updateNeedsReinstall,
          contains('write down your recovery phrase first'),
        );
      },
    );

    test(
      "the installer's refusal of another key asks for a reinstall too",
      () async {
        final updates = container.read(updateProvider.notifier);
        await updates.check();
        await updates.install();
        expect(container.read(updateProvider).phase, UpdatePhase.installing);
        platform.events.add((
          status: 'failed',
          message:
              'INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package '
              'uk.btlabs.epiccash.mobile signatures do not match newer version; ignoring!',
        ));
        await pumpEventQueue();
        var state = container.read(updateProvider);
        expect(state.phase, UpdatePhase.failed);
        expect(
          state.text?.call(englishStrings),
          englishStrings.updateNeedsReinstall,
        );
        // Any other refusal still shows the installer's own reason.
        platform.events.add((
          status: 'failed',
          message: 'INSTALL_FAILED_INSUFFICIENT_STORAGE',
        ));
        await pumpEventQueue();
        state = container.read(updateProvider);
        expect(
          state.text?.call(englishStrings),
          englishStrings.updateNotInstalled(
            'INSTALL_FAILED_INSUFFICIENT_STORAGE',
          ),
        );
      },
    );

    test(
      'a manifest over 64 KiB is not read and means no information',
      () async {
        reply = 'huge';
        await container.read(updateProvider.notifier).check();
        final state = container.read(updateProvider);
        expect(state.phase, UpdatePhase.upToDate);
        expect(
          state.text?.call(englishStrings),
          'No update information available.',
        );
      },
    );

    test('a quiet failure with nothing known stays idle', () async {
      reply = 'error';
      await container.read(updateProvider.notifier).checkOnOpening();
      expect(requests, 1);
      expect(container.read(updateProvider).phase, UpdatePhase.idle);
    });
  });


  group('update.json state across restarts', () {
    late HttpServer server;
    late String body;
    late MemorySecretStore store;
    final now = DateTime.utc(2026, 11, 1);

    setUp(() async {
      store = MemorySecretStore();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..write(body)
          ..close();
      });
    });

    tearDown(() => server.close(force: true));

    // One app run: a fresh notifier on the same store, which checks once.
    Future<UpdateState> run() async {
      final platform = _FakeUpdatePlatform();
      final container = ProviderContainer(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          secretStoreProvider.overrideWithValue(store),
          updateManifestUrlProvider.overrideWithValue(Uri.parse('http://127.0.0.1:${server.port}/update.json')),
          updateKeyringProvider.overrideWithValue(testUpdateKeyring),
          updateClockProvider.overrideWithValue(() => now),
        ],
      );
      await container.read(updateProvider.notifier).check();
      final state = container.read(updateProvider);
      container.dispose();
      await platform.events.close();
      return state;
    }

    Future<String> serial(int serial, {String versionName = '1.0.1', List<String>? revoked, SimpleKeyPair? key}) async {
      final payload = testUpdatePayload(serial: serial, versionName: versionName);
      if (revoked != null) payload['revoked_keys'] = revoked;
      return signedUpdate(payload, keys: key == null ? null : [key]);
    }

    test('an older manifest is refused after a restart, a newer one taken', () async {
      body = await serial(1790000100);
      expect((await run()).update?.versionName, '1.0.1');
      final stored = ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!));
      expect(stored?.serial, 1790000100);

      body = await serial(1790000000, versionName: '1.0.2');
      expect((await run()).update, isNull, reason: 'a replayed older manifest offers nothing');
      expect(ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!))?.serial, 1790000100);

      body = await serial(1790000200, versionName: '1.0.3');
      expect((await run()).update?.versionName, '1.0.3');
      expect(ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!))?.serial, 1790000200);
    });

    test('the same serial with other bytes is refused after a restart', () async {
      body = await serial(1790000100);
      await run();
      body = await serial(1790000100, versionName: '1.0.9');
      expect((await run()).update, isNull);
    });

    test('a key revoked by a manifest stays revoked after a restart', () async {
      final keyA = testUpdateKeyring.keys.firstWhere((k) => k.rank == 1).keyid;
      final keyB = await testKeyFromPem(File('test/fixtures/btlabs/test-b.key').readAsStringSync());
      body = await serial(1790000100, revoked: [keyA], key: keyB);
      expect((await run()).update?.versionName, '1.0.1');
      expect(ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!))?.revoked, {keyA});
      // Signed by the revoked key A, newer: still refused in a new run.
      body = await serial(1790000300, versionName: '1.0.4');
      expect((await run()).update, isNull);
    });

    test("a key update.json revoked signs no btlabs.json either", () async {
      final keyA = testUpdateKeyring.keys.firstWhere((k) => k.rank == 1).keyid;
      final d = [donation('btlabs', 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.stack.invalid')];
      final file = await signedPublicFile(d, serial: 3);
      final at = DateTime.utc(2026, 11);
      expect(await verifyBtlabsPublic(file, keyring: testKeyring(), now: at), isA<Accepted<BtlabsPublic>>());
      final r = await verifyBtlabsPublic(file, keyring: testKeyring(), now: at, alsoRevoked: {keyA});
      expect(r, isA<Rejected<BtlabsPublic>>());
      final ok = await verifyBtlabsPublic(file, keyring: testKeyring(), now: at) as Accepted<BtlabsPublic>;
      expect(await loadCachedBtlabsPublic(file, keyring: testKeyring(), state: ok.state), isNotNull);
      expect(await loadCachedBtlabsPublic(file, keyring: testKeyring(), state: ok.state, alsoRevoked: {keyA}), isNull);
    });

    test('a stored state that does not read is ignored, then replaced', () async {
      for (final bad in ['{not json', '{"serial": "x"}', '[]']) {
        store.values[updateStateKey] = bad;
        body = await serial(1790000100);
        expect((await run()).update?.versionName, '1.0.1', reason: bad);
        expect(ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!))?.serial, 1790000100, reason: bad);
      }
    });

    test('a store that cannot be read is not written over', () async {
      store.values[updateStateKey] = jsonEncode(
        ManifestState(serial: 1790000500, keyid: testUpdateKeyring.keys.first.keyid, digest: 'a' * 64).toJson(),
      );
      final broken = _ThrowingStore(store);
      body = await serial(1790000100);
      final platform = _FakeUpdatePlatform();
      final container = ProviderContainer(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          secretStoreProvider.overrideWithValue(broken),
          updateManifestUrlProvider.overrideWithValue(Uri.parse('http://127.0.0.1:${server.port}/update.json')),
          updateKeyringProvider.overrideWithValue(testUpdateKeyring),
          updateClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await container.read(updateProvider.notifier).check();
      expect(ManifestState.fromJson(jsonDecode(store.values[updateStateKey]!))?.serial, 1790000500);
      expect(broken.writes, 0);
    });
  });

  group('relays', () {
    test('parses host and port, and refuses junk', () {
      final a = EpicboxRelay.parse(' Box.Net.Invalid ')!;
      expect(a.host, 'box.net.invalid');
      expect(a.port, 443);
      expect(a.label, 'box.net.invalid');
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

/// An installed 1.0.0 (2001) on arm64 that never installs anything: [install] answers
/// [installStatus], and [events] stands for the installer's later results.
/// A secret store whose reads fail, as a locked or broken keystore's would.
class _ThrowingStore implements SecretStore {
  _ThrowingStore(this.inner);
  final MemorySecretStore inner;
  int writes = 0;

  @override
  Future<String?> read(String key) async => throw StateError('locked');

  @override
  Future<void> write(String key, String value) async {
    writes++;
    await inner.write(key, value);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);
}

class _FakeUpdatePlatform implements UpdatePlatform {
  String installStatus = 'started';
  int installs = 0;
  bool canInstall = true;
  final events =
      StreamController<({String status, String? message})>.broadcast();

  @override
  Future<InstalledApp> installedApp() async => InstalledApp(
    packageName: 'uk.btlabs.epiccash.mobile',
    versionCode: 2001,
    versionName: '1.0.0',
    abis: const ['arm64-v8a'],
    canInstall: canInstall,
  );

  @override
  Future<String> install(File apk) async {
    installs++;
    return installStatus;
  }

  @override
  Future<void> requestInstallPermission() async {}

  @override
  Stream<({String status, String? message})> get installEvents => events.stream;
}
