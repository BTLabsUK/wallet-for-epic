// SPDX-License-Identifier: Apache-2.0
/// The PIN key and the PIN failure count, held under a key of the phone's secure hardware.
///
/// LEPIC keeps a wallet's PIN key (`lepic.pin-key`, and `lepic.pin-key-pending` during a PIN
/// change) and its count of wrong PINs (`lepic.pin-failures`) in the app's store, beside the
/// sealed wallet password. Anyone with a copy of that store could try all 10^6 PINs offline.
/// [HardwarePinStore] seals those three entries with a non-exportable Android Keystore key
/// ([KeyWrap], `PinKeyWrap.kt`), so a copy is useless off the phone. Each new failure count is
/// written under a new Keystore key and the old key is deleted, so putting back an older copy
/// of the store (with a lower count) leaves text no key opens.
///
/// Entries of an older app stay plain and keep working until the first PIN attempt, whose
/// count write seals all three: that is the migration. A key the Keystore lost turns into
/// [PinKeyLost], and the user is sent to the recovery phrase.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'log.dart';
import 'secret_store_api.dart';

/// The Keystore key that held a wallet's PIN key is gone or no longer opens it (a reset
/// Keystore, a known fault on some phones, or an older copy of the store put back). The
/// wallet opens only from its recovery phrase now.
class PinKeyLost implements Exception {
  const PinKeyLost(this.reason);

  final String reason;

  @override
  String toString() => 'PinKeyLost: $reason';
}

/// The Keystore could not answer now (a locked phone, a busy Keystore); trying again may work.
class KeyWrapUnavailable implements Exception {
  const KeyWrapUnavailable(this.code);

  final String code;

  @override
  String toString() => 'KeyWrapUnavailable: $code';
}

/// Keys held by the platform's secure hardware that seal short text.
abstract interface class KeyWrap {
  /// Makes the key [alias]. Returns what it got (`strongBox`, `unlockedRequired`).
  Future<Map<String, bool>> create(String alias);

  /// [text] sealed under [alias] and bound to [name].
  Future<String> seal(String alias, String name, String text);

  /// What [seal] sealed. Throws [PinKeyLost] when the key is gone or the text does not open.
  Future<String> open(String alias, String name, String blob);

  Future<void> delete(String alias);

  /// Every key whose alias starts with [prefix].
  Future<List<String>> aliases(String prefix);
}

/// [KeyWrap] for tests: sealed text is a handle into a map, [lose] drops a key as a faulty
/// Keystore would, and [failCreate] makes new keys fail.
class MemoryKeyWrap implements KeyWrap {
  final Map<String, Map<String, ({String name, String text})>> keys = {};
  bool failCreate = false;
  int created = 0;

  /// How often [open] was asked: each one is a Keystore call on the phone.
  int opened = 0;

  // Across instances, so text sealed by one never equals another's.
  static int _next = 0;

  void lose(String alias) => keys.remove(alias);

  void loseAll() => keys.clear();

  @override
  Future<Map<String, bool>> create(String alias) async {
    if (failCreate) throw const KeyWrapUnavailable('create failed');
    created++;
    keys[alias] = {};
    return {'strongBox': false, 'unlockedRequired': false};
  }

  @override
  Future<String> seal(String alias, String name, String text) async {
    final key = keys[alias];
    if (key == null) throw const PinKeyLost('no key');
    final blob = 'b${_next++}';
    key[blob] = (name: name, text: text);
    return blob;
  }

  @override
  Future<String> open(String alias, String name, String blob) async {
    opened++;
    final sealed = keys[alias]?[blob];
    if (sealed == null || sealed.name != name) throw const PinKeyLost('does not open');
    return sealed.text;
  }

  @override
  Future<void> delete(String alias) async => keys.remove(alias);

  @override
  Future<List<String>> aliases(String prefix) async =>
      keys.keys.where((a) => a.startsWith(prefix)).toList();
}

/// The failure count reported when a sealed wallet's count was removed or replaced with plain
/// text: someone edited the store, so the next try costs LEPIC's longest wait.
const int tamperedPinFailures = 1000;

const String _tag = 'wfe-hw1:';
const String _keyName = 'lepic.pin-key';
const String _pendingName = 'lepic.pin-key-pending';
const String _failuresName = 'lepic.pin-failures';

/// A wallet's store with its PIN entries sealed by [KeyWrap]; every other entry passes through.
///
/// It sees the store's full keys: [walletId] is the wallet's key prefix
/// (`LepicWalletService._storePrefix`), so the PIN key is `<walletId>lepic.pin-key`.
class HardwarePinStore implements SecretStore {
  HardwarePinStore(this._inner, this._wrap, this.walletId);

  final SecretStore _inner;
  final KeyWrap _wrap;
  final String walletId;

  /// One chain of store calls per wallet: a read must never meet a rotation half done. Shared
  /// across instances, since the service builds a new one per call.
  static final Map<String, Future<void>> _queues = {};

  /// The key the next rotation takes, per wallet, made ahead by [prepareNextKey] in this
  /// process and never used to seal an entry yet. Only such a key is taken: a key merely found
  /// in the Keystore may have sealed an entry that an older copy of the store still holds.
  static final Map<String, ({int gen, Map<String, bool> got})> _spares = {};

  /// The failure count last opened or sealed, per wallet, with the stored text it came from,
  /// so the same text is not opened again (the unlock screen, then LEPIC, read it in turn).
  /// Text that changed is opened again. The count is no secret; the PIN key is never kept.
  static final Map<String, ({String raw, String text})> _counts = {};

  /// Forgets every key made ahead and every text kept (tests: each starts from none).
  @visibleForTesting
  static void forgetKept() {
    _spares.clear();
    _counts.clear();
  }

  String get _key => '$walletId$_keyName';
  String get _pending => '$walletId$_pendingName';
  String get _failures => '$walletId$_failuresName';

  bool _guarded(String key) => key == _key || key == _pending || key == _failures;

  /// Keystore aliases of this wallet start with this; the key generation follows.
  String get aliasPrefix =>
      'wfe.pinwrap.${sha256.convert(utf8.encode(walletId)).toString().substring(0, 24)}.';

  String _alias(int gen) => '$aliasPrefix$gen';

  Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _queues[walletId] ?? Future<void>.value();
    final result = previous.then((_) async {
      try {
        return await action();
      } on PinKeyLost {
        // The count kept would hide it from the next read, which must say it again.
        _counts.remove(walletId);
        rethrow;
      }
    });
    _queues[walletId] = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<String?> read(String key) =>
      _guarded(key) ? _serial(() => _read(key)) : _inner.read(key);

  @override
  Future<void> write(String key, String value) =>
      _guarded(key) ? _serial(() => _write(key, value)) : _inner.write(key, value);

  @override
  Future<void> delete(String key) =>
      _guarded(key) ? _serial(() => _delete(key)) : _inner.delete(key);

  /// Whether the PIN key is sealed by the Keystore: the migration happened.
  Future<bool> isSealed() => _serial(() async => _parse(await _inner.read(_key)) != null);

  /// Makes the key the next PIN attempt rotates to, while the user is still typing: on a phone
  /// with StrongBox, making a key is the slowest Keystore step of an attempt. Nothing is sealed
  /// under it until that attempt, so an older copy of the store opens with it no more than
  /// before. A wallet without a PIN key gets none; a Keystore that cannot make one now leaves
  /// it to the attempt, as before.
  Future<void> prepareNextKey() => _serial(() async {
    if (_spares.containsKey(walletId) || await _inner.read(_key) == null) return;
    try {
      final gen = await _lastGen(await _aliasesOrEmpty()) + 1;
      _spares[walletId] = (gen: gen, got: await _wrap.create(_alias(gen)));
    } on Object catch (error) {
      logInfo('vault', 'next PIN key not made ahead (${error.runtimeType})');
    }
  });

  static ({int gen, String blob})? _parse(String? raw) {
    if (raw == null || !raw.startsWith(_tag)) return null;
    final rest = raw.substring(_tag.length);
    final colon = rest.indexOf(':');
    final gen = colon < 0 ? null : int.tryParse(rest.substring(0, colon));
    // Tagged but unreadable: no key opens it, the same as a lost one.
    if (gen == null) throw const PinKeyLost('damaged entry');
    return (gen: gen, blob: rest.substring(colon + 1));
  }

  Future<bool> _sealedWallet() async => _parse(await _inner.read(_key)) != null;

  Future<String?> _read(String key) async {
    final raw = await _inner.read(key);
    final sealed = _parse(raw);
    if (sealed != null) {
      final known = key == _failures ? _counts[walletId] : null;
      if (known != null && known.raw == raw) return known.text;
      final text = await _wrap.open(_alias(sealed.gen), key, sealed.blob);
      if (key == _failures) _counts[walletId] = (raw: raw!, text: text);
      return text;
    }
    // A count gone, or plain text beside a sealed PIN key, was put there by hand.
    if (key != _key && await _sealedWallet()) {
      return key == _failures ? '$tamperedPinFailures' : null;
    }
    return raw;
  }

  /// The one key generation every present entry is sealed under, or null when an entry is
  /// plain (an older app's) or they differ (a rotation was cut short).
  Future<int?> _currentGen() async {
    int? gen;
    for (final key in [_key, _pending, _failures]) {
      final raw = await _inner.read(key);
      if (raw == null) continue;
      final sealed = _parse(raw);
      if (sealed == null || (gen != null && gen != sealed.gen)) return null;
      gen = sealed.gen;
    }
    return gen;
  }

  Future<void> _write(String key, String value) async {
    // A higher count goes under a new key, so no older copy of the store opens again.
    final count = key == _failures ? int.tryParse(value.trim()) : null;
    if (count != null && count > 0) return _rotate(key, value);
    final gen = await _currentGen();
    if (gen == null) return _rotate(key, value);
    await _writeSealed(key, '$_tag$gen:${await _wrap.seal(_alias(gen), key, value)}', value);
  }

  /// Writes [raw], the sealed text of [text], to [key], and keeps what the reads may skip.
  Future<void> _writeSealed(String key, String raw, String text) async {
    _forget(key);
    await _inner.write(key, raw);
    if (key == _failures) _counts[walletId] = (raw: raw, text: text);
  }

  /// Drops what is kept of [key]'s text before it changes.
  void _forget(String key) {
    if (key == _failures) _counts.remove(walletId);
  }

  Future<void> _delete(String key) async {
    _forget(key);
    if (key == _key) {
      // The wallet's PIN is forgotten: its Keystore keys go with it.
      _spares.remove(walletId);
      await _inner.delete(key);
      for (final alias in await _wrap.aliases(aliasPrefix)) {
        await _wrap.delete(alias);
      }
      return;
    }
    // Once sealed, a count of zero is stored, never left out: a missing count reads as edited.
    if (key == _failures && await _inner.read(_key) != null) return _write(key, '0');
    await _inner.delete(key);
  }

  /// Seals every PIN entry, with [key] set to [value], under a new Keystore key, then deletes
  /// the older keys. The PIN key is written last, so until it is sealed the store reads as an
  /// older app's; entries name their key, so a cut-short rotation still opens.
  Future<void> _rotate(String key, String value) async {
    final wasSealed = await _sealedWallet();
    final values = <String, String?>{
      for (final k in [_failures, _pending, _key]) k: k == key ? value : await _read(k),
    };
    values[_failures] ??= '0';
    final spare = _spares.remove(walletId);
    final existing = await _aliasesOrEmpty();
    final next = await _lastGen(existing, except: spare?.gen) + 1;

    // Every entry sealed under [gen], before any is written.
    Future<Map<String, String>> sealAll(int gen) async => {
      for (final MapEntry(key: k, value: v) in values.entries)
        if (v != null) k: '$_tag$gen:${await _wrap.seal(_alias(gen), k, v)}',
    };

    Map<String, bool>? got;
    Map<String, String>? sealed;
    if (spare != null && spare.gen == next) {
      // The key made ahead; one that no longer seals is replaced as if there were none.
      try {
        sealed = await sealAll(next);
        got = spare.got;
      } on Object catch (error) {
        logInfo('vault', 'key made ahead does not seal (${error.runtimeType}); making another');
        await _wrap.delete(_alias(next));
      }
    }
    if (sealed == null) {
      try {
        got = await _wrap.create(_alias(next));
      } on KeyWrapUnavailable catch (error) {
        if (wasSealed) rethrow;
        // A Keystore that makes no key at all: the entries stay as an older app kept them
        // rather than the wallet not opening.
        logWarn('vault', 'Keystore made no key (${error.code}); PIN key stays in the store');
        _forget(key);
        return _inner.write(key, value);
      }
      sealed = await sealAll(next);
    }
    // The count first and the PIN key last, in the order of [values].
    for (final MapEntry(key: k, value: raw) in sealed.entries) {
      await _writeSealed(k, raw, values[k]!);
    }
    for (final alias in existing) {
      if (alias != _alias(next)) await _wrap.delete(alias);
    }
    if (!wasSealed && values[_key] != null) {
      logInfo(
        'vault',
        'PIN key now held by the Keystore'
            '${got?['strongBox'] == true ? ' (StrongBox)' : ''}'
            '${got?['unlockedRequired'] == true ? ', unlocked device only' : ''}',
      );
    }
  }

  /// The highest key generation an entry is sealed under or a Keystore alias in [aliases]
  /// names, leaving out [except] (a key made ahead), or 0.
  Future<int> _lastGen(List<String> aliases, {int? except}) async {
    var gen = 0;
    for (final k in [_failures, _pending, _key]) {
      final sealed = _parse(await _inner.read(k));
      if (sealed != null && sealed.gen > gen) gen = sealed.gen;
    }
    for (final alias in aliases) {
      final n = int.tryParse(alias.substring(aliasPrefix.length)) ?? 0;
      if (n != except && n > gen) gen = n;
    }
    return gen;
  }

  Future<List<String>> _aliasesOrEmpty() async {
    try {
      return await _wrap.aliases(aliasPrefix);
    } on KeyWrapUnavailable {
      return const [];
    }
  }
}
