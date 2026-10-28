// SPDX-License-Identifier: Apache-2.0
/// "Remember on this computer": a wallet's password kept so the app opens it at start
/// without asking.
///
/// The password is never written as it is. It is sealed with AES-256-GCM under a random key
/// that only the OS store holds ([SecretStore]: on Windows a file encrypted with DPAPI for the
/// user, on Linux libsecret), and the sealed text lies in a file of its own under
/// `<application support>/remember`. Either half alone opens nothing; deleting either forgets.
/// Anything running as the same user can still read both, so the checkbox says so.
///
/// Rules: per wallet; expires [rememberFor] after it was saved; forgotten on "Forget this
/// computer", after [maxRememberFails] wrong passwords in a row, on a password change and on
/// Delete wallet. The expiry is sealed with the password (in the associated data), so editing
/// the file to extend it breaks the seal.
///
/// LEPIC's PIN mode (`create_with_pin`) seals a password too, but only for a wallet created
/// with a PIN, and it counts PIN attempts in the wallet; using it here needs LEPIC changes.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

import '../../log.dart';
import '../../secret_store_api.dart';

const Duration rememberFor = Duration(days: 30);
const int maxRememberFails = 5;

class RememberedPasswords {
  RememberedPasswords({required this._secrets, required this._dir, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SecretStore _secrets;
  final Future<Directory> Function() _dir;
  final DateTime Function() _now;
  static final _aes = AesGcm.with256bits();

  static String _keyName(String id) => 'desk.remember.$id';

  Future<File> _file(String id) async {
    final name = sha256.convert(utf8.encode(id)).toString().substring(0, 24);
    return File('${(await _dir()).path}${Platform.pathSeparator}$name.json');
  }

  static List<int> _aad(String id, int until) => utf8.encode('wfe-remember-v1|$id|$until');

  /// Keeps [password] for the wallet [id] for [rememberFor] from when it was first set: kept
  /// again while still valid, it keeps its expiry. False when the OS store or the disk
  /// refused; nothing is kept then.
  Future<bool> remember(String id, String password) async {
    try {
      final key = List<int>.generate(32, (_) => _random.nextInt(256));
      final keptUntil = (await _record(id))?['until'] as int?;
      final until = keptUntil != null && DateTime.fromMillisecondsSinceEpoch(keptUntil).isAfter(_now())
          ? keptUntil
          : _now().add(rememberFor).millisecondsSinceEpoch;
      final box = await _aes.encrypt(
        utf8.encode(password),
        secretKey: SecretKey(key),
        nonce: _aes.newNonce(),
        aad: _aad(id, until),
      );
      final file = await _file(id);
      await file.parent.create(recursive: true);
      await _secrets.write(_keyName(id), base64.encode(key));
      await file.writeAsString(
        jsonEncode({'v': 1, 'until': until, 'fails': 0, 'box': base64.encode(box.concatenation())}),
        flush: true,
      );
      logInfo('remember', 'wallet remembered on this computer');
      return true;
    } on Object catch (e) {
      logWarn('remember', 'not remembered: ${e.runtimeType}');
      await forget(id, quiet: true);
      return false;
    }
  }

  Future<Map<String, dynamic>?> _record(String id) async {
    try {
      final file = await _file(id);
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString());
      return j is Map<String, dynamic> && j['v'] == 1 && j['until'] is int && j['box'] is String ? j : null;
    } on Object {
      return null;
    }
  }

  /// Whether a password is kept for [id] and not expired.
  Future<bool> isRemembered(String id) async {
    final r = await _record(id);
    return r != null && DateTime.fromMillisecondsSinceEpoch(r['until'] as int).isAfter(_now());
  }

  /// The password kept for [id]; null when none, expired, its key is gone or it does not
  /// open (then it is forgotten). Throws [RememberUnavailable] when the OS store does not
  /// answer (a locked keyring, a slow D-Bus): the seal is kept for the next try.
  Future<String?> recall(String id) async {
    final r = await _record(id);
    if (r == null) return null;
    final until = r['until'] as int;
    if (!DateTime.fromMillisecondsSinceEpoch(until).isAfter(_now())) {
      logInfo('remember', 'remembered password expired');
      await forget(id, quiet: true);
      return null;
    }
    final String? key;
    try {
      key = await _secrets.read(_keyName(id));
    } on Object catch (e) {
      logWarn('remember', 'key store unavailable: ${e.runtimeType}');
      throw const RememberUnavailable();
    }
    try {
      if (key == null) throw const FormatException('no key'); // l10n-ok: internal
      final box = SecretBox.fromConcatenation(
        base64.decode(r['box'] as String),
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
      return utf8.decode(await _aes.decrypt(box, secretKey: SecretKey(base64.decode(key)), aad: _aad(id, until)));
    } on Object catch (e) {
      logWarn('remember', 'remembered password unreadable: ${e.runtimeType}');
      await forget(id, quiet: true);
      return null;
    }
  }

  /// A wrong password for [id]: after [maxRememberFails] in a row, what was kept is forgotten.
  Future<void> failed(String id) async {
    final r = await _record(id);
    if (r == null) return;
    final fails = (r['fails'] is int ? r['fails'] as int : 0) + 1;
    if (fails >= maxRememberFails) {
      logInfo('remember', 'forgotten after $fails wrong passwords');
      return forget(id, quiet: true);
    }
    try {
      await (await _file(id)).writeAsString(jsonEncode({...r, 'fails': fails}), flush: true);
    } on Object catch (e) {
      logWarn('remember', 'fail count not saved: ${e.runtimeType}');
    }
  }

  /// The right password for [id]: the count of wrong ones starts again.
  Future<void> succeeded(String id) async {
    final r = await _record(id);
    if (r == null || r['fails'] == 0) return;
    try {
      await (await _file(id)).writeAsString(jsonEncode({...r, 'fails': 0}), flush: true);
    } on Object catch (e) {
      logWarn('remember', 'fail count not saved: ${e.runtimeType}');
    }
  }

  /// Forgets what is kept for [id], both halves.
  Future<void> forget(String id, {bool quiet = false}) async {
    try {
      await _secrets.delete(_keyName(id));
    } on Object catch (e) {
      logWarn('remember', 'key not deleted: ${e.runtimeType}');
    }
    try {
      final file = await _file(id);
      if (await file.exists()) await file.delete();
    } on Object catch (e) {
      logWarn('remember', 'file not deleted: ${e.runtimeType}');
    }
    if (!quiet) logInfo('remember', 'wallet forgotten on this computer');
  }

  static final _random = Random.secure();
}

/// The OS store did not answer: the remembered password is kept but cannot be read now.
class RememberUnavailable implements Exception {
  const RememberUnavailable();

  @override
  String toString() => 'Remembered password unavailable'; // l10n-ok: log text
}

/// Set once the first Unlock screen of this run tried the remembered password: Unlock after a
/// Lock always asks (a wallet chosen in the wallet switch is tried again: `UnlockPick.switched`).
bool rememberAutoTried = false;
