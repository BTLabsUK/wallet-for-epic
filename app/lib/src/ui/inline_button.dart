// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

/// The inline text button's style: in a column of text its words start on the text's edge,
/// not the 12 dp in of a stock [TextButton]; 44 dp tall for the finger, 8 dp after the words so
/// the ink does not stop on the last letter. Merged over the theme's [TextButtonThemeData], so
/// colour and type stay the theme's.
final ButtonStyle inlineTextButtonStyle = TextButton.styleFrom(
  padding: const EdgeInsetsDirectional.only(end: 8),
  minimumSize: const Size(48, 44),
  alignment: AlignmentDirectional.centerStart,
);

/// A text button that sits in a column of text (More, Show the steps, Learn more, Save
/// contact), put at the column's start (an [Align] or a start-aligned column): its words line
/// up with the text above. [icon] puts a
/// glyph before the words, itself on the edge. [style] adds to [inlineTextButtonStyle] (a dim
/// colour). Dialog footers and a header's end keep the stock [TextButton].
class InlineTextButton extends StatelessWidget {
  const InlineTextButton({super.key, required this.onPressed, required this.child, this.icon, this.style});

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style == null ? inlineTextButtonStyle : this.style!.merge(inlineTextButtonStyle);
    final icon = this.icon;
    return icon == null
        ? TextButton(style: style, onPressed: onPressed, child: child)
        : TextButton.icon(style: style, onPressed: onPressed, icon: icon, label: child);
  }
}
