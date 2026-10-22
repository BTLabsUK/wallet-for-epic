import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'combo.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_http.dart';

/// Start states of Settings › Receiving.
enum ReceivingDemo { comboOpen, torOn, epicboxDown, httpOn, httpFailed }

ETone epicboxTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

ETone torTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

/// The line after the Epicbox state word.
String epicboxLine(ServiceHealth h, {required bool onStart}) => switch (h) {
  ServiceHealth.ok => 'delivers payments to the Epic address',
  ServiceHealth.down => 'payments wait until it is back',
  ServiceHealth.off => onStart ? 'starts on unlock' : 'start it on the Receive page',
  _ => 'connecting to the server',
};

class SettingsReceivingScreen extends ConsumerStatefulWidget {
  const SettingsReceivingScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsReceivingScreen> createState() => _SettingsReceivingScreenState();
}

class _SettingsReceivingScreenState extends ConsumerState<SettingsReceivingScreen> {
  String? _onion;
  bool _switching = false;
  bool _torBusy = false;

  @override
  void initState() {
    super.initState();
    if (DeskFeatures.tor) ref.read(deskApiProvider).torAddress().then((v) => mounted ? setState(() => _onion = v) : null);
    final arg = widget.arg;
    Future.microtask(() {
      final n = ref.read(deskProvider.notifier);
      final s = ref.read(deskProvider).settings;
      if (arg == ReceivingDemo.torOn && !s.tor) n.setTor(true);
      if (arg == ReceivingDemo.httpOn) n.setHttp(true);
    });
  }

  /// The Tor switch, and Retry after a failure (on again).
  Future<void> _setTor(bool on) async {
    setState(() => _torBusy = true);
    try {
      await ref.read(deskProvider.notifier).setTor(on);
    } finally {
      if (mounted) setState(() => _torBusy = false);
    }
  }

  Future<void> _switch(String domain) async {
    setState(() => _switching = true);
    await ref.read(deskProvider.notifier).useEpicbox(domain);
    if (mounted) setState(() => _switching = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    final p = ref.read(settingsPrefsProvider.notifier);
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
    final healthy = boxes.where((b) => b.health == ServiceHealth.ok && b.domain != box.domain);
    final suggest = healthy.isEmpty ? null : healthy.first;
    String? tip(EpicboxServer b) => b.latencyMs == null ? null : 'Response time ${b.latencyMs} ms. Measured from the status site.';

    final rows = <Widget>[
      ESetRow(
        title: 'Epicbox server',
        stacked: true,
        control: ServiceCombo(
          label: 'Epicbox server',
          hint: 'Find or type an Epicbox server',
          value: box.domain,
          fieldText: box.domain,
          fieldSub: box.operator,
          tone: epicboxTone(boxHealth),
          busy: _switching,
          busyLabel: 'Switching the Epicbox server…',
          openInitially: widget.arg == ReceivingDemo.comboOpen,
          options: [
            for (final b in boxes)
              ComboOption(
                value: b.domain,
                host: b.domain,
                sub: b.operator,
                isDefault: b.domain == boxes.first.domain,
                tone: epicboxTone(b.health),
                word: b.health == ServiceHealth.down ? 'Not responding' : null,
                tip: tip(b),
              ),
          ],
          typedRow: (t) {
            final d = t.toLowerCase().replaceFirst(RegExp('^[a-z]+://'), '').split('/').first;
            if (!d.contains('.') || d.contains(' ')) return null;
            return ComboOption(value: d, host: d, sub: 'not in the public list', tone: ETone.neutral);
          },
          typedNote: (_) => 'Enter uses it. Its status shows once the wallet connects.',
          listNote: 'State from status.btlabs.uk, checked every few minutes.',
          onPicked: _switch,
        ),
        below: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text.rich(
                TextSpan(style: ts.small, children: [
                  TextSpan(text: epicboxWord(boxHealth), style: ts.small.copyWith(color: _toneColor(c, epicboxTone(boxHealth)), fontWeight: FontWeight.w600)),
                  TextSpan(text: '  ·  ', style: ts.small.copyWith(color: c.faint)),
                  TextSpan(text: epicboxLine(boxHealth, onStart: prefs.epicboxOnStart)),
                ]),
              ),
            ),
            if (boxHealth == ServiceHealth.down) ...[
              SizedBox(height: Sp.x3),
              _DownNotice(suggest: suggest?.domain, busy: _switching, onSwitch: () => _switch(suggest!.domain)),
            ],
          ],
        ),
      ),
      ESetRow(
        title: 'Start Epicbox with the wallet',
        text: 'Payments arrive as soon as the wallet is unlocked.',
        control: ESwitch(
          value: prefs.epicboxOnStart,
          semanticLabel: 'Start Epicbox with the wallet',
          onChanged: (v) => p.set(prefs.copyWith(epicboxOnStart: v)),
        ),
      ),
      if (DeskFeatures.httpDirect) HttpListenerRow(demoFailed: widget.arg == ReceivingDemo.httpFailed),
    ];

    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JumpSection(section: SettingsJump.epicbox, child: ESetGroup(title: 'Receiving', rows: rows)),
          if (DeskFeatures.tor)
          ESetGroup(
            title: 'Advanced',
            rows: [
              ESetRow(
                title: 'Tor',
                text: 'Receive at an .onion address and send to one. This wallet only.',
                control: ESwitch(
                  value: s.tor && status.torIncluded,
                  semanticLabel: 'Tor',
                  onChanged: status.torIncluded && !_torBusy ? _setTor : null,
                ),
                below: s.tor || !status.torIncluded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Row(
                              children: [
                                EStatusDot(status.torIncluded ? torTone(status.tor) : ETone.neutral),
                                SizedBox(width: Sp.x2),
                                Expanded(child: Text(torStatusLine(status), style: ts.small)),
                                if (s.tor && status.torIncluded && status.tor == ServiceHealth.down)
                                  EButton(label: 'Retry', icon: EIcons.refresh, size: EBtnSize.inline, busy: _torBusy, onPressed: _torBusy ? null : () => _setTor(true)),
                              ],
                            ),
                          ),
                          if (s.tor && status.torIncluded && _onion != null) ...[
                            SizedBox(height: Sp.x2),
                            Row(children: [Expanded(child: EAddress(_onion!)), SizedBox(width: Sp.x2), ECopyButton(text: _onion!, label: 'Copy Tor address')]),
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

Color _toneColor(DeskColors c, ETone t) => switch (t) {
  ETone.ok => c.ok,
  ETone.warn => c.warn,
  ETone.risk => c.risk,
  _ => c.faint,
};

/// The Epicbox server is not answering: one line, and the healthiest other server, one click.
class _DownNotice extends StatelessWidget {
  const _DownNotice({required this.suggest, required this.busy, required this.onSwitch});

  final String? suggest;
  final bool busy;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
      decoration: BoxDecoration(color: c.riskSoft, borderRadius: BorderRadius.circular(Rad.sm)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Sp.x3,
        runSpacing: Sp.x2,
        children: [
          Text.rich(
            TextSpan(style: ts.small.copyWith(color: c.text), children: [
              TextSpan(text: 'Epicbox server isn’t responding. ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: suggest != null ? 'Switch to $suggest?' : 'Payments wait until it is back.'),
            ]),
          ),
          if (suggest != null) EButton(label: 'Switch', icon: EIcons.swap, size: EBtnSize.inline, busy: busy, onPressed: onSwitch),
        ],
      ),
    );
  }
}
