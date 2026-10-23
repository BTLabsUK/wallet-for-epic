/// Send's summary lines for the outputs a send spends (F11, F12; design spec §4.2, §4.3, §4.5):
/// the split line under Network fee, Balance after and Spendable until change confirms with
/// the lock caption under Total, and the review dialog's Locks and Strategy facts. The Send
/// page keeps Amount, Network fee and Total.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/kit.dart';

String _outputs(int n) => n == 1 ? '1 output' : '$n outputs';

String _strategyWord(SelectionStrategy s) => switch (s) {
  SelectionStrategy.smallest => 'Smallest',
  SelectionStrategy.all => 'All',
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
  static String why(int outputs, int change) =>
      'So the next send does not wait for this one to confirm. Change comes back as $outputs outputs of about ${formatEpic(change ~/ outputs, decimals: 4)} EPIC instead of one.';

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x1),
      child: Row(
        children: [
          Icon(EIcons.split, size: 14.u, color: c.accentText),
          SizedBox(width: Sp.x2),
          Expanded(child: Text('Change split into $outputs outputs (+${formatEpic(extraFee, minDecimals: 3)} EPIC fee)', style: ts.small)),
          HelpTip(text: why(outputs, change), label: 'Why the change is split'),
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
/// spendable).
(String, bool) lockCaption(SendSummary s) {
  final n = _outputs(s.lockedOutputs);
  if (s.noChange) return ('No change: $n spent exactly, nothing waits.', false);
  if (s.locksAll) return ('Everything is locked: $n, ${formatEpic(s.locked)} EPIC, about 3 blocks.', true);
  return ('$n locked, ${formatEpic(s.locked)} EPIC, about 3 blocks.', false);
}

/// Under Total: Balance after, Spendable until change confirms with the lock caption, and
/// the strategy when this send does not use the default. [summary] null: "—" and no caption,
/// as before an amount is typed.
class SendLockRows extends StatelessWidget {
  const SendLockRows({super.key, required this.summary, required this.strategy, required this.defaultStrategy});

  final SendSummary? summary;
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final s = summary;
    final caption = s == null ? null : lockCaption(s);
    final warn = caption?.$2 ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SummaryLine(label: 'Balance after', value: s?.balanceAfter, dim: true),
        SummaryLine(label: 'Spendable until change confirms', value: s?.spendableMeanwhile, warn: warn, top: true),
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
            child: Text('Strategy for this send: ${_strategyWord(strategy)} · ${_outputs(s?.lockedOutputs ?? 0)}.', style: ts.caption),
          ),
        ),
      ],
    );
  }
}

/// The review dialog's Locks fact (§4.5).
String reviewLocks(SendSummary s, SelectionStrategy strategy) {
  final n = _outputs(s.lockedOutputs);
  final locked = formatEpic(s.locked);
  if (s.noChange) return '$locked EPIC in $n; no change comes back.';
  if (strategy == SelectionStrategy.all && s.locksAll) return 'Everything: $locked EPIC in $n until the change confirms (3 blocks). Nothing stays spendable.';
  if (s.locksAll) return '$locked EPIC in $n until the change confirms (3 blocks). Nothing else is spendable meanwhile.';
  return '$locked EPIC in $n until the change confirms (3 blocks). ${formatEpic(s.spendableMeanwhile)} EPIC stays spendable.';
}

/// The review dialog's lines for the outputs: the second line of Network fee when the change
/// is split, or with strategy All and change [usesAll] ("Uses all 5 outputs · change 1
/// output": All consolidates, so its change is never split), then Locks after Total and
/// Strategy when not the default. The dialog puts [feeSecondLine] under its fee and adds
/// [facts] after Total.
({String? feeSecondLine, List<(String, Widget)> facts}) reviewOutputLines(
  SendSummary s, {
  required SelectionStrategy strategy,
  required SelectionStrategy defaultStrategy,
  int extraFee = 0,
  String Function(int outputs)? usesAll,
}) => (
  feeSecondLine: strategy == SelectionStrategy.all && s.change > 0 && usesAll != null
      ? usesAll(s.lockedOutputs)
      : s.changeOutputs > 1
      ? 'Change split into ${s.changeOutputs} outputs (+${formatEpic(extraFee, minDecimals: 3)} EPIC).'
      : null,
  facts: [
    ('Locks', Text(reviewLocks(s, strategy))),
    if (strategy != defaultStrategy) ('Strategy', Text('${_strategyWord(strategy)} outputs, for this send')),
  ],
);
