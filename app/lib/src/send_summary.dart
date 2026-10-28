// SPDX-License-Identifier: Apache-2.0
/// What Send's summary shows: the amount, the fee, what the balance is after the send,
/// and what the send locks until its change confirms. Pure: amounts in nanoepic, as the
/// desktop UI keeps them; no wallet calls.
library;

import 'models.dart';

/// A send's estimate in nanoepic: [FeeEstimate] for screens that count in `int`.
class SendEstimate {
  const SendEstimate({
    required this.amount,
    required this.fee,
    this.inputCount = 0,
    this.change = 0,
    this.locked = 0,
    this.changeOutputs = 0,
  });

  SendEstimate.fromFee(FeeEstimate e)
    : amount = e.amount.toInt(),
      fee = e.fee.toInt(),
      inputCount = e.inputCount,
      change = e.change.toInt(),
      locked = e.locked.toInt(),
      changeOutputs = e.changeOutputs;

  /// What the receiver gets; [fee] comes on top.
  final int amount;
  final int fee;

  /// How many of the wallet's outputs the send spends.
  final int inputCount;

  /// What comes back as change, in [changeOutputs] outputs (zero when there is no change).
  final int change;
  final int changeOutputs;

  /// The value of the outputs the send spends (`amount + fee + change`), locked until the
  /// send confirms.
  final int locked;

  @override
  int get hashCode => Object.hash(amount, fee, inputCount, change, locked, changeOutputs);

  @override
  bool operator ==(Object other) =>
      other is SendEstimate &&
      amount == other.amount &&
      fee == other.fee &&
      inputCount == other.inputCount &&
      change == other.change &&
      locked == other.locked &&
      changeOutputs == other.changeOutputs;

  @override
  String toString() =>
      'SendEstimate(amount: $amount, fee: $fee, inputs: $inputCount, change: $change in $changeOutputs, locked: $locked)';
}

/// The summary rows of a send.
class SendSummary {
  const SendSummary._({
    required this.amount,
    required this.fee,
    required this.balanceAfter,
    required this.locked,
    required this.lockedOutputs,
    required this.spendableMeanwhile,
    required this.change,
    required this.changeOutputs,
    required this.shortBy,
    required this.hasLockFigures,
  });

  /// The rows for sending [estimate] from a wallet whose whole balance is [balance] and of
  /// which [spendable] can be spent now. A [estimate] without lock figures (an older core,
  /// [SendEstimate.locked] zero) counts amount and fee as locked.
  factory SendSummary.of({required int balance, required int spendable, required SendEstimate estimate}) {
    final total = estimate.amount + estimate.fee;
    final locked = estimate.locked > 0 ? estimate.locked : total;
    final short = total - spendable;
    return SendSummary._(
      amount: estimate.amount,
      fee: estimate.fee,
      balanceAfter: _atLeastZero(balance - total),
      locked: locked,
      lockedOutputs: estimate.inputCount,
      spendableMeanwhile: _atLeastZero(spendable - locked),
      change: estimate.change,
      changeOutputs: estimate.change > 0 ? estimate.changeOutputs : 0,
      shortBy: short > 0 ? short : 0,
      hasLockFigures: estimate.locked > 0,
    );
  }

  /// "Amount": what the receiver gets.
  final int amount;

  /// "Network fee".
  final int fee;

  /// "Total": amount and fee.
  int get total => amount + fee;

  /// "Balance after": the whole balance once the send is done, never below zero.
  final int balanceAfter;

  /// "Locked until change confirms": the outputs the send spends, all of them, change
  /// included, until the send confirms.
  final int locked;

  /// The caption under [locked]: "N outputs".
  final int lockedOutputs;

  /// "Spendable meanwhile" ("Spendable until change confirms"): what can be sent while this
  /// send confirms, never below zero.
  final int spendableMeanwhile;

  /// What comes back, and in how many outputs; zero and zero when the inputs cover amount
  /// and fee exactly (a send-all).
  final int change;
  final int changeOutputs;

  /// How much amount and fee exceed the spendable balance; zero when the send fits.
  final int shortBy;

  /// Amount and fee fit in the spendable balance.
  bool get fits => shortBy == 0;

  /// The estimate carried lock figures ([SendEstimate.locked] above zero); an older core's
  /// did not, and then [locked] is only amount and fee and [change] is unknown.
  final bool hasLockFigures;

  /// Nothing comes back: every spent output goes to amount and fee. Only known with
  /// [hasLockFigures].
  bool get noChange => hasLockFigures && change == 0;

  /// The send leaves nothing spendable until it confirms (a send-all, or Strategy All).
  bool get locksAll => spendableMeanwhile == 0;

  static int _atLeastZero(int v) => v < 0 ? 0 : v;
}
