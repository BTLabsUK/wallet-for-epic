// The phone's phrase error (R22): which word is not a phrase word, a wrong count, or a phrase
// whose check does not match.

import 'package:epic_wallet/src/phrase_problem.dart';
import 'package:flutter_test/flutter_test.dart';

const _twelve = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  test('names the first word that is not in the list, with its place', () {
    final p = phraseProblem('abandon abandom zoo');
    expect(p.kind, PhraseProblemKind.word);
    expect(p.position, 2);
    expect(p.word, 'abandom');
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
