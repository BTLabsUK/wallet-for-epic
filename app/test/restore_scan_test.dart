// SPDX-License-Identifier: Apache-2.0
// The phone's "restore not finished" state (restore_scan.dart): the core's flag read on every
// unlock and after every scan; while it is set and the network allows, the scan with no start
// height (= from block 0) starts by itself, one at a time, and a failure waits instead of
// looping.

import 'dart:async';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/restore_scan.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _failed = [ScanProgress(percent: null, message: 'Scan failed: node gone', finished: true)];

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [secretStoreProvider.overrideWithValue(MemorySecretStore())],
  );
  // Alive for the test, as app.dart keeps it.
  container.listen(restoreScanProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => NetGate.set(NetworkMode.standard));

  test('an unlock with the flag set scans from block 0 by itself until the flag clears', () async {
    final container = _container();
    addTearDown(container.dispose);
    final session = FakeWalletSession()..restoreScanPending = true;
    container.read(sessionProvider.notifier).unlocked(session);
    await pumpEventQueue();

    // No start height: the core starts at block 0 while the flag is set.
    expect(session.scanStarts, [null]);
    expect(session.restoreScanPending, isFalse);
    expect(container.read(restoreScanProvider).required, isFalse);
  });

  test('nothing runs when the flag is clear', () async {
    final container = _container();
    addTearDown(container.dispose);
    final session = FakeWalletSession();
    container.read(sessionProvider.notifier).unlocked(session);
    await pumpEventQueue();
    expect(session.scanCalls, 0);
    expect(container.read(restoreScanProvider).required, isFalse);
  });

  test('a restore from a start height is finished from block 0 once its own scan ends', () async {
    final container = _container();
    addTearDown(container.dispose);
    final restore = container.read(restoreScanProvider.notifier)..hold();
    final session = FakeWalletSession()..restoreScanPending = true;
    container.read(sessionProvider.notifier).unlocked(session);
    await pumpEventQueue();
    // The Restore screen holds it: its own scan, from the user's height, comes first.
    expect(session.scanCalls, 0);
    expect(container.read(restoreScanProvider).required, isTrue);

    await container.read(scanProvider.notifier).run(startHeight: BigInt.from(3000000));
    await pumpEventQueue();
    expect(session.scanStarts, [BigInt.from(3000000)]);
    expect(session.restoreScanPending, isTrue, reason: 'a height above 0 leaves the flag');
    expect(session.scanCalls, 1, reason: 'held while the Restore screen is up');

    restore.release();
    await pumpEventQueue();
    expect(session.scanStarts, [BigInt.from(3000000), null]);
    expect(container.read(restoreScanProvider).required, isFalse);
  });

  test('Kill switch waits with the reason, and the scan starts when it is off', () async {
    final container = _container();
    addTearDown(container.dispose);
    NetGate.set(NetworkMode.killSwitch);
    final session = FakeWalletSession()..restoreScanPending = true;
    container.read(sessionProvider.notifier).unlocked(session);
    await pumpEventQueue();
    expect(session.scanCalls, 0);
    final waiting = container.read(restoreScanProvider);
    expect(waiting.required, isTrue);
    expect(waiting.waitingNetwork, isTrue);

    NetGate.set(NetworkMode.standard);
    await container.read(restoreScanProvider.notifier).check(retry: true);
    await pumpEventQueue();
    expect(session.scanStarts, [null]);
    expect(container.read(restoreScanProvider).required, isFalse);
  });

  test('a failed scan waits 30 s, then doubles; Try again starts at once', () {
    fakeAsync((async) {
      final container = _container();
      final session = FakeWalletSession()
        ..restoreScanPending = true
        ..scanEvents = _failed;
      container.read(sessionProvider.notifier).unlocked(session);
      async.flushMicrotasks();
      expect(session.scanCalls, 1);
      final failed = container.read(restoreScanProvider);
      expect(failed.required, isTrue);
      expect(failed.error, isA<Exception>());

      // No tight loop: nothing until the wait is over.
      async.elapse(const Duration(seconds: 29));
      expect(session.scanCalls, 1);
      async.elapse(const Duration(seconds: 2));
      expect(session.scanCalls, 2);
      // The next wait is 60 s, from the second failure at 30 s.
      async.elapse(const Duration(seconds: 57));
      expect(session.scanCalls, 2);
      async.elapse(const Duration(seconds: 2));
      expect(session.scanCalls, 3);

      // Try again does not wait; a scan that works clears the state.
      session.scanEvents = const [
        ScanProgress(percent: 100, message: 'Done', finished: true),
      ];
      unawaited(container.read(restoreScanProvider.notifier).retry());
      async.flushMicrotasks();
      expect(session.scanCalls, 4);
      expect(container.read(restoreScanProvider).required, isFalse);
      expect(container.read(restoreScanProvider).error, isNull);
      container.dispose();
    });
  });

  test('a scan from block 0 that leaves the flag set waits instead of starting another', () {
    fakeAsync((async) {
      final container = _container();
      final session = _StuckFlagSession();
      container.read(sessionProvider.notifier).unlocked(session);
      async.flushMicrotasks();
      expect(session.scanCalls, 1);
      expect(container.read(restoreScanProvider).error, isNotNull);
      async.elapse(const Duration(seconds: 10));
      expect(session.scanCalls, 1);
      container.dispose();
    });
  });

  test('a lock clears the state', () async {
    final container = _container();
    addTearDown(container.dispose);
    NetGate.set(NetworkMode.killSwitch);
    container.read(sessionProvider.notifier).unlocked(FakeWalletSession()..restoreScanPending = true);
    await pumpEventQueue();
    expect(container.read(restoreScanProvider).required, isTrue);
    container.read(sessionProvider.notifier).lock();
    await pumpEventQueue();
    expect(container.read(restoreScanProvider).required, isFalse);
  });
}

/// A core whose scan ends without error but never clears the flag (a skipped scan).
class _StuckFlagSession extends FakeWalletSession {
  @override
  Future<bool> restoreScanRequired() async => true;
}
