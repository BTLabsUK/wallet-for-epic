import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/theme/protocol.dart' show CornerTicksPainter, GridFieldPainter;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';

/// A panel: s1 fill, hairline edge, 8 px radius. [head] and [foot] get their own bands.
class EPanel extends StatelessWidget {
  const EPanel({
    super.key,
    required this.child,
    this.title,
    this.headTrailing,
    this.foot,
    this.padding = const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x5),
  });

  final Widget child;
  final String? title;
  final Widget? headTrailing;
  final Widget? foot;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x3),
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                children: [
                  Expanded(child: Text(title!, style: context.ts.label)),
                  ?headTrailing,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
          if (foot != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x3),
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
  const ESectionHead(this.title, {super.key, this.trailing, this.top = Sp.x8});

  final String title;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: Sp.x3),
      child: Row(
        children: [
          Container(width: 14, height: 2, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(header: true, child: Text(title, style: context.ts.h3)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum ETone { neutral, ok, warn, risk, gold }

extension on ETone {
  (Color fg, Color bg) colors(DeskColors c) => switch (this) {
    ETone.neutral => (c.dim, Colors.transparent),
    ETone.ok => (c.ok, c.okSoft),
    ETone.warn => (c.warn, c.warnSoft),
    ETone.risk => (c.risk, c.riskSoft),
    ETone.gold => (c.accentText, c.accentSoft),
  };
}

/// A 22 px tag: state words in lists and headers.
class ETag extends StatelessWidget {
  const ETag(this.label, {super.key, this.tone = ETone.neutral, this.icon, this.mono = false});

  final String label;
  final ETone tone;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final (fg, bg) = tone.colors(c);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: Sp.x2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Rad.xs),
        border: Border.all(color: tone == ETone.neutral ? c.lineStrong : fg.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: Sp.x1)],
          Text(
            label,
            style: mono
                ? context.ts.mono(size: Fs.xs, color: fg, weight: FontWeight.w500)
                : TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
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
  });

  final String title;
  final String? text;
  final ETone tone;
  final IconData? icon;
  final List<Widget> actions;

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
      padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      decoration: BoxDecoration(
        color: tone == ETone.neutral || tone == ETone.ok ? c.s1 : (tone == ETone.gold ? c.accentFaint : bg),
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(
          color: tone == ETone.neutral || tone == ETone.ok ? c.lineStrong : fg.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(glyph, size: Ctl.icon, color: iconColor),
          ),
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                if (text != null) ...[
                  const SizedBox(height: 2),
                  Text(text!, style: ts.small),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: Sp.x3),
            Wrap(spacing: Sp.x2, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Key/value facts in two columns.
class EFacts extends StatelessWidget {
  const EFacts(this.rows, {super.key, this.labelWidth = 140});

  final List<(String, Widget)> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: labelWidth, child: Text(k, style: ts.bodyDim)),
                const SizedBox(width: Sp.x6),
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
  const EAddress(this.address, {super.key, this.large = false, this.onCopied});

  final String address;
  final bool large;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final base = ts.mono(size: large ? 14.5 : Fs.sm);
    final hl = base.copyWith(color: c.accentText, fontWeight: FontWeight.w600);
    // The highlight marks the address itself, not the relay after "@" or a URL.
    final at = address.indexOf('@');
    final a = at > 0 ? address.substring(0, at) : address;
    final rest = at > 0 ? address.substring(at) : '';
    final spans = a.length > 14 && !a.startsWith('http')
        ? [
            TextSpan(text: a.substring(0, 6), style: hl),
            TextSpan(text: a.substring(6, a.length - 6)),
            TextSpan(text: a.substring(a.length - 6), style: hl),
            TextSpan(text: rest, style: base.copyWith(color: c.dim)),
          ]
        : [TextSpan(text: address)];
    return Container(
      padding: const EdgeInsets.fromLTRB(Sp.x4, Sp.x3, Sp.x2, Sp.x3),
      decoration: BoxDecoration(
        color: c.s2,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.lineStrong),
      ),
      child: Row(
        children: [
          Expanded(child: SelectableText.rich(TextSpan(style: base, children: spans))),
          const SizedBox(width: Sp.x2),
          ECopyButton(text: address, onCopied: onCopied),
        ],
      ),
    );
  }
}

/// Copy to the clipboard; the icon turns into a check for a moment.
class ECopyButton extends StatefulWidget {
  const ECopyButton({super.key, required this.text, this.label = 'Copy', this.onCopied, this.withLabel = false});

  final String text;
  final String label;
  final VoidCallback? onCopied;
  final bool withLabel;

  @override
  State<ECopyButton> createState() => _ECopyButtonState();
}

class _ECopyButtonState extends State<ECopyButton> {
  bool _done = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    widget.onCopied?.call();
    if (!mounted) return;
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.withLabel) {
      return EButton(
        label: _done ? 'Copied' : widget.label,
        icon: _done ? EIcons.check : EIcons.copy,
        size: EBtnSize.inline,
        kind: EBtnKind.ghost,
        onPressed: _copy,
      );
    }
    return EIconButton(
      icon: _done ? EIcons.check : EIcons.copy,
      label: _done ? 'Copied' : widget.label,
      color: _done ? context.dc.ok : null,
      onPressed: _copy,
    );
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Rad.sm),
              border: Border.all(color: c.lineStrong),
            ),
            child: Icon(icon, size: Ctl.iconLg, color: c.accentText),
          ),
          const SizedBox(height: Sp.x4),
          Text(title, style: ts.h3, textAlign: TextAlign.center),
          if (text != null) ...[
            const SizedBox(height: Sp.x2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(text!, style: ts.bodyDim, textAlign: TextAlign.center),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Sp.x4),
            Wrap(spacing: Sp.x2, runSpacing: Sp.x2, alignment: WrapAlignment.center, children: actions),
          ],
        ],
      ),
    );
  }
}

/// A settings group: section head, then rows in one enclosure.
class ESetGroup extends StatelessWidget {
  const ESetGroup({super.key, this.title, required this.rows, this.trailing});

  final String? title;
  final List<Widget> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.x8),
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
  const ESetRow({super.key, required this.title, this.text, this.control, this.stacked = false, this.below});

  final String title;
  final String? text;
  final Widget? control;
  final bool stacked;

  /// Extra content under the row (status line, expanded options).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: ts.strong),
        if (text != null) ...[
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(text!, style: ts.small),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked || control == null) ...[
            words,
            if (control != null) ...[const SizedBox(height: Sp.x3), control!],
          ] else
            Row(
              children: [
                Expanded(child: words),
                const SizedBox(width: Sp.x6),
                control!,
              ],
            ),
          if (below != null) ...[const SizedBox(height: Sp.x3), below!],
        ],
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
        minHeight: 4,
        backgroundColor: c.s3,
        color: c.accent,
      ),
    );
  }
}

class ESpinner extends StatelessWidget {
  const ESpinner({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color ?? context.dc.accent),
  );
}

/// The hairline between blocks.
class EDivider extends StatelessWidget {
  const EDivider({super.key, this.space = Sp.x6});

  final double space;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.symmetric(vertical: space), child: Divider(height: 1, thickness: 1, color: context.dc.line));
}

/// Collapsible "technical details" block.
class EDetails extends StatefulWidget {
  const EDetails({super.key, required this.title, required this.child, this.initiallyOpen = false});

  final String title;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<EDetails> createState() => _EDetailsState();
}

class _EDetailsState extends State<EDetails> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
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
              constraints: const BoxConstraints(minHeight: Ctl.md),
              padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: Dur.base,
                    child: Icon(EIcons.chevronRight, size: Ctl.icon, color: c.dim),
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(child: Text(widget.title, style: context.ts.strong.copyWith(color: c.dim))),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.x4, 0, Sp.x4, Sp.x4),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
