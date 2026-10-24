/// The details a user may add to a payment a scan found: who paid, how it came, a note.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart' show ContactsScreen;
import 'method_names.dart';
import 'theme/tokens.dart';

/// The longest note a payment takes, in characters.
const int txNoteMaxLength = 500;

/// What the sheet hands back: each field as typed, null where it is empty.
typedef TxDetailsInput = ({
  String? counterparty,
  String? transport,
  String? note,
});

/// Opens the sheet for [tx] and returns the details the user saved, or null when they cancelled.
Future<TxDetailsInput?> showTxDetailsSheet(BuildContext context, TxEntry tx) =>
    showModalBottomSheet<TxDetailsInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TxDetailsSheet(tx: tx),
    );

class _TxDetailsSheet extends ConsumerStatefulWidget {
  const _TxDetailsSheet({required this.tx});

  final TxEntry tx;

  @override
  ConsumerState<_TxDetailsSheet> createState() => _TxDetailsSheetState();
}

class _TxDetailsSheetState extends ConsumerState<_TxDetailsSheet> {
  late final _from = TextEditingController(
    text: widget.tx.manualFields.contains(ManualField.counterparty)
        ? widget.tx.counterparty
        : '',
  );
  late final _note = TextEditingController(
    text: widget.tx.manualFields.contains(ManualField.note)
        ? widget.tx.note
        : '',
  );
  late String? _transport =
      widget.tx.manualFields.contains(ManualField.transport)
      ? widget.tx.transport
      : null;
  String? _fromError;

  @override
  void dispose() {
    _from.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => const ContactsScreen(pick: true),
      ),
    );
    if (contact == null || !mounted) return;
    setState(() {
      _from.text = contact.address;
      _fromError = null;
    });
  }

  void _save() {
    final l = context.l10n;
    final raw = _from.text.trim();
    String? from;
    if (raw.isNotEmpty) {
      final problem = checkRecipient(l, ref.read(walletServiceProvider), raw);
      if (problem != null) {
        setState(() => _fromError = problem);
        return;
      }
      from = parseRecipient(raw).address;
    }
    final note = _note.text.trim();
    Navigator.pop<TxDetailsInput>(context, (
      counterparty: from,
      transport: _transport,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final tx = widget.tx;
    final editing = tx.manualFields.any((f) => f != ManualField.label);
    final date = formatDateTime(l, localTime(tx.blockTimeUnix ?? tx.timeUnix));
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? l.txEditEdit : l.txEditAdd,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _from,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                if (_fromError != null) setState(() => _fromError = null);
              },
              decoration: InputDecoration(
                labelText: l.txEditFrom,
                hintText: l.txEditFromHint,
                helperText: l.txEditFromHelper,
                helperMaxLines: 2,
                errorText: _fromError,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: l.sendChooseContactTooltip,
                  icon: const Icon(Icons.people_outline),
                  onPressed: _pickContact,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.sendMethodLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label: l.sendMethodLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in const [
                    null,
                    'epicbox',
                    'http',
                    'tor',
                    'file',
                  ])
                    ChoiceChip(
                      label: Text(txMethodWord(l, m)),
                      selected: _transport == m,
                      onSelected: (_) => setState(() => _transport = m),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: t.dim),
                const SizedBox(width: 8),
                Text('${l.txDetailsDate}  ', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Text(
                    date,
                    style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              maxLength: txNoteMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.txDetailsNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _save,
                    child: Text(l.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
