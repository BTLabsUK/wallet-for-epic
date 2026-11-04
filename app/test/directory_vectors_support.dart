// SPDX-License-Identifier: Apache-2.0
/// The shared directory test vectors (`docs/design/directory-vectors.json`), read from the repo,
/// and the walk both directory wire tests share.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/directory/directory.dart';

/// The vector file, from the app folder tests run in.
Map<String, Object?> loadVectors() =>
    jsonDecode(File('../docs/design/directory-vectors.json').readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> vectorList(Map<String, Object?> v, String key) =>
    [for (final e in v[key]! as List<Object?>) e! as Map<String, Object?>];

Uint8List? hexOrNull(Object? v) => v == null ? null : fromHex(v as String);

/// What a verifier call was asked: key text, domain, message, DER.
String callKey(String keyText, String domain, List<int> message, List<int> der) =>
    '$keyText|$domain|${toHex(message)}|${toHex(der)}';

/// The key text of every vector signer, both networks, by secret key hex.
Map<String, List<String>> signerKeyTexts(Map<String, Object?> v) {
  final k3 = v['k3']! as Map<String, Object?>;
  return {
    for (final s in vectorList(k3, 'sign'))
      s['sk']! as String: [
        epicboxKeyText(fromHex(s['pubkey']! as String), netMainnet),
        epicboxKeyText(fromHex(s['pubkey']! as String), netFloonet),
      ],
  };
}

/// Every signature the vector file lists as valid, as [callKey]s: the `k3.verify` entries that
/// are valid, and the `signatures` of every good card, request and payload.
Set<String> listedValidCalls(Map<String, Object?> v) {
  final texts = signerKeyTexts(v);
  final out = <String>{};
  for (final e in vectorList(v['k3']! as Map<String, Object?>, 'verify')) {
    if (e['valid'] == true) out.add(callKey(e['key_text']! as String, e['domain']! as String, fromHex(e['message']! as String), fromHex(e['der']! as String)));
  }
  for (final group in ['cards', 'payreqs', 'payloads']) {
    for (final e in vectorList(v, group)) {
      for (final s in (e['signatures']! as List<Object?>).cast<Map<String, Object?>>()) {
        for (final text in texts[s['sk']]!) {
          out.add(callKey(text, s['domain']! as String, fromHex(s['message']! as String), fromHex(s['der']! as String)));
        }
      }
    }
  }
  return out;
}

/// The calls one good entry lists, as [callKey]s, for both networks.
Set<String> entryCalls(Map<String, Object?> v, Map<String, Object?> entry) {
  final texts = signerKeyTexts(v);
  return {
    for (final s in (entry['signatures']! as List<Object?>).cast<Map<String, Object?>>())
      for (final text in texts[s['sk']]!)
        callKey(text, s['domain']! as String, fromHex(s['message']! as String), fromHex(s['der']! as String)),
  };
}

/// What a bad entry or a good one is run through: the decoder, then the verification its kind
/// has, with the entry's context. Throws [DirectoryException] as the wallet would.
Future<Object> runEntry(
  String kind,
  Uint8List? raw,
  String? text,
  Map<String, Object?> ctx,
  DirectoryVerifier verifier,
) async {
  final net = ctx['net']! as int;
  final now = ctx['now']! as int;
  switch (kind) {
    case 'card':
      return verifyCard(ListingCard.decode(raw!), net, verifier);
    case 'payreq':
      return verifyPayreq(
        text != null ? Payreq.fromText(text) : Payreq.decode(raw!),
        net: net,
        nowSeconds: now,
        listingKey: hexOrNull(ctx['listing_key']),
        verifier: verifier,
      );
    case 'payload':
      return verifyPayload(
        DirectoryPayload.decode(raw!),
        net: net,
        dkey: hexOrNull(ctx['dkey']),
        bind: hexOrNull(ctx['bind']),
        verifier: verifier,
      );
  }
  throw ArgumentError(kind);
}
