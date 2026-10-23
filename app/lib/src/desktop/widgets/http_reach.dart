/// HTTP From the internet: whether the internet reaches the public address, with Check. On
/// Receive and in Settings › Receiving, while the listener runs From the internet.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/http_address.dart' show HttpReach;
import 'kit.dart';

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
    widget.onChanged?.call(r);
  }

  @override
  Widget build(BuildContext context) {
    // The listener restarts on a new port: check that one.
    ref.listen(deskProvider.select((s) => (s.settings.httpPort, s.status?.httpListener)), (a, b) {
      if (a != b) unawaited(_read());
    });
    final r = _reach;
    final check = EButton(
      key: const ValueKey('http-reach-check'),
      label: 'Check',
      size: EBtnSize.inline,
      busy: _checking,
      onPressed: _checking ? null : () => unawaited(_read(recheck: true)),
    );
    if (r == null) {
      return _checking
          ? const ENotice(key: ValueKey('http-reach'), title: 'Checking from the internet…')
          : const SizedBox.shrink();
    }
    final lan = r.lanAddress;
    final local = lan == null ? '' : ' On your network: $lan.';
    final (tone, title, text) = switch ((r.publicIp, r.reachable)) {
      (null, _) => (ETone.warn, 'Public IP not found', 'The internet could not be asked for it. Try again later.$local'),
      (_, false) => (
        ETone.warn,
        'Not reachable from the internet',
        'Forward TCP port ${r.port} on your router to this computer${r.lan == null ? '' : ' (${r.lan})'}, then check again.',
      ),
      (_, null) => (ETone.warn, 'Reachability unknown', 'The port check did not answer. Try again later.$local'),
      (_, true) => (ETone.ok, 'Reachable from the internet', 'Port ${r.port} is forwarded.$local'),
    };
    return ENotice(key: const ValueKey('http-reach'), tone: tone, title: title, text: text, actions: [check]);
  }
}
