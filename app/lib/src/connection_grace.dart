// SPDX-License-Identifier: Apache-2.0
/// The connection grace (item 11, the owner 2026-11-01): right after the app starts and after it
/// comes back to the front, connections are only re-establishing. For `[notices]
/// server_grace_s` of `app-config.toml` (20 s as shipped) no warning about the node, Epicbox or
/// Tor shows: no toast, banner, notice or switch offer. Only the title-bar status icons (the
/// phone's status chip) say "Connecting". After it, a server still unreachable gets its notice,
/// compact and on its own page.
///
/// Both apps read [connectionGraceProvider]; it starts itself on its first read (the app's
/// start) and again on every return to the front: `resumed` after `hidden` or `paused` (the
/// phone back from the background, the desktop window restored from the taskbar), not after a
/// focus change alone.
library;

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_file/host_settings.dart' show hostSettings, hostSettingsLoaded;

/// How long the grace lasts: `notices.server_grace_s`, or none before the settings are read
/// (tests, a bare core check). Override it in a test to give it a length.
final connectionGraceLengthProvider = Provider<Duration>(
  (ref) => hostSettingsLoaded ? hostSettings.config.serverGrace : Duration.zero,
);

/// True while the grace runs: server warnings wait, the status icons say "Connecting".
final connectionGraceProvider = NotifierProvider<ConnectionGraceNotifier, bool>(ConnectionGraceNotifier.new);

/// Starts the grace at its first read and at every return to the front; ends it after
/// [connectionGraceLengthProvider].
class ConnectionGraceNotifier extends Notifier<bool> {
  Timer? _timer;
  AppLifecycleListener? _life;

  /// The app was in the background (`hidden` or `paused`) since the last `resumed`.
  bool _away = false;

  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
      _life?.dispose();
    });
    try {
      _life = AppLifecycleListener(onStateChange: _lifecycle);
    } on Object {
      // No widgets binding (a plain unit test): no lifecycle, the grace runs once.
    }
    return _arm();
  }

  void _lifecycle(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _away = true;
      case AppLifecycleState.resumed when _away:
        _away = false;
        restart();
      default:
    }
  }

  /// Starts the timer; whether the grace runs now.
  bool _arm() {
    _timer?.cancel();
    final length = ref.read(connectionGraceLengthProvider);
    if (length <= Duration.zero) return false;
    _timer = Timer(length, () => state = false);
    return true;
  }

  /// The grace again from now, as after a return to the front (another resume signal a
  /// platform has, such as a network change).
  void restart() => state = _arm();

  /// Ends the grace now (a server that answered, a test).
  void end() {
    _timer?.cancel();
    state = false;
  }
}
