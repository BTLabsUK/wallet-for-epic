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
    final dir = Directory('${support.path}/wallets/${chain.name}');
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
    // A GUI root with two accounts, and the epic program's mainnet and floonet wallets.
    final gui = '$home/.epic-gui';
    final a = await oldWallet('$gui/wallets/w1', '{"seed":"alpha"}');
    final b = await oldWallet('$gui/wallets/w2', '{"seed":"beta"}');
    await write('$gui/settings.json', jsonEncode({
      'wallets': [
        {'id': 'w1', 'label': 'Savings', 'network': 'mainnet', 'dataDir': a},
        {'id': 'w2', 'label': 'Everyday', 'network': 'mainnet', 'dataDir': b},
      ],
    }));
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

  test('finds the GUI and epic program wallets; floonet is listed but blocked; a copy is marked', () async {
    final found = await wallet.findOldWallets();
    expect(found.map((w) => w.name), containsAll(['Savings', 'Everyday', 'Wallet (epic program)']));
    final floo = found.firstWhere((w) => w.network == 'floonet');
    expect(floo.importable, isFalse);
    expect(floo.blocked, contains('Only mainnet'));
    expect(byName(found, 'Savings').importable, isTrue);
    expect(byName(found, 'Savings').group, OldWalletGroup.gui);
    final cli = cliMain(found);
    expect(cli.group, OldWalletGroup.cli);
    expect(cli.sameAs, 'Same wallet as Savings');
    expect(cli.inApp, isFalse);
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
    final history = r.proof.firstWhere((p) => p.text.contains('5.3 or older'));
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
    expect(service.createdConfig!.dataDir, '${support.path}/wallets/$id/mainnet');
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
    expect(Directory('${support.path}/wallets').listSync().map((e) => e.path.split('/').last), ['mainnet']);
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
    expect(service.deletedWallets, unorderedEquals(['${support.path}/wallets/${a.id}/mainnet', '${support.path}/wallets/${b.id}/mainnet']));
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
    picked = await oldWallet('${support.path}/wallets/x/mainnet', '{"seed":"own"}');
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
}
