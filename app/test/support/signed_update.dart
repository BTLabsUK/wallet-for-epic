// SPDX-License-Identifier: Apache-2.0
// Test helper: signed update.json envelopes (btlabs-public FORMAT.md §6), signed with the
// committed TEST keys in test/fixtures/btlabs. Never trusted by a release build. In the build
// without Tor (`--dart-define=WFE_TOR=false`) [testUpdatePayload] puts the release in the
// `notor` section, the part that build reads.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:epic_wallet/src/tor_build.dart';

import 'btlabs_sign.dart';

const _fixtures = 'test/fixtures/btlabs';

/// The test keyring: test key A (rank 1) and B (rank 2).
final Keyring testUpdateKeyring = Keyring.parse(
  File('$_fixtures/test-keyring.json').readAsStringSync(),
);

/// Test key A, which signs by default.
Future<SimpleKeyPair> testUpdateKeyA() =>
    testKeyFromPem(File('$_fixtures/test-a.key').readAsStringSync());

/// A key that is in no keyring.
Future<SimpleKeyPair> testUpdateStrangerKey() =>
    testKeyFromSeed(List<int>.filled(32, 7));

/// One APK entry of a manifest.
Map<String, Object?> testApk({
  String abi = 'arm64-v8a',
  int versionCode = 2002,
  String? url,
  String? sha256,
  int size = 10,
}) => {
  'abi': abi,
  'versionCode': versionCode,
  'url': url ?? testApkUrl('app-arm64-v8a-release.apk'),
  'sha256': sha256 ?? 'a' * 64,
  'size': size,
};

/// The payload of a manifest: valid by default, issued 2026-10-01, expiring 2027-04-01. Its
/// [apks] and [desktop] are this build's release: the top-level one with Tor, the `notor`
/// section without ([notor], by default the build's), beside a top-level release the build
/// does not read.
Map<String, Object?> testUpdatePayload({
  String packageName = 'uk.btlabs.epiccash.mobile',
  String versionName = '1.0.1',
  String? notes = 'Fixes',
  List<Map<String, Object?>>? apks,
  Object? desktop,
  int serial = 1790000000,
  String issuedAt = '2026-10-01T00:00:00Z',
  String expiresAt = '2027-04-01T00:00:00Z',
  bool notor = !torBuilt,
}) => {
  'schema': 1,
  'serial': serial,
  'issued_at': issuedAt,
  'expires_at': expiresAt,
  'packageName': packageName,
  'versionName': versionName,
  'notes': ?notes,
  if (!notor) ...{'apks': apks ?? [testApk()], 'desktop': ?desktop},
  if (notor) ...{
    // The release with Tor, newer than anything a test offers: this build must never take it.
    'apks': [testApk(versionCode: 2000000000, url: testApkUrl('app-tor.apk'))],
    'notor': {'apks': apks ?? [testApk()], 'desktop': ?desktop},
  },
};

/// [payload] (JSON-encoded, or the bytes as given) signed into an envelope, by test key A
/// unless [keys] names others.
Future<String> signedUpdate(
  Object payload, {
  List<SimpleKeyPair>? keys,
  String payloadType = walletUpdateType,
}) async {
  final bytes = payload is List<int>
      ? payload
      : utf8.encode(jsonEncode(payload));
  return signBtlabsEnvelope(
    bytes,
    keys ?? [await testUpdateKeyA()],
    payloadType: payloadType,
  );
}

/// A phone APK at [name] in the update download folder, the only place one may be.
String testApkUrl(String name) => '${walletUpdateDownloads!}$name';
