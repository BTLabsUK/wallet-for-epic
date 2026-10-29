// SPDX-License-Identifier: Apache-2.0
/// Verifier and parser for the BT Labs signed public file (`btlabs.json`).
///
/// Implements FORMAT.md v1: a DSSE envelope, Ed25519 over the DSSE
/// pre-authentication encoding, a bundled keyring with ranks, and the client
/// rule of section 5. Pure Dart; the only dependency is `package:cryptography`.
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import 'settings_file/host_settings.dart' show hostSettings;

/// The `payloadType` of the BT Labs public file.
const btlabsPublicType = 'application/vnd.btlabs.public+json';

/// The `payloadType` of the wallet release manifest (FORMAT.md section 6).
const walletUpdateType = 'application/vnd.btlabs.wallet-for-epic.update+json';

/// Largest accepted envelope, in UTF-8 bytes.
const btlabsMaxEnvelopeBytes = 65536;

/// Why a file was rejected. [code] is the FORMAT.md reason string.
enum RejectReason {
  tooLarge('too_large'),
  malformed('malformed'),
  wrongType('wrong_type'),
  unknownKey('unknown_key'),
  badSignature('bad_signature'),
  unsupportedSchema('unsupported_schema'),
  expired('expired'),
  rollback('rollback');

  const RejectReason(this.code);

  /// Snake-case reason, as in FORMAT.md section 5.
  final String code;
}

/// One trusted signing key.
class BtlabsKey {
  /// Creates a key. [Keyring.parse] checks that [keyid] matches [publicKey].
  const BtlabsKey({required this.keyid, required this.rank, required this.publicKey, required this.label});

  /// First 16 lowercase hex characters of SHA-256 over [publicKey].
  final String keyid;

  /// Unique, 1 or more. Rank 1 signs today; a key may only revoke lower ranks
  /// when a higher-ranked key signs (FORMAT.md section 2).
  final int rank;

  /// Raw 32-byte Ed25519 public key.
  final List<int> publicKey;

  /// Human label, e.g. `btlabs-2026-a`.
  final String label;
}

/// The bundled set of trusted keys.
class Keyring {
  /// Builds a keyring from already-trusted bundled data (no checks).
  const Keyring(this.keys);

  /// Parses and checks `btlabs-keyring.json`.
  ///
  /// Throws [FormatException] on any invalid entry: bad shape, `keyid` that
  /// does not match the key, duplicate `keyid` or `rank`, bad base64 or length.
  factory Keyring.parse(String json) {
    final Object? root;
    try {
      root = _strictDecode(json);
    } on FormatException {
      throw const FormatException('keyring: not JSON');
    } on _Bad {
      throw const FormatException('keyring: duplicate key');
    }
    if (root is! Map<String, dynamic>) throw const FormatException('keyring: not an object');
    final list = root['keys'];
    if (list is! List || list.isEmpty || list.length > 16) {
      throw const FormatException('keyring: keys must hold 1 to 16 entries');
    }
    final keys = <BtlabsKey>[];
    final ids = <String>{};
    final ranks = <int>{};
    for (final e in list) {
      if (e is! Map<String, dynamic>) throw const FormatException('keyring: entry not an object');
      final keyid = e['keyid'];
      final rank = e['rank'];
      final pub = e['public_key'];
      final label = e['label'];
      if (keyid is! String || !_keyidRe.hasMatch(keyid)) throw const FormatException('keyring: bad keyid');
      if (rank is! int || rank < 1) throw const FormatException('keyring: bad rank');
      if (pub is! String) throw const FormatException('keyring: bad public_key');
      if (label is! String || !_idRe.hasMatch(label)) throw const FormatException('keyring: bad label');
      final raw = _strictBase64(pub);
      if (raw == null || raw.length != 32) throw const FormatException('keyring: public_key must be 32 bytes');
      if (btlabsKeyid(raw) != keyid) {
        throw FormatException('keyring: keyid $keyid does not match its public key');
      }
      if (!ids.add(keyid)) throw FormatException('keyring: duplicate keyid $keyid');
      if (!ranks.add(rank)) throw FormatException('keyring: duplicate rank $rank');
      keys.add(BtlabsKey(keyid: keyid, rank: rank, publicKey: raw, label: label));
    }
    return Keyring(List.unmodifiable(keys));
  }

  /// The keys.
  final List<BtlabsKey> keys;

  /// The key with this [keyid], or null.
  BtlabsKey? byKeyid(String keyid) {
    for (final k in keys) {
      if (k.keyid == keyid) return k;
    }
    return null;
  }
}

/// What the client remembers about the last accepted file.
class ManifestState {
  /// Creates a state.
  const ManifestState({required this.serial, required this.keyid, required this.digest, this.revoked = const {}});

  /// Reads the stored JSON form; null for anything that is not a valid state.
  static ManifestState? fromJson(Object? json) {
    if (json is! Map) return null;
    final serial = json['serial'];
    final keyid = json['keyid'];
    final digest = json['digest'];
    final revoked = json['revoked'];
    if (serial is! int || serial < 1 || serial > _maxSerial) return null;
    if (keyid is! String || !_keyidRe.hasMatch(keyid)) return null;
    if (digest is! String || !_digestRe.hasMatch(digest)) return null;
    if (revoked is! List) return null;
    final set = <String>{};
    for (final r in revoked) {
      if (r is! String || !_keyidRe.hasMatch(r)) return null;
      set.add(r);
    }
    return ManifestState(serial: serial, keyid: keyid, digest: digest, revoked: Set.unmodifiable(set));
  }

  /// Serial of the last accepted file.
  final int serial;

  /// Signer of the last accepted file.
  final String keyid;

  /// Lowercase hex SHA-256 of the last accepted payload bytes.
  final String digest;

  /// Keys revoked for good.
  final Set<String> revoked;

  /// `{"serial","keyid","digest","revoked":[sorted]}`.
  Map<String, Object?> toJson() => {
    'serial': serial,
    'keyid': keyid,
    'digest': digest,
    'revoked': revoked.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is ManifestState &&
      other.serial == serial &&
      other.keyid == keyid &&
      other.digest == digest &&
      other.revoked.length == revoked.length &&
      other.revoked.containsAll(revoked);

  @override
  int get hashCode => Object.hash(serial, keyid, digest, revoked.length);
}

/// Result of [verifyBtlabsPublic] or [verifyWalletUpdate].
sealed class VerifyResult<T> {
  const VerifyResult();
}

/// The file passed every check.
final class Accepted<T> extends VerifyResult<T> {
  /// Creates an accepted result.
  const Accepted({
    required this.manifest,
    required this.state,
    required this.signer,
    required this.unchanged,
    required this.payloadText,
  });

  /// The parsed payload.
  final T manifest;

  /// State to store together with the envelope bytes.
  final ManifestState state;

  /// `keyid` of the signing key.
  final String signer;

  /// True when it is the file already stored (same serial and digest).
  final bool unchanged;

  /// The decoded payload text.
  final String payloadText;
}

/// The file was rejected; keep what you have.
final class Rejected<T> extends VerifyResult<T> {
  /// Creates a rejection.
  const Rejected(this.reason);

  /// Why.
  final RejectReason reason;
}

/// Publisher block.
class BtlPublisher {
  /// Creates a publisher.
  const BtlPublisher({required this.name, required this.legalName, required this.website});

  /// Display name.
  final String name;

  /// Legal name.
  final String legalName;

  /// https URL.
  final String website;
}

/// A donation address.
class BtlDonation {
  /// Creates a donation.
  const BtlDonation({
    required this.id,
    required this.coin,
    required this.network,
    required this.method,
    required this.address,
    required this.name,
    required this.note,
  });

  /// Stable id, e.g. `btlabs`.
  final String id;

  /// Coin id, e.g. `epic`.
  final String coin;

  /// Network, e.g. `mainnet`.
  final String network;

  /// Payment method, e.g. `epicbox`.
  final String method;

  /// Address; the client must validate it for its coin and method.
  final String address;

  /// Display name.
  final String name;

  /// Note.
  final String note;
}

/// An official link.
class BtlLink {
  /// Creates a link.
  const BtlLink({required this.id, required this.kind, required this.label, required this.url});

  /// Id.
  final String id;

  /// One of website, github, telegram, support, status, explorer, docs, social, other.
  final String kind;

  /// Label.
  final String label;

  /// https URL.
  final String url;
}

/// A public node.
class BtlNode {
  /// Creates a node.
  const BtlNode({required this.id, required this.chain, required this.url, required this.operator});

  /// Id.
  final String id;

  /// `mainnet` or `floonet`.
  final String chain;

  /// https URL.
  final String url;

  /// Operator name.
  final String operator;
}

/// An Epicbox relay.
class BtlEpicboxRelay {
  /// Creates a relay.
  const BtlEpicboxRelay({required this.chain, required this.host, this.port = 443, required this.operator});

  /// `mainnet` or `floonet`.
  final String chain;

  /// Lower-case DNS name.
  final String host;

  /// Port, 443 when the file omits it.
  final int port;

  /// Operator name.
  final String operator;
}

/// A service such as a status page or explorer.
class BtlService {
  /// Creates a service.
  const BtlService({required this.id, required this.kind, this.chain, required this.url});

  /// Id.
  final String id;

  /// `status`, `explorer` or `other`.
  final String kind;

  /// Chain, if specific to one.
  final String? chain;

  /// https URL.
  final String url;
}

/// One Tor onion service for a public host (`infrastructure.onions`).
class BtlOnion {
  /// Creates the entry.
  const BtlOnion({
    required this.id,
    required this.service,
    required this.host,
    required this.port,
    required this.onion,
    required this.onionPort,
    required this.tls,
  });

  /// Short id.
  final String id;

  /// `epicbox`, `node`, `support`, `status` or `other`.
  final String service;

  /// The clearnet host the onion stands for.
  final String host;

  /// The clearnet port.
  final int port;

  /// The 56-character v3 address with `.onion`.
  final String onion;

  /// The port on the onion.
  final int onionPort;

  /// True: the onion serves TLS for [host] and the client verifies that host's certificate.
  /// False: plain HTTP, only for public read-only data.
  final bool tls;
}

/// Public infrastructure lists.
class BtlInfrastructure {
  /// Creates the lists.
  const BtlInfrastructure({
    required this.nodes,
    required this.epicboxRelays,
    required this.services,
    this.onions,
  });

  /// The onion list; null when the file has no such field (a built-in copy then stays in use).
  final List<BtlOnion>? onions;

  /// Nodes.
  final List<BtlNode> nodes;

  /// Relays, best first.
  final List<BtlEpicboxRelay> epicboxRelays;

  /// Services.
  final List<BtlService> services;
}

/// A short plain-text notice.
class BtlNotice {
  /// Creates a notice.
  const BtlNotice({
    required this.id,
    required this.severity,
    required this.title,
    required this.text,
    this.url,
    this.startsAt,
    this.endsAt,
    this.projects,
  });

  /// Id.
  final String id;

  /// `info` or `warning`.
  final String severity;

  /// Title.
  final String title;

  /// Plain text.
  final String text;

  /// Optional https URL.
  final String? url;

  /// Show from (UTC), if set.
  final DateTime? startsAt;

  /// Show until (UTC), if set.
  final DateTime? endsAt;

  /// Project ids it is meant for; null = all.
  final List<String>? projects;
}

/// The parsed, validated payload (schema 1).
class BtlabsPublic {
  /// Creates a manifest.
  const BtlabsPublic({
    required this.schema,
    required this.serial,
    required this.issuedAt,
    required this.expiresAt,
    required this.publisher,
    required this.donations,
    required this.links,
    required this.infrastructure,
    required this.notices,
    required this.revokedKeys,
  });

  /// Always 1.
  final int schema;

  /// Strictly increasing serial.
  final int serial;

  /// Issue time (UTC).
  final DateTime issuedAt;

  /// Expiry (UTC).
  final DateTime expiresAt;

  /// Publisher.
  final BtlPublisher publisher;

  /// Donation addresses.
  final List<BtlDonation> donations;

  /// Official links.
  final List<BtlLink> links;

  /// Nodes, relays, services.
  final BtlInfrastructure infrastructure;

  /// Notices (empty when absent).
  final List<BtlNotice> notices;

  /// Revoked keyids named by the file (not yet filtered by rank).
  final List<String> revokedKeys;

  /// Donations matching [coin], [network] and [method].
  Iterable<BtlDonation> donationsFor({required String coin, required String network, required String method}) =>
      donations.where((d) => d.coin == coin && d.network == network && d.method == method);
}

/// One APK of a release.
class WalletApk {
  /// Creates an APK entry.
  const WalletApk({
    required this.abi,
    required this.versionCode,
    required this.url,
    required this.sha256,
    required this.size,
  });

  /// `arm64-v8a`, `armeabi-v7a`, `x86_64` or `universal`.
  final String abi;

  /// Android version code, 1 to 2^31-1.
  final int versionCode;

  /// https download URL.
  final Uri url;

  /// 64 lowercase hex characters. The client still checks it after download.
  final String sha256;

  /// Size in bytes, 1 to 2^32. The client still checks it after download.
  final int size;
}

/// A desktop release entry.
class WalletDesktopEntry {
  /// Creates an entry.
  const WalletDesktopEntry({required this.version, this.page, this.file});

  /// `major.minor.patch`.
  final String version;

  /// Release page under one of the settings file's `updates.pages`, if given.
  final String? page;

  /// The system's release file, if given (a per-system entry only).
  final WalletDesktopFile? file;
}

/// Where a desktop release file may be: the download folder of `app-config.toml`
/// (`updates.downloads`), a plain file name after it; null: no in-app download.
String? get walletDesktopDownloads => hostSettings.updateDownloads;

/// A desktop release file the app may download and install by itself: the Windows setup or
/// the Linux AppImage. Clients before 26.10.9 ignore it.
class WalletDesktopFile {
  /// Creates the entry.
  const WalletDesktopFile({required this.url, required this.sha256, required this.size});

  /// https, under [walletDesktopDownloads].
  final Uri url;

  /// 64 lowercase hex characters. The client still checks it after download.
  final String sha256;

  /// Size in bytes, 1 to 2^32. The client still checks it after download.
  final int size;
}

/// Desktop versions: one for every system, or per system.
class WalletDesktop {
  /// Creates the block. Exactly one of [all] and [bySystem] is set.
  const WalletDesktop({this.all, this.bySystem = const {}});

  /// The entry for every system, if the file gave one.
  final WalletDesktopEntry? all;

  /// Entries by `windows`, `linux` or `macos`.
  final Map<String, WalletDesktopEntry> bySystem;

  /// The entry for [system]: its own, else [all].
  WalletDesktopEntry? forSystem(String system) => bySystem[system] ?? all;
}

/// The parsed, validated wallet release manifest (schema 1).
class WalletUpdate {
  /// Creates a manifest.
  const WalletUpdate({
    required this.schema,
    required this.serial,
    required this.issuedAt,
    required this.expiresAt,
    required this.packageName,
    required this.versionName,
    required this.notes,
    required this.apks,
    required this.desktop,
    required this.revokedKeys,
    this.notor,
  });

  /// Always 1.
  final int schema;

  /// Strictly increasing serial.
  final int serial;

  /// Issue time (UTC).
  final DateTime issuedAt;

  /// Expiry (UTC).
  final DateTime expiresAt;

  /// Android package; the client requires its own.
  final String packageName;

  /// `major.minor.patch`.
  final String versionName;

  /// Plain text, may hold line feeds; empty when absent.
  final String notes;

  /// 1 to 8 APKs with unique ABIs.
  final List<WalletApk> apks;

  /// Desktop versions, if given.
  final WalletDesktop? desktop;

  /// Revoked keyids named by the file (not yet filtered by rank).
  final List<String> revokedKeys;

  /// The release of the builds without Tor, the `notor` section; null when the file has none.
  final WalletNotor? notor;

  /// The release a build reads: the top-level one for the build with Tor ([tor]), the `notor`
  /// section for the build without, whose absence means nothing newer is known (null).
  WalletUpdate? release({required bool tor}) {
    if (tor) return this;
    final n = notor;
    if (n == null) return null;
    return WalletUpdate(
      schema: schema,
      serial: serial,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      packageName: packageName,
      versionName: n.versionName,
      notes: n.notes,
      apks: n.apks,
      desktop: n.desktop,
      revokedKeys: revokedKeys,
    );
  }
}

/// The `notor` section of a release manifest: the release of the builds without Tor. Its
/// version and notes default to the top-level ones.
class WalletNotor {
  /// Creates the section.
  const WalletNotor({required this.versionName, required this.notes, required this.apks, required this.desktop});

  /// `major.minor.patch`.
  final String versionName;

  /// Plain text, may hold line feeds; empty when absent.
  final String notes;

  /// 1 to 8 APKs with unique ABIs.
  final List<WalletApk> apks;

  /// Desktop versions, if given.
  final WalletDesktop? desktop;
}

/// Verifies [envelope] by FORMAT.md section 5, steps 1 to 9. Never throws.
///
/// [state] is the stored state (null on first run). [now] is the clock. [alsoRevoked] are keys
/// another signed file (update.json) revoked: they count as revoked here too.
Future<VerifyResult<BtlabsPublic>> verifyBtlabsPublic(
  String envelope, {
  required Keyring keyring,
  ManifestState? state,
  required DateTime now,
  String payloadType = btlabsPublicType,
  Set<String> alsoRevoked = const {},
}) async {
  try {
    return await _verify<BtlabsPublic>(envelope, keyring, state, now, payloadType, _parsePayload, alsoRevoked);
  } catch (_) {
    return const Rejected<BtlabsPublic>(RejectReason.malformed);
  }
}

/// Verifies a wallet release manifest ([walletUpdateType], FORMAT.md section 6) by
/// section 5, steps 1 to 9. Never throws.
Future<VerifyResult<WalletUpdate>> verifyWalletUpdate(
  String envelope, {
  required Keyring keyring,
  ManifestState? state,
  required DateTime now,
}) async {
  try {
    return await _verify<WalletUpdate>(envelope, keyring, state, now, walletUpdateType, _parseWalletUpdate);
  } catch (_) {
    return const Rejected<WalletUpdate>(RejectReason.malformed);
  }
}

/// Re-checks a stored envelope on load (FORMAT.md section 5, last paragraph).
///
/// The signer must be trusted and not revoked, the signature valid and the
/// payload digest equal to [state].digest. Expiry and serial are not checked. [alsoRevoked]
/// are keys another signed file revoked, as for [verifyBtlabsPublic].
/// Returns null on any failure.
Future<BtlabsPublic?> loadCachedBtlabsPublic(
  String envelope, {
  required Keyring keyring,
  required ManifestState state,
  String payloadType = btlabsPublicType,
  Set<String> alsoRevoked = const {},
}) async {
  try {
    if (utf8.encode(envelope).length > btlabsMaxEnvelopeBytes) return null;
    final env = _parseEnvelope(envelope);
    if (env == null || env.type != payloadType) return null;
    final signer = await _findSigner(env, keyring, {...state.revoked, ...alsoRevoked});
    if (signer is! BtlabsKey) return null;
    if (_hex((await const DartSha256().hash(env.payload)).bytes) != state.digest) return null;
    return _parsePayload(env.payload).manifest;
  } catch (_) {
    return null;
  }
}

Future<VerifyResult<T>> _verify<T>(
  String envelope,
  Keyring keyring,
  ManifestState? state,
  DateTime now,
  String payloadType,
  _Parsed<T> Function(List<int>) parse, [
  Set<String> alsoRevoked = const {},
]) async {
  if (utf8.encode(envelope).length > btlabsMaxEnvelopeBytes) return Rejected<T>(RejectReason.tooLarge);
  final env = _parseEnvelope(envelope);
  if (env == null) return Rejected<T>(RejectReason.malformed);
  if (env.type != payloadType) return Rejected<T>(RejectReason.wrongType);

  final stored = {...?state?.revoked, ...alsoRevoked};
  final signer = await _findSigner(env, keyring, stored);
  if (signer is RejectReason) return Rejected<T>(signer);
  signer as BtlabsKey;

  final _Parsed<T> parsed;
  try {
    parsed = parse(env.payload);
  } on _Unsupported {
    return Rejected<T>(RejectReason.unsupportedSchema);
  } on _Bad {
    return Rejected<T>(RejectReason.malformed);
  }
  if (!parsed.expiresAt.isAfter(now)) return Rejected<T>(RejectReason.expired);

  // Only keys the keyring knows have a rank; others cannot be compared.
  final revoked = {...stored};
  for (final id in parsed.revokedKeys) {
    final k = keyring.byKeyid(id);
    if (k != null && k.rank < signer.rank) revoked.add(id);
  }

  final digest = _hex((await const DartSha256().hash(env.payload)).bytes);
  var unchanged = false;
  // The serial counts only while the stored file's signer is still trusted: a key that was
  // revoked or dropped from the keyring may have pushed it to the maximum.
  if (state != null && keyring.byKeyid(state.keyid) != null && !revoked.contains(state.keyid)) {
    if (parsed.serial < state.serial) return Rejected<T>(RejectReason.rollback);
    if (parsed.serial == state.serial) {
      if (digest != state.digest) return Rejected<T>(RejectReason.rollback);
      unchanged = true;
    }
  }
  final newState = unchanged
      ? ManifestState(
          serial: state!.serial,
          keyid: state.keyid,
          digest: state.digest,
          revoked: Set.unmodifiable(revoked),
        )
      : ManifestState(serial: parsed.serial, keyid: signer.keyid, digest: digest, revoked: Set.unmodifiable(revoked));
  return Accepted<T>(
    manifest: parsed.manifest,
    state: newState,
    signer: signer.keyid,
    unchanged: unchanged,
    payloadText: parsed.text,
  );
}

class _Envelope {
  _Envelope(this.type, this.payload, this.sigs);
  final String type;
  final List<int> payload;
  final List<({String keyid, List<int> sig})> sigs;
}

/// Step 2. Null = malformed.
_Envelope? _parseEnvelope(String text) {
  final Object? root;
  try {
    root = _strictDecode(text);
  } on FormatException {
    return null;
  } on _Bad {
    return null;
  }
  if (root is! Map<String, dynamic>) return null;
  final type = root['payloadType'];
  final payload = root['payload'];
  final sigs = root['signatures'];
  if (type is! String || payload is! String || sigs is! List) return null;
  if (sigs.isEmpty || sigs.length > 8) return null;
  final body = _strictBase64(payload);
  if (body == null) return null;
  final out = <({String keyid, List<int> sig})>[];
  for (final s in sigs) {
    if (s is! Map<String, dynamic>) return null;
    final keyid = s['keyid'];
    final sig = s['sig'];
    if (keyid is! String || sig is! String) return null;
    final raw = _strictBase64(sig);
    if (raw == null || raw.length != 64) return null;
    out.add((keyid: keyid, sig: raw));
  }
  return _Envelope(type, body, out);
}

/// Step 4. Returns the signer key or a [RejectReason]. The signer is the verifying key of the
/// highest rank, never simply the first: a stolen lower-rank key must not be able to mask the
/// revocations in a higher-rank file by putting its own signature in front.
Future<Object> _findSigner(_Envelope env, Keyring keyring, Set<String> revoked) async {
  final message = pae(env.type, env.payload);
  var anyTrusted = false;
  BtlabsKey? best;
  for (final s in env.sigs) {
    final key = keyring.byKeyid(s.keyid);
    if (key == null || revoked.contains(key.keyid)) continue;
    anyTrusted = true;
    final ok = await DartEd25519().verify(
      message,
      signature: Signature(s.sig, publicKey: SimplePublicKey(key.publicKey, type: KeyPairType.ed25519)),
    );
    if (ok && (best == null || key.rank > best.rank)) best = key;
  }
  return best ?? (anyTrusted ? RejectReason.badSignature : RejectReason.unknownKey);
}

/// DSSE pre-authentication encoding of [type] and [body].
List<int> pae(String type, List<int> body) {
  final t = utf8.encode(type);
  return [...ascii.encode('DSSEv1 ${t.length} '), ...t, ...ascii.encode(' ${body.length} '), ...body];
}

/// First 16 lowercase hex characters of SHA-256 over a raw public key.
String btlabsKeyid(List<int> publicKey) => _hex(const DartSha256().hashSync(publicKey).bytes).substring(0, 16);

// ---------------------------------------------------------------- helpers

const _maxSerial = 9007199254740991;
final _keyidRe = RegExp(r'^[0-9a-f]{16}$');
final _digestRe = RegExp(r'^[0-9a-f]{64}$');
final _idRe = RegExp(r'^[a-z0-9][a-z0-9-]{0,31}$');
final _b64Re = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
final _tsRe = RegExp(
  r'^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])Z$',
);
final _hostRe = RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$');
final _addrRe = RegExp(r'^[\x21-\x7e]+$');

// Python's `\s` for str patterns (the reference tool): \x09-\x0d, \x1c-\x20,
// \x85, \xa0, \u1680, \u2000-\u200a, \u2028, \u2029, \u202f, \u205f, \u3000.
// (Dart's own `\s` differs: it has \ufeff, lacks \x1c-\x1f and \x85.)
const _ws = r'\x09-\x0d\x1c-\x20\x85\xa0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000';
final _urlRe = RegExp(r'^https://[a-z0-9.-]+(:[0-9]{1,5})?(/[\x21-\x7e]*)?$');
final _wsRe = RegExp('[$_ws]');
// Never in text: C0/C1 controls and DEL, zero-width and direction marks, line/paragraph
// separators, bidi embeddings and isolates, BOM (FORMAT.md §3).
final _ctrlRe = RegExp(r'[\x00-\x1f\x7f-\x9f\u200b-\u200f\u2028\u2029\u202a-\u202e\u2066-\u2069\ufeff]');

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

/// Standard base64 with padding; no whitespace, no url-safe characters.
List<int>? _strictBase64(String s) {
  if (s.length % 4 != 0 || !_b64Re.hasMatch(s)) return null;
  try {
    final out = base64.decode(s);
    return base64.encode(out) == s ? out : null; // canonical: unused trailing bits are zero
  } on FormatException {
    return null;
  }
}

/// [jsonDecode], but a repeated key in any object throws [_Bad] (jsonDecode
/// would silently keep the last one).
Object? _strictDecode(String text) {
  final v = jsonDecode(text); // syntax is valid from here on
  if (_hasDuplicateKeys(text)) throw const _Bad();
  return v;
}

/// Scans valid JSON text for an object with a repeated key. Keys are compared
/// after unescaping, so `"a"` and `"\u0061"` clash.
bool _hasDuplicateKeys(String s) {
  final keys = <Set<String>?>[]; // one frame per open container; null = array
  var expectKey = false;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x22) {
      var j = i + 1;
      while (s.codeUnitAt(j) != 0x22) {
        j += s.codeUnitAt(j) == 0x5c ? 2 : 1;
      }
      if (expectKey && keys.isNotEmpty && keys.last != null) {
        if (!keys.last!.add(jsonDecode(s.substring(i, j + 1)) as String)) return true;
        expectKey = false;
      }
      i = j;
    } else if (c == 0x7b) {
      keys.add(<String>{});
      expectKey = true;
    } else if (c == 0x5b) {
      keys.add(null);
      expectKey = false;
    } else if (c == 0x7d || c == 0x5d) {
      keys.removeLast();
      expectKey = false;
    } else if (c == 0x2c) {
      expectKey = keys.isNotEmpty && keys.last != null;
    }
  }
  return false;
}

class _Bad implements Exception {
  const _Bad();
}

class _Unsupported implements Exception {
  const _Unsupported();
}

class _Parsed<T> {
  _Parsed(this.manifest, this.text, {required this.serial, required this.expiresAt, required this.revokedKeys});
  final T manifest;
  final String text;
  final int serial;
  final DateTime expiresAt;
  final List<String> revokedKeys;
}

const _linkKinds = ['website', 'github', 'telegram', 'support', 'status', 'explorer', 'docs', 'social', 'other'];

/// Common part of every payload: strict UTF-8 and JSON, schema 1.
({String text, Map<String, dynamic> root}) _decodeRoot(List<int> bytes) {
  final String text;
  final Object? root;
  // No BOM (utf8.decode would drop it silently).
  if (bytes.length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf) throw const _Bad();
  try {
    text = utf8.decode(bytes);
    root = _strictDecode(text);
  } on FormatException {
    throw const _Bad();
  }
  if (root is! Map<String, dynamic>) throw const _Bad();
  final schema = root['schema'];
  if (schema is! int) throw const _Bad(); // 1.0 is a double: malformed
  if (schema != 1) throw const _Unsupported();
  return (text: text, root: root);
}

/// Common header fields: serial, issued_at, expires_at and the expiry window.
({int serial, DateTime issued, DateTime expires}) _header(Map<String, dynamic> root) {
  final serial = _int(root['serial'], 1, _maxSerial);
  final issued = _ts(root['issued_at']);
  final expires = _ts(root['expires_at']);
  if (!expires.isAfter(issued) || expires.difference(issued) > const Duration(days: 400)) throw const _Bad();
  return (serial: serial, issued: issued, expires: expires);
}

List<String> _revokedKeys(Map<String, dynamic> root) => root.containsKey('revoked_keys')
    ? _list(root['revoked_keys'], 16, (e) {
        if (e is! String || !_keyidRe.hasMatch(e)) throw const _Bad();
        return e;
      })
    : <String>[];

_Parsed<BtlabsPublic> _parsePayload(List<int> bytes) {
  final (:text, :root) = _decodeRoot(bytes);

  final (:serial, :issued, :expires) = _header(root);

  final pub = _obj(root['publisher']);
  final publisher = BtlPublisher(
    name: _text(pub['name'], 64),
    legalName: _text(pub['legal_name'], 64),
    website: _url(pub['website']),
  );

  final donations = _list(root['donations'], 32, (e) {
    final o = _obj(e);
    return BtlDonation(
      id: _id(o['id']),
      coin: _id(o['coin']),
      network: _id(o['network']),
      method: _id(o['method']),
      address: _address(o['address']),
      name: _text(o['name'], 64),
      note: _text(o['note'], 280),
    );
  });
  _unique(donations.map((e) => e.id));

  final links = _list(root['links'], 64, (e) {
    final o = _obj(e);
    return BtlLink(
      id: _id(o['id']),
      kind: _enum(o['kind'], _linkKinds),
      label: _text(o['label'], 64),
      url: _url(o['url']),
    );
  });
  _unique(links.map((e) => e.id));

  final infra = _obj(root['infrastructure']);
  final nodes = _list(infra['nodes'], 64, (e) {
    final o = _obj(e);
    return BtlNode(
      id: _id(o['id']),
      chain: _chain(o['chain']),
      url: _url(o['url']),
      operator: _text(o['operator'], 64),
    );
  });
  _unique(nodes.map((e) => e.id));
  final relays = _list(infra['epicbox_relays'], 64, (e) {
    final o = _obj(e);
    return BtlEpicboxRelay(
      chain: _chain(o['chain']),
      host: _host(o['host']),
      port: o.containsKey('port') ? _int(o['port'], 1, 65535) : 443,
      operator: _text(o['operator'], 64),
    );
  });
  final services = _list(infra['services'], 64, (e) {
    final o = _obj(e);
    return BtlService(
      id: _id(o['id']),
      kind: _enum(o['kind'], const ['status', 'explorer', 'other']),
      chain: o.containsKey('chain') ? _chain(o['chain']) : null,
      url: _url(o['url']),
    );
  });
  _unique(services.map((e) => e.id));
  final onions = _onions(infra['onions']);

  final notices = root.containsKey('notices')
      ? _list(root['notices'], 16, (e) {
          final o = _obj(e);
          return BtlNotice(
            id: _id(o['id']),
            severity: _enum(o['severity'], const ['info', 'warning']),
            title: _text(o['title'], 80),
            text: _text(o['text'], 500),
            url: o.containsKey('url') ? _url(o['url']) : null,
            startsAt: o.containsKey('starts_at') ? _ts(o['starts_at']) : null,
            endsAt: o.containsKey('ends_at') ? _ts(o['ends_at']) : null,
            projects: o.containsKey('projects') ? List.unmodifiable(_list(o['projects'], 32, _id)) : null,
          );
        })
      : <BtlNotice>[];
  _unique(notices.map((e) => e.id));

  final revoked = _revokedKeys(root);

  return _Parsed<BtlabsPublic>(
    BtlabsPublic(
      schema: 1,
      serial: serial,
      issuedAt: issued,
      expiresAt: expires,
      publisher: publisher,
      donations: List.unmodifiable(donations),
      links: List.unmodifiable(links),
      infrastructure: BtlInfrastructure(
        nodes: List.unmodifiable(nodes),
        epicboxRelays: List.unmodifiable(relays),
        services: List.unmodifiable(services),
        onions: onions,
      ),
      notices: List.unmodifiable(notices),
      revokedKeys: List.unmodifiable(revoked),
    ),
    text,
    serial: serial,
    expiresAt: expires,
    revokedKeys: revoked,
  );
}

/// The optional onion list. Version 1 clients ignore the field, so a bad entry is skipped (never
/// a reason to reject the file) and a repeated `host:port` keeps the first. Only BT Labs' own
/// hosts ([isBtlabsHost]) may be mapped to an onion; an entry for any other host is skipped.
List<BtlOnion>? _onions(Object? v) {
  if (v is! List) return null;
  final seen = <String>{};
  final out = <BtlOnion>[];
  for (final e in v.take(64)) {
    try {
      final o = _obj(e);
      final tls = o['tls'];
      if (tls is! bool) continue;
      final onion = o['onion'];
      if (onion is! String || !_onionRe.hasMatch(onion)) continue;
      final entry = BtlOnion(
        id: _id(o['id']),
        service: _enum(o['service'], const ['epicbox', 'node', 'support', 'status', 'other']),
        host: _host(o['host']),
        port: _int(o['port'], 1, 65535),
        onion: onion,
        onionPort: _int(o['onion_port'], 1, 65535),
        tls: tls,
      );
      if (!isBtlabsHost(entry.host)) continue;
      if (seen.add('${entry.host}:${entry.port}')) out.add(entry);
    } on _Bad {
      continue;
    }
  }
  return List.unmodifiable(out);
}

final _onionRe = RegExp(r'^[a-z2-7]{56}\.onion$');

/// Whether [host] is one of the settings file's `tor.onion_only_domains` or a name under it
/// (whole labels: `xdomain` and `domain.example.com` are not).
bool isBtlabsHost(String host) {
  final h = host.toLowerCase();
  return hostSettings.torOnionOnlyDomains.any((d) => h == d || h.endsWith('.$d'));
}

Map<String, dynamic> _obj(Object? v) => v is Map<String, dynamic> ? v : throw const _Bad();

List<T> _list<T>(Object? v, int max, T Function(Object?) f) {
  if (v is! List || v.length > max) throw const _Bad();
  return [for (final e in v) f(e)];
}

void _unique(Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw const _Bad();
  }
}

/// JSON integers only: 1.0 is a double in Dart and is rejected.
int _int(Object? v, int min, int max) {
  if (v is! int || v < min || v > max) throw const _Bad();
  return v;
}

String _id(Object? v) => v is String && _idRe.hasMatch(v) ? v : throw const _Bad();

String _enum(Object? v, List<String> allowed) => v is String && allowed.contains(v) ? v : throw const _Bad();

String _chain(Object? v) => _enum(v, const ['mainnet', 'floonet']);

String _url(Object? v) => v is String && v.length <= 512 && _urlRe.hasMatch(v) ? v : throw const _Bad();

String _host(Object? v) => v is String && v.length <= 253 && _hostRe.hasMatch(v) ? v : throw const _Bad();

String _address(Object? v) => v is String && v.length <= 256 && _addrRe.hasMatch(v) ? v : throw const _Bad();

String _text(Object? v, int max) {
  if (v is! String) throw const _Bad();
  final runes = v.runes.toList();
  if (runes.isEmpty || runes.length > max || _ctrlRe.hasMatch(v)) throw const _Bad();
  if (_wsRe.hasMatch(String.fromCharCode(runes.first)) || _wsRe.hasMatch(String.fromCharCode(runes.last))) {
    throw const _Bad();
  }
  return v;
}

DateTime _ts(Object? v) {
  if (v is! String) throw const _Bad();
  final m = _tsRe.firstMatch(v);
  if (m == null) throw const _Bad();
  if (m[1] == '0000') throw const _Bad();
  final mo = int.parse(m[2]!);
  final d = int.parse(m[3]!);
  final t = DateTime.utc(int.parse(m[1]!), mo, d, int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
  if (t.month != mo || t.day != d) throw const _Bad(); // e.g. 2026-02-30 rolls over
  return t;
}

// ------------------------------------------------------- wallet update

final _packageRe = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
final _versionRe = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$');
final _sha256Re = RegExp(r'^[0-9a-f]{64}$');
bool _pageOk(String page) => hostSettings.updatePages.any(page.startsWith);
final _fileNameRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
bool _desktopFileOk(String url) {
  final base = walletDesktopDownloads;
  return base != null && url.startsWith(base) && _fileNameRe.hasMatch(url.substring(base.length));
}
const _abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal'];
const _systems = ['windows', 'linux', 'macos'];

_Parsed<WalletUpdate> _parseWalletUpdate(List<int> bytes) {
  final (:text, :root) = _decodeRoot(bytes);
  final (:serial, :issued, :expires) = _header(root);

  final packageName = root['packageName'];
  if (packageName is! String || !_packageRe.hasMatch(packageName)) throw const _Bad();
  final versionName = _version(root['versionName']);
  final notes = root.containsKey('notes') ? _notes(root['notes']) : '';

  final apks = _apks(root['apks']);
  final desktop = root.containsKey('desktop') ? _desktop(root['desktop']) : null;

  // The release of the builds without Tor (FORMAT.md section 6), checked as the top-level one: a
  // bad section rejects the whole file. Clients up to 26.10.22 ignore it.
  WalletNotor? notor;
  if (root.containsKey('notor')) {
    final n = _obj(root['notor']);
    notor = WalletNotor(
      versionName: n.containsKey('versionName') ? _version(n['versionName']) : versionName,
      notes: n.containsKey('notes') ? _notes(n['notes']) : notes,
      apks: _apks(n['apks']),
      desktop: n.containsKey('desktop') ? _desktop(n['desktop']) : null,
    );
  }

  final revoked = _revokedKeys(root);
  return _Parsed<WalletUpdate>(
    WalletUpdate(
      schema: 1,
      serial: serial,
      issuedAt: issued,
      expiresAt: expires,
      packageName: packageName,
      versionName: versionName,
      notes: notes,
      apks: apks,
      desktop: desktop,
      revokedKeys: List.unmodifiable(revoked),
      notor: notor,
    ),
    text,
    serial: serial,
    expiresAt: expires,
    revokedKeys: revoked,
  );
}

/// An `apks` list.
List<WalletApk> _apks(Object? v) {
  final apks = _list(v, 8, (e) {
    final o = _obj(e);
    final sha = o['sha256'];
    if (sha is! String || !_sha256Re.hasMatch(sha)) throw const _Bad();
    return WalletApk(
      abi: _enum(o['abi'], _abis),
      versionCode: _int(o['versionCode'], 1, 2147483647),
      url: Uri.parse(_url(o['url'])),
      sha256: sha,
      size: _int(o['size'], 1, 4294967296),
    );
  });
  if (apks.isEmpty) throw const _Bad();
  _unique(apks.map((e) => e.abi));
  return List.unmodifiable(apks);
}

/// A `desktop` block, one entry for all or one per system.
WalletDesktop _desktop(Object? v) {
  final d = _obj(v);
  if (d.containsKey('version')) return WalletDesktop(all: _desktopEntry(d, perSystem: false));
  if (d.isEmpty || d.keys.any((k) => !_systems.contains(k))) throw const _Bad();
  return WalletDesktop(
    bySystem: Map.unmodifiable({for (final e in d.entries) e.key: _desktopEntry(e.value, perSystem: true)}),
  );
}

String _version(Object? v) => v is String && _versionRe.hasMatch(v) ? v : throw const _Bad();

WalletDesktopEntry _desktopEntry(Object? v, {required bool perSystem}) {
  final o = _obj(v);
  String? page;
  if (o.containsKey('page')) {
    page = _url(o['page']);
    if (!_pageOk(page)) throw const _Bad();
  }
  // The release file: `url`, `sha256` and `size` together or none, in a per-system entry only
  // (one file cannot fit every system).
  WalletDesktopFile? file;
  final given = const ['url', 'sha256', 'size'].where(o.containsKey).length;
  if (given != 0) {
    if (given != 3 || !perSystem) throw const _Bad();
    final url = _url(o['url']);
    if (!_desktopFileOk(url)) throw const _Bad();
    final sha = o['sha256'];
    if (sha is! String || !_sha256Re.hasMatch(sha)) throw const _Bad();
    file = WalletDesktopFile(url: Uri.parse(url), sha256: sha, size: _int(o['size'], 1, 4294967296));
  }
  return WalletDesktopEntry(version: _version(o['version']), page: page, file: file);
}

/// The text rule of section 3, but line feeds are allowed inside; at most 2000 code points.
String _notes(Object? v) {
  if (v is! String) throw const _Bad();
  final runes = v.runes.toList();
  if (runes.isEmpty || runes.length > 2000 || _ctrlRe.hasMatch(v.replaceAll('\n', ''))) throw const _Bad();
  if (_wsRe.hasMatch(String.fromCharCode(runes.first)) || _wsRe.hasMatch(String.fromCharCode(runes.last))) {
    throw const _Bad();
  }
  return v;
}
