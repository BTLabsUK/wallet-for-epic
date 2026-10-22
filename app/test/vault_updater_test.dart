import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('checks a PIN by sealing again under it', () async {
      final session = (await vault.create(config, pin: '123456')).session;
      await vault.checkPin(session, config, '123456');
      expect(service.confirmedPinChanges, [fakeSealedPassword('123456')]);
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

    String manifest(int versionCode) => jsonEncode({
      'schema': 1,
      'packageName': 'com.blacktyger.epic_wallet',
      'versionName': versionCode == 2002 ? '1.0.1' : '1.0.0',
      'notes': '',
      'apks': [
        {
          'abi': 'arm64-v8a',
          'versionCode': versionCode,
          'url': 'app.apk',
          'sha256': sha256.convert(apkBytes).toString(),
          'size': apkBytes.length,
        },
      ],
    });

    setUp(() async {
      requests = 0;
      reply = 'newer';
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
        switch (reply) {
          case 'newer':
            response.write(manifest(2002));
          case 'same':
            response.write(manifest(2001));
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
              'com.blacktyger.epic_wallet signatures do not match newer version; ignoring!',
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

    test('a quiet failure with nothing known stays idle', () async {
      reply = 'error';
      await container.read(updateProvider.notifier).checkOnOpening();
      expect(requests, 1);
      expect(container.read(updateProvider).phase, UpdatePhase.idle);
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

/// An installed 1.0.0 (2001) on arm64 that never installs anything: [install] answers
/// [installStatus], and [events] stands for the installer's later results.
class _FakeUpdatePlatform implements UpdatePlatform {
  String installStatus = 'started';
  int installs = 0;
  final events =
      StreamController<({String status, String? message})>.broadcast();

  @override
  Future<InstalledApp> installedApp() async => const InstalledApp(
    packageName: 'com.blacktyger.epic_wallet',
    versionCode: 2001,
    versionName: '1.0.0',
    abis: ['arm64-v8a'],
  );

  @override
  Future<String> install(File apk) async {
    installs++;
    return installStatus;
  }

  @override
  Stream<({String status, String? message})> get installEvents => events.stream;
}
