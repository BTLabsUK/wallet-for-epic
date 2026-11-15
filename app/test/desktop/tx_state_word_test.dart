// SPDX-License-Identifier: Apache-2.0
// Activity list with the detail pane open (bug 4): the state word of a row is never broken in
// the middle of a word, however narrow its cell.
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const word = 'Confirming, 5 of 6';
  const style = TextStyle(fontSize: 13);

  Future<RenderParagraph> pumpIn(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: const TxStateWord(word, style: style)),
          ),
        ),
      ),
    );
    return tester.renderObject<RenderParagraph>(find.byType(RichText));
  }

  testWidgets('a cell narrower than the longest word keeps every word whole and fits the cell', (tester) async {
    for (final width in [200.0, 90.0, 60.0, 40.0]) {
      final p = await pumpIn(tester, width);
      expect(p.didExceedMaxLines, isFalse, reason: 'a word broken in the middle needs more than two lines at $width');
      final boxes = p.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 11));
      expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: '"Confirming," sits on one line at $width');
      expect(tester.getSize(find.byType(TxStateWord)).width, lessThanOrEqualTo(width), reason: 'it fits the cell at $width');
      expect(tester.getRect(find.byType(RichText)).right, lessThanOrEqualTo(width + 0.5), reason: 'nothing is drawn outside the cell at $width');
    }
  });

  testWidgets('a cell with room wraps between words as before and does not scale', (tester) async {
    final p = await pumpIn(tester, 400);
    expect(p.size.height, lessThan(20), reason: 'one line');
    expect(find.byType(FittedBox), findsNothing);
  });
}
