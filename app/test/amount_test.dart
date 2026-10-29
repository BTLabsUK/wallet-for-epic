// SPDX-License-Identifier: Apache-2.0
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

  group('displayEpic: the one display rule', () {
    BigInt epic(String text) => parseEpic(text);

    test('four decimals always, grouped, cut off and never rounded up', () {
      for (final (exact, shown) in [
        ('0', '0.0000'),
        ('0.00000001', '0.0000'),
        ('0.5', '0.5000'),
        ('12.5', '12.5000'),
        ('1234.5678', '1,234.5678'),
        ('1234.56781234', '1,234.5678'),
        ('999.99999999', '999.9999'),
        ('1234567.12345678', '1,234,567.1234'),
        ('20999999.99999999', '20,999,999.9999'),
      ]) {
        expect(displayEpic(epic(exact)), shown, reason: exact);
      }
      // A negative amount is cut towards zero too.
      expect(displayEpic(-epic('2.56789')), '-2.5678');
      // A negative amount that cuts to nothing is nothing: no sign on a zero.
      expect(displayEpic(-epic('0.00000001')), '0.0000');
    });

    test('never shows more than the wallet holds', () {
      for (final real in [
        epic('0.00009999'),
        epic('1234567.12345678'),
        BigInt.two.pow(53) + BigInt.one,
      ]) {
        final shown = parseEpic(displayEpic(real).replaceAll(',', ''));
        expect(shown <= real, isTrue, reason: formatEpic(real));
        expect(real - shown < BigInt.from(10000), isTrue, reason: formatEpic(real));
      }
    });

    test('exact above the double precision limit', () {
      // 2^53 + 1 atomic units, where a double would already be off.
      final big = BigInt.two.pow(53) + BigInt.one;
      expect(displayEpic(big), '90,071,992.5474');
      expect(exactEpic(big), '90,071,992.54740993');
      expect(formatEpic(big), '90071992.54740993');
    });

    test('exactEpic writes every decimal out; cutEpic any count', () {
      expect(exactEpic(epic('12.5')), '12.50000000');
      expect(exactEpic(epic('1234.56781234')), '1,234.56781234');
      expect(exactEpic(BigInt.zero), '0.00000000');
      expect(cutEpic(epic('1.23456789'), 2), '1.23');
      expect(cutEpic(epic('1.23456789'), 0), '1');
      expect(cutEpic(epic('1.23456789'), 8), '1.23456789');
    });
  });

  group('amount text', () {
    final big = parseEpic('1234567.12345678');
    AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

    test(
      'epicText follows the display rule, epicExact writes every decimal out',
      () {
        expect(epicText(englishStrings, big), '1,234,567.1234 EPIC');
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
      expect(epicText(l('de'), big), '1.234.567,1234 EPIC');
      expect(epicText(l('pl'), big), '1\u00a0234\u00a0567,1234 EPIC');
      expect(epicText(l('ru'), big), '1\u00a0234\u00a0567,1234 EPIC');
      expect(epicText(l('zh'), big), '1,234,567.1234 EPIC');
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
