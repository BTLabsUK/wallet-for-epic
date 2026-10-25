// Receive's method tabs (PH-1): every label at one size; a label too wide breaks at its " · ".
import 'package:epic_wallet/src/ui/receive_screen.dart' show fitTabLabels;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<({List<String> texts, double size})> _fit(WidgetTester tester, List<String> labels, double width) async {
  late ({List<String> texts, double size}) out;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          out = fitTabLabels(context, labels, width: width, style: const TextStyle(fontSize: 12));
          return const SizedBox();
        },
      ),
    ),
  );
  return out;
}

void main() {
  testWidgets('labels that fit stay on one line at the full size', (tester) async {
    final f = await _fit(tester, ['Epicbox', 'Link', 'Direct · QR', 'Direct · File'], 400);
    expect(f.texts, ['Epicbox', 'Link', 'Direct · QR', 'Direct · File']);
    expect(f.size, 12);
  });

  testWidgets('a label too wide breaks at its " · "; the others keep one line', (tester) async {
    final f = await _fit(tester, ['Epicbox', 'Link', 'Bezpośrednio · QR', 'Bezpośrednio · Plik'], 110);
    expect(f.texts, ['Epicbox', 'Link', 'Bezpośrednio\nQR', 'Bezpośrednio\nPlik']);
  });

  testWidgets('a line that still does not fit makes all of them one smaller size, never one per tab', (tester) async {
    final f = await _fit(tester, ['Epicbox', 'Link', 'Bezpośrednio · QR'], 40);
    expect(f.size, lessThan(12));
    expect(f.size, greaterThan(0));
  });
}
