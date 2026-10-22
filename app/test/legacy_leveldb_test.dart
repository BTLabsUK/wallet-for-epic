import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:epic_wallet/src/legacy/indexeddb.dart';
import 'package:epic_wallet/src/legacy/leveldb.dart';
import 'package:epic_wallet/src/legacy/snappy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The LevelDB, IndexedDB and Snappy readers on the files real Chromium wrote
/// (test/fixtures/legacy_gui/idb, tool/legacy_gui_fixtures.py) and on damaged copies of them.
void main() {
  const idb = 'test/fixtures/legacy_gui/idb';
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('legacy_leveldb_'));
  tearDown(() => tmp.delete(recursive: true));

  Future<String> copy(String fixture) async {
    final from = Directory('$idb/$fixture/app_._0.indexeddb.leveldb');
    final to = Directory('${tmp.path}/$fixture');
    await to.create();
    await for (final f in from.list()) {
      if (f is File) await f.copy('${to.path}/${f.uri.pathSegments.last}');
    }
    return to.path;
  }

  Future<IdbRead> read(String dir) => readIdbStores(dir, 'Epicwallet', {'User', 'Addressbook', 'AddressTransactions'});

  List<Object?> field(IdbRead r, String store, String f) => [for (final x in r.stores[store]!) (x.value as Map)[f]];

  test('the log only: live rows, the deleted one gone, the updated one new, keys injected from the record key', () async {
    final r = await read('$idb/gui616_log/app_._0.indexeddb.leveldb');
    expect(r.found, isTrue);
    expect(r.notes, isEmpty);
    expect(field(r, 'User', 'account'), ['w1', 'w2']);
    expect(field(r, 'User', 'name'), ['Główny portfel 💰', 'Тестовый']);
    expect(field(r, 'User', 'nodeInternal'), [false, true]);
    expect([for (final x in r.stores['User']!) x.key], [1.0, 2.0]);
    expect(field(r, 'Addressbook', 'name'), ['Alice', 'Zoë 李雷', 'Alice', 'Carol', 'Dave']);
    expect(field(r, 'Addressbook', 'notice')[3], 'updated note');
    expect(field(r, 'Addressbook', 'user_id'), [1, 1, 1, 1, 2]);
  });

  test('values: doubles, large numbers, arrays, null and undefined', () async {
    final r = await read('$idb/gui616_log/app_._0.indexeddb.leveldb');
    final t = r.stores['AddressTransactions']!.single.value as Map;
    expect(t['amount'], 1.5);
    expect(t['big'], pow(2, 40));
    expect(t['tags'], ['a', 2, null, true]);
    expect(t.containsKey('gone'), isTrue);
    expect(t['gone'], isNull);
  });

  test('a Snappy-compressed table and a log over it', () async {
    final dir = '$idb/gui531_table/app_._0.indexeddb.leveldb';
    expect(Directory(dir).listSync().any((f) => f.path.endsWith('.ldb')), isTrue);
    final r = await read(dir);
    expect(r.notes, isEmpty);
    expect(field(r, 'User', 'account'), ['default', 'alpha']);
    expect(field(r, 'Addressbook', 'name'), ['Eve', 'Frank', 'Shared', 'Carol', 'Heidi']);
    expect(field(r, 'Addressbook', 'notice')[1], 'changed after compaction');
    expect(field(r, 'Addressbook', 'city')[0], 'München');
    // the filler database was deleted and compacted away; the leftover store is empty
    expect(r.stores['AddressTransactions']!.length, 1);
  });

  test('another database name is not found', () async {
    final r = await readIdbStores('$idb/gui616_log/app_._0.indexeddb.leveldb', 'Other', {'User'});
    expect(r.found, isFalse);
    expect(r.stores, isEmpty);
  });

  test('a cut-off log: the records before the cut, a note', () async {
    final dir = await copy('gui616_log');
    final log = File('$dir/000003.log');
    final bytes = await log.readAsBytes();
    await log.writeAsBytes(bytes.sublist(0, bytes.length * 2 ~/ 3));
    final r = await read(dir);
    expect(r.notes.join(), contains('cut off'));
    expect(field(r, 'User', 'account'), ['w1', 'w2']);
  });

  test('a damaged log record: what came before it, a note', () async {
    final dir = await copy('gui616_log');
    final log = File('$dir/000003.log');
    final bytes = await log.readAsBytes();
    bytes[bytes.length - 40] ^= 0x55;
    await log.writeAsBytes(bytes);
    final r = await read(dir);
    expect(r.notes.join(), contains('damaged record'));
    expect(r.found, isTrue);
  });

  test('a missing or broken MANIFEST: every file is read, with a note', () async {
    final dir = await copy('gui531_table');
    await File('$dir/CURRENT').writeAsString('MANIFEST-999999\n');
    final r = await read(dir);
    expect(r.notes.join(), contains('MANIFEST'));
    expect(field(r, 'Addressbook', 'name'), ['Eve', 'Frank', 'Shared', 'Carol', 'Heidi']);
  });

  test('a truncated table: a note, no throw', () async {
    final dir = await copy('gui531_table');
    final t = File('$dir/000005.ldb');
    final bytes = await t.readAsBytes();
    await t.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
    final r = await read(dir);
    expect(r.notes.join(), contains('000005.ldb'));
    // the table held the database's own entries, so it is not found from the log alone
    expect(r.found, isFalse);
  });

  test('random damage never throws or hangs', () async {
    final rnd = Random(7);
    for (final fixture in ['gui616_log', 'gui531_table']) {
      for (var i = 0; i < 25; i++) {
        final dir = await copy(fixture);
        for (final f in Directory(dir).listSync().whereType<File>()) {
          final b = await f.readAsBytes();
          if (b.isEmpty) continue;
          for (var k = 0; k < 1 + rnd.nextInt(8); k++) {
            b[rnd.nextInt(b.length)] = rnd.nextInt(256);
          }
          await f.writeAsBytes(rnd.nextBool() ? b : b.sublist(0, rnd.nextInt(b.length)));
        }
        await read(dir); // no throw
        await Directory(dir).delete(recursive: true);
      }
    }
  });

  test('not a leveldb folder at all', () async {
    final r = await read('${tmp.path}/missing');
    expect(r.found, isFalse);
    expect(r.notes, isNotEmpty);
    final empty = await readLevelDb(tmp.path);
    expect(empty.entries, isEmpty);
  });

  test('limits: too many keys, too large files', () async {
    final few = await readLevelDb('$idb/gui616_log/app_._0.indexeddb.leveldb', limits: const LevelDbLimits(maxEntries: 10));
    expect(few.entries.length, 10);
    expect(few.notes.join(), contains('more than 10 keys'));
    final small = await readLevelDb('$idb/gui616_log/app_._0.indexeddb.leveldb', limits: const LevelDbLimits(maxFileBytes: 100));
    expect(small.notes.join(), contains('larger than'));
  });

  group('snappy', () {
    test('literals and copies, overlapping runs included', () {
      // "abcabcabcabcX": literal "abc", copy offset 3 len 9 (1-byte offset form), literal "X"
      final data = Uint8List.fromList([13, 0x08, 0x61, 0x62, 0x63, ((9 - 4) << 2) | 1, 3, 0x00, 0x58]);
      expect(String.fromCharCodes(snappyDecompress(data)), 'abcabcabcabcX');
      // a 2-byte-offset copy
      final two = Uint8List.fromList([6, 0x08, 0x61, 0x62, 0x63, ((3 - 1) << 2) | 2, 3, 0]);
      expect(String.fromCharCodes(snappyDecompress(two)), 'abcabc');
    });

    test('bad input throws a FormatException, never reads out of bounds', () {
      expect(() => snappyDecompress(Uint8List.fromList([5, 0x08, 0x61])), throwsFormatException);
      expect(() => snappyDecompress(Uint8List.fromList([4, 0x01, 9])), throwsFormatException); // copy before any data
      expect(() => snappyDecompress(Uint8List.fromList([0xff, 0xff, 0xff, 0xff, 0x7f])), throwsFormatException);
      expect(() => snappyDecompress(Uint8List.fromList([3, 0x08, 0x61, 0x62, 0x63, 0x05, 1])), throwsFormatException);
    });
  });

  group('V8 values', () {
    Uint8List v8(List<int> body) => Uint8List.fromList([0xff, 0x0f, ...body]);

    test('the old envelope (no Blink trailer) and every primitive', () {
      expect(decodeIdbValue(v8([0x49, 0x05])), -3);
      expect(decodeIdbValue(v8([0x55, 0x80, 0x01])), 128);
      expect(decodeIdbValue(v8([0x54])), true);
      expect(decodeIdbValue(v8([0x30])), null);
      expect(decodeIdbValue(v8([0x53, 0x03, 0xe2, 0x9c, 0x93])), '✓');
      expect(decodeIdbValue(v8([0x6f, 0x22, 0x01, 0x61, 0x49, 0x02, 0x7b, 0x01])), {'a': 1});
      // a dense array of two, the second a reference to the array itself
      final a = decodeIdbValue(v8([0x41, 0x02, 0x49, 0x02, 0x5e, 0x00, 0x24, 0x00, 0x02])) as List;
      expect(a.length, 2);
      expect(identical(a[1], a), isTrue);
    });

    test("older Electrons' envelopes: Blink 20 without a trailer, Blink 21 with one", () {
      final body = [0xff, 0x0d, 0x6f, 0x22, 0x01, 0x61, 0x22, 0x01, 0x62, 0x7b, 0x01];
      expect(decodeIdbValue(Uint8List.fromList([0xff, 0x14, ...body])), {'a': 'b'});
      expect(decodeIdbValue(Uint8List.fromList([0xff, 0x15, 0xfe, ...List.filled(12, 0), ...body])), {'a': 'b'});
    });

    test('nesting and unknown tags are refused', () {
      expect(() => decodeIdbValue(v8([for (var i = 0; i < 100; i++) 0x41, 0x01])), throwsFormatException);
      expect(() => decodeIdbValue(v8([0x7e])), throwsFormatException);
      expect(() => decodeIdbValue(v8([0x22, 0x10, 0x61])), throwsFormatException);
    });
  });
}
