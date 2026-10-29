// SPDX-License-Identifier: Apache-2.0
/// Where the settings text lives: a file in the data folder (`settings_backend_io.dart`) or,
/// on the web, a key in the app's store ([StoreSettingsBackend]). Nothing here imports
/// `dart:io`.
library;

import 'dart:async';

import '../secret_store_api.dart';

/// The name of the settings file, in every data folder.
const String settingsFileName = 'settings.toml';

/// The lock was not free in time (another process holds it); nothing was written.
class SettingsLockTimeout implements Exception {
  const SettingsLockTimeout(this.name);
  final String name;
  @override
  String toString() => 'SettingsLockTimeout: $name';
}

abstract class SettingsBackend {
  /// The file's name, as notices name it.
  String get fileName;

  /// Whether the first start writes the shipped text (a file) or leaves it unstored until the
  /// app changes something (the web's store: shipped changes then reach it).
  bool get writesShippedFirst;

  /// The text, or null when there is none. Throws on a read error.
  Future<String?> read();

  /// Replaces the text all at once (a temporary file and a rename for a file).
  Future<void> write(String text);

  /// Runs [body] holding the lock every writer of this text takes (other processes too).
  Future<T> locked<T>(Future<T> Function() body);

  /// Saves a broken [text] beside the file and returns the name it got.
  Future<String> saveBroken(String text, DateTime at);

  /// Fires when the text may have changed outside this app (a file watcher); null without one.
  Stream<void>? changes();
}

/// Runs [body] after every earlier body queued under the same [key] in this process. A file
/// lock does not keep two holders in one process apart, so the backends queue first.
Future<T> runQueued<T>(String key, Future<T> Function() body) {
  final previous = _queues[key] ?? Future<void>.value();
  final done = Completer<void>();
  _queues[key] = done.future;
  return previous.then((_) => body()).whenComplete(() {
    done.complete();
    if (identical(_queues[key], done.future)) _queues.remove(key);
  });
}

final Map<String, Future<void>> _queues = {};

/// `settings.toml.bad-<yyyyMMdd-HHmmss>` for a broken file saved at [at].
String brokenName(String fileName, DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '$fileName.bad-${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}${two(at.second)}';
}

/// The settings text as one key of the app's store: the web, where there is no file, and tests.
class StoreSettingsBackend implements SettingsBackend {
  StoreSettingsBackend(this.store, {this.key = 'app.settingsToml', this.writesShippedFirst = false});

  final SecretStore store;
  final String key;

  @override
  final bool writesShippedFirst;

  @override
  String get fileName => settingsFileName;

  @override
  Future<String?> read() => store.read(key);

  @override
  Future<void> write(String text) => store.write(key, text);

  @override
  Future<T> locked<T>(Future<T> Function() body) => runQueued('store:$key:${identityHashCode(store)}', body);

  @override
  Future<String> saveBroken(String text, DateTime at) async {
    final name = brokenName(fileName, at);
    await store.write('$key.${name.substring(fileName.length + 1)}', text);
    return name;
  }

  @override
  Stream<void>? changes() => null;
}
