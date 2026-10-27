/// The web build's node info: it has no node clients, so an own node reads as not known.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network.dart';
import 'node_info_types.dart';

/// [NodeInfo] of a node URL: never asked on the web.
final nodeInfoProvider = FutureProvider.autoDispose.family<NodeInfo, ({String url, NetworkPreset preset})>(
  (ref, key) => NodeInfo(url: key.url, source: NodeInfoSource.none, at: DateTime.now(), error: 'web'),
);
