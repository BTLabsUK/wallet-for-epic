import 'package:flutter/material.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Opens an [EDialog] over a scrim. Returns what the dialog pops.
Future<T?> showEDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) =>
    showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: context.dc.scrim,
      builder: builder,
    );

/// Opens an [EDrawer] from the end edge.
Future<T?> showEDrawer<T>(BuildContext context, {required WidgetBuilder builder}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close',
  barrierColor: context.dc.scrim,
  transitionDuration: Dur.slow,
  pageBuilder: (context, _, _) => Align(alignment: Alignment.centerRight, child: builder(context)),
  transitionBuilder: (context, anim, _, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      ),
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
    this.width = 480,
    this.dismissible = true,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final ETone tone;
  final Widget? body;
  final List<Widget> actions;
  final double width;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final iconColor = switch (tone) {
      ETone.ok => c.ok,
      ETone.warn => c.warn,
      ETone.risk => c.risk,
      ETone.gold => c.accentText,
      ETone.neutral => c.dim,
    };
    return Dialog(
      backgroundColor: c.s4,
      insetPadding: const EdgeInsets.all(Sp.x6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.lg),
        side: BorderSide(color: c.lineStrong),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.x6, Sp.x6, Sp.x4, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Rad.sm),
                          border: Border.all(color: c.lineStrong),
                        ),
                        child: Icon(icon, size: Ctl.icon, color: iconColor),
                      ),
                      const SizedBox(width: Sp.x3),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(header: true, child: Text(title, style: ts.h3)),
                          if (description != null) ...[
                            const SizedBox(height: 6),
                            Text(description!, style: ts.bodyDim),
                          ],
                        ],
                      ),
                    ),
                    if (dismissible)
                      EIconButton(
                        icon: EIcons.close,
                        label: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                  ],
                ),
              ),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.x6, Sp.x5, Sp.x6, 0),
                  child: body,
                ),
              Padding(
                padding: const EdgeInsets.all(Sp.x6),
                child: actions.isEmpty
                    ? const SizedBox.shrink()
                    : Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Sp.x3,
                        runSpacing: Sp.x2,
                        children: actions,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A side sheet: 420 wide, head with title and close, scrolling body, foot with actions.
class EDrawer extends StatelessWidget {
  const EDrawer({super.key, required this.title, required this.body, this.actions = const [], this.width = 420});

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Material(
      color: c.s1,
      child: Container(
        width: width,
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.lineStrong))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: Ctl.topbar,
              padding: const EdgeInsets.only(left: Sp.x6, right: Sp.x3),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text(title, style: context.ts.h3))),
                  EIconButton(icon: EIcons.close, label: 'Close', onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(padding: const EdgeInsets.all(Sp.x6), child: body),
            ),
            if (actions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x4),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: Wrap(alignment: WrapAlignment.end, spacing: Sp.x3, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

/// A toast at the bottom right: icon, title, one line. Use [showEToast].
void showEToast(BuildContext context, String title, {String? text, ETone tone = ETone.ok}) {
  final c = context.dc;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final color = switch (tone) {
    ETone.ok => c.ok,
    ETone.risk => c.risk,
    ETone.warn => c.warn,
    _ => c.accentText,
  };
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 380,
      backgroundColor: c.s4,
      elevation: 6,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
        side: BorderSide(color: c.lineStrong),
      ),
      content: Row(
        children: [
          Icon(tone == ETone.risk ? EIcons.error : EIcons.okCircle, size: Ctl.icon, color: color),
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: c.text, fontSize: Fs.md, fontWeight: FontWeight.w600)),
                if (text != null) Text(text, style: TextStyle(color: c.dim, fontSize: Fs.sm)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
