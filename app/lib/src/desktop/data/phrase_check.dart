// SPDX-License-Identifier: Apache-2.0
import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;

import '../../bip39_words.dart';

/// The BIP-39 word list in index order (the set keeps its insertion order).
final List<String> bip39List = bip39Words.toList(growable: false);

final Map<String, int> _index = {for (var i = 0; i < bip39List.length; i++) bip39List[i]: i};

/// Whether [words] is a BIP-39 phrase: 12, 15, 18, 21 or 24 words of the list whose check bits
/// (the first `n / 3` bits of the SHA-256 of the entropy) match. This is the same rule the
/// wallet core applies; the mock answers with it so the UI tests see real checksums.
bool bip39PhraseValid(List<String> words) {
  final n = words.length;
  if (n < 12 || n > 24 || n % 3 != 0) return false;
  final bits = StringBuffer();
  for (final w in words) {
    final i = _index[w.trim().toLowerCase()];
    if (i == null) return false;
    bits.write(i.toRadixString(2).padLeft(11, '0'));
  }
  final all = bits.toString();
  final cs = n ~/ 3;
  final ent = all.length - cs;
  final bytes = [for (var i = 0; i < ent; i += 8) int.parse(all.substring(i, i + 8), radix: 2)];
  final hash = sha256.convert(bytes).bytes;
  final check = hash.map((b) => b.toRadixString(2).padLeft(8, '0')).join().substring(0, cs);
  return all.substring(ent) == check;
}

/// The fingerprint earlier builds kept in the wallet list ([WalletEntry.phraseFingerprint]):
/// SHA-256 over a fixed tag and the phrase as the wallet core takes it (lowercase, single
/// spaces), as 64 hex characters. Only compared now, against entries not unlocked since, and
/// never written: the list keeps the core's 32-bit [WalletEntry.walletFingerprint] instead.
String phraseFingerprint(String mnemonic) {
  final normal = mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  return sha256.convert(utf8.encode('epic-wallet phrase fingerprint v1\n$normal')).toString(); // l10n-ok: hash input
}
