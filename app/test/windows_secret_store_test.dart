import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/windows_secret_store.dart';

/// Stands in for DPAPI: a SHA-256 of the plain text, then the text XORed. Like DPAPI's MAC, a
/// truncated or altered blob fails to decrypt.
class FakeCipher implements SecretCipher {
  int protects = 0;

  @override
  Uint8List protect(Uint8List plain) {
    protects++;
    return Uint8List.fromList([
      ...sha256.convert(plain).bytes,
      for (final b in plain) b ^ 0x5a,
    ]);
  }

  @override
  Uint8List unprotect(Uint8List encrypted) {
    if (encrypted.length < 32) throw const OSError('bad data', 13);
    final plain = Uint8List.fromList([
      for (final b in encrypted.skip(32)) b ^ 0x5a,
    ]);
    final mac = sha256.convert(plain).bytes;
    for (var i = 0; i < 32; i++) {
      if (mac[i] != encrypted[i]) throw const OSError('bad data', 13);
    }
    return plain;
  }
}

/// Bytes as flutter_secure_storage_windows 4.2.2 writes the file: protect(utf8(jsonEncode)).
Uint8List pluginFile(SecretCipher cipher, Map<String, Object?> map) =>
    cipher.protect(utf8.encode(jsonEncode(map)));

class Crash implements Exception {
  const Crash(this.at);
  final String at;
  @override
  String toString() => 'Crash at $at';
}

/// An in-memory disk. [crashAt] names a step (`write:<name>`, `written:<name>`,
/// `move:<from>-><to>`, `moved:<from>-><to>`; names without the folder); reaching it throws
/// [Crash] with the disk exactly as a power cut at that point leaves it. A crash during a write
/// leaves the first half of the bytes.
class MemoryFiles implements StoreFiles {
  final Map<String, Uint8List> disk = {};
  String? crashAt;
  final List<String> steps = [];

  static String name(String path) => path.split(Platform.pathSeparator).last;

  void _step(String step) {
    steps.add(step);
    if (step == crashAt) {
      crashAt = null;
      throw Crash(step);
    }
  }

  @override
  Future<Uint8List?> read(String path) async {
    await Future<void>.delayed(Duration.zero);
    return disk[name(path)];
  }

  @override
  Future<void> writeFlushed(String path, Uint8List bytes) async {
    await Future<void>.delayed(Duration.zero);
    final n = name(path);
    if (crashAt == 'write:$n') {
      disk[n] = Uint8List.fromList(bytes.sublist(0, bytes.length ~/ 2));
    }
    _step('write:$n');
    disk[n] = Uint8List.fromList(bytes);
    _step('written:$n');
  }

  @override
  Future<void> replace(String from, String to) async {
    await Future<void>.delayed(Duration.zero);
    final f = name(from), t = name(to);
    _step('move:$f->$t');
    final bytes = disk.remove(f);
    if (bytes == null) throw FileSystemException('missing', from);
    disk[t] = bytes;
    _step('moved:$f->$t');
  }

  @override
  Future<void> delete(String path) async {
    await Future<void>.delayed(Duration.zero);
    disk.remove(name(path));
  }
}

const dat = secretFileName;
const bak = '$secretFileName.bak';
const tmp = '$secretFileName.tmp';

void main() {
  late FakeCipher cipher;
  late MemoryFiles files;

  WindowsSecretStore open() => WindowsSecretStore(
    directory: () async => 'C:${Platform.pathSeparator}support',
    cipher: cipher,
    files: files,
  );

  setUp(() {
    cipher = FakeCipher();
    files = MemoryFiles();
  });

  Map<String, Object?> contents(String file) =>
      jsonDecode(utf8.decode(cipher.unprotect(files.disk[file]!)))
          as Map<String, Object?>;

  test('reads a file in the plugin format', () async {
    files.disk[dat] = pluginFile(cipher, {
      'lepic.vault': 'v1',
      'settings': '{"a":1}',
      'odd': 3,
    });
    final store = open();
    expect(await store.read('lepic.vault'), 'v1');
    expect(await store.read('settings'), '{"a":1}');
    expect(await store.read('odd'), isNull);
    expect(await store.read('missing'), isNull);
  });

  test(
    'a fresh install is an empty store and the first write creates the file',
    () async {
      final store = open();
      expect(await store.read('k'), isNull);
      await store.write('k', 'v');
      expect(files.disk.keys, [dat]);
      expect(contents(dat), {'k': 'v'});
      expect(await open().read('k'), 'v');
    },
  );

  test('a write keeps the previous file as the backup', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    expect(contents(dat), {'a': '1', 'b': '2'});
    expect(contents(bak), {'a': '1'});
    expect(files.disk.containsKey(tmp), isFalse);
    expect(files.steps, [
      'write:$tmp',
      'written:$tmp',
      'move:$tmp->$dat',
      'moved:$tmp->$dat',
      'write:$tmp',
      'written:$tmp',
      'move:$dat->$bak',
      'moved:$dat->$bak',
      'move:$tmp->$dat',
      'moved:$tmp->$dat',
    ]);
  });

  test(
    'delete removes the key; deleting a missing key writes nothing',
    () async {
      final store = open();
      await store.write('a', '1');
      await store.write('b', '2');
      final before = cipher.protects;
      await store.delete('missing');
      expect(cipher.protects, before);
      await store.delete('a');
      expect(contents(dat), {'b': '2'});
      expect(await store.read('a'), isNull);
    },
  );

  group('a crash during a write opens the last complete state', () {
    // Before the crashed write: dat holds {a:1, b:2}, bak holds {a:1}. The crashed write sets c.
    for (final (step, expected) in [
      ('write:$tmp', {'a': '1', 'b': '2'}),
      ('written:$tmp', {'a': '1', 'b': '2'}),
      ('move:$dat->$bak', {'a': '1', 'b': '2'}),
      ('moved:$dat->$bak', {'a': '1', 'b': '2'}),
      ('move:$tmp->$dat', {'a': '1', 'b': '2'}),
      ('moved:$tmp->$dat', {'a': '1', 'b': '2', 'c': '3'}),
    ]) {
      test(step, () async {
        final store = open();
        await store.write('a', '1');
        await store.write('b', '2');
        files.crashAt = step;
        await expectLater(store.write('c', '3'), throwsA(isA<Crash>()));

        // The app starts again.
        final again = open();
        for (final key in ['a', 'b', 'c']) {
          expect(await again.read(key), expected[key], reason: key);
        }
        // A leftover temporary file is cleaned.
        expect(files.disk.containsKey(tmp), isFalse);

        // The next write works from there and leaves a good file and backup.
        await again.write('d', '4');
        expect(contents(dat), {...expected, 'd': '4'});
        expect(contents(bak), expected);
        expect(await open().read('d'), '4');
      });
    }
  });

  test(
    'a crash between the two moves, then another crash, still opens',
    () async {
      final store = open();
      await store.write('a', '1');
      await store.write('b', '2');
      files.crashAt = 'moved:$dat->$bak';
      await expectLater(store.write('c', '3'), throwsA(isA<Crash>()));
      expect(files.disk.containsKey(dat), isFalse);

      // Restarted, it opens the backup; its first write crashes after the temporary file.
      final again = open();
      files.crashAt = 'written:$tmp';
      await expectLater(again.write('d', '4'), throwsA(isA<Crash>()));
      expect(await open().read('b'), '2');
      expect(await open().read('d'), isNull);
    },
  );

  test('the very first write stopped before its move is kept, not dropped', () async {
    final store = open();
    files.crashAt = 'move:$tmp->$dat';
    await expectLater(store.write('lepic.vault', 'v'), throwsA(isA<Crash>()));
    expect(files.disk.containsKey(dat), isFalse);

    // The app starts again: the complete first write becomes the store file.
    final again = open();
    expect(await again.read('lepic.vault'), 'v');
    expect(files.disk.containsKey(dat), isTrue);
    expect(files.disk.containsKey(tmp), isFalse);
  });

  test('a first write that stopped while writing leaves an empty store', () async {
    final store = open();
    files.crashAt = 'write:$tmp';
    await expectLater(store.write('a', '1'), throwsA(isA<Crash>()));
    final again = open();
    expect(await again.read('a'), isNull);
    expect(files.disk.containsKey(tmp), isFalse);
  });

  test('a truncated store file opens the backup', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    files.disk[dat] = files.disk[dat]!.sublist(0, 40);
    expect(await open().read('a'), '1');
    expect(await open().read('b'), isNull);
    expect(files.disk.containsKey(dat), isTrue, reason: 'never deleted');
  });

  test('an empty store file opens the backup', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    files.disk[dat] = Uint8List(0);
    expect(await open().read('a'), '1');
  });

  test('a store file that fails to decrypt opens the backup; the next write sets it aside', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    final damaged = Uint8List.fromList(files.disk[dat]!)..[40] ^= 0xff;
    files.disk[dat] = damaged;

    final again = open();
    expect(await again.read('a'), '1');
    await again.write('c', '3');
    expect(contents(dat), {'a': '1', 'c': '3'});
    expect(contents(bak), {
      'a': '1',
    }, reason: 'the damaged file never becomes the backup');
    expect(files.disk['$secretFileName.damaged'], damaged);
  });

  test('a store file that decrypts to something other than a JSON object opens the backup', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    files.disk[dat] = cipher.protect(utf8.encode('[1, 2]'));
    expect(await open().read('a'), '1');
    files.disk[dat] = cipher.protect(utf8.encode('{"a": '));
    expect(await open().read('a'), '1');
  });

  test('both files damaged is an error, never an empty store, and nothing is touched', () async {
    final store = open();
    await store.write('a', '1');
    await store.write('b', '2');
    files.disk[dat] = files.disk[dat]!.sublist(0, 10);
    files.disk[bak] = Uint8List(0);
    final before = Map.of(files.disk);

    final again = open();
    await expectLater(again.read('a'), throwsA(isA<SecretStoreDamaged>()));
    await expectLater(
      again.write('x', 'y'),
      throwsA(isA<SecretStoreDamaged>()),
    );
    await expectLater(again.delete('a'), throwsA(isA<SecretStoreDamaged>()));
    expect(files.disk, before);
  });

  test('a damaged store file with no backup is an error', () async {
    files.disk[dat] = Uint8List.fromList([1, 2, 3]);
    await expectLater(open().read('a'), throwsA(isA<SecretStoreDamaged>()));
    expect(files.disk[dat], [1, 2, 3]);
  });

  test('a missing store file with a damaged backup is an error', () async {
    files.disk[bak] = Uint8List.fromList([1, 2, 3]);
    await expectLater(open().read('a'), throwsA(isA<SecretStoreDamaged>()));
  });

  test('the error says what failed without the contents', () async {
    files.disk[dat] = cipher.protect(utf8.encode('not json secret-word'));
    try {
      await open().read('a');
      fail('read a damaged store');
    } on SecretStoreDamaged catch (e) {
      expect(e.message, contains('not JSON'));
      expect(e.message, isNot(contains('secret-word')));
    }
  });

  test('concurrent writes and deletes all land', () async {
    final store = open();
    await Future.wait([
      for (var i = 0; i < 40; i++) store.write('k$i', 'v$i'),
      store.delete('k0'),
    ]);
    final map = contents(dat);
    expect(map.length, 39);
    expect(map['k0'], isNull);
    expect(map['k39'], 'v39');
  });

  test('a failed write does not block the next one', () async {
    final store = open();
    await store.write('a', '1');
    files.crashAt = 'write:$tmp';
    final failed = store.write('b', '2');
    final next = store.write('c', '3');
    await expectLater(failed, throwsA(isA<Crash>()));
    await next;
    expect(contents(dat), {'a': '1', 'c': '3'});
  });

  group('on the real file system', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('wss');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    WindowsSecretStore real() => WindowsSecretStore(
      directory: () async => '${dir.path}${Platform.pathSeparator}support',
      cipher: cipher,
    );

    File file(String n) => File(
      '${dir.path}${Platform.pathSeparator}support${Platform.pathSeparator}$n',
    );

    test(
      'reads a plugin file, writes, keeps a backup, ignores a leftover',
      () async {
        file(dat)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(pluginFile(cipher, {'lepic.vault': 'v1'}));
        file(tmp).writeAsBytesSync([9, 9, 9]);

        final store = real();
        expect(await store.read('lepic.vault'), 'v1');
        expect(file(tmp).existsSync(), isFalse);
        await store.write('lepic.vault-next', 'v2');
        expect(await real().read('lepic.vault-next'), 'v2');
        expect(
          jsonDecode(
            utf8.decode(cipher.unprotect(file(bak).readAsBytesSync())),
          ),
          {'lepic.vault': 'v1'},
        );
        file(dat).writeAsBytesSync([1]);
        expect(await real().read('lepic.vault'), 'v1');
        expect(await real().read('lepic.vault-next'), isNull);
      },
    );

    test('a fresh folder is created on the first write', () async {
      final store = real();
      expect(await store.read('a'), isNull);
      await store.write('a', '1');
      expect(file(dat).existsSync(), isTrue);
    });
  });
}
