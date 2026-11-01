// SPDX-License-Identifier: Apache-2.0
/// The level-1 shell's two status icons in the app bar ([LevelFeatures.statusIcons]: Network
/// and Epicbox). The same glyphs and one-mark state language as today's icons ([StatusIcon]);
/// the tooltip reads "Network · OK", and a tap opens the connections sheet
/// (`home_status.dart`), whose rows open the icons' explore sheets (`status_sheets.dart`)
/// instead of a server list, which level 1 does not show. An Epicbox relay offer
/// ([relaySwitchProvider]) turns the Epicbox mark amber.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/level_features.dart' show LevelFeatures;
import '../../levels/level_features.dart' as lv show StatusIcon;
import '../../levels/level_providers.dart';
import '../../levels/relay_switch_providers.dart';
import '../../providers.dart';
import '../network_status.dart' show nodeBehind;
import '../status.dart';
import '../status_icons.dart';
import '../home_status.dart' show showConnectionsSheet;

/// The keys of the level-1 icons, for tests.
const Key shellNetworkIconKey = ValueKey('shell-status-network');
const Key shellEpicboxIconKey = ValueKey('shell-status-epicbox');

/// Whether the quiet shell's statuses show: the level hides the server settings, so a status
/// opens its explore sheet rather than a server list.
bool shellStatusesShown(LevelFeatures f) => !f.serverSettings;

/// The node's state in plain words, with its dot.
({StatusDot dot, String word}) shellNetworkFace(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final status = watchWalletStatus(ref);
  final preset = ref.watch(networkChoiceProvider).value?.preset;
  final behind = nodeBehind(ref, status.node, preset);
  final face = nodeIconFace(context, status.node, ref.watch(walletConfigProvider), behind: behind);
  final word = switch (status.node.state) {
    NodeState.online when face.dot == StatusDot.bad => l.lvShellStateBehind,
    NodeState.online => l.commonOk,
    NodeState.syncing => l.lvShellStateCatchingUp,
    NodeState.connecting => l.lvShellStateConnecting,
    NodeState.offline => l.netStatusNotReachable,
  };
  return (dot: face.dot, word: word);
}

/// The Epicbox listener's state in plain words, with its dot: amber while a relay is offered.
({StatusDot dot, String word}) shellEpicboxFace(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final state = watchWalletStatus(ref).epicbox;
  final offer = ref.watch(relaySwitchProvider);
  return switch (state) {
    null => (dot: StatusDot.off, word: l.netStatusOff),
    EpicboxState.online => (dot: StatusDot.ok, word: l.commonOk),
    EpicboxState.connecting => (dot: StatusDot.busy, word: l.lvShellStateConnecting),
    EpicboxState.offline || EpicboxState.blocked => (
      dot: offer != null ? StatusDot.warn : StatusDot.bad,
      word: l.netStatusNotReachable,
    ),
  };
}

/// Network and Epicbox side by side, for the app bar.
class ShellStatusIcons extends ConsumerWidget {
  const ShellStatusIcons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final shown = ref.watch(levelFeaturesProvider.select((f) => f.statusIcons));
    final net = shellNetworkFace(context, ref);
    final box = shellEpicboxFace(context, ref);
    final syncing = watchWalletStatus(ref).node.state == NodeState.syncing;
    Widget icon(Key key, IconData glyph, String name, ({StatusDot dot, String word}) face, VoidCallback onTap, {bool pulse = false}) {
      final tip = l.lvShellStatusTip(name, face.word);
      return StatusIcon(
        key: key,
        icon: glyph,
        enabled: face.dot != StatusDot.off,
        dot: face.dot,
        label: tip,
        detail: tip,
        actionHint: l.lvShellOpensDetails,
        pulse: pulse,
        onTap: onTap,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown.contains(lv.StatusIcon.network))
          icon(shellNetworkIconKey, EpicGlyphs.node, l.settingsAboutNetwork, net, () => showConnectionsSheet(context), pulse: syncing),
        if (shown.contains(lv.StatusIcon.epicbox))
          icon(shellEpicboxIconKey, EpicGlyphs.epicbox, l.netStatusEpicbox, box, () => showConnectionsSheet(context)),
      ],
    );
  }
}
