/// A minimal read-only LevelDB reader, for the IndexedDB of older Epic GUIs (Chromium keeps each
/// origin's IndexedDB in one LevelDB folder). Plain dart:io.
///
/// It reads CURRENT and the MANIFEST to learn which tables (.ldb, .sst) and write-ahead logs
/// (.log) are live, reads them, and keeps the newest version of every key by sequence number,
/// dropping deleted keys. Files are only opened for reading: no LOCK is taken and nothing is
/// written, so a running Chromium is not disturbed (its last, unflushed writes may be missing).
///
/// Everything is bounded (files, bytes, entries) and every malformed byte becomes a note; nothing
/// here throws on bad input.
library;

import 'dart:io';
import 'dart:typed_data';

import 'snappy.dart';

/// Limits of one read.
class LevelDbLimits {
  const LevelDbLimits({
    this.maxFiles = 200,
    this.maxFileBytes = 64 << 20,
    this.maxTotalBytes = 256 << 20,
    this.maxEntries = 500000,
  });

  /// Directory entries looked at, and live files read.
  final int maxFiles;
  final int maxFileBytes;
  final int maxTotalBytes;

  /// Distinct keys kept.
  final int maxEntries;
}

/// The live keys and values of a LevelDB, as far as they could be read.
class LevelDbSnapshot {
  LevelDbSnapshot(this.entries, this.notes);

  /// Key bytes (as a latin1 string, one char per byte) → value.
  final Map<String, Uint8List> entries;

  /// What could not be read, and why. Empty when everything was read.
  final List<String> notes;
}

class _Version {
  _Version(this.seq, this.value);
  final int seq;

  /// null: deleted.
  final Uint8List? value;
}

const int _blockSize = 32768;

/// Reads the LevelDB in [dir]. Never throws.
Future<LevelDbSnapshot> readLevelDb(String dir, {LevelDbLimits limits = const LevelDbLimits()}) async {
  final r = _Reader(dir, limits);
  try {
    await r.run();
  } catch (e) {
    r.notes.add('leveldb $dir: ${_why(e)}');
  }
  final out = <String, Uint8List>{};
  r.versions.forEach((k, v) {
    if (v.value != null) out[k] = v.value!;
  });
  return LevelDbSnapshot(out, r.notes);
}

String _why(Object e) => e is FormatException ? e.message : e is FileSystemException ? e.message : e.toString();

class _Reader {
  _Reader(this.dir, this.limits);

  final String dir;
  final LevelDbLimits limits;
  final notes = <String>[];
  final versions = <String, _Version>{};
  int _bytesRead = 0;
  bool _full = false;

  String _p(String name) => '$dir${Platform.pathSeparator}$name';

  Future<void> run() async {
    final names = <String>[];
    await for (final e in Directory(dir).list(followLinks: false)) {
      if (names.length >= limits.maxFiles) {
        notes.add('leveldb: more than ${limits.maxFiles} files; the rest were not looked at');
        break;
      }
      if (e is File) names.add(e.uri.pathSegments.last);
    }
    final tables = <int, String>{}, logs = <int, String>{};
    for (final n in names) {
      final m = RegExp(r'^(\d{1,12})\.(ldb|sst|log)$').firstMatch(n);
      if (m == null) continue;
      (m[2] == 'log' ? logs : tables)[int.parse(m[1]!)] = n;
    }

    // which files are live, from the MANIFEST CURRENT names
    final live = await _manifest(names);
    List<int> tableNums, logNums;
    if (live == null) {
      notes.add('leveldb: the MANIFEST could not be read; every table and log in the folder was read');
      tableNums = tables.keys.toList()..sort();
      logNums = logs.keys.toList()..sort();
    } else {
      tableNums = live.files.toList()..sort();
      for (final t in tableNums) {
        if (!tables.containsKey(t)) notes.add('leveldb: table $t is missing');
      }
      tableNums = [for (final t in tableNums) if (tables.containsKey(t)) t];
      logNums = [for (final l in logs.keys) if (l >= live.logNumber || l == live.prevLogNumber) l]..sort();
    }
    var count = 0;
    for (final t in tableNums) {
      if (++count > limits.maxFiles || _full) break;
      await _guard(tables[t]!, () => _readTable(tables[t]!));
    }
    for (final l in logNums) {
      if (++count > limits.maxFiles || _full) break;
      await _guard(logs[l]!, () => _readLog(logs[l]!));
    }
  }

  Future<void> _guard(String name, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      notes.add('leveldb $name: ${_why(e)}');
    }
  }

  Future<Uint8List> _readFile(String name) async {
    final f = File(_p(name));
    final size = await f.length();
    if (size > limits.maxFileBytes) throw FormatException('$size bytes, larger than ${limits.maxFileBytes}');
    if (_bytesRead + size > limits.maxTotalBytes) throw const FormatException('the read limit was reached');
    _bytesRead += size;
    return f.readAsBytes();
  }

  void _put(Uint8List key, int seq, Uint8List? value) {
    final k = String.fromCharCodes(key);
    final old = versions[k];
    if (old != null && old.seq > seq) return;
    if (old == null && versions.length >= limits.maxEntries) {
      if (!_full) notes.add('leveldb: more than ${limits.maxEntries} keys; the rest were not read');
      _full = true;
      return;
    }
    versions[k] = _Version(seq, value);
  }

  // ---- MANIFEST

  Future<_Live?> _manifest(List<String> names) async {
    if (!names.contains('CURRENT')) {
      notes.add('leveldb: no CURRENT file');
      return null;
    }
    try {
      final cur = await File(_p('CURRENT')).readAsBytes();
      if (cur.length > 256) throw const FormatException('CURRENT is too large');
      final name = String.fromCharCodes(cur).trim();
      if (!RegExp(r'^MANIFEST-\d{1,12}$').hasMatch(name) || !names.contains(name)) {
        throw FormatException('CURRENT names no MANIFEST here');
      }
      final live = _Live();
      var edits = 0;
      for (final rec in _logRecords(await _readFile(name), name)) {
        if (++edits > 100000) throw const FormatException('too many MANIFEST records');
        _applyEdit(rec, live);
      }
      if (edits == 0) throw const FormatException('the MANIFEST is empty');
      return live;
    } catch (e) {
      notes.add('leveldb MANIFEST: ${_why(e)}');
      return null;
    }
  }

  void _applyEdit(Uint8List rec, _Live live) {
    final b = _Bytes(rec);
    while (!b.done) {
      final tag = b.varint();
      switch (tag) {
        case 1: // comparator
          b.skip(b.varint());
        case 2:
          live.logNumber = b.varint();
        case 3: // next file number
        case 4: // last sequence
          b.varint();
        case 5: // compact pointer
          b.varint();
          b.skip(b.varint());
        case 6: // deleted file
          final level = b.varint(), n = b.varint();
          live.byLevel[level]?.remove(n);
        case 7: // new file
          final level = b.varint(), n = b.varint();
          b.varint(); // size
          b.skip(b.varint()); // smallest
          b.skip(b.varint()); // largest
          if (level < 0 || level > 20) throw const FormatException('bad level in MANIFEST');
          live.byLevel.putIfAbsent(level, () => <int>{}).add(n);
        case 9:
          live.prevLogNumber = b.varint();
        default:
          throw FormatException('unknown MANIFEST tag $tag');
      }
    }
  }

  // ---- write-ahead log

  Future<void> _readLog(String name) async {
    for (final rec in _logRecords(await _readFile(name), name)) {
      _applyBatch(rec, name);
      if (_full) return;
    }
  }

  /// The records of a log-format file (a .log or the MANIFEST). A torn or corrupt record ends the
  /// file with a note: what follows it cannot be trusted.
  Iterable<Uint8List> _logRecords(Uint8List data, String name) sync* {
    var pos = 0;
    BytesBuilder? partial;
    while (pos < data.length) {
      final left = _blockSize - pos % _blockSize;
      if (left < 7) {
        pos += left;
        continue;
      }
      if (pos + 7 > data.length) break; // a zero tail
      final crc = _u32(data, pos);
      final len = data[pos + 4] | (data[pos + 5] << 8);
      final type = data[pos + 6];
      if (type == 0 && len == 0 && crc == 0) {
        // preallocated zeros: the rest of the block is empty
        pos += left;
        continue;
      }
      if (len > left - 7 || pos + 7 + len > data.length) {
        notes.add('leveldb $name: a record is cut off at byte $pos; the rest was not read');
        return;
      }
      if (_unmask(crc) != _crc32c(data, pos + 6, len + 1)) {
        notes.add('leveldb $name: a damaged record at byte $pos; the rest was not read');
        return;
      }
      final body = Uint8List.sublistView(data, pos + 7, pos + 7 + len);
      pos += 7 + len;
      switch (type) {
        case 1: // full
          partial = null;
          yield body;
        case 2: // first
          partial = BytesBuilder(copy: true)..add(body);
        case 3: // middle
          partial?.add(body);
          if ((partial?.length ?? 0) > limits.maxFileBytes) partial = null;
        case 4: // last
          if (partial != null) {
            partial.add(body);
            final out = partial.takeBytes();
            partial = null;
            yield out;
          }
        default:
          notes.add('leveldb $name: an unknown record type $type; the rest was not read');
          return;
      }
    }
  }

  void _applyBatch(Uint8List rec, String name) {
    if (rec.length < 12) {
      notes.add('leveldb $name: a short write batch');
      return;
    }
    final seq = _u64(rec, 0);
    final count = _u32(rec, 8);
    final b = _Bytes(rec)..pos = 12;
    try {
      for (var i = 0; i < count && !b.done; i++) {
        final tag = b.byte();
        final key = b.bytes(b.varint());
        if (tag == 1) {
          _put(key, seq + i, Uint8List.fromList(b.bytes(b.varint())));
        } else if (tag == 0) {
          _put(key, seq + i, null);
        } else {
          throw FormatException('an unknown batch tag $tag');
        }
      }
    } on FormatException catch (e) {
      notes.add('leveldb $name: ${e.message}');
    }
  }

  // ---- tables

  Future<void> _readTable(String name) async {
    final data = await _readFile(name);
    // the magic 0xdb4775248b80fb57, little-endian
    if (data.length < 48 || _u32(data, data.length - 8) != 0x8b80fb57 || _u32(data, data.length - 4) != 0xdb477524) {
      throw const FormatException('not a table (no footer)');
    }
    final f = _Bytes(Uint8List.sublistView(data, data.length - 48, data.length - 8));
    f.varint(); // metaindex offset
    f.varint(); // metaindex size
    final indexOff = f.varint(), indexSize = f.varint();
    final index = _block(data, indexOff, indexSize);
    var blocks = 0;
    for (final (_, handle) in _blockEntries(index)) {
      if (++blocks > 1000000) throw const FormatException('too many blocks');
      final h = _Bytes(handle);
      final off = h.varint(), size = h.varint();
      try {
        for (final (ikey, value) in _blockEntries(_block(data, off, size))) {
          if (ikey.length < 8) throw const FormatException('a short key');
          final tag = _u64(ikey, ikey.length - 8);
          final user = Uint8List.sublistView(ikey, 0, ikey.length - 8);
          final type = tag & 0xff, seq = tag >>> 8;
          if (type == 1) {
            _put(user, seq, Uint8List.fromList(value));
          } else if (type == 0) {
            _put(user, seq, null);
          }
          if (_full) return;
        }
      } on FormatException catch (e) {
        // one bad block: the others may still be good
        notes.add('leveldb $name: a block at $off: ${e.message}');
      }
    }
  }

  /// A block's contents, checked and decompressed.
  Uint8List _block(Uint8List data, int off, int size) {
    if (off < 0 || size < 0 || off + size + 5 > data.length) throw const FormatException('a block outside the file');
    final type = data[off + size];
    if (_unmask(_u32(data, off + size + 1)) != _crc32c(data, off, size + 1)) {
      throw const FormatException('a damaged block (checksum)');
    }
    final raw = Uint8List.sublistView(data, off, off + size);
    return switch (type) {
      0 => raw,
      1 => snappyDecompress(raw, maxLength: limits.maxFileBytes),
      _ => throw FormatException('compression $type is not supported'),
    };
  }

  /// The (key, value) entries of a block, keys rebuilt from their shared prefixes.
  Iterable<(Uint8List, Uint8List)> _blockEntries(Uint8List block) sync* {
    if (block.length < 4) throw const FormatException('a short block');
    final restarts = _u32(block, block.length - 4);
    final end = block.length - 4 - 4 * restarts;
    if (restarts < 0 || end < 0) throw const FormatException('a bad block');
    final b = _Bytes(Uint8List.sublistView(block, 0, end));
    var key = Uint8List(0);
    while (!b.done) {
      final shared = b.varint(), nonShared = b.varint(), valueLen = b.varint();
      if (shared > key.length) throw const FormatException('a bad key prefix');
      final k = Uint8List(shared + nonShared)
        ..setRange(0, shared, key)
        ..setRange(shared, shared + nonShared, b.bytes(nonShared));
      key = k;
      yield (k, b.bytes(valueLen));
    }
  }
}

class _Live {
  int logNumber = 0;
  int prevLogNumber = -1;
  final byLevel = <int, Set<int>>{};
  Iterable<int> get files => byLevel.values.expand((s) => s);
}

/// A cursor over bytes; reading past the end throws a [FormatException].
class _Bytes {
  _Bytes(this.data);
  final Uint8List data;
  int pos = 0;

  bool get done => pos >= data.length;

  int byte() {
    if (pos >= data.length) throw const FormatException('cut off');
    return data[pos++];
  }

  int varint() {
    var r = 0;
    for (var shift = 0; shift < 64; shift += 7) {
      final b = byte();
      r |= (b & 0x7f) << shift;
      if (b < 0x80) return r;
    }
    throw const FormatException('a bad varint');
  }

  Uint8List bytes(int n) {
    if (n < 0 || n > data.length - pos) throw const FormatException('cut off');
    final out = Uint8List.sublistView(data, pos, pos + n);
    pos += n;
    return out;
  }

  void skip(int n) => bytes(n);
}

int _u32(Uint8List d, int i) => d[i] | (d[i + 1] << 8) | (d[i + 2] << 16) | (d[i + 3] << 24);
int _u64(Uint8List d, int i) => _u32(d, i) | (_u32(d, i + 4) << 32);

int _unmask(int masked) {
  final rot = (masked - 0xa282ead8) & 0xffffffff;
  return ((rot >>> 17) | (rot << 15)) & 0xffffffff;
}

final Uint32List _crcTable = () {
  final t = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0x82f63b78 ^ (c >>> 1) : c >>> 1;
    }
    t[n] = c;
  }
  return t;
}();

/// CRC-32C (Castagnoli), as LevelDB checks its records and blocks.
int _crc32c(Uint8List d, int start, int len) {
  var c = 0xffffffff;
  for (var i = start; i < start + len; i++) {
    c = _crcTable[(c ^ d[i]) & 0xff] ^ (c >>> 8);
  }
  return c ^ 0xffffffff;
}
