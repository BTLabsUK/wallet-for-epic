// SPDX-License-Identifier: Apache-2.0
// Audit 26.10.24: the camera plugin leaves pause and resume to the app. Without them a
// scanner sent to the background came back black until the screen was opened again.
import 'dart:ui';

import 'package:epic_wallet/src/ui/scanner_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('releases on leaving the foreground, starts again on return, once each', (
    tester,
  ) async {
    final calls = <String>[];
    final lifecycle = ScannerLifecycle(
      onPause: () async => calls.add('pause'),
      onResume: () async => calls.add('resume'),
    );
    final binding = tester.binding;

    // Not watching yet: nothing happens.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, isEmpty);

    lifecycle.watch();
    // A resume with no pause before it does not start a second camera.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, isEmpty);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(calls, ['pause']);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, ['pause', 'resume']);

    lifecycle.stop();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, ['pause', 'resume']);
  });

  testWidgets('a failed restart is swallowed (the controller keeps the error)', (
    tester,
  ) async {
    final lifecycle = ScannerLifecycle(
      onPause: () async {},
      onResume: () async => throw const ScannerException(ScannerError.failed),
    )..watch();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.takeException(), isNull);
    lifecycle.stop();
  });
}
