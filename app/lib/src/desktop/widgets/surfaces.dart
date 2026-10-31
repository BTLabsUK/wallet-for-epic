// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

export '../../ui/badge.dart';

import '../desk_l10n.dart';
import '../../log.dart' show logWarn;
import '../../ui/theme/protocol.dart' show CornerTicksPainter, GridFieldPainter;
import '../theme/icons.dart';
import '../../ui/badge.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'selectable.dart';
import 'motion.dart';
import 'popover.dart';

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
    final pad = (padding ?? EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x5)).resolve(Directionality.of(context));
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHead)
            Container(
              key: const ValueKey('epanel-head'),
              // Starts where the body starts (Sp.x5 over an unpadded body); a custom head ends
              // close to the edge for its icon button.
              padding: EdgeInsets.fromLTRB(
                pad.left < Sp.x4 ? Sp.x5 : pad.left,
                head != null ? 0 : Sp.x2,
                head != null ? Sp.x2 : (pad.right < Sp.x4 ? Sp.x5 : pad.right),
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
              padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x3),
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
    return Container(
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.xs),
      ),
      child: CustomPaint(
        painter: grid ? GridFieldPainter(c.grid.withValues(alpha: c.grid.a * 2.2)) : null,
        foregroundPainter: CornerTicksPainter(c.tick),
        child: child,
      ),
    );
  }
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

/// A status dot: shape and colour, never colour alone (filled ok, ring warn, cross risk).
class EStatusDot extends StatelessWidget {
  const EStatusDot(this.tone, {super.key, this.size = 8});

  final ETone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final (fg, _) = tone.colors(c);
    final color = tone == ETone.neutral ? c.faint : fg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone == ETone.ok || tone == ETone.risk ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}

/// An inline message in the flow: tinted, with an icon, title, text and actions on the right.
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
  });

  final String title;
  final String? text;

  /// Full-width content under the text, inside the panel (a progress bar).
  final Widget? below;

  /// The text's colour when it is not the usual one (a payment request's dropped parts).
  final Color? textColor;
  final ETone tone;
  final IconData? icon;
  final List<Widget> actions;

  /// Puts [actions] on their own wrapping row under the text (several or long buttons).
  final bool actionsBelow;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final (fg, bg) = tone.colors(c);
    final iconColor = tone == ETone.neutral ? c.dim : fg;
    final glyph = icon ??
        switch (tone) {
          ETone.ok => EIcons.okCircle,
          ETone.warn => EIcons.alert,
          ETone.risk => EIcons.error,
          _ => EIcons.info,
        };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      decoration: BoxDecoration(
        // In progress (info) is not a warning: the neutral panel with a blue icon.
        color: tone == ETone.neutral || tone == ETone.ok || tone == ETone.info ? c.s1 : (tone == ETone.gold ? c.accentFaint : bg),
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(
          color: tone == ETone.neutral || tone == ETone.ok || tone == ETone.info ? c.lineStrong : fg.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(glyph, size: Ctl.icon, color: iconColor),
          ),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                if (text != null) ...[
                  const SizedBox(height: 2),
                  Text(text!, style: textColor == null ? ts.small : ts.small.copyWith(color: textColor)),
                ],
                if (below != null) ...[
                  SizedBox(height: Sp.x2),
                  SizedBox(width: double.infinity, child: below),
                ],
                if (actionsBelow && actions.isNotEmpty) ...[
                  SizedBox(height: Sp.x3),
                  Wrap(spacing: Sp.x2, runSpacing: Sp.x2, children: actions),
                ],
              ],
            ),
          ),
          if (!actionsBelow && actions.isNotEmpty) ...[
            SizedBox(width: Sp.x3),
            Wrap(spacing: Sp.x2, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Key/value facts in two columns.
class EFacts extends StatelessWidget {
  const EFacts(this.rows, {super.key, this._labelWidth});

  final List<(String, Widget)> rows;
  final double? _labelWidth;
  double get labelWidth => _labelWidth ?? 140.u;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.u),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: labelWidth, child: Text(k, style: ts.bodyDim)),
                SizedBox(width: Sp.x6),
                Expanded(child: DefaultTextStyle.merge(style: ts.body, child: v)),
              ],
            ),
          ),
      ],
    );
  }
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

/// An address to read and copy: the first and last six characters in the accent.
class EAddress extends StatelessWidget {
  const EAddress(this.address, {super.key, this.large = false, this.onCopied, this.copyLabel, this.copy = true, this.extra});

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

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final base = ts.mono(size: large ? 14.5 : Fs.sm);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    // The highlight marks the address itself, not the server after "@", ".onion" or a URL.
    final at = address.indexOf('@');
    final onion = at < 0 && address.toLowerCase().endsWith('.onion');
    final cut = at > 0 ? at : (onion ? address.length - 6 : address.length);
    final a = address.substring(0, cut);
    final rest = address.substring(cut);
    final marked = a.length > 14 && !a.startsWith('http');
    final keySpans = marked
        ? [
            TextSpan(text: a.substring(0, 6), style: hl),
            TextSpan(text: a.substring(6, a.length - 6)),
            TextSpan(text: a.substring(a.length - 6), style: hl),
          ]
        : [TextSpan(text: a)];
    final restStyle = base.copyWith(color: c.dim);
    // When the address needs two lines it breaks only before "@": the server stays whole on
    // the last line, never a server cut in the middle of its name.
    final text = LayoutBuilder(
      builder: (context, box) {
        final whole = TextSpan(style: base, children: [...keySpans, TextSpan(text: rest, style: restStyle)]);
        if (!rest.startsWith('@') || !box.maxWidth.isFinite) return SelectableText.rich(whole);
        final tp = TextPainter(text: whole, textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context), maxLines: 1)..layout();
        final fits = tp.width <= box.maxWidth;
        tp.dispose();
        if (fits) return SelectableText.rich(whole);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(TextSpan(style: base, children: keySpans)),
            Text(rest, style: restStyle, softWrap: false, overflow: TextOverflow.fade),
          ],
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
          Expanded(child: text),
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
  });

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
        ? EButton(label: label, icon: icon, size: widget.size, kind: widget.kind, tabStop: widget.tabStop ?? true, onPressed: _copy)
        : EIconButton(icon: icon, label: label, color: _done ? (_failed ? context.dc.risk : context.dc.ok) : null, tabStop: widget.tabStop ?? false, onPressed: _copy);
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
              child: Text(text!, style: ts.bodyDim, textAlign: TextAlign.center),
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

/// A settings group: section head, then rows in one enclosure.
class ESetGroup extends StatelessWidget {
  const ESetGroup({super.key, this.title, required this.rows, this.trailing, this.gap = true});

  final String? title;
  final List<Widget> rows;
  final Widget? trailing;

  /// The space below the group; off when the caller sets it (a tour target ends at the box).
  final bool gap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.only(bottom: gap ? Sp.x8 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ESectionHead(title!, top: 0, trailing: trailing),
          Container(
            decoration: BoxDecoration(
              color: c.s1,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A settings row: title and one line on the left, the control on the right; [stacked] puts
/// the control under the text (wide controls such as a combobox).
class ESetRow extends StatelessWidget {
  const ESetRow({super.key, this.title, this.text, this.hint, this.hintTitle, this.hintIcon, this.hintHelp, this.control, this.stacked = false, this.wrap = false, this.below, this.leading, this.badge});

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

  /// For a control sized to its words (it is no [ERowControl]): beside the words while both
  /// fit on one line, under them when a narrow window, big text or long words leave no room.
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
        if (title != null && hint == null) Text(title!, style: ts.strong),
        if (title != null && hint != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(title!, style: ts.strong)),
              SizedBox(width: Sp.x1),
              EInfoHint(hint!, title: hintTitle, icon: hintIcon, onHelp: hintHelp),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked || control == null) ...[
            words,
            if (control != null) ...[SizedBox(height: Sp.x3), control!],
          ] else if (wrap)
            _WrapRow(gap: Sp.x6, runGap: Sp.x3, minWords: 160.u, children: [words, control!])
          else
            Row(
              children: [
                Expanded(child: words),
                SizedBox(width: Sp.x6),
                control!,
              ],
            ),
          if (below != null) ...[SizedBox(height: Sp.x3), below!],
        ],
      ),
    );
  }
}

/// The info icon that carries an explanation: a tooltip on hover and on keyboard focus, and
/// the text itself for a screen reader. Settings rows use it so the main view shows labels only.
/// [ESetRow.wrap]'s layout: the control at its own width at the right with the words in the
/// rest, while that leaves the words [minWords]; otherwise the control under the words.
class _WrapRow extends MultiChildRenderObjectWidget {
  const _WrapRow({required this.gap, required this.runGap, required this.minWords, required super.children});

  final double gap;
  final double runGap;
  final double minWords;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWrapRow(gap, runGap, minWords);

  @override
  void updateRenderObject(BuildContext context, _RenderWrapRow renderObject) => renderObject
    ..gap = gap
    ..runGap = runGap
    ..minWords = minWords;
}

class _WrapRowData extends ContainerBoxParentData<RenderBox> {}

class _RenderWrapRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _WrapRowData>, RenderBoxContainerDefaultsMixin<RenderBox, _WrapRowData> {
  _RenderWrapRow(this._gap, this._runGap, this._minWords);

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
      wd.offset = Offset(0, (h - _words.size.height) / 2);
      cd.offset = Offset(width - c.width, (h - c.height) / 2);
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
/// (`popover.dart`): a click, Enter or Space opens it at once beside the icon; a click outside,
/// Esc or its ✕ closes it and the focus comes back here. The icon is a Tab stop with the
/// desktop's focus ring and a button for screen readers, named by [title] (or [label]). With a
/// [title] the popover shows [icon] and the title on its first line, as the phone's info sheet
/// does; without one, the text alone.
class EInfoHint extends StatefulWidget {
  const EInfoHint(this.text, {super.key, this.title, this.icon, this.label, this.glyph = EIcons.info, this.size, this.onHelp});

  final String text;

  /// Opens the Help topic that says more; the popover then ends in a "More in Help" link.
  final VoidCallback? onHelp;

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
    await showEInfoPopover(context, anchor: anchor, text: widget.text, title: widget.title, icon: widget.icon, help: widget.onHelp);
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
    return Semantics(
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
    );
  }
}


/// A 4 px progress bar; null [value] runs indeterminate.

class EProgress extends StatelessWidget {
  const EProgress({super.key, this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
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
          InkWell(
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
