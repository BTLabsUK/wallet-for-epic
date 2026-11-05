// SPDX-License-Identifier: Apache-2.0
/// Base58check and the Epicbox key text: the version bytes (`01 00` mainnet, `01 88` floonet) and
/// a 33-byte compressed key, as an address starts with. Pure Dart.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

final BigInt _radix = BigInt.from(58);

/// The first four bytes of SHA-256 twice: the check of base58check and of a payment link.
Uint8List doubleSha256Check(List<int> bytes) =>
    Uint8List.fromList(sha256.convert(sha256.convert(bytes).bytes).bytes.sublist(0, 4));

/// [payload] and its four check bytes as base58.
String base58CheckEncode(List<int> payload) {
  final raw = [...payload, ...doubleSha256Check(payload)];
  var n = BigInt.zero;
  for (final b in raw) {
    n = (n << 8) | BigInt.from(b);
  }
  final out = StringBuffer();
  while (n > BigInt.zero) {
    out.write(_alphabet[(n % _radix).toInt()]);
    n ~/= _radix;
  }
  final zeros = raw.takeWhile((b) => b == 0).length;
  return '${_alphabet[0] * zeros}${out.toString().split('').reversed.join()}';
}

/// The payload of a base58check [text], or null when a character is not base58 or the check
/// fails.
Uint8List? base58CheckDecode(String text) {
  var n = BigInt.zero;
  for (final unit in text.codeUnits) {
    final i = unit < 128 ? _alphabet.indexOf(String.fromCharCode(unit)) : -1;
    if (i < 0) return null;
    n = n * _radix + BigInt.from(i);
  }
  final body = <int>[];
  while (n > BigInt.zero) {
    body.add((n & BigInt.from(0xff)).toInt());
    n >>= 8;
  }
  final zeros = text.codeUnits.takeWhile((c) => c == 0x31).length;
  final raw = [...List<int>.filled(zeros, 0), ...body.reversed];
  if (raw.length < 5) return null;
  final payload = raw.sublist(0, raw.length - 4);
  final check = doubleSha256Check(payload);
  for (var i = 0; i < 4; i++) {
    if (raw[raw.length - 4 + i] != check[i]) return null;
  }
  return Uint8List.fromList(payload);
}

/// `0` mainnet, `1` floonet: the network byte of the wire format.
const int netMainnet = 0;
const int netFloonet = 1;

/// The Epicbox key text of a 33-byte compressed [key] on [net].
String epicboxKeyText(List<int> key, int net) {
  assert(key.length == 33 && (net == netMainnet || net == netFloonet));
  return base58CheckEncode([1, net == netMainnet ? 0x00 : 0x88, ...key]);
}

/// The network and the 33-byte key of an Epicbox key [text], or null: only the length, the
/// version bytes and the compressed-key prefix are checked, not that the point is on the curve.
(int, Uint8List)? parseEpicboxKeyText(String text) {
  final p = base58CheckDecode(text);
  if (p == null || p.length != 35 || p[0] != 1) return null;
  if (p[1] != 0x00 && p[1] != 0x88) return null;
  if (p[2] != 2 && p[2] != 3) return null;
  return (p[1] == 0x00 ? netMainnet : netFloonet, Uint8List.sublistView(p, 2));
}
