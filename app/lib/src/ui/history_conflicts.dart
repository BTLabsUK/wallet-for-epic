/// "Details differ": what a history backup says about payments the user described here, when it
/// says something else. Per value two cards, Mine (chosen at first) and Backup.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'theme/tokens.dart';
import 'method_names.dart' show txMethodWord;

/// The choices to import with, by [ImportConflict.id] (true takes the backup's value), or null
/// when the user cancelled and nothing is to be written.
Future<Map<String, bool>?> showImportConflicts(
  BuildContext context,
  List<ImportConflict> conflicts,
) => showModalBottomSheet<Map<String, bool>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
  ),
  builder: (_) => _ConflictSheet(conflicts: conflicts),
);

String _fieldName(AppLocalizations l, ManualField field) => switch (field) {
  ManualField.label => l.txLabel,
  ManualField.counterparty => l.txEditFrom,
  ManualField.transport => l.sendMethodLabel,
  ManualField.note => l.txDetailsNoteLabel,
};

class _ConflictSheet extends StatefulWidget {
  const _ConflictSheet({required this.conflicts});

  final List<ImportConflict> conflicts;

  @override
  State<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends State<_ConflictSheet> {
  /// The ids the user switched to the backup; everything else stays theirs.
  final _backup = <String>{};

  Map<String, bool> get _choices => {
    for (final c in widget.conflicts) c.id: _backup.contains(c.id),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final byPayment = <String, List<ImportConflict>>{};
    for (final c in widget.conflicts) {
      byPayment.putIfAbsent(c.key, () => []).add(c);
    }
    final payments = byPayment.values.toList();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Semantics(
              header: true,
              child: Text(
                l.histConflictTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.histConflictLead(payments.length)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              children: [
                for (final payment in payments) ...[
                  const SizedBox(height: 8),
                  _PaymentHeading(first: payment.first),
                  for (final c in payment)
                    _ConflictRow(
                      conflict: c,
                      backup: _backup.contains(c.id),
                      onChoose: (backup) => setState(
                        () => backup ? _backup.add(c.id) : _backup.remove(c.id),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(context, {
                          for (final c in widget.conflicts) c.id: false,
                        }),
                        child: Text(l.histConflictKeepAll),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context, _choices),
                  child: Text(l.histConflictImport),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Which payment the values belong to: its day and its amount.
class _PaymentHeading extends StatelessWidget {
  const _PaymentHeading({required this.first});

  final ImportConflict first;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final amount = first.amount;
    final sign = amount.isNegative ? '-' : '+';
    return Semantics(
      header: true,
      child: Text(
        '${formatDateTime(l, localTime(first.timeUnix))} · $sign${epicText(l, amount.abs())}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({
    required this.conflict,
    required this.backup,
    required this.onChoose,
  });

  final ImportConflict conflict;
  final bool backup;
  final ValueChanged<bool> onChoose;

  String? _shown(AppLocalizations l, String? value) {
    if (value == null || value.isEmpty) return null;
    return conflict.field == ManualField.transport
        ? txMethodWord(l, value)
        : value;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fieldName(l, conflict.field),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ChoiceCard(
                    title: l.histConflictMine,
                    value: _shown(l, conflict.mine),
                    selected: !backup,
                    onTap: () => onChoose(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceCard(
                    title: l.histConflictBackup,
                    value: _shown(l, conflict.theirs),
                    selected: backup,
                    onTap: () => onChoose(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two values, a radio card: the whole card selects, 48 dp tall at least.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;

  /// The value, or null when it is empty.
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final text = value ?? l.histConflictEmpty;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title: $text',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? t.accentSoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? t.accent : t.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: selected ? t.accent : t.dim,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: value == null
                        ? theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: t.dim,
                          )
                        : theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
