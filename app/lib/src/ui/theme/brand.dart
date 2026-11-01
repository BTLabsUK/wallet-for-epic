// SPDX-License-Identifier: Apache-2.0
/// The wallet's identity: the Epic Cash mark, the framed tile that carries it (or an icon) on
/// hero screens, the lit backdrop behind those screens, and the empty state built from them.
/// They reuse the Protocol devices in `protocol.dart` (grid, corner ticks), so every hero screen
/// reads as the same instrument.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../balanced_text.dart';
import 'protocol.dart';
import 'tokens.dart';

/// The Epic Cash mark, from `docs/themes/epic-mark.svg` (a 281 x 324 view box). Drawn as a
/// path, so it needs no image asset or SVG package, and stays sharp at any size.
class EpicMark extends StatelessWidget {
  const EpicMark({super.key, this.size = 32, this.color});

  /// Height in logical pixels; the width follows the mark's proportions.
  final double size;

  /// Defaults to the accent: gold in dark mode, the AA brown in light mode.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = color ?? t.accent;
    // Dark mode shades the gold down to the ticks' deeper gold, like a lit metal edge.
    final bottom = color ?? (dark ? t.tick : t.accent);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size * _EpicMarkPainter.aspect, size),
        painter: _EpicMarkPainter(top, bottom),
      ),
    );
  }
}

class _EpicMarkPainter extends CustomPainter {
  const _EpicMarkPainter(this.top, this.bottom);

  final Color top;
  final Color bottom;

  static const double _w = 281, _h = 324;
  static const double aspect = _w / _h;

  static final List<Path> _parts = [
    Path()
      ..moveTo(253.678, 72.443)
      ..cubicTo(256.503, 70.801, 256.503, 66.729, 253.678, 65.152)
      ..lineTo(225.895, 49.126)
      ..cubicTo(224.581, 48.404, 223.005, 48.404, 221.691, 49.126)
      ..lineTo(202.644, 60.095)
      ..lineTo(238.966, 81.047)
      ..close(),
    Path()
      ..moveTo(83.759, 131.031)
      ..lineTo(83.759, 163.806)
      ..cubicTo(83.759, 167.09, 87.306, 169.126, 90.13, 167.484)
      ..lineTo(232.528, 84.725)
      ..lineTo(196.206, 63.773)
      ..lineTo(85.861, 127.419)
      ..cubicTo(84.547, 128.141, 83.759, 129.52, 83.759, 131.031)
      ..close(),
    Path()
      ..moveTo(111.084, 211.36)
      ..lineTo(140.115, 228.108)
      ..cubicTo(141.429, 228.831, 143.005, 228.831, 144.319, 228.108)
      ..lineTo(253.482, 165.12)
      ..lineTo(253.482, 121.244)
      ..lineTo(111.084, 204.003)
      ..cubicTo(108.26, 205.645, 108.325, 209.717, 111.084, 211.36)
      ..close(),
    Path()
      ..moveTo(278.899, 150.473)
      ..cubicTo(280.213, 149.75, 281.001, 148.305, 281.001, 146.795)
      ..lineTo(281.001, 112.64)
      ..cubicTo(281.001, 109.356, 277.454, 107.32, 274.63, 108.962)
      ..lineTo(259.917, 117.501)
      ..lineTo(259.917, 161.376)
      ..close(),
    Path()
      ..moveTo(140.705, 323.544)
      ..lineTo(181.034, 300.293)
      ..lineTo(280.673, 242.756)
      ..lineTo(280.673, 196.187)
      ..lineTo(253.546, 211.82)
      ..lineTo(176.961, 256.023)
      ..lineTo(140.705, 276.976)
      ..lineTo(41.131, 219.504)
      ..lineTo(41.131, 104.561)
      ..lineTo(153.973, 39.405)
      ..lineTo(181.034, 23.773)
      ..lineTo(140.705, 0.456)
      ..lineTo(0.803, 81.244)
      ..lineTo(0.803, 242.756)
      ..close(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);
    // In view-box units, since the shader is set up after the scale.
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, _h), [
        top,
        bottom,
      ]);
    for (final part in _parts) {
      canvas.drawPath(part, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EpicMarkPainter old) =>
      old.top != top || old.bottom != bottom;
}

/// Which app a [BrandWordmark] names.
enum BrandVariant {
  desktop('Desktop'),
  mobile('Mobile');

  const BrandVariant(this.word);

  /// The platform word under "Epic Cash". A brand name: never translated.
  final String word;
}

/// The product wordmark: "Epic Cash" in the mark's gold, and under it the platform word in
/// grey, smaller, uppercase and tracked, aligned to the right edge of "Epic Cash" (at half
/// the size it would need a letter-spacing of a third of an em to match the width, which
/// falls apart below 24 px; the right edge keeps one relation at every size). [size] is the
/// font size of "Epic Cash"; the platform word is [secondRatio] of it, never under 9 px.
/// One semantics node with the full product name, so a reader hears "Epic Cash Desktop",
/// not two lines. Colours: the gold gradient of [EpicMark] in dark mode, the AA brown in
/// light mode, or [color] for both; the second line takes [secondColor] or the dim text.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    required this.variant,
    this.size = 24,
    this.color,
    this.secondColor,
    this.label,
  });

  final BrandVariant variant;

  /// The font size of "Epic Cash", in logical pixels.
  final double size;

  /// A flat colour for "Epic Cash" instead of the gold gradient.
  final Color? color;

  /// The platform word's colour; dim text by default.
  final Color? secondColor;

  /// What screen readers get; the full product name by default.
  final String? label;

  /// The first line, the brand. Never translated.
  static const String brand = 'Epic Cash';

  /// The platform word's size as a share of [size].
  static const double secondRatio = 0.5;

  /// Space between the lines, as a share of [size].
  static const double gapRatio = 0.12;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = color ?? t.accent;
    final bottom = color ?? (dark ? t.tick : t.accent);
    final second = (size * secondRatio).clamp(9.0, double.infinity);
    final first = Text(
      brand,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontFamily: t.headFamily,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1.1,
        letterSpacing: size * -0.02,
        color: top,
      ),
    );
    return Semantics(
      label: label ?? '$brand ${variant.word}',
      excludeSemantics: true,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (color != null)
              first
            else
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => ui.Gradient.linear(
                  bounds.topLeft,
                  bounds.bottomLeft,
                  [top, bottom],
                ),
                child: first,
              ),
            SizedBox(height: size * gapRatio),
            Text(
              variant.word.toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: t.headFamily,
                fontWeight: FontWeight.w600,
                fontSize: second,
                height: 1.1,
                letterSpacing: second * 0.14,
                color: secondColor ?? t.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The mark beside the wordmark, as the sidebar and the phone's app bar show them. [size]
/// is the mark's height; the wordmark's "Epic Cash" takes [textRatio] of it.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    required this.variant,
    this.size = 32,
    this.textRatio = 0.6,
    this.color,
    this.label,
  });

  final BrandVariant variant;
  final double size;
  final double textRatio;

  /// A flat colour for the mark and "Epic Cash" instead of the gradient.
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? '${BrandWordmark.brand} ${variant.word}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EpicMark(size: size, color: color),
          SizedBox(width: size * 0.34),
          BrandWordmark(variant: variant, size: size * textRatio, color: color),
        ],
      ),
    );
  }
}

/// A QR code of [data] at error correction level H, with the [EpicMark] on a small white tile
/// in its centre. The tile is [markFraction] of the code's width, so it hides about 4 % of the
/// modules, well inside the 30 % level H restores. Dark modules for white paper: the caller
/// puts it on white with a quiet zone, so it scans in either theme. Decorative to screen
/// readers; label it where it is used.
class MarkedQr extends StatefulWidget {
  const MarkedQr({super.key, required this.data, required this.size});

  /// What the code holds, in full.
  final String data;

  /// Width and height in logical pixels.
  final double size;

  /// The mark's tile, as a share of the code's width. At most a fifth.
  static const double markFraction = 0.2;

  /// The error correction level of every code it draws.
  static const int errorCorrectLevel = QrErrorCorrectLevel.H;

  @override
  State<MarkedQr> createState() => _MarkedQrState();
}

class _MarkedQrState extends State<MarkedQr> {
  late QrImage _image = _encode();

  QrImage _encode() => QrImage(
    QrCode.fromData(
      data: widget.data,
      errorCorrectLevel: MarkedQr.errorCorrectLevel,
    ),
  );

  @override
  void didUpdateWidget(MarkedQr old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _image = _encode();
  }

  @override
  Widget build(BuildContext context) {
    // The paper is white in both themes, so the mark takes the light theme's accent.
    const paper = protocolLight;
    final tile = widget.size * MarkedQr.markFraction;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: PrettyQrView(
                qrImage: _image,
                decoration: PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(color: paper.text),
                ),
              ),
            ),
            Container(
              width: tile,
              height: tile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: paper.surface,
                borderRadius: BorderRadius.circular(tile * 0.18),
              ),
              child: EpicMark(size: tile * 0.68, color: paper.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A square instrument tile: panel fill, the fading grid, corner ticks, and in dark mode a soft
/// gold light around it. Holds the [EpicMark] on hero screens, or an icon on result and empty
/// screens. Decorative: give the screen's meaning in text next to it.
class GlyphTile extends StatelessWidget {
  const GlyphTile({super.key, required this.child, this.size = 88});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
          boxShadow: [
            BoxShadow(
              color: t.accent.withValues(alpha: dark ? 0.18 : 0.10),
              blurRadius: size * 0.45,
              spreadRadius: -size * 0.06,
            ),
          ],
        ),
        child: CustomPaint(
          painter: GridFieldPainter(
            t.text.withValues(alpha: dark ? 0.06 : 0.07),
            step: size / 6,
          ),
          foregroundPainter: CornerTicksPainter(t.tick, length: size / 9),
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: t.accentText, size: size * 0.4),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark in its tile, the [wordmark] under it, then [title] as the screen's heading. Tops
/// the screens that open the app: launch (the wordmark alone), first run and unlock.
class BrandHero extends StatelessWidget {
  const BrandHero({super.key, this.title, this.wordmark = BrandVariant.mobile})
    : assert(title != null || wordmark != null);

  /// The screen's heading; none on launch, where the wordmark is the heading.
  final String? title;

  /// The product's wordmark under the tile; null leaves the tile and the title alone.
  final BrandVariant? wordmark;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final wordmark = this.wordmark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const GlyphTile(size: 96, child: EpicMark(size: 50)),
        if (wordmark != null) ...[
          const SizedBox(height: 18),
          Semantics(
            header: title == null,
            child: BrandWordmark(variant: wordmark, size: 26),
          ),
        ],
        if (title != null) ...[
          SizedBox(height: wordmark == null ? 20 : 22),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ],
    );
  }
}

/// Where the backdrop's light sits on a centred hero screen: on the tile above the middle.
const Alignment heroGlow = Alignment(0, -0.4);

/// Where it sits on a screen that leads with its top, such as Home's balance.
const Alignment topGlow = Alignment(0, -0.9);

/// The background of a hero screen: [WalletTokens.bg], a pool of accent light at [focus], and
/// the measurement grid fading out from it. With [breath] (0 at full light, 1 at the faintest)
/// the light fades to 55 %; the painter repaints on its own as it moves.
class ProtocolBackdropPainter extends CustomPainter {
  const ProtocolBackdropPainter({
    required this.bg,
    required this.glow,
    required this.grid,
    required this.focus,
    this.step = 28,
    this.breath,
  }) : super(repaint: breath);

  final Color bg;
  final Color glow;
  final Color grid;
  final Alignment focus;
  final double step;
  final Animation<double>? breath;

  /// [glow] as it is painted now, faded by [breath].
  Color get glowNow {
    final b = breath;
    if (b == null) return glow;
    return glow.withValues(alpha: glow.a * (1 - 0.45 * Curves.easeInOut.transform(b.value)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = focus.withinRect(rect);
    final glow = glowNow;
    canvas.drawRect(rect, Paint()..color = bg);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(center, size.shortestSide * 0.95, [
          glow,
          glow.withValues(alpha: 0),
        ]),
    );
    final lines = Paint()
      ..strokeWidth = 1
      ..shader = ui.Gradient.radial(center, size.shortestSide * 0.8, [
        grid,
        grid.withValues(alpha: 0),
      ]);
    // Lines are aligned on the focus, so the grid looks centred on the hero.
    final x0 = center.dx % step, y0 = center.dy % step;
    for (var x = x0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lines);
    }
    for (var y = y0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }
  }

  @override
  bool shouldRepaint(ProtocolBackdropPainter old) =>
      old.bg != bg ||
      old.glow != glow ||
      old.grid != grid ||
      old.focus != focus ||
      old.step != step ||
      old.breath != breath;
}

/// Paints [ProtocolBackdropPainter] behind [child] with the active tokens, and makes the
/// scaffold and app bar inside see-through so the light runs under the status bar. With
/// [breathing] the light swells and fades slowly (3.2 s a breath, between 55 % and full) for a
/// few breaths, as home does once the node starts syncing, then stays full: a light that
/// breathes for a whole sync redraws the screen for minutes. With reduced motion it stays full;
/// a new [breathing] stretch breathes again. Only the light repaints as it moves: [child] sits
/// on its own layer.
class ProtocolBackdrop extends StatefulWidget {
  const ProtocolBackdrop({
    super.key,
    required this.focus,
    required this.child,
    this.breathing = false,
  });

  final Alignment focus;
  final Widget child;
  final bool breathing;

  @override
  State<ProtocolBackdrop> createState() => _ProtocolBackdropState();
}

/// The key of the backdrop's paint, for tests.
const Key backdropPaintKey = ValueKey('protocol-backdrop');

/// Breaths the backdrop takes before it holds still: five, 16 s.
@visibleForTesting
const int backdropBreaths = 5;

class _ProtocolBackdropState extends State<ProtocolBackdrop>
    with SingleTickerProviderStateMixin {
  /// 0 at full light, 1 at the faintest.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )
    // The breaths end at full light: a frame that lands past the last one could leave the
    // value part way down.
    ..addStatusListener((status) {
      if (!_breath.isAnimating &&
          (status == AnimationStatus.completed || status == AnimationStatus.dismissed)) {
        _breath.value = 0;
      }
    });

  /// The breaths ran for this breathing stretch.
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ProtocolBackdrop old) {
    super.didUpdateWidget(old);
    if (!widget.breathing) _played = false;
    _sync();
  }

  void _sync() {
    final run = widget.breathing && !MediaQuery.disableAnimationsOf(context);
    if (run && !_played) {
      _played = true;
      // Fade and swell is one breath: an even count ends at full light.
      _breath
        ..value = 0
        ..repeat(reverse: true, count: backdropBreaths * 2);
    } else if (!run && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final clear = t.bg.withValues(alpha: 0);
    final glow = dark ? 0.13 : 0.08;
    return CustomPaint(
      key: backdropPaintKey,
      painter: ProtocolBackdropPainter(
        bg: t.bg,
        glow: t.accent.withValues(alpha: glow),
        grid: t.text.withValues(alpha: dark ? 0.05 : 0.06),
        focus: widget.focus,
        breath: _breath,
      ),
      child: RepaintBoundary(
        child: Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: clear,
            appBarTheme: theme.appBarTheme.copyWith(backgroundColor: clear),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// What a list shows when it has nothing: a tile with [icon], [message], and an optional
/// [action] that gets something into it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final Widget icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphTile(size: 72, child: icon),
          const SizedBox(height: 20),
          BalancedText(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action case final action?) ...[
            const SizedBox(height: 20),
            action,
          ],
        ],
      ),
    );
  }
}
