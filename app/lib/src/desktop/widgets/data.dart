import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/brand.dart' show MarkedQr;
import '../data/models.dart';
import '../data/state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Initials on a hairline square: wallets and contacts.
class EAvatar extends StatelessWidget {
  const EAvatar(this.name, {super.key, this.size = 32});

  final String name;
  final double size;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s_:-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts[1][0] : (parts.first.length > 1 ? parts.first[1] : '');
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rad.sm),
          border: Border.all(color: c.lineStrong),
        ),
        child: Text(
          initials(name),
          style: context.ts.h3.copyWith(fontSize: size * 0.4, color: c.accentText, letterSpacing: 0),
        ),
      ),
    );
  }
}

/// Confirmation ring: an arc for the count out of [needed], a check when done, a dashed
/// faint ring when [off] (cancelled).
class ERing extends StatelessWidget {
  const ERing({super.key, required this.confirmations, this.needed = 10, this.size = 22, this.off = false});

  final int confirmations;
  final int needed;
  final double size;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final done = confirmations >= needed;
    return Semantics(
      label: off ? 'Cancelled' : (done ? 'Confirmed' : '$confirmations of $needed confirmations'),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: off ? 1 : math.min(1, confirmations / needed),
            track: c.lineStrong,
            arc: off ? c.faint : (done ? c.ok : c.accent),
          ),
          child: Center(
            child: done && !off
                ? Icon(EIcons.check, size: size * 0.6, color: c.ok)
                : (off || size < 18
                      ? null
                      : Text('$confirmations', style: context.ts.mono(size: size * 0.42, weight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.track, required this.arc});

  final double value;
  final Color track, arc;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    canvas.drawOval(r, Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.arc != arc;
}

/// An amount in EPIC: mono, tabular, blurred while amounts are hidden.
class EMoney extends ConsumerWidget {
  const EMoney(this.nano, {super.key, this.size = Fs.md, this.color, this.sign = false, this.unit = true, this.weight});

  final int nano;
  final double size;
  final Color? color;

  /// Prefix "+" for incoming amounts.
  final bool sign;
  final bool unit;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final c = context.dc;
    final text = '${sign && nano > 0 ? '+' : ''}${formatEpic(nano)}';
    final style = context.ts.mono(size: size, color: color, weight: weight ?? FontWeight.w500);
    final row = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: hidden ? '••••••' : text),
          if (unit) TextSpan(text: ' EPIC', style: style.copyWith(color: c.dim, fontSize: size * 0.82)),
        ],
      ),
      style: style,
      maxLines: 1,
      softWrap: false,
    );
    return Semantics(label: hidden ? 'Hidden amount' : '$text EPIC', excludeSemantics: true, child: row);
  }
}

/// A QR code with the Epic mark, on white, with the accent glow.
class EQr extends StatelessWidget {
  const EQr(this.data, {super.key, this.size = 216});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Rad.sm),
        boxShadow: [
          BoxShadow(color: c.lineStrong, spreadRadius: 1),
          BoxShadow(color: c.glow, blurRadius: 40, spreadRadius: -6),
        ],
      ),
      child: MarkedQr(data: data, size: size - 28),
    );
  }
}

/// A file drop zone with a pick button: dashed edge, icon, title, one line.
class EDropZone extends StatefulWidget {
  const EDropZone({super.key, required this.title, this.text, this.buttonLabel = 'Choose file', required this.onPick});

  final String title;
  final String? text;
  final String buttonLabel;
  final VoidCallback onPick;

  @override
  State<EDropZone> createState() => _EDropZoneState();
}

class _EDropZoneState extends State<EDropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: CustomPaint(
        painter: _DashedBorder(color: _hover ? c.accent : c.lineField),
        child: AnimatedContainer(
          duration: Dur.fast,
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(Sp.x6),
          decoration: BoxDecoration(
            color: _hover ? c.accentFaint : Colors.transparent,
            borderRadius: BorderRadius.circular(Rad.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(EIcons.fileUp, size: 28, color: c.accentText),
              const SizedBox(height: Sp.x2),
              Text(widget.title, style: ts.strong, textAlign: TextAlign.center),
              if (widget.text != null) ...[
                const SizedBox(height: 2),
                Text(widget.text!, style: ts.small, textAlign: TextAlign.center),
              ],
              const SizedBox(height: Sp.x3),
              EButton(label: widget.buttonLabel, icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: widget.onPick),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Rad.sm));
    final path = Path()..addRRect(rrect.deflate(0.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// The recovery phrase: numbered words in four columns, veiled until [revealed].
class ESeedGrid extends StatelessWidget {
  const ESeedGrid({super.key, required this.words, this.revealed = true, this.columns = 4});

  final List<String> words;
  final bool revealed;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth < 480 ? 2 : columns;
        final w = (box.maxWidth - (cols - 1) * Sp.x2) / cols;
        return Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (var i = 0; i < words.length; i++)
              Container(
                width: w,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: Sp.x3),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('${i + 1}', textAlign: TextAlign.right, style: context.ts.mono(size: 11, color: c.faint)),
                    ),
                    const SizedBox(width: Sp.x2),
                    Expanded(
                      child: revealed
                          ? Text(words[i], style: context.ts.mono(size: Fs.md))
                          : Container(height: 8, margin: const EdgeInsets.only(right: Sp.x6), decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One option of [ESelect].
class ESelectItem<T> {
  const ESelectItem(this.value, this.title, {this.subtitle, this.trailing, this.leading});

  final T value;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
}

/// A combobox: a 44 px field showing the choice, a popover list of options with a subtitle and
/// a trailing status each, and an optional footer action (e.g. "Add node…").
class ESelect<T> extends StatelessWidget {
  const ESelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.footer,
    this.mono = false,
    this.semanticLabel,
  });

  final List<ESelectItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget? footer;
  final bool mono;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final current = items.where((i) => i.value == value).firstOrNull;
    return LayoutBuilder(
      builder: (context, box) => MenuAnchor(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.s4),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(Sp.x2)),
          minimumSize: WidgetStatePropertyAll(Size(box.maxWidth, 0)),
          maximumSize: WidgetStatePropertyAll(Size(box.maxWidth, 420)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
          ),
        ),
        menuChildren: [
          for (final item in items)
            MenuItemButton(
              onPressed: () => onChanged(item.value),
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(box.maxWidth - Sp.x4, item.subtitle == null ? 40 : 52)),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) || item.value == value ? c.s3 : null,
                ),
              ),
              leadingIcon: item.value == value
                  ? Icon(EIcons.check, size: Ctl.iconSm, color: c.accentText)
                  : (item.leading ?? const SizedBox(width: Ctl.iconSm)),
              trailingIcon: item.trailing,
              child: SizedBox(
                width: math.max(120, box.maxWidth - 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title, style: mono ? ts.mono(size: Fs.sm) : ts.body, overflow: TextOverflow.ellipsis),
                    if (item.subtitle != null) Text(item.subtitle!, style: ts.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          if (footer != null) ...[Divider(height: Sp.x3, color: c.line), footer!],
        ],
        builder: (context, controller, _) => Semantics(
          button: true,
          label: semanticLabel,
          value: current?.title,
          child: InkWell(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            borderRadius: BorderRadius.circular(Rad.sm),
            child: Container(
              height: Ctl.md,
              padding: const EdgeInsets.only(left: Sp.x3, right: Sp.x2),
              decoration: BoxDecoration(
                color: c.s2,
                borderRadius: BorderRadius.circular(Rad.sm),
                border: Border.all(color: controller.isOpen ? c.accent : c.lineField),
              ),
              child: Row(
                children: [
                  if (current?.leading != null) ...[current!.leading!, const SizedBox(width: Sp.x2)],
                  Expanded(
                    child: Text(
                      current?.title ?? '',
                      style: mono ? ts.mono(size: Fs.sm) : ts.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (current?.trailing != null) ...[current!.trailing!, const SizedBox(width: Sp.x2)],
                  Icon(EIcons.chevronDown, size: Ctl.icon, color: c.dim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A vertical list of sub-pages (settings) with the current one raised.
class ESubnav extends StatelessWidget {
  const ESubnav({super.key, required this.items, required this.current, required this.onTap});

  /// Null entries draw a separator.
  final List<(Object, String, IconData)?> items;
  final Object current;
  final ValueChanged<Object> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          if (item == null)
            Padding(padding: const EdgeInsets.symmetric(vertical: Sp.x2, horizontal: Sp.x3), child: Divider(height: 1, color: c.line))
          else
            ENavItem(
              icon: item.$3,
              label: item.$2,
              selected: item.$1 == current,
              onTap: () => onTap(item.$1),
            ),
      ],
    );
  }
}

/// A 40 px navigation entry: icon, label, optional count badge. Used by the sidebar and
/// sub-navigation.
class ENavItem extends StatefulWidget {
  const ENavItem({super.key, required this.icon, required this.label, required this.selected, required this.onTap, this.count, this.compact = false});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  /// Icon only (the narrow rail), the label in a tooltip.
  final bool compact;

  @override
  State<ENavItem> createState() => _ENavItemState();
}

class _ENavItemState extends State<ENavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final sel = widget.selected;
    final count = widget.count ?? 0;
    Widget item = AnimatedContainer(
      duration: Dur.fast,
      height: 40,
      margin: const EdgeInsets.only(bottom: 2),
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : Sp.x3),
      decoration: BoxDecoration(
        color: sel ? c.s3 : (_hover ? c.hover : Colors.transparent),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Row(
        mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Badge(
            isLabelVisible: widget.compact && count > 0,
            backgroundColor: c.accent,
            smallSize: 8,
            child: Icon(widget.icon, size: Ctl.icon, color: sel ? c.accentText : c.faint),
          ),
          if (!widget.compact) ...[
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w500, color: sel || _hover ? c.text : c.dim),
              ),
            ),
            if (count > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: context.ts.mono(size: Fs.xs, color: c.accentText, weight: FontWeight.w500)),
              ),
          ],
        ],
      ),
    );
    if (widget.compact) item = Tooltip(message: widget.label, child: item);
    return Semantics(
      button: true,
      selected: sel,
      label: count > 0 ? '${widget.label}, $count need action' : widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onTap,
            child: FocusRing(focused: Focus.of(context).hasFocus, child: item),
          ),
        ),
      ),
    );
  }
}

/// A key cap: "Ctrl+L".
class EKbd extends StatelessWidget {
  const EKbd(this.keys, {super.key});

  final String keys;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rad.xs), border: Border.all(color: c.lineStrong)),
      child: Text(keys, style: context.ts.mono(size: 11, color: c.dim, weight: FontWeight.w500)),
    );
  }
}

/// Words for a health state, used by status rows, comboboxes and the status card.
String healthWord(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => 'Online',
  ServiceHealth.slow => 'Slow',
  ServiceHealth.down => 'Offline',
  ServiceHealth.off => 'Off',
  ServiceHealth.checking => 'Checking',
};

/// Tone for a health state: ok filled, slow ring, down cross, off neutral.
ETone healthTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
  ServiceHealth.checking => ETone.gold,
};
