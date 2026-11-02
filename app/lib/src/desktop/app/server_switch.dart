// SPDX-License-Identifier: Apache-2.0
/// Switch server inside the Shallow status popover (Network or Epicbox): the level has no
/// server settings, so the popover lists the other servers of the user's list, each by its
/// address (never an operator name), with what the status site says of it. Healthy first; one
/// not answering is shown but cannot be picked; one not checked yet can. One click moves.
///
/// Epicbox moves as the server offer does ([DeskRelaySwitch.moveTo]): another server is another
/// address, so the "Now on" notice opens with the new one. A node is saved as the one in use, as
/// a pick on the Node page. NetGate holds as the offer: no Epicbox switch in Node only, Kill
/// switch or with Epicbox off, no node switch in Kill switch, and in Tor only only servers Tor
/// reaches.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkMode;
import '../../levels/relay_switch.dart';
import '../../net/tor_net.dart' show torBuiltInOnion;
import '../../network.dart' show EpicboxRelay;
import '../../network_gate.dart' show netModeOf;
import '../../node_failover.dart' show failoverOverTor;
import '../data/desk_errors.dart' show deskErrorText;
import '../data/desk_relay_switch.dart';
import '../data/net_mode_view.dart';
import '../data/server_lists.dart';
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart' show settingsPrefsProvider;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'status_parts.dart';

/// One server the switch may name.
typedef DeskSwitchServer = ({String value, String name, RelayHealth health, String? operator, ServerIcon? icon});

/// The other Epicbox servers of the list, healthy first; empty while NetGate holds Epicbox.
List<DeskSwitchServer> deskEpicboxSwitchServers(DeskState st, ServerList? list) {
  final mode = deskNetMode(st);
  final hold = relaySwitchHold(mode: mode, tor: deskNetTor(st), epicboxOn: st.settings.payments.epicbox);
  if (hold == RelaySwitchHold.offline || hold == RelaySwitchHold.epicboxOff) return const [];
  final listed = st.epicboxes ?? const <EpicboxServer>[];
  final box = st.status?.epicbox;
  final torOnly = netModeOf(mode) == NetworkMode.torOnly;
  EpicboxServer? listedAs(EpicboxRelay r) => listed.where((s) => s.domain.toLowerCase() == r.host.toLowerCase() && s.port == r.port).firstOrNull;
  return _ordered([
    for (final c in deskRelayCandidates(list, listed))
      if (box == null || c.relay.host.toLowerCase() != box.domain.toLowerCase() || c.relay.port != box.port)
        if (!torOnly || relayOverTor(c.relay, hasOnion: (_, _) => false))
          (
            value: c.relay.label,
            name: c.name,
            health: deskRelayHealth(listed, c.relay),
            operator: listedAs(c.relay)?.listedAs ?? listedAs(c.relay)?.operator,
            icon: listedAs(c.relay)?.icon,
          ),
  ]);
}

/// The other nodes of the list, healthy first; empty in Kill switch.
List<DeskSwitchServer> deskNodeSwitchServers(DeskState st, ServerList? list) {
  final mode = netModeOf(deskNetMode(st));
  if (mode == NetworkMode.killSwitch) return const [];
  final nodes = st.nodes ?? const <NodeServer>[];
  final entries = list?.entries ?? [for (final n in nodes) n.url];
  final current = st.status?.node.url ?? '';
  NodeServer? listedAs(String url) => nodes.where((n) => sameServer(ServerKind.node, n.url, url)).firstOrNull;
  return _ordered([
    for (final url in entries)
      if (current.isEmpty || !sameServer(ServerKind.node, url, current))
        if (mode != NetworkMode.torOnly || failoverOverTor(url, hasOnion: (h, p) => torBuiltInOnion(h, p) != null))
          (
            value: url,
            name: deskNodeAddress(url),
            health: switch (listedAs(url)?.health) {
              ServiceHealth.ok => RelayHealth.healthy,
              ServiceHealth.down => RelayHealth.down,
              _ => RelayHealth.unknown,
            },
            operator: listedAs(url)?.listedAs ?? listedAs(url)?.operator,
            icon: listedAs(url)?.icon,
          ),
  ]);
}

/// Healthy, then not checked, then not answering; the list's order within each.
List<DeskSwitchServer> _ordered(List<DeskSwitchServer> all) => [
  for (final h in [RelayHealth.healthy, RelayHealth.unknown, RelayHealth.down]) ...all.where((s) => s.health == h),
];

/// `host:port` of a node URL, the port only when the URL names one.
String deskNodeAddress(String url) {
  final u = Uri.tryParse(url.contains('://') ? url : 'http://$url');
  if (u == null || u.host.isEmpty) return url;
  return u.hasPort ? '${u.host}:${u.port}' : u.host;
}

/// Switch server and its list, for the Node ([epicbox] false) or Epicbox popover: the
/// popover's footer band, a hairline over it. [close] closes the popover before the move.
class DeskServerSwitch extends ConsumerStatefulWidget {
  const DeskServerSwitch({super.key, required this.epicbox, required this.close, this.trailing});

  final bool epicbox;
  final VoidCallback close;

  /// Sits at the end of the Switch server row (the popover's Close).
  final Widget? trailing;

  @override
  ConsumerState<DeskServerSwitch> createState() => _DeskServerSwitchState();
}

class _DeskServerSwitchState extends ConsumerState<DeskServerSwitch> {
  bool _open = false;

  /// The controller, kept for dispose (ref is gone by then).
  DeskController? _nodes;

  String get _id => widget.epicbox ? 'epicbox' : 'node';

  void _toggle() {
    setState(() => _open = !_open);
    // The node list's health is read while the list is open, as on the Node page.
    if (!widget.epicbox) {
      _nodes ??= ref.read(deskProvider.notifier);
      _nodes!.showNodes(_open);
    }
  }

  @override
  void dispose() {
    if (_open) _nodes?.showNodes(false);
    super.dispose();
  }

  Future<void> _pick(DeskSwitchServer s) async {
    // Read up front: the popover closes before the move.
    final desk = ref.read(deskProvider.notifier);
    final relays = ref.read(deskRelayOfferProvider.notifier);
    final prefsOf = ref.read(settingsPrefsProvider.notifier);
    final prefs = ref.read(settingsPrefsProvider);
    final epicbox = widget.epicbox;
    widget.close();
    try {
      if (epicbox) {
        final relay = EpicboxRelay.parse(s.value);
        if (relay != null) await relays.moveTo(RelayCandidate(relay: relay, name: s.name));
      } else {
        await desk.useNode(s.value);
        if (prefs.builtin) prefsOf.set(prefs.copyWith(builtin: false));
      }
    } on Object catch (e) {
      final at = deskNavigatorKey.currentContext;
      if (at != null && at.mounted) showEToast(at, at.l10n.deskSendEpicboxNotSwitched, text: deskErrorText(e, at.l10n), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    final list = ref.watch(deskServerListProvider(widget.epicbox ? ServerKind.relay : ServerKind.node));
    final servers = widget.epicbox ? deskEpicboxSwitchServers(st, list) : deskNodeSwitchServers(st, list);
    final held = widget.epicbox
        ? switch (relaySwitchHold(mode: deskNetMode(st), tor: deskNetTor(st), epicboxOn: st.settings.payments.epicbox)) {
            RelaySwitchHold.offline || RelaySwitchHold.epicboxOff => true,
            _ => false,
          }
        : netModeOf(deskNetMode(st)) == NetworkMode.killSwitch;
    if (held) return const SizedBox.shrink();

    // The host wins: whole on its own line, the state under it as a dot and its one word
    // (state_language.dart), so neither is cut for the other (#20).
    Widget row(DeskSwitchServer s) {
      final down = s.health == RelayHealth.down;
      final shown = switch (s.health) {
        RelayHealth.healthy => ShownState.healthy,
        RelayHealth.down => ShownState.notAnswering,
        RelayHealth.unknown => ShownState.unchecked,
      };
      final word = shown.word(l);
      return Semantics(
        button: true,
        enabled: !down,
        label: '${s.name}, $word',
        excludeSemantics: true,
        child: EInkWell(
          key: ValueKey('status-switch-$_id-${s.value}'),
          borderRadius: BorderRadius.circular(Rad.sm),
          hoverColor: c.hover,
          onTap: down ? null : () => _pick(s),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 5.u),
            child: Row(
              children: [
                DeskServerTile(host: s.name, operator: s.operator, icon: s.icon, size: 26.u, dimmed: down),
                SizedBox(width: Sp.x2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ETip.value(
                        s.name,
                        mono: true,
                        child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.mono(size: Fs.sm, color: down ? c.faint : c.text)),
                      ),
                      SizedBox(height: 2.u),
                      Row(
                        children: [
                          EStateDot.of(shown, size: 7.u),
                          SizedBox(width: 6.u),
                          Flexible(child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.caption.copyWith(color: c.dim))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(top: Sp.x2),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.lineStrong))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Switch server at the start, the trailing button at the end; on its own run when the
          // two do not fit on one (a large text scale).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton(
                key: ValueKey('status-switch-$_id'),
                label: l.deskLvShellSwitchServer,
                icon: _open ? EIcons.chevronDown : EIcons.swap,
                kind: EBtnKind.ghost,
                size: EBtnSize.sm,
                onPressed: _toggle,
              ),
              ?widget.trailing,
            ],
          ),
          ExpandFade(
            open: _open,
            child: Padding(
              padding: EdgeInsets.only(top: Sp.x1),
              child: servers.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 6.u),
                      child: Text(l.deskLvShellNoOtherServer, style: ts.small.copyWith(color: c.dim)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Said where the server is chosen, plainly: the move gives a new address.
                        if (widget.epicbox)
                          Padding(
                            padding: EdgeInsets.fromLTRB(Sp.x2, 2.u, Sp.x2, 6.u),
                            child: Text(l.slSwitchBody, style: ts.caption.copyWith(color: c.dim)),
                          ),
                        for (final s in servers) row(s),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
