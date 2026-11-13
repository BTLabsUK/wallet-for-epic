// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trust_ids.dart';
import '../desk_l10n.dart';
import '../app/routes.dart' show deskNavProvider, DeskLocation;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../../ui/theme/dialog_metrics.dart';
import '../../ui/theme/epic1_mark.dart';
import 'buttons.dart';
import 'modal.dart';
import 'motion.dart';
import 'selectable.dart';
import 'surfaces.dart';

export '../../ui/theme/dialog_metrics.dart' show DialogWidth, DialogMetrics;

/// Opens an [EDialog] over a scrim. Returns what the dialog pops.
Future<T?> showEDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) =>
    showDialog<T>(context: context, barrierDismissible: dismissible, barrierColor: context.dc.scrim, builder: builder);

/// Opens an [EDrawer] from the end edge.
Future<T?> showEDrawer<T>(BuildContext context, {required WidgetBuilder builder}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.commonClose,
  barrierColor: context.dc.scrim,
  transitionDuration: Dur.slow,
  pageBuilder: (context, _, _) => Align(alignment: Alignment.centerRight, child: builder(context)),
  transitionBuilder: (context, anim, _, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);

/// The one desktop dialog, centred: Close in the corner, the [tone]'s mark (a 52 px ticked
/// tile with [icon], or the tone's glyph), the title, one sentence ([description]), the body at
/// the dialog's full width, the footer, and a strip that says what Esc and Enter do. The tone
/// also draws a hairline and a soft light at the top edge; neutral wears the brand gold.
///
/// The footer is laid out here, so call sites cannot drift: all buttons [EBtnSize.md] tall;
/// ghost and soft buttons show as the outlined secondary; a destructive [EBtnKind.danger]
/// keeps the outlined risk style and the filled primary comes last; only one primary is filled
/// (an earlier one shows as a secondary). The buttons share one row, the main one 1.35 times
/// as wide as each of the others and last; past three, the first ones sit in a row above.
/// Pass plain `EButton`s (secondary), one `EButton.primary` or `EButton(kind: danger)`;
/// their `size` is ignored here.
class EDialog extends StatelessWidget {
  const EDialog({
    super.key,
    required this.title,
    this.description,
    this.titleTrailing,
    this.icon,
    this.tone = ETone.neutral,
    this.body,
    this.actions = const [],
    this.size = DialogWidth.standard,
    @Deprecated('Pass size: a DialogWidth') this._width,
    this.dismissible = true,
    this.foot,
  });

  final String title;

  /// Inline after the last word of the title (a verified check), wrapping with it.
  final Widget? titleTrailing;
  final String? description;
  final IconData? icon;
  final ETone tone;
  final Widget? body;

  /// Pinned under the scrolling body, above the buttons: a field the dialog focuses (a
  /// password), so its focus never scrolls the body's first lines out of a short window.
  final Widget? foot;
  final List<Widget> actions;

  /// Standard or wide: the dialog widths are a fixed set.
  final DialogWidth size;

  /// Deprecated: pass [size]. A width still given snaps to the nearest size (up to the
  /// standard width is standard, wider is wide); `double.infinity` is wide.
  final double? _width;

  /// The dialog's width at the current scale: 480 or 600 on desktop (the canvas's two widths).
  double get width => switch (_width == null ? size : DialogMetrics.snap(_width / deskScale)) {
    DialogWidth.standard => 480.u,
    DialogWidth.wide => 600.u,
  };
  final bool dismissible;

  /// The tile's glyph when no [icon] is given.
  static IconData toneIcon(ETone tone) => switch (tone) {
    ETone.ok => EIcons.okCircle,
    ETone.warn => EIcons.alert,
    ETone.risk => EIcons.error,
    ETone.info || ETone.neutral || ETone.gold => EIcons.info,
  };

  /// The footer in its order ([EModalButtons.ordered]).
  static List<Widget> footer(List<Widget> actions) => EModalButtons.ordered(actions);

  /// What Enter does, for the key strip: the label of a primary that takes the focus when the
  /// dialog opens ([EButton.autofocus]); null when Enter belongs to a field or to nothing.
  String? get _enterLabel {
    for (final a in actions.reversed) {
      if (a is EButton && a.kind == EBtnKind.primary) return a.autofocus && a.onPressed != null ? a.label : null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final window = MediaQuery.sizeOf(context);
    final narrow = window.width < Bp.desktop;
    // A short window (the canvas tightens under 760): a smaller mark and less air, so the body
    // keeps its room.
    final short = window.height < 760.u;
    final padRaw = (narrow ? 20 : 28).toDouble();
    final padX = padRaw.u;
    final padTop = (short ? 18 : (narrow ? 22 : 28)).u;
    final padEnd = (narrow ? 16 : 20).u;
    final enter = _enterLabel;
    final keys = dismissible || enter != null;
    final dialog = Dialog(
      backgroundColor: c.modal,
      insetPadding: EdgeInsets.all(Sp.x5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.lg),
        side: BorderSide(color: c.lineStrong),
      ),
      // The dialog's text is selectable and copyable (selectable.dart).
      child: DeskSelectable(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Stack(
            children: [
              // The tone at the top edge: a hairline and a soft light under it. Painted once.
              ...modalGlow(context, tone),
              // The title and the buttons stay in view; the body scrolls between them when the
              // window is too short (linux-09: a long message pushed Send off the screen; a short
              // window at a large scale must not overflow either, and a field scrolled into view
              // must not take the title with it).
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A long description in a very short window scrolls by itself, never overflows.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padX, padTop, padX, 0),
                        child: Column(
                          children: [
                            EModalMark(tone: tone, icon: icon ?? toneIcon(tone), short: short),
                            SizedBox(height: short ? Sp.x2 : 14.u),
                            Semantics(
                              header: true,
                              child: titleTrailing == null
                                  ? Epic1Text(title, style: ts.h2, textAlign: TextAlign.center)
                                  : Text.rich(
                                      TextSpan(
                                        text: title,
                                        children: [const TextSpan(text: ' '), WidgetSpan(alignment: PlaceholderAlignment.middle, child: titleTrailing!)],
                                      ),
                                      style: ts.h2,
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            if (description != null) ...[
                              SizedBox(height: 6.u),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 380.u),
                                child: Text(description!, style: ts.bodyDim, textAlign: TextAlign.center),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (body != null)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(padding: EdgeInsets.fromLTRB(padX, Sp.x4, padX, 0), child: body),
                      ),
                    ),
                  if (foot != null) Padding(padding: EdgeInsets.fromLTRB(padX, Sp.x4, padX, 0), child: foot),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(padX, short ? Sp.x4 : 22.u, padX, 0),
                      child: EModalButtons(actions: actions),
                    ),
                  if (keys)
                    EModalKeys(
                      padX: padRaw,
                      short: short,
                      hints: [
                        if (dismissible) EKeyHint(keys: l.deskSetFrameEscKey, does: l.commonClose),
                        if (enter != null) EKeyHint(keys: l.deskSetSearchKeyEnter, does: enter),
                      ],
                    )
                  else
                    SizedBox(height: padEnd),
                ],
              ),
              if (dismissible)
                PositionedDirectional(
                  top: 10.u,
                  end: 10.u,
                  child: EIconButton(semanticsId: TrustIds.dialogClose, icon: EIcons.close, label: l.deskKitCloseEsc, tabStop: false, onPressed: () => Navigator.of(context).maybePop()),
                ),
            ],
          ),
        ),
      ),
    );
    if (!dismissible) return dialog;
    return _EscCloses(child: dialog);
  }
}

/// A key and what it does, for the strip at a dialog's foot and wherever keys are named. One
/// run of text (the key as a chip inside it), so a button's own label stays the only plain text
/// with those words.
class EKeyHint extends StatelessWidget {
  const EKeyHint({super.key, required this.keys, required this.does});

  final String keys;
  final String does;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            // As wide as the key's name (a Container with an alignment would take the whole line).
            child: Container(
              constraints: BoxConstraints(minWidth: 20.u),
              height: 20.u,
              margin: EdgeInsetsDirectional.only(end: 6.u),
              padding: EdgeInsets.symmetric(horizontal: 6.u),
              decoration: BoxDecoration(
                color: c.s2,
                borderRadius: BorderRadius.circular(Rad.xs),
                border: Border(top: BorderSide(color: c.lineStrong), left: BorderSide(color: c.lineStrong), right: BorderSide(color: c.lineStrong), bottom: BorderSide(color: c.lineStrong, width: 2)),
              ),
              child: Center(widthFactor: 1, child: Text(keys, style: ts.mono(size: Fs.xs, color: c.dim, weight: FontWeight.w500))),
            ),
          ),
          TextSpan(text: does),
        ],
      ),
      style: ts.caption.copyWith(color: c.faint),
    );
  }
}

/// Esc closes a dialog that shows Close, also one opened with a barrier that does not dismiss
/// (a click outside must not lose the typing; Esc is deliberate). A PopScope in the dialog
/// still holds it while busy. With no field focused the dialog itself takes the focus, so Esc
/// reaches it.
class _EscCloses extends StatefulWidget {
  const _EscCloses({required this.child});

  final Widget child;

  @override
  State<_EscCloses> createState() => _EscClosesState();
}

class _EscClosesState extends State<_EscCloses> {
  final _node = FocusNode(debugLabel: 'dialog', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    // After the dialog's own autofocus has had its turn.
    Future<void>.delayed(Duration.zero, () {
      if (mounted && !_node.hasFocus && (ModalRoute.of(context)?.isCurrent ?? false)) _node.requestFocus();
    });
    FocusManager.instance.addListener(_refocus);
  }

  /// When the focus falls back to nothing or to a scope around the dialog (a system window,
  /// such as the Save dialog, took it and gave it back; a focused control went away), the
  /// dialog takes it again so Esc and Tab still work. Focus inside the dialog or in a menu it
  /// opened is left alone.
  void _refocus() {
    if (!mounted || _node.hasFocus) return;
    final f = FocusManager.instance.primaryFocus;
    final lost = f == null || (f is FocusScopeNode && _node.ancestors.contains(f));
    if (!lost || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    scheduleMicrotask(() {
      if (mounted && !_node.hasFocus) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_refocus);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => Navigator.of(context).maybePop())},
    child: Focus(focusNode: _node, child: widget.child),
  );
}

/// A side sheet: 420 wide, head with title and close, scrolling body, foot with actions.
class EDrawer extends StatelessWidget {
  const EDrawer({super.key, required this.title, required this.body, this.actions = const [], this._width});

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double? _width;
  double get width => _width ?? 420.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Material(
      color: c.s1,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.lineStrong)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: Ctl.topbar,
              padding: EdgeInsets.only(left: Sp.x6, right: Sp.x3),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(header: true, child: Text(title, style: context.ts.h3)),
                  ),
                  EIconButton(semanticsId: TrustIds.dialogClose, icon: EIcons.close, label: context.l10n.deskKitCloseEsc, tabStop: false, onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Sp.x6),
                child: DeskSelectable(child: body),
              ),
            ),
            if (actions.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x4),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Wrap(alignment: WrapAlignment.end, spacing: Sp.x3, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

/// A toast at the bottom right: icon, title, one line. Use [showEToast]. [tone] has no default,
/// so a failure never borrows the success tick: [ETone.risk] for errors, [ETone.warn] for refusals
/// and cautions, [ETone.ok] or [ETone.gold] for done, [ETone.info] or [ETone.neutral] for notes.
/// [action] is the next step (a button that closes the toast first); it stays longer. [items]
/// fold under the title (a digest's kinds), a chevron unfolds them, each a way somewhere; such
/// a toast stays while the pointer is over it or it is unfolded. A toast
/// goes with the screen it was shown on; one that [stay]s shows again on the next, until it is
/// closed or the window leaves the wallet (lock, welcome).
void showEToast(
  BuildContext context,
  String title, {
  String? text,
  required ETone tone,
  ({String label, VoidCallback run})? action,
  List<({String label, VoidCallback run})> items = const [],
  bool stay = false,
}) {
  final c = context.dc;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final color = switch (tone) {
    ETone.ok => c.ok,
    ETone.risk => c.risk,
    ETone.warn => c.warn,
    ETone.info => c.info,
    ETone.neutral => c.dim,
    // Gold is the brand's, never a notice's: a done toast in gold reads as done (ok).
    ETone.gold => c.ok,
  };
  var acted = false;
  final icon = switch (tone) {
    ETone.risk => EIcons.error,
    ETone.warn => EIcons.alert,
    ETone.info || ETone.neutral => EIcons.info,
    ETone.ok || ETone.gold => EIcons.okCircle,
  };
  Widget head({Widget? trailing}) => Row(
    children: [
      Icon(icon, size: Ctl.icon, color: color),
      SizedBox(width: Sp.x3),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: c.text, fontSize: Fs.md, fontWeight: FontWeight.w600),
            ),
            if (text != null)
              Text(
                text,
                style: TextStyle(color: c.dim, fontSize: Fs.sm),
              ),
          ],
        ),
      ),
      if (action != null) ...[
        SizedBox(width: Sp.x3),
        EButton(
          label: action.label,
          size: EBtnSize.sm,
          onPressed: () {
            acted = true;
            messenger.hideCurrentSnackBar();
            action.run();
          },
        ),
      ],
      if (trailing != null) ...[SizedBox(width: Sp.x2), trailing],
    ],
  );
  // A toast with items keeps its own clock: it stops while the pointer is over the toast or
  // the items are unfolded, so the SnackBar's own must not run out first.
  final folds = items.isNotEmpty;
  final shown = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 380.u,
      backgroundColor: c.s4,
      elevation: 6,
      duration: folds ? const Duration(days: 1) : Duration(seconds: action == null ? 4 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
        side: BorderSide(color: c.lineStrong),
      ),
      padding: folds ? EdgeInsets.fromLTRB(Sp.x3, Sp.x2, Sp.x2, Sp.x2) : null,
      content: folds
          ? _ToastFold(
              head: head,
              items: items,
              onItem: (item) {
                acted = true;
                messenger.hideCurrentSnackBar();
                item.run();
              },
              onExpire: () => messenger.hideCurrentSnackBar(),
            )
          : head(),
    ),
  );
  // A toast belongs to the screen it was shown on: leaving the screen closes it.
  ProviderContainer? container;
  try {
    container = ProviderScope.containerOf(context, listen: false);
  } on Object {
    container = null;
  }
  if (container == null) return;
  ProviderSubscription<DeskLocation>? sub;
  sub = container.listen(deskNavProvider, (prev, next) {
    if (prev?.route != next.route) {
      // Every toast of the screen goes, the queued ones too: closing a queued one by its
      // controller is not allowed.
      messenger.clearSnackBars();
      sub?.close();
      sub = null;
      if (stay && !acted && !next.route.bare) {
        // After every toast of the old screen cleared, this one's own clear included.
        scheduleMicrotask(() {
          if (context.mounted) showEToast(context, title, text: text, tone: tone, action: action, items: items, stay: true);
        });
      }
    }
  });
  shown.closed.then((_) {
    sub?.close();
    sub = null;
  });
}

/// The unfold chevron and the items of a digest toast, for tests.
const Key toastUnfoldKey = ValueKey('toast-unfold');
const Key toastItemsKey = ValueKey('toast-items');

/// How long a toast with items stays, folded and untouched.
const Duration toastFoldDuration = Duration(seconds: 10);

/// A toast's body that folds: the head with a chevron at its end, and under it, once unfolded,
/// one row per item, each a way somewhere. Its clock stops while the pointer is over it or the
/// items are unfolded.
class _ToastFold extends StatefulWidget {
  const _ToastFold({required this.head, required this.items, required this.onItem, required this.onExpire});

  final Widget Function({Widget? trailing}) head;
  final List<({String label, VoidCallback run})> items;
  final void Function(({String label, VoidCallback run}) item) onItem;
  final VoidCallback onExpire;

  @override
  State<_ToastFold> createState() => _ToastFoldState();
}

class _ToastFoldState extends State<_ToastFold> {
  bool _open = false;
  bool _hover = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(toastFoldDuration, () {
      if (mounted) widget.onExpire();
    });
  }

  void _settle() {
    if (_hover || _open) {
      _timer?.cancel();
    } else {
      _arm();
    }
  }

  void _toggle() {
    setState(() => _open = !_open);
    _settle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final still = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        _settle();
      },
      onExit: (_) {
        _hover = false;
        _settle();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            onTap: _toggle,
            child: EInkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(Rad.sm),
              child: widget.head(
                trailing: AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: still ? Duration.zero : Motion.expand,
                  curve: Motion.easeOut,
                  child: EIconButton(
                    key: toastUnfoldKey,
                    icon: EIcons.chevronDown,
                    label: _open ? l.msgCheckHideDetails : l.msgCheckShowDetails,
                    onPressed: _toggle,
                  ),
                ),
              ),
            ),
          ),
          ExpandFade(
            open: _open,
            child: Padding(
              key: toastItemsKey,
              padding: EdgeInsetsDirectional.only(start: Ctl.icon + Sp.x3 - Sp.x2, top: Sp.x2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in widget.items)
                    EInkWell(
                      onTap: () => widget.onItem(item),
                      borderRadius: BorderRadius.circular(Rad.sm),
                      hoverColor: c.hover,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 6.u),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.label, style: ts.body)),
                            Icon(EIcons.chevronRight, size: Ctl.iconSm, color: c.dim),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
