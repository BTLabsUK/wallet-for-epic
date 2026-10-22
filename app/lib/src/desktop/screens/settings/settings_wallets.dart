import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'dialogs.dart';
import 'settings_frame.dart';

/// Shortens a long folder path in the middle: "~/.epic/…/wallet_data".
String shortPath(String p, {int max = 40}) {
  if (p.length <= max) return p;
  final parts = p.split('/');
  if (parts.length < 4) return '${p.substring(0, max - 1)}…';
  return '${parts.take(2).join('/')}/…/${parts.last}';
}

class SettingsWalletsScreen extends ConsumerStatefulWidget {
  const SettingsWalletsScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsWalletsScreen> createState() => _SettingsWalletsScreenState();
}

class _SettingsWalletsScreenState extends ConsumerState<SettingsWalletsScreen> {
  /// Wallet folders the list lost (removed from the list only).
  List<WalletEntry> _removed = const [];
  String? _adding;

  @override
  void initState() {
    super.initState();
    _findRemoved();
  }

  Future<void> _findRemoved() async {
    try {
      final found = await ref.read(deskApiProvider).findRemoved();
      if (mounted) setState(() => _removed = found);
    } on Object {
      // Nothing to offer.
    }
  }

  Future<void> _addBack(WalletEntry w) async {
    setState(() => _adding = w.id);
    try {
      await ref.read(deskApiProvider).addBack(w.id);
      await ref.read(deskProvider.notifier).loadWallets();
      if (mounted) showEToast(context, '${w.name} added back');
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not added back', text: deskErrorText(e));
    }
    if (mounted) setState(() => _adding = null);
    await _findRemoved();
  }

  Future<void> _openFolder(WalletEntry w) async {
    final ok = Directory(w.folder).existsSync() && await ref.read(deskOpenFolderProvider)(w.folder);
    if (!ok && mounted) showEToast(context, 'Folder not opened', text: w.folder);
  }

  Future<void> _remove(WalletEntry w) async {
    await showRemoveWalletDialog(context, w);
    await _findRemoved();
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'All wallets',
                  rows: [
                    for (final w in wallets)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
                        child: Row(
                          children: [
                            EGlyphTile(size: 36.u, icon: EIcons.wallet),
                            SizedBox(width: Sp.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: Sp.x2,
                                    runSpacing: Sp.x1,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(w.name, style: ts.strong, overflow: TextOverflow.ellipsis),
                                      if (w.network != 'mainnet') ETag(w.network, tone: ETone.warn),
                                      if (w.current) const ETag('Open now', tone: ETone.ok),
                                      if (w.missing) const ETag('Folder missing', tone: ETone.risk),
                                    ],
                                  ),
                                  Tooltip(
                                    message: w.folder,
                                    child: Text(shortPath(w.folder), style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: Sp.x2),
                            EIconButton(
                              icon: EIcons.folderOpen,
                              label: 'Show ${w.name} in its folder',
                              onPressed: () => _openFolder(w),
                            ),
                            w.current
                                ? SizedBox(width: Ctl.sm)
                                : EIconButton(icon: EIcons.trash, label: 'Remove ${w.name}…', onPressed: () => _remove(w)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_removed.isNotEmpty)
                  ESetGroup(
                    title: 'Removed from list',
                    rows: [
                      for (final w in _removed)
                        ESetRow(
                          title: w.name,
                          text: shortPath(w.folder),
                          control: ERowControl(child: EButton(label: 'Add back', size: EBtnSize.sm, busy: _adding == w.id, onPressed: _adding == null ? () => _addBack(w) : null)),
                        ),
                    ],
                  ),
                ESectionHead('Add a wallet', top: 0),
                LayoutBuilder(
                  builder: (context, box) {
                    final cards = [
                      EChoiceCard(
                        title: 'Create a wallet',
                        description: 'A new wallet with a new recovery phrase.',
                        icon: EIcons.plus,
                        selected: false,
                        onTap: () => nav.go(DeskRoute.create),
                      ),
                      if (DeskFeatures.importWizard)
                        EChoiceCard(
                          title: 'Import',
                          description: 'From an older Epic Wallet or a folder.',
                          icon: EIcons.folderOpen,
                          selected: false,
                          onTap: () => nav.go(DeskRoute.importWallets),
                        ),
                      EChoiceCard(
                        title: 'Restore',
                        description: 'From a recovery phrase.',
                        icon: EIcons.backup,
                        selected: false,
                        onTap: () => nav.go(DeskRoute.restore),
                      ),
                    ];
                    if (box.maxWidth < 600.u) {
                      return Column(children: [for (final w in cards) Padding(padding: EdgeInsets.only(bottom: Sp.x3), child: w)]);
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) SizedBox(width: Sp.x3),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
