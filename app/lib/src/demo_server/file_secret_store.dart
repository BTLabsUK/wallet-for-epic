/// One demo's secret store: a JSON file, mode 600, replaced atomically on every write.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../secret_store.dart' show SecretStore;
import 'demo_store.dart' show writeAtomic;

/// Holds what LEPIC stores through the app's `SecretStore` (its PIN vault). The values are
/// already sealed by LEPIC; this file only keeps them across restarts of the server.
class FileSecretStore implements SecretStore {
  FileSecretStore(this.path);

  final String path;
  Map<String, String>? _values;
  Future<void> _last = Future.value();

  Future<Map<String, String>> _load() async {
    final cached = _values;
    if (cached != null) return cached;
    final file = File(path);
    final values = <String, String>{};
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) {
        throw FileSystemException('not a secret store', path);
      }
      for (final e in json.entries) {
        if (e.value is String) values[e.key] = e.value as String;
      }
    }
    return _values = values;
  }

  /// Runs [change] after every earlier write, so two writes never interleave.
  Future<void> _serial(Future<void> Function() change) {
    final next = _last.then((_) => change());
    _last = next.catchError((Object _) {});
    return next;
  }

  @override
  Future<String?> read(String key) async {
    await _last;
    return (await _load())[key];
  }

  @override
  Future<void> write(String key, String value) => _serial(() async {
    final values = await _load();
    values[key] = value;
    await writeAtomic(path, jsonEncode(values), mode: '600');
  });

  @override
  Future<void> delete(String key) => _serial(() async {
    final values = await _load();
    if (values.remove(key) == null) return;
    await writeAtomic(path, jsonEncode(values), mode: '600');
  });
}
