/// The network status card on Home: one row each for the node and Epicbox, and one for Tor
/// while it starts or runs. A row's tap opens the server picker for it, or Settings for Tor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart' show Chain;
import '../network.dart';
import '../phone_tor.dart';
import '../providers.dart';
import 'server_picker.dart';
import 'settings_screen.dart';
import 'status.dart';
import 'theme/tokens.dart';

/// The keys of the card's rows, for tests: the node and epicbox rows take the keys the
/// header's status icons had.
const Key netStatusNodeKey = nodeStatusKey;
const Key netStatusEpicboxKey = epicboxStatusKey;
const Key netStatusTorKey = ValueKey('net-status-tor');

/// Whether the card shows a Tor row: while phone Tor starts, runs or retries after a failure.
bool torRowShown(PhoneTorState s) => switch (s.phase) {
  PhoneTorPhase.starting ||
  PhoneTorPhase.connected ||
  PhoneTorPhase.ready ||
  PhoneTorPhase.failed => true,
  PhoneTorPhase.off || PhoneTorPhase.unavailable => false,
};

/// Tor's face on the card.
NetFace torNetFace(BuildContext context, PhoneTorState s) {
  final l = context.l10n;
  final t = context.tokens;
  return switch (s.phase) {
    PhoneTorPhase.starting => (
      level: SignalLevel.two,
      color: t.dim,
      word: l.netStatusStarting(s.progress ?? 0),
    ),
    PhoneTorPhase.connected || PhoneTorPhase.ready => (
      level: SignalLevel.three,
      color: t.ok,
      word: l.netStatusOn,
    ),
    PhoneTorPhase.failed => (
      level: SignalLevel.one,
      color: t.risk,
      word: l.netStatusFailed,
    ),
    PhoneTorPhase.off || PhoneTorPhase.unavailable => (
      level: SignalLevel.none,
      color: t.dim,
      word: l.netStatusOff,
    ),
  };
}

/// The node's lag behind the network's tip as status.btlabs.uk sees it, for a node that
/// answers; null when either height is unknown.
int? _behind(WidgetRef ref, NodeStatus node, NetworkPreset? preset) {
  final height = node.tip?.height;
  if (height == null || preset == null || preset.statusChain == null) {
    return null;
  }
  final tip = ref.watch(networkStatusProvider(preset)).value?.tipHeight;
  if (tip == null) return null;
  final lag = tip - height.toInt();
  return lag < 0 ? 0 : lag;
}

/// The node, Epicbox and Tor rows in a hairline card.
class NetworkStatusCard extends ConsumerWidget {
  const NetworkStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final status = watchWalletStatus(ref);
    final config = ref.watch(walletConfigProvider);
    final choice = ref.watch(networkChoiceProvider).value;
    final tor = ref.watch(phoneTorProvider);
    final preset = choice?.preset;
    final nodeUrl = config?.nodeUrl ?? choice?.nodeUrl;
    final chain = config?.chain ?? preset?.chain;
    final nodeHost = nodeUrl == null ? '' : serverHost(nodeUrl);
    final relay = config != null
        ? EpicboxRelay(
            host: config.epicboxDomain,
            port: config.epicboxPort,
          ).label
        : choice?.relay.label ?? '';
    final online = status.node.state == NodeState.online;
    final node = nodeNetFace(
      context,
      status.node,
      behind: online ? _behind(ref, status.node, preset) : null,
    );
    final epicbox = epicboxNetFace(context, status.epicbox);
    final nodeWords = nodeStatusWords(context, status.node, config);
    final epicboxWords = epicboxStatusWords(context, status.epicbox, config);
    final rows = <Widget>[
      _StatusRow(
        key: netStatusNodeKey,
        title: l.netStatusNode,
        host: chain != null && chain != Chain.mainnet && nodeHost.isNotEmpty
            ? l.netStatusTestHost(chainName(l, chain), nodeHost)
            : nodeHost,
        face: node,
        spoken: nodeWords.label,
        detail: nodeWords.detail,
        pulse: status.node.state == NodeState.syncing,
        onTap: () => showNodePicker(context),
      ),
      _StatusRow(
        key: netStatusEpicboxKey,
        title: l.netStatusEpicbox,
        host: relay,
        face: epicbox,
        spoken: epicboxWords?.label,
        detail: epicboxWords?.detail,
        onTap: () => showEpicboxPicker(context),
      ),
      if (torRowShown(tor))
        _StatusRow(
          key: netStatusTorKey,
          title: l.netStatusTor,
          host: '',
          face: torNetFace(context, tor),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
    ];
    return Semantics(
      container: true,
      label: l.netStatusTitle,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One row: bars, the service, its host in mono, the state word and a chevron; one 56 dp
/// target, read as "Node online, node.btlabs.uk, Synced" ([spoken] first, as the header's
/// icons said it, else the title) with the icon's tooltip [detail] as the hint.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.title,
    required this.host,
    required this.face,
    required this.onTap,
    this.spoken,
    this.detail,
    this.pulse = false,
  });

  final String? spoken;
  final String? detail;

  final String title;
  final String host;
  final NetFace face;
  final bool pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      liveRegion: true,
      label: [spoken ?? title, if (host.isNotEmpty) host, face.word].join(', '),
      hint: detail ?? context.l10n.netStatusOpenHint,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: [
                  SignalBars(
                    level: face.level,
                    color: face.color,
                    pulse: pulse,
                  ),
                  const SizedBox(width: 12),
                  // The service over its host, as the desktop's sidebar rows: a long host
                  // never pushes the state word off the row.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: theme.textTheme.bodyMedium),
                        if (host.isNotEmpty)
                          Text(
                            host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: t.monoFamily,
                              fontSize: 12,
                              height: 1.3,
                              color: t.dim,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      face.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: face.color,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: t.dim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
