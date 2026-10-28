import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  BigInt atomic(int v) => BigInt.from(v);

  group('formatEpic', () {
    test('whole and fractional amounts', () {
      expect(formatEpic(BigInt.zero), '0');
      expect(formatEpic(atomic(100000000)), '1');
      expect(formatEpic(atomic(150000000)), '1.5');
      expect(formatEpic(atomic(1)), '0.00000001');
      expect(formatEpic(atomic(800000)), '0.008');
      expect(formatEpic(atomic(-250000000)), '-2.5');
    });

    test('keeps minDecimals digits', () {
      expect(formatEpic(atomic(100000000), minDecimals: 2), '1.00');
      expect(formatEpic(atomic(123456789), minDecimals: 2), '1.23456789');
    });

    test('exact above the double precision limit', () {
      final big = BigInt.parse('123456789012345678901');
      expect(formatEpic(big), '1234567890123.45678901');
    });
  });

  group('headlineEpic', () {
    BigInt epic(String text) => parseEpic(text);

    test('two decimals always, grouped, cut off and never rounded up', () {
      for (final (exact, shown) in [
        ('0', '0.00'),
        ('0.00000001', '0.00'),
        ('0.5', '0.50'),
        ('12.5', '12.50'),
        ('1234.5678', '1,234.56'),
        ('1234.56781234', '1,234.56'),
        ('999.99999999', '999.99'),
        ('20999999.99999999', '20,999,999.99'),
      ]) {
        expect(headlineEpic(epic(exact)), shown, reason: exact);
      }
      // A negative amount is cut towards zero too.
      expect(headlineEpic(-epic('2.567')), '-2.56');
    });
  });

  group('displayEpic', () {
    BigInt epic(String text) => parseEpic(text);

    test('the brief\'s matrix', () {
      for (final (exact, shown) in [
        ('0', '0'),
        ('0.00000001', '0.00000001'),
        ('0.5', '0.5'),
        ('1', '1'),
        ('12.5', '12.5'),
        ('99.99999999', '99.99999999'),
        ('999.99999999', '999.9999999'),
        ('1000', '1,000'),
        ('123456.789', '123,456.789'),
        ('1234567.12345678', '1,234,567.123'),
        // Epic's supply approaches 21 million; a wallet must still show more.
        ('20999999.99999999', '20,999,999.99'),
        ('21000000', '21,000,000'),
        ('99999999.99999999', '99,999,999.99'),
        ('123456789012.34567891', '123,456,789,012.34'),
      ]) {
        expect(displayEpic(epic(exact)), shown, reason: exact);
      }
    });

    test('decimals fall as the whole part grows, never below 2', () {
      expect(
        [for (var digits = 1; digits <= 10; digits++) '1'.padRight(digits, '0')]
            .map((whole) => displayDecimals(epic(whole))),
        [8, 8, 7, 6, 5, 4, 3, 2, 2, 2],
      );
      expect(displayDecimals(epic('0.1')), 8);
    });

    test('cuts digits off and never rounds up', () {
      // Each would round up to the next shown digit.
      expect(displayEpic(epic('999.99999999')), '999.9999999');
      expect(displayEpic(epic('9999.99999999')), '9,999.999999');
      expect(displayEpic(epic('99999.99999999')), '99,999.99999');
      expect(displayEpic(epic('999999.99999999')), '999,999.9999');
      expect(displayEpic(epic('9999999.99999999')), '9,999,999.999');
      expect(displayEpic(epic('20999999.99999999')), '20,999,999.99');
      // Not past a whole either.
      expect(displayEpic(epic('99999999.999')), '99,999,999.99');
      // Shown never exceeds the real amount, and drops less than one shown digit.
      for (final text in [
        '0.12345678',
        '987.65432199',
        '54321.98765432',
        '7654321.99999999',
        '20999999.98765432',
        '31415926.53589793',
      ]) {
        final real = epic(text);
        final shown = parseEpic(displayEpic(real).replaceAll(',', ''));
        expect(shown, lessThanOrEqualTo(real), reason: text);
        final step = BigInt.from(10).pow(epicDecimals - displayDecimals(real));
        expect(real - shown, lessThan(step), reason: text);
      }
    });

    test('trailing zeros go after the cut', () {
      expect(displayEpic(epic('1234567.10000009')), '1,234,567.1');
      expect(displayEpic(epic('1234567.00099999')), '1,234,567');
    });

    test('a negative amount is cut towards zero', () {
      expect(displayEpic(-epic('1234567.12345678')), '-1,234,567.123');
      expect(displayEpic(-epic('0.00000001')), '-0.00000001');
    });

    test('exact above the double precision limit', () {
      // 2^53 + 1 atomic units, where a double would already be off.
      final big = BigInt.two.pow(53) + BigInt.one;
      expect(displayEpic(big), '90,071,992.54');
      expect(formatEpic(big), '90071992.54740993');
    });
  });

  group('amount text', () {
    final big = parseEpic('1234567.12345678');
    AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

    test(
      'epicText follows the display rule, epicExact keeps every decimal',
      () {
        expect(epicText(englishStrings, big), '1,234,567.123 EPIC');
        expect(epicExact(englishStrings, big), '1,234,567.12345678 EPIC');
        expect(
          shownEpic(englishStrings, big, hidden: false, exact: true),
          '1,234,567.12345678 EPIC',
        );
        expect(
          shownEpic(englishStrings, big, hidden: true, exact: true),
          hiddenAmount,
        );
      },
    );

    test('each language\'s marks', () {
      expect(epicText(l('de'), big), '1.234.567,123 EPIC');
      expect(epicText(l('pl'), big), '1\u00a0234\u00a0567,123 EPIC');
      expect(epicText(l('ru'), big), '1\u00a0234\u00a0567,123 EPIC');
      expect(epicText(l('zh'), big), '1,234,567.123 EPIC');
    });

    test('a short fiat value drops its cents from 1,000, cut off', () {
      const display = (hidden: false, price: 0.5, currency: 'usd');
      String? fiat(String epic, {bool short = true}) =>
          approxFiat(englishStrings, parseEpic(epic), display, short: short);
      expect(fiat('12.5'), '≈ 6.25 USD');
      expect(fiat('1999.98'), '≈ 999.99 USD');
      expect(fiat('2001.98'), '≈ 1,000 USD');
      expect(fiat('17639999.98'), '≈ 8,819,999 USD');
      expect(fiat('17639999.98', short: false), '≈ 8,819,999.99 USD');
      expect(
        approxFiat(l('de'), parseEpic('2001.98'), display, short: true),
        '≈ 1.000 USD',
      );
    });
  });

  group('parseEpic', () {
    test('valid input', () {
      expect(parseEpic('1'), atomic(100000000));
      expect(parseEpic('1.5'), atomic(150000000));
      expect(parseEpic('1,5'), atomic(150000000));
      expect(parseEpic('.5'), atomic(50000000));
      expect(parseEpic('2.'), atomic(200000000));
      expect(parseEpic(' 0.00000001 '), atomic(1));
      expect(parseEpic('0'), BigInt.zero);
    });

    test('rejects malformed input', () {
      for (final bad in [
        '',
        ' ',
        '.',
        '-1',
        '1e5',
        'abc',
        '1.2.3',
        '1 000',
        '0.000000001',
      ]) {
        expect(
          () => parseEpic(bad),
          throwsFormatException,
          reason: 'input "$bad"',
        );
      }
    });

    test('round-trips with formatEpic', () {
      for (final value in [
        BigInt.zero,
        atomic(1),
        atomic(99999999),
        atomic(100000001),
        BigInt.parse('987654321987654321'),
      ]) {
        expect(parseEpic(formatEpic(value)), value);
      }
    });
  });
}
