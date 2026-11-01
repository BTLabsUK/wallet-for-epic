// SPDX-License-Identifier: Apache-2.0
import 'bip39_words.dart';

/// What is wrong with a recovery phrase the core refused, so the error can say it.
enum PhraseProblemKind {
  /// A word that is not in the BIP-39 list ([PhraseProblem.position], [PhraseProblem.word]).
  word,

  /// Not 12, 15, 18, 21 or 24 words ([PhraseProblem.count]).
  count,

  /// Every word is in the list and the count is right, but the check bits do not match:
  /// words in the wrong order, or one swapped for another word of the list.
  checksum,
}

class PhraseProblem {
  const PhraseProblem(this.kind, {required this.count, this.position, this.word, this.unknown = const []});

  final PhraseProblemKind kind;

  /// Words in the phrase.
  final int count;

  /// The first unknown word's place, from 1.
  final int? position;
  final String? word;

  /// Every unknown word as (place from 1, word), in phrase order; [position]/[word] are its first.
  final List<(int, String)> unknown;
}

/// The unknown words for the status line: `harbo (24), wandr (15)`, one entry per word, in place order.
String unknownWordsText(Iterable<(int, String)> unknown) => unknown.map((u) => '${u.$2} (${u.$1})').join(', ');

/// Word counts a recovery phrase can have.
const Set<int> phraseWordCounts = {12, 15, 18, 21, 24};

/// Why [phrase] (normalized: lower case, single spaces) is not a valid phrase, in the order a
/// person fixes it: the first unknown word, then the count, then the check bits. Call it only
/// after the core refused the phrase; the core alone decides validity.
PhraseProblem phraseProblem(String phrase) {
  final words = phrase.isEmpty ? const <String>[] : phrase.split(' ');
  final unknown = <(int, String)>[
    for (var i = 0; i < words.length; i++)
      if (!bip39Words.contains(words[i])) (i + 1, words[i]),
  ];
  if (unknown.isNotEmpty) {
    return PhraseProblem(
      PhraseProblemKind.word,
      count: words.length,
      position: unknown.first.$1,
      word: unknown.first.$2,
      unknown: unknown,
    );
  }
  if (!phraseWordCounts.contains(words.length)) {
    return PhraseProblem(PhraseProblemKind.count, count: words.length);
  }
  return PhraseProblem(PhraseProblemKind.checksum, count: words.length);
}
