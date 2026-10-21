import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Argument of the Receive route: [internet] scrolls to the "Receive from internet" section,
/// [portOpen] is what the port check found there.
class ReceiveArgs {
  const ReceiveArgs({this.internet = false, this.portOpen = false});

  final bool internet;
  final bool portOpen;
}

enum _Port { open, closed, checking }

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _internetKey = GlobalKey();
  late _Port _port;
  String? _http;
  String? _tor;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    _port = a is ReceiveArgs && a.portOpen ? _Port.open : _Port.closed;
    final api = ref.read(deskApiProvider);
    unawaited(api.httpAddress().then((v) => mounted ? setState(() => _http = v) : null));
    unawaited(api.torAddress().then((v) => mounted ? setState(() => _tor = v) : null));
    if (a is ReceiveArgs && a.internet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _internetKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.05);
      });
    }
  }

  Future<void> _check() async {
    setState(() => _port = _Port.checking);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final a = widget.arg;
    setState(() => _port = a is ReceiveArgs && a.portOpen ? _Port.open : _Port.closed);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final c = context.dc;
    final status = st.status;
    final listening = status != null && status.epicboxHealth != ServiceHealth.off;
    return EPage(
      title: 'Receive',
      width: EPageWidth.mid,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(listening ? EIcons.okCircle : EIcons.minusCircle, size: Ctl.iconSm, color: listening ? c.ok : c.faint),
            const SizedBox(width: Sp.x2),
            Text(status == null ? 'Checking' : (listening ? 'Receiving is on' : 'Receiving is off'), style: ts.small),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(st),
          const ESectionHead('Direct receive', top: Sp.x8),
          _direct(st, nav),
          Container(key: _internetKey, child: const ESectionHead('Receive from internet')),
          _internet(st, nav),
          const ESectionHead('Transaction files'),
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
        ],
      ),
    );
  }

  Widget _hero(DeskState st) {
    final ts = context.ts;
    final c = context.dc;
    final addr = st.epicboxAddress;
    final status = st.status;
    final domain = status?.epicbox.domain;
    final health = status?.epicboxHealth;
    final (icon, color, text) = switch (health) {
      null => (EIcons.sync, c.faint, 'Connecting'),
      ServiceHealth.ok || ServiceHealth.slow => (EIcons.okCircle, c.ok, 'Listening via $domain'),
      ServiceHealth.checking => (EIcons.sync, c.faint, 'Connecting'),
      ServiceHealth.down => (EIcons.alert, c.warn, '$domain is not answering. Payments wait on the relay.'),
      ServiceHealth.off => (EIcons.minusCircle, c.faint, 'Receiving is off. Payments wait on the relay.'),
    };
    return EPanel(
      padding: const EdgeInsets.all(Sp.x6),
      child: LayoutBuilder(
        builder: (context, box) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Epic address', style: ts.h3)),
              const SizedBox(height: Sp.x2),
              Text('Share it to get paid. It works while this wallet is closed: the relay holds payments until the wallet is back.', style: ts.bodyDim),
              const SizedBox(height: Sp.x4),
              if (addr == null)
                const Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: ESpinner(size: 20))
              else ...[
                EAddress(addr, large: true),
                const SizedBox(height: Sp.x2),
                Text('When reading it out, check the first six and last six characters.', style: ts.caption),
              ],
              const SizedBox(height: Sp.x4),
              Row(
                children: [
                  Icon(icon, size: Ctl.iconSm, color: color),
                  const SizedBox(width: Sp.x2),
                  Expanded(child: Text(text, style: ts.small)),
                ],
              ),
            ],
          );
          final qr = addr == null ? const SizedBox(width: 184, height: 184) : EQr(addr, size: 184);
          if (box.maxWidth < 560) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: Sp.x5), Center(child: qr)]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: info), const SizedBox(width: Sp.x6), qr],
          );
        },
      ),
    );
  }

  Widget _direct(DeskState st, DeskNav nav) {
    final status = st.status;
    final httpOn = status?.httpListener == ServiceHealth.ok;
    final torOn = st.settings.tor && status?.tor == ServiceHealth.ok;
    return ESetGroup(
      rows: [
        _AddrRow(
          title: 'HTTP address',
          icon: EIcons.http,
          on: httpOn,
          loading: status == null,
          address: httpOn ? _http : null,
          offText: 'Off. Turn it on to receive over HTTP.',
          action: EButton(label: 'Receiving settings', size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
          showAction: !httpOn && status != null,
        ),
        _AddrRow(
          title: 'Tor address',
          icon: EIcons.tor,
          on: torOn,
          loading: status == null,
          address: torOn ? _tor : null,
          offText: st.settings.tor ? 'Tor is connecting.' : 'Off. Turn it on to receive through Tor.',
          action: EButton(label: 'Receiving settings', size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving)),
          showAction: !torOn && status != null,
        ),
      ],
    );
  }

  Widget _internet(DeskState st, DeskNav nav) {
    final ts = context.ts;
    final pub = st.settings.publicMode;
    final port = _port;
    final Widget notice;
    if (!pub) {
      notice = ENotice(
        title: 'Listening on this computer only',
        text: 'Public mode is off, so only this computer reaches port 3415. Turn it on to receive from other wallets.',
        icon: EIcons.lanOff,
        actions: [EButton(label: 'Receiving settings', size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsReceiving))],
      );
    } else {
      notice = switch (port) {
        _Port.checking => const ENotice(title: 'Checking port 3415', icon: EIcons.sync),
        _Port.open => ENotice(
          title: 'Port 3415 is reachable from the internet',
          text: 'Wallets anywhere can send to the HTTP address.',
          tone: ETone.ok,
          icon: EIcons.web,
          actions: [EButton(label: 'Check again', size: EBtnSize.inline, onPressed: _check)],
        ),
        _Port.closed => ENotice(
          title: 'Port 3415 is not reachable from the internet',
          text: 'Only wallets on this network can send here. To receive from anywhere, forward TCP port 3415 on the router to this computer.',
          tone: ETone.warn,
          icon: EIcons.lanOff,
          actions: [EButton(label: 'Check again', size: EBtnSize.inline, onPressed: _check)],
        ),
      };
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receive over HTTP from wallets outside this network. Needs public mode and a forwarded port.', style: ts.small),
        const SizedBox(height: Sp.x3),
        notice,
        if (pub && _http != null) ...[
          const SizedBox(height: Sp.x3),
          EAddress(_http!),
        ],
      ],
    );
  }
}

class _AddrRow extends StatelessWidget {
  const _AddrRow({
    required this.title,
    required this.icon,
    required this.on,
    required this.loading,
    required this.address,
    required this.offText,
    required this.action,
    required this.showAction,
  });

  final String title;
  final IconData icon;
  final bool on;
  final bool loading;
  final String? address;
  final String offText;
  final Widget action;
  final bool showAction;

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
          ? Row(
              children: [
                Expanded(child: SelectableText(address!, style: ts.mono(size: Fs.sm, color: c.dim), maxLines: 1)),
                ECopyButton(text: address!, label: 'Copy $title'),
              ],
            )
          : Row(
              children: [
                const EStatusDot(ETone.neutral),
                const SizedBox(width: Sp.x2),
                Expanded(child: Text(offText, style: ts.small)),
                if (showAction) action,
              ],
            ),
    );
  }
}
