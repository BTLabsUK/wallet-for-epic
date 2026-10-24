/// The status rows of the sidebar (spec §5, §16): Node, a divider, then Epicbox, HTTP and Tor,
/// each with signal bars, a name and one short line; the details in a hover card; a click
/// opens that service's settings. Every row is 40 u tall in every state, so the rail never
/// changes height.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../data/desk_node.dart';
import '../data/node_view.dart';
import '../data/tor_view.dart';
import '../screens/settings/prefs.dart';
import '../screens/settings/settings_http.dart' show httpRun;
import '../widgets/kit.dart';

/// One row's content, whatever the service.
class RailItem {
  const RailItem({
    required this.icon,
    required this.name,
    required this.word,
    required this.state,
    required this.second,
    this.marker,
    this.lines = const [],
    this.note,
    required this.open,
    required this.jump,
  });

  final IconData icon;
  final String name;
  final String word;
  final EState state;

  /// The line under the name: a host or a status word; "–" when off.
  final String second;

  /// After [second], never cut ("12 %", "no answer").
  final String? marker;
  final List<String> lines;

  /// Prose under the lines, wrapped at a reading width (the Tor row's explanation).
  final String? note;

  /// The hover card's last line: where a click goes.
  final String open;
  final SettingsJump jump;
}

/// The Epicbox, HTTP and Tor rows of a status (null: nothing known yet).
List<RailItem> receivingRailItems(AppLocalizations l, ServiceStatus? st, DeskSettings settings) {
  final eb = st?.epicboxHealth ?? ServiceHealth.checking;
  final ebHost = st?.epicbox.domain;
  final tor = torStateOf(settings, st);
  final ebWay = torWay(TorRoute.epicbox, tor);
  final ebWaits = eb != ServiceHealth.off && (ebWay == TorWay.wait || ebWay == TorWay.blocked);
  final ebWord = switch (eb) {
    _ when ebWaits => l.deskRailWaitingTor,
    ServiceHealth.ok => l.deskRailOn,
    ServiceHealth.checking => l.deskRailConnecting,
    ServiceHealth.slow => l.deskRailSlow,
    ServiceHealth.down => l.deskRailNotAnswering,
    ServiceHealth.off => l.deskRailOff,
  };
  final items = [
    RailItem(
      icon: EIcons.epicbox,
      name: 'Epicbox', // l10n-ok: product name
      word: st == null ? l.deskRailChecking : ebWord,
      state: st == null
          ? EState.off
          : ebWaits
          ? (ebWay == TorWay.blocked ? EState.risk : EState.warn)
          : stateOf(eb),
      second: eb == ServiceHealth.off || ebHost == null ? '–' : railHost('Epicbox', ebHost), // l10n-ok: product name
      lines: [
        if (eb != ServiceHealth.off && ebHost != null) ebHost,
        if (eb != ServiceHealth.off && ebWay == TorWay.overTor) l.deskRailOverTor,
        if (ebWaits) l.deskRailWaitsForTor,
        if (eb == ServiceHealth.down && !ebWaits) l.deskRailPaymentsWait,
      ],
      open: l.deskRailOpenEpicbox,
      jump: SettingsJump.epicbox,
    ),
  ];
  if (DeskFeatures.httpDirect) {
    final run = httpRun(st);
    final public = settings.publicMode;
    items.add(
      RailItem(
        icon: EIcons.http,
        name: l.methodDirectHttp,
        word: switch (run) {
          HttpRun.on => l.deskRailOn,
          HttpRun.busy => l.deskRailStarting,
          HttpRun.failed => l.deskRailNotReceiving,
          HttpRun.off => l.deskRailOff,
        },
        state: switch (run) {
          HttpRun.on => EState.ok,
          HttpRun.busy => EState.warn,
          HttpRun.failed => EState.risk,
          HttpRun.off => EState.off,
        },
        second: switch (run) {
          HttpRun.on => public ? l.deskRailOnInternet : l.deskRailOnLocal,
          HttpRun.busy => l.deskRailStarting,
          HttpRun.failed => st?.httpProblem == HttpProblem.portInUse || st?.httpProblem == HttpProblem.portUnavailable ? l.deskRailPortInUse : l.deskRailStopped,
          HttpRun.off => '–',
        },
        lines: [
          if (run != HttpRun.off) public ? l.deskRailPortInternet('${settings.httpPort}') : l.deskRailPortLocal('${settings.httpPort}'),
          if (run == HttpRun.failed && st?.httpProblem != null) httpProblemText(l, st!.httpProblem!, st.httpProblemPort ?? settings.httpPort),
        ],
        open: l.deskRailOpenHttp,
        jump: SettingsJump.http,
      ),
    );
  }
  if (DeskFeatures.tor) {
    // The one Tor switch, always shown: Off, Starting…, On, Not connected. A click opens
    // Settings › Privacy, where the switch is.
    final included = st?.torIncluded ?? true;
    final word = included ? torWord(l, tor) : l.deskRailTorNotInBuild;
    items.add(
      RailItem(
        icon: EIcons.tor,
        name: 'Tor', // l10n-ok: product name
        word: word,
        state: !included
            ? EState.off
            : switch (tor) {
                TorState.off => EState.off,
                TorState.starting => EState.warn,
                TorState.on => EState.ok,
                TorState.failed => EState.risk,
              },
        second: tor == TorState.starting ? l.deskRailStartingDots : word,
        marker: tor == TorState.starting ? '${st?.torProgress ?? 0} %' : null,
        note: included ? torNetworkHint(l) : null,
        lines: [
          if (tor == TorState.failed && st?.torProblem != null) st!.torProblem!,
          if (tor == TorState.on && st?.tor == ServiceHealth.slow) l.deskRailTorSlow(st?.torProblem ?? l.deskRailTorNoAddress),
        ],
        open: l.deskRailOpenPrivacy,
        jump: SettingsJump.tor,
      ),
    );
  }
  return items;
}

/// The Node row from a [NodeView].
RailItem nodeRailItem(AppLocalizations l, NodeView v) => RailItem(
  icon: EIcons.node,
  name: l.deskRailNode,
  word: v.word,
  state: v.state,
  second: v.host,
  marker: v.marker,
  lines: v.lines,
  open: l.deskRailOpenNode,
  jump: SettingsJump.node,
);

/// How often the rail asks about a remote node again.
const Duration railNodeRefresh = Duration(seconds: 60);

/// The rail: Node, a divider, Epicbox, HTTP, Tor. [horizontal] lays the compact rows side by
/// side (the phone's top bar).
class ServiceRows extends ConsumerStatefulWidget {
  const ServiceRows({super.key, this.compact = false, this.horizontal = false});

  final bool compact;
  final bool horizontal;

  @override
  ConsumerState<ServiceRows> createState() => _ServiceRowsState();
}

/// How long the wallet's node must stay down before the row says Not answering.
const Duration railDownAfter = Duration(seconds: 30);

/// The OS text scale the rail follows before its rows would outgrow 40 u.
const double railMaxTextScale = 1.2;

/// The rail's clock (tests set it).
DateTime Function() railClock = DateTime.now;

class _ServiceRowsState extends ConsumerState<ServiceRows> {
  Timer? _refresh;
  Timer? _downTimer;
  String? _url;

  /// When the wallet's node stopped answering; null while it answers.
  DateTime? _downSince;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(railNodeRefresh, (_) {
      final u = _url;
      if (mounted && u != null) ref.invalidate(deskNodeInfoProvider(u));
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _downTimer?.cancel();
    super.dispose();
  }

  /// The wallet's view of its node, once it has been down for [railDownAfter]: before that the
  /// row keeps what the node's own info says (a blip never flashes red).
  ServiceHealth? _settledHealth(ServiceHealth h) {
    if (h != ServiceHealth.down) {
      _downSince = null;
      _downTimer?.cancel();
      _downTimer = null;
      return h;
    }
    final since = _downSince ??= railClock();
    final left = railDownAfter - railClock().difference(since);
    if (left <= Duration.zero) return h;
    _downTimer ??= Timer(left, () {
      _downTimer = null;
      if (mounted) setState(() {});
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = ref.watch(deskProvider.select((s) => s.status));
    final settings = ref.watch(deskProvider.select((s) => s.settings));
    final prefs = ref.watch(settingsPrefsProvider);
    final p = ref.read(settingsPrefsProvider.notifier);
    final NodeView node;
    if (prefs.builtin) {
      _url = null;
      // The node the wallet actually reads through: the public fallback until the local node
      // takes over (D-7), whatever the local node's phase.
      node = localNodeView(context.l10n, ref.watch(deskLocalNodeProvider).value, fallbackUrl: status?.node.url);
    } else if (status == null) {
      _url = null;
      node = NodeView(word: l.deskRailChecking, state: EState.off, host: '–');
    } else {
      final url = (prefs.typedNode ?? status.node).url;
      _url = url;
      final health = _settledHealth(status.nodeHealth);
      final torState = torStateOf(settings, status);
      final v = remoteNodeView(
        context.l10n,
        url,
        ref.watch(deskNodeInfoProvider(url)).value,
        health: health,
        downSince: health == ServiceHealth.down ? _downSince : null,
        torOn: torState != TorState.off,
      );
      final tor = torNodeLines(context.l10n, url, torState);
      node = tor.isEmpty ? v : NodeView(word: v.word, state: v.state, host: v.host, marker: v.marker, lines: [...v.lines, ...tor]);
    }
    final items = [nodeRailItem(l, node), ...receivingRailItems(l, status, settings)];
    Widget row(RailItem i) => RailRow(item: i, compact: widget.compact, onTap: () => p.jumpTo(i.jump));
    if (widget.horizontal) {
      return Row(mainAxisSize: MainAxisSize.min, children: [for (final i in items) SizedBox(width: Ctl.md, child: row(i))]);
    }
    final c = context.dc;
    return Column(
      key: const ValueKey('rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(items.first),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6.u, horizontal: 8.u),
          child: Divider(height: 1, thickness: 1, color: c.line),
        ),
        for (final i in items.skip(1)) row(i),
      ],
    );
  }
}

/// One rail row, 40 u tall: bars, the name over one line (compact: the service's icon and the
/// bars). Hover shows the card; a click opens the service's settings.
class RailRow extends StatefulWidget {
  const RailRow({super.key, required this.item, required this.onTap, this.compact = false});

  final RailItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<RailRow> createState() => _RailRowState();
}

class _RailRowState extends State<RailRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final i = widget.item;
    final off = i.second == '–';
    // A host is mono; a status word is in the interface face.
    final mono = i.icon == EIcons.node || i.icon == EIcons.epicbox;
    final secondStyle = off
        ? ts.small.copyWith(color: c.faint, height: 15 / 12)
        : (mono && !off ? ts.mono(size: Fs.xs, color: c.dim) : ts.caption.copyWith(color: c.dim)).copyWith(height: 15 / Fs.xs);
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ESignalBars(i.state),
            SizedBox(width: Sp.x2),
            Text('${i.name} · ${i.word}', style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: Sp.x1),
        for (final l in i.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(l, style: ts.mono(size: Fs.xs, color: c.dim)),
          ),
        if (i.note != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360.u),
            child: Padding(
              padding: EdgeInsets.only(top: Sp.x1),
              child: Text(i.note!, style: ts.small.copyWith(color: c.dim, height: 1.45)),
            ),
          ),
        SizedBox(height: Sp.x2),
        Text(i.open, style: ts.caption.copyWith(color: c.accentText)),
      ],
    );
    final Widget content;
    if (widget.compact) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i.icon, size: 16.u, color: c.dim),
          SizedBox(width: 5.u),
          ESignalBars(i.state),
        ],
      );
    } else {
      content = Row(
        children: [
          ESignalBars(i.state),
          SizedBox(width: 10.u),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.name, maxLines: 1, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600, height: 17 / Fs.sm)),
                Row(
                  children: [
                    Flexible(child: Text(i.second, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: secondStyle)),
                    if (i.marker != null) Text(' · ${i.marker}', maxLines: 1, softWrap: false, style: ts.caption.copyWith(color: c.dim, height: 15 / Fs.xs)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Tooltip(
      richMessage: WidgetSpan(child: card),
      preferBelow: false,
      verticalOffset: 18.u,
      child: Semantics(
        button: true,
        label: '${i.open}: ${i.word}',
        // One line each: '. ' would add full stops in Thai and Chinese.
        hint: [...i.lines, ?i.note].join('\n'),
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            height: 40.u,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 8.u),
            decoration: BoxDecoration(color: _hover ? c.hover : null, borderRadius: BorderRadius.circular(Rad.sm)),
            // The row is 40 u in every state; the OS text scale follows up to the size where
            // the two lines still fit (the interface scale is already in `u`).
            child: MediaQuery.withClampedTextScaling(maxScaleFactor: railMaxTextScale * deskScale, child: content),
          ),
        ),
      ),
    );
  }
}
