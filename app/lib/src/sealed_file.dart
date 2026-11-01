// SPDX-License-Identifier: Apache-2.0
/// The app's files sealed at rest: a wallet's `wfe_meta.sealed` and each wallet's wrap of the
/// address book's key (`contacts.keys/<walletId>.key`) are sealed by that wallet with LEPIC's
/// `sealAppData` (the `.wfeh` format, under a key from the seed), reached through
/// [AppDataSealer]; only `lepic_wallet_service.dart` talks to LEPIC.
///
/// Every sealed payload starts with one line of JSON, its header, `{kind, walletId, version}`
/// (plus what the kind records), then a line break and the body. The header is checked on open,
/// so one kind of sealed file never opens as another, nor one wallet's file as another's.
///
/// Every write is copy-then-switch: the sealed text goes to `<name>.tmp`, flushed, read back and
/// opened, and only a copy that opens to the same payload is renamed over `<name>`. A crash
/// leaves the old file or the new one, never part of one; a stale `.tmp` is deleted at the
/// next open. Sealed text, keys and payloads are never logged.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Why a sealed file did not open.
enum SealedOpenProblem {
  /// An intact file of another wallet (another recovery phrase).
  foreign,

  /// A file of this wallet that was changed or cut short.
  damaged,

  /// A later format of the sealing or of the header.
  newer,

  /// Not a sealed file, or a sealed file of another kind or another wallet id.
  notOurs,
}

class SealedOpenError implements Exception {
  const SealedOpenError(this.problem);

  final SealedOpenProblem problem;

  @override
  String toString() => 'SealedOpenError(${problem.name})';
}

/// Seals and opens app files for one open wallet (LEPIC's `sealAppData` / `openAppData`).
abstract interface class AppDataSealer {
  Future<Uint8List> seal(Uint8List payload);

  /// Throws [SealedOpenError].
  Future<Uint8List> open(Uint8List file);
}

/// The kinds of sealed file. Never renamed: they are on disk.
const String sealedKindMeta = 'wfe-meta';
const String sealedKindContactsKey = 'wfe-contacts-key';
const String sealedKindContacts = 'wfe-contacts';

/// The header version this app writes; a higher one is read, never rewritten.
const int sealedHeaderVersion = 1;

/// A wallet id fit for a file name and a header: the registry's 32 hex characters or
/// `legacy-<chain>`.
final RegExp sealedWalletIdPattern = RegExp(r'^[A-Za-z0-9-]{1,64}$');

/// The id a wallet's sealed files carry: its registry id, or `legacy-<chain>` for the wallet of
/// a phone and registry wallet 1 (whose [walletId] is null), as the registry names that one.
String sealedWalletId(String? walletId, String chainName) => walletId ?? 'legacy-$chainName';

/// Size and SHA-256 of a plain file the sealed one was made from, so a plain file an older build
/// changed since is noticed and merged in.
class PlainRecord {
  const PlainRecord({required this.size, required this.sha256Hex});

  final int size;
  final String sha256Hex;

  static PlainRecord of(List<int> bytes) =>
      PlainRecord(size: bytes.length, sha256Hex: sha256.convert(bytes).toString());

  /// The record of the file at [path], or null when there is none.
  static Future<PlainRecord?> ofFile(String path) async {
    try {
      return of(await File(path).readAsBytes());
    } on PathNotFoundException {
      return null;
    }
  }

  static PlainRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final size = j['size'], hash = j['sha256'];
    if (size is! int || hash is! String) return null;
    return PlainRecord(size: size, sha256Hex: hash);
  }

  Map<String, Object> toJson() => {'size': size, 'sha256': sha256Hex};

  @override
  bool operator ==(Object other) => other is PlainRecord && other.size == size && other.sha256Hex == sha256Hex;

  @override
  int get hashCode => Object.hash(size, sha256Hex);
}

/// A payload's header and body.
class SealedPayload {
  const SealedPayload({
    required this.kind,
    required this.walletId,
    this.version = sealedHeaderVersion,
    this.plain,
    required this.body,
  });

  final String kind;
  final String walletId;
  final int version;

  /// The plain file this one was made from or last merged, as it was then.
  final PlainRecord? plain;
  final Uint8List body;

  Uint8List encode() {
    final header = utf8.encode(
      jsonEncode({'kind': kind, 'walletId': walletId, 'version': version, 'plain': ?plain?.toJson()}),
    );
    return Uint8List.fromList([...header, 0x0a, ...body]);
  }

  /// Reads [payload] and checks its header is [kind] for [walletId]. A later header version
  /// reads; the caller keeps it read-only. Throws [SealedOpenError] `notOurs` otherwise.
  static SealedPayload decode(Uint8List payload, {required String kind, required String walletId}) {
    final nl = payload.indexOf(0x0a);
    if (nl < 0) throw const SealedOpenError(SealedOpenProblem.notOurs);
    final Object? h;
    try {
      h = jsonDecode(utf8.decode(payload.sublist(0, nl)));
    } on FormatException {
      throw const SealedOpenError(SealedOpenProblem.notOurs);
    }
    if (h is! Map || h['kind'] != kind || h['walletId'] != walletId || h['version'] is! int) {
      throw const SealedOpenError(SealedOpenProblem.notOurs);
    }
    return SealedPayload(
      kind: kind,
      walletId: walletId,
      version: h['version'] as int,
      plain: PlainRecord.fromJson(h['plain']),
      body: Uint8List.sublistView(payload, nl + 1),
    );
  }
}

/// Whether [payload] is one of the app's own sealed files rather than a history file: a
/// history import refuses it.
bool isSealedAppPayload(Uint8List payload) {
  final nl = payload.indexOf(0x0a);
  if (nl < 0) return false;
  try {
    final h = jsonDecode(utf8.decode(payload.sublist(0, nl)));
    return h is Map && const {sealedKindMeta, sealedKindContactsKey, sealedKindContacts}.contains(h['kind']);
  } on FormatException {
    return false;
  }
}

/// Atomic writes and reads of sealed files.
abstract final class SealedFile {
  /// Called at each step of a write with its name (`tmp-written`, `verified`, `switched`), so a
  /// test can stop a write there as a kill would.
  @visibleForTesting
  static void Function(String path, String step)? killPoint;

  static void step(String path, String name) => killPoint?.call(path, name);

  static String tmpOf(String path) => '$path.tmp';

  /// The bytes at [path], or null when there is none.
  static Future<Uint8List?> read(String path) async {
    try {
      return await File(path).readAsBytes();
    } on PathNotFoundException {
      return null;
    }
  }

  /// Deletes a write a crash left behind.
  static Future<void> dropTmp(String path) async {
    try {
      await File(tmpOf(path)).delete();
    } on PathNotFoundException {
      // None.
    }
  }

  /// Writes [bytes] to [path] copy-then-switch: `<path>.tmp`, flushed, owner-only, then
  /// [verify] on what was read back from disk, then renamed over [path]. A [verify] that throws
  /// leaves [path] as it was.
  static Future<void> write(String path, Uint8List bytes, {required Future<void> Function(Uint8List onDisk) verify}) async {
    final tmp = File(tmpOf(path));
    try {
      await tmp.parent.create(recursive: true);
      await tmp.writeAsBytes(bytes, flush: true);
      if (Platform.isLinux || Platform.isMacOS) {
        final r = await Process.run('chmod', ['600', tmp.path]);
        if (r.exitCode != 0) throw FileSystemException('chmod failed', tmp.path);
      }
      step(path, 'tmp-written');
      await verify(await tmp.readAsBytes());
      step(path, 'verified');
      await tmp.rename(path);
      step(path, 'switched');
    } on Object {
      // A stop at a kill point is a crash: leave the disk as a crash would.
      if (killPoint == null) {
        try {
          if (await tmp.exists()) await tmp.delete();
        } on FileSystemException {
          // Left for the next open to delete.
        }
      }
      rethrow;
    }
  }

  /// Seals [payload] with [sealer] and writes it to [path]; the copy on disk must open to the
  /// same payload before it replaces [path].
  static Future<void> writeSealed(String path, AppDataSealer sealer, SealedPayload payload) async {
    final plain = payload.encode();
    final sealed = await sealer.seal(plain);
    await write(path, sealed, verify: (onDisk) async {
      if (!_same(await sealer.open(onDisk), plain)) {
        throw FileSystemException('the sealed copy did not open to what was written', tmpOf(path));
      }
    });
  }

  /// Opens the sealed file at [path] as [kind] for [walletId]: null when there is none.
  static Future<SealedPayload?> readSealed(
    String path,
    AppDataSealer sealer, {
    required String kind,
    required String walletId,
  }) async {
    final bytes = await read(path);
    if (bytes == null) return null;
    return SealedPayload.decode(await sealer.open(bytes), kind: kind, walletId: walletId);
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
