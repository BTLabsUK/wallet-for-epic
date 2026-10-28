// SPDX-License-Identifier: Apache-2.0
/// Auto-lock (Settings › Account › Security), the phone's choices and default: the wallet locks
/// after [DeskSettings.autoLockMinutes] (1 to 60) without a key press or the mouse in the
/// window. Off ([DeskSettings.autoLockOn]) leaves locking to the user.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../data/state.dart';
import 'shell.dart';

/// Wraps the open wallet's shell: any key or pointer in the window starts the idle time again.
class DeskAutoLock extends ConsumerStatefulWidget {
  const DeskAutoLock({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeskAutoLock> createState() => _DeskAutoLockState();
}

class _DeskAutoLockState extends ConsumerState<DeskAutoLock> {
  Timer? _timer;

  /// Running for a second after the idle time started again: pointer moves meanwhile keep it.
  Timer? _settle;

  /// The idle time, or null while auto-lock is off.
  int? get _minutes {
    final s = ref.read(deskProvider).settings;
    return s.autoLockOn ? s.autoLockMinutes : null;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    _settle?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    _restart();
    return false;
  }

  void _poke() {
    if (_settle?.isActive ?? false) return;
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 1), () {});
    final minutes = _minutes;
    if (minutes == null) return;
    _timer = Timer(Duration(minutes: minutes), _lock);
  }

  void _lock() {
    if (!mounted) return;
    // A chain scan (a restore's first, or Recheck balance) keeps the wallet open: a lock
    // would stop it every idle period and a restore would never finish (item 25).
    if (ref.read(deskProvider).status?.scanning ?? false) {
      logInfo('session', 'auto-lock waits for the scan');
      _restart();
      return;
    }
    logInfo('session', 'auto-lock');
    unawaited(lockWallet(ref));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deskProvider.select((s) => (s.settings.autoLockOn, s.settings.autoLockMinutes)), (_, _) => _restart());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _poke(),
      onPointerMove: (_) => _poke(),
      onPointerHover: (_) => _poke(),
      onPointerSignal: (_) => _poke(),
      child: widget.child,
    );
  }
}
