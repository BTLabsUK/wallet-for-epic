import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Two panels side by side as one unit (rule R1 of `docs/plans/w7-layout.md`): [main] takes
/// the width left over, [side] is [sideWidth] wide, [gap] apart ([Sp.col] by default). Both get
/// the taller one's height, so they share their top and bottom edges.
///
/// Under a bounded height (a page that hands its height down, `EPage(scroll: false)`) the unit
/// is at most that tall: each child sizes itself up to it (a panel taller than that scrolls
/// inside itself, `EPanel(scroll: true)`), then both are stretched to the taller. Under an
/// unbounded height (inside a scrolling page) the children must size themselves without a
/// [Flexible].
class PanelRow extends MultiChildRenderObjectWidget {
  PanelRow({super.key, required Widget main, required Widget side, required this.sideWidth, this.gap, this.maxSideFraction = 1, this.sideFirst = false})
    // Children in reading order, so semantics, Tab and finders meet them as they are shown.
    : super(children: sideFirst ? [side, main] : [main, side]);

  final double sideWidth;
  final double? gap;

  /// The side never takes more than this share of the row (a large interface scale on a small
  /// window), so the main column keeps room for its rows.
  final double maxSideFraction;

  /// The side column at the start (a list beside its detail, as Contacts), not the end.
  final bool sideFirst;

  @override
  RenderPanelRow createRenderObject(BuildContext context) =>
      RenderPanelRow(sideWidth, gap ?? Sp.col, Directionality.of(context), maxSideFraction, sideFirst);

  @override
  void updateRenderObject(BuildContext context, RenderPanelRow renderObject) {
    renderObject
      ..sideWidth = sideWidth
      ..gap = gap ?? Sp.col
      ..textDirection = Directionality.of(context)
      ..maxSideFraction = maxSideFraction
      ..sideFirst = sideFirst
      // A column at the full height is a relayout boundary (its constraints are tight), so a
      // rebuild of the page measures both columns again.
      ..markNeedsLayout();
  }
}

class _PanelRowData extends ContainerBoxParentData<RenderBox> {}

class RenderPanelRow extends RenderBox with ContainerRenderObjectMixin<RenderBox, _PanelRowData>, RenderBoxContainerDefaultsMixin<RenderBox, _PanelRowData> {
  RenderPanelRow(this._sideWidth, this._gap, this._textDirection, this._maxSideFraction, this._sideFirst);

  bool _sideFirst;
  set sideFirst(bool v) {
    if (v == _sideFirst) return;
    _sideFirst = v;
    markNeedsLayout();
  }

  double _sideWidth;
  set sideWidth(double v) {
    if (v == _sideWidth) return;
    _sideWidth = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  double _maxSideFraction;
  set maxSideFraction(double v) {
    if (v == _maxSideFraction) return;
    _maxSideFraction = v;
    markNeedsLayout();
  }

  RenderBox get _main => _sideFirst ? lastChild! : firstChild!;
  RenderBox get _side => _sideFirst ? firstChild! : lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PanelRowData) child.parentData = _PanelRowData();
  }

  /// The side's width in a row [width] wide (whole pixels).
  double _sideOf(double width) => width.isFinite ? math.min(_sideWidth, (width * _maxSideFraction).floorToDouble()) : _sideWidth;
  double _mainOf(double width) => math.max(0, width - _sideOf(width) - _gap);

  @override
  double computeMinIntrinsicWidth(double height) => _main.getMinIntrinsicWidth(height) + _gap + _sideWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _main.getMaxIntrinsicWidth(height) + _gap + _sideWidth;

  @override
  double computeMinIntrinsicHeight(double width) => math.max(_main.getMinIntrinsicHeight(_mainOf(width)), _side.getMinIntrinsicHeight(_sideOf(width)));

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(_main.getMaxIntrinsicHeight(_mainOf(width)), _side.getMaxIntrinsicHeight(_sideOf(width)));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final mainW = _mainOf(w);
    final sideW = _sideOf(w);
    final m = _main.getDryLayout(BoxConstraints(minWidth: mainW, maxWidth: mainW, maxHeight: constraints.maxHeight));
    final s = _side.getDryLayout(BoxConstraints(minWidth: sideW, maxWidth: sideW, maxHeight: constraints.maxHeight));
    return constraints.constrain(Size(w, math.max(m.height, s.height)));
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth, 'PanelRow needs a bounded width');
    final w = constraints.maxWidth;
    final mainW = _mainOf(w);
    final sideW = _sideOf(w);
    final cap = constraints.maxHeight;
    // First pass: each at its own height, up to the cap.
    _main.layout(BoxConstraints(minWidth: mainW, maxWidth: mainW, maxHeight: cap), parentUsesSize: true);
    _side.layout(BoxConstraints(minWidth: sideW, maxWidth: sideW, maxHeight: cap), parentUsesSize: true);
    final h = constraints.constrainHeight(math.max(_main.size.height, _side.size.height));
    // Second pass: the shorter one stretched to the taller. At least that tall rather than
    // exactly, so the column stays no relayout boundary: when its content grows (an error line
    // in a form), this row measures both again.
    if (_main.size.height != h) _main.layout(BoxConstraints(minWidth: mainW, maxWidth: mainW, minHeight: h, maxHeight: cap), parentUsesSize: true);
    if (_side.size.height != h) _side.layout(BoxConstraints(minWidth: sideW, maxWidth: sideW, minHeight: h, maxHeight: cap), parentUsesSize: true);
    final ltr = (_textDirection == TextDirection.ltr) != _sideFirst;
    (_main.parentData! as _PanelRowData).offset = Offset(ltr ? 0 : w - mainW, 0);
    (_side.parentData! as _PanelRowData).offset = Offset(ltr ? w - sideW : 0, 0);
    size = Size(w, h);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
}
