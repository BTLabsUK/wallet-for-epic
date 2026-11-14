// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust_ids.dart';
import '../../desk_l10n.dart';
import '../../../advanced.dart' show NetworkMode;
import '../../../ui/network_mode_text.dart';
import '../../../ui/help/network_modes_diagram.dart';
import '../../../help/help_content.dart' show HelpId;
import 'help_pairing.dart' show HelpAt;
import '../../data/net_mode_view.dart';
import '../../widgets/kit.dart';
import '../transfer/send_advanced.dart' show ERadioRow;
import 'prefs.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show confirmNetworkModeSwitch;
import '../../../settings_file/status_site.dart' show statusSiteConfigured, statusSiteHost;

/// The tour's Tor states: on, starting, not connected (laid over the mock's status).
enum PrivacyShot { torOn, torStarting, torFailed }

/// Settings › Network & privacy (B-03): how the wallet reaches the network, on one page in the
/// phone's order. Connection mode (Tor only is the one whole-wallet Tor control; Link · Tor in
/// Payments is Tor for payments alone), then Server status. The servers and Switch node
/// automatically are on the Node and Transactions pages.
class SettingsPrivacyScreen extends ConsumerWidget {
  const SettingsPrivacyScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsFrame(
      route: DeskRoute.settingsPrivacy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ESetGroup owns the gap between groups.
          const JumpSection(section: SettingsJump.network, child: NetworkModeGroup()),
          const PrivacyGroup(),
        ],
      ),
    );
  }
}

/// Server status: whether the status site is asked ([DeskSettings.useStatusSite]; off, the node
/// and Epicbox lists are the built-in ones with health from the servers themselves). No status
/// site in app-config.toml: no group.
class PrivacyGroup extends ConsumerWidget {
  const PrivacyGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final l = context.l10n;
    final n = ref.read(deskProvider.notifier);
    if (!statusSiteConfigured) return const SizedBox.shrink();
    return ESetGroup(
      key: const ValueKey('privacy-servers'),
      title: l.deskSetPrivServerStatus,
      rows: [
        ESetRow(
          anchor: SetId.statusSite,
          title: l.deskSetPrivUseStatus(statusSiteHost),
          hint: l.deskSetPrivUseStatusHint,
          control: ESwitch(
            value: s.useStatusSite,
            semanticLabel: l.deskSetPrivUseStatus(statusSiteHost),
            onChanged: (v) => n.saveSettings(s.copyWith(useStatusSite: v)),
          ),
        ),
      ],
    );
  }
}

/// The test drivers' stable names for the modes (`TrustIds`, lib/src/trust_ids.dart).
const _modeId = {NetworkMode.standard: TrustIds.privacyModeStandard, NetworkMode.torOnly: TrustIds.privacyModeToronly};

/// The network modes as radio rows (each with its ⓘ): Normal, Tor only, Node only, Kill switch.
/// A switch that would pause a waiting send asks first ([confirmNetworkModeSwitch]).
class NetworkModeGroup extends ConsumerWidget {
  const NetworkModeGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final s = st.settings;
    final adv = s.advanced;
    final torIncluded = (st.status?.torIncluded ?? true) && DeskFeatures.tor;
    Future<void> choose(NetworkMode m) => deskChooseNetworkMode(context, ref, m);
    Widget mode(NetworkMode m, {bool tor = false}) => ERadioRow(
      key: ValueKey('adv-mode-${m.name}'),
      semanticsId: _modeId[m],
      selected: adv.networkMode == m,
      // Just the name and its ⓘ: no explanations in the list (the owner).
      title: networkModeName(l, m),
      hint: networkModeHint(l, m, tor: DeskFeatures.tor),
      hintIcon: networkModeGlyph(m),
      // The ⓘ opens the picture of the modes at this row's mode.
      onHint: () => showNetworkModesDialog(context, ref, m),
      tag: tor && !torIncluded ? l.deskSetAdvNotInBuild : null,
      onSelected: tor && !torIncluded ? null : () => choose(m),
    );
    return ESetGroup(
      key: const ValueKey('privacy-network'),
      title: l.deskSetPrivMode,
      // The picture of the modes, at the wallet's own.
      trailing: EInfoHint(
        networkModeHint(l, adv.networkMode, tor: DeskFeatures.tor),
        key: networkModesHintKey,
        label: l.netModesAbout,
        onOpen: () => showNetworkModesDialog(context, ref, adv.networkMode),
      ),
      rows: [
        // One row per mode, as tall as a settings row (its padding less the radio row's own).
        SetAnchor(id: SetId.netMode, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (m, tor)) in [(NetworkMode.standard, false), if (DeskFeatures.tor) (NetworkMode.torOnly, true), (NetworkMode.nodeOnly, false), (NetworkMode.killSwitch, false)].indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: context.dc.line),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
                  child: mode(m, tor: tor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Switches the wallet to the connection mode [m] (Settings › Network and privacy, the status
/// bar's mode menu). A switch that would pause a send waiting for its recipient asks first
/// ([confirmNetworkModeSwitch]).
Future<void> deskChooseNetworkMode(BuildContext context, WidgetRef ref, NetworkMode m) async {
  final st = ref.read(deskProvider);
  final adv = st.settings.advanced;
  if (m == adv.networkMode) return;
  final waiting = switchPausesSends(m) && !switchPausesSends(adv.networkMode) ? deskPendingNetworkSends(st) : 0;
  if (waiting > 0) {
    final ok = await confirmNetworkModeSwitch(context, mode: m, waiting: waiting);
    if (ok != true) return;
  }
  await ref.read(deskProvider.notifier).saveSettings(ref.read(deskProvider).settings.copyWith(advanced: adv.withMode(m)));
}

/// The modes in the order Settings lists them; Tor only in builds with Tor.
List<NetworkMode> deskNetworkModes() => [NetworkMode.standard, if (DeskFeatures.tor) NetworkMode.torOnly, NetworkMode.nodeOnly, NetworkMode.killSwitch];

/// The ⓘ beside the Connection mode heading: the picture of the modes.
const Key networkModesHintKey = ValueKey('adv-modes-hint');

/// The key of the dialog that shows the picture of the modes.
const Key networkModesDialogKey = ValueKey('net-modes-dialog');

/// Opens the picture of the connection modes ([NetworkModesDiagram]) in a wide dialog, at
/// [initial]: More in Help and Close. It explains only; nothing in it changes the wallet's mode.
Future<void> showNetworkModesDialog(BuildContext context, WidgetRef ref, NetworkMode initial) {
  final l = context.l10n;
  return showEDialog<void>(
    context,
    builder: (dialog) => EDialog(
      key: networkModesDialogKey,
      title: l.netModesTitle,
      // The info tile: the dialog is about every mode, not the one it opened at.
      tone: ETone.info,
      size: DialogWidth.wide,
      body: NetworkModesDiagram(initial: initial, tor: DeskFeatures.tor),
      actions: [
        EButton(
          key: const ValueKey('net-modes-dialog-help'),
          label: l.deskKitMoreInHelp,
          onPressed: () {
            Navigator.pop(dialog);
            ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.modes));
          },
        ),
        EButton.primary(label: l.commonClose, onPressed: () => Navigator.pop(dialog)),
      ],
    ),
  );
}
