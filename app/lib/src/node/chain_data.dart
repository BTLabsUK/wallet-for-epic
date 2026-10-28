// SPDX-License-Identifier: Apache-2.0
/// Chain data folders of Epic nodes on this machine: what is in one (size, age, whether a node of
/// 4.1.0 can sync on from it), whether a node runs on it, and where the CLI node and GUI 6.1 keep
/// theirs. Read only: nothing here creates, writes, renames or deletes a file.
///
/// The rules are those of GUI 6.1.6 (src/shared/legacyScan.js scanChains, chainOffer.js
/// usableChain, folderLock.js), ported.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../legacy_wallets.dart' show LegacyRoots;
import '../models.dart' show Chain;

/// Where a chain data folder was found.
enum ChainDataSource {
  /// Our own built-in node's folder.
  bundled,

  /// The CLI node's `~/.epic/<net>/chain_data`.
  cli,

  /// GUI 6.1's built-in node, `<gui root>/node/<net>/chain_data`.
  gui,

  /// A folder the user chose (GUI 6.1's `node.<network>.chainDir` setting, or picked by hand).
  custom,
}

/// Whether a node runs on a chain data folder, told by trying its `epic.lock`.
enum FolderLock { free, locked, unknown }

/// What [inspectChainData] found in one chain data folder.
class ChainDataInfo {
  const ChainDataInfo({
    required this.path,
    required this.source,
    required this.chain,
    required this.bytes,
    required this.headerBytes,
    required this.txhashsetBytes,
    required this.modified,
    required this.lock,
    required this.usable,
  });

  /// The `chain_data` folder, canonical (symlinks resolved).
  final String path;
  final ChainDataSource source;
  final Chain chain;

  /// Everything under [path] (see [dirSize]).
  final int bytes;

  /// `header/header_head/pmmr_hash.bin`: about 64 bytes a header.
  final int headerBytes;
  final int txhashsetBytes;

  /// The newest change time of the key files, or null when none could be read.
  final DateTime? modified;
  final FolderLock lock;

  /// A node of 4.1.0 can sync on from it (see [usableChainData]).
  final bool usable;

  @override
  String toString() =>
      'ChainDataInfo($path, $source, $chain, bytes: $bytes, headers: $headerBytes, '
      'txhashset: $txhashsetBytes, modified: $modified, lock: $lock, usable: $usable)';
}

/// What every node 3.0.0 – 4.1.0-1 writes (txhashset/kernel, output and rangeproof are folders); all must be there for the data to be offered.
const chainDataLayout = [
  ['lmdb', 'data.mdb'],
  ['header', 'header_head', 'pmmr_hash.bin'],
  ['txhashset', 'kernel'],
  ['txhashset', 'output'],
  ['txhashset', 'rangeproof'],
];

/// Whether everything in [chainDataLayout] is under [dir] (the txhashset entries are folders).
Future<bool> chainLayoutComplete(String dir) async {
  for (final part in chainDataLayout) {
    final type = await FileSystemEntity.type(joinPath([dir, ...part]));
    if (type == FileSystemEntityType.notFound) return false;
  }
  return true;
}

/// Header hashes a mainnet chain needs to be offered, so a node stopped right after it started is
/// not. Floonet and usernet: any headers.
const minMainnetHeaderBytes = 64 * 1000;

/// The GUI's USABLE rule: the whole [chainDataLayout] is there and the headers are enough for
/// [chain]. `lmdb/data.mdb` is no measure (on Windows LMDB sizes it to its map size, empty or not);
/// an empty txhashset (headers only) still counts, the headers alone save most of the sync.
bool usableChainData({
  required Chain chain,
  required bool layoutComplete,
  required int headerBytes,
}) =>
    layoutComplete &&
    (chain == Chain.mainnet
        ? headerBytes >= minMainnetHeaderBytes
        : headerBytes > 0);

/// The folder name epic uses for [chain]: main, floo, user.
String chainFolderName(Chain chain) => switch (chain) {
  Chain.mainnet => 'main',
  Chain.floonet => 'floo',
  Chain.usernet => 'user',
};

/// Tries the lock of one `epic.lock` file that exists. Injectable for tests.
typedef LockProbe = Future<FolderLock> Function(String lockFile);

/// Looks at [chainDataDir]: null when it is not a folder. [probe] tries the lock (default
/// [probeChainLock]'s own).
Future<ChainDataInfo?> inspectChainData(
  String chainDataDir, {
  required Chain chain,
  required ChainDataSource source,
  LockProbe? probe,
}) async {
  final String path;
  try {
    if (!await FileSystemEntity.isDirectory(chainDataDir)) return null;
    path = await Directory(chainDataDir).resolveSymbolicLinks();
  } on Object {
    return null;
  }
  final complete = await chainLayoutComplete(path);
  final headerBytes = await _length(
    joinPath([path, 'header', 'header_head', 'pmmr_hash.bin']),
  );
  DateTime? modified;
  for (final p in [
    joinPath([path, 'lmdb', 'data.mdb']),
    joinPath([path, 'lmdb']),
    joinPath([path, 'txhashset']),
    joinPath([path, 'header', 'header_head', 'pmmr_hash.bin']),
  ]) {
    try {
      final st = await FileStat.stat(p);
      if (st.type == FileSystemEntityType.notFound) continue;
      if (modified == null || st.modified.isAfter(modified)) {
        modified = st.modified;
      }
    } on Object {
      // unreadable: not counted
    }
  }
  return ChainDataInfo(
    path: path,
    source: source,
    chain: chain,
    bytes: await dirSize(path),
    headerBytes: headerBytes,
    txhashsetBytes: await dirSize(joinPath([path, 'txhashset'])),
    modified: modified,
    lock: await probeChainLock(path, probe: probe),
    usable: usableChainData(
      chain: chain,
      layoutComplete: complete,
      headerBytes: headerBytes,
    ),
  );
}

Future<int> _length(String file) async {
  try {
    return await File(file).length();
  } on Object {
    return 0;
  }
}

/// Where other Epic programs keep chain data for [chain], as `(path, source)`, existing or not: the
/// CLI node's `<home>/.epic/<net>/chain_data` (also under %USERPROFILE% on Windows), GUI 6.1's
/// `<gui root>/node/<net>/chain_data` and the chain folder GUI 6.1's settings name for [chain].
/// Reads only `location.json` and `settings.json` of GUI 6.1, each at most [_maxJsonBytes].
Future<List<(String, ChainDataSource)>> foreignChainDataPaths(
  Chain chain, {
  required LegacyRoots roots,
}) async {
  final net = chainFolderName(chain);
  final out = <(String, ChainDataSource)>[];
  for (final h in _homes(roots)) {
    out.add((joinPath([h, '.epic', net, 'chain_data']), ChainDataSource.cli));
  }
  final guiRoot = await guiRootOf(roots);
  if (guiRoot != null) {
    out.add((
      joinPath([guiRoot, 'node', net, 'chain_data']),
      ChainDataSource.gui,
    ));
    final settings = await _readJson(joinPath([guiRoot, 'settings.json']));
    final node = settings is Map ? settings['node'] : null;
    final entry = node is Map ? node[chain.name] : null;
    final dir = entry is Map ? entry['chainDir'] : null;
    if (dir is String && _isAbsolute(dir)) {
      out.add((dir, ChainDataSource.custom));
    }
  }
  return out;
}

/// GUI 6.1's root: EPIC_GUI_HOME ([LegacyRoots.guiHome]) when absolute, else
/// `<home>/.epic-gui/location.json` {"root"} when absolute, else `<home>/.epic-gui` (home is
/// %USERPROFILE% on Windows when set). appPaths.js resolveRoot.
Future<String?> guiRootOf(LegacyRoots roots) async {
  final env = roots.guiHome;
  if (env != null && _isAbsolute(env)) return env;
  final base = roots.userProfile != null && _isAbsolute(roots.userProfile!)
      ? roots.userProfile!
      : roots.home;
  if (base.isEmpty) return null;
  final def = joinPath([base, '.epic-gui']);
  final loc = await _readJson(joinPath([def, 'location.json']));
  final root = loc is Map ? loc['root'] : null;
  if (root is String && _isAbsolute(root)) return root;
  return def;
}

/// The chain data of other nodes for [chain] (see [foreignChainDataPaths]), each inspected once
/// (deduplicated by canonical path), never our own: a folder that is [bundledRoot]'s
/// `<net>/chain_data` is left out ([inspectChainData] it directly). Usable first, then the most
/// recently changed, then the larger.
Future<List<ChainDataInfo>> findChainData(
  Chain chain, {
  required LegacyRoots roots,
  String? bundledRoot,
  LockProbe? probe,
}) async {
  final seen = <String>{};
  if (bundledRoot != null) {
    final own = await canonicalPath(
      joinPath([bundledRoot, chainFolderName(chain), 'chain_data']),
    );
    seen.add(_key(own));
  }
  final out = <ChainDataInfo>[];
  for (final (dir, source) in await foreignChainDataPaths(
    chain,
    roots: roots,
  )) {
    final String canonical;
    try {
      if (!await FileSystemEntity.isDirectory(dir)) continue;
      canonical = await Directory(dir).resolveSymbolicLinks();
    } on Object {
      continue;
    }
    if (!seen.add(_key(canonical))) continue;
    final info = await inspectChainData(
      canonical,
      chain: chain,
      source: source,
      probe: probe,
    );
    if (info != null) out.add(info);
  }
  out.sort(compareChainData);
  return out;
}

/// Usable first, then the most recently changed, then the larger.
int compareChainData(ChainDataInfo a, ChainDataInfo b) {
  if (a.usable != b.usable) return a.usable ? -1 : 1;
  final am = a.modified?.millisecondsSinceEpoch ?? 0;
  final bm = b.modified?.millisecondsSinceEpoch ?? 0;
  if (am != bm) return bm.compareTo(am);
  return b.bytes.compareTo(a.bytes);
}

/// Bytes of every file under [dir], recursively. Never follows a symlink (a link counts as
/// nothing, and is not entered), so each file is counted once along its one path; hard links are
/// counted per name (dart:io has no inode). A file or folder that vanishes or cannot be read
/// mid-walk counts as nothing. A missing [dir] is 0.
///
/// On Windows LMDB's `data.mdb` is preallocated to the map size: this reports its plain length,
/// which may be far more than the disk space it really takes.
Future<int> dirSize(String dir) async {
  var total = 0;
  final pending = [Directory(dir)];
  while (pending.isNotEmpty) {
    final d = pending.removeLast();
    try {
      await for (final e in d.list(followLinks: false)) {
        if (e is Directory) {
          pending.add(e);
        } else if (e is File) {
          try {
            total += await e.length();
          } on Object {
            // vanished or unreadable
          }
        }
      }
    } on Object {
      // vanished or unreadable
    }
  }
  return total;
}

/// Whether a node runs on [chainDataDir]. epic holds `chain_data/epic.lock` with fs2
/// try_lock_exclusive while it runs: flock(LOCK_EX|LOCK_NB) on Unix, LockFileEx on Windows. The file
/// stays after the node exits, so only trying the lock tells; a missing file is [FolderLock.free].
///
/// dart:io's [RandomAccessFile.lock] is fcntl on Linux and macOS, which does not see flock locks
/// (checked: it takes the lock while `flock` holds the file), so on Unix a child process tries the
/// flock: perl (macOS and almost every Linux have it), else util-linux `flock` on Linux. On Windows
/// dart:io's lock is LockFileEx, the same as epic's, and is used directly. The file is only ever
/// opened read-only (no create, no write, no delete); [FolderLock.unknown] when it cannot be told.
Future<FolderLock> probeChainLock(
  String chainDataDir, {
  LockProbe? probe,
}) async {
  final lockFile = joinPath([chainDataDir, 'epic.lock']);
  final FileSystemEntityType type;
  try {
    type = await FileSystemEntity.type(lockFile, followLinks: false);
  } on Object {
    return FolderLock.unknown;
  }
  if (type == FileSystemEntityType.notFound) return FolderLock.free;
  if (type != FileSystemEntityType.file) return FolderLock.unknown;
  try {
    return await (probe ?? systemLockProbe)(lockFile);
  } on Object {
    return FolderLock.unknown;
  }
}

/// The real [LockProbe] of this platform (see [probeChainLock]).
Future<FolderLock> systemLockProbe(String lockFile) =>
    Platform.isWindows ? _windowsProbe(lockFile) : _unixProbe(lockFile);

Future<FolderLock> _windowsProbe(String lockFile) async {
  RandomAccessFile? f;
  try {
    f = await File(lockFile).open(); // FileMode.read: never creates
  } on Object {
    return FolderLock.unknown;
  }
  try {
    // LockFileEx exclusive, fail immediately, bytes 0..max: overlaps epic's whole-file lock.
    await f.lock(FileLock.exclusive);
    await f.unlock();
    return FolderLock.free;
  } on FileSystemException catch (e) {
    // ERROR_LOCK_VIOLATION (33): another handle holds it.
    return e.osError?.errorCode == 33 ? FolderLock.locked : FolderLock.unknown;
  } on Object {
    return FolderLock.unknown;
  } finally {
    try {
      await f.close();
    } on Object {
      // nothing to do
    }
  }
}

/// Prints `free`, `locked` or `error <errno>` for the file given as the argument. O_RDONLY: never
/// creates the file.
const _perlFlockProbe = r'''
use strict; use warnings;
use Fcntl qw(O_RDONLY O_NONBLOCK LOCK_EX LOCK_NB LOCK_UN);
use Errno qw(EWOULDBLOCK EAGAIN);
my $fh;
if (!sysopen($fh, $ARGV[0], O_RDONLY | O_NONBLOCK)) { print "error ", $! + 0, "\n"; exit 0; }
if (flock($fh, LOCK_EX | LOCK_NB)) { flock($fh, LOCK_UN); print "free\n"; }
elsif ($! == EWOULDBLOCK || $! == EAGAIN) { print "locked\n"; }
else { print "error ", $! + 0, "\n"; }
close $fh;
''';

const _probeTimeout = Duration(seconds: 5);

Future<FolderLock> _unixProbe(String lockFile) async {
  final perl = await File('/usr/bin/perl').exists() ? '/usr/bin/perl' : 'perl';
  final viaPerl = await _run(perl, ['-e', _perlFlockProbe, '--', lockFile]);
  if (viaPerl != null && viaPerl.code == 0) {
    final out = viaPerl.stdout.trim();
    if (out == 'free') return FolderLock.free;
    if (out == 'locked') return FolderLock.locked;
    return FolderLock.unknown;
  }
  if (!Platform.isLinux) return FolderLock.unknown;
  // util-linux flock opens with O_RDONLY|O_CREAT; the file was seen above, so it creates nothing
  // unless the file is deleted in between. -E 200: "held by someone else".
  final viaFlock = await _run('flock', ['-n', '-E', '200', lockFile, 'true']);
  return switch (viaFlock?.code) {
    0 => FolderLock.free,
    200 => FolderLock.locked,
    _ => FolderLock.unknown,
  };
}

/// Runs a short helper with a time-out; null when it could not run or took too long.
Future<({int code, String stdout})?> _run(String exe, List<String> args) async {
  final Process p;
  try {
    p = await Process.start(exe, args, environment: const {'LC_ALL': 'C'});
  } on Object {
    return null;
  }
  final out = p.stdout.transform(utf8.decoder).join();
  unawaited(p.stderr.drain<void>());
  try {
    final code = await p.exitCode.timeout(_probeTimeout);
    return (code: code, stdout: await out);
  } on TimeoutException {
    p.kill(ProcessSignal.sigkill);
    return null;
  }
}

/// [path] with symlinks resolved; for a path that does not exist (yet), its nearest existing
/// ancestor resolved and the rest appended. Absolute.
Future<String> canonicalPath(String path) async {
  var head = File(path).absolute.path;
  final tail = <String>[];
  while (true) {
    try {
      if (await FileSystemEntity.type(head) != FileSystemEntityType.notFound) {
        final resolved = await FileSystemEntity.isDirectory(head)
            ? await Directory(head).resolveSymbolicLinks()
            : await File(head).resolveSymbolicLinks();
        return joinPath([resolved, ...tail.reversed]);
      }
    } on Object {
      // fall through to the parent
    }
    final parent = File(head).parent.path;
    if (parent == head) return joinPath([head, ...tail.reversed]);
    tail.add(_basename(head));
    head = parent;
  }
}

/// A path as compared: case-blind on Windows. (macOS volumes are usually case-blind too; that is
/// not assumed, so two spellings of one macOS folder count as two.)
String _key(String path) => Platform.isWindows ? path.toLowerCase() : path;

/// Whether two canonical paths name the same place.
bool samePath(String a, String b) => _key(_trim(a)) == _key(_trim(b));

/// Whether canonical [inner] is strictly below canonical [outer].
bool isInside(String inner, String outer) {
  final o = _key(_trim(outer));
  final i = _key(_trim(inner));
  final sep = Platform.pathSeparator;
  return i.length > o.length && i.startsWith(o.endsWith(sep) ? o : '$o$sep');
}

String _trim(String p) {
  final sep = Platform.pathSeparator;
  var s = p;
  while (s.length > 1 && s.endsWith(sep) && !s.endsWith(':$sep')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

String _basename(String p) {
  final s = _trim(p);
  final i = s.lastIndexOf(Platform.pathSeparator);
  return i < 0 ? s : s.substring(i + 1);
}

/// [parts] joined with the platform's separator, without doubling one.
String joinPath(List<String> parts) {
  final sep = Platform.pathSeparator;
  final b = StringBuffer();
  for (final part in parts) {
    if (part.isEmpty) continue;
    if (b.isEmpty) {
      b.write(part);
    } else {
      final s = b.toString();
      if (!s.endsWith(sep) && !s.endsWith('/')) b.write(sep);
      b.write(part);
    }
  }
  return b.toString();
}

bool _isAbsolute(String p) => Platform.isWindows
    ? RegExp(r'^([a-zA-Z]:[\\/]|\\\\)').hasMatch(p)
    : p.startsWith('/');

List<String> _homes(LegacyRoots roots) {
  final out = <String>[];
  for (final h in [roots.userProfile, roots.home]) {
    if (h != null && h.isNotEmpty && !out.contains(h)) out.add(h);
  }
  return out;
}

const _maxJsonBytes = 1024 * 1024;

/// A small JSON file, or null when missing, too big or broken.
Future<Object?> _readJson(String file) async {
  try {
    final f = File(file);
    if (await f.length() > _maxJsonBytes) return null;
    return jsonDecode(await f.readAsString());
  } on Object {
    return null;
  }
}
