// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The pending pairing row's invite time: a fact, never a ticking age.
void main() {
  setUpAll(() => initializeDateFormatting());
  final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 28, 16, 30);

  test('today: the clock time', () {
    expect(invitedLine(l, DateTime(2026, 10, 28, 14, 5), now), 'Invited 14:05');
  });

  test('yesterday: the word, whatever the hour', () {
    expect(invitedLine(l, DateTime(2026, 10, 27, 23, 59), now), 'Invited yesterday');
    expect(invitedLine(l, DateTime(2026, 10, 27, 0, 1), now), 'Invited yesterday');
  });

  test('older: the day', () {
    expect(invitedLine(l, DateTime(2026, 10, 3, 9, 0), now), 'Invited 3 Oct 2026');
  });

  test('the six languages all say it', () {
    for (final code in ['en', 'de', 'pl', 'ru', 'zh', 'th']) {
      final s = lookupAppLocalizations(Locale(code));
      expect(invitedLine(s, DateTime(2026, 10, 28, 14, 5), now), contains('14:05'));
      expect(invitedLine(s, DateTime(2026, 10, 27), now), isNotEmpty);
      expect(invitedLine(s, DateTime(2026, 10, 3), now), contains('3'));
    }
  });
}
