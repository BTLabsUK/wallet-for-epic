// SPDX-License-Identifier: Apache-2.0
/// Windows' tray: the runner's notification icon and its menu (windows/runner/tray.cpp), over the
/// `epic_wallet/tray` channel. The runner also passes the system's end of session here, so the
/// node stops before Windows ends the process.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../log.dart';
import 'tray_host.dart';
import 'tray_menu.dart';

class WindowsTray extends TrayHost {
  WindowsTray() {
    _channel.setMethodCallHandler(_call);
  }

  static const _channel = MethodChannel('epic_wallet/tray');

  /// Windows is ending the session (shutdown, restart, sign-out): close down before it ends the
  /// process. The runner waits for this, up to 20 seconds.
  Future<void> Function()? onEndSession;

  static final _yes = ValueNotifier(true);

  @override
  ValueListenable<bool> get available => _yes;

  @override
  Future<bool> check() async => true;

  @override
  Future<({List<int> icons, int menu})> sizes() async {
    try {
      final m = await _channel.invokeMapMethod<String, int>('metrics');
      return (icons: [m?['icon'] ?? 16], menu: m?['menuIcon'] ?? 16);
    } on Object catch (e) {
      logWarn('tray', 'no tray metrics (${e.runtimeType})');
      return (icons: const [16], menu: 16);
    }
  }

  static Map<String, Object> _img(TrayImage i) => {'width': i.width, 'height': i.height, 'rgba': i.rgba};

  @override
  Future<void> show(TrayView view) => _channel.invokeMethod<void>('set', {
    'icon': _img(view.icons.first),
    'tooltip': view.tooltip,
    'items': [
      for (final it in view.items)
        {
          'kind': it.kind.name,
          'id': it.id,
          'label': it.label,
          'enabled': it.enabled,
          'checked': ?it.checked,
          if (view.marks[it.mark] case final m?) 'icon': _img(m),
          if (it.kind == TrayItemKind.header) 'bold': true,
        },
    ],
  });

  @override
  Future<void> remove() => _channel.invokeMethod<void>('remove');

  Future<Object?> _call(MethodCall call) async {
    switch (call.method) {
      case 'click':
        onClick?.call();
      case 'activate':
        final id = call.arguments;
        if (id is String) onActivate?.call(id);
      case 'endSession':
        logInfo('tray', 'session ending');
        await onEndSession?.call();
    }
    return null;
  }
}
