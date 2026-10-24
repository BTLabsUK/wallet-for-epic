import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/tor_view.dart';
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../widgets/http_reach.dart';
import '../../widgets/kit.dart';
import '../../widgets/tor_chip.dart';
import '../invoices/invoice_parts.dart' show InvButton, InvW;
import 'epicbox_notice.dart';

enum RxEpicbox { on, off, down }

enum RxHttp { off, on, starting, failed }

enum RxTor { off, on, connecting, failed }

enum RxQr { none, epicbox, http }

/// Argument of the Receive route, for the tour (spec 4.3): which method is on, starting or
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
      Future.microtask(() async {
        await n.setEpicboxListening(args.epicbox != RxEpicbox.off);
        if (DeskFeatures.httpDirect) await n.setHttp(args.http != RxHttp.off);
        if (DeskFeatures.tor) await n.setTor(args.tor != RxTor.off);
      });
    }
  }

  /// The real status with the tour's starting and failed states laid over it.
  ServiceStatus? _status(ServiceStatus? s) {
    final a = _args;
    if (s == null || a == null) return s;
    final epicbox = a.epicbox == RxEpicbox.down ? ServiceHealth.down : s.epicboxHealth;
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
      httpListener: http,
      tor: tor,
      httpProblem: a.http == RxHttp.failed ? HttpProblem.portInUse : s.httpProblem,
      httpProblemPort: a.http == RxHttp.failed ? 3415 : s.httpProblemPort,
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
      if (mounted) showEToast(context, on ? context.l10n.deskRecvTurnOnFailed(_name(context.l10n, m)) : context.l10n.deskRecvTurnOffFailed(_name(context.l10n, m)), text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy.remove(m));
    }
  }

  static String _name(AppLocalizations l, TxMethod m) => switch (m) {
    TxMethod.epicbox => 'Epicbox', // l10n-ok: product name
    TxMethod.http => 'HTTP', // l10n-ok: protocol name
    TxMethod.tor => 'Tor', // l10n-ok: product name
    TxMethod.file => l.deskRecvNameFile,
  };

  /// Direct receiving is the clearnet HTTP listener with Tor off and the Tor address with Tor
  /// on (tor_routes.dart: the listener stops while Tor is on).
  List<TxMethod> _methodsFor(DeskSettings s) => [
    TxMethod.epicbox,
    if (DeskFeatures.tor && s.tor) TxMethod.tor else if (DeskFeatures.httpDirect) TxMethod.http,
  ];

  bool _switchOn(TxMethod m, ServiceStatus? s, DeskSettings settings) => switch (m) {
    TxMethod.epicbox => s != null && s.epicboxHealth != ServiceHealth.off,
    TxMethod.http => s != null && s.httpListener != ServiceHealth.off,
    TxMethod.tor => settings.tor,
    TxMethod.file => false,
  };

  void _jump(TxMethod m) {
    final at = _panels[m]?.currentContext;
    if (at != null) Scrollable.ensureVisible(at, duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base, alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final status = _status(st.status);
    if (DeskFeatures.httpDirect && status?.httpListener == ServiceHealth.ok) unawaited(_readHttp());
    final nav = ref.read(deskNavProvider.notifier);
    final l = context.l10n;
    final epicbox = TourTarget(id: 'receive-epicbox', child: _epicboxPanel(st, status));
    final others = [
      if (DeskFeatures.tor && st.settings.tor) _torPanel(st, status) else if (DeskFeatures.httpDirect) _httpPanel(st, status),
    ];
    final tor = torStateOf(st.settings, status);
    final files = _filesPanel(nav);
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
      titleTrailing: DeskFeatures.tor && torWay(TorRoute.epicbox, tor) != TorWay.clearnet
          ? TorChip(torWay(TorRoute.epicbox, tor))
          : null,
      width: EPageWidth.full,
      actions: [_indicator(st, status)],
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1180.u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tor == TorState.starting || tor == TorState.failed) ...[_torNotice(tor), SizedBox(height: Sp.x4)],
            LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= 1040.u) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gap([epicbox, files])),
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
                SizedBox(height: Sp.x3),
                files,
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }

  /// Tor starting or not connected: what it holds up, and Retry or Turn Tor off when it failed.
  Widget _torNotice(TorState tor) {
    final failed = tor == TorState.failed;
    final busy = _busy.contains(TxMethod.tor);
    final l = context.l10n;
    return ENotice(
      key: const ValueKey('rx-tor-notice'),
      tone: failed ? ETone.risk : ETone.warn,
      title: failed ? l.deskRecvTorNotConnected : l.deskRecvTorStarting,
      text: failed ? l.deskRecvTorDownText(torWaitingText(l)) : l.deskRecvTorStartingText,
      actions: [
        if (failed) ...[
          EButton(label: l.commonRetry, icon: EIcons.refresh, size: EBtnSize.inline, busy: busy, onPressed: busy ? null : () => _toggle(TxMethod.tor, true)),
          EButton.ghost(label: l.deskRecvTurnTorOff, size: EBtnSize.inline, onPressed: busy ? null : () => _toggle(TxMethod.tor, false)),
        ],
      ],
    );
  }

  /// "Receiving" and one icon per method in its state colour; a click scrolls to its panel.
  Widget _indicator(DeskState st, ServiceStatus? status) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final methods = _methodsFor(st.settings);
    final lines = {for (final m in methods) m: status == null ? null : methodStateLine(l, m, status, st.settings)};
    String word(TxMethod m) => lines[m] == null ? l.deskRecvStateChecking : (lines[m]!.state == EState.off ? l.deskRecvStateOff : (lines[m]!.state == EState.ok ? l.deskRecvStateOn : lines[m]!.word.toLowerCase()));
    return Semantics(
      liveRegion: true,
      label: [for (final m in methods) l.deskRecvSemList(_name(l, m), word(m))].join(', '),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Text(l.deskRecvReceiving, style: ts.small.copyWith(color: c.dim))),
          for (final m in methods) ...[
            SizedBox(width: Sp.x2),
            Tooltip(
              message: lines[m] == null
                  ? l.deskRecvTipChecking(_name(l, m))
                  : lines[m]!.detail == null
                  ? l.deskRecvTip(_name(l, m), lines[m]!.word)
                  : l.deskRecvTipDetail(_name(l, m), lines[m]!.word, lines[m]!.detail!),
              child: Semantics(
                button: true,
                label: l.deskRecvSemMethod(_name(l, m), word(m)),
                excludeSemantics: true,
                onTap: () => _jump(m),
                child: InkWell(
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
    final line = status == null ? null : methodStateLine(context.l10n, m, status, st.settings);
    final health = status?.epicboxHealth;
    final tag = !on
        ? l.deskRecvTagPaused
        : health == ServiceHealth.checking
        ? l.deskRecvTagStarting
        : null;
    final Widget addressBox = addr == null
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
        SizedBox(height: Sp.x2),
        Text(l.deskRecvCheckSix, style: ts.caption),
        SizedBox(height: Sp.x4),
        if (line == null) const Align(alignment: Alignment.centerLeft, child: ESpinner()) else EStateLine(line, key: const ValueKey('rx-state-epicbox')),
        if (health == ServiceHealth.down) ...[SizedBox(height: Sp.x3), const EpicboxDownNotice()],
        // Invoices (docs/invoices/flow.md §1): ask someone to pay; the invoice address never shows here.
        if (ref.watch(deskApiProvider).supportsInvoices) ...[
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
            initiallyShown: _args?.qr == RxQr.epicbox,
          );
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: l.deskRecvEpicboxAddress,
      state: line?.state ?? EState.off,
      switchOn: on,
      busy: _busy.contains(m) || status == null,
      onSwitch: status == null ? null : (v) => _toggle(m, v),
      grown: true,
      small: const SizedBox.shrink(),
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 520.u
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, SizedBox(height: Sp.x5), Center(child: qr)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), SizedBox(width: Sp.x6), qr]),
      ),
    );
  }

  Widget _httpPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.http;
    final ts = context.ts;
    final l = context.l10n;
    final on = _switchOn(m, status, st.settings);
    final line = status == null ? null : methodStateLine(context.l10n, m, status, st.settings);
    final ok = status?.httpListener == ServiceHealth.ok;
    final failed = status?.httpListener == ServiceHealth.down;
    final addr = _http != null && _http!.isNotEmpty ? _http : null;
    final caption = Text(
      st.settings.publicMode
          ? l.deskRecvHttpPublic(st.settings.httpPort)
          : l.deskRecvHttpLocal,
      style: ts.caption,
    );
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: l.deskRecvHttpAddress,
      state: line?.state ?? EState.off,
      switchOn: on,
      busy: _busy.contains(m) || status == null,
      onSwitch: status == null ? null : (v) => _toggle(m, v),
      grown: on,
      small: line == null ? const SizedBox.shrink() : EStateLine(line, key: const ValueKey('rx-state-http')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskRecvHttpIntro, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          if (addr != null) ...[
            EQrReveal(
              address: addr,
              form: QrRevealForm.compact,
              title: l.deskRecvHttpAddress,
              copyLabel: l.deskRecvCopyHttp,
              addressOpacity: ok ? 1 : 0.6,
              tag: failed ? l.deskRecvTagNotReachable : (ok ? null : l.deskRecvTagStarting),
              caption: caption,
              method: 'http',
              initiallyShown: _args?.qr == RxQr.http,
            ),
            SizedBox(height: Sp.x4),
          ],
          if (ok && st.settings.publicMode) ...[
            HttpReachNotice(onChanged: (_) => unawaited(_readHttp())),
            SizedBox(height: Sp.x4),
          ],
          if (line != null) EStateLine(line, key: const ValueKey('rx-state-http'), trailing: _retry(m, line)),
          if (DeskFeatures.tor) ...[
            SizedBox(height: Sp.x3),
            Text(l.deskRecvHttpTorHint, style: ts.caption),
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
    final line = status == null ? null : methodStateLine(context.l10n, m, status, st.settings);
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
          Text(l.deskRecvTorIntro, style: ts.bodyDim),
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

  Widget _filesPanel(DeskNav nav) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return EPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x6, 20.u, Sp.x6, Sp.x2),
            child: Row(
              children: [
                Icon(EIcons.file, size: 20.u, color: c.dim),
                SizedBox(width: 10.u),
                Semantics(header: true, child: Text(l.deskRecvFiles, style: ts.h3)),
              ],
            ),
          ),
          ESetRow(
            title: l.deskRecvSignTitle,
            text: l.deskRecvSignText,
            control: EButton(label: l.deskRecvOpen, icon: EIcons.fileDown, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.importTx)),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          ESetRow(
            title: l.deskRecvFinalizeTitle,
            text: l.deskRecvFinalizeText,
            control: EButton(label: l.deskRecvOpen, icon: EIcons.fileUp, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.finalize)),
          ),
        ],
      ),
    );
  }
}

/// One receiving method (spec 4.2): the title row with its switch, then the state line alone
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
            padding: EdgeInsets.fromLTRB(Sp.x6, 20.u, Sp.x6, 0),
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
              child: Padding(padding: EdgeInsets.fromLTRB(Sp.x6, 6.u, Sp.x6, Sp.x4), child: small),
            ),
          ExpandFade(
            open: grown,
            child: Padding(padding: EdgeInsets.fromLTRB(Sp.x6, Sp.x3, Sp.x6, Sp.x6), child: body),
          ),
        ],
      ),
    );
  }
}
