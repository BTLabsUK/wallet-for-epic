// SPDX-License-Identifier: Apache-2.0
/// Desktop: the Allow invoices switch as the one place it is decided, after the words matched
/// (the verified result dialog, or the save dialog of an unsaved contact) and on the contact
/// page. Same content and states as the phone's `ui/pairing/pair_allow_row.dart`: off by
/// default; the line under the title says the state in words (off, the hint while on, "Finish
/// the key check first" while a key check is open); a change in flight shows the asked-for
/// position with a spinner beside the switch and keeps the row's colour.
///
/// Nothing from the other wallet is shown but its name: the payer decides alone.
library;

import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The verified result dialog's Done button.
const Key deskMatchedDoneKey = ValueKey('desk-matched-done');

/// The Allow invoices switch on the verified result (both dialogs).
const Key deskMatchedAllowKey = ValueKey('desk-matched-allow');

/// The seal switch on the verified result (both dialogs).
const Key deskMatchedSealKey = ValueKey('desk-matched-seal');

/// An [ESetRow] with a switch whose line follows its state and that shows its work while a
/// change is written:
///
/// - [busy]: the switch shows the position the user asked for, an [ESpinner] sits before it
///   and clicks are ignored; the words keep their colour. When [busy] ends the switch shows
///   [value] again, so a failed write snaps back by itself.
/// - [lockedLine]: the switch is disabled (the [ESwitch] disabled look) and the line says why.
///
/// A null [onChanged] disables the switch too, with [line] as its explanation. The line's
/// height change runs at [Motion.expand], one frame under reduced motion.
class DeskLiveSwitchRow extends StatefulWidget {
  const DeskLiveSwitchRow({
    super.key,
    required this.title,
    required this.value,
    this.hint,
    this.line,
    this.lockedLine,
    this.busy = false,
    this.onChanged,
    this.switchKey,
    this.semanticsId,
  });

  final String title;
  final bool value;

  /// The ⓘ popover's text; null for none.
  final String? hint;

  /// The line under the title in the usable states (the state in words).
  final String? line;

  /// Set while the switch may not be used (an open key check): shown in place of [line], and
  /// the switch is disabled.
  final String? lockedLine;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final Key? switchKey;
  final String? semanticsId;

  @override
  State<DeskLiveSwitchRow> createState() => _DeskLiveSwitchRowState();
}

class _DeskLiveSwitchRowState extends State<DeskLiveSwitchRow> {
  /// The position the user asked for, shown while [DeskLiveSwitchRow.busy].
  bool? _pending;

  @override
  void didUpdateWidget(DeskLiveSwitchRow old) {
    super.didUpdateWidget(old);
    if (!widget.busy || widget.value != old.value) _pending = null;
  }

  void _toggle(bool v) {
    setState(() => _pending = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null && widget.lockedLine == null;
    final shown = widget.busy && _pending != null ? _pending! : widget.value;
    final line = widget.lockedLine ?? widget.line;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: reduce ? Duration.zero : Motion.expand,
      curve: Motion.easeOut,
      alignment: AlignmentDirectional.topStart,
      child: ESetRow(
        title: widget.title,
        text: line,
        hint: widget.hint,
        hintTitle: widget.title,
        control: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.busy) ...[
              const ExcludeSemantics(child: ESpinner()),
              SizedBox(width: Sp.x2),
            ],
            IgnorePointer(
              ignoring: widget.busy,
              child: ESwitch(
                key: widget.switchKey,
                value: shown,
                semanticLabel: widget.title,
                semanticsId: widget.semanticsId,
                // Busy keeps the enabled look; a second click or Space does nothing until the
                // write ends.
                onChanged: !enabled ? null : (widget.busy ? (_) {} : _toggle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Allow invoices row: off by default; while off the line is [offLine] ("Invoices from
/// {name} are off."); while on, [onLine], which defaults to `l.sasAllowInvoicesHint(name)`;
/// while a key check is open, [lockedLine] ("Finish the key check first") and the switch is
/// disabled. The ⓘ carries `contactAllowInfoDesktop` (the wallet password, not a PIN).
///
/// [name] is the contact's name as this wallet calls it (never a name the other wallet sent).
class DeskAllowRow extends StatelessWidget {
  const DeskAllowRow({
    super.key,
    required this.name,
    required this.value,
    required this.offLine,
    this.onLine,
    this.lockedLine,
    this.busy = false,
    this.onChanged,
    this.switchKey,
    this.semanticsId,
  });

  final String name;
  final bool value;
  final String offLine;
  final String? onLine;
  final String? lockedLine;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final Key? switchKey;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DeskLiveSwitchRow(
      title: l.contactAllowInvoices,
      hint: l.contactAllowInfoDesktop(name),
      value: value,
      line: value ? (onLine ?? l.sasAllowInvoicesHint(name)) : offLine,
      lockedLine: lockedLine,
      busy: busy,
      onChanged: onChanged,
      switchKey: switchKey,
      semanticsId: semanticsId,
    );
  }
}

/// Which row of a [DeskMatchedGroup] is writing its change.
enum DeskBusyRow { seal, allow }

/// The verified result's rows in one [ESetGroup]: the seal row (when [seal] is given) over
/// the Allow invoices row. Goes into [DeskMatchedDialog] and, for an unsaved contact, into
/// `DeskPairedSaveDialog`'s body between the body text and the "Save as" label (standard and
/// wide dialog widths leave the words well over [setRowMinWords], so the switch stays beside
/// them). [busy] marks the row whose change is being written; the other stays usable.
class DeskMatchedGroup extends StatelessWidget {
  const DeskMatchedGroup({
    super.key,
    required this.name,
    this.seal,
    this.onSeal,
    required this.allow,
    required this.offLine,
    this.onLine,
    this.onAllow,
    this.busy,
    this.sealKey = deskMatchedSealKey,
    this.allowKey = deskMatchedAllowKey,
  });

  final String name;

  /// The seal switch's value; null hides the row.
  final bool? seal;
  final ValueChanged<bool>? onSeal;
  final bool allow;
  final String offLine;
  final String? onLine;
  final ValueChanged<bool>? onAllow;
  final DeskBusyRow? busy;
  final Key? sealKey;
  final Key? allowKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ESetGroup(
      gap: false,
      rows: [
        if (seal case final s?)
          DeskLiveSwitchRow(
            title: l.contactSealPayments,
            hint: l.contactSealTip(name),
            value: s,
            busy: busy == DeskBusyRow.seal,
            onChanged: onSeal,
            switchKey: sealKey,
          ),
        DeskAllowRow(
          name: name,
          value: allow,
          offLine: offLine,
          onLine: onLine,
          busy: busy == DeskBusyRow.allow,
          onChanged: onAllow,
          switchKey: allowKey,
        ),
      ],
    );
  }
}

/// The verified result for a saved contact (today a toast): title "{name} is verified", the
/// body line, the seal and Allow invoices rows, Done. Same content as the phone result.
/// Opened with `showEDialog(host, builder: (_) => DeskMatchedDialog(...))` after the words
/// matched; the caller rebuilds it (a `StatefulBuilder` or the record's provider) as [allow],
/// [seal] and [busy] change.
class DeskMatchedDialog extends StatelessWidget {
  const DeskMatchedDialog({
    super.key,
    required this.name,
    this.isService = false,
    this.seal,
    this.onSeal,
    required this.allow,
    required this.offLine,
    this.onLine,
    this.onAllow,
    this.busy,
    this.doneKey = deskMatchedDoneKey,
  });

  final String name;

  /// The peer stated it is automated: adds the `pairIsService` line.
  final bool isService;
  final bool? seal;
  final ValueChanged<bool>? onSeal;
  final bool allow;
  final String offLine;
  final String? onLine;
  final ValueChanged<bool>? onAllow;
  final DeskBusyRow? busy;
  final Key? doneKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return EDialog(
      title: l.sasMatchedTitle(name),
      tone: ETone.ok,
      icon: EIcons.trusted,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.sasMatchedBody(name), style: ts.bodyDim),
          if (isService) ...[
            SizedBox(height: Sp.x1),
            Text(l.pairIsService, style: ts.bodyDim),
          ],
          SizedBox(height: Sp.x4),
          DeskMatchedGroup(
            name: name,
            seal: seal,
            onSeal: onSeal,
            allow: allow,
            offLine: offLine,
            onLine: onLine,
            onAllow: onAllow,
            busy: busy,
          ),
        ],
      ),
      actions: [
        EButton.primary(key: doneKey, label: l.commonDone, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
