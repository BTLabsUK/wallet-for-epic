// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../../advanced.dart' show NetworkMode;
import '../../data/net_mode_view.dart';
import '../../data/tor_view.dart';
import '../../widgets/kit.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show openAdvanced;
import '../../../settings_file/status_site.dart' show statusSiteConfigured, statusSiteHost;

/// The tour's Tor states: on, starting, not connected (laid over the mock's status).
enum PrivacyDemo { torOn, torStarting, torFailed }

/// Settings › Privacy: the one Tor switch (what it covers is `tor_routes.dart`'s) and whether
/// the status site is asked.
class SettingsPrivacyScreen extends ConsumerWidget {
  const SettingsPrivacyScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsFrame(
    route: DeskRoute.settingsPrivacy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ESetGroup owns the gap between groups.
        if (DeskFeatures.tor) TorGroup(demo: arg is PrivacyDemo ? arg as PrivacyDemo : null),
        const PrivacyGroup(),
      ],
    ),
  );
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
    // Advanced › Network: Tor only keeps the switch on, Kill switch leaves it off; in Node only
    // it is the user's and carries the node.
    final mode = st.settings.advanced.networkMode;
    final torOnly = mode == NetworkMode.torOnly;
    final offline = mode == NetworkMode.killSwitch;
    // Undercover is Tor only: the switch shows disabled, and a tap, its ⓘ and its line say why
    // and lead to the Depth page, where Undercover is changed.
    void changeUndercover() => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsLevel);
    final control = ESwitch(
      key: const ValueKey('privacy-tor-switch'),
      value: (torOnly || st.settings.tor) && included && !offline,
      semanticLabel: torNetworkLabel(context.l10n),
      onChanged: included && !torOnly && !offline ? _set : null,
    );
    return JumpSection(
      section: SettingsJump.tor,
      child: ESetGroup(
        title: l.deskSetPrivTor,
        rows: [
          ESetRow(
            title: torNetworkLabel(context.l10n),
            hint: torOnly ? '${torNetworkHint(l)}\n\n${l.deskSetPrivUndercoverLine}' : torNetworkHint(l),
            hintTitle: torNetworkLabel(context.l10n),
            hintIcon: EIcons.tor,
            control: SizedBox(
              width: 40.u,
              height: 24.u,
              child: _busy
                  ? Center(child: Semantics(label: l.deskSetPrivSwitching, child: ESpinner(size: 18.u)))
                  : !torOnly
                  ? control
                  : GestureDetector(
                      key: const ValueKey('privacy-tor-undercover-tap'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showEToast(
                        context,
                        l.deskSetPrivUndercoverLine,
                        tone: ETone.info,
                        action: (label: l.deskSetPrivUndercoverChange, run: changeUndercover),
                      ),
                      child: control,
                    ),
            ),
            below: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!offline) EStateLine(line, key: const ValueKey('privacy-tor-state')),
                if (torOnly || offline) ...[
                  SizedBox(height: Sp.x2),
                  Wrap(
                    spacing: Sp.x2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        torOnly ? l.deskSetPrivUndercoverLine : l.netBlockKillSwitch,
                        key: const ValueKey('privacy-mode-line'),
                        style: context.ts.small,
                      ),
                      if (torOnly)
                        ELink(
                          key: const ValueKey('privacy-undercover-change'),
                          label: l.deskSetPrivUndercoverChange,
                          onPressed: changeUndercover,
                        )
                      else
                        ELink(label: l.deskNetOpenAdvanced, onPressed: () => openAdvanced(ref)),
                    ],
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
    TorState.off => MethodLine(l.deskSetFrameOff, EState.off),
    TorState.starting => MethodLine(l.deskSetPrivStarting, EState.active, detail: l.deskSetPrivStartingDetail(status?.torProgress ?? 0)),
    TorState.on when status?.tor == ServiceHealth.slow =>
      MethodLine(l.deskSetFrameHealthOn, EState.ok, detail: status?.torProblem == null ? l.deskSetPrivNotPublished : l.deskSetPrivProblemSendsWork(status!.torProblem!)),
    TorState.on => MethodLine(l.deskSetFrameHealthOn, EState.ok, detail: l.deskSetPrivConnected),
    TorState.failed => MethodLine(
      l.deskSetPrivNotConnected,
      EState.risk,
      detail: status?.torProblem == null ? l.deskSetPrivStoppedDetail : l.deskSetPrivProblemDetail(_noStop(status!.torProblem!)),
    ),
  };
}

/// Whether the status site is asked ([DeskSettings.useStatusSite]). Off, the node and
/// Epicbox lists are the built-in ones with health from the servers themselves. Applies at once.
class PrivacyGroup extends ConsumerWidget {
  const PrivacyGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No status site in app-config.toml: no group.
    if (!statusSiteConfigured) return const SizedBox.shrink();
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final l = context.l10n;
    return ESetGroup(
      title: l.deskSetPrivStatusSite,
      rows: [
        ESetRow(
          title: l.deskSetPrivUseStatus(statusSiteHost),
          hint: l.deskSetPrivUseStatusHint,
          control: ESwitch(

            value: s.useStatusSite,
            semanticLabel: l.deskSetPrivUseStatus(statusSiteHost),
            onChanged: (v) => ref.read(deskProvider.notifier).saveSettings(s.copyWith(useStatusSite: v)),
          ),
        ),
      ],
    );
  }
}
