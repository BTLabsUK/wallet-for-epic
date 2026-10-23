/// The one picker row for nodes and Epicbox servers (spec §18): bars, host, operator, the
/// relay's default tag, the node's tip column, latency, version and the star. Every list
/// (Settings › Node, Setup, Settings › Receiving) shows servers through [ServerRow], in the
/// neutral order of [neutralOrder]: nothing pinned, no node row tagged.
library;

import 'package:flutter/material.dart';

import 'kit.dart';

enum ServerKind { node, relay }

/// What a row knows about one server; a field the source does not give is null and prints "–".
@immutable
class ServerInfo {
  const ServerInfo({
    required this.value,
    required this.host,
    this.full,
    this.operator,
    this.state = EState.ok,
    this.behind,
    this.latencyMs,
    this.version,
    this.versionOld = false,
    this.isDefault = false,
    this.starred,
  });

  /// What a pick returns (the URL or domain).
  final String value;

  /// The host without scheme or port (the row); [full] with the port, for the tooltip.
  final String host;
  final String? full;
  final String? operator;

  /// risk = down (one bar), warn = behind or an older version (two), ok (three).
  final EState state;

  /// Blocks behind the network tip; 0 at the tip; null unknown.
  final int? behind;
  final int? latencyMs;
  final String? version;
  final bool versionOld;

  /// The D-13 Epicbox default: a tag on relay rows only, never on a node row.
  final bool isDefault;

  /// In My nodes (the star is on), not (off), or no star at all (null).
  final bool? starred;

  bool get down => state == EState.risk;

  /// The row's state from the facts: still being checked → off (neutral, never healthy);
  /// down → risk; behind or an older version → warn; else ok.
  static EState stateFor({required bool down, int? behind, bool versionOld = false, bool checking = false}) {
    if (checking) return EState.off;
    if (down) return EState.risk;
    if ((behind ?? 0) > 0 || versionOld) return EState.warn;
    return EState.ok;
  }
}

int _rank(EState s) => switch (s) {
  EState.ok => 0,
  EState.warn => 1,
  EState.risk => 2,
  EState.off => 3,
};

/// The neutral order of a public list: by state (healthy, degraded, down), then by the
/// latency the row shows (unknown last), the source's order as the tie-break. Stable: nothing
/// is pinned and no row jumps while the list is open (sort once, when it opens).
List<T> neutralOrder<T>(List<T> items, {required EState Function(T) state, required int? Function(T) latency}) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final s = _rank(state(a.$2)).compareTo(_rank(state(b.$2)));
    if (s != 0) return s;
    final la = latency(a.$2), lb = latency(b.$2);
    if (la != lb) {
      if (la == null) return 1;
      if (lb == null) return -1;
      final l = la.compareTo(lb);
      if (l != 0) return l;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Under this width the operator hides; under [narrowVersion] the version column too.
const double narrowOperator = 420;
const double narrowVersion = 480;

/// One list row, 36 u: bars · host · operator · [default] · tip · latency · version · star.
/// A down row keeps full bars (one, risk) and greys its words; it stays selectable.
class ServerRow extends StatelessWidget {
  const ServerRow({
    super.key,
    required this.kind,
    required this.info,
    this.selected = false,
    this.onTap,
    this.onStar,
    this.semanticsHint,
  });

  final ServerKind kind;
  final ServerInfo info;
  final bool selected;
  final VoidCallback? onTap;

  /// The star's press (the row shows a star only when [ServerInfo.starred] is set).
  final VoidCallback? onStar;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final i = info;
    final grey = i.down;
    final words = grey ? c.faint : c.text;
    final dim = grey ? c.faint : c.dim;
    final tip = switch (i.behind) {
      null => ('–', c.faint),
      0 => ('at tip', dim),
      final n when n < 0 => ('at tip', dim),
      final n => ('${digitsText(n)} behind', grey ? c.faint : c.warn),
    };
    final latency = i.down
        ? ('no answer', c.risk)
        : i.latencyMs == null
        ? ('–', c.faint)
        : ('${digitsText(i.latencyMs!)} ms', c.faint);
    final version = i.version == null ? ('–', c.faint) : ('v${i.version}', i.versionOld && !grey ? c.warn : c.faint);
    final star = i.starred;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final showOperator = w >= narrowOperator.u && i.operator != null && i.operator!.isNotEmpty;
        final showVersion = w >= narrowVersion.u;
        final row = Row(
          children: [
            ESignalBars(i.state),
            SizedBox(width: 10.u),
            Expanded(
              child: Tooltip(
                message: i.full ?? i.host,
                waitDuration: const Duration(milliseconds: 600),
                child: Text(i.host, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.mono(size: Fs.sm, color: words)),
              ),
            ),
            if (showOperator) ...[
              SizedBox(width: 10.u),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 110.u),
                child: Text(i.operator!, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.caption.copyWith(color: dim)),
              ),
            ],
            if (kind == ServerKind.relay && i.isDefault) ...[
              SizedBox(width: 10.u),
              const ETag('default'),
            ],
            if (kind == ServerKind.node) ...[
              SizedBox(width: 10.u),
              SizedBox(
                width: 72.u,
                child: Text(tip.$1, maxLines: 1, softWrap: false, textAlign: TextAlign.right, style: ts.caption.copyWith(color: tip.$2)),
              ),
            ],
            SizedBox(width: 10.u),
            SizedBox(
              width: 68.u,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(latency.$1, maxLines: 1, softWrap: false, textAlign: TextAlign.right, style: ts.mono(size: Fs.xs, color: latency.$2)),
              ),
            ),
            if (showVersion) ...[
              SizedBox(width: 10.u),
              SizedBox(
                width: 46.u,
                child: Text(version.$1, maxLines: 1, softWrap: false, textAlign: TextAlign.right, style: ts.mono(size: Fs.xs, color: version.$2)),
              ),
            ],
            if (star != null) ...[
              SizedBox(width: 10.u),
              EIconButton(
                icon: star ? EIcons.star : EIcons.starOutline,
                label: star ? 'Remove ${i.host} from my nodes' : 'Add ${i.host} to my nodes',
                size: EBtnSize.inline,
                selected: star,
                tabStop: false,
                onPressed: onStar,
              ),
            ],
          ],
        );
        return Semantics(
          button: onTap != null,
          selected: selected,
          label: 'Use ${i.host}${i.operator != null ? ', ${i.operator}' : ''}${i.down ? ', not answering' : ''}',
          hint: semanticsHint,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Rad.sm),
            focusColor: c.s3,
            hoverColor: c.s3,
            child: Container(
              height: 36.u,
              padding: EdgeInsets.symmetric(horizontal: 12.u),
              decoration: BoxDecoration(color: selected ? c.s3 : null, borderRadius: BorderRadius.circular(Rad.sm)),
              child: row,
            ),
          ),
        );
      },
    );
  }
}

/// The This computer row of the node list: the monitor, "Local node" and its state.
class LocalNodeRow extends StatelessWidget {
  const LocalNodeRow({super.key, required this.stateText, this.selected = false, this.onTap});

  /// `Not set up` / `Syncing 12 %` / `Synced` / `Stopped`.
  final String stateText;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: 'Use the local node, $stateText',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.sm),
        focusColor: c.s3,
        hoverColor: c.s3,
        child: Container(
          height: 36.u,
          padding: EdgeInsets.symmetric(horizontal: 12.u),
          decoration: BoxDecoration(color: selected ? c.s3 : null, borderRadius: BorderRadius.circular(Rad.sm)),
          child: Row(
            children: [
              SizedBox(width: 16.u, child: Icon(EIcons.monitor, size: 16.u, color: c.dim)),
              SizedBox(width: 10.u),
              Text('Local node', style: ts.body.copyWith(color: c.text)),
              SizedBox(width: 10.u),
              Expanded(child: Text(stateText, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.caption.copyWith(color: c.dim))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list's caption head: 11 u uppercase faint.
class ListGroupHead extends StatelessWidget {
  const ListGroupHead(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12.u, Sp.x3, 12.u, Sp.x1),
    child: ExcludeSemantics(
      child: Text(title.toUpperCase(), style: context.ts.caption.copyWith(fontSize: 11.u, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: context.dc.faint)),
    ),
  );
}

/// 2914414 → "2,914,414".
String digitsText(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
