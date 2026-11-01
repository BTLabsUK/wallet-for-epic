// SPDX-License-Identifier: Apache-2.0
/// Fixed anchors for both front ends: room that is held whether something is in it or not, so
/// nothing on a screen moves when a caption, an error, a progress bar or a loaded value comes
/// and goes. Theme-free: the caller passes the style or colour from its own tokens.
library;

import 'package:flutter/widgets.dart';

/// A slot that keeps its height whatever it holds: a caption, an error, a title that may take
/// one or two lines, a progress bar, or nothing. A child taller than the room grows the slot
/// (large text), never clips.
class ReservedSlot extends StatelessWidget {
  /// Room for [lines] lines of [style] at the current text scale; [child] sits at [alignment]
  /// in it (at the bottom for a title over its field, so the spare line falls above it).
  const ReservedSlot.lines({
    super.key,
    this.child,
    required TextStyle this.style,
    this.lines = 1,
    this.alignment = AlignmentDirectional.topStart,
  }) : model = null;

  /// The room [model] takes, laid out but neither painted, heard nor tappable; [child] sits at
  /// [alignment] over it. For a slot that holds a button in one state and nothing (or a
  /// progress bar) in another.
  const ReservedSlot.like({
    super.key,
    required Widget this.model,
    this.child,
    this.alignment = AlignmentDirectional.center,
  }) : style = null,
       lines = 0;

  final Widget? child;
  final TextStyle? style;
  final int lines;
  final Widget? model;
  final AlignmentGeometry alignment;

  /// The height of [lines] lines of [style] at [scaler].
  static double heightOf(TextStyle style, int lines, TextScaler scaler, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.preferredLineHeight * lines;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final model = this.model;
    if (model != null) {
      return Stack(
        alignment: alignment,
        // As wide as the parent asks (a stretched column's button stays full width).
        fit: StackFit.passthrough,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: model,
          ),
          ?child,
        ],
      );
    }
    final height = heightOf(style!, lines, MediaQuery.textScalerOf(context), Directionality.of(context));
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Align(alignment: alignment, heightFactor: 1, child: child),
    );
  }
}

/// A value still loading, drawn as a bar exactly where and as large as the loaded [child]
/// will be: [child] is the loaded widget with a placeholder value, laid out but not painted
/// nor heard. So a skeleton always has the loaded layout, and loading moves nothing.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    required this.loading,
    required this.child,
    required this.color,
    this.radius = 4,
    this.inset = EdgeInsets.zero,
  });

  final bool loading;
  final Widget child;

  /// The bar's fill, from the caller's tokens.
  final Color color;
  final double radius;

  /// The bar inside the child's box (a bar a little shorter than its line reads as text).
  final EdgeInsetsGeometry inset;

  @override
  Widget build(BuildContext context) {
    if (!loading) return child;
    return ExcludeSemantics(
      child: Stack(
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: child,
          ),
          Positioned.fill(
            child: Padding(
              padding: inset,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
