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
      child: Row(
        children: [
          Flexible(
            flex: 0,
            child: Text(label, style: KitType.body.copyWith(color: labelColor ?? t.dim, height: 1.3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child:
                  valueWidget ??
                  (value == null
                      ? const SizedBox.shrink()
                      : Text(value!, style: valueStyle, textAlign: TextAlign.end, maxLines: maxValueLines, overflow: TextOverflow.ellipsis)),
            ),
          ),
          if (chevron) ...[const SizedBox(width: 6), Icon(KitIcons.chevron, size: 18, color: t.faint)],
        ],
      ),
    );
    final row = onTap == null
        ? Semantics(container: true, child: body)
        : Semantics(button: true, child: InkWell(onTap: onTap, child: body));
    return kitId(semanticsId, Material(type: MaterialType.transparency, child: row));
  }
}
