/// Send's summary lines for the outputs a send spends (F11, F12; design spec §4.2, §4.3, §4.5):
/// the split line under Network fee, Balance after and Spendable until change confirms with
/// the lock caption under Total, and the review dialog's Locks and Strategy facts. The Send
/// page keeps Amount, Network fee and Total.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The strategy's name as a word, in Send's radio rows and inside sentences.
String strategyWord(AppLocalizations l, SelectionStrategy s) => switch (s) {
  SelectionStrategy.smallest => l.deskSendStrategySmallest,
  SelectionStrategy.all => l.deskSendStrategyAll,
};

/// One summary line: the label, and the amount on the right ("—" while unknown).
class SummaryLine extends StatelessWidget {
  const SummaryLine({super.key, required this.label, required this.value, this.strong = false, this.dim = false, this.warn = false, this.top = false});

  final String label;
  final int? value;
  final bool strong;
  final bool dim;
  final bool warn;

  /// The value sits at the top of a label that wraps.
  final bool top;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final v = value;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        crossAxisAlignment: top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: strong ? ts.strong : ts.bodyDim)),
          SizedBox(width: Sp.x3),
          if (v == null)
            Text('—', style: ts.mono(size: Fs.md, color: c.faint))
          else
            EMoney(v, size: strong ? Fs.lg : Fs.md, color: warn ? c.warn : (dim ? c.dim : null), weight: strong ? FontWeight.w600 : null),
        ],
      ),
    );
  }
}

/// "Change split into 4 outputs (+0.012 EPIC fee)" with a help icon that explains why, on
/// hover, click or Enter (F12).
class SendSplitLine extends StatelessWidget {
  const SendSplitLine({super.key, required this.outputs, required this.extraFee, required this.change});

  /// Change outputs the send makes (more than 1).
  final int outputs;

  /// What the split adds to the fee.
  final int extraFee;

  /// The change, shared out over [outputs].
  final int change;

  /// The help icon's text.
  static String why(AppLocalizations l, int outputs, int change) => l.deskSendSplitWhy(outputs, formatEpicL(l, change ~/ outputs, decimals: 4));

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
          Expanded(child: Text(l.deskSendSplitLine(outputs, formatEpicL(l, extraFee, minDecimals: 3)), style: ts.small)),
          HelpTip(text: why(l, outputs, change), label: l.deskSendSplitWhyLabel),
        ],
      ),
    );
  }
}

/// A 28 u help icon whose text shows on hover, on click and on Enter or Space.
class HelpTip extends StatefulWidget {
  const HelpTip({super.key, required this.text, required this.label});

  final String text;

  /// What a screen reader calls the icon.
  final String label;

  @override
  State<HelpTip> createState() => _HelpTipState();
}

class _HelpTipState extends State<HelpTip> {
  final _tip = GlobalKey<TooltipState>();
  bool _hover = false;

  void _show() => _tip.currentState?.ensureTooltipVisible();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Tooltip(
      key: _tip,
      message: widget.text,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Dur.fast,
      child: Semantics(
        button: true,
        label: widget.label,
        hint: widget.text,
        excludeSemantics: true,
        onTap: _show,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.help,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(), SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _show())},
          child: Builder(
            builder: (context) => FocusRing(
              focused: Focus.of(context).hasFocus,
              child: SizedBox.square(
                dimension: 28.u,
                child: Icon(EIcons.help, size: 14.u, color: _hover ? c.text : c.dim),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The caption under "Spendable until change confirms" and whether it warns (nothing stays
/// spendable). [blocks] is the wallet's minimum confirmations.
(String, bool) lockCaption(AppLocalizations l, SendSummary s, int blocks) {
  final n = s.lockedOutputs;
  if (s.noChange) return (l.deskSendLockNoChange(n), false);
  if (s.locksAll) return (l.deskSendLockAll(n, formatEpicL(l, s.locked), blocks), true);
  return (l.deskSendLockSome(n, formatEpicL(l, s.locked), blocks), false);
}

/// Under Total: Balance after, Spendable until change confirms with the lock caption, and
/// the strategy when this send does not use the default. [summary] null: "—" and no caption,
/// as before an amount is typed.
class SendLockRows extends StatelessWidget {
  const SendLockRows({super.key, required this.summary, required this.strategy, required this.defaultStrategy, required this.blocks});

  final SendSummary? summary;
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
        SummaryLine(label: l.deskSendBalanceAfter, value: s?.balanceAfter, dim: true),
        SummaryLine(label: l.deskSendSpendableUntil, value: s?.spendableMeanwhile, warn: warn, top: true),
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

/// The review dialog's Locks fact (§4.5); [blocks] is the wallet's minimum confirmations.
String reviewLocks(AppLocalizations l, SendSummary s, SelectionStrategy strategy, int blocks) {
  final n = s.lockedOutputs;
  final locked = formatEpicL(l, s.locked);
  if (s.noChange) return l.deskSendReviewLocksNone(n, locked);
  if (strategy == SelectionStrategy.all && s.locksAll) return l.deskSendReviewLocksAll(n, locked, blocks);
  if (s.locksAll) return l.deskSendReviewLocksEverything(n, locked, blocks);
  return l.deskSendReviewLocksSome(n, locked, formatEpicL(l, s.spendableMeanwhile), blocks);
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
      ? l.deskSendReviewSplit(s.changeOutputs, formatEpicL(l, extraFee, minDecimals: 3))
      : null,
  facts: [
    (l.deskSendFactLocks, Text(reviewLocks(l, s, strategy, blocks))),
    if (strategy != defaultStrategy) (l.deskSendFactStrategy, Text(l.deskSendFactStrategyValue(strategyWord(l, strategy)))),
  ],
);
