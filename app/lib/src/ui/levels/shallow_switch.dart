// SPDX-License-Identifier: Apache-2.0
/// Switch server on the level-1 status sheets (`status_sheets.dart`): the user's own way off a
/// node or Epicbox server that keeps failing, beside the automatic relay offer. "Switch server"
/// opens, in place, the OTHER servers of the list (the settings file's: [hostSettingsProvider]
/// for Epicbox as the offer, [serverListProvider] for nodes as failover), each named by its
/// address, never its operator, with the status site's health: healthy first; one listed down is
/// shown but cannot be picked; one not checked can (the user decides).
///
/// One tap moves. Epicbox: [acceptRelaySwitch] with the relay ([RelaySwitchNotifier.moveTo]), so
/// the sheet then shows the new address as after an accepted offer. Node: [switchServersLive]
/// with the relay in use, saved and first in the list, as a pick in the level-3 list.
///
/// No Epicbox switch while no relay may be used ([relaySwitchHold]: Kill switch, Node only,
/// Epicbox off); while Tor starts the user may still pick. In Tor only only the relays Tor
/// reaches ([relayOverTor]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart' show NetworkMode;
import '../../btlabs_onions.dart' show onionDirectoryProvider;
import '../../errors.dart';
import '../../l10n.dart';
import '../../levels/relay_switch.dart';
import '../../levels/relay_switch_providers.dart';
import '../../network.dart';
import '../../network_gate.dart';
import '../../node_failover_phone.dart';
import '../../phone_tor.dart';
import '../../providers.dart';
import '../../relay_directory.dart' show NodeHealthState, NodeStatus, RelayStatus, nodeStatusFor, relayStatusProvider;
import '../../server_list_file.dart' show operatorFor;
import '../../server_list_store.dart';
import '../../server_switch.dart';
import '../../settings.dart' show networkModeProvider;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../tor_phone.dart';
import '../../tor_routes.dart' show TorState;
import '../notices.dart';
import '../server_picker.dart' show publicNodeStatusProvider;
import '../status.dart' show serverHost;
import '../badge.dart';
import '../theme/tokens.dart';
import 'relay_down.dart';
import 'status_parts.dart';

/// The Switch server button of [kind]'s sheet, and a row of its list by the server's value (a
/// node address, a relay's label), for tests.
Key shallowSwitchKey(ServerKind kind) => ValueKey('shallow-switch-${kind.name}');
Key shallowSwitchRowKey(String value) => ValueKey('shallow-switch-row-$value');

/// What the status site says of a server, in the list's order.
enum _Health { healthy, behind, unknown, down }

typedef _Row = ({String value, String host, _Health health, RelayCandidate? relay, ServerFace face});

class ShallowServerSwitch extends ConsumerStatefulWidget {
  const ShallowServerSwitch({super.key, required this.kind, this.liveSwitch = switchServersLive});

  final ServerKind kind;

  /// The node move (tests pass a fake).
  final Future<bool> Function(WidgetRef ref, {required String nodeUrl, required EpicboxRelay relay}) liveSwitch;

  @override
  ConsumerState<ShallowServerSwitch> createState() => _ShallowServerSwitchState();
}

class _ShallowServerSwitchState extends ConsumerState<ShallowServerSwitch> {
  bool _open = false;

  /// The row being switched to.
  String? _moving;

  /// "Switched to …" after a node move, until the list opens again.
  String? _done;

  bool get _node => widget.kind == ServerKind.node;

  List<_Row> _rows() {
    final config = ref.watch(walletConfigProvider);
    final preset = ref.watch(networkChoiceProvider).value?.preset;
    if (config == null) return const [];
    final rows = <_Row>[];
    final known = [
      for (final n in (preset == null ? null : ref.watch(publicNodeStatusProvider(preset)).value) ?? const <NodeStatus>[]) (operator: n.operator, icon: n.icon),
      for (final r in (preset == null ? null : ref.watch(relayStatusProvider(preset)).value) ?? const <RelayStatus>[]) (operator: r.operator, icon: r.icon),
    ];
    if (_node) {
      final inUse = ref.watch(nodeFailoverProvider)?.inUse ?? config.nodeUrl;
      final list = ref.watch(serverListProvider((ServerKind.node, config.chain))).value?.entries ?? const [];
      final listed = preset == null ? null : ref.watch(publicNodeStatusProvider(preset)).value;
      for (final url in list) {
        if (sameServer(ServerKind.node, url, inUse)) continue;
        final health = switch (nodeStatusFor(listed ?? const <NodeStatus>[], url)?.state) {
          NodeHealthState.healthy => _Health.healthy,
          NodeHealthState.degraded => _Health.behind,
          NodeHealthState.down => _Health.down,
          _ => _Health.unknown,
        };
        final s = nodeStatusFor(listed ?? const <NodeStatus>[], url);
        final operator = operatorFor(ServerKind.node, url, listed: s?.operator);
        rows.add((
          value: url,
          host: serverHost(url),
          health: health,
          relay: null,
          face: (operator: s?.operator ?? operator, icon: serverIconFor(s?.icon, s?.operator ?? operator, known)),
        ));
      }
    } else {
      final inUse = EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
      final torOnly = netModeOf(ref.watch(networkModeProvider)) == NetworkMode.torOnly;
      final onions = onionLookupOf(ref.watch(onionDirectoryProvider));
      final listed = preset == null ? null : ref.watch(relayStatusProvider(preset)).value;
      for (final c in relayCandidatesOf(ref.watch(hostSettingsProvider).epicboxServers)) {
        if (sameServer(ServerKind.relay, c.relay.label, inUse.label)) continue;
        if (torOnly && !relayOverTor(c.relay, hasOnion: (h, p) => onions(h, p) != null)) continue;
        final health = switch (relayHealthOf(listed ?? const <RelayStatus>[], c.relay)) {
          RelayHealth.healthy => _Health.healthy,
          RelayHealth.down => _Health.down,
          RelayHealth.unknown => _Health.unknown,
        };
        final s = (listed ?? const <RelayStatus>[]).where((r) => r.relay == c.relay).firstOrNull;
        final operator = operatorFor(ServerKind.relay, c.relay.label, listed: s?.operator);
        rows.add((
          value: c.relay.label,
          host: c.name,
          health: health,
          relay: c,
          face: (operator: s?.operator ?? operator, icon: serverIconFor(s?.icon, s?.operator ?? operator, known)),
        ));
      }
    }
    // Healthy first; otherwise the list's order.
    final order = [for (var i = 0; i < rows.length; i++) i]
      ..sort((a, b) {
        final h = rows[a].health.index.compareTo(rows[b].health.index);
        return h != 0 ? h : a.compareTo(b);
      });
    return [for (final i in order) rows[i]];
  }

  Future<void> _pick(_Row row) async {
    setState(() => _moving = row.value);
    if (row.relay case final relay?) {
      final moved = await acceptRelaySwitch(context, ref, to: relay);
      if (mounted) {
        setState(() {
          _moving = null;
          if (moved) _open = false;
        });
      }
      return;
    }
    final l = context.l10n;
    try {
      final config = ref.read(walletConfigProvider);
      if (config == null) return;
      await widget.liveSwitch(
        ref,
        nodeUrl: row.value,
        relay: EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort),
      );
      if (mounted) {
        setState(() {
          _open = false;
          _done = l.serverSwitched(row.host);
        });
      }
    } on Object catch (e) {
      ref.read(noticeProvider.notifier).show(describeError(l, e), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _moving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    if (!_node) {
      final tor = ref.exists(phoneTorProvider) ? phoneTorState(ref.watch(phoneTorProvider)) : TorState.off;
      final hold = relaySwitchHold(mode: ref.watch(networkModeProvider), tor: tor, epicboxOn: NetGate.epicbox);
      // Waiting for Tor still lets the user pick: the way out must never depend on the relay.
      if (hold != null && hold != RelaySwitchHold.waitingForTor) return const SizedBox.shrink();
    }
    final rows = _open ? _rows() : const <_Row>[];
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_done != null && !_open)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(_done!, style: theme.textTheme.bodyMedium?.copyWith(color: t.ok)),
              ),
            ),
          OutlinedButton.icon(
            key: shallowSwitchKey(widget.kind),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: Icon(_open ? Icons.expand_less : Icons.swap_horiz, size: 18),
            label: Text(l.lvShellSwitchServer),
            onPressed: _moving != null
                ? null
                : () => setState(() {
                    _open = !_open;
                    _done = null;
                  }),
          ),
          if (_open) ...[
            const SizedBox(height: 4),
            if (!_node)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(l.slSwitchBody, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
              ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l.lvShellNoOtherServer, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
              ),
            for (final r in rows) _row(context, r),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _Row r) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final down = r.health == _Health.down;
    final (word, tone) = switch (r.health) {
      _Health.healthy => (l.serverHealthy, BadgeTone.ok),
      _Health.behind => (l.serverDegraded, BadgeTone.warn),
      _Health.unknown => (l.serverHealthNone, BadgeTone.neutral),
      _Health.down => (l.serverNotResponding, BadgeTone.neutral),
    };
    final busy = _moving == r.value;
    return ListTile(
      key: shallowSwitchRowKey(r.value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      minTileHeight: 52,
      horizontalTitleGap: 12,
      enabled: !down && _moving == null,
      leading: StatusServerTile(host: r.host, operator: r.face.operator, icon: r.face.icon, size: 32, dimmed: down),
      title: Text(
        r.host,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: t.monoFamily,
          color: down ? t.faint : null,
        ),
      ),
      trailing: busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EBadge(word, tone: tone, dot: true),
                if (!down) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, size: 20, color: t.dim)],
              ],
            ),
      onTap: down || _moving != null ? null : () => _pick(r),
    );
  }
}
