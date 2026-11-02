// SPDX-License-Identifier: Apache-2.0
// The connection grace (item 11): on at start for its length, off after it, on again when the
// app comes back to the front (resumed after hidden or paused), not after a focus change alone.
import 'package:epic_wallet/src/connection_grace.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer grace(Duration length) {
    final c = ProviderContainer(overrides: [connectionGraceLengthProvider.overrideWithValue(length)]);
    addTearDown(c.dispose);
    return c;
  }

  void life(AppLifecycleState s) => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(s);

  testWidgets('runs from the start for its length, then ends', (tester) async {
    final c = grace(const Duration(seconds: 20));
    expect(c.read(connectionGraceProvider), isTrue);
    await tester.pump(const Duration(seconds: 19));
    expect(c.read(connectionGraceProvider), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(c.read(connectionGraceProvider), isFalse);
  });

  testWidgets('a length of 0 has no grace (warnings at once)', (tester) async {
    expect(grace(Duration.zero).read(connectionGraceProvider), isFalse);
  });

  testWidgets('back to the front starts it again; a focus change alone does not', (tester) async {
    final c = grace(const Duration(seconds: 20));
    c.read(connectionGraceProvider);
    await tester.pump(const Duration(seconds: 21));
    expect(c.read(connectionGraceProvider), isFalse);

    // The desktop window loses and gets the focus: inactive, then resumed.
    life(AppLifecycleState.inactive);
    life(AppLifecycleState.resumed);
    expect(c.read(connectionGraceProvider), isFalse);

    // The phone in the background, or the window minimised, then back.
    life(AppLifecycleState.inactive);
    life(AppLifecycleState.hidden);
    life(AppLifecycleState.inactive);
    life(AppLifecycleState.resumed);
    expect(c.read(connectionGraceProvider), isTrue);
    await tester.pump(const Duration(seconds: 21));
    expect(c.read(connectionGraceProvider), isFalse);
  });

  testWidgets('restart and end', (tester) async {
    final c = grace(const Duration(seconds: 20));
    c.read(connectionGraceProvider.notifier).end();
    expect(c.read(connectionGraceProvider), isFalse);
    c.read(connectionGraceProvider.notifier).restart();
    expect(c.read(connectionGraceProvider), isTrue);
    c.read(connectionGraceProvider.notifier).end();
  });
}
