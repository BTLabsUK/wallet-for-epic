// SPDX-License-Identifier: Apache-2.0
/// The QR glyph the frames draw on the "Other ways", "In person" and "No address?" rows
/// (Receive-1, Receive-4, Receive-5, Send-1, Send-6): three corner squares and a small cluster,
/// stroke 1.75 on the 24 grid. Lucide's qr-code (KitIcons.qr) is a different, denser shape.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

const _svg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">'
    '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>'
    '<rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3h-3zM20 14v.01M14 20v.01M17 20h3v-3"/></svg>';

/// The frames' QR glyph at [size] in [color] (dim text by default). Decorative.
class KitQrGlyph extends StatelessWidget {
  const KitQrGlyph({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    _svg,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color ?? context.tokens.dim, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}
