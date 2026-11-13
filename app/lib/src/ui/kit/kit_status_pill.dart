// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import '../via.dart';
import 'kit_connection_dot.dart';
import 'kit_route_icon.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The state of the wallet's connection as a word with a dot (HANDOFF 7.1): [ok] "Ready",
/// [warn] "Reconnecting". The dot ([KitConnectionDot]) has a soft halo of its colour. Pass
/// [label] to name another state. [onTap] makes it a button (Home and unlock open the
/// connections sheet from it); [semanticsId] names it for the test drivers.
class KitStatusPill extends StatelessWidget {
  const KitStatusPill({super.key, required this.ready, this.label, this.onTap, this.semanticsId, this.tor = false});

  final bool ready;
  final String? label;
  final VoidCallback? onTap;
  final String? semanticsId;

  /// While Tor is on: the Tor mark and the word "Tor" lead the pill, in the pill's own quiet
  /// ink, parted from the state by a hairline. The dot and the state's word stay as they are and
  /// keep their place when the pill sits at a row's end; the word names the route, the dot alone
  /// carries the state. A screen reader hears "Tor" first.
  final bool tor;

  /// The Tor mark's size: the cap height of the word next to it, optically.
  static const double torMark = 14;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final word = label ?? (ready ? context.l10n.phoneKitReady : context.l10n.phoneKitReconnecting);
    final pill = Container(
      height: Kit.pill,
      padding: EdgeInsetsDirectional.only(start: tor ? 10 : 11, end: 13),
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tor) ...[
            KitRouteIcon(Via.tor, size: torMark, color: t.dim),
            const SizedBox(width: 6),
            Text(context.l10n.netStatusTor, style: KitType.pill.copyWith(color: t.dim), maxLines: 1),
            const SizedBox(width: 9),
            Container(width: 1, height: 12, color: t.hair2),
            const SizedBox(width: 10),
          ],
          // Home-busy: a pill that is not ready says so in the dot's colour.
          KitConnectionDot(ready: ready),
          const SizedBox(width: 8),
          Flexible(child: Text(word, style: KitType.pill.copyWith(color: ready ? t.dim : t.warn), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    final id = semanticsId;
    // As a button the pill is 48 dp tall to touch (Android's guideline); the pill drawn is 32.
    // widthFactor 1: the box is as wide as the pill, so a row can put it at its end.
    Widget out = Semantics(
      label: tor ? '${context.l10n.netStatusTor}, $word' : word,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null ? pill : SizedBox(height: Kit.touchMin, child: Center(widthFactor: 1, child: pill)),
    );
    if (onTap != null) out = GestureDetector(behavior: HitTestBehavior.opaque, excludeFromSemantics: true, onTap: onTap, child: out);
    return id == null ? out : kitId(id, out);
  }
}
