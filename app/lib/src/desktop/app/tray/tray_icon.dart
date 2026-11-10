// SPDX-License-Identifier: Apache-2.0
/// The tray's pictures: the app's own icon (the Linux icon set, the same picture as Windows'
/// app_icon.ico) with the status mark in its corner, and the marks beside the menu lines. Drawn
/// once per size and mark, then kept.
library;

import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'tray_host.dart';
import 'tray_menu.dart';

/// The icon sizes the app ships (pubspec.yaml); the smallest one at least as large is scaled.
const List<int> _assetSizes = [16, 24, 32, 48, 64];

String _assetOf(int size) => 'linux/icons/hicolor/${size}x$size/apps/epic-cash-desktop.png';

// The app's status colours between its dark and light themes: the menus are the system's, light
// or dark.
const _ready = ui.Color(0xFF3DB25A);
const _busy = ui.Color(0xFF4C8FE0);
const _problem = ui.Color(0xFFE5484D);
const _ink = ui.Color(0xFF101014);
const _white = ui.Color(0xFFFFFFFF);

final _assets = <int, Future<ui.Image>>{};
final _icons = <(int, TrayMark), Future<TrayImage>>{};
final _marks = <(int, TrayMark), Future<TrayImage>>{};

Future<ui.Image> _asset(int size) {
  final pick = _assetSizes.firstWhere((s) => s >= size, orElse: () => _assetSizes.last);
  return _assets[pick] ??= () async {
    final data = await rootBundle.load(_assetOf(pick));
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    return (await codec.getNextFrame()).image;
  }();
}

Future<TrayImage> _render(int size, void Function(ui.Canvas c) draw) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(size, size);
  try {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return TrayImage(width: size, height: size, rgba: rgba!.buffer.asUint8List(), png: png!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

/// A mark in the circle at [c] of radius [r]: green solid ready, a blue ring in progress, red
/// with "!" a problem. [outline] puts a dark edge around it, for the icon's corner.
void _mark(ui.Canvas canvas, ui.Offset c, double r, TrayMark mark, {bool outline = false}) {
  if (mark == TrayMark.none) return;
  if (outline) canvas.drawCircle(c, r + r * 0.28, ui.Paint()..color = _ink);
  switch (mark) {
    case TrayMark.none:
      return;
    case TrayMark.ready:
      canvas.drawCircle(c, r, ui.Paint()..color = _ready);
    case TrayMark.busy:
      final w = r * 0.5;
      canvas.drawCircle(
        c,
        r - w / 2,
        ui.Paint()
          ..color = _busy
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = w,
      );
    case TrayMark.problem:
      canvas.drawCircle(c, r, ui.Paint()..color = _problem);
      final white = ui.Paint()..color = _white;
      final w = r * 0.36;
      canvas.drawRect(ui.Rect.fromLTRB(c.dx - w / 2, c.dy - r * 0.62, c.dx + w / 2, c.dy + r * 0.14), white);
      canvas.drawRect(ui.Rect.fromLTRB(c.dx - w / 2, c.dy + r * 0.34, c.dx + w / 2, c.dy + r * 0.34 + w), white);
  }
}

/// The app's icon at [size] pixels with [mark] in its lower right corner.
Future<TrayImage> trayIcon(int size, TrayMark mark) => _icons[(size, mark)] ??= () async {
  final app = await _asset(size);
  return _render(size, (c) {
    final s = size.toDouble();
    c.drawImageRect(
      app,
      ui.Rect.fromLTWH(0, 0, app.width.toDouble(), app.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final r = s * 0.22;
    _mark(c, ui.Offset(s - r * 1.1, s - r * 1.1), r, mark, outline: true);
  });
}();

/// The picture beside a menu line, [size] pixels square; none for [TrayMark.none].
Future<TrayImage?> trayMarkImage(int size, TrayMark mark) async {
  if (mark == TrayMark.none || size <= 0) return null;
  return _marks[(size, mark)] ??= _render(size, (c) {
    final s = size.toDouble();
    _mark(c, ui.Offset(s / 2, s / 2), s * 0.3, mark);
  });
}
