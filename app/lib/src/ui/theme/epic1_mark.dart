// SPDX-License-Identifier: Apache-2.0
/// The epic1 logo ("Corners"): "epic", then a 1 at x-height inside four open scan-frame corners,
/// on one line. [Epic1Mark] is the inline wordmark, sized from the text it sits in; [Epic1Glyph]
/// is the square mark alone; [Epic1Text] renders a string with the mark in place of its plain
/// "epic1" token. Notifications, exports, logs and search keep the plain token.
///
/// The artwork lives in two files and nowhere else: `assets/brand/epic1-wordmark.svg` and
/// `assets/brand/epic1-mark.svg`. In both, `currentColor` takes the ink and [Epic1Art.keyAccent]
/// takes the accent. Swapping the logo means replacing those files and, if the wordmark's box
/// changes, the numbers in [Epic1Art].
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tokens.dart';

/// The epic1 artwork: its files and the wordmark's box, in the SVG's own units.
abstract final class Epic1Art {
  static const String wordmark = 'assets/brand/epic1-wordmark.svg';
  static const String mark = 'assets/brand/epic1-mark.svg';

  /// The colour the SVGs use for the accent part (the 1); replaced with the theme's accent.
  static const Color keyAccent = Color(0xFFF6D471);

  /// The wordmark's viewBox size, the baseline's distance from its top and the x-height of
  /// "epic", all in the SVG's units.
  static const double width = 3010;
  static const double height = 935;
  static const double baseline = 760;
  static const double xHeight = 542;

  /// The family name, for screen readers and wherever the plain token stays. Never translated.
  static const String name = 'epic1';
}

/// The x-height of the app's text faces as a share of the font size: Montserrat 534/1000 and
/// Geist 530/1000 (OS/2 sxHeight).
const double _textXHeight = 0.53;

/// Maps the artwork's accent key to the theme's accent.
@immutable
class _AccentMapper extends ColorMapper {
  const _AccentMapper(this.accent);

  final Color accent;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) =>
      color.toARGB32() == Epic1Art.keyAccent.toARGB32() ? accent : color;

  @override
  bool operator ==(Object other) => other is _AccentMapper && other.accent == accent;

  @override
  int get hashCode => accent.hashCode;
}

/// The ink and accent the marks take by default: the text colour, and the accent as text (gold
/// in dark mode, the deeper gold that holds 4.5:1 in light mode).
({Color ink, Color accent}) _colours(BuildContext context, Color? ink, Color? accent) {
  final t = context.tokens;
  return (ink: ink ?? t.text, accent: accent ?? t.accentText);
}

/// The inline epic1 wordmark. Its "epic" has the x-height of a [fontSize] font and its
/// baseline is the text's, so in a row or a [WidgetSpan] it reads as a word. One semantics
/// node labelled "epic1" unless [excludeSemantics].
class Epic1Mark extends StatelessWidget {
  const Epic1Mark({
    super.key,
    this.fontSize,
    this.color,
    this.accent,
    this.excludeSemantics = false,
    this.scaleText = true,
  });

  /// The size of the text it stands in; the ambient [DefaultTextStyle]'s when null.
  final double? fontSize;

  /// The ink for "epic" and the corners; the ambient text colour, else the text token.
  final Color? color;

  /// The colour of the 1; the accent-as-text token by default.
  final Color? accent;

  /// Leaves the label to an ancestor (a [Text] that carries the whole string).
  final bool excludeSemantics;

  /// Applies the platform text scale. Off inside a [WidgetSpan], which scales its child itself.
  final bool scaleText;

  /// Below this text size the 1 inside its corners stops reading; [Epic1Text] falls back to
  /// the plain token there.
  static const double minFontSize = 13;

  /// The mark's size for a [fontSize] font, unscaled.
  static Size sizeFor(double fontSize) {
    final s = fontSize * _textXHeight / Epic1Art.xHeight;
    return Size(Epic1Art.width * s, Epic1Art.height * s);
  }

  /// The baseline's distance from the mark's top, for a [fontSize] font.
  static double baselineFor(double fontSize) =>
      Epic1Art.baseline * fontSize * _textXHeight / Epic1Art.xHeight;

  @override
  Widget build(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style;
    final base = fontSize ?? ambient.fontSize ?? 14;
    final size = scaleText ? MediaQuery.textScalerOf(context).scale(base) : base;
    final c = _colours(context, color ?? ambient.color, accent);
    final box = sizeFor(size);
    Widget art = _BaselineBox(
      baseline: baselineFor(size),
      child: SizedBox.fromSize(
        size: box,
        child: SvgPicture.asset(
          Epic1Art.wordmark,
          width: box.width,
          height: box.height,
          theme: SvgTheme(currentColor: c.ink),
          colorMapper: _AccentMapper(c.accent),
          excludeFromSemantics: true,
        ),
      ),
    );
    if (excludeSemantics) return ExcludeSemantics(child: art);
    return Semantics(label: Epic1Art.name, image: true, excludeSemantics: true, child: art);
  }
}

/// The square epic1 mark alone (the corners and the 1), for icon slots. Decorative unless it
/// gets a [semanticLabel].
class Epic1Glyph extends StatelessWidget {
  const Epic1Glyph({super.key, this.size = 20, this.color, this.accent, this.semanticLabel});

  final double size;
  final Color? color;
  final Color? accent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = _colours(context, color ?? IconTheme.of(context).color, accent);
    final art = SvgPicture.asset(
      Epic1Art.mark,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c.ink),
      colorMapper: _AccentMapper(c.accent),
      excludeFromSemantics: true,
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(label: label, image: true, excludeSemantics: true, child: art);
  }
}

/// [text] with [Epic1Mark] in place of each plain "epic1" token, on the text's baseline and at
/// its size. Screen readers get [text] whole. Below [Epic1Mark.minFontSize], or when [text]
/// has no token, it is a plain [Text].
class Epic1Text extends StatelessWidget {
  const Epic1Text(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.accent,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// The colour of the mark's 1; the accent-as-text token by default.
  final Color? accent;

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
              accent: accent,
              excludeSemantics: true,
              scaleText: false,
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
