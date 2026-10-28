// SPDX-License-Identifier: Apache-2.0
// cleanInvoiceText: text from another wallet shows as one plain line, with nothing invisible
// or direction-changing left in it.
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zero-width characters and line separators become plain spaces', () {
    for (final c in ['\u200b', '\u200c', '\u200d', '\u2060', '\ufeff', '\u2028', '\u2029']) {
      final code = c.codeUnitAt(0).toRadixString(16);
      expect(cleanInvoiceText('Order${c}42'), 'Order 42', reason: 'U+$code');
      expect(cleanInvoiceText('$c$c'), '', reason: 'U+$code alone leaves nothing');
    }
  });

  test('controls and bidi characters stay removed', () {
    expect(cleanInvoiceText('a\u202eb\u2066c\u200fd\u0007e\u0085f'), 'a b c d e f');
    expect(cleanInvoiceText('two\nlines'), 'two lines');
    expect(cleanInvoiceText(null), '');
  });

  test('a long message is cut to the limit', () {
    expect(cleanInvoiceText('abcdef', max: 4), 'abc…');
  });
}
