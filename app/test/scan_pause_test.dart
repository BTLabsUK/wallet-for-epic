// SPDX-License-Identifier: Apache-2.0
// Item 3 of 26.10.18: Android cuts a background app's network within seconds, which failed a
// restore scan or Recheck balance there, and the retry showed 0 % until its first page. The
// scan now pauses with the app and goes on, with the same start, when it is back.
import 'dart:async';

import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// Each scan is a stream the test drives; a cancel ends it with an error, as the core's does
/// when the node call it was in fails.
class _Session extends FakeWalletSession {
  final List<StreamController<ScanProgress>> scans = [];

  @override
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    super.scan(startHeight: startHeight, deleteUnconfirmed: deleteUnconfirmed);
    final scan = StreamController<ScanProgress>();
    scans.add(scan);
    return scan.stream;
  }

  @override
  void cancelScan() {
    super.cancelScan();
    final scan = scans.last;
    if (scan.isClosed) return;
    scan.addError(Exception('node request failed: connection abort'));
    scan.close();
  }
}

/// LEPIC's set_servers cancels a running scan (LN-01): its stream ends, the cancel swallowed
/// as the service does, before the switch returns, which waits for [gate].
class _SwitchSession extends _Session {
  final gate = Completer<void>();

  @override
  Future<void> setServers({required WalletConfig config}) async {
    final scan = scans.last;
    if (!scan.isClosed) await scan.close();
    await gate.future;
  }
}

const _switchTo = WalletConfig(
  dataDir: '/data/mainnet',
  chain: Chain.mainnet,
  nodeUrl: 'https://node.example.org',
  epicboxDomain: 'relay.example.org',
  epicboxPort: 443,
);

void main() {
  for (final start in [null, BigInt.from(1200)]) {
    test('a server switch during a scan (start $start) runs that scan again to its end', () async {
      final session = _SwitchSession();
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [sessionProvider.overrideWith(() => _Open(session))],
      );
      addTearDown(c.dispose);
      final scan = c.read(scanProvider.notifier);
      final run = scan.run(startHeight: start);
      await pumpEventQueue();
      session.scans.last.add(const ScanProgress(percent: 40, message: 'Scanning', finished: false));
      await pumpEventQueue();

      final switched = scan.duringSwitch(
        () => session.setServers(config: _switchTo),
      );
      await pumpEventQueue();
      expect(session.scanCalls, 1, reason: 'nothing starts while the switch runs');
      expect(c.read(scanProvider).running, isTrue);
      expect(c.read(scanProvider).stopped, isFalse);

      session.gate.complete();
      await switched;
      await pumpEventQueue();
      expect(session.scanStarts, [start, start], reason: 'the same scan, a restore stays one');
      expect(c.read(scanProvider).percent, 40);
      session.scans.last.add(const ScanProgress(percent: 100, message: 'Done', finished: true));
      await session.scans.last.close();
      expect(await run, isTrue);
      expect(c.read(scanProvider).done, isTrue);
    });
  }

  test('Stop during a server switch stops the scan, which does not start again', () async {
    final session = _SwitchSession();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    final scan = c.read(scanProvider.notifier);
    final run = scan.run();
    await pumpEventQueue();
    final switched = scan.duringSwitch(
      () => session.setServers(config: _switchTo),
    );
    await pumpEventQueue();
    scan.stop();
    session.gate.complete();
    await switched;
    expect(await run, isFalse);
    expect(c.read(scanProvider).stopped, isTrue);
    expect(session.scanCalls, 1);
  });

  test('a scan pauses with the app and goes on from where it was when the app is back', () async {
    final session = _Session();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    final scan = c.read(scanProvider.notifier);
    var ended = false;
    final run = scan.run(startHeight: BigInt.zero).whenComplete(() => ended = true);
    await pumpEventQueue();
    session.scans.last.add(const ScanProgress(percent: 74, message: 'Scanning', finished: false));
    await pumpEventQueue();

    scan.pause();
    await pumpEventQueue();
    var state = c.read(scanProvider);
    expect(session.scanCancels, 1);
    expect(state.running, isTrue, reason: 'one scan through the pause');
    expect(state.paused, isTrue);
    expect(state.error, isNull, reason: 'the network cut is not a failure');
    expect(state.percent, 74);
    expect(ended, isFalse);
    expect(session.scanCalls, 1, reason: 'nothing starts while away');

    scan.resume();
    await pumpEventQueue();
    expect(session.scanStarts, [BigInt.zero, BigInt.zero], reason: 'the same start resumes');
    // The core first reports its start height, not the last stored page.
    session.scans.last.add(const ScanProgress(percent: 0, message: 'Scanning', finished: false));
    await pumpEventQueue();
    state = c.read(scanProvider);
    expect(state.paused, isFalse);
    expect(state.resuming, isTrue);
    expect(state.percent, 74);

    session.scans.last.add(const ScanProgress(percent: 84, message: 'Scanning', finished: false));
    await pumpEventQueue();
    state = c.read(scanProvider);
    expect(state.resuming, isFalse);
    expect(state.percent, 84);

    session.scans.last.add(const ScanProgress(percent: 100, message: 'Done', finished: true));
    await session.scans.last.close();
    expect(await run, isTrue);
    expect(c.read(scanProvider).done, isTrue);
  });

  test('the first 0 % a scan reports, its start height, reads as starting', () async {
    // After the app was closed, the core goes on from its stored page but first reports
    // block 0: the line said 0 % until the first page.
    final session = _Session();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    unawaited(c.read(scanProvider.notifier).run());
    await pumpEventQueue();
    session.scans.last.add(const ScanProgress(percent: 0, message: 'Scanning', finished: false));
    await pumpEventQueue();
    expect(c.read(scanProvider).running, isTrue);
    expect(c.read(scanProvider).percent, isNull);
    session.scans.last.add(const ScanProgress(percent: 77, message: 'Scanning', finished: false));
    await pumpEventQueue();
    expect(c.read(scanProvider).percent, 77);
    session.scans.last.add(const ScanProgress(percent: 100, message: 'Done', finished: true));
    await session.scans.last.close();
  });

  test('a scan whose stream ends without its finished event is stopped, never done', () async {
    // Recheck balance said "Balance rechecked" for a scan the core ended early.
    final session = _Session();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    final run = c.read(scanProvider.notifier).run(startHeight: BigInt.zero);
    await pumpEventQueue();
    session.scans.last.add(const ScanProgress(percent: 22, message: 'Scanning', finished: false));
    await session.scans.last.close();
    expect(await run, isFalse);
    expect(c.read(scanProvider).done, isFalse);
    expect(c.read(scanProvider).stopped, isTrue);
  });

  test('Stop while paused ends the scan as stopped, without starting it again', () async {
    final session = _Session();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    final scan = c.read(scanProvider.notifier);
    final run = scan.run();
    await pumpEventQueue();
    scan.pause();
    await pumpEventQueue();
    scan.stop();
    expect(await run, isFalse);
    expect(c.read(scanProvider).stopped, isTrue);
    scan.resume();
    await pumpEventQueue();
    expect(session.scanCalls, 1);
  });
}
