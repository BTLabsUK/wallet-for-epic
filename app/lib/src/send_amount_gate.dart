// SPDX-License-Identifier: Apache-2.0
/// Whether a payment's amount may go on to its confirm: the one rule every send path asks,
/// on the phone and the desktop (Epicbox, Link, Direct · File and QR Payment, HTTP, Tor, an
/// invoice or payment request). Pure: amounts in nanoepic, as [SendSummary] counts them; no
/// wallet calls.
///
/// An amount above what can be spent now stops at once, on the keystroke, without waiting for
/// the wallet's estimate. Below it, the confirm waits for an estimate made for exactly this
/// amount: until it has come (a debounce, a slow wallet), nothing goes on. A screen asks again
/// on the tap itself, before anything is built or sent.
library;

/// Why a payment cannot go on to its confirm yet.
enum SendAmountBlock {
  /// No amount, or not one above zero; the field says what is wrong with its text.
  noAmount,

  /// The amount, with the fee once it is known, is more than can be spent now.
  notEnough,

  /// The estimate for this amount failed; its error says why.
  estimateFailed,

  /// The estimate for exactly this amount, or the balance, has not come yet.
  checking,
}

/// The answer for one amount: [ready], or the [block] that holds it.
class SendAmountGate {
  const SendAmountGate._(this.block);

  /// The gate for sending [amount] from [spendable] (null while the balance is not known).
  ///
  /// [estimate] is the last estimate the screen holds, whatever amount it was made for: only
  /// one made for exactly [amount] counts, and then its fee counts against [spendable] too.
  /// [estimateFailed] says the estimate for [amount] failed. A payment whose amount is fixed
  /// and that the wallet prices itself (an invoice) passes [needsEstimate] false: then the
  /// balance must be known instead.
  factory SendAmountGate.check({
    required int? amount,
    required int? spendable,
    ({int amount, int fee})? estimate,
    bool estimateFailed = false,
    bool needsEstimate = true,
  }) {
    if (amount == null || amount <= 0) {
      return const SendAmountGate._(SendAmountBlock.noAmount);
    }
    // At once, before any estimate: the fee only adds to it.
    if (spendable != null && amount > spendable) {
      return const SendAmountGate._(SendAmountBlock.notEnough);
    }
    final forThis = estimate != null && estimate.amount == amount ? estimate : null;
    if (forThis != null && spendable != null && amount + forThis.fee > spendable) {
      return const SendAmountGate._(SendAmountBlock.notEnough);
    }
    if (estimateFailed) return const SendAmountGate._(SendAmountBlock.estimateFailed);
    if (needsEstimate ? forThis == null : spendable == null) {
      return const SendAmountGate._(SendAmountBlock.checking);
    }
    return const SendAmountGate._(null);
  }

  /// What holds the payment; null when it may go on.
  final SendAmountBlock? block;

  /// The amount may go on to its confirm.
  bool get ready => block == null;

  /// More than can be spent now: the screen says so at once.
  bool get notEnough => block == SendAmountBlock.notEnough;

  /// The estimate for this amount is on its way.
  bool get checking => block == SendAmountBlock.checking;

  /// The confirm is off whatever else the screen checks: too much, or still checking. A screen
  /// that explains a missing amount or a failed estimate on the tap (the desktop's Review send)
  /// keeps its button on for those and asks [ready] on the tap.
  bool get holds => notEnough || checking;

  @override
  String toString() => 'SendAmountGate(${block?.name ?? 'ready'})';
}
