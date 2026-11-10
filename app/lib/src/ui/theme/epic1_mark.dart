// SPDX-License-Identifier: Apache-2.0
/// The epic1 logo from the epic1 branding pack (the Cipher route): "epic" in Red Hat Mono Bold,
/// then a 1 built from blocks on a 7 by 5 grid that breaks into noise to its right. Inside the
/// wallet it is always the one-colour version in the text colour, never the pack's accent.
/// [Epic1Mark] is the inline wordmark, sized from the text it sits in; [Epic1Glyph] is the
/// blocks alone, for icon slots; [Epic1Text] renders a string with the wordmark in place of its
/// plain "epic1" token. Notifications, exports, logs and search keep the plain token.
///
/// The wordmark is `assets/brand/epic1-wordmark.svg`: the pack's `epic1-wordmark-mono-ink.svg`
/// with `currentColor` for the ink and its box cut to the letters' advance (left) and the mark's
/// edge (right), from the dot of the i to the tail of the p. The blocks alone are painted from
/// the pack's grid ([Epic1Art.grid]).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tokens.dart';

/// The epic1 artwork: the wordmark file, its box in em of the letters, and the mark's grid.
abstract final class Epic1Art {
  static const String wordmark = 'assets/brand/epic1-wordmark.svg';

  /// The wordmark's box in em of its letters (the SVG's 100 units): four letters at 0.58,
  /// a 0.1 gap and the 0.73 em high mark.
  static const double width = 3.448;
  static const double height = 1.007;

  /// The baseline's distance from the box's top, in em.
  static const double baseline = 0.798;

  /// The mark's height, in em of the letters.
  static const double markHeight = 0.73;

  /// The rows of the 7 by 5 grid, top to bottom; `#` is a block. Columns 0 to 2 are the 1,
  /// columns 3 to 6 the noise.
  static const List<String> grid = ['.#..#..', '##....#', '.#.#...', '.#...#.', '###.#..'];

  /// The opacity of noise columns 3, 4, 5 and 6.
  static const List<double> noiseOpacity = [0.6, 0.45, 0.32, 0.22];

  /// A grid cell and the block in it, in grid units: a 1-unit gap between blocks.
  static const double cell = 10;
  static const double block = 9;

  /// Clear space on every side: two grid cells, in em of the letters.
  static const double clearSpace = 2 * cell * markHeight / (5 * cell - (cell - block));

  /// The family name, for screen readers and wherever the plain token stays. Never translated.
  static const String name = 'epic1';
}

/// The ink the marks take by default: the given colour, else the text token.
Color _ink(BuildContext context, Color? ink) => ink ?? context.tokens.text;

/// The inline epic1 wordmark. Its letters are set at [fontSize] and its baseline is the text's,
/// so in a row or a [WidgetSpan] it reads as a word. Below [minFontSize] the wordmark is not
/// used: it shows the 1 alone (grid columns 0 to 2), 0.73 em high on the baseline. One
/// semantics node labelled "epic1" unless [excludeSemantics].
class Epic1Mark extends StatelessWidget {
  const Epic1Mark({
    super.key,
    this.fontSize,
    this.color,
    this.excludeSemantics = false,
    this.scaleText = true,
    this.clearStart = 0,
    this.clearEnd = 0,
  });

  /// The letter size; the ambient [DefaultTextStyle]'s when null.
  final double? fontSize;

  /// The ink; the ambient text colour, else the text token.
  final Color? color;

  /// Leaves the label to an ancestor (a [Text] that carries the whole string).
  final bool excludeSemantics;

  /// Applies the platform text scale. Off inside a [WidgetSpan], which scales its child itself.
  final bool scaleText;

  /// Extra room before and after the wordmark, in em, so that with the neighbouring space it
  /// keeps [Epic1Art.clearSpace]; see [Epic1Text].
  final double clearStart;
  final double clearEnd;

  /// The smallest letter size for the wordmark (the pack's minimum). [Epic1Text] keeps the
  /// plain token below it.
  static const double minFontSize = 14;

  /// The wordmark's size for letters of [fontSize], unscaled.
  static Size sizeFor(double fontSize) => Size(Epic1Art.width * fontSize, Epic1Art.height * fontSize);

  /// The baseline's distance from the wordmark's top, for letters of [fontSize].
  static double baselineFor(double fontSize) => Epic1Art.baseline * fontSize;

  @override
  Widget build(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style;
    final base = fontSize ?? ambient.fontSize ?? 14;
    final size = scaleText ? MediaQuery.textScalerOf(context).scale(base) : base;
    final ink = _ink(context, color ?? ambient.color);
    final Widget art;
    if (size < minFontSize) {
      final h = Epic1Art.markHeight * size;
      art = _BaselineBox(
        baseline: h,
        child: CustomPaint(size: Size(h * Epic1Glyph._aspect(3), h), painter: _BlocksPainter(ink, 3)),
      );
    } else {
      final box = sizeFor(size);
      art = _BaselineBox(
        baseline: baselineFor(size),
        child: SizedBox.fromSize(
          size: box,
          child: SvgPicture.asset(
            Epic1Art.wordmark,
            width: box.width,
            height: box.height,
            theme: SvgTheme(currentColor: ink),
            excludeFromSemantics: true,
          ),
        ),
      );
    }
    final padded = clearStart > 0 || clearEnd > 0
        ? Padding(padding: EdgeInsetsDirectional.only(start: clearStart * size, end: clearEnd * size), child: art)
        : art;
    if (excludeSemantics) return ExcludeSemantics(child: padded);
    return Semantics(label: Epic1Art.name, image: true, excludeSemantics: true, child: padded);
  }
}

/// The epic1 blocks alone, for icon slots, in one colour: grid columns 0 to 4 (the pack's icon)
/// at 24 px and up, columns 0 to 2 (the 1 alone) below. The blocks fill 0.8 of [size] in
/// height and are centred. Decorative unless it gets a [semanticLabel].
class Epic1Glyph extends StatelessWidget {
  const Epic1Glyph({super.key, this.size = 20, this.color, this.semanticLabel});

  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Width over height of the blocks in the first [columns] columns.
  static double _aspect(int columns) =>
      (columns * Epic1Art.cell - (Epic1Art.cell - Epic1Art.block)) /
      (Epic1Art.grid.length * Epic1Art.cell - (Epic1Art.cell - Epic1Art.block));

  @override
  Widget build(BuildContext context) {
    final columns = size < 24 ? 3 : 5;
    final h = size * 0.8;
    final art = SizedBox.square(
      dimension: size,
      child: Center(
        child: CustomPaint(
          size: Size(h * _aspect(columns), h),
          painter: _BlocksPainter(_ink(context, color ?? IconTheme.of(context).color), columns),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(label: label, image: true, excludeSemantics: true, child: art);
  }
}

/// Paints the first [columns] columns of [Epic1Art.grid] to fill its size: the 1 in [ink], the
/// noise in [ink] at [Epic1Art.noiseOpacity].
class _BlocksPainter extends CustomPainter {
  const _BlocksPainter(this.ink, this.columns);

  final Color ink;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / (Epic1Art.grid.length * Epic1Art.cell - (Epic1Art.cell - Epic1Art.block));
    final paint = Paint()..isAntiAlias = true;
    for (var row = 0; row < Epic1Art.grid.length; row++) {
      for (var col = 0; col < columns; col++) {
        if (Epic1Art.grid[row][col] != '#') continue;
        final opacity = col < 3 ? 1.0 : Epic1Art.noiseOpacity[col - 3];
        paint.color = ink.withValues(alpha: ink.a * opacity);
        canvas.drawRect(
          Rect.fromLTWH(col * Epic1Art.cell * unit, row * Epic1Art.cell * unit, Epic1Art.block * unit, Epic1Art.block * unit),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BlocksPainter old) => old.ink != ink || old.columns != columns;
}

/// [text] with [Epic1Mark] in place of each plain "epic1" token, on the text's baseline and at
/// its size, with [Epic1Art.clearSpace] between it and the words beside it (a neighbouring
/// space counts towards it). Screen readers get [text] whole. Below [Epic1Mark.minFontSize]
/// (the wordmark's minimum), or when [text] has no token, it is a plain [Text]: the name as a
/// word, which the pack allows in any sentence.
class Epic1Text extends StatelessWidget {
  const Epic1Text(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Matches the token as a word: not inside a longer word or a link like `epic1:…`.
  static final RegExp token = RegExp(r'(?<![\w:/.-])epic1(?![\w:/-])');

  @override
  Widget build(BuildContext context) {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    final fontSize = merged.fontSize ?? 14;
    final parts = text.split(token);
    if (parts.length == 1 || fontSize < Epic1Mark.minFontSize) {
      return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
    }
    // The space's advance in em, so a space beside the wordmark plus the padding makes the
    // clear space and no more.
    final space = TextPainter(
      text: TextSpan(text: ' ', style: merged),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final spaceEm = space.width / fontSize;
    space.dispose();
    double clear(String side, {required bool before}) {
      if (side.isEmpty) return 0;
      final ch = before ? side[side.length - 1] : side[0];
      final room = ch.trim().isEmpty ? Epic1Art.clearSpace - spaceEm : Epic1Art.clearSpace;
      return room > 0 ? room : 0;
    }

    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Epic1Mark(
              fontSize: fontSize,
              color: merged.color,
              excludeSemantics: true,
              scaleText: false,
              clearStart: clear(parts[i - 1], before: true),
              clearEnd: clear(parts[i], before: false),
            ),
          ),
        );
      }
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: text,
    );
  }
}

/// A fixed-size child that reports [baseline] as its alphabetic baseline, so a [WidgetSpan] or
/// a baseline-aligned [Row] sets the artwork on the text's baseline.
class _BaselineBox extends SingleChildRenderObjectWidget {
  const _BaselineBox({required this.baseline, required super.child});

  final double baseline;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBaselineBox(baseline);

  @override
  void updateRenderObject(BuildContext context, _RenderBaselineBox renderObject) {
    renderObject.baseline = baseline;
  }
}

class _RenderBaselineBox extends RenderProxyBox {
  _RenderBaselineBox(this._baseline);

  double _baseline;
  set baseline(double value) {
    if (value == _baseline) return;
    _baseline = value;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) => _baseline;
}
