// SPDX-License-Identifier: Apache-2.0
/// SmartOutputs: when a send would leave the wallet with too few spendable outputs, its
/// change comes back in several outputs, so the next send need not wait for this one to
/// confirm. Pure: the rule, and the plan that asks for the estimate with the split.
library;

import 'send_summary.dart';
import 'wallet_service.dart';

/// SmartOutputs is on unless the user turned it off (the Outputs page).
const bool smartOutputsDefault = true;

/// The rule's parameters, in one place so they can be tuned.
class SmartOutputsRule {
  const SmartOutputsRule({
    this.minOutputsLeft = 3,
    this.minChange = standardMinChange,
    this.outputStep = nanoEpic ~/ 2,
    this.maxOutputs = 4,
    this.targetOutputs = 4,
    this.minPerOutput = nanoEpic ~/ 2,
  });

  /// Split when the send leaves fewer spendable outputs than this.
  final int minOutputsLeft;

  /// Split only change of at least this (1 EPIC).
  final int minChange;

  /// One change output per this much change (0.5 EPIC)...
  final int outputStep;

  /// ...up to this many.
  final int maxOutputs;

  /// ...and no more than bring the spendable outputs, once the change confirms, to this
  /// many (the outputs the send leaves plus the change outputs).
  final int targetOutputs;

  /// Never an output below this (0.5 EPIC).
  final int minPerOutput;

  static const SmartOutputsRule standard = SmartOutputsRule();

  /// [minChange] of [standard] (1 EPIC).
  static const int standardMinChange = nanoEpic;
}

/// 1 EPIC in nanoepic.
const int nanoEpic = 100000000;

/// Why [smartOutputs] chose its count.
enum SmartOutputsReason {
  /// The user turned SmartOutputs off.
  off,

  /// The send brings no change back (a send-all, or inputs that cover it exactly).
  noChange,

  /// Enough spendable outputs stay for the next send.
  enoughOutputs,

  /// The change is under [SmartOutputsRule.minChange].
  smallChange,

  /// The change is split.
  split,

  /// Strategy All spends every output, a consolidating send: its change is always one output.
  allStrategy,
}

class SmartOutputsDecision {
  const SmartOutputsDecision(this.changeOutputs, this.reason, {required this.outputsLeft});

  /// The change outputs to ask for; 1 is a plain send.
  final int changeOutputs;
  final SmartOutputsReason reason;

  /// Spendable outputs the send leaves untouched.
  final int outputsLeft;

  bool get splits => changeOutputs > 1;

  @override
  String toString() => 'SmartOutputsDecision($changeOutputs, ${reason.name}, left $outputsLeft)';
}

/// The change outputs for a send of [base] (estimated with one change output) from a wallet
/// with [spendableOutputs] spendable outputs: when fewer than
/// [SmartOutputsRule.minOutputsLeft] stay and the change is at least
/// [SmartOutputsRule.minChange], n = min([SmartOutputsRule.maxOutputs],
/// [SmartOutputsRule.targetOutputs] − left, change / [SmartOutputsRule.outputStep]), never
/// below [SmartOutputsRule.minPerOutput] each, applied when n ≥ 2; else 1. With the
/// standard rule: min(4, 4 − left, floor(change / 0.5 EPIC)).
SmartOutputsDecision smartOutputs({
  required bool enabled,
  required int spendableOutputs,
  required SendEstimate base,
  SmartOutputsRule rule = SmartOutputsRule.standard,
}) {
  final left = spendableOutputs - base.inputCount;
  final outputsLeft = left < 0 ? 0 : left;
  SmartOutputsDecision one(SmartOutputsReason why) => SmartOutputsDecision(1, why, outputsLeft: outputsLeft);
  if (!enabled) return one(SmartOutputsReason.off);
  if (base.change <= 0) return one(SmartOutputsReason.noChange);
  if (outputsLeft >= rule.minOutputsLeft) return one(SmartOutputsReason.enoughOutputs);
  if (base.change < rule.minChange) return one(SmartOutputsReason.smallChange);
  var n = base.change ~/ rule.outputStep;
  if (n > rule.maxOutputs) n = rule.maxOutputs;
  if (n > rule.targetOutputs - outputsLeft) n = rule.targetOutputs - outputsLeft;
  if (n > maxChangeOutputs) n = maxChangeOutputs;
  while (n > 1 && base.change ~/ n < rule.minPerOutput) {
    n--;
  }
  if (n <= 1) return one(SmartOutputsReason.smallChange);
  return SmartOutputsDecision(n, SmartOutputsReason.split, outputsLeft: outputsLeft);
}

/// [smartOutputs]' count alone, in the Outputs terms: [spendableOutputsLeft]
/// spendable outputs the send does not spend, [changeNano] its change with one change output.
int smartChangeOutputs({
  required int spendableOutputsLeft,
  required int changeNano,
  required bool enabled,
  SmartOutputsRule rule = SmartOutputsRule.standard,
}) => smartOutputs(
  enabled: enabled,
  spendableOutputs: spendableOutputsLeft,
  base: SendEstimate(amount: 0, fee: 0, change: changeNano),
  rule: rule,
).changeOutputs;

/// How many [outputs] count as spendable now. The list must be refreshed with the balance
/// before a send is planned from it: a stale list misjudges how many outputs a send leaves.
int spendableCount(Iterable<WalletOutput> outputs) =>
    outputs.where((o) => o.category == OutputCategory.spendable).length;

/// A send planned with SmartOutputs: the estimate with one change output, the decision, and
/// the estimate the send goes out with.
class SmartSendPlan {
  const SmartSendPlan({required this.base, required this.decision, required this.estimate, required this.options});

  /// The estimate with one change output.
  final SendEstimate base;
  final SmartOutputsDecision decision;

  /// The estimate of the send as it goes out: [base], or the split's.
  final SendEstimate estimate;

  /// What the send and its estimate are given.
  final SendOptions options;

  /// What the split adds to the fee ("Change split into 4 outputs (+0.0000x EPIC fee)"); zero
  /// without a split.
  int get extraFee => estimate.fee - base.fee;

  bool get splits => options.changeOutputs > 1;
}

/// Whether [error] is the core refusing a split it cannot build (change too small, too
/// heavy): [WalletErrorKind.invalidArgument].
bool coreRefusedSplit(Object error) => error is WalletError && error.kind == WalletErrorKind.invalidArgument;

/// Estimates a send with [strategy] and one change output, applies [smartOutputs], and when
/// it splits estimates again with the split. Strategy All never splits: it is a consolidating
/// send, so its change is one output whatever [smartOutputsOn] says. A split error that [splitRefused] accepts falls
/// back to one change output (the core's refusal is [coreRefusedSplit], the desktop's
/// `deskSplitRefused`; no default, so a caller cannot take the wrong one); any other error, and every error of the first estimate, is
/// the caller's.
Future<SmartSendPlan> planSend({
  required Future<SendEstimate> Function(SendOptions options) estimate,
  required SelectionStrategy strategy,
  required bool smartOutputsOn,
  required int spendableOutputs,
  SmartOutputsRule rule = SmartOutputsRule.standard,
  required bool Function(Object error) splitRefused,
}) async {
  final plain = SendOptions(strategy: strategy);
  final base = await estimate(plain);
  final decision = strategy == SelectionStrategy.all
      ? SmartOutputsDecision(1, SmartOutputsReason.allStrategy, outputsLeft: 0)
      : smartOutputs(enabled: smartOutputsOn, spendableOutputs: spendableOutputs, base: base, rule: rule);
  if (!decision.splits) {
    return SmartSendPlan(base: base, decision: decision, estimate: base, options: plain);
  }
  SmartSendPlan unsplit() => SmartSendPlan(
    base: base,
    decision: SmartOutputsDecision(1, SmartOutputsReason.smallChange, outputsLeft: decision.outputsLeft),
    estimate: base,
    options: plain,
  );
  // The split's own fee comes out of the change, so each output is checked against the floor
  // again with the split's estimate, one output fewer each time it falls short.
  var n = decision.changeOutputs;
  while (n > 1) {
    final split = SendOptions(strategy: strategy, changeOutputs: n);
    final SendEstimate e;
    try {
      e = await estimate(split);
    } catch (err) {
      if (!splitRefused(err)) rethrow;
      return unsplit();
    }
    if (e.change ~/ n >= rule.minPerOutput) {
      final d = n == decision.changeOutputs ? decision : SmartOutputsDecision(n, SmartOutputsReason.split, outputsLeft: decision.outputsLeft);
      return SmartSendPlan(base: base, decision: d, estimate: e, options: split);
    }
    n--;
  }
  return unsplit();
}

/// The word an output shows under (Outputs page): one place for the desktop's
/// and the phone's rows.
enum OutputLabel {
  spendable,
  confirming,
  finalizing,
  immature,
  mining,
  locked,
  spent,
}

/// [output]'s word: spent and locked by status; an unconfirmed output awaiting finalization is
/// finalizing, an unconfirmed reward without a category is mining; an immature one by its
/// category; any other unconfirmed or under-confirmed output is confirming.
OutputLabel outputWord(WalletOutput output) {
  switch (output.status) {
    case WalletOutputStatus.spent:
      return OutputLabel.spent;
    case WalletOutputStatus.locked:
      return OutputLabel.locked;
    case WalletOutputStatus.unspent:
    case WalletOutputStatus.unconfirmed:
      return switch (output.category) {
        OutputCategory.spendable => OutputLabel.spendable,
        OutputCategory.awaitingFinalization ||
        OutputCategory.unpaidInvoice => OutputLabel.finalizing,
        OutputCategory.immature => OutputLabel.immature,
        OutputCategory.locked => OutputLabel.locked,
        OutputCategory.awaitingConfirmation => OutputLabel.confirming,
        null => output.isCoinbase ? OutputLabel.mining : OutputLabel.confirming,
      };
  }
}

/// The phone's send of [amount] as Outputs set it: [strategy], and with [splitChange]
/// SmartOutputs over the wallet's spendable outputs ([planSend], never for All). The estimate
/// the send goes out with and the options it must be sent with.
Future<({FeeEstimate estimate, SendOptions options})> planSessionSend(
  WalletSession session, {
  required BigInt amount,
  required BigInt minimumConfirmations,
  required SelectionStrategy strategy,
  required bool splitChange,
}) async {
  final estimates = <SendOptions, FeeEstimate>{};
  final smart = splitChange && strategy != SelectionStrategy.all;
  final plan = await planSend(
    estimate: (o) async => SendEstimate.fromFee(
      estimates[o] = await session.estimateFee(
        amount: amount,
        minimumConfirmations: minimumConfirmations,
        options: o,
      ),
    ),
    strategy: strategy,
    smartOutputsOn: smart,
    spendableOutputs: smart ? spendableCount(await session.outputs()) : 0,
    splitRefused: coreRefusedSplit,
  );
  return (estimate: estimates[plan.options]!, options: plan.options);
}
