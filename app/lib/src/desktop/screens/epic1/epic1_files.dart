// SPDX-License-Identifier: Apache-2.0
/// What epic1 does with files and pasted texts: the stop for an epic1 thing while the
/// payment settings have epic1 off (with [Settings] to the switch), and the way a `.epictx`
/// opens when it is on.
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

/// Opens Settings › Payments with the epic1 switch in view.
void jumpToEpic1Switch(WidgetRef ref) => ref.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);

/// [jumpToEpic1Switch] where only a container is at hand.
void jumpToEpic1SwitchIn(ProviderContainer c) => c.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);

/// The stop for an epic1 link, in-person code or file while epic1 is off: "epic1 is off in
/// the payment settings." with [Settings] (the switch) and [Close].
Future<void> showEpic1OffStop(BuildContext context, WidgetRef ref) =>
    showEpic1OffStopIn(context, () => jumpToEpic1Switch(ref));

/// [showEpic1OffStop] where no [WidgetRef] is at hand: [jump] opens the switch.
Future<void> showEpic1OffStopIn(BuildContext context, [void Function()? jump]) async {
  final settings = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      key: const ValueKey('e1-mode-dialog'),
      title: ctx.l10n.netBlockMethodOff(ctx.l10n.deskE1SetSwitch),
      icon: EIcons.file,
      actions: [
        EButton(key: const ValueKey('e1-mode-settings'), label: ctx.l10n.deskRecvSettings, icon: EIcons.settings, onPressed: () => Navigator.pop(ctx, true)),
        EButton.primary(label: ctx.l10n.commonClose, autofocus: true, onPressed: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  if (settings != true) return;
  if (jump != null) {
    jump();
  } else if (context.mounted) {
    ProviderScope.containerOf(context, listen: false).read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);
  }
}

/// A `.epictx` file's text or pasted `BEGINEPICTX.` text. An in-person code or
/// answer goes to its flow; any other payment to Import transaction or Finalize. With epic1
/// off it stops with the off line. True when the text was opened.
Future<bool> openDeskEpictx(BuildContext context, WidgetRef ref, String text) async {
  final api = ref.read(deskApiProvider);
  final e1 = api.epic1;
  if (e1 == null || !ref.read(deskEpic1OnProvider)) {
    await showEpic1OffStop(context, ref);
    return false;
  }
  final nav = ref.read(deskNavProvider.notifier);
  try {
    final opened = await e1.openEpictx(text);
    if (!context.mounted) return false;
    if (await openDeskInPersonText(context, text)) return true;
    if (await api.isResponseText(opened.slateJson)) {
      nav.go(DeskRoute.finalize, FinalizeArgs(text: opened.slateJson));
    } else {
      nav.go(DeskRoute.importTx, ImportArgs(text: opened.slateJson));
    }
    return true;
  } on Object catch (e) {
    if (context.mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
    return false;
  }
}
