import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../network.dart' show defaultEpicboxHost;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../transfer/epicbox_notice.dart';
import 'combo.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_http.dart';

/// Start states of Settings › Receiving, for the tour.
enum ReceivingDemo { comboOpen, torOn, torStopped, epicboxDown, httpOn, httpFailed, httpPublic }

ETone epicboxTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

/// Settings › Receiving (spec 6.1): one group per method, each the same three parts:
/// Receiving (switch and state line), Start with the wallet, then the method's options.
class SettingsReceivingScreen extends ConsumerStatefulWidget {
  const SettingsReceivingScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsReceivingScreen> createState() => _SettingsReceivingScreenState();
}

class _SettingsReceivingScreenState extends ConsumerState<SettingsReceivingScreen> {
  bool _switching = false;
  final Set<TxMethod> _busy = {};

  @override
  void initState() {
    super.initState();
    final arg = widget.arg;
    Future.microtask(() async {
      final n = ref.read(deskProvider.notifier);
      final s = ref.read(deskProvider).settings;
      if (arg == ReceivingDemo.torOn || arg == ReceivingDemo.torStopped) await n.setTor(true);
      if (arg == ReceivingDemo.httpOn || arg == ReceivingDemo.httpFailed || arg == ReceivingDemo.httpPublic) await n.setHttp(true);
      if (arg == ReceivingDemo.httpPublic && !s.publicMode) await n.saveSettings(ref.read(deskProvider).settings.copyWith(publicMode: true));
    });
  }

  /// The real status with the tour's failed states laid over it.
  ServiceStatus _status(ServiceStatus s) {
    final a = widget.arg;
    if (a != ReceivingDemo.epicboxDown && a != ReceivingDemo.httpFailed && a != ReceivingDemo.torStopped) return s;
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: a == ReceivingDemo.epicboxDown ? ServiceHealth.down : s.epicboxHealth,
      httpListener: a == ReceivingDemo.httpFailed ? ServiceHealth.down : s.httpListener,
      tor: a == ReceivingDemo.torStopped ? ServiceHealth.down : s.tor,
      httpProblem: a == ReceivingDemo.httpFailed ? 'Port ${ref.read(deskProvider).settings.httpPort} in use' : s.httpProblem,
      torProgress: s.torProgress,
      torProblem: a == ReceivingDemo.torStopped ? 'Tor could not connect to the network.' : s.torProblem,
      torCanSend: s.torCanSend,
      torIncluded: s.torIncluded,
      syncProgress: s.syncProgress,
      lastUpdate: s.lastUpdate,
      notice: s.notice,
    );
  }

  Future<void> _toggle(TxMethod m, bool on) async {
    setState(() => _busy.add(m));
    final n = ref.read(deskProvider.notifier);
    try {
      switch (m) {
        case TxMethod.epicbox:
          await n.setEpicboxListening(on);
        case TxMethod.http:
          await n.setHttp(on);
        case TxMethod.tor:
          await n.setTor(on);
        case TxMethod.file:
          break;
      }
    } on Object catch (e) {
      if (mounted) showEToast(context, '${_name(m)} not turned ${on ? 'on' : 'off'}', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy.remove(m));
    }
  }

  static String _name(TxMethod m) => switch (m) {
    TxMethod.epicbox => 'Epicbox',
    TxMethod.http => 'HTTP',
    TxMethod.tor => 'Tor',
    TxMethod.file => 'File',
  };

  Future<void> _switch(String domain) async {
    setState(() => _switching = true);
    try {
      await ref.read(deskProvider.notifier).useEpicbox(domain);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Server not changed', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// The group's first row: the switch (a spinner while it runs) and the state line.
  Widget _receivingRow(TxMethod m, String text, bool on, MethodLine line, {bool enabled = true, Widget? notice}) {
    final busy = _busy.contains(m);
    // In Settings the description sits above: an "Off" line needs no repeat of it.
    final shown = line.state == EState.off && m != TxMethod.epicbox ? MethodLine(line.word, line.state) : line;
    return ESetRow(
      title: 'Receiving',
      text: text,
      control: SizedBox(
        width: 40.u,
        height: 24.u,
        child: busy
            ? Center(child: Semantics(label: 'Switching ${_name(m)} receiving', child: ESpinner(size: 18.u)))
            : ESwitch(
                key: ValueKey('st-switch-${m.name}'),
                value: on,
                semanticLabel: '${_name(m)} receiving',
                onChanged: enabled ? (v) => _toggle(m, v) : null,
              ),
      ),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EStateLine(
            shown,
            key: ValueKey('st-state-${m.name}'),
            trailing: line.retry
                ? EButton(
                    label: m == TxMethod.http ? 'Try again' : 'Retry',
                    icon: EIcons.refresh,
                    size: EBtnSize.inline,
                    busy: busy,
                    onPressed: busy ? null : () => _toggle(m, true),
                  )
                : null,
          ),
          if (notice != null) ...[SizedBox(height: Sp.x3), notice],
        ],
      ),
    );
  }

  Future<void> _saveAutostart(DeskSettings s) async {
    try {
      await ref.read(deskProvider.notifier).saveSettings(s);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not saved', text: deskErrorText(e), tone: ETone.risk);
    }
  }

  Widget _autostart(TxMethod m, bool value, ValueChanged<bool>? onChanged) => ESetRow(
    title: 'Start with the wallet',
    text: 'Turns on at unlock.',
    control: ESwitch(key: ValueKey('st-autostart-${m.name}'), value: value, semanticLabel: '${_name(m)}: start with the wallet', onChanged: onChanged),
  );

  Widget _group(TxMethod m, SettingsJump jump, String title, MethodLine line, List<Widget> rows) => JumpSection(
    section: jump,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodHead(method: m, title: title, line: line),
        ESetGroup(rows: rows),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final boxes = st.epicboxes;
    final raw = st.status;
    if (boxes == null || raw == null) {
      return const SettingsFrame(route: DeskRoute.settingsReceiving, child: SettingsLoading());
    }
    final status = _status(raw);
    final s = st.settings;
    final box = status.epicbox;
    String? tip(EpicboxServer b) => b.latencyMs == null ? null : 'Response time ${b.latencyMs} ms. Measured from the status site.';
    final ebLine = methodStateLine(TxMethod.epicbox, status, s);
    final httpLine = methodStateLine(TxMethod.http, status, s);

    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group(TxMethod.epicbox, SettingsJump.epicbox, 'Epicbox receiving', ebLine, [
            _receivingRow(
              TxMethod.epicbox,
              'Payments arrive via the Epicbox server, also while the wallet is closed.',
              status.epicboxHealth != ServiceHealth.off,
              ebLine,
              notice: status.epicboxHealth == ServiceHealth.down ? const EpicboxDownNotice() : null,
            ),
            _autostart(TxMethod.epicbox, s.epicboxAutostart, (v) => _saveAutostart(s.copyWith(epicboxAutostart: v))),
            ESetRow(
              title: 'Epicbox server',
              text: 'Which server holds payments for this address. Both wallets can use different servers.',
              stacked: true,
              // TODO(§18): the shared server picker (fb-w6) replaces this combo.
              control: ServiceCombo(
                label: 'Epicbox server',
                hint: 'Find or type an Epicbox server',
                value: box.domain,
                fieldText: box.domain,
                fieldSub: box.operator,
                tone: epicboxTone(status.epicboxHealth),
                busy: _switching,
                busyLabel: 'Switching the Epicbox server…',
                openInitially: widget.arg == ReceivingDemo.comboOpen,
                options: [
                  for (final b in boxes)
                    ComboOption(
                      value: b.domain,
                      host: b.domain,
                      sub: b.operator,
                      isDefault: b.domain == defaultEpicboxHost,
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
                listNote: st.settings.useStatusSite ? 'State from status.btlabs.uk, checked every few minutes.' : null,
                onPicked: _switch,
              ),
            ),
          ]),
          if (DeskFeatures.httpDirect)
            _group(TxMethod.http, SettingsJump.http, 'HTTP receiving', httpLine, [
              _receivingRow(
                TxMethod.http,
                'Straight from another wallet while this one is open.',
                status.httpListener != ServiceHealth.off,
                httpLine,
                // Off while Tor is on (tor_routes.dart): Direct payments arrive at the Tor address.
                enabled: !s.tor,
                notice: s.tor
                    ? ENotice(
                        title: 'Off while Tor is on',
                        text: 'Direct payments arrive at this wallet’s Tor address instead.',
                        actions: [
                          EButton(
                            label: 'Privacy settings',
                            size: EBtnSize.inline,
                            onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.tor),
                          ),
                        ],
                      )
                    : null,
              ),
              _autostart(TxMethod.http, s.httpAutostart, (v) => _saveAutostart(s.copyWith(httpAutostart: v))),
              const HttpOptions(),
            ]),
        ],
      ),
    );
  }
}

/// A group's head: the method's icon in its state colour, the title, the state word right.
class _MethodHead extends StatelessWidget {
  const _MethodHead({required this.method, required this.title, required this.line});

  final TxMethod method;
  final String title;
  final MethodLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final word = switch (line.word) {
      'Not answering' || 'Not receiving' => 'Stopped',
      'Connecting to Tor…' || 'Publishing the Tor address…' || 'Starting…' => 'Starting',
      final w => w,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x3),
      child: Row(
        children: [
          Container(width: 14.u, height: 2, color: c.accent),
          SizedBox(width: 10.u),
          EMethodIcon(method, line.state, size: 20.u),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Semantics(header: true, child: Text(title, style: ts.h3)),
          ),
          Text(word, style: ts.caption.copyWith(fontWeight: FontWeight.w600, color: line.state == EState.off ? c.dim : stateColor(c, line.state))),
        ],
      ),
    );
  }
}
