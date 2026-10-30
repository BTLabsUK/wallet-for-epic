// SPDX-License-Identifier: Apache-2.0
/// The quiet line beside every Cancel (and Withdraw) button: what cancelling does in this one
/// case, and a link, "How cancelling works", that opens Help › "Cancelling a payment" at the
/// matching heading. One widget, so the phone says it the same way everywhere (2026-10-25: the
/// rule is always visible around the button, never only in Help). The confirmations with a fee
/// line and an info icon are in `cancel_dialog.dart`.
library;

import 'package:flutter/material.dart';

import '../help/help_content.dart';
import '../l10n.dart';
import 'help_screen.dart';
import 'theme/tokens.dart';

/// [text], then the link opening [HelpId.cancel] at [anchor] ([HelpAnchor]). Small and dim by
/// default; [style] for a dialog's body. [alignment] follows the button it sits under.
class CancelNote extends StatelessWidget {
  const CancelNote({super.key, required this.text, required this.anchor, this.style, this.alignment = WrapAlignment.start});

  final String text;
  final String anchor;
  final TextStyle? style;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final base = style ?? Theme.of(context).textTheme.bodySmall!.copyWith(color: t.dim);
    final end = alignment == WrapAlignment.end;
    final body = Text(text, style: base, textAlign: end ? TextAlign.end : TextAlign.start);
    final link = Semantics(
      button: true,
      link: true,
      child: InkWell(
        onTap: () => openHelp(context, HelpId.cancel, anchor),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(
            l.cancelMoreInHelp,
            style: base.copyWith(
              color: t.accentText,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: t.accentText.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [body, link],
    );
  }
}
