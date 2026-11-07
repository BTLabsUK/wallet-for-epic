// SPDX-License-Identifier: Apache-2.0
/// The Allow invoices switch as the one place it is decided: the verified result after the
/// words matched, and the contact page. Off by default; the line under the switch says the
/// state in words ("Invoices from Ann are off.", the hint while on, "Finish the key check
/// first" while a key check is open), so the switch's position is never the only sign. While a
/// change is being written the switch shows the asked-for position with a small spinner beside
/// it; the row keeps its colour, so a toggle does not flash the row dim and back.
///
/// Nothing from the other wallet is shown here but its name: the payer decides alone.
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../info_hint.dart';
import '../theme/tokens.dart';
import 'pairing_parts.dart' show PairCard;

/// A switch row whose line follows its state and that shows its work while a change is
/// written. The same anatomy as [PairSwitchRow] (16 dp inset, 56 dp least height, the info
/// icon after the label, the line under it, the switch at the end), plus:
///
/// - [busy]: the switch shows the position the user asked for, a 16 dp spinner sits before it
///   and taps are ignored; the words keep their colour. When [busy] ends the switch shows
///   [value] again, so a failed write snaps back by itself.
/// - [lockedLine]: the row is disabled (dim words, the switch at 0.38) and the line says why.
///
/// A null [onChanged] disables the row too, with [line] as its explanation.
class PairLiveSwitchRow extends StatefulWidget {
  const PairLiveSwitchRow({
    super.key,
    required this.label,
    required this.info,
    required this.value,
    this.line,
    this.lockedLine,
    this.busy = false,
    this.onChanged,
    this.switchKey,
  });

  final String label;

  /// The info sheet's text; empty for none.
  final String info;
  final bool value;

  /// The line under the label in the usable states (the state in words).
  final String? line;

  /// Set while the switch may not be used (an open key check): shown in place of [line], and
  /// the row is disabled.
  final String? lockedLine;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final Key? switchKey;

  @override
  State<PairLiveSwitchRow> createState() => _PairLiveSwitchRowState();
}

class _PairLiveSwitchRowState extends State<PairLiveSwitchRow> {
  /// The position the user asked for, shown while [PairLiveSwitchRow.busy].
  bool? _pending;

  @override
  void didUpdateWidget(PairLiveSwitchRow old) {
    super.didUpdateWidget(old);
    // The write ended (or the stored value moved): the real value shows again.
    if (!widget.busy || widget.value != old.value) _pending = null;
  }

  void _toggle(bool v) {
    setState(() => _pending = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final enabled = widget.onChanged != null && widget.lockedLine == null;
    final shown = widget.busy && _pending != null ? _pending! : widget.value;
    final line = widget.lockedLine ?? widget.line;
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Not merged: a screen reader reaches the info button on its own, and the switch carries
    // the row's label and line.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: ExcludeSemantics(
                          child: Text(widget.label, style: theme.textTheme.bodyLarge?.copyWith(color: enabled ? t.text : t.dim)),
                        ),
                      ),
                      if (widget.info.isNotEmpty) InfoHint(widget.info, title: widget.label),
                    ],
                  ),
                  if (line != null)
                    // The line changes with the state; its height follows at the app's pace
                    // (a long name wraps one line and not the other), instantly under reduced
                    // motion.
                    AnimatedSize(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      alignment: AlignmentDirectional.topStart,
                      child: ExcludeSemantics(
                        child: Text(line, key: ValueKey(line), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.busy) ...[
              const SizedBox(width: 8),
              ExcludeSemantics(child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.info))),
            ],
            Semantics(
              label: widget.label,
              hint: line,
              // Disabled reads as disabled: not the accent of a switch that can be used.
              child: Opacity(
                opacity: enabled ? 1 : 0.38,
                child: IgnorePointer(
                  ignoring: widget.busy,
                  child: Switch(
                    key: widget.switchKey,
                    value: shown,
                    // Busy keeps the enabled look; a second tap or Enter does nothing until the
                    // write ends.
                    onChanged: !enabled ? null : (widget.busy ? (_) {} : _toggle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Allow invoices row: off by default; while off the line says "Invoices from {name} are
/// off." ([offLine]); while on, [onLine] (the hint: the wallet can ask to pay, nothing is paid
/// without the PIN); while a key check is open, [lockedLine] and the switch is disabled.
///
/// [name] is the contact's name as this wallet calls it (never a name the other wallet sent).
/// [offLine] is `l.sasAllowOffLine(name)`, [lockedLine] `l.contactAllowFinishCheck`; [onLine]
/// defaults to `l.sasAllowInvoicesHint(name)`.
class PairAllowRow extends StatelessWidget {
  const PairAllowRow({
    super.key,
    required this.name,
    required this.value,
    required this.offLine,
    this.onLine,
    this.lockedLine,
    this.busy = false,
    this.onChanged,
    this.switchKey,
  });

  final String name;
  final bool value;
  final String offLine;
  final String? onLine;
  final String? lockedLine;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PairLiveSwitchRow(
      switchKey: switchKey,
      label: l.contactAllowInvoices,
      info: '${l.contactAllowInfo(name)}\n\n${l.contactAllowInfoMore}',
      value: value,
      line: value ? (onLine ?? l.sasAllowInvoicesHint(name)) : offLine,
      lockedLine: lockedLine,
      busy: busy,
      onChanged: onChanged,
    );
  }
}

/// The verified result's card: the seal row (when [seal] is given) over the Allow invoices
/// row, in one [PairCard]. Shown for every pairing that can take payments. [busy] marks the
/// row whose change is being written: [BusyRow.seal] or [BusyRow.allow]; the other row stays
/// usable.
///
/// Under the result's title and body:
/// ```dart
/// PairMatchedCard(
///   name: name,
///   seal: record.seal != SealMode.off,
///   onSeal: (v) => ...,
///   allow: record.allowInvoices,
///   offLine: l.sasAllowOffLine(name),
///   onAllow: (v) => ...,
///   busy: _busyRow,
///   allowKey: resultAllowKey,
/// )
/// ```
class PairMatchedCard extends StatelessWidget {
  const PairMatchedCard({
    super.key,
    required this.name,
    this.seal,
    this.onSeal,
    required this.allow,
    required this.offLine,
    this.onLine,
    this.onAllow,
    this.busy,
    this.sealKey,
    this.allowKey,
  });

  final String name;

  /// The seal switch's value; null hides the row.
  final bool? seal;
  final ValueChanged<bool>? onSeal;
  final bool allow;
  final String offLine;
  final String? onLine;
  final ValueChanged<bool>? onAllow;

  /// The row whose change is in flight, if any.
  final BusyRow? busy;
  final Key? sealKey;
  final Key? allowKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PairCard(
      children: [
        if (seal case final s?)
          PairLiveSwitchRow(
            switchKey: sealKey,
            label: l.contactSealPayments,
            info: l.contactSealTip(name),
            value: s,
            busy: busy == BusyRow.seal,
            onChanged: onSeal,
          ),
        PairAllowRow(
          switchKey: allowKey,
          name: name,
          value: allow,
          offLine: offLine,
          onLine: onLine,
          busy: busy == BusyRow.allow,
          onChanged: onAllow,
        ),
      ],
    );
  }
}

/// Which row of a [PairMatchedCard] is writing its change.
enum BusyRow { seal, allow }
