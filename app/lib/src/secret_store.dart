// SPDX-License-Identifier: Apache-2.0
/// The platform's secret storage, and a biometric-gated variant. The [SecretStore] interface
/// and [MemorySecretStore] are in `secret_store_api.dart`, without Flutter, and re-exported here.
///
/// [PlatformSecretStore] is the platform keystore: Android Keystore, iOS Keychain (this device
/// only), libsecret on Linux. [PlatformBiometricStore] adds a Keystore/Keychain key that only a
/// fresh biometric check unlocks, so the biometric copy of a secret is bound to the fingerprint or
/// face, not just gated by a dialog. Tests use the in-memory versions.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart' show AndroidAuthMessages;

import 'app_log.dart';
import 'pin_wrap.dart';
import 'secret_store_api.dart';

export 'secret_store_api.dart';

/// [KeyWrap] over `PinKeyWrap.kt`. Android only.
class PlatformKeyWrap implements KeyWrap {
  const PlatformKeyWrap();

  static const _channel = MethodChannel('epic_wallet/pin_wrap');

  Future<T?> _call<T>(String method, Map<String, Object> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (error) {
      if (error.code == 'lost') throw PinKeyLost(error.message ?? 'lost');
      throw KeyWrapUnavailable(error.message ?? error.code);
    }
  }

  @override
  Future<Map<String, bool>> create(String alias) async {
    final got = await _call<Map<Object?, Object?>>('create', {'alias': alias});
    return {for (final e in (got ?? const {}).entries) '${e.key}': e.value == true};
  }

  @override
  Future<String> seal(String alias, String name, String text) async =>
      (await _call<String>('seal', {'alias': alias, 'name': name, 'text': text}))!;

  @override
  Future<String> open(String alias, String name, String blob) async =>
      (await _call<String>('open', {'alias': alias, 'name': name, 'blob': blob}))!;

  @override
  Future<void> delete(String alias) => _call<void>('delete', {'alias': alias});

  @override
  Future<List<String>> aliases(String prefix) async =>
      (await _call<List<Object?>>('aliases', {'prefix': prefix}) ?? const [])
          .cast<String>();
}

/// Biometric storage. [read] and [write] show the system prompt and throw
/// [BiometricCancelled] when the user dismisses it or the check fails.
abstract interface class BiometricStore {
  /// True when the device has strong biometrics enrolled and this platform supports them.
  Future<bool> isAvailable();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// False once this process wrote a copy: the store can no longer prove a fresh biometric
  /// check for a read until the app restarts, so no read is offered ([WalletVault]).
  bool get readable;
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
    // The login (file) keychain, not the data-protection one: that needs a keychain-access-groups
    // entitlement, so an app signed without a Team ID gets errSecMissingEntitlement (-34018).
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      usesDataProtectionKeychain: false,
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
      // The plugin takes a namespace it never saw for one made by its old default (RSA) and
      // migrates it under a prompt whose cancel it never answers: Setup waited for good after
      // "Use PIN". Nothing here is worth migrating: the entry is a copy of the PIN.
      migrateOnAlgorithmChange: false,
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

  /// How long a call into the biometric store may wait for its prompt. flutter_secure_storage
  /// 11.2.0 never answers when its prompt is dismissed with "Use PIN" (Android logs "Unknown
  /// cookie"); past this the call counts as dismissed rather than waiting for good.
  static const Duration promptLimit = Duration(seconds: 90);

  /// How long a call may stay unanswered once the app is back in front, the prompt gone. A
  /// confirmed prompt answers within moments; one dismissed with "Use PIN" never does.
  static const Duration answerGrace = Duration(seconds: 3);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await _promptAnswer(action()).timeout(promptLimit);
    } on TimeoutException {
      logInfo('biometrics', 'not unlocked: no answer');
      throw const BiometricCancelled('no answer');
    } on PlatformException catch (error) {
      logInfo('biometrics', 'not unlocked: ${error.code}');
      throw BiometricCancelled(error.message ?? error.code);
    } on LocalAuthException catch (error) {
      logInfo('biometrics', 'not unlocked: ${error.code.name}');
      throw BiometricCancelled(error.description ?? error.code.name);
    }
  }

  /// [call], or [BiometricCancelled] once the app was covered by a prompt, came back to the
  /// front and [answerGrace] passed with no answer: the prompt was dismissed and the store will
  /// not say so. Covered again meanwhile (the store's own prompt after local_auth's),
  /// the wait starts over.
  Future<T> _promptAnswer<T>(Future<T> call) {
    final done = Completer<T>();
    Timer? grace;
    var covered = false;
    final watch = _LifecycleWatch((state) {
      if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
        covered = true;
        grace?.cancel();
        grace = null;
      } else if (state == AppLifecycleState.resumed && covered) {
        grace?.cancel();
        grace = Timer(answerGrace, () {
          if (!done.isCompleted) done.completeError(const BiometricCancelled('dismissed'));
        });
      }
    });
    WidgetsBinding.instance.addObserver(watch);
    call.then((v) {
      if (!done.isCompleted) done.complete(v);
    }, onError: (Object e, StackTrace st) {
      if (!done.isCompleted) done.completeError(e, st);
    });
    return done.future.whenComplete(() {
      grace?.cancel();
      WidgetsBinding.instance.removeObserver(watch);
    });
  }

  // flutter_secure_storage 11.2.0 keeps the key it unlocked for the first write of a new
  // namespace for the rest of the process, so later reads skip the prompt despite
  // requireBiometricsPerOperation (seen on the API 36 emulator; a cold start prompts every time).
  // A read would then be gated only by a prompt that answers yes or no, with no key bound to
  // it, so after a write this process reads nothing: the PIN opens the wallet until the app
  // restarts, and the Keystore-bound prompt is back from then on.
  bool _wroteThisProcess = false;

  @override
  bool get readable => !_wroteThisProcess;

  /// local_auth's prompt with [prompt]'s words, as the store's own prompt has them (its
  /// defaults are English).
  Future<bool> _authenticate() => _auth.authenticate(
    localizedReason: prompt.subtitle,
    authMessages: [
      // No hint line: the reason above already says it, and the prompt hides an empty one.
      AndroidAuthMessages(signInTitle: prompt.title, signInHint: '', cancelButton: prompt.usePin),
    ],
    biometricOnly: true,
    sensitiveTransaction: false,
  );

  @override
  Future<String?> read(String key) => _guard(() async {
    if (_wroteThisProcess) throw const BiometricCancelled('written in this process');
    return _storage.read(key: key, aOptions: _promptOptions);
  });

  @override
  Future<void> write(String key, String value) => _guard(() async {
    // local_auth first: it answers a dismissed prompt, which the store's own prompt does not
    //. The store then asks once more, for its key.
    if (!await _authenticate()) {
      throw const BiometricCancelled('dismissed');
    }
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

  /// As [PlatformBiometricStore] after a write in the same process, when set false.
  @override
  bool readable = true;

  /// How often [delete] was called: the real store can prompt for it.
  int deletes = 0;

  /// Set: [read] waits for it, as a prompt the system never answers.
  Completer<void>? hold;
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
    await hold?.future;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _prompt();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    values.remove(key);
  }
}

class _LifecycleWatch with WidgetsBindingObserver {
  _LifecycleWatch(this.onChange);

  final void Function(AppLifecycleState state) onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}
