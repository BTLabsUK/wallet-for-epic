// SPDX-License-Identifier: Apache-2.0
/// The warning before the first import of wallets from older software (Welcome and All wallets
/// › Import wallets; our own history backup needs none):
/// an early version, the import only reads, have a backup of every wallet, at your own risk.
/// It shows once per install ([DeskSettings.importWarningSeen], saved with the app's
/// settings in the data folder); Help › Keeping the wallet safe › Before you import keeps the
/// same words. Cancel changes nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/desk_store.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// Runs [go] once the warning was acknowledged: now, or at an earlier import. Does nothing when
/// the user cancels.
Future<void> importAfterWarning(BuildContext context, WidgetRef ref, VoidCallback go) async {
  if (!ref.read(deskProvider).settings.importWarningSeen && !ref.read(deskBootProvider).settings.importWarningSeen) {
    final ok = await showImportWarningDialog(context);
    if (ok != true || !context.mounted) return;
    ref.read(deskProvider.notifier).holdImportWarningSeen();
    try {
      await ref.read(deskStoreProvider)?.saveImportWarningSeen();
    } on Object catch (e) {
      // Shown again next time, at worst.
      logWarn('desk', 'import warning seen not saved: ${e.runtimeType}');
    }
    if (!context.mounted) return;
  }
  go();
}

/// The warning dialog on its own. Pops true once the user ticked "I have a backup" and chose
/// Continue; false or null otherwise.
Future<bool?> showImportWarningDialog(BuildContext context) => showEDialog<bool>(context, builder: (_) => const ImportWarningDialog());

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
    final ts = context.ts;
    return EDialog(
      title: l.importWarnTitle,
      description: '${l.importWarnEarly} ${l.importWarnReads}',
      icon: EIcons.shield,
      tone: ETone.info,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.importWarnBackup, style: ts.body),
          SizedBox(height: Sp.x3),
          Text(l.importWarnRiskPlain, style: ts.body),
          SizedBox(height: Sp.x5),
          ECheckbox(value: _ack, onChanged: (v) => setState(() => _ack = v), label: l.importWarnAck),
        ],
      ),
      actions: [
        EButton.ghost(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(label: l.commonContinue, onPressed: _ack ? () => Navigator.pop(context, true) : null),
      ],
    );
  }
}
