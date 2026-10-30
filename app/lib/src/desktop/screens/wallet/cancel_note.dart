// SPDX-License-Identifier: Apache-2.0
/// The quiet line beside every Cancel (and Withdraw) button on the desktop: what cancelling does
/// in this one case, and "How cancelling works", which opens Settings › Help › "Cancelling a
/// payment" at the matching heading. In a confirmation where the other side could still finish
/// the payment, [DeskCancelChoices] puts the two ways to cancel above the buttons, each on one
/// line with its name: the fee line with an info icon for Cancel for sure, "Free. The payment
/// may still finish." for Stop waiting (2026-10-30). The phone's twin is `ui/cancel_note.dart`
/// and `ui/cancel_dialog.dart`.
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
/// closes the dialog first, as the Help page opens under it otherwise.
class DeskCancelNote extends ConsumerWidget {
  const DeskCancelNote({super.key, this.text, required this.anchor, this.style, this.inDialog = false, this.alignment = WrapAlignment.start});

  final String? text;
  final String anchor;
  final TextStyle? style;
  final bool inDialog;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = style ?? context.ts.small.copyWith(color: context.dc.faint);
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Sp.x2,
      children: [
        if (text case final text?) Text(text, style: base),
        DeskCancelHelpLink(anchor: anchor, inDialog: inDialog),
      ],
    );
  }
}

/// "How cancelling works": opens Help › Cancelling a payment at [anchor].
class DeskCancelHelpLink extends ConsumerWidget {
  const DeskCancelHelpLink({super.key, required this.anchor, this.inDialog = false});

  final String anchor;
  final bool inDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ELink(
      label: context.l10n.cancelMoreInHelp,
      onPressed: () {
        if (inDialog) Navigator.of(context).pop();
        ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.cancel, anchor: anchor));
      },
    );
  }
}

/// The body of a confirmation with Keep / Stop waiting / Cancel for sure: one line per way to
/// cancel, named as its button is, then the Help link. The fee belongs to Cancel for sure
/// alone; the info icon beside it explains both ways in plain words.
class DeskCancelChoices extends StatelessWidget {
  const DeskCancelChoices({super.key, required this.anchor});

  final String anchor;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final name = ts.body.copyWith(fontWeight: FontWeight.w600);
    final line = ts.body.copyWith(color: context.dc.dim);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                Padding(padding: EdgeInsets.only(right: Sp.x3, top: Sp.x1, bottom: Sp.x1), child: Text(l.cancelForSure, style: name)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(l.cancelFeeLine, style: line)),
                    SizedBox(width: Sp.x1),
                    EInfoHint(l.cancelChoicesWhy, key: deskCancelFeeHintKey, title: l.cancelChoicesTitle, icon: EIcons.info),
                  ],
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(padding: EdgeInsets.only(right: Sp.x3, top: Sp.x1, bottom: Sp.x1), child: Text(l.cancelStopWaiting, style: name)),
                Text(l.cancelStopWaitingLine, style: line),
              ],
            ),
          ],
        ),
        SizedBox(height: Sp.x3),
        DeskCancelHelpLink(anchor: anchor, inDialog: true),
      ],
    );
  }
}
