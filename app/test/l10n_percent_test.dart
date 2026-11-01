// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one percent form per language: no space in English, a no-break space in German', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));
    expect(percentText(en, 40), '40%');
    expect(percentText(en, 99.6), '100%');
    expect(percentText(en, 99.95, decimals: 1), '100.0%');
    expect(percentText(de, 40), '40\u00a0%');
    expect(percentText(de, 98.5, decimals: 1), '98,5\u00a0%');
    expect(percentText(lookupAppLocalizations(const Locale('zh')), 7), '7%');
  });
}
