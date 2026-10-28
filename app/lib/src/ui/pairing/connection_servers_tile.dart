// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Experimental › Connection servers (phone): the Epicbox servers where two
/// wallets find each other when they connect. A row with the state line under its name and the
/// ⓘ sheet; a tap opens the Epicbox list as a set to tick, up to three
/// ([showRelaySelectionSheet]). Shown only while Pairing is on and on a network that has meeting
/// servers; Epicbox off and Offline keep it, paused, because the choice matters once they are
/// back.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connection_servers.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../providers.dart';
import '../../relay_directory.dart';
import '../../server_list.dart';
import '../info_hint.dart';
import '../server_list_sheet.dart';
import '../status_icons.dart';
import '../theme/tokens.dart';

/// The key of the row, for tests and the tour.
const Key connectionServersTileKey = ValueKey('adv-connection-servers');

/// The key of the state line under the row's name, for tests.
const Key connectionServersLineKey = ValueKey('adv-connection-servers-line');

class ConnectionServersTile extends ConsumerWidget {
  const ConnectionServersTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(networkChoiceProvider).value;
    if (choice == null || !ref.watch(pairingOnProvider)) return const SizedBox.shrink();
    final chain = choice.preset.chain;
    if (!connectionServersShown(chain)) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final defaults = defaultConnectionServers(chain);
    final chosen = connectionServersIn(chain, ref.watch(pairingRelaysProvider).value);
    final net = ref.watch(pairNetProvider);
    final listed = ref.watch(relayStatusProvider(choice.preset)).value ?? const <RelayStatus>[];
    final line = connectionServersLine(
      chosen: chosen,
      defaults: defaults,
      health: {
        for (final r in listed) serverKeyOf(ServerKind.relay, r.relay.label): r.healthy ? NodeHealthState.healthy : NodeHealthState.down,
      },
      epicboxOff: net == PairNet.epicboxOff,
      offline: net == PairNet.offline,
    );
    final color = line.risk
        ? t.risk
        : line.warn
        ? t.warn
        : line.dim
        ? t.dim
        : t.info;
    final text = line.text(l);
    return ListTile(
      key: connectionServersTileKey,
      leading: Icon(EpicGlyphs.epicbox),
      title: TitleWithHint(l.connServers, hint: connectionServersInfo(l), icon: EpicGlyphs.epicbox),
      subtitle: Semantics(
        liveRegion: true,
        child: Text(text, key: connectionServersLineKey, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showRelaySelectionSheet(
        context,
        selection: RelaySelection(
          limit: connectionServersLimit,
          chosen: chosen,
          defaults: defaults,
          onChanged: (set) => ref.read(pairingRelaysProvider.notifier).set(set),
          title: l.connServers,
          note: l.connServersNote,
        ),
      ),
    );
  }
}
