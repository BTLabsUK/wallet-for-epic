// SPDX-License-Identifier: Apache-2.0
/// The phone's view of the wallet's message checks ([MessageCheck]), folded by default: one
/// row with a quiet icon, the headline ("Checked 2 min ago", live) and, under it, what the
/// last check found in a few words. A tap unfolds the findings in three groups, Read, Waiting
/// and Needs a look, each line with its own quiet icon; a tap folds them again. Nothing with a
/// zero count shows; without findings the row has no chevron and does not open.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../message_checks.dart';
import 'message_check_lines.dart';
import 'theme/tokens.dart';

/// The panel's keys, for tests and tours.
const Key messageCheckPanelKey = ValueKey('message-check-panel');
const Key messageCheckRowKey = ValueKey('message-check-row');
const Key messageCheckDetailsKey = ValueKey('message-check-details');

/// How long the unfold takes; the fold takes the same.
const Duration messageCheckUnfold = Duration(milliseconds: 220);

class MessageCheckPanel extends StatefulWidget {
  const MessageCheckPanel(this.check, {super.key, this.padding = EdgeInsets.zero, this.open = false});

  final MessageCheck check;

  /// Around the row and the details; the row's tap target fills it.
  final EdgeInsetsGeometry padding;

  /// Unfolded at first.
  final bool open;

  @override
  State<MessageCheckPanel> createState() => _MessageCheckPanelState();
}

class _MessageCheckPanelState extends State<MessageCheckPanel> {
  late bool _open = widget.open;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "Checked 2 min ago" moves on its own.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final view = messageCheckView(l, widget.check);
    final headline = messageCheckHeadline(l, view, DateTime.now());
    final summary = messageCheckSummary(l, view);
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : messageCheckUnfold;
    final canOpen = view.hasItems;
    final open = canOpen && _open;
    final hint = open ? l.msgCheckHideDetails : l.msgCheckShowDetails;
    final lead = switch (view.head) {
      CheckHead.checking => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: t.dim),
      ),
      CheckHead.failed => Icon(Icons.error_outline, size: 18, color: t.risk),
      CheckHead.checked || CheckHead.never => Icon(Icons.schedule, size: 18, color: t.dim),
    };
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 24, height: 24, child: Center(child: lead)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(headline, style: text.bodyMedium?.copyWith(color: view.head == CheckHead.failed ? t.risk : t.text)),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(summary, style: text.bodySmall?.copyWith(color: t.dim)),
              ],
            ],
          ),
        ),
        if (canOpen) ...[
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: Icon(Icons.expand_more, size: 24, color: t.dim),
          ),
        ],
      ],
    );
    return Padding(
      key: messageCheckPanelKey,
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            key: messageCheckRowKey,
            button: canOpen,
            expanded: canOpen ? open : null,
            label: summary.isEmpty ? headline : '$headline. $summary',
            hint: canOpen ? hint : null,
            excludeSemantics: true,
            onTap: canOpen ? () => setState(() => _open = !_open) : null,
            child: InkWell(
              onTap: canOpen ? () => setState(() => _open = !_open) : null,
              borderRadius: BorderRadius.circular(t.radiusSmall),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: row,
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            reverseDuration: duration,
            curve: open ? Curves.easeOutCubic : Curves.easeInCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: open ? _Details(key: messageCheckDetailsKey, view) : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// The findings in their groups: a small heading per group, one line per finding with a quiet
/// icon; a problem's icon is amber and its reason reads under it.
class _Details extends StatelessWidget {
  const _Details(this.view, {super.key});

  final MessageCheckView view;

  static IconData _icon(CheckItemKind kind) => switch (kind) {
    CheckItemKind.read => Icons.mark_email_read_outlined,
    CheckItemKind.held => Icons.hourglass_empty,
    CheckItemKind.more => Icons.more_horiz,
    CheckItemKind.refused => Icons.block,
    CheckItemKind.pairingFailed => Icons.link_off,
    CheckItemKind.unreadable => Icons.visibility_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final groups = [for (final g in CheckGroup.values) if (view.of(g).isNotEmpty) g];
    return Padding(
      // Under the row's icon column: the lines start where the headline starts.
      padding: const EdgeInsetsDirectional.only(start: 36, top: 2, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (n, g) in groups.indexed) ...[
            Padding(
              padding: EdgeInsets.only(top: n == 0 ? 0 : 12, bottom: 4),
              child: Text(
                checkGroupLabel(l, g).toUpperCase(),
                style: text.labelSmall?.copyWith(color: g == CheckGroup.problems ? t.warn : t.dim, letterSpacing: 0.8),
              ),
            ),
            for (final i in view.of(g))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(_icon(i.kind), size: 18, color: g == CheckGroup.problems ? t.warn : t.dim),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(i.text, style: text.bodyMedium),
                          if (i.why case final why?) Text(why, style: text.bodySmall?.copyWith(color: t.dim)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
