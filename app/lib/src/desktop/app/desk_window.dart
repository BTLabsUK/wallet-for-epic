// SPDX-License-Identifier: Apache-2.0
/// The app's own window: no system title bar, so the title bar (title_bar.dart) moves, sizes and
/// closes it through this. The OS keeps what it can: Windows the frame, shadow, rounding and
/// snapping; Linux has no frame at all once the title is hidden, so the app draws a border and
/// resize edges ([DeskWindowFrame]).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snap_layouts/snap_layouts.dart';
import 'package:window_manager/window_manager.dart';

/// Which window controls the bar draws: Windows' three on the right, round GNOME-style ones,
/// or room for the macOS traffic lights on the left (the system draws those).
enum DeskWindowStyle { windows, linux, mac }

/// The style of this computer; the tests and the tour shots run as Linux.
DeskWindowStyle get deskWindowStyle => switch (defaultTargetPlatform) {
  TargetPlatform.windows => DeskWindowStyle.windows,
  TargetPlatform.macOS => DeskWindowStyle.mac,
  _ => DeskWindowStyle.linux,
};

/// What the bar shows of the window.
@immutable
class DeskWindowState {
  const DeskWindowState({this.maximized = false, this.focused = true});

  final bool maximized;

  /// False while another window has the focus: the bar and the page dim.
  final bool focused;

  DeskWindowState copyWith({bool? maximized, bool? focused}) =>
      DeskWindowState(maximized: maximized ?? this.maximized, focused: focused ?? this.focused);

  @override
  bool operator ==(Object other) => other is DeskWindowState && other.maximized == maximized && other.focused == focused;

  @override
  int get hashCode => Object.hash(maximized, focused);
}

/// The window behind the bar. [DeskWindow.none] does nothing: tests, the tour, the web build.
class DeskWindow {
  const DeskWindow();

  static const DeskWindow none = DeskWindow();

  /// The app draws the controls (the system title bar is hidden).
  bool get frameless => false;

  /// The app draws the border and the resize edges too (Linux: no frame from the system).
  bool get drawsFrame => false;

  ValueListenable<DeskWindowState> get state => _still;
  static final _still = ValueNotifier(const DeskWindowState());

  Future<void> minimize() async {}
  Future<void> toggleMaximize() async {}

  /// Moves the window with the pointer that is down now (the system does the rest: snapping,
  /// Wayland's compositor-driven move).
  Future<void> startDragging() async {}
  Future<void> startResizing(ResizeEdge edge) async {}

  /// The system's window menu (Windows: Alt+Space's menu) where the bar was right-clicked.
  Future<void> systemMenu() async {}

  /// Where the maximise button is, for Windows 11's snap layouts flyout (physical pixels of the
  /// window's client area).
  void maximizeButtonAt(Rect physical) {}

  /// The Windows 11 snap flyout's hover and click on the maximise button: while the pointer is
  /// on it the system has it, so Flutter sees neither.
  ValueListenable<bool> get snapHover => _noHover;
  static final _noHover = ValueNotifier(false);

  /// Called when the system asks the window to close (✕ of the taskbar, Alt+F4, the window
  /// menu); the app decides (close_guard.dart).
  set onCloseRequested(Future<void> Function()? run) {}

  /// Ends the process's window for good, after the app said yes.
  Future<void> destroy() async {}
}

/// The screenshot tour's window: the bar draws the window controls as on a real window, and
/// nothing moves.
class PictureDeskWindow extends DeskWindow {
  const PictureDeskWindow();

  @override
  bool get frameless => true;
}

/// The window the bar drives; main_desktop.dart puts in the real one.
final deskWindowProvider = Provider<DeskWindow>((ref) => DeskWindow.none);

/// The real window, through window_manager. Call [init] before the first frame.
class SystemDeskWindow extends DeskWindow with WindowListener, SnapLayoutsListener {
  SystemDeskWindow._();

  static SystemDeskWindow? _instance;

  /// Hides the system title bar and takes over closing. Null where the app keeps the system's
  /// title bar (macOS for now, any other platform).
  static Future<SystemDeskWindow?> init() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux)) return null;
    final w = _instance ??= SystemDeskWindow._();
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    // Every close the system asks for comes to onWindowClose, so a send is never cut off.
    await windowManager.setPreventClose(true);
    windowManager.addListener(w);
    w._state.value = DeskWindowState(maximized: await windowManager.isMaximized(), focused: await windowManager.isFocused());
    if (Platform.isWindows) snapLayouts.addListener(w);
    return w;
  }

  final _state = ValueNotifier(const DeskWindowState());
  final _hover = ValueNotifier(false);
  Future<void> Function()? _onClose;

  @override
  bool get frameless => true;

  @override
  bool get drawsFrame => Platform.isLinux;

  @override
  ValueListenable<DeskWindowState> get state => _state;

  @override
  ValueListenable<bool> get snapHover => _hover;

  @override
  set onCloseRequested(Future<void> Function()? run) => _onClose = run;

  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Future<void> startDragging() => windowManager.startDragging();

  @override
  Future<void> startResizing(ResizeEdge edge) => windowManager.startResizing(edge);

  @override
  Future<void> systemMenu() async {
    if (Platform.isWindows) await windowManager.popUpWindowMenu();
  }

  Rect? _maxButton;

  @override
  void maximizeButtonAt(Rect physical) {
    if (!Platform.isWindows || physical == _maxButton) return;
    _maxButton = physical;
    unawaited(
      snapLayouts.updateSnapLayoutsRect(
        left: physical.left.round(),
        top: physical.top.round(),
        right: physical.right.round(),
        bottom: physical.bottom.round(),
      ),
    );
  }

  @override
  Future<void> destroy() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    final run = _onClose;
    if (run == null) {
      unawaited(destroy());
    } else {
      unawaited(run());
    }
  }

  @override
  void onWindowFocus() => _state.value = _state.value.copyWith(focused: true);

  @override
  void onWindowBlur() => _state.value = _state.value.copyWith(focused: false);

  @override
  void onWindowMaximize() => _state.value = _state.value.copyWith(maximized: true);

  @override
  void onWindowUnmaximize() => _state.value = _state.value.copyWith(maximized: false);

  // A snap from the flyout or an edge, a restore from the taskbar: read it back.
  @override
  void onWindowResized() => unawaited(_reread());

  @override
  void onWindowRestore() => unawaited(_reread());

  Future<void> _reread() async => _state.value = _state.value.copyWith(maximized: await windowManager.isMaximized());

  // Windows 11 snap layouts: the system holds the pointer over the maximise button.
  @override
  void onSnapLayoutsLocate() {
    final r = _maxButton;
    _maxButton = null;
    if (r != null) maximizeButtonAt(r);
  }

  @override
  void onSnapLayoutsHover() => _hover.value = true;

  @override
  void onSnapLayoutsLeave() => _hover.value = false;

  @override
  void onSnapLayoutsClick() => unawaited(toggleMaximize());
}
