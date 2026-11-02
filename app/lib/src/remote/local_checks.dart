// SPDX-License-Identifier: Apache-2.0
/// The recovery phrase check the desktop runs before it asks the wallet core (`desktop/data/phrase_check.dart`).
library;

import 'package:crypto/crypto.dart';

import '../bip39_words.dart';

/// Word positions in the BIP-39 list; a const set iterates in source order.
final Map<String, int> _wordIndex = {
  for (final (i, w) in bip39Words.indexed) w: i,
};

/// True for a BIP-39 English phrase of 12, 15, 18, 21 or 24 words with a correct checksum,
/// as LEPIC's `validate_mnemonic` decides it: words split on whitespace and lowercased.
bool validMnemonic(String phrase) {
  final words = phrase.trim().toLowerCase().split(RegExp(r'\s+'));
  if (words.length < 12 || words.length > 24 || words.length % 3 != 0) {
    return false;
  }
  var bits = BigInt.zero;
  for (final w in words) {
    final i = _wordIndex[w];
    if (i == null) return false;
    bits = (bits << 11) | BigInt.from(i);
  }
  final checksumBits = words.length * 11 ~/ 33;
  final entropyBytes = (words.length * 11 - checksumBits) ~/ 8;
  final entropy = [
    for (var i = entropyBytes - 1; i >= 0; i--)
      ((bits >> (checksumBits + 8 * i)) & BigInt.from(0xff)).toInt(),
  ];
  final expected = sha256.convert(entropy).bytes.first >> (8 - checksumBits);
  final given = (bits & BigInt.from((1 << checksumBits) - 1)).toInt();
  return expected == given;
}
