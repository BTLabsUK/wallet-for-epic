// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Change level: the depth dial with its preview, Undercover, Save.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart' show NetworkMode;
import '../../../levels/wallet_level.dart';
import '../../../log.dart';
import '../../../tor_build.dart' show torBuilt;
import '../../data/desk_levels.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../onboarding/depth_dial.dart';

/// Save's key, for tests.
const Key deskLevelSaveKey = ValueKey('desk-level-save');

class SettingsLevelScreen extends ConsumerStatefulWidget {
  const SettingsLevelScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsLevelScreen> createState() => _SettingsLevelScreenState();
}

class _SettingsLevelScreenState extends ConsumerState<SettingsLevelScreen> {
  late WalletLevel _level = ref.read(deskLevelProvider);
  late final bool _wasUndercover = ref.read(deskProvider).settings.advanced.networkMode == NetworkMode.torOnly;
  late bool _undercover = _wasUndercover;
  bool _busy = false;

  bool get _changed => _level != ref.read(deskLevelProvider) || _undercover != _wasUndercover;

  void _back() {
    final nav = ref.read(deskNavProvider.notifier);
    nav.canBack ? nav.back() : nav.go(DeskRoute.settingsAdvanced);
  }

  Future<void> _save() async {
    if (_busy || !_changed) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final control = ref.read(deskLevelControlProvider);
      if (_level != ref.read(deskLevelProvider)) await control.setLevel(_level);
      if (_undercover != _wasUndercover) {
        // After the level: its preset may have saved the settings.
        final s = ref.read(deskProvider).settings;
        await ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withMode(_undercover ? NetworkMode.torOnly : NetworkMode.standard)));
      }
    } on Object catch (e) {
      logWarn('levels', 'level not saved: ${e.runtimeType}');
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    showEToast(context, l.lvPickSaved, tone: ETone.ok);
    _back();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    // Follow a level that changed elsewhere while the page stayed open (nothing to save then).
    ref.listen(deskLevelProvider, (prev, next) {
      if (prev != next && _level == prev && mounted) setState(() => _level = next);
    });
    final tight = MediaQuery.sizeOf(context).height < 940;
    return EPage(
      title: l.lvPickDepth,
      width: EPageWidth.full,
      onBack: _back,
      actions: [EIconButton(icon: EIcons.info, label: l.lvPickHelpTitle, onPressed: () => showDepthHelp(context))],
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1180.u),
          child: DeskDepthPicker(
            level: _level,
            onLevel: (v) => setState(() => _level = v),
            compact: tight,
            caption: l.deskLvStartPreviewCaptionShort,
            foot: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (torBuilt) ...[
                  DeskUndercoverRow(later: true, value: _undercover, onChanged: _busy ? null : (v) => setState(() => _undercover = v)),
                  SizedBox(height: Sp.x2),
                  Text(l.lvPickTakesEffect, style: ts.small),
                ],
                SizedBox(height: Sp.x5),
                Row(
                  children: [
                    EButton.primary(key: deskLevelSaveKey, label: l.commonSave, onPressed: _changed && !_busy ? _save : null),
                    SizedBox(width: Sp.x3),
                    EButton.ghost(label: l.commonCancel, onPressed: _busy ? null : _back),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
