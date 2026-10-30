// SPDX-License-Identifier: Apache-2.0
// Payments a Link listener took in by itself: told apart from the rest, cancelled once they
// waited past the app's expiry, and never more than the cap waiting at once.

import 'package:epic_wallet/src/listener_receives.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 30, 12);

int _ago(Duration d) => _now.subtract(d).millisecondsSinceEpoch ~/ 1000;

TxEntry _tx(
  int id, {
  Duration age = Duration.zero,
  TxKind kind = TxKind.received,
  String? transport = 'http',
  TxStatus status = TxStatus.awaitingConfirmation,
  BigInt? height,
  TxFlow flow = TxFlow.payment,
}) => TxEntry(
  key: 'l:$id',
  id: id,
  kind: kind,
  status: status,
  source: TxSource.wallet,
  createdAtUnix: _ago(age),
  timeUnix: _ago(age),
  confirmed: status == TxStatus.confirmed,
  blockHeight: height,
  amountCredited: BigInt.from(100000000),
  amountDebited: BigInt.zero,
  numInputs: 1,
  numOutputs: 1,
  outputCommits: const [],
  transport: transport,
  cancellable: true,
  repostable: false,
  releasable: false,
  flow: flow,
);

void main() {
  test('only a waiting payment a listener took in counts', () {
    expect(isListenerReceive(_tx(1)), isTrue);
    expect(isListenerReceive(_tx(2, transport: 'tor')), isTrue);
    for (final other in [
      _tx(3, transport: 'epicbox'),
      _tx(4, transport: 'file'),
      _tx(5, transport: null),
      _tx(6, kind: TxKind.sent),
      _tx(7, status: TxStatus.confirmed, height: BigInt.from(10)),
      _tx(8, height: BigInt.from(10)),
      _tx(9, status: TxStatus.cancelled),
    ]) {
      expect(isListenerReceive(other), isFalse, reason: other.key);
    }
  });

  test('a listener payment past the expiry is cancelled, a fresh one and other payments are not', () {
    final txs = [
      _tx(1, age: listenerReceiveTtl + const Duration(minutes: 1)),
      _tx(2, age: listenerReceiveTtl - const Duration(minutes: 1)),
      _tx(3, age: const Duration(days: 30), transport: 'epicbox'),
      _tx(4, age: const Duration(days: 30), transport: 'file'),
    ];
    expect(listenerReceivesToCancel(txs, _now), [1]);
  });

  test('beyond the cap the oldest waiting ones are cancelled', () {
    final txs = [for (var i = 0; i < maxListenerReceives + 3; i++) _tx(i + 1, age: Duration(minutes: i))];
    final cancel = listenerReceivesToCancel(txs, _now);
    expect(cancel, [maxListenerReceives + 1, maxListenerReceives + 2, maxListenerReceives + 3]);
  });
}
