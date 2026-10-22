/// The local node's data folder as one safe sequence each: stop the node, do the file work,
/// save the setting, start it again when it ran before. The file work is in
/// `data_folder_ops.dart`; this file only orders it around the node.
///
/// A failure leaves the setting as it was (the node keeps its old folder), and a node that ran
/// before is started again on that folder.
library;

import 'dart:io';

import '../builtin_node.dart' show DiskProbe;
import '../legacy_wallets.dart' show LegacyRoots;
import 'chain_data.dart';
import 'data_folder_ops.dart' as ops;
import 'data_folder_ops.dart' show DataFolderException, DataFolderFailure, MovePlan, VolumeCheck;
import 'local_node_controller.dart';

/// How a new folder is taken into use.
enum FolderChange {
  /// The chain data moves there (copied and checked, then the old copy goes).
  move,

  /// The node uses that folder as it is: its chain data, or nothing (a fresh sync).
  point,
}

/// How another node's chain data is reused.
enum ReuseMode {
  /// Copied into the node's own folder; the other node's folder is only read.
  copy,

  /// The node runs on the other folder itself. The other node must not run at the same time
  /// (its lock refuses), and "Delete chain data" never deletes that folder.
  point,
}

class NodeMaintenance {
  /// The probes are for tests; null uses the real ones.
  NodeMaintenance(this._controller, {this.roots, this.probe, this.freeBytes, this.sameVolume});

  final LocalNodeController _controller;

  /// Where the CLI and GUI nodes keep their data: never deleted, only read for a copy.
  final LegacyRoots? roots;
  final LockProbe? probe;
  final DiskProbe? freeBytes;
  final VolumeCheck? sameVolume;

  /// The chain data folder in use now.
  String get chainDataPath => _controller.state.chainDataPath;

  /// The chain data folder for a folder the user picked: `<folder>/chain_data`, or [folder]
  /// itself when it is one. The node's data always sits in a `chain_data` folder, which is what
  /// "Delete chain data" checks for.
  static String chainDataIn(String folder) {
    final sep = Platform.pathSeparator;
    var f = folder;
    while (f.length > 1 && (f.endsWith(sep) || f.endsWith('/'))) {
      f = f.substring(0, f.length - 1);
    }
    final name = f.split(RegExp(r'[\\/]')).last;
    return name == 'chain_data' ? f : '$f${sep}chain_data';
  }

  /// What moving the chain data into [folder] ([chainDataIn]) would take, and what stands in
  /// the way.
  Future<MovePlan> planMove(String folder) => ops.planMove(
    chainDataPath,
    chainDataIn(folder),
    freeBytes: freeBytes,
    sameVolume: sameVolume,
    probe: probe,
  );

  /// Moves the chain data into [folder] ([chainDataIn]), or points the node at it
  /// ([FolderChange.point]: its chain data, or a fresh sync when it holds none).
  Future<void> changeDataFolder(
    String folder, {
    required FolderChange how,
    void Function(int done, int total)? progress,
    bool Function()? cancelled,
  }) => _stopped(() async {
    final target = chainDataIn(folder);
    switch (how) {
      case FolderChange.move:
        final plan = await planMove(folder);
        if (plan.problems.isNotEmpty) {
          throw DataFolderException(DataFolderFailure.problems, 'cannot move: ${plan.problems.map((p) => p.name).join(', ')}', problems: plan.problems);
        }
        await ops.moveChainData(plan, nodeStopped: true, progress: progress, cancelled: cancelled, roots: roots, probe: probe);
      case FolderChange.point:
        final info = await inspectChainData(target, chain: _controller.chain, source: ChainDataSource.custom);
        if (info != null) {
          final problems = await ops.checkPointTarget(info, probe: probe);
          // An empty or new folder is a fresh sync; a folder with chain data must be whole.
          if (problems.isNotEmpty && await _hasFiles(target)) {
            throw DataFolderException(DataFolderFailure.problems, 'cannot use it: ${problems.map((p) => p.name).join(', ')}', problems: problems);
          }
        }
    }
    await _controller.setChainDataPath(target);
  });

  /// Reuses another node's chain data ([findChainData]). Copying goes into the node's own
  /// folder (`<node folder>/chain_data`), which must be empty: delete its chain data first.
  Future<void> reuseChainData(
    ChainDataInfo source, {
    required ReuseMode how,
    void Function(int done, int total)? progress,
    bool Function()? cancelled,
  }) => _stopped(() async {
    switch (how) {
      case ReuseMode.copy:
        await ops.copyChainDataFrom(
          source,
          _ownChainData,
          nodeStopped: true,
          progress: progress,
          cancelled: cancelled,
          freeBytes: freeBytes,
          probe: probe,
        );
        await _controller.setChainDataPath(null);
      case ReuseMode.point:
        final problems = await ops.checkPointTarget(source, probe: probe);
        if (problems.isNotEmpty) {
          throw DataFolderException(DataFolderFailure.problems, 'cannot use it: ${problems.map((p) => p.name).join(', ')}', problems: problems);
        }
        await _controller.setChainDataPath(source.path);
    }
  });

  /// Deletes the node's chain data (its own folder only; never another node's), with the node
  /// stopped; it stays stopped. Returns the bytes freed. The next start syncs from scratch.
  Future<int> deleteChainData() async {
    await _controller.stop();
    final freed = await ops.deleteChainData(chainDataPath, managedPath: chainDataPath, nodeStopped: true, roots: roots, probe: probe);
    await _controller.refreshDisk();
    return freed;
  }

  String get _ownChainData => chainDataIn(_controller.node.folder);

  /// Runs [work] with the node stopped and starts it again when it ran before, also after a
  /// failure (then on the old folder).
  Future<void> _stopped(Future<void> Function() work) async {
    // A stalled node runs too (its phase is error); a failed one does not.
    final wasRunning = _controller.node.wantsRunning;
    await _controller.stop();
    try {
      await work();
    } on Object {
      if (wasRunning) {
        try {
          await _controller.start();
        } on Object {
          // the state shows why; the first error is the one to report
        }
      }
      rethrow;
    } finally {
      await _controller.refreshDisk();
    }
    if (wasRunning) await _controller.start();
  }
}

Future<bool> _hasFiles(String dir) async {
  try {
    return !await Directory(dir).list(followLinks: false).isEmpty;
  } on FileSystemException {
    return false;
  }
}
