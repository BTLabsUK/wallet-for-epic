import 'package:epic_wallet/src/ui/warn_pulse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool amber, {bool reduce = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: WarnPulse(active: amber, color: const Color(0xFFF5A54A), child: const SizedBox(width: 8, height: 8)),
    ),
  ),
);

final Finder _echo = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is WarnEchoPainter);

bool _echoing(WidgetTester tester) => _echo.evaluate().isNotEmpty;

/// The cooldown reads [warnEchoNow]; tests move it with the pumped time.
late DateTime _now;

Future<void> _pump(WidgetTester tester, Duration d) async {
  _now = _now.add(d);
  await tester.pump(d);
}

void _nothingScheduled(WidgetTester tester) {
  expect(tester.hasRunningAnimations, isFalse);
  expect(tester.binding.hasScheduledFrame, isFalse);
}

void main() {
  setUp(() {
    _now = DateTime(2026, 11, 7, 12);
    warnEchoNow = () => _now;
  });
  tearDown(() => warnEchoNow = DateTime.now);

  testWidgets('steady at 14 s, one echo from 15 s, then nothing runs', (tester) async {
    await tester.pumpWidget(_app(true));
    await _pump(tester, const Duration(seconds: 14));
    await _pump(tester, const Duration(seconds: 1) - const Duration(milliseconds: 1));
    expect(_echoing(tester), isFalse);
    // Waiting costs no frame: only the delay timer is pending.
    _nothingScheduled(tester);
    await _pump(tester, const Duration(milliseconds: 1));
    expect(_echoing(tester), isTrue);
    expect(tester.hasRunningAnimations, isTrue);
    // The rings draw outside the dot without changing its layout.
    expect(tester.getSize(find.byType(WarnPulse)), const Size(8, 8));
    await _pump(tester, warnEchoLength ~/ 2);
    expect(_echoing(tester), isTrue);
    await _pump(tester, warnEchoLength ~/ 2 + const Duration(milliseconds: 20));
    await tester.pump();
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
    // Still amber an hour later: still nothing.
    await _pump(tester, const Duration(hours: 1));
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
    await tester.pumpWidget(_app(false));
    await tester.pump();
    expect(_echoing(tester), isFalse);
  });

  testWidgets('green ends it; amber back within the cooldown stays steady, after it echoes again', (tester) async {
    await tester.pumpWidget(_app(true));
    await _pump(tester, const Duration(seconds: 16));
    expect(_echoing(tester), isTrue);
    await tester.pumpWidget(_app(false));
    await _pump(tester, const Duration(seconds: 30));
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
    // Flapping: amber again well inside the cooldown.
    await tester.pumpWidget(_app(true));
    await _pump(tester, const Duration(seconds: 60));
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
    await tester.pumpWidget(_app(false));
    await _pump(tester, warnEchoCooldown);
    // A fresh stretch past the cooldown waits the delay, then echoes once.
    await tester.pumpWidget(_app(true));
    await _pump(tester, const Duration(seconds: 14));
    expect(_echoing(tester), isFalse);
    await _pump(tester, const Duration(seconds: 2));
    expect(_echoing(tester), isTrue);
    await tester.pumpWidget(_app(false));
    await tester.pump();
    _nothingScheduled(tester);
  });

  testWidgets('green in the middle of an echo stops it', (tester) async {
    await tester.pumpWidget(_app(true));
    await _pump(tester, const Duration(seconds: 15) + const Duration(milliseconds: 400));
    expect(_echoing(tester), isTrue);
    await tester.pumpWidget(_app(false));
    await tester.pump();
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
  });

  testWidgets('reduced motion: never echoes', (tester) async {
    await tester.pumpWidget(_app(true, reduce: true));
    await _pump(tester, const Duration(seconds: 40));
    expect(_echoing(tester), isFalse);
    _nothingScheduled(tester);
  });

  testWidgets('the painter draws rings only while the echo runs', (tester) async {
    final progress = AnimationController(vsync: const TestVSync(), duration: warnEchoLength);
    addTearDown(progress.dispose);
    final painter = WarnEchoPainter(progress: progress, color: const Color(0xFFF5A54A));
    expect(painter.shouldRepaint(WarnEchoPainter(progress: progress, color: const Color(0xFFF5A54A))), isFalse);
    expect(painter.shouldRepaint(WarnEchoPainter(progress: progress, color: const Color(0xFF000000))), isTrue);
    // Two rings, the second starting one gap in and ending with the whole echo.
    expect(warnEchoLength, warnEchoRing + warnEchoGap * (warnEchoRings - 1));
  });
}
