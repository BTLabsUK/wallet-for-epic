// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_button.dart';
import 'kit_sheet.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The help sheet behind a header's "?" (HANDOFF Gap-2-Help): the grabber, a [title] such as
/// "How sending works", a few short paragraphs ([lines], or any [body] widget instead), then a
/// quiet "More in Help" button when [onMore] is set. Show it with [showKitHelp]. [sheetId] names
/// the sheet and [moreId] the button for the test drivers.
class KitHelpSheet extends StatelessWidget {
  const KitHelpSheet({super.key, required this.title, this.lines = const [], this.body, this.onMore, this.sheetId, this.moreId})
    : assert(body == null || lines.length == 0, 'Give lines or a body, not both');

  final String title;
  final List<String> lines;
  final Widget? body;

  /// Opens the matching Help page. [showKitHelp] closes the sheet first.
  final VoidCallback? onMore;
  final String? sheetId;
  final String? moreId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content =
        body ??
        (lines.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                      child: Text(lines[i], style: KitType.body.copyWith(color: t.dim)),
                    ),
                ],
              ));
    return kitId(
      sheetId,
      KitSheet(
        title: title,
        secondary: onMore == null
            ? null
            : KitButton(label: context.l10n.deskKitMoreInHelp, onPressed: onMore, kind: KitButtonKind.quiet, semanticsId: moreId),
        child: content == null ? null : Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: content),
      ),
    );
  }
}

/// Opens a [KitHelpSheet]. A tap on "More in Help" closes the sheet and then calls [onMore].
Future<void> showKitHelp(
  BuildContext context, {
  required String title,
  List<String> lines = const [],
  Widget? body,
  VoidCallback? onMore,
  String? sheetId,
  String? moreId,
}) => showKitSheet<void>(
  context: context,
  builder: (sheetContext) => KitHelpSheet(
    title: title,
    lines: lines,
    body: body,
    sheetId: sheetId,
    moreId: moreId,
    onMore: onMore == null
        ? null
        : () {
            Navigator.of(sheetContext).pop();
            onMore();
          },
  ),
);
