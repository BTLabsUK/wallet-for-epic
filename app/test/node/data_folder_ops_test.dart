// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/legacy_wallets.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/node/chain_data.dart';
import 'package:epic_wallet/src/node/data_folder_ops.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every folder here is a temp dir; the fake home keeps the real ~/.epic and ~/.epic-gui out.
void main() {
  late Directory tmp;
  late String home;
  late LegacyRoots roots;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('data_folder_ops_');
    tmp = Directory(await tmp.resolveSymbolicLinks());
    home = '${tmp.path}/home';
    await Directory(home).create();
    roots = LegacyRoots(home: home);
  });
  tearDown(() async {
    // a test may leave a folder read-only
    await Process.run('chmod', ['-R', 'u+w', tmp.path]);
    await tmp.delete(recursive: true);
  });

  Future<int?> plenty(String _) async => 1 << 50;
  Future<bool?> same(String a, String b) async => true;
  Future<bool?> other(String a, String b) async => false;
  Future<FolderLock> locked(String _) async => FolderLock.locked;
  Future<FolderLock> unknown(String _) async => FolderLock.unknown;

  Future<MovePlan> plan(
    String from,
    String to, {
    VolumeCheck? volume,
    LockProbe? probe,
    Future<int?> Function(String)? free,
  }) => planMove(
    from,
    to,
    freeBytes: free ?? plenty,
    sameVolume: volume ?? other,
    probe: probe,
  );

  Future<DataFolderException> refusal(Future<Object?> f) async {
    try {
      await f;
    } on DataFolderException catch (e) {
      return e;
    }
    fail('expected a DataFolderException');
  }

  group('planMove', () {
    test('a clean move has no problems', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final p = await plan(from, '${tmp.path}/b/chain_data');
      expect(p.problems, isEmpty);
      expect(p.sameVolume, isFalse);
      expect(p.bytesNeeded, spaceNeeded(await dirSize(from)));
      expect(p.to, '${tmp.path}/b/chain_data');
      final r = await plan(from, '${tmp.path}/b/chain_data', volume: same);
      expect(r.sameVolume, isTrue);
      expect(r.bytesNeeded, 0);
    });

    test(
      'the default volume check says a temp dir is on its own volume',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        final p = await planMove(from, '${tmp.path}/b/chain_data');
        expect(p.sameVolume, isTrue);
        expect(p.freeOnTarget, greaterThan(0));
      },
    );

    test('targetInsideSource', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      expect(
        (await plan(from, '$from/sub/chain_data')).problems,
        contains(MoveProblem.targetInsideSource),
      );
      expect(
        (await plan(from, from)).problems,
        contains(MoveProblem.targetInsideSource),
      );
    });

    test('sourceInsideTarget', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      expect(
        (await plan(from, '${tmp.path}/a')).problems,
        contains(MoveProblem.sourceInsideTarget),
      );
    });

    test('targetNotEmpty; an empty target is fine', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final to = '${tmp.path}/b/chain_data';
      await Directory(to).create(recursive: true);
      expect((await plan(from, to)).problems, isEmpty);
      await File('$to/x').writeAsString('x');
      expect((await plan(from, to)).problems, [MoveProblem.targetNotEmpty]);
    });

    test('notEnoughSpace only when copying', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final to = '${tmp.path}/b/chain_data';
      final need = spaceNeeded(await dirSize(from));
      expect((await plan(from, to, free: (_) async => need - 1)).problems, [
        MoveProblem.notEnoughSpace,
      ]);
      expect((await plan(from, to, free: (_) async => need)).problems, isEmpty);
      expect((await plan(from, to, free: (_) async => null)).problems, isEmpty);
      expect(
        (await plan(from, to, volume: same, free: (_) async => 0)).problems,
        isEmpty,
      );
    });

    test('sourceMissing', () async {
      expect(
        (await plan(
          '${tmp.path}/none/chain_data',
          '${tmp.path}/b/chain_data',
        )).problems,
        [MoveProblem.sourceMissing],
      );
    });

    test('sourceLocked', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      await File('$from/epic.lock').create();
      expect(
        (await plan(from, '${tmp.path}/b/chain_data', probe: locked)).problems,
        [MoveProblem.sourceLocked],
      );
      // unknown is not a problem for our own folder: the caller stopped the node
      expect(
        (await plan(from, '${tmp.path}/b/chain_data', probe: unknown)).problems,
        isEmpty,
      );
    });

    test(
      'targetNotWritable',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        await Directory('${tmp.path}/ro').create();
        await Process.run('chmod', ['555', '${tmp.path}/ro']);
        expect((await plan(from, '${tmp.path}/ro/new/chain_data')).problems, [
          MoveProblem.targetNotWritable,
        ]);
        // a file in the way
        await File('${tmp.path}/file').writeAsString('x');
        expect(
          (await plan(from, '${tmp.path}/file/chain_data')).problems,
          contains(MoveProblem.targetNotWritable),
        );
      },
      skip: Platform.isWindows || _isRoot()
          ? 'needs a non-root Unix user'
          : false,
    );
  });

  group('moveChainData', () {
    test('same volume: a rename', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final before = await snapshot(from);
      final p = await plan(from, '${tmp.path}/b/c/chain_data', volume: same);
      await moveChainData(p, nodeStopped: true, roots: roots);
      expect(await Directory(from).exists(), isFalse);
      expect(await snapshot(p.to), before);
    });

    test(
      'another volume: copy, check, rename, then delete the source',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        await File('$from/epic.lock').create();
        await File('$from/lmdb/lock.mdb').writeAsString('lock');
        final before = await snapshot(from);
        final to = '${tmp.path}/b/chain_data';
        final p = await plan(from, to);
        final seen = <(int, int)>[];
        await moveChainData(
          p,
          nodeStopped: true,
          roots: roots,
          progress: (d, t) => seen.add((d, t)),
        );
        expect(await Directory(from).exists(), isFalse);
        expect(await Directory('$to.partial').exists(), isFalse);
        expect(await snapshot(to), {
          for (final e in before.entries)
            if (!e.key.endsWith('epic.lock') && !e.key.endsWith('lock.mdb'))
              e.key: e.value,
        });
        expect(seen.last.$1, seen.last.$2);
        expect(
          seen.last.$2,
          greaterThan(2 * 1024 * 1024),
        ); // more than one chunk
      },
    );

    test('re-running after a success does nothing', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final p = await plan(from, '${tmp.path}/b/chain_data');
      await moveChainData(p, nodeStopped: true, roots: roots);
      final after = await snapshot(p.to);
      await moveChainData(p, nodeStopped: true, roots: roots);
      expect(await snapshot(p.to), after);
    });

    test(
      'cancelled mid-copy: the source intact, no target, no partial',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        final before = await snapshot(from);
        final to = '${tmp.path}/b/chain_data';
        final p = await plan(from, to);
        var chunks = 0;
        final e = await refusal(
          moveChainData(
            p,
            nodeStopped: true,
            roots: roots,
            progress: (d, _) => chunks++,
            cancelled: () => chunks > 1,
          ),
        );
        expect(e.reason, DataFolderFailure.cancelled);
        expect(await snapshot(from), before);
        expect(await Directory(to).exists(), isFalse);
        expect(await Directory('$to.partial').exists(), isFalse);
      },
    );

    test(
      'a crash mid-copy: our leftover partial is removed at the next attempt',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        final before = await snapshot(from);
        final to = '${tmp.path}/b/chain_data';
        // what a killed copy leaves: the marker and some of the files
        await File('$to.partial/lmdb/data.mdb').create(recursive: true);
        await File('$to.partial/$copyMarkerName')
            .writeAsString(jsonEncode({'op': 'move', 'from': from}));
        final p = await plan(from, to);
        expect(p.problems, isEmpty);
        await moveChainData(p, nodeStopped: true, roots: roots);
        expect(await Directory('$to.partial').exists(), isFalse);
        expect(await snapshot(to), before);
      },
    );

    test('a partial that is not ours is refused', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final to = '${tmp.path}/b/chain_data';
      await File('$to.partial/precious').create(recursive: true);
      final e = await refusal(
        moveChainData(await plan(from, to), nodeStopped: true, roots: roots),
      );
      expect(e.reason, DataFolderFailure.partialNotOurs);
      expect(await File('$to.partial/precious').exists(), isTrue);
      expect(await Directory(from).exists(), isTrue);
    });

    test('a crash after the rename: the next run deletes the source', () async {
      final from = await fakeChain('${tmp.path}/a/chain_data');
      final before = await snapshot(from);
      final to = '${tmp.path}/b/chain_data';
      await Directory('${tmp.path}/b').create();
      // the copy is in place with its marker, the source is still there
      expect((await Process.run('cp', ['-a', from, to])).exitCode, 0);
      await File('$to/$copyMarkerName')
          .writeAsString(jsonEncode({'op': 'move', 'from': from}));
      final p = await plan(from, to);
      expect(p.problems, isEmpty);
      await moveChainData(p, nodeStopped: true, roots: roots);
      expect(await Directory(from).exists(), isFalse);
      expect(await snapshot(to), before);
    });

    test(
      'refuses while the node runs, a plan with problems, a held lock',
      () async {
        final from = await fakeChain('${tmp.path}/a/chain_data');
        final p = await plan(from, '${tmp.path}/b/chain_data');
        expect(
          (await refusal(moveChainData(p, nodeStopped: false, roots: roots)))
              .reason,
          DataFolderFailure.nodeRunning,
        );
        final bad = await plan(from, from);
        final e = await refusal(
          moveChainData(bad, nodeStopped: true, roots: roots),
        );
        expect(e.reason, DataFolderFailure.problems);
        expect(e.problems, contains(MoveProblem.targetInsideSource));
        // locked after the plan was made
        await File('$from/epic.lock').create();
        expect(
          (await refusal(
            moveChainData(p, nodeStopped: true, roots: roots, probe: locked),
          )).reason,
          DataFolderFailure.locked,
        );
        expect(await Directory(from).exists(), isTrue);
      },
    );

    test('never moves the CLI or GUI folder', () async {
      for (final dir in [
        '$home/.epic/main/chain_data',
        '$home/.epic-gui/node/floo/chain_data',
      ]) {
        final from = await fakeChain(dir);
        final e = await refusal(
          moveChainData(
            await plan(from, '${tmp.path}/b/chain_data'),
            nodeStopped: true,
            roots: roots,
          ),
        );
        expect(e.reason, DataFolderFailure.foreignFolder, reason: dir);
        expect(await Directory(from).exists(), isTrue);
      }
    });
  });

  group('copyChainDataFrom', () {
    Future<ChainDataInfo> info(String dir) async => (await inspectChainData(
      dir,
      chain: Chain.mainnet,
      source: ChainDataSource.cli,
    ))!;

    test(
      'copies; the source is left exactly as it was; lock files stay behind',
      () async {
        final src = await fakeChain('$home/.epic/main/chain_data');
        await File('$src/epic.lock').create();
        await File('$src/peer/lock.mdb').writeAsString('lock');
        final before = await snapshot(src, times: true);
        final to = '${tmp.path}/own/main/chain_data';
        await copyChainDataFrom(
          await info(src),
          to,
          nodeStopped: true,
          freeBytes: plenty,
        );
        expect(await snapshot(src, times: true), before);
        final copied = await snapshot(to);
        expect(copied.keys, isNot(contains('epic.lock')));
        expect(copied.keys, isNot(contains('peer/lock.mdb')));
        expect(
          copied['lmdb/data.mdb'],
          before['lmdb/data.mdb']!.split('@').first,
        );
        expect(copied, hasLength(before.length - 2));
        expect(await Directory('$to.partial').exists(), isFalse);
      },
    );

    test('refuses a source a node runs on, and the target not empty', () async {
      final src = await fakeChain('$home/.epic/main/chain_data');
      await File('$src/epic.lock').create();
      final to = '${tmp.path}/own/chain_data';
      expect(
        (await refusal(
          copyChainDataFrom(
            await info(src),
            to,
            nodeStopped: true,
            freeBytes: plenty,
            probe: locked,
          ),
        )).reason,
        DataFolderFailure.locked,
      );
      expect(await Directory(to).exists(), isFalse);
      await File('$to/x').create(recursive: true);
      final e = await refusal(
        copyChainDataFrom(
          await info(src),
          to,
          nodeStopped: true,
          freeBytes: plenty,
        ),
      );
      expect(e.problems, [MoveProblem.targetNotEmpty]);
      expect(
        (await refusal(
          copyChainDataFrom(
            await info(src),
            '${tmp.path}/n/chain_data',
            nodeStopped: false,
          ),
        )).reason,
        DataFolderFailure.nodeRunning,
      );
    });

    test('not enough space', () async {
      final src = await fakeChain('$home/.epic/main/chain_data');
      final e = await refusal(
        copyChainDataFrom(
          await info(src),
          '${tmp.path}/own/chain_data',
          nodeStopped: true,
          freeBytes: (_) async => 10,
        ),
      );
      expect(e.problems, [MoveProblem.notEnoughSpace]);
    });

    test('cancelled: the source intact, no target, no partial', () async {
      final src = await fakeChain('$home/.epic/main/chain_data');
      final before = await snapshot(src, times: true);
      final to = '${tmp.path}/own/chain_data';
      final e = await refusal(
        copyChainDataFrom(
          await info(src),
          to,
          nodeStopped: true,
          freeBytes: plenty,
          cancelled: () => true,
        ),
      );
      expect(e.reason, DataFolderFailure.cancelled);
      expect(await snapshot(src, times: true), before);
      expect(await Directory(to).exists(), isFalse);
      expect(await Directory('$to.partial').exists(), isFalse);
    });

    test('a symlink inside the source is refused', () async {
      final src = await fakeChain('$home/.epic/main/chain_data');
      await Link('$src/peer/elsewhere').create(tmp.path);
      final e = await refusal(
        copyChainDataFrom(
          await info(src),
          '${tmp.path}/own/chain_data',
          nodeStopped: true,
          freeBytes: plenty,
        ),
      );
      expect(e.reason, DataFolderFailure.symlink);
      expect(
        await Directory('${tmp.path}/own/chain_data.partial').exists(),
        isFalse,
      );
    });
  });

  group('checkPointTarget', () {
    test('a complete, free folder: nothing in the way', () async {
      final dir = await fakeChain('${tmp.path}/x/chain_data');
      final i = (await inspectChainData(
        dir,
        chain: Chain.mainnet,
        source: ChainDataSource.custom,
      ))!;
      expect(await checkPointTarget(i), isEmpty);
      await File('$dir/epic.lock').create();
      expect(await checkPointTarget(i, probe: locked), [
        MoveProblem.sourceLocked,
      ]);
      await Directory('$dir/txhashset/kernel').delete(recursive: true);
      expect(await checkPointTarget(i), [MoveProblem.layoutIncomplete]);
      await Directory(dir).delete(recursive: true);
      expect(await checkPointTarget(i), [MoveProblem.sourceMissing]);
    });
  });

  group('deleteChainData', () {
    test('deletes the managed folder and says how much it freed', () async {
      final dir = await fakeChain('${tmp.path}/app/node/main/chain_data');
      final size = await dirSize(dir);
      final freed = await deleteChainData(
        dir,
        managedPath: dir,
        nodeStopped: true,
        roots: roots,
      );
      expect(freed, size);
      expect(await Directory(dir).exists(), isFalse);
      expect(await Directory('${tmp.path}/app/node/main').exists(), isTrue);
    });

    test('links inside are removed, their targets kept', () async {
      final dir = await fakeChain('${tmp.path}/app/node/main/chain_data');
      final keep = await File('${tmp.path}/keep/file').create(recursive: true);
      await Link('$dir/peer/out').create('${tmp.path}/keep');
      await deleteChainData(
        dir,
        managedPath: dir,
        nodeStopped: true,
        roots: roots,
      );
      expect(await keep.exists(), isTrue);
    });

    test('refusals leave everything in place', () async {
      final dir = await fakeChain('${tmp.path}/app/node/main/chain_data');
      final other = await fakeChain('${tmp.path}/other/chain_data');
      final named = await fakeChain('${tmp.path}/app/node/main/not_chain');
      await Link('${tmp.path}/app/link').create('${tmp.path}/app/node/main');
      await Directory('${tmp.path}/l').create();
      await Link('${tmp.path}/l/chain_data').create(dir);

      Future<DataFolderFailure> reason(
        String path, {
        String? managed,
        bool stopped = true,
        LockProbe? probe,
      }) async => (await refusal(
        deleteChainData(
          path,
          managedPath: managed ?? dir,
          nodeStopped: stopped,
          roots: roots,
          probe: probe,
        ),
      )).reason;

      expect(await reason(dir, stopped: false), DataFolderFailure.nodeRunning);
      expect(await reason(other), DataFolderFailure.notManaged);
      expect(
        await reason(named, managed: named),
        DataFolderFailure.notChainData,
      );
      expect(
        await reason('${tmp.path}/l/chain_data'),
        DataFolderFailure.symlink,
      );
      expect(
        await reason('${tmp.path}/nope/chain_data'),
        DataFolderFailure.missing,
      );
      await File('$dir/epic.lock').create();
      expect(await reason(dir, probe: locked), DataFolderFailure.locked);
      expect(await reason(dir, probe: unknown), DataFolderFailure.lockUnknown);
      // the CLI node's folder, even when the caller calls it managed
      final cli = await fakeChain('$home/.epic/user/chain_data');
      expect(await reason(cli, managed: cli), DataFolderFailure.foreignFolder);

      for (final d in [dir, other, named, cli]) {
        expect(await Directory(d).exists(), isTrue, reason: d);
      }
    });

    test('a real flock on epic.lock refuses', () async {
      final dir = await fakeChain('${tmp.path}/app/node/main/chain_data');
      await File('$dir/epic.lock').create();
      final holder = await Process.start('sh', [
        '-c',
        r'exec 9<"$1" && flock -n 9 && exec sleep 60',
        'holder',
        '$dir/epic.lock',
      ]);
      try {
        for (var i = 0; i < 100; i++) {
          if (await probeChainLock(dir) == FolderLock.locked) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        final e = await refusal(
          deleteChainData(
            dir,
            managedPath: dir,
            nodeStopped: true,
            roots: roots,
          ),
        );
        expect(e.reason, DataFolderFailure.locked);
      } finally {
        holder.kill();
        await holder.exitCode;
      }
      expect(await Directory(dir).exists(), isTrue);
    }, skip: Platform.isWindows ? 'Unix flock' : false);
  });
}

bool _isRoot() {
  try {
    return (Process.runSync('id', ['-u']).stdout as String).trim() == '0';
  } on Object {
    return false;
  }
}

/// A usable mainnet chain_data with a 3 MiB data.mdb (so a copy takes several chunks).
Future<String> fakeChain(String dir) async {
  Future<void> write(String rel, int bytes, int fill) async {
    final f = File('$dir/$rel');
    await f.create(recursive: true);
    await f.writeAsBytes(List.filled(bytes, fill));
  }

  await write('lmdb/data.mdb', 3 * 1024 * 1024 + 17, 1);
  await write('header/header_head/pmmr_hash.bin', 64000, 2);
  await write('header/header_head/pmmr_size.bin', 8000, 3);
  for (final (i, f) in ['kernel', 'output', 'rangeproof'].indexed) {
    await write('txhashset/$f/pmmr_data.bin', 1000 + i, 4 + i);
  }
  await write('peer/data.mdb', 500, 9);
  return Directory(dir).resolveSymbolicLinks();
}

/// Relative path -> "size:sum" of every file under [dir] (and "@mtime" when [times]).
Future<Map<String, String>> snapshot(String dir, {bool times = false}) async {
  final out = <String, String>{};
  await for (final e in Directory(
    dir,
  ).list(recursive: true, followLinks: false)) {
    if (e is! File) continue;
    final bytes = await e.readAsBytes();
    final sum = bytes.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    var v = '${bytes.length}:$sum';
    if (times) v += '@${(await e.stat()).modified.microsecondsSinceEpoch}';
    out[e.path.substring(dir.length + 1)] = v;
  }
  return out;
}
