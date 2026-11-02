// SPDX-License-Identifier: Apache-2.0
/// The one desktop month picker (item 6, the owner 2026-11-02): a field in a row's control column
/// (calendar icon, "March 2020", chevron) that opens a small popover under it: the year between
/// ‹ › arrows, the twelve months in a 4 × 3 grid, and the block the month starts from. Recheck
/// balance and Restore use it; the phone's twin is `StartMonthChoice` (`ui/month_picker.dart`),
/// and both share `start_month.dart`. Months map to heights on mainnet only.
///
/// The 26.10.25 dialog opened on 2019, whose January to August are not offered (Epic Cash
/// starts in September 2019) yet looked like the offered months: clicks on them did nothing.
/// Here a month not offered is visibly off (faint, no edge) and the popover opens on the
/// chosen month, else on the first month offered.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart' show KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey;

import '../../l10n.dart' show localInt, localMonthShort, localMonthYear, localYear;
import '../../start_month.dart';
import '../desk_l10n.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'selectable.dart';

export '../../start_month.dart' show mainnetHeightForDate, StartMonth;

/// The start of a restore as a month (a year and a month, no day; the scan starts from the
/// first): the month field and, under it, the block the chosen month starts from (or [hint]),
/// with a warning when the month is this one or the one before.
class EStartDate extends StatelessWidget {
  const EStartDate({super.key, required this.date, required this.onChanged, this.label, this.hint});

  /// The chosen month's first day; null for none.
  final DateTime? date;

  /// Called with the first day of the month picked.
  final ValueChanged<DateTime?> onChanged;

  /// The field's words before a month is chosen ("Pick a month").
  final String? label;

  /// The line under the field before a month is chosen; none when null.
  final String? hint;

  /// The key of the recent-month warning, for tests.
  static const Key recentKey = ValueKey('start-date-recent');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final chosen = date == null ? null : StartMonth.of(date!);
    final line = chosen == null ? hint : l.restoreMonthStart(localInt(l, chosen.height));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Ctl.rowWide,
          child: EStartMonthField(month: chosen, placeholder: label, size: EBtnSize.md, onChanged: (m) => onChanged(m.firstDay)),
        ),
        if (line != null) ...[SizedBox(height: Sp.x1), Text(line, style: ts.small)],
        if (chosen != null && startMonthRecent(chosen, DateTime.now())) EStartMonthRecent(key: recentKey),
      ],
    );
  }
}

/// The warning under a month that is this one or the one before: older coins may be missed.
class EStartMonthRecent extends StatelessWidget {
  const EStartMonthRecent({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: EdgeInsets.only(top: Sp.x1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.u),
              child: Icon(EIcons.alert, size: Ctl.iconSm, color: c.warn),
            ),
            SizedBox(width: 6.u),
            Flexible(
              child: Text(context.l10n.restoreMonthRecent, style: ts.small.copyWith(color: c.warn)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The month field: a select-like field (the [ESelect] look) with a calendar glyph, the month
/// or [placeholder], and a chevron. A click, Enter or Space opens [showEStartMonthPopover]
/// under it; its semantics say whether the popover is open. It fills its parent's width
/// (an [ERowControl] in a Settings row).
class EStartMonthField extends StatefulWidget {
  const EStartMonthField({
    super.key,
    required this.month,
    required this.onChanged,
    this.placeholder,
    this.size = EBtnSize.sm,
    this.semanticLabel,
    this.invalid = false,
  });

  final StartMonth? month;
  final ValueChanged<StartMonth> onChanged;

  /// Before a month is chosen; "Pick a month" when null.
  final String? placeholder;

  /// `sm` ([Ctl.sm], a Settings row) or `md` (44, a form's field).
  final EBtnSize size;

  /// The field's name for a screen reader; the dialog title when null.
  final String? semanticLabel;

  /// Drawn with the risk edge (Recheck without a month).
  final bool invalid;

  static const Key fieldKey = ValueKey('start-date-pick');

  @override
  State<EStartMonthField> createState() => _EStartMonthFieldState();
}

class _EStartMonthFieldState extends State<EStartMonthField> {
  bool _open = false;
  bool _hover = false;
  final _node = FocusNode(debugLabel: 'start month field');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_open || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final root = Navigator.of(context, rootNavigator: true).context.findRenderObject();
    final anchor = box.localToGlobal(Offset.zero, ancestor: root) & box.size;
    setState(() => _open = true);
    final picked = await showEStartMonthPopover(context, anchor: anchor, initial: widget.month);
    if (!mounted) return;
    setState(() => _open = false);
    // The focus comes back to the field, as it does from the help popover.
    _node.requestFocus();
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final m = widget.month;
    final text = m == null ? (widget.placeholder ?? l.restorePickMonthShort) : localMonthYear(l, m.firstDay);
    final edge = _open ? c.accent : (widget.invalid ? c.risk : (_hover ? c.faint : c.lineField));
    return Semantics(
      button: true,
      expanded: _open,
      label: widget.semanticLabel ?? l.restoreDatePickerTitle,
      value: m == null ? null : text,
      excludeSemantics: true,
      onTap: _pick,
      child: FocusableActionDetector(
        key: EStartMonthField.fieldKey,
        focusNode: _node,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _pick())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: _pick,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                height: widget.size == EBtnSize.md ? Ctl.md : Ctl.sm,
                padding: EdgeInsets.only(left: Sp.x3, right: Sp.x2),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: edge),
                ),
                child: NoSelect(
                  child: Row(
                    children: [
                      Icon(EIcons.calendar, size: Ctl.iconSm, color: c.dim),
                      SizedBox(width: Sp.x2),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: m == null ? ts.body.copyWith(color: c.dim) : ts.body,
                        ),
                      ),
                      Icon(EIcons.chevronDown, size: Ctl.iconSm, color: c.dim),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The popover's width.
double get startMonthPopoverWidth => 300.u;

/// Opens the month popover under [anchor] (the field's rectangle in the root navigator's
/// coordinates), right edge on the field's right edge. It opens on [initial]'s year, else on
/// the first month offered (never today). Returns the month picked, or null when closed
/// (Esc, a click outside).
Future<StartMonth?> showEStartMonthPopover(BuildContext context, {required Rect anchor, StartMonth? initial, DateTime? now}) => showGeneralDialog<StartMonth>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.commonClose,
  barrierColor: Colors.transparent,
  transitionDuration: Dur.fast,
  pageBuilder: (context, _, _) => CustomSingleChildLayout(
    delegate: StartMonthPopoverLayout(anchor: anchor, margin: Sp.x2, gap: Sp.x1, width: startMonthPopoverWidth),
    child: EStartMonthPicker(initial: initial, now: now ?? DateTime.now()),
  ),
  transitionBuilder: (context, anim, _, child) => MediaQuery.disableAnimationsOf(context) ? child : FadeTransition(opacity: anim, child: child),
);

/// Where the popover goes: under the field with its right edge on the field's (the control
/// column), else its left edge on the field's when there is no room to the left; above the
/// field when there is no room under it. Never outside the window less [margin].
class StartMonthPopoverLayout extends SingleChildLayoutDelegate {
  const StartMonthPopoverLayout({required this.anchor, required this.margin, required this.gap, required this.width});

  final Rect anchor;
  final double margin, gap, width;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(
    minWidth: math.max(0, math.min(width, constraints.maxWidth - 2 * margin)),
    maxWidth: math.max(0, math.min(width, constraints.maxWidth - 2 * margin)),
    maxHeight: math.max(0, constraints.maxHeight - 2 * margin),
  );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.right - childSize.width;
    if (x < margin) x = anchor.left;
    x = x.clamp(margin, math.max(margin, size.width - margin - childSize.width));
    var y = anchor.bottom + gap;
    if (y + childSize.height > size.height - margin) {
      final above = anchor.top - gap - childSize.height;
      y = above >= margin ? above : size.height - margin - childSize.height;
    }
    y = y.clamp(margin, math.max(margin, size.height - margin - childSize.height));
    return Offset(x.roundToDouble(), y.roundToDouble());
  }

  @override
  bool shouldRelayout(StartMonthPopoverLayout old) => anchor != old.anchor || margin != old.margin || gap != old.gap || width != old.width;
}

/// The popover: the year between its arrows, the twelve months, and the block the month under
/// the keyboard cursor starts from. Keys: arrows move the cursor (across years), PageUp and
/// PageDown change the year, Enter or Space picks, Esc closes. Tab goes round the arrows and
/// the cursor's month and stays in the popover. [now] bounds the months offered.
class EStartMonthPicker extends StatefulWidget {
  const EStartMonthPicker({super.key, this.initial, required this.now});

  final StartMonth? initial;
  final DateTime now;

  /// The key of a month's cell, for tests: `start-month-2021-07`.
  static Key monthKey(StartMonth m) => ValueKey('start-month-$m');

  static const Key earlierKey = ValueKey('start-month-earlier');
  static const Key laterKey = ValueKey('start-month-later');
  static const Key blockKey = ValueKey('start-month-block');

  @override
  State<EStartMonthPicker> createState() => _EStartMonthPickerState();
}

class _EStartMonthPickerState extends State<EStartMonthPicker> {
  /// The month the keyboard is on; the year shown is its year.
  late StartMonth _cursor = _clamp(widget.initial ?? firstStartMonth);

  final List<FocusNode> _cells = List.generate(12, (i) => FocusNode(debugLabel: 'month ${i + 1}'));

  StartMonth get _last => StartMonth.of(widget.now);

  StartMonth _clamp(StartMonth m) => m < firstStartMonth ? firstStartMonth : (m > _last ? _last : m);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCursor());
  }

  @override
  void dispose() {
    for (final n in _cells) {
      n.dispose();
    }
    super.dispose();
  }

  void _focusCursor() {
    if (mounted) _cells[_cursor.month - 1].requestFocus();
  }

  /// The cursor on [m] (kept within the months offered), its cell focused.
  void _moveTo(StartMonth m, {bool focus = true}) {
    setState(() => _cursor = _clamp(m));
    if (focus) WidgetsBinding.instance.addPostFrameCallback((_) => _focusCursor());
  }

  StartMonth _plus(int months) {
    final i = _cursor.year * 12 + _cursor.month - 1 + months;
    return StartMonth(i ~/ 12, i % 12 + 1);
  }

  /// The same month [years] away, or the nearest offered one in that year.
  void _year(int years, {bool focus = true}) => _moveTo(StartMonth(_cursor.year + years, _cursor.month), focus: focus);

  void _pick(StartMonth m) => Navigator.of(context).pop(m);

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    // Only while a month has the focus: the arrows' own buttons keep Enter and Space.
    final onMonth = _cells.any((n) => n.hasPrimaryFocus);
    final step = {LogicalKeyboardKey.arrowLeft: -1, LogicalKeyboardKey.arrowRight: 1, LogicalKeyboardKey.arrowUp: -4, LogicalKeyboardKey.arrowDown: 4}[k];
    if (step != null && onMonth) {
      final to = _plus(step);
      if (startMonthOffered(to, widget.now)) _moveTo(to);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageUp) {
      _year(-1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageDown) {
      _year(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final year = _cursor.year;
    final title = l.restoreDatePickerTitle;
    return Semantics(
      container: true,
      role: SemanticsRole.dialog,
      label: title,
      child: Actions(
        actions: {DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => Navigator.of(context).maybePop())},
        child: Focus(
          skipTraversal: true,
          onKeyEvent: _key,
          debugLabel: 'month popover',
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: c.popover,
              child: Padding(
                padding: EdgeInsets.all(Sp.x3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        EIconButton(
                          key: EStartMonthPicker.earlierKey,
                          icon: EIcons.chevronLeft,
                          label: l.restoreMonthEarlierYear,
                          size: EBtnSize.md,
                          onPressed: year > firstStartMonth.year ? () => _year(-1, focus: false) : null,
                        ),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              localYear(l, DateTime(year)),
                              textAlign: TextAlign.center,
                              style: ts.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ),
                        ),
                        EIconButton(
                          key: EStartMonthPicker.laterKey,
                          icon: EIcons.chevronRight,
                          label: l.restoreMonthLaterYear,
                          size: EBtnSize.md,
                          onPressed: year < _last.year ? () => _year(1, focus: false) : null,
                        ),
                      ],
                    ),
                    SizedBox(height: Sp.x2),
                    for (var row = 0; row < 3; row++) ...[
                      if (row > 0) SizedBox(height: Sp.x1),
                      Row(
                        children: [
                          for (var col = 0; col < 4; col++) ...[
                            if (col > 0) SizedBox(width: Sp.x1),
                            Expanded(child: _cell(StartMonth(year, row * 4 + col + 1))),
                          ],
                        ],
                      ),
                    ],
                    SizedBox(height: Sp.x2),
                    Text(l.restoreMonthStart(localInt(l, _cursor.height)), key: EStartMonthPicker.blockKey, style: ts.caption),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(StartMonth m) => _MonthCell(
    month: m,
    node: _cells[m.month - 1],
    selected: widget.initial == m,
    current: m == _last,
    cursor: m == _cursor,
    enabled: startMonthOffered(m, widget.now),
    onPick: () => _pick(m),
    onFocus: () {
      if (_cursor != m) setState(() => _cursor = m);
    },
  );
}

/// One month, at least 44 u tall. Offered: the text colour with a hairline; selected: the
/// neutral raised fill (s4 and its strong hairline, as [ESegmented]), never the gold. Not
/// offered: faint, no edge, not pressable. Only the keyboard cursor's month is a Tab stop.
class _MonthCell extends StatefulWidget {
  const _MonthCell({
    required this.month,
    required this.node,
    required this.selected,
    required this.current,
    required this.cursor,
    required this.enabled,
    required this.onPick,
    required this.onFocus,
  });

  final StartMonth month;
  final FocusNode node;
  final bool selected;

  /// This month: a quiet underline.
  final bool current;
  final bool cursor;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onFocus;

  @override
  State<_MonthCell> createState() => _MonthCellState();
}

class _MonthCellState extends State<_MonthCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final sel = widget.selected;
    final on = widget.enabled;
    final fg = on ? c.text : c.faint;
    return Semantics(
      button: true,
      selected: sel,
      enabled: on,
      label: localMonthYear(l, widget.month.firstDay),
      excludeSemantics: true,
      onTap: on ? widget.onPick : null,
      child: FocusableActionDetector(
        key: EStartMonthPicker.monthKey(widget.month),
        focusNode: widget.node..skipTraversal = !widget.cursor,
        enabled: on,
        mouseCursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v && on),
        onFocusChange: (f) {
          setState(() {});
          if (f) widget.onFocus();
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => on ? widget.onPick() : null)},
        child: GestureDetector(
          onTap: on ? widget.onPick : null,
          child: FocusRing(
            focused: widget.node.hasFocus,
            child: AnimatedContainer(
              duration: Dur.fast,
              height: Ctl.md,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? c.s4 : (_hover ? c.hover : Colors.transparent),
                borderRadius: BorderRadius.circular(Rad.sm),
                border: Border.all(color: sel ? c.lineStrong : (on ? c.line : Colors.transparent)),
              ),
              child: NoSelect(
                child: Opacity(
                  opacity: on ? 1 : 0.5,
                  child: Text(
                    localMonthShort(l, widget.month.firstDay),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Fs.md,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                      decoration: widget.current ? TextDecoration.underline : null,
                      decorationColor: c.lineStrong,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
