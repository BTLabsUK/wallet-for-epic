// SPDX-License-Identifier: Apache-2.0
/// `settings.toml` in a folder: atomic writes (`settings.toml.tmp`, then a rename), an
/// exclusive lock on `settings.toml.lock` around every read-merge-write, and a watcher on the
/// folder (editors save by writing a new file and renaming it over the old one).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'settings_backend.dart';

class FileSettingsBackend implements SettingsBackend {
  FileSettingsBackend(this.folder, {this.lockWait = const Duration(seconds: 10)});

  final Directory folder;

  /// How long a write waits for another process's lock before it gives up.
  final Duration lockWait;

  File get file => File(_path(settingsFileName));
  String _path(String name) => '${folder.path}${Platform.pathSeparator}$name';

  @override
  String get fileName => settingsFileName;

  @override
  bool get writesShippedFirst => true;

  @override
  Future<String?> read() async {
    try {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      // Notepad's "UTF-8 with BOM".
      return text.startsWith('\uFEFF') ? text.substring(1) : text;
    } on PathNotFoundException {
      return null;
    }
  }

  @override
  Future<void> write(String text) async {
    await folder.create(recursive: true);
    final tmp = File(_path('$settingsFileName.tmp'));
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<T> locked<T>(Future<T> Function() body) {
    final lockPath = _path('$settingsFileName.lock');
    return runQueued('file:${File(lockPath).absolute.path}', () async {
      await folder.create(recursive: true);
      final raf = await File(lockPath).open(mode: FileMode.append);
      try {
        final deadline = DateTime.now().add(lockWait);
        while (true) {
          try {
            await raf.lock(FileLock.exclusive);
            break;
          } on FileSystemException {
            if (DateTime.now().isAfter(deadline)) throw SettingsLockTimeout(lockPath);
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        }
        try {
          return await body();
        } finally {
          await raf.unlock();
        }
      } finally {
        await raf.close();
      }
    });
  }

  @override
  Future<String> saveBroken(String text, DateTime at) async {
    final base = brokenName(settingsFileName, at);
    var name = base;
    for (var n = 2; await File(_path(name)).exists(); n++) {
      name = '$base-$n';
    }
    await File(_path(name)).writeAsString(text, flush: true);
    return name;
  }

  @override
  Stream<void>? changes() {
    if (!FileSystemEntity.isWatchSupported) return null;
    bool ours(String path) => path.split(RegExp(r'[\\/]')).last == settingsFileName;
    return folder
        .watch()
        .where((e) => ours(e.path) || (e is FileSystemMoveEvent && e.destination != null && ours(e.destination!)))
        .map((_) {});
  }
}
