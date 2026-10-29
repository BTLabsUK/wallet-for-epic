// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/node/chain_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chain data trees live in temp dirs only; no real ~/.epic or ~/.epic-gui is ever read.
void main() {
  late Directory tmp;
  late String home;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('chain_data_');
    home = '${tmp.path}/home';
    await Directory(home).create();
  });
  tearDown(() => tmp.delete(recursive: true));

  LegacyRoots roots({String? guiHome}) =>
      LegacyRoots(home: home, guiHome: guiHome);

  test('a full layout with enough mainnet headers is usable', () async {
    final dir = await fakeChain('${tmp.path}/a/chain_data', headerBytes: 64000);
    final info = await inspectChainData(
      dir,
      chain: Chain.mainnet,
      source: ChainDataSource.custom,
    );
    expect(info, isNotNull);
    expect(info!.usable, isTrue);
    expect(info.headerBytes, 64000);
    expect(info.txhashsetBytes, 300);
    expect(info.bytes, 64000 + 300 + 1000 + 50);
    expect(info.lock, FolderLock.free); // no epic.lock
    expect(info.modified, isNotNull);
    expect(info.path, await Directory(dir).resolveSymbolicLinks());
  });

  test('mainnet needs 64000 header bytes; floonet and usernet any', () async {
    final dir = await fakeChain('${tmp.path}/a/chain_data', headerBytes: 63999);
    for (final (chain, usable) in [
      (Chain.mainnet, false),
      (Chain.floonet, true),
      (Chain.usernet, true),
    ]) {
      final info = await inspectChainData(
        dir,
        chain: chain,
        source: ChainDataSource.custom,
      );
      expect(info!.usable, usable, reason: '$chain');
    }
    final empty = await fakeChain('${tmp.path}/b/chain_data', headerBytes: 0);
    final info = await inspectChainData(
      empty,
      chain: Chain.floonet,
      source: ChainDataSource.custom,
    );
    expect(info!.usable, isFalse);
  });

  test('each missing layout file makes it unusable', () async {
    for (final part in chainDataLayout) {
      final dir = await fakeChain(
        '${tmp.path}/${part.join('_')}/chain_data',
        headerBytes: 70000,
      );
      // a file or, for the txhashset entries, a folder
      await File([dir, ...part].join('/')).delete(recursive: true);
      final info = await inspectChainData(
        dir,
        chain: Chain.floonet,
        source: ChainDataSource.custom,
      );
      expect(info!.usable, isFalse, reason: part.join('/'));
    }
  });

  test('not a folder: null', () async {
    expect(
      await inspectChainData(
        '${tmp.path}/nope',
        chain: Chain.mainnet,
        source: ChainDataSource.cli,
      ),
      isNull,
    );
    await File('${tmp.path}/file').writeAsString('x');
    expect(
      await inspectChainData(
        '${tmp.path}/file',
        chain: Chain.mainnet,
        source: ChainDataSource.cli,
      ),
      isNull,
    );
  });

  group('dirSize', () {
    test('counts files recursively, does not follow links', () async {
      await write('${tmp.path}/d/a', 10);
      await write('${tmp.path}/d/sub/b', 20);
      await write('${tmp.path}/outside/big', 5000);
      await Link('${tmp.path}/d/link').create('${tmp.path}/outside');
      await Link('${tmp.path}/d/flink').create('${tmp.path}/outside/big');
      expect(await dirSize('${tmp.path}/d'), 30);
    });

    test('a missing folder is 0', () async {
      expect(await dirSize('${tmp.path}/missing'), 0);
    });
  });

  group('findChainData', () {
    test(
      'finds the CLI and GUI folders, sorted usable, newest, larger',
      () async {
        final cli = await fakeChain(
          '$home/.epic/main/chain_data',
          headerBytes: 64000,
          when: DateTime(2026, 1, 1),
        );
        final gui = await fakeChain(
          '$home/.epic-gui/node/main/chain_data',
          headerBytes: 64000,
          when: DateTime(2026, 6, 1),
        );
        final bad = await fakeChain(
          '$home/.epic-gui/settings-chain/chain_data',
          headerBytes: 10,
          when: DateTime(2026, 9, 1),
        );
        await File('$home/.epic-gui/settings.json').writeAsString(
          jsonEncode({
            'node': {
              'mainnet': {'chainDir': bad},
            },
          }),
        );
        // floonet data is not offered for mainnet
        await fakeChain('$home/.epic/floo/chain_data', headerBytes: 64000);

        final found = await findChainData(Chain.mainnet, roots: roots());
        expect(found.map((c) => c.path), [gui, cli, bad]);
        expect(found.map((c) => c.source), [
          ChainDataSource.gui,
          ChainDataSource.cli,
          ChainDataSource.custom,
        ]);
        expect(found.map((c) => c.usable), [true, true, false]);
      },
    );

    test('same time: the larger first', () async {
      final when = DateTime(2026, 3, 3);
      await fakeChain(
        '$home/.epic/user/chain_data',
        headerBytes: 100,
        when: when,
      );
      final big = await fakeChain(
        '$home/.epic-gui/node/user/chain_data',
        headerBytes: 900,
        when: when,
      );
      final found = await findChainData(Chain.usernet, roots: roots());
      expect(found.first.path, big);
    });

    test('a symlinked folder is listed once', () async {
      final real = await fakeChain(
        '${tmp.path}/real/chain_data',
        headerBytes: 64000,
      );
      await Directory('$home/.epic/main').create(recursive: true);
      await Link('$home/.epic/main/chain_data').create(real);
      await Directory('$home/.epic-gui/node/main').create(recursive: true);
      await Link('$home/.epic-gui/node/main/chain_data').create(real);
      final found = await findChainData(Chain.mainnet, roots: roots());
      expect(found, hasLength(1));
      expect(found.single.path, real);
      expect(found.single.source, ChainDataSource.cli);
    });

    test('EPIC_GUI_HOME, then location.json, then ~/.epic-gui', () async {
      final envRoot = '${tmp.path}/env-gui';
      final locRoot = '${tmp.path}/loc-gui';
      final viaEnv = await fakeChain(
        '$envRoot/node/floo/chain_data',
        headerBytes: 5,
      );
      final viaLoc = await fakeChain(
        '$locRoot/node/floo/chain_data',
        headerBytes: 5,
      );
      final viaDefault = await fakeChain(
        '$home/.epic-gui/node/floo/chain_data',
        headerBytes: 5,
      );
      expect(
        (await findChainData(
          Chain.floonet,
          roots: roots(guiHome: envRoot),
        )).map((c) => c.path),
        [viaEnv],
      );
      expect(
        (await findChainData(Chain.floonet, roots: roots())).map((c) => c.path),
        [viaDefault],
      );
      await File('$home/.epic-gui/location.json')
          .writeAsString(jsonEncode({'root': locRoot}));
      expect(
        (await findChainData(Chain.floonet, roots: roots())).map((c) => c.path),
        [viaLoc],
      );
      // a relative root is ignored
      await File('$home/.epic-gui/location.json')
          .writeAsString(jsonEncode({'root': 'rel/gui'}));
      expect(
        (await findChainData(Chain.floonet, roots: roots())).map((c) => c.path),
        [viaDefault],
      );
    });

    test('our bundled folder is not offered', () async {
      final bundled = '${tmp.path}/app/node';
      final own = await fakeChain(
        '$bundled/chain_data',
        headerBytes: 64000,
      );
      await Directory('$home/.epic/main').create(recursive: true);
      await Link('$home/.epic/main/chain_data').create(own);
      final cli = await findChainData(Chain.mainnet, roots: roots());
      expect(cli, hasLength(1));
      final found = await findChainData(
        Chain.mainnet,
        roots: roots(),
        bundledRoot: bundled,
      );
      expect(found, isEmpty);
      final info = await inspectChainData(
        '$bundled/chain_data',
        chain: Chain.mainnet,
        source: ChainDataSource.bundled,
      );
      expect(info!.source, ChainDataSource.bundled);
    });

    test('a huge or broken settings.json is ignored', () async {
      await Directory('$home/.epic-gui').create();
      await File('$home/.epic-gui/settings.json').writeAsString('{broken');
      expect(await findChainData(Chain.mainnet, roots: roots()), isEmpty);
      final dir = await fakeChain(
        '${tmp.path}/x/chain_data',
        headerBytes: 64000,
      );
      final pad = 'x' * (1024 * 1024);
      await File('$home/.epic-gui/settings.json').writeAsString(
        jsonEncode({
          'pad': pad,
          'node': {
            'mainnet': {'chainDir': dir},
          },
        }),
      );
      expect(await findChainData(Chain.mainnet, roots: roots()), isEmpty);
    });
  });

  group('probeChainLock', () {
    test('no epic.lock: free, without running a probe', () async {
      final dir = await fakeChain('${tmp.path}/c/chain_data', headerBytes: 1);
      var ran = false;
      final lock = await probeChainLock(
        dir,
        probe: (_) async {
          ran = true;
          return FolderLock.locked;
        },
      );
      expect(lock, FolderLock.free);
      expect(ran, isFalse);
    });

    test('a probe that throws: unknown', () async {
      final dir = await fakeChain('${tmp.path}/c/chain_data', headerBytes: 1);
      await File('$dir/epic.lock').create();
      expect(
        await probeChainLock(dir, probe: (_) async => throw StateError('x')),
        FolderLock.unknown,
      );
    });

    test(
      'free, then locked while a child flock holds epic.lock, and the file is untouched',
      () async {
        final dir = await fakeChain('${tmp.path}/c/chain_data', headerBytes: 1);
        final lockFile = File('$dir/epic.lock');
        await lockFile.create();
        final before = await lockFile.stat();
        expect(await probeChainLock(dir), FolderLock.free);

        final holder = await holdFlock(lockFile.path);
        try {
          expect(await probeChainLock(dir), FolderLock.locked);
        } finally {
          holder.kill();
          await holder.exitCode;
        }
        expect(await probeChainLock(dir), FolderLock.free);
        final after = await lockFile.stat();
        expect(after.size, 0);
        expect(after.modified, before.modified);
      },
      skip: Platform.isWindows || !_hasFlock()
          ? 'needs util-linux flock'
          : false,
    );

    test(
      'dart:io RandomAccessFile.lock is fcntl on Linux: it does not see a flock',
      () async {
        final file = File('${tmp.path}/probe.lock');
        await file.create();
        final holder = await holdFlock(file.path);
        try {
          final f = await file.open(mode: FileMode.append);
          await f.lock(FileLock.exclusive); // would throw if it were flock
          await f.unlock();
          await f.close();
        } finally {
          holder.kill();
          await holder.exitCode;
        }
      },
      skip: !Platform.isLinux || !_hasFlock() ? 'Linux with flock only' : false,
    );

    // The real epic 4.1.0 node the lead runs for this work. Only its lock is tried (read only).
    const sample =
        '/tmp/sample-node';
    test('a running epic 4.1.0 node: locked', () async {
      expect(
        await probeChainLock('$sample/main/chain_data'),
        FolderLock.locked,
      );
    }, skip: _sampleRunning(sample) ? false : 'the sample node is not running');
  });
}

bool _hasFlock() {
  try {
    return Process.runSync('flock', ['--version']).exitCode == 0;
  } on Object {
    return false;
  }
}

bool _sampleRunning(String sample) {
  try {
    final pid = File('$sample/pid').readAsStringSync().trim();
    return pid.isNotEmpty &&
        Directory('/proc/$pid').existsSync() &&
        File('$sample/main/chain_data/epic.lock').existsSync();
  } on Object {
    return false;
  }
}

/// A child process holding an exclusive flock on [path] until killed: one process (the shell
/// execs `sleep` with the locked fd), so killing it releases the lock.
Future<Process> holdFlock(String path) async {
  final p = await Process.start('sh', [
    '-c',
    r'exec 9<"$1" && flock -n 9 && exec sleep 60',
    'holder',
    path,
  ]);
  // wait until the lock shows (the child has it once `sleep` runs)
  for (var i = 0; i < 100; i++) {
    final r = await Process.run('flock', ['-n', '-E', '200', path, 'true']);
    if (r.exitCode == 200) return p;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  p.kill();
  throw StateError('flock holder did not take the lock');
}

Future<void> write(String path, int bytes) async {
  await File(path).create(recursive: true);
  await File(path).writeAsBytes(List.filled(bytes, 7));
}

/// A chain_data layout: lmdb/data.mdb (1000), header hashes ([headerBytes]), txhashset files
/// (100 each), peer/data.mdb (50). [when] sets the key files' times.
Future<String> fakeChain(
  String dir, {
  required int headerBytes,
  DateTime? when,
}) async {
  await write('$dir/lmdb/data.mdb', 1000);
  await write('$dir/header/header_head/pmmr_hash.bin', headerBytes);
  // as epic writes them: folders of pmmr files
  for (final f in ['kernel', 'output', 'rangeproof']) {
    await write('$dir/txhashset/$f/pmmr_data.bin', 100);
  }
  await write('$dir/peer/data.mdb', 50);
  if (when != null) {
    for (final f in [
      '$dir/lmdb/data.mdb',
      '$dir/header/header_head/pmmr_hash.bin',
    ]) {
      await File(f).setLastModified(when);
    }
    // folder times follow their files only on some systems; pin them by touching
    for (final d in ['$dir/lmdb', '$dir/txhashset']) {
      await Process.run('touch', ['-d', when.toIso8601String(), d]);
    }
  }
  return Directory(dir).resolveSymbolicLinks();
}
