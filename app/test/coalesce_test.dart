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

  test('a failure frees the next run and drops the mark', () async {
    final c = Coalesced();
    await expectLater(c.run(() async => throw StateError('x')), throwsStateError);
    expect(c.running, isFalse);
    expect(await c.run(() async => 1), 1);
  });
}
