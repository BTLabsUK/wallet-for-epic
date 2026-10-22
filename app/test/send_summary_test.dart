// F11's summary rows and F12's SmartOutputs rule, pure; one plan runs against the fake
// session's input selection.

import 'package:epic_wallet/src/send_summary.dart';
import 'package:epic_wallet/src/smart_outputs.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const int epic = 100000000;
const int fee = 800000;

void main() {
  group('send summary', () {
    test('a plain send: balance after, the lock and what stays spendable', () {
      // 120 EPIC: 100 in one output, 20 in others; sending 1 spends the 100.
      final s = SendSummary.of(
        balance: 130 * epic,
        spendable: 120 * epic,
        estimate: const SendEstimate(amount: epic, fee: fee, inputCount: 1, change: 99 * epic - fee, locked: 100 * epic, changeOutputs: 1),
      );
      expect(s.amount, epic);
      expect(s.fee, fee);
      expect(s.total, epic + fee);
      expect(s.balanceAfter, 129 * epic - fee);
      expect(s.locked, 100 * epic);
      expect(s.lockedOutputs, 1);
      expect(s.spendableMeanwhile, 20 * epic);
      expect(s.change, 99 * epic - fee);
      expect(s.changeOutputs, 1);
      expect(s.fits, true);
      expect(s.noChange, false);
      expect(s.locksAll, false);
    });

    test('send-all: no change, nothing spendable meanwhile, nothing left', () {
      final s = SendSummary.of(
        balance: 10 * epic,
        spendable: 10 * epic,
        estimate: const SendEstimate(amount: 10 * epic - fee, fee: fee, inputCount: 3, locked: 10 * epic),
      );
      expect(s.balanceAfter, 0);
      expect(s.noChange, true);
      expect(s.changeOutputs, 0);
      expect(s.locked, 10 * epic);
      expect(s.lockedOutputs, 3);
      expect(s.spendableMeanwhile, 0);
      expect(s.locksAll, true);
      expect(s.fits, true);
    });

    test('zero change reports no change outputs even when asked for several', () {
      final s = SendSummary.of(
        balance: 5 * epic,
        spendable: 5 * epic,
        estimate: const SendEstimate(amount: 2 * epic - fee, fee: fee, inputCount: 1, locked: 2 * epic, changeOutputs: 4),
      );
      expect(s.changeOutputs, 0);
      expect(s.spendableMeanwhile, 3 * epic);
    });

    test('a fee above what remains: short by the difference, never below zero', () {
      final s = SendSummary.of(
        balance: 5 * epic,
        spendable: 5 * epic,
        estimate: const SendEstimate(amount: 5 * epic, fee: fee),
      );
      expect(s.fits, false);
      expect(s.shortBy, fee);
      expect(s.balanceAfter, 0);
      expect(s.spendableMeanwhile, 0);
    });

    test('an estimate without lock figures locks amount and fee', () {
      final s = SendSummary.of(balance: 5 * epic, spendable: 4 * epic, estimate: const SendEstimate(amount: epic, fee: fee));
      expect(s.locked, epic + fee);
      expect(s.spendableMeanwhile, 3 * epic - fee);
    });

    test('from the core estimate', () {
      final e = SendEstimate.fromFee(
        FeeEstimate(
          amount: BigInt.from(epic),
          fee: BigInt.from(fee),
          inputCount: 2,
          change: BigInt.from(3 * epic),
          locked: BigInt.from(4 * epic + fee),
          changeOutputs: 4,
        ),
      );
      expect(e, const SendEstimate(amount: epic, fee: fee, inputCount: 2, change: 3 * epic, locked: 4 * epic + fee, changeOutputs: 4));
    });
  });

  group('SmartOutputs rule', () {
    SendEstimate base({required int inputs, required int change}) =>
        SendEstimate(amount: epic, fee: fee, inputCount: inputs, change: change, locked: epic + fee + change, changeOutputs: change > 0 ? 1 : 0);

    test('one 100 EPIC output sending 1: change in 4 outputs', () {
      final d = smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: 99 * epic - fee));
      expect(d.changeOutputs, 4);
      expect(d.reason, SmartOutputsReason.split);
      expect(d.outputsLeft, 0);
      expect(d.splits, true);
    });

    test('many outputs: one change output', () {
      final d = smartOutputs(enabled: true, spendableOutputs: 12, base: base(inputs: 2, change: 50 * epic));
      expect(d.changeOutputs, 1);
      expect(d.reason, SmartOutputsReason.enoughOutputs);
      expect(d.outputsLeft, 10);
    });

    test('exactly the minimum left: no split; one fewer: split', () {
      expect(smartOutputs(enabled: true, spendableOutputs: 4, base: base(inputs: 1, change: 9 * epic)).changeOutputs, 1);
      expect(smartOutputs(enabled: true, spendableOutputs: 3, base: base(inputs: 1, change: 9 * epic)).changeOutputs, 4);
    });

    test('small change: one change output', () {
      final d = smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: epic - 1));
      expect(d.changeOutputs, 1);
      expect(d.reason, SmartOutputsReason.smallChange);
    });

    test('change between 1 and 2 EPIC: as many 0.5 EPIC outputs as fit', () {
      expect(smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: epic)).changeOutputs, 2);
      expect(smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: 3 * epic ~/ 2)).changeOutputs, 3);
    });

    test('off, and no change: one change output', () {
      expect(smartOutputs(enabled: false, spendableOutputs: 1, base: base(inputs: 1, change: 99 * epic)).reason, SmartOutputsReason.off);
      expect(smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: 0)).reason, SmartOutputsReason.noChange);
    });

    test('never below the minimum per output', () {
      const rule = SmartOutputsRule(outputStep: epic ~/ 10, maxOutputs: 8, minPerOutput: epic ~/ 4);
      // 1 EPIC in 0.1 EPIC steps would be 8 outputs; 0.25 EPIC each allows 4.
      final d = smartOutputs(enabled: true, spendableOutputs: 1, base: base(inputs: 1, change: epic), rule: rule);
      expect(d.changeOutputs, 4);
    });

    test('the default is on', () => expect(smartOutputsDefault, true));

    test('counts spendable outputs only', () {
      WalletOutput out(OutputCategory? c) => WalletOutput(
        commitment: 'c',
        value: BigInt.one,
        status: WalletOutputStatus.unspent,
        category: c,
        isCoinbase: false,
        height: BigInt.one,
        lockHeight: BigInt.zero,
        confirmations: BigInt.one,
      );
      expect(spendableCount([out(OutputCategory.spendable), out(OutputCategory.locked), out(null), out(OutputCategory.spendable)]), 2);
    });
  });

  group('SmartOutputs plan', () {
    test('a split shows its extra fee and goes out with its options', () async {
      final asked = <SendOptions>[];
      final plan = await planSend(
        estimate: (o) async {
          asked.add(o);
          final f = fee + (o.changeOutputs - 1) * 100000;
          return SendEstimate(amount: epic, fee: f, inputCount: 1, change: 99 * epic - f, locked: 100 * epic, changeOutputs: o.changeOutputs);
        },
        strategy: SelectionStrategy.smallest,
        smartOutputsOn: true,
        spendableOutputs: 1,
      );
      expect(asked, const [SendOptions(), SendOptions(changeOutputs: 4)]);
      expect(plan.splits, true);
      expect(plan.options, const SendOptions(changeOutputs: 4));
      expect(plan.extraFee, 300000);
      expect(plan.estimate.fee, fee + 300000);
      expect(plan.base.fee, fee);
    });

    test('no split: one estimate, no extra fee, the strategy kept', () async {
      var calls = 0;
      final plan = await planSend(
        estimate: (o) async {
          calls++;
          return SendEstimate(amount: epic, fee: fee, inputCount: 1, change: 5 * epic, locked: 6 * epic + fee, changeOutputs: 1);
        },
        strategy: SelectionStrategy.all,
        smartOutputsOn: true,
        spendableOutputs: 20,
      );
      expect(calls, 1);
      expect(plan.splits, false);
      expect(plan.extraFee, 0);
      expect(plan.options, const SendOptions(strategy: SelectionStrategy.all));
    });

    test('a split the core refuses falls back to one change output', () async {
      final plan = await planSend(
        estimate: (o) async {
          if (o.changeOutputs > 1) throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'change too small');
          return SendEstimate(amount: epic, fee: fee, inputCount: 1, change: 2 * epic, locked: 3 * epic + fee, changeOutputs: 1);
        },
        strategy: SelectionStrategy.smallest,
        smartOutputsOn: true,
        spendableOutputs: 1,
      );
      expect(plan.splits, false);
      expect(plan.decision.reason, SmartOutputsReason.smallChange);
      expect(plan.estimate, plan.base);
    });

    test('other errors of the split estimate are the caller\'s', () async {
      await expectLater(
        planSend(
          estimate: (o) async {
            if (o.changeOutputs > 1) throw const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'down');
            return SendEstimate(amount: epic, fee: fee, inputCount: 1, change: 2 * epic, locked: 3 * epic + fee, changeOutputs: 1);
          },
          strategy: SelectionStrategy.smallest,
          smartOutputsOn: true,
          spendableOutputs: 1,
        ),
        throwsA(isA<WalletError>()),
      );
    });

    test('with the wallet: one 100 EPIC output, send 1, change in 4 outputs', () async {
      final session = FakeWalletSession()
        ..outputsValue = [
          WalletOutput(
            commitment: 'c1',
            value: BigInt.from(100 * epic),
            status: WalletOutputStatus.unspent,
            category: OutputCategory.spendable,
            isCoinbase: false,
            height: BigInt.from(10),
            lockHeight: BigInt.zero,
            confirmations: BigInt.from(5),
          ),
        ];
      final outputs = await session.outputs();
      final plan = await planSend(
        estimate: (o) async => SendEstimate.fromFee(
          await session.estimateFee(amount: BigInt.from(epic), minimumConfirmations: BigInt.from(3), options: o),
        ),
        strategy: SelectionStrategy.smallest,
        smartOutputsOn: true,
        spendableOutputs: spendableCount(outputs),
      );
      expect(plan.estimate.changeOutputs, 4);
      expect(plan.extraFee, 3 * session.changeOutputFee.toInt());
      final summary = SendSummary.of(balance: 100 * epic, spendable: 100 * epic, estimate: plan.estimate);
      expect(summary.locked, 100 * epic);
      expect(summary.lockedOutputs, 1);
      expect(summary.spendableMeanwhile, 0);
      expect(summary.change, 99 * epic - plan.estimate.fee);
    });
  });
}
