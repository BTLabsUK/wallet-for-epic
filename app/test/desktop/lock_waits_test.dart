// SPDX-License-Identifier: Apache-2.0
// Locking never ends a payment mid-way: the lock waits for a send or split under way (LEPIC
// 5eb9c6e ends running calls at lock, maybe after storing their effect).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a lock waits for a split under way', () async {
    final w = MockDeskWallet(delay: const Duration(milliseconds: 40));
    final split = w.splitOutputs(2);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(w.busy, isTrue);
    var locked = false;
    final lock = w.lock().then((_) => locked = true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(locked, isFalse, reason: 'the split still runs');
    final done = await split;
    expect(done.outputCount, 2);
    await lock;
    expect(locked, isTrue);
    expect(w.busy, isFalse);
  });

  test('a lock waits for a send under way', () async {
    final w = MockDeskWallet(delay: const Duration(milliseconds: 40));
    final send = w.send(const SendRequest(method: TxMethod.file, amount: 100000000));
    await Future<void>.delayed(Duration.zero);
    expect(w.busy, isTrue);
    var sent = false;
    final sending = send.then((_) => sent = true);
    await w.lock();
    expect(sent, isTrue, reason: 'the lock returned only after the send');
    await sending;
  });

  test('with nothing under way the lock is at once', () async {
    final w = MockDeskWallet(delay: Duration.zero);
    expect(w.busy, isFalse);
    await w.lock();
  });
}
