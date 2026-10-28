/// Problem reports, sealed to the developer and posted to the support intake. The same format as
/// the Electron GUI's "Report a problem" (its `src/shared/supportBundle.js`), so the developer's
/// `support:list` and `support:fetch` tools read reports from both apps:
///
/// - The report is JSON `{v: 1, created, app, description, contact, files, dropped}`, gzipped.
/// - It is sealed to the developer's X25519 public key: each report gets a fresh key pair, and
///   the key is HKDF-SHA256(X25519(ephemeral, developer), salt = ephemeral || developer,
///   info = `epic-gui-support v1`). Layout: `EPICSUP1` (8) | key id (8) | ephemeral public
///   key (32) | nonce (12) | AES-256-GCM ciphertext | tag (16), the 60 header bytes being the
///   additional data. The app holds only the public key, so it cannot open what it sent.
/// - `POST https://support.btlabs.uk/v1/report` with
///   `{"v": 2, "bundle": "<base64>", "app": "<version>"}`; the intake answers `{"ok": true, "id": "<8 chars>"}`.
///
/// What goes in is cleaned first (`support_clean.dart`), and [SupportReport.text] shows all of
/// it, so the preview is exactly what is sealed.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';

import 'net/http.dart';

/// The developer's public key (the GUI's `src/shared/supportKey.js`), and its id: the first 8
/// bytes of its SHA-256. Rotating it means shipping a new key with the next release.
const String supportPublicKey = 'YM65I1OjO76rTaLGRAbLux2+rIObMMd+3v092QufNSU=';
const String supportKeyId = 'd9749febd701c2fe';

/// Where reports go. A build can point elsewhere with `--dart-define=WFE_SUPPORT_URL=...`.
const String supportUrlSetting = String.fromEnvironment(
  'WFE_SUPPORT_URL',
  defaultValue: 'https://support.btlabs.uk/v1/report',
);

/// The intake's limits: a sealed report, the tail kept of each file, the description, the
/// contact.
const int maxSupportBundle = 2 * 1024 * 1024;
const int maxSupportFileText = 512 * 1024;
const int maxSupportDescription = 2000;
const int maxSupportContact = 100;

/// How long a send may take before it counts as failed.
const Duration supportTimeout = Duration(seconds: 20);

final Uint8List _magic = ascii.encode('EPICSUP1');
final Uint8List _info = ascii.encode('epic-gui-support v1');
const int _header = 8 + 8 + 32 + 12;
const int _tag = 16;

/// One attached text: `app/wfe.log`, or the facts about the app.
class SupportFile {
  const SupportFile({required this.name, required this.text, this.cut = false});

  final String name;
  final String text;

  /// Only the newest part of it is here.
  final bool cut;

  int get bytes => utf8.encode(text).length;

  Map<String, Object> toJson() => {
    'name': name,
    'bytes': bytes,
    'text': text,
    'cut': cut,
  };
}

/// The newest [max] bytes of [text], from a whole line, with a note when the start was left
/// out (the GUI's `tailText`).
SupportFile tailFile(String name, String text, {int max = maxSupportFileText}) {
  final bytes = utf8.encode(text);
  if (bytes.length <= max) return SupportFile(name: name, text: text);
  var rest = utf8.decode(bytes.sublist(bytes.length - max), allowMalformed: true);
  final nl = rest.indexOf('\n');
  if (nl >= 0 && nl < rest.length - 1) rest = rest.substring(nl + 1);
  rest = rest.replaceFirst(RegExp('^�+'), '');
  return SupportFile(name: name, text: '[… earlier lines left out …]\n$rest', cut: true);
}

// No control characters in a line of user text (the GUI's `one`).
String _oneLine(String text, int max) {
  final clean = text
      .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '')
      .trim();
  return clean.length > max ? clean.substring(0, max) : clean;
}

/// A report as it is sealed. [description] is already cleaned; [app] holds short facts (the
/// GUI's decrypt tool shows `version`, `ui` and `platform`); [files] are already cleaned and cut.
class SupportReport {
  SupportReport({
    required this.created,
    required String description,
    String contact = '',
    required this.app,
    this.files = const [],
  }) : description = _oneLine(description, maxSupportDescription),
       contact = _oneLine(contact, maxSupportContact);

  final DateTime created;
  final String description;
  final String contact;
  final Map<String, String> app;
  final List<SupportFile> files;

  Map<String, Object> toJson({List<String> dropped = const []}) => {
    'v': 1,
    'created': _iso(created),
    'app': app,
    'description': description,
    'contact': contact,
    'files': [for (final f in files) f.toJson()],
    'dropped': dropped,
  };

  /// Everything the report carries, as the preview shows it.
  String get text {
    final out = StringBuffer()
      ..writeln('Created: ${_iso(created)}')
      ..writeln('Contact: ${contact.isEmpty ? 'none' : contact}')
      ..writeln();
    for (final MapEntry(:key, :value) in app.entries) {
      out.writeln('$key: $value');
    }
    out
      ..writeln()
      ..writeln('Description:')
      ..writeln(description);
    if (files.isEmpty) {
      out
        ..writeln()
        ..writeln('Logs: none attached');
    }
    for (final f in files) {
      out
        ..writeln()
        ..writeln('== ${f.name} ==')
        ..write(f.text);
      if (!f.text.endsWith('\n')) out.writeln();
    }
    return out.toString();
  }
}

/// UTC to the millisecond, as JavaScript's `toISOString`.
String _iso(DateTime at) => DateTime.fromMillisecondsSinceEpoch(
  at.millisecondsSinceEpoch,
  isUtc: true,
).toIso8601String();

/// Raw bytes of a base64 X25519 public key.
Uint8List rawSupportKey(String base64Key) {
  final raw = base64.decode(base64Key);
  if (raw.length != 32) throw ArgumentError('An X25519 public key is 32 bytes.');
  return raw;
}

/// The first 8 bytes of SHA-256 of the key.
Uint8List supportKeyIdOf(List<int> rawPublicKey) =>
    Uint8List.fromList(hash.sha256.convert(rawPublicKey).bytes.sublist(0, 8));

Future<SecretKey> _derive(
  SimpleKeyPair own,
  List<int> peer,
  List<int> ephemeral,
  List<int> developer,
) async {
  final shared = await X25519().sharedSecretKey(
    keyPair: own,
    remotePublicKey: SimplePublicKey(peer, type: KeyPairType.x25519),
  );
  final bytes = await shared.extractBytes();
  // A low-order key gives an all-zero secret: refuse it rather than encrypt to nobody.
  if (bytes.every((b) => b == 0)) throw ArgumentError('Bad public key.');
  return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
    secretKey: SecretKey(bytes),
    nonce: [...ephemeral, ...developer],
    info: _info,
  );
}

/// [plain] sealed to [developerKey] (base64 raw X25519).
Future<Uint8List> sealSupport(List<int> plain, String developerKey) async {
  final dev = rawSupportKey(developerKey);
  final eph = await X25519().newKeyPair();
  final ephRaw = (await eph.extractPublicKey()).bytes;
  final key = await _derive(eph, dev, ephRaw, dev);
  final aes = AesGcm.with256bits();
  final nonce = aes.newNonce();
  final header = Uint8List.fromList([..._magic, ...supportKeyIdOf(dev), ...ephRaw, ...nonce]);
  final box = await aes.encrypt(plain, secretKey: key, nonce: nonce, aad: header);
  return Uint8List.fromList([...header, ...box.cipherText, ...box.mac.bytes]);
}

/// Opens a sealed report with the developer's raw 32-byte private key. For tests: the app never
/// holds a private key.
Future<Uint8List> openSupport(List<int> sealed, List<int> privateKey) async {
  if (sealed.length < _header + _tag ||
      !_same(sealed.sublist(0, 8), _magic)) {
    throw const FormatException('Not a support bundle.');
  }
  final dev = await X25519().newKeyPairFromSeed(privateKey);
  final devRaw = (await dev.extractPublicKey()).bytes;
  if (!_same(sealed.sublist(8, 16), supportKeyIdOf(devRaw))) {
    throw const FormatException('The bundle is for another key.');
  }
  final ephRaw = sealed.sublist(16, 48);
  final key = await _derive(dev, ephRaw, ephRaw, devRaw);
  final plain = await AesGcm.with256bits().decrypt(
    SecretBox(
      sealed.sublist(_header, sealed.length - _tag),
      nonce: sealed.sublist(48, _header),
      mac: Mac(sealed.sublist(sealed.length - _tag)),
    ),
    secretKey: key,
    aad: sealed.sublist(0, _header),
  );
  return Uint8List.fromList(plain);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// [report] gzipped and sealed, within [max]: when too big, the last files are dropped and
/// named in `dropped` (the GUI's `buildBundle`).
Future<Uint8List> buildSupportBundle(
  SupportReport report, {
  String publicKey = supportPublicKey,
  int max = maxSupportBundle,
}) async {
  var files = report.files;
  final dropped = <String>[];
  while (true) {
    final kept = SupportReport(
      created: report.created,
      description: report.description,
      contact: report.contact,
      app: report.app,
      files: files,
    );
    final json = utf8.encode(jsonEncode(kept.toJson(dropped: dropped)));
    final bundle = await sealSupport(gzip.encode(json), publicKey);
    if (bundle.length <= max) return bundle;
    if (files.isEmpty) throw StateError('Report too big.');
    dropped.insert(0, files.last.name);
    files = files.sublist(0, files.length - 1);
  }
}

/// The report inside a sealed bundle. For tests.
Future<Map<String, dynamic>> openSupportBundle(
  List<int> sealed,
  List<int> privateKey,
) async {
  final json = utf8.decode(gzip.decode(await openSupport(sealed, privateKey)));
  return jsonDecode(json) as Map<String, dynamic>;
}

/// The app version as the intake's readable `app` field: `wfe-0.1.0` (1 to 24 of `0-9A-Za-z.+-`).
String supportAppTag(String version) {
  final v = version.split(' ').first.replaceAll(RegExp(r'[^0-9A-Za-z.+-]'), '');
  final tag = 'wfe-${v.isEmpty ? 'unknown' : v}';
  return tag.length > 24 ? tag.substring(0, 24) : tag;
}

/// The request body the intake takes. [appVersion] must be 1 to 24 of `0-9A-Za-z.+-`.
String supportRequestBody(List<int> bundle, String appVersion) =>
    jsonEncode({'v': 2, 'bundle': base64.encode(bundle), 'app': appVersion});

/// Why a report was not taken.
enum SupportFailure { offline, timeout, tooBig, rate, server }

class SupportSendError implements Exception {
  const SupportSendError(this.reason, [this.status]);

  final SupportFailure reason;
  final int? status;

  /// Short English, for the desktop and the log.
  String get text => switch (reason) {
    SupportFailure.offline => 'The support server could not be reached. Check the connection.',
    SupportFailure.timeout => 'The support server did not answer in time.',
    SupportFailure.tooBig => 'The report is too big. Turn off Attach logs and try again.',
    SupportFailure.rate => 'Too many reports from this connection. Try again later.',
    SupportFailure.server => 'The support server refused the report${status == null ? '' : ' ($status)'}.',
  };

  @override
  String toString() => text;
}

/// The report id from the intake's answer, or throws [SupportSendError] (the GUI's
/// `intakeResult`).
String supportReportId(int status, String body) {
  Object? json;
  try {
    json = jsonDecode(body);
  } catch (_) {}
  if (status == 200 && json is Map && json['ok'] == true) {
    final id = '${json['id'] ?? ''}';
    return id.length > 40 ? id.substring(0, 40) : id;
  }
  if (status == 413) throw SupportSendError(SupportFailure.tooBig, status);
  if (status == 429) throw SupportSendError(SupportFailure.rate, status);
  throw SupportSendError(SupportFailure.server, status);
}

/// Seals and posts reports. Tests replace it.
abstract interface class SupportSender {
  /// Posts [report] and answers the report id. Throws [SupportSendError].
  Future<String> send(SupportReport report, {required String appVersion});
}

class HttpSupportSender implements SupportSender {
  HttpSupportSender(this.url, {this.timeout = supportTimeout});

  final Uri url;
  final Duration timeout;

  @override
  Future<String> send(SupportReport report, {required String appVersion}) async {
    final bundle = await buildSupportBundle(report);
    try {
      final reply = await httpPost(
        url,
        body: utf8.encode(supportRequestBody(bundle, appVersion)),
        contentType: 'application/json',
        timeout: timeout,
      );
      return supportReportId(reply.status, reply.body);
    } on TimeoutException {
      throw const SupportSendError(SupportFailure.timeout);
    } on NetError {
      throw const SupportSendError(SupportFailure.offline);
    }
  }
}
