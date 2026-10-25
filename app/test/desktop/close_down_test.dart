// Closing the app always closes: a wallet lock or a node stop that fails or never ends is
// skipped after its limit (the window's exit hook waited on them without one).
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/close_down.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const limit = Duration(milliseconds: 200);

  test('both steps run in order when they work', () async {
    final done = <String>[];
    await deskCloseDown(disposeWallet: () async => done.add('wallet'), stopNodes: () async => done.add('node'), walletLimit: limit, nodeLimit: limit);
    expect(done, ['wallet', 'node']);
  });

  test('a wallet that throws, even synchronously, still lets the node stop and the app close', () async {
    final done = <String>[];
    await deskCloseDown(disposeWallet: () => throw StateError('broken'), stopNodes: () async => done.add('node'), walletLimit: limit, nodeLimit: limit);
    await deskCloseDown(disposeWallet: () async => throw StateError('broken'), stopNodes: () async => done.add('node'), walletLimit: limit, nodeLimit: limit);
    expect(done, ['node', 'node']);
  });

  test('a wallet lock and a node stop that never end are left after their limits', () async {
    final done = <String>[];
    final watch = Stopwatch()..start();
    await deskCloseDown(
      disposeWallet: () => Completer<void>().future,
      stopNodes: () => Completer<void>().future.whenComplete(() => done.add('never')),
      walletLimit: limit,
      nodeLimit: limit,
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(done, isEmpty);
  });
}
