/// The platform's secret storage, and a biometric-gated variant. The [SecretStore] interface
/// and [MemorySecretStore] are in `secret_store_api.dart`, without Flutter, and re-exported here.
///
/// [PlatformSecretStore] is the platform keystore: Android Keystore, iOS Keychain (this device
/// only), libsecret on Linux. [PlatformBiometricStore] adds a Keystore/Keychain key that only a
/// fresh biometric check unlocks, so the biometric copy of a secret is bound to the fingerprint or
/// face, not just gated by a dialog. Tests use the in-memory versions.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'app_log.dart';
import 'secret_store_api.dart';

export 'secret_store_api.dart';

/// Biometric storage. [read] and [write] show the system prompt and throw
/// [BiometricCancelled] when the user dismisses it or the check fails.
abstract interface class BiometricStore {
  /// True when the device has strong biometrics enrolled and this platform supports them.
  Future<bool> isAvailable();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class BiometricCancelled implements Exception {
  const BiometricCancelled(this.message);

  final String message;

  @override
  String toString() => 'BiometricCancelled: $message';
}

class PlatformSecretStore implements SecretStore {
  const PlatformSecretStore();

  // resetOnError defaults to true, which erases every entry after a Keystore error. The sealed
  // wallet password must never vanish silently, so errors surface instead.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    // This Mac only, as on iOS. Entries written before under the default level stay readable:
    // flutter_secure_storage_darwin 0.4.3+ reads, finds and deletes across every level and
    // rewrites an entry at this level on its next write (secret_store_test checks the lock).
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The words in the system's biometric prompt.
typedef BiometricPromptText = ({String title, String subtitle, String usePin});

class PlatformBiometricStore implements BiometricStore {
  PlatformBiometricStore();

  final LocalAuthentication _auth = LocalAuthentication();

  /// What the next prompt says. `WalletApp` sets it from the app's language; until then the
  /// English below, the same as in [_storage].
  BiometricPromptText prompt = (
    title: 'Unlock wallet',
    subtitle: 'Confirm with your fingerprint or face',
    usePin: 'Use PIN',
  );

  /// [_storage]'s Android options with [prompt]'s words. copyWith keeps every other option, so
  /// the namespace and the Keystore key stay the same.
  AndroidOptions get _promptOptions => _storage.aOptions.copyWith(
    biometricPromptTitle: prompt.title,
    biometricPromptSubtitle: prompt.subtitle,
    biometricPromptNegativeButton: prompt.usePin,
  );

  // A separate namespace keeps this Keystore key apart from the main store. The key requires a
  // Class 3 biometric for every operation. A new enrollment invalidates it; the entry is only a
  // copy of the PIN-sealed password, so a reset here loses nothing.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      requireBiometricsPerOperation: true,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      // A recognized face continues on its own instead of waiting for a Confirm tap.
      requireBiometricConfirmation: false,
      storageNamespace: 'wfe_biometric',
      biometricPromptTitle: 'Unlock wallet',
      biometricPromptSubtitle: 'Confirm with your fingerprint or face',
      biometricPromptNegativeButton: 'Use PIN',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.passcode,
      accessControlFlags: [AccessControlFlag.biometryCurrentSet],
    ),
  );

  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> isAvailable() async {
    if (!_mobile) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.strong) ||
          types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.face);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      logInfo('biometrics', 'not unlocked: ${error.code}');
      throw BiometricCancelled(error.message ?? error.code);
    } on LocalAuthException catch (error) {
      logInfo('biometrics', 'not unlocked: ${error.code.name}');
      throw BiometricCancelled(error.description ?? error.code.name);
    }
  }

  // flutter_secure_storage 11.2.0 keeps the key it unlocked for the first write of a new
  // namespace for the rest of the process, so later reads skip the prompt despite
  // requireBiometricsPerOperation (seen on the API 36 emulator; a cold start prompts every time).
  // Until the process restarts, reads after a write therefore ask local_auth first.
  bool _wroteThisProcess = false;

  @override
  Future<String?> read(String key) => _guard(() async {
    if (_wroteThisProcess &&
        !await _auth.authenticate(
          localizedReason: prompt.title,
          biometricOnly: true,
          sensitiveTransaction: false,
        )) {
      throw const BiometricCancelled('dismissed');
    }
    return _storage.read(key: key, aOptions: _promptOptions);
  });

  @override
  Future<void> write(String key, String value) => _guard(() async {
    await _storage.write(key: key, value: value, aOptions: _promptOptions);
    _wroteThisProcess = true;
  });

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key, aOptions: _promptOptions);
    } on PlatformException {
      // Deleting an entry whose key was invalidated can fail; the entry is useless either way.
    }
  }
}

/// Scripted biometrics for tests. Set [succeed] to false to simulate a dismissed prompt.
class MemoryBiometricStore implements BiometricStore {
  MemoryBiometricStore({this.available = true});

  bool available;
  bool succeed = true;
  int prompts = 0;
  final Map<String, String> values = {};

  void _prompt() {
    prompts++;
    if (!succeed) throw const BiometricCancelled('dismissed');
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> read(String key) async {
    _prompt();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _prompt();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}
