// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_connection_dot.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The state of the wallet's connection as a word with a dot (HANDOFF 7.1): [ok] "Ready",
/// [warn] "Reconnecting". Built for Home but not shown there until the design is settled. The
/// dot ([KitConnectionDot]) has a soft halo of its colour. Pass [label] to name another state.
/// [onTap] makes it a button (Home and unlock open the connections sheet from it); [semanticsId]
/// names it for the test drivers.
class KitStatusPill extends StatelessWidget {
  const KitStatusPill({super.key, required this.ready, this.label, this.onTap, this.semanticsId});

  final bool ready;
  final String? label;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final word = label ?? (ready ? context.l10n.phoneKitReady : context.l10n.phoneKitReconnecting);
    final pill = Container(
      height: Kit.pill,
      padding: const EdgeInsetsDirectional.only(start: 11, end: 13),
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KitConnectionDot(ready: ready),
          const SizedBox(width: 11),
          Flexible(child: Text(word, style: KitType.pill.copyWith(color: t.dim), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    final id = semanticsId;
    // As a button the pill is 48 dp tall to touch (Android's guideline); the pill drawn is 32.
    Widget out = Semantics(
      label: word,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null ? pill : SizedBox(height: Kit.touchMin, child: Center(child: pill)),
    );
    if (onTap != null) out = GestureDetector(behavior: HitTestBehavior.opaque, excludeFromSemantics: true, onTap: onTap, child: out);
    return id == null ? out : kitId(id, out);
  }
}
