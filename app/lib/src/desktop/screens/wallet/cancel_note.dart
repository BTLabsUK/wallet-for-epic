// SPDX-License-Identifier: Apache-2.0
/// The quiet line beside every Cancel (and Withdraw) button on the desktop: what cancelling does
/// in this one case, and "More in Help", which opens Settings › Help › "Cancelling a payment" at
/// the matching heading. The phone's twin is `ui/cancel_note.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../help/help_content.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/help_pairing.dart' show HelpAt;

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
    final l = context.l10n;
    final base = style ?? context.ts.small.copyWith(color: context.dc.faint);
    void open() {
      if (inDialog) Navigator.of(context).pop();
      ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.cancel, anchor: anchor));
    }
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Sp.x2,
      children: [
        if (text case final text?) Text(text, style: base),
        ELink(label: l.cancelMoreInHelp, onPressed: open),
      ],
    );
  }
}
