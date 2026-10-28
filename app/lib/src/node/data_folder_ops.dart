// SPDX-License-Identifier: Apache-2.0
/// File operations on the built-in node's chain data folder: move it elsewhere, copy another
/// node's chain data in, check a folder to run on in place, delete it. Starting and stopping the
/// node is the caller's: every operation that changes files takes `nodeStopped` and refuses while
/// the node runs, and refuses a folder whose `epic.lock` is held.
///
/// A crash at any point leaves the old or the new complete copy: data is copied into
/// `<to>.partial` (with a [copyMarkerName] file inside, so a leftover is known as ours and removed at
/// the next attempt), checked, renamed to `<to>`, and only then is a moved source deleted.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../builtin_node.dart' show DiskProbe;
import '../legacy_wallets.dart' show LegacyRoots;
import '../models.dart' show Chain;
import 'chain_data.dart';

/// Why a move (or a copy, or running on a folder in place) cannot go ahead.
enum MoveProblem {
  targetInsideSource,
  sourceInsideTarget,
  targetNotEmpty,
  notEnoughSpace,
  sourceMissing,
  sourceLocked,
  targetNotWritable,

  /// The folder lacks files every node writes (see [chainDataLayout]).
  layoutIncomplete,

  /// The target is where the CLI node or the Epic GUI keeps its chain data.
  targetForeign,
}

/// Why an operation refused or failed.
enum DataFolderFailure {
  /// The caller said the node runs.
  nodeRunning,

  /// A node holds the folder's `epic.lock`.
  locked,

  /// Whether a node holds the folder could not be told (deleting refuses then).
  lockUnknown,

  /// [MovePlan.problems] (or the same checks for a copy) are not empty; see
  /// [DataFolderException.problems].
  problems,

  /// Not the managed folder given.
  notManaged,

  /// The folder is not named `chain_data`.
  notChainData,

  /// The folder is a symlink (or junction), or holds one.
  symlink,

  /// The CLI node's or GUI 6.1's folder: never moved or deleted.
  foreignFolder,
  missing,

  /// `<to>.partial` exists without our marker: not ours to remove.
  partialNotOurs,

  /// The copy does not match the source (file count or bytes).
  verifyFailed,
  cancelled,

  /// The file system refused (see the message).
  io,

  /// The node's toml was edited by hand: it names its own `db_root`, which the app does not
  /// change, so moving or pointing would not take effect.
  userToml,
}

class DataFolderException implements Exception {
  const DataFolderException(
    this.reason,
    this.message, {
    this.problems = const [],
  });

  final DataFolderFailure reason;
  final String message;
  final List<MoveProblem> problems;

  @override
  String toString() => 'DataFolderException($reason): $message';
}

/// Whether two existing paths are on the same volume (a rename between them works); null when
/// unknown. Injectable for tests.
typedef VolumeCheck = Future<bool?> Function(String a, String b);

/// Name of the marker file inside a copy in progress (`<to>.partial`) and inside a moved folder
/// whose source is not deleted yet.
const copyMarkerName = '.epic-wallet-copy';

/// Free space kept on the target beyond the data: 10% and 1 GiB.
int spaceNeeded(int bytes) => bytes + bytes ~/ 10 + (1 << 30);

/// What a move of [from] to [to] takes, and what stands in its way. Plan right before moving.
class MovePlan {
  const MovePlan({
    required this.from,
    required this.to,
    required this.bytesNeeded,
    required this.freeOnTarget,
    required this.sameVolume,
    required this.problems,
  });

  /// Canonical paths.
  final String from;
  final String to;

  /// The data's size, with the margin of [spaceNeeded]; 0 on the same volume (a rename).
  final int bytesNeeded;

  /// Free bytes on the target's volume, null when unknown (then not a problem).
  final int? freeOnTarget;
  final bool sameVolume;
  final List<MoveProblem> problems;

  @override
  String toString() =>
      'MovePlan($from -> $to, needed: $bytesNeeded, free: $freeOnTarget, '
      'sameVolume: $sameVolume, problems: $problems)';
}

/// Plans moving the chain data folder [from] to [to] (the new `chain_data` folder itself).
Future<MovePlan> planMove(
  String from,
  String to, {
  DiskProbe? freeBytes,
  VolumeCheck? sameVolume,
  LockProbe? probe,
  LegacyRoots? roots,
}) async {
  final src = await canonicalPath(from);
  final dst = await canonicalPath(to);
  final problems = <MoveProblem>[];
  // Nothing more is looked at there, not even a write probe.
  if (await _isForeign(dst, roots ?? LegacyRoots.current())) {
    return MovePlan(from: src, to: dst, bytesNeeded: 0, freeOnTarget: null, sameVolume: false, problems: const [MoveProblem.targetForeign]);
  }
  final srcExists = await FileSystemEntity.isDirectory(src);
  if (!srcExists) problems.add(MoveProblem.sourceMissing);
  if (samePath(src, dst) || isInside(dst, src)) {
    problems.add(MoveProblem.targetInsideSource);
  } else if (isInside(src, dst)) {
    problems.add(MoveProblem.sourceInsideTarget);
  }
  if (!await _emptyOrAbsent(dst) && !await _finishedMoveOf(dst, src)) {
    problems.add(MoveProblem.targetNotEmpty);
  }
  if (srcExists &&
      await probeChainLock(src, probe: probe) == FolderLock.locked) {
    problems.add(MoveProblem.sourceLocked);
  }
  final anchor = await _existingAncestor(dst);
  if (anchor == null || !await _writable(anchor)) {
    problems.add(MoveProblem.targetNotWritable);
  }
  var same = false;
  if (srcExists && anchor != null) {
    try {
      same = await (sameVolume ?? _sameVolume)(src, anchor) ?? false;
    } on Object {
      same = false;
    }
  }
  final bytes = srcExists && !same ? spaceNeeded(await dirSize(src)) : 0;
  int? free;
  if (anchor != null) {
    try {
      free = await (freeBytes ?? _freeBytes)(anchor);
    } on Object {
      free = null;
    }
  }
  if (!same && free != null && free < bytes) {
    problems.add(MoveProblem.notEnoughSpace);
  }
  return MovePlan(
    from: src,
    to: dst,
    bytesNeeded: bytes,
    freeOnTarget: free,
    sameVolume: same,
    problems: problems,
  );
}

/// Moves our own chain data folder as [plan] says: a rename on the same volume, else copy, check,
/// rename into place, then delete the source. The source must be the built-in node's own folder:
/// the CLI node's and GUI 6.1's folders ([roots]) are refused. Re-running after a success, or after
/// a crash, finishes or does nothing. [cancelled] is asked between chunks; a cancelled move leaves
/// the source as it was and no `<to>` or `<to>.partial`.
Future<void> moveChainData(
  MovePlan plan, {
  required bool nodeStopped,
  void Function(int done, int total)? progress,
  bool Function()? cancelled,
  LegacyRoots? roots,
  LockProbe? probe,
}) async {
  if (!nodeStopped) throw _nodeRunning();
  final from = plan.from;
  final to = plan.to;
  final r = roots ?? LegacyRoots.current();
  if (await _isForeign(from, r)) {
    throw DataFolderException(
      DataFolderFailure.foreignFolder,
      '$from belongs to another Epic node; it is never moved',
    );
  }
  if (await _isForeign(to, r)) {
    throw DataFolderException(
      DataFolderFailure.foreignFolder,
      '$to is where another Epic node keeps its data; not a target',
    );
  }
  // A crash after the rename into place: the copy is complete; delete what is left of the source.
  if (await _finishedMoveOf(to, from)) {
    if (await Directory(from).exists()) {
      await _requireFree(from, probe, allowUnknown: true);
      await _deleteTree(from);
    }
    await _deleteFile(_join(to, copyMarkerName));
    return;
  }
  // Done before: the source is gone and whole chain data is at the target.
  if (!await Directory(from).exists() && await chainLayoutComplete(to)) {
    await _removeOurPartial(to);
    return;
  }
  if (plan.problems.isNotEmpty) throw _problems(plan.problems);
  await _requireFree(from, probe, allowUnknown: true);
  await _removeOurPartial(to);
  if (plan.sameVolume && await _tryRename(from, to)) return;
  await _copyInto(
    from,
    to,
    op: 'move',
    progress: progress,
    cancelled: cancelled,
  );
  await _deleteTree(from);
  await _deleteFile(_join(to, copyMarkerName));
}

/// Copies another node's chain data [source] to [to] (the new `chain_data` folder) for the built-in
/// node to use. The source is only read: never renamed, written or deleted, and its lock files
/// (`epic.lock`, LMDB's `lock.mdb`, which LMDB recreates) are not copied. Refused while a node runs
/// on the source. Re-running after a success does nothing.
Future<void> copyChainDataFrom(
  ChainDataInfo source,
  String to, {
  required bool nodeStopped,
  void Function(int done, int total)? progress,
  bool Function()? cancelled,
  DiskProbe? freeBytes,
  LockProbe? probe,
  LegacyRoots? roots,
}) async {
  if (!nodeStopped) throw _nodeRunning();
  final src = await canonicalPath(source.path);
  final dst = await canonicalPath(to);
  if (await _isForeign(dst, roots ?? LegacyRoots.current())) {
    throw DataFolderException(
      DataFolderFailure.foreignFolder,
      '$to is where another Epic node keeps its data; not a target',
    );
  }
  final marker = _join(dst, copyMarkerName);
  if (await _markerOf(dst, 'copy', src)) {
    await _deleteFile(marker);
    return;
  }
  final problems = <MoveProblem>[];
  if (!await FileSystemEntity.isDirectory(src)) {
    problems.add(MoveProblem.sourceMissing);
  }
  if (samePath(src, dst) || isInside(dst, src)) {
    problems.add(MoveProblem.targetInsideSource);
  } else if (isInside(src, dst)) {
    problems.add(MoveProblem.sourceInsideTarget);
  }
  if (!await _emptyOrAbsent(dst)) problems.add(MoveProblem.targetNotEmpty);
  final anchor = await _existingAncestor(dst);
  if (anchor == null || !await _writable(anchor)) {
    problems.add(MoveProblem.targetNotWritable);
  } else if (!problems.contains(MoveProblem.sourceMissing)) {
    int? free;
    try {
      free = await (freeBytes ?? _freeBytes)(anchor);
    } on Object {
      free = null;
    }
    if (free != null && free < spaceNeeded(await dirSize(src))) {
      problems.add(MoveProblem.notEnoughSpace);
    }
  }
  if (problems.isNotEmpty) throw _problems(problems);
  await _requireFree(src, probe, allowUnknown: true);
  await _removeOurPartial(dst);
  await _copyInto(
    src,
    dst,
    op: 'copy',
    progress: progress,
    cancelled: cancelled,
  );
  await _deleteFile(marker);
}

/// What stands in the way of running the built-in node on [target] in place (no files change):
/// gone, a node runs on it, or the files every node writes are not all there.
Future<List<MoveProblem>> checkPointTarget(
  ChainDataInfo target, {
  LockProbe? probe,
}) async {
  final info = await inspectChainData(
    target.path,
    chain: target.chain,
    source: target.source,
    probe: probe,
  );
  if (info == null) return const [MoveProblem.sourceMissing];
  return [
    if (info.lock == FolderLock.locked) MoveProblem.sourceLocked,
    if (!await chainLayoutComplete(info.path)) MoveProblem.layoutIncomplete,
  ];
}

/// Deletes the built-in node's own chain data folder [path] and returns the bytes freed. Only when
/// [path] is exactly [managedPath] (both canonical), is named `chain_data`, is no symlink, is not
/// the CLI node's or GUI 6.1's folder ([roots]) and its lock is free (unknown refuses too). The tree
/// under that one folder is deleted; links inside are removed, never followed.
Future<int> deleteChainData(
  String path, {
  required String managedPath,
  required bool nodeStopped,
  LegacyRoots? roots,
  LockProbe? probe,
}) async {
  if (!nodeStopped) throw _nodeRunning();
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.link) {
    throw DataFolderException(
      DataFolderFailure.symlink,
      '$path is a link; only the folder itself is deleted',
    );
  }
  if (type == FileSystemEntityType.notFound) {
    throw DataFolderException(
      DataFolderFailure.missing,
      '$path does not exist',
    );
  }
  if (type != FileSystemEntityType.directory) {
    throw DataFolderException(
      DataFolderFailure.notChainData,
      '$path is not a folder',
    );
  }
  final canonical = await canonicalPath(path);
  if (_name(canonical) != 'chain_data' || _name(path) != 'chain_data') {
    throw DataFolderException(
      DataFolderFailure.notChainData,
      '$path is not a chain_data folder',
    );
  }
  if (!samePath(canonical, await canonicalPath(managedPath))) {
    throw DataFolderException(
      DataFolderFailure.notManaged,
      '$path is not the built-in node\'s folder',
    );
  }
  if (await _isForeign(canonical, roots ?? LegacyRoots.current())) {
    throw DataFolderException(
      DataFolderFailure.foreignFolder,
      '$path belongs to another Epic node; it is never deleted',
    );
  }
  await _requireFree(canonical, probe, allowUnknown: false);
  final bytes = await dirSize(canonical);
  await _deleteTree(canonical);
  return bytes;
}

// ---------------------------------------------------------------------------------------------

DataFolderException _nodeRunning() => const DataFolderException(
  DataFolderFailure.nodeRunning,
  'stop the node first',
);

DataFolderException _problems(List<MoveProblem> problems) =>
    DataFolderException(
      DataFolderFailure.problems,
      'cannot go ahead: ${problems.map((p) => p.name).join(', ')}',
      problems: List.unmodifiable(problems),
    );

Future<void> _requireFree(
  String dir,
  LockProbe? probe, {
  required bool allowUnknown,
}) async {
  final lock = await probeChainLock(dir, probe: probe);
  if (lock == FolderLock.locked) {
    throw DataFolderException(
      DataFolderFailure.locked,
      'a node is running on $dir',
    );
  }
  if (lock == FolderLock.unknown && !allowUnknown) {
    throw DataFolderException(
      DataFolderFailure.lockUnknown,
      'cannot tell whether a node is running on $dir',
    );
  }
}

/// Whether [dir] is a folder the CLI node or GUI 6.1 uses, for any chain.
Future<bool> _isForeign(String dir, LegacyRoots roots) async {
  final canonical = await canonicalPath(dir);
  for (final chain in Chain.values) {
    for (final (p, _) in await foreignChainDataPaths(chain, roots: roots)) {
      if (samePath(canonical, await canonicalPath(p))) return true;
    }
  }
  return false;
}

String _join(String a, String b) => joinPath([a, b]);

String _name(String p) {
  final s = p.endsWith(Platform.pathSeparator)
      ? p.substring(0, p.length - 1)
      : p;
  return s.substring(s.lastIndexOf(Platform.pathSeparator) + 1);
}

/// The marker inside [dir] says it is a complete [op] ('move' or 'copy') of [from].
Future<bool> _markerOf(String dir, String op, String from) async {
  try {
    final f = File(_join(dir, copyMarkerName));
    if (!await f.exists() || await f.length() > 64 * 1024) return false;
    final m = jsonDecode(await f.readAsString());
    return m is Map &&
        m['op'] == op &&
        m['from'] is String &&
        samePath(m['from'] as String, from);
  } on Object {
    return false;
  }
}

Future<bool> _finishedMoveOf(String to, String from) =>
    _markerOf(to, 'move', from);

Future<bool> _emptyOrAbsent(String dir) async {
  final type = await FileSystemEntity.type(dir);
  if (type == FileSystemEntityType.notFound) return true;
  if (type != FileSystemEntityType.directory) return false;
  try {
    return await Directory(dir).list().isEmpty;
  } on Object {
    return false;
  }
}

Future<String?> _existingAncestor(String path) async {
  var p = path;
  while (true) {
    if (await FileSystemEntity.isDirectory(p)) return p;
    if (await FileSystemEntity.type(p) != FileSystemEntityType.notFound) {
      return null; // a file in the way
    }
    final parent = Directory(p).parent.path;
    if (parent == p) return null;
    p = parent;
  }
}

/// Creates and removes a uniquely named empty file in [dir].
Future<bool> _writable(String dir) async {
  final f = File(
    _join(
      dir,
      '.epic-wallet-write-test-$pid-${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  try {
    await f.create(exclusive: true);
    await f.delete();
    return true;
  } on Object {
    return false;
  }
}

/// Removes `<to>.partial` when it carries our marker; refuses one that does not.
Future<void> _removeOurPartial(String to) async {
  final partial = '$to.partial';
  final type = await FileSystemEntity.type(partial, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (type != FileSystemEntityType.directory ||
      !await File(_join(partial, copyMarkerName)).exists()) {
    throw DataFolderException(
      DataFolderFailure.partialNotOurs,
      '$partial exists and was not made by this app; move it away first',
    );
  }
  await _deleteTree(partial);
}

/// Renames [from] to [to] (an empty [to] is replaced). False when they are on different volumes
/// after all, so the caller copies.
Future<bool> _tryRename(String from, String to) async {
  try {
    await Directory(to).parent.create(recursive: true);
    if (await Directory(to).exists()) await Directory(to).delete();
    await Directory(from).rename(to);
    return true;
  } on FileSystemException catch (e) {
    // EXDEV (18) on Unix, ERROR_NOT_SAME_DEVICE (17) on Windows.
    final code = e.osError?.errorCode;
    if (code == 18 || (Platform.isWindows && code == 17)) return false;
    throw DataFolderException(
      DataFolderFailure.io,
      'rename failed: ${e.message} ${e.osError ?? ''}',
    );
  }
}

/// Lock files that are not copied: they are recreated, and a held one says nothing about the copy.
bool _skipped(String rel) {
  final name = rel.substring(rel.lastIndexOf(Platform.pathSeparator) + 1);
  return rel == 'epic.lock' || name == 'lock.mdb';
}

/// Copies the tree [from] into `<to>.partial` (marker first), checks it, renames it to [to]. The
/// marker stays in [to]; the caller removes it when its op is through.
Future<void> _copyInto(
  String from,
  String to, {
  required String op,
  void Function(int done, int total)? progress,
  bool Function()? cancelled,
}) async {
  final dirs = <String>[];
  final files = <String, int>{};
  final pending = [from];
  while (pending.isNotEmpty) {
    final d = pending.removeLast();
    await for (final e in Directory(d).list(followLinks: false)) {
      final rel = e.path.substring(from.length + 1);
      if (e is Link) {
        throw DataFolderException(
          DataFolderFailure.symlink,
          '${e.path} is a link; chain data with links is not copied',
        );
      } else if (e is Directory) {
        dirs.add(rel);
        pending.add(e.path);
      } else if (e is File) {
        if (!_skipped(rel)) files[rel] = await e.length();
      }
    }
  }
  final total = files.values.fold(0, (a, b) => a + b);
  final partial = '$to.partial';
  try {
    await Directory(partial).create(recursive: true);
    final marker = await File(_join(partial, copyMarkerName))
        .open(mode: FileMode.writeOnly);
    await marker.writeString(jsonEncode({'op': op, 'from': from}));
    await marker.flush();
    await marker.close();
    for (final rel in dirs..sort()) {
      await Directory(_join(partial, rel)).create(recursive: true);
    }
    var done = 0;
    progress?.call(0, total);
    for (final entry in files.entries) {
      final copied = await _copyFile(
        _join(from, entry.key),
        _join(partial, entry.key),
        cancelled: cancelled,
        onChunk: (n) {
          done += n;
          progress?.call(done, total);
        },
      );
      files[entry.key] = copied;
    }
    // Check: every file there with the bytes copied, and the source still that size; nothing else.
    final found = <String, int>{};
    final walk = [partial];
    while (walk.isNotEmpty) {
      final d = walk.removeLast();
      await for (final e in Directory(d).list(followLinks: false)) {
        final rel = e.path.substring(partial.length + 1);
        if (e is Directory) {
          walk.add(e.path);
        } else if (rel != copyMarkerName) {
          found[rel] = await File(e.path).length();
        }
      }
    }
    var ok = found.length == files.length;
    for (final MapEntry(:key, :value) in files.entries) {
      if (!ok) break;
      ok =
          found[key] == value && await File(_join(from, key)).length() == value;
    }
    if (!ok) {
      throw DataFolderException(
        DataFolderFailure.verifyFailed,
        'the copy in $partial does not match $from (${found.length} of ${files.length} files)',
      );
    }
    // an empty target, checked before, is replaced
    if (await Directory(to).exists()) await Directory(to).delete();
    await Directory(partial).rename(to);
  } on Object catch (e) {
    try {
      if (await Directory(partial).exists()) await _deleteTree(partial);
    } on Object {
      // left for the next attempt, which removes it by its marker
    }
    if (e is DataFolderException) rethrow;
    throw DataFolderException(DataFolderFailure.io, 'copy failed: $e');
  }
}

const _chunk = 1 << 20;

/// Copies one file in chunks, flushed to disk; returns the bytes copied.
Future<int> _copyFile(
  String from,
  String to, {
  bool Function()? cancelled,
  required void Function(int n) onChunk,
}) async {
  final src = await File(from).open(); // read only
  RandomAccessFile? dst;
  var n = 0;
  try {
    dst = await File(to).open(mode: FileMode.writeOnly);
    while (true) {
      if (cancelled?.call() ?? false) {
        throw const DataFolderException(
          DataFolderFailure.cancelled,
          'cancelled',
        );
      }
      final bytes = await src.read(_chunk);
      if (bytes.isEmpty) break;
      await dst.writeFrom(bytes);
      n += bytes.length;
      onChunk(bytes.length);
    }
    await dst.flush();
    return n;
  } finally {
    await src.close();
    await dst?.close();
  }
}

/// Deletes the tree under [dir], that exact folder. Links inside are removed, not followed.
Future<void> _deleteTree(String dir) async {
  try {
    await Directory(dir).delete(recursive: true);
  } on FileSystemException catch (e) {
    throw DataFolderException(
      DataFolderFailure.io,
      'could not delete $dir: ${e.message} ${e.osError ?? ''}',
    );
  }
}

Future<void> _deleteFile(String file) async {
  try {
    await File(file).delete();
  } on FileSystemException {
    // already gone
  }
}

/// Free bytes on [directory]'s volume, or null when unknown: `df -Pk` on Unix, Get-PSDrive on
/// Windows (a drive letter only).
Future<int?> _freeBytes(String directory) async {
  try {
    if (Platform.isWindows) {
      final drive = directory.length > 1 && directory[1] == ':'
          ? directory[0]
          : null;
      if (drive == null) return null;
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '(Get-PSDrive -Name $drive).Free',
      ]);
      return int.tryParse((r.stdout as String).trim());
    }
    final r = await Process.run('df', ['-Pk', directory]);
    if (r.exitCode != 0) return null;
    final lines = (r.stdout as String).trim().split('\n');
    if (lines.length < 2) return null;
    final cols = lines.last.trim().split(RegExp(r'\s+'));
    final kb = int.tryParse(cols.length > 3 ? cols[3] : '');
    return kb == null ? null : kb * 1024;
  } on Object {
    return null;
  }
}

/// Same volume: the same drive letter on Windows (null for UNC paths), the same mount point by
/// `df -P` on Unix.
Future<bool?> _sameVolume(String a, String b) async {
  try {
    if (Platform.isWindows) {
      bool letter(String p) => p.length > 1 && p[1] == ':';
      if (!letter(a) || !letter(b)) return null;
      return a[0].toLowerCase() == b[0].toLowerCase();
    }
    final r = await Process.run('df', ['-P', a, b]);
    if (r.exitCode != 0) return null;
    final lines = (r.stdout as String).trim().split('\n');
    if (lines.length != 3) return null;
    // the file system and its mount point (which may hold spaces); the numbers between differ
    String volume(String line) {
      final cols = line.trim().split(RegExp(r'\s+'));
      return cols.length < 6
          ? line
          : '${cols.first} ${cols.sublist(5).join(' ')}';
    }

    return volume(lines[1]) == volume(lines[2]);
  } on Object {
    return null;
  }
}
