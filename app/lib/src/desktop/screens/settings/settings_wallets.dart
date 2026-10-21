import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

class SettingsWalletsScreen extends ConsumerWidget {
  const SettingsWalletsScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(deskProvider.select((s) => s.wallets));
    final nav = ref.read(deskNavProvider.notifier);
    final c = context.dc;
    final ts = context.ts;
    return SettingsFrame(
      route: DeskRoute.settingsWallets,
      child: wallets == null
          ? const SettingsLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ESetGroup(
                  title: 'Wallets on this computer',
                  rows: wallets.isEmpty
                      ? [const ESetRow(title: 'No wallets found', text: 'Add an existing wallet folder or import wallets.')]
                      : [
                          for (final w in wallets)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
                              child: Row(
                                children: [
                                  EAvatar(w.name),
                                  const SizedBox(width: Sp.x3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(w.name, style: ts.strong, overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: Sp.x2),
                                            ETag(w.network),
                                          ],
                                        ),
                                        Text(w.folder, style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Sp.x3),
                                  w.current
                                      ? const ETag('Current', tone: ETone.gold, icon: EIcons.check)
                                      : EButton(label: 'Switch', size: EBtnSize.sm, onPressed: () => nav.reset(DeskRoute.unlock)),
                                ],
                              ),
                            ),
                        ],
                ),
                Wrap(
                  spacing: Sp.x3,
                  runSpacing: Sp.x3,
                  children: [
                    EButton(label: 'Add existing', icon: EIcons.plus, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.found)),
                    EButton(label: 'Import wallets', icon: EIcons.fileDown, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.importWallets)),
                  ],
                ),
              ],
            ),
    );
  }
}
