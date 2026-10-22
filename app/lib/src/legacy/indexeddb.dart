/// Reads object stores of a Chromium IndexedDB database from its LevelDB folder, without
/// Chromium: enough of Chromium's key encoding to find a database and its object stores, and of
/// Blink's and V8's value serialization to decode plain records (objects, arrays, strings,
/// numbers, booleans, null). Read only, bounded, and every bad byte becomes a note.
///
/// Key layout (content/browser/indexed_db/indexed_db_leveldb_coding.cc):
///
/// ```text
///   KeyPrefix(0,0,0) 0xC9 <origin: StringWithLength> <name: StringWithLength>  → database id (varint)
///   KeyPrefix(db,0,0) 0x32 <store id: varint> 0x00                              → store name (UTF-16BE)
///   KeyPrefix(db,store,1) <IDB key>                                              → varint version, value
/// ```
///
/// KeyPrefix: one byte of id sizes ((db-1)<<5 | (store-1)<<2 | (index-1)), then the ids
/// little-endian. A value is Blink's envelope (0xFF version, 0xFE trailer offset from version 21)
/// around V8's ValueSerializer output (0xFF version, then tags).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'leveldb.dart';
import 'snappy.dart';

/// One record of an object store: its primary key and its decoded value.
class IdbRecord {
  const IdbRecord(this.key, this.value);

  /// String, double, or a list of them, as stored.
  final Object? key;

  /// The decoded value: `Map<String, Object?>`, List, String, num, bool or null.
  final Object? value;
}

/// What [readIdbStores] found.
class IdbRead {
  IdbRead(this.found, this.stores, this.notes);

  /// Whether the database exists in the folder.
  final bool found;

  /// Store name → its records in key order. Stores the database lacks are absent.
  final Map<String, List<IdbRecord>> stores;
  final List<String> notes;
}

/// Limits of the value decoder.
const int _maxDepth = 32;
const int _maxString = 1 << 20;
const int _maxNodes = 100000;
const int _maxRecords = 100000;

/// Reads [storeNames] of the IndexedDB database [dbName] in the LevelDB folder [leveldbDir].
/// Never throws.
Future<IdbRead> readIdbStores(String leveldbDir, String dbName, Set<String> storeNames,
    {LevelDbLimits limits = const LevelDbLimits()}) async {
  final snap = await readLevelDb(leveldbDir, limits: limits);
  final notes = [...snap.notes];
  try {
    return _fromSnapshot(snap, dbName, storeNames, notes);
  } catch (e) {
    notes.add('indexeddb: ${e is FormatException ? e.message : e}');
    return IdbRead(false, const {}, notes);
  }
}

IdbRead _fromSnapshot(LevelDbSnapshot snap, String dbName, Set<String> storeNames, List<String> notes) {
  // 1. the database's id: if an origin holds the name twice (it cannot), the first wins
  int? dbId;
  for (final k in snap.entries.keys) {
    if (k.length < 6 || k.codeUnitAt(4) != 0xC9) continue;
    final c = _Cursor(_bytes(k));
    final p = c.prefix();
    if (p == null || p.$1 != 0 || p.$2 != 0 || p.$3 != 0 || c.byte() != 0xC9) continue;
    try {
      c.stringWithLength(); // the origin
      if (c.stringWithLength() != dbName) continue;
      dbId = _Cursor(snap.entries[k]!).varint();
      break;
    } on FormatException {
      continue;
    }
  }
  if (dbId == null) return IdbRead(false, const {}, notes);

  // 2. its object stores, by name
  final storeIds = <int, String>{};
  for (final k in snap.entries.keys) {
    final c = _Cursor(_bytes(k));
    final p = c.prefix();
    if (p == null || p.$1 != dbId || p.$2 != 0 || p.$3 != 0) continue;
    try {
      if (c.byte() != 0x32) continue;
      final id = c.varint();
      if (c.byte() != 0 || !c.done) continue;
      final name = _utf16be(snap.entries[k]!);
      if (storeNames.contains(name)) storeIds[id] = name;
    } on FormatException {
      continue;
    }
  }

  // 3. their records (index id 1: the object store's data)
  final stores = <String, List<(List<int>, IdbRecord)>>{for (final n in storeIds.values) n: []};
  var bad = 0, count = 0;
  for (final e in snap.entries.entries) {
    final kb = _bytes(e.key);
    final c = _Cursor(kb);
    final p = c.prefix();
    if (p == null || p.$1 != dbId || p.$3 != 1) continue;
    final store = storeIds[p.$2];
    if (store == null) continue;
    if (++count > _maxRecords) {
      notes.add('indexeddb: more than $_maxRecords records; the rest were not read');
      break;
    }
    try {
      final keyStart = c.pos;
      final key = c.idbKey(0);
      final v = _Cursor(e.value);
      v.varint(); // the record's version
      final value = decodeIdbValue(Uint8List.sublistView(e.value, v.pos));
      stores[store]!.add((kb.sublist(keyStart), IdbRecord(key, value)));
    } on FormatException catch (x) {
      bad++;
      if (bad <= 5) notes.add('indexeddb: a record in $store could not be decoded (${x.message})');
    }
  }
  if (bad > 5) notes.add('indexeddb: ${bad - 5} more records could not be decoded');
  return IdbRead(true, {
    for (final s in stores.entries) s.key: [for (final r in (s.value..sort(_order))) r.$2],
  }, notes);
}

/// Records in key order, as getAll() gives them: numbers by value, anything else by its encoding.
int _order((List<int>, IdbRecord) a, (List<int>, IdbRecord) b) {
  final x = a.$2.key, y = b.$2.key;
  if (x is num && y is num) return x.compareTo(y);
  return _cmp(a.$1, b.$1);
}

int _cmp(List<int> a, List<int> b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}

Uint8List _bytes(String latin1Key) => Uint8List.fromList(latin1Key.codeUnits);

String _utf16be(Uint8List b) {
  if (b.length.isOdd || b.length > _maxString) throw const FormatException('a bad name');
  final units = List<int>.generate(b.length ~/ 2, (i) => (b[2 * i] << 8) | b[2 * i + 1]);
  return String.fromCharCodes(units);
}

class _Cursor {
  _Cursor(this.data);
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

  Uint8List take(int n) {
    if (n < 0 || n > data.length - pos) throw const FormatException('cut off');
    final out = Uint8List.sublistView(data, pos, pos + n);
    pos += n;
    return out;
  }

  int le(int n) {
    var r = 0;
    for (var i = 0; i < n; i++) {
      r |= byte() << (8 * i);
    }
    return r;
  }

  double float64() => ByteData.sublistView(take(8)).getFloat64(0, Endian.little);

  /// (database id, object store id, index id), or null when the bytes are no KeyPrefix.
  (int, int, int)? prefix() {
    try {
      final b = byte();
      final dbBytes = (b >> 5) + 1, storeBytes = ((b >> 2) & 7) + 1, indexBytes = (b & 3) + 1;
      if (dbBytes > 8 || storeBytes > 8) return null;
      return (le(dbBytes), le(storeBytes), le(indexBytes));
    } on FormatException {
      return null;
    }
  }

  String stringWithLength() {
    final n = varint();
    if (n > _maxString) throw const FormatException('a string too long');
    return _utf16be(take(n * 2));
  }

  /// An encoded IDBKey: 0 null, 1 string, 2 date, 3 number, 4 array, 6 binary.
  Object? idbKey(int depth) {
    if (depth > _maxDepth) throw const FormatException('a key nested too deep');
    return switch (byte()) {
      0 => null,
      1 => stringWithLength(),
      2 || 3 => float64(),
      4 => [for (var i = 0, n = _count(varint()); i < n; i++) idbKey(depth + 1)],
      6 => take(_count(varint())).toList(),
      final t => throw FormatException('an unknown key type $t'),
    };
  }

  int _count(int n) => n > _maxString ? throw const FormatException('a key too long') : n;
}

/// Decodes one stored IndexedDB value: Blink's envelope, then V8's serialization. Throws a
/// [FormatException] on anything it cannot read.
Object? decodeIdbValue(Uint8List bytes) {
  var b = bytes;
  // IndexedDB's own wrapper (Chromium 2023+): 0xFF 0x11, then 1 (moved to a blob) or 2 (Snappy)
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0x11 && (b[2] == 1 || b[2] == 2)) {
    if (b[2] == 1) throw const FormatException('the value is kept in a separate blob file');
    b = snappyDecompress(Uint8List.sublistView(b, 3), maxLength: 16 << 20);
  }
  final c = _Cursor(b);
  // Blink's header: 0xFF <version>; from version 21 a trailer offset follows (0xFE, 8 + 4 bytes)
  if (!c.done && c.data[c.pos] == 0xFF) {
    c.pos++;
    final blink = c.varint();
    if (blink >= 21 && !c.done && c.data[c.pos] == 0xFE) c.take(13);
  }
  // V8's header: 0xFF <version>; versions before 13 had none (or it is the one just read)
  if (!c.done && c.data[c.pos] == 0xFF) {
    c.pos++;
    c.varint();
  }
  return _V8(c).read(0);
}

class _V8 {
  _V8(this.c);
  final _Cursor c;
  final objects = <Object?>[];
  int nodes = 0;

  int _tag() {
    while (true) {
      final t = c.byte();
      if (t != 0) return t; // 0: padding
    }
  }

  Object? read(int depth) {
    if (depth > _maxDepth) throw const FormatException('a value nested too deep');
    if (++nodes > _maxNodes) throw const FormatException('a value too large');
    final t = _tag();
    switch (t) {
      case 0x5F: // '_' undefined
      case 0x30: // '0' null
      case 0x2D: // '-' the hole of an array
        return null;
      case 0x54: // 'T'
        return true;
      case 0x46: // 'F'
        return false;
      case 0x49: // 'I' int32, zigzag
        final z = c.varint();
        return (z >>> 1) ^ -(z & 1);
      case 0x55: // 'U' uint32
        return c.varint();
      case 0x4E: // 'N' double
        return c.float64();
      case 0x5A: // 'Z' BigInt: its digits are skipped, null given
        c.take(_len(c.varint() >> 1));
        return null;
      case 0x22: // '"' one-byte (Latin-1)
        return String.fromCharCodes(c.take(_len(c.varint())));
      case 0x63: // 'c' two-byte (UTF-16LE)
        final n = _len(c.varint());
        if (n.isOdd) throw const FormatException('a bad two-byte string');
        final b = c.take(n);
        return String.fromCharCodes([for (var i = 0; i < n; i += 2) b[i] | (b[i + 1] << 8)]);
      case 0x53: // 'S' UTF-8
        return utf8.decode(c.take(_len(c.varint())), allowMalformed: true);
      case 0x44: // 'D' Date: milliseconds
        return _keep(c.float64());
      case 0x79: // 'y' Boolean object true
        return _keep(true);
      case 0x78: // 'x'
        return _keep(false);
      case 0x6E: // 'n' Number object
        return _keep(c.float64());
      case 0x73: // 's' String object
        final i = _slot();
        return objects[i] = read(depth + 1);
      case 0x5E: // '^' a reference to an earlier object
        final id = c.varint();
        if (id >= objects.length) throw const FormatException('a bad object reference');
        return objects[id];
      case 0x6F: // 'o' object
        final m = <String, Object?>{};
        _keep(m);
        _props(m, 0x7B, depth); // '{'
        c.varint(); // the number of properties
        return m;
      case 0x41: // 'A' dense array
        final n = _len(c.varint());
        final list = <Object?>[];
        _keep(list);
        for (var i = 0; i < n; i++) {
          list.add(read(depth + 1));
        }
        _props(<String, Object?>{}, 0x24, depth); // '$', extra properties dropped
        c.varint();
        c.varint();
        return list;
      case 0x61: // 'a' sparse array
        final n = _len(c.varint());
        final list = <Object?>[];
        _keep(list);
        final props = <String, Object?>{};
        _props(props, 0x40, depth); // '@'
        c.varint();
        c.varint();
        for (var i = 0; i < n && i < _maxNodes; i++) {
          list.add(props['$i']);
        }
        return list;
      case 0x3B: // ';' Map → a Dart map with string keys
        final m = <String, Object?>{};
        _keep(m);
        while (true) {
          if (_peek() == 0x3A) {
            // ':'
            c.byte();
            c.varint();
            return m;
          }
          final k = read(depth + 1);
          m['$k'] = read(depth + 1);
        }
      case 0x27: // '\'' Set → a list
        final list = <Object?>[];
        _keep(list);
        while (true) {
          if (_peek() == 0x2C) {
            // ','
            c.byte();
            c.varint();
            return list;
          }
          list.add(read(depth + 1));
        }
      default:
        throw FormatException('an unsupported value tag 0x${t.toRadixString(16)}');
    }
  }

  int _len(int n) => n > _maxString ? throw const FormatException('a string too long') : n;

  int _slot() {
    objects.add(null);
    return objects.length - 1;
  }

  T _keep<T>(T o) {
    objects.add(o);
    return o;
  }

  int _peek() {
    while (!c.done && c.data[c.pos] == 0) {
      c.pos++;
    }
    if (c.done) throw const FormatException('cut off');
    return c.data[c.pos];
  }

  /// key/value pairs until [end]; the end tag is consumed.
  void _props(Map<String, Object?> into, int end, int depth) {
    while (true) {
      if (_peek() == end) {
        c.byte();
        return;
      }
      final k = read(depth + 1);
      if (k is! String && k is! num) throw const FormatException('a bad property name');
      into[k is double && k == k.truncateToDouble() ? '${k.toInt()}' : '$k'] = read(depth + 1);
    }
  }
}
