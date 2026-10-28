// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Experimental › Connection servers (desktop): the Epicbox servers where two
/// wallets find each other when they connect. The row says in one line what it is for, shows the
/// chosen servers in the field (every host, wrapped, never cut), opens the Epicbox list as a set
/// to tick, up to three ([ServerListPanel.selection]), and keeps a state line under it. The
/// ⓘ card has the rest. Shown only while Pairing is on and on a network that has meeting
/// servers; Epicbox off and Offline keep it, paused.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../connection_servers.dart';
import '../../../network.dart' show EpicboxRelay;
import '../../../relay_directory.dart' show NodeHealthState;
import '../../../net/probe_not_run.dart' show ProbeNotRun;
import '../../../send_preflight.dart' show relayProbeProvider;
import '../../../tor_build.dart' show torBuilt;
import '../../data/desk_node.dart' show deskNodeProvider;
import '../../data/pairing_state.dart';
import '../../data/server_lists.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../widgets/server_list_panel.dart';

/// The key of the row, for tests and the tour.
const Key connectionServersRowKey = ValueKey('adv-connection-servers');

/// The key of the state line under the field, for tests.
const Key connectionServersLineKey = ValueKey('adv-connection-servers-line');

class ConnectionServersRow extends ConsumerWidget {
  const ConnectionServersRow({super.key, this.openInitially = false});

  /// The tour opens the list.
  final bool openInitially;

  /// Add's test: a WebSocket handshake with the server, as the Epicbox page does. Null when it
  /// answered.
  static Future<String?> _test(WidgetRef ref, BuildContext context, String value) async {
    final l = context.l10n;
    final relay = EpicboxRelay.parse(value);
    if (relay == null) return l.slNotAnAddress;
    try {
      return await ref.read(relayProbeProvider).reachable(relay) ? null : l.slRelayNoAnswer;
    } on ProbeNotRun {
      return torBuilt ? l.deskSlTorWait : l.slRelayNoAnswer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chain = ref.watch(deskNodeProvider).chain;
    if (!ref.watch(deskPairingOnProvider) || !connectionServersShown(chain)) return const SizedBox.shrink();
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final boxes = st.epicboxes ?? const [];
    final defaults = defaultConnectionServers(chain);
    final chosen = connectionServersIn(chain, ref.watch(deskPairingRelaysProvider));
    final net = ref.watch(deskPairNetProvider);
    final line = connectionServersLine(
      chosen: chosen,
      defaults: defaults,
      health: {
        for (final b in boxes)
          serverKeyOf(ServerKind.relay, relayLabel(b)): switch (b.health) {
            ServiceHealth.down => NodeHealthState.down,
            ServiceHealth.ok || ServiceHealth.slow => NodeHealthState.healthy,
            ServiceHealth.checking || ServiceHealth.off => null,
          },
      },
      epicboxOff: net == DeskPairNet.epicboxOff,
      offline: net == DeskPairNet.offline,
    );
    final c = context.dc;
    final tone = line.risk
        ? ETone.risk
        : line.warn
        ? ETone.warn
        : line.dim
        ? ETone.ok
        : ETone.info;
    final color = line.risk
        ? c.risk
        : line.warn
        ? c.warn
        : line.dim
        ? c.dim
        : c.info;
    // The chosen servers the monitor does not list still get a row.
    final listed = {for (final b in boxes) serverKeyOf(ServerKind.relay, relayLabel(b))};
    final extra = [
      for (final v in chosen)
        if (!listed.contains(serverKeyOf(ServerKind.relay, v))) v,
    ];
    return ESetRow(
      key: connectionServersRowKey,
      title: l.connServers,
      hint: connectionServersInfo(l),
      hintTitle: l.connServers,
      hintIcon: EIcons.epicbox,
      text: l.connServersHint,
      stacked: true,
      control: ServerListPanel(
        kind: ServerKind.relay,
        label: l.connServers,
        value: '',
        fieldText: chosen.join(', '),
        tone: tone,
        servers: [
          ...relayPanelRows(boxes),
          for (final v in extra) PanelServer.bare(ServerKind.relay, v),
        ],
        // The defaults are always listed, as is whatever is chosen.
        source: DeskServerSource(
          public: [
            for (final b in boxes) relayLabel(b),
            for (final d in defaults)
              if (!listed.contains(serverKeyOf(ServerKind.relay, d))) d,
          ],
          keep: chosen,
        ),
        openInitially: openInitially,
        onChoose: (_) async {},
        onTest: (v) => _test(ref, context, v),
        selection: RelaySelection(
          limit: connectionServersLimit,
          chosen: chosen,
          defaults: defaults,
          onChanged: (set) => ref.read(deskPairingRelaysProvider.notifier).set(set),
          title: l.connServers,
          note: l.connServersNote,
        ),
      ),
      below: Semantics(
        liveRegion: true,
        child: Text(line.text(l), key: connectionServersLineKey, style: context.ts.small.copyWith(color: color)),
      ),
    );
  }
}
