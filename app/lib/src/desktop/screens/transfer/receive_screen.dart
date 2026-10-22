import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'epicbox_notice.dart';

/// Argument of the Receive route, for the tour: [stopped] opens with the listener stopped,
/// [httpFailed] with the HTTP listener failed on a busy port, [qrHttp] with the HTTP address's QR
/// code, [epicboxDown] with our relay not answering.
class ReceiveArgs {
  const ReceiveArgs({this.stopped = false, this.httpFailed = false, this.qrHttp = false, this.epicboxDown = false});

  final bool stopped;
  final bool httpFailed;
  final bool qrHttp;
  final bool epicboxDown;
}

enum _Qr { epic, http, tor }

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late final ReceiveArgs _args;
  String? _http;
  String? _tor;
  _Qr _qr = _Qr.epic;
  bool _listenBusy = false;
  bool _httpBusy = false;
  // The tour's "port in use" state; a real failure comes with the status.
  bool _httpFailed = false;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    _args = a is ReceiveArgs ? a : const ReceiveArgs();
    _httpFailed = _args.httpFailed;
    final api = ref.read(deskApiProvider);
    if (DeskFeatures.tor) unawaited(api.torAddress().then((v) => mounted ? setState(() => _tor = v) : null));
    final n = ref.read(deskProvider.notifier);
    if (_args.stopped) {
      Future.microtask(() => n.setListening(false));
    } else if (_args.httpFailed || _args.qrHttp || _args.epicboxDown) {
      // The HTTP row needs the listener running (an earlier tour shot may have stopped it).
      Future.microtask(() async {
        await n.setListening(true);
        if (_args.qrHttp) await n.setHttp(true);
      });
    }
    if (_args.qrHttp) _qr = _Qr.http;
  }

  bool _listening(ServiceStatus? s) => s != null && (s.epicboxHealth != ServiceHealth.off || s.httpListener != ServiceHealth.off);

  Future<void> _setListening(bool on) async {
    setState(() => _listenBusy = true);
    try {
      await ref.read(deskProvider.notifier).setListening(on);
      if (!mounted) return;
      if (!on) {
        _httpFailed = false;
        _qr = _Qr.epic;
      }
      showEToast(context, on ? 'Listener started' : 'Listener stopped');
    } finally {
      if (mounted) setState(() => _listenBusy = false);
    }
  }

  Future<void> _setHttp(bool on) async {
    setState(() => _httpBusy = true);
    try {
      await ref.read(deskProvider.notifier).setHttp(on);
      if (!mounted) return;
      setState(() {
        _httpFailed = false;
        if (!on && _qr == _Qr.http) _qr = _Qr.epic;
      });
    } finally {
      if (mounted) setState(() => _httpBusy = false);
    }
  }

  /// The HTTP address follows the listener: read again whenever it runs.
  Future<void> _readHttp() async {
    final a = await ref.read(deskApiProvider).httpAddress();
    if (mounted && a != _http) setState(() => _http = a);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showEToast(context, 'Copied');
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final c = context.dc;
    final status = st.status;
    final listening = _listening(status);
    if (DeskFeatures.httpDirect && status?.httpListener == ServiceHealth.ok) unawaited(_readHttp());
    return EPage(
      title: 'Receive',
      width: EPageWidth.mid,
      actions: [
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(listening ? EIcons.okCircle : EIcons.minusCircle, size: Ctl.iconSm, color: listening ? c.ok : c.faint),
              SizedBox(width: Sp.x2),
              Text(status == null ? 'Checking' : (listening ? 'Receiving is on' : 'Receiving is off'), style: ts.small),
            ],
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null && !listening) ...[_start(), SizedBox(height: Sp.x5)],
          _hero(st, listening),
          if (DeskFeatures.httpDirect || DeskFeatures.tor) ...[
            ESectionHead('Other ways to receive', top: Sp.x8),
            _direct(st, nav, listening),
          ],
          ESectionHead('Transaction files', top: DeskFeatures.httpDirect || DeskFeatures.tor ? 0 : null),
          ESetGroup(
            rows: [
              ESetRow(
                title: 'Sign a transaction file',
                text: 'A sender gave a transaction file. The wallet signs it and saves a response for them.',
                control: EButton(label: 'Open', icon: EIcons.fileDown, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.importTx)),
              ),
              ESetRow(
                title: 'Finalize a response file',
                text: 'A file send got a response back. Finalizing posts the payment.',
                control: EButton(label: 'Open', icon: EIcons.fileUp, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.finalize)),
              ),
            ],
          ),
          if (listening) ...[
            const ESectionHead('Listener', top: 0),
            ESetGroup(
              rows: [
                ESetRow(
                  title: 'Receiving is on',
                  text: status?.httpListener == ServiceHealth.ok
                      ? 'Epicbox and HTTP are listening. Once stopped, Epicbox payments wait on the relay for a while, HTTP payments fail, and transaction files still work.'
                      : 'Epicbox is listening. Once stopped, payments to the Epic address wait on the relay for a while, and transaction files still work.',
                  control: EButton(
                    label: 'Stop receiving',
                    icon: EIcons.stop,
                    size: EBtnSize.sm,
                    busy: _listenBusy,
                    onPressed: _listenBusy ? null : () => _setListening(false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _start() {
    final ts = context.ts;
    final c = context.dc;
    final text = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(EIcons.antenna, size: Ctl.iconLg, color: c.accentText),
        SizedBox(width: Sp.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Start the listener to receive online', style: ts.h3)),
              SizedBox(height: Sp.x2),
              Text(
                DeskFeatures.httpDirect
                    ? 'Epicbox and HTTP payments need the listener running. Payments already sent to the Epic address wait on the relay and arrive once it starts. Files work either way.'
                    : 'Epicbox payments need the listener running. Payments already sent to the Epic address wait on the relay and arrive once it starts. Files work either way.',
                style: ts.bodyDim,
              ),
            ],
          ),
        ),
      ],
    );
    final button = EButton.primary(label: 'Start listener', icon: EIcons.antenna, busy: _listenBusy, onPressed: _listenBusy ? null : () => _setListening(true));
    return EPanel(
      padding: EdgeInsets.all(Sp.x6),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 560.u
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, SizedBox(height: Sp.x4), button])
            : Row(children: [Expanded(child: text), SizedBox(width: Sp.x6), button]),
      ),
    );
  }

  Widget _hero(DeskState st, bool listening) {
    final ts = context.ts;
    final c = context.dc;
    final addr = st.epicboxAddress;
    final status = st.status;
    final domain = status?.epicbox.domain;
    final health = _args.epicboxDown && listening ? ServiceHealth.down : status?.epicboxHealth;
    final httpOn = status?.httpListener == ServiceHealth.ok;
    final (icon, color, text) = switch (health) {
      null => (EIcons.sync, c.faint, 'Connecting'),
      _ when !listening => (EIcons.minusCircle, c.faint, 'Receiving is off. Payments wait on the relay until the listener starts.'),
      ServiceHealth.ok || ServiceHealth.slow => (EIcons.okCircle, c.ok, 'Listening via $domain'),
      ServiceHealth.checking => (EIcons.sync, c.faint, 'Connecting to $domain'),
      ServiceHealth.down => (EIcons.alert, c.warn, '$domain is not answering. Payments wait on the relay.'),
      ServiceHealth.off => (EIcons.alert, c.warn, httpOn ? 'The listener is on, but Epicbox is not running.' : 'Epicbox is not running.'),
    };
    final tor = _tor;
    final qrData = _qr == _Qr.http && _http != null && _http!.isNotEmpty && httpOn
        ? _http!
        : _qr == _Qr.tor && tor != null && st.settings.tor
        ? tor
        : addr;
    final qrSize = 184.u;
    final Widget qr = qrData == null
        ? SizedBox(width: qrSize, height: qrSize)
        : Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: listening ? 1 : 0.35, child: EQr(qrData, size: qrSize)),
                  if (!listening)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x1),
                      decoration: BoxDecoration(color: c.s1, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineStrong)),
                      child: Text('Paused', style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              SizedBox(height: Sp.x2),
              Text(qrData == addr ? 'QR code of the Epic address' : 'QR code of the HTTP address', style: ts.caption),
            ],
          );
    return EPanel(
      padding: EdgeInsets.all(Sp.x6),
      child: LayoutBuilder(
        builder: (context, box) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Epic address', style: ts.h3)),
              SizedBox(height: Sp.x2),
              Text('Share it to get paid. It works while this wallet is closed: the relay holds payments until the wallet is back.', style: ts.bodyDim),
              SizedBox(height: Sp.x4),
              if (addr == null)
                Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: ESpinner(size: 20.u))
              else if (addr.isEmpty)
                Text('The Epic address could not be read. Open Receive again in a moment.', style: ts.small)
              else ...[
                Opacity(opacity: listening ? 1 : 0.6, child: EAddress(addr, large: true)),
                SizedBox(height: Sp.x2),
                Text('When reading it out, check the first six and last six characters.', style: ts.caption),
                SizedBox(height: Sp.x4),
                Wrap(
                  spacing: Sp.x3,
                  runSpacing: Sp.x2,
                  children: [
                    listening
                        ? EButton.primary(label: 'Copy address', icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => _copy(addr))
                        : EButton(label: 'Copy address', icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => _copy(addr)),
                    if (qrData != addr) EButton.ghost(label: 'Show QR code', icon: EIcons.qr, onPressed: () => setState(() => _qr = _Qr.epic)),
                  ],
                ),
              ],
              SizedBox(height: Sp.x4),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(icon, size: Ctl.iconSm, color: color),
                    SizedBox(width: Sp.x2),
                    Expanded(child: Text(text, style: ts.small)),
                  ],
                ),
              ),
              if (health == ServiceHealth.down && listening) ...[SizedBox(height: Sp.x3), const EpicboxDownNotice()],
            ],
          );
          if (box.maxWidth < 560.u) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, SizedBox(height: Sp.x5), Center(child: qr)]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: info), SizedBox(width: Sp.x6), qr],
          );
        },
      ),
    );
  }

  Widget _direct(DeskState st, DeskNav nav, bool listening) {
    final status = st.status;
    final ts = context.ts;
    final c = context.dc;
    final httpOn = !_httpFailed && status?.httpListener == ServiceHealth.ok;
    final failed = _httpFailed || status?.httpListener == ServiceHealth.down;
    final port = st.settings.httpPort;
    // The onion is known before tor runs; the line under it says whether others reach it yet.
    final torOn = st.settings.tor;
    final http = httpOn && _http != null && _http!.isNotEmpty ? _http : null;
    final Widget httpLine;
    if (status == null) {
      httpLine = const Align(alignment: Alignment.centerLeft, child: ESpinner());
    } else if (failed) {
      httpLine = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.only(top: Sp.x1), child: const EStatusDot(ETone.risk)),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'HTTP is not receiving. ', style: ts.small.copyWith(fontWeight: FontWeight.w600, color: c.text)),
                  TextSpan(
                    text: _httpFailed || status.httpProblem == 'Port $port in use'
                        ? 'Port $port is used by another program. Close that program or pick another port, then try again.'
                        : '${status.httpProblem ?? 'It stopped'}. Try again.',
                  ),
                ],
              ),
              style: ts.small,
            ),
          ),
        ],
      );
    } else {
      httpLine = Row(
        children: [
          EStatusDot(httpOn ? ETone.ok : ETone.neutral),
          SizedBox(width: Sp.x2),
          Expanded(
            child: Text(
              switch (status.httpListener) {
                ServiceHealth.ok => st.settings.publicMode
                    ? 'On, port $port. Senders on the internet use http://<public IP>:$port once the router forwards the port.'
                    : 'On, port $port. This computer only (127.0.0.1).',
                ServiceHealth.checking => 'Starting…',
                _ => 'Off.',
              },
              style: ts.small,
            ),
          ),
        ],
      );
    }
    return ESetGroup(
      rows: [
        if (DeskFeatures.httpDirect)
        ESetRow(
          title: 'HTTP address',
          stacked: true,
          below: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (http != null && st.settings.publicMode) Text('This network', style: ts.caption),
              Text(http ?? (httpOn ? '…' : 'Off'), style: ts.mono(size: Fs.sm, color: httpOn ? c.dim : c.faint), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: Sp.x2),
              httpLine,
              SizedBox(height: Sp.x3),
              Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (failed)
                    EButton(label: 'Try again', icon: EIcons.refresh, size: EBtnSize.sm, busy: _httpBusy, onPressed: _httpBusy ? null : () => _setHttp(true)),
                  if (httpOn || failed)
                    EButton(label: 'Turn off', icon: EIcons.stop, size: EBtnSize.sm, busy: _httpBusy && !failed, onPressed: _httpBusy ? null : () => _setHttp(false))
                  else
                    EButton(label: 'Turn on', icon: EIcons.antenna, size: EBtnSize.sm, busy: _httpBusy, onPressed: _httpBusy || status == null ? null : () => _setHttp(true)),
                  EIconButton(icon: EIcons.copy, label: 'Copy HTTP address', size: EBtnSize.sm, onPressed: http != null ? () => _copy(http) : null),
                  EIconButton(icon: EIcons.qr, label: 'Show QR code of the HTTP address', size: EBtnSize.sm, onPressed: http != null ? () => setState(() => _qr = _Qr.http) : null),
                  EButton(label: 'Settings', size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
                ],
              ),
            ],
          ),
        ),
        if (DeskFeatures.tor)
        _AddrRow(
          title: 'Tor address',
          on: torOn,
          loading: status == null,
          address: torOn ? _tor : null,
          line: status == null ? null : torStatusLine(status),
          onQr: () => setState(() => _qr = _Qr.tor),
          offText: 'Off. Turn it on to receive through Tor.',
          action: EButton(label: 'Receiving settings', size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
          showAction: !torOn && status != null,
        ),
      ],
    );
  }
}

class _AddrRow extends StatelessWidget {
  const _AddrRow({
    required this.title,
    required this.on,
    required this.loading,
    required this.address,
    required this.offText,
    required this.action,
    required this.showAction,
    this.line,
    this.onQr,
  });

  final String title;
  final bool on;
  final bool loading;
  final String? address;
  final String offText;
  final Widget action;
  final bool showAction;

  /// Under the address: what the service is doing now.
  final String? line;

  /// Shows the address's QR code.
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return ESetRow(
      title: title,
      stacked: true,
      below: loading
          ? const Align(alignment: Alignment.centerLeft, child: ESpinner())
          : on && address != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: SelectableText(address!, style: ts.mono(size: Fs.sm, color: c.dim), maxLines: 1)),
                    ECopyButton(text: address!, label: 'Copy $title'),
                    if (onQr != null) EIconButton(icon: EIcons.qr, label: 'Show QR code of the $title', size: EBtnSize.sm, onPressed: onQr),
                  ],
                ),
                if (line != null) Semantics(liveRegion: true, child: Text(line!, style: ts.small)),
              ],
            )
          : Row(
              children: [
                const EStatusDot(ETone.neutral),
                SizedBox(width: Sp.x2),
                Expanded(child: Text(offText, style: ts.small)),
                if (showAction) action,
              ],
            ),
    );
  }
}
