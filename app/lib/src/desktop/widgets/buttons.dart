// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import 'selectable.dart';

import '../theme/tokens.dart';
import 'tip.dart';

/// [primarySoft] is the primary of a row of peers (a detail header's Send): the accent as a soft
/// tint with gold ink and a gold hairline, where a filled block would shout.
enum EBtnKind { primary, primarySoft, secondary, ghost, danger }

enum EBtnSize {
  /// 28 px: inside a line of text, a row or a notice.
  inline,

  /// 36 px: a row's control, toolbars.
  sm,

  /// 44 px: the page's main action, and every button of a dialog's footer.
  md,
}

/// Around a dialog's footer ([EDialog] puts it there): every [EButton] in it is [EBtnSize.md]
/// tall, so the labels share one baseline, and takes one of the footer's three faces:
/// outlined secondary, filled primary, outlined risk. A ghost or soft button becomes the
/// outlined secondary; [kind], when set, overrides the button's own (a second primary is
/// shown as a secondary: one filled button per dialog). Call sites cannot drift from it.
class EDialogActions extends InheritedWidget {
  const EDialogActions({super.key, required super.child, this.kind});

  final EBtnKind? kind;

  static EDialogActions? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<EDialogActions>();

  /// The face [kind] takes in a footer.
  static EBtnKind face(EBtnKind kind) => switch (kind) {
    EBtnKind.primary => EBtnKind.primary,
    EBtnKind.danger => EBtnKind.danger,
    EBtnKind.secondary || EBtnKind.ghost || EBtnKind.primarySoft => EBtnKind.secondary,
  };

  @override
  bool updateShouldNotify(EDialogActions oldWidget) => kind != oldWidget.kind;
}

/// The one button. Kind sets the colour, size the height; see [Ctl] for the rule.
class EButton extends StatefulWidget {
  const EButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = EBtnKind.secondary,
    this.size = EBtnSize.md,
    this.busy = false,
    this.expand = false,
    this.tooltip,
    this.tabStop = true,
    this.hit44 = false,
    this.autofocus = false,
  });

  const EButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = EBtnSize.md,
    this.busy = false,
    this.expand = false,
    this.tooltip,
    this.tabStop = true,
    this.hit44 = false,
    this.autofocus = false,
  }) : kind = EBtnKind.primary;

  const EButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = EBtnSize.sm,
    this.busy = false,
    this.expand = false,
    this.tooltip,
    this.tabStop = true,
    this.hit44 = false,
    this.autofocus = false,
  }) : kind = EBtnKind.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EBtnKind kind;
  final EBtnSize size;

  /// Spinner in the icon slot, label stays, presses ignored.
  final bool busy;

  /// Full width of the parent.
  final bool expand;
  final String? tooltip;

  /// False for a secondary action (Back, an inline helper): Tab skips it (see keyboard.dart).
  final bool tabStop;

  /// Keeps the drawn size and pads the hit area to [Ctl.md] tall (a 28 or 36 px button that is
  /// the only way on, as in the tour card). The layout height grows with it.
  final bool hit44;

  /// Takes the focus when it appears: the default button of a confirm, so Enter presses it.
  final bool autofocus;

  @override
  State<EButton> createState() => _EButtonState();
}

class _EButtonState extends State<EButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final enabled = widget.onPressed != null && !widget.busy;
    final disabled = widget.onPressed == null;
    final footer = EDialogActions.maybeOf(context);
    final kind = footer == null ? widget.kind : EDialogActions.face(footer.kind ?? widget.kind);
    final size = footer == null ? widget.size : EBtnSize.md;
    final (height, padH, fs, iconSize) = switch (size) {
      EBtnSize.inline => (Ctl.inline, Sp.x2, Fs.sm, Ctl.iconSm),
      EBtnSize.sm => (Ctl.sm, Sp.x3, Fs.sm, 18.u),
      EBtnSize.md => (Ctl.md, Sp.x5, Fs.md, 18.u),
    };
    Color bg, fg, border;
    switch (kind) {
      case EBtnKind.primary:
        bg = _down ? c.accentDeep : (_hover ? Color.lerp(c.accent, c.text, 0.12)! : c.accent);
        fg = c.accentInk;
        border = Colors.transparent;
      case EBtnKind.primarySoft:
        bg = _down ? c.press : (_hover ? Color.lerp(c.accentSoft, c.accent, 0.12)! : c.accentSoft);
        fg = c.accentText;
        border = c.accent.withValues(alpha: 0.35);
      case EBtnKind.secondary:
        bg = _down ? c.press : (_hover ? c.s3 : c.s2);
        fg = c.text;
        border = _hover ? c.dim : c.lineField;
      case EBtnKind.ghost:
        bg = _down ? c.press : (_hover ? c.hover : Colors.transparent);
        fg = size == EBtnSize.inline ? c.accentText : (_hover ? c.text : c.dim);
        border = Colors.transparent;
      case EBtnKind.danger:
        bg = _hover ? c.riskSoft : Colors.transparent;
        fg = c.risk;
        border = c.risk;
    }
    // One disabled recipe for every kind (D-03): a flat fill, faint ink, no edge, so a
    // disabled primary never reads as an enabled outlined secondary. A ghost stays bare.
    if (disabled) {
      bg = kind == EBtnKind.ghost ? Colors.transparent : c.press;
      fg = c.faint;
      border = Colors.transparent;
    }
    final lead = widget.busy
        ? SizedBox.square(
            dimension: iconSize - 2,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : (widget.icon == null ? null : Icon(widget.icon, size: iconSize, color: fg));
    final face = AnimatedContainer(
      duration: Dur.fast,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padH),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lead != null) ...[lead, SizedBox(width: size == EBtnSize.inline ? Sp.x1 : Sp.x2)],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fs, fontWeight: FontWeight.w600, color: fg, height: 1.2),
            ),
          ),
        ],
      ),
    );
    // A label is never selected by a drag over the page (selectable.dart).
    Widget body = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      // The tap a screen reader runs: excludeSemantics drops the GestureDetector's own.
      onTap: enabled ? widget.onPressed : null,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        mouseCursor: enabled ? SystemMouseCursors.click : (widget.busy ? SystemMouseCursors.progress : SystemMouseCursors.forbidden),
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTapDown: enabled ? (_) => setState(() => _down = true) : null,
              onTapUp: enabled ? (_) => setState(() => _down = false) : null,
              onTapCancel: () => setState(() => _down = false),
              onTap: enabled ? widget.onPressed : null,
              behavior: widget.hit44 ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
              child: widget.hit44
                  ? ConstrainedBox(
                      constraints: BoxConstraints(minHeight: Ctl.md),
                      child: Center(widthFactor: 1, child: FocusRing(focused: focused, child: NoSelect(child: face))),
                    )
                  : FocusRing(focused: focused, child: NoSelect(child: face)),
            );
          },
        ),
      ),
    );
    if (widget.tooltip != null) body = ETip(widget.tooltip, child: body);
    return ExcludeFocusTraversal(excluding: !widget.tabStop, child: body);
  }
}

/// The trailing control of a Settings row: [Ctl.rowW] wide, or [Ctl.rowWide] with
/// [wide] (segmented choices, server pickers), so every row control of a card has one of two
/// widths and the same right edge. The child fills it: an [EButton] of [EBtnSize.sm] (its icon
/// and label centred in the width), an [ESelect] or [EInput] with `size: EBtnSize.sm`, an
/// `ESegmented(stretch: true)`.
class ERowControl extends StatelessWidget {
  const ERowControl({super.key, required this.child, this.wide = false});

  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) => SizedBox(width: wide ? Ctl.rowWide : Ctl.rowW, child: child);
}

/// Icon-only button. Always has a label for screen readers and a tooltip.
class EIconButton extends StatefulWidget {
  const EIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = EBtnSize.sm,
    this.selected = false,
    this.color,
    this.tabStop = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final EBtnSize size;
  final bool selected;
  final Color? color;

  /// False for a secondary icon (eye, info, copy, QR, clear, close): Tab skips it; screen
  /// readers still press it (see keyboard.dart). Icons inside an [EInput] are never stops.
  final bool tabStop;

  @override
  State<EIconButton> createState() => _EIconButtonState();
}

class _EIconButtonState extends State<EIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final dim = switch (widget.size) {
      EBtnSize.inline => Ctl.inline,
      EBtnSize.sm => Ctl.sm,
      EBtnSize.md => Ctl.md,
    };
    final enabled = widget.onPressed != null;
    final fg = !enabled
        ? c.faint
        : widget.selected
        ? c.accentText
        : (widget.color ?? (_hover ? c.text : c.dim));
    return ExcludeFocusTraversal(
      excluding: !widget.tabStop,
      child: ETip(
      widget.label,
      child: Semantics(
        button: true,
        label: widget.label,
        selected: widget.selected,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: widget.onPressed,
              child: FocusRing(
                focused: Focus.of(context).hasFocus,
                child: AnimatedContainer(
                  duration: Dur.fast,
                  width: dim,
                  height: dim,
                  decoration: BoxDecoration(
                    color: _hover && enabled ? c.hover : Colors.transparent,
                    borderRadius: BorderRadius.circular(Rad.sm),
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.size == EBtnSize.inline ? Ctl.iconSm : Ctl.icon,
                    color: fg,
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

/// A text link styled as the accent, underlined; for "Forgot password?" style actions.
class ELink extends StatefulWidget {
  const ELink({super.key, required this.label, this.onPressed, this.dim = false, this.tabStop = true});

  final String label;
  final VoidCallback? onPressed;

  /// False for a link beside a field ("Available …"): Tab skips it (see keyboard.dart).
  final bool tabStop;

  /// Dim colour (auth screens' alternatives) instead of the accent.
  final bool dim;

  @override
  State<ELink> createState() => _ELinkState();
}

class _ELinkState extends State<ELink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final color = widget.dim ? (_hover ? c.text : c.dim) : c.accentText;
    return ExcludeFocusTraversal(
      excluding: !widget.tabStop,
      child: Semantics(
      link: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onPressed,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: NoSelect(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: Fs.sm,
                  fontWeight: widget.dim ? FontWeight.w400 : FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: _hover ? color : color.withValues(alpha: 0.45),
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

/// The 2 px accent outline every focusable control shows on keyboard focus.
class FocusRing extends StatelessWidget {
  const FocusRing({super.key, required this.focused, required this.child, this.radius});

  final bool focused;
  final Widget child;

  /// Defaults to [Rad.sm].
  final double? radius;

  @override
  Widget build(BuildContext context) {
    if (!focused) return child;
    final c = context.dc;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((radius ?? Rad.sm) + 2),
        border: Border.all(color: c.accent, width: 2, strokeAlign: BorderSide.strokeAlignOutside),
      ),
      child: child,
    );
  }
}
