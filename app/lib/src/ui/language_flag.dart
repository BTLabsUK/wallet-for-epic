/// The small flag next to a language's own name in the language pickers (assets/flags, from
/// lipis/flag-icons, MIT). Bundled SVGs, not emoji: emoji flags do not draw on Windows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The flag file (without `.svg`) that stands for the app language [code]: English by the UK's,
/// as the app's copy is UK English; Chinese by the PRC's, as it is Simplified.
const Map<String, String> languageFlagFiles = {
  'en': 'gb',
  'de': 'de',
  'pl': 'pl',
  'ru': 'ru',
  'zh': 'cn',
  'th': 'th',
};

/// A 4:3 rounded flag of the language [code] ([height] tall), with a hairline in the theme's
/// line colour so the white parts (gb, pl, ru, th) stay visible on a light surface, and a little
/// muted so it stays quiet. The language's name next to it is its label, so it is left out of
/// semantics. A code with no flag draws nothing.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag(this.code, {super.key, this.height = 16});

  final String code;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = languageFlagFiles[code];
    if (file == null) return const SizedBox.shrink();
    final line =
        DividerTheme.of(context).color ?? Theme.of(context).dividerColor;
    final shape = BorderRadius.circular(3);
    return ExcludeSemantics(
      child: Opacity(
        opacity: 0.9,
        child: SizedBox(
          width: height * 4 / 3,
          height: height,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: line, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: SvgPicture.asset(
                'assets/flags/$file.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
