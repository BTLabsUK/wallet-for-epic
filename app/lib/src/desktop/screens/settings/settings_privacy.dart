// SPDX-License-Identifier: Apache-2.0
import '../../../state_language.dart' show torShownState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../advanced.dart' show NetworkMode;
import '../../../ui/network_mode_text.dart';
import '../../data/net_mode_view.dart';
import '../../data/tor_view.dart';
import '../../widgets/kit.dart';
import '../transfer/send_advanced.dart' show ERadioRow;
import 'prefs.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show confirmNetworkModeSwitch;
import '../../../settings_file/status_site.dart' show statusSiteConfigured, statusSiteHost;

/// The tour's Tor states: on, starting, not connected (laid over the mock's status).
enum PrivacyDemo { torOn, torStarting, torFailed }

/// Settings › Network & privacy (B-03): how the wallet reaches the network, on one page in the
/// phone's order (Deeper and up). Connection mode (Tor only is the one whole-wallet Tor
/// control; Link · Tor in Payments is Tor for payments alone), then Server status. Node
/// failover is on the Node page.
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

/// [problem] without its own full stop: the string adds one.
String _noStop(String problem) => problem.endsWith('.') || problem.endsWith('。') ? problem.substring(0, problem.length - 1) : problem;

/// The Tor state line of Settings › Privacy and the status card's hover card.
MethodLine torStateLine(AppLocalizations l, TorState tor, ServiceStatus? status, {bool included = true}) {
  if (!included) return MethodLine(l.deskSetPrivNotInBuild, EState.off);
  return switch (tor) {
    // Tor's one word per state (torShownState), as the rail and the status bar (D-04).
    TorState.off => MethodLine.of(l, torShownState(tor)),
    TorState.starting => MethodLine.of(l, torShownState(tor), detail: l.deskSetPrivStartingDetail(status?.torProgress ?? 0)),
    TorState.on when status?.tor == ServiceHealth.slow =>
      MethodLine.of(l, torShownState(tor), detail: status?.torProblem == null ? l.deskSetPrivNotPublished : l.deskSetPrivProblemSendsWork(status!.torProblem!)),
    TorState.on => MethodLine.of(l, torShownState(tor)),
    TorState.failed => MethodLine.of(
      l,
      torShownState(tor),
      detail: status?.torProblem == null ? l.deskSetPrivStoppedDetail : l.deskSetPrivProblemDetail(_noStop(status!.torProblem!)),
    ),
  };
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
    Future<void> choose(NetworkMode m) async {
      if (m == adv.networkMode) return;
      final waiting = switchPausesSends(m) && !switchPausesSends(adv.networkMode) ? deskPendingNetworkSends(st) : 0;
      if (waiting > 0) {
        final ok = await confirmNetworkModeSwitch(context, mode: m, waiting: waiting);
        if (ok != true) return;
      }
      await ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: adv.withMode(m)));
    }
    Widget mode(NetworkMode m, {bool tor = false}) => ERadioRow(
      key: ValueKey('adv-mode-${m.name}'),
      selected: adv.networkMode == m,
      // Just the name and its ⓘ: no explanations in the list (the owner).
      title: networkModeName(l, m),
      hint: networkModeHint(l, m, tor: DeskFeatures.tor),
      hintIcon: networkModeGlyph(m),
      tag: tor && !torIncluded ? l.deskSetAdvNotInBuild : null,
      onSelected: tor && !torIncluded ? null : () => choose(m),
    );
    return ESetGroup(
      key: const ValueKey('privacy-network'),
      title: l.deskSetPrivMode,
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
