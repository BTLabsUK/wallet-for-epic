import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/tor_view.dart';
import '../../widgets/kit.dart';
import 'prefs.dart';
import 'settings_frame.dart';

/// The tour's Tor states: on, starting, not connected (laid over the mock's status).
enum PrivacyDemo { torOn, torStarting, torFailed }

/// Settings › Privacy: the one Tor switch (what it covers is `tor_routes.dart`'s) and whether
/// status.btlabs.uk is asked.
class SettingsPrivacyScreen extends ConsumerWidget {
  const SettingsPrivacyScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsFrame(
    route: DeskRoute.settingsPrivacy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (DeskFeatures.tor) ...[TorGroup(demo: arg is PrivacyDemo ? arg as PrivacyDemo : null), SizedBox(height: Sp.x6)],
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
      torProblem: failed ? 'Tor could not connect to the network' : null,
      torIncluded: s.torIncluded,
      syncProgress: s.syncProgress,
      lastUpdate: s.lastUpdate,
      notice: s.notice,
    );
  }

  Future<void> _set(bool on) async {
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).setTor(on);
    } on Object catch (e) {
      if (mounted) showEToast(context, on ? 'Tor not turned on' : 'Tor not turned off', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final status = _status(st.status);
    final included = status?.torIncluded ?? true;
    final tor = torStateOf(st.settings, status);
    final line = torStateLine(tor, status, included: included);
    return JumpSection(
      section: SettingsJump.tor,
      child: ESetGroup(
        title: 'Tor',
        rows: [
          ESetRow(
            title: 'Tor',
            text: torCoverageText(),
            control: SizedBox(
              width: 40.u,
              height: 24.u,
              child: _busy
                  ? Center(child: Semantics(label: 'Switching Tor', child: ESpinner(size: 18.u)))
                  : ESwitch(
                      key: const ValueKey('privacy-tor-switch'),
                      value: st.settings.tor && included,
                      semanticLabel: 'Tor',
                      onChanged: included ? _set : null,
                    ),
            ),
            below: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EStateLine(line, key: const ValueKey('privacy-tor-state')),
                if (tor == TorState.failed) ...[
                  SizedBox(height: Sp.x3),
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x2,
                    children: [
                      EButton(label: 'Retry', icon: EIcons.refresh, size: EBtnSize.inline, busy: _busy, onPressed: _busy ? null : () => _set(true)),
                      EButton.ghost(label: 'Turn Tor off', size: EBtnSize.inline, onPressed: _busy ? null : () => _set(false)),
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

/// The Tor state line of Settings › Privacy and the status card's hover card.
MethodLine torStateLine(TorState tor, ServiceStatus? status, {bool included = true}) {
  if (!included) return const MethodLine('Not in this build', EState.off);
  final waiting = torWaitingText();
  return switch (tor) {
    TorState.off => const MethodLine('Off', EState.off, detail: 'Connections use this computer’s own address.'),
    TorState.starting => MethodLine('Starting…', EState.warn, detail: '${status?.torProgress ?? 0} %. $waiting wait until Tor is up.'),
    TorState.on when status?.tor == ServiceHealth.slow =>
      MethodLine('On', EState.ok, detail: '${status?.torProblem ?? 'Tor address not published yet'}. Sends work.'),
    TorState.on => const MethodLine('On', EState.ok, detail: 'Connected.'),
    TorState.failed => MethodLine('Not connected', EState.risk, detail: '${status?.torProblem ?? 'Tor stopped'}. $waiting wait for Retry or Tor off.'),
  };
}

/// Whether status.btlabs.uk is asked ([DeskSettings.useStatusSite]). Off, the node and
/// Epicbox lists are the built-in ones with health from the servers themselves. Applies at once.
class PrivacyGroup extends ConsumerWidget {
  const PrivacyGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deskProvider.select((s) => s.settings));
    return ESetGroup(
      title: 'Status site',
      rows: [
        ESetRow(
          title: 'Use status.btlabs.uk',
          text: 'Server health and node lists. Off: only the servers themselves are asked.',
          control: ESwitch(
            value: s.useStatusSite,
            semanticLabel: 'Use status.btlabs.uk',
            onChanged: (v) => ref.read(deskProvider.notifier).saveSettings(s.copyWith(useStatusSite: v)),
          ),
        ),
      ],
    );
  }
}
