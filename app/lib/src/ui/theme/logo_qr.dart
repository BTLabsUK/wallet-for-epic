// SPDX-License-Identifier: Apache-2.0
/// Every QR code the wallet shows, in one look (the epic1 brand pack's QR, `~/epic1-branding`,
/// the promo): square dots with small gaps, rounded finder squares, error correction level H,
/// and a logo on a clear patch in the centre. epic1 codes (links, in-person codes and answers,
/// pairing and device invites) carry the block 1 of the epic1 mark in amber; the rest
/// (addresses, the phrase, payment files) carry the BT Wallet mark in ink.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'brand.dart' show paintBtMark;
import 'palette.dart';

/// The logo in a [LogoQr]'s centre.
enum QrLogo {
  /// The BT Wallet mark ([paintBtMark]), in ink: the brand kit's rule for light ground.
  bt(PaletteLight.text, PaletteLight.text),

  /// The block 1 of the epic1 mark, in the epic1 pack's amber, with its ink.
  epic1(PaletteEpic1.ink, PaletteEpic1.amber);

  const QrLogo(this.ink, this.mark);

  /// The modules' colour.
  final Color ink;

  /// The logo's colour.
  final Color mark;
}

/// A QR code of [data] at error correction level H with [logo] in its centre, ink on white.
/// The clear patch is [patchFraction] of the code's width (about 8 % of its modules, well
/// inside the 30 % level H restores). The caller puts it on white with a margin, so it scans in
/// either theme. Decorative to screen readers; label it where it is used.
class LogoQr extends StatefulWidget {
  const LogoQr({super.key, required this.data, required this.size, this.logo = QrLogo.bt});

  /// What the code holds, in full.
  final String data;

  /// Width and height in logical pixels.
  final double size;

  final QrLogo logo;

  /// The clear patch's side, as a share of the code's width (rounded down to an odd number of
  /// modules, so it sits on the module grid around the centre).
  static const double patchFraction = 0.3;

  /// The error correction level of every code it draws.
  static const int errorCorrectLevel = QrErrorCorrectLevel.H;

  /// The modules the patch covers on a code [moduleCount] wide: an odd number, at least 5.
  static int patchModules(int moduleCount) {
    var k = (moduleCount * patchFraction).floor();
    if (k.isEven) k -= 1;
    return math.max(5, k);
  }

  @override
  State<LogoQr> createState() => _LogoQrState();
}

class _LogoQrState extends State<LogoQr> {
  late QrImage _image = _encode();

  QrImage _encode() => QrImage(QrCode.fromData(data: widget.data, errorCorrectLevel: LogoQr.errorCorrectLevel));

  @override
  void didUpdateWidget(LogoQr old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _image = _encode();
  }

  @override
  Widget build(BuildContext context) => LogoQrImage(image: _image, size: widget.size, logo: widget.logo);
}

/// An encoded QR [image] in the [LogoQr] look, for frames of an animated code (`QrFrames`).
class LogoQrImage extends StatelessWidget {
  const LogoQrImage({super.key, required this.image, required this.size, this.logo = QrLogo.bt});

  final QrImage image;
  final double size;
  final QrLogo logo;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: LogoQrPainter(image, logo),
        ),
      ),
    );
  }
}

/// Paints a [LogoQr] to fill its box. The background stays as the caller paints it (white).
class LogoQrPainter extends CustomPainter {
  LogoQrPainter(this.image, this.logo);

  final QrImage image;
  final QrLogo logo;

  @override
  void paint(Canvas canvas, Size size) =>
      paintLogoQr(canvas, image, logo: logo, origin: Offset.zero, module: size.shortestSide / image.moduleCount);

  @override
  bool shouldRepaint(LogoQrPainter old) => old.image != image || old.logo != logo;
}

/// The epic1 mark's grid (brand pack `tokens.json`); columns 0 to 2 are the 1.
const List<String> _epic1Grid = ['.#..#..', '##....#', '.#.#...', '.#...#.', '###.#..'];

/// The block 1's height, as a share of the patch's side.
const double _epic1MarkFraction = 0.72;

/// The BT Wallet mark's width, as a share of the patch's side.
const double _btMarkFraction = 0.8;

/// Paints [image] in the [LogoQr] look with its top left at [origin], each module [module]
/// wide, and [logo] in the clear patch. No quiet zone: the caller leaves it.
void paintLogoQr(Canvas canvas, QrImage image, {required QrLogo logo, required Offset origin, required double module}) {
  final n = image.moduleCount;
  final m = module;
  final ink = Paint()..color = logo.ink;
  final ring = Paint()
    ..color = logo.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = m;

  // The clear patch, in modules, centred on the middle module.
  final mid = n ~/ 2;
  final half = LogoQr.patchModules(n) ~/ 2;
  bool inPatch(int r, int c) => (r - mid).abs() <= half && (c - mid).abs() <= half;

  // Finder squares: the three 7 x 7 corners.
  bool inFinder(int r, int c) => (r < 7 && c < 7) || (r < 7 && c >= n - 7) || (r >= n - 7 && c < 7);

  // Alignment squares (version 2 up) that clear the finders and the patch.
  final pos = _alignment[image.typeNumber - 1];
  final drawn = <(int, int)>[];
  for (final r in pos) {
    for (final c in pos) {
      if (inFinder(r - 2, c - 2) || inFinder(r + 2, c - 2) || inFinder(r - 2, c + 2)) continue;
      if ((r - mid).abs() <= half + 2 && (c - mid).abs() <= half + 2) continue;
      drawn.add((r, c));
    }
  }
  bool inAlign(int r, int c) => drawn.any((a) => (r - a.$1).abs() <= 2 && (c - a.$2).abs() <= 2);

  Rect cell(double c, double r, double w, double h) => Rect.fromLTWH(origin.dx + c * m, origin.dy + r * m, w * m, h * m);

  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (!image.isDark(r, c) || inFinder(r, c) || inPatch(r, c) || inAlign(r, c)) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(cell(c + .06, r + .06, .88, .88), Radius.circular(.22 * m)), ink);
    }
  }

  for (final (oc, or) in [(0, 0), (n - 7, 0), (0, n - 7)]) {
    canvas.drawRRect(RRect.fromRectAndRadius(cell(oc + .5, or + .5, 6, 6), Radius.circular(1.7 * m)), ring);
    canvas.drawRRect(RRect.fromRectAndRadius(cell(oc + 2.0, or + 2.0, 3, 3), Radius.circular(.8 * m)), ink);
  }
  for (final (r, c) in drawn) {
    canvas.drawRRect(RRect.fromRectAndRadius(cell(c - 1.5, r - 1.5, 4, 4), Radius.circular(1.1 * m)), ring);
    canvas.drawRect(cell(c.toDouble(), r.toDouble(), 1, 1), ink);
  }

  final patchSide = (2 * half + 1) * m;
  final centre = origin + Offset((mid + .5) * m, (mid + .5) * m);
  final mark = Paint()..color = logo.mark;
  switch (logo) {
    case QrLogo.bt:
      final w = patchSide * _btMarkFraction;
      paintBtMark(canvas, Rect.fromCenter(center: centre, width: w, height: w), mark);
    case QrLogo.epic1:
      // The block 1: a 3 x 5 grid of 10-unit cells, 9-unit blocks, centred in the patch.
      final unit = patchSide * _epic1MarkFraction / 49;
      final x0 = centre.dx - 14.5 * unit;
      final y0 = centre.dy - 24.5 * unit;
      for (var y = 0; y < _epic1Grid.length; y++) {
        for (var x = 0; x < 3; x++) {
          if (_epic1Grid[y][x] != '#') continue;
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x0 + x * 10 * unit, y0 + y * 10 * unit, 9 * unit, 9 * unit), Radius.circular(.6 * unit)),
            mark,
          );
        }
      }
  }
}

/// Alignment pattern centres per version (ISO/IEC 18004 Annex E), version 1 first.
const List<List<int>> _alignment = [
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
  [6, 28, 50, 72, 94],
  [6, 26, 50, 74, 98],
  [6, 30, 54, 78, 102],
  [6, 28, 54, 80, 106],
  [6, 32, 58, 84, 110],
  [6, 30, 58, 86, 114],
  [6, 34, 62, 90, 118],
  [6, 26, 50, 74, 98, 122],
  [6, 30, 54, 78, 102, 126],
  [6, 26, 52, 78, 104, 130],
  [6, 30, 56, 82, 108, 134],
  [6, 34, 60, 86, 112, 138],
  [6, 30, 58, 86, 114, 142],
  [6, 34, 62, 90, 118, 146],
  [6, 30, 54, 78, 102, 126, 150],
  [6, 24, 50, 76, 102, 128, 154],
  [6, 28, 54, 80, 106, 132, 158],
  [6, 32, 58, 84, 110, 136, 162],
  [6, 26, 54, 82, 110, 138, 166],
  [6, 30, 58, 86, 114, 142, 170],
];
