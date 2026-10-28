// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/password_estimate.dart';
import 'package:epic_wallet/src/password_lists.dart';
import 'package:flutter_test/flutter_test.dart';

const _minute = 60.0, _hour = 3600.0, _day = 86400.0, _month = 2629800.0, _year = 31557600.0;

void main() {
  group('crackTimeText', () {
    test('under a minute', () {
      expect(crackTimeText(0), 'under a minute to crack');
      expect(crackTimeText(59.9), 'under a minute to crack');
    });

    test('minutes, rounded to one figure, rolling into hours', () {
      expect(crackTimeText(_minute), 'about 1 minute to crack');
      expect(crackTimeText(2 * _minute), 'about 2 minutes to crack');
      expect(crackTimeText(14 * _minute), 'about 10 minutes to crack');
      expect(crackTimeText(56 * _minute), 'about 1 hour to crack');
    });

    test('hours, days, months', () {
      expect(crackTimeText(_hour), 'about 1 hour to crack');
      expect(crackTimeText(5 * _hour), 'about 5 hours to crack');
      expect(crackTimeText(_day), 'about 1 day to crack');
      expect(crackTimeText(3 * _day), 'about 3 days to crack');
      expect(crackTimeText(_month), 'about 1 month to crack');
      expect(crackTimeText(4 * _month), 'about 4 months to crack');
      expect(crackTimeText(11.8 * _month), 'about 1 year to crack');
    });

    test('years up to 1,000, then more than 1,000', () {
      expect(crackTimeText(_year), 'about 1 year to crack');
      expect(crackTimeText(7 * _year), 'about 7 years to crack');
      expect(crackTimeText(300 * _year), 'about 300 years to crack');
      expect(crackTimeText(960 * _year), 'about 1,000 years to crack');
      expect(crackTimeText(999.9 * _year), 'about 1,000 years to crack');
      expect(crackTimeText(1000 * _year), 'more than 1,000 years to crack');
      expect(crackTimeText(double.infinity), 'more than 1,000 years to crack');
    });
  });

  test('characterCount: 1 character, N characters', () {
    expect(characterCount(1), '1 character');
    expect(characterCount(2), '2 characters');
    expect(characterCount(14), '14 characters');
  });

  test('parseWordLists keeps each list apart and skips unknown kinds', () {
    final lists = parseWordLists('@commonWords\nalpha\nbeta\n@names\nanna\n@wordSequences\nx\n@names\nnowak\n');
    expect(lists, hasLength(3));
    expect(lists.first.values.single, ['alpha', 'beta']);
    expect(lists.map((d) => d.keys.single.name), ['commonWords', 'names', 'names']);
  });

  test('the estimator still runs without word lists', () {
    final e = PasswordEstimator(const {});
    expect(e.crackTime('aaaaaaaa'), 'under a minute to crack');
    expect(e.guesses('x8F!q2Lm#9Rt'), greaterThan(1e10));
  });

  group('with the shipped word lists', () {
    late PasswordEstimator e;
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      e = await loadPasswordEstimator();
    });

    test('common passwords and words of each language are quick', () {
      for (final p in ['password', 'Password1!', 'qwertz123', 'Schmetterling', 'Kochamcie1', 'epiccash2024']) {
        expect(e.crackTime(p), 'under a minute to crack', reason: p);
      }
    });

    test('long passphrases are slow', () {
      expect(e.crackTime('correct horse battery staple'), 'more than 1,000 years to crack');
      expect(e.guesses('Tr0ub4dor&3'), greaterThan(1e9));
    });
  });
}
