// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

/// Makes the readable text under it selectable with the mouse (drag, double-click a word,
/// triple-click a paragraph) and copyable with Ctrl+C or the right-click menu, as a desktop
/// app's text is. Every [Text] below joins in; controls opt out with [NoSelect] so a button's
/// label or a nav item never turns blue under a drag. Inputs keep their own selection.
///
/// One sits around the shell's page and one inside each dialog and drawer, inside the route's
/// focus scope: the region takes the focus when clicked (so Ctrl+C reaches it) and that focus
/// stays inside the dialog, where Esc and Tab still work. It is no Tab stop of its own.
class DeskSelectable extends StatefulWidget {
  const DeskSelectable({super.key, required this.child});

  final Widget child;

  @override
  State<DeskSelectable> createState() => _DeskSelectableState();
}

class _DeskSelectableState extends State<DeskSelectable> {
  final _node = FocusNode(debugLabel: 'selectable', skipTraversal: true);

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionArea(focusNode: _node, child: widget.child);
}

/// Text that a drag over the page must not select: a control's label, a nav item, a chip, the
/// recovery phrase. Taps and keys are untouched.
class NoSelect extends StatelessWidget {
  const NoSelect({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SelectionContainer.disabled(child: child);
}
