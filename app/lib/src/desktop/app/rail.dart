// SPDX-License-Identifier: Apache-2.0
/// The status rows of the sidebar: Node, a divider, then Epicbox, HTTP and Tor,
/// each with signal bars, a name and one short line; the details in a hover card; a click
/// opens that service's settings. Every row is 40 u tall in every state, so the rail never
/// changes height.
library;

import '../../advanced.dart' show NetworkMode, NetworkModeRestricted;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../data/desk_node.dart';
import '../data/net_mode_view.dart';
import 'desk_failover.dart';
import '../data/node_view.dart';
import '../data/tor_view.dart' as tor_view;
import '../data/tor_view.dart' hide isLocalNodeUrl;
import '../data/node_switch.dart' show deskNodeSwitchProvider, nodeSwitchView;
import '../../ui/network_mode_text.dart' show statusOffByModeWord;
import '../screens/settings/prefs.dart';
import '../screens/settings/settings_http.dart' show httpRun;
import '../widgets/http_reach.dart' show deskLastHttpReachProvider;
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
    this.byMode = false,
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

  /// The mode turned this service off: a click opens the Network section ([opens]).
  final bool byMode;

  /// The row of a service the network mode turns off: neutral, "Off (Node only)", nothing is
  /// being checked; a click opens the Network section, not the service's switch.
  RailItem offByMode(AppLocalizations l, NetworkMode mode) => RailItem(
    icon: icon,
    name: name,
    word: statusOffByModeWord(l, mode),
    state: EState.off,
    second: statusOffByModeWord(l, mode),
    lines: [l.statusOffByModeDetail],
    open: l.deskRailOpenNetwork,
    jump: jump,
    byMode: true,
  );

  /// Where a click goes: the service's own switch, or the Network section when the mode turned
  /// the service off (its own switch would not help).
  SettingsJump get opens => byMode ? SettingsJump.network : jump;
}

/// The Epicbox, HTTP and Tor rows of a status (null: nothing known yet).
List<RailItem> receivingRailItems(AppLocalizations l, ServiceStatus? st, DeskSettings settings, {bool reachClosed = false}) {
  final eb = st?.epicboxHealth ?? ServiceHealth.checking;
  final ebHost = st?.epicbox.domain;
  final tor = netTorState(settings, st);
  final ebWay = torWay(TorRoute.epicbox, tor);
  final ebWaits = eb != ServiceHealth.off && (ebWay == TorWay.wait || ebWay == TorWay.blocked);
  final blocked = st != null && st.epicboxBlocked && eb == ServiceHealth.down && !ebWaits;
  final ebWord = switch (eb) {
    _ when ebWaits => l.deskRailWaitingTor,
    _ when blocked => l.deskEpicboxBlockedWord,
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
          ? (ebWay == TorWay.blocked ? EState.risk : EState.active)
          : stateOf(eb),
      // Tor only says what it waits for on the row itself; the other modes keep the host.
      second: ebWaits && settings.advanced.networkMode == NetworkMode.torOnly
          ? ebWord
          : eb == ServiceHealth.off || ebHost == null
          ? '–'
          : railHost('Epicbox', ebHost), // l10n-ok: product name
      lines: [
        if (eb != ServiceHealth.off && ebHost != null) ebHost,
        if (eb != ServiceHealth.off && ebWay == TorWay.overTor) l.deskRailOverTor,
        if (ebWaits) l.deskRailWaitsForTor,
        if (blocked) l.deskEpicboxBlockedShort(ebHost ?? '') else if (eb == ServiceHealth.down && !ebWaits) l.deskRailPaymentsWait,
      ],
      open: l.deskRailOpenEpicbox,
      jump: SettingsJump.epicbox,
    ),
  ];
  // Settings › Transactions › Direct; a listener that is on, starting or failed keeps its row.
  // Always listed: off, its row and the bar's glyph say so and open the switch.
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
        // Listening, but the internet does not reach the port: not a green On.
        HttpRun.on => reachClosed ? EState.warn : EState.ok,
        HttpRun.busy => EState.active,
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
                TorState.starting => EState.active,
                TorState.on => EState.ok,
                TorState.failed => EState.risk,
              },
        second: tor == TorState.starting ? l.deskRailStartingDots : word,
        marker: tor == TorState.starting ? percentText(l, st?.torProgress ?? 0) : null,
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
  // Node only keeps the node and the Tor that carries it; Epicbox and Link are off. Kill
  // switch turns every service off.
  final mode = settings.advanced.networkMode;
  return mode.restricted ? [for (final i in items) mode == NetworkMode.nodeOnly && i.icon == EIcons.tor ? i : i.offByMode(l, mode)] : items;
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

/// How often the rail asks about a remote node again: the network's tip (the "behind" check),
/// the version and the latency. The node's own height and whether it answers come with every
/// wallet status; the info is also asked again when the node changes or answers again.
const Duration railNodeRefresh = Duration(minutes: 5);

/// The rail: Node, Epicbox, HTTP, Tor, a divider between every two. [horizontal] lays the
/// compact rows side by side (the phone's top bar).
class ServiceRows extends ConsumerStatefulWidget {
  const ServiceRows({super.key, this.compact = false, this.horizontal = false, this.builder});

  final bool compact;
  final bool horizontal;

  /// Lays the rows out another way (the title bar's status); the rows' content stays this one.
  final Widget Function(BuildContext context, List<RailItem> items)? builder;

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

  /// The node is on this computer: never over Tor, so Tor only does not hold it.
  bool _localNode(SettingsPrefs prefs, ServiceStatus? status) =>
      status != null && tor_view.isLocalNodeUrl((prefs.typedNode ?? status.node).url);

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
    // The node answers the wallet again: what it says of itself is asked again too.
    ref.listen(deskProvider.select((s) => s.status?.nodeHealth), (was, now) {
      final u = _url;
      if (u != null && was != null && was != ServiceHealth.ok && now == ServiceHealth.ok) ref.invalidate(deskNodeInfoProvider(u));
    });
    final status = ref.watch(deskProvider.select((s) => s.status));
    final settings = ref.watch(deskProvider.select((s) => s.settings));
    final prefs = ref.watch(settingsPrefsProvider);
    final p = ref.read(settingsPrefsProvider.notifier);
    final NodeView node;
    if (prefs.builtin) {
      _url = null;
      // The node the wallet actually reads through: the public fallback until the local node
      // takes over, whatever the local node's phase.
      node = localNodeView(context.l10n, ref.watch(deskLocalNodeProvider).value, fallbackUrl: status?.node.url);
    } else if (status == null) {
      _url = null;
      node = NodeView(word: l.deskRailChecking, state: EState.off, host: '–');
    } else {
      final url = (prefs.typedNode ?? status.node).url;
      _url = url;
      final health = _settledHealth(status.nodeHealth);
      final torState = netTorState(settings, status);
      final info = ref.watch(deskNodeInfoProvider(url)).value;
      final v = remoteNodeView(
        context.l10n,
        url,
        info?.withNodeHeight(status.nodeHeight),
        health: health,
        downSince: health == ServiceHealth.down ? _downSince : null,
        torOn: torState != TorState.off,
      );
      final tor = torNodeLines(context.l10n, url, torState);
      // Node failover: the chosen node, under the one standing in for it this session.
      final failover = ref.watch(deskFailoverProvider);
      final instead = failover == null ? const <String>[] : [l.deskNodeFailoverInsteadOf(nodeHost(failover.chosen))];
      node = tor.isEmpty && instead.isEmpty
          ? v
          : NodeView(word: v.word, state: v.state, host: v.host, marker: v.marker, lines: [...instead, ...v.lines, ...tor]);
    }
    // A node switch the user started says what happens at once, before the wallet has moved.
    final moving = ref.watch(deskNodeSwitchProvider);
    var nodeItem = nodeRailItem(l, moving == null ? node : nodeSwitchView(l, moving));
    final netMode = settings.advanced.networkMode;
    if (netMode == NetworkMode.killSwitch) {
      nodeItem = nodeItem.offByMode(l, netMode);
    } else if (netMode == NetworkMode.torOnly && netTorState(settings, status) != TorState.on && !(prefs.builtin || _localNode(prefs, status))) {
      // Tor only, Tor not up yet: the node waits for it and goes nowhere else.
      nodeItem = RailItem(
        icon: nodeItem.icon,
        name: nodeItem.name,
        word: l.deskRailWaitingTor,
        state: EState.active,
        second: l.deskRailWaitingTor,
        lines: [l.deskRailWaitsForTor],
        open: nodeItem.open,
        jump: nodeItem.jump,
      );
    }
    final reach = settings.publicMode && httpRun(status) == HttpRun.on ? ref.watch(deskLastHttpReachProvider) : null;
    final items = [nodeItem, ...receivingRailItems(l, status, settings, reachClosed: reach?.reachable == false)];
    if (widget.builder != null) return widget.builder!(context, items);
    Widget row(RailItem i) => RailRow(item: i, compact: widget.compact, onTap: () => p.jumpTo(i.opens));
    if (widget.horizontal) {
      return Row(mainAxisSize: MainAxisSize.min, children: [for (final i in items) SizedBox(width: Ctl.md, child: row(i))]);
    }
    final c = context.dc;
    return Column(
      key: const ValueKey('rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var n = 0; n < items.length; n++) ...[
          // The same hairline and the same space between every two rows.
          if (n > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.u, horizontal: 8.u),
              child: Divider(height: 1, thickness: 1, color: c.line),
            ),
          row(items[n]),
        ],
      ],
    );
  }
}

/// One rail row, 40 u tall: the service's icon, the name over one line, the bars at the end
/// (compact: the icon and the bars). Hover shows the card; a click opens the service's settings.
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
            EStateDot(i.state),
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
        SizedBox(height: Sp.x2),
        Text(i.open, style: ts.caption.copyWith(color: c.accentText)),
      ],
    );
    final Widget content;
    if (widget.compact) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EStatusGlyph(icon: i.icon, state: i.state, label: '${i.name}: ${i.word}', size: 16.u),
        ],
      );
    } else {
      content = Row(
        children: [
          // The glyph with its state dot, as the title bar; bars only where latency shows.
          EStatusGlyph(icon: i.icon, state: i.state, label: '${i.name}: ${i.word}', size: 16.u),
          SizedBox(width: 6.u),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.name, maxLines: 1, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600, height: 17 / Fs.sm)),
                Row(
                  children: [
                    Flexible(child: Text(i.second, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: secondStyle)),
                    if (i.marker != null) Flexible(child: Text(' · ${i.marker}', maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.caption.copyWith(color: c.dim, height: 15 / Fs.xs))),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ETip.card(
      card,
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
