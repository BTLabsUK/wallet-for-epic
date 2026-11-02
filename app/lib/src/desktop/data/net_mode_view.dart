// SPDX-License-Identifier: Apache-2.0
/// The network mode (Settings › Advanced) as the desktop screens show it: what blocks network
/// actions now, and the one sentence that says why. Every screen asks here, so they all say the
/// same thing (`network_gate.dart`'s [netBlockFor] decides).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../l10n.dart' show AppLocalizations;
import '../../network_gate.dart';
import '../../payment_prefs.dart' show MethodKind;
import '../../ui/method_icons.dart' show MethodIcons;
import '../../net/node_peers.dart';
import 'models.dart';
import 'state.dart';
import 'tor_view.dart';
import '../../tor_build.dart' show torBuilt;

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

/// The wallet's tor process as onion sends and the Tor address see it, whoever started it:
/// the Tor switch (or Tor only), or Link · Tor for payments alone ([torPayWantedIn]).
TorState deskTorProcess(DeskState st) => torProcessState(st.settings, st.status);

/// [deskTorProcess] from the parts.
TorState torProcessState(DeskSettings settings, ServiceStatus? status) {
  final net = netTorState(settings, status);
  if (net != TorState.off || !torPayWantedIn(settings)) return net;
  if (status == null) return TorState.starting;
  return switch (status.tor) {
    ServiceHealth.down => TorState.failed,
    ServiceHealth.off => TorState.starting,
    ServiceHealth.checking when !status.torCanSend => TorState.starting,
    _ => TorState.on,
  };
}

/// Link · Tor asks for tor for payments: on, in a build with Tor, outside Node only and Kill
/// switch (the adapters start it from the same rule).
bool torPayWantedIn(DeskSettings settings) =>
    torBuilt && settings.payments.linkTor && !settings.advanced.networkMode.restricted;

/// The node in use is on this computer or the local network: Node only says nothing about a
/// public node then.
bool deskLocalNode(DeskState st) => isLocalAddressUrl(st.status?.node.url);

/// Why network actions can't run now ([NetBlock.none]: they can). [nodeOnly]: the action
/// reaches only the node in use (Recheck balance, posting), which Node only allows. [epicbox]: the action goes over Epicbox,
/// which the Epicbox switch (Settings › Transactions) holds when off. [offered]: false when
/// the action's method is off there ([NetBlock.methodOff]).
NetBlock deskNetBlock(DeskState st, {bool nodeOnly = false, bool epicbox = false, bool offered = true}) => netBlockFor(
  deskNetMode(st),
  deskNetTor(st),
  node: nodeOnly,
  epicbox: !epicbox || st.settings.payments.epicbox,
  offered: offered,
);

/// The transaction file method uses the node in use while Node only, and the node is not
/// local: the screen says so (`network_gate.dart`'s [nodeOnlyUsesNode]); it is never held.
bool deskOfflineUsesNode(DeskState st) => nodeOnlyUsesNode(deskNetMode(st), localNode: deskLocalNode(st));

/// Sends that wait for their recipient over Epicbox or Link: Node only and Kill switch stop the
/// listeners they wait on, so the switch asks first.
int deskPendingNetworkSends(DeskState st) => (st.txs ?? const <Tx>[])
    .where((t) => !t.incoming && t.state == TxState.waitingRecipient && t.method != TxMethod.file)
    .length;

/// The balance and history show as last known: Kill switch asks no node.
bool deskLastKnown(DeskState st) => deskNetMode(st) == NetworkMode.killSwitch;

/// [deskLastKnown] for a widget.
final deskLastKnownProvider = Provider<bool>((ref) => ref.watch(deskProvider.select(deskLastKnown)));

/// [deskNetBlock] for a widget: rebuilds only when the answer changes.
final deskNetBlockProvider = Provider<NetBlock>((ref) => deskNetBlock(ref.watch(deskProvider)));

/// The local node's peer count while Node only (`nodePeerCount`); null otherwise or when it
/// does not say. With 0 a payment waits in the node's pool until it reconnects.
final deskOfflinePeersProvider = FutureProvider.autoDispose<int?>((ref) async {
  final url = ref.watch(deskProvider.select((st) => deskNetMode(st) == NetworkMode.nodeOnly && deskLocalNode(st) ? st.status?.node.url : null));
  return url == null ? null : nodePeerCount(url);
});

/// [deskNetBlock] with `nodeOnly` for a widget.
final deskNodeBlockProvider = Provider<NetBlock>((ref) => deskNetBlock(ref.watch(deskProvider), nodeOnly: true));

/// [deskOfflineUsesNode] for a widget.
final deskOfflineUsesNodeProvider = Provider<bool>((ref) => deskOfflineUsesNode(ref.watch(deskProvider)));

/// The reason for a disabled network action, one short line; null when nothing blocks.
String? netBlockReason(AppLocalizations l, NetBlock b) => switch (b) {
  NetBlock.none => null,
  NetBlock.nodeOnly => l.netBlockNodeOnly,
  NetBlock.killSwitch => l.netBlockKillSwitch,
  NetBlock.waitingForTor => l.netBlockWaitingForTorLong,
  NetBlock.epicboxOff => l.netBlockEpicboxOff,
  // The screen names the method it asked about ([methodOffReason]).
  NetBlock.methodOff => null,
};

/// The reason an action by [m] is off: its switch on Settings › Transactions.
String methodOffReason(AppLocalizations l, MethodKind m) =>
    m == MethodKind.epicbox ? l.netBlockEpicboxOff : l.netBlockMethodOff(MethodIcons.fullName(l, m));
