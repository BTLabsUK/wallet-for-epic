// SPDX-License-Identifier: Apache-2.0
/// Where a wallet's [DeviceBook] is kept: one JSON value in the app's [SecretStore], keyed by
/// chain and wallet like the other per-wallet app data (`phone.tor_receiving.<chain>.<wallet>`).
library;

import 'dart:convert';

import '../log.dart';
import '../models.dart' show Chain;
import '../secret_store_api.dart';
import 'device_model.dart';

class DeviceStore {
  DeviceStore(this._store, {required Chain chain, String? walletId}) : key = keyFor(chain, walletId);

  final SecretStore _store;
  final String key;

  static String keyFor(Chain chain, String? walletId) => 'devices.${chain.name}.${walletId ?? 'legacy'}';

  /// The store could not be read: what [load] returned is a stand-in, and [save] leaves the
  /// stored book alone rather than overwrite links it could not see.
  bool _unreadable = false;

  /// The stored book, or a fresh one named [defaultName] (a new device id) when there is none
  /// or it does not read.
  Future<DeviceBook> load({required String defaultName}) async {
    final String? raw;
    try {
      raw = await _store.read(key);
    } catch (e) {
      // A keyring that is locked or missing: no linked devices this run, nothing lost.
      logWarn('devices', 'linked devices not readable: ${e.runtimeType}');
      _unreadable = true;
      return DeviceBook.fresh(defaultName);
    }
    _unreadable = false;
    if (raw != null) {
      try {
        final book = DeviceBook.fromJson(jsonDecode(raw));
        if (book != null) return book;
      } on FormatException {
        // Falls through to a fresh book.
      }
      logWarn('devices', 'stored linked devices did not read; starting fresh');
    }
    return DeviceBook.fresh(defaultName);
  }

  Future<void> save(DeviceBook book) async {
    if (_unreadable) return;
    await _store.write(key, jsonEncode(book.toJson()));
  }

  /// Forgets everything (the wallet was deleted).
  Future<void> clear() => _store.delete(key);
}
