// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Change level: a Settings page like the others. One group with the three
/// depths as radio rows (glyph, name, one line) and the small Overview picture under them, then
/// Undercover as a settings row. A pick applies at once, as every other setting here does; the
/// level's preset and Undercover's "takes effect right away" behave as before.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced.dart' show NetworkMode;
import '../../../levels/wallet_level.dart';
import '../../../log.dart';
import '../../../tor_build.dart' show torBuilt;
import '../../../ui/levels/level_art.dart';
import '../../../ui/levels/level_picker.dart' show levelLine, levelStopName;
import '../../data/desk_levels.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../onboarding/depth_dial.dart' show DeskOverviewPreview, deskLevelStopKey, deskUndercoverKey, showDepthHelp;
import '../transfer/send_advanced.dart' show ERadioRow;
import 'settings_frame.dart';

/// The preview's key, for tests.
const Key deskLevelPreviewKey = ValueKey('desk-level-preview');

LevelArtKind _art(WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => LevelArtKind.relaxed,
  WalletLevel.casual => LevelArtKind.curious,
  WalletLevel.everything => LevelArtKind.explorer,
};

class SettingsLevelScreen extends ConsumerStatefulWidget {
  const SettingsLevelScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsLevelScreen> createState() => _SettingsLevelScreenState();
}

class _SettingsLevelScreenState extends ConsumerState<SettingsLevelScreen> {
  bool _busy = false;

  Future<void> _pick(WalletLevel level) async {
    if (_busy || level == ref.read(deskLevelProvider)) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskLevelControlProvider).setLevel(level);
    } on Object catch (e) {
      logWarn('levels', 'level not saved: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undercover(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final s = ref.read(deskProvider).settings;
      await ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withMode(on ? NetworkMode.torOnly : NetworkMode.standard)));
    } on Object catch (e) {
      logWarn('levels', 'undercover not saved: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final level = ref.watch(deskLevelProvider);
    final undercover = ref.watch(deskProvider.select((s) => s.settings.advanced.networkMode == NetworkMode.torOnly));
    return SettingsFrame(
      route: DeskRoute.settingsLevel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: l.lvPickDepth,
            trailing: EButton.ghost(label: l.lvPickHelpTitle, icon: EIcons.info, size: EBtnSize.inline, onPressed: () => showDepthHelp(context)),
            rows: [
              // The three depths and the picked one's Overview, side by side while the card has
              // the room (the picture takes what the rows leave, within its bounds), else the
              // picture under the rows.
              LayoutBuilder(
                builder: (context, box) {
                  final beside = box.maxWidth >= 600.u;
                  final rows = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, lv) in WalletLevel.values.indexed) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                        // As tall as a settings row (its padding less the radio row's own).
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
                          child: ERadioRow(
                            key: deskLevelStopKey(lv),
                            selected: lv == level,
                            title: levelStopName(l, lv),
                            text: levelLine(l, lv),
                            leading: LevelArt(_art(lv), size: 20.u, color: lv == level ? c.accentText : c.dim),
                            onSelected: _busy ? null : () => _pick(lv),
                          ),
                        ),
                      ],
                    ],
                  );
                  final preview = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        key: deskLevelPreviewKey,
                        label: l.deskLvStartPreviewLabel,
                        child: ExcludeSemantics(
                          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: Max.dial), child: DeskOverviewPreview(level: level)),
                        ),
                      ),
                      SizedBox(height: Sp.x2),
                      Text(l.deskLvStartPreviewCaptionShort, style: context.ts.small),
                    ],
                  );
                  if (!beside) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        rows,
                        Divider(height: 1, thickness: 1, color: c.line),
                        Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4), child: preview),
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Center(child: rows)),
                        VerticalDivider(width: 1, thickness: 1, color: c.line),
                        Container(
                          width: (box.maxWidth - 400.u).clamp(240.u, 320.u),
                          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
                          alignment: Alignment.center,
                          child: preview,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          if (torBuilt)
            ESetGroup(
              rows: [
                ESetRow(
                  title: l.lvPickUndercover,
                  hint: l.lvPickUndercoverLaterHelp,
                  hintTitle: l.lvPickUndercover,
                  control: ESwitch(key: deskUndercoverKey, value: undercover, semanticLabel: l.lvPickUndercover, onChanged: _busy ? null : _undercover),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
