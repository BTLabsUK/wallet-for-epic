/// The wallet password the user never sees, and the PIN and biometrics that release it.
///
/// Each chain's wallet gets its own random password. While the first-run PIN setup is still in
/// progress the password is kept unsealed as `pending`, so a crash or a killed app never loses
/// it. Once the PIN is set it is stored only sealed under the PIN (Rust `seal_password`), plus
/// an optional copy in [BiometricStore].
library;

import 'dart:math';

import 'rust/api/vault.dart' as rust;
import 'secret_store.dart';
import 'wallet_service.dart';

/// Digits in a wallet PIN.
const int pinLength = 6;

/// Wrong PINs allowed before each lockout.
const int freePinAttempts = 5;

/// First lockout; each further wrong PIN doubles it, up to [maxLockout].
const Duration firstLockout = Duration(seconds: 30);
const Duration maxLockout = Duration(hours: 1);

/// Seals and opens passwords. [RustVaultCrypto] in the app, a fake in widget tests.
abstract interface class VaultCrypto {
  String generatePassword();

  Future<String> seal({required String pin, required String password});

  /// Throws [WalletError] with [WalletErrorKind.wrongPassword] for a wrong PIN.
  Future<String> open({required String pin, required String sealed});
}

class RustVaultCrypto implements VaultCrypto {
  const RustVaultCrypto();

  @override
  String generatePassword() => rust.generateWalletPassword();

  @override
  Future<String> seal({required String pin, required String password}) =>
      rust.sealPassword(pin: pin, password: password);

  @override
  Future<String> open({required String pin, required String sealed}) =>
      rust.openPassword(pin: pin, sealed: sealed);
}

/// Reversible stand-in for tests. Not encryption.
class FakeVaultCrypto implements VaultCrypto {
  int _counter = 0;

  @override
  String generatePassword() => 'generated-password-${_counter++}';

  @override
  Future<String> seal({required String pin, required String password}) async =>
      'sealed|$pin|$password';

  @override
  Future<String> open({required String pin, required String sealed}) async {
    final parts = sealed.split('|');
    if (parts.length != 3 || parts[1] != pin) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'wrong password',
      );
    }
    return parts[2];
  }
}

/// How far the vault of one chain got.
enum VaultStage {
  /// Nothing stored.
  empty,

  /// A password exists, but the PIN is not set yet.
  pending,

  /// The password is sealed under a PIN.
  sealed,
}

/// A wrong PIN, with what the user may do next.
class PinRejected implements Exception {
  const PinRejected({this.attemptsLeft, this.lockedUntil});

  /// Tries left before a lockout, or null while locked out.
  final int? attemptsLeft;

  /// When the next try is allowed, if the vault is locked out.
  final DateTime? lockedUntil;
}

/// `true` when [pin] is exactly [pinLength] ASCII digits.
bool isValidPin(String pin) =>
    pin.length == pinLength && RegExp(r'^[0-9]+$').hasMatch(pin);

class WalletVault {
  WalletVault({
    required this.store,
    required this.biometrics,
    required this.crypto,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SecretStore store;
  final BiometricStore biometrics;
  final VaultCrypto crypto;
  final DateTime Function() _clock;

  String _key(Chain chain, String name) => 'wallet.${chain.name}.$name';

  Future<VaultStage> stage(Chain chain) async {
    if (await store.read(_key(chain, 'sealed')) != null) {
      return VaultStage.sealed;
    }
    if (await store.read(_key(chain, 'pending')) != null) {
      return VaultStage.pending;
    }
    return VaultStage.empty;
  }

  /// The pending password of [chain], created and stored first if there is none.
  Future<String> pendingPassword(Chain chain) async {
    final key = _key(chain, 'pending');
    final existing = await store.read(key);
    if (existing != null) return existing;
    final password = crypto.generatePassword();
    await store.write(key, password);
    return password;
  }

  /// Seals [password] under [pin] and drops the pending copy. With [useBiometrics] it also
  /// stores a biometric copy, which prompts; returns whether that copy was stored.
  Future<bool> seal(
    Chain chain, {
    required String pin,
    required String password,
    required bool useBiometrics,
  }) async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be $pinLength digits');
    final sealed = await crypto.seal(pin: pin, password: password);
    await store.write(_key(chain, 'sealed'), sealed);
    await store.delete(_key(chain, 'pending'));
    await _resetAttempts(chain);
    if (!useBiometrics) return false;
    return enableBiometrics(chain, password);
  }

  /// Opens the password with [pin]. Throws [PinRejected] for a wrong PIN or during a lockout.
  Future<String> unlockWithPin(Chain chain, String pin) async {
    final lockedUntil = await this.lockedUntil(chain);
    if (lockedUntil != null) throw PinRejected(lockedUntil: lockedUntil);
    final sealed = await store.read(_key(chain, 'sealed'));
    if (sealed == null) {
      throw const WalletError(
        kind: WalletErrorKind.walletNotFound,
        message: 'no PIN is set for this wallet',
      );
    }
    try {
      final password = await crypto.open(pin: pin, sealed: sealed);
      await _resetAttempts(chain);
      return password;
    } on WalletError catch (error) {
      if (error.kind != WalletErrorKind.wrongPassword) rethrow;
      throw await _recordFailure(chain);
    }
  }

  /// When the next PIN try is allowed, or null if it is allowed now.
  Future<DateTime?> lockedUntil(Chain chain) async {
    final value = await store.read(_key(chain, 'lockedUntil'));
    final until = value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.tryParse(value) ?? 0);
    if (until == null || !until.isAfter(_clock())) return null;
    return until;
  }

  Future<PinRejected> _recordFailure(Chain chain) async {
    final failedKey = _key(chain, 'failed');
    final failed = (int.tryParse(await store.read(failedKey) ?? '') ?? 0) + 1;
    await store.write(failedKey, '$failed');
    if (failed < freePinAttempts) {
      return PinRejected(attemptsLeft: freePinAttempts - failed);
    }
    final doublings = min(failed - freePinAttempts, 20);
    final wait = Duration(
      milliseconds: min(
        firstLockout.inMilliseconds * (1 << doublings),
        maxLockout.inMilliseconds,
      ),
    );
    final until = _clock().add(wait);
    await store.write(
      _key(chain, 'lockedUntil'),
      '${until.millisecondsSinceEpoch}',
    );
    return PinRejected(lockedUntil: until);
  }

  Future<void> _resetAttempts(Chain chain) async {
    await store.delete(_key(chain, 'failed'));
    await store.delete(_key(chain, 'lockedUntil'));
  }

  Future<bool> biometricsEnabled(Chain chain) async =>
      await store.read(_key(chain, 'biometrics')) == '1';

  /// Stores a biometric copy of [password]. Returns false if the prompt was dismissed.
  Future<bool> enableBiometrics(Chain chain, String password) async {
    try {
      await biometrics.write(_key(chain, 'password'), password);
    } on BiometricCancelled {
      return false;
    }
    await store.write(_key(chain, 'biometrics'), '1');
    return true;
  }

  Future<void> disableBiometrics(Chain chain) async {
    await store.delete(_key(chain, 'biometrics'));
    await biometrics.delete(_key(chain, 'password'));
  }

  /// The password via biometrics, or null if the prompt was dismissed or the copy is gone
  /// (for example after a new fingerprint was enrolled).
  Future<String?> unlockWithBiometrics(Chain chain) async {
    if (!await biometricsEnabled(chain)) return null;
    try {
      final password = await biometrics.read(_key(chain, 'password'));
      if (password == null) await disableBiometrics(chain);
      return password;
    } on BiometricCancelled {
      return null;
    }
  }

  Future<bool> isBackedUp(Chain chain) async =>
      await store.read(_key(chain, 'backedUp')) == '1';

  Future<void> markBackedUp(Chain chain) =>
      store.write(_key(chain, 'backedUp'), '1');

  /// Deletes everything stored for [chain]. The wallet files are separate.
  Future<void> forget(Chain chain) async {
    await disableBiometrics(chain);
    for (final name in [
      'sealed',
      'pending',
      'failed',
      'lockedUntil',
      'backedUp',
    ]) {
      await store.delete(_key(chain, name));
    }
  }
}
