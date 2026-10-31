// SPDX-License-Identifier: Apache-2.0
import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;

import '../../bip39_words.dart';
import '../../remote/local_checks.dart' show validMnemonic;

/// The BIP-39 word list in index order (the set keeps its insertion order).
final List<String> bip39List = bip39Words.toList(growable: false);

/// Whether [words], one word per slot, is a BIP-39 phrase: 12, 15, 18, 21 or 24 words of the
/// list whose check bits match ([validMnemonic], the rule the wallet core applies). A blank slot
/// or one holding a space is refused: joined, it would shift the words after it. The mock
/// answers with it so the UI tests see real checksums.
bool bip39PhraseValid(List<String> words) {
  for (final w in words) {
    final word = w.trim();
    if (word.isEmpty || word.contains(RegExp(r'\s'))) return false;
  }
  return validMnemonic(words.join(' '));
}

/// The fingerprint earlier builds kept in the wallet list ([WalletEntry.phraseFingerprint]):
/// SHA-256 over a fixed tag and the phrase as the wallet core takes it (lowercase, single
/// spaces), as 64 hex characters. Only compared now, against entries not unlocked since, and
/// never written: the list keeps the core's 32-bit [WalletEntry.walletFingerprint] instead.
String phraseFingerprint(String mnemonic) {
  final normal = mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  return sha256.convert(utf8.encode('epic-wallet phrase fingerprint v1\n$normal')).toString(); // l10n-ok: hash input
}
