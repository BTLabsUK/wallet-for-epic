// SPDX-License-Identifier: Apache-2.0
import '../../../tor_routes.dart' show TorState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../levels/wallet_level.dart';
import '../../../models.dart' show defaultMinimumConfirmations, maxMinimumConfirmations, minMinimumConfirmations;
import '../../../payment_prefs.dart';
import '../../../advanced.dart' show NetworkModeRestricted;
import '../../../tor_pay.dart';
import '../../../trust_ids.dart';
import '../../data/method_names.dart';
import '../../data/net_mode_view.dart' show netTorState;
import '../../desk_l10n.dart';
import '../../../net/probe_not_run.dart';
import '../../../network.dart' show EpicboxRelay;
import '../../../settings_file/host_settings.dart' show shippedHostSettings;
import '../../../send_preflight.dart' show relayProbeProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/http_reach.dart' show deskHttpReachClosedProvider;
import '../../widgets/kit.dart';
import '../../widgets/server_list_panel.dart';
import '../../data/server_lists.dart';
import '../transfer/epicbox_notice.dart';
import '../../data/desk_levels.dart' show deskLevelProvider;
import '../wallet/outputs_dialogs.dart' show EStepper;
import 'prefs.dart';
import 'search/settings_sections.dart' show setJoinReasons;
import 'setting_ids.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;
import 'settings_http.dart';
import '../../../settings_file/status_site.dart' show statusSiteHost;

/// Start states of Settings › Transactions (once Receiving), for the tour. [directOn] has the
/// Direct switch on, [sendOptions] also Advanced › Send options.
enum ReceivingShot { comboOpen, picked, torOn, torStopped, epicboxDown, httpOn, httpFailed, httpPublic, directOn, sendOptions }

ETone epicboxTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.checking => ETone.info,
  ServiceHealth.slow => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

/// Settings › Payments (once Transactions; one switch per method 26.10.16): how payments
/// are made, then Sending and Receiving (Confirmations). Payment methods grouped by family (Epicbox; Link › HTTP, Tor; Direct › File
/// Transfer), each one switch, at least one on; what Send starts on and, with Advanced › Send
/// options, its defaults. Each method's receiving details sit under its own switch, shown
/// only while it is on (no scrolling to the bottom to see them): Epicbox its
/// listener switch, Start with the wallet and the server; Link · HTTP its state line and
/// options (the method switch is the one HTTP switch, there is no second one) while it is on
/// or its listener still runs; Link · Tor the state of Tor for payments under its switch (item 2).
/// The Tor caption under the Epicbox rows, for tests.
const Key deskTorRelayCaptionKey = ValueKey('tor-relay-caption');

/// Link · Tor's state under its switch, for tests.
const Key deskTorPayLineKey = ValueKey('st-torPay-line');

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
      if (arg == ReceivingShot.torOn || arg == ReceivingShot.torStopped) {
        // Link · Tor on: Tor for payments starts, the Tor switch of Network & privacy stays off.
        await n.setLinkTor(true);
      }
      if (arg == ReceivingShot.httpOn || arg == ReceivingShot.httpFailed || arg == ReceivingShot.httpPublic) await n.setHttp(true);
      if (arg == ReceivingShot.httpPublic && !s.publicMode) await n.saveSettings(ref.read(deskProvider).settings.copyWith(publicMode: true));
      if (arg == ReceivingShot.directOn || arg == ReceivingShot.sendOptions) {
        await n.setHttp(true);
        if (arg == ReceivingShot.sendOptions) {
          final now = ref.read(deskProvider).settings;
          await n.saveSettings(now.copyWith(advanced: now.advanced.withFeature(AdvancedFeature.sendOptions, true)));
        }
      }
    });
  }

  /// The real status with the tour's failed states laid over it.
  ServiceStatus _status(ServiceStatus s) {
    final a = widget.arg;
    if (a != ReceivingShot.epicboxDown && a != ReceivingShot.httpFailed && a != ReceivingShot.torStopped) return s;
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: a == ReceivingShot.epicboxDown ? ServiceHealth.down : s.epicboxHealth,
      httpListener: a == ReceivingShot.httpFailed ? ServiceHealth.down : s.httpListener,
      tor: a == ReceivingShot.torStopped ? ServiceHealth.down : s.tor,
      httpProblem: a == ReceivingShot.httpFailed ? HttpProblem.portInUse : s.httpProblem,
      httpProblemPort: a == ReceivingShot.httpFailed ? ref.read(deskProvider).settings.httpPort : s.httpProblemPort,
      torProgress: s.torProgress,
      torProblem: a == ReceivingShot.torStopped ? 'Tor could not connect to the network.' : s.torProblem, // l10n-ok: shot status text
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
          // Link · Tor (item 2): tor for payments alone; Retry starts it again. The Tor switch
          // of Network & privacy is never touched here.
          if (ref.read(deskProvider).settings.payments.linkTor == on) {
            await n.retryTorPay();
          } else {
            await n.setLinkTor(on);
          }
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
  Widget _receivingRow(TxMethod m, String text, bool on, MethodLine line, {bool enabled = true, bool switchable = true, Widget? notice, Widget? picker, String? anchor}) {
    final l = context.l10n;
    final busy = _busy.contains(m);
    // The row's info hint describes the method: an "Off" line needs no repeat of it.
    final shown = line.state == EState.off && m != TxMethod.epicbox ? MethodLine(line.word, line.state) : line;
    return ESetRow(
      anchor: anchor,
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
          // Epicbox: the server picker is the row's first line; the state line follows it.
          if (picker != null) ...[picker, SizedBox(height: Sp.x3)],
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

  Widget _autostart(TxMethod m, bool value, ValueChanged<bool>? onChanged, {String? anchor}) {
    final l = context.l10n;
    return ESetRow(
      anchor: anchor,
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
      // Tor for payments alone (item 2): the Tor switch of Network & privacy stays as it is.
      case MethodKind.linkTor:
        return _toggle(TxMethod.tor, on);
      case MethodKind.directQr || MethodKind.directFile:
        return _savePayments((x) => x.withMethod(m, on));
    }
  }

  /// A method's row in Payment methods: its icon, its name under the family's subhead, one
  /// hint, and its switch. Link · Tor starts Tor for its payments by itself (item 2).
  Widget _methodRow(MethodKind m, PaymentPrefs p, DeskSettings s, {required String anchor, TorPay? torPay}) {
    final l = context.l10n;
    final name = MethodIcons.groupName(l, m);
    final full = MethodIcons.fullName(l, m);
    final hint = switch (m) {
      MethodKind.epicbox => l.deskSetTxEpicboxHint,
      MethodKind.linkHttp => DeskFeatures.tor ? l.deskSetTxDirectHint('${s.httpPort}') : l.deskNoTorSetTxDirectHint('${s.httpPort}'),
      MethodKind.linkTor => l.deskSetTxTorPayHint,
      MethodKind.directQr => '',
      MethodKind.directFile => l.deskSetTxFileHint,
    };
    final busy = (m == MethodKind.linkHttp && _busy.contains(TxMethod.http)) || (m == MethodKind.linkTor && _busy.contains(TxMethod.tor));
    // Link · Tor is locked while Node only or Kill switch blocks it; its line says why.
    final locked = m == MethodKind.linkTor && torPay != null && !torPayCanSwitch(torPay);
    return ESetRow(
      key: ValueKey('st-method-${m.name}'),
      anchor: anchor,
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
                onChanged: locked ? null : (v) => _setMethod(m, v),
              ),
      ),
      below: m == MethodKind.linkTor && torPay != null && torPay.kind != TorPayKind.off ? _torPayBelow(torPay) : null,
    );
  }

  /// Under the Link · Tor switch: what Tor for payments does now (starting, receiving at the
  /// onion with Copy, off in Node only or Kill switch and why, failed with Retry), then whether
  /// Tor also carries every other connection (Network & privacy's switch).
  Widget _torPayBelow(TorPay p) {
    final l = context.l10n;
    final c = context.dc;
    final busy = _busy.contains(TxMethod.tor);
    final text = torPayLine(l, p);
    final cut = text.indexOf(' · ');
    final state = switch (p.kind) {
      TorPayKind.ready => EState.ok,
      TorPayKind.starting => EState.active,
      TorPayKind.failed => EState.risk,
      TorPayKind.off || TorPayKind.blocked => EState.off,
    };
    final line = cut < 0 ? MethodLine(text, state) : MethodLine(text.substring(0, cut), state, detail: text.substring(cut + 3));
    final onion = p.kind == TorPayKind.ready ? p.onion : null;
    return Column(
      key: deskTorPayLineKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EStateLine(
          line,
          key: const ValueKey('st-state-torPay'),
          trailing: torPayRetry(p)
              ? EButton(
                  key: const ValueKey('st-torPay-retry'),
                  label: l.commonRetry,
                  icon: EIcons.refresh,
                  size: EBtnSize.inline,
                  busy: busy,
                  onPressed: busy ? null : () => _toggle(TxMethod.tor, true),
                )
              : null,
        ),
        if (onion != null) ...[SizedBox(height: Sp.x2), EAddress(onion, copyLabel: l.deskRecvCopyTor)],
        if (p.kind != TorPayKind.blocked) ...[
          SizedBox(height: Sp.x2),
          Text(torPayRestLine(l, p), key: const ValueKey('st-torPay-rest'), style: context.ts.small.copyWith(color: c.dim)),
        ],
      ],
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

  /// Send starts on names Link once for the family (the address picks HTTP or Tor), the
  /// others by their short name (a segment is a tight place).
  String _startName(AppLocalizations l, MethodKind m) => switch (m) {
    MethodKind.linkHttp || MethodKind.linkTor => MethodIcons.familyName(l, MethodFamily.link),
    // The phone's list and the short tier (UD-031): Epicbox, Link, Direct · File.
    _ => MethodIcons.shortName(l, m),
  };

  /// Payment methods: one switch per method, grouped by family. Epicbox is its own family, so
  /// its row stands alone; Link and Direct get a subhead on their first method's row. A method
  /// that is on carries its receiving [details] right under its row, so the feedback (the
  /// state line, the server, the options) is where the switch is.
  Widget _methodsGroup(PaymentPrefs p, DeskSettings s, Map<MethodKind, (SettingsJump, List<Widget>)> details, TorPay torPay) {
    final l = context.l10n;
    Widget row(MethodKind m, {required String anchor}) {
      final d = details[m];
      final body = _methodRow(m, p, s, anchor: anchor, torPay: m == MethodKind.linkTor ? torPay : null);
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
        // Epicbox stands alone; Link (HTTP, Tor in a Tor build) and Direct get their subhead.
        row(MethodKind.epicbox, anchor: SetId.epicbox),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_familyRow(MethodFamily.link), row(MethodKind.linkHttp, anchor: SetId.http)]),
        if (DeskFeatures.tor) row(MethodKind.linkTor, anchor: SetId.torPay),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_familyRow(MethodFamily.direct), row(MethodKind.directFile, anchor: SetId.file)]),
      ],
    );
  }

  /// Send: the method it starts on, and with Advanced › Send options its defaults (the strategy
  /// and Split change that Outputs kept before).
  Widget _sendGroup(PaymentPrefs p) {
    final l = context.l10n;
    // Link once, whichever of its methods is on (the address decides the route).
    final offered = [
      if (p.epicbox) MethodKind.epicbox,
      if (p.offersFamily(MethodFamily.link)) MethodKind.linkHttp,
      if (p.directFile) MethodKind.directFile,
    ];
    final start = p.startMethod.family == MethodFamily.link ? MethodKind.linkHttp : p.startMethod;
    // Deep end with Advanced › Send options; otherwise behind the group's ⇕, saying both.
    final deep = ref.watch(deskLevelProvider) == WalletLevel.everything;
    final options = deep && advancedHas(ref, AdvancedFeature.sendOptions);
    final by = options
        ? null
        : setJoinReasons(l, [if (!deep) advancedByView(l, 3), if (!advancedHas(ref, AdvancedFeature.sendOptions)) advancedByFeature(l, AdvancedFeature.sendOptions)]);
    final out = ref.watch(deskOutputPrefsProvider).value ?? const OutputPrefs();
    final save = ref.read(deskOutputPrefsProvider.notifier).save;
    final optionRows = [
            ESetRow(
              key: const ValueKey('st-strategy'),
              anchor: SetId.strategy,
              advancedBy: by,
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
              anchor: SetId.splitChange,
              advancedBy: by,
              title: l.deskOutSplitChangeTitle,
              hint: l.deskOutSplitChangeText,
              control: ESwitch(
                value: out.smartOutputs,
                semanticLabel: l.deskOutSplitChangeTitle,
                onChanged: (v) => save(OutputPrefs(strategy: out.strategy, smartOutputs: v)),
              ),
            ),
    ];
    return ESetGroup(
        title: l.deskSetTxSending,
        hidden: options ? const [] : optionRows,
        revealKey: 'pay-sending',
        rows: [
          if (offered.length > 1)
            ESetRow(
              key: const ValueKey('st-start-method'),
              anchor: SetId.defaultMethod,
              title: l.deskSetTxStart,
              hint: l.deskSetTxStartHint,
              // Sized to its words: three segments with the family names do not fit the
              // fixed row control. In a narrow window or long words they go under the title,
              // and shrink a little when even that width is short of their words.
              wrap: true,
              control: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: ESegmented<MethodKind>(
                  segments: [for (final m in offered) ESegment(m, _startName(l, m), icon: m.family == MethodFamily.link ? MethodIcons.family(MethodFamily.link) : MethodIcons.of(m))],
                  value: offered.contains(start) ? start : offered.firstOrNull ?? MethodKind.epicbox,
                  onChanged: (m) => _savePayments((x) => x.copyWith(defaultMethod: m)),
                ),
              ),
            ),
          if (options) ...optionRows,
        ],
    );
  }

  /// Tor for payments as the line shows it: Node only and Kill switch say why the switch is
  /// locked even while it is off; the tour's stopped state fails without a reason.
  TorPay _torPay(DeskSettings s) {
    final p = ref.watch(deskTorPayProvider);
    if (p.kind == TorPayKind.off && s.advanced.networkMode.restricted) return TorPay(TorPayKind.blocked, mode: p.mode, torAll: p.torAll);
    if (widget.arg == ReceivingShot.torStopped && s.payments.linkTor) return TorPay(TorPayKind.failed, mode: p.mode, torAll: p.torAll);
    return p;
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
    final httpLine = methodStateLine(l, TxMethod.http, status, s, reachClosed: ref.watch(deskHttpReachClosedProvider));
    final torPay = _torPay(s);

    // Each method's receiving rows, under its switch while it is on.
    final details = <MethodKind, (SettingsJump, List<Widget>)>{
      MethodKind.epicbox: (SettingsJump.epicbox, [
        if (!ebOff) ...[
          _receivingRow(
            TxMethod.epicbox,
            // The server's hint lived on its own row; the picker is here now, so its ⓘ is too.
            '${l.deskSetRecvEpicboxText}\n\n${status.epicboxOwn ? l.deskSetRecvEpicboxOwnHint : l.deskSetRecvEpicboxServerHint}',
            status.epicboxHealth != ServiceHealth.off,
            // The picker names the server: the line keeps its word and any detail beyond the host.
            ebLine.detail == box.domain ? MethodLine(ebLine.word, ebLine.state) : ebLine,
            anchor: SetId.epicboxRecv,
            notice: status.epicboxHealth == ServiceHealth.down ? const EpicboxDownNotice(sentence: false) : null,
            picker: SetAnchor(id: SetId.epicboxServer, child: ServerListPanel(
              kind: ServerKind.relay,
              label: l.deskSetRecvEpicboxServer,
              value: relayLabel(box),
              fieldText: relayLabel(box),
              fieldSub: box.operator,
              tone: epicboxTone(status.epicboxHealth),
              servers: relayPanelRows([...boxes, if (!boxes.any((b) => relayLabel(b) == relayLabel(box))) box], defaultHost: EpicboxRelay.parse(shippedHostSettings.epicboxUse)?.label ?? shippedHostSettings.epicboxUse),
              source: relaySource(boxes, inUse: relayLabel(box)),
              listNote: st.settings.useStatusSite ? l.deskSetRecvListNote(statusSiteHost) : null,
              busy: _switching,
              busyLabel: l.deskSetRecvSwitchingServer,
              openInitially: widget.arg == ReceivingShot.comboOpen,
              shot: widget.arg == ReceivingShot.picked ? ServerPanelShot(pick: shippedHostSettings.epicboxServers.elementAtOrNull(1)?.label ?? relayLabel(box)) : null,
              onChoose: _switch,
              onTest: _test,
            ),
            ),
          ),
          _autostart(TxMethod.epicbox, s.epicboxAutostart, (v) => _saveAutostart(s.copyWith(epicboxAutostart: v)), anchor: SetId.epicboxStart),
          // While Tor is off: where the relay would not see this computer's address.
          if (status.torIncluded && netTorState(s, status) == TorState.off)
            _DetailsNote(key: deskTorRelayCaptionKey, text: l.torRelayCaption),
        ],
      ]),
      // Link · HTTP on; a listener that is on keeps its rows. The switch is the method's: these
      // rows hold its state and options.
      MethodKind.linkHttp: (SettingsJump.http, [
        if (s.payments.linkHttp || status.httpListener != ServiceHealth.off) ...[
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
                        label: l.settingsSectionNetworkPrivacy,
                        size: EBtnSize.inline,
                        onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network),
                      ),
                    ],
                  )
                : null,
          ),
          const HttpOptions(),
        ],
      ]),
      // Link · Tor: its state line is under its own switch (_torPayBelow).
      MethodKind.linkTor: (SettingsJump.tor, const []),
    };

    return SettingsFrame(
      route: DeskRoute.settingsReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _methodsGroup(s.payments, s, details, torPay),
          _sendGroup(s.payments),
          const JumpSection(section: SettingsJump.confirmations, child: ReceivingGroup()),
        ],
      ),
    );
  }
}

/// A method's receiving rows under its switch: set in from the icon column, on the next
/// surface step, so they read as the method's own and not as more methods. One divider style:
/// full-width hairlines between rows, none before a [_DetailsNote]; the rows are indented to
/// the method's title (ESetRow's leading, 18 px and a gap), with no rail.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && rows[i] is! _DetailsNote) Divider(height: 1, thickness: 1, color: c.line),
            // HttpOptions indents its own rows, so its divider spans the card too.
            if (rows[i] is HttpOptions) rows[i] else Padding(padding: methodDetailsIndent, child: rows[i]),
          ],
        ],
      ),
    );
  }
}

/// A quiet line at the end of a method's details: inside the group, under the row before it
/// with no line of its own, and the rows' own bottom padding.
class _DetailsNote extends StatelessWidget {
  const _DetailsNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(Sp.panel, 0, Sp.panel, Sp.x4),
    child: Text(text, style: context.ts.small),
  );
}

/// Payments › Receiving: the wallet's minimum confirmations (the core keeps it per wallet): a
/// stepper that applies each step at once, a Default tag at the default and Reset elsewhere,
/// and a quiet line under it below the default. A refused count goes back and says why in a
/// toast.
class ReceivingGroup extends ConsumerWidget {
  const ReceivingGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final count = ref.watch(deskMinConfirmationsSettingProvider).value ?? deskMinConfirmations(ref);
    Future<void> set(int n) async {
      if (n == count) return;
      try {
        await ref.read(deskMinConfirmationsSettingProvider.notifier).set(n);
      } on Object catch (e) {
        if (context.mounted) showEToast(context, l.deskSetAdvConfirmationsNotSaved, text: deskErrorText(e, l), tone: ETone.risk);
      }
    }

    return ESetGroup(
      key: const ValueKey('adv-balance'),
      title: l.deskSetRecvReceiving,
      rows: [
        ESetRow(
          key: const ValueKey('adv-minConfirmations'),
          anchor: SetId.confirmations,
          title: l.deskSetAdvConfirmations,
          hint: l.deskSetAdvConfirmationsHint(defaultMinimumConfirmations, minMinimumConfirmations, maxMinimumConfirmations),
          hintTitle: l.deskSetAdvConfirmations,
          wrap: true,
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count == defaultMinimumConfirmations)
                EBadge(l.deskSetAdvConfirmationsDefault)
              else
                EButton.ghost(
                  key: const ValueKey('adv-minConfirmations-reset'),
                  label: l.deskSetAdvConfirmationsReset(defaultMinimumConfirmations),
                  size: EBtnSize.inline,
                  onPressed: () => set(defaultMinimumConfirmations),
                ),
              SizedBox(width: Sp.x3),
              EStepper(
                value: count,
                min: minMinimumConfirmations,
                max: maxMinimumConfirmations,
                label: l.deskSetAdvConfirmations,
                fewerLabel: l.deskSetAdvConfirmationsFewer,
                moreLabel: l.deskSetAdvConfirmationsMore,
                fewerId: TrustIds.paymentsConfirmationsFewer,
                moreId: TrustIds.paymentsConfirmationsMore,
                onChanged: set,
              ),
            ],
          ),
          below: count < defaultMinimumConfirmations
              ? Text(l.deskSetAdvConfirmationsLowNote, key: const ValueKey('adv-minConfirmations-note'), style: context.ts.small.copyWith(color: c.dim))
              : null,
        ),
      ],
    );
  }
}
