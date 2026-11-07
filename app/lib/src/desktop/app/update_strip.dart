// SPDX-License-Identifier: Apache-2.0
/// The update strip: one slim line across the top of the content area, above the page's
/// title, while a newer BT Wallet is out and nothing was done about it yet ("Version 26.11.9
/// is available." · Update · ×). Information, not a warning: the info icon's blue on the
/// panel. Update runs the same step as the sidebar's slot ([deskUpdateAct]); × closes it for
/// that version ([SettingsPrefs.updateSeen]), and it comes back for a newer one. The slot
/// (`now_slot.dart`) stays whatever happens here: the reminder and the way back to the update.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tor_build.dart' show inAppUpdates;
import '../../trust_ids.dart';
import '../data/desk_update.dart';
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart';
import '../widgets/kit.dart';
import 'update_notice.dart' show deskUpdateAct;

/// The version the strip offers, or null when it has nothing to show: no update, one already
/// downloading or downloaded (the slot and its dialog carry those), one that failed (the slot
/// says so), or one the user closed the strip for.
final deskUpdateStripProvider = Provider<String?>((ref) {
  if (!inAppUpdates) return null;
  final u = ref.watch(deskUpdateProvider);
  final v = u.version;
  if (u.phase != DeskUpdatePhase.available || u.problem != null || v == null) return null;
  final seen = ref.watch(settingsPrefsProvider.select((p) => p.updateSeen));
  if (seen != null && !isNewerVersion(v, seen)) return null;
  return v;
});

class DeskUpdateStrip extends ConsumerWidget {
  const DeskUpdateStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(deskUpdateStripProvider);
    // The same enter and leave as a notice: the page slides down and back up.
    return ExpandFade(
      open: version != null,
      child: version == null ? const SizedBox.shrink() : _Strip(key: const ValueKey('update-strip'), version: version),
    );
  }
}

class _Strip extends ConsumerWidget {
  const _Strip({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    // The page's own gutter (frames.dart), so the words line up with the title under them.
    return LayoutBuilder(
      builder: (context, box) {
        final pad = MediaQuery.sizeOf(context).width < Bp.phone ? Sp.x4 : (box.maxWidth < Lay.xl ? Sp.x6 : Sp.x8);
        return Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            padding: EdgeInsets.fromLTRB(pad, Sp.x2, pad - Sp.x1, Sp.x2),
            decoration: BoxDecoration(color: c.s1, border: Border(bottom: BorderSide(color: c.lineStrong))),
            child: Row(
              children: [
                Icon(EIcons.download, size: Ctl.icon, color: c.info),
                SizedBox(width: Sp.x3),
                Expanded(child: Text(l.updateAvailable(version), style: ts.body, maxLines: 2, overflow: TextOverflow.ellipsis)),
                SizedBox(width: Sp.x4),
                EButton(
                  key: const ValueKey('update-strip-act'),
                  label: l.deskUpdStripAct,
                  size: EBtnSize.inline,
                  tooltip: l.deskUpdDownload(version),
                  onPressed: () => unawaited(deskUpdateAct(context, ref)),
                ),
                SizedBox(width: Sp.x1),
                EIconButton(
                  key: const ValueKey('update-strip-close'),
                  semanticsId: TrustIds.updatestripHide,
                  icon: EIcons.close,
                  label: l.deskUpdStripHide,
                  size: EBtnSize.inline,
                  onPressed: () => ref.read(settingsPrefsProvider.notifier).hideUpdateStrip(version),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
