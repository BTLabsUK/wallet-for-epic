// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import '../desk_l10n.dart';
import '../../ui/theme/brand.dart' show EpicMark;
import '../../ui/theme/protocol.dart' show CornerTicksPainter, GridFieldPainter;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'dialogs.dart' show EKeyHint;
import 'buttons.dart';
import 'keyboard.dart';
import 'modal.dart';
import 'phrase_layout.dart' show EPhraseLayout;
import 'tip.dart';

/// Content widths for [EPage].
enum EPageWidth { narrow, mid, full }

/// A page inside the app shell: a 64 px top bar with the title, optional crumb (back) and
/// actions, then the scrolling content. Without [header] the content starts at the page's top
/// (Home, whose balance is its title); [title] still names the page to a screen reader. [scroll] false hands the remaining height to [child]
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
    this.fill,
    this.header = true,
  });

  final String title;

  /// The top bar with the title, Back and the actions.
  final bool header;

  /// Fills the room the scrolling content leaves under it, inside the gutters (a quiet
  /// graphic). Scrolling pages only; nothing when the content is taller than the page.
  final Widget? fill;

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
    // The gutter follows the page's own width, not the window's: a page beside the Settings
    // column is narrower than its window.
    return LayoutBuilder(builder: (context, box) => _page(context, MediaQuery.sizeOf(context).width < Bp.phone ? Sp.x4 : (box.maxWidth < Lay.xl ? Sp.x6 : Sp.x8)));
  }

  Widget _page(BuildContext context, double pad) {
    final maxW = switch (width) {
      EPageWidth.narrow => Ctl.narrow,
      EPageWidth.mid => Ctl.mid,
      EPageWidth.full => double.infinity,
    };
    final body = Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: child),
    );
    // The content's top padding: a breath under the top bar, the page's gutter without one.
    final top = header ? Sp.x2 : pad;
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!header)
          Semantics(header: true, label: title, child: const SizedBox.shrink())
        else
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
                        child: Text(title, style: context.ts.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        // A breath between the title row and the content (its first row of tabs or tiles).
        Expanded(
          child: scroll && fill != null
              ? CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, top, pad, 0),
                      sliver: SliverToBoxAdapter(child: body),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(padding: EdgeInsets.fromLTRB(pad, 0, pad, pad), child: fill),
                    ),
                  ],
                )
              : scroll
              ? SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, top, pad, pad), child: body)
              : Padding(padding: EdgeInsets.fromLTRB(pad, top, pad, pad), child: body),
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
    child: ETip(
    context.l10n.deskKitBackAlt,
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

/// A window too short for the opening screens' full spacing (under 640 u tall).
bool isShortWindow(BuildContext context) => MediaQuery.sizeOf(context).height < 760 * deskScale / deskBase;

/// The full-window backdrop of the screens that open the app: a pool of accent light at the
/// top and a measurement grid fading out.
class EHeroScreen extends StatelessWidget {
  const EHeroScreen({super.key, required this.child, this.topAnchored = false});

  final Widget child;

  /// The content starts at one height from the top whatever its length, instead of being
  /// centred: for a screen whose states differ in height (Unlock's form, its missing-folder
  /// notice, its progress), so the tile and the title stay where they were.
  final bool topAnchored;

  /// Where a [topAnchored] screen's content starts: a tenth of the window, within bounds.
  static double topInset(BuildContext context) =>
      isShortWindow(context) ? Sp.x4 : (MediaQuery.sizeOf(context).height * 0.1).clamp(Sp.x8, 120.u);

  @override
  Widget build(BuildContext context) {
    final pad = isShortWindow(context) ? Sp.x4 : Sp.x8;
    final body = Padding(
      padding: topAnchored ? EdgeInsets.fromLTRB(pad, topInset(context), pad, pad) : EdgeInsets.all(pad),
      child: child,
    );
    // Centred (or anchored) in the room the screen has, above the status bar; a screen
    // taller than that scrolls.
    return EBackdrop(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Align(alignment: topAnchored ? Alignment.topCenter : Alignment.center, child: body),
          ),
        ),
      ),
    );
  }
}

/// The ground of the screens before a wallet is open: a pool of accent light at the top and a
/// measurement grid fading out, under [child].
class EBackdrop extends StatelessWidget {
  const EBackdrop({super.key, required this.child});

  final Widget child;

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
          Positioned.fill(child: child),
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
          color: risk || c.tint.a == 0 ? c.s1 : Color.alphaBlend(c.tint, c.s1),
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

/// Unlock's card: the modal standing on the page with the Epic mark (or [icon]), the title, one
/// sentence, the form, the other ways (links) under it, and what Enter does in the form.
class EAuthCard extends StatelessWidget {
  const EAuthCard({
    super.key,
    required this.title,
    this.lead,
    required this.child,
    this.alternatives = const [],
    this.width,
    this.icon,
    this.enter,
  });

  final String title;
  final String? lead;
  final Widget child;
  final List<Widget> alternatives;

  /// The card's width; [Max.auth] when null.
  final double? width;
  final IconData? icon;

  /// What Enter does in the form, for the key strip; null for no strip.
  final String? enter;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return EModalCard(
      width: width ?? Max.auth,
      icon: icon,
      mark: icon == null ? EpicMark(size: 26.u, color: c.accent) : null,
      title: title,
      lead: lead,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child,
          if (alternatives.isNotEmpty) ...[
            SizedBox(height: Sp.x4),
            Wrap(alignment: WrapAlignment.center, spacing: 22.u, runSpacing: Sp.x2, children: alternatives),
          ],
        ],
      ),
      keys: [if (enter != null) EKeyHint(keys: context.l10n.deskSetSearchKeyEnter, does: enter!)],
    );
  }
}

/// One step of a first-run flow's track.
class ERailStep {
  const ERailStep(this.label, {this.done = false, this.current = false});

  final String label;
  final bool done;
  final bool current;
}

/// The first-run frame: a bar with Back, the flow's name and its step track, and the step as
/// the modal standing in the middle of the page ([EModalCard]): its mark, title, one sentence,
/// the step, a status line, then Back and the step's actions at its foot.
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
    this.onBack,
    this.backLabel,
    this.status,
    this.barEnd,
    this.fill = false,
    this.icon,
    this.width,
    this.enter,
  });

  /// What Enter does on this step, for the key strip ("Next field, then create"); null where
  /// no form takes Enter.
  final String? enter;

  /// [child] gets the height left in the card instead of scrolling with it, so it can keep
  /// parts of its own in view ([EPhraseLayout]: only the words scroll). With less room than
  /// [fillMinHeight] the whole page scrolls as usual.
  final bool fill;

  /// The room [fill] needs: the title, the phrase step's warning, actions and checkbox, and two
  /// rows of words.
  static double get fillMinHeight => 450.u;

  /// The card of a step of words or of a list (the phrase, the word boxes, wallets to import).
  static double get wide => 680.u;

  /// The card of the connection steps.
  static double get mid => 600.u;

  /// The flow's name in the bar: "New wallet", "Restore", …
  final String sideTitle;
  final List<ERailStep> steps;
  final String title;

  /// Stands in for [title]'s text: a title with a control in it (the wallet's name with its pen).
  final Widget? heading;
  final String? lead;
  final Widget child;

  /// The step's actions, the primary last; Back goes first on its own.
  final List<Widget> actions;

  /// Back, at the foot and as the bar's arrow; null on a step without one.
  final VoidCallback? onBack;

  /// Back's words in place of "Back".
  final String? backLabel;

  /// A short line over the footer, set against the actions it explains ("Imported 1 of 3").
  final String? status;

  /// At the bar's end, after the track: a way out of the whole flow (Cancel).
  final Widget? barEnd;

  /// The card's mark; none for a card of words.
  final IconData? icon;

  /// The card's width: 480 unless given ([wide], [mid]).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final window = MediaQuery.sizeOf(context);
    // Short as the canvas means it (760 canvas px): an 800-high window keeps the full spacing.
    final short = window.height < 760 * deskScale / deskBase;
    final current = steps.indexWhere((s) => s.current);
    final back = onBack == null ? null : EButton(key: const ValueKey('onb-back'), label: backLabel ?? l.deskSetupBack, tabStop: false, onPressed: onBack);
    Widget card({required bool bounded, required Widget body, bool scrolls = false}) => EModalCard(
      width: width ?? 480.u,
      icon: icon,
      title: title,
      heading: heading,
      lead: lead,
      body: body,
      status: status,
      actions: [?back, ...actions],
      bounded: bounded,
      scrolls: scrolls,
      keys: [
        if (onBack != null) EKeyHint(keys: l.deskSetFrameEscKey, does: backLabel ?? l.deskSetupBack),
        if (enter != null) EKeyHint(keys: l.deskSetSearchKeyEnter, does: enter!),
      ],
    );
    final bar = SizedBox(
      height: (short ? 52 : 60).u,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.x6),
        child: LayoutBuilder(
          builder: (context, box) {
            // The track from a bar of 720; a narrower one says "Step 2 of 4".
            final Widget? track = steps.length < 2
                ? null
                : box.maxWidth < 720.u
                ? (current < 0 ? null : Text(l.deskKitStepOf(current + 1, steps.length), style: ts.caption, maxLines: 1, overflow: TextOverflow.ellipsis))
                : ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: (window.width < Bp.desktop ? 107 : 140).u * steps.length),
                    child: EStepTrack(steps: steps),
                  );
            return Row(
              children: [
                if (onBack != null) ...[
                  EIconButton(key: const ValueKey('onb-bar-back'), icon: EIcons.arrowLeft, label: backLabel ?? l.deskKitBackAlt, tabStop: false, onPressed: onBack),
                  SizedBox(width: Sp.x2),
                ],
                Expanded(
                  flex: 2,
                  child: Semantics(header: true, child: Text(sideTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.h3)),
                ),
                if (track != null) ...[SizedBox(width: Sp.x4), Flexible(flex: 3, child: Align(alignment: AlignmentDirectional.centerEnd, child: track))],
                if (barEnd != null) ...[SizedBox(width: Sp.x4), barEnd!],
              ],
            );
          },
        ),
      ),
    );
    final stage = LayoutBuilder(
      builder: (context, box) {
        // Anchored at one height, not centred: a step whose content grows (a hint, an error
        // line) moves nothing above it.
        final pad = EdgeInsets.fromLTRB(Sp.x6, short ? Sp.x3 : (window.height * 0.04).clamp(Sp.x4, 72.u), Sp.x6, short ? Sp.x3 : 28.u);
        // As in a dialog, the step scrolls inside the card and its buttons stay in view; a
        // [fill] step scrolls its own part. Too short a window scrolls the whole page.
        if (box.maxHeight >= fillMinHeight) {
          return Padding(
            padding: pad,
            child: Align(
              alignment: Alignment.topCenter,
              child: card(bounded: true, body: child, scrolls: !fill),
            ),
          );
        }
        return SingleChildScrollView(
          padding: pad,
          child: Align(alignment: Alignment.topCenter, child: card(bounded: false, body: child)),
        );
      },
    );
    final page = EBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [bar, Expanded(child: stage)],
      ),
    );
    if (onBack == null) return page;
    // Esc is Back, as the mouse's Back button: the screen's inner step first ([DeskStepBack],
    // which typed passwords hold), else this step's Back.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!DeskStepBack.tryStepBack()) onBack!();
        },
      },
      child: page,
    );
  }
}

/// A flow's steps in a line: a dot per step (done green, the current one blue) joined by a
/// line, the step's name under it.
class EStepTrack extends StatelessWidget {
  const EStepTrack({super.key, required this.steps});

  final List<ERailStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final dot = 13.u;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, s) in steps.indexed)
          Expanded(
            child: Semantics(
              label: '${s.label}${s.done ? ', done' : ''}', // l10n-ok: as the rail said it
              selected: s.current,
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: dot,
                    child: Row(
                      children: [
                        Container(
                          width: dot,
                          height: dot,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.done ? c.ok : (s.current ? c.info : c.s1),
                            border: Border.all(color: s.done ? c.ok : (s.current ? c.info : c.lineField), width: 2),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: EdgeInsets.symmetric(horizontal: 4.u),
                              decoration: BoxDecoration(color: s.done ? c.ok : c.lineStrong, borderRadius: BorderRadius.circular(1)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 7.u),
                  Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: s.current ? ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600) : ts.small.copyWith(color: c.dim),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
