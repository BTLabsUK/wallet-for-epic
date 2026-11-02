// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/relay_offer.dart' show deskRelayMovedProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider, deskLevelUiProvider;
import '../../../levels/relay_switch_providers.dart' show RelaySwitchResult;
import '../../data/method_names.dart';
import '../../../network.dart' show EpicboxRelay;
import '../../../network_gate.dart' show NetBlock, NetBlockByMode, NetGate;
import '../../../connection_grace.dart' show connectionGraceProvider;
import '../../data/net_mode_view.dart';
import '../../data/tor_view.dart';
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../widgets/http_addresses.dart';
import '../../widgets/http_reach.dart' show deskLastHttpReachProvider;
import '../../data/pairing_state.dart' show deskInvoicesShownProvider, deskPairsProvider;
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart' show DeskPaymentSteps;
import '../../widgets/tor_chip.dart';
import '../invoices/invoice_parts.dart' show InvButton, InvW;
import 'epicbox_notice.dart';
import 'finished_payment.dart' show showPostFinished;
import '../../../ui/network_mode_text.dart' show networkModeName, statusOffByModeWord;
import '../settings/prefs.dart' show SettingsJump, settingsPrefsProvider;
import '../../../settings_file/host_settings.dart' show appConfig, hostSettings;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;

enum RxEpicbox { on, off, down, blocked }

enum RxHttp { off, on, starting, failed }

enum RxTor { off, on, connecting, failed }

enum RxQr { none, epicbox, http }

/// Argument of the Receive route, for the tour: which method is on, starting or
/// failed, and which QR code is revealed. The page sets the methods on or off as asked and
/// shows the starting and failed states over the real status.
class ReceiveArgs {
  const ReceiveArgs({this.epicbox = RxEpicbox.on, this.http = RxHttp.off, this.tor = RxTor.off, this.qr = RxQr.none});

  final RxEpicbox epicbox;
  final RxHttp http;
  final RxTor tor;
  final RxQr qr;
}

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  ReceiveArgs? _args;
  String? _http;
  String? _tor;
  final Set<TxMethod> _busy = {};
  final Map<TxMethod, GlobalKey> _panels = {for (final m in TxMethod.values) m: GlobalKey()};

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    _args = a is ReceiveArgs ? a : null;
    final api = ref.read(deskApiProvider);
    if (DeskFeatures.tor) {
      unawaited(
        api.torAddress().then(
          (v) => mounted ? setState(() => _tor = v.isEmpty ? v : parseAddress(v, api).canonical) : null,
          onError: (Object _) => null,
        ),
      );
    }
    final args = _args;
    if (args != null) {
      final n = ref.read(deskProvider.notifier);
      // The container, not ref: the screen can be gone before these awaits finish.
      final c = ProviderScope.containerOf(context, listen: false);
      Future.microtask(() async {
        await n.setEpicboxListening(args.epicbox != RxEpicbox.off);
        await n.setHttp(args.http != RxHttp.off);
        if (DeskFeatures.tor && args.tor != RxTor.off) {
          // The Tor address shows while Link · Tor is on (Settings › Transactions) and Tor runs.
          final s = c.read(deskProvider).settings;
          if (!s.payments.linkTor) await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: true)));
        }
        if (DeskFeatures.tor) await n.setTor(args.tor != RxTor.off);
      });
    }
  }

  /// The real status with the tour's starting and failed states laid over it.
  ServiceStatus? _status(ServiceStatus? s) {
    final a = _args;
    if (s == null || a == null) return s;
    final blocked = a.epicbox == RxEpicbox.blocked;
    final epicbox = a.epicbox == RxEpicbox.down || blocked ? ServiceHealth.down : s.epicboxHealth;
    final http = switch (a.http) {
      RxHttp.starting => ServiceHealth.checking,
      RxHttp.failed => ServiceHealth.down,
      _ => s.httpListener,
    };
    final tor = switch (a.tor) {
      RxTor.connecting => ServiceHealth.checking,
      RxTor.failed => ServiceHealth.down,
      _ => s.tor,
    };
    return ServiceStatus(
      node: s.node,
      nodeHealth: s.nodeHealth,
      nodeHeight: s.nodeHeight,
      epicbox: s.epicbox,
      epicboxHealth: epicbox,
      epicboxBlocked: blocked || s.epicboxBlocked,
      epicboxInstead: blocked ? EpicboxRelay(host: hostSettings.epicboxServers.last.host) : s.epicboxInstead, // l10n-ok: tour demo relay
      httpListener: http,
      tor: tor,
      httpProblem: a.http == RxHttp.failed ? HttpProblem.portInUse : s.httpProblem,
      httpProblemPort: a.http == RxHttp.failed ? appConfig.httpListenPort : s.httpProblemPort,
      torProgress: a.tor == RxTor.connecting ? 45 : s.torProgress,
      torProblem: a.tor == RxTor.failed ? 'Tor could not connect to the network.' : s.torProblem, // l10n-ok: tour demo state
      torCanSend: a.tor == RxTor.connecting ? false : s.torCanSend,
      torIncluded: s.torIncluded,
      syncProgress: s.syncProgress,
      lastUpdate: s.lastUpdate,
      notice: s.notice,
    );
  }

  /// The HTTP address follows the listener: read again whenever it runs.
  Future<void> _readHttp() async {
    final a = await ref.read(deskApiProvider).httpAddress();
    if (mounted && a != _http) setState(() => _http = a);
  }

  Future<void> _toggle(TxMethod m, bool on) async {
    // Offline and Tor only without Tor: no listener starts (Epicbox, HTTP, Tor itself).
    if (on && ref.read(m == TxMethod.http ? deskNodeBlockProvider : deskNetBlockProvider) != NetBlock.none) return;
    setState(() => _busy.add(m));
    final n = ref.read(deskProvider.notifier);
    try {
      switch (m) {
        case TxMethod.epicbox:
          await n.setEpicboxListening(on);
        case TxMethod.http:
          await n.setHttp(on);
        case TxMethod.tor:
          // Tor for payments alone (Link · Tor, item 2): Retry starts that tor again and leaves
          // the Tor switch of Network & privacy as it is.
          final s = ref.read(deskProvider).settings;
          if (on && !s.tor && torPayWantedIn(s)) {
            await n.retryTorPay();
          } else {
            await n.setTor(on);
          }
        case TxMethod.file:
          break;
      }
    } on Object catch (e) {
      if (mounted) showEToast(context, on ? context.l10n.deskRecvTurnOnFailed(_name(context.l10n, m)) : context.l10n.deskRecvTurnOffFailed(_name(context.l10n, m)), text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy.remove(m));
    }
  }

  static String _name(AppLocalizations l, TxMethod m) => methodLabel(l, m);

  /// Direct receiving is the clearnet HTTP listener with Tor off and the Tor address with Tor
  /// on (tor_routes.dart: the listener stops while Tor is on).
  /// The methods the indicator shows: Epicbox while its switch is on (Settings › Transactions),
  /// Link · Tor while its switch is on and Tor runs, else Link · HTTP while its switch is on,
  /// then Tor or HTTP.
  List<TxMethod> _methodsFor(DeskSettings s) => [
    if (s.payments.epicbox) TxMethod.epicbox,
    if (DeskFeatures.tor && s.payments.linkTor && s.tor) TxMethod.tor else if (s.payments.linkHttp) TxMethod.http,
  ];

  bool _switchOn(TxMethod m, ServiceStatus? s, DeskSettings settings) => switch (m) {
    TxMethod.epicbox => s != null && s.epicboxHealth != ServiceHealth.off,
    TxMethod.http => s != null && s.httpListener != ServiceHealth.off,
    TxMethod.tor => settings.tor || torPayWantedIn(settings),
    TxMethod.file => false,
  };

  /// The reach check said the internet does not reach Link · HTTP's port.
  bool get _reachClosed => ref.watch(deskLastHttpReachProvider)?.reachable == false;

  void _jump(TxMethod m) {
    final at = _panels[m]?.currentContext;
    if (at != null) Scrollable.ensureVisible(at, duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base, alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final status = _status(st.status);
    if (status?.httpListener == ServiceHealth.ok) unawaited(_readHttp());
    final nav = ref.read(deskNavProvider.notifier);
    final l = context.l10n;
    // Wallet levels: Shallow has the address card alone (no host, no switch, no files, no Link
    // tabs); Deeper adds the host, the switch and the payment files; Deep end is the full page.
    final feat = ref.watch(deskLevelFeaturesProvider);
    final ui = ref.watch(deskLevelUiProvider);
    final shallow = ui.shallow;
    final moved = shallow ? ref.watch(deskRelayMovedProvider) : null;
    // The Epicbox switch off (Settings › Transactions): no address to hand out; a notice says
    // where it is turned on and that senders' payments wait at the relay meanwhile.
    final epicbox = TourTarget(
      id: 'receive-epicbox',
      child: st.settings.payments.epicbox ? (shallow ? _shallowPanel(st, status, moved) : _epicboxPanel(st, status)) : _epicboxOffNotice(nav),
    );
    // Settings › Payments: Link · Tor's panel while its switch is on: it starts tor for payments
    // by itself (item 2), or the Tor switch runs it; Link · HTTP's while the Tor switch is off
    // (it stops the clearnet listener), or while its listener still runs. Off, Link · HTTP's
    // panel is one line with its switch, so it is turned on again here.
    final p = st.settings.payments;
    final torPanel = feat.linkPayments && DeskFeatures.tor && p.linkTor && (st.settings.tor || torPayWantedIn(st.settings));
    final httpPanel = feat.linkPayments && (!st.settings.tor || status?.httpListener == ServiceHealth.ok);
    final others = [
      if (torPanel) _torPanel(st, status),
      if (httpPanel) _httpPanel(st, status),
    ];
    final tor = netTorState(st.settings, status);
    // The tor behind the Tor address, whoever started it.
    final torRx = torProcessState(st.settings, status);
    final net = deskNetBlock(st);
    // Settings › Transactions › File; a file send waiting for its response keeps the panel (Finalize).
    final files = feat.fileTransfer && (st.settings.payments.directFile || st.pendingFiles > 0)
        ? TourTarget(id: 'receive-files', child: _filesPanel(nav, offlineNode: deskOfflineUsesNode(st), casual: ui.casualWords))
        : null;
    final arriving = shallow || ui.casualWords ? _arriving(st) : null;
    final head = ESectionHead(
      l.deskRecvOtherWays,
      top: 0,
      trailing: EButton.ghost(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
    );
    List<Widget> gap(List<Widget> xs) => [
      for (var i = 0; i < xs.length; i++) ...[if (i > 0) SizedBox(height: Sp.x3), xs[i]],
    ];
    return EPage(
      title: l.deskRecvTitle,
      // How receiving connects while the Tor switch is on (tor_routes.dart). Nothing with it
      // off: the switch names only what goes over Tor.
      titleTrailing: !shallow && DeskFeatures.tor && torWay(TorRoute.epicbox, tor) != TorWay.clearnet
          ? TorChip(torWay(TorRoute.epicbox, tor), quiet: _torBanner(st, status))
          : null,
      width: EPageWidth.full,
      actions: [if (!shallow) _indicator(st, status)],
      child: ConstrainedBox(
        // Wide enough at large windows for the QR beside the Epicbox address and room for
        // Other ways (UI-063).
        constraints: BoxConstraints(maxWidth: 1600.u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (net != NetBlock.none) ...[_netNotice(net), SizedBox(height: Sp.x4)]
            else if (torPanel && (torRx == TorState.starting || torRx == TorState.failed) && (torRx == TorState.starting || !ref.watch(connectionGraceProvider))) ...[_torNotice(torRx), SizedBox(height: Sp.x4)],
            if (arriving != null) ...[_arrivalCard(arriving, nav), SizedBox(height: Sp.x4)],
            LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= Lay.wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gap([epicbox, ?files])),
                  ),
                  if (others.isNotEmpty) ...[
                    SizedBox(width: Sp.x6),
                    Expanded(
                      flex: 5,
                      child: TourTarget(
                        id: 'receive-others',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, ...gap(others)]),
                      ),
                    ),
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                epicbox,
                if (others.isNotEmpty) ...[
                  SizedBox(height: Sp.x8),
                  TourTarget(
                    id: 'receive-others',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, ...gap(others)]),
                  ),
                ],
                if (files != null) ...[SizedBox(height: Sp.x3), files],
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }

  /// Epicbox off in Settings › Transactions: in the address panel's place.
  Widget _epicboxOffNotice(DeskNav nav) {
    final l = context.l10n;
    return ENotice(
      key: const ValueKey('rx-epicbox-off'),
      icon: EIcons.epicbox,
      title: l.netBlockEpicboxOff,
      text: l.receiveEpicboxOffText,
      actions: [EButton(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving))],
    );
  }

  /// The network mode holds receiving: the address stays to hand out, the file panel works.
  Widget _netNotice(NetBlock net) {
    final l = context.l10n;
    final offline = net.byMode;
    final modeName = networkModeName(l, deskNetMode(ref.read(deskProvider)));
    return ENotice(
      key: const ValueKey('rx-net-blocked'),
      // Waiting for Tor is in progress (blue ⓘ); Node only and Kill switch are the user's choice (calm).
      tone: offline ? ETone.neutral : ETone.info,
      icon: offline ? EIcons.lanOff : null,
      title: offline ? l.receiveEpicboxOffMode(modeName) : netBlockReason(l, net)!,
      text: offline ? l.receiveEpicboxOffModeBody(modeName) : l.deskNetRecvWaitTorText,
      actions: [EButton(label: l.netChangeLink, size: EBtnSize.inline, onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network))],
    );
  }

  /// Whether the page's banner says Tor is not connected ([_torNotice]): then it is the one
  /// place that explains it and offers Retry; the Tor line keeps only its state, the chip its
  /// neutral look (D-04).
  bool _torBanner(DeskState st, ServiceStatus? status) {
    final p = st.settings.payments;
    final torPanel = ref.read(deskLevelFeaturesProvider).linkPayments && DeskFeatures.tor && p.linkTor && (st.settings.tor || torPayWantedIn(st.settings));
    return torPanel && deskNetBlock(st) == NetBlock.none && torProcessState(st.settings, status) == TorState.failed;
  }

  /// Tor starting or not connected: what it holds up, and Retry or Settings when it failed.
  Widget _torNotice(TorState tor) {
    final failed = tor == TorState.failed;
    final busy = _busy.contains(TxMethod.tor);
    final l = context.l10n;
    return ENotice(
      key: const ValueKey('rx-tor-notice'),
      tone: failed ? ETone.risk : ETone.info,
      title: failed ? l.deskRecvTorNotConnected : l.deskRecvTorStarting,
      text: failed ? l.deskRecvTorDownText : l.deskRecvTorStartingText,
      actions: [
        if (failed) ...[
          // Retry only (D-05): turning Tor off is never the fix an error offers.
          EButton(label: l.commonRetry, icon: EIcons.refresh, size: EBtnSize.inline, busy: busy, onPressed: busy ? null : () => _toggle(TxMethod.tor, true)),
        ],
      ],
    );
  }

  /// "Receiving" and one icon per method in its state colour; a click scrolls to its panel.
  Widget _indicator(DeskState st, ServiceStatus? status) {
    final l = context.l10n;
    final methods = _methodsFor(st.settings);
    final offline = deskNetBlock(st).byMode;
    final lines = {
      for (final m in methods)
        m: status == null
            ? null
            : offline
            ? MethodLine(statusOffByModeWord(l, deskNetMode(st)), EState.off)
            : methodStateLine(l, m, status, st.settings, reachClosed: _reachClosed),
    };
    // The line's own word (state_language.dart), spoken: "connected", "receiving", "off".
    String word(TxMethod m) => lines[m]?.word.toLowerCase() ?? l.deskRecvStateChecking;
    final receiving = lines.values.any((m) => m != null && m.state != EState.off);
    // The glyphs alone; "Receiving" stays on the card switch and in this tooltip (UD-015). With
    // every method off the header shows nothing, as it would claim receiving.
    if (!receiving) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      label: [for (final m in methods) l.deskRecvSemList(_name(l, m), word(m))].join(', '),
      child: ETip(
        l.deskRecvHeaderTip(metaLine([for (final m in methods) if (lines[m] != null && lines[m]!.state != EState.off) _name(l, m)])),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in methods) ...[
            SizedBox(width: Sp.x2),
            ETip(
              lines[m] == null
                  ? l.deskRecvTipChecking(_name(l, m))
                  : lines[m]!.detail == null
                  ? l.deskRecvTip(_name(l, m), lines[m]!.word)
                  : l.deskRecvTipDetail(_name(l, m), lines[m]!.word, lines[m]!.detail!),
              child: Semantics(
                button: true,
                label: l.deskRecvSemMethod(_name(l, m), word(m)),
                excludeSemantics: true,
                onTap: () => _jump(m),
                child: EInkWell(
                  borderRadius: BorderRadius.circular(Rad.sm),
                  onTap: () => _jump(m),
                  child: Padding(
                    padding: EdgeInsets.all(2.u),
                    child: EMethodIcon(m, lines[m]?.state ?? EState.off, size: 20.u),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget? _retry(TxMethod m, MethodLine line) {
    if (!line.retry) return null;
    final busy = _busy.contains(m);
    return EButton(
      label: m == TxMethod.http ? context.l10n.deskRecvTryAgain : context.l10n.commonRetry,
      icon: EIcons.refresh,
      size: EBtnSize.sm,
      busy: busy,
      onPressed: busy ? null : () => _toggle(m, true),
    );
  }

  Widget _epicboxPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.epicbox;
    final ts = context.ts;
    final l = context.l10n;
    final addr = st.epicboxAddress;
    final on = _switchOn(m, status, st.settings);
    final net = deskNetBlock(st);
    final line = status == null
        ? null
        : net.byMode
        ? MethodLine(statusOffByModeWord(l, deskNetMode(st)), EState.off, detail: l.statusOffByModeDetailNet)
        : methodStateLine(context.l10n, m, status, st.settings);
    final health = net.byMode ? null : status?.epicboxHealth;
    final tag = !on
        ? l.deskRecvTagPaused
        : health == ServiceHealth.checking
        ? l.deskRecvTagStarting
        : null;
    // The Epicbox list of the settings file is empty: no server, so no address and no line.
    final noServer = ref.read(hostSettingsProvider).epicboxServers.isEmpty;
    final Widget addressBox = noServer
        ? ENotice(
            key: const ValueKey('rx-no-epicbox'),
            title: l.deskSlNoEpicboxTitle,
            text: l.deskSlNoEpicboxText,
            tone: ETone.warn,
            icon: EIcons.epicbox,
            actions: [EButton(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving))],
          )
        : addr == null
        ? Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: ESpinner(size: 20.u))
        : addr.isEmpty
        ? Text(l.deskRecvAddressUnreadable, style: ts.small)
        : Opacity(
            opacity: on ? 1 : 0.6,
            child: EAddress(addr, large: true, copyLabel: l.deskRecvCopyEpicbox),
          );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.deskRecvEpicboxIntro, style: ts.bodyDim),
        SizedBox(height: Sp.x4),
        addressBox,
        if (!noServer) ...[
          SizedBox(height: Sp.x2),
          Text(l.deskRecvCheckSix, style: ts.caption),
          SizedBox(height: Sp.x4),
          if (line == null) const Align(alignment: Alignment.centerLeft, child: ESpinner()) else EStateLine(line, key: const ValueKey('rx-state-epicbox')),
          if (health == ServiceHealth.down) ...[SizedBox(height: Sp.x3), EpicboxDownNotice(sentence: false, status: status)],
        ],
        // Invoices: ask a paired contact to pay.
        if (ref.watch(deskInvoicesShownProvider) && ref.watch(deskPairsProvider)) ...[
          SizedBox(height: Sp.x5),
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InvButton(
                label: context.l10n.deskInvIssueAction,
                icon: EIcons.request,
                width: InvW.lg,
                onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoiceIssue),
              ),
              Text(context.l10n.deskInvSetReceiveHint, style: ts.small),
            ],
          ),
        ],
      ],
    );
    final qr = addr == null || addr.isEmpty
        ? SizedBox(width: 184.u, height: 184.u)
        : EQrReveal(
            address: addr,
            form: QrRevealForm.covered,
            title: l.deskRecvEpicboxAddress,
            tag: tag,
            method: 'epicbox',
            // Shown from the start: no blur, no Show QR (item 17).
            fixed: true,
          );
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: l.deskRecvEpicboxAddress,
      state: line?.state ?? EState.off,
      switchOn: on,
      busy: _busy.contains(m) || status == null,
      onSwitch: status == null || net != NetBlock.none ? null : (v) => _toggle(m, v),
      grown: true,
      small: const SizedBox.shrink(),
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth < Lay.lg
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, SizedBox(height: Sp.x5), Align(alignment: Alignment.centerLeft, child: qr)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), SizedBox(width: Sp.x6), qr]),
      ),
    );
  }

  /// The newest payment coming in (a receive not yet confirmed), or null. A request this wallet
  /// issued that nobody paid yet is not arriving.
  Tx? _arriving(DeskState st) {
    Tx? best;
    for (final t in st.txs ?? const <Tx>[]) {
      if (t.direction != TxDirection.received || t.coinbase || t.otherWallet) continue;
      if (t.state == TxState.confirmed || t.state == TxState.cancelled) continue;
      if (t.flow == TxFlow.invoice && t.state == TxState.waitingRecipient) continue;
      if (best == null || t.created.isAfter(best.created)) best = t;
    }
    return best;
  }

  /// "+12.5000 from Bob" and the receiving steps while a payment comes in.
  Widget _arrivalCard(Tx tx, DeskNav nav) {
    final l = context.l10n;
    final ts = context.ts;
    final name = tx.contactName;
    final amount = formatEpicL(l, tx.amount);
    return EPanel(
      key: const ValueKey('rx-arrival'),
      padding: EdgeInsets.all(Sp.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(name == null ? l.lvShellQuietArriving(amount) : l.lvPayArrivalFrom('+$amount', name), style: ts.strong),
                ),
              ),
              EButton.ghost(label: l.lvPayOpen, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.activity, tx.id)),
            ],
          ),
          SizedBox(height: Sp.x3),
          DeskPaymentSteps(tx: tx, dense: true),
        ],
      ),
    );
  }

  /// Shallow's address card: "Your address" without the Epicbox server, Copy, Show QR (covered
  /// as on the other levels) and "Ready to receive". After a move to another server: "Your new
  /// address", the server once, and the old address folded away.
  Widget _shallowPanel(DeskState st, ServiceStatus? status, RelaySwitchResult? moved) {
    final ts = context.ts;
    final l = context.l10n;
    final c = context.dc;
    final addr = (moved?.address ?? st.epicboxAddress);
    final net = deskNetBlock(st);
    final noServer = ref.read(hostSettingsProvider).epicboxServers.isEmpty;
    final health = net.byMode ? null : status?.epicboxHealth;
    final ready = !net.byMode && health == ServiceHealth.ok;
    final line = status == null
        ? null
        : net.byMode
        ? MethodLine(statusOffByModeWord(l, deskNetMode(st)), EState.off, detail: l.statusOffByModeDetailNet)
        : ready
        ? MethodLine(l.deskLvSendReady, EState.ok)
        : methodStateLine(l, TxMethod.epicbox, status, st.settings);
    final Widget addressBox = noServer
        ? ENotice(
            key: const ValueKey('rx-no-epicbox'),
            title: l.deskSlNoEpicboxTitle,
            text: l.deskSlNoEpicboxText,
            tone: ETone.warn,
            icon: EIcons.epicbox,
            actions: [EButton(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving))],
          )
        : addr == null
        ? Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: ESpinner(size: 20.u))
        : addr.isEmpty
        ? Text(l.deskRecvAddressUnreadable, style: ts.small)
        : EAddress(addr, large: true, copyLabel: l.deskRecvCopyEpicbox);
    final info = Column(
      key: const ValueKey('rx-shallow-address'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(child: Semantics(header: true, child: Text(moved != null ? l.lvPayNewAddress : l.deskLvSendYourAddress, style: ts.h3))),
            if (moved != null) ...[SizedBox(width: Sp.x2), EBadge(l.lvPayNewToday, tone: BadgeTone.info)],
          ],
        ),
        SizedBox(height: Sp.x2),
        if (moved != null) ...[
          Text(l.lvPayServerLine(moved.name), key: const ValueKey('rx-server-line'), style: ts.bodyDim),
          Text(l.lvPayOldAddressLine, style: ts.bodyDim),
        ] else
          Row(
            children: [
              Flexible(child: Text(l.deskRecvEpicboxIntro, style: ts.bodyDim)),
              SizedBox(width: Sp.x1),
              EInfoHint(l.deskLvSendClosedInfo, title: l.deskLvSendYourAddress, size: Ctl.inline),
            ],
          ),
        SizedBox(height: Sp.x4),
        addressBox,
        if (!noServer) ...[
          SizedBox(height: Sp.x2),
          Text(l.deskRecvCheckSix, style: ts.caption),
          SizedBox(height: Sp.x4),
          if (line == null) const Align(alignment: Alignment.centerLeft, child: ESpinner()) else EStateLine(line, key: const ValueKey('rx-state-epicbox')),
          if (moved != null) ...[
            SizedBox(height: Sp.x3),
            EDetails(
              key: const ValueKey('rx-previous-address'),
              title: l.deskLvSendPrevAddress,
              child: Padding(
                padding: EdgeInsets.only(top: Sp.x1),
                child: Text(l.deskLvSendPrevText(moved.from.label), style: ts.small.copyWith(color: c.dim)),
              ),
            ),
          ],
        ],
      ],
    );
    final qr = addr == null || addr.isEmpty || noServer
        ? SizedBox(width: 184.u, height: 184.u)
        : EQrReveal(
            address: addr,
            form: QrRevealForm.covered,
            title: l.deskLvSendYourAddress,
            method: 'epicbox',
            // Shown from the start: no blur, no Show QR (item 17).
            fixed: true,
          );
    return EPanel(
      key: ValueKey('rx-panel-${TxMethod.epicbox.name}'),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < Lay.lg
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, SizedBox(height: Sp.x5), Align(alignment: Alignment.centerLeft, child: qr)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), SizedBox(width: Sp.x6), qr]),
      ),
    );
  }

  Widget _httpPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.http;
    final ts = context.ts;
    final l = context.l10n;
    final on = _switchOn(m, status, st.settings);
    final line = status == null ? null : methodStateLine(context.l10n, m, status, st.settings, reachClosed: _reachClosed);
    final ok = status?.httpListener == ServiceHealth.ok;
    final failed = status?.httpListener == ServiceHealth.down;
    final addr = on && _http != null && _http!.isNotEmpty ? _http : null;
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: l.deskRecvHttpAddress,
      state: line?.state ?? EState.off,
      switchOn: on,
      busy: _busy.contains(m) || status == null,
      // On, the switches are the two addresses' (HttpAddresses): this computer and the
      // internet. Off, the panel's own switch turns it on again.
      onSwitch: status == null ? null : (v) => unawaited(_toggle(m, v)),
      showSwitch: !on,
      grown: on,
      small: line == null ? const SizedBox.shrink() : EStateLine(line, key: const ValueKey('rx-state-http')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HttpAddresses(
            local: addr,
            localBusy: _busy.contains(m) || status == null,
            onLocal: (v) => unawaited(_toggle(m, v)),
            view: (context, address, title) => EQrReveal(
              address: address,
              form: QrRevealForm.compact,
              title: title,
              copyLabel: l.deskRecvCopyHttp,
              addressOpacity: ok ? 1 : 0.6,
              tag: failed ? l.deskRecvTagNotReachable : (ok ? null : l.deskRecvTagStarting),
              method: 'http',
              initiallyShown: _args?.qr == RxQr.http,
            ),
          ),
          SizedBox(height: Sp.x4),
          if (line != null) EStateLine(line, key: const ValueKey('rx-state-http'), trailing: _retry(m, line)),
          if (DeskFeatures.tor) ...[
            SizedBox(height: Sp.x3),
            Text(l.deskRecvHttpTorHintNet, style: ts.caption),
          ],
        ],
      ),
    );
  }

  Widget _torPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.tor;
    final ts = context.ts;
    final l = context.l10n;
    final on = _switchOn(m, status, st.settings);
    final full = status == null ? null : methodStateLine(context.l10n, m, status, st.settings);
    // The banner says why and offers Retry: the line keeps its state's dot and word.
    final line = full != null && _torBanner(st, status) ? MethodLine(full.word, full.state) : full;
    final ready = status?.tor == ServiceHealth.ok;
    final failed = status?.tor == ServiceHealth.down || status?.tor == ServiceHealth.slow;
    final addr = _tor;
    final included = status?.torIncluded ?? true;
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: l.deskRecvDirectTor,
      state: line?.state ?? EState.off,
      switchOn: on && included,
      busy: _busy.contains(m) || status == null,
      onSwitch: null,
      showSwitch: false,
      grown: on && included,
      small: line == null ? const SizedBox.shrink() : EStateLine(line, key: const ValueKey('rx-state-tor')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskRecvTorIntroNet, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          if (addr == null)
            Align(alignment: Alignment.centerLeft, child: ESpinner(size: 20.u))
          else if (addr.isEmpty)
            Text(l.deskRecvAddressUnreadable, style: ts.small)
          else
            EQrReveal(
              address: addr,
              form: QrRevealForm.compact,
              title: l.deskRecvTorAddress,
              copyLabel: l.deskRecvCopyTor,
              addressOpacity: ready ? 1 : 0.6,
              tag: failed ? l.deskRecvTagNotReachable : (ready ? null : l.deskRecvTagStarting),
              caption: Text(l.deskRecvTorOnion, style: ts.caption),
              method: 'tor',
            ),
          SizedBox(height: Sp.x4),
          if (line != null) EStateLine(line, key: const ValueKey('rx-state-tor'), trailing: _retry(m, line)),
        ],
      ),
    );
  }

  /// [offlineNode]: Offline on a node that is not local; the files still run, through it.
  Widget _filesPanel(DeskNav nav, {required bool offlineNode, bool casual = false}) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return EPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.panel, Sp.panel, Sp.panel, Sp.x2),
            child: Row(
              children: [
                Icon(EIcons.file, size: 20.u, color: c.dim),
                SizedBox(width: 10.u),
                Semantics(header: true, child: Text(casual ? l.deskLvSendPayFiles : l.deskRecvFiles, style: ts.h3)),
              ],
            ),
          ),
          ESetRow(
            title: casual ? l.deskLvSendSignFile : l.deskRecvSignTitle,
            text: casual ? l.deskLvSendSignFileText : l.deskRecvSignText,
            control: EButton(label: l.deskRecvOpen, icon: EIcons.fileUp, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.importTx)),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          ESetRow(
            title: casual ? l.deskLvSendFinishFile : l.deskRecvFinalizeTitle,
            text: casual ? l.deskLvSendFinishFileText : l.deskRecvFinalizeText,
            control: EButton(label: l.deskRecvOpen, icon: EIcons.fileUp, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.finalize)),
          ),
          if (!casual) ...[
          Divider(height: 1, thickness: 1, color: c.line),
          ESetRow(
            key: const ValueKey('rx-post-finished'),
            title: l.postFinishedDeskRow,
            text: NetGate.killSwitch ? l.postFinishedOffKill : l.postFinishedIntroOffline,
            control: EButton(
              key: const ValueKey('rx-post-finished-open'),
              label: l.postFinishedOpen,
              icon: EIcons.fileUp,
              size: EBtnSize.sm,
              onPressed: NetGate.killSwitch ? null : () => showPostFinished(context),
            ),
          ),
          ],
          if (offlineNode) ...[
            Divider(height: 1, thickness: 1, color: c.line),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.panel, Sp.x3, Sp.panel, Sp.x4),
              child: Row(
                key: const ValueKey('rx-files-offline-node'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(EIcons.info, size: 16.u, color: c.info),
                  SizedBox(width: 8.u),
                  Expanded(child: Text(l.netOfflineNodeHint, style: ts.small)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One receiving method: the title row with its switch, then the state line alone
/// ([small]) or the whole [body] when [grown]; the change runs through [ExpandFade].
class _MethodPanel extends StatelessWidget {
  const _MethodPanel({
    super.key,
    required this.method,
    required this.title,
    required this.state,
    required this.switchOn,
    required this.busy,
    required this.onSwitch,
    required this.grown,
    required this.small,
    required this.body,
    this.showSwitch = true,
  });

  /// False for Direct over Tor: the one Tor switch is in Settings › Privacy.
  final bool showSwitch;

  final TxMethod method;
  final String title;
  final EState state;
  final bool switchOn;
  final bool busy;
  final ValueChanged<bool>? onSwitch;
  final bool grown;
  final Widget small;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return EPanel(
      key: ValueKey('rx-panel-${method.name}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.panel, Sp.panel, Sp.panel, 0),
            child: Row(
              children: [
                EMethodIcon(method, state, size: 20.u),
                SizedBox(width: 10.u),
                Expanded(
                  child: Semantics(header: true, child: Text(title, style: ts.h3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ),
                if (showSwitch) ...[
                ExcludeSemantics(child: Text(context.l10n.deskRecvReceiving, style: ts.body)),
                SizedBox(width: Sp.x3),
                SizedBox(
                  width: 40.u,
                  height: 24.u,
                  child: busy
                      ? Center(child: ESpinner(size: 18.u))
                      : ESwitch(
                          key: ValueKey('rx-switch-${method.name}'),
                          value: switchOn,
                          onChanged: onSwitch,
                          semanticLabel: context.l10n.deskRecvSwitchLabel(title),
                        ),
                ),
                ],
              ],
            ),
          ),
          if (method != TxMethod.epicbox)
            ExpandFade(
              open: !grown,
              child: Padding(padding: EdgeInsets.fromLTRB(Sp.panel, 6.u, Sp.panel, Sp.x4), child: small),
            ),
          ExpandFade(
            open: grown,
            child: Padding(padding: EdgeInsets.fromLTRB(Sp.panel, Sp.x3, Sp.panel, Sp.panel), child: body),
          ),
        ],
      ),
    );
  }
}
