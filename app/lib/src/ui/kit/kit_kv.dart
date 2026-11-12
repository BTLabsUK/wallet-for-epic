// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A label and its value on one line (`.kv`): 13 above and below, 14 in, the label dim at 15,
/// the value at the end. A [value] is plain text, [mono] sets it in the figure face (an
/// amount), [valueColor] tints it (the gold of an action), and a [chevron] or a [trailing]
/// widget sits after it. With [onTap] the row reads as a button.
class KitKvRow extends StatelessWidget {
  const KitKvRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.mono = false,
    this.valueColor,
    this.labelColor,
    this.chevron = false,
    this.onTap,
    this.semanticsId,
    this.maxValueLines = 2,
  });

  final String label;
  final String? value;

  /// A value that is not plain text, in place of [value].
  final Widget? valueWidget;
  final bool mono;
  final Color? valueColor;
  final Color? labelColor;
  final bool chevron;
  final VoidCallback? onTap;
  final String? semanticsId;
  final int maxValueLines;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final valueStyle = (mono ? KitType.rowAmount : KitType.body).copyWith(color: valueColor ?? t.text, height: 1.3);
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            // The label keeps its own width, up to 70% of the row: a long one wraps instead of
            // pushing the value out; with no value it takes the row.
            if (value == null && valueWidget == null)
              Expanded(child: Text(label, style: KitType.body.copyWith(color: labelColor ?? t.dim, height: 1.3)))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.7),
                child: Text(label, style: KitType.body.copyWith(color: labelColor ?? t.dim, height: 1.3)),
              ),
            if (value != null || valueWidget != null) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child:
                      valueWidget ??
                      Text(value!, style: valueStyle, textAlign: TextAlign.end, maxLines: maxValueLines, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            if (chevron) ...[const SizedBox(width: 6), Icon(KitIcons.chevron, size: 18, color: t.faint)],
          ],
        ),
      ),
    );
    // A row that can be tapped is at least 48 tall (the platform's tap target; the frame's 46
    // is 2 short of it).
    final row = onTap == null
        ? Semantics(container: true, child: body)
        : Semantics(
            button: true,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(alignment: AlignmentDirectional.centerStart, child: body),
              ),
            ),
          );
    return kitId(semanticsId, Material(type: MaterialType.transparency, child: row));
  }
}
