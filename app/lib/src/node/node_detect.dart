// SPDX-License-Identifier: Apache-2.0
/// The first-run "Local node" choice: is a node already running on this computer (the CLI
/// node, the Epic GUI's node), and the facts the explanation step shows before anything starts
/// or downloads: disk space, chain size, sync time, the Windows firewall prompt.
library;

import 'dart:async';
import 'dart:io';

import '../builtin_node.dart';
import '../models.dart' show Chain;
import 'chain_data.dart';
import 'node_api.dart';
import 'node_api_types.dart';

/// What answered on a local address.
class LocalNodeProbe {
  const LocalNodeProbe({
    required this.url,
    required this.answers,
    this.version,
    this.height,
    this.readyForTxs,
    this.latencyMs,
    this.ours = false,
  });

  /// `http://127.0.0.1:<api port>` or the address the user typed.
  final String url;

  /// A node answered `get_tip` there.
  final bool answers;
  final String? version;
  final int? height;
  final bool? readyForTxs;
  final int? latencyMs;

  /// It is the bundled node this app runs, not another program's.
  final bool ours;

  /// Another node runs: "Use the node already running on this computer" can be offered.
  bool get otherNode => answers && !ours;
}

/// Probes [url] (default: the chain's standard API port on loopback) with the foreign API. [ours]
/// is the app's bundled node of this chain, when one exists: a node that answers while it runs is
/// that one.
Future<LocalNodeProbe> detectLocalNode(
  Chain chain, {
  String? url,
  BuiltInNode? ours,
  NodeApiClient Function(String url)? clientFor,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final where = url ?? 'http://127.0.0.1:${NodePorts.of(chain).api}';
  final isOurs = ours != null && ours.state.isActive && ours.url == where;
  final NodeApiClient api;
  try {
    api = (clientFor ?? NodeApiClient.new)(where);
  } on NodeRpcException {
    return LocalNodeProbe(url: where, answers: false);
  }
  final watch = Stopwatch()..start();
  final NodeTipInfo tip;
  try {
    tip = await api.tip().timeout(timeout);
  } on Object {
    return LocalNodeProbe(url: where, answers: false, ours: isOurs);
  }
  final latency = watch.elapsedMilliseconds;
  Future<T?> quiet<T>(Future<T?> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on Object {
      return null;
    }
  }

  final (ready, version) = await (
    quiet(api.readyForTxs),
    quiet(() async => (await api.version()).nodeVersion),
  ).wait;
  return LocalNodeProbe(
    url: where,
    answers: true,
    version: version,
    height: tip.height,
    readyForTxs: ready,
    latencyMs: latency,
    ours: isOurs,
  );
}

/// The size of a synced mainnet node's chain data, for the warning before the first start: the
/// monitor does not publish it, so it is a measured constant ([chainSizeMeasuredOn]) unless a
/// found chain gives a real number.
const int mainnetChainBytesEstimate = 5 * 1024 * 1024 * 1024;
const String chainSizeMeasuredOn = '2026-10';

/// The facts of the explanation step.
class LocalNodeFacts {
  const LocalNodeFacts({
    required this.chainBytes,
    required this.chainBytesMeasured,
    required this.freeBytes,
    required this.minFreeBytes,
    required this.firewallPrompt,
    this.reusable = const [],
  });

  /// About how much the chain takes on disk.
  final int chainBytes;

  /// [chainBytes] comes from chain data found on this computer, not from the estimate.
  final bool chainBytesMeasured;

  /// Free space where the node's folder would be; null when it cannot be told.
  final int? freeBytes;

  /// The node refuses to start, and stops, under this much free space.
  final int minFreeBytes;

  /// Windows asks to allow the node through the firewall at its first start (it listens for
  /// peers on its P2P port).
  final bool firewallPrompt;

  /// Chain data of another node that can be reused (copied or pointed to) instead of downloading.
  final List<ChainDataInfo> reusable;

  /// Enough room for the chain and the floor.
  bool? get enoughSpace => freeBytes == null ? null : freeBytes! >= chainBytes + minFreeBytes;
}

/// Gathers [LocalNodeFacts] for a node whose folder is [folder].
Future<LocalNodeFacts> localNodeFacts(
  Chain chain, {
  required String folder,
  required DiskProbe freeBytes,
  List<ChainDataInfo> found = const [],
  int minFreeBytes = 5 * 1024 * 1024 * 1024,
  bool? isWindows,
}) async {
  final reusable = found.where((c) => c.usable && c.chain == chain).toList();
  final measured = reusable.map((c) => c.bytes).fold<int>(0, (a, b) => b > a ? b : a);
  var probeDir = folder;
  // The folder may not exist yet: ask about the closest parent that does.
  while (!await Directory(probeDir).exists()) {
    final parent = Directory(probeDir).parent.path;
    if (parent == probeDir) break;
    probeDir = parent;
  }
  return LocalNodeFacts(
    chainBytes: chain == Chain.mainnet
        ? (measured > 0 ? measured : mainnetChainBytesEstimate)
        : measured,
    chainBytesMeasured: measured > 0,
    freeBytes: await freeBytes(probeDir),
    minFreeBytes: minFreeBytes,
    firewallPrompt: isWindows ?? Platform.isWindows,
    reusable: reusable,
  );
}
