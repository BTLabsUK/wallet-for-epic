/// The secret store on Windows: the file `flutter_secure_storage.dat` that
/// flutter_secure_storage_windows 4.2.2 writes (one DPAPI-encrypted JSON object of every key, in
/// the app support folder), read in the same format and written crash-safe.
///
/// The plugin rewrites that file in place (truncate, then write) on every write, and deletes it
/// when it fails to decrypt or parse; either can lose every wallet's vault. This store writes a
/// temporary file, flushes it and moves it over the old one, keeps the last good file as `.bak`,
/// opens the `.bak` when the main file is damaged, and never deletes or empties a damaged file.
///
/// One write, with D the main file, B the backup, T the temporary file:
///  1. read D (or B when D is missing or damaged) and apply the change;
///  2. write T and flush it;
///  3. when D was read and is good: move D over B; when D is damaged: move it aside to
///     `.damaged`; when D is missing: nothing;
///  4. move T over D.
/// Each move is atomic and written through (MoveFileEx on Windows). A crash leaves one of:
///  - during or after 2: D old (good), B older, T partial or complete → D opens, T is ignored;
///  - after 3: no D, B old, T new → B opens (the write never returned, so the old state is right);
///  - after 4: D new, B old → D opens.
/// The next write after a crash starts from what opened, so B only ever holds a file that read.
///
/// Pure Dart: the file system and DPAPI come in through [StoreFiles] and [SecretCipher], so tests
/// inject crashes and a fake cipher on any platform. `windows_dpapi.dart` has the real ones.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'log.dart';
import 'secret_store_api.dart';

/// The plugin's file name (flutter_secure_storage_windows `encryptedJsonFileName`).
const String secretFileName = 'flutter_secure_storage.dat';

/// Encrypts and decrypts the file's bytes. On Windows, DPAPI for the current user with no
/// entropy and no flags, as the plugin calls it. [unprotect] throws when the bytes are not a
/// valid blob (truncated, altered, another user's).
abstract interface class SecretCipher {
  Uint8List protect(Uint8List plain);

  Uint8List unprotect(Uint8List encrypted);
}

/// The few file operations the store needs.
abstract interface class StoreFiles {
  /// The file's bytes, or null when it does not exist.
  Future<Uint8List?> read(String path);

  /// Creates or truncates [path], writes [bytes] and flushes them to the disk before returning.
  /// Creates the parent folder when it is missing.
  Future<void> writeFlushed(String path, Uint8List bytes);

  /// Moves [from] over [to] in one atomic step, replacing [to], durable when it returns.
  Future<void> replace(String from, String to);

  /// Deletes [path]; nothing when it does not exist.
  Future<void> delete(String path);
}

/// Neither the store file nor its backup could be read. Nothing was changed on disk; the files
/// stay for a later attempt or a support report.
class SecretStoreDamaged implements Exception {
  const SecretStoreDamaged(this.message);

  final String message;

  @override
  String toString() => 'SecretStoreDamaged: $message';
}

/// [StoreFiles] on dart:io. [replace] is a rename, atomic on POSIX file systems; on Windows
/// `windows_dpapi.dart` overrides it with MoveFileEx write-through.
class IoStoreFiles implements StoreFiles {
  const IoStoreFiles();

  @override
  Future<Uint8List?> read(String path) async {
    try {
      return await File(path).readAsBytes();
    } on PathNotFoundException {
      return null;
    }
  }

  @override
  Future<void> writeFlushed(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      // FlushFileBuffers on Windows, fsync elsewhere.
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> replace(String from, String to) async {
    await File(from).rename(to);
  }

  @override
  Future<void> delete(String path) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }
}

/// Where a load found the keys.
enum _Source { main, backup, none }

class WindowsSecretStore implements SecretStore {
  WindowsSecretStore({
    required this._directory,
    required this._cipher,
    this._files = const IoStoreFiles(),
  });

  final Future<String> Function() _directory;
  final SecretCipher _cipher;
  final StoreFiles _files;

  // Every operation runs alone: a write's read-modify-write must not interleave with another.
  Future<void> _last = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final next = _last.then((_) => action());
    _last = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<String> _path(String suffix) async {
    final dir = await _directory();
    return '$dir${Platform.pathSeparator}$secretFileName$suffix';
  }

  @override
  Future<String?> read(String key) => _locked(() async {
    final (map, _) = await _load();
    return map[key];
  });

  @override
  Future<void> write(String key, String value) => _locked(() async {
    final (map, source) = await _load();
    map[key] = value;
    await _save(map, source);
  });

  @override
  Future<void> delete(String key) => _locked(() async {
    final (map, source) = await _load();
    if (map.remove(key) == null) return;
    await _save(map, source);
  });

  /// The keys, from the main file or else the backup. Throws [SecretStoreDamaged] when a file
  /// exists but none reads: a damaged store must never look like an empty one.
  Future<(Map<String, String>, _Source)> _load() async {
    final mainPath = await _path('');
    final backupPath = await _path('.bak');
    final tmpPath = await _path('.tmp');

    final main = await _files.read(mainPath);
    String? mainProblem;
    if (main != null) {
      final decoded = _decode(main);
      if (decoded.$1 != null) {
        await _dropTmp(tmpPath);
        return (decoded.$1!, _Source.main);
      }
      mainProblem = decoded.$2;
    }

    final backup = await _files.read(backupPath);
    if (backup == null) {
      if (mainProblem != null) {
        logWarn('secrets', 'store file unreadable ($mainProblem), no backup');
        throw SecretStoreDamaged(
          'store file unreadable ($mainProblem), no backup',
        );
      }
      // A fresh install, or a first write that never finished.
      await _dropTmp(tmpPath);
      return (<String, String>{}, _Source.none);
    }
    final decoded = _decode(backup);
    if (decoded.$1 == null) {
      final what = mainProblem == null
          ? 'store file missing'
          : 'store file unreadable ($mainProblem)';
      logWarn('secrets', '$what, backup unreadable (${decoded.$2})');
      throw SecretStoreDamaged('$what, backup unreadable (${decoded.$2})');
    }
    logWarn(
      'secrets',
      mainProblem == null
          ? 'store file missing, opened the backup'
          : 'store file unreadable ($mainProblem), opened the backup',
    );
    await _dropTmp(tmpPath);
    return (decoded.$1!, _Source.backup);
  }

  /// The map in [bytes], or null and why not. The reason names the failure, never content.
  (Map<String, String>?, String) _decode(Uint8List bytes) {
    if (bytes.isEmpty) return (null, 'empty');
    final String text;
    try {
      text = utf8.decode(_cipher.unprotect(bytes));
    } on FormatException {
      return (null, 'not text after decrypting');
    } catch (error) {
      return (null, 'decrypt failed: ${error.runtimeType}');
    }
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return (null, 'not JSON');
    }
    if (json is! Map) return (null, 'not a JSON object');
    // As the plugin reads it: string keys with string values, anything else skipped.
    return (
      {
        for (final e in json.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      },
      '',
    );
  }

  Future<void> _dropTmp(String tmpPath) async {
    try {
      await _files.delete(tmpPath);
    } catch (error) {
      // A leftover is overwritten by the next write; reading must not fail over it.
      logWarn(
        'secrets',
        'leftover temporary file not removed: ${error.runtimeType}',
      );
    }
  }

  Future<void> _save(Map<String, String> map, _Source source) async {
    final mainPath = await _path('');
    final tmpPath = await _path('.tmp');
    final encrypted = _cipher.protect(utf8.encode(jsonEncode(map)));
    await _files.writeFlushed(tmpPath, encrypted);
    switch (source) {
      case _Source.main:
        await _files.replace(mainPath, await _path('.bak'));
      case _Source.backup:
        // The main file is missing or damaged; a damaged one is set aside, never made the backup.
        if (await _files.read(mainPath) != null) {
          await _files.replace(mainPath, await _path('.damaged'));
        }
      case _Source.none:
        break;
    }
    await _files.replace(tmpPath, mainPath);
  }
}
