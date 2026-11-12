// SPDX-License-Identifier: Apache-2.0
/// The network status card (Settings › Privacy & network; Home shows the compact status icons
/// of `home_status.dart` instead): one row each for the node, Epicbox and Tor. A row's tap
/// opens the server picker for it, or Settings › Privacy for Tor. A row whose connection goes
/// through Tor, or waits for it, says so on a line of its own under the state word.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dev_networks.dart' show devNetworksOf;

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
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_tokens.dart';
import 'network_mode_text.dart' show statusOffByModeWord;
import 'settings_screen.dart';
import 'status.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import '../text_join.dart';

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
  const NetworkStatusCard({super.key, this.showTor = true, this.extraRows = const []});

  final bool showTor;

  /// Rows that belong to the servers but are not a status (the node failover switch).
  final List<Widget> extraRows;

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
        key: netStatusEpicboxKey,
        title: l.netStatusEpicbox,
        host: relay,
        face: epicbox,
        spoken: epicboxWords?.label,
        detail: epicboxWords?.detail,
        torWay: way(TorRoute.epicbox),
        onTap: () => showEpicboxPicker(context),
      ),
      _StatusRow(
        key: netStatusNodeKey,
        title: l.netStatusNode,
        host: chain != null &&
                chain != Chain.mainnet &&
                nodeHost.isNotEmpty &&
                devNetworksOf(context)
            ? metaLine([chainName(l, chain), nodeHost])
            : nodeHost,
        note: failover == null
            ? null
            : l.nodeFailoverInsteadOf(serverHost(failover.chosen)),
        face: node,
        spoken: nodeWords.label,
        detail: nodeWords.detail,
        torWay: nodeTorWay(nodeUrl, torState),
        onTap: () => showNodePicker(context),
      ),
      if (showTor && torRowShown(tor))
        _StatusRow(
          key: netStatusTorKey,
            title: l.torNetworkLabel,
          detail: l.torNetworkHint,
          host: '',
          face: torNetFace(context, tor),
          onTap: () => openPrivacySettings(context),
        ),
      ...extraRows,
    ];
    return Semantics(
      container: true,
      label: l.netStatusTitle,
      child: KitGroup(dividerInset: Kit.dividerInsetPlain, children: rows),
    );
  }
}

/// One row: the service, its host in mono under it, the state word and a chevron; read as
/// "Node online, node.example.org, Synced" ([spoken] first, as the header's icons said it, else
/// the title) with the icon's tooltip [detail] as the hint.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.title,
    required this.host,
    required this.face,
    required this.onTap,
    this.spoken,
    this.detail,
    this.torWay = TorWay.clearnet,
    this.note,
  });

  /// A line under the host: the node chosen while failover uses another one.
  final String? note;

  final String? spoken;
  final String? detail;
  final String title;
  final String host;
  final NetFace face;

  /// How the connection goes under the Tor switch: over Tor, or waiting for it, is a line of
  /// its own under the host ([torWayWords]) and read out after it; nothing otherwise.
  final TorWay torWay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final tor = torWayWords(l, t, torWay);
    // While Tor starts (or failed) the route is not up yet: one state on the row, "Waiting
    // for Tor", never "Synced" over it (UP-014); "Over Tor" is a line under the host.
    final torOnly = tor != null && torWay != TorWay.overTor;
    final word = torOnly ? tor.word : face.word;
    final color = torOnly ? tor.color : face.color;
    final lines = <Widget>[
      if (host.isNotEmpty)
        Text(host, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(fontFamily: t.monoFamily, color: t.dim, fontSize: 12.5)),
      if (note != null) Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.dim)),
      if (tor != null && !torOnly)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(torIcon, size: 14, color: tor.color),
            const SizedBox(width: 4),
            Flexible(child: Text(tor.word, style: KitType.rowSub.copyWith(color: tor.color))),
          ],
        ),
    ];
    // The row reads as one button: "Node online, node.example.org, Synced", the state's
    // explanation as its hint.
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
      excludeSemantics: true,
      onTap: onTap,
      child: KitRow(
        title: title,
        subtitleWidget: lines.isEmpty
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: lines),
        value: word,
        valueColor: color,
        chevron: true,
        size: KitRowSize.list,
        onTap: onTap,
      ),
    );
  }
}
