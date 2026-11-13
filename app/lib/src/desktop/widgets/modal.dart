// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../ui/theme/protocol.dart' show CornerTicksPainter;
import 'buttons.dart';
import 'selectable.dart';
import 'surfaces.dart';

/// The parts of the one modal surface: the dialog ([EDialog]) and the first-run card
/// ([EModalCard], the Start screens) share them, so the two never drift.

/// A tone's line and soft colours; neutral and gold wear the brand's.
(Color line, Color soft) modalTone(BuildContext context, ETone tone) {
  final c = context.dc;
  return switch (tone) {
    ETone.ok => (c.ok, c.okSoft),
    ETone.warn => (c.warn, c.warnSoft),
    ETone.risk => (c.risk, c.riskSoft),
    ETone.info => (c.info, c.infoSoft),
    ETone.gold || ETone.neutral => (c.accentText, c.accentSoft),
  };
}

/// The tone at a modal's top edge: a soft light and a hairline. Children of the modal's Stack.
List<Widget> modalGlow(BuildContext context, ETone tone) {
  final (line, soft) = modalTone(context, tone);
  return [
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 150.u,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(center: Alignment.topCenter, radius: 0.9, colors: [soft.withValues(alpha: soft.a * 0.7), soft.withValues(alpha: 0)], stops: const [0, 0.72]),
          ),
        ),
      ),
    ),
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 1,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [line.withValues(alpha: 0), line.withValues(alpha: 0.75), line.withValues(alpha: 0.75), line.withValues(alpha: 0)], stops: const [0, 0.28, 0.72, 1]),
          ),
        ),
      ),
    ),
  ];
}

/// A modal's mark: a ticked tile in the tone with [icon], or [child] (the Epic mark, a spinner).
class EModalMark extends StatelessWidget {
  const EModalMark({super.key, this.tone = ETone.neutral, this.icon, this.child, this.short = false});

  final ETone tone;
  final IconData? icon;
  final Widget? child;

  /// A short window: 40 instead of 52.
  final bool short;

  @override
  Widget build(BuildContext context) {
    final (line, soft) = modalTone(context, tone);
    final size = (short ? 40 : 52).u;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        color: soft.withValues(alpha: soft.a * 0.5),
        child: CustomPaint(
          foregroundPainter: CornerTicksPainter(line, length: size / 6, width: 1.5),
          child: Center(child: child ?? Icon(icon, size: short ? Ctl.icon : Ctl.iconLg, color: line)),
        ),
      ),
    );
  }
}

/// A modal's footer, laid out once: secondaries as given, then a destructive action, then the
/// primary; every primary but the last shows as a secondary. The buttons share one row, the
/// main one 1.35 times as wide as each of the others and last; past three, the first ones sit
/// in a row above. One Wrap with every button a keyed sibling, so a button that moves when the
/// footer changes keeps its state and its work in flight.
class EModalButtons extends StatelessWidget {
  const EModalButtons({super.key, required this.actions});

  final List<Widget> actions;

  /// [actions] in the footer's order, each in its slot ([EDialogActions]).
  static List<Widget> ordered(List<Widget> actions) {
    int rank(Widget w) => w is EButton
        ? switch (w.kind) {
            EBtnKind.primary => 2,
            EBtnKind.danger => 1,
            _ => 0,
          }
        : 0;
    final sorted = [for (var i = 0; i < actions.length; i++) (i, actions[i])]
      ..sort((a, b) {
        final r = rank(a.$2).compareTo(rank(b.$2));
        return r != 0 ? r : a.$1.compareTo(b.$1);
      });
    final lastPrimary = sorted.lastIndexWhere((e) => rank(e.$2) == 2);
    // An action's own key keys its slot: one that moves when the footer changes keeps its state.
    final keys = [for (final a in actions) a.key];
    Key? slot(Widget w) => w.key != null && keys.where((k) => k == w.key).length == 1 ? ValueKey<Key>(w.key!) : null;
    return [
      for (var i = 0; i < sorted.length; i++)
        EDialogActions(
          key: slot(sorted[i].$2),
          kind: rank(sorted[i].$2) == 2 && i != lastPrimary ? EBtnKind.secondary : null,
          child: sorted[i].$2,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final buttons = ordered(actions);
    return LayoutBuilder(
      builder: (context, box) {
        final gap = 10.u;
        final last = buttons.length > 3 ? 3 : buttons.length;
        final first = buttons.length - last;
        double floor(double w) => (w * 100).floorToDouble() / 100;
        final unit = floor((box.maxWidth - gap * (last - 1)) / (last == 1 ? 1 : last - 1 + 1.35));
        final main = last == 1 ? unit : floor(box.maxWidth - gap * (last - 1) - unit * (last - 1));
        final above = first == 0 ? 0.0 : floor((box.maxWidth - gap * (first - 1)) / first);
        // One group: a footer may set its own Tab order (FocusTraversalOrder on an action).
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, b) in buttons.indexed)
              SizedBox(
                key: b.key,
                width: i < first ? above : (i == buttons.length - 1 ? main : unit),
                child: EButtonFill(child: b),
              ),
          ],
          ),
        );
      },
    );
  }
}

/// The strip at a modal's foot that says what keys do: not read out (the buttons say it), not
/// selectable.
class EModalKeys extends StatelessWidget {
  const EModalKeys({super.key, required this.hints, this.padX = 28, this.short = false});

  final List<Widget> hints;

  /// The modal's side padding before the scale.
  final double padX;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      margin: EdgeInsets.only(top: short ? Sp.x3 : Sp.x5),
      padding: EdgeInsets.symmetric(horizontal: padX.u, vertical: short ? 6.u : 10.u),
      decoration: BoxDecoration(color: c.modalFoot, border: Border(top: BorderSide(color: c.line))),
      child: NoSelect(
        child: ExcludeSemantics(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Sp.x5,
            runSpacing: 6.u,
            children: hints,
          ),
        ),
      ),
    );
  }
}

/// The modal standing on a page (the Start screens): the dialog's surface, mark, title, one
/// sentence, the body, a status line, the footer and the key strip, without a scrim or Close.
/// With [bounded] the body takes what height is left and the rest stays in view.
class EModalCard extends StatelessWidget {
  const EModalCard({
    super.key,
    required this.width,
    this.tone = ETone.neutral,
    this.icon,
    this.mark,
    this.title,
    this.heading,
    this.lead,
    this.body,
    this.status,
    this.actions = const [],
    this.keys = const [],
    this.bounded = false,
    this.liveTitle = false,
  });

  final double width;
  final ETone tone;

  /// The mark's glyph; with neither it nor [mark] the card has no mark (a wide card of words).
  final IconData? icon;
  final Widget? mark;
  final String? title;

  /// Stands in for [title]'s text (a title with a control in it).
  final Widget? heading;
  final String? lead;
  final Widget? body;

  /// A short line over the footer, set against the buttons it explains.
  final String? status;
  final List<Widget> actions;

  /// [EKeyHint]s; none, no strip.
  final List<Widget> keys;
  final bool bounded;

  /// The title is announced when it changes (a long action's progress and its failure).
  final bool liveTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final window = MediaQuery.sizeOf(context);
    final narrow = window.width < Bp.desktop;
    // Short as the canvas means it (760 canvas px): an 800-high window keeps the full spacing.
    final short = window.height < 760 * deskScale / deskBase;
    final padX = (narrow ? 20 : 28).toDouble();
    final pad = padX.u;
    final head = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null || mark != null) ...[
          Center(child: EModalMark(tone: tone, icon: icon, short: short, child: mark)),
          // Room between the mark, the title and what follows (the user's call, every modal).
          SizedBox(height: short ? Sp.x3 : Sp.x5),
        ],
        if (heading != null)
          heading!
        else if (title != null)
          Semantics(header: true, liveRegion: liveTitle, child: Text(title!, style: ts.h2, textAlign: TextAlign.center)),
        if (lead != null) ...[
          SizedBox(height: Sp.x2),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width >= 600.u ? 560.u : 380.u),
              child: Text(lead!, style: ts.bodyDim, textAlign: TextAlign.center),
            ),
          ),
        ],
      ],
    );
    final content = body == null ? null : Padding(padding: EdgeInsets.fromLTRB(pad, short ? Sp.x4 : Sp.x6, pad, 0), child: body);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: c.modal, borderRadius: BorderRadius.circular(Rad.lg)),
        // On top, so the key strip's fill never covers the edge or the corners.
        foregroundDecoration: BoxDecoration(border: Border.all(color: c.lineStrong), borderRadius: BorderRadius.circular(Rad.lg)),
        child: Stack(
          children: [
            ...modalGlow(context, tone),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: EdgeInsets.fromLTRB(pad, (short ? 18 : (narrow ? 22 : 28)).u, pad, 0), child: head),
                if (content != null) bounded ? Flexible(child: content) : content,
                if (status != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, Sp.x3, pad, 0),
                    child: Text(status!, style: ts.caption, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, status != null ? Sp.x2 : (short ? Sp.x4 : 22.u), pad, 0),
                    child: EModalButtons(actions: actions),
                  ),
                if (keys.isNotEmpty) EModalKeys(hints: keys, padX: padX, short: short) else SizedBox(height: (narrow ? 16 : 20).u),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
