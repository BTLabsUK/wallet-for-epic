// SPDX-License-Identifier: Apache-2.0
/// Where the window opens and how big it is. The first start opens at [deskWindowShare] of the
/// work area of the display the pointer is on (the display minus taskbars, docks and panels),
/// capped at [deskWindowMaxStart] and never under [deskWindowMinSize], centred. Afterwards the
/// last size, position and maximised state are kept per display ([WindowMemory], DeskStore
/// `desk.window`, for the app, not per wallet) and restored, unless the display is gone or the
/// saved frame no longer fits on it: then the first-start rule again.
///
/// All sizes are logical pixels, so the system's scale (150 % on Windows, Retina, GDK_SCALE)
/// keeps the same look; the app's own interface scale only scales what is inside.
///
/// Linux and macOS are placed from here before the first frame (Linux's runner shows the window
/// on its first frame; macOS's runner keeps it hidden until [placeDeskWindow] shows it). Windows'
/// runner places its window itself before creating it (windows/runner/window_placement.cpp, the
/// same numbers), so nothing moves there.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_log.dart';
import '../data/desk_store.dart';

/// The smallest window: the sidebar stays a rail (below 600 px the phone layout takes over), and
/// Send shows the recipient, the amount and Review without scrolling.
const deskWindowMinSize = Size(800, 700);

/// The largest first window: on a big display more room only spreads the content out.
const deskWindowMaxStart = Size(1600, 1000);

/// The share of the work area the first window takes, each way.
const deskWindowShare = 0.8;

/// One display, as the window sees it.
@immutable
class DeskDisplay {
  const DeskDisplay({required this.key, required this.work, this.scale = 1});

  /// Names the display across starts: the system's id where it gives one (macOS), else its
  /// name, size and where its work area starts (Linux gives no id).
  final String key;

  /// The work area in logical pixels, in the desktop's coordinates.
  final Rect work;

  /// Physical pixels per logical pixel.
  final double scale;

  @override
  String toString() => 'DeskDisplay($key, $work, x$scale)';
}

/// The window on one display: its frame when neither maximised nor minimised, and whether it
/// was maximised.
@immutable
class SavedWindow {
  const SavedWindow({required this.frame, this.maximized = false});

  final Rect frame;
  final bool maximized;

  static SavedWindow? fromJson(Object? j) {
    if (j is! Map) return null;
    final x = j['x'], y = j['y'], w = j['w'], h = j['h'];
    if (x is! num || y is! num || w is! num || h is! num || w <= 0 || h <= 0) return null;
    return SavedWindow(frame: Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()), maximized: j['max'] == true);
  }

  Map<String, Object> toJson() => {'x': frame.left, 'y': frame.top, 'w': frame.width, 'h': frame.height, 'max': maximized};

  @override
  bool operator ==(Object other) => other is SavedWindow && other.frame == frame && other.maximized == maximized;

  @override
  int get hashCode => Object.hash(frame, maximized);

  @override
  String toString() => 'SavedWindow($frame${maximized ? ', maximized' : ''})';
}

/// What is kept: the window per display, and the display it was on last.
@immutable
class WindowMemory {
  const WindowMemory({this.last, this.displays = const {}});

  static const empty = WindowMemory();

  final String? last;
  final Map<String, SavedWindow> displays;

  /// The window on [display] now; that display becomes the last one. Kept to [keep] displays,
  /// the oldest dropped first.
  WindowMemory withSaved(String display, SavedWindow saved, {int keep = 8}) {
    final next = {...displays}..remove(display);
    while (next.length >= keep) {
      next.remove(next.keys.first);
    }
    next[display] = saved;
    return WindowMemory(last: display, displays: next);
  }

  static WindowMemory fromJson(Object? j) {
    if (j is! Map) return empty;
    final shown = j['displays'];
    final displays = <String, SavedWindow>{};
    if (shown is Map) {
      for (final e in shown.entries) {
        final saved = SavedWindow.fromJson(e.value);
        if (e.key is String && saved != null) displays[e.key as String] = saved;
      }
    }
    final last = j['last'];
    return WindowMemory(last: last is String ? last : null, displays: displays);
  }

  Map<String, Object> toJson() => {
    'last': ?last,
    'displays': {for (final e in displays.entries) e.key: e.value.toJson()},
  };

  @override
  bool operator ==(Object other) => other is WindowMemory && other.last == last && mapEquals(other.displays, displays);

  @override
  int get hashCode => Object.hash(last, Object.hashAllUnordered(displays.entries.map((e) => Object.hash(e.key, e.value))));
}

/// Where the window opens.
@immutable
class WindowStart {
  const WindowStart({required this.display, required this.frame, this.maximized = false, this.restored = false});

  final DeskDisplay display;
  final Rect frame;
  final bool maximized;

  /// From [WindowMemory]; false for the first-start rule.
  final bool restored;

  @override
  String toString() => 'WindowStart(${display.key}, $frame${maximized ? ', maximized' : ''}${restored ? ', restored' : ''})';
}

/// [deskWindowMinSize], or the work area where that is smaller (a small display at a large scale).
Size deskWindowMinOn(DeskDisplay d) =>
    Size(math.min(deskWindowMinSize.width, d.work.width), math.min(deskWindowMinSize.height, d.work.height));

/// The first-start frame on [d]: [deskWindowShare] of the work area, at most [deskWindowMaxStart],
/// at least [deskWindowMinOn], centred, on whole physical pixels.
Rect firstStartFrame(DeskDisplay d) {
  final min = deskWindowMinOn(d);
  double side(double work, double least, double most) => (work * deskWindowShare).clamp(least, math.max(least, most)).toDouble();
  final w = _snap(side(d.work.width, min.width, deskWindowMaxStart.width), d.scale);
  final h = _snap(side(d.work.height, min.height, deskWindowMaxStart.height), d.scale);
  final left = _snap(d.work.left + (d.work.width - w) / 2, d.scale);
  final top = _snap(d.work.top + (d.work.height - h) / 2, d.scale);
  return Rect.fromLTWH(left, top, w, h);
}

/// [v] logical pixels rounded to whole physical ones.
double _snap(double v, double scale) {
  final s = scale > 0 ? scale : 1;
  return (v * s).roundToDouble() / s;
}

/// The display [frame] is on: the one holding its centre, else the one it overlaps most, else
/// null.
DeskDisplay? displayOf(Rect frame, List<DeskDisplay> displays) {
  for (final d in displays) {
    if (d.work.contains(frame.center)) return d;
  }
  DeskDisplay? best;
  var most = 0.0;
  for (final d in displays) {
    final i = d.work.intersect(frame);
    final area = i.width > 0 && i.height > 0 ? i.width * i.height : 0.0;
    if (area > most) {
      most = area;
      best = d;
    }
  }
  return best;
}

/// [saved] on [d], or null when it no longer fits there: its centre off the work area (the
/// layout changed) or larger than the work area (a smaller display, a larger scale). A frame
/// that sticks out a little is moved in; one under the minimum grows to it.
Rect? restoredFrame(SavedWindow saved, DeskDisplay d) {
  final f = saved.frame;
  const slack = 1.0;
  if (!d.work.contains(f.center) || f.width > d.work.width + slack || f.height > d.work.height + slack) return null;
  final min = deskWindowMinOn(d);
  final w = f.width.clamp(min.width, d.work.width).toDouble();
  final h = f.height.clamp(min.height, d.work.height).toDouble();
  final left = f.left.clamp(d.work.left, d.work.right - w).toDouble();
  final top = f.top.clamp(d.work.top, d.work.bottom - h).toDouble();
  return Rect.fromLTWH(left, top, w, h);
}

/// Where the window opens: the last display's saved window when that display is here and the
/// window still fits on it; else the saved window of [openOn] (the display the pointer is on);
/// else the first-start rule on the last display (when still here) or on [openOn]. A saved
/// maximised state is kept, with the restored frame under it.
WindowStart windowStart({required List<DeskDisplay> displays, required DeskDisplay openOn, WindowMemory memory = WindowMemory.empty}) {
  DeskDisplay? present(String? key) {
    if (key == null) return null;
    for (final d in displays) {
      if (d.key == key) return d;
    }
    return null;
  }

  final last = present(memory.last);
  for (final d in [?last, openOn]) {
    final saved = memory.displays[d.key];
    if (saved == null) continue;
    final frame = restoredFrame(saved, d);
    if (frame != null) return WindowStart(display: d, frame: frame, maximized: saved.maximized, restored: true);
  }
  final on = last ?? openOn;
  return WindowStart(display: on, frame: firstStartFrame(on), maximized: last != null && (memory.displays[last.key]?.maximized ?? false));
}

/// [d] as a [DeskDisplay].
DeskDisplay deskDisplayOf(Display d) {
  final origin = d.visiblePosition ?? Offset.zero;
  final size = d.visibleSize ?? d.size;
  final key = d.id.isNotEmpty
      ? d.id
      : '${d.name ?? ''}@${d.size.width.round()}x${d.size.height.round()}+${origin.dx.round()},${origin.dy.round()}';
  return DeskDisplay(key: key, work: origin & size, scale: (d.scaleFactor ?? 1).toDouble());
}

/// Places the window by [windowStart] and keeps where it goes ([DeskWindowKeeper]). Linux and
/// macOS only (Windows' runner does both); null elsewhere. [store] null (the mock build) places
/// by the first-start rule and keeps nothing. Never throws: a window that cannot be placed
/// opens where the runner put it. On macOS it shows the window, which the runner kept hidden.
Future<DeskWindowKeeper?> placeDeskWindow(DeskStore? store) async {
  if (kIsWeb || !(Platform.isLinux || Platform.isMacOS)) return null;
  DeskWindowKeeper? keeper;
  try {
    await windowManager.ensureInitialized();
    final displays = (await screenRetriever.getAllDisplays()).map(deskDisplayOf).toList();
    final cursor = await screenRetriever.getCursorScreenPoint();
    final openOn =
        displays.where((d) => d.work.contains(cursor)).firstOrNull ?? deskDisplayOf(await screenRetriever.getPrimaryDisplay());
    var memory = WindowMemory.empty;
    if (store != null) {
      try {
        memory = WindowMemory.fromJson(await store.readJson(DeskStore.windowKey));
      } on Object catch (e) {
        logWarn('desk', 'window place not read: ${e.runtimeType}');
      }
    }
    final start = windowStart(displays: displays.isEmpty ? [openOn] : displays, openOn: openOn, memory: memory);
    String wh(Size s) => '${s.width.round()}x${s.height.round()}';
    logInfo('desk', 'window ${start.restored ? 'restored' : 'first start'}: ${wh(start.frame.size)} on ${wh(start.display.work.size)} x${start.display.scale}');
    await windowManager.setMinimumSize(deskWindowMinOn(start.display));
    await windowManager.setBounds(start.frame);
    if (start.maximized) await windowManager.maximize();
    if (store != null) keeper = DeskWindowKeeper(store, memory)..listen();
  } on Object catch (e, stack) {
    logError('desk', 'window not placed: ${e.runtimeType}', stack);
  } finally {
    if (Platform.isMacOS) await showDeskWindow();
  }
  return keeper;
}

/// Shows the window macOS' runner keeps hidden at launch (MainFlutterWindow); also on a start
/// that failed before the window was placed, so it never stays invisible.
Future<void> showDeskWindow() async {
  if (kIsWeb || !Platform.isMacOS) return;
  try {
    await windowManager.show();
  } on Object catch (e) {
    logWarn('desk', 'window not shown: ${e.runtimeType}');
  }
}

/// Keeps the window's place: [delay] after it stops moving or resizing, and once more when the
/// app closes ([save]). Only what changed is written.
class DeskWindowKeeper with WindowListener {
  DeskWindowKeeper(this._store, this._memory, {this.delay = const Duration(seconds: 1)});

  final DeskStore _store;
  WindowMemory _memory;
  final Duration delay;
  Timer? _timer;
  Future<void>? _saving;

  WindowMemory get memory => _memory;

  void listen() => windowManager.addListener(this);

  void _later() {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(save()));
  }

  /// Writes where the window is now, if that changed.
  Future<void> save() async {
    _timer?.cancel();
    final running = _saving;
    if (running != null) await running;
    final next = _saving = _save();
    try {
      await next;
    } finally {
      if (identical(_saving, next)) _saving = null;
    }
  }

  Future<void> _save() async {
    try {
      // Minimised or full screen: nothing to keep from now.
      if (await windowManager.isMinimized() || await windowManager.isFullScreen()) return;
      final maximized = await windowManager.isMaximized();
      final displays = (await screenRetriever.getAllDisplays()).map(deskDisplayOf).toList();
      final bounds = await windowManager.getBounds();
      final display = displayOf(bounds, displays);
      if (display == null) return;
      // Maximised: the frame under it stays as saved (or the first-start one).
      final frame = maximized ? (_memory.displays[display.key]?.frame ?? firstStartFrame(display)) : bounds;
      final next = _memory.withSaved(display.key, SavedWindow(frame: frame, maximized: maximized));
      if (next == _memory) return;
      await _store.writeJson(DeskStore.windowKey, next.toJson());
      _memory = next;
    } on Object catch (e) {
      logWarn('desk', 'window place not saved: ${e.runtimeType}');
    }
  }

  @override
  void onWindowResize() => _later();

  @override
  void onWindowResized() => _later();

  @override
  void onWindowMove() => _later();

  @override
  void onWindowMoved() => _later();

  @override
  void onWindowMaximize() => _later();

  @override
  void onWindowUnmaximize() => _later();
}
