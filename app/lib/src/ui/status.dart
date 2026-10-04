import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart' show groupDigits;
import 'theme/tokens.dart';

/// Where the node stands for the open wallet.
enum NodeState { online, syncing, connecting, offline }

/// Where the epicbox listener stands.
enum EpicboxState { online, connecting, offline }

/// The node row of the header: its state, and what its tooltip tells.
class NodeStatus {
  const NodeStatus(
    this.state, {
    this.percent,
    this.tip,
    this.height,
    this.validated = true,
  });

  final NodeState state;

  /// Percent done while [NodeState.syncing], when the refresh reports it.
  final int? percent;

  /// The node's answer, when it gave one.
  final NodeTip? tip;

  /// The block the balances were checked at, else the node's tip.
  final BigInt? height;

  /// False when the balances on screen were read from the wallet's files only, because the
  /// refresh against the node failed. Only [NodeState.offline] has it false.
  final bool validated;
}

/// The header's two statuses. [epicbox] is null when the listener does not run.
typedef WalletStatus = ({NodeStatus node, EpicboxState? epicbox});

/// The node and epicbox statuses from what the app knows: the node's tip, whether a refresh
/// runs ([syncing]) and its [percent], the balances shown ([summary]) and the listener.
///
/// Node: a running refresh is syncing; a failed tip request, or balances the refresh could not
/// check, is offline; a tip is online; no answer yet is connecting. Epicbox: connected is
/// online, a lost connection is offline, anything else connecting; a stopped listener has no
/// status.
WalletStatus walletStatus({
  required AsyncValue<NodeTip> tip,
  required bool syncing,
  int? percent,
  WalletSummary? summary,
  required ListenerState listener,
}) {
  final answer = tip.value;
  final checked = summary != null && summary.lastConfirmedHeight > BigInt.zero
      ? summary.lastConfirmedHeight
      : answer?.height;
  final NodeStatus node;
  if (syncing) {
    node = NodeStatus(
      NodeState.syncing,
      percent: percent,
      tip: answer,
      height: checked,
    );
  } else if (tip.hasError && !tip.isLoading) {
    node = NodeStatus(NodeState.offline, height: checked);
  } else if (summary != null && !summary.validatedWithNode) {
    node = NodeStatus(
      NodeState.offline,
      tip: answer,
      height: checked,
      validated: false,
    );
  } else if (answer != null) {
    node = NodeStatus(NodeState.online, tip: answer, height: checked);
  } else {
    node = NodeStatus(NodeState.connecting, height: checked);
  }
  final EpicboxState? epicbox = listener.stopped
      ? null
      : listener.connected
      ? EpicboxState.online
      : listener.lost
      ? EpicboxState.offline
      : EpicboxState.connecting;
  return (node: node, epicbox: epicbox);
}

/// How bad a state is: 0 fine, 1 on its way, 2 a problem.
int _severity(Object state) => switch (state) {
  NodeState.online || EpicboxState.online => 0,
  NodeState.offline || EpicboxState.offline => 2,
  _ => 1,
};

/// Whether the single icon of the shrunk header shows epicbox instead of the node: only when
/// epicbox is strictly worse. A tie names the node, since the balances depend on it.
bool epicboxIsWorse(WalletStatus status) {
  final epicbox = status.epicbox;
  return epicbox != null && _severity(epicbox) > _severity(status.node.state);
}

/// The [WalletStatus] of the open wallet, rebuilt when any input changes.
WalletStatus watchWalletStatus(WidgetRef ref) {
  final home = ref.watch(homeProvider);
  final data = home.value;
  final syncing = data != null && (home.isLoading || data.syncing);
  return walletStatus(
    tip: ref.watch(nodeTipProvider),
    syncing: syncing,
    percent: syncing ? ref.watch(syncProgressProvider) : null,
    summary: data?.summary,
    listener: ref.watch(listenerProvider),
  );
}

/// Icon, words (the service and its state, also what a screen reader says), colour, spoken
/// label and tooltip of one status.
class _Face {
  const _Face(this.icon, this.word, this.color, this.label, this.detail);

  final IconData icon;
  final String word;
  final Color color;
  final String label;
  final String detail;
}

_Face _nodeFace(BuildContext context, NodeStatus node, WalletConfig? config) {
  final l = context.l10n;
  final t = context.tokens;
  final (
    IconData icon,
    String word,
    Color color,
    String sentence,
  ) = switch (node.state) {
    NodeState.online => (
      Icons.cloud_done_outlined,
      l.statusNodeOnline,
      t.ok,
      l.homeSyncUpToDate,
    ),
    NodeState.syncing => (
      Icons.sync,
      node.percent == null
          ? l.statusNodeSyncing
          : l.statusNodeSyncingPercent(node.percent!),
      t.dim,
      node.percent == null
          ? l.homeSyncSyncing
          : l.homeSyncSyncingPercent(node.percent!),
    ),
    NodeState.connecting => (
      Icons.cloud_queue,
      l.statusNodeConnecting,
      t.dim,
      l.homeSyncContactingNode,
    ),
    NodeState.offline => (
      Icons.cloud_off,
      l.statusNodeOffline,
      t.risk,
      node.validated ? l.homeSyncNodeUnreachable : l.homeSyncNotValidated,
    ),
  };
  final host = config == null
      ? null
      : Uri.tryParse(config.nodeUrl)?.host ?? config.nodeUrl;
  final height = node.height;
  final version = node.tip?.nodeVersion ?? '';
  final detail = [
    sentence,
    if (host != null && host.isNotEmpty) l.statusNodeHost(host),
    if (height != null && height > BigInt.zero)
      l.homeSyncedAtBlock(groupDigits(l, height)),
    if (version.isNotEmpty) l.statusNodeVersion(version),
  ].join('\n');
  return _Face(icon, word, color, word, detail);
}

_Face _epicboxFace(
  BuildContext context,
  EpicboxState state,
  WalletConfig? config,
) {
  final l = context.l10n;
  final t = context.tokens;
  final (
    IconData icon,
    String word,
    Color color,
    String sentence,
  ) = switch (state) {
    EpicboxState.online => (
      Icons.mark_email_read_outlined,
      l.statusEpicboxOnline,
      t.ok,
      l.receiveEpicboxConnected,
    ),
    EpicboxState.connecting => (
      Icons.mail_outline,
      l.statusEpicboxConnecting,
      t.dim,
      l.homeEpicboxConnecting,
    ),
    EpicboxState.offline => (
      Icons.unsubscribe_outlined,
      l.statusEpicboxOffline,
      t.risk,
      l.homeEpicboxOffline,
    ),
  };
  final detail = [
    sentence,
    if (config != null)
      l.statusRelay('${config.epicboxDomain}:${config.epicboxPort}'),
  ].join('\n');
  return _Face(icon, word, color, word, detail);
}

/// A tooltip that opens on a long press, a tap, or hover, over a 48 dp target.
class _StatusTarget extends StatelessWidget {
  const _StatusTarget({super.key, required this.face, required this.child});

  final _Face face;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: face.detail,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: Semantics(
        container: true,
        label: face.label,
        hint: face.detail,
        liveRegion: true,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: child,
        ),
      ),
    );
  }
}

/// One status as a row: icon, then the word, right-aligned.
class _StatusRow extends StatelessWidget {
  const _StatusRow({super.key, required this.face});

  final _Face face;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: face.color);
    return _StatusTarget(
      face: face,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(face.icon, size: 16, color: face.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              face.word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// The key of the node row, for tests.
const Key nodeStatusKey = ValueKey('status-node');

/// The key of the epicbox row, for tests.
const Key epicboxStatusKey = ValueKey('status-epicbox');

/// The key of the single icon the shrunk header shows, for tests.
const Key compactStatusKey = ValueKey('status-compact');

/// The Wallet tab's statuses: one right-aligned row for the node, one for epicbox while the
/// listener runs. Each row's tooltip has the detail.
class StatusRows extends ConsumerWidget {
  const StatusRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = watchWalletStatus(ref);
    final config = ref.watch(walletConfigProvider);
    final epicbox = status.epicbox;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatusRow(
          key: nodeStatusKey,
          face: _nodeFace(context, status.node, config),
        ),
        if (epicbox != null)
          _StatusRow(
            key: epicboxStatusKey,
            face: _epicboxFace(context, epicbox, config),
          ),
      ],
    );
  }
}

/// The shrunk header's status: the icon of the worse of the two, with its tooltip.
class CompactStatus extends ConsumerWidget {
  const CompactStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = watchWalletStatus(ref);
    final config = ref.watch(walletConfigProvider);
    final face = epicboxIsWorse(status)
        ? _epicboxFace(context, status.epicbox!, config)
        : _nodeFace(context, status.node, config);
    return _StatusTarget(
      key: compactStatusKey,
      face: face,
      // At the row's end, where the two rows end on Wallet.
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        widthFactor: 1,
        child: Icon(face.icon, size: 20, color: face.color),
      ),
    );
  }
}
