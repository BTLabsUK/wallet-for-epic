import 'package:epic_wallet/src/ui/warn_pulse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool amber, {bool reduce = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: WarnPulse(active: amber, child: const SizedBox(width: 8, height: 8)),
  ),
);

double _opacity(WidgetTester tester) {
  final fade = find.byType(FadeTransition);
  return fade.evaluate().isEmpty ? 1 : tester.widget<FadeTransition>(fade).opacity.value;
}

void main() {
  testWidgets('no pulse at 14 s, pulses from 15 s', (tester) async {
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(seconds: 14));
    await tester.pump(const Duration(seconds: 1) - const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(warnPulseHalf);
    expect(tester.hasRunningAnimations, isTrue);
    expect(_opacity(tester), lessThan(1));
    expect(_opacity(tester), greaterThanOrEqualTo(warnPulseLow));
    await tester.pumpWidget(_app(false));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 1);
  });

  testWidgets('green ends it and a fresh amber waits 15 s again', (tester) async {
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(seconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(_app(false));
    await tester.pump(const Duration(seconds: 30));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(seconds: 14));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(_app(false));
  });

  testWidgets('reduced motion: never pulses', (tester) async {
    await tester.pumpWidget(_app(true, reduce: true));
    await tester.pump(const Duration(seconds: 40));
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacity(tester), 1);
  });
}
