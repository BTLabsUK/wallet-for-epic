// SPDX-License-Identifier: Apache-2.0
import 'bip39_words.dart';

/// What is wrong with a recovery phrase the core refused, so the error can say it.
enum PhraseProblemKind {
  /// A word that is not in the BIP-39 list ([PhraseProblem.position]).
  word,

  /// Not 12, 15, 18, 21 or 24 words ([PhraseProblem.count]).
  count,

  /// Every word is in the list and the count is right, but the check bits do not match:
  /// words in the wrong order, or one swapped for another word of the list.
  checksum,
}

class PhraseProblem {
  const PhraseProblem(this.kind, {required this.count, this.position, this.unknown = const []});

  final PhraseProblemKind kind;

  /// Words in the phrase.
  final int count;

  /// The first unknown word's place, from 1.
  final int? position;

  /// Every unknown word's place, from 1, in phrase order; [position] is the first. The words
  /// themselves are never kept: an error names a word by its number only.
  final List<int> unknown;
}

/// The places of the unknown words for the status line: `15, 24`. Never the words.
String wordNumbersText(Iterable<int> positions) => positions.join(', ');

/// Word counts a recovery phrase can have.
const Set<int> phraseWordCounts = {12, 15, 18, 21, 24};

/// Why [phrase] (normalized: lower case, single spaces) is not a valid phrase, in the order a
/// person fixes it: the first unknown word, then the count, then the check bits. Call it only
/// after the core refused the phrase; the core alone decides validity.
PhraseProblem phraseProblem(String phrase) {
  final words = phrase.isEmpty ? const <String>[] : phrase.split(' ');
  final unknown = [
    for (var i = 0; i < words.length; i++)
      if (!bip39Words.contains(words[i])) i + 1,
  ];
  if (unknown.isNotEmpty) {
    return PhraseProblem(PhraseProblemKind.word, count: words.length, position: unknown.first, unknown: unknown);
  }
  if (!phraseWordCounts.contains(words.length)) {
    return PhraseProblem(PhraseProblemKind.count, count: words.length);
  }
  return PhraseProblem(PhraseProblemKind.checksum, count: words.length);
}
