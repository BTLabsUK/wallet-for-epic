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

WalletConfig _config(WalletEntry e) => WalletConfig(
  dataDir: e.dataDir,
  chain: e.chain,
  nodeUrl: 'http://127.0.0.1:1',
  epicboxDomain: 'example.invalid',
  epicboxPort: 443,
  walletId: e.id,
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
    expect(a.dataDir, '${tmp.path}/wallets/${a.id}/floonet');
    await registry.forget(a.id);
    final c = await registry.add(chain: Chain.mainnet);
    expect(c.label, 'Wallet 1', reason: 'the lowest free number');
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
    Directory('${a.dataDir}/lepic').createSync();
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
      Directory('${a.dataDir}/lepic').createSync();
      File('${tmp.path}/wallets.json').writeAsStringSync('{ not json');
      final again = WalletRegistry(tmp.path);
      await again.load();
      final aside = tmp.listSync().whereType<File>().where(
        (f) => f.path.contains('wallets.json.damaged-'),
      );
      expect(aside, hasLength(1));
      expect(aside.single.readAsStringSync(), '{ not json');
      expect(again.list().single.id, a.id);
      expect(File('${tmp.path}/wallets.json').existsSync(), isTrue);
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
      final old = Directory('${tmp.path}/wallets/floonet')
        ..createSync(recursive: true);
      Directory('${old.path}/lepic').createSync();
      Directory('${old.path}/wallet_data').createSync();
      File('${old.path}/wallet_data/wallet.seed').writeAsStringSync('seed');
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
      expect(Directory('${old.path}/lepic').existsSync(), isFalse);
      expect(
        File('${old.path}/wallet_data/wallet.seed').readAsStringSync(),
        'seed',
      );
    },
  );

  test('delete removes an id wallet and its folders', () async {
    final a = await registry.add(chain: Chain.floonet);
    Directory('${a.dataDir}/lepic').createSync();
    File('${a.dataDir}/lepic/db').writeAsStringSync('x');
    final service = _Service();
    await registry.delete(a.id, service: service, config: _config(a));
    expect(service.deleted.single.walletId, a.id);
    expect(Directory('${tmp.path}/wallets/${a.id}').existsSync(), isFalse);
    expect(registry.list(), isEmpty);
  });

  test('delete refuses a folder outside the wallets root', () async {
    final outside = Directory('${tmp.path}/elsewhere/floonet')
      ..createSync(recursive: true);
    File('${outside.path}/keep').writeAsStringSync('x');
    final a = await registry.add(chain: Chain.floonet);
    // A hand-edited list that points the wallet outside.
    final file = File('${tmp.path}/wallets.json');
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
    expect(File('${outside.path}/keep').existsSync(), isTrue);
    expect(again.list(), hasLength(1));
  });

  test('delete refuses a path through a symlink', () async {
    final target = Directory('${tmp.path}/target/floonet')
      ..createSync(recursive: true);
    Directory('${target.path}/lepic').createSync();
    final a = await registry.add(chain: Chain.floonet);
    final idDir = Directory('${tmp.path}/wallets/${a.id}')
      ..deleteSync(recursive: true);
    Link(idDir.path).createSync('${tmp.path}/target');
    final service = _Service();
    await expectLater(
      registry.delete(a.id, service: service, config: _config(a)),
      throwsA(isA<UnsafeWalletPathException>()),
    );
    expect(service.deleted, isEmpty);
    expect(Directory('${target.path}/lepic').existsSync(), isTrue);
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
