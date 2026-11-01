// SPDX-License-Identifier: Apache-2.0
/// A node switch the user started (Settings › Node, the status popover), while it runs: what the
/// selected server field and the sidebar status say at once, before the wallet has moved.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../address_format.dart' show railHost;
import '../../l10n.dart' show AppLocalizations;
import '../../node/local_node_state.dart' show LocalNodePhase, LocalNodeState;
import '../widgets/status.dart' show EState;
import 'desk_node.dart' show deskLocalNodeProvider, nodeHost;
import 'node_view.dart' show NodeView;

enum NodeSwitchStep {
  /// The wallet is opening on the public node.
  connecting,

  /// The local node is starting (the switch to it).
  starting,

  /// The wallet is on the public node; the local node is closing its files.
  stopping,
}

class NodeSwitch {
  const NodeSwitch(this.step, {this.url});

  final NodeSwitchStep step;

  /// The public node switched to; null for the local node.
  final String? url;
}

final deskNodeSwitchProvider = NotifierProvider<DeskNodeSwitch, NodeSwitch?>(DeskNodeSwitch.new);

class DeskNodeSwitch extends Notifier<NodeSwitch?> {
  ProviderSubscription<AsyncValue<LocalNodeState>>? _watch;

  @override
  NodeSwitch? build() {
    ref.onDispose(() => _watch?.close());
    return null;
  }

  /// Says [step] while [move] runs. A switch away from a running local node then says
  /// [NodeSwitchStep.stopping] until the node has exited (the wallet does not wait for that).
  Future<void> run(NodeSwitchStep step, String? url, Future<void> Function() move) async {
    // Read only when it exists: creating it would start the local node's controller.
    final local = ref.exists(deskLocalNodeProvider) ? ref.read(deskLocalNodeProvider).value : null;
    final fromLocal = step == NodeSwitchStep.connecting && local != null && (local.phase != LocalNodePhase.stopped || local.stopping);
    _watch?.close();
    _watch = null;
    final mine = NodeSwitch(step, url: url);
    state = mine;
    var moved = false;
    try {
      await move();
      moved = true;
    } finally {
      if (identical(state, mine)) {
        if (moved && fromLocal) {
          _followStop(NodeSwitch(NodeSwitchStep.stopping, url: url));
        } else {
          state = null;
        }
      }
    }
  }

  void _followStop(NodeSwitch s) {
    state = s;
    void check(LocalNodeState? n) {
      if (n != null && n.stopping) return;
      _watch?.close();
      _watch = null;
      if (identical(state, s)) state = null;
    }

    _watch = ref.listen(deskLocalNodeProvider, (_, v) => check(v.value));
    // It may have exited already.
    scheduleMicrotask(() => check(ref.read(deskLocalNodeProvider).value));
  }
}

/// The words of a switch under way: "Connecting to node.example.org…", "Starting the local
/// node…", "Stopping the local node…".
String nodeSwitchText(AppLocalizations l, NodeSwitch s) => switch (s.step) {
  NodeSwitchStep.connecting => l.deskNodeSwitchConnecting(nodeHost(s.url ?? '')),
  NodeSwitchStep.starting => l.deskNodeSwitchStarting,
  NodeSwitchStep.stopping => l.deskNodeSwitchStopping,
};

/// The rail's Node row while a switch runs: the node switched to, and what happens.
NodeView nodeSwitchView(AppLocalizations l, NodeSwitch s) => NodeView(
  word: switch (s.step) {
    NodeSwitchStep.connecting => l.deskRailConnecting,
    NodeSwitchStep.starting => l.deskRailStarting,
    NodeSwitchStep.stopping => l.deskNodeSwitchStoppingWord,
  },
  state: EState.active,
  host: s.url == null ? l.deskSetNodeLocalNode : railHost('Node', nodeHost(s.url!)), // l10n-ok: railHost's row key
  lines: [nodeSwitchText(l, s)],
);
