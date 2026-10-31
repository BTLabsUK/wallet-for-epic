// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../data/method_names.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../wallet/tx_display.dart';

/// Opens "Details differ" over the import: a history backup has other values than ones the user
/// typed. Resolves to the choices by [ImportConflict.id] (true: the backup's value; false: keep
/// the user's), or null when the user cancelled and nothing may be written. With [oldWallet] the
/// other side is the old wallet's history (epic-wallet) instead of a backup file.
Future<Map<String, bool>?> showHistoryConflicts(BuildContext context, List<ImportConflict> conflicts, {bool oldWallet = false}) =>
    showEDialog<Map<String, bool>>(
      context,
      dismissible: false,
      builder: (_) => HistoryConflictsDialog(conflicts: conflicts, oldWallet: oldWallet),
    );

class HistoryConflictsDialog extends StatefulWidget {
  const HistoryConflictsDialog({super.key, required this.conflicts, this.oldWallet = false});

  final List<ImportConflict> conflicts;

  /// The values come from the old wallet's history, not from a backup file.
  final bool oldWallet;

  @override
  State<HistoryConflictsDialog> createState() => _HistoryConflictsDialogState();
}

class _HistoryConflictsDialogState extends State<HistoryConflictsDialog> {
  /// By [ImportConflict.id]; every field starts as the user's own.
  late final Map<String, bool> _useBackup = {for (final c in widget.conflicts) c.id: false};

  Map<String, bool> get _keepAll => {for (final c in widget.conflicts) c.id: false};

  /// The conflicts of each payment, in the order the import reported them.
  Map<String, List<ImportConflict>> get _byPayment {
    final out = <String, List<ImportConflict>>{};
    for (final c in widget.conflicts) {
      (out[c.key] ??= []).add(c);
    }
    return out;
  }

  String _fieldName(AppLocalizations l, ManualField f) => switch (f) {
    ManualField.label => l.deskTxLabelField,
    ManualField.counterparty => l.deskTxDetailsFrom,
    ManualField.transport => l.deskTxFactMethod,
    ManualField.note => l.deskTxDetailsNote,
  };

  /// The value as the dialog shows it; transports in words.
  String? _valueText(AppLocalizations l, ManualField f, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (f != ManualField.transport) return v;
    return methodLabelOfTransport(l, v);
  }

  Widget _card(BuildContext context, ImportConflict c, {required bool backup}) {
    final l = context.l10n;
    final ts = context.ts;
    final dc = context.dc;
    final text = _valueText(l, c.field, backup ? c.theirs : c.mine);
    final mono = c.field == ManualField.counterparty;
    return EChoiceCard(
      title: backup ? (widget.oldWallet ? l.deskHistConflictOldWallet : l.deskHistConflictBackup) : l.deskHistConflictMine,
      icon: backup ? EIcons.archive : EIcons.pencil,
      selected: _useBackup[c.id] == backup,
      onTap: () => setState(() => _useBackup[c.id] = backup),
      tag: text == null
          ? Text(l.deskHistConflictEmpty, style: ts.small.copyWith(color: dc.faint, fontStyle: FontStyle.italic))
          : Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: mono ? ts.mono(size: Fs.xs) : ts.body),
    );
  }

  Widget _payment(BuildContext context, List<ImportConflict> list) {
    final l = context.l10n;
    final ts = context.ts;
    final dc = context.dc;
    final first = list.first;
    final when = DateTime.fromMillisecondsSinceEpoch(first.timeUnix * 1000);
    return Container(
      padding: EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: dc.s1,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: dc.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EMoney(first.amount.toInt(), sign: true, size: Fs.md, color: first.amount.isNegative ? dc.text : dc.ok),
              SizedBox(width: Sp.x3),
              Text(shortDay(l, when), style: ts.small),
            ],
          ),
          for (final c in list) ...[
            SizedBox(height: Sp.x3),
            Semantics(container: true, label: _fieldName(l, c.field), child: Text(_fieldName(l, c.field), style: ts.label)),
            SizedBox(height: Sp.x2),
            LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= Lay.xs;
                final mine = _card(context, c, backup: false);
                final theirs = _card(context, c, backup: true);
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: mine),
                          SizedBox(width: Sp.x3),
                          Expanded(child: theirs),
                        ],
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [mine, SizedBox(height: Sp.x2), theirs]);
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final payments = _byPayment.values.toList();
    return EDialog(
      title: l.deskHistConflictTitle,
      description: widget.oldWallet ? l.deskHistConflictLeadOldWallet(payments.length) : l.deskHistConflictLead(payments.length),
      icon: EIcons.archive,
      width: 600.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in payments.indexed) ...[if (i > 0) SizedBox(height: Sp.x3), _payment(context, p)],
        ],
      ),
      actions: [
        // The phone's order: Cancel as text first, Keep all mine, Import last.
        EButton.ghost(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton(label: l.deskHistConflictKeepAll, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop(_keepAll)),
        EButton.primary(label: widget.oldWallet ? l.deskHistConflictApply : l.deskHistConflictImport, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop({..._useBackup})),
      ],
    );
  }
}
