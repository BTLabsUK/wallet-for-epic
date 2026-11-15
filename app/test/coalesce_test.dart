import 'dart:async';

import 'package:epic_wallet/src/coalesce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('triggers during a run make exactly one rerun', () async {
    final c = Coalesced();
    var runs = 0;
    final gate = Completer<void>();
    Future<int> body() async {
      runs++;
      if (runs == 1) await gate.future;
      return 1;
    }

    final first = c.run(body);
    expect(await c.run(body), 0);
    expect(await c.run(body), 0);
    expect(await c.run(body), 0);
    expect(runs, 1);
    gate.complete();
    expect(await first, 2);
    expect(runs, 2);
    expect(c.running, isFalse);
    expect(await c.run(body), 1);
    expect(runs, 3);
  });

  test('the rerun is the latest body given', () async {
    final c = Coalesced();
    final gate = Completer<void>();
    final ran = <String>[];
    final first = c.run(() async {
      ran.add('first');
      await gate.future;
      return 1;
    });
    await c.run(() async {
      ran.add('second');
      return 0;
    });
    await c.run(() async {
      ran.add('third');
      return 0;
    });
    gate.complete();
    await first;
    expect(ran, ['first', 'third']);
  });

  test('a failure frees the next run and drops the mark', () async {
    final c = Coalesced();
    await expectLater(c.run(() async => throw StateError('x')), throwsStateError);
    expect(c.running, isFalse);
    expect(await c.run(() async => 1), 1);
  });

  test('the rerun is the highest rank given, the latest of equal rank', () async {
    final c = Coalesced();
    final gate = Completer<void>();
    final ran = <String>[];
    Future<int> Function() named(String name) => () async {
      ran.add(name);
      return 0;
    };
    final first = c.run(() async {
      ran.add('first');
      await gate.future;
      return 1;
    });
    // A full check, then a check of a few: the full check stays the rerun.
    await c.run(named('full'), rank: 1);
    await c.run(named('some'));
    gate.complete();
    await first;
    expect(ran, ['first', 'full']);

    // A check of a few, then the full check: the full check wins, and the next round starts clean.
    ran.clear();
    final gate2 = Completer<void>();
    final second = c.run(() async {
      ran.add('first');
      await gate2.future;
      return 1;
    });
    await c.run(named('some'));
    await c.run(named('full'), rank: 1);
    await c.run(named('full again'), rank: 1);
    gate2.complete();
    await second;
    expect(ran, ['first', 'full again']);

    ran.clear();
    final gate3 = Completer<void>();
    final third = c.run(() async {
      await gate3.future;
      return 1;
    });
    await c.run(named('some'));
    gate3.complete();
    await third;
    expect(ran, ['some'], reason: 'the rank of the last round does not carry over');
  });
}
