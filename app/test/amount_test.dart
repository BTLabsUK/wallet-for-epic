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
        // 2^53 + 1 is above the 21 million parseEpic takes, so read the display back by hand.
        final parts = '${displayEpic(real).replaceAll(',', '')}.'.split('.');
        final shown = BigInt.parse('${parts[0]}${parts[1].padRight(epicDecimals, '0')}');
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
        expect(epicText(englishStrings, big), '1,234,567.1234\u00a0EPIC');
        expect(epicExact(englishStrings, big), '1,234,567.12345678\u00a0EPIC');
        expect(
          shownEpic(englishStrings, big, hidden: false, exact: true),
          '1,234,567.12345678\u00a0EPIC',
        );
        expect(
          shownEpic(englishStrings, big, hidden: true, exact: true),
          hiddenAmount,
        );
      },
    );

    test('each language\'s marks', () {
      expect(epicText(l('de'), big), '1.234.567,1234\u00a0EPIC');
      expect(epicText(l('pl'), big), '1\u00a0234\u00a0567,1234\u00a0EPIC');
      expect(epicText(l('ru'), big), '1\u00a0234\u00a0567,1234\u00a0EPIC');
      expect(epicText(l('zh'), big), '1,234,567.1234\u00a0EPIC');
    });

    test('one formatter per surface, the same on both apps', () {
      final amount = parseEpic('12.508');
      expect(AmountSurface.row.decimals, displayDecimals);
      expect(AmountSurface.exact.decimals, exactDecimals);
      expect(AmountSurface.hero.decimals, displayDecimals);
      expect(surfaceEpic(big, AmountSurface.row), '1,234,567.1234');
      expect(surfaceEpic(big, AmountSurface.exact), '1,234,567.12345678');
      expect(surfaceEpic(big, AmountSurface.hero), '1,234,567.1234');
      expect(epicFor(englishStrings, amount), '12.5080\u00a0EPIC');
      expect(
        epicFor(englishStrings, amount, surface: AmountSurface.exact),
        '12.50800000\u00a0EPIC',
      );
      expect(epicFor(englishStrings, amount, unit: false), '12.5080');
      expect(epicFor(l('de'), amount, surface: AmountSurface.exact), '12,50800000\u00a0EPIC');
    });

    test('signs: plus on request, a true minus always', () {
      final amount = parseEpic('25');
      expect(epicFor(englishStrings, amount, signed: true), '+25.0000\u00a0EPIC');
      expect(epicFor(englishStrings, -amount), '\u221225.0000\u00a0EPIC');
      expect(epicFor(englishStrings, -amount, signed: true, unit: false), '\u221225.0000');
      expect(epicFor(englishStrings, BigInt.zero, signed: true), '0.0000\u00a0EPIC');
      // Cut towards zero, never rounded away from it; what cuts to zero has no sign.
      expect(epicFor(englishStrings, -parseEpic('1.00009999'), unit: false), '\u22121.0000');
      expect(epicFor(englishStrings, -parseEpic('0.00009999'), unit: false), '0.0000');
      expect(epicFor(englishStrings, parseEpic('0.00009999'), signed: true, unit: false), '0.0000');
    });

    test('a short fiat value drops its cents from 1,000, cut off', () {
      const display = (hidden: false, price: 0.5, currency: 'usd');
      String? fiat(String epic, {bool short = true}) =>
          approxFiat(englishStrings, parseEpic(epic), display, short: short);
      expect(fiat('12.5'), '≈\u00a06.25\u00a0USD');
      expect(fiat('1999.98'), '≈\u00a0999.99\u00a0USD');
      expect(fiat('2001.98'), '≈\u00a01,000\u00a0USD');
      expect(fiat('17639999.98'), '≈\u00a08,819,999\u00a0USD');
      expect(fiat('17639999.98', short: false), '≈\u00a08,819,999.99\u00a0USD');
      expect(
        approxFiat(l('de'), parseEpic('2001.98'), display, short: true),
        '≈\u00a01.000\u00a0USD',
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
        BigInt.parse('1234567812345678'),
        maxEpicAtomic,
      ]) {
        expect(parseEpic(formatEpic(value)), value);
      }
    });

    Matcher refused(AmountProblem problem) => throwsA(
      isA<AmountFormatException>().having((e) => e.problem, 'problem', problem),
    );

    // WAL-08: a 64-bit int parser turned 184467440738 EPIC into 0.90448384 EPIC.
    test('a huge amount is refused, never wrapped or cut', () {
      for (final big in [
        '184467440738',
        '184467440738.5',
        '99999999999999999999',
        '18446744073709551616',
        '1${'0' * 400}',
        '21000001',
        '100000000',
      ]) {
        expect(() => parseEpic(big), refused(AmountProblem.tooLarge), reason: big);
      }
    });

    test('the 21 million boundary is exact', () {
      expect(parseEpic('21000000'), maxEpicAtomic);
      expect(parseEpic('21000000.00000000'), maxEpicAtomic);
      expect(parseEpic('020999999.99999999'), maxEpicAtomic - BigInt.one);
      expect(parseEpic('00000000000000000021000000'), maxEpicAtomic);
      expect(() => parseEpic('21000000.00000001'), refused(AmountProblem.tooLarge));
      // Far below 2^53, so the desktop's `toInt()` is exact on the web too.
      expect(maxEpicAtomic < BigInt.two.pow(53), isTrue);
    });

    test('8 decimals are exact, 9 are refused, not rounded', () {
      expect(parseEpic('0.12345678'), atomic(12345678));
      expect(parseEpic('20999999.99999999'), atomic(2099999999999999));
      expect(parseEpic('1.10000000'), atomic(110000000));
      expect(() => parseEpic('0.123456789'), refused(AmountProblem.decimals));
      expect(() => parseEpic('1.000000000'), refused(AmountProblem.decimals));
      expect(() => parseEpic('0,999999999'), refused(AmountProblem.decimals));
    });

    test('garbage, negative and odd separators are refused', () {
      for (final bad in [
        '',
        '   ',
        '.',
        ',',
        '-1',
        '-0.5',
        '+1',
        '−1',
        '1e8',
        'Infinity',
        'NaN',
        '0x10',
        '1.2.3',
        '1,2,3',
        '1.2,3',
        "1'000",
        '1_000',
        '1 000',
        '1 000',
        '１',
        '١',
        '1;5',
        '1..5',
        'EPIC',
        '1 EPIC',
      ]) {
        expect(() => parseEpic(bad), refused(AmountProblem.malformed), reason: bad);
      }
    });

    test('the too-large refusal reads as a field error', () {
      expect(
        () => parseEpic('184467440738'),
        throwsA(
          isA<LocalizedFormatException>().having(
            (e) => e.text(englishStrings),
            'text',
            'That is more EPIC than will ever exist. Check the amount.',
          ),
        ),
      );
    });
  });
}
