// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import '../status_icons.dart';
import 'kit_connection_dot.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The state of the wallet's connection as a word with a dot (HANDOFF 7.1): [ok] "Ready",
/// [warn] "Reconnecting". Built for Home but not shown there until the design is settled. The
/// dot ([KitConnectionDot]) has a soft halo of its colour. Pass [label] to name another state.
/// [onTap] makes it a button (Home and unlock open the connections sheet from it); [semanticsId]
/// names it for the test drivers.
class KitStatusPill extends StatelessWidget {
  const KitStatusPill({super.key, required this.ready, this.label, this.onTap, this.semanticsId, this.tor = false});

  final bool ready;
  final String? label;
  final VoidCallback? onTap;
  final String? semanticsId;

  /// While Tor is on: a small Tor glyph overlaps the pill's top-left corner, like a badge. The
  /// pill is otherwise unchanged. Its words say "Tor" first for a screen reader.
  final bool tor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final word = label ?? (ready ? context.l10n.phoneKitReady : context.l10n.phoneKitReconnecting);
    final base = Container(
      height: Kit.pill,
      padding: const EdgeInsetsDirectional.only(start: 11, end: 13),
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Home-busy: a pill that is not ready says so in the dot's colour.
          KitConnectionDot(ready: ready),
          const SizedBox(width: 8),
          Flexible(child: Text(word, style: KitType.pill.copyWith(color: ready ? t.dim : t.warn), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    final pill = !tor
        ? base
        : Stack(
            clipBehavior: Clip.none,
            children: [
              base,
              PositionedDirectional(
                top: -5,
                start: -5,
                child: ExcludeSemantics(
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    // A ring in the page's colour parts the badge from the pill.
                    decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle, border: Border.all(color: t.bg, width: 1.5)),
                    child: Icon(EpicGlyphs.tor, size: 11, color: t.accentText),
                  ),
                ),
              ),
            ],
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
