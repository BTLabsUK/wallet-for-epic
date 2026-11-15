// SPDX-License-Identifier: Apache-2.0
/// The Epicmail logo, the envelope from Epicmail's own brand files (`assets/brand/epicmail-mark-*.svg`,
/// copied from the Epicmail repository's `docs/assets`: a dark and a light drawing, two colours
/// each). Shown where a screen would say Epicbox for a relay that runs Epicmail
/// (`relay_software.dart`), at the size of the app's other inline icons.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_svg/flutter_svg.dart';

import 'l10n.dart';

/// The path of the logo for a [dark] or light surface.
String epicmailMarkAsset({required bool dark}) => dark ? 'assets/brand/epicmail-mark-dark.svg' : 'assets/brand/epicmail-mark-light.svg';

/// The logo alone, [size] logical pixels square. Decorative: the word beside it names it.
class EpicmailMark extends StatelessWidget {
  const EpicmailMark({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      epicmailMarkAsset(dark: Theme.of(context).brightness == Brightness.dark),
      width: size,
      height: size,
      excludeFromSemantics: true,
    ),
  );
}

/// The logo and the name, as one run of text: "✉ Epicmail", the logo [size] tall, sitting on
/// the text's line, with [before] and [after] around it ("Connected · Epicmail").
class EpicmailName extends StatelessWidget {
  const EpicmailName({super.key, this.style, this.size = 14, this.before, this.after, this.maxLines, this.overflow, this.textAlign});

  /// "Connected · Epicmail": the connected line's words around the name, in the language's own
  /// order (the template's `{server}` is where the logo and name go), then [server] (the host,
  /// with Advanced server details) after a dot.
  factory EpicmailName.connected(AppLocalizations l, {Key? key, TextStyle? style, double size = 14, String? server}) {
    const mark = '\u0000';
    final parts = l.receiveEpicboxConnected(mark).split(mark);
    final after = parts.length > 1 ? parts.sublist(1).join() : '';
    final tail = server == null ? after : '$after · $server';
    return EpicmailName(key: key, style: style, size: size, before: parts.first, after: tail.isEmpty ? null : tail);
  }

  final TextStyle? style;
  final double size;

  /// Text before the logo, and after the name.
  final String? before;
  final String? after;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        if (before != null) TextSpan(text: before),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(padding: const EdgeInsets.only(right: 5), child: EpicmailMark(size: size)),
        ),
        TextSpan(text: context.l10n.relayNameEpicmail),
        if (after != null) TextSpan(text: after),
      ],
    ),
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
  );
}
