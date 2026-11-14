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
                      Text(value!, style: valueStyle, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
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

/// `.kv`: a label and its value in a group, padding 13 14, 15 px, 16 between. The label is dim
/// ([labelStrong] makes it the text colour, weight 600); the value is mono (`b`) or [valueText]
/// in the text colour. [sub] is the dim 12 px line under a mono value. A [onTap] row is a
/// button with a faint chevron after the label (`button.kv`).
class KitKv extends StatelessWidget {
  const KitKv({
    super.key,
    required this.label,
    this.value,
    this.valueText,
    this.sub,
    this.labelStrong = false,
    this.valueWeight = FontWeight.w400,
    this.chevron = false,
    this.onTap,
  });

  final String label;

  /// The mono value (`b`).
  final String? value;

  /// A plain value in the body face, in the text colour (a note).
  final String? valueText;
  final String? sub;
  final bool labelStrong;
  final FontWeight valueWeight;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final labelStyle = KitType.body.copyWith(
      height: 1.3,
      color: labelStrong ? t.text : t.dim,
      fontWeight: labelStrong ? FontWeight.w600 : FontWeight.w400,
    );
    Widget? main;
    if (value != null) {
      // At large text the figure shrinks to its share of the row; the label keeps the rest.
      main = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(value!, maxLines: 1, textAlign: TextAlign.end, style: KitType.rowAmount.copyWith(color: t.text, fontWeight: valueWeight)),
      );
    } else if (valueText != null) {
      main = Text(valueText!, textAlign: TextAlign.end, maxLines: 3, overflow: TextOverflow.ellipsis, style: labelStyle.copyWith(color: t.text, fontWeight: FontWeight.w400));
    }
    final right = main == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              main,
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sub!, textAlign: TextAlign.end, style: KitType.body.copyWith(fontSize: 12, height: 1.2, color: t.faint)),
                ),
            ],
          );
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: labelStyle)),
          if (chevron) Icon(KitIcons.chevron, size: 18, color: t.faint),
          if (right != null) ...[
            const SizedBox(width: 16),
            Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: right)),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      container: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// `.hint`: an info glyph and 13 px dim text at 1.45, padding 0 20, 8 between. [inset] is the
/// side padding where the page already has its own 16 (4 there).
class KitHint extends StatelessWidget {
  const KitHint(this.text, {super.key, this.inset = 20});

  final String text;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ExcludeSemantics(child: Icon(KitIcons.info, size: 16, color: t.dim)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: KitType.body.copyWith(fontSize: 13, height: 1.45, color: t.dim))),
        ],
      ),
    );
  }
}
