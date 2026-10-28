// SPDX-License-Identifier: Apache-2.0
// Test helper: signed btlabs.json files for the seed-contact tests, made with the test keys.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:cryptography/cryptography.dart';

import 'btlabs_sign.dart';

const _fixtures = 'test/fixtures/btlabs';

/// The test keyring (keys A, rank 1, and B, rank 2).
Keyring testKeyring() => Keyring.parse(File('$_fixtures/test-keyring.json').readAsStringSync());

Future<SimpleKeyPair> testKeyA() async => testKeyFromPem(File('$_fixtures/test-a.key').readAsStringSync());

/// A donation entry as the file holds it.
Map<String, Object?> donation(
  String id,
  String address, {
  String coin = 'epic',
  String network = 'mainnet',
  String method = 'epicbox',
  String name = 'BT Labs',
  String note = 'Donations support development of this wallet.',
}) => {'id': id, 'coin': coin, 'network': network, 'method': method, 'address': address, 'name': name, 'note': note};

/// A payload with [donations], serial and dates as given.
List<int> publicPayload(List<Map<String, Object?>> donations, {int serial = 1, String? issuedAt, String? expiresAt, List<Object?>? onions}) => utf8.encode(
  jsonEncode({
    'schema': 1,
    'serial': serial,
    'issued_at': issuedAt ?? _ts(DateTime.now().toUtc().subtract(const Duration(days: 1))),
    'expires_at': expiresAt ?? _ts(DateTime.now().toUtc().add(const Duration(days: 200))),
    'publisher': {'name': 'BT Labs', 'legal_name': 'BT Labs Ltd', 'website': 'https://btlabs.uk'},
    'donations': donations,
    'links': <Object?>[],
    'infrastructure': {
      'nodes': <Object?>[],
      'epicbox_relays': <Object?>[],
      'services': <Object?>[],
      'onions': ?onions,
    },
    'notices': <Object?>[],
  }),
);

/// A signed envelope over [donations]; [keys] default to test key A.
Future<String> signedPublicFile(
  List<Map<String, Object?>> donations, {
  int serial = 1,
  String? issuedAt,
  String? expiresAt,
  List<SimpleKeyPair>? keys,
  List<Object?>? onions,
}) async =>
    signBtlabsEnvelope(publicPayload(donations, serial: serial, issuedAt: issuedAt, expiresAt: expiresAt, onions: onions), keys ?? [await testKeyA()]);

/// FORMAT.md timestamp: UTC, whole seconds, `Z`.
String _ts(DateTime t) => '${t.toIso8601String().split('.').first}Z';

/// [t] as a file timestamp.
String fileTime(DateTime t) => _ts(t.toUtc());

/// Parses [envelope] to a manifest, as the wallet does (no state).
Future<BtlabsPublic> verified(String envelope) async {
  final r = await verifyBtlabsPublic(envelope, keyring: testKeyring(), now: DateTime.utc(2026, 11));
  if (r is Rejected<BtlabsPublic>) throw StateError("rejected: ${r.reason.code}");
  return (r as Accepted<BtlabsPublic>).manifest;
}

/// An onion entry as the file holds it.
Map<String, Object?> onionEntry(
  String host, {
  String id = 'x',
  String service = 'other',
  int port = 443,
  String? onion,
  int onionPort = 443,
  bool tls = true,
}) => {
  'id': id,
  'service': service,
  'host': host,
  'port': port,
  'onion': onion ?? '${'a' * 56}.onion',
  'onion_port': onionPort,
  'tls': tls,
};
