/// The network mode (Settings › Advanced) as the desktop screens show it: what blocks network
/// actions now, and the one sentence that says why. Every screen asks here, so they all say the
/// same thing (`network_gate.dart`'s [netBlockFor] decides).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../l10n.dart' show AppLocalizations;
import '../../network_gate.dart';
import '../../net/node_peers.dart';
import 'models.dart';
import 'state.dart';
import 'tor_view.dart';

/// The stored network mode.
NetworkMode deskNetMode(DeskState st) => st.settings.advanced.networkMode;

/// The Tor state the screens read: in Tor only the switch counts as on (the runtime turns it
/// on), so while it is not up yet the state is starting, never off.
TorState deskNetTor(DeskState st) => netTorState(st.settings, st.status);

/// [deskNetTor] from the parts, for the rail and the status card.
TorState netTorState(DeskSettings settings, ServiceStatus? status) {
  final tor = torStateOf(settings, status);
  return settings.advanced.networkMode == NetworkMode.torOnly && tor == TorState.off ? TorState.starting : tor;
}

/// The node in use is on this computer or the local network: Offline still asks it.
bool deskLocalNode(DeskState st) => isLocalAddressUrl(st.status?.node.url);

/// Why network actions can't run now ([NetBlock.none]: they can). [nodeOnly]: the action
/// reaches only the node (Recheck balance, the HTTP listener) or local addresses (a Direct
/// send), which Offline allows with a local node.
NetBlock deskNetBlock(DeskState st, {bool nodeOnly = false}) =>
    netBlockFor(deskNetMode(st), deskNetTor(st), localNode: nodeOnly && deskLocalNode(st));

/// Why the transaction file method can't run now: Offline without a local node only (Tor only
/// waits for Tor too, but a file needs no connection of its own to be made, so it goes on).
NetBlock deskFileBlock(DeskState st) => fileBlockFor(deskNetMode(st), localNode: deskLocalNode(st));

/// [deskNetBlock] for a widget: rebuilds only when the answer changes.
final deskNetBlockProvider = Provider<NetBlock>((ref) => deskNetBlock(ref.watch(deskProvider)));

/// The local node's peer count while Offline (`nodePeerCount`); null otherwise or when it
/// does not say. With 0 a payment waits in the node's pool until it reconnects.
final deskOfflinePeersProvider = FutureProvider.autoDispose<int?>((ref) async {
  final url = ref.watch(deskProvider.select((st) => deskNetMode(st) == NetworkMode.offline && deskLocalNode(st) ? st.status?.node.url : null));
  return url == null ? null : nodePeerCount(url);
});

/// [deskNetBlock] with `nodeOnly` for a widget.
final deskNodeBlockProvider = Provider<NetBlock>((ref) => deskNetBlock(ref.watch(deskProvider), nodeOnly: true));

/// [deskFileBlock] for a widget.
final deskFileBlockProvider = Provider<NetBlock>((ref) => deskFileBlock(ref.watch(deskProvider)));

/// The reason for a disabled network action, one short line; null when nothing blocks.
String? netBlockReason(AppLocalizations l, NetBlock b) => switch (b) {
  NetBlock.none => null,
  NetBlock.offline => l.deskNetOfflineReason,
  NetBlock.waitingForTor => l.deskNetWaitingTorReason,
};
