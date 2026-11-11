// SPDX-License-Identifier: Apache-2.0
/// The brand mark of a payment route, one icon per way a payment travels, all drawn on the same
/// 24-unit square so a row of them lines up. The files are the Epicbox brand pack's
/// `route-*-mono-current.svg` in `assets/routes/` (one colour, the ambient or given ink).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';
import '../via.dart';

/// The asset of [via]'s route mark. In person has no mark of its own: it is the QR one.
String kitRouteAsset(Via via) => switch (via) {
  Via.epicbox => 'assets/routes/route-epicbox.svg',
  Via.link => 'assets/routes/route-epic1.svg',
  Via.file => 'assets/routes/route-file.svg',
  Via.http => 'assets/routes/route-link.svg',
  Via.tor => 'assets/routes/route-tor.svg',
  Via.inPerson || Via.qr => 'assets/routes/route-qr.svg',
};

/// The route mark of [via] at [size], in [color] (the dim text colour by default). Decorative:
/// the words next to it name the route.
class KitRouteIcon extends StatelessWidget {
  const KitRouteIcon(this.via, {super.key, this.size = 15, this.color});

  final Via via;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      kitRouteAsset(via),
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color ?? context.tokens.dim),
      excludeFromSemantics: true,
    ),
  );
}
