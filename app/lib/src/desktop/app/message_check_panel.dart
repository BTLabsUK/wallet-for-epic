// SPDX-License-Identifier: Apache-2.0
/// The desktop's view of the wallet's message checks ([MessageCheck]) in the Epicbox status
/// popover: the phone panel's twin (`ui/message_check_panel.dart`) in the desk idiom. Folded,
/// one row: a quiet icon, the headline ("Checked 2 min ago", live) and what the last check
/// found in a few words; a click, or the chevron, unfolds the findings in three groups, Read,
/// Waiting and Needs a look. Zero counts never show; without findings the row has no chevron.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../message_checks.dart';
import '../../ui/message_check_lines.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// The panel's keys, for tests and tours.
const Key deskMessageCheckPanelKey = ValueKey('desk-message-check-panel');
const Key deskMessageCheckRowKey = ValueKey('desk-message-check-row');
const Key deskMessageCheckDetailsKey = ValueKey('desk-message-check-details');

class DeskMessageCheckPanel extends StatefulWidget {
  const DeskMessageCheckPanel(this.check, {super.key, this.open = false});

  final MessageCheck check;

  /// Unfolded at first.
  final bool open;

  @override
  State<DeskMessageCheckPanel> createState() => _DeskMessageCheckPanelState();
}

class _DeskMessageCheckPanelState extends State<DeskMessageCheckPanel> {
  late bool _open = widget.open;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static IconData _icon(CheckItemKind kind) => switch (kind) {
    CheckItemKind.read => EIcons.invoice,
    CheckItemKind.held => EIcons.sand,
    CheckItemKind.more => EIcons.dots,
    CheckItemKind.refused => EIcons.cancel,
    CheckItemKind.pairingFailed => EIcons.lanOff,
    CheckItemKind.unreadable => EIcons.eyeOff,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final view = messageCheckView(l, widget.check);
    final headline = messageCheckHeadline(l, view, DateTime.now());
    final summary = messageCheckSummary(l, view);
    final canOpen = view.hasItems;
    final open = canOpen && _open;
    final still = MediaQuery.disableAnimationsOf(context);
    final hint = open ? l.msgCheckHideDetails : l.msgCheckShowDetails;
    final lead = switch (view.head) {
      CheckHead.checking => ESpinner(size: Ctl.iconSm, color: c.dim),
      CheckHead.failed => Icon(EIcons.error, size: Ctl.iconSm, color: c.risk),
      CheckHead.checked || CheckHead.never => Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim),
    };
    final groups = [for (final g in CheckGroup.values) if (view.of(g).isNotEmpty) g];
    void toggle() => setState(() => _open = !_open);
    return Column(
      key: deskMessageCheckPanelKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: deskMessageCheckRowKey,
          button: canOpen,
          expanded: canOpen ? open : null,
          label: summary.isEmpty ? headline : '$headline. $summary',
          hint: canOpen ? hint : null,
          excludeSemantics: true,
          onTap: canOpen ? toggle : null,
          child: EInkWell(
            onTap: canOpen ? toggle : null,
            borderRadius: BorderRadius.circular(Rad.sm),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x2),
              child: Row(
                children: [
                  SizedBox(width: Ctl.icon, height: Ctl.icon, child: Center(child: lead)),
                  SizedBox(width: Sp.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(headline, style: ts.body.copyWith(color: view.head == CheckHead.failed ? c.risk : c.text)),
                        if (summary.isNotEmpty) Text(summary, style: ts.small),
                      ],
                    ),
                  ),
                  if (canOpen) ...[
                    SizedBox(width: Sp.x2),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: still ? Duration.zero : Motion.expand,
                      curve: Motion.easeOut,
                      child: Icon(EIcons.chevronDown, size: Ctl.icon, color: c.dim),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ExpandFade(
          open: open,
          child: Padding(
            // Under the row's icon: the lines start where the headline starts.
            padding: EdgeInsetsDirectional.only(start: Sp.x2 + Ctl.icon + Sp.x2, end: Sp.x2, top: 2.u, bottom: Sp.x2),
            child: Column(
              key: deskMessageCheckDetailsKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (n, g) in groups.indexed) ...[
                  Padding(
                    padding: EdgeInsets.only(top: n == 0 ? 0 : Sp.x3, bottom: 4.u),
                    child: Text(
                      checkGroupLabel(l, g).toUpperCase(),
                      style: ts.caption.copyWith(color: g == CheckGroup.problems ? c.warn : c.dim, letterSpacing: 0.8, fontWeight: FontWeight.w600),
                    ),
                  ),
                  for (final i in view.of(g))
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.u),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2.u),
                            child: Icon(_icon(i.kind), size: Ctl.iconSm, color: g == CheckGroup.problems ? c.warn : c.dim),
                          ),
                          SizedBox(width: Sp.x2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(i.text, style: ts.body),
                                if (i.why case final why?) Text(why, style: ts.small),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
