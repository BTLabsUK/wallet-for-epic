// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../../ui/theme/brand.dart' show BrandLockup, BrandVariant, EpicMark;
import '../../ui/theme/protocol.dart' show CornerTicksPainter, GridFieldPainter;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'keyboard.dart';

/// Content widths for [EPage].
enum EPageWidth { narrow, mid, full }

/// A page inside the app shell: a 64 px top bar with the title, optional crumb (back) and
/// actions, then the scrolling content. [scroll] false hands the remaining height to [child]
/// (list/detail panes that scroll themselves). With [onBack], the app's Back (mouse, Alt+Left,
/// Backspace) runs it before it changes the place.
class EPage extends StatelessWidget {
  const EPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onBack,
    this.width = EPageWidth.mid,
    this.scroll = true,
    this.titleTrailing,
    this.footer,
  });

  final String title;

  /// Pinned under the scrolling content, full width (a narrow form's main action).
  final Widget? footer;

  /// Right after the title, e.g. a state chip.
  final Widget? titleTrailing;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final EPageWidth width;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Bp.phone;
    final pad = compact ? Sp.x4 : Sp.x8;
    final maxW = switch (width) {
      EPageWidth.narrow => Ctl.narrow,
      EPageWidth.mid => Ctl.mid,
      EPageWidth.full => double.infinity,
    };
    final body = Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: child),
    );
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: Ctl.topbar,
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onBack: onBack!),
                SizedBox(width: Sp.x2),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: context.ts.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (titleTrailing != null) ...[SizedBox(width: Sp.x3), titleTrailing!],
                  ],
                ),
              ),
              for (final a in actions) ...[SizedBox(width: Sp.x2), a],
            ],
          ),
        ),
        Expanded(
          child: scroll
              ? SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, 0, pad, pad), child: body)
              : Padding(padding: EdgeInsets.fromLTRB(pad, 0, pad, pad), child: body),
        ),
        ?footer,
      ],
    );
    return DeskStepBack(onBack: onBack, child: page);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  // Not a Tab stop: Alt+Left and the mouse Back button do the same.
  Widget build(BuildContext context) => ExcludeFocusTraversal(
    child: Tooltip(
    message: context.l10n.deskKitBackAlt,
    child: IconButton(
      onPressed: onBack,
      icon: Icon(EIcons.arrowLeft, size: Ctl.icon, color: context.dc.dim),
      style: IconButton.styleFrom(
        fixedSize: Size.square(Ctl.sm),
        minimumSize: Size.square(Ctl.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm)),
      ),
    ),
    ),
  );
}

/// The full-window backdrop of the screens that open the app: a pool of accent light at the
/// top and a measurement grid fading out.
class EHeroScreen extends StatelessWidget {
  const EHeroScreen({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ColoredBox(
      color: c.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 0.9,
                  colors: [c.accentFaint.withValues(alpha: c.accentFaint.a * 1.6), c.bg.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (r) => const RadialGradient(
                center: Alignment(0, -0.6),
                radius: 0.8,
                colors: [Colors.white, Colors.transparent],
              ).createShader(r),
              child: CustomPaint(painter: _Grid(c.grid.withValues(alpha: c.grid.a * 1.4))),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
                // The footer follows the content: on a screen taller than the window it scrolls
                // with it instead of covering it. The top spacer, about the footer's height,
                // keeps the content centred.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(height: footer == null ? 0 : Sp.x10),
                    Center(child: Padding(padding: EdgeInsets.all(Sp.x8), child: child)),
                    if (footer != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: Sp.x5),
                        child: DefaultTextStyle.merge(
                          style: context.ts.caption,
                          textAlign: TextAlign.center,
                          child: Center(child: footer!),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends CustomPainter {
  const _Grid(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 32.u) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height; y += 32.u) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_Grid old) => old.color != color;
}

/// The Epic mark on a ticked tile with a soft glow.
class EGlyphTile extends StatelessWidget {
  const EGlyphTile({super.key, this._size, this.icon, this.risk = false});

  final double? _size;
  double get size => _size ?? 72.u;

  /// An icon instead of the mark.
  final IconData? icon;

  /// A failure: the icon in red on a neutral frame, no gold and no glow.
  final bool risk;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.s1,
          border: Border.all(color: c.lineStrong),
          borderRadius: BorderRadius.circular(Rad.sm),
          boxShadow: risk ? null : [BoxShadow(color: c.glow.withValues(alpha: c.glow.a * 0.7), blurRadius: 36.u, spreadRadius: -8.u)],
        ),
        child: CustomPaint(
          painter: GridFieldPainter(c.grid.withValues(alpha: c.grid.a * 2), step: size / 6),
          foregroundPainter: CornerTicksPainter(risk ? c.lineStrong : c.tick, length: size / 9),
          child: Center(
            child: icon != null
                ? Icon(icon, size: size * 0.4, color: risk ? c.risk : c.accentText)
                : EpicMark(size: size * 0.46, color: c.accent),
          ),
        ),
      ),
    );
  }
}

/// The card of unlock and the other single-question screens: tile, title, lead, the form in a
/// panel, then alternatives under it.
class EAuthCard extends StatelessWidget {
  const EAuthCard({
    super.key,
    required this.title,
    this.lead,
    required this.child,
    this.alternatives = const [],
    this.width = 400,
    this.icon,
  });

  final String title;
  final String? lead;
  final Widget child;
  final List<Widget> alternatives;
  final double width;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: EGlyphTile(icon: icon)),
          SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text(title, style: ts.h1, textAlign: TextAlign.center)),
          if (lead != null) ...[
            SizedBox(height: 6.u),
            Text(lead!, style: ts.bodyDim, textAlign: TextAlign.center),
          ],
          SizedBox(height: Sp.x6),
          Container(
            padding: EdgeInsets.all(Sp.x8),
            decoration: BoxDecoration(
              color: c.s1,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: child,
          ),
          if (alternatives.isNotEmpty) ...[
            SizedBox(height: Sp.x5),
            Wrap(alignment: WrapAlignment.center, spacing: Sp.x4, runSpacing: Sp.x2, children: alternatives),
          ],
        ],
      ),
    );
  }
}

/// One step on the onboarding rail.
class ERailStep {
  const ERailStep(this.label, {this.done = false, this.current = false});

  final String label;
  final bool done;
  final bool current;
}

/// The first-run frame: the step rail on a 260 px side, the step in the main column, the
/// actions pinned at its foot. Below 760 px the rail collapses to "Step n of m".
class EOnbFrame extends StatelessWidget {
  const EOnbFrame({
    super.key,
    required this.sideTitle,
    required this.steps,
    required this.title,
    this.heading,
    this.lead,
    required this.child,
    this.actions = const [],
    this.sideFoot,
  });

  /// Under the brand: "New wallet", "Restore", …
  final String sideTitle;
  final List<ERailStep> steps;
  final String title;

  /// Stands in for [title]'s text: a title with a control in it (the wallet's name with its pen).
  final Widget? heading;
  final String? lead;
  final Widget child;

  /// Left to right; put the primary last.
  final List<Widget> actions;
  final Widget? sideFoot;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final narrow = MediaQuery.sizeOf(context).width < 760.u;
    final current = steps.indexWhere((s) => s.current);
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(narrow ? Sp.x5 : Sp.x12, narrow ? Sp.x6 : Sp.x12, narrow ? Sp.x5 : Sp.x12, Sp.x8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600.u),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (narrow && current >= 0) ...[
                          Text(context.l10n.deskKitStepOf(current + 1, steps.length), style: ts.caption),
                          SizedBox(height: Sp.x2),
                        ],
                        heading ?? Semantics(header: true, child: Text(title, style: ts.h1)),
                        if (lead != null) ...[
                          SizedBox(height: Sp.x2),
                          Text(lead!, style: ts.lead),
                        ],
                        SizedBox(height: Sp.x8),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
              // Content cut by the footer line fades out over 24 u first, so it reads as
              // scrollable rather than chopped (UD-024).
              if (actions.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: Sp.x6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.bg.withValues(alpha: 0), c.bg]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: narrow ? Sp.x5 : Sp.x12, vertical: Sp.x5),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600.u),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i == actions.length - 1) const Spacer(),
                      if (i > 0 && i < actions.length - 1) SizedBox(width: Sp.x3),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
    if (narrow) return ColoredBox(color: c.bg, child: main);
    return ColoredBox(
      color: c.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 260.u,
            padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x6),
            decoration: BoxDecoration(color: c.s1, border: Border(right: BorderSide(color: c.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Sp.x2),
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: BrandLockup(variant: BrandVariant.desktop, size: 28.u, textRatio: 0.56),
                        ),
                      ),
                      SizedBox(width: Sp.x3),
                      // A long title (Set a new password, in German say) ends in an ellipsis
                      // instead of pushing past the panel.
                      Flexible(child: Text(sideTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.caption, textAlign: TextAlign.end)),
                    ],
                  ),
                ),
                SizedBox(height: Sp.x6),
                ERail(steps: steps),
                const Spacer(),
                ?sideFoot,
              ],
            ),
          ),
          Expanded(child: main),
        ],
      ),
    );
  }
}

/// A numbered step list: done steps get a check, the current one an accent edge.
class ERail extends StatelessWidget {
  const ERail({super.key, required this.steps});

  final List<ERailStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Semantics(
            label: '${steps[i].label}${steps[i].done ? ', done' : ''}',
            selected: steps[i].current,
            excludeSemantics: true,
            child: Container(
              height: Ctl.md,
              margin: const EdgeInsets.only(bottom: 2),
              padding: EdgeInsets.symmetric(horizontal: Sp.x3),
              decoration: BoxDecoration(
                color: steps[i].current ? c.s3 : null,
                borderRadius: BorderRadius.circular(Rad.sm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.u,
                    height: 24.u,
                    alignment: Alignment.center,
                    decoration: steps[i].done
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(6.u),
                            border: Border.all(color: steps[i].current ? c.lineField : c.lineStrong),
                          ),
                    child: steps[i].done
                        ? Icon(EIcons.check, size: 18.u, color: c.ok)
                        : Text(
                            '${i + 1}',
                            style: context.ts.mono(size: Fs.xs, color: steps[i].current ? c.text : c.faint),
                          ),
                  ),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Text(
                      steps[i].label,
                      style: TextStyle(
                        fontSize: Fs.md,
                        fontWeight: FontWeight.w500,
                        color: steps[i].current ? c.text : (steps[i].done ? c.dim : c.faint),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
