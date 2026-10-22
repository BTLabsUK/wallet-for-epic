/// Settings › Receiving › HTTP receiving (G01, G03, G04, G06): Reachable (Local only / From the
/// internet, with the guide) and the port. HTTP answers from the internet only after the
/// guide's "Receive from the internet".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'prefs.dart';

/// HTTP receiving as the status shows it.
HttpRun httpRun(ServiceStatus? s) => switch (s?.httpListener) {
  ServiceHealth.ok => HttpRun.on,
  ServiceHealth.checking => HttpRun.busy,
  ServiceHealth.down => HttpRun.failed,
  _ => HttpRun.off,
};

/// The port a field holds, or null when it is not one.
int? parsePort(String text) {
  final n = int.tryParse(text.trim());
  return n != null && n >= 1 && n <= 65535 ? n : null;
}

/// The HTTP group's options (spec 6.1): Reachable (Local only / From the internet, which opens
/// the guide) and the port. The switch and Start with the wallet are the group's own rows.
class HttpOptions extends ConsumerStatefulWidget {
  const HttpOptions({super.key});

  @override
  ConsumerState<HttpOptions> createState() => _HttpOptionsState();
}

class _HttpOptionsState extends ConsumerState<HttpOptions> {
  late final TextEditingController _port = TextEditingController(text: '${ref.read(deskProvider).settings.httpPort}');
  String? _portError;

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not changed', text: '$e', tone: ETone.risk);
    }
  }

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

  /// From the internet: the guide the first time, then straight to it.
  Future<void> _pickPublic() async {
    if (ref.read(deskProvider).settings.internetGuideSeen) return _setPublic(true);
    return _openGuide();
  }

  /// The guide; opening it changes nothing, only its buttons do. Shown once is seen.
  Future<void> _openGuide() async {
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (!s.internetGuideSeen) unawaited(_run(() => n.saveSettings(s.copyWith(internetGuideSeen: true))));
    final choice = await showEDialog<InternetGuideChoice>(context, builder: (_) => InternetGuide(port: s.httpPort, isPublic: s.publicMode));
    switch (choice) {
      case InternetGuideChoice.public:
        await _setPublic(true);
      case InternetGuideChoice.local:
        await _setPublic(false);
      case InternetGuideChoice.tor:
        // Lands on the Tor group, connecting.
        ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.tor);
        await _run(() => ref.read(deskProvider.notifier).setTor(true));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(deskProvider.select((st) => st.settings));
    final c = context.dc;
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) => ESetRow(
          title: 'Reachable',
          stacked: box.maxWidth < 640.u,
          text: 'Who can pay the HTTP address.',
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ESegmented<bool>(
                segments: const [ESegment(false, 'Local only'), ESegment(true, 'From the internet')],
                value: s.publicMode,
                // The first From the internet opens the guide; only its button makes the
                // address public. Once seen, the guide is behind the (?).
                onChanged: (v) => v ? unawaited(_pickPublic()) : unawaited(_setPublic(false)),
              ),
              SizedBox(width: Sp.x2),
              EIconButton(icon: EIcons.help, label: 'Receive from the internet: how it works', size: EBtnSize.sm, tabStop: false, onPressed: _openGuide),
            ],
          ),
          below: s.publicMode
              ? Text(
                  'Answers on all interfaces. The router must forward TCP ${s.httpPort} to this computer. Senders on the internet use http://<public IP>:${s.httpPort}.',
                  style: ts.caption,
                )
              : null,
        ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        ESetRow(
          title: 'Port',
          text: '1 to 65535. Used by the HTTP address.',
          control: SizedBox(
            width: 96.u,
            child: Focus(
              onFocusChange: (f) => f ? null : unawaited(_applyPort()),
              child: EInput(
                controller: _port,
                mono: true,
                invalid: _portError != null,
                semanticLabel: 'HTTP port',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                onSubmitted: (_) => _applyPort(),
              ),
            ),
          ),
          below: _portError == null ? null : Text(_portError!, style: ts.small.copyWith(color: c.risk)),
        ),
      ],
    );
  }
}

/// Receive from the internet (G04, G05): Local only or From the internet, how to forward the
/// port, and Tor as the way with nothing to set up. Pops an [InternetGuideChoice], null on Close.
/// What the guide was closed with: "Receive from the internet", "Back to local only" or
/// "Turn on Tor receiving".
enum InternetGuideChoice { public, local, tor }

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
          step(1, 'Listen on all interfaces', 'The wallet answers on 0.0.0.0, port $port. Other devices and the internet can then send payments to this wallet. The firewall may ask to allow it.'),
          step(2, 'Forward the port', 'On the router’s page (often 10.0.1.1), find Port forwarding and forward TCP $port to this computer.'),
          step(3, 'Share the public address', 'Senders use http://<public IP>:$port. The public IP can change.'),
          if (DeskFeatures.tor) ...[
            ENotice(
              icon: EIcons.tor,
              title: 'No router setup?',
              text: 'Tor works from anywhere with nothing to forward.',
              actionsBelow: true,
              actions: [
                EButton(label: 'Turn on Tor receiving', size: EBtnSize.inline, onPressed: () => Navigator.of(context).pop(InternetGuideChoice.tor)),
              ],
            ),
            SizedBox(height: Sp.x3),
          ],
          Text('Only the receiving API is exposed. Plain HTTP is not encrypted.', style: ts.caption),
        ],
      ),
      actions: [
        EButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
        if (isPublic)
          EButton(label: 'Back to local only', onPressed: () => Navigator.of(context).pop(InternetGuideChoice.local))
        else
          EButton.primary(label: 'Receive from the internet', icon: EIcons.web, onPressed: () => Navigator.of(context).pop(InternetGuideChoice.public)),
      ],
    );
  }
}
