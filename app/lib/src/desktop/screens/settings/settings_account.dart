import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'dialogs.dart';
import 'settings_frame.dart';

class SettingsAccountScreen extends ConsumerWidget {
  const SettingsAccountScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(deskProvider.select((s) => s.account));
    if (a == null) return const SettingsFrame(route: DeskRoute.settingsAccount, child: SettingsLoading());
    final c = context.dc;
    final ts = context.ts;
    return SettingsFrame(
      route: DeskRoute.settingsAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: 'This wallet',
            rows: [
              ESetRow(title: 'Name', text: 'Only shown in this app.', control: Text(a.name, style: ts.strong)),
              ESetRow(title: 'Network', text: 'Set when the wallet was created.', control: ETag(a.network, tone: a.network == 'mainnet' ? ETone.gold : ETone.neutral)),
              ESetRow(
                title: 'Folder',
                stacked: true,
                control: Row(
                  children: [
                    Expanded(child: Text(a.folder, style: ts.mono(size: Fs.sm, color: c.dim), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: Sp.x3),
                    EButton(label: 'Open folder', icon: EIcons.folderOpen, size: EBtnSize.inline, onPressed: () => showEToast(context, 'Opening folder', text: a.folder)),
                  ],
                ),
              ),
            ],
          ),
          ESetGroup(
            title: 'Security',
            rows: [
              ESetRow(
                title: 'Password',
                text: 'Unlocks this wallet.',
                control: EButton(label: 'Change password…', size: EBtnSize.sm, icon: EIcons.key, onPressed: () => showChangePasswordDialog(context)),
              ),
            ],
          ),
          ESetGroup(
            title: 'Remove',
            rows: [
              ESetRow(
                title: 'Remove wallet',
                text: 'Deletes the wallet from this computer. The recovery phrase restores it.',
                control: EButton(label: 'Remove wallet…', size: EBtnSize.sm, kind: EBtnKind.danger, icon: EIcons.trash, onPressed: () => showRemoveWalletDialog(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
