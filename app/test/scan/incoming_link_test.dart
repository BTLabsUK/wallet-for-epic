// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late ProviderContainer c;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    c = ProviderContainer(
      overrides: [linkClockProvider.overrideWithValue(() => now)],
    );
    addTearDown(c.dispose);
  });

  void deliver(String t) => c.read(incomingLinkProvider.notifier).deliver(t);
  void advance(int s) => now = now.add(Duration(seconds: s));

  test('trims and holds a link', () {
    deliver('  epic:abc?amount=1  ');
    expect(c.read(incomingLinkProvider)!.text, 'epic:abc?amount=1');
  });

  test('cap: 4097 chars dropped, 4096 accepted', () {
    deliver('e' * 4097);
    expect(c.read(incomingLinkProvider), isNull);
    deliver('e' * 4096);
    expect(c.read(incomingLinkProvider), isNotNull);
  });

  test('a newer link replaces the older', () {
    deliver('epic:a');
    advance(3);
    deliver('epic:b');
    expect(c.read(incomingLinkProvider)!.text, 'epic:b');
  });

  test('take clears, and returns null after 5 minutes', () {
    deliver('epic:a');
    final n = c.read(incomingLinkProvider.notifier);
    expect(n.take()!.text, 'epic:a');
    expect(c.read(incomingLinkProvider), isNull);
    expect(n.take(), isNull);
    advance(10);
    deliver('epic:b');
    advance(301);
    expect(n.take(), isNull);
    expect(c.read(incomingLinkProvider), isNull);
  });

  test('exactly 5 minutes is still fresh', () {
    deliver('epic:a');
    advance(300);
    expect(c.read(incomingLinkProvider.notifier).take(), isNotNull);
  });

  test('ten links in one second: only the first', () {
    for (var i = 0; i < 10; i++) {
      deliver('epic:l$i');
      now = now.add(const Duration(milliseconds: 100));
    }
    expect(c.read(incomingLinkProvider)!.text, 'epic:l0');
  });

  test('same text within 10 s ignored, accepted after', () {
    deliver('epic:a');
    advance(3);
    deliver('epic:b');
    advance(3);
    deliver('epic:a');
    expect(c.read(incomingLinkProvider)!.text, 'epic:b');
    advance(5);
    deliver('epic:a');
    expect(c.read(incomingLinkProvider)!.text, 'epic:a');
  });

  test('more than 3 in 30 s dropped', () {
    for (var i = 0; i < 4; i++) {
      deliver('epic:l$i');
      advance(5);
    }
    expect(c.read(incomingLinkProvider)!.text, 'epic:l2');
    advance(11);
    deliver('epic:l4');
    expect(c.read(incomingLinkProvider)!.text, 'epic:l4');
  });

  test('busy drops the link and counts it', () {
    c.read(linkBusyProvider.notifier).set(true);
    deliver('epic:a');
    // Rate-limited before the busy check: a burst says "finish the payment" once.
    deliver('epic:b');
    expect(c.read(linkDroppedBusyProvider), 1);
    advance(3);
    deliver('epic:b');
    expect(c.read(incomingLinkProvider), isNull);
    expect(c.read(linkDroppedBusyProvider), 2);
    c.read(linkBusyProvider.notifier).set(false);
    advance(3);
    deliver('epic:c');
    expect(c.read(incomingLinkProvider)!.text, 'epic:c');
    expect(c.read(linkDroppedBusyProvider), 2);
  });
}
