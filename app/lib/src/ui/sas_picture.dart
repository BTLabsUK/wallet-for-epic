// SPDX-License-Identifier: Apache-2.0
/// The pairing pictures as images: one of the 256 entries of the pairing word table, drawn from
/// its bundled SVG (`assets/sas/<name>.svg`, Noto Emoji, tool/sas_pictures.py), so it looks the
/// same on every system and needs no emoji font. Phone and desktop both draw a picture with
/// [SasPicture].
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models.dart' show SasWord;
import '../sas_table.dart' show sasTable;
import 'theme/fonts.dart' show sasEmojiFallback;

final Set<SasWord> _tableWords = sasTable.toSet();

/// The bundled picture of [word]: `assets/sas/<name>.svg` for an entry of [sasTable], else null.
String? sasPictureAsset(SasWord word) =>
    _tableWords.contains(word) ? 'assets/sas/${word.name}.svg' : null;

/// [word]'s picture, [size] square. Its name is the semantics label unless [semanticLabel]
/// says otherwise; [excludeFromSemantics] leaves it out where the name is read beside it. A word
/// that is not in the table, or a file that fails to load, falls back to the emoji as text.
class SasPicture extends StatelessWidget {
  const SasPicture(
    this.word, {
    super.key,
    this.size = 32,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  final SasWord word;
  final double size;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final asset = sasPictureAsset(word);
    final Widget picture = asset == null
        ? _emoji()
        : SvgPicture.asset(
            asset,
            width: size,
            height: size,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => _emoji(),
          );
    if (excludeFromSemantics) return ExcludeSemantics(child: picture);
    return Semantics(
      image: true,
      label: semanticLabel ?? word.name,
      excludeSemantics: true,
      child: picture,
    );
  }

  Widget _emoji() => SizedBox.square(
    dimension: size,
    child: Center(
      child: Text(
        word.emoji,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: size * 0.8, height: 1, fontFamilyFallback: sasEmojiFallback),
      ),
    ),
  );
}
