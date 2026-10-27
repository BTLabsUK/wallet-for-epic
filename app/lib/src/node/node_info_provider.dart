/// The node info providers (F27), apart from the rest of the node layer so that the phone's
/// server list can ask an own node without the desktop's node controls; the web build takes
/// node_info_provider_web.dart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network.dart';
import '../relay_directory.dart';
import 'node_info.dart';

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
  (ref, key) {
    // Read again when status.btlabs.uk is turned on or off.
    ref.watch(useStatusSiteProvider);
    return ref.watch(nodeInfoServiceProvider).info(key.url, chain: key.preset.statusChain);
  },
);

class _NoNodes implements NodeDirectory {
  const _NoNodes();

  @override
  Future<List<NodeStatus>> nodes(String chain) async => const [];
}
