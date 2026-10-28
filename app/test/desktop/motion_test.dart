// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/motion.dart';
import 'package:epic_wallet/src/desktop/widgets/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// §0 task 10 / §10.1: ExpandFade opens and closes in the same number of frames, the height is
// monotonic, the fade trails the height by 40 ms, and reduced motion swaps in one frame.

const _step = Duration(milliseconds: 16);
const _body = Key('body');

class _Host extends StatefulWidget {
  const _Host({required this.reduce, this.details = false});
  final bool reduce;
  final bool details;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final body = SizedBox(key: _body, height: 120, child: const Text('body'));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDeskTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: widget.reduce),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(onPressed: () => setState(() => open = !open), child: const Text('toggle')),
            if (widget.details) EDetails(title: 'More', child: body) else ExpandFade(open: open, child: body),
          ],
        ),
      ),
    );
  }
}

double _height(WidgetTester t) => t.getSize(find.byType(ExpandFade)).height;

double _opacity(WidgetTester t) =>
    t.widget<FadeTransition>(find.descendant(of: find.byType(ExpandFade), matching: find.byType(FadeTransition))).opacity.value;

/// Pumps 16 ms frames until the height stops changing; returns the heights seen (one per frame).
Future<List<double>> _settle(WidgetTester t) async {
  final seen = <double>[_height(t)];
  for (var i = 0; i < 60; i++) {
    await t.pump(_step);
    final h = _height(t);
    if (h == seen.last) break;
    seen.add(h);
  }
  return seen;
}

void _expectMonotonic(List<double> hs, {required bool up}) {
  for (var i = 1; i < hs.length; i++) {
    expect(up ? hs[i] >= hs[i - 1] : hs[i] <= hs[i - 1], isTrue, reason: 'frame $i of $hs');
  }
}

void main() {
  testWidgets('open and close take the same frames, the fade trails the height', (t) async {
    await t.pumpWidget(const _Host(reduce: false));
    expect(_height(t), 0);
    expect(find.text('body'), findsNothing, reason: 'offstage when closed');

    await t.tap(find.text('toggle'));
    await t.pump();
    final opening = await _settle(t);
    final openFrames = opening.length - 1;
    expect(opening.last, 120);
    _expectMonotonic(opening, up: true);
    expect(openFrames, inInclusiveRange(14, 17), reason: '240 ms / 16 ms ≈ 15 frames');

    await t.tap(find.text('toggle'));
    await t.pump();
    final closing = await _settle(t);
    final closeFrames = closing.length - 1;
    expect(closing.last, 0);
    _expectMonotonic(closing, up: false);
    expect((openFrames - closeFrames).abs(), lessThanOrEqualTo(1), reason: 'open $openFrames vs close $closeFrames');
    expect(find.text('body'), findsNothing, reason: 'offstage again when closed');

    // The stagger: 40 ms in, the height has moved but the content is still invisible.
    await t.tap(find.text('toggle'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    expect(_height(t), greaterThan(0));
    expect(_opacity(t), lessThan(0.01));
    await t.pumpAndSettle();
    expect(_opacity(t), 1);
    // Closing: at 200 ms the content is gone while the height is still shrinking.
    await t.tap(find.text('toggle'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(_opacity(t), lessThan(0.01));
    expect(_height(t), greaterThan(0));
    await t.pumpAndSettle();
    expect(_height(t), 0);
  });

  testWidgets('reduced motion swaps in one frame, both ways', (t) async {
    await t.pumpWidget(const _Host(reduce: true));
    expect(_height(t), 0);
    await t.tap(find.text('toggle'));
    await t.pump();
    expect(_height(t), 120);
    expect(_opacity(t), 1);
    await t.tap(find.text('toggle'));
    await t.pump();
    expect(_height(t), 0);
  });

  testWidgets('EDetails folds out and back through ExpandFade', (t) async {
    await t.pumpWidget(const _Host(reduce: false, details: true));
    expect(find.byType(ExpandFade), findsOneWidget);
    expect(find.text('body'), findsNothing);
    await t.tap(find.text('More'));
    await t.pump();
    final opening = await _settle(t);
    expect(find.text('body'), findsOneWidget);
    await t.tap(find.text('More'));
    await t.pump();
    final closing = await _settle(t);
    expect(opening.last, greaterThan(100));
    expect(closing.last, 0);
    expect((opening.length - closing.length).abs(), lessThanOrEqualTo(1));
  });
}
