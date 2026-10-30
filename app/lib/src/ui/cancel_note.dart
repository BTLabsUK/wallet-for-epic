// SPDX-License-Identifier: Apache-2.0
/// The quiet line beside every Cancel (and Withdraw) button: what cancelling does in this one
/// case, and a link that opens Help › "Cancelling a payment" at the matching heading. One
/// widget, so the phone says it the same way everywhere (2026-10-25: the rule is
/// always visible around the button, never only in Help). In a confirmation whose cancel also
/// moves the coins back to this wallet, the fee line sits under the text with an info icon
/// that explains it ([InfoHint], 2026-10-30).
library;

import 'package:flutter/material.dart';

import '../help/help_content.dart';
import '../l10n.dart';
import 'help_screen.dart';
import 'info_hint.dart';
import 'theme/tokens.dart';

/// The info icon beside the fee line of a cancel confirmation (tests).
const Key cancelFeeHintKey = ValueKey('cancel-fee-hint');

/// [text], then "More in Help" opening [HelpId.cancel] at [anchor] ([HelpAnchor]). Small and
/// dim by default; [style] for a dialog's body. [alignment] follows the button it sits under.
/// With [fee], the line "Costs the normal network fee." and its info icon come between the
/// text and the link: only for a cancel that also moves the coins back to this wallet.
class CancelNote extends StatelessWidget {
  const CancelNote({super.key, required this.text, required this.anchor, this.style, this.alignment = WrapAlignment.start, this.fee = false});

  final String text;
  final String anchor;
  final TextStyle? style;
  final WrapAlignment alignment;
  final bool fee;

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
    if (!fee) {
      return Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [body, link],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        body,
        const SizedBox(height: 4),
        // The fee line and, right beside it, why: the icon opens the explanation as a sheet.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(l.cancelFeeLine, style: base)),
            InfoHint(l.cancelFeeWhy, key: cancelFeeHintKey, size: 32, title: l.sendNetworkFee, icon: Icons.toll_outlined),
          ],
        ),
        Align(alignment: end ? Alignment.centerRight : Alignment.centerLeft, child: link),
      ],
    );
  }
}
