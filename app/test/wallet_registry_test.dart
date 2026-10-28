// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart';
import 'package:epic_wallet/src/wallet_service.dart';

/// Records `deleteWallet`; nothing else is called.
class _Service implements WalletService {
  final deleted = <WalletConfig>[];

  @override
  Future<void> deleteWallet({required WalletConfig config}) async =>
      deleted.add(config);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final sep = Platform.pathSeparator;

WalletConfig _config(WalletEntry e) => WalletConfig(
  dataDir: e.dataDir,
  chain: e.chain,
  nodeUrl: 'http://127.0.0.1:1',
  epicboxDomain: 'example.invalid',
  epicboxPort: 443,
  walletId: e.walletId,
);

void main() {
  late Directory tmp;
  late WalletRegistry registry;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('wfe_registry_');
    registry = WalletRegistry(tmp.path);
    await registry.load();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('a missing file is an empty list', () {
    expect(registry.list(), isEmpty);
    expect(registry.lastUsedId, isNull);
  });

  test('add makes the folder, a 32-hex id, and default labels', () async {
    final a = await registry.add(chain: Chain.floonet);
    final b = await registry.add(chain: Chain.floonet);
    expect(a.id, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(a.id, isNot(b.id));
    expect(a.label, 'Wallet 1');
    expect(b.label, 'Wallet 2');
    expect(Directory(a.dataDir).existsSync(), isTrue);
    expect(a.dataDir, '${tmp.path}${sep}wallets$sep${a.id}${sep}floonet');
    await registry.forget(a.id);
    final c = await registry.add(chain: Chain.mainnet);
    expect(c.label, 'Wallet 1', reason: 'the lowest free number');
  });

  test('the phrase fingerprint is kept, found and survives a reload; a malformed one is ignored', () async {
    final fp = 'ab' * 32;
    final a = await registry.add(chain: Chain.mainnet);
    final b = await registry.add(chain: Chain.mainnet);
    expect(a.phraseFingerprint, isNull, reason: 'none until the app writes one');
    expect(registry.byPhraseFingerprint(fp), isNull);
    await registry.setPhraseFingerprint(a.id, fp);
    expect(registry.byPhraseFingerprint(fp)!.id, a.id);
    expect(registry.list().firstWhere((e) => e.id == b.id).phraseFingerprint, isNull);
    await expectLater(registry.setPhraseFingerprint(b.id, 'AB' * 32), throwsA(isA<WalletRegistryException>()));
    await expectLater(registry.setPhraseFingerprint('0' * 32, fp), throwsA(isA<WalletNotListedException>()));
    final again = WalletRegistry(tmp.path);
    await again.load();
    expect(again.byPhraseFingerprint(fp)!.id, a.id);
    // A fingerprint the file holds in a shape this code never writes is left out, not matched.
    final file = File('${tmp.path}$sep${WalletRegistry.fileName}');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    (json['wallets'] as List).cast<Map<String, dynamic>>().firstWhere((w) => w['id'] == a.id)['phraseFingerprint'] = 'short';
    file.writeAsStringSync(jsonEncode(json));
    final third = WalletRegistry(tmp.path);
    await third.load();
    expect(third.list().firstWhere((e) => e.id == a.id).phraseFingerprint, isNull);
  });

  test('the list survives a reload', () async {
    final a = await registry.add(chain: Chain.floonet, label: '  Savings ');
    await registry.markOpened(a.id);
    final again = WalletRegistry(tmp.path);
    await again.load();
    expect(again.list().single.label, 'Savings');
    expect(again.list().single.lastOpenedAt, isNotNull);
    expect(again.lastUsedId, a.id);
  });

  test('rename trims and limits to 1 to 32 characters', () async {
    final a = await registry.add(chain: Chain.floonet);
    expect((await registry.rename(a.id, ' Daily ')).label, 'Daily');
    expect((await registry.rename(a.id, 'x' * 32)).label.length, 32);
    await expectLater(
      registry.rename(a.id, 'x' * 33),
      throwsA(isA<WalletRegistryException>()),
    );
    await expectLater(
      registry.rename(a.id, '   '),
      throwsA(isA<WalletRegistryException>()),
    );
    await registry.rename(a.id, 'Daily');
    await registry.add(chain: Chain.floonet, label: 'Daily');
    expect(registry.list().where((e) => e.label == 'Daily'), hasLength(2));
  });

  test('forget keeps files; rescan finds it and restore lists it', () async {
    final a = await registry.add(chain: Chain.floonet);
    Directory('${a.dataDir}${sep}lepic').createSync();
    await registry.forget(a.id);
    expect(registry.list(), isEmpty);
    expect(Directory(a.dataDir).existsSync(), isTrue);
    final found = await registry.rescan();
    expect(found.single.id, a.id);
    expect(registry.list(), isEmpty, reason: 'rescan adds nothing');
    await registry.restore(found.single);
    expect(registry.list().single.id, a.id);
    expect(await registry.rescan(), isEmpty);
  });

  test('folderMissing', () async {
    final a = await registry.add(chain: Chain.floonet);
    expect(registry.folderMissing(a), isFalse);
    Directory(a.dataDir).deleteSync();
    expect(registry.folderMissing(a), isTrue);
  });

  test(
    'a corrupt file is set aside, never deleted, and rebuilt by scan',
    () async {
      final a = await registry.add(chain: Chain.floonet);
      Directory('${a.dataDir}${sep}lepic').createSync();
      File('${tmp.path}${sep}wallets.json').writeAsStringSync('{ not json');
      final again = WalletRegistry(tmp.path);
      await again.load();
      final aside = tmp.listSync().whereType<File>().where(
        (f) => f.path.contains('wallets.json.damaged-'),
      );
      expect(aside, hasLength(1));
      expect(aside.single.readAsStringSync(), '{ not json');
      expect(again.list().single.id, a.id);
      expect(File('${tmp.path}${sep}wallets.json').existsSync(), isTrue);
    },
  );

  test('writes leave no temp file', () async {
    await registry.add(chain: Chain.floonet);
    final names = tmp.listSync().map(
      (e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    );
    expect(names, containsAll(['wallets.json', 'wallets']));
    expect(names.where((n) => n.endsWith('.tmp')), isEmpty);
  });

  test(
    'legacy wallet 1 is adopted at its old path; wallet_data kept',
    () async {
      final old = Directory('${tmp.path}${sep}wallets${sep}floonet')
        ..createSync(recursive: true);
      Directory('${old.path}${sep}lepic').createSync();
      Directory('${old.path}${sep}wallet_data').createSync();
      File('${old.path}${sep}wallet_data${sep}wallet.seed')
          .writeAsStringSync('seed');
      expect(await registry.adoptLegacy(Chain.mainnet), isNull);
      final e = (await registry.adoptLegacy(Chain.floonet))!;
      expect(e.id, 'legacy-floonet');
      expect(e.label, 'Wallet 1');
      expect(e.dataDir, old.path);
      expect(await registry.adoptLegacy(Chain.floonet), isNull);
      expect(await registry.rescan(), isEmpty);

      final service = _Service();
      await registry.delete(e.id, service: service, config: _config(e));
      expect(service.deleted, hasLength(1));
      expect(registry.list(), isEmpty);
      expect(Directory('${old.path}${sep}lepic').existsSync(), isFalse);
      expect(
        File('${old.path}${sep}wallet_data${sep}wallet.seed')
            .readAsStringSync(),
        'seed',
      );
    },
  );

  test('delete removes an id wallet and its folders', () async {
    final a = await registry.add(chain: Chain.floonet);
    Directory('${a.dataDir}${sep}lepic').createSync();
    File('${a.dataDir}${sep}lepic${sep}db').writeAsStringSync('x');
    final service = _Service();
    await registry.delete(a.id, service: service, config: _config(a));
    expect(service.deleted.single.walletId, a.id);
    expect(
      Directory('${tmp.path}${sep}wallets$sep${a.id}').existsSync(),
      isFalse,
    );
    expect(registry.list(), isEmpty);
  });

  test('delete refuses a folder outside the wallets root', () async {
    final outside = Directory('${tmp.path}${sep}elsewhere${sep}floonet')
      ..createSync(recursive: true);
    File('${outside.path}${sep}keep').writeAsStringSync('x');
    final a = await registry.add(chain: Chain.floonet);
    // A hand-edited list that points the wallet outside.
    final file = File('${tmp.path}${sep}wallets.json');
    file.writeAsStringSync(
      file.readAsStringSync().replaceAll(a.dataDir, outside.path),
    );
    final again = WalletRegistry(tmp.path);
    await again.load();
    final service = _Service();
    await expectLater(
      again.delete(
        a.id,
        service: service,
        config: _config(again.list().single),
      ),
      throwsA(isA<UnsafeWalletPathException>()),
    );
    expect(service.deleted, isEmpty);
    expect(File('${outside.path}${sep}keep').existsSync(), isTrue);
    expect(again.list(), hasLength(1));
  });

  test('delete refuses a path through a symlink', () async {
    final target = Directory('${tmp.path}${sep}target${sep}floonet')
      ..createSync(recursive: true);
    Directory('${target.path}${sep}lepic').createSync();
    final a = await registry.add(chain: Chain.floonet);
    final idDir = Directory('${tmp.path}${sep}wallets$sep${a.id}')
      ..deleteSync(recursive: true);
    Link(idDir.path).createSync('${tmp.path}${sep}target');
    final service = _Service();
    await expectLater(
      registry.delete(a.id, service: service, config: _config(a)),
      throwsA(isA<UnsafeWalletPathException>()),
    );
    expect(service.deleted, isEmpty);
    expect(Directory('${target.path}${sep}lepic').existsSync(), isTrue);
  });

  test(
    'delete refuses a ".." path through a link and removes nothing',
    () async {
      final a = await registry.add(chain: Chain.floonet);
      final outside = Directory('${tmp.path}${sep}outside');
      final real = Directory('${outside.path}${sep}x')
        ..createSync(recursive: true);
      final victim = Directory(
        '${outside.path}$sep${a.id}${sep}floonet${sep}lepic',
      )..createSync(recursive: true);
      File('${victim.path}${sep}keep').writeAsStringSync('x');
      Link('${tmp.path}${sep}wallets${sep}L').createSync(real.path);
      final sneaky =
          '${tmp.path}${sep}wallets${sep}L$sep..$sep${a.id}${sep}floonet';
      final file = File('${tmp.path}${sep}wallets.json');
      file.writeAsStringSync(
        file.readAsStringSync().replaceAll(a.dataDir, sneaky),
      );
      final again = WalletRegistry(tmp.path);
      await again.load();
      expect(again.list().single.dataDir, sneaky);
      final service = _Service();
      await expectLater(
        again.delete(
          a.id,
          service: service,
          config: _config(again.list().single),
        ),
        throwsA(isA<UnsafeWalletPathException>()),
      );
      expect(service.deleted, isEmpty);
      expect(File('${victim.path}${sep}keep').existsSync(), isTrue);
    },
  );

  test('delete refuses a config with another folder than the entry', () async {
    final a = await registry.add(chain: Chain.floonet);
    final c = _config(a);
    final other = WalletConfig(
      dataDir: '${a.dataDir}$sep..${sep}floonet',
      chain: c.chain,
      nodeUrl: c.nodeUrl,
      epicboxDomain: c.epicboxDomain,
      epicboxPort: c.epicboxPort,
      walletId: c.walletId,
    );
    final service = _Service();
    await expectLater(
      registry.delete(a.id, service: service, config: other),
      throwsA(isA<UnsafeWalletPathException>()),
    );
    expect(service.deleted, isEmpty);
  });

  test('a wallet 1 config must use a null walletId', () async {
    Directory('${tmp.path}${sep}wallets${sep}floonet${sep}lepic')
        .createSync(recursive: true);
    final e = (await registry.adoptLegacy(Chain.floonet))!;
    expect(e.walletId, isNull);
    final service = _Service();
    final withId = WalletConfig(
      dataDir: e.dataDir,
      chain: e.chain,
      nodeUrl: 'http://127.0.0.1:1',
      epicboxDomain: 'example.invalid',
      epicboxPort: 443,
      walletId: e.id,
    );
    await expectLater(
      registry.delete(e.id, service: service, config: withId),
      throwsA(isA<UnsafeWalletPathException>()),
    );
    expect(service.deleted, isEmpty);
  });

  group('wallets.json damage', () {
    File listFile() => File('${tmp.path}${sep}wallets.json');
    final goodId = 'a' * 32;

    Map<String, Object?> raw(String id, {String chain = 'floonet'}) => {
      'id': id,
      'label': 'L',
      'chain': chain,
      'dataDir': '/x',
      'createdAt': '2026-01-01T00:00:00Z',
    };

    test('only ids of 32 lowercase hex or legacy-<own chain> parse', () {
      expect(WalletEntry.tryParse(raw(goodId)), isNotNull);
      expect(WalletEntry.tryParse(raw('legacy-floonet')), isNotNull);
      expect(WalletEntry.tryParse(raw('legacy-mainnet')), isNull);
      expect(WalletEntry.tryParse(raw('A' * 32)), isNull);
      expect(WalletEntry.tryParse(raw('a' * 31)), isNull);
      expect(WalletEntry.tryParse(raw('../x')), isNull);
      expect(WalletEntry.tryParse(raw('x')), isNull);
    });

    test('one bad entry is skipped and written back unchanged', () async {
      final bad = {'id': '../../etc', 'label': 'evil'};
      listFile().writeAsStringSync(
        jsonEncode({
          'version': 1,
          'wallets': [raw(goodId), bad],
        }),
      );
      final again = WalletRegistry(tmp.path);
      await again.load();
      expect(again.list().single.id, goodId);
      await again.rename(goodId, 'Renamed');
      final saved = jsonDecode(listFile().readAsStringSync()) as Map;
      expect((saved['wallets'] as List), hasLength(2));
      expect((saved['wallets'] as List).last, bad);
      expect(tmp.listSync().where((f) => f.path.contains('damaged')), isEmpty);
    });

    test('invalid UTF-8 is set aside and legacy wallet 1 is adopted', () async {
      Directory('${tmp.path}${sep}wallets${sep}floonet${sep}lepic')
          .createSync(recursive: true);
      listFile().writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
      final again = WalletRegistry(tmp.path);
      await again.load();
      expect(again.list().single.id, 'legacy-floonet');
      final aside = tmp.listSync().where((f) => f.path.contains('.damaged-'));
      expect((aside.single as File).readAsBytesSync(), [
        0x7b,
        0xff,
        0xfe,
        0x7d,
      ]);
    });

    test('a corrupt file also adopts legacy wallet 1', () async {
      Directory('${tmp.path}${sep}wallets${sep}floonet${sep}lepic')
          .createSync(recursive: true);
      listFile().writeAsStringSync('{ nope');
      final again = WalletRegistry(tmp.path);
      await again.load();
      expect(again.list().single.id, 'legacy-floonet');
      final reload = WalletRegistry(tmp.path);
      await reload.load();
      expect(reload.list().single.id, 'legacy-floonet');
    });

    test('a newer version is read but never written', () async {
      final text = jsonEncode({
        'version': 2,
        'wallets': [raw(goodId)],
      });
      listFile().writeAsStringSync(text);
      final again = WalletRegistry(tmp.path);
      await again.load();
      expect(again.list(), hasLength(1));
      await expectLater(
        again.rename(goodId, 'New'),
        throwsA(isA<WalletRegistryVersionException>()),
      );
      expect(again.list().single.label, 'L');
      expect(listFile().readAsStringSync(), text);
    });

    test('every change on a newer file is refused before anything is touched', () async {
      final a = await registry.add(chain: Chain.floonet);
      final dir = Directory(a.dataDir)..createSync(recursive: true);
      File('${dir.path}${sep}lepic${sep}wallet.db').createSync(recursive: true);
      final text = (jsonDecode(listFile().readAsStringSync()) as Map)..['version'] = 2;
      listFile().writeAsStringSync(jsonEncode(text));
      final again = WalletRegistry(tmp.path);
      await again.load();
      final service = _Service();
      final before = Directory('${tmp.path}${sep}wallets').listSync(recursive: true).length;
      final isVersion = throwsA(isA<WalletRegistryVersionException>());
      await expectLater(again.delete(a.id, service: service, config: _config(a)), isVersion);
      expect(service.deleted, isEmpty);
      expect(File('${dir.path}${sep}lepic${sep}wallet.db').existsSync(), isTrue);
      await expectLater(again.add(chain: Chain.floonet), isVersion);
      await expectLater(again.rename(a.id, 'New'), isVersion);
      await expectLater(again.forget(a.id), isVersion);
      await expectLater(again.markOpened(a.id), isVersion);
      await expectLater(again.restore(a), isVersion);
      await expectLater(again.adoptLegacy(Chain.floonet, exists: (_) async => true), isVersion);
      expect(Directory('${tmp.path}${sep}wallets').listSync(recursive: true).length, before, reason: 'no folder made or removed');
      expect(again.list().single.label, a.label);
    });

    test('a wallet id that is not listed has its own exception', () async {
      await expectLater(registry.rename(goodId, 'x'), throwsA(isA<WalletNotListedException>()));
    });

    test('a damaged file does not adopt a legacy wallet in skipLegacy', () async {
      Directory('${tmp.path}${sep}wallets${sep}floonet${sep}lepic').createSync(recursive: true);
      listFile().writeAsStringSync('not json');
      final again = WalletRegistry(tmp.path);
      await again.load(skipLegacy: {Chain.floonet});
      expect(again.list(), isEmpty);
    });

    test('memory is unchanged when the save fails', () async {
      final a = await registry.add(chain: Chain.floonet);
      // A directory where the temp file goes makes the write fail.
      Directory('${tmp.path}${sep}wallets.json.tmp').createSync();
      await expectLater(registry.rename(a.id, 'Other'), throwsA(anything));
      expect(registry.byId(a.id)!.label, 'Wallet 1');
      await expectLater(registry.markOpened(a.id), throwsA(anything));
      expect(registry.lastUsedId, isNull);
      await expectLater(registry.forget(a.id), throwsA(anything));
      expect(registry.list(), hasLength(1));
    });
  });

  test('labels with control or direction characters are refused', () async {
    final a = await registry.add(chain: Chain.floonet);
    for (final bad in [
      'a\nb',
      'a\u0000b',
      'a\u2028b',
      'a\u2029b',
      'a\u202Eb',
      'a\u2066b',
      'a\u200Fb',
      'a\u200Eb',
      'a\u0085b',
    ]) {
      await expectLater(
        registry.rename(a.id, bad),
        throwsA(isA<WalletRegistryException>()),
        reason: bad.runes.toString(),
      );
    }
    expect((await registry.rename(a.id, 'Zażółć 钱包')).label, 'Zażółć 钱包');
  });

  group('store prefixes', () {
    WalletConfig cfg(Chain chain, String dir, {String? id}) => WalletConfig(
      dataDir: dir,
      chain: chain,
      nodeUrl: 'http://127.0.0.1:1',
      epicboxDomain: 'example.invalid',
      epicboxPort: 443,
      walletId: id,
    );

    test('wallet 1 keeps its pinned or path prefix', () async {
      final store = MemorySecretStore({
        LepicWalletService.storePrefixKey(Chain.floonet):
            'lepic:floonet:id-old:',
      });
      final service = LepicWalletService(
        secrets: store,
        runtime: () => throw StateError('no runtime needed'),
        oneWalletPerChain: true,
      );
      expect(
        await service.storePrefixFor(cfg(Chain.floonet, '/w/floonet')),
        'lepic:floonet:id-old:',
      );
      expect(
        await service.storePrefixFor(
          cfg(Chain.floonet, '/w/floonet', id: 'legacy-floonet'),
        ),
        'lepic:floonet:id-old:',
      );
      final plain = LepicWalletService(secrets: MemorySecretStore());
      expect(
        await plain.storePrefixFor(cfg(Chain.floonet, '/w/floonet')),
        'lepic:floonet:/w/floonet:',
      );
    });

    test('a registry folder without its walletId is refused', () async {
      final service = LepicWalletService(
        secrets: MemorySecretStore(),
        runtime: () => throw StateError('no runtime needed'),
        oneWalletPerChain: true,
      );
      final dir = '${tmp.path}${sep}wallets$sep${'b' * 32}${sep}floonet';
      await expectLater(
        service.storePrefixFor(cfg(Chain.floonet, dir)),
        throwsStateError,
      );
    });

    test('registry wallets of one chain get separate prefixes', () async {
      final store = MemorySecretStore();
      final service = LepicWalletService(
        secrets: store,
        runtime: () => throw StateError('no runtime needed'),
        oneWalletPerChain: true,
      );
      final a = await registry.add(chain: Chain.floonet);
      final b = await registry.add(chain: Chain.floonet);
      final pa = await service.storePrefixFor(_config(a));
      final pb = await service.storePrefixFor(_config(b));
      expect(pa, 'lepic:floonet:id-${a.id}:');
      expect(pb, 'lepic:floonet:id-${b.id}:');
      expect(pa, isNot(pb));
      // Neither prefix is a prefix of a key under the other, so vaults never overlap.
      expect('${pb}vault'.startsWith(pa), isFalse);
      expect('${pa}vault'.startsWith(pb), isFalse);
      expect(store.values, isEmpty, reason: 'no pin entry for id wallets');
    });
  });
}
