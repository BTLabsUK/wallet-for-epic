// SPDX-License-Identifier: Apache-2.0
/// The parts a status sheet is built from (`status_sheets.dart`, the connections sheet in
/// `home_status.dart`), the desktop popover's anatomy (`desktop/app/status_parts.dart`) in the
/// phone's tokens: a header with the service's tile (the server's operator icon or initials as
/// the server lists show it, or the service's glyph on a gold-ticked tile for Tor and Link), the
/// name with its state as a badge and the server under it; the facts as a strip of aligned
/// cells; the actions as the phone's full-width buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network.dart' show EpicboxRelay;
import '../../providers.dart' show networkChoiceProvider;
import '../../relay_directory.dart' show NodeStatus, RelayStatus, ServerIcon, nodeStatusFor, relayStatusProvider;
import '../../server_list.dart' show ServerKind, serverIconFor;
import '../../server_list_file.dart' show operatorFor;
import '../badge.dart';
import '../server_picker.dart' show publicNodeStatusProvider;
import '../server_tile.dart';
import '../status.dart' show StatusDot;
import '../theme/protocol.dart' show CornerTicksPainter;
import '../theme/tokens.dart';

/// The badge tone of a dot: the sheet's header says the state in words with the dot.
BadgeTone phoneStateTone(StatusDot dot) => switch (dot) {
  StatusDot.ok => BadgeTone.ok,
  StatusDot.busy => BadgeTone.info,
  StatusDot.bad => BadgeTone.risk,
  StatusDot.warn => BadgeTone.warn,
  StatusDot.off => BadgeTone.neutral,
};

/// The tile's side in a header; the switch list's rows use a smaller one.
const double statusTileSize = 44;

/// What the status site knows of a server in the list: the operator's name and icon.
typedef ServerFace = ({String? operator, ServerIcon? icon});

/// The operator and icon of [value] (a node URL, a relay's `host:port`) of [kind], from the
/// status site's lists as the server list sheet reads them; initials when it has nothing.
ServerFace serverFaceOf(WidgetRef ref, ServerKind kind, String value) {
  final preset = ref.watch(networkChoiceProvider).value?.preset;
  if (preset == null) return (operator: operatorFor(kind, value), icon: null);
  final nodes = ref.watch(publicNodeStatusProvider(preset)).value ?? const <NodeStatus>[];
  final relays = ref.watch(relayStatusProvider(preset)).value ?? const <RelayStatus>[];
  final known = [
    for (final n in nodes) (operator: n.operator, icon: n.icon),
    for (final r in relays) (operator: r.operator, icon: r.icon),
  ];
  if (kind == ServerKind.node) {
    final s = nodeStatusFor(nodes, value);
    final operator = operatorFor(kind, value, listed: s?.operator);
    return (operator: s?.operator ?? operator, icon: serverIconFor(s?.icon, s?.operator ?? operator, known));
  }
  final relay = EpicboxRelay.parse(value);
  final s = relay == null ? null : relays.where((r) => r.relay == relay).firstOrNull;
  final operator = operatorFor(kind, value, listed: s?.operator);
  return (operator: s?.operator ?? operator, icon: serverIconFor(s?.icon, s?.operator ?? operator, known));
}

/// A server's tile for a status header or a switch row: the operator's icon, or initials on a
/// tint, as in the server list ([ServerTileView]); no corner dot, the badge says the state.
class StatusServerTile extends StatelessWidget {
  const StatusServerTile({super.key, required this.host, this.operator, this.icon, this.size = statusTileSize, this.dimmed = false});

  final String host;
  final String? operator;
  final ServerIcon? icon;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ServerTileView(
      operator: operator,
      host: host,
      icon: icon,
      state: null,
      showDot: false,
      dimmed: dimmed,
      size: size,
      radius: size >= statusTileSize ? t.radiusSmall : 6,
      fontFamily: montserrat,
      colors: ServerTileColors(
        surface: t.surface,
        line: t.line,
        initials: t.dim,
        tints: [
          t.accent.withValues(alpha: 0.14),
          t.info.withValues(alpha: 0.16),
          t.text.withValues(alpha: 0.08),
        ],
        ok: t.ok,
        warn: t.warn,
        risk: t.risk,
        unknown: t.faint,
        info: t.info,
        ring: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

/// A service's tile where there is no server to show (Tor, Link): its glyph in gold on the
/// surface with the brand's corner ticks; faint, without the ticks, while it is off.
class StatusServiceTile extends StatelessWidget {
  const StatusServiceTile({super.key, required this.icon, required this.enabled, this.size = statusTileSize, this.child});

  final IconData icon;
  final bool enabled;
  final double size;

  /// Drawn in the glyph's place when given (the connections sheet's glyph with its state mark).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        child: CustomPaint(
          foregroundPainter: enabled ? CornerTicksPainter(t.tick, length: size / 5, width: 1.5) : null,
          child: Center(child: child ?? Icon(icon, size: size / 2, color: enabled ? t.accentText : t.faint)),
        ),
      ),
    );
  }
}

/// The header: [tile], then the [name] with the state [word] as a badge in its tone, and
/// [second] (a host in mono, or a state detail) under them.
class StatusSheetHeader extends StatelessWidget {
  const StatusSheetHeader({
    super.key,
    required this.tile,
    required this.name,
    required this.word,
    required this.dot,
    this.second,
    this.secondMono = false,
  });

  final Widget tile;
  final String name;
  final String word;
  final StatusDot dot;
  final String? second;
  final bool secondMono;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final second = this.second;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tile,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    EBadge(word, tone: phoneStateTone(dot), dot: true, liveRegion: true),
                  ],
                ),
                if (second != null && second.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    second,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: t.dim, fontFamily: secondMono ? t.monoFamily : null),
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
typedef SheetFact = ({String label, String value, bool mono});

/// The facts as a strip: up to three short facts side by side, each its label over its value,
/// a hairline between them; a long value takes a row of its own. The strip sits between two
/// hairlines.
class StatusFactStrip extends StatelessWidget {
  const StatusFactStrip(this.facts, {super.key});

  final List<SheetFact> facts;

  /// A value wider than this reads on its own row.
  static const int longValue = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    if (facts.isEmpty) return const SizedBox.shrink();
    final short = [for (final f in facts) if (f.value.length <= longValue) f];
    final long = [for (final f in facts) if (f.value.length > longValue) f];
    Widget cell(SheetFact f, {bool padStart = false, bool padEnd = true}) => Padding(
      padding: EdgeInsetsDirectional.only(start: padStart ? 12 : 0, end: padEnd ? 12 : 0, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(f.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          const SizedBox(height: 2),
          Text(
            f.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: f.mono ? null : FontWeight.w600, fontFamily: f.mono ? t.monoFamily : null),
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
                if (n > 0) VerticalDivider(width: 1, thickness: 1, color: t.lineStrong),
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
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.lineStrong), bottom: BorderSide(color: t.lineStrong))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (n, r) in rows.indexed) ...[
            if (n > 0) Divider(height: 1, thickness: 1, color: t.lineStrong),
            r,
          ],
        ],
      ),
    );
  }
}

/// A card inside a sheet: an offer (warn), a move done (ok) or a plain note (neutral), with an
/// icon, a title, the body and, under them, [actions].
class StatusSheetCard extends StatelessWidget {
  const StatusSheetCard({super.key, required this.title, required this.body, this.tone = BadgeTone.neutral, this.icon, this.actions = const []});

  final String title;
  final String body;
  final BadgeTone tone;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final (Color fg, Color bg) = switch (tone) {
      BadgeTone.ok => (t.ok, t.okSoft),
      BadgeTone.warn => (t.warn, t.warnSoft),
      BadgeTone.risk => (t.risk, t.riskSoft),
      BadgeTone.info => (t.info, t.infoSoft),
      BadgeTone.gold => (t.accentText, t.accentSoft),
      BadgeTone.neutral => (t.dim, t.surface),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: tone == BadgeTone.neutral ? t.line : fg.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 20, color: fg)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (n, a) in actions.indexed) ...[if (n > 0) const SizedBox(height: 8), a],
          ],
        ],
      ),
    );
  }
}
