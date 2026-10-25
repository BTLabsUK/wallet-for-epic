/// The warning before the first import of a file (the history backup): an early version, the
/// import only reads, have a backup of every wallet, at your own risk. It shows once per
/// install ([AppSettings.importWarningSeen]); Help › Keeping the wallet safe › Before you
/// import keeps the same words. Cancel changes nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../settings.dart';

/// True once the warning was acknowledged: now, or at an earlier import.
Future<bool> confirmImportWarning(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(appSettingsProvider).value;
  if (settings?.importWarningSeen ?? false) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const ImportWarningDialog(),
  );
  if (ok != true) return false;
  await ref.read(appSettingsProvider.notifier).markImportWarningSeen();
  return true;
}

class ImportWarningDialog extends StatefulWidget {
  const ImportWarningDialog({super.key});

  @override
  State<ImportWarningDialog> createState() => _ImportWarningDialogState();
}

class _ImportWarningDialogState extends State<ImportWarningDialog> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = Theme.of(context).textTheme.bodyMedium;
    return AlertDialog(
      title: Text(l.importWarnTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.importWarnEarly} ${l.importWarnReads}', style: body),
          const SizedBox(height: 12),
          Text(l.importWarnBackup, style: body),
          const SizedBox(height: 12),
          Text(l.importWarnRisk, style: body),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _ack,
            onChanged: (v) => setState(() => _ack = v ?? false),
            title: Text(l.importWarnAck),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _ack ? () => Navigator.pop(context, true) : null,
          child: Text(l.commonContinue),
        ),
      ],
    );
  }
}
