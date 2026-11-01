// SPDX-License-Identifier: Apache-2.0
/// Send's summary lines for the outputs a send spends:
/// the split line under Network fee, Balance after and Spendable until change confirms with
/// the lock caption under Total, and the review dialog's Locks and Strategy facts. The Send
/// page keeps Amount, Network fee and Total.
library;

import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../../amount.dart' show exactDecimals;
import '../../widgets/kit.dart';

/// The strategy's name as a word, in Send's radio rows and inside sentences.
String strategyWord(AppLocalizations l, SelectionStrategy s) => switch (s) {
  SelectionStrategy.smallest => l.deskSendStrategySmallest,
  SelectionStrategy.all => l.deskSendStrategyAll,
};

/// The value of a summary line while the estimate is on its way: a small blue spinner.
class SummaryPending extends StatelessWidget {
  const SummaryPending({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.txDetailsLoading,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x1),
      child: ESpinner(size: 12.u, color: context.dc.info),
    ),
  );
}

/// One summary line: the label, and the amount on the right ("—" while unknown, a spinner
/// while [loading]). The one row of Send's summary, its panel and its lock rows alike.
class SummaryLine extends StatelessWidget {
  const SummaryLine({super.key, required this.label, required this.value, this.strong = false, this.dim = false, this.warn = false, this.risk = false, this.top = false, this.loading = false, this.reserveLines = 1});

  final String label;
  final int? value;
  final bool strong;
  final bool dim;
  final bool warn;

  /// The amount is more than can be sent: in the risk colour.
  final bool risk;

  /// The value sits at the top of a label that wraps.
  final bool top;

  /// The estimate is on its way.
  final bool loading;

  /// Lines of label height the row keeps whatever the value, so a label that wraps beside a
  /// wide amount but not beside "—" never moves the rows under it.
  final int reserveLines;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final v = value;
    final labelStyle = strong ? ts.strong : ts.bodyDim;
    final lineHeight = MediaQuery.textScalerOf(context).scale(labelStyle.fontSize ?? Fs.md) * (labelStyle.height ?? 1.5);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: reserveLines > 1 ? lineHeight * reserveLines : 0),
        child: Row(
          crossAxisAlignment: top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            SizedBox(width: Sp.x3),
            if (loading)
              const SummaryPending()
            else if (v == null)
              Text('—', style: ts.mono(size: Fs.md, color: c.faint)) // l10n-ok: no amount yet
            else
              EMoney(v, size: strong ? Fs.lg : Fs.md, color: risk ? c.risk : (warn ? c.warn : (dim ? c.dim : null)), weight: strong ? FontWeight.w600 : null),
          ],
        ),
      ),
    );
  }
}

/// "Change split into 4 outputs (+0.012 EPIC fee)" with a help icon that explains why, on
/// hover, click or Enter.
class SendSplitLine extends StatelessWidget {
  const SendSplitLine({super.key, required this.outputs, required this.extraFee, required this.change});

  /// Change outputs the send makes (more than 1).
  final int outputs;

  /// What the split adds to the fee.
  final int extraFee;

  /// The change, shared out over [outputs].
  final int change;

  /// The help icon's text.
  static String why(AppLocalizations l, int outputs, int change) => keepNumbersWithUnits(l.deskSendSplitWhy(outputs, formatEpicL(l, change ~/ outputs)));

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x1),
      child: Row(
        children: [
          Icon(EIcons.split, size: 14.u, color: c.accentText),
          SizedBox(width: Sp.x2),
          Expanded(child: Text(keepNumbersWithUnits(l.deskSendSplitLine(outputs, formatEpicL(l, extraFee))), style: ts.small)),
          HelpTip(text: why(l, outputs, change), label: l.deskSendSplitWhyLabel),
        ],
      ),
    );
  }
}

/// A 28 u help icon whose text opens in a popover on a click, Enter or Space ([EInfoHint]).
class HelpTip extends StatelessWidget {
  const HelpTip({super.key, required this.text, required this.label});

  final String text;

  /// What a screen reader calls the icon.
  final String label;

  @override
  Widget build(BuildContext context) => EInfoHint(text, label: label, glyph: EIcons.help, size: Ctl.inline);
}

/// The caption under "Spendable until change confirms" and whether it warns (nothing stays
/// spendable). [blocks] is the wallet's minimum confirmations.
(String, bool) lockCaption(AppLocalizations l, SendSummary s, int blocks) {
  final n = s.lockedOutputs;
  if (s.noChange) return (keepNumbersWithUnits(l.deskSendLockNoChange(n)), false);
  if (s.locksAll) return (keepNumbersWithUnits(l.deskSendLockAll(n, formatEpicL(l, s.locked), blocks)), true);
  return (keepNumbersWithUnits(l.deskSendLockSome(n, formatEpicL(l, s.locked), blocks)), false);
}

/// Under Total: Balance after, Spendable until change confirms with the lock caption, and
/// the strategy when this send does not use the default. [summary] null: "—" and no caption,
/// as before an amount is typed.
class SendLockRows extends StatelessWidget {
  const SendLockRows({super.key, required this.summary, required this.strategy, required this.defaultStrategy, required this.blocks, this.loading = false});

  final SendSummary? summary;

  /// The estimate is on its way: spinners instead of "—".
  final bool loading;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  /// The wallet's minimum confirmations: blocks until the change confirms.
  final int blocks;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final s = summary;
    final caption = s == null ? null : lockCaption(l, s, blocks);
    final warn = caption?.$2 ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SummaryLine(label: l.deskSendBalanceAfter, value: s?.balanceAfter, dim: true, loading: loading && s == null),
        // Two lines kept whatever the label does, so typing an amount never moves the rows
        // under it (#28).
        SummaryLine(label: l.deskSendSpendableWhile, value: s?.spendableMeanwhile, warn: warn, top: true, reserveLines: 2, loading: loading && s == null),
        ExpandFade(
          open: caption != null,
          child: Semantics(
            liveRegion: true,
            child: Text(caption?.$1 ?? '', style: ts.caption.copyWith(color: warn ? c.warn : null)),
          ),
        ),
        ExpandFade(
          open: s != null && strategy != defaultStrategy,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x1),
            child: Text(l.deskSendStrategyLine(s?.lockedOutputs ?? 0, strategyWord(l, strategy)), style: ts.caption),
          ),
        ),
      ],
    );
  }
}

/// The review dialog's Locks fact (§4.5); [blocks] is the wallet's minimum confirmations. The
/// review is a commit surface: its amounts are exact ([AmountSurface.exact]).
String reviewLocks(AppLocalizations l, SendSummary s, SelectionStrategy strategy, int blocks) {
  // In plain words (D-07): what is set aside and until when, no outputs or change.
  final locked = formatEpicL(l, s.locked, decimals: exactDecimals);
  final String text;
  if (s.noChange) {
    text = l.deskSendReviewSetAsideNone(locked);
  } else if (strategy == SelectionStrategy.all && s.locksAll) {
    text = l.deskSendReviewSetAsideAll(locked, blocks);
  } else if (s.locksAll) {
    text = l.deskSendReviewSetAsideEverything(locked, blocks);
  } else {
    text = l.deskSendReviewSetAsideSome(locked, blocks, formatEpicL(l, s.spendableMeanwhile, decimals: exactDecimals));
  }
  return keepNumbersWithUnits(text);
}

/// The review dialog's lines for the outputs: the second line of Network fee when the change
/// is split, or with strategy All and change [usesAll] ("Uses all 5 outputs · change 1
/// output": All consolidates, so its change is never split), then Locks after Total and
/// Strategy when not the default. The dialog puts [feeSecondLine] under its fee and adds
/// [facts] after Total.
({String? feeSecondLine, List<(String, Widget)> facts}) reviewOutputLines(
  AppLocalizations l,
  SendSummary s, {
  required SelectionStrategy strategy,
  required SelectionStrategy defaultStrategy,
  required int blocks,
  int extraFee = 0,
  String Function(int outputs)? usesAll,
}) => (
  feeSecondLine: strategy == SelectionStrategy.all && s.change > 0 && usesAll != null
      ? usesAll(s.lockedOutputs)
      : s.changeOutputs > 1
      ? keepNumbersWithUnits(l.deskSendReviewSplit(s.changeOutputs, formatEpicL(l, extraFee, decimals: exactDecimals)))
      : null,
  facts: [
    (l.deskSendFactLocks, Text(reviewLocks(l, s, strategy, blocks))),
    if (strategy != defaultStrategy) (l.deskSendFactStrategy, Text(l.deskSendFactStrategyValue(strategyWord(l, strategy)))),
  ],
);
