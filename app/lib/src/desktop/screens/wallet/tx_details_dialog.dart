// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../transfer/contact_picker.dart';
import 'tx_display.dart';

/// The longest private note the wallet keeps, in characters.
const int txNoteMaxLength = 500;

/// Opens the dialog where the user adds what they know of a payment a scan found: who paid,
/// how it came, a note. Only for [Tx.restored] rows; the label is edited in place.
Future<void> showTxDetailsDialog(BuildContext context, Tx t) => showEDialog<void>(context, builder: (_) => TxDetailsDialog(tx: t));

class TxDetailsDialog extends ConsumerStatefulWidget {
  const TxDetailsDialog({super.key, required this.tx});

  final Tx tx;

  @override
  ConsumerState<TxDetailsDialog> createState() => _TxDetailsDialogState();
}

class _TxDetailsDialogState extends ConsumerState<TxDetailsDialog> {
  late final TextEditingController _from = TextEditingController(text: widget.tx.counterparty ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.tx.note ?? '');

  /// The method's transport name, or '' for unknown.
  late String _via = widget.tx.transport ?? '';
  bool _busy = false;
  bool _badFrom = false;

  /// Details exist already: the dialog edits them.
  late final bool _had = widget.tx.manualFields.any((f) => f != ManualField.label);

  @override
  void dispose() {
    _from.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final contact = await showContactPicker(context);
    if (contact == null || !mounted) return;
    setState(() {
      _from.text = contact.address;
      _badFrom = false;
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    final t = widget.tx;
    final typed = _from.text.trim();
    final parsed = typed.isEmpty ? null : parseAddress(typed, ref.read(deskApiProvider));
    if (parsed != null && parsed.kind == AddressKind.none) {
      setState(() => _badFrom = true);
      return;
    }
    final from = parsed?.canonical ?? '';
    final note = _note.text.trim();
    final changed = from != (t.counterparty ?? '') || _via != (t.transport ?? '') || note != (t.note ?? '');
    if (!changed) return Navigator.of(context).pop();
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).setTxDetails(t.key, counterparty: from, transport: _via, note: note);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, l.deskTxDetailsNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    final empty = from.isEmpty && _via.isEmpty && note.isEmpty;
    showEToast(context, empty ? l.deskTxDetailsRemoved : (_had ? l.deskTxDetailsSaved : l.deskTxDetailsAdded), tone: ETone.ok);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: _had ? l.deskTxDetailsTitleEdit : l.deskTxDetailsTitleAdd,
      description: l.deskTxDetailsTip,
      icon: EIcons.pencil,
      width: 560.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskTxFactMethod,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ESegmented<String>(
                  segments: [
                    ESegment('', l.deskKitUnknown),
                    // The build without Tor lists Link · Tor only for a payment that already says it.
                    for (final m in TxMethod.values)
                      if (DeskFeatures.tor || m != TxMethod.tor || widget.tx.transport == m.name) ESegment(m.name, methodLabel(l, m)),
                  ],
                  value: _via,
                  onChanged: _busy ? (_) {} : (v) => setState(() => _via = v),
                ),
              ),
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskTxDetailsFrom,
            labelTrailing: Padding(
              padding: EdgeInsets.only(left: Sp.x1),
              child: EInfoHint(l.deskTxDetailsFromTip),
            ),
            error: _badFrom ? (DeskFeatures.tor ? l.deskTxDetailsFromBad : l.deskNoTorTxDetailsFromBad) : null,
            child: EInput(
              controller: _from,
              mono: true,
              hint: l.deskTxDetailsFromHint,
              invalid: _badFrom,
              enabled: !_busy,
              semanticLabel: l.deskTxDetailsFrom,
              onChanged: (_) => setState(() => _badFrom = false),
              trailing: EButton(label: l.deskSendPickTitle, icon: EIcons.contacts, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: _busy ? null : _pick),
              trailingTabStop: true,
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskTxDetailsNote,
            child: EInput(
              controller: _note,
              maxLines: 3,
              enabled: !_busy,
              semanticLabel: l.deskTxDetailsNote,
              inputFormatters: [LengthLimitingTextInputFormatter(txNoteMaxLength)],
            ),
          ),
          SizedBox(height: Sp.x1),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: l.commonSave, size: EBtnSize.sm, busy: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }
}
