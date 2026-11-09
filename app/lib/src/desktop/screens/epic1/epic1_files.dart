// SPDX-License-Identifier: Apache-2.0
/// Files and pasted texts across the two payment modes (spec D1, Files): the mode line with
/// [Settings] [Close] for what this mode cannot open, and the way a `.epictx` opens in epic1
/// mode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../in_person/in_person_entry.dart' show openDeskInPersonText;
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/setting_ids.dart';
import '../transfer/finalize_screen.dart' show FinalizeArgs;
import '../transfer/import_tx_screen.dart' show ImportArgs;

/// Opens Settings › Transactions with the epic1 payments switch in view.
void jumpToEpic1Switch(WidgetRef ref) => ref.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);

/// [text], a mode line ("epic1 file. Turn on epic1 payments to open it."), with [Settings]
/// (the switch) and [Close].
Future<void> showEpic1ModeDialog(BuildContext context, WidgetRef ref, String text) async {
  final settings = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      key: const ValueKey('e1-mode-dialog'),
      title: text,
      icon: EIcons.file,
      actions: [
        EButton(key: const ValueKey('e1-mode-settings'), label: ctx.l10n.deskRecvSettings, icon: EIcons.settings, onPressed: () => Navigator.pop(ctx, true)),
        EButton.primary(label: ctx.l10n.commonClose, autofocus: true, onPressed: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  if (settings == true) jumpToEpic1Switch(ref);
}

/// epic1 mode: a `.epictx` file's text or pasted `BEGINEPICTX.` text. An in-person code or
/// answer goes to its flow; any other payment to Import transaction or Finalize.
Future<void> openDeskEpictx(BuildContext context, WidgetRef ref, String text) async {
  final api = ref.read(deskApiProvider);
  final e1 = api.epic1;
  if (e1 == null) return;
  final nav = ref.read(deskNavProvider.notifier);
  try {
    final opened = await e1.openEpictx(text);
    if (!context.mounted) return;
    if (await openDeskInPersonText(context, text)) return;
    if (await api.isResponseText(opened.slateJson)) {
      nav.go(DeskRoute.finalize, FinalizeArgs(text: opened.slateJson));
    } else {
      nav.go(DeskRoute.importTx, ImportArgs(text: opened.slateJson));
    }
  } on Object catch (e) {
    if (context.mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
  }
}
