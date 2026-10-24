import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../data/method_names.dart';
import '../../desk_l10n.dart';
import '../../../net/probe_not_run.dart';
import '../../../network.dart' show EpicboxRelay, defaultEpicboxHost;
import '../../../send_preflight.dart' show relayProbeProvider;
import '../../../tor_routes.dart' show TorRoute, TorWay, torWay;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/tor_view.dart' show torStateOf;
import '../../widgets/kit.dart';
import '../../widgets/server_list_panel.dart';
import '../../data/server_lists.dart';
import '../transfer/epicbox_notice.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_http.dart';

/// Start states of Settings › Receiving, for the tour.
enum ReceivingDemo { comboOpen, picked, torOn, torStopped, epicboxDown, httpOn, httpFailed, httpPublic }

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
      httpProblem: a == ReceivingDemo.httpFailed ? HttpProblem.portInUse : s.httpProblem,
      httpProblemPort: a == ReceivingDemo.httpFailed ? ref.read(deskProvider).settings.httpPort : s.httpProblemPort,
      torProgress: s.torProgress,
      torProblem: a == ReceivingDemo.torStopped ? 'Tor could not connect to the network.' : s.torProblem, // l10n-ok: demo status text
      torCanSend: s.torCanSend,
      torIncluded: s.torIncluded,
      syncProgress: s.syncProgress,
      lastUpdate: s.lastUpdate,
      notice: s.notice,
    );
  }

  Future<void> _toggle(TxMethod m, bool on) async {
    final l = context.l10n;
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
      if (mounted) showEToast(context, on ? l.deskSetRecvMethodOnFailed(methodLabel(l, m)) : l.deskSetRecvMethodOffFailed(methodLabel(l, m)), text: deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy.remove(m));
    }
  }

  Future<void> _switch(String domain) async {
    final l = context.l10n;
    setState(() => _switching = true);
    try {
      await ref.read(deskProvider.notifier).useEpicbox(domain);
    } on Object catch (e) {
      if (mounted) showEToast(context, l.deskSetRecvServerNotChanged, text: deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// Add's test: a WebSocket handshake with the relay, through Tor while the Tor switch covers
  /// the app's connections, as the wallet's Epicbox connection goes. Null when it answered.
  Future<String?> _test(String value) async {
    final l = context.l10n;
    final relay = EpicboxRelay.parse(value);
    if (relay == null) return l.slNotAnAddress;
    try {
      return await ref.read(relayProbeProvider).reachable(relay) ? null : l.slRelayNoAnswer;
    } on ProbeNotRun {
      return l.deskSlTorWait;
    }
  }

  /// The group's first row: the switch (a spinner while it runs) and the state line.
  Widget _receivingRow(TxMethod m, String text, bool on, MethodLine line, {bool enabled = true, Widget? notice}) {
    final l = context.l10n;
    final busy = _busy.contains(m);
    // In Settings the description sits above: an "Off" line needs no repeat of it.
    final shown = line.state == EState.off && m != TxMethod.epicbox ? MethodLine(line.word, line.state) : line;
    return ESetRow(
      title: l.deskSetRecvReceiving,
      text: text,
      control: SizedBox(
        width: 40.u,
        height: 24.u,
        child: busy
            ? Center(child: Semantics(label: l.deskSetRecvSwitching(methodLabel(l, m)), child: ESpinner(size: 18.u)))
            : ESwitch(
                key: ValueKey('st-switch-${m.name}'),
                value: on,
                semanticLabel: l.deskSetRecvMethodReceiving(methodLabel(l, m)),
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
                    label: m == TxMethod.http ? l.deskSetBackupTryAgain : l.commonRetry,
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
    final l = context.l10n;
    try {
      await ref.read(deskProvider.notifier).saveSettings(s);
    } on Object catch (e) {
      if (mounted) showEToast(context, l.deskSetRecvNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
    }
  }

  Widget _autostart(TxMethod m, bool value, ValueChanged<bool>? onChanged) {
    final l = context.l10n;
    return ESetRow(
      title: l.deskSetRecvAutostart,
      hint: l.deskSetRecvAutostartHint,
      control: ESwitch(key: ValueKey('st-autostart-${m.name}'), value: value, semanticLabel: l.deskSetRecvMethodAutostart(methodLabel(l, m)), onChanged: onChanged),
    );
  }

  /// The word at the right of a group's head: Stopped or Starting where the line says why in
  /// words of its own, else the line's word.
  String _headWord(AppLocalizations l, TxMethod m, ServiceStatus status, DeskSettings s, MethodLine line) {
    switch (m) {
      case TxMethod.epicbox:
        if (status.epicboxHealth == ServiceHealth.down) {
          final way = torWay(TorRoute.epicbox, torStateOf(s, status));
          if (way != TorWay.wait && way != TorWay.blocked) return l.deskSetRecvHeadStopped;
        }
      case TxMethod.http:
        if (status.httpListener == ServiceHealth.down) return l.deskSetRecvHeadStopped;
        if (status.httpListener == ServiceHealth.checking) return l.deskSetRecvHeadStarting;
      case TxMethod.tor:
        if (status.tor == ServiceHealth.checking) return l.deskSetRecvHeadStarting;
        if (status.tor == ServiceHealth.down) return l.deskSetRecvHeadStopped;
      case TxMethod.file:
        break;
    }
    return line.word;
  }

  Widget _group(TxMethod m, SettingsJump jump, String title, MethodLine line, String word, List<Widget> rows) => JumpSection(
    section: jump,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodHead(method: m, title: title, line: line, word: word),
        ESetGroup(rows: rows),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final boxes = st.epicboxes;
    final raw = st.status;
    if (boxes == null || raw == null) {
      return const SettingsFrame(route: DeskRoute.settingsReceiving, child: SettingsLoading());
    }
    final status = _status(raw);
    final s = st.settings;
    final box = status.epicbox;
    final ebLine = methodStateLine(l, TxMethod.epicbox, status, s);
    final httpLine = methodStateLine(l, TxMethod.http, status, s);

    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group(TxMethod.epicbox, SettingsJump.epicbox, l.deskSetRecvEpicboxTitle, ebLine, _headWord(l, TxMethod.epicbox, status, s, ebLine), [
            _receivingRow(
              TxMethod.epicbox,
              l.deskSetRecvEpicboxText,
              status.epicboxHealth != ServiceHealth.off,
              ebLine,
              notice: status.epicboxHealth == ServiceHealth.down ? const EpicboxDownNotice() : null,
            ),
            _autostart(TxMethod.epicbox, s.epicboxAutostart, (v) => _saveAutostart(s.copyWith(epicboxAutostart: v))),
            ESetRow(
              title: l.deskSetRecvEpicboxServer,
              hint: l.deskSetRecvEpicboxServerHint,
              stacked: true,
              control: ServerListPanel(
                kind: ServerKind.relay,
                label: l.deskSetRecvEpicboxServer,
                value: relayLabel(box),
                fieldText: relayLabel(box),
                fieldSub: box.operator,
                tone: epicboxTone(status.epicboxHealth),
                servers: relayPanelRows([...boxes, if (!boxes.any((b) => relayLabel(b) == relayLabel(box))) box], defaultHost: defaultEpicboxHost),
                source: relaySource(boxes, inUse: relayLabel(box)),
                listNote: st.settings.useStatusSite ? l.deskSetRecvListNote : null,
                busy: _switching,
                busyLabel: l.deskSetRecvSwitchingServer,
                openInitially: widget.arg == ReceivingDemo.comboOpen,
                demo: widget.arg == ReceivingDemo.picked ? const ServerPanelDemo(pick: 'epicbox.stackwallet.com') : null, // l10n-ok: a relay host
                onChoose: _switch,
                onTest: _test,
              ),
            ),
          ]),
          if (DeskFeatures.httpDirect)
            _group(TxMethod.http, SettingsJump.http, l.deskSetRecvHttpTitle, httpLine, _headWord(l, TxMethod.http, status, s, httpLine), [
              _receivingRow(
                TxMethod.http,
                l.deskSetRecvHttpText,
                status.httpListener != ServiceHealth.off,
                httpLine,
                // Off while Tor is on (tor_routes.dart): Direct payments arrive at the Tor address.
                enabled: !s.tor,
                notice: s.tor
                    ? ENotice(
                        title: l.deskSetRecvHttpOffTitle,
                        text: l.deskSetRecvHttpOffText,
                        actions: [
                          EButton(
                            label: l.deskSetRecvPrivacySettings,
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
  const _MethodHead({required this.method, required this.title, required this.line, required this.word});

  final TxMethod method;
  final String title;
  final MethodLine line;
  final String word;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
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
