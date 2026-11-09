// SPDX-License-Identifier: Apache-2.0
/// Sync in background, for the built-in node: the window's close hides the window to the tray
/// while the node syncs (tray_menu.dart's `hidesOnClose`), and the tray's menu shows the node
/// and Epicbox and holds their switches until Open wallet or Quit. The icon is there only while
/// the window is hidden.
///
/// The wallet is not kept open by a hidden window: auto-lock's idle timer runs on (no key or
/// pointer reaches a hidden window), so the wallet locks when the setting says, and the node
/// syncs on while it is locked. Every state is listened to with `listenManual`: a hidden window
/// draws no frame, so nothing in build would run.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../../node/local_node_state.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/desk_node.dart' show deskLocalNodeProvider;
import '../../data/method_names.dart' show methodLabel;
import '../../desk_l10n.dart';
import '../../screens/settings/prefs.dart' show settingsPrefsProvider;
import '../../widgets/kit.dart';
import '../close_guard.dart';
import '../desk_app.dart' show deskNavigatorKey;
import '../desk_window.dart';
import '../shell.dart' show lockWallet;
import 'tray_host.dart';
import 'tray_icon.dart';
import 'tray_menu.dart';

class DeskTray extends ConsumerStatefulWidget {
  const DeskTray({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeskTray> createState() => _DeskTrayState();
}

class _DeskTrayState extends ConsumerState<DeskTray> {
  late final TrayHost _host = ref.read(deskTrayHostProvider);
  late final DeskWindow _window = ref.read(deskWindowProvider);

  /// The window is hidden and the icon in the tray.
  bool _hidden = false;
  bool _drawing = false;
  bool _again = false;
  TrayView? _shown;
  Future<({List<int> icons, int menu})>? _sizes;

  @override
  void initState() {
    super.initState();
    _host.onClick = () => unawaited(_open());
    _host.onActivate = (id) => unawaited(_activate(id));
    _window.visible.addListener(_onVisible);
    deskHideToTray = _hide;
    ref.listenManual(deskLocalNodeProvider, (_, _) => _changed());
    ref.listenManual(settingsPrefsProvider.select((p) => (p.nodeBackground, p.builtin)), (_, _) => _changed());
    ref.listenManual(deskProvider.select((s) => (s.status, s.settings)), (_, _) => _changed());
    ref.listenManual(deskNavProvider.select((n) => n.route.bare), (_, _) => _changed());
  }

  @override
  void dispose() {
    _window.visible.removeListener(_onVisible);
    deskHideToTray = () async => false;
    _host.onClick = null;
    _host.onActivate = null;
    // Never a hidden window without its icon.
    if (_hidden) unawaited(_window.show());
    unawaited(_host.remove());
    super.dispose();
  }

  TrayFacts _facts() {
    final prefs = ref.read(settingsPrefsProvider);
    final desk = ref.read(deskProvider);
    final unlocked = !ref.read(deskNavProvider).route.bare;
    return TrayFacts(
      node: ref.read(deskLocalNodeProvider).value,
      background: prefs.nodeBackground,
      unlocked: unlocked,
      settings: desk.settings,
      status: unlocked ? desk.status : null,
    );
  }

  /// The window's close: to the tray when the rule says so, the icon first so the window never
  /// goes without a way back. False: the close goes on as before.
  Future<bool> _hide() async {
    if (_hidden) return true;
    final prefs = ref.read(settingsPrefsProvider);
    final node = ref.read(deskLocalNodeProvider).value;
    final background = DeskFeatures.nodeBackground && prefs.nodeBackground;
    if (!hidesOnClose(builtin: prefs.builtin, background: background, node: node, trayAvailable: true)) return false;
    if (!await _host.check()) {
      logInfo('tray', 'no tray on this desktop; closing');
      return false;
    }
    _hidden = true;
    _drawing = true;
    _sizes = null;
    try {
      final view = await _view();
      await _host.show(view);
      _shown = view;
    } on Object catch (e, stack) {
      logError('tray', 'icon not shown: ${e.runtimeType}', stack);
      _hidden = false;
      _shown = null;
      unawaited(_host.remove());
      return false;
    } finally {
      _drawing = false;
    }
    await _window.hide();
    logInfo('tray', 'window hidden; the node syncs in the background');
    if (_again) unawaited(_draw());
    return true;
  }

  Future<void> _open() async {
    await _window.show();
    _onVisible();
  }

  /// The window is back (Open wallet, the icon, a second start of the app): the icon goes.
  void _onVisible() {
    if (!_window.visible.value || !_hidden) return;
    _hidden = false;
    _shown = null;
    logInfo('tray', 'window shown');
    unawaited(_host.remove());
  }

  void _changed() {
    if (!_hidden) return;
    final prefs = ref.read(settingsPrefsProvider);
    final node = ref.read(deskLocalNodeProvider).value;
    // Sync in background turned off (in the tray or by a settings file edit), the built-in node
    // left or stopped: nothing runs in the background any more, so the window comes back. A
    // failed node stays in the tray with the problem mark.
    if (!prefs.nodeBackground || !prefs.builtin || node?.phase == LocalNodePhase.stopped) {
      unawaited(_open());
      return;
    }
    unawaited(_draw());
  }

  Future<void> _draw() async {
    if (_drawing) {
      _again = true;
      return;
    }
    _drawing = true;
    try {
      do {
        _again = false;
        if (!_hidden) return;
        final view = await _view();
        if (!_hidden || _same(view, _shown)) continue;
        await _host.show(view);
        _shown = view;
      } while (_again);
    } on Object catch (e, stack) {
      logError('tray', 'menu not updated: ${e.runtimeType}', stack);
    } finally {
      _drawing = false;
    }
  }

  static bool _same(TrayView a, TrayView? b) =>
      b != null &&
      a.title == b.title &&
      a.tooltip == b.tooltip &&
      a.attention == b.attention &&
      listEquals(a.icons, b.icons) &&
      listEquals(a.items, b.items) &&
      mapEquals(a.marks, b.marks);

  Future<TrayView> _view() async {
    // The app's language as last drawn; a hidden window draws nothing to read it from.
    final l = deskStrings;
    final f = _facts();
    final sizes = await (_sizes ??= _host.sizes());
    final mark = trayIconMark(l, f);
    final icons = <TrayImage>[];
    for (final s in sizes.icons) {
      icons.add(await trayIcon(s, mark));
    }
    final marks = <TrayMark, TrayImage>{};
    for (final m in TrayMark.values) {
      final image = await trayMarkImage(sizes.menu, m);
      if (image != null) marks[m] = image;
    }
    return TrayView(
      icons: icons,
      title: l.appTitle,
      tooltip: trayTooltip(l, f),
      attention: mark == TrayMark.problem,
      items: trayMenu(l, f),
      marks: marks,
    );
  }

  Future<void> _activate(String id) async {
    switch (id) {
      case TrayIds.background:
        // The same setting as Settings › Node › Sync in background; off brings the window back.
        final p = ref.read(settingsPrefsProvider);
        ref.read(settingsPrefsProvider.notifier).set(p.copyWith(nodeBackground: !p.nodeBackground));
      case TrayIds.epicbox:
        await _epicbox();
      case TrayIds.open:
        await _open();
      case TrayIds.lock:
        if (!ref.read(deskNavProvider).route.bare) await lockWallet(ref);
      case TrayIds.quit:
        // A send running: the window comes back and asks, as its close does.
        if (ref.read(deskSendingProvider) > 0) await _open();
        logInfo('tray', 'quit');
        await deskClose(ref);
    }
  }

  /// Settings › Transactions › Epicbox › Receiving's switch, the same call.
  Future<void> _epicbox() async {
    final f = _facts();
    if (!f.unlocked || !f.epicboxMethod || f.status == null) return;
    final on = !f.epicboxListening;
    try {
      await ref.read(deskProvider.notifier).setEpicboxListening(on);
    } on Object catch (e) {
      // Said in the window, where the reason can be read.
      await _open();
      final c = deskNavigatorKey.currentContext;
      if (c != null && c.mounted) {
        final l = c.l10n;
        final name = methodLabel(l, TxMethod.epicbox);
        showEToast(c, on ? l.deskSetRecvMethodOnFailed(name) : l.deskSetRecvMethodOffFailed(name), text: deskErrorText(e, l), tone: ETone.risk);
      }
    }
    _changed();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
