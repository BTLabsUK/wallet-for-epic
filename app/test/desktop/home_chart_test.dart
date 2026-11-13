// SPDX-License-Identifier: Apache-2.0
// Home's 30-day chart: what it counts in and out, and where the step line starts and ends.
import 'package:epic_wallet/src/desktop/screens/wallet/home_chart.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 13, 12);
  Tx tx(int id, TxDirection dir, int amount, {int fee = 0, int daysAgo = 1, TxState state = TxState.confirmed}) => Tx(
    id: id,
    slateId: 's$id',
    direction: dir,
    state: state,
    method: TxMethod.epicbox,
    amount: amount,
    fee: fee,
    created: now.subtract(Duration(days: daysAgo)),
  );

  test('in and out over 30 days: confirmed payments only, fees with what went out', () {
    final txs = [
      tx(1, TxDirection.received, 100, daysAgo: 20),
      tx(2, TxDirection.sent, 30, fee: 1, daysAgo: 5),
      tx(3, TxDirection.received, 50, daysAgo: 40), // older than the chart
      tx(4, TxDirection.received, 7, state: TxState.confirming), // not confirmed yet
    ];
    final d = homeChartData(txs, 1000, now);
    expect(d.inSum, 100);
    expect(d.outSum, 31);
    // It starts at what the balance was before the 30 days' payments and ends at the balance now.
    expect(d.steps.first.$2, 1000 - 100 + 31);
    expect(d.steps.last.$2, 1000);
    expect(d.steps.length, 4);
  });

  test('no payments in the 30 days: a flat line at the balance', () {
    final d = homeChartData(const [], 500, now);
    expect(d.inSum, 0);
    expect(d.outSum, 0);
    expect([for (final s in d.steps) s.$2], [500, 500]);
  });
}
