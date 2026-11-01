// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';

/// Centred text whose lines come out about even: it takes the narrowest width that keeps the
/// line count it has at full width, so a paragraph never ends on one short word (an orphan).
/// For short centred copy (an empty state, a hero line); one line stays as it is. Both apps.
class BalancedText extends StatelessWidget {
  const BalancedText(this.text, {super.key, this.style, this.textAlign = TextAlign.center});

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final plain = Text(text, style: style, textAlign: textAlign);
      if (!box.hasBoundedWidth) return plain;
      final width = balancedWidth(
        text,
        DefaultTextStyle.of(context).style.merge(style),
        box.maxWidth,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      );
      if (width >= box.maxWidth) return plain;
      // Aligned in the box, so a tight box (a stretched column) still gets the narrower lines.
      return Align(
        alignment: textAlign == TextAlign.center ? Alignment.topCenter : AlignmentDirectional.topStart,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox(width: width, child: plain),
      );
    },
  );
}

/// The narrowest width up to [maxWidth] at which [text] takes no more lines than at
/// [maxWidth]. Returns [maxWidth] for one line.
double balancedWidth(
  String text,
  TextStyle style,
  double maxWidth, {
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  Locale? locale,
}) {
  final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: textDirection, textScaler: textScaler, locale: locale);
  int linesAt(double w) {
    painter.layout(maxWidth: w);
    return painter.computeLineMetrics().length;
  }

  try {
    final lines = linesAt(maxWidth);
    if (lines <= 1) return maxWidth;
    // The text cannot be narrower than its widest line divided over the lines.
    var lo = painter.maxIntrinsicWidth / lines;
    var hi = maxWidth;
    for (var i = 0; i < 12 && hi - lo > 1; i++) {
      final mid = (lo + hi) / 2;
      if (linesAt(mid) <= lines) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    // A pixel of slack against rounding between this layout and the Text's own.
    return (hi + 1).clamp(0, maxWidth).toDouble();
  } finally {
    painter.dispose();
  }
}
