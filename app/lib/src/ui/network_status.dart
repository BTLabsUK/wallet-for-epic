// SPDX-License-Identifier: Apache-2.0
/// The network status card (Settings › Privacy & network; Home shows the compact status icons
/// of `home_status.dart` instead): one row each for the node, Epicbox and Tor. A row's tap
/// opens the server picker for it, or Settings › Privacy for Tor. A row whose connection goes
/// through Tor, or waits for it, says so on a line of its own under the state word.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart' show devNetworksOf;

import '../l10n.dart';
import '../models.dart' show Chain;
import '../network.dart';
import '../advanced.dart' show NetworkMode, NetworkModeRestricted;
import '../settings.dart' show networkModeProvider;
import '../node_failover_phone.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../tor_phone.dart';
import '../net/tor_net.dart' show isLoopbackUrl;
import '../tor_routes.dart';
import 'server_picker.dart';
import 'info_hint.dart';
import 'network_mode_text.dart' show statusOffByModeWord;
import 'settings_screen.dart';
import 'status.dart';
import 'status_icons.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';

/// The keys of the card's rows, for tests: the node and epicbox rows take the keys the
/// header's status icons had.
const Key netStatusNodeKey = nodeStatusKey;
const Key netStatusEpicboxKey = epicboxStatusKey;
const Key netStatusTorKey = ValueKey('net-status-tor');

/// Whether the card shows a Tor row: always, where the app has Tor.
bool torRowShown(PhoneTorState s) => s.phase != PhoneTorPhase.unavailable;

/// Tor's face on the card, in the switch's four words: Off (faint), Starting…, On (ok), Not
/// connected (risk).
NetFace torNetFace(BuildContext context, PhoneTorState s) {
  final l = context.l10n;
  final t = context.tokens;
  final state = phoneTorState(s);
  return (
    level: switch (state) {
      TorState.off => SignalLevel.none,
      TorState.starting => SignalLevel.two,
      TorState.on => SignalLevel.three,
      TorState.failed => SignalLevel.one,
    },
    color: torWordColor(t, state),
    word: torWord(l, state),
  );
}

/// The node's lag behind the network's tip as the status site sees it, for a node that
/// answers and is [NodeState.online]; null when either height is unknown. The status card and
/// Home's status icons both read "Behind N" from it.
int? nodeBehind(WidgetRef ref, NodeStatus node, NetworkPreset? preset) {
  final height = node.tip?.height;
  if (node.state != NodeState.online ||
      height == null ||
      preset == null ||
      preset.statusChain == null) {
    return null;
  }
  final tip = ref.watch(networkStatusProvider(preset)).value?.tipHeight;
  if (tip == null) return null;
  final lag = tip - height.toInt();
  return lag < 0 ? 0 : lag;
}

/// How the node's connection goes under the Tor switch: a node on this computer stays direct
/// ([torSkipsLocalNode]); any other follows [torWay].
TorWay nodeTorWay(String? nodeUrl, TorState state) =>
    torSkipsLocalNode && nodeUrl != null && isLoopbackUrl(Uri.parse(nodeUrl))
    ? TorWay.clearnet
    : torWay(TorRoute.node, state);

/// The node, Epicbox and Tor rows in a hairline card. With [showTor] false the Tor row is
/// left out: right above the Tor switch (Settings › Privacy & network) it would repeat it.
class NetworkStatusCard extends ConsumerWidget {
  const NetworkStatusCard({super.key, this.showTor = true});

  final bool showTor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final status = watchWalletStatus(ref);
    final config = ref.watch(walletConfigProvider);
    final choice = ref.watch(networkChoiceProvider).value;
    final tor = ref.watch(phoneTorProvider);
    final torState = phoneTorState(tor);
    TorWay way(TorRoute route) => torWay(route, torState);
    final preset = choice?.preset;
    final nodeUrl = config?.nodeUrl ?? choice?.nodeUrl;
    final chain = config?.chain ?? preset?.chain;
    final nodeHost = nodeUrl == null ? '' : serverHost(nodeUrl);
    // Node failover moved the wallet for this session: the chosen node is named under it.
    final failover = ref.watch(nodeFailoverProvider);
    final relay = config != null
        ? EpicboxRelay(
            host: config.epicboxDomain,
            port: config.epicboxPort,
          ).label
        : choice?.relay.label ?? '';
    // A service the mode turns off is "Off (Node only)": neutral, never red or blue. Node only
    // keeps the node; Kill switch turns both off.
    final mode = ref.watch(networkModeProvider);
    final pausedFace = (level: SignalLevel.none, color: t.dim, word: statusOffByModeWord(l, mode));
    final node = mode == NetworkMode.killSwitch
        ? pausedFace
        : nodeNetFace(
            context,
            status.node,
            behind: nodeBehind(ref, status.node, preset),
          );
    final epicbox = mode.restricted ? pausedFace : epicboxNetFace(context, status.epicbox);
    final nodeWords = nodeStatusWords(context, status.node, config);
    final epicboxWords = epicboxStatusWords(context, status.epicbox, config);
    final rows = <Widget>[
      _StatusRow(
        key: netStatusNodeKey,
        glyph: EpicGlyphs.node,
        title: l.netStatusNode,
        host: chain != null &&
                chain != Chain.mainnet &&
                nodeHost.isNotEmpty &&
                devNetworksOf(context)
            ? '${chainName(l, chain)} · $nodeHost'
            : nodeHost,
        note: failover == null
            ? null
            : l.nodeFailoverInsteadOf(serverHost(failover.chosen)),
        face: node,
        spoken: nodeWords.label,
        detail: nodeWords.detail,
        pulse: status.node.state == NodeState.syncing,
        torWay: nodeTorWay(nodeUrl, torState),
        onTap: () => showNodePicker(context),
      ),
      _StatusRow(
        key: netStatusEpicboxKey,
        glyph: EpicGlyphs.epicbox,
        title: l.netStatusEpicbox,
        host: relay,
        face: epicbox,
        spoken: epicboxWords?.label,
        detail: epicboxWords?.detail,
        torWay: way(TorRoute.epicbox),
        onTap: () => showEpicboxPicker(context),
      ),
      if (showTor && torRowShown(tor))
        _StatusRow(
          key: netStatusTorKey,
          glyph: torIcon,
          title: l.torNetworkLabel,
          hint: l.torNetworkHint,
          detail: l.torNetworkHint,
          host: '',
          face: torNetFace(context, tor),
          onTap: () => openPrivacySettings(context),
        ),
    ];
    return Semantics(
      container: true,
      label: l.netStatusTitle,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One row: bars, the service, its host in mono, the state word and a chevron; one 56 dp
/// target, read as "Node online, node.example.org, Synced" ([spoken] first, as the header's
/// icons said it, else the title) with the icon's tooltip [detail] as the hint.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.title,
    required this.host,
    required this.face,
    required this.onTap,
    required this.glyph,
    this.spoken,
    this.detail,
    this.pulse = false,
    this.torWay = TorWay.clearnet,
    this.hint,
    this.note,
  });

  /// A line under the host: the node chosen while failover uses another one.
  final String? note;

  final String? spoken;
  final String? detail;

  /// The explanation behind an info icon after the title (the Tor row).
  final String? hint;

  final String title;
  final String host;
  final NetFace face;
  final bool pulse;

  /// The service's glyph, drawn with the state dot (one icon per meaning).
  final IconData glyph;

  /// How the connection goes under the Tor switch: over Tor, or waiting for it, is a line of
  /// its own under the state word ([torWayWords]) and read out after it; nothing otherwise.
  final TorWay torWay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final tor = torWayWords(l, t, torWay);
    // While Tor starts (or failed) the route is not up yet: one state on the row, "Waiting
    // for Tor", never "Synced" over it (UP-014); "Over Tor" is a line under the state.
    final torOnly = tor != null && torWay != TorWay.overTor;
    final dot = torOnly ? (torWay == TorWay.wait ? StatusDot.busy : StatusDot.bad) : netFaceDot(t, face);
    return Semantics(
      button: true,
      liveRegion: true,
      label: [
        spoken ?? title,
        if (host.isNotEmpty) host,
        ?note,
        if (!torOnly) face.word,
        if (torWay == TorWay.overTor) l.netStatusOverTor else ?tor?.word,
      ].join(', '),
      hint: [?tor?.detail, detail ?? l.netStatusOpenHint].join('\n'),
      // With an info icon the row's own words are excluded one by one and the icon is an
      // explicit child node, so it stays a button of its own (a screen reader reaches it; a
      // browser's semantics tap opens it).
      excludeSemantics: hint == null,
      explicitChildNodes: hint != null,
      // The row's action lives on this node; the InkWell adds none of its own.
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: [
                  Pulse(
                    active: pulse,
                    child: StatusGlyph(
                      icon: glyph,
                      enabled: face.level != SignalLevel.none,
                      dot: dot,
                      ring: t.surface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // The service over its host, as the desktop's sidebar rows: a long host
                  // never pushes the state word off the row.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hint == null)
                          Text(title, style: theme.textTheme.bodyMedium)
                        else
                          DefaultTextStyle.merge(
                            style: theme.textTheme.bodyMedium,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: ExcludeSemantics(child: Text(title)),
                                ),
                                const SizedBox(width: 4),
                                // 48 dp: the icon is a target of its own on this row.
                                InfoHint(
                                  hint!,
                                  size: 48,
                                  title: title,
                                  icon: torIcon,
                                ),
                              ],
                            ),
                          ),
                        if (host.isNotEmpty)
                          ExcludeSemantics(
                            child: Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: t.monoFamily,
                                fontSize: 12,
                                height: 1.3,
                                color: t.dim,
                              ),
                            ),
                          ),
                        if (note != null)
                          ExcludeSemantics(
                            child: Text(
                              note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // No flex here: the state word keeps its size and the service column takes
                  // the rest, so the word sits at the trailing edge. The Tor line sits under it
                  // with its icon first, so a long word in a large font never cuts the mark off.
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (torOnly)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(torIcon, size: 14, color: tor.color),
                              const SizedBox(width: 4),
                              Text(
                                tor.word,
                                maxLines: 1,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tor.color,
                                ),
                              ),
                            ],
                          )
                        else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            face.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: face.color,
                            ),
                          ),
                        ),
                        // Short in every language: it keeps its width.
                        if (tor != null && !torOnly)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(torIcon, size: 14, color: tor.color),
                              const SizedBox(width: 4),
                              Text(
                                tor.word,
                                maxLines: 1,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tor.color,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(Icons.chevron_right, size: 20, color: t.dim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
