// SPDX-License-Identifier: Apache-2.0
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;

export '../../ui/badge.dart';

import '../../address_format.dart' show AddressPart, AddressTone, addressLines, addressParts, addressPartsSpan;
import '../desk_l10n.dart';
import '../../balanced_text.dart';
import '../../log.dart' show logWarn;
import '../../trust_ids.dart' show TrustId;
import '../../ui/info_action.dart';
import '../../ui/theme/protocol.dart' show CornerTicksPainter, GridFieldPainter;
import '../theme/icons.dart';
import '../../ui/badge.dart';
import '../../ui/notice_layout.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'selectable.dart';
import 'status.dart' show EState, EStateDot;
import 'motion.dart';
import 'more_options.dart';
import 'popover.dart';
import 'tip.dart';

/// A panel: s1 fill, hairline edge, 8 px radius. [title] (or a custom [head]) and [foot] get
/// their own bands; the head band is [Ctl.header] tall and starts where the body starts, so
/// panels side by side have their header lines and first rows level.
class EPanel extends StatelessWidget {
  const EPanel({
    super.key,
    required this.child,
    this.title,
    this.head,
    this.headTrailing,
    this.foot,
    this.padding,
    this.scroll = false,
    this.expand = false,
    this.strong = false,
  });

  final Widget child;
  final String? title;

  /// In place of [title]: anything that fits a header band (tabs, a title and a close button).
  final Widget? head;
  final Widget? headTrailing;
  final Widget? foot;

  /// Defaults to 24 by 20.
  final EdgeInsetsGeometry? padding;

  /// The body scrolls inside the panel when the panel is given less height than it needs
  /// (a column of a [PanelRow] under a bounded height). Needs a bounded height.
  final bool scroll;

  /// The body fills the panel's height (needs a bounded height), so its last item can sit at
  /// the bottom: cards side by side with their buttons on one line.
  final bool expand;

  /// The stronger edge of a selected item's pane.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    // One inset for every panel ([Sp.panel]), the same as an [ESetRow]'s inside one.
    final pad = (padding ?? EdgeInsets.all(Sp.panel)).resolve(Directionality.of(context));
    // A scrolling pane is a column of its own: its text selects within it (selectable.dart), so a
    // drag never lands in the pane next to it.
    final body = scroll
        ? Flexible(child: SingleChildScrollView(padding: pad, child: DeskSelectable(child: child)))
        : (expand ? Expanded(child: Padding(padding: pad, child: child)) : Padding(padding: pad, child: child));
    final hasHead = head != null || title != null;
    return Container(
      clipBehavior: scroll ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: strong ? c.lineStrong : c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
        boxShadow: c.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHead)
            Container(
              key: const ValueKey('epanel-head'),
              // Starts where the body starts (Sp.panel over an unpadded body); a custom head ends
              // close to the edge for its icon button.
              padding: EdgeInsets.fromLTRB(
                pad.left < Sp.x4 ? Sp.panel : pad.left,
                head != null ? 0 : Sp.x2,
                head != null ? Sp.x2 : (pad.right < Sp.x4 ? Sp.panel : pad.right),
                head != null ? 0 : Sp.x2,
              ),
              constraints: BoxConstraints(minHeight: Ctl.header),
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: head ??
                  Row(
                    children: [
                      Expanded(child: Text(title!, style: context.ts.label)),
                      ?headTrailing,
                    ],
                  ),
            ),
          body,
          if (foot != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: Sp.panel, vertical: Sp.x3),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: foot,
            ),
        ],
      ),
    );
  }
}

/// The instrument frame: grid field fading from the top left and corner ticks. Only for the
/// balance and the brand tiles on the screens that open the app.
class ETicked extends StatelessWidget {
  const ETicked({super.key, required this.child, this.grid = true});

  final Widget child;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    // Light makes it the hero: a warm fill running to white, the brand edge, the grid and the
    // ticks in the brand brown. Dark keeps the flat panel.
    final hero = c.hero.a != 0;
    return Container(
      decoration: BoxDecoration(
        color: hero ? null : c.s1,
        gradient: hero ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.hero, c.s1]) : null,
        border: Border.all(color: hero ? c.tick.withValues(alpha: 0.45) : c.line),
        borderRadius: BorderRadius.circular(Rad.xs),
        boxShadow: c.panelShadow,
      ),
      child: CustomPaint(
        painter: grid ? GridFieldPainter(hero ? c.tick.withValues(alpha: 0.12) : c.grid.withValues(alpha: c.grid.a * 2.2)) : null,
        foregroundPainter: hero ? CornerTicksPainter(c.tick, length: 12.u, width: 2) : CornerTicksPainter(c.tick),
        child: child,
      ),
    );
  }
}

/// The page area's backdrop behind every desktop screen: the window colour with a warm
/// brand wash ([DeskColors.wash]) rising behind the top of the content, where the title and
/// the balance sit, gone before the page's foot and at the sidebar's edge. One gradient, no
/// blur, drawn once; in dark the wash is transparent and the child is returned as it is.
class DeskBackdrop extends StatelessWidget {
  const DeskBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    if (c.wash.a == 0) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: c.dots.a == 0 ? null : _PageDots(c.dots, step: 22.u, radius: 1.u),
                  child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.55, -0.4),
                      radius: 1.15,
                      colors: [c.wash, c.wash.withValues(alpha: c.wash.a * 0.5), c.wash.withValues(alpha: 0)],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The page backdrop's texture: a dot at every [step], drawn once as one set of points.
class _PageDots extends CustomPainter {
  const _PageDots(this.color, {required this.step, required this.radius});

  final Color color;
  final double step, radius;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = radius * 2
      ..strokeCap = StrokeCap.round;
    final pts = <Offset>[
      for (var y = step / 2; y < size.height; y += step)
        for (var x = step / 2; x < size.width; x += step) Offset(x, y),
    ];
    canvas.drawPoints(PointMode.points, pts, p);
  }

  @override
  bool shouldRepaint(_PageDots old) => old.color != color || old.step != step || old.radius != radius;
}

/// Section head: a short accent rule and the title in sentence case.
class ESectionHead extends StatelessWidget {
  const ESectionHead(this.title, {super.key, this.trailing, this.top});

  final String title;
  final Widget? trailing;

  /// Defaults to [Sp.x8].
  final double? top;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.only(top: top ?? Sp.x8, bottom: Sp.x3),
      child: Row(
        children: [
          Container(width: 14.u, height: 2, color: c.accent),
          SizedBox(width: 10.u),
          Expanded(
            child: Semantics(header: true, child: Text(title, style: context.ts.h3)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The badge's tone, used by the dots and notices too: [BadgeTone.ok] green for done and
/// working, warn amber, risk red, info blue for in progress, gold for a brand highlight,
/// neutral for the rest. A sent amount wears DeskColors.txSent, not a tone.
typedef ETone = BadgeTone;

extension on ETone {
  (Color fg, Color bg) colors(DeskColors c) => switch (this) {
    ETone.neutral => (c.dim, Colors.transparent),
    ETone.ok => (c.ok, c.okSoft),
    ETone.warn => (c.warn, c.warnSoft),
    ETone.risk => (c.risk, c.riskSoft),
    ETone.info => (c.info, c.infoSoft),
    ETone.gold => (c.accentText, c.accentSoft),
  };
}

/// A status dot by notice tone: the shared state mark ([EStateDot]), never colour alone.
/// Prefer [EStateDot] with the state itself; a neutral or gold tone is a state not known yet
/// (a blue ring), never a healthy dot.
class EStatusDot extends StatelessWidget {
  const EStatusDot(this.tone, {super.key, this.size = 8});

  final ETone tone;
  final double size;

  @override
  Widget build(BuildContext context) => EStateDot(
    switch (tone) {
      ETone.ok => EState.ok,
      ETone.warn => EState.warn,
      ETone.risk => EState.risk,
      ETone.info || ETone.neutral || ETone.gold => EState.active,
    },
    size: size,
  );
}

/// An inline message in the flow, the phone notice's anatomy ([NoticeLayout]): the tone's icon,
/// a bold [title] (a few words), an optional regular, dim [text] (the sentence), and [actions].
/// The actions sit beside the words while those fit on one line, else on their own row under
/// them, at the end; a notice of one line is centred on its row with its icon and buttons.
/// Warnings and risks are tinted; the calm tones (neutral, ok, info) sit on the panel with the
/// tone on the icon. Gold is the brand's, never a notice's: it reads as [ETone.neutral].
class ENotice extends StatelessWidget {
  const ENotice({
    super.key,
    required this.title,
    this.text,
    this.tone = ETone.neutral,
    this.icon,
    this.actions = const [],
    this.actionsBelow = false,
    this.textColor,
    this.below,
    this.textSpan,
  });

  final String title;
  final String? text;

  /// [text] as a span, when part of it must not wrap (an address in a [WidgetSpan]).
  final InlineSpan? textSpan;

  /// Full-width content under the text, inside the panel (a progress bar).
  final Widget? below;

  /// The text's colour when it is not the usual one (a payment request's dropped parts).
  final Color? textColor;
  final ETone tone;
  final IconData? icon;
  final List<Widget> actions;

  /// Puts [actions] on their own row under the text whatever its length (several buttons).
  final bool actionsBelow;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final tone = this.tone == ETone.gold ? ETone.neutral : this.tone;
    final (fg, bg) = tone.colors(c);
    final calm = tone == ETone.neutral || tone == ETone.ok || tone == ETone.info;
    final iconColor = tone == ETone.neutral ? c.dim : fg;
    final glyph = icon ??
        switch (tone) {
          ETone.ok => EIcons.okCircle,
          ETone.warn => EIcons.alert,
          ETone.risk => EIcons.error,
          _ => EIcons.info,
        };
    final strong = ts.strong;
    final line = MediaQuery.textScalerOf(context).scale(strong.fontSize ?? Fs.md) * (strong.height ?? 1.5);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      decoration: BoxDecoration(
        // In progress (info) is not a warning: the neutral panel with a blue icon.
        color: calm ? c.s1 : bg,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: calm ? c.lineStrong : fg.withValues(alpha: 0.4)),
      ),
      child: NoticeLayout(
        icon: Icon(glyph, size: Ctl.icon, color: iconColor),
        words: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: strong),
            if (textSpan != null || text != null) ...[
              const SizedBox(height: 2),
              if (textSpan != null)
                // The style reaches the span's widgets too (a WidgetSpan's Text).
                DefaultTextStyle.merge(
                  style: textColor == null ? ts.small : ts.small.copyWith(color: textColor),
                  child: Text.rich(textSpan!),
                )
              else
                Text(text!, style: textColor == null ? ts.small : ts.small.copyWith(color: textColor)),
            ],
            if (below != null) ...[
              SizedBox(height: Sp.x2),
              SizedBox(width: double.infinity, child: below),
            ],
          ],
        ),
        actions: actions.isEmpty
            ? null
            : Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, spacing: Sp.x2, runSpacing: Sp.x2, children: actions),
        actionsBelow: actionsBelow,
        iconGap: Sp.x3,
        actionGap: Sp.x4,
        runGap: Sp.x3,
        firstLine: line,
      ),
    );
  }
}

/// The least an [EFacts] value gets beside its label.
double get factsMinValue => 200.u;

/// Key/value facts in two columns, or label above value where the value would be squeezed.
class EFacts extends StatelessWidget {
  const EFacts(this.rows, {super.key, this._labelWidth});

  final List<(String, Widget)> rows;
  final double? _labelWidth;
  double get labelWidth => _labelWidth ?? 140.u;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    // The label beside its value while the value keeps [factsMinValue]; else above it, so an
    // address or a sentence gets the whole width. A render object, not a LayoutBuilder: facts
    // sit in rows that measure their children's intrinsic heights.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.u),
            child: _FactRow(
              labelWidth: labelWidth,
              gap: Sp.x6,
              runGap: 2.u,
              minValue: factsMinValue,
              children: [
                Text(k, style: ts.bodyDim),
                DefaultTextStyle.merge(style: ts.body, child: v),
              ],
            ),
          ),
      ],
    );
  }
}

/// One [EFacts] row: the label at [labelWidth] beside the value while the value keeps
/// [minValue], else the label above the value at the full width.
class _FactRow extends MultiChildRenderObjectWidget {
  const _FactRow({required this.labelWidth, required this.gap, required this.runGap, required this.minValue, required super.children});

  final double labelWidth;
  final double gap;
  final double runGap;
  final double minValue;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFactRow(labelWidth, gap, runGap, minValue);

  @override
  void updateRenderObject(BuildContext context, _RenderFactRow r) => r
    ..labelWidth = labelWidth
    ..gap = gap
    ..runGap = runGap
    ..minValue = minValue;
}

class _FactRowData extends ContainerBoxParentData<RenderBox> {}

class _RenderFactRow extends RenderBox with ContainerRenderObjectMixin<RenderBox, _FactRowData>, RenderBoxContainerDefaultsMixin<RenderBox, _FactRowData> {
  _RenderFactRow(this._labelWidth, this._gap, this._runGap, this._minValue);

  double _labelWidth;
  set labelWidth(double v) {
    if (v == _labelWidth) return;
    _labelWidth = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  double _minValue;
  set minValue(double v) {
    if (v == _minValue) return;
    _minValue = v;
    markNeedsLayout();
  }

  RenderBox get _label => firstChild!;
  RenderBox get _value => lastChild!;

  bool _besideAt(double width) => !width.isFinite || width - _labelWidth - _gap >= _minValue;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FactRowData) child.parentData = _FactRowData();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _labelWidth + _gap + _value.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) => _labelWidth + _gap + _value.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _height(width, (b, w) => b.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width, (b, w) => b.getMaxIntrinsicHeight(w));

  double _height(double width, double Function(RenderBox, double) h) {
    if (_besideAt(width)) {
      final a = h(_label, _labelWidth), b = h(_value, width - _labelWidth - _gap);
      return a > b ? a : b;
    }
    return h(_label, width) + _runGap + h(_value, width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (_besideAt(width)) {
      final a = _label.getDryLayout(BoxConstraints.tightFor(width: _labelWidth)).height;
      final b = _value.getDryLayout(BoxConstraints.tightFor(width: width - _labelWidth - _gap)).height;
      return constraints.constrain(Size(width, a > b ? a : b));
    }
    final a = _label.getDryLayout(BoxConstraints(maxWidth: width)).height;
    final b = _value.getDryLayout(BoxConstraints.tightFor(width: width)).height;
    return constraints.constrain(Size(width, a + _runGap + b));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final beside = _besideAt(width);
    final ld = _label.parentData! as _FactRowData;
    final vd = _value.parentData! as _FactRowData;
    if (beside) {
      _label.layout(BoxConstraints.tightFor(width: _labelWidth), parentUsesSize: true);
      _value.layout(width.isFinite ? BoxConstraints.tightFor(width: width - _labelWidth - _gap) : const BoxConstraints(), parentUsesSize: true);
      ld.offset = Offset.zero;
      vd.offset = Offset(_labelWidth + _gap, 0);
      final h = _label.size.height > _value.size.height ? _label.size.height : _value.size.height;
      size = constraints.constrain(Size(width.isFinite ? width : _labelWidth + _gap + _value.size.width, h));
    } else {
      _label.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
      _value.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      ld.offset = Offset.zero;
      vd.offset = Offset(0, _label.size.height + _runGap);
      size = constraints.constrain(Size(width, _label.size.height + _runGap + _value.size.height));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}

/// Monospace data that may be copied: an id, a host, a commitment.
class EMonoText extends StatelessWidget {
  const EMonoText(this.text, {super.key, this.size = Fs.sm, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      SelectableText(text, style: context.ts.mono(size: size, color: color));
}

/// Room left over a measured address for the way Windows draws it (a bold glyph a little wider).
const double addressDrawSlack = 6;

/// How small an [EAddress] gets, as a share of its size, before it gives way in the middle.
const double _addressMinScale = 0.82;

/// [a] in [st], its first and last six in the accent when [marked].
TextSpan _marked(String a, TextStyle st, DeskColors c, bool marked) {
  if (!marked) return TextSpan(text: a, style: st);
  final h = st.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
  return TextSpan(
    style: st,
    children: [TextSpan(text: a.substring(0, 6), style: h), TextSpan(text: a.substring(6, a.length - 6)), TextSpan(text: a.substring(a.length - 6), style: h)],
  );
}

/// [a]'s first [head] and last [tail] characters around "…", the first and last six marked.
TextSpan _cut(String a, int head, int tail, TextStyle st, DeskColors c, bool marked) {
  if (head + tail >= a.length) return _marked(a, st, c, marked);
  final h = st.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
  final start = a.substring(0, head), end = a.substring(a.length - tail);
  if (!marked || head < 6 || tail < 6) return TextSpan(text: '$start…$end', style: st);
  return TextSpan(
    style: st,
    children: [
      TextSpan(text: start.substring(0, 6), style: h),
      TextSpan(text: '${start.substring(6)}…${end.substring(0, end.length - 6)}'),
      TextSpan(text: end.substring(end.length - 6), style: h),
    ],
  );
}

/// An address to read and copy: the first and last six characters in the accent.
class EAddress extends StatelessWidget {
  const EAddress(this.address, {super.key, this.large = false, this.onCopied, this.copyLabel, this.copy = true, this.extra, this.semanticsId});

  final String address;
  final bool large;

  /// The copy icon inside the box. Off where a "Copy …" button under it copies the same text:
  /// one copy control per value.
  final bool copy;

  /// The copy button's tooltip and screen-reader label.
  /// The copy button's name; "Copy" when null.
  final String? copyLabel;
  final VoidCallback? onCopied;

  /// A small control before the copy icon (Receive's QR button).
  final Widget? extra;

  /// The address's id for the drivers ([TrustId]), on the address and not on Copy.
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final base = ts.mono(size: large ? 14.5 : Fs.sm);
    // address_format.dart's parts: a key's first and last six or a link's host:port in the
    // accent, a link's scheme and path, `.onion` and an Epicbox server dim.
    const mark = TextStyle(fontWeight: FontWeight.w600);
    final markStyle = mark.copyWith(color: c.accentText);
    final quietStyle = TextStyle(color: c.dim, fontWeight: FontWeight.w400);
    TextSpan spanOf(TextStyle st, List<AddressPart> ps) => addressPartsSpan(ps, style: st, mark: markStyle, quiet: quietStyle);
    final parts = addressParts(address);
    final lines = addressLines(parts);
    final first = lines.isEmpty ? const <AddressPart>[] : lines.first;
    final rest = lines.skip(1).expand((l) => l).map((p) => p.text).join();
    final firstText = first.map((p) => p.text).join();
    // The part that gives way in the middle at the last: a key (its ends stay marked), else
    // the first line's text.
    final keyLen = first.takeWhile((p) => p.tone != AddressTone.quiet).fold(0, (n, p) => n + p.text.length);
    final a = keyLen > 0 ? firstText.substring(0, keyLen) : firstText;
    final keyTail = keyLen > 0 ? firstText.substring(keyLen) : '';
    final marked = keyLen > 12;
    final restStyle = base.copyWith(color: c.dim);
    // Never more than two lines: the whole address on one when it fits, else the key (a link's
    // host:port) on the first line and the server ("@epicbox.example.org", a link's path) whole
    // on the second, shrunk rather than cut. An address too long for its line gets smaller,
    // down to [_addressMinScale] of its size, then a key gives way in the middle, its first
    // and last six still marked; the whole of it is then in the tooltip and on Copy, and the
    // cut line cannot be selected (it would copy the "…").
    final text = LayoutBuilder(
      builder: (context, box) {
        final dir = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(InlineSpan span) {
          final tp = TextPainter(text: span, textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
          final w = tp.width;
          tp.dispose();
          return w;
        }

        final room = box.maxWidth - addressDrawSlack;
        final whole = spanOf(base, parts);
        if (!box.maxWidth.isFinite || widthOf(whole) <= room) return SelectableText.rich(whole, maxLines: 1);
        final split = rest.isNotEmpty;
        // An Epicbox server whole on one line, shrunk rather than cut; a link's path wraps
        // (it may be long), selectable like the line above.
        final Widget? second = !split
            ? null
            : rest.startsWith('@')
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(rest, style: restStyle, maxLines: 1, softWrap: false)),
              )
            : SelectableText(rest, style: restStyle);
        // The first line whole, smaller where needed.
        final size = base.fontSize!;
        for (var s = size; s >= size * _addressMinScale - 0.01; s -= 0.5) {
          final st = base.copyWith(fontSize: s);
          final span = spanOf(st, split ? first : parts);
          if (widthOf(span) <= room) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [SelectableText.rich(span, maxLines: 1), ?second],
            );
          }
        }
        // Cut in the middle at the smallest size: the most characters that fit, half each side.
        final st = base.copyWith(fontSize: size * _addressMinScale);
        final tailSpan = keyTail.isEmpty ? null : TextSpan(text: keyTail, style: restStyle.copyWith(fontSize: st.fontSize));
        InlineSpan cutTo(int n) {
          final h = (n + 1) ~/ 2;
          final cut = _cut(a, h, n - h, st, c, marked);
          return tailSpan == null ? cut : TextSpan(children: [cut, tailSpan]);
        }

        var lo = 12, hi = a.length;
        while (hi - lo > 1) {
          final mid = (lo + hi) ~/ 2;
          final span = cutTo(mid);
          if (widthOf(span) <= room) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return ETip.value(
          address,
          mono: true,
          child: Semantics(
            label: address,
            excludeSemantics: true,
            child: NoSelect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [Text.rich(cutTo(lo), maxLines: 1, softWrap: false), ?second],
              ),
            ),
          ),
        );
      },
    );
    return Container(
      padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, Sp.x2, Sp.x3),
      decoration: BoxDecoration(
        color: c.s2,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.lineStrong),
      ),
      child: Row(
        children: [
          Expanded(child: TrustId(semanticsId, child: text)),
          if (extra != null) ...[SizedBox(width: Sp.x2), extra!],
          if (copy) ...[SizedBox(width: Sp.x2), ECopyButton(text: address, label: copyLabel ?? context.l10n.commonCopy, onCopied: onCopied)],
        ],
      ),
    );
  }
}

/// Copy to the clipboard. For 1.5 s the button shows a check and "Copied" (read out by screen
/// readers); a clipboard that refuses the text says so instead. Every copy control in the
/// desktop UI is one of these, so each copy confirms the same way.
class ECopyButton extends StatefulWidget {
  const ECopyButton({
    super.key,
    required this.text,
    this.label,
    this.onCopied,
    this.withLabel = false,
    this.kind = EBtnKind.ghost,
    this.size = EBtnSize.inline,
    this.tabStop,
    this.semanticsId,
  });

  /// The test drivers' stable name for this control (`TrustIds`, lib/src/trust_ids.dart).
  final String? semanticsId;

  final String text;
  /// The button's name; "Copy" when null.
  final String? label;
  final VoidCallback? onCopied;

  /// A button with [label] in words, in [kind] and [size]; otherwise an icon.
  final bool withLabel;
  final EBtnKind kind;
  final EBtnSize size;

  /// Whether the button is a Tab stop; by default a labelled button is, an icon is not.
  final bool? tabStop;

  @override
  State<ECopyButton> createState() => _ECopyButtonState();
}

class _ECopyButtonState extends State<ECopyButton> {
  bool _done = false;
  bool _failed = false;

  /// One retry on a [PlatformException]: on Windows another program may hold the clipboard
  /// for a moment. Every refusal is logged.
  Future<void> _copy() async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await Clipboard.setData(ClipboardData(text: widget.text));
        _failed = false;
        break;
      } on PlatformException catch (e) {
        logWarn('desk', 'copy refused (try $attempt): ${e.code} ${e.message ?? ''}');
        _failed = true;
        if (attempt == 1) await Future<void>.delayed(const Duration(milliseconds: 150));
      } on Object catch (e) {
        logWarn('desk', 'copy refused: ${e.runtimeType}');
        _failed = true;
        break;
      }
    }
    if (!_failed) widget.onCopied?.call();
    if (!mounted) return;
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = !_done ? (widget.label ?? context.l10n.commonCopy) : (_failed ? context.l10n.deskKitNotCopied : context.l10n.deskKitCopied);
    final icon = !_done ? EIcons.copy : (_failed ? EIcons.alert : EIcons.check);
    final Widget button = widget.withLabel
        ? EButton(semanticsId: widget.semanticsId, label: label, icon: icon, size: widget.size, kind: widget.kind, tabStop: widget.tabStop ?? true, onPressed: _copy)
        : EIconButton(semanticsId: widget.semanticsId, icon: icon, label: label, color: _done ? (_failed ? context.dc.risk : context.dc.ok) : null, tabStop: widget.tabStop ?? false, onPressed: _copy);
    return Semantics(liveRegion: true, child: button);
  }
}

/// Nothing to show yet: glyph tile, title, one line, optional actions.
class EEmpty extends StatelessWidget {
  const EEmpty({super.key, required this.icon, required this.title, this.text, this.actions = const []});

  final IconData icon;
  final String title;
  final String? text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.u,
            height: 56.u,
            decoration: BoxDecoration(
              color: c.tint.a == 0 ? null : c.tint,
              borderRadius: BorderRadius.circular(Rad.sm),
              border: Border.all(color: c.lineStrong),
            ),
            child: Icon(icon, size: Ctl.iconLg, color: c.accentText),
          ),
          SizedBox(height: Sp.x4),
          Text(title, style: ts.h3, textAlign: TextAlign.center),
          if (text != null) ...[
            SizedBox(height: Sp.x2),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.u),
              child: BalancedText(text!, style: ts.bodyDim),
            ),
          ],
          if (actions.isNotEmpty) ...[
            SizedBox(height: Sp.x4),
            Wrap(spacing: Sp.x2, runSpacing: Sp.x2, alignment: WrapAlignment.center, children: actions),
          ],
        ],
      ),
    );
  }
}

/// A settings group: section head, then rows in one enclosure. Rows the view or an Advanced
/// switch hides ([hidden]) stay out behind the one "more options" control in the heading
/// ([EMoreOptions]); revealed, they follow [rows] in place, each with its marker.
class ESetGroup extends StatelessWidget {
  const ESetGroup({super.key, this.title, required this.rows, this.trailing, this.gap = true, this.hidden = const [], this.revealKey});

  final String? title;
  final List<Widget> rows;
  final Widget? trailing;

  /// Rows the view or an Advanced switch hides here, each an [ESetRow] with [ESetRow.advancedBy]
  /// set. The group shows the one "more options" control (EMoreOptions) for them; revealed, they
  /// follow [rows] in place, marked. [revealKey] keys the reveal state (unique per page group).
  final List<Widget> hidden;
  final String? revealKey;

  /// The space below the group; off when the caller sets it (a tour target ends at the box).
  final bool gap;

  /// The reveal key: [revealKey], else one made from the title.
  String get _key => revealKey ?? 'g:${title ?? ''}';

  @override
  Widget build(BuildContext context) {
    if (hidden.isEmpty) return _group(context, false);
    return Consumer(builder: (context, ref, _) => _group(context, moreOptionsOpen(ref, _key)));
  }

  Widget _group(BuildContext context, bool open) {
    final c = context.dc;
    final more = hidden.isEmpty
        ? null
        : EMoreOptions(
            revealKey: _key,
            count: hidden.length,
            reasons: [for (final w in hidden) if (w is ESetRow && w.advancedBy != null) w.advancedBy!],
          );
    final end = more == null
        ? trailing
        : trailing == null
        ? more
        : Row(mainAxisSize: MainAxisSize.min, children: [trailing!, SizedBox(width: Sp.x1), more]);
    final list = open ? [...rows, ...hidden] : rows;
    return Padding(
      padding: EdgeInsets.only(bottom: gap ? Sp.x8 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ESectionHead(title!, top: 0, trailing: end)
          // No heading: the control sits at the box's top right.
          else if (more != null) Align(alignment: AlignmentDirectional.centerEnd, child: end),
          if (list.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: c.s1,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(Rad.sm),
                boxShadow: c.panelShadow,
              ),
              // The marked rows' tint stays inside the rounded box.
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                    list[i],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The least a Settings row's words get beside its control; with less, the control goes under
/// them (rules: no row squeezed under this).
double get setRowMinWords => 240.u;

/// A settings row: title and one line on the left, the control on the right while the words
/// keep [setRowMinWords], else the control under the words at its own width (a narrow window
/// or a large interface scale); [stacked] always puts the control under the text (wide
/// controls such as a combobox).
class ESetRow extends StatelessWidget {
  const ESetRow({super.key, this.title, this.text, this.hint, this.hintTitle, this.hintIcon, this.hintHelp, this.control, this.stacked = false, this.wrap = false, this.below, this.leading, this.badge, this.anchor, this.advancedBy});

  /// The row's id in the settings registry (`settings_registry.dart`): search jumps here.
  final String? anchor;

  /// Set on a row shown only because the user revealed hidden options: what normally shows it
  /// ("Deep end view", "Advanced › Send options"). The row gets the quiet advanced marker.
  final String? advancedBy;

  /// Null when the group's title already names the row: the text is then the row's head.
  final String? title;

  /// A line under the title: a value or a state. An explanation goes in [hint] instead, so
  /// the main view shows labels only.
  final String? text;

  /// The row's explanation, behind an info icon after the title: a click, Enter or Space
  /// opens it in a popover ([EInfoHint]); a screen reader reads it with the title.
  final String? hint;

  /// Opens the Help topic that says more than [hint]: a "More in Help" link in the popover.
  final VoidCallback? hintHelp;

  /// With [hintTitle], the popover shows that title (and [hintIcon]) on its first line.
  final String? hintTitle;
  final IconData? hintIcon;
  final Widget? control;
  final bool stacked;

  /// For a control sized to its words (it is no [ERowControl]): beside the words while they
  /// keep 160 u (not [setRowMinWords]).
  final bool wrap;

  /// Extra content under the row (status line, expanded options).
  final Widget? below;

  /// A glyph before the words (a payment method's icon), 18 u, in the dim colour.
  final IconData? leading;

  /// A badge before [text] (a trust state, as the contact shows it).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && hint == null && advancedBy == null) Text(title!, style: ts.strong),
        if (title != null && (hint != null || advancedBy != null))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(title!, style: ts.strong)),
              if (hint != null) ...[
                SizedBox(width: Sp.x1),
                // 20 u to see, 44 px to hit (review 8).
                EHitSlop(child: EInfoHint(hint!, title: hintTitle, icon: hintIcon, onHelp: hintHelp)),
              ],
              if (advancedBy != null) ...[SizedBox(width: Sp.x2), EReasonTag(advancedBy!)],
            ],
          ),
        if (this.text != null) ...[
          if (title != null) const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.u),
            child: badge == null
                ? Text(this.text!, style: title == null ? ts.bodyDim : ts.small)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      badge!,
                      SizedBox(width: Sp.x2),
                      Flexible(child: Text(this.text!, style: title == null ? ts.bodyDim : ts.small)),
                    ],
                  ),
          ),
        ],
      ],
    );
    final words = leading == null
        ? text
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: EdgeInsets.only(top: 1.u), child: Icon(leading, size: 18.u, color: c.dim)),
              SizedBox(width: Sp.x3),
              Expanded(child: text),
            ],
          );
    final ctl = control == null || anchor == null ? control : _AnchorControl(child: control!);
    Widget row = _SlopHost(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.panel, vertical: Sp.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stacked || ctl == null) ...[
              words,
              if (ctl != null) ...[SizedBox(height: Sp.x3), ctl],
            ] else
              // The control beside the words while they keep their room, else under them.
              _WrapRow(gap: Sp.x6, runGap: Sp.x3, minWords: wrap ? 160.u : setRowMinWords, children: [words, ctl]),
            if (below != null) ...[SizedBox(height: Sp.x3), below!],
          ],
        ),
      ),
    );
    // Shown only because its hidden options are revealed: a faint tint and a 2 px mark at the
    // left edge, neutral (gold is for the brand and the main action).
    if (advancedBy != null) {
      row = DecoratedBox(
        decoration: BoxDecoration(
          color: c.hover,
          border: BorderDirectional(start: BorderSide(color: c.faint, width: 2)),
        ),
        child: row,
      );
    }
    return anchor == null ? row : SetAnchor(id: anchor!, child: row);
  }
}

/// A small tag with a dashed edge: what normally shows a revealed row ("Deep end view").
class EReasonTag extends StatelessWidget {
  const EReasonTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return CustomPaint(
      painter: _DashedEdge(c.faint, Rad.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.u, vertical: 1.u),
        child: Text(text, style: context.ts.small.copyWith(color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DashedEdge extends CustomPainter {
  const _DashedEdge(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3 < m.length ? d + 3 : m.length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedEdge old) => old.color != color || old.radius != radius;
}

/// The rows on screen that carry an anchor ([ESetRow.anchor]), and the jump to one: once its
/// page is built, the row scrolls into view, its control takes the focus and a thin gold
/// outline fades out over a second (none with reduced motion), as a jump to a section does.
abstract final class ESetAnchors {
  static final Map<String, _SetRowAnchorState> _live = {};
  static int _jump = 0;

  /// Whether a row with [id] is on screen.
  static bool shown(String id) => _live[id]?.mounted ?? false;

  /// Shows row [id] (else [fallback], the row it sits under) once the page that holds it is
  /// built; false when neither appears within a few frames.
  static Future<bool> jump(String id, {String? fallback}) async {
    final n = ++_jump;
    for (var i = 0; i < 4; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (n != _jump) return false;
      final s = _live[id] ?? (fallback == null ? null : _live[fallback]);
      if (s != null && s.mounted) {
        s.show();
        return true;
      }
    }
    return false;
  }
}

/// The anchor of a Settings row that is no [ESetRow] (a custom block, a group's trailing
/// button, a list): search jumps to [child] as to an anchored row, focusing its first stop.
class SetAnchor extends StatefulWidget {
  const SetAnchor({super.key, required this.id, required this.child});

  /// The row's id in the settings registry ([SetId]).
  final String id;
  final Widget child;

  @override
  State<SetAnchor> createState() => _SetRowAnchorState();
}

class _SetRowAnchorState extends State<SetAnchor> with SingleTickerProviderStateMixin {
  final _focus = FocusNode(debugLabel: 'row anchor', skipTraversal: true);
  late final _cue = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000), value: 0);
  late final _fade = CurvedAnimation(parent: _cue, curve: const Interval(0, 0.75, curve: Curves.easeInCubic));

  @override
  void initState() {
    super.initState();
    ESetAnchors._live[widget.id] = this;
  }

  @override
  void didUpdateWidget(SetAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      if (ESetAnchors._live[old.id] == this) ESetAnchors._live.remove(old.id);
      ESetAnchors._live[widget.id] = this;
    }
  }

  @override
  void dispose() {
    if (ESetAnchors._live[widget.id] == this) ESetAnchors._live.remove(widget.id);
    _fade.dispose();
    _cue.dispose();
    _focus.dispose();
    super.dispose();
  }

  void show() {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Scrollable.ensureVisible(context, duration: reduce ? Duration.zero : Dur.base, alignment: 0.3);
    // The control first (the row's switch, select or button), else anything in the row.
    bool usable(FocusNode n) => n.canRequestFocus && !n.skipTraversal && n.context != null;
    final ctl = _AnchorControl.nodeIn(context);
    final target = ctl?.descendants.where(usable).firstOrNull ?? _focus.descendants.where(usable).firstOrNull;
    (target ?? _focus).requestFocus();
    if (!reduce) _cue.reverse(from: 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    // A jump target only: no semantics node of its own, so a screen reader reads the row's
    // words once, from the row (its focus node would gather them as a second label).
    return Focus(
      focusNode: _focus,
      includeSemantics: false,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (_, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: _fade.value == 0
              ? const BoxDecoration()
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: c.accent.withValues(alpha: c.accent.a * 0.8 * _fade.value), width: 1.5),
                ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Marks an anchored row's control, so a jump focuses it before the row's other stops.
class _AnchorControl extends StatefulWidget {
  const _AnchorControl({required this.child});

  final Widget child;

  /// The control's focus node in the anchored row around [context].
  static FocusNode? nodeIn(BuildContext context) {
    FocusNode? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is _AnchorControlState) {
        found = (e.state as _AnchorControlState)._node;
        return;
      }
      e.visitChildren(visit);
    }
    context.visitChildElements(visit);
    return found;
  }

  @override
  State<_AnchorControl> createState() => _AnchorControlState();
}

class _AnchorControlState extends State<_AnchorControl> {
  final _node = FocusNode(debugLabel: 'row control', skipTraversal: true, canRequestFocus: false);

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(focusNode: _node, includeSemantics: false, child: widget.child);
}

/// Gives [child] (a small icon button) a hit area of at least 44 px without changing its
/// layout: a press up to 22 px from its centre, inside the settings row around it, lands on it.
/// Only inside an [ESetRow]; elsewhere it is the child alone.
class EHitSlop extends SingleChildRenderObjectWidget {
  const EHitSlop({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSlop(Ctl.md);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderSlop).target = Ctl.md;
}

class _RenderSlop extends RenderProxyBox {
  _RenderSlop(this.target);

  double target;
  _RenderSlopHost? _host;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderObject? p = parent;
    while (p != null && p is! _RenderSlopHost) {
      p = p.parent;
    }
    _host = p as _RenderSlopHost?;
    _host?._slops.add(this);
  }

  @override
  void detach() {
    _host?._slops.remove(this);
    _host = null;
    super.detach();
  }
}

class _SlopHost extends SingleChildRenderObjectWidget {
  const _SlopHost({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSlopHost();
}

class _RenderSlopHost extends RenderProxyBox {
  final List<_RenderSlop> _slops = [];

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final s in _slops) {
      if (!s.attached || !s.hasSize) continue;
      final m = s.getTransformTo(this);
      final own = MatrixUtils.transformRect(m, Offset.zero & s.size);
      if (own.contains(position)) break;
      final wide = Rect.fromCenter(center: own.center, width: own.width < s.target ? s.target : own.width, height: own.height < s.target ? s.target : own.height);
      if (wide.contains(position)) {
        return result.addWithPaintTransform(
          transform: m,
          position: own.center,
          hitTest: (r, p) => s.hitTest(r, position: p),
        );
      }
    }
    return super.hitTestChildren(result, position: position);
  }
}

/// The info icon that carries an explanation: a tooltip on hover and on keyboard focus, and
/// the text itself for a screen reader. Settings rows use it so the main view shows labels only.
/// [words] with [control] beside them at the end while the words keep [minWords]
/// ([setRowMinWords] by default), else the control under the words at its own width: a custom
/// row that is not an [ESetRow]. [top] aligns both to the top instead of centring them.
class EBesideOrUnder extends StatelessWidget {
  const EBesideOrUnder({super.key, required this.words, required this.control, this.minWords, this.top = false});

  final Widget words;
  final Widget control;
  final double? minWords;
  final bool top;

  @override
  Widget build(BuildContext context) =>
      _WrapRow(gap: Sp.x6, runGap: Sp.x3, minWords: minWords ?? setRowMinWords, top: top, children: [words, control]);
}

/// [ESetRow]'s layout: the control at its own width at the right with the words in the
/// rest, while that leaves the words [minWords]; otherwise the control under the words.
class _WrapRow extends MultiChildRenderObjectWidget {
  const _WrapRow({required this.gap, required this.runGap, required this.minWords, this.top = false, required super.children});

  /// On one line, both at the top (a notice's actions) instead of centred (a row's control).
  final bool top;
  final double gap;
  final double runGap;
  final double minWords;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWrapRow(gap, runGap, minWords, top);

  @override
  void updateRenderObject(BuildContext context, _RenderWrapRow renderObject) => renderObject
    ..gap = gap
    ..runGap = runGap
    ..minWords = minWords
    ..top = top;
}

class _WrapRowData extends ContainerBoxParentData<RenderBox> {}

class _RenderWrapRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _WrapRowData>, RenderBoxContainerDefaultsMixin<RenderBox, _WrapRowData> {
  _RenderWrapRow(this._gap, this._runGap, this._minWords, this._top);

  bool _top;
  set top(bool v) {
    if (v == _top) return;
    _top = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  double _minWords;
  set minWords(double v) {
    if (v == _minWords) return;
    _minWords = v;
    markNeedsLayout();
  }

  RenderBox get _words => firstChild!;
  RenderBox get _control => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WrapRowData) child.parentData = _WrapRowData();
  }

  bool _fits(double width, double control) => control + _gap + _minWords <= width;

  @override
  double computeMinIntrinsicWidth(double height) => [_words.getMinIntrinsicWidth(height), _control.getMinIntrinsicWidth(height)].reduce((a, b) => a > b ? a : b);

  @override
  double computeMaxIntrinsicWidth(double height) => _words.getMaxIntrinsicWidth(height) + _gap + _control.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _height(width, (b, w) => b.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width, (b, w) => b.getMaxIntrinsicHeight(w));

  double _height(double width, double Function(RenderBox, double) h) {
    final cw = _control.getMaxIntrinsicWidth(double.infinity);
    if (_fits(width, cw)) {
      final a = h(_words, width - cw - _gap);
      final b = h(_control, cw);
      return a > b ? a : b;
    }
    return h(_words, width) + _runGap + h(_control, width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final c = _control.getDryLayout(BoxConstraints(maxWidth: width));
    if (_fits(width, c.width)) {
      final w = _words.getDryLayout(BoxConstraints.tightFor(width: width - c.width - _gap));
      return constraints.constrain(Size(width, w.height > c.height ? w.height : c.height));
    }
    final w = _words.getDryLayout(BoxConstraints.tightFor(width: width));
    return constraints.constrain(Size(width, w.height + _runGap + c.height));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    _control.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    final c = _control.size;
    final wd = _words.parentData! as _WrapRowData;
    final cd = _control.parentData! as _WrapRowData;
    if (_fits(width, c.width)) {
      // On one line, both centred on it, as the plain row does.
      _words.layout(BoxConstraints.tightFor(width: width - c.width - _gap), parentUsesSize: true);
      final h = _words.size.height > c.height ? _words.size.height : c.height;
      wd.offset = Offset(0, _top ? 0 : (h - _words.size.height) / 2);
      cd.offset = Offset(width - c.width, _top ? 0 : (h - c.height) / 2);
      size = constraints.constrain(Size(width, h));
    } else {
      _words.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      wd.offset = Offset.zero;
      cd.offset = Offset(0, _words.size.height + _runGap);
      size = constraints.constrain(Size(width, _words.size.height + _runGap + c.height));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}

/// The info (or help) icon that opens the row's explanation in a popover
/// (`popover.dart`): a hover shows the text as a tip ([ETip]); a click, Enter or Space opens the
/// popover at once beside the icon; a click outside, Esc or its ✕ closes it and the focus comes
/// back here. The icon is a Tab stop with the
/// desktop's focus ring and a button for screen readers, named by [title] (or [label]). With a
/// [title] the popover shows [icon] and the title on its first line, as the phone's info sheet
/// does; without one, the text alone.
class EInfoHint extends StatefulWidget {
  const EInfoHint(this.text, {super.key, this.title, this.icon, this.label, this.glyph = EIcons.info, this.size, this.onHelp, this.onOpen, this.action});

  final String text;

  /// Opens the Help topic that says more; the popover then ends in a "More in Help" link.
  final VoidCallback? onHelp;

  /// Opens a richer explanation in place of the popover (the network-modes dialog) and
  /// completes when it closes; [text] stays what a screen reader hears.
  final Future<void> Function()? onOpen;

  /// A choice the popover holds, as a button under the text ([EInfoPopover.action]).
  final InfoAction? action;

  /// The popover's first line (the row's name), with [icon] before it.
  final String? title;
  final IconData? icon;

  /// What a screen reader calls the icon when there is no [title]; "More information" when
  /// neither is given.
  final String? label;

  /// The icon itself: info, or help (the Send summary's "why").
  final IconData glyph;

  /// The icon's square: 20 u by default, inline with a row's title; [Ctl.inline] on a line of
  /// its own.
  final double? size;

  @override
  State<EInfoHint> createState() => EInfoHintState();
}

class EInfoHintState extends State<EInfoHint> {
  final _node = FocusNode(debugLabel: 'info hint');
  bool _hover = false;
  bool _open = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  /// Opens the popover beside the icon (the screenshot tour calls it too). Returns when it
  /// closes.
  Future<void> open() async {
    if (_open || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final root = Navigator.of(context, rootNavigator: true).context.findRenderObject();
    final anchor = box.localToGlobal(Offset.zero, ancestor: root) & box.size;
    final hadFocus = _node.hasFocus;
    setState(() => _open = true);
    if (widget.onOpen case final open?) {
      await open();
    } else {
      await showEInfoPopover(context, anchor: anchor, text: widget.text, title: widget.title, icon: widget.icon, help: widget.onHelp, action: widget.action);
    }
    if (!mounted) return;
    setState(() => _open = false);
    // Opened from the keyboard: the focus comes back to the icon (the route's scope gives it
    // back, this makes sure). Opened by a click, it stays where it was.
    if (hadFocus) _node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final size = widget.size ?? 20.u;
    final lit = _hover || _open;
    // Its text on hover; a click opens the popover, which says it in full.
    return ETip(
      widget.text,
      onClick: false,
      excludeFromSemantics: true,
      child: Semantics(
      button: true,
      label: widget.title ?? widget.label ?? context.l10n.deskKitInfoLabel,
      hint: widget.text,
      expanded: _open,
      excludeSemantics: true,
      onTap: open,
      child: FocusableActionDetector(
        focusNode: _node,
        mouseCursor: SystemMouseCursors.help,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(), SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => open())},
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: open,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              radius: Rad.xs,
              child: AnimatedContainer(
                duration: Dur.fast,
                width: size,
                height: size,
                decoration: BoxDecoration(color: lit ? c.hover : Colors.transparent, borderRadius: BorderRadius.circular(Rad.xs)),
                child: Icon(widget.glyph, size: Ctl.iconSm, color: lit ? c.text : c.dim),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}


/// A 4 px progress bar that holds still: it fills to [value] and only moves when the number
/// does. Null (no number yet) shows the empty track; the words beside it say the work runs.

class EProgress extends StatelessWidget {
  const EProgress({super.key, this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value ?? 0,
        minHeight: 4.u,
        backgroundColor: c.s3,
        // Progress is in progress: blue, never the brand gold.
        color: c.info,
      ),
    );
  }
}

class ESpinner extends StatelessWidget {
  const ESpinner({super.key, this._size, this.color});

  final double? _size;
  double get size => _size ?? 16.u;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color ?? context.dc.accent),
  );
}

/// The hairline between blocks.
class EDivider extends StatelessWidget {
  const EDivider({super.key, this.space});

  /// Defaults to [Sp.x6].
  final double? space;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.symmetric(vertical: space ?? Sp.x6), child: Divider(height: 1, thickness: 1, color: context.dc.line));
}

/// Collapsible "technical details" block.
class EDetails extends StatefulWidget {
  const EDetails({super.key, required this.title, required this.child, this.initiallyOpen = false, this.subtitle});

  final String title;

  /// Beside the title, dim: what is chosen inside ("· Smallest outputs").
  final String? subtitle;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<EDetails> createState() => _EDetailsState();
}

class _EDetailsState extends State<EDetails> {
  late bool _open = widget.initiallyOpen;

  void _fold() => setState(() => _open = false);

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final box = Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EInkWell(
            borderRadius: BorderRadius.circular(Rad.sm),
            onTap: () => setState(() => _open = !_open),
            child: Container(
              constraints: BoxConstraints(minHeight: Ctl.md),
              padding: EdgeInsets.symmetric(horizontal: Sp.x4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: Dur.base,
                    child: Icon(EIcons.chevronRight, size: Ctl.icon, color: c.dim),
                  ),
                  SizedBox(width: Sp.x2),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: widget.title),
                          if (widget.subtitle != null) TextSpan(text: ' ${widget.subtitle}', style: context.ts.bodyDim),
                        ],
                      ),
                      style: context.ts.strong.copyWith(color: c.dim),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ExpandFade(
            open: _open,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Sp.x4, 0, Sp.x4, Sp.x4),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
    // Esc with the focus in an open panel on the page folds it. In a dialog Esc closes the
    // dialog instead (the dialog is the top-most thing).
    return Actions(actions: {DismissIntent: _FoldAction(this)}, child: box);
  }
}

/// Esc in an [EDetails]: folds it when it is open on the page; otherwise hands Esc on up (a
/// disabled action would stop the search for one, so this one passes it along itself).
class _FoldAction extends DismissAction {
  _FoldAction(this.details);

  final _EDetailsState details;

  @override
  Object? invoke(DismissIntent intent) {
    if (details.mounted && details._open && (ModalRoute.of(details.context)?.isFirst ?? true)) {
      details._fold();
      return null;
    }
    return details.mounted ? Actions.maybeInvoke(details.context, intent) : null;
  }
}
