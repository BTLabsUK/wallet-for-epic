// SPDX-License-Identifier: Apache-2.0
/// The one anatomy of a notice, on the phone ([NoticeCard], [InlineNotice]) and the desktop
/// (`ENotice`): the level's icon, the words (a bold title and/or a regular text), the actions
/// and, at the end, a close button. Only the surface around it is each platform's own.
///
/// The rule it lays out: the actions sit beside the words while every line of the words fits
/// there unwrapped; as soon as the words would wrap, the actions take their own row under them,
/// at the end, so the words keep the whole width and are never cut to a few letters (#07). A
/// single line is centred on its row with its icon and buttons (#25); with more lines the icon
/// and the close button stay level with the first one.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The parts of a [NoticeLayout].
enum NoticeSlot { icon, words, actions, close }

/// Lays out a notice's parts by the rule above. [firstLine] is the height of the words' first
/// line, which the icon and [close] are centred on. [textEnd] keeps the words that far from the
/// end when nothing sits beside them. [actionsBelow] puts the actions under the words whatever
/// their length (a row of several buttons). [minHeight] centres a short notice in that height.
class NoticeLayout extends SlottedMultiChildRenderObjectWidget<NoticeSlot, RenderBox> {
  const NoticeLayout({
    super.key,
    required this.icon,
    required this.words,
    this.actions,
    this.close,
    this.iconGap = 12,
    this.actionGap = 8,
    this.runGap = 0,
    this.firstLine = 20,
    this.textEnd = 0,
    this.minHeight = 0,
    this.actionsBelow = false,
  });

  final Widget icon;
  final Widget words;
  final Widget? actions;
  final Widget? close;
  final double iconGap;
  final double actionGap;
  final double runGap;
  final double firstLine;
  final double textEnd;
  final double minHeight;
  final bool actionsBelow;

  @override
  Iterable<NoticeSlot> get slots => NoticeSlot.values;

  @override
  Widget? childForSlot(NoticeSlot slot) => switch (slot) {
    NoticeSlot.icon => icon,
    NoticeSlot.words => words,
    NoticeSlot.actions => actions,
    NoticeSlot.close => close,
  };

  @override
  RenderNoticeLayout createRenderObject(BuildContext context) => RenderNoticeLayout(
    iconGap: iconGap,
    actionGap: actionGap,
    runGap: runGap,
    firstLine: firstLine,
    textEnd: textEnd,
    minHeight: minHeight,
    actionsBelow: actionsBelow,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderNoticeLayout renderObject) => renderObject
    ..iconGap = iconGap
    ..actionGap = actionGap
    ..runGap = runGap
    ..firstLine = firstLine
    ..textEnd = textEnd
    ..minHeight = minHeight
    ..actionsBelow = actionsBelow
    ..textDirection = Directionality.of(context);
}

/// Where each part goes at one width; [NoticeLayout]'s plan, shared by layout and measuring.
typedef _Plan = ({Size size, Map<NoticeSlot, Rect> rects, bool beside});

class RenderNoticeLayout extends RenderBox with SlottedContainerRenderObjectMixin<NoticeSlot, RenderBox> {
  RenderNoticeLayout({
    required double iconGap,
    required double actionGap,
    required double runGap,
    required double firstLine,
    required double textEnd,
    required double minHeight,
    required bool actionsBelow,
    required TextDirection textDirection,
  }) {
    _iconGap = iconGap;
    _actionGap = actionGap;
    _runGap = runGap;
    _firstLine = firstLine;
    _textEnd = textEnd;
    _minHeight = minHeight;
    _actionsBelow = actionsBelow;
    _textDirection = textDirection;
  }

  late double _iconGap;
  set iconGap(double v) {
    if (v == _iconGap) return;
    _iconGap = v;
    markNeedsLayout();
  }

  late double _actionGap;
  set actionGap(double v) {
    if (v == _actionGap) return;
    _actionGap = v;
    markNeedsLayout();
  }

  late double _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  late double _firstLine;
  set firstLine(double v) {
    if (v == _firstLine) return;
    _firstLine = v;
    markNeedsLayout();
  }

  late double _textEnd;
  set textEnd(double v) {
    if (v == _textEnd) return;
    _textEnd = v;
    markNeedsLayout();
  }

  late double _minHeight;
  set minHeight(double v) {
    if (v == _minHeight) return;
    _minHeight = v;
    markNeedsLayout();
  }

  late bool _actionsBelow;
  set actionsBelow(bool v) {
    if (v == _actionsBelow) return;
    _actionsBelow = v;
    markNeedsLayout();
  }

  late TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  RenderBox? get _icon => childForSlot(NoticeSlot.icon);
  RenderBox? get _words => childForSlot(NoticeSlot.words);
  RenderBox? get _actions => childForSlot(NoticeSlot.actions);
  RenderBox? get _close => childForSlot(NoticeSlot.close);

  /// Whether the actions sat beside the words in the last layout, for tests.
  bool get actionsBeside => _beside;
  bool _beside = true;

  double _w(RenderBox? b, double Function(RenderBox) f) => b == null ? 0 : f(b);

  @override
  double computeMinIntrinsicWidth(double height) {
    final words = _w(_words, (b) => b.getMinIntrinsicWidth(double.infinity));
    final actions = _w(_actions, (b) => b.getMinIntrinsicWidth(double.infinity));
    return _w(_icon, (b) => b.getMaxIntrinsicWidth(double.infinity)) +
        _iconGap +
        math.max(words, actions) +
        math.max(_textEnd, _w(_close, (b) => b.getMaxIntrinsicWidth(double.infinity)));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final actions = _actions == null ? 0.0 : _actionGap + _actions!.getMaxIntrinsicWidth(double.infinity);
    return _w(_icon, (b) => b.getMaxIntrinsicWidth(double.infinity)) +
        _iconGap +
        _w(_words, (b) => b.getMaxIntrinsicWidth(double.infinity)) +
        actions +
        math.max(_actions == null ? _textEnd : 0, _w(_close, (b) => b.getMaxIntrinsicWidth(double.infinity)));
  }

  /// The size of [b] in [c], by its intrinsic size: for the intrinsic heights.
  static Size _intrinsic(RenderBox b, BoxConstraints c) {
    final width = c.hasTightWidth ? c.maxWidth : math.min(b.getMaxIntrinsicWidth(double.infinity), c.maxWidth);
    return c.constrain(Size(width, b.getMaxIntrinsicHeight(width)));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _plan(width, _intrinsic).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) => _plan(width, _intrinsic).size.height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_plan(_widthIn(constraints), (b, c) => b.getDryLayout(c)).size);

  double _widthIn(BoxConstraints constraints) =>
      constraints.hasBoundedWidth ? constraints.maxWidth : getMaxIntrinsicWidth(double.infinity);

  /// The plan at [width]; [size] measures a child in the given constraints.
  _Plan _plan(double width, Size Function(RenderBox, BoxConstraints) size) {
    final icon = _icon == null ? Size.zero : size(_icon!, BoxConstraints(maxWidth: width));
    final close = _close == null ? Size.zero : size(_close!, BoxConstraints(maxWidth: width));
    final start = icon.width + (_icon == null ? 0 : _iconGap);
    // The words' room when nothing sits beside them but the close button.
    final room = math.max(0.0, width - start - math.max(close.width, _textEnd));
    final actions = _actions == null ? Size.zero : size(_actions!, BoxConstraints(maxWidth: math.max(0, width - start)));
    final end = math.max(0.0, width - start - close.width);
    final words = _words;
    final unwrapped = words == null ? 0.0 : words.getMaxIntrinsicWidth(double.infinity);
    // Beside while the words' longest line fits there unwrapped.
    final beside = _actions == null || (!_actionsBelow && unwrapped + _actionGap + actions.width <= end);
    final wordsWidth = _actions != null && beside ? math.max(0.0, end - actions.width - _actionGap) : room;
    final text = words == null ? Size.zero : size(words, BoxConstraints.tightFor(width: wordsWidth));
    final row = math.max(text.height, _actions != null && beside ? actions.height : 0);
    final wordsY = (row - text.height) / 2;
    // The first line's middle: the icon and the close button are centred on it.
    final line = wordsY + math.min(_firstLine, text.height) / 2;
    final iconY = line - icon.height / 2;
    final closeY = line - close.height / 2;
    final rects = <NoticeSlot, Rect>{
      NoticeSlot.icon: Rect.fromLTWH(0, iconY, icon.width, icon.height),
      NoticeSlot.words: Rect.fromLTWH(start, wordsY, text.width, text.height),
      NoticeSlot.close: Rect.fromLTWH(width - close.width, closeY, close.width, close.height),
      if (_actions != null)
        NoticeSlot.actions: beside
            ? Rect.fromLTWH(start + wordsWidth + _actionGap, (row - actions.height) / 2, actions.width, actions.height)
            : Rect.fromLTWH(width - actions.width, row + _runGap, actions.width, actions.height),
    };
    var top = 0.0, bottom = row;
    for (final MapEntry(key: slot, value: r) in rects.entries) {
      if (childForSlot(slot) == null) continue;
      top = math.min(top, r.top);
      bottom = math.max(bottom, r.bottom);
    }
    final height = bottom - top;
    final shift = -top + math.max(0.0, (_minHeight - height) / 2);
    final rtl = _textDirection == TextDirection.rtl;
    return (
      size: Size(width, math.max(height, _minHeight)),
      rects: {
        for (final MapEntry(:key, :value) in rects.entries)
          key: Rect.fromLTWH(rtl ? width - value.right : value.left, value.top + shift, value.width, value.height),
      },
      beside: beside,
    );
  }

  @override
  void performLayout() {
    final width = _widthIn(constraints);
    final plan = _plan(width, (b, c) => ChildLayoutHelper.layoutChild(b, c));
    _beside = plan.beside;
    for (final MapEntry(:key, :value) in plan.rects.entries) {
      final child = childForSlot(key);
      if (child == null) continue;
      (child.parentData! as BoxParentData).offset = value.topLeft;
    }
    size = constraints.constrain(plan.size);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final words = _words;
    if (words == null) return null;
    final d = words.getDistanceToActualBaseline(baseline);
    return d == null ? null : d + (words.parentData! as BoxParentData).offset.dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(child, (child.parentData! as BoxParentData).offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) => child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
