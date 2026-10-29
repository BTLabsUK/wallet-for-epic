// SPDX-License-Identifier: Apache-2.0
// The import of old wallets through LepicDeskWallet on FakeWalletService. Old wallets are
// fixture folders in a temp dir; the real home folder is never scanned. The passwords and
// seeds here are throwaway test values.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _old = 'old password';

/// Counts the seed imports and the seed files they were given.
class _Counting extends core.FakeWalletService {
  _Counting() : super(password: _password);

  final List<String> seeds = [];

  @override
  Future<core.WalletSession> importWalletSeed({required core.WalletConfig config, required String seedFile, required String seedPassword, required String password}) async {
    final s = await super.importWalletSeed(config: config, seedFile: seedFile, seedPassword: seedPassword, password: password);
    seeds.add(seedFile);
    return s;
  }
}

void main() {
  late Directory tmp;
  late String home;
  late Directory support;
  late MemorySecretStore secrets;
  late _Counting service;
  late LepicDeskWallet wallet;
  String? picked;

  Future<String> walletDir(core.Chain chain) async {
    final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
    await dir.create(recursive: true);
    return dir.path;
  }

  LepicDeskWallet make({ProcessLister? processes}) => LepicDeskWallet(
    service: service,
    walletDir: walletDir,
    secrets: secrets,
    filesDir: () async => tmp,
    nodePoll: const Duration(hours: 1),
    legacyRoots: () => LegacyRoots(home: home, appData: '${tmp.path}/appdata'),
    pickDirectory: () async => picked,
    listProcesses: processes ?? () async => const [],
  );

  Future<void> write(String path, String text) async {
    await File(path).create(recursive: true);
    await File(path).writeAsString(text);
  }

  /// An epic-wallet folder: wallet_data/wallet.seed and a database.
  Future<String> oldWallet(String dir, String seed) async {
    await write('$dir/wallet_data/wallet.seed', seed);
    await write('$dir/wallet_data/db/sqlite/epic.db', 'db-$seed');
    return dir;
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('desk-import-');
    home = '${tmp.path}/home';
    support = await Directory('${tmp.path}/support').create();
    secrets = MemorySecretStore();
    service = _Counting();
    picked = null;
    // Two accounts of the public GUI (the account list in ~/.epic), and the epic program's mainnet
    // and floonet wallets. A GUI 6.1 folder is not searched (see the pick test).
    await oldWallet('$home/acc-a/main', '{"seed":"alpha"}');
    await oldWallet('$home/acc-b/main', '{"seed":"beta"}');
    await write('$home/.epic/epic_3-0-0_config.json', jsonEncode({
      'account_dirs': [
        {'account': 'Savings', 'userhomedir': '$home/acc-a', 'network': 'mainnet'},
        {'account': 'Everyday', 'userhomedir': '$home/acc-b', 'network': 'mainnet'},
      ],
    }));
    final gui = '$home/.epic-gui';
    await oldWallet('$gui/wallets/w9', '{"seed":"gui61"}');
    await oldWallet('$home/.epic/main', '{"seed":"alpha"}');
    await oldWallet('$home/.epic/floo', '{"seed":"floo"}');
    wallet = make();
  });

  tearDown(() async {
    await wallet.dispose();
    await tmp.delete(recursive: true);
  });

  OldWallet byName(List<OldWallet> all, String name) => all.firstWhere((w) => w.name == name);

  /// The epic program's mainnet wallet (its floonet one has the same name).
  OldWallet cliMain(List<OldWallet> all) => all.firstWhere((w) => w.folder == '$home/.epic/main');

  test('finds the GUI and epic program wallets; floonet is not offered; a copy is marked', () async {
    final found = await wallet.findOldWallets();
    expect(found.map((w) => w.name), containsAll(['Savings', 'Everyday', 'Wallet (epic program)']));
    expect(found.any((w) => w.folder.contains('.epic-gui')), isFalse, reason: 'GUI 6.1 folder is not searched');
    expect(found.where((w) => w.network != 'mainnet'), isEmpty, reason: 'a release build names no network, and ~/.epic/floo would');
    expect(byName(found, 'Savings').importable, isTrue);
    expect(byName(found, 'Savings').group, OldWalletGroup.gui);
    final cli = cliMain(found);
    expect(cli.group, OldWalletGroup.cli);
    expect(cli.sameAs, 'Same wallet as Savings');
    expect(cli.inApp, isFalse);
  });

  test('a GUI 6.1 folder picked by hand is listed', () async {
    picked = '$home/.epic-gui';
    final pick = (await wallet.pickFolder())!;
    expect(pick.wallets.single.group, OldWalletGroup.picked);
    expect(pick.wallets.single.folder, '$home/.epic-gui/wallets/w9');
  });

  test('the old history is imported with the seed and shown in the proof', () async {
    service.session.legacyImport = const core.LegacyHistoryImport(status: core.LegacyHistoryStatus.imported, transactions: 41);
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    final r = await wallet.importOldWallet(savings.id, oldPassword: _old);
    expect(r.proof.map((p) => p.text), contains('History: 41 transactions'));
    final meta = jsonDecode((await secrets.read('desk.wallet.mainnet.${r.id}'))!) as Map<String, dynamic>;
    expect(meta['historyImport'], 'imported');
    expect(await wallet.unlock(_old), isTrue);
    await wallet.sync();
    expect(service.session.legacyImports, hasLength(1), reason: 'imported once, not again at the sync');
  });

  test('a history the core cannot read is a warning in the proof, never a failed import', () async {
    service.session.legacyImport = const core.LegacyHistoryImport(status: core.LegacyHistoryStatus.oldFormat);
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    final r = await wallet.importOldWallet(savings.id, oldPassword: _old);
    final history = r.proof.firstWhere((p) => p.text.contains('older database format'));
    expect(history.ok, isFalse);
    expect((await wallet.wallets()).single.name, 'Savings');
  });

  test('a wallet an earlier build imported gets its history at the next sync, once', () async {
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    final r = await wallet.importOldWallet(savings.id, oldPassword: _old);
    // As 0.1.0 left it: imported from the folder, no history import recorded.
    final key = 'desk.wallet.mainnet.${r.id}';
    final meta = jsonDecode((await secrets.read(key))!) as Map<String, dynamic>..remove('historyImport');
    await secrets.write(key, jsonEncode(meta));
    service.session.legacyImports.clear();
    service.session.legacyImport = const core.LegacyHistoryImport(status: core.LegacyHistoryStatus.imported, transactions: 7);
    expect(await wallet.unlock(_old), isTrue);
    await wallet.sync();
    await wallet.sync();
    expect(service.session.legacyImports, [savings.folder]);
    final after = jsonDecode((await secrets.read(key))!) as Map<String, dynamic>;
    expect(after['historyImport'], 'imported');
  });

  test('a history the running old wallet held back is imported at the next unlock', () async {
    service.session.legacyImport = const core.LegacyHistoryImport(status: core.LegacyHistoryStatus.sourceBusy);
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    final r = await wallet.importOldWallet(savings.id, oldPassword: _old);
    expect(r.proof.map((p) => p.text), contains(contains('imported at the next unlock')));
    final key = 'desk.wallet.mainnet.${r.id}';
    expect((jsonDecode((await secrets.read(key))!) as Map<String, dynamic>)['historyImport'], isNull);
    service.session.legacyImport = const core.LegacyHistoryImport(status: core.LegacyHistoryStatus.imported, transactions: 3);
    expect(await wallet.unlock(_old), isTrue);
    await wallet.sync();
    await wallet.sync();
    expect(service.session.legacyImports, [savings.folder, savings.folder], reason: 'once at import, once after unlock');
    expect((jsonDecode((await secrets.read(key))!) as Map<String, dynamic>)['historyImport'], 'imported');
  });

  test('success: a new list entry with walletId, scan due, fingerprint; the old folder is unchanged', () async {
    final before = await folderHash(home);
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    final r = await wallet.importOldWallet(savings.id, oldPassword: _old);
    expect(r.name, 'Savings');
    expect(r.proof.map((p) => (p.text, p.ok)), [
      ('Seed read', true),
      ('Wallet created', true),
      ('No history in the old folder; the scan restores the balance', true),
      ('Old folder unchanged', true),
    ]);
    expect(service.session.legacyImports, [savings.folder], reason: 'the history is read from the old folder');
    expect(service.seeds, ['{"seed":"alpha"}']);
    expect(service.importedSeedPassword, _old);
    expect(service.password, _old, reason: 'the old password has 8+ characters: it stays');
    final id = service.createdConfig!.walletId!;
    expect(r.id, id);
    expect(service.createdConfig!.dataDir, '${support.path}/wallets/$id');
    final meta = jsonDecode((await secrets.read('desk.wallet.mainnet.$id'))!) as Map<String, dynamic>;
    expect(meta['scanPending'], isTrue);
    expect(meta['name'], 'Savings');
    expect(meta['seedFingerprint'], sha256.convert(utf8.encode('{"seed":"alpha"}')).toString());
    expect(meta['historyImport'], 'noHistory');
    expect((await wallet.wallets()).map((e) => (e.id, e.name, e.current)), [(id, 'Savings', true)]);
    expect(await secrets.read('desk.wallet.mainnet'), isNull, reason: 'wallet 1 keys untouched');
    expect(await folderHash(home), before);
    // The first unlock scans for the history.
    expect(await wallet.unlock(_old), isTrue);
    await wallet.sync();
    expect(service.session.scanCalls, 1);
  });

  test('a wrong old password asks again and makes nothing', () async {
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    await expectLater(
      wallet.importOldWallet(savings.id, oldPassword: 'not the password'),
      throwsA(isA<DeskError>().having((e) => e.wrongPassword, 'wrongPassword', isTrue)),
    );
    expect(await wallet.wallets(), isEmpty);
    final wallets = Directory('${support.path}/wallets');
    expect(wallets.existsSync() ? wallets.listSync() : const [], isEmpty, reason: 'no wallet folder made');
    expect(secrets.values.keys.where((k) => k.startsWith('desk.wallet.')), isEmpty);
    // The right one then works.
    await wallet.importOldWallet(savings.id, oldPassword: _old);
    expect((await wallet.wallets()).single.name, 'Savings');
  });

  test('a short old password needs a new password of 8+', () async {
    service.seedFilePassword = 'short';
    final savings = byName(await wallet.findOldWallets(), 'Savings');
    await expectLater(
      wallet.importOldWallet(savings.id, oldPassword: 'short'),
      throwsA(isA<DeskError>().having((e) => e.newPasswordNeeded, 'newPasswordNeeded', isTrue)),
    );
    await expectLater(
      wallet.importOldWallet(savings.id, oldPassword: 'short', newPassword: 'tiny'),
      throwsA(isA<DeskError>().having((e) => e.newPasswordNeeded, 'newPasswordNeeded', isTrue)),
    );
    expect(service.seeds, isEmpty);
    await wallet.importOldWallet(savings.id, oldPassword: 'short', newPassword: _password);
    expect(service.importedSeedPassword, 'short');
    expect(service.password, _password);
  });

  test('the same seed is not imported twice in one run', () async {
    final found = await wallet.findOldWallets();
    await wallet.importOldWallet(byName(found, 'Savings').id, oldPassword: _old);
    await expectLater(
      wallet.importOldWallet(cliMain(found).id, oldPassword: _old),
      throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Already in the app as Savings')),
    );
    expect(service.seeds, hasLength(1));
    expect((await wallet.wallets()).map((e) => e.name), ['Savings']);
  });

  test('each wallet opens its seed once', () async {
    final found = await wallet.findOldWallets();
    await wallet.importOldWallet(byName(found, 'Savings').id, oldPassword: _old);
    await wallet.importOldWallet(byName(found, 'Everyday').id, oldPassword: _old);
    expect(service.seeds, ['{"seed":"alpha"}', '{"seed":"beta"}']);
    expect((await wallet.wallets()).map((e) => e.name), ['Savings', 'Everyday']);
  });

  test('cancel removes only this run\'s wallets; old folders and wallet 1 stay', () async {
    await wallet.createWallet(name: 'Main', password: _password);
    final mainMeta = await secrets.read('desk.wallet.mainnet');
    final before = await folderHash(home);
    final found = await wallet.findOldWallets();
    final a = await wallet.importOldWallet(byName(found, 'Savings').id, oldPassword: _old);
    final b = await wallet.importOldWallet(byName(found, 'Everyday').id, oldPassword: _old);
    expect((await wallet.wallets()).map((e) => e.name), ['Main', 'Savings', 'Everyday']);
    await wallet.cancelImport();
    expect((await wallet.wallets()).map((e) => e.name), ['Main']);
    expect(service.deletedWallets, unorderedEquals(['${support.path}/wallets/${a.id}', '${support.path}/wallets/${b.id}']));
    expect(await secrets.read('desk.wallet.mainnet.${a.id}'), isNull);
    expect(await secrets.read('desk.wallet.mainnet'), mainMeta);
    expect(await folderHash(home), before);
    // A new run starts empty: cancelling it removes nothing.
    await wallet.findOldWallets();
    await wallet.cancelImport();
    expect((await wallet.wallets()).map((e) => e.name), ['Main']);
  });

  test('a wallet the app imported is "Already in the app" at the next search', () async {
    final found = await wallet.findOldWallets();
    await wallet.importOldWallet(byName(found, 'Savings').id, oldPassword: _old);
    final again = await wallet.findOldWallets();
    expect(byName(again, 'Savings').sameAs, 'Already in the app as Savings');
    expect(byName(again, 'Savings').inApp, isTrue);
    expect(cliMain(again).sameAs, 'Already in the app as Savings');
    expect(byName(again, 'Everyday').sameAs, isNull);
  });

  test('a chosen folder: its wallets, chain data only, nothing, the app\'s own folder', () async {
    expect(await wallet.pickFolder(), isNull, reason: 'dialog closed');
    final backup = await oldWallet('${tmp.path}/backup/old', '{"seed":"gamma"}');
    picked = backup;
    final pick = (await wallet.pickFolder())!;
    expect(pick.message, isNull);
    expect(pick.wallets.single.group, OldWalletGroup.picked);
    expect(pick.wallets.single.importable, isTrue);
    await Directory('${tmp.path}/chain/chain_data/lmdb').create(recursive: true);
    picked = '${tmp.path}/chain/chain_data';
    expect((await wallet.pickFolder())!.message, chainOnlyText);
    picked = await Directory('${tmp.path}/empty').create().then((d) => d.path);
    expect((await wallet.pickFolder())!.message, noWalletText);
    picked = await oldWallet('${support.path}/wallets/x', '{"seed":"own"}');
    final own = (await wallet.pickFolder())!;
    expect(own.wallets, isEmpty);
    expect(own.message, 'This wallet is in the app already.');
  });

  test('in use: a wallet program working in the folder', () async {
    final busy = make(processes: () async => [RunningProcess(pid: 7, name: 'epic-wallet', args: const ['listen'], cwd: '$home/.epic/main')]);
    addTearDown(busy.dispose);
    final found = await busy.findOldWallets();
    expect(await busy.checkOldWallet(cliMain(found).id), OldWalletUse.inUse);
    expect(await busy.checkOldWallet(byName(found, 'Savings').id), OldWalletUse.free);
    await expectLater(busy.checkOldWallet('nope'), throwsA(isA<DeskError>()));
  });
  group('the older app\'s Epicbox server', () {
    const box = 'epicbox.example.org';
    const listKey = 'desk.serverList.relay.mainnet';

    /// Savings, picked by hand: a GUI 6.1 folder is not searched.
    Future<OldWallet> savings() async {
      picked = '$home/.epic-gui';
      return (await wallet.pickFolder())!.wallets.firstWhere((w) => w.folder.endsWith('/w1'));
    }

    /// Savings used [box] in GUI 6.1.
    Future<void> savingsOnBox() async {
      final gui = '$home/.epic-gui';
      await oldWallet('$gui/wallets/w1', '{"seed":"alpha"}');
      await oldWallet('$gui/wallets/w2', '{"seed":"beta"}');
      await write('$gui/settings.json', jsonEncode({
        'wallets': [
          {'id': 'w1', 'label': 'Savings', 'network': 'mainnet', 'dataDir': '$gui/wallets/w1', 'settings': {'epicbox_domain': box}},
          {'id': 'w2', 'label': 'Everyday', 'network': 'mainnet', 'dataDir': '$gui/wallets/w2'},
        ],
      }));
    }

    Map<String, dynamic> meta(String id) => jsonDecode(secrets.values['desk.wallet.mainnet.$id']!) as Map<String, dynamic>;
    List<String> listed() => [for (final e in (jsonDecode(secrets.values[listKey]!)['entries'] as List)) '$e'];

    test('kept from the import: the wallet listens there, the list has it, the app\'s server stays', () async {
      await savingsOnBox();
      final r = await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      expect(r.oldRelay, box);
      expect(r.appRelay, isNot(box));
      expect(r.proof.map((p) => p.text), isNot(contains(contains('Epicbox'))), reason: 'the choice replaces the proof line');
      expect(meta(r.id)['epicbox'], box);
      expect(listed(), contains(box));
      expect(listed(), contains(r.appRelay), reason: 'the defaults stay listed');
      expect(await wallet.unlock(_old), isTrue);
      expect(service.session.openedConfig!.epicboxDomain, box);
      expect((await wallet.status()).epicbox.domain, box);
      expect((await wallet.status()).epicboxOwn, isTrue);
      expect(await secrets.read('app.relay.mainnet'), r.appRelay);
    });

    test('Use the app\'s server: back on it, the list entry the import added goes again', () async {
      await savingsOnBox();
      final r = await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      await wallet.keepOldRelay(r.id, keep: false);
      expect(meta(r.id)['epicbox'], isNull);
      expect(listed(), isNot(contains(box)));
      expect(await wallet.unlock(_old), isTrue);
      expect(service.session.openedConfig!.epicboxDomain, r.appRelay);
      expect((await wallet.status()).epicboxOwn, isFalse);
      // And Keep again.
      await wallet.lock();
      await wallet.keepOldRelay(r.id, keep: true);
      expect(listed(), contains(box));
    });

    test('a server listed before stays listed when the wallet goes back to the app\'s', () async {
      await savingsOnBox();
      await secrets.write(listKey, jsonEncode({'entries': ['epicbox.epiccash.com', box]}));
      final r = await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      await wallet.keepOldRelay(r.id, keep: false);
      expect(listed(), contains(box));
    });

    test('a Settings pick while the wallet is open is its own; the app\'s server stays', () async {
      await savingsOnBox();
      final r = await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      expect(await wallet.unlock(_old), isTrue);
      await wallet.useEpicbox('epicbox.other.example');
      expect(meta(r.id)['epicbox'], 'epicbox.other.example');
      expect(await secrets.read('app.relay.mainnet'), r.appRelay);
      expect(service.session.openedConfig!.epicboxDomain, 'epicbox.other.example');
    });

    test('Cancel takes the server it listed back out', () async {
      await savingsOnBox();
      await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      await wallet.cancelImport();
      expect(listed(), isNot(contains(box)));
    });

    test('the same server as the app\'s: no choice', () async {
      await oldWallet('$home/.epic-gui/wallets/w1', '{"seed":"alpha"}');
      final r = await wallet.importOldWallet((await savings()).id, oldPassword: _old);
      expect(r.oldRelay, isNull);
      expect(meta(r.id)['epicbox'], isNull);
    });
  });

  group('one fingerprint for the same wallet', () {
    List<String> words() => service.phrase.split(' ');

    // Savings' seed file holds the test phrase.
    setUp(() => service.seedFilePhrase = service.phrase);

    test('an imported wallet is "already here" for a restore of its phrase', () async {
      final r = await wallet.importOldWallet(byName(await wallet.findOldWallets(), 'Savings').id, oldPassword: _old);
      final entry = (await wallet.registry()).byId(r.id)!;
      expect(entry.walletFingerprint, core.fakeWalletFingerprint(service.phrase, core.Chain.mainnet));
      expect((await wallet.walletWithPhrase(words()))?.id, r.id);
      await expectLater(
        wallet.restoreWallet(password: _password, phrase: words()),
        throwsA(isA<DeskError>().having((e) => e.sameWallet?.id, 'sameWallet', r.id)),
      );
      expect((await wallet.wallets()).map((e) => e.name), ['Savings']);
    });

    test('an import of a phrase restored before is refused and leaves nothing', () async {
      await wallet.restoreWallet(name: 'Main', password: _password, phrase: words());
      await expectLater(
        wallet.importOldWallet(byName(await wallet.findOldWallets(), 'Savings').id, oldPassword: _old),
        throwsA(isA<DeskError>().having((e) => e.message, 'message', 'Already in the app as Main')),
      );
      expect((await wallet.wallets()).map((e) => e.name), ['Main']);
    });

    test('a wallet made before fingerprints gets one at its next unlock', () async {
      await wallet.createWallet(name: 'Main', password: _password);
      await wallet.dispose();
      // As an older build left the list: no fingerprint of either kind.
      final file = File('${support.path}/wallets.json');
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      for (final e in json['wallets'] as List) {
        (e as Map).remove('phraseFingerprint');
        e.remove('walletFingerprint');
      }
      await file.writeAsString(jsonEncode(json));
      wallet = make();
      expect(await wallet.walletWithPhrase(words()), isNull, reason: 'nothing to compare yet');
      expect(await wallet.unlock(_password), isTrue);
      await wallet.lock();
      expect((await wallet.walletWithPhrase(words()))?.name, 'Main');
    });
  });

  test('an older GUI wallet takes its name from the old profile', () async {
    const fixtures = 'test/fixtures/legacy_gui';
    final dir = await oldWallet('$home/.epic/alpha/main', '{"seed":"alpha-old"}');
    await File('$fixtures/gui531/.epic/alpha/main/config.json').copy('$dir/config.json');
    for (final (fixture, profile) in [('gui531_table', 'EpicWallet'), ('gui600_log', 'epic-desktop-wallet')]) {
      final from = Directory('$fixtures/idb/$fixture');
      await for (final e in from.list(recursive: true)) {
        if (e is! File) continue;
        final dest = File('${tmp.path}/appdata/$profile/IndexedDB${e.path.substring(from.path.length)}');
        await dest.parent.create(recursive: true);
        await e.copy(dest.path);
      }
    }
    final found = await wallet.findOldWallets();
    final alpha = found.firstWhere((w) => w.folder == dir);
    final r = await wallet.importOldWallet(alpha.id, oldPassword: _old);
    expect(r.name, 'Alpha (6.0)');
    expect(r.oldRelay, 'epicbox.fastepic.eu');
  });

  test('Done knows whether the wallet got a new password', () async {
    final found = await wallet.findOldWallets();
    final kept = await wallet.importOldWallet(byName(found, 'Savings').id, oldPassword: _old);
    expect(kept.newPassword, isFalse);
    service.seedFilePassword = 'short';
    final fresh = await wallet.importOldWallet(byName(found, 'Everyday').id, oldPassword: 'short', newPassword: _password);
    expect(fresh.newPassword, isTrue);
  });
}
