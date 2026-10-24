/// Key-value storage for secrets, as the wallet core sees it, and an in-memory store for tests
/// and the demo server. Nothing here imports Flutter; the platform stores are in
/// `secret_store.dart`.
library;

abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// The platform refused to protect a secret before it was stored (on Windows, DPAPI); nothing
/// was written. [code] names the failure, never the content.
class SecretProtectError implements Exception {
  const SecretProtectError(this.code);

  final String code;

  @override
  String toString() => 'SecretProtectError: $code';
}

class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
