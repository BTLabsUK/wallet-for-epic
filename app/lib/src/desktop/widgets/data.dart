import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../../ui/theme/brand.dart' show MarkedQr;
import '../../initials.dart';
import '../../providers.dart' show defaultMinimumConfirmations;
import '../data/models.dart';
import '../data/state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Initials on a hairline square: wallets and contacts.
class EAvatar extends StatelessWidget {
  const EAvatar(this.name, {super.key, this._size});

  final String name;
  final double? _size;
  double get size => _size ?? 32.u;

  /// Letters only ([nameInitials]): "Wallet (epic program)" is WE, never "W(".
  static String initials(String name) {
    final letters = nameInitials(name);
    return letters.isEmpty ? '·' : letters;
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
          style: context.ts.h3.copyWith(fontSize: size * 0.4 / deskScale, color: c.accentText, letterSpacing: 0),
        ),
      ),
    );
  }
}

/// Confirmation ring: an arc for the count out of [needed], a check when done, a dashed
/// faint ring when [off] (cancelled).
class ERing extends StatelessWidget {
  const ERing({super.key, required this.confirmations, this.needed = defaultMinimumConfirmations, this._size, this.off = false});

  final int confirmations;
  final int needed;
  final double? _size;
  double get size => _size ?? 22.u;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final done = confirmations >= needed;
    return Semantics(
      label: off ? context.l10n.deskKitRingCancelled : (done ? context.l10n.deskKitRingConfirmed : context.l10n.deskKitRingProgress(confirmations, needed)),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: off ? 1 : math.min(1, confirmations / needed),
            track: c.lineStrong,
            arc: off ? c.faint : (done ? c.ok : c.info),
          ),
          child: Center(
            child: done && !off
                ? Icon(EIcons.check, size: size * 0.6, color: c.ok)
                : (off || size < 18
                      ? null
                      : Text('$confirmations', style: context.ts.mono(size: size * 0.42 / deskScale, weight: FontWeight.w600))),
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
  const EMoney(this.nano, {super.key, this.size = Fs.md, this.color, this.sign = false, this.unit = true, this.weight, this.decimals});

  final int nano;
  final double size;
  final Color? color;

  /// Prefix "+" for incoming amounts.
  final bool sign;
  final bool unit;
  final FontWeight? weight;

  /// At least this many decimals (default 4).
  final int? decimals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final c = context.dc;
    final text = '${sign && nano > 0 ? '+' : ''}${formatEpicL(context.l10n, nano, minDecimals: decimals ?? 4)}';
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
    return Semantics(label: hidden ? context.l10n.deskKitHiddenAmount : '$text EPIC', excludeSemantics: true, child: row);
  }
}

/// A QR code with the Epic mark, on white, with the accent glow.
class EQr extends StatelessWidget {
  const EQr(this.data, {super.key, this._size});

  final String data;
  final double? _size;
  double get size => _size ?? 216.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(14.u),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Rad.sm),
        boxShadow: [
          BoxShadow(color: c.lineStrong, spreadRadius: 1),
          BoxShadow(color: c.glow, blurRadius: 40.u, spreadRadius: -6.u),
        ],
      ),
      child: MarkedQr(data: data, size: size - 28.u),
    );
  }
}

/// A file drop zone with a pick button: dashed edge, icon, title, one line.
class EDropZone extends StatefulWidget {
  const EDropZone({super.key, required this.title, this.text, this.buttonLabel, required this.onPick});

  final String title;
  final String? text;
  /// The pick button's label; "Choose file" when null.
  final String? buttonLabel;
  /// Null: the pick button is disabled.
  final VoidCallback? onPick;

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
          constraints: BoxConstraints(minHeight: 160.u),
          padding: EdgeInsets.all(Sp.x6),
          decoration: BoxDecoration(
            color: _hover ? c.accentFaint : Colors.transparent,
            borderRadius: BorderRadius.circular(Rad.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(EIcons.fileUp, size: 28.u, color: c.accentText),
              SizedBox(height: Sp.x2),
              Text(widget.title, style: ts.strong, textAlign: TextAlign.center),
              if (widget.text != null) ...[
                const SizedBox(height: 2),
                Text(widget.text!, style: ts.small, textAlign: TextAlign.center),
              ],
              SizedBox(height: Sp.x3),
              EButton(label: widget.buttonLabel ?? context.l10n.deskKitChooseFile, icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: widget.onPick),
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
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(Rad.sm));
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
        final cols = box.maxWidth < 480.u ? 2 : columns;
        final w = (box.maxWidth - (cols - 1) * Sp.x2) / cols;
        return Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (var i = 0; i < words.length; i++)
              Container(
                width: w,
                height: 40.u,
                padding: EdgeInsets.symmetric(horizontal: Sp.x3),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20.u,
                      child: Text('${i + 1}', textAlign: TextAlign.right, style: context.ts.mono(size: 11, color: c.faint)),
                    ),
                    SizedBox(width: Sp.x2),
                    Expanded(
                      child: revealed
                          ? Text(words[i], style: context.ts.mono(size: Fs.md))
                          : Container(height: 8.u, margin: EdgeInsets.only(right: Sp.x6), decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(4.u))),
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
  const ESelectItem(this.value, this.title, {this.subtitle, this.subtitleIsPath = false, this.tooltip, this.trailing, this.action, this.leading});

  final T value;
  final String title;
  final String? subtitle;

  /// [subtitle] is a folder: cut in the middle, so its end (the part that tells folders
  /// apart) stays.
  final bool subtitleIsPath;

  /// Shown on hover over the option: the whole text where the list cuts it (a wallet's folder).
  final String? tooltip;

  /// Shown after the title in the list and in the closed field (a network badge).
  final Widget? trailing;

  /// A control on the option in the list only (a copy button): the closed field stays a field.
  final Widget? action;
  final Widget? leading;
}

/// A combobox: a 44 px field showing the choice, a popover list of options with a subtitle and
/// a trailing status each, and an optional footer action (e.g. "Add node…").
class ESelect<T> extends StatefulWidget {
  const ESelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.footer,
    this.mono = false,
    this.semanticLabel,
    this.size = EBtnSize.md,
    this.openInitially = false,
    this.keepBelow = 0,
  });

  /// Room the open list leaves free under it, so the form's main button stays in view.
  final double keepBelow;

  /// `md` (44, a form's field) or `sm` ([Ctl.sm], a Settings row's dropdown).
  final EBtnSize size;

  final List<ESelectItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget? footer;
  final bool mono;
  final String? semanticLabel;

  /// The list opens with the first frame: the tour's shots of a list.
  final bool openInitially;

  @override
  State<ESelect<T>> createState() => _ESelectState<T>();
}

class _ESelectState<T> extends State<ESelect<T>> {
  final _controller = MenuController();

  /// The open list's height: as tall as the window under the field allows, less the room kept
  /// for what follows; measured when it opens (the field may have moved since).
  double? _maxHeight;

  void _measure() {
    final anchor = context.findRenderObject() as RenderBox?;
    if (anchor == null || !anchor.attached || !anchor.hasSize) return;
    final below = MediaQuery.sizeOf(context).height - anchor.localToGlobal(Offset(0, anchor.size.height)).dy - widget.keepBelow - 8.u;
    final h = below.clamp(120.u, 420.u);
    if (h != _maxHeight) setState(() => _maxHeight = h);
  }

  @override
  void initState() {
    super.initState();
    if (widget.openInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isOpen) _controller.open();
      });
    }
  }

  static Widget _withTooltip(String? message, Widget child) =>
      message == null ? child : Tooltip(message: message, child: child);

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final items = widget.items;
    final value = widget.value;
    final onChanged = widget.onChanged;
    final footer = widget.footer;
    final mono = widget.mono;
    final size = widget.size;
    final semanticLabel = widget.semanticLabel;
    final current = items.where((i) => i.value == value).firstOrNull;
    final maxHeight = _maxHeight ?? 420.u;
    return LayoutBuilder(
      builder: (context, box) {
        // The text column of each option: the field's width less the check and trailing room.
        final width = math.max(120.u, box.maxWidth - 160.u);
        return MenuAnchor(
          controller: _controller,
          onOpen: _measure,
          // A click outside only closes the list: it does not also press what is under it.
          consumeOutsideTap: true,
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(c.s4),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            padding: WidgetStatePropertyAll(EdgeInsets.all(Sp.x2)),
            minimumSize: WidgetStatePropertyAll(Size(box.maxWidth, 0)),
            maximumSize: WidgetStatePropertyAll(Size(box.maxWidth, maxHeight)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
            ),
          ),
          menuChildren: [
            for (final item in items)
              MenuItemButton(
                onPressed: () => onChanged(item.value),
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(box.maxWidth - Sp.x4, item.subtitle == null ? 40.u : 52.u)),
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) || item.value == value ? c.s3 : null,
                  ),
                ),
                leadingIcon: item.value == value
                    ? Icon(EIcons.check, size: Ctl.iconSm, color: c.text)
                    : (item.leading ?? SizedBox(width: Ctl.iconSm)),
                trailingIcon: item.trailing == null && item.action == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.trailing != null) item.trailing!,
                          if (item.trailing != null && item.action != null) SizedBox(width: Sp.x2),
                          if (item.action != null) item.action!,
                        ],
                      ),
                child: _withTooltip(
                  item.tooltip,
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.title, style: mono ? ts.mono(size: Fs.sm) : ts.body, overflow: TextOverflow.ellipsis),
                        if (item.subtitle != null)
                          item.subtitleIsPath
                              ? EMiddleEllipsis(item.subtitle!, style: ts.caption, tooltip: item.tooltip == null, width: width)
                              : Text(item.subtitle!, style: ts.caption, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            if (footer != null) ...[Divider(height: Sp.x3, color: c.line), footer],
          ],
          // Escape closes the list without choosing; the field keeps the focus while it is open.
          builder: (context, controller, _) => Focus(
            skipTraversal: true,
            onKeyEvent: (_, e) {
              if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape || !controller.isOpen) return KeyEventResult.ignored;
              controller.close();
              return KeyEventResult.handled;
            },
            child: Builder(
              builder: (context) => Semantics(
                button: true,
                label: semanticLabel,
                value: current?.title,
                child: InkWell(
                  onTap: () {
                    if (controller.isOpen) return controller.close();
                    Focus.of(context).requestFocus();
                    controller.open();
                  },
                  borderRadius: BorderRadius.circular(Rad.sm),
                  child: Container(
                    height: size == EBtnSize.sm ? Ctl.sm : Ctl.md,
                    padding: EdgeInsets.only(left: Sp.x3, right: Sp.x2),
                    decoration: BoxDecoration(
                      color: c.s2,
                      borderRadius: BorderRadius.circular(Rad.sm),
                      border: Border.all(color: controller.isOpen ? c.accent : c.lineField),
                    ),
                    child: Row(
                      children: [
                        if (current?.leading != null) ...[current!.leading!, SizedBox(width: Sp.x2)],
                        Expanded(
                          child: Text(
                            current?.title ?? '',
                            style: mono ? ts.mono(size: Fs.sm) : ts.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (current?.trailing != null) ...[current!.trailing!, SizedBox(width: Sp.x2)],
                        Icon(EIcons.chevronDown, size: Ctl.icon, color: c.dim),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A vertical list of sub-pages (settings) with the current one raised.
class ESubnav extends StatelessWidget {
  const ESubnav({super.key, required this.items, required this.current, required this.onTap, this.wrap});

  /// Null entries draw a separator.
  final List<(Object, String, IconData)?> items;
  final Object current;
  final ValueChanged<Object> onTap;

  /// Wraps each entry (the tour marks them as targets).
  final Widget Function(Object id, Widget entry)? wrap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    // One group: Tab does not interleave the sub-pages with the page's controls.
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          if (item == null)
            Padding(padding: EdgeInsets.symmetric(vertical: Sp.x2, horizontal: Sp.x3), child: Divider(height: 1, color: c.line))
          else
            (wrap ?? (_, w) => w)(
              item.$1,
              ENavItem(
                icon: item.$3,
                label: item.$2,
                selected: item.$1 == current,
                onTap: () => onTap(item.$1),
              ),
            ),
      ],
    ),
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
    // A long name wraps to a second line (never one line cut with an ellipsis); the row grows from
    // 40 px and the icon and badge stay level with the first line.
    final line = Fs.md * 1.4;
    final wrapped = !widget.compact;
    Widget item = AnimatedContainer(
      duration: Dur.fast,
      constraints: BoxConstraints(minHeight: 40.u),
      margin: const EdgeInsets.only(bottom: 2),
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : Sp.x3, vertical: wrapped ? math.max(0.0, (40.u - line) / 2) : 0),
      decoration: BoxDecoration(
        color: sel ? c.s3 : (_hover ? c.hover : Colors.transparent),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Row(
        crossAxisAlignment: wrapped ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          SizedBox(
            height: wrapped ? line : null,
            child: Center(
              child: Badge(
                isLabelVisible: widget.compact && count > 0,
                backgroundColor: c.accent,
                smallSize: 8,
                child: Icon(widget.icon, size: Ctl.icon, color: sel ? c.accentText : c.faint),
              ),
            ),
          ),
          if (!widget.compact) ...[
            SizedBox(width: Sp.x3),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: Fs.md, height: 1.4, fontWeight: FontWeight.w500, color: sel || _hover ? c.text : c.dim),
              ),
            ),
            if (count > 0)
              Container(
                constraints: BoxConstraints(minWidth: 20.u),
                height: 20.u,
                padding: EdgeInsets.symmetric(horizontal: 6.u),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10.u)),
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
      label: count > 0 ? context.l10n.deskKitNeedAction(widget.label, count) : widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
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
      padding: EdgeInsets.symmetric(horizontal: 6.u, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rad.xs), border: Border.all(color: c.lineStrong)),
      child: Text(keys, style: context.ts.mono(size: 11, color: c.dim, weight: FontWeight.w500)),
    );
  }
}

/// Words for a health state, used by status rows, comboboxes and the status card.
String healthWord(AppLocalizations l, ServiceHealth h) => switch (h) {
  ServiceHealth.ok => l.deskKitHealthOn,
  ServiceHealth.slow => l.deskKitHealthSlow,
  ServiceHealth.down => l.deskKitHealthOffline,
  ServiceHealth.off => l.deskKitHealthOff,
  ServiceHealth.checking => l.deskKitHealthChecking,
};

/// Tone for a health state: ok filled, slow ring, down cross, off neutral.
ETone healthTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
  ServiceHealth.checking => ETone.info,
};

/// A path on one line: when it does not fit, the middle gives way (its end matters more).
class EMiddleEllipsis extends StatelessWidget {
  const EMiddleEllipsis(this.text, {super.key, required this.style, this.tooltip = true, this.width});

  final String text;
  final TextStyle style;

  /// The whole text on hover; off where the row around it has its own tooltip.
  final bool tooltip;

  /// The room it has, where it is known; inside a menu, which measures its items' intrinsic
  /// sizes, a LayoutBuilder cannot ask.
  final double? width;

  @override
  Widget build(BuildContext context) =>
      width != null ? _line(context, width!) : LayoutBuilder(builder: (context, box) => _line(context, box.maxWidth));

  Widget _line(BuildContext context, double room) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    // Measured in the font the Text draws with: [style] alone has no family, and the default
    // font the painter would take is wider, which cut the path to a few characters.
    final drawn = DefaultTextStyle.of(context).style.merge(style);
    bool fits(String t) {
      final p = TextPainter(text: TextSpan(text: t, style: drawn), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
      return p.width <= room;
    }

    var shown = text;
    if (!fits(shown) && text.length > 4) {
      var lo = 0, hi = text.length;
      // The longest text that fits, cut in the middle.
      while (hi - lo > 1) {
        final mid = (lo + hi) ~/ 2;
        final keep = text.length - mid;
        final head = keep ~/ 2, tail = keep - head;
        final t = '${text.substring(0, head)}…${text.substring(text.length - tail)}';
        if (fits(t)) {
          hi = mid;
          shown = t;
        } else {
          lo = mid;
        }
      }
    }
    final line = Text(shown, maxLines: 1, softWrap: false, style: style, semanticsLabel: text);
    return tooltip ? Tooltip(message: text, waitDuration: const Duration(milliseconds: 600), child: line) : line;
  }
}
