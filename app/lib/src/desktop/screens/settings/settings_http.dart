/// Settings › Receiving › HTTP listener (G01, G03, G04, G06): the switch, its status line, the
/// address senders use, Reachable (Local only / From the internet, with the guide), the port
/// and Start with the wallet. The listener runs only on the user's choice, and answers from the
/// internet only after the guide's "Receive from the internet".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'prefs.dart';

/// The HTTP listener as the status shows it.
HttpRun httpRun(ServiceStatus? s) => switch (s?.httpListener) {
  ServiceHealth.ok => HttpRun.on,
  ServiceHealth.checking => HttpRun.busy,
  ServiceHealth.down => HttpRun.failed,
  _ => HttpRun.off,
};

/// The status line under the switch.
String httpStatusText(ServiceStatus? st, DeskSettings s) {
  final port = s.httpPort;
  return switch (httpRun(st)) {
    HttpRun.on => s.publicMode ? 'On · port $port, from the internet' : 'On · port $port, this computer only',
    HttpRun.busy => 'Starting…',
    HttpRun.failed => st?.httpProblem ?? 'Didn’t start',
    HttpRun.off => s.directHttp ? 'Off · starts with the listener' : 'Off · most payments come via Epicbox',
  };
}

/// The port a field holds, or null when it is not one.
int? parsePort(String text) {
  final n = int.tryParse(text.trim());
  return n != null && n >= 1 && n <= 65535 ? n : null;
}

class HttpListenerRow extends ConsumerStatefulWidget {
  const HttpListenerRow({super.key, this.demoFailed = false});

  /// The tour's "port in use" state (the mock never fails).
  final bool demoFailed;

  @override
  ConsumerState<HttpListenerRow> createState() => _HttpListenerRowState();
}

class _HttpListenerRowState extends ConsumerState<HttpListenerRow> {
  late final TextEditingController _port = TextEditingController(text: '${ref.read(deskProvider).settings.httpPort}');
  String? _portError;
  String? _address;
  bool _busy = false;

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  Future<void> _readAddress() async {
    final a = await ref.read(deskApiProvider).httpAddress();
    if (mounted && a != _address) setState(() => _address = a);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not changed', text: '$e', tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setOn(bool on) => _run(() => ref.read(deskProvider.notifier).setHttp(on));

  Future<void> _setPublic(bool public) async {
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (s.publicMode == public) return;
    await _run(() => n.saveSettings(s.copyWith(publicMode: public)));
  }

  Future<void> _applyPort() async {
    final port = parsePort(_port.text);
    if (port == null) {
      setState(() => _portError = 'Port must be 1 to 65535');
      return;
    }
    setState(() => _portError = null);
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (s.httpPort != port) await _run(() => n.saveSettings(s.copyWith(httpPort: port)));
  }

  Future<void> _openGuide() async {
    final s = ref.read(deskProvider).settings;
    final public = await showEDialog<bool>(context, builder: (_) => InternetGuide(port: s.httpPort, isPublic: s.publicMode));
    if (public != null) await _setPublic(public);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final s = st.settings;
    final status = st.status;
    final c = context.dc;
    final ts = context.ts;
    var run = httpRun(status);
    var text = httpStatusText(status, s);
    if (widget.demoFailed) (run, text) = (HttpRun.failed, 'Port ${s.httpPort} in use');
    if (run == HttpRun.on) unawaited(_readAddress());
    final address = run == HttpRun.on ? _address : null;

    return ESetRow(
      title: 'HTTP listener',
      text: 'Payments straight from another wallet. Off until needed.',
      control: _busy && run != HttpRun.failed
          ? Semantics(label: 'Switching the HTTP listener', child: ESpinner(size: Ctl.iconLg))
          : ESwitch(value: s.directHttp || widget.demoFailed, semanticLabel: 'HTTP listener', onChanged: _setOn),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.u),
                  child: EStatusDot(switch (run) {
                    HttpRun.on => ETone.ok,
                    HttpRun.failed => ETone.risk,
                    HttpRun.busy => ETone.warn,
                    HttpRun.off => ETone.neutral,
                  }),
                ),
                SizedBox(width: Sp.x2),
                Expanded(
                  child: Text.rich(
                    TextSpan(style: ts.small, children: [
                      if (run == HttpRun.failed) TextSpan(text: 'Not receiving. ', style: ts.small.copyWith(color: c.risk, fontWeight: FontWeight.w600)),
                      TextSpan(text: text),
                    ]),
                  ),
                ),
                if (run == HttpRun.failed) ...[
                  SizedBox(width: Sp.x2),
                  EButton(label: 'Try again', icon: EIcons.refresh, size: EBtnSize.inline, busy: _busy, onPressed: _busy ? null : () => _setOn(true)),
                ],
              ],
            ),
          ),
          if (address != null && address.isNotEmpty) ...[
            SizedBox(height: Sp.x2),
            if (s.publicMode) Text('This network', style: ts.caption),
            Row(children: [Expanded(child: EAddress(address)), SizedBox(width: Sp.x2), ECopyButton(text: address)]),
          ],
          if (s.publicMode) ...[
            SizedBox(height: Sp.x2),
            Text('Listening on all interfaces. The router must forward TCP ${s.httpPort} to this computer. Senders on the internet use http://<public IP>:${s.httpPort}.', style: ts.caption),
          ],
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Reachable', style: ts.small.copyWith(color: c.text)),
              ESegmented<bool>(
                segments: const [ESegment(false, 'Local only'), ESegment(true, 'From the internet')],
                value: s.publicMode,
                // From the internet opens the guide; only its button makes the listener public.
                onChanged: (v) => v ? unawaited(_openGuide()) : unawaited(_setPublic(false)),
              ),
              EIconButton(icon: EIcons.help, label: 'Receive from the internet: how it works', size: EBtnSize.sm, onPressed: _openGuide),
            ],
          ),
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Port', style: ts.small.copyWith(color: c.text)),
              SizedBox(
                width: 96.u,
                child: Focus(
                  onFocusChange: (f) => f ? null : unawaited(_applyPort()),
                  child: EInput(
                    controller: _port,
                    mono: true,
                    invalid: _portError != null,
                    semanticLabel: 'HTTP listener port',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                    onSubmitted: (_) => _applyPort(),
                  ),
                ),
              ),
              if (_portError != null) Text(_portError!, style: ts.small.copyWith(color: c.risk)),
            ],
          ),
          SizedBox(height: Sp.x3),
          ECheckbox(
            value: s.httpAutostart,
            label: 'Start with the wallet',
            onChanged: (v) => _run(
              () => ref
                  .read(deskProvider.notifier)
                  .saveSettings(s.copyWith(httpAutostart: v)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Receive from the internet (G04, G05): Local only or From the internet, how to forward the
/// port, and Tor as the way with nothing to set up. Pops true for "Receive from the internet",
/// false for "Back to local only", null on Close.
class InternetGuide extends StatelessWidget {
  const InternetGuide({super.key, required this.port, required this.isPublic});

  final int port;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    Widget step(int n, String title, String text, [Widget? extra]) => Padding(
      padding: EdgeInsets.only(bottom: Sp.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: SizedBox(width: Sp.x6, child: Text('$n', style: ts.strong.copyWith(color: c.accentText)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                SizedBox(height: 2.u),
                Text(text, style: ts.small),
                ?extra,
              ],
            ),
          ),
        ],
      ),
    );
    return EDialog(
      title: 'Receive from the internet',
      description: isPublic ? 'Now: from the internet.' : 'Now: local only. Only programs on this computer reach the HTTP address.',
      icon: EIcons.web,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          step(1, 'Listen on all interfaces', 'The listener answers on 0.0.0.0, port $port. Other devices and the internet can then send payments to this wallet. The firewall may ask to allow it.'),
          step(2, 'Forward the port', 'On the router’s page (often 10.0.1.1), find Port forwarding and forward TCP $port to this computer.'),
          step(3, 'Share the public address', 'Senders use http://<public IP>:$port. The public IP can change.'),
          if (DeskFeatures.tor) ...[
            ENotice(
              icon: EIcons.tor,
              title: 'No router setup?',
              text: 'Tor works from anywhere with nothing to forward. Turn it on under Advanced.',
            ),
            SizedBox(height: Sp.x3),
          ],
          Text('Only the receiving API is exposed. Plain HTTP is not encrypted.', style: ts.caption),
        ],
      ),
      actions: [
        EButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
        if (isPublic)
          EButton(label: 'Back to local only', onPressed: () => Navigator.of(context).pop(false))
        else
          EButton.primary(label: 'Receive from the internet', icon: EIcons.web, onPressed: () => Navigator.of(context).pop(true)),
      ],
    );
  }
}
