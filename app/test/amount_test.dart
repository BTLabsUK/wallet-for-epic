import 'package:epic_wallet/src/amount.dart';
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
