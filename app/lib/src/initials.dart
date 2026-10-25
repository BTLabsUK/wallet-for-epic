/// The letters on an avatar, for wallets and contacts on the phone and the desktop. Pure Dart.
library;

import 'package:characters/characters.dart';

/// Up to [count] letters for [name], in upper case: the first letter of each of its first
/// words, else the first letters of its one word. Only letters and digits count: brackets,
/// punctuation and emoji split words and never show ("Wallet (epic program)" is "WE").
/// Empty when [name] has none.
String nameInitials(String name, {int count = 2}) {
  final words = name
      .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  final picked = words.length > 1
      ? words.take(count).map((w) => w.characters.first).join()
      : words.first.characters.take(count).toString();
  return picked.toUpperCase();
}
