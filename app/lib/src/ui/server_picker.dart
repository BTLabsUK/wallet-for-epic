// SPDX-License-Identifier: Apache-2.0
/// Where the phone's Node and Epicbox pickers open ([showNodePicker], [showEpicboxPicker]),
/// and the monitor's views they show: the public nodes and the network as a whole.
///
/// The pickers are one editable list per kind (`server_list_sheet.dart`, stored by
/// `server_list_store.dart`). Nothing switches on its own: a tap asks first, and a switch
/// moves the open wallet, or saves the choice and starts the app again on it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network.dart';
import '../providers.dart' show askNodeTip, sessionProvider, walletServiceProvider;
import '../relay_directory.dart';
import 'launch_screen.dart';
import 'server_list_sheet.dart' show showEpicboxListSheet, showNodeListSheet;

export '../server_list_store.dart'
    show ServerKind, builtInNodesFor, builtInRelaysFor, typedNodeUrl;

// Providers.

/// The public nodes the status site lists for [NetworkPreset.statusChain], in its order.
/// Empty for usernet; an error when the site is off or does not answer.
final publicNodeStatusProvider = FutureProvider.autoDispose.family<List<NodeStatus>, NetworkPreset>(
  (ref, preset) async {
    final chain = preset.statusChain;
    if (chain == null) return const [];
    ref.watch(useStatusSiteProvider);
    final directory = ref.watch(relayDirectoryProvider);
    if (directory is! NodeDirectory) throw StateError('no node directory');
    return (directory as NodeDirectory).nodes(chain);
  },
);

/// A node on this phone or the local network ([isLocalNodeUrl]), asked from this phone:
/// The status site cannot reach it, so its row never takes the monitor's word. Healthy when
/// it gives its tip within [localNodeProbeTimeout], else down.
final localNodeStatusProvider = FutureProvider.autoDispose.family<NodeStatus, ({String url, NetworkPreset preset})>(
  (ref, k) async {
    final watch = Stopwatch()..start();
    try {
      final tip = await askNodeTip(
        ref.read(walletServiceProvider),
        ref.read(sessionProvider),
        k.preset.config(dataDir: '', nodeUrl: k.url),
      ).timeout(localNodeProbeTimeout);
      return NodeStatus(
        url: k.url,
        healthy: true,
        verified: false,
        state: NodeHealthState.healthy,
        height: tip.height.toInt(),
        latencyMs: watch.elapsedMilliseconds,
        nodeVersion: tip.nodeVersion,
      );
    } on Object {
      return NodeStatus(url: k.url, healthy: false, verified: false, state: NodeHealthState.down);
    }
  },
);

/// How long [localNodeStatusProvider] waits for a local node.
const localNodeProbeTimeout = Duration(seconds: 10);

/// The status site's view of the chain as a whole (its tip, nodes up, last block).
final networkStatusProvider = FutureProvider.autoDispose.family<NetworkStatus, NetworkPreset>((
  ref,
  preset,
) async {
  final chain = preset.statusChain;
  if (chain == null) throw StateError('no status for ${preset.chain.name}');
  ref.watch(useStatusSiteProvider);
  final directory = ref.watch(relayDirectoryProvider);
  if (directory is! NetworkDirectory) {
    throw StateError('no network directory');
  }
  return (directory as NetworkDirectory).network(chain);
});

// The sheets.

/// Opens the node picker over the current screen.
Future<void> showNodePicker(BuildContext context) => showNodeListSheet(context);

/// Opens the Epicbox picker over the current screen.
Future<void> showEpicboxPicker(BuildContext context) => showEpicboxListSheet(context);

/// Starts the app again on the saved network choice, when no wallet was open to switch live.
void relaunchAfterSwitch(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const LaunchScreen()), (_) => false);
}
