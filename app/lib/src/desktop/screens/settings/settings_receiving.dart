import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../advanced.dart' show NetworkMode;
import '../../../payment_prefs.dart';
import '../../data/method_names.dart';
import '../../data/net_mode_view.dart' show netTorState;
import '../../desk_l10n.dart';
import '../../../net/probe_not_run.dart';
import '../../../network.dart' show EpicboxRelay, defaultEpicboxHost;
import '../../../send_preflight.dart' show relayProbeProvider;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../../widgets/server_list_panel.dart';
import '../../data/server_lists.dart';
import '../transfer/epicbox_notice.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;
import 'settings_http.dart';
import 'settings_privacy.dart' show torStateLine;

/// Start states of Settings › Transactions (once Receiving), for the tour. [directOn] has the
/// Direct switch on, [sendOptions] also Advanced › Send options.
enum ReceivingDemo { comboOpen, picked, torOn, torStopped, epicboxDown, httpOn, httpFailed, httpPublic, directOn, sendOptions }

ETone epicboxTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

/// Settings › Transactions (spec 6.1, 26.10.13; one switch per method 26.10.16): how payments
/// are made. Payment methods grouped by family (Epicbox; Link › HTTP, Tor; Direct › File
/// Transfer), each one switch, at least one on; what Send starts on and, with Advanced › Send
/// options, its defaults. Each method's receiving details sit under its own switch, shown
/// only while it is on (tester #112: no scrolling to the bottom for feedback): Epicbox its
/// listener switch, Start with the wallet and the server; Link · HTTP its state line and
/// options (the method switch is the one HTTP switch, there is no second one) while it is on
/// or its listener still runs; Link · Tor its state line (Tor itself is Settings › Privacy's).
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
      if (arg == ReceivingDemo.torOn || arg == ReceivingDemo.torStopped) {
        // Link · Tor on with Tor: its group shows with the Tor state.
        if (!s.payments.linkTor) await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: true)));
        await n.setTor(true);
      }
      if (arg == ReceivingDemo.httpOn || arg == ReceivingDemo.httpFailed || arg == ReceivingDemo.httpPublic) await n.setHttp(true);
      if (arg == ReceivingDemo.httpPublic && !s.publicMode) await n.saveSettings(ref.read(deskProvider).settings.copyWith(publicMode: true));
      if (arg == ReceivingDemo.directOn || arg == ReceivingDemo.sendOptions) {
        await n.setHttp(true);
        if (arg == ReceivingDemo.sendOptions) {
          final now = ref.read(deskProvider).settings;
          await n.saveSettings(now.copyWith(advanced: now.advanced.withFeature(AdvancedFeature.sendOptions, true)));
        }
      }
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
      return DeskFeatures.tor ? l.deskSlTorWait : l.slRelayNoAnswer;
    }
  }

  /// The group's first row: the switch (a spinner while it runs) and the state line. Without
  /// [switchable] the row is the state alone: the method's switch in Payment methods is the
  /// one switch (Link · HTTP), so none is repeated here.
  Widget _receivingRow(TxMethod m, String text, bool on, MethodLine line, {bool enabled = true, bool switchable = true, Widget? notice}) {
    final l = context.l10n;
    final busy = _busy.contains(m);
    // The row's info hint describes the method: an "Off" line needs no repeat of it.
    final shown = line.state == EState.off && m != TxMethod.epicbox ? MethodLine(line.word, line.state) : line;
    return ESetRow(
      title: l.deskSetRecvReceiving,
      hint: text,
      control: !switchable ? null : SizedBox(
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
  Future<void> _savePayments(PaymentPrefs Function(PaymentPrefs p) change) async {
    final s = ref.read(deskProvider).settings;
    await _saveAutostart(s.copyWith(payments: change(s.payments)));
  }

  /// Epicbox off while sends still wait for their replies over Epicbox: "Turn Epicbox off?".
  Future<bool> _confirmEpicboxOff(int waiting) async {
    final yes = await showEDialog<bool>(
      context,
      builder: (context) {
        final l = context.l10n;
        return EDialog(
          title: l.txEpicboxOffTitle,
          description: l.txEpicboxOffPending(waiting),
          icon: EIcons.epicbox,
          actions: [
            EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop(false)),
            EButton.primary(label: l.txEpicboxOffAction, onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );
    return yes == true;
  }

  Future<void> _setEpicbox(bool on) async {
    if (!on) {
      final waiting = (ref.read(deskProvider).txs ?? const <Tx>[])
          .where((t) => t.method == TxMethod.epicbox && t.state == TxState.waitingRecipient && !t.incoming)
          .length;
      if (waiting > 0 && !await _confirmEpicboxOff(waiting)) return;
    }
    await _savePayments((x) => x.copyWith(epicbox: on));
  }

  /// A method's switch changed: the last one on stays on (a toast says so); Epicbox asks
  /// while sends wait; Link · HTTP starts or stops the listener with the switch.
  Future<void> _setMethod(MethodKind m, bool on) async {
    final l = context.l10n;
    final p = ref.read(deskProvider).settings.payments;
    if (!on && !p.canTurnOff(m)) {
      showEToast(context, l.deskSetTxLastMethod, tone: ETone.warn);
      return;
    }
    switch (m) {
      case MethodKind.epicbox:
        return _setEpicbox(on);
      case MethodKind.linkHttp:
        return _toggle(TxMethod.http, on);
      case MethodKind.linkTor || MethodKind.directQr || MethodKind.directFile:
        return _savePayments((x) => x.withMethod(m, on));
    }
  }

  /// A method's row in Payment methods: its icon, its name under the family's subhead, one
  /// hint, and its switch. Link · Tor on while Tor is off says what it needs.
  Widget _methodRow(MethodKind m, PaymentPrefs p, DeskSettings s) {
    final l = context.l10n;
    final name = MethodIcons.groupName(l, m);
    final full = MethodIcons.fullName(l, m);
    final hint = switch (m) {
      MethodKind.epicbox => l.deskSetTxEpicboxHint,
      MethodKind.linkHttp => DeskFeatures.tor ? l.deskSetTxDirectHint : l.deskNoTorSetTxDirectHint,
      MethodKind.linkTor => l.deskSetTxTorHint,
      MethodKind.directQr => '',
      MethodKind.directFile => l.deskSetTxFileHint,
    };
    final busy = m == MethodKind.linkHttp && _busy.contains(TxMethod.http);
    final needsTor = m == MethodKind.linkTor && p.linkTor && !s.tor;
    return ESetRow(
      key: ValueKey('st-method-${m.name}'),
      leading: MethodIcons.of(m),
      title: name,
      hint: hint,
      hintTitle: full,
      hintIcon: MethodIcons.of(m),
      control: SizedBox(
        width: 40.u,
        height: 24.u,
        child: busy
            ? Center(child: Semantics(label: l.deskSetRecvSwitching(full), child: ESpinner(size: 18.u)))
            : ESwitch(
                key: ValueKey('st-offer-${m.name}'),
                value: p.offers(m),
                semanticLabel: full,
                onChanged: (v) => _setMethod(m, v),
              ),
      ),
      below: needsTor
          ? ENotice(
              key: const ValueKey('st-tor-needs-tor'),
              icon: EIcons.tor,
              title: l.deskSetTxTorNeedsTor,
              // Offline: Tor never runs there, so no way to turn it on here; the reason instead.
              text: s.advanced.networkMode == NetworkMode.offline ? l.netBlockOffline : null,
              actions: [
                if (s.advanced.networkMode != NetworkMode.offline) ...[
                  EButton(label: l.deskSetHttpTurnOnTor, icon: EIcons.tor, size: EBtnSize.inline, onPressed: () => _toggle(TxMethod.tor, true)),
                  EButton.ghost(label: l.deskSetRecvPrivacySettings, size: EBtnSize.inline, onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.tor)),
                ],
              ],
            )
          : null,
    );
  }

  /// A family's subhead inside Payment methods: its glyph and name, over its methods.
  Widget _familyRow(MethodFamily f) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    return Padding(
      key: ValueKey('st-family-${f.name}'),
      padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, 0),
      child: Row(
        children: [
          Icon(MethodIcons.family(f), size: 16.u, color: c.dim),
          SizedBox(width: Sp.x2),
          Semantics(header: true, child: Text(MethodIcons.familyName(l, f), style: ts.caption.copyWith(fontWeight: FontWeight.w600, color: c.dim))),
        ],
      ),
    );
  }

  /// The methods this build has, by family: Epicbox; Link › HTTP, Tor; Direct › File Transfer
  /// (QR Payment is the phone's).
  static List<MethodKind> _familyMethods(MethodFamily f) => [
    for (final m in MethodKind.values)
      if (m.family == f && m != MethodKind.directQr && (m != MethodKind.linkHttp || DeskFeatures.httpDirect) && (m != MethodKind.linkTor || DeskFeatures.tor)) m,
  ];

  /// Send starts on names Link once for the family (the address picks HTTP or Tor), the
  /// others by their short name (a segment is a tight place).
  String _startName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.linkHttp || MethodKind.linkTor => MethodIcons.familyName(l, MethodFamily.link),
    _ => MethodIcons.fullName(l, m),
  };

  /// Payment methods: one switch per method, grouped by family. Epicbox is its own family, so
  /// its row stands alone; Link and Direct get a subhead on their first method's row. A method
  /// that is on carries its receiving [details] right under its row, so the feedback (the
  /// state line, the server, the options) is where the switch is.
  Widget _methodsGroup(PaymentPrefs p, DeskSettings s, Map<MethodKind, (SettingsJump, List<Widget>)> details) {
    final l = context.l10n;
    Widget row(MethodKind m) {
      final d = details[m];
      final body = _methodRow(m, p, s);
      if (d == null) return body;
      final (jump, rows) = d;
      return JumpSection(
        section: jump,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            if (rows.isNotEmpty) _MethodDetails(method: m, rows: rows),
          ],
        ),
      );
    }
    return ESetGroup(
      title: l.deskSetTxMethods,
      rows: [
        for (final f in MethodFamily.values)
          for (final (i, m) in _familyMethods(f).indexed)
            if (i == 0 && f != MethodFamily.epicbox)
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_familyRow(f), row(m)])
            else
              row(m),
      ],
    );
  }

  /// Send: the method it starts on, and with Advanced › Send options its defaults (the strategy
  /// and Split change that Outputs kept before).
  Widget? _sendGroup(PaymentPrefs p) {
    final l = context.l10n;
    // Link once, whichever of its methods is on (the address decides the route).
    final offered = [
      if (p.epicbox) MethodKind.epicbox,
      if ((DeskFeatures.httpDirect || DeskFeatures.tor) && p.offersFamily(MethodFamily.link)) MethodKind.linkHttp,
      if (p.directFile) MethodKind.directFile,
    ];
    final start = p.startMethod.family == MethodFamily.link ? MethodKind.linkHttp : p.startMethod;
    final options = advancedHas(ref, AdvancedFeature.sendOptions);
    if (offered.length < 2 && !options) return null;
    final out = ref.watch(deskOutputPrefsProvider).value ?? const OutputPrefs();
    final save = ref.read(deskOutputPrefsProvider.notifier).save;
    return ESetGroup(
        title: l.deskSetTxSend,
        rows: [
          if (offered.length > 1)
            ESetRow(
              key: const ValueKey('st-start-method'),
              title: l.deskSetTxStart,
              hint: l.deskSetTxStartHint,
              // Sized to its words: three segments with the family names do not fit the
              // fixed row control. In a narrow window or long words they go under the title.
              wrap: true,
              control: ESegmented<MethodKind>(
                segments: [for (final m in offered) ESegment(m, _startName(l, m), icon: m.family == MethodFamily.link ? MethodIcons.family(MethodFamily.link) : MethodIcons.of(m))],
                value: offered.contains(start) ? start : offered.firstOrNull ?? MethodKind.epicbox,
                onChanged: (m) => _savePayments((x) => x.copyWith(defaultMethod: m)),
              ),
            ),
          if (options) ...[
            ESetRow(
              key: const ValueKey('st-strategy'),
              title: l.deskOutStrategyTitle,
              hint: l.deskOutStrategyHint,
              hintTitle: l.deskOutStrategyHelpTitle,
              hintIcon: EIcons.coins,
              control: ERowControl(
                child: ESegmented<SelectionStrategy>(
                  stretch: true,
                  segments: [ESegment(SelectionStrategy.smallest, l.deskOutStrategySmallest), ESegment(SelectionStrategy.all, l.deskOutStrategyAll)],
                  value: out.strategy,
                  onChanged: (v) => save(OutputPrefs(strategy: v, smartOutputs: out.smartOutputs)),
                ),
              ),
            ),
            ESetRow(
              key: const ValueKey('st-split'),
              title: l.deskOutSplitChangeTitle,
              hint: l.deskOutSplitChangeText,
              control: ESwitch(
                value: out.smartOutputs,
                semanticLabel: l.deskOutSplitChangeTitle,
                onChanged: (v) => save(OutputPrefs(strategy: out.strategy, smartOutputs: v)),
              ),
            ),
          ],
        ],
    );
  }

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
    // The Epicbox switch off: the group reads Off with the reason, its Receiving switch waits.
    final ebOff = !s.payments.epicbox;
    final ebLine = ebOff
        ? MethodLine(l.deskKitMethodOff, EState.off, detail: l.netBlockEpicboxOff)
        : methodStateLine(l, TxMethod.epicbox, status, s);
    final httpLine = methodStateLine(l, TxMethod.http, status, s);
    final torLine = torStateLine(l, netTorState(s, status), status, included: status.torIncluded);

    // Each method's receiving rows, under its switch while it is on.
    final details = <MethodKind, (SettingsJump, List<Widget>)>{
      MethodKind.epicbox: (SettingsJump.epicbox, [
        if (!ebOff) ...[
          _receivingRow(
            TxMethod.epicbox,
            l.deskSetRecvEpicboxText,
            status.epicboxHealth != ServiceHealth.off,
            ebLine,
            notice: status.epicboxHealth == ServiceHealth.down ? const EpicboxDownNotice(sentence: false) : null,
          ),
          _autostart(TxMethod.epicbox, s.epicboxAutostart, (v) => _saveAutostart(s.copyWith(epicboxAutostart: v))),
          ESetRow(
            title: l.deskSetRecvEpicboxServer,
            hint: status.epicboxOwn ? l.deskSetRecvEpicboxOwnHint : l.deskSetRecvEpicboxServerHint,
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
        ],
      ]),
      // Link · HTTP on; a listener that is on keeps its rows. The switch is the method's: these
      // rows hold its state and options.
      MethodKind.linkHttp: (SettingsJump.http, [
        if (DeskFeatures.httpDirect && (s.payments.linkHttp || status.httpListener != ServiceHealth.off)) ...[
          _receivingRow(
            TxMethod.http,
            l.deskSetRecvHttpText,
            status.httpListener != ServiceHealth.off,
            httpLine,
            switchable: false,
            // Off while Tor is on (tor_routes.dart): Link payments arrive at the Tor address.
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
          const HttpOptions(),
        ],
      ]),
      // Link · Tor on: where its address stands (Tor itself is Settings › Privacy's switch).
      MethodKind.linkTor: (SettingsJump.tor, [
        if (DeskFeatures.tor && s.payments.linkTor) _receivingRow(TxMethod.tor, l.deskSetRecvTorText, s.tor, torLine, switchable: false),
      ]),
    };

    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _methodsGroup(s.payments, s, details),
          ?_sendGroup(s.payments),
        ],
      ),
    );
  }
}

/// A method's receiving rows under its switch: set in from the icon column, on the next
/// surface step, so they read as the method's own and not as more methods.
class _MethodDetails extends StatelessWidget {
  const _MethodDetails({required this.method, required this.rows});

  final MethodKind method;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      key: ValueKey('st-details-${method.name}'),
      decoration: BoxDecoration(color: c.s2, border: Border(top: BorderSide(color: c.line))),
      // The icon column (ESetRow's leading, 18 px and a gap) is the indent; a hairline in it
      // ties the rows to the switch above.
      padding: EdgeInsets.only(left: 18.u + Sp.x3),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.lineStrong, width: 2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}
