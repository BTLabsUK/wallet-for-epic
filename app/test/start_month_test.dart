// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/start_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1, 19, 30);

  test('a month starts on its first day, at that day\'s height', () {
    const m = StartMonth(2021, 7);
    expect(m.firstDay, DateTime(2021, 7, 1));
    expect(m.height, mainnetHeightForDate(DateTime(2021, 7, 1)));
    // Earlier than any block of the month: the margin keeps the scan on the safe side.
    expect(m.height < mainnetHeightForDate(DateTime(2021, 7, 2)), isTrue);
    expect(StartMonth.of(DateTime(2021, 7, 31, 23, 59)), m);
  });

  test('offers September 2019 up to this month, nothing later', () {
    expect(firstStartMonth, const StartMonth(2019, 9));
    expect(startYears(now), [2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026]);
    expect(startMonthOffered(const StartMonth(2019, 8), now), isFalse);
    expect(startMonthOffered(const StartMonth(2019, 9), now), isTrue);
    expect(startMonthOffered(const StartMonth(2026, 11), now), isTrue);
    expect(startMonthOffered(const StartMonth(2026, 12), now), isFalse);
    // The first month maps to block 1, the start of the chain.
    expect(firstStartMonth.height, BigInt.one);
  });

  test('opens on the wallet era, or on the chosen month\'s year; never today', () {
    expect(startPickerYear(null), 2019);
    expect(startPickerYear(const StartMonth(2023, 4)), 2023);
  });

  test('warns on this month and the one before', () {
    expect(startMonthRecent(const StartMonth(2026, 11), now), isTrue);
    expect(startMonthRecent(const StartMonth(2026, 10), now), isTrue);
    expect(startMonthRecent(const StartMonth(2026, 9), now), isFalse);
    // Across the new year: January warns for December too.
    final january = DateTime(2027, 1, 5);
    expect(startMonthRecent(const StartMonth(2026, 12), january), isTrue);
    expect(startMonthRecent(const StartMonth(2026, 11), january), isFalse);
  });

  test('orders months', () {
    expect(const StartMonth(2020, 12) < const StartMonth(2021, 1), isTrue);
    expect(const StartMonth(2021, 1).previous, const StartMonth(2020, 12));
    expect(const StartMonth(2021, 3).previous, const StartMonth(2021, 2));
  });
}
