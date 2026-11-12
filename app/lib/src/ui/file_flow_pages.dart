// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import 'kit/kit_row.dart';
import 'kit/kit_tokens.dart';
import 'theme/tokens.dart';

/// The card of a file the wallet made, on the "With a file" pages (HANDOFF 7.9): a well with a
/// file glyph, the [title] ("Payment file") and one [sub] line ("For 12.5 EPIC · made 18:12").
/// A screen reader hears it as one block.
class FileCard extends StatelessWidget {
  const FileCard({super.key, required this.title, required this.sub, this.icon = Icons.insert_drive_file_outlined});

  final String title;
  final String sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      label: '$title. $sub',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.group,
          borderRadius: BorderRadius.circular(Kit.rGroup),
          border: Border.all(color: t.hair),
        ),
        child: Row(
          children: [
            KitIconWell(icon, color: t.accentText, size: 46, iconSize: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: KitType.rowTitle.copyWith(fontSize: 17, color: t.text)),
                  const SizedBox(height: 3),
                  Text(sub, style: KitType.rowSub.copyWith(color: t.dim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line of guidance under a card: an info mark and [text] in the dim colour, one voice for
/// every "what happens next" line of the file and accept pages. [bare] drops the mark.
class FileInfoLine extends StatelessWidget {
  const FileInfoLine(this.text, {super.key, this.bare = false});

  final String text;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!bare) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ExcludeSemantics(child: Icon(Icons.info_outline_rounded, size: 18, color: t.dim)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(text, style: KitType.body.copyWith(color: t.dim))),
        ],
      ),
    );
  }
}

/// "18:12" in the device's own clock style, for the "made …" line of a file card.
String fileMadeTime(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

/// The info line and the figures of "when their reply arrives": a dim label over the next
/// step's row (see the send screen's file page).
class FileNextLabel extends StatelessWidget {
  const FileNextLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
    child: Text(text, style: KitType.groupLabel.copyWith(color: context.tokens.dim)),
  );
}
