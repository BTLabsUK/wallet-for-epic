/// The web app's [SecretStore]: the browser's `localStorage` for this origin.
///
/// The browser has no keystore. On the web the wallet lives on the demo server, and the only
/// secret here is the PIN-sealed text of that server's wallet, which opens nothing without the
/// PIN and the server. Keys get a `wfe.` prefix so nothing else on the origin collides.
library;

import 'dart:js_interop';

import 'secret_store_api.dart';

class BrowserSecretStore implements SecretStore {
  const BrowserSecretStore();

  static const String prefix = 'wfe.';

  @override
  Future<String?> read(String key) async =>
      _localStorage.getItem('$prefix$key');

  @override
  Future<void> write(String key, String value) async =>
      _localStorage.setItem('$prefix$key', value);

  @override
  Future<void> delete(String key) async =>
      _localStorage.removeItem('$prefix$key');
}

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}
