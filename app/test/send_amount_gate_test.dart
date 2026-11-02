// SPDX-License-Identifier: Apache-2.0
// The one rule every send path asks before its confirm (next-fixes 12: 5 EPIC with 0.892
// available could be confirmed before the estimate came).

import 'package:epic_wallet/src/send_amount_gate.dart';
import 'package:flutter_test/flutter_test.dart';

const int _epic = 100000000;

void main() {
  group('SendAmountGate', () {
    test('more than spendable is blocked at once, with no estimate', () {
      final gate = SendAmountGate.check(amount: 5 * _epic, spendable: 89200000);
      expect(gate.block, SendAmountBlock.notEnough);
      expect(gate.ready, isFalse);
      expect(gate.holds, isTrue);
    });

    test('over spendable wins over a failed or a pending estimate', () {
      expect(
        SendAmountGate.check(amount: 5 * _epic, spendable: _epic, estimateFailed: true).block,
        SendAmountBlock.notEnough,
      );
      expect(
        SendAmountGate.check(
          amount: 5 * _epic,
          spendable: _epic,
          estimate: (amount: 4 * _epic, fee: 800000),
        ).block,
        SendAmountBlock.notEnough,
      );
    });

    test('amount and the fee of its own estimate above spendable: not enough', () {
      final gate = SendAmountGate.check(
        amount: _epic,
        spendable: _epic,
        estimate: (amount: _epic, fee: 800000),
      );
      expect(gate.notEnough, isTrue);
    });

    test('waits for an estimate made for exactly this amount', () {
      // None yet: the debounce, or the wallet still answering.
      expect(SendAmountGate.check(amount: _epic, spendable: 40 * _epic).checking, isTrue);
      // One for the amount typed before.
      final stale = SendAmountGate.check(
        amount: 2 * _epic,
        spendable: 40 * _epic,
        estimate: (amount: _epic, fee: 800000),
      );
      expect(stale.checking, isTrue);
      expect(stale.holds, isTrue);
      final ready = SendAmountGate.check(
        amount: 2 * _epic,
        spendable: 40 * _epic,
        estimate: (amount: 2 * _epic, fee: 800000),
      );
      expect(ready.ready, isTrue);
      expect(ready.block, isNull);
    });

    test('Max: the estimate of the whole spendable balance is ready', () {
      final gate = SendAmountGate.check(
        amount: 40 * _epic - 800000,
        spendable: 40 * _epic,
        estimate: (amount: 40 * _epic - 800000, fee: 800000),
      );
      expect(gate.ready, isTrue);
    });

    test('a failed estimate blocks without holding', () {
      final gate = SendAmountGate.check(amount: _epic, spendable: 40 * _epic, estimateFailed: true);
      expect(gate.block, SendAmountBlock.estimateFailed);
      expect(gate.holds, isFalse);
    });

    test('no amount, zero or below', () {
      for (final amount in [null, 0, -1]) {
        final gate = SendAmountGate.check(amount: amount, spendable: 40 * _epic);
        expect(gate.block, SendAmountBlock.noAmount, reason: '$amount');
        expect(gate.holds, isFalse);
      }
    });

    test('balance not known: the estimate decides', () {
      expect(SendAmountGate.check(amount: _epic, spendable: null).checking, isTrue);
      expect(
        SendAmountGate.check(amount: _epic, spendable: null, estimate: (amount: _epic, fee: 800000)).ready,
        isTrue,
      );
    });

    test('a fixed amount the wallet prices (an invoice) needs the balance, not an estimate', () {
      expect(SendAmountGate.check(amount: _epic, spendable: 2 * _epic, needsEstimate: false).ready, isTrue);
      expect(SendAmountGate.check(amount: _epic, spendable: null, needsEstimate: false).checking, isTrue);
      expect(SendAmountGate.check(amount: 3 * _epic, spendable: 2 * _epic, needsEstimate: false).notEnough, isTrue);
      // Its fee, when estimated, counts.
      expect(
        SendAmountGate.check(
          amount: 2 * _epic,
          spendable: 2 * _epic,
          estimate: (amount: 2 * _epic, fee: 800000),
          needsEstimate: false,
        ).notEnough,
        isTrue,
      );
    });
  });
}
