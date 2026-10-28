// SPDX-License-Identifier: Apache-2.0
// Test helper: signs BT Labs envelopes the way the Python tool does.
// Self-contained; vendor it into a test/ folder next to btlabs_public.dart.
import 'dart:convert';

import 'package:epic_wallet/src/btlabs_public.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Loads an Ed25519 key from a PKCS#8 PEM (the 32-byte seed is the last 32
/// bytes of the DER).
Future<SimpleKeyPair> testKeyFromPem(String pem) {
  final body = pem.split('\n').where((l) => l.isNotEmpty && !l.startsWith('-----')).join();
  final der = base64.decode(body);
  return testKeyFromSeed(der.sublist(der.length - 32));
}

/// Ed25519 key pair from a 32-byte seed.
Future<SimpleKeyPair> testKeyFromSeed(List<int> seed) => DartEd25519().newKeyPairFromSeed(seed);

/// The `keyid` of [key].
Future<String> testKeyid(SimpleKeyPair key) async => btlabsKeyid((await key.extractPublicKey()).bytes);

/// Signs [payloadBytes] with every key in [keys] and returns the envelope file
/// text: JSON, 2-space indent, keys `payloadType`, `payload`, `signatures`
/// (each `keyid`, `sig`), trailing newline.
Future<String> signBtlabsEnvelope(
  List<int> payloadBytes,
  List<SimpleKeyPair> keys, {
  String payloadType = btlabsPublicType,
}) async {
  final message = pae(payloadType, payloadBytes);
  final sigs = <Map<String, String>>[];
  for (final k in keys) {
    final sig = await DartEd25519().sign(message, keyPair: k);
    sigs.add({'keyid': await testKeyid(k), 'sig': base64.encode(sig.bytes)});
  }
  final env = {'payloadType': payloadType, 'payload': base64.encode(payloadBytes), 'signatures': sigs};
  return '${const JsonEncoder.withIndent('  ').convert(env)}\n';
}
