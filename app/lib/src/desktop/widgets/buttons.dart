import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum EBtnKind { primary, secondary, ghost, danger }

enum EBtnSize {
  /// 28 px: inside a line of text, a row or a notice.
  inline,

  /// 36 px: a row's control, toolbars, dialog secondaries.
  sm,

  /// 44 px: the page's main action.
  md,
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
    final (height, padH, fs, iconSize) = switch (widget.size) {
      EBtnSize.inline => (Ctl.inline, Sp.x2, Fs.sm, Ctl.iconSm),
      EBtnSize.sm => (Ctl.sm, Sp.x3, Fs.sm, 18.u),
      EBtnSize.md => (Ctl.md, Sp.x5, Fs.md, 18.u),
    };
    Color bg, fg, border;
    switch (widget.kind) {
      case EBtnKind.primary:
        bg = disabled ? c.s3 : (_down ? c.accentDeep : (_hover ? Color.lerp(c.accent, c.text, 0.12)! : c.accent));
        fg = disabled ? c.faint : c.accentInk;
        border = disabled ? c.lineStrong : Colors.transparent;
      case EBtnKind.secondary:
        bg = disabled ? Colors.transparent : (_down ? c.press : (_hover ? c.s3 : c.s2));
        fg = disabled ? c.faint : c.text;
        border = disabled ? c.line : (_hover ? c.dim : c.lineField);
      case EBtnKind.ghost:
        bg = _down ? c.press : (_hover && !disabled ? c.hover : Colors.transparent);
        fg = disabled ? c.faint : (widget.size == EBtnSize.inline ? c.accentText : (_hover ? c.text : c.dim));
        border = Colors.transparent;
      case EBtnKind.danger:
        bg = _hover && !disabled ? c.riskSoft : Colors.transparent;
        fg = disabled ? c.faint : c.risk;
        border = disabled ? c.line : c.risk;
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
          if (lead != null) ...[lead, SizedBox(width: widget.size == EBtnSize.inline ? Sp.x1 : Sp.x2)],
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
    Widget body = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: enabled,
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
              child: FocusRing(focused: focused, child: face),
            );
          },
        ),
      ),
    );
    if (widget.tooltip != null) body = Tooltip(message: widget.tooltip!, child: body);
    return body;
  }
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final EBtnSize size;
  final bool selected;
  final Color? color;

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
    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        label: widget.label,
        selected: widget.selected,
        excludeSemantics: true,
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
    );
  }
}

/// A text link styled as the accent, underlined; for "Forgot password?" style actions.
class ELink extends StatefulWidget {
  const ELink({super.key, required this.label, this.onPressed, this.dim = false});

  final String label;
  final VoidCallback? onPressed;

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
    return Semantics(
      link: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onPressed,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
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
