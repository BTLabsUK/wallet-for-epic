// SPDX-License-Identifier: Apache-2.0
/// Where a wallet's [DirectoryBook] is kept: one JSON value in the app's [SecretStore], keyed by
/// chain and wallet like the linked devices (`devices/device_store.dart`). Not in the wallet's
/// history: deleting history must not drop a membership.
library;

import 'dart:convert';

import '../log.dart';
import '../models.dart' show Chain;
import '../secret_store_api.dart';
import 'directory_model.dart';

class DirectoryStore {
  DirectoryStore(this._store, {required Chain chain, String? walletId}) : key = keyFor(chain, walletId);

  final SecretStore _store;
  final String key;

  static String keyFor(Chain chain, String? walletId) => 'directory.${chain.name}.${walletId ?? 'legacy'}';

  /// The store could not be read: what [load] returned is a stand-in, and [save] leaves the
  /// stored book alone rather than overwrite memberships it could not see.
  bool _unreadable = false;

  Future<DirectoryBook> load() async {
    final String? raw;
    try {
      raw = await _store.read(key);
    } catch (e) {
      logWarn('directory', 'directories not readable: ${e.runtimeType}');
      _unreadable = true;
      return const DirectoryBook();
    }
    _unreadable = false;
    if (raw != null) {
      try {
        final book = DirectoryBook.fromJson(jsonDecode(raw));
        if (book != null) return book;
      } on FormatException {
        // Falls through to a fresh book.
      }
      logWarn('directory', 'stored directories did not read; starting fresh');
    }
    return const DirectoryBook();
  }

  Future<void> save(DirectoryBook book) async {
    if (_unreadable) return;
    await _store.write(key, jsonEncode(book.toJson()));
  }

  /// Forgets everything (the wallet was deleted).
  Future<void> clear() => _store.delete(key);
}
