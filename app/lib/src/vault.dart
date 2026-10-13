/// The PIN and biometrics that open a wallet, over LEPIC's PIN vault.
///
/// LEPIC generates each wallet's password, seals it under the PIN and a key it keeps in the
/// app's store, and hands Dart only the sealed text (`createWithPin`). This vault stores that
/// text per chain and passes it back to open the wallet, show its phrase or change its PIN.
/// LEPIC counts wrong PINs and makes later tries wait ([pinDelay]); [PinRejected] reports its
/// count. Biometrics keep a copy of the PIN in [BiometricStore] (OD-5). Nothing here logs the
/// PIN or the sealed text.
library;

import 'dart:io';
import 'dart:math';

import 'app_log.dart';
import 'secret_store.dart';
import 'wallet_service.dart';

/// Digits in a wallet PIN.
const int pinLength = 6;

/// A wrong PIN, with LEPIC's count of wrong PINs since the last right one.
class PinRejected implements Exception {
  const PinRejected(this.failures);

  final int failures;

  /// Tries left before tries start to wait.
  int get attemptsLeft => max(0, freePinAttempts - failures);

  /// How long LEPIC waits before it checks the next try.
  Duration get nextWait => pinDelay(failures);
}

/// `true` when [pin] is exactly [pinLength] ASCII digits.
bool isValidPin(String pin) =>
    pin.length == pinLength && RegExp(r'^[0-9]+$').hasMatch(pin);

/// Whether a chain has a wallet the PIN opens.
enum VaultStage {
  /// No wallet: first run.
  empty,

  /// A wallet and its sealed text.
  ready,
}

/// Deletes what an older app left in a wallet directory; returns whether anything was there.
typedef LegacyFiles = Future<bool> Function(String dataDir);

/// Deletes epic-wallet's `wallet_data/` and the old core's `wfe_meta.json` from [dataDir], the
/// files of an install on 1.2.x or older (OD-3: no migration). No old-core session runs in a
/// LEPIC app, so nothing writes them again afterwards. Synchronous calls: one `stat` at launch
/// in the common case, and they also complete inside widget tests' fake async zone.
Future<bool> deleteLegacyWalletFiles(String dataDir) async {
  final sep = Platform.pathSeparator;
  final walletData = Directory('$dataDir${sep}wallet_data');
  if (!walletData.existsSync()) return false;
  walletData.deleteSync(recursive: true);
  final meta = File('$dataDir${sep}wfe_meta.json');
  if (meta.existsSync()) meta.deleteSync();
  return true;
}

class WalletVault {
  WalletVault({
    required this.store,
    required this.biometrics,
    required this.service,
    LegacyFiles? legacyFiles,
  }) : _legacyFiles = legacyFiles ?? deleteLegacyWalletFiles;

  final SecretStore store;
  final BiometricStore biometrics;
  final WalletService service;
  final LegacyFiles _legacyFiles;

  String _key(Chain chain, String name) => 'wallet.${chain.name}.$name';

  /// Entries of the 1.2.x vault: its password sealed by the old core, the password of an
  /// unfinished first run, and its own lockout.
  static const List<String> _legacyKeys = [
    'sealed',
    'pending',
    'failed',
    'lockedUntil',
    'biometrics',
  ];

  /// Clears what does not open with a PIN, then says whether [config]'s wallet does.
  ///
  /// Gone: the files and entries of a 1.2.x install; a wallet whose sealed text was never
  /// stored, because the app stopped right after creating it (its phrase was never shown, so
  /// it holds no funds); and the entries of a wallet whose files are gone.
  Future<VaultStage> prepare(WalletConfig config) async {
    final chain = config.chain;
    var legacy = await _legacyFiles(config.dataDir);
    for (final name in _legacyKeys) {
      final key = _key(chain, name);
      if (await store.read(key) != null) {
        legacy = true;
        await store.delete(key);
      }
    }
    if (legacy) {
      // The 1.2.x biometric copy held the old password.
      await biometrics.delete(_key(chain, 'password'));
      logInfo('vault', 'discarded the ${chain.name} wallet of an older app');
    }
    final exists = await service.walletExists(config: config);
    final sealed = await store.read(_key(chain, 'pinSealed'));
    if (exists && sealed != null) return VaultStage.ready;
    if (exists) {
      logInfo('vault', 'deleting a ${chain.name} wallet without sealed text');
      await service.deleteWallet(config: config);
    }
    if (exists || sealed != null || legacy) await forget(chain);
    return VaultStage.empty;
  }

  /// Creates the wallet of [config] under [pin], restoring [mnemonic] if given, and stores its
  /// sealed text before anything can show the phrase. With [useBiometrics] it also stores the
  /// biometric copy of the PIN, which prompts. A wallet that already opens with a PIN is never
  /// replaced: that throws [WalletErrorKind.walletAlreadyExists].
  Future<({WalletSession session, bool biometrics})> create(
    WalletConfig config, {
    required String pin,
    String? mnemonic,
    bool useBiometrics = false,
  }) async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be $pinLength digits');
    if (await prepare(config) == VaultStage.ready) {
      throw const WalletError(
        kind: WalletErrorKind.walletAlreadyExists,
        message: 'a wallet with a PIN exists',
      );
    }
    final created = await service.createWithPin(
      config: config,
      mnemonic: mnemonic,
      pin: pin,
    );
    try {
      await store.write(_key(config.chain, 'pinSealed'), created.sealedPassword);
    } catch (_) {
      // Without the text the wallet never opens again; it holds nothing yet.
      created.session.dispose();
      await service.deleteWallet(config: config);
      rethrow;
    }
    final bio = useBiometrics && await _storeBiometricPin(config.chain, pin);
    return (session: created.session, biometrics: bio);
  }

  Future<String> _sealed(Chain chain) async {
    final sealed = await store.read(_key(chain, 'pinSealed'));
    if (sealed == null) {
      throw const WalletError(
        kind: WalletErrorKind.walletNotFound,
        message: 'no PIN is set for this wallet',
      );
    }
    return sealed;
  }

  /// Runs a PIN call, turning LEPIC's wrong-PIN answer into [PinRejected].
  Future<T> _pinCall<T>(WalletConfig config, Future<T> Function() call) async {
    try {
      return await call();
    } on WalletError catch (error) {
      if (error.kind != WalletErrorKind.wrongPassword) rethrow;
      final failures = await service.pinFailures(config: config);
      logInfo('unlock', 'wrong PIN, $failures in a row');
      throw PinRejected(failures);
    }
  }

  /// How long LEPIC will wait before it checks the next PIN.
  Future<Duration> nextPinWait(WalletConfig config) async =>
      pinDelay(await service.pinFailures(config: config));

  /// Opens the wallet with [pin]. Throws [PinRejected] for a wrong PIN.
  Future<WalletSession> unlock(WalletConfig config, String pin) async {
    final sealed = await _sealed(config.chain);
    return _pinCall(
      config,
      () => service.openWithPin(config: config, pin: pin, sealedPassword: sealed),
    );
  }

  /// The recovery phrase of the open wallet, for the backup screen only.
  Future<String> mnemonic(
    WalletSession session,
    WalletConfig config,
    String pin,
  ) async {
    final sealed = await _sealed(config.chain);
    return _pinCall(
      config,
      () => session.mnemonicWithPin(pin: pin, sealedPassword: sealed),
    );
  }

  /// Seals the password under [newPin], stores the new text, then lets LEPIC drop the old one.
  /// If the app stops in between, the text it holds still opens.
  Future<void> _reseal(
    WalletSession session,
    WalletConfig config, {
    required String currentPin,
    required String newPin,
  }) async {
    if (!isValidPin(newPin)) throw ArgumentError('PIN must be $pinLength digits');
    final sealed = await _sealed(config.chain);
    final next = await _pinCall(
      config,
      () => session.changePin(
        sealedPassword: sealed,
        oldPin: currentPin,
        newPin: newPin,
      ),
    );
    await store.write(_key(config.chain, 'pinSealed'), next);
    await session.confirmPinChange(sealedPassword: next);
  }

  /// Checks [pin] without showing anything. LEPIC has no plain PIN check, so this seals the
  /// password again under the same PIN, which also renews the PIN key. Throws [PinRejected].
  Future<void> checkPin(
    WalletSession session,
    WalletConfig config,
    String pin,
  ) => _reseal(session, config, currentPin: pin, newPin: pin);

  /// Replaces the PIN; a wrong [currentPin] throws [PinRejected] and changes nothing. The
  /// biometric copy is rewritten, which prompts. Returns false when biometric unlock was on
  /// and is now off, because that prompt was dismissed.
  Future<bool> changePin(
    WalletSession session,
    WalletConfig config, {
    required String currentPin,
    required String newPin,
  }) async {
    await _reseal(session, config, currentPin: currentPin, newPin: newPin);
    if (!await biometricsEnabled(config.chain)) return true;
    if (await _storeBiometricPin(config.chain, newPin)) return true;
    await disableBiometrics(config.chain);
    return false;
  }

  Future<bool> biometricsEnabled(Chain chain) async =>
      await store.read(_key(chain, 'pinBiometrics')) == '1';

  /// Checks [pin] ([checkPin]), then stores the biometric copy of it. Returns false if the
  /// prompt was dismissed.
  Future<bool> enableBiometrics(
    WalletSession session,
    WalletConfig config,
    String pin,
  ) async {
    await checkPin(session, config, pin);
    return _storeBiometricPin(config.chain, pin);
  }

  Future<bool> _storeBiometricPin(Chain chain, String pin) async {
    try {
      await biometrics.write(_key(chain, 'pin'), pin);
    } on BiometricCancelled {
      return false;
    }
    await store.write(_key(chain, 'pinBiometrics'), '1');
    return true;
  }

  Future<void> disableBiometrics(Chain chain) async {
    await store.delete(_key(chain, 'pinBiometrics'));
    await biometrics.delete(_key(chain, 'pin'));
  }

  /// The biometric copy of the PIN. Null if biometrics are off, the prompt was dismissed, or
  /// the copy is gone (for example after a new fingerprint was enrolled; that turns them off).
  Future<String?> readBiometricPin(Chain chain) async {
    if (!await biometricsEnabled(chain)) return null;
    final String? pin;
    try {
      pin = await biometrics.read(_key(chain, 'pin'));
    } on BiometricCancelled {
      return null;
    }
    if (pin == null) await disableBiometrics(chain);
    return pin;
  }

  /// Opens the wallet with the biometric copy of the PIN, or null as [readBiometricPin]. A
  /// copy that no longer opens turns biometrics off and throws [PinRejected].
  Future<WalletSession?> unlockWithBiometrics(WalletConfig config) async {
    final pin = await readBiometricPin(config.chain);
    if (pin == null) return null;
    try {
      return await unlock(config, pin);
    } on PinRejected {
      await disableBiometrics(config.chain);
      rethrow;
    }
  }

  Future<bool> isBackedUp(Chain chain) async =>
      await store.read(_key(chain, 'backedUp')) == '1';

  Future<void> markBackedUp(Chain chain) =>
      store.write(_key(chain, 'backedUp'), '1');

  /// Whether [chain]'s wallet was created with the web demo's fixed PIN. Only demo mode reads
  /// it; elsewhere it changes nothing.
  Future<bool> usesDemoPin(Chain chain) async =>
      await store.read(_key(chain, 'demoPin')) == '1';

  Future<void> markDemoPin(Chain chain) =>
      store.write(_key(chain, 'demoPin'), '1');

  /// Deletes everything the app stored for [chain]. The wallet itself, with LEPIC's PIN key
  /// and count, goes with [WalletService.deleteWallet].
  Future<void> forget(Chain chain) async {
    await disableBiometrics(chain);
    for (final name in [
      'pinSealed',
      'backedUp',
      'demoPin',
      'backupCardDismissed', // home's recovery phrase card (home_screen.dart)
    ]) {
      await store.delete(_key(chain, name));
    }
  }
}
