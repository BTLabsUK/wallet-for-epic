// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../desk_l10n.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'data.dart' show ESelect, ESelectItem;
import 'keyboard.dart';
import 'selectable.dart';
import 'tip.dart';
import '../../text_join.dart';

/// Label, control, then help or error. [aside] sits at the label's right (e.g. "Available …").
class EField extends StatelessWidget {
  const EField({
    super.key,
    required this.label,
    required this.child,
    this.optional = false,
    this.help,
    this.error,
    this.aside,
    this.reserveError = false,
    this.labelTrailing,
  });

  final String label;
  final Widget child;
  final bool optional;
  final String? help;
  final String? error;
  final Widget? aside;

  /// Right after the label (Send's "Over Tor" tag).
  final Widget? labelTrailing;

  /// Keeps the error line's height when there is no error (and no help), so the controls
  /// below do not move when one appears.
  final bool reserveError;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The aside goes under the label when both do not fit on one line.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: Sp.x3,
          runSpacing: Sp.x1,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label, style: ts.label),
                if (optional) ...[
                  SizedBox(width: Sp.x2),
                  Text(context.l10n.deskKitOptional, style: ts.small.copyWith(color: c.faint)),
                ],
                ?labelTrailing,
              ],
            ),
            ?aside,
          ],
        ),
        SizedBox(height: 6.u),
        _EFieldLabel(label: label, child: child),
        if (error != null) ...[
          SizedBox(height: 6.u),
          _line(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(EIcons.error, size: Ctl.iconSm, color: c.risk),
              ),
              SizedBox(width: 6.u),
              Expanded(
                child: Text(error!, style: ts.small.copyWith(color: c.risk, fontWeight: FontWeight.w500)),
              ),
            ],
          )),
        ] else if (help != null) ...[
          SizedBox(height: 6.u),
          _line(Text(help!, style: ts.small)),
        ] else if (reserveError) ...[
          // One fixed line the error or hint fills, no more (UD-010).
          SizedBox(height: 6.u + 20.u),
        ],
      ],
    );
  }

  /// With [reserveError], an error or hint line takes at least the reserved line, so the field
  /// below stays put when one comes or goes.
  Widget _line(Widget child) => reserveError ? ConstrainedBox(constraints: BoxConstraints(minHeight: 20.u), child: child) : child;
}

/// Hands an [EField]'s label to the [EInput] inside it, as the field's accessible name.
class _EFieldLabel extends InheritedWidget {
  const _EFieldLabel({required this.label, required super.child});

  final String label;

  static String? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_EFieldLabel>()?.label;

  @override
  bool updateShouldNotify(_EFieldLabel old) => label != old.label;
}

/// A 44 px text field. [mono] for addresses, hosts and amounts. [trailing] holds unit text or
/// small icon buttons inside the right edge.
class EInput extends StatefulWidget {
  const EInput({
    super.key,
    this.controller,
    this.hint,
    this.mono = false,
    this.obscure = false,
    this.invalid = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.trailingTabStop = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
    this.semanticLabel,
    this.textInputAction,
    this.size = EBtnSize.md,
    this.fadeEnd = false,
    this.line = false,
  });

  /// No box: a hairline under the text, as [ESearch] draws it. One line only.
  final bool line;

  /// A long one-line value fades out over its last 24 u before [trailing] instead of being cut
  /// through a glyph (an address under the field's buttons, UD-013).
  final bool fadeEnd;

  final TextEditingController? controller;
  final String? hint;
  final bool mono;
  final bool obscure;
  final bool invalid;
  final bool enabled;
  final IconData? leading;
  final Widget? trailing;

  /// Lets [trailing] hold Tab stops (a button such as "All"); its icons opt out themselves.
  final bool trailingTabStop;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  /// Above 1 the field grows to a text area.
  final int maxLines;
  final FocusNode? focusNode;

  /// The name a screen reader reads; by default the label of the [EField] around it, else [hint].
  final String? semanticLabel;

  /// The soft keyboard's action; in an [EForm] "next", or "done" in its last field.
  final TextInputAction? textInputAction;

  /// `md` (44, every form field) or `sm` ([Ctl.sm], a Settings row's field); one line only.
  final EBtnSize size;

  @override
  State<EInput> createState() => _EInputState();
}

class _EInputState extends State<EInput> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hover = false;
  EFormState? _form;

  bool get _multi => widget.maxLines > 1 && !widget.obscure;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = EForm.maybeOf(context);
    if (form == _form) return;
    _form?.unregister(_focus);
    _form = form;
    if (!_multi) _form?.register(_focus);
  }

  void _onFocus() => setState(() {});

  /// Enter: the field's own action, else the form's next field or main action.
  void _submitted(String text) {
    if (widget.onSubmitted != null) return widget.onSubmitted!(text);
    _form?.enter(_focus);
  }

  @override
  void dispose() {
    _form?.unregister(_focus);
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final focused = _focus.hasFocus;
    final border = widget.invalid
        ? c.risk
        : focused
        ? c.accent
        : (_hover ? c.dim : c.lineField);
    final style = widget.mono ? ts.mono(size: Fs.sm) : ts.body;
    final multi = widget.maxLines > 1;
    final line = widget.line && !multi;
    final sm = (widget.size == EBtnSize.sm || line) && !multi;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Dur.fast,
        height: sm ? Ctl.sm : null,
        constraints: sm ? null : BoxConstraints(minHeight: multi ? 80.u : Ctl.md),
        decoration: line
            // The line look: no fill, no box; the hairline under the text takes the
            // field's states (dim on hover, the accent with focus).
            ? BoxDecoration(border: Border(bottom: BorderSide(color: border, width: focused ? 1.5 : 1)))
            : BoxDecoration(
                color: c.s2,
                borderRadius: BorderRadius.circular(Rad.sm),
                border: Border.all(color: border),
                boxShadow: focused
                    ? [
                        BoxShadow(color: widget.invalid ? c.riskSoft : c.accentSoft, spreadRadius: 3.u),
                      ]
                    : null,
              ),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: Row(
            crossAxisAlignment: multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (widget.leading != null)
                Padding(
                  padding: EdgeInsets.only(left: line ? Sp.x1 : Sp.x3),
                  child: Icon(widget.leading, size: line ? Ctl.iconSm + 2.u : Ctl.icon, color: line && focused ? c.dim : c.faint),
                ),
              Expanded(
                child: _FadeEnd(
                  on: widget.fadeEnd && !multi && widget.trailing != null,
                  child: Semantics(
                  label: widget.semanticLabel ?? _EFieldLabel.of(context) ?? widget.hint,
                  child: TextField(
                    controller: widget.controller,
                    // A mouse caret and selection, never the phone's teardrop handles.
                    selectionControls: desktopTextSelectionControls,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    obscureText: widget.obscure,
                    autofocus: widget.autofocus,
                    maxLines: widget.obscure ? 1 : widget.maxLines,
                    minLines: multi ? 3 : 1,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    onSubmitted: _submitted,
                    // Enter keeps the focus in the field (a wrong password can be retyped);
                    // the form moves it when there is a next field.
                    onEditingComplete: widget.onSubmitted != null || _form != null ? () {} : null,
                    textInputAction: widget.textInputAction ?? (_form == null || _multi ? null : TextInputAction.next),
                    style: style,
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: ts.body.copyWith(color: c.faint),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: line ? Sp.x2 : Sp.x3,
                        vertical: multi ? Sp.x3 : (sm ? 0 : 12),
                      ),
                    ),
                  ),
                  ),
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: EdgeInsets.only(right: Sp.x1),
                  // Icons inside a field (eye, clear, paste) are never Tab stops.
                  child: ExcludeFocusTraversal(excluding: !widget.trailingTabStop, child: widget.trailing!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one search field of the desktop: a search glyph, the words on a hairline (no box), a
/// clear button once there is text. [Ctl.sm] tall, so it sits on one centre line with the tabs
/// and buttons of its row; [width] wide (260 u), or its parent's width when null.
/// [label] names it to a screen reader; [clearLabel] the clear button. Clearing empties
/// [controller] and reports it through [onChanged] (or [onClear] when given).
class ESearch extends StatefulWidget {
  const ESearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    required this.clearLabel,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.width,
    this.clearKey,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final String clearLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;

  /// Null fills the parent; [double.nan] takes the standard width, [standardWidth].
  final double? width;
  final Key? clearKey;

  static double get standardWidth => 260.u;

  @override
  State<ESearch> createState() => _ESearchState();
}

class _ESearchState extends State<ESearch> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ESearch old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  void _clear() {
    if (widget.onClear != null) return widget.onClear!();
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final field = EInput(
      controller: widget.controller,
      line: true,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      hint: widget.hint,
      leading: EIcons.search,
      semanticLabel: widget.label,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      trailing: widget.controller.text.isEmpty ? null : EIconButton(key: widget.clearKey, icon: EIcons.close, label: widget.clearLabel, size: EBtnSize.inline, onPressed: _clear),
    );
    final w = widget.width;
    if (w == null) return field;
    return SizedBox(width: w.isNaN ? ESearch.standardWidth : w, child: field);
  }
}

/// A password field with a show/hide toggle. The eye is not a Tab stop; Alt+F8 (Ctrl+Shift+P off
/// Windows) in the field shows or hides the password.
class EPasswordInput extends StatefulWidget {
  const EPasswordInput({
    super.key,
    this.controller,
    this.hint,
    this.invalid = false,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool invalid;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final TextInputAction? textInputAction;

  @override
  State<EPasswordInput> createState() => _EPasswordInputState();
}

class _EPasswordInputState extends State<EPasswordInput> {
  bool _show = false;

  void _toggle() => setState(() => _show = !_show);

  /// Alt+F8 is the Windows sign-in key; GNOME takes it (resize window), so other systems use
  /// Ctrl+Shift+P.
  static bool get _windows => defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      _windows ? const SingleActivator(LogicalKeyboardKey.f8, alt: true) : const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true): _toggle,
    },
    child: EInput(
      controller: widget.controller,
      hint: widget.hint,
      obscure: !_show,
      invalid: widget.invalid,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      semanticLabel: widget.semanticLabel,
      textInputAction: widget.textInputAction,
      trailing: EIconButton(
        icon: _show ? EIcons.eyeOff : EIcons.eye,
        label: '${_show ? 'Hide' : 'Show'} (${_windows ? 'Alt+F8' : 'Ctrl+Shift+P'})',
        tabStop: false,
        onPressed: _toggle,
      ),
    ),
  );
}

/// On/off switch: 40×24 track, label and description beside it when given.
class ESwitch extends StatelessWidget {
  const ESwitch({super.key, required this.value, this.onChanged, this.label, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Shown beside the track.
  final String? label;

  /// Read by screen readers only, for a switch whose row already shows its title.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final enabled = onChanged != null;
    final track = AnimatedContainer(
      duration: Dur.base,
      width: 40.u,
      height: 24.u,
      padding: EdgeInsets.all(3.u),
      decoration: BoxDecoration(
        color: value ? c.accent : c.s3,
        borderRadius: BorderRadius.circular(12.u),
        border: Border.all(color: value ? c.accent : c.lineField),
      ),
      child: AnimatedAlign(
        duration: Dur.base,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16.u,
          height: 16.u,
          decoration: BoxDecoration(color: value ? c.accentInk : c.dim, shape: BoxShape.circle),
        ),
      ),
    );
    return Semantics(
      toggled: value,
      label: label ?? semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onChanged?.call(!value))},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: enabled ? () => onChanged!(!value) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FocusRing(focused: Focus.of(context).hasFocus, radius: 12.u, child: track),
                  if (label != null) ...[
                    SizedBox(width: Sp.x3),
                    Text(label!, style: context.ts.body),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A segment of [ESegmented].
class ESegment<T> {
  const ESegment(this.value, this.label, {this.icon, this.count, this.enabled = true, this.tooltip, this.badge});

  final T value;
  final String label;
  final IconData? icon;
  final int? count;

  /// False: shown dimmed and not pressable (a choice that comes later); [tooltip] says why.
  final bool enabled;
  final String? tooltip;

  /// After the label: an "Off" badge on a choice that is not available now.
  final Widget? badge;
}

/// Segmented control: the selected segment is raised, neutral (never gold), with a hairline.
/// [size] `sm` is 36 u tall (a row's control), `md` 44 u (the Send method selector);
/// [stretch] gives every segment an equal share of the width.
class ESegmented<T> extends StatelessWidget {
  const ESegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.size = EBtnSize.sm,
    this.stretch = false,
    this.shrink = false,
  });

  final List<ESegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final EBtnSize size;
  final bool stretch;

  /// Short of room, the control shrinks before it clips (UD-025): first the counts go (into
  /// each segment's tooltip), then the segments wrap onto a second row, or become a dropdown past two; a label is
  /// never cut.
  final bool shrink;

  /// The width the segments take with their words whole.
  double _natural(BuildContext context, {required bool counts}) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    double text(String s, TextStyle st) {
      final tp = TextPainter(text: TextSpan(text: s, style: st), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }
    // As the segment draws it: the inherited style (family, spacing) under its own.
    final label = DefaultTextStyle.of(context).style.merge(TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w500));
    final count = context.ts.mono(size: 11);
    var w = 2 * 3.u + 2 + 2.0 * (segments.length - 1);
    for (final s in segments) {
      w += _segWidth(s, label, count, text, counts: counts);
    }
    return w.ceilToDouble() + 2;
  }

  double _segWidth(ESegment<T> s, TextStyle label, TextStyle count, double Function(String, TextStyle) text, {required bool counts}) {
    var w = 2 * Sp.x3 + text(s.label, label);
    if (s.icon != null) w += Ctl.iconSm + 6.u;
    if (counts && s.count != null) w += 6.u + text('${s.count}', count);
    if (s.badge != null) w += 6.u + 40.u;
    return w;
  }

  /// Rows the segments need when they wrap inside [room] (greedy, as [Wrap] lays them out).
  int _rowsIn(BuildContext context, double room) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    double text(String s, TextStyle st) {
      final tp = TextPainter(text: TextSpan(text: s, style: st), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }
    final label = DefaultTextStyle.of(context).style.merge(TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w500));
    final count = context.ts.mono(size: 11);
    final inner = room - 2 * 3.u - 4;
    var rows = 1;
    var used = 0.0;
    for (final s in segments) {
      final w = _segWidth(s, label, count, text, counts: false) + 2;
      if (used > 0 && used + w > inner) {
        rows++;
        used = 0;
      }
      used += w;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final md = size == EBtnSize.md;
    Widget control(List<ESegment<T>> segs, bool stretch, {bool wrap = false}) => Container(
      padding: EdgeInsets.all(3.u),
      decoration: BoxDecoration(
        color: c.s2,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.line),
      ),
      child: wrap
          ? Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [for (final s in segs) _Seg(seg: s, selected: s.value == value, md: md, stretch: false, onTap: s.enabled ? () => onChanged(s.value) : null)],
            )
          : Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final s in segs) ...[
            if (s != segs.first) const SizedBox(width: 2),
            if (stretch)
              Expanded(child: _Seg(seg: s, selected: s.value == value, md: md, stretch: true, onTap: s.enabled ? () => onChanged(s.value) : null))
            else
              _Seg(seg: s, selected: s.value == value, md: md, stretch: false, onTap: s.enabled ? () => onChanged(s.value) : null),
          ],
        ],
      ),
    );
    if (!shrink) return control(segments, stretch);
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxWidth.isFinite || _natural(context, counts: true) <= box.maxWidth) return control(segments, stretch);
        // Counts into the tooltips.
        final bare = [
          for (final s in segments)
            ESegment<T>(s.value, s.label, icon: s.icon, enabled: s.enabled, badge: s.badge, tooltip: s.tooltip ?? (s.count == null ? null : metaLine([s.label, '${s.count}']))),
        ];
        if (_natural(context, counts: false) <= box.maxWidth) return control(bare, stretch);
        // Still too wide: the labels stay whole and the segments wrap onto a second row; past two
        // rows the control is a dropdown, so every choice stays visible and clickable.
        if (_rowsIn(context, box.maxWidth) <= 2) return control(bare, false, wrap: true);
        return ESelect<T>(
          size: size,
          items: [for (final s in segments) ESelectItem<T>(s.value, s.count == null ? s.label : metaLine([s.label, '${s.count}']), tooltip: s.tooltip)],
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _Seg<T> extends StatefulWidget {
  const _Seg({required this.seg, required this.selected, required this.md, required this.stretch, required this.onTap});

  final ESegment<T> seg;
  final bool selected;
  final bool md;
  final bool stretch;

  /// Null for a segment that cannot be chosen.
  final VoidCallback? onTap;

  @override
  State<_Seg<T>> createState() => _SegState<T>();
}

class _SegState<T> extends State<_Seg<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final sel = widget.selected;
    final off = widget.onTap == null;
    final fg = sel ? c.text : (off ? c.faint : (_hover ? c.text : c.dim));
    final label = TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w500, color: fg);
    final tip = widget.seg.tooltip;
    final seg = Semantics(
      button: true,
      selected: sel,
      enabled: !off,
      child: FocusableActionDetector(
        enabled: !off,
        mouseCursor: off ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v && !off),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onTap,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              radius: 6.u,
              child: AnimatedContainer(
                duration: widget.md ? Dur.base : Dur.fast,
                // The whole control (3 u padding and 1 px border each side) is Ctl.md or Ctl.sm tall.
                height: (widget.md ? Ctl.md : Ctl.sm) - 2 * 3.u - 2,
                padding: EdgeInsets.symmetric(horizontal: Sp.x3),
                decoration: BoxDecoration(
                  color: sel ? c.s4 : (_hover ? c.hover : Colors.transparent),
                  borderRadius: BorderRadius.circular(6.u),
                ),
                // The hairline is drawn over the segment, so choosing one never shifts the row.
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.u),
                  border: Border.all(color: sel ? c.lineStrong : Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.seg.icon != null) ...[
                      Icon(widget.seg.icon, size: Ctl.iconSm, color: fg),
                      SizedBox(width: 6.u),
                    ],
                    if (widget.stretch)
                      Flexible(child: NoSelect(child: Text(widget.seg.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: label)))
                    else
                      NoSelect(child: Text(widget.seg.label, style: label)),
                    if (widget.seg.count != null) ...[
                      SizedBox(width: 6.u),
                      Text('${widget.seg.count}', style: context.ts.mono(size: 11, color: c.faint)),
                    ],
                    if (widget.seg.badge case final badge?) ...[
                      SizedBox(width: 6.u),
                      badge,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return ETip(tip, child: seg);
  }
}

/// A radio option that needs a sentence: icon, title, description; selected is neutral: a raised
/// fill, a 40 % text edge and a check (never gold).
class EChoiceCard extends StatefulWidget {
  const EChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.tag,
    this.titleLines,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? tag;

  /// Reserve this many title lines, so the subtitles of cards in one row share a baseline
  /// whether a title wraps or not (UD-021).
  final int? titleLines;

  @override
  State<EChoiceCard> createState() => _EChoiceCardState();
}

class _EChoiceCardState extends State<EChoiceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final sel = widget.selected;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: sel,
      button: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onTap,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                padding: EdgeInsets.all(Sp.x4),
                decoration: BoxDecoration(
                  color: sel ? c.s3 : c.s1,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: sel ? c.text.withValues(alpha: 0.4) : (_hover ? c.dim : c.lineStrong)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: Ctl.icon, color: sel ? c.text : c.faint),
                      SizedBox(width: Sp.x3),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.titleLines case final n?)
                            SizedBox(height: n * (ts.strong.fontSize ?? Fs.md) * (ts.strong.height ?? 1.4), child: Text(widget.title, style: ts.strong, maxLines: n, overflow: TextOverflow.ellipsis))
                          else
                            Text(widget.title, style: ts.strong),
                          if (widget.description != null) ...[
                            SizedBox(height: Sp.x1),
                            Text(widget.description!, style: ts.small),
                          ],
                          if (widget.tag != null) ...[SizedBox(height: Sp.x2), widget.tag!],
                        ],
                      ),
                    ),
                    SizedBox(width: Sp.x3),
                    AnimatedOpacity(
                      opacity: sel ? 1 : 0,
                      duration: Dur.fast,
                      child: Icon(EIcons.check, size: Ctl.iconSm, color: c.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A checkbox with a label, 20 px box.
class ECheckbox extends StatelessWidget {
  const ECheckbox({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onChanged(!value))},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () => onChanged(!value),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FocusRing(
                  focused: Focus.of(context).hasFocus,
                  radius: Rad.xs,
                  child: Container(
                    width: 20.u,
                    height: 20.u,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: value ? c.accent : c.s2,
                      borderRadius: BorderRadius.circular(Rad.xs),
                      border: Border.all(color: value ? c.accent : c.lineField),
                    ),
                    child: value ? Icon(EIcons.check, size: 16.u, color: c.accentInk) : null,
                  ),
                ),
                SizedBox(width: Sp.x3),
                Flexible(child: Text(label, style: context.ts.body)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades [child]'s last 24 u to transparent when [on] (a one-line field whose text runs under
/// its trailing buttons).
class _FadeEnd extends StatelessWidget {
  const _FadeEnd({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    // The shader paints outside the widget tree: the reading direction is resolved here.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final fade = (24.u / rect.width).clamp(0.0, 1.0);
        return LinearGradient(
          begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
          end: rtl ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          stops: [0, 1 - fade, 1],
        ).createShader(rect);
      },
      child: child,
    );
  }
}
