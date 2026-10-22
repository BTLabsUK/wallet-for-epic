/// Riverpod providers of the node service layer, for the desktop screens to bind to: the local
/// node's state and controls, its peers, node info for any node (F27), local node detection and
/// facts (F24), reusable chain data, and the public-node fallback (D-7).
///
/// Reading a provider starts no node and downloads nothing: only [LocalNodeController.start]
/// does, after the user chose to (O2).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../builtin_node.dart';
import '../builtin_node_provider.dart';
import '../legacy_wallets.dart' show LegacyRoots;
import '../models.dart' show Chain;
import '../network.dart';
import '../providers.dart';
import '../relay_directory.dart';
import 'chain_data.dart';
import 'fallback.dart';
import 'local_node_controller.dart';
import 'local_node_state.dart';
import 'node_api.dart';
import 'node_detect.dart';
import 'node_info.dart';
import 'node_maintenance.dart';
import 'node_settings.dart';
import 'peers.dart';

/// The monitor's chain name of [chain], or null where it has none (usernet).
String? statusChainOf(Chain chain) => switch (chain) {
  Chain.mainnet => 'mainnet',
  Chain.floonet => 'floonet',
  Chain.usernet => null,
};

/// The per-chain node settings (start with the app, data folder, peers, fallback answer).
final nodeSettingsProvider = Provider.family<NodeSettings, Chain>(
  (ref, chain) => NodeSettings(ref.watch(secretStoreProvider), chain),
);

/// The local node's controller of a chain: the same [BuiltInNode] the wallet uses
/// ([builtInNodeFor]). Desktop only; throws [UnsupportedError] on phones.
final localNodeControllerProvider = FutureProvider.family<LocalNodeController, Chain>((ref, chain) async {
  final node = await ref.watch(builtInNodeProvider(chain).future);
  final settings = ref.watch(nodeSettingsProvider(chain));
  final directory = ref.watch(relayDirectoryProvider);
  final statusChain = statusChainOf(chain);
  final controller = LocalNodeController(
    node,
    settings: settings,
    dirSize: dirSize,
    directoryTip: directory is NetworkDirectory && statusChain != null
        ? () async => (await (directory as NetworkDirectory).network(statusChain)).tipHeight
        : null,
    // The peers' heights, from the last read of the peers table (null while it was never open).
    peersMaxHeight: () async => (await ref.read(peerServiceProvider(chain).future)).last?.maxHeight,
  );
  await controller.load();
  ref.onDispose(controller.dispose);
  return controller;
});

/// The local node's data folder operations: change folder, reuse another node's chain data,
/// delete chain data. Each stops the node first and starts it again when it ran.
final nodeMaintenanceProvider = FutureProvider.family<NodeMaintenance, Chain>(
  (ref, chain) async => NodeMaintenance(await ref.watch(localNodeControllerProvider(chain).future)),
);

/// The local node's state as it changes ([LocalNodeState.online] only when synced and ready).
final localNodeStateProvider = StreamProvider.family<LocalNodeState, Chain>((ref, chain) async* {
  final c = await ref.watch(localNodeControllerProvider(chain).future);
  yield c.state;
  yield* c.states;
});

/// An owner-API client of the local node (its secret read from the node's folder).
final localNodeApiProvider = FutureProvider.family<NodeApiClient, Chain>((ref, chain) async {
  final node = await ref.watch(builtInNodeProvider(chain).future);
  return NodeApiClient(node.url, secret: node.readSecret);
});

/// The peer service of the local node; it keeps the session's peer-count history.
final peerServiceProvider = FutureProvider.family<PeerService, Chain>((ref, chain) async {
  return PeerService(await ref.watch(localNodeApiProvider(chain).future));
});

/// How often the peers are read while the peers table is open; graph samples are kept every
/// 30 s ([PeerService.sampleEvery]).
const Duration peerReadEvery = Duration(seconds: 10);

/// The peers, read now and every [peerReadEvery] while something listens (the peers table),
/// and not at all otherwise.
final peersProvider = StreamProvider.autoDispose.family<PeerSnapshot, Chain>((ref, chain) async* {
  final service = await ref.watch(peerServiceProvider(chain).future);
  final ticks = StreamController<void>();
  final timer = Timer.periodic(peerReadEvery, (_) => ticks.add(null));
  ref.onDispose(() {
    timer.cancel();
    unawaited(ticks.close());
  });
  yield await service.refresh();
  await for (final _ in ticks.stream) {
    try {
      yield await service.refresh();
    } on Object {
      // a missed sample: the last snapshot stays
    }
  }
});

/// Node info for any node URL (F27), shared by the picker, the card and the status rail.
final nodeInfoServiceProvider = Provider<NodeInfoService>((ref) {
  final directory = ref.watch(relayDirectoryProvider);
  return NodeInfoService(
    nodes: directory is NodeDirectory ? directory as NodeDirectory : const _NoNodes(),
    network: directory is NetworkDirectory ? directory as NetworkDirectory : null,
  );
});

/// [NodeInfo] of a node URL on a network preset's chain. Refresh with `ref.invalidate`.
final nodeInfoProvider = FutureProvider.autoDispose.family<NodeInfo, ({String url, NetworkPreset preset})>(
  (ref, key) => ref.watch(nodeInfoServiceProvider).info(key.url, chain: key.preset.statusChain),
);

/// Whether a node already answers on this computer's standard port (F24).
final localNodeProbeProvider = FutureProvider.autoDispose.family<LocalNodeProbe, Chain>((ref, chain) async {
  BuiltInNode? ours;
  if (ref.watch(builtInNodeSupportedProvider)) {
    ours = await ref.watch(builtInNodeProvider(chain).future);
  }
  return detectLocalNode(chain, ours: ours);
});

/// Chain data of other nodes on this computer that the local node could reuse.
final chainDataCandidatesProvider = FutureProvider.autoDispose.family<List<ChainDataInfo>, Chain>((ref, chain) async {
  final where = await ref.watch(builtInNodeLocationProvider.future);
  return findChainData(chain, roots: LegacyRoots.current(), bundledRoot: where.root);
});

/// The facts of the "Local node" explanation step (F24).
final localNodeFactsProvider = FutureProvider.autoDispose.family<LocalNodeFacts, Chain>((ref, chain) async {
  final node = await ref.watch(builtInNodeProvider(chain).future);
  final found = await ref.watch(chainDataCandidatesProvider(chain).future);
  return localNodeFacts(chain, folder: node.folder, freeBytes: realFreeBytes, found: found, minFreeBytes: node.minFreeBytes);
});

/// The user's answer to the public-node fallback question.
final fallbackChoiceProvider = FutureProvider.family<FallbackChoice, Chain>(
  (ref, chain) => ref.watch(nodeSettingsProvider(chain)).fallbackChoice(),
);

/// What the wallet should do about its node while the local node syncs (D-7).
final fallbackDecisionProvider = Provider.family<AsyncValue<FallbackDecision>, Chain>((ref, chain) {
  final local = ref.watch(localNodeStateProvider(chain));
  final choice = ref.watch(fallbackChoiceProvider(chain));
  if (local.hasError) return AsyncError(local.error!, local.stackTrace ?? StackTrace.current);
  if (choice.hasError) return AsyncError(choice.error!, choice.stackTrace ?? StackTrace.current);
  final l = local.value, c = choice.value;
  if (l == null || c == null) return const AsyncLoading();
  return AsyncData(decideFallback(l, c));
});

class _NoNodes implements NodeDirectory {
  const _NoNodes();

  @override
  Future<List<NodeStatus>> nodes(String chain) async => const [];
}
