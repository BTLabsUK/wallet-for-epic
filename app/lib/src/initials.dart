// SPDX-License-Identifier: Apache-2.0
/// The letters on an avatar, for wallets and contacts on the phone and the desktop. Pure Dart.
library;

import 'package:characters/characters.dart';

/// Up to [count] letters for [name], in upper case: the first letter of each of its first
/// words, else the first letters of its one word. Only letters and digits count: brackets,
/// punctuation and emoji split words and never show ("Wallet (epic program)" is "WE").
/// Empty when [name] has none.
///
/// [phone] is the phone's rule for one word: its first letter and its last ("Tom" is "TM"), or
/// its first two when the last is the first again ("Bob" is "BO", "Anna" is "AN"); a one-letter
/// word stays one letter. The desktop keeps the default.
String nameInitials(String name, {int count = 2, bool phone = false}) {
  final words = name
      .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  final String picked;
  if (words.length > 1) {
    picked = words.take(count).map((w) => w.characters.first).join();
  } else if (phone && count == 2) {
    final cs = words.first.characters;
    final first = cs.first.toUpperCase();
    final last = cs.last.toUpperCase();
    picked = cs.length < 2 ? cs.first : (first == last ? cs.take(2).toString() : cs.first + cs.last);
  } else {
    picked = words.first.characters.take(count).toString();
  }
  return picked.toUpperCase();
}
