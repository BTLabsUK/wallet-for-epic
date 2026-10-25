import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [path] with '/' between its parts: the app joins with the platform's separator, the tests
/// with '/', so paths compare by their parts (Windows, item 28).
String _p(String path) => path.replaceAll(r'\', '/');

/// Symlinks need administrator rights on Windows, and chmod is POSIX.
final Object _posixOnly = Platform.isWindows ? 'POSIX links and modes' : false;

/// Fixture trees live in temp dirs only; no real wallet is ever opened.
void main() {
  late Directory tmp;
  late String home;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('legacy_wallets_');
    home = '${tmp.path}/home';
    await Directory(home).create();
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> write(String path, String text) async {
    await File(path).create(recursive: true);
    await File(path).writeAsString(text);
  }

  /// A wallet folder: wallet_data/wallet.seed (+ an sqlite db), optionally a toml.
  Future<String> wallet(String dir, {String seed = 'seed-a', String? chainType, bool sqlite = true}) async {
    await write('$dir/wallet_data/wallet.seed', seed);
    if (sqlite) await write('$dir/wallet_data/db/sqlite/epic.db', 'db-$seed');
    if (chainType != null) await write('$dir/epic-wallet.toml', 'chain_type = "$chainType"\n');
    return dir;
  }

  LegacyRoots roots() => LegacyRoots(home: home, appData: '${tmp.path}/appdata');

  Future<Map<String, String>> hashes(List<String> dirs) async => {for (final d in dirs) d: await folderHash(d)};

  Future<void> expectUnchanged(Map<String, String> before) async {
    for (final e in before.entries) {
      expect(await folderHash(e.key), e.value, reason: '${e.key} changed');
    }
  }

  test('GUI 6.1 root is not searched; picked by hand its wallets are listed', () async {
    final root = '$home/.epic-gui';
    final a = await wallet('$root/wallets/w1', seed: 'alpha');
    await wallet('$root/wallets/w2', seed: 'beta', chainType: 'Floonet');
    await write('$root/settings.json', jsonEncode({
      'wallets': [
        {'id': 'w1', 'label': 'Savings', 'network': 'mainnet', 'dataDir': a},
      ],
    }));
    await write('$root/location.json', jsonEncode({'root': root}));
    final before = await hashes([root]);
    final scan = await findLegacyWallets(roots: LegacyRoots(home: home, appData: '${tmp.path}/appdata', guiHome: root));
    expect(scan.wallets, isEmpty);

    final pick = await inspectFolder(root);
    expect(pick.wallets.map((w) => _p(w.path).split('/').last).toSet(), {'w1', 'w2'});
    expect(pick.wallets.every((w) => w.source == LegacySource.picked), isTrue);
    expect(pick.wallets.firstWhere((w) => _p(w.path).split('/').last == 'w2').network, LegacyNetwork.floo);
    expect(guiRootOfWallet(a), root);
    expect(guiRootOfWallet('$home/folders/one'), isNull);
    await expectUnchanged(before);
  });

  test('~/.epic with main and floo is the epic program; account list gives names', () async {
    final epic = '$home/.epic';
    await wallet('$epic/main', seed: 'cli-main');
    await wallet('$epic/floo', seed: 'cli-floo');
    final old = '$home/old-gui';
    await wallet('$old/main', seed: 'acc', sqlite: false);
    await write('$epic/epic_3-0-0_config.json', jsonEncode({
      'account_dirs': [
        {'account': 'Everyday', 'userhomedir': old, 'network': 'mainnet'},
        {'account': 'x', 'userhomedir': 'relative/dir'},
      ],
    }));
    final before = await hashes([epic, old]);
    final scan = await findLegacyWallets(roots: roots());

    final cli = scan.of(LegacySource.cli);
    expect(cli.map((w) => w.network).toSet(), {LegacyNetwork.main, LegacyNetwork.floo});
    expect(cli.firstWhere((w) => w.network == LegacyNetwork.main).label, 'main');
    final gui = scan.of(LegacySource.gui).single;
    expect(gui.label, 'Everyday');
    expect(gui.legacyDb, isTrue);
    expect(scan.wallets, hasLength(3));
    await expectUnchanged(before);
  });

  test('older layouts: <account>/<net> and <net>/<account>; the same folder is listed once', () async {
    final epic = '$home/.epic';
    await wallet('$epic/alpha/floo', seed: 'one');
    await wallet('$epic/main/beta', seed: 'two');
    await write('$epic/epic_3-0-0_config.json', jsonEncode({
      'account_dirs': [
        {'account': 'alpha', 'userhomedir': epic, 'network': 'floonet'},
      ],
    }));
    final before = await hashes([epic]);
    final scan = await findLegacyWallets(roots: roots());
    expect(scan.wallets, hasLength(2));
    final alpha = scan.wallets.firstWhere((w) => w.label == 'alpha');
    expect(alpha.network, LegacyNetwork.floo);
    final beta = scan.wallets.firstWhere((w) => w.label == 'beta');
    expect(beta.network, LegacyNetwork.main);
    expect(beta.app, '3.0.x');
    await expectUnchanged(before);
  });

  test('network falls back to the toml, then to mainnet (unknown)', () async {
    await wallet('$home/folders/one', chainType: 'UserTesting');
    await wallet('$home/folders/two');
    final scan = await inspectFolder('$home/folders');
    final one = scan.wallets.firstWhere((w) => w.path.endsWith('one'));
    final two = scan.wallets.firstWhere((w) => w.path.endsWith('two'));
    expect(one.network, LegacyNetwork.user);
    expect(one.networkKnown, isTrue);
    expect(two.networkKnown, isFalse);
  });

  test('chain data: next to a wallet and alone', () async {
    final epic = '$home/.epic';
    await wallet('$epic/main');
    await write('$epic/main/chain_data/lmdb/data.mdb', 'x' * 100);
    await write('$epic/floo/chain_data/lmdb/data.mdb', 'y' * 50);
    final before = await hashes([epic]);
    final scan = await findLegacyWallets(roots: roots());
    expect(scan.wallets.single.chain!.sizeBytes, 100);
    expect(scan.chains.map((c) => c.sizeBytes).toList()..sort(), [50, 100]);
    expect(scan.wallets, hasLength(1));
    await expectUnchanged(before);

    final pick = await inspectFolder('$epic/floo/chain_data');
    expect(pick.chainOnly, isTrue);
    expect(pick.wallets, isEmpty);
    expect(pick.message, 'Blockchain data, not a wallet.');
    final next = await inspectFolder('$epic/main/chain_data');
    expect(next.chainOnly, isTrue);
    expect(_p(next.wallets.single.path), _p('$epic/main'));
    await expectUnchanged(before);
  });

  test('inspectFolder: a wallet, a folder of wallets, inside a wallet, nothing', () async {
    final w = await wallet('$home/picked/Mine', seed: 'm');
    await wallet('$home/many/main', seed: 'a');
    await wallet('$home/many/other', seed: 'b');
    await Directory('$home/empty').create();
    final before = await hashes([home]);

    final one = await inspectFolder(w);
    expect(one.wallets.single.source, LegacySource.picked);
    expect(one.message, isNull);
    expect(_p((await inspectFolder('$w/wallet_data/db')).wallets.single.path), _p(w));
    expect((await inspectFolder('$home/many')).wallets, hasLength(2));
    final none = await inspectFolder('$home/empty');
    expect(none.wallets, isEmpty);
    expect(none.chainOnly, isFalse);
    expect(none.message, noWalletText);
    expect((await inspectFolder('$home/missing')).message, noWalletText);
    await expectUnchanged(before);
  });

  test('a symlink inside a wallet refuses it with the spec text', () async {
    final epic = '$home/.epic';
    final w = await wallet('$epic/main', seed: 'linked');
    await write('$home/elsewhere/file', 'data');
    await Link('$w/wallet_data/saved_txs').create('$home/elsewhere');
    final before = await hashes([epic, '$home/elsewhere']);
    final scan = await findLegacyWallets(roots: roots());
    final f = scan.wallets.single;
    expect(f.hasLinks, isTrue);
    expect(f.copyable, isFalse);
    expect(f.refusal, LegacyRefusal.links);
    expect(f.refusal!.text, "This wallet's folder has links in it, so it is not imported. Restore it from the recovery phrase.");
    await expectUnchanged(before);
  }, skip: _posixOnly);

  test('the wallet folder, wallet_data or wallet_tor being a link refuses it', () async {
    final real = await wallet('$home/real/main', seed: 'real');
    await Link('$home/.epic-gui/wallets/via-link').create(real, recursive: true);
    final scan = await findLegacyWallets(roots: roots());
    final f = scan.wallets.where((w) => w.path.endsWith('via-link')).toList();
    // a link to a folder is not descended into, so it is not found at all
    expect(f, isEmpty);
    final w2 = '$home/.epic/floo';
    await write('$home/other/wallet_data/wallet.seed', 'x');
    await Directory(w2).create(recursive: true);
    await Link('$w2/wallet_data').create('$home/other/wallet_data');
    final scan2 = await findLegacyWallets(roots: roots());
    final linked = scan2.wallets.singleWhere((w) => _p(w.path) == _p(w2));
    expect(linked.hasLinks, isTrue);
    expect(linked.copyable, isFalse);
  }, skip: _posixOnly);

  test('an unreadable part of wallet_data refuses the wallet as incomplete', () async {
    final w = await wallet('$home/.epic/main', seed: 'inc');
    final locked = Directory('$w/wallet_data/locked')..createSync();
    File('${locked.path}/f').writeAsStringSync('x');
    await Process.run('chmod', ['000', locked.path]);
    addTearDown(() => Process.run('chmod', ['755', locked.path]));
    try {
      Directory(locked.path).listSync();
      return; // running as someone who can read it anyway
    } on FileSystemException {/* as expected */}
    final f = (await findLegacyWallets(roots: roots())).wallets.single;
    expect(f.incomplete, isTrue);
    expect(f.copyable, isFalse);
    expect(f.refusal, LegacyRefusal.incomplete);
    expect(f.refusal!.text, isNotEmpty);
  }, skip: _posixOnly);

  test('displayLabel names a network-folder label by its source', () async {
    await wallet('$home/.epic/main', seed: 'a');
    final f = (await findLegacyWallets(roots: roots())).wallets.single;
    expect(f.label, 'main');
    expect(f.displayLabel, 'Wallet (epic program)');
  });

  test('seed sanity: empty is no wallet, over 4 KiB is refused and not hashed', () async {
    final epic = '$home/.epic';
    await wallet('$epic/main', seed: '');
    await wallet('$epic/floo', seed: 'z' * 5000);
    final before = await hashes([epic]);
    final scan = await findLegacyWallets(roots: roots());
    final big = scan.wallets.single;
    expect(big.network, LegacyNetwork.floo);
    expect(big.seedTooLarge, isTrue);
    expect(big.refusal, LegacyRefusal.seedTooLarge);
    expect(big.seedFingerprint, isNull);
    await expectUnchanged(before);
  });

  test('empty home: nothing found, no error', () async {
    final scan = await findLegacyWallets(roots: roots());
    expect(scan.isEmpty, isTrue);
    expect(scan.groups, isEmpty);
    expect(scan.chains, isEmpty);
    final gone = await findLegacyWallets(roots: LegacyRoots(home: '${tmp.path}/nope'));
    expect(gone.isEmpty, isTrue);
  });

  test('identical seed files are the same wallet; the app list wins', () async {
    final epic = '$home/.epic';
    await wallet('$epic/main', seed: 'same');
    await wallet('$home/copy/main', seed: 'same');
    await wallet('$home/other/main', seed: 'different');
    await write('$epic/epic_3-0-0_config.json', jsonEncode({
      'account_dirs': [
        {'account': 'Backup', 'userhomedir': '$home/copy', 'network': 'mainnet'},
        {'account': 'Else', 'userhomedir': '$home/other', 'network': 'mainnet'},
      ],
    }));
    final before = await hashes([home]);
    final scan = await findLegacyWallets(roots: roots());
    final same = findSameWallets(scan.wallets);
    expect(same, hasLength(1));
    final cliWallet = scan.of(LegacySource.cli).single;
    expect(same[cliWallet.path]!.text, 'Same wallet as Backup');
    expect(same[cliWallet.path]!.inApp, isFalse);

    final fp = scan.wallets.firstWhere((w) => w.label == 'Else').seedFingerprint!;
    final inApp = findSameWallets(scan.wallets, inApp: {fp: 'Savings'});
    expect(inApp[scan.wallets.firstWhere((w) => w.label == 'Else').path]!.text, 'Already in the app as Savings');
    await expectUnchanged(before);
  });

  test('older Electron profiles are reported, not read', () async {
    await Directory('${tmp.path}/appdata/EpicWallet/IndexedDB').create(recursive: true);
    final before = await hashes(['${tmp.path}/appdata']);
    final scan = await findLegacyWallets(roots: roots());
    expect(scan.profiles.map((p) => p.app), ['≤5.3.1']);
    await expectUnchanged(before);
  });

  group('checkInUse', () {
    late LegacyWallet w;
    late String dir;
    setUp(() async {
      dir = await wallet('$home/.epic/main');
      w = (await findLegacyWallets(roots: roots())).wallets.single;
    });

    Future<InUse> check(List<RunningProcess>? procs) => checkInUse(w, listProcesses: () async => procs);

    test('a running epic-wallet in the folder', () async {
      expect(await check([RunningProcess(pid: 1, name: '/usr/bin/epic-wallet', args: ['owner_api'], cwd: dir)]), InUse.inUse);
      expect(
          await check([RunningProcess(pid: 2, name: 'epic-wallet', args: ['--top_level_dir', '$dir/wallet_data'], cwd: '/')]),
          InUse.inUse);
    });
    test('no matching process is free', () async {
      expect(await check([]), InUse.free);
      expect(await check([RunningProcess(pid: 3, name: 'epic-wallet', args: ['--floonet'], cwd: '$home/.epic/floo')]), InUse.free);
      expect(await check([RunningProcess(pid: 4, name: 'bash', args: [], cwd: dir)]), InUse.free);
      expect(await check([RunningProcess(pid: 5, name: 'epic-wallet', args: ['--floonet'], cwd: '$dir-other')]), InUse.free);
    });
    test('no folder given and no toml in the cwd: ~/.epic/<net> by the network flags', () async {
      expect(await check([const RunningProcess(pid: 7, name: 'epic-wallet', args: ['owner_api'], cwd: '/')]), InUse.inUse);
      expect(await check([const RunningProcess(pid: 8, name: 'epic', args: ['--floonet'], cwd: '/')]), InUse.free);
      expect(await check([const RunningProcess(pid: 9, name: 'epic', args: ['--usernet'], cwd: '/')]), InUse.free);
      expect(await check([const RunningProcess(pid: 10, name: 'epic', args: [], cwd: null)]), InUse.unknown);
      expect(await check([const RunningProcess(pid: 11, name: 'epic', args: [], cwd: '/', argsKnown: false)]), InUse.unknown);
    });
    test('unknown when it cannot tell', () async {
      expect(await check(null), InUse.unknown);
      expect(await check([const RunningProcess(pid: 6, name: 'epic-wallet', args: [], cwd: null)]), InUse.unknown);
      expect(await checkInUse(w, listProcesses: () async => throw Exception('no')), InUse.unknown);
    });
    test('the real probe leaves the folder alone', () async {
      final before = await folderHash(dir);
      await checkInUse(w);
      expect(await folderHash(dir), before);
    });
  });

  group('folderHash', () {
    test('database files are never opened, only stat\'ed', () async {
      final d = await wallet('$home/h2', seed: 'one');
      await write('$d/wallet_data/db/lmdb/data.mdb', 'aaaa');
      final db = File('$d/wallet_data/db/sqlite/epic.db');
      final h0 = await folderHash(d);
      final when = db.lastModifiedSync();
      db.writeAsStringSync('b' * db.lengthSync());
      db.setLastModifiedSync(when);
      expect(await folderHash(d), h0, reason: 'same path, size and mtime: content not read');
      db.writeAsStringSync('longer content');
      expect(await folderHash(d), isNot(h0));
    });

    test('a file over 64 KiB is not read either', () async {
      final d = await wallet('$home/h3', seed: 'one');
      final big = File('$d/wallet_data/big.bin')..writeAsBytesSync(List.filled(70 * 1024, 1));
      final h0 = await folderHash(d);
      final when = big.lastModifiedSync();
      big.writeAsBytesSync(List.filled(70 * 1024, 2));
      big.setLastModifiedSync(when);
      expect(await folderHash(d), h0);
    });

    test('is stable and changes with content, size, names and links', () async {
      final d = await wallet('$home/h', seed: 'one');
      final h0 = await folderHash(d);
      expect(await folderHash(d), h0);
      await write('$d/wallet_data/new.txt', 'x');
      final h1 = await folderHash(d);
      expect(h1, isNot(h0));
      await File('$d/wallet_data/new.txt').writeAsString('y');
      expect(await folderHash(d), isNot(h1));
      await File('$d/wallet_data/new.txt').rename('$d/wallet_data/renamed.txt');
      expect(await folderHash(d), isNot(h1));
      final h2 = await folderHash(d);
      await Link('$d/ln').create('$d/wallet_data');
      expect(await folderHash(d), isNot(h2));
    }, skip: _posixOnly);
  });
}
