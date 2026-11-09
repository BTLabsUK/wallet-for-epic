// SPDX-License-Identifier: Apache-2.0
/// Link · HTTP's two addresses, each with its switch: this computer
/// (`http://127.0.0.1:<port>`, the listener itself) and the internet
/// (`http://<the router's public IP>:<port>`, [DeskSettings.publicMode]: the listener binds
/// 0.0.0.0 instead of 127.0.0.1). On Receive and in Settings › Transactions › Link · HTTP.
///
/// The public IP is asked (status server, `[status] ip` of `app-config.toml`) only while the
/// internet switch is on and the listener runs; never the LAN address in its place.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../network_gate.dart' show NetGate;
import '../data/desk_errors.dart' show deskErrorText;
import '../data/http_address.dart' show HttpReach;
import '../desk_l10n.dart';
import 'http_reach.dart';
import 'kit.dart';

/// How an address is drawn: Receive's QR reveal, or a plain address box in Settings.
typedef HttpAddressView = Widget Function(BuildContext context, String address, String title);

class HttpAddresses extends ConsumerStatefulWidget {
  const HttpAddresses({
    super.key,
    required this.local,
    this.onLocal,
    this.localBusy = false,
    this.view,
    this.publicTrailing,
    this.onReach,
  });

  /// The running listener's `http://127.0.0.1:<port>`; null while it is off or starting.
  final String? local;

  /// The local switch (the listener on or off); null shows no local switch, where the
  /// method's own switch is next to it (Settings).
  final ValueChanged<bool>? onLocal;

  final bool localBusy;

  /// Draws the internet address; [EAddress] when null. This computer's is always a plain
  /// [EAddress]: no QR code, as no other device reaches 127.0.0.1.
  final HttpAddressView? view;

  /// After the internet row's title: Settings' guide button.
  final Widget? publicTrailing;

  /// Each reach answer, for a caller that shows it elsewhere.
  final ValueChanged<HttpReach?>? onReach;

  @override
  ConsumerState<HttpAddresses> createState() => _HttpAddressesState();
}

class _HttpAddressesState extends ConsumerState<HttpAddresses> {
  HttpReach? _reach;
  bool _publicBusy = false;

  Future<void> _setPublic(bool on) async {
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (s.publicMode == on) return;
    final l = context.l10n;
    setState(() => _publicBusy = true);
    try {
      // Saved for this wallet; the running listener restarts on 0.0.0.0 or 127.0.0.1.
      await n.saveSettings(s.copyWith(publicMode: on));
      if (!on) _reach = null;
    } on Object catch (e) {
      logWarn('desk', 'http public not changed: $e');
      if (mounted) showEToast(context, l.deskSetHttpNotChanged, text: deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _publicBusy = false);
    }
  }

  Widget _address(BuildContext context, String address, String title) =>
      widget.view?.call(context, address, title) ?? EAddress(address, copyLabel: context.l10n.deskRecvCopyHttp);

  Widget _row({
    required Key key,
    required String title,
    required Widget? trailingTitle,
    required Widget switcher,
    required List<Widget> body,
  }) {
    final ts = context.ts;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(child: Text(title, style: ts.strong)),
                  // No gap: the inline button's own padding sets it, as ESetRow's info icon.
                  if (trailingTitle != null) EHitSlop(child: trailingTitle),
                ],
              ),
            ),
            SizedBox(width: Sp.x3),
            switcher,
          ],
        ),
        for (final w in body) ...[SizedBox(height: Sp.x2), w],
      ],
    );
  }

  Widget _switch(Key key, bool value, ValueChanged<bool>? onChanged, String label, bool busy) => SizedBox(
    width: 40.u,
    height: 24.u,
    child: busy
        ? Center(child: ESpinner(size: 18.u))
        : ESwitch(key: key, value: value, onChanged: onChanged, semanticLabel: label),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final s = ref.watch(deskProvider.select((st) => st.settings));
    final listener = ref.watch(deskProvider.select((st) => st.status?.httpListener));
    final running = listener == ServiceHealth.ok;
    final localOn = listener != null && listener != ServiceHealth.off;
    final port = s.httpPort;
    // Off while Tor is on and in Node only / Kill switch: no clearnet listener to open.
    final canPublic = localOn && !s.tor && !NetGate.restricted;
    final local = widget.local;
    final publicAddress = s.publicMode && running ? _reach?.publicAddress : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          key: const ValueKey('http-local'),
          title: l.deskHttpLocalTitle,
          trailingTitle: null,
          switcher: widget.onLocal == null
              ? const SizedBox.shrink()
              : _switch(const ValueKey('http-local-switch'), localOn, widget.onLocal, l.deskHttpLocalSwitch, widget.localBusy),
          body: [
            if (local != null) EAddress(local, copyLabel: l.deskRecvCopyHttp),
            Text(l.deskRecvHttpIntro, style: ts.caption),
          ],
        ),
        SizedBox(height: Sp.x4),
        _row(
          key: const ValueKey('http-public'),
          title: l.deskHttpPublicTitle,
          trailingTitle: widget.publicTrailing,
          switcher: _switch(const ValueKey('http-public-switch'), s.publicMode, canPublic ? (v) => unawaited(_setPublic(v)) : null, l.deskSetHttpGuideTitle, _publicBusy),
          body: [
            if (publicAddress != null) _address(context, publicAddress, l.deskHttpPublicTitle),
            Text(l.deskHttpPublicNote('$port'), key: const ValueKey('http-public-note'), style: ts.caption),
            // The public IP and whether the port answers: asked only while this is on.
            if (s.publicMode && running)
              HttpReachNotice(
                onChanged: (r) {
                  if (mounted) setState(() => _reach = r);
                  widget.onReach?.call(r);
                },
              ),
          ],
        ),
      ],
    );
  }
}
