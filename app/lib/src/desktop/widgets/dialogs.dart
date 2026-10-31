// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../app/routes.dart' show deskNavProvider, DeskLocation;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'selectable.dart';
import 'surfaces.dart';

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

/// A modal dialog: optional glyph, title and description, body, and buttons at the foot
/// (right-aligned, primary last). 480 wide unless [width] says otherwise.
class EDialog extends StatelessWidget {
  const EDialog({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.tone = ETone.neutral,
    this.body,
    this.actions = const [],
    this._width,
    this.dismissible = true,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final ETone tone;
  final Widget? body;
  final List<Widget> actions;
  final double? _width;
  double get width => _width ?? 480.u;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final iconColor = switch (tone) {
      ETone.ok => c.ok,
      ETone.warn => c.warn,
      ETone.risk => c.risk,
      ETone.info => c.info,
      ETone.gold => c.accentText,
      ETone.neutral => c.dim,
    };
    final dialog = Dialog(
      backgroundColor: c.s4,
      insetPadding: EdgeInsets.all(Sp.x6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.lg),
        side: BorderSide(color: c.lineStrong),
      ),
      // The dialog's text is selectable and copyable (selectable.dart).
      child: DeskSelectable(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          // The title and the buttons stay in view; the body scrolls between them when the window
          // is too short (linux-09: a long message pushed Send off the screen; a short window at a
          // large scale must not overflow either, and a field scrolled into view must not take the
          // title with it).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A long description in a very short window scrolls by itself, never overflows.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Sp.x6, Sp.x6, Sp.x4, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 40.u,
                            height: 40.u,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Rad.sm),
                              border: Border.all(color: c.lineStrong),
                            ),
                            child: Icon(icon, size: Ctl.icon, color: iconColor),
                          ),
                          SizedBox(width: Sp.x3),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(header: true, child: Text(title, style: ts.h3)),
                              if (description != null) ...[SizedBox(height: 6.u), Text(description!, style: ts.bodyDim)],
                            ],
                          ),
                        ),
                        if (dismissible) EIconButton(icon: EIcons.close, label: context.l10n.deskKitCloseEsc, tabStop: false, onPressed: () => Navigator.of(context).maybePop()),
                      ],
                    ),
                  ),
                ),
              ),
              if (body != null)
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(padding: EdgeInsets.fromLTRB(Sp.x6, Sp.x5, Sp.x6, 0), child: body),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(Sp.x6),
                child: actions.isEmpty ? const SizedBox.shrink() : Wrap(alignment: WrapAlignment.end, spacing: Sp.x3, runSpacing: Sp.x2, children: actions),
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
                  EIconButton(icon: EIcons.close, label: context.l10n.deskKitCloseEsc, tabStop: false, onPressed: () => Navigator.of(context).maybePop()),
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
/// [action] is the next step (a button that closes the toast first); it stays longer.
void showEToast(BuildContext context, String title, {String? text, required ETone tone, ({String label, VoidCallback run})? action}) {
  final c = context.dc;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final color = switch (tone) {
    ETone.ok => c.ok,
    ETone.risk => c.risk,
    ETone.warn => c.warn,
    ETone.info => c.info,
    ETone.neutral => c.dim,
    ETone.gold => c.accentText,
  };
  final shown = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 380.u,
      backgroundColor: c.s4,
      elevation: 6,
      duration: Duration(seconds: action == null ? 4 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
        side: BorderSide(color: c.lineStrong),
      ),
      content: Row(
        children: [
          Icon(
            switch (tone) {
              ETone.risk => EIcons.error,
              ETone.warn => EIcons.alert,
              ETone.info || ETone.neutral => EIcons.info,
              ETone.ok || ETone.gold => EIcons.okCircle,
            },
            size: Ctl.icon,
            color: color,
          ),
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
                messenger.hideCurrentSnackBar();
                action.run();
              },
            ),
          ],
        ],
      ),
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
    }
  });
  shown.closed.then((_) {
    sub?.close();
    sub = null;
  });
}
