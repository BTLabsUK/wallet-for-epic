// SPDX-License-Identifier: Apache-2.0
import '../../../state_language.dart' show torShownState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
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
/// phone's order (Deeper and up). Connection mode, Tor for all connections (what it covers is
/// `tor_routes.dart`'s; locked on in Tor only, off in Kill switch, with the line that says
/// why), then Server status. Node failover is on the Node page.
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
          if (DeskFeatures.tor) TorGroup(demo: arg is PrivacyDemo ? arg as PrivacyDemo : null),
          const PrivacyGroup(),
        ],
      ),
    );
  }
}

/// The Tor switch with its state line; Retry and Turn Tor off when it is not connected.
class TorGroup extends ConsumerStatefulWidget {
  const TorGroup({super.key, this.demo});

  final PrivacyDemo? demo;

  @override
  ConsumerState<TorGroup> createState() => _TorGroupState();
}

class _TorGroupState extends ConsumerState<TorGroup> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The tour turns Tor on for the shot; the next shot's prepare turns it off (resetSettingsDemo).
    if (widget.demo != null) {
      final n = ref.read(deskProvider.notifier);
      Future.microtask(() => n.setTor(true));
    }
  }

  /// The real status with the tour's starting and failed states laid over it.
  ServiceStatus? _status(ServiceStatus? s) {
    final d = widget.demo;
    if (s == null || d == null || d == PrivacyDemo.torOn) return s;
    final failed = d == PrivacyDemo.torFailed;
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: failed ? ServiceHealth.down : ServiceHealth.checking,
      torProgress: failed ? null : 45,
      torProblem: failed ? 'Tor could not connect to the network' : null, // l10n-ok: demo status text
      torIncluded: s.torIncluded,
      syncProgress: s.syncProgress,
      lastUpdate: s.lastUpdate,
      notice: s.notice,
    );
  }

  Future<void> _set(bool on) async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).setTor(on);
    } on Object catch (e) {
      if (mounted) showEToast(context, on ? l.deskSetPrivTorOnFailed : l.deskSetPrivTorOffFailed, text: deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final status = _status(st.status);
    final included = status?.torIncluded ?? true;
    final tor = netTorState(st.settings, status);
    final line = torStateLine(l, tor, status, included: included);
    // The mode above it on this page: Tor only keeps the switch on, Kill switch leaves it off;
    // in Node only it is the user's and carries the node.
    final mode = st.settings.advanced.networkMode;
    final torOnly = mode == NetworkMode.torOnly;
    final offline = mode == NetworkMode.killSwitch;
    return JumpSection(
      section: SettingsJump.tor,
      child: ESetGroup(
        title: l.deskSetPrivTor,
        rows: [
          ESetRow(
            anchor: SetId.torAll,
            title: l.deskSetPrivTorAll,
            hint: torOnly ? '${torNetworkHint(l)}\n\n${l.torLockedTorOnly}' : torNetworkHint(l),
            hintTitle: l.deskSetPrivTorAll,
            hintIcon: EIcons.tor,
            control: SizedBox(
              width: 40.u,
              height: 24.u,
              child: _busy
                  ? Center(child: Semantics(label: l.deskSetPrivSwitching, child: ESpinner(size: 18.u)))
                  : ESwitch(
                      key: const ValueKey('privacy-tor-switch'),
                      value: (torOnly || st.settings.tor) && included && !offline,
                      semanticLabel: l.deskSetPrivTorAll,
                      onChanged: included && !torOnly && !offline ? _set : null,
                    ),
            ),
            below: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!offline) EStateLine(line, key: const ValueKey('privacy-tor-state')),
                if (torOnly || offline) ...[
                  SizedBox(height: Sp.x2),
                  Text(
                    torOnly ? l.torLockedTorOnly : l.netBlockKillSwitch,
                    key: const ValueKey('privacy-mode-line'),
                    style: context.ts.small,
                  ),
                ],
                if (tor == TorState.failed && !offline) ...[
                  SizedBox(height: Sp.x3),
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x2,
                    children: [
                      EButton(label: l.commonRetry, icon: EIcons.refresh, size: EBtnSize.inline, busy: _busy, onPressed: _busy ? null : () => _set(true)),
                      if (!torOnly) EButton.ghost(label: l.deskSetPrivTurnOff, size: EBtnSize.inline, onPressed: _busy ? null : () => _set(false)),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
