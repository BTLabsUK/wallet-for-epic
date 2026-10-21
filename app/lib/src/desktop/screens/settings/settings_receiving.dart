import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'combo.dart';
import 'dialogs.dart';
import 'settings_frame.dart';

/// Start states of Settings › Receiving.
enum ReceivingDemo { comboOpen, torOn, epicboxDown }

class SettingsReceivingScreen extends ConsumerStatefulWidget {
  const SettingsReceivingScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsReceivingScreen> createState() => _SettingsReceivingScreenState();
}

class _SettingsReceivingScreenState extends ConsumerState<SettingsReceivingScreen> {
  String? _http;
  String? _onion;

  @override
  void initState() {
    super.initState();
    final api = ref.read(deskApiProvider);
    api.httpAddress().then((v) => mounted ? setState(() => _http = v) : null);
    api.torAddress().then((v) => mounted ? setState(() => _onion = v) : null);
    if (widget.arg == ReceivingDemo.torOn) {
      Future.microtask(() {
        final n = ref.read(deskProvider.notifier);
        n.saveSettings(ref.read(deskProvider).settings.copyWith(tor: true, directHttp: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final notifier = ref.read(deskProvider.notifier);
    final boxes = st.epicboxes;
    final status = st.status;
    if (boxes == null || status == null) {
      return const SettingsFrame(route: DeskRoute.settingsReceiving, child: SettingsLoading());
    }
    final s = st.settings;
    final c = context.dc;
    final ts = context.ts;
    final box = status.epicbox;
    final boxHealth = widget.arg == ReceivingDemo.epicboxDown ? ServiceHealth.down : status.epicboxHealth;
    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: 'Epicbox',
            rows: [
              ESetRow(
                title: 'Epicbox server',
                text: 'Holds payments for this wallet until it is online.',
                stacked: true,
                control: ServiceCombo(
                  label: 'Epicbox server',
                  value: box.domain,
                  openInitially: widget.arg == ReceivingDemo.comboOpen,
                  options: [
                    for (final b in boxes)
                      ComboOption(value: b.domain, title: b.operator ?? b.domain, host: b.domain, health: b.health, latencyMs: b.latencyMs, group: 'Public servers'),
                  ],
                  onChanged: notifier.useEpicbox,
                  footerActions: [('Add server…', EIcons.plus, () => showEToast(context, 'Custom servers are not part of this preview', tone: ETone.warn))],
                ),
                below: Row(
                  children: [
                    HealthLine(boxHealth, latencyMs: box.latencyMs),
                    const SizedBox(width: Sp.x3),
                    Expanded(
                      child: Text(
                        boxHealth == ServiceHealth.down ? 'payments wait until it is back' : 'connected',
                        style: ts.small.copyWith(color: c.faint),
                      ),
                    ),
                  ],
                ),
              ),
              ESetRow(
                title: 'Switch automatically',
                text: 'Use the next healthy server when this one stops answering.',
                control: ESwitch(
                  value: s.epicboxFailover,
                  onChanged: (v) => notifier.saveSettings(s.copyWith(epicboxFailover: v)),
                ),
              ),
            ],
          ),
          if (boxHealth == ServiceHealth.down) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.x8),
              child: ENotice(
                title: 'Epicbox server is down',
                text: 'Payments wait until it is back. Switch to another server to receive now.',
                tone: ETone.risk,
                actions: [
                  EButton(
                    label: 'Switch server',
                    size: EBtnSize.inline,
                    onPressed: () => notifier.useEpicbox(boxes.firstWhere((b) => b.health == ServiceHealth.ok, orElse: () => boxes.first).domain),
                  ),
                ],
              ),
            ),
          ],
          ESetGroup(
            title: 'Direct transactions',
            rows: [
              ESetRow(
                title: 'Receive over HTTP',
                text: 'Peer to peer on port 3415. Both wallets must be online.',
                control: ESwitch(
                  value: s.directHttp,
                  semanticLabel: 'Receive over HTTP',
                  onChanged: (v) => notifier.saveSettings(s.copyWith(directHttp: v)),
                ),
                below: s.directHttp && _http != null
                    ? EAddress(s.publicMode ? _http! : 'http://127.0.0.1:3415')
                    : null,
              ),
              ESetRow(
                title: 'Public mode',
                text: s.publicMode ? 'Reachable from the internet once the router forwards port 3415.' : 'This computer only.',
                control: EButton(label: s.publicMode ? 'Change…' : 'Make public…', size: EBtnSize.sm, onPressed: () => showPublicModeDialog(context)),
              ),
              ESetRow(
                title: 'Tor',
                text: 'Receive at an .onion address from anywhere, with nothing to set up.',
                control: ESwitch(
                  value: s.tor,
                  semanticLabel: 'Receive over Tor',
                  onChanged: (v) => notifier.saveSettings(s.copyWith(tor: v)),
                ),
                below: s.tor
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const ETag('Ready', tone: ETone.ok, icon: EIcons.check),
                              const SizedBox(width: Sp.x3),
                              Text('Reachable over Tor', style: ts.small),
                            ],
                          ),
                          if (_onion != null) ...[
                            const SizedBox(height: Sp.x3),
                            Row(children: [Expanded(child: EAddress(_onion!)), const SizedBox(width: Sp.x2), ECopyButton(text: _onion!)]),
                          ],
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
