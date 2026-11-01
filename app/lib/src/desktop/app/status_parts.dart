// SPDX-License-Identifier: Apache-2.0
/// The parts a status popover is built from (`status_popover.dart`), one look for every
/// service and level: a header with the service's tile (the server's operator icon or
/// initials as the server lists show it, or the service's glyph on a gold-ticked tile for Tor
/// and Link), the name with its state as a badge and the server under it; the facts as a
/// strip of aligned cells; a footer band with the actions. The phone's sheets draw the same
/// anatomy in their own tokens (`ui/levels/status_parts.dart`).
library;

import 'package:flutter/material.dart';

import '../../ui/server_tile.dart';
import '../../ui/theme/protocol.dart' show CornerTicksPainter;
import '../widgets/kit.dart';
import '../widgets/server_list_panel.dart' show deskTileColors;

/// The badge tone of a state: the popover's header says the state in words with the dot.
ETone deskStateTone(EState s) => switch (s) {
  EState.ok => ETone.ok,
  EState.active => ETone.info,
  EState.warn => ETone.warn,
  EState.risk => ETone.risk,
  EState.off => ETone.neutral,
};

/// The tile's side in the header; the switch list's rows use a smaller one.
double get deskStatusTile => 36.u;

/// A server's tile for a status header: the operator's icon, or initials on a tint, as in the
/// server lists ([ServerTileView]); no corner dot, the header's badge says the state.
class DeskServerTile extends StatelessWidget {
  const DeskServerTile({super.key, required this.host, this.operator, this.icon, this.size, this.dimmed = false});

  final String host;
  final String? operator;
  final ServerIcon? icon;
  final double? size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final px = size ?? deskStatusTile;
    return ServerTileView(
      operator: operator,
      host: host,
      icon: icon,
      state: null,
      showDot: false,
      dimmed: dimmed,
      size: px,
      radius: px >= deskStatusTile ? Rad.sm : 5.u,
      fontFamily: context.ts.mono().fontFamily,
      colors: deskTileColors(c),
    );
  }
}

/// A service's tile where there is no server to show (Tor, Link · HTTP): its glyph in gold on
/// the s2 ground with the brand's corner ticks; faint, without the ticks, while it is off.
class DeskServiceTile extends StatelessWidget {
  const DeskServiceTile({super.key, required this.icon, required this.state, this.size});

  final IconData icon;
  final EState state;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final px = size ?? deskStatusTile;
    final off = state == EState.off;
    return ExcludeSemantics(
      child: Container(
        width: px,
        height: px,
        decoration: BoxDecoration(
          color: c.s2,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(Rad.sm),
        ),
        child: CustomPaint(
          foregroundPainter: off ? null : CornerTicksPainter(c.tick, length: px / 5, width: 1.5),
          child: Center(child: Icon(icon, size: px / 2, color: off ? c.faint : c.accentText)),
        ),
      ),
    );
  }
}

/// The header: [tile], then the [name] with the state [word] as a badge in its tone, and
/// [second] (a host in mono, or a state detail) under them. [rowKey] marks the name row for
/// tests.
class DeskStatusHeader extends StatelessWidget {
  const DeskStatusHeader({
    super.key,
    required this.tile,
    required this.name,
    required this.word,
    required this.state,
    this.second,
    this.secondMono = false,
    this.rowKey,
    this.badgeKey,
  });

  final Widget tile;
  final String name;
  final String word;
  final EState state;
  final String? second;
  final bool secondMono;
  final Key? rowKey;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final second = this.second;
    return Semantics(
      header: true,
      child: Row(
        key: rowKey,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tile,
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.label)),
                    SizedBox(width: Sp.x2),
                    EBadge(word, key: badgeKey, tone: deskStateTone(state), dot: true, liveRegion: true),
                  ],
                ),
                if (second != null && second.isNotEmpty) ...[
                  SizedBox(height: 2.u),
                  Text(
                    second,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: secondMono ? ts.mono(size: Fs.xs, color: c.dim) : ts.caption.copyWith(color: c.dim),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One fact of the strip: [label] over [value]; [mono] for a host or an address.
typedef DeskFact = ({String label, String value, bool mono});

/// The facts as a strip: up to three short facts side by side, each its label over its value,
/// a hairline between them; a long value (an address) takes a row of its own. The strip sits
/// between two hairlines, like the figures under a balance.
class DeskFactStrip extends StatelessWidget {
  const DeskFactStrip(this.facts, {super.key});

  final List<DeskFact> facts;

  /// A value wider than this reads on its own row.
  static const int longValue = 18;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    if (facts.isEmpty) return const SizedBox.shrink();
    final short = [for (final f in facts) if (f.value.length <= longValue) f];
    final long = [for (final f in facts) if (f.value.length > longValue) f];
    Widget cell(DeskFact f, {bool padStart = false, bool padEnd = true}) => Padding(
      padding: EdgeInsetsDirectional.only(start: padStart ? Sp.x3 : 0, end: padEnd ? Sp.x3 : 0, top: Sp.x2, bottom: Sp.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(f.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.caption),
          SizedBox(height: 2.u),
          Text(
            f.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: f.mono ? ts.mono(size: Fs.sm, color: c.text) : ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    final rows = <Widget>[];
    for (var i = 0; i < short.length; i += 3) {
      final run = short.sublist(i, (i + 3).clamp(0, short.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (n, f) in run.indexed) ...[
                if (n > 0) VerticalDivider(width: 1, thickness: 1, color: c.lineStrong),
                Expanded(child: cell(f, padStart: n > 0)),
              ],
            ],
          ),
        ),
      );
    }
    for (final f in long) {
      rows.add(cell(f, padEnd: false));
    }
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineStrong), bottom: BorderSide(color: c.lineStrong))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (n, r) in rows.indexed) ...[
            if (n > 0) Divider(height: 1, thickness: 1, color: c.lineStrong),
            r,
          ],
        ],
      ),
    );
  }
}
