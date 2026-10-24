/// The node card of Settings › Node (spec §17): the remote node's word and host, its facts
/// (height, version, latency, uptime, peers, operator; four facts and a "Limited info" tag
/// when only the node itself answered), the down notice with a Switch action, then the
/// network and source lines. No spinner: a value still being fetched prints "–", and every
/// fact has a fixed two-line height so nothing jumps.
library;

import 'package:flutter/material.dart';

import '../data/desk_node.dart';
import '../data/node_view.dart';
import 'kit.dart';
import 'server_row.dart' show digitsText;
import '../desk_l10n.dart';

/// "2 min ago", "40 s ago", "3 h ago".
String ageText(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} s ago';
  if (d.inMinutes < 90) return '${d.inMinutes} min ago';
  if (d.inHours < 48) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// Why readiness is unknown: only a node that says it is older than 4.1.0 lacks `ready_for_txs`;
/// a 4.1.x node (or one whose version is unknown) simply did not answer that call in time.
String _unknownReadiness(String? version) {
  final c = version == null ? null : compareVersions(version, '4.1.0');
  return c != null && c < 0 ? 'node before 4.1.0' : 'no answer';
}

/// The network line of a directory answer: the tip, nodes and relays up, the last block.
/// With `forked` the first part becomes "Nodes disagree on the tip" (warn).
(String, bool) networkLine(NetworkStatus n) {
  final forked = n.forked == true;
  final parts = [
    if (forked) 'Nodes disagree on the tip' else if (n.tipHeight != null) 'Nodes agree on ${digitsText(n.tipHeight!)}',
    if (n.nodesHealthy != null && n.nodesTotal != null) '${n.nodesHealthy} of ${n.nodesTotal} nodes up',
    if (n.epicboxHealthy != null && n.epicboxTotal != null) '${n.epicboxHealthy} of ${n.epicboxTotal} Epicbox servers up',
    if (n.tipAgeSeconds != null) 'last block ${ageText(Duration(seconds: n.tipAgeSeconds!))}',
  ];
  return (parts.isEmpty ? '–' : parts.join(' · '), forked);
}

const String limitedNetworkLine =
    'status.btlabs.uk is not reachable. These facts come from the node itself: no tip to compare with, no uptime, no peer count.';

/// The "best" other node for the Switch action: the healthy node with the lowest latency.
class SwitchTarget {
  const SwitchTarget({required this.host, required this.url});

  final String host;
  final String url;
}

class NodeCard extends StatelessWidget {
  const NodeCard({super.key, required this.url, this.info, this.health, this.torOn = false, this.downSince, this.switchTo, this.onSwitch, this.now});

  final String url;

  /// The wallet's own view of the node: ok keeps a failed info probe from saying it is down.
  final ServiceHealth? health;

  /// Whether the Tor switch is on: a latency measured directly is not shown then.
  final bool torOn;

  /// Null while nothing has come in yet: every value prints "–".
  final NodeInfo? info;

  /// When the node stopped answering (the head's "since HH:MM").
  final DateTime? downSince;
  final SwitchTarget? switchTo;
  final ValueChanged<SwitchTarget>? onSwitch;

  /// For tests; the clock otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final i = info;
    // Only the wallet reaching the node counts here; a down of its own shows in the head and the rail.
    final v = remoteNodeView(context.l10n, url, i, health: health == ServiceHealth.ok ? health : null, downSince: downSince, torOn: torOn);
    final latency = i == null ? null : shownLatency(i, torOn: torOn);
    final where = i == null ? null : latencyWhere(i, torOn: torOn);
    final host = nodeHost(url);
    final down = v.state == EState.risk;
    final limited = i != null && i.source == NodeInfoSource.limited;
    final directory = i != null && i.source == NodeInfoSource.directory;
    final at = now ?? DateTime.now();

    final facts = <_Fact>[];
    if (limited) {
      final tipAge = i.tipTime == null ? null : at.difference(i.tipTime!);
      facts.addAll([
        _Fact('Height', i.height == null ? '–' : digitsText(i.height!), tipAge == null ? null : 'last block ${ageText(tipAge)}'),
        _Fact('Version', i.version == null ? '–' : i.version!, null),
        _Fact(
          'Accepts transactions',
          switch (i.readyForTxs) {
            true => 'Yes',
            false => 'Not yet',
            null => 'Unknown',
          },
          i.readyForTxs == null ? _unknownReadiness(i.version) : null,
          tone: i.readyForTxs == false ? EState.warn : null,
        ),
        _Fact('Latency', latency == null ? '–' : '${digitsText(latency)} ms', where),
      ]);
    } else {
      final behind = i?.blocksBehind;
      final old = i?.updateAvailable == true;
      facts.addAll([
        _Fact(
          'Height',
          i?.height == null || down ? '–' : digitsText(i!.height!),
          down ? 'no answer' : (behind == null ? null : (behind <= 0 ? 'at tip' : '${digitsText(behind)} behind')),
          tone: down ? EState.risk : (behind == null ? null : (behind <= 0 ? EState.ok : EState.warn)),
        ),
        _Fact(
          'Version',
          i?.version == null ? '–' : i!.version!,
          i?.version == null ? null : (old ? '${i!.releasedVersion} is out' : (i!.releasedVersion == null ? null : 'latest')),
          tone: old ? EState.warn : null,
        ),
        _Fact('Latency', latency == null ? '–' : '${digitsText(latency)} ms', where),
        _Fact('Uptime', i?.uptime24h == null ? '–' : '${(i!.uptime24h! * 100).toStringAsFixed(1)} %', 'last 24 h'),
        _Fact('Peers', i?.peers == null ? '–' : '${i!.peers}', down && i?.at != null ? 'at ${hhmm(i!.at)}' : null),
        _Fact('Operator', i?.operator == null ? '–' : i!.operator!, i?.listing == 'official' ? 'listed as official' : null),
      ]);
    }

    final (netLine, forked) = directory && i.network != null ? networkLine(i.network!) : (limited ? limitedNetworkLine : '–', false);
    final String? sourceLine;
    if (directory) {
      sourceLine = [
        'status.btlabs.uk, checked ${hhmm(i.at)}',
        if (where != null && !i.latencyFromMonitor) 'latency measured $where',
      ].join(' · ');
    } else if (limited) {
      sourceLine = i.directoryReachedAt == null ? null : 'Status site last reached ${hhmm(i.directoryReachedAt!)}';
    } else {
      sourceLine = null;
    }

    final detail = down && downSince != null ? 'since ${hhmm(downSince!)}' : null;
    return Semantics(
      container: true,
      label: 'Node ${v.word}: $host',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ESignalBars(v.state),
              SizedBox(width: Sp.x2),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: v.word, style: ts.body.copyWith(fontWeight: FontWeight.w600, color: stateColor(c, v.state))),
                      TextSpan(text: ' · ', style: ts.body.copyWith(color: c.faint)),
                      TextSpan(text: host, style: ts.mono(size: Fs.sm, color: c.dim)),
                      if (detail != null) ...[
                        TextSpan(text: ' · ', style: ts.body.copyWith(color: c.faint)),
                        TextSpan(text: detail, style: ts.small.copyWith(color: c.dim)),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (limited) ...[
                SizedBox(width: Sp.x2),
                const _LimitedTag(),
              ],
            ],
          ),
          SizedBox(height: Sp.x4),
          Wrap(
            spacing: 14.u,
            runSpacing: 20.u,
            children: [for (final f in facts) ConstrainedBox(constraints: BoxConstraints(minWidth: 150.u), child: f)],
          ),
          if (down && switchTo != null) ...[
            SizedBox(height: Sp.x4),
            ENotice(
              tone: ETone.risk,
              title: 'Node not answering.',
              text: 'Switch to ${switchTo!.host}, the healthiest other node?',
              actions: [
                EButton(label: 'Switch', size: EBtnSize.inline, onPressed: onSwitch == null ? null : () => onSwitch!(switchTo!)),
              ],
            ),
          ],
          SizedBox(height: Sp.x4),
          Divider(height: 1, thickness: 1, color: c.line),
          SizedBox(height: Sp.x3),
          Text(netLine, style: ts.small.copyWith(color: forked ? c.warn : c.dim)),
          if (sourceLine != null) ...[SizedBox(height: Sp.x1), Text(sourceLine, style: ts.caption.copyWith(color: c.faint))],
        ],
      ),
    );
  }
}

/// A 20 u outlined warn tag.
class _LimitedTag extends StatelessWidget {
  const _LimitedTag();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      height: 20.u,
      padding: EdgeInsets.symmetric(horizontal: Sp.x2),
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rad.xs), border: Border.all(color: c.warn.withValues(alpha: 0.6))),
      child: Text('Limited info', style: context.ts.caption.copyWith(color: c.warn, fontWeight: FontWeight.w600)),
    );
  }
}

/// Label / value / sub, a fixed two-line body so a late value never moves the others.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, this.sub, {this.tone});

  final String label;
  final String value;
  final String? sub;
  final EState? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final subColor = tone == null ? c.dim : stateColor(c, tone!);
    return Semantics(
      label: '$label: $value${sub == null ? '' : ', $sub'}',
      excludeSemantics: true,
      // At least 60 u; taller rather than cut when a large scale makes the text taller.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 60.u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ts.caption.copyWith(color: c.faint), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.u),
            Text(
              value,
              style: ts.body.copyWith(fontSize: 15.u, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()], color: c.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(sub ?? '', style: ts.caption.copyWith(color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Where [i]'s latency was measured, or null with no figure shown ([shownLatency]). While the
/// Tor switch is on ([torOn]) it is never "from this computer" for a remote node.
String? latencyWhere(NodeInfo i, {bool torOn = false}) {
  if (shownLatency(i, torOn: torOn) == null) return null;
  if (i.latencyFromMonitor) return 'from status.btlabs.uk';
  return i.latencyOverTor || (torOn && !isLocalNodeUrl(i.url)) ? 'over Tor' : 'from this computer';
}
