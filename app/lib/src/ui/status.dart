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

/// The side of a status's tap target.
const double statusTarget = 48;

/// The side of a status's icon, centred in its target.
const double statusGlyph = 18;

/// From a status target's leading edge to its icon's: what a row of statuses is moved back by
/// so its first icon lines up with the text above or beside it.
const double statusInset = (statusTarget - statusGlyph) / 2;

/// The key of the node status, for tests.
const Key nodeStatusKey = ValueKey('status-node');

/// The key of the epicbox status, for tests.
const Key epicboxStatusKey = ValueKey('status-epicbox');

/// How many statuses [BarStatuses] shows for [status]: the node, and epicbox while the
/// listener runs.
int statusCount(WalletStatus status) => status.epicbox == null ? 1 : 2;

/// The width [BarStatuses] takes for [status].
double statusesWidth(WalletStatus status) => statusTarget * statusCount(status);

/// [child] fading between 45 % and full opacity every 1.6 s while [active], as the mockup's
/// pulse. Still at full opacity with reduced motion, or when not [active].
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.45)
      .chain(CurveTween(curve: const Cubic(0.22, 0.61, 0.36, 1)))
      .animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!run && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// One status as its icon on a [statusTarget] square, in the state's colour. A tap, a long
/// press or hover shows the tooltip with the detail; a screen reader says the word and the
/// detail. The syncing node pulses.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    super.key,
    required this.face,
    required this.pulse,
    required this.alignment,
  });

  final _Face face;
  final bool pulse;
  final AlignmentGeometry alignment;

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
        child: SizedBox.square(
          dimension: statusTarget,
          child: Align(
            alignment: alignment,
            child: Pulse(
              active: pulse,
              child: Icon(face.icon, size: statusGlyph, color: face.color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The node and epicbox statuses as icons side by side, epicbox only while the listener
/// runs: in the app bar, in Wallet's fiat row, or in the row under the app bar on Send and
/// Receive. [alignment] places each icon in its target; the row under the app bar is shorter
/// than a target, so its icons sit in the target's top part.
class BarStatuses extends ConsumerWidget {
  const BarStatuses({super.key, this.alignment = Alignment.center});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = watchWalletStatus(ref);
    final config = ref.watch(walletConfigProvider);
    final epicbox = status.epicbox;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusIcon(
          key: nodeStatusKey,
          face: _nodeFace(context, status.node, config),
          pulse: status.node.state == NodeState.syncing,
          alignment: alignment,
        ),
        if (epicbox != null)
          _StatusIcon(
            key: epicboxStatusKey,
            face: _epicboxFace(context, epicbox, config),
            pulse: false,
            alignment: alignment,
          ),
      ],
    );
  }
}
