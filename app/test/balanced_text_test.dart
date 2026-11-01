// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/balanced_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

int _lines(String text, TextStyle style, double width) {
  final p = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout(maxWidth: width);
  final n = p.computeLineMetrics().length;
  p.dispose();
  return n;
}

void main() {
  const style = TextStyle(fontSize: 14);
  const text = 'Payments show here. Received coins are spendable after 10 confirmations.';

  test('one line keeps the whole width', () {
    expect(balancedWidth('Nothing yet', style, 400), 400);
  });

  test('a wrapped paragraph narrows to even lines, never more of them', () {
    const max = 420.0;
    final lines = _lines(text, style, max);
    expect(lines, greaterThan(1));
    final w = balancedWidth(text, style, max);
    expect(w, lessThan(max));
    expect(_lines(text, style, w), lines, reason: 'the same line count');
    // Narrower than balanced adds a line: the last line is no orphan.
    expect(_lines(text, style, w - 12), greaterThan(lines));
  });

  testWidgets('BalancedText lays out within its box', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 420, child: BalancedText(text, style: style))),
      ),
    );
    expect(tester.getSize(find.byType(Text)).width, lessThan(420));
    expect(tester.takeException(), isNull);
  });
}
