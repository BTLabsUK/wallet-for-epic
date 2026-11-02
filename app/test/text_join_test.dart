// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/text_join.dart';
import 'package:flutter/painting.dart' show TextSpan, TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a number and its unit never part', () {
    expect(withUnit('12.5', 'EPIC'), '12.5\u00a0EPIC');
  });

  test('one metadata joiner: a no-break space before the dot, none doubled', () {
    expect(metaSeparator, '\u00a0\u00b7 ');
    expect(metaLine(['Link · HTTP', 'Tom']), 'Link · HTTP\u00a0\u00b7 Tom');
    expect(metaLine([' 14:05 ', null, '', '  ', 'Epicbox']), '14:05\u00a0\u00b7 Epicbox');
    expect(metaLine(<String?>[]), '');
    expect(metaLine(['40 s ago', '4.1 MB'], whole: true), '40\u00a0s\u00a0ago\u00a0\u00b7 4.1\u00a0MB');
  });

  test('metaSpans puts the dot between parts only, in its own style', () {
    const dot = TextStyle(fontSize: 1);
    final spans = metaSpans([const TextSpan(text: 'a'), null, const TextSpan(text: ' '), const TextSpan(text: 'b')], dot: dot);
    expect(spans.length, 3);
    expect((spans[1] as TextSpan).text, metaSeparator);
    expect((spans[1] as TextSpan).style, dot);
    expect(metaSpans([null]), isEmpty);
  });

  test('numbers keep the word after them', () {
    expect(keepNumbersWithUnits('about 6 blocks (1 block), 1,586.2321 EPIC.'), 'about 6\u00a0blocks (1\u00a0block), 1,586.2321\u00a0EPIC.');
    expect(keepNumbersWithUnits('Confirmations 0 / 6'), 'Confirmations 0 / 6');
    expect(keepNumbersWithUnits('Осталось 6 блоков'), 'Осталось 6\u00a0блоков');
  });

  test('an estimate keeps its mark', () {
    expect(approxText('5.25\u00a0USD'), '\u2248\u00a05.25\u00a0USD');
  });
}
