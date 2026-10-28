// SPDX-License-Identifier: Apache-2.0
/// The keyboard rules of the desktop app, one set for every screen.
///
/// **Tab** visits a form's fields in visual order (text fields, selects, switches, checkboxes,
/// choice cards, segments), then its main button as the last stop, then wraps; Shift+Tab goes
/// back. Secondary controls are never stops: eye, info, copy, QR, clear and paste icons, icons
/// inside a field, a dialog's close icon, Back buttons and the page's back arrow. They stay
/// reachable by mouse, by screen reader (each keeps its semantics tap) and by a shortcut where
/// one matters (Alt+F8, Ctrl+Shift+P off Windows, shows or hides a password; Esc closes; Alt+Left goes back). Pages that
/// are not forms (lists, toolbars, the sidebar) keep their buttons as stops. Dialogs keep the
/// focus inside them. The shell's sidebar and page are separate groups, so the focus finishes
/// the page before it moves to the sidebar.
///
/// **Enter** in a field moves to the next field of its [EForm]; in the last field it runs the
/// form's main action when the form is valid and does nothing when it is not. Multi-line fields
/// keep Enter for a new line (Ctrl+Enter runs the main action from anywhere in the form). Enter
/// never fires a destructive or send-confirm step: those live in a dialog that must be open and
/// filled first, and the dialog's own button or Enter in its last field confirms.
///
/// **Esc** closes the top-most open thing, in this order: an open dropdown or menu, a tooltip
/// or popover, a dialog, a sheet, an expanded panel on the page. The key is consumed: one press
/// closes one thing. With nothing open it does nothing. A click after Esc never selects a
/// hidden item (closed lists are gone, an outside click only closes a list).
///
/// **Back / Forward**: the mouse Back button, Alt+Left and Backspace (outside a text field) go
/// one step back: inside a wizard or a detail pane first ([DeskStepBack]), then to the previous
/// place, until Overview; the mouse Forward button and Alt+Right go forward again. The page's
/// back arrow uses the same history. With a dialog or the tour open they do nothing (Esc is for
/// closing).
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A form: its fields take Enter as "next field", the last one as [onSubmit].
class EForm extends StatefulWidget {
  const EForm({super.key, required this.child, this.onSubmit});

  final Widget child;

  /// The main button's action; null while the form is not valid (Enter then does nothing).
  final VoidCallback? onSubmit;

  /// The form around [context], if any. Does not make [context] depend on it.
  static EFormState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_EFormScope>()?.state;

  @override
  State<EForm> createState() => EFormState();
}

class EFormState extends State<EForm> {
  final Set<FocusNode> _fields = {};

  /// A single-line field of this form ([EInput] registers itself).
  void register(FocusNode node) => _fields.add(node);

  void unregister(FocusNode node) => _fields.remove(node);

  /// The fields that can take the focus now, in reading order.
  List<FocusNode> get fields {
    final live = [
      for (final n in _fields)
        if (n.context != null && n.context!.mounted && n.canRequestFocus && n.context!.findRenderObject()?.attached == true) n,
    ];
    live.sort((a, b) {
      final ra = a.rect, rb = b.rect;
      if ((ra.top - rb.top).abs() > ra.height / 2) return ra.top.compareTo(rb.top);
      return ra.left.compareTo(rb.left);
    });
    return live;
  }

  /// Enter in [from]: the next field, or the main action from the last one.
  void enter(FocusNode from) {
    final order = fields;
    final i = order.indexOf(from);
    if (i >= 0 && i < order.length - 1) {
      order[i + 1].requestFocus();
      return;
    }
    widget.onSubmit?.call();
  }

  /// True when [node] is the form's last field (its text action is "done").
  bool isLast(FocusNode node) {
    final order = fields;
    return order.isEmpty || order.last == node;
  }

  @override
  Widget build(BuildContext context) => _EFormScope(
    state: this,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () => widget.onSubmit?.call(),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => widget.onSubmit?.call(),
      },
      child: FocusTraversalGroup(child: widget.child),
    ),
  );
}

class _EFormScope extends InheritedWidget {
  const _EFormScope({required this.state, required super.child});

  final EFormState state;

  @override
  bool updateShouldNotify(_EFormScope old) => false;
}

/// One step back inside a screen: a wizard's previous step or a detail pane's list. The
/// innermost one with an [onBack] wins; the app's Back (mouse, Alt+Left, Backspace) asks these
/// before it changes the place. A no-op [onBack] holds Back on a step that must not be left
/// that way (the wallet is being made, the phrase is on screen).
class DeskStepBack extends StatefulWidget {
  const DeskStepBack({super.key, required this.onBack, required this.child});

  /// Null: no inner step; Back changes the place.
  final VoidCallback? onBack;
  final Widget child;

  static final List<_DeskStepBackState> _mounted = [];

  /// Runs the innermost step back; false when no screen has one. The screen that holds the
  /// focus decides (its nearest [DeskStepBack] with an [onBack], then the ones around it);
  /// with no focus in a step, the most recent mounted one whose tickers run. A screen that is
  /// animating out (its ticker mode is off) never catches Back.
  static bool tryStepBack() {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null && focus.mounted) {
      var ran = false;
      focus.visitAncestorElements((e) {
        if (e is StatefulElement && e.state is _DeskStepBackState) {
          final s = e.state as _DeskStepBackState;
          final run = s.widget.onBack;
          if (run != null) {
            run();
            ran = true;
            return false;
          }
        }
        return true;
      });
      if (ran) return true;
    }
    for (final s in _mounted.reversed) {
      final run = s.widget.onBack;
      if (run != null && s.mounted && TickerMode.valuesOf(s.context).enabled) {
        run();
        return true;
      }
    }
    return false;
  }

  @override
  State<DeskStepBack> createState() => _DeskStepBackState();
}

class _DeskStepBackState extends State<DeskStepBack> {
  @override
  void initState() {
    super.initState();
    DeskStepBack._mounted.add(this);
  }

  @override
  void dispose() {
    DeskStepBack._mounted.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// True when the focus is in a text field (Backspace then edits, it does not go back).
bool deskTextFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  return ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}
