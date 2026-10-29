// SPDX-License-Identifier: Apache-2.0
/// A plain debug view of the node service layer: the local node's state and controls, its
/// peers, node info, detection and found chain data. For developers only; the real screens are
/// designed separately. Started by `lib/main_node_debug.dart`, never part of a release build.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show Chain;
import '../../../network.dart';
import '../../../node/local_node_state.dart';
import '../../../node/node_info.dart';
import '../../../node/node_providers.dart';
import '../../../settings_file/host_settings.dart' show hostSettings;

class NodeDebugView extends ConsumerWidget {
  const NodeDebugView({super.key, this.chain = Chain.mainnet});

  final Chain chain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localNodeStateProvider(chain));
    final controller = ref.watch(localNodeControllerProvider(chain)).value;
    final fallback = ref.watch(fallbackDecisionProvider(chain));
    return Scaffold(
      appBar: AppBar(title: Text('Node debug · ${chain.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 8, children: [
            FilledButton(onPressed: controller?.start, child: const Text('Start')),
            OutlinedButton(onPressed: controller?.stop, child: const Text('Stop')),
            OutlinedButton(onPressed: controller?.restart, child: const Text('Restart')),
            OutlinedButton(
              onPressed: () => ref.invalidate(peersProvider(chain)),
              child: const Text('Refresh peers'),
            ),
          ]),
          const _Head('Local node'),
          state.when(
            data: (s) => _Facts(_localFacts(s)),
            error: (e, _) => Text('$e'),
            loading: () => const LinearProgressIndicator(),
          ),
          const _Head('Fallback'),
          Text(fallback.when(data: (d) => d.toString(), error: (e, _) => '$e', loading: () => '…')),
          const _Head('Peers'),
          _Peers(chain),
          const _Head('Detect'),
          Consumer(builder: (context, ref, _) {
            final p = ref.watch(localNodeProbeProvider(chain));
            return Text(p.when(
              data: (p) => '${p.url}: answers ${p.answers}, ours ${p.ours}, ${p.version} at ${p.height}, ready ${p.readyForTxs}',
              error: (e, _) => '$e',
              loading: () => '…',
            ));
          }),
          Consumer(builder: (context, ref, _) {
            final found = ref.watch(chainDataCandidatesProvider(chain));
            return Text(found.when(
              data: (l) => l.isEmpty
                  ? 'No other chain data found'
                  : l.map((c) => '${c.source.name} ${c.path} ${_gb(c.bytes)} usable ${c.usable} lock ${c.lock.name}').join('\n'),
              error: (e, _) => '$e',
              loading: () => '…',
            ));
          }),
          const _Head('Node info'),
          for (final url in [hostSettings.nodeUse, 'http://127.0.0.1:3413']) _Info(url),
        ],
      ),
    );
  }

  static List<(String, String)> _localFacts(LocalNodeState s) => [
    ('phase', '${s.phase.name}${s.online ? ' (online)' : ''}${s.stalled ? ' stalled' : ''}'),
    ('stage', '${s.progress?.stage.name} ${s.progress?.done}/${s.progress?.total} overall ${_pct(s.progress?.overall)}'),
    ('eta · rate', '${s.eta} · ${s.stageRate?.toStringAsFixed(1)}/s'),
    ('height', '${s.height} of ${s.networkHeight} (${s.blocksBehind} behind)'),
    ('ready · version', '${s.readyForTxs} · ${s.version}'),
    ('uptime', '${s.uptime} since ${s.startedAt}'),
    ('peers', '${s.peers}'),
    ('folder', s.dataFolder),
    ('chain data', '${s.chainDataPath} ${_gb(s.chainDataBytes)} (start ${_gb(s.chainDataBytesAtStart)}), free ${_gb(s.freeBytes)}'),
    ('flags', 'restartNeeded ${s.restartNeeded} userToml ${s.userToml} reused ${s.chainDataReused}'),
    ('failure', '${s.failure?.name} ${s.reason ?? ''}'),
  ];

  static String _pct(double? f) => f == null ? '-' : '${(f * 100).toStringAsFixed(1)} %';

  static String _gb(int? b) => b == null ? '-' : '${(b / (1 << 30)).toStringAsFixed(2)} GB';
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Facts extends StatelessWidget {
  const _Facts(this.rows);

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (k, v) in rows)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(k)),
          Expanded(child: SelectableText(v)),
        ]),
    ],
  );
}

class _Peers extends ConsumerWidget {
  const _Peers(this.chain);

  final Chain chain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(peersProvider(chain));
    final service = ref.watch(peerServiceProvider(chain)).value;
    return peers.when(
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.connected.length} connected · ${s.inbound} in · ${s.outbound} out · ${s.banned.length} banned · '
              '${service?.history.length ?? 0} samples'),
          for (final p in s.connected)
            Row(children: [
              Expanded(child: Text('${p.addr} ${p.peer.direction.name} ${p.peer.userAgent} ${p.peer.height} since ${p.firstSeen}')),
              TextButton(onPressed: () => service?.ban(p.addr), child: const Text('Ban')),
            ]),
          for (final b in s.banned)
            Row(children: [
              Expanded(child: Text('${b.addr} banned ${b.lastBanned} ${b.banReason}')),
              TextButton(onPressed: () => service?.unban(b.addr), child: const Text('Unban')),
            ]),
        ],
      ),
      error: (e, _) => Text('peers: $e'),
      loading: () => const Text('…'),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info(this.url);

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(nodeInfoProvider((url: url, preset: mainnetPreset)));
    return Text(info.when(
      data: (i) => '$url · ${i.source.name}: ${i.state?.name} at ${i.height} (${i.blocksBehind} behind), '
          '${i.version} (released ${i.releasedVersion}, update ${i.updateAvailable}), ${i.latencyMs} ms'
          '${i.latencyFromMonitor ? ' (monitor)' : ''}, up ${i.uptime24h}, ${i.peers} peers, ${i.operator}, '
          'ready ${i.readyForTxs}, tip ${i.tipTime}${i.source == NodeInfoSource.none ? ' error ${i.error}' : ''}',
      error: (e, _) => '$url: $e',
      loading: () => '$url …',
    ));
  }
}

