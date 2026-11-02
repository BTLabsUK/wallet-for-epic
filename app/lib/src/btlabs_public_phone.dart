// SPDX-License-Identifier: Apache-2.0
/// The phone's copy of BT Labs' signed public file (`[support] signed_file`, btlabs-public
/// FORMAT.md), read as the desktop reads it: once per app run, in the background, verified with
/// the keys the app ships ([btlabsKeyring]), never older than the copy kept, which stays in use
/// when the read is skipped or fails. Only the BT Labs contact's address and the source code link are
/// taken from it ([useSignedDonation], [useSignedLinks]); the bundled ones stay the fallback.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'btlabs_keys.dart';
import 'btlabs_public.dart';
import 'log.dart';
import 'net/http.dart';
import 'network_gate.dart';
import 'secret_store_api.dart';
import 'seed_contacts.dart';
import 'updater.dart' show storedUpdateState, updateStateKey;

/// The last accepted file in the secret store: `{"envelope": …, "state": …}` as JSON text.
const String btlabsPublicKey = 'app.btlabs_public';

/// Takes the kept copy's contact address, then reads the file once. Node only and Kill switch
/// read nothing; with Tor on the read goes through tor or not at all (`httpGet`, which also
/// holds it while tor connects). Never throws, never shows anything: called unawaited at launch.
Future<void> refreshBtlabsPublicAtStart(
  SecretStore store, {
  Future<String?> Function(Uri url)? fetch,
  Keyring? keyring,
  DateTime Function()? now,
  bool Function(String address)? validAddress,
}) async {
  try {
    final signed = btlabsPublicUrl;
    if (signed == null) return; // No signed file in app-config.toml: nothing to read.
    final keys = keyring ?? btlabsKeyring;
    final valid = validAddress ?? looksLikeEpicboxAddress;
    final revoked = await _updateRevoked(store);
    final kept = await _readKept(store);
    if (kept != null) {
      final file = await loadCachedBtlabsPublic(kept.envelope, keyring: keys, state: kept.state, alsoRevoked: revoked);
      if (file != null) {
        useSignedDonation(seedContactsFrom(file, validAddress: valid));
        useSignedLinks(file);
      }
    }
    if (kIsWeb || NetGate.restricted) return;
    final body = await (fetch ?? fetchBtlabsPublic)(Uri.parse(signed));
    if (body == null) return;
    final r = await verifyBtlabsPublic(body, keyring: keys, state: kept?.state, now: (now ?? DateTime.now)().toUtc(), alsoRevoked: revoked);
    switch (r) {
      case Rejected(:final reason):
        logInfo('btlabs', 'btlabs.json not used: ${reason.code}');
      case Accepted(:final manifest, :final state):
        await store.write(btlabsPublicKey, jsonEncode({'envelope': body, 'state': state.toJson()}));
        useSignedDonation(seedContactsFrom(manifest, validAddress: valid));
        useSignedLinks(manifest);
    }
  } on Object catch (e) {
    logInfo('btlabs', 'btlabs.json not read: ${e.runtimeType}');
  }
}

/// The signed file, or null when it did not answer with one (the network mode, Tor, size cap
/// and timeout all end here as null).
Future<String?> fetchBtlabsPublic(Uri url) async {
  try {
    final r = await httpGet(url, timeout: const Duration(seconds: 5), maxBytes: btlabsMaxEnvelopeBytes);
    return r.status == 200 ? r.body : null;
  } on Object {
    return null; // Refused by the network mode or Tor, timed out, over the cap, no answer.
  }
}

/// A mainnet Epicbox address with its server, by shape: `es`, the key, `@host`. The phone has
/// no wallet open at launch to check the key's checksum; the signature is the real check.
bool looksLikeEpicboxAddress(String address) =>
    RegExp(r'^es[1-9A-HJ-NP-Za-km-z]{38,58}@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$').hasMatch(address);

Future<({String envelope, ManifestState state})?> _readKept(SecretStore store) async {
  final text = await store.read(btlabsPublicKey);
  if (text == null) return null;
  final j = jsonDecode(text);
  if (j is! Map || j['envelope'] is! String) return null;
  final state = ManifestState.fromJson(j['state']);
  return state == null ? null : (envelope: j['envelope'] as String, state: state);
}

/// The keys the last accepted update.json revoked: they sign no btlabs.json either.
Future<Set<String>> _updateRevoked(SecretStore store) async {
  try {
    final text = await store.read(updateStateKey);
    return text == null ? const {} : storedUpdateState(jsonDecode(text))?.revoked ?? const {};
  } on Object {
    return const {};
  }
}
