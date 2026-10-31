// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../onboarding/import_warning.dart';
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
    final l = context.l10n;
    setState(() => _adding = w.id);
    try {
      await ref.read(deskApiProvider).addBack(w.id);
      await ref.read(deskProvider.notifier).loadWallets();
      if (mounted) showEToast(context, l.deskSetWalletsAddedBack(w.name), tone: ETone.ok);
    } on Object catch (e) {
      if (mounted) showEToast(context, l.deskSetWalletsNotAddedBack, text: deskErrorText(e, l), tone: ETone.risk);
    }
    if (mounted) setState(() => _adding = null);
    await _findRemoved();
  }

  Future<void> _openFolder(WalletEntry w) async {
    final l = context.l10n;
    final ok = Directory(w.folder).existsSync() && await ref.read(deskOpenFolderProvider)(w.folder);
    if (!ok && mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: w.folder, tone: ETone.warn);
  }

  Future<void> _remove(WalletEntry w) async {
    await showRemoveWalletDialog(context, w);
    await _findRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  title: l.deskSetFrameAllWallets,
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
                                      if (w.network != 'mainnet' && DeskFeatures.testNetworks) EBadge(w.network, tone: ETone.warn),
                                      if (w.current) EBadge(l.deskSetWalletsOpenNow, tone: ETone.ok),
                                      if (w.missing) EBadge(l.deskSetWalletsFolderMissing, tone: ETone.risk),
                                    ],
                                  ),
                                  ETip.value(
                                    w.folder,
                                    mono: true,
                                    child: Text(shortPath(w.folder), style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: Sp.x2),
                            EIconButton(
                              icon: EIcons.folderOpen,
                              label: l.deskSetWalletsShowFolder(w.name),
                              onPressed: () => _openFolder(w),
                            ),
                            w.current
                                ? SizedBox(width: Ctl.sm)
                                : EIconButton(icon: EIcons.trash, label: l.deskSetWalletsRemove(w.name), onPressed: () => _remove(w)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_removed.isNotEmpty)
                  ESetGroup(
                    title: l.deskSetWalletsRemovedGroup,
                    rows: [
                      for (final w in _removed)
                        ESetRow(
                          title: w.name,
                          text: shortPath(w.folder),
                          control: ERowControl(child: EButton(label: l.deskSetWalletsAddBack, size: EBtnSize.sm, busy: _adding == w.id, onPressed: _adding == null ? () => _addBack(w) : null)),
                        ),
                    ],
                  ),
                ESectionHead(l.deskSetWalletsAdd, top: 0),
                LayoutBuilder(
                  builder: (context, box) {
                    // In a row the title block is two lines tall, so the subtitles align (UD-021).
                    // Three short cards across from Lay.md, else one column (never two and a lone one).
                    final perRow = box.maxWidth >= Lay.md ? 3 : 1;
                    final row = perRow > 1;
                    final cards = [
                      EChoiceCard(
                        titleLines: row ? 2 : null,
                        title: l.deskSetWalletsCreate,
                        description: l.deskSetWalletsCreateText,
                        icon: EIcons.plus,
                        selected: false,
                        onTap: () => nav.go(DeskRoute.create),
                      ),
                      EChoiceCard(
                        titleLines: row ? 2 : null,
                        title: l.deskSetWalletsImport,
                        description: l.deskSetWalletsImportText,
                        icon: EIcons.folderOpen,
                        selected: false,
                        onTap: () => importAfterWarning(context, ref, () => nav.go(DeskRoute.importWallets)),
                      ),
                      EChoiceCard(
                        titleLines: row ? 2 : null,
                        title: l.deskSetWalletsRestore,
                        description: l.deskSetWalletsRestoreText,
                        icon: EIcons.backup,
                        selected: false,
                        onTap: () => nav.go(DeskRoute.restore),
                      ),
                    ];
                    if (!row) {
                      return Column(children: [for (final w in cards) Padding(padding: EdgeInsets.only(bottom: Sp.x3), child: w)]);
                    }
                    return Column(
                      children: [
                        for (var r = 0; r < cards.length; r += perRow) ...[
                          if (r > 0) SizedBox(height: Sp.x3),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < perRow; i++) ...[
                                  if (i > 0) SizedBox(width: Sp.x3),
                                  Expanded(child: r + i < cards.length ? cards[r + i] : const SizedBox.shrink()),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}
