import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
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
      httpProblem: a.http == RxHttp.failed ? 'Port 3415 in use' : s.httpProblem,
      torProgress: a.tor == RxTor.connecting ? 45 : s.torProgress,
      torProblem: a.tor == RxTor.failed ? 'Tor could not connect to the network.' : s.torProblem,
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

  List<TxMethod> get _methods => [TxMethod.epicbox, if (DeskFeatures.httpDirect) TxMethod.http, if (DeskFeatures.tor) TxMethod.tor];

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
    final epicbox = _epicboxPanel(st, status);
    final others = [
      if (DeskFeatures.httpDirect) _httpPanel(st, status),
      if (DeskFeatures.tor) _torPanel(st, status),
    ];
    final files = _filesPanel(nav);
    final head = ESectionHead(
      'Other ways to receive',
      top: 0,
      trailing: EButton.ghost(label: 'Settings', icon: EIcons.settings, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
    );
    List<Widget> gap(List<Widget> xs) => [
      for (var i = 0; i < xs.length; i++) ...[if (i > 0) SizedBox(height: Sp.x3), xs[i]],
    ];
    return EPage(
      title: 'Receive',
      width: EPageWidth.full,
      actions: [_indicator(st, status)],
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1180.u),
        child: LayoutBuilder(
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, ...gap(others)]),
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
                  head,
                  ...gap(others),
                ],
                SizedBox(height: Sp.x3),
                files,
              ],
            );
          },
        ),
      ),
    );
  }

  /// "Receiving" and one icon per method in its state colour; a click scrolls to its panel.
  Widget _indicator(DeskState st, ServiceStatus? status) {
    final ts = context.ts;
    final c = context.dc;
    final lines = {for (final m in _methods) m: status == null ? null : methodStateLine(m, status, st.settings)};
    String word(TxMethod m) => lines[m] == null ? 'checking' : (lines[m]!.state == EState.off ? 'off' : (lines[m]!.word == 'On' ? 'on' : lines[m]!.word.toLowerCase()));
    return Semantics(
      liveRegion: true,
      label: [for (final m in _methods) '${_name(m)} ${word(m)}'].join(', '),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Text('Receiving', style: ts.small.copyWith(color: c.dim))),
          for (final m in _methods) ...[
            SizedBox(width: Sp.x2),
            Tooltip(
              message: lines[m] == null ? '${_name(m)} · Checking' : '${_name(m)} · ${lines[m]!.word}${lines[m]!.detail == null ? '' : '\n${lines[m]!.detail}'}',
              child: Semantics(
                button: true,
                label: '${_name(m)}: ${word(m)}',
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
      label: m == TxMethod.http ? 'Try again' : 'Retry',
      icon: EIcons.refresh,
      size: EBtnSize.sm,
      busy: busy,
      onPressed: busy ? null : () => _toggle(m, true),
    );
  }

  Widget _epicboxPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.epicbox;
    final ts = context.ts;
    final addr = st.epicboxAddress;
    final on = _switchOn(m, status, st.settings);
    final line = status == null ? null : methodStateLine(m, status, st.settings);
    final health = status?.epicboxHealth;
    final tag = !on
        ? 'Paused'
        : health == ServiceHealth.checking
        ? 'Starting'
        : null;
    final Widget addressBox = addr == null
        ? Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: ESpinner(size: 20.u))
        : addr.isEmpty
        ? Text('The address could not be read. Open Receive again in a moment.', style: ts.small)
        : Opacity(
            opacity: on ? 1 : 0.6,
            child: EAddress(addr, large: true, copyLabel: 'Copy Epicbox address'),
          );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Share it to get paid. Works while the wallet is closed: the Epicbox server holds payments until the wallet is back.', style: ts.bodyDim),
        SizedBox(height: Sp.x4),
        addressBox,
        SizedBox(height: Sp.x2),
        Text('When reading it out, check the first six and last six characters.', style: ts.caption),
        SizedBox(height: Sp.x4),
        if (line == null) const Align(alignment: Alignment.centerLeft, child: ESpinner()) else EStateLine(line, key: const ValueKey('rx-state-epicbox')),
        if (health == ServiceHealth.down) ...[SizedBox(height: Sp.x3), const EpicboxDownNotice()],
      ],
    );
    final qr = addr == null || addr.isEmpty
        ? SizedBox(width: 184.u, height: 184.u)
        : EQrReveal(
            address: addr,
            form: QrRevealForm.covered,
            title: 'Epicbox address',
            tag: tag,
            method: 'epicbox',
            initiallyShown: _args?.qr == RxQr.epicbox,
          );
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: 'Epicbox address',
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
    final on = _switchOn(m, status, st.settings);
    final line = status == null ? null : methodStateLine(m, status, st.settings);
    final ok = status?.httpListener == ServiceHealth.ok;
    final failed = status?.httpListener == ServiceHealth.down;
    final addr = _http != null && _http!.isNotEmpty ? _http : null;
    final caption = Text(
      st.settings.publicMode
          ? 'Senders on the internet use this address once the router forwards port ${st.settings.httpPort}.'
          : 'Programs on this computer can pay this address. For other devices, see Settings › Receiving.',
      style: ts.caption,
    );
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: 'HTTP address',
      state: line?.state ?? EState.off,
      switchOn: on,
      busy: _busy.contains(m) || status == null,
      onSwitch: status == null ? null : (v) => _toggle(m, v),
      grown: on,
      small: line == null ? const SizedBox.shrink() : EStateLine(line, key: const ValueKey('rx-state-http')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Straight from another wallet while this one is open. On this computer only unless Settings says otherwise.', style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          if (addr != null) ...[
            EQrReveal(
              address: addr,
              form: QrRevealForm.compact,
              title: 'HTTP address',
              copyLabel: 'Copy HTTP address',
              addressOpacity: ok ? 1 : 0.6,
              tag: failed ? 'Not reachable' : (ok ? null : 'Starting'),
              caption: caption,
              method: 'http',
              initiallyShown: _args?.qr == RxQr.http,
            ),
            SizedBox(height: Sp.x4),
          ],
          if (line != null) EStateLine(line, key: const ValueKey('rx-state-http'), trailing: _retry(m, line)),
        ],
      ),
    );
  }

  Widget _torPanel(DeskState st, ServiceStatus? status) {
    const m = TxMethod.tor;
    final ts = context.ts;
    final on = _switchOn(m, status, st.settings);
    final line = status == null ? null : methodStateLine(m, status, st.settings);
    final ready = status?.tor == ServiceHealth.ok;
    final failed = status?.tor == ServiceHealth.down || status?.tor == ServiceHealth.slow;
    final addr = _tor;
    final included = status?.torIncluded ?? true;
    return _MethodPanel(
      key: _panels[m],
      method: m,
      title: 'Tor address',
      state: line?.state ?? EState.off,
      switchOn: on && included,
      busy: _busy.contains(m) || status == null,
      onSwitch: status == null || !included ? null : (v) => _toggle(m, v),
      grown: on && included,
      small: line == null ? const SizedBox.shrink() : EStateLine(line, key: const ValueKey('rx-state-tor')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Slower and more private. Blocked or not allowed in some countries.', style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          if (addr == null)
            Align(alignment: Alignment.centerLeft, child: ESpinner(size: 20.u))
          else if (addr.isEmpty)
            Text('The address could not be read. Open Receive again in a moment.', style: ts.small)
          else
            EQrReveal(
              address: addr,
              form: QrRevealForm.compact,
              title: 'Tor address',
              copyLabel: 'Copy Tor address',
              addressOpacity: ready ? 1 : 0.6,
              tag: failed ? 'Not reachable' : (ready ? null : 'Starting'),
              caption: Text('Some wallets show the address without .onion; both are the same address.', style: ts.caption),
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
                Semantics(header: true, child: Text('Transaction files', style: ts.h3)),
              ],
            ),
          ),
          ESetRow(
            title: 'Sign a transaction file',
            text: 'A sender gave a transaction file. The wallet signs it and saves a response for them.',
            control: EButton(label: 'Open', icon: EIcons.fileDown, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.importTx)),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          ESetRow(
            title: 'Finalize a response file',
            text: 'A file send got a response back. Finalizing posts the payment.',
            control: EButton(label: 'Open', icon: EIcons.fileUp, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.finalize)),
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
  });

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
                ExcludeSemantics(child: Text('Receiving', style: ts.body)),
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
                          semanticLabel: '$title, receiving',
                        ),
                ),
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
