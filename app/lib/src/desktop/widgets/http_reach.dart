// SPDX-License-Identifier: Apache-2.0
/// HTTP From the internet: whether the internet reaches the public address, with Check. On
/// Receive and in Settings › Transactions, while the listener runs From the internet.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../data/http_address.dart' show HttpReach, WebReachProbe;
import 'kit.dart';

/// The last answer the reach notice got, for the rail's HTTP row; null until one comes in.
/// The rail only reads it: no check of its own.
class DeskLastHttpReach extends Notifier<HttpReach?> {
  @override
  HttpReach? build() => null;

  void set(HttpReach? r) => state = r;
}

final deskLastHttpReachProvider = NotifierProvider<DeskLastHttpReach, HttpReach?>(DeskLastHttpReach.new);

/// [DeskSettings.httpReachAck] for [r]: its public address and port.
String httpReachAckOf(HttpReach r) => '${r.publicIp}:${r.port}';

/// The internet does not reach Link · HTTP's public address and the user has not dismissed
/// that warning for this address and port: its glyph and line are amber. Dismissed, they are
/// green again, reachable or not.
final deskHttpReachClosedProvider = Provider<bool>((ref) {
  final r = ref.watch(deskLastHttpReachProvider);
  if (r?.reachable != false) return false;
  return ref.watch(deskProvider.select((s) => s.settings.httpReachAck)) != httpReachAckOf(r!);
});

/// The check's notice: checking, reachable, not reachable (forward the port), or could not
/// tell. Asked on open, every minute (a network change shows within one; the answer is kept 2
/// minutes) and on Check. [onChanged] gets each answer, for the address above it.
class HttpReachNotice extends ConsumerStatefulWidget {
  const HttpReachNotice({super.key, this.onChanged});

  final ValueChanged<HttpReach?>? onChanged;

  @override
  ConsumerState<HttpReachNotice> createState() => _HttpReachNoticeState();
}

class _HttpReachNoticeState extends ConsumerState<HttpReachNotice> {
  HttpReach? _reach;
  bool _checking = true;
  Timer? _every;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
    _every = Timer.periodic(const Duration(minutes: 1), (_) => unawaited(_read()));
  }

  @override
  void dispose() {
    _every?.cancel();
    super.dispose();
  }

  Future<void> _read({bool recheck = false}) async {
    if (recheck) setState(() => _checking = true);
    HttpReach? r;
    try {
      r = await ref.read(deskApiProvider).httpReach(recheck: recheck);
    } on Object {
      r = null;
    }
    if (!mounted) return;
    setState(() {
      _reach = r;
      _checking = false;
    });
    ref.read(deskLastHttpReachProvider.notifier).set(r);
    widget.onChanged?.call(r);
  }

  @override
  Widget build(BuildContext context) {
    // No reach check in app-config.toml: no notice.
    if (!WebReachProbe.configured) return const SizedBox.shrink();
    // The listener restarts on a new port: check that one.
    ref.listen(deskProvider.select((s) => (s.settings.httpPort, s.status?.httpListener)), (a, b) {
      if (a != b) unawaited(_read());
    });
    final l = context.l10n;
    final r = _reach;
    final check = EButton(
      key: const ValueKey('http-reach-check'),
      label: l.deskKitReachCheck,
      size: EBtnSize.inline,
      busy: _checking,
      onPressed: _checking ? null : () => unawaited(_read(recheck: true)),
    );
    if (r == null) {
      return _checking
          ? ENotice(key: const ValueKey('http-reach'), title: l.deskKitReachChecking)
          : const SizedBox.shrink();
    }
    if (r.needsTorOff) {
      return ENotice(key: const ValueKey('http-reach'), title: l.deskKitReachTorOff, actions: [check]);
    }
    final lan = r.lanAddress;
    // Not reachable, and the user dismissed that for this address and port: nothing more to say.
    final acked = ref.watch(deskProvider.select((s) => s.settings.httpReachAck)) == httpReachAckOf(r);
    if (r.publicIp != null && r.reachable == false && acked) return const SizedBox.shrink();
    final (tone, title, text) = switch ((r.publicIp, r.reachable)) {
      (null, _) => (
        ETone.warn,
        l.deskKitReachNoIpTitle,
        lan == null ? l.deskKitReachNoIpText : l.deskKitReachNoIpTextLan(lan),
      ),
      (_, false) => (
        ETone.warn,
        l.deskKitReachClosedTitle,
        r.lan == null ? l.deskKitReachClosedText('${r.port}') : l.deskKitReachClosedTextLan('${r.port}', '${r.lan}'),
      ),
      (_, null) => (
        ETone.warn,
        l.deskKitReachUnknownTitle,
        lan == null ? l.deskKitReachUnknownText : l.deskKitReachUnknownTextLan(lan),
      ),
      (_, true) => (
        ETone.ok,
        l.deskKitReachOpenTitle,
        lan == null ? l.deskKitReachOpenText('${r.port}') : l.deskKitReachOpenTextLan('${r.port}', lan),
      ),
    };
    // Not reachable: the user may know (no port forward wanted, a LAN-only setup) and dismiss it
    // for this address and port; a new address or port, or From the internet off and on again,
    // shows it again.
    final dismiss = r.publicIp != null && r.reachable == false
        ? EButton.ghost(
            key: const ValueKey('http-reach-dismiss'),
            label: l.deskKitReachDismiss,
            size: EBtnSize.inline,
            onPressed: () {
              final n = ref.read(deskProvider.notifier);
              unawaited(n.saveSettings(ref.read(deskProvider).settings.copyWith(httpReachAck: httpReachAckOf(r))));
            },
          )
        : null;
    return ENotice(key: const ValueKey('http-reach'), tone: tone, title: title, text: text, textSpan: _unbrokenAddress(text, lan), actions: [check, ?dismiss]);
  }
}

/// [text] with [address] in it kept on one line (an ellipsis when even a line is too short):
/// never "http://" at a line's end and the rest on the next. Copied as it reads. Null when
/// [text] does not hold [address].
InlineSpan? _unbrokenAddress(String text, String? address) {
  final at = address == null ? -1 : text.indexOf(address);
  if (at < 0) return null;
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, at)),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Text(address!, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
      ),
      TextSpan(text: text.substring(at + address.length)),
    ],
  );
}
