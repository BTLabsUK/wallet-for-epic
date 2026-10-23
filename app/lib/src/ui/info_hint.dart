/// The phone's explanation marks: a row shows its label only, and the sentence that explains
/// it sits behind a small info icon (a tap or a long press shows it; a screen reader reads it
/// as the row's hint). Settings rows, switches and section titles use it; the main view never
/// carries explanation text.
library;

import 'package:flutter/material.dart';

import 'theme/tokens.dart';

/// The info icon with [text] as its tooltip, [size] square (a 40 dp target inside a row that
/// is itself the 48 dp target).
class InfoHint extends StatelessWidget {
  const InfoHint(this.text, {super.key, this.size = 40});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(Icons.info_outline, size: 18, color: t.dim),
          ),
        ),
      ),
    );
  }
}

/// A row title with its [InfoHint] after it: `Text(title)` for a `ListTile.title` that has an
/// explanation. The title keeps the row's text style; the icon is 40 dp square, which keeps
/// the row at its usual height.
class TitleWithHint extends StatelessWidget {
  const TitleWithHint(this.title, {super.key, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(title)),
      const SizedBox(width: 4),
      InfoHint(hint, size: 32),
    ],
  );
}
