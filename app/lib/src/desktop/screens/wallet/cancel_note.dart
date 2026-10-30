// SPDX-License-Identifier: Apache-2.0
/// The quiet line beside every Cancel (and Withdraw) button on the desktop: what cancelling does
/// in this one case, and "More in Help", which opens Settings › Help › "Cancelling a payment" at
/// the matching heading. In a confirmation whose cancel also moves the coins back to this
/// wallet, the fee line sits above the link with an info icon that explains it ([EInfoHint],
/// 2026-10-30). The phone's twin is `ui/cancel_note.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../help/help_content.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/help_pairing.dart' show HelpAt;

/// The info icon beside the fee line of a cancel confirmation (tests).
const Key deskCancelFeeHintKey = ValueKey('desk-cancel-fee-hint');

/// [text] (none for a link alone) then the Help link for [anchor] ([HelpAnchor]). [inDialog]
/// closes the dialog first, as the Help page opens under it otherwise. With [fee], the line
/// "Costs the normal network fee." and its info icon come before the link: only for a cancel
/// that also moves the coins back to this wallet.
class DeskCancelNote extends ConsumerWidget {
  const DeskCancelNote({super.key, this.text, required this.anchor, this.style, this.inDialog = false, this.alignment = WrapAlignment.start, this.fee = false});

  final String? text;
  final String anchor;
  final TextStyle? style;
  final bool inDialog;
  final WrapAlignment alignment;
  final bool fee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = style ?? context.ts.small.copyWith(color: context.dc.faint);
    void open() {
      if (inDialog) Navigator.of(context).pop();
      ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.cancel, anchor: anchor));
    }
    final link = ELink(label: l.cancelMoreInHelp, onPressed: open);
    if (!fee) {
      return Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Sp.x2,
        children: [
          if (text case final text?) Text(text, style: base),
          link,
        ],
      );
    }
    final end = alignment == WrapAlignment.end;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (text case final text?) ...[Text(text, style: base), SizedBox(height: Sp.x1)],
        // The fee line and, right beside it, why: the icon opens the explanation as a popover.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(l.cancelFeeLine, style: context.ts.body)),
            SizedBox(width: Sp.x1),
            EInfoHint(l.cancelFeeWhy, key: deskCancelFeeHintKey, title: l.sendNetworkFee, icon: EIcons.info),
          ],
        ),
        SizedBox(height: Sp.x2),
        link,
      ],
    );
  }
}
