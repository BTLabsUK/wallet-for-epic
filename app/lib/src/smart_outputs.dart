/// SmartOutputs (F12): when a send would leave the wallet with too few spendable outputs, its
/// change comes back in several outputs, so the next send need not wait for this one to
/// confirm. Pure: the rule, and the plan that asks for the estimate with the split.
library;

import 'models.dart';
import 'send_summary.dart';

/// SmartOutputs is on unless the user turned it off (Outputs tab).
const bool smartOutputsDefault = true;

/// The rule's parameters, in one place so they can be tuned.
class SmartOutputsRule {
  const SmartOutputsRule({
    this.minOutputsLeft = 3,
    this.minChange = nanoEpic,
    this.outputStep = nanoEpic ~/ 2,
    this.maxOutputs = 4,
    this.minPerOutput = nanoEpic ~/ 4,
  });

  /// Split when the send leaves fewer spendable outputs than this.
  final int minOutputsLeft;

  /// Split only change of at least this (1 EPIC).
  final int minChange;

  /// One change output per this much change (0.5 EPIC)...
  final int outputStep;

  /// ...up to this many.
  final int maxOutputs;

  /// Never an output below this (0.25 EPIC).
  final int minPerOutput;

  static const SmartOutputsRule standard = SmartOutputsRule();
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
/// with [spendableOutputs] spendable outputs: min([SmartOutputsRule.maxOutputs],
/// change / [SmartOutputsRule.outputStep]) when fewer than [SmartOutputsRule.minOutputsLeft]
/// stay and the change is at least [SmartOutputsRule.minChange], never below
/// [SmartOutputsRule.minPerOutput] each; else 1.
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
  if (n > maxChangeOutputs) n = maxChangeOutputs;
  while (n > 1 && base.change ~/ n < rule.minPerOutput) {
    n--;
  }
  if (n <= 1) return one(SmartOutputsReason.smallChange);
  return SmartOutputsDecision(n, SmartOutputsReason.split, outputsLeft: outputsLeft);
}

/// How many [outputs] count as spendable now.
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
/// it splits estimates again with the split. A split error that [splitRefused] accepts falls
/// back to one change output; any other error, and every error of the first estimate, is
/// the caller's.
Future<SmartSendPlan> planSend({
  required Future<SendEstimate> Function(SendOptions options) estimate,
  required SelectionStrategy strategy,
  required bool smartOutputsOn,
  required int spendableOutputs,
  SmartOutputsRule rule = SmartOutputsRule.standard,
  bool Function(Object error) splitRefused = coreRefusedSplit,
}) async {
  final plain = SendOptions(strategy: strategy);
  final base = await estimate(plain);
  final decision = smartOutputs(enabled: smartOutputsOn, spendableOutputs: spendableOutputs, base: base, rule: rule);
  if (!decision.splits) {
    return SmartSendPlan(base: base, decision: decision, estimate: base, options: plain);
  }
  final split = SendOptions(strategy: strategy, changeOutputs: decision.changeOutputs);
  try {
    final e = await estimate(split);
    return SmartSendPlan(base: base, decision: decision, estimate: e, options: split);
  } catch (e) {
    if (!splitRefused(e)) rethrow;
    return SmartSendPlan(
      base: base,
      decision: SmartOutputsDecision(1, SmartOutputsReason.smallChange, outputsLeft: decision.outputsLeft),
      estimate: base,
      options: plain,
    );
  }
}
