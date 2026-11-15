// SPDX-License-Identifier: Apache-2.0
// The phone's phrase error: which word is not a phrase word, a wrong count, or a phrase
// whose check does not match.

import 'package:epic_wallet/src/phrase_problem.dart';
import 'package:flutter_test/flutter_test.dart';

const _twelve = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  test('gives the place of the first word that is not in the list', () {
    final p = phraseProblem('abandon abandom zoo');
    expect(p.kind, PhraseProblemKind.word);
    expect(p.position, 2);
  });

  test('lists every unknown word by place, in phrase order, never the words', () {
    final p = phraseProblem('abandon abandom zoo harbo');
    expect(p.unknown, [2, 4]);
    expect(wordNumbersText(p.unknown), '2, 4');
  });

  test('a wrong count once every word is in the list', () {
    final p = phraseProblem(_twelve.split(' ').take(11).join(' '));
    expect(p.kind, PhraseProblemKind.count);
    expect(p.count, 11);
    expect(phraseProblem('').kind, PhraseProblemKind.count);
  });

  test('the check bits when words and count are right', () {
    // The last word swapped for another list word: the BIP-39 check fails.
    final p = phraseProblem(_twelve.replaceFirst(RegExp(r'about$'), 'abandon'));
    expect(p.kind, PhraseProblemKind.checksum);
    expect(p.count, 12);
  });
}
