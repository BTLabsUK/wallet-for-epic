// SPDX-License-Identifier: Apache-2.0
import 'package:flutter_test/flutter_test.dart';

/// Pumps frames, letting real time pass between them, until [done] or [limit] of real time.
///
/// For work that fake time does not move: assets read from disk, an isolate, the engine drawing
/// an image. On a loaded machine that work takes seconds, so a loop of a fixed count of short
/// waits fails there now and then; this one ends as soon as [done] holds, and the expect after
/// it still fails when the work never finishes.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration step = Duration.zero,
  Duration limit = const Duration(seconds: 30),
}) async {
  final clock = Stopwatch()..start();
  while (!done() && clock.elapsed < limit) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(step);
  }
}
