/// The phone's one server picker: the node and Epicbox lists ([ServerList]), the sheets the
/// status card opens ([showNodePicker], [showEpicboxPicker]) and the "my nodes" store.
///
/// Rows come from the built-in lists merged with status.btlabs.uk's ([mergePublicNodes],
/// [mergePublicRelays]); with no answer from it the built-in rows show without health. Nothing
/// switches on its own: a tap asks first, and a switch saves the network choice and starts the
/// app again on it, as Settings › Network does.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../models.dart' show Chain;
import '../network.dart';
import '../server_switch.dart';
import '../providers.dart';
import '../public_servers.dart';
import '../push_registration.dart' show PushRegistration;
import '../relay_directory.dart';
import '../net/tor_net.dart' show isLoopbackUrl;
import '../tor_routes.dart' show TorRoute, torSkipsLocalNode;
import 'common.dart' show groupDigits;
import 'notices.dart';
import 'help_screen.dart' show HelpButton, HelpId;
import 'launch_screen.dart';
import 'status.dart' hide NodeStatus;
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart' show TorWayLine;

// Providers.

/// The public nodes status.btlabs.uk lists for [NetworkPreset.statusChain], in its order.
/// Empty for usernet; an error when the site is off or does not answer.
final publicNodeStatusProvider = FutureProvider.autoDispose
    .family<List<NodeStatus>, NetworkPreset>((ref, preset) async {
      final chain = preset.statusChain;
      if (chain == null) return const [];
      ref.watch(useStatusSiteProvider);
      final directory = ref.watch(relayDirectoryProvider);
      if (directory is! NodeDirectory) throw StateError('no node directory');
      return (directory as NodeDirectory).nodes(chain);
    });

/// status.btlabs.uk's view of the chain as a whole (its tip, nodes up, last block).
final networkStatusProvider = FutureProvider.autoDispose
    .family<NetworkStatus, NetworkPreset>((ref, preset) async {
      final chain = preset.statusChain;
      if (chain == null) throw StateError('no status for ${preset.chain.name}');
      ref.watch(useStatusSiteProvider);
      final directory = ref.watch(relayDirectoryProvider);
      if (directory is! NetworkDirectory) {
        throw StateError('no network directory');
      }
      return (directory as NetworkDirectory).network(chain);
    });

/// The secret-store key of a chain's "my nodes": a JSON list of node addresses.
String myNodesKey(Chain chain) => 'app.myNodes.${chain.name}';

/// The secret-store key of a chain's "my relays": a JSON list of relay labels.
String myRelaysKey(Chain chain) => 'app.myRelays.${chain.name}';

/// The user's nodes of a chain: starred public nodes, addresses they typed and nodes the
/// wallet connected to that no list has, in the order they were added.
final myNodesProvider =
    AsyncNotifierProvider.family<MyNodesNotifier, List<String>, Chain>(
      MyNodesNotifier.new,
    );

/// The user's Epicbox relays of a chain (labels, `host` or `host:port`): every relay the wallet
/// connected to, oldest first, at most [MyRelaysNotifier.cap] of them.
final myRelaysProvider =
    AsyncNotifierProvider.family<MyRelaysNotifier, List<String>, Chain>(
      MyRelaysNotifier.new,
    );

/// [list] with at most one public entry: [inUse] when it is one of them, else the last. Custom
/// entries (those [isPublic] says no to) all stay, in their order.
List<String> keepOnePublic(
  List<String> list, {
  required String Function(String) sameKey,
  required bool Function(String) isPublic,
  String? inUse,
}) {
  final publics = [
    for (var i = 0; i < list.length; i++)
      if (isPublic(list[i])) i,
  ];
  if (publics.length < 2) return list;
  final inUseKey = inUse == null ? null : sameKey(inUse);
  final keep = publics.firstWhere(
    (i) => sameKey(list[i]) == inUseKey,
    orElse: () => publics.last,
  );
  return [
    for (var i = 0; i < list.length; i++)
      if (i == keep || !publics.contains(i)) list[i],
  ];
}

/// A list of server values kept in the secret store under [storeKey], one per [sameKey]. It
/// holds at most one public server (the one in use after a switch) and any number of custom
/// ones; what is public is told by the caller, as the public list comes from the monitor.
abstract class MyServersNotifier extends AsyncNotifier<List<String>> {
  MyServersNotifier(this.chain);

  final Chain chain;

  String get storeKey;

  /// What makes two values the same server.
  String sameKey(String value);

  /// Whether [value] is in the built-in public list of this chain (the monitor's extra servers
  /// are only known to the pickers).
  bool isBuiltInPublic(String value);

  /// The server of this chain the wallet is on, if the saved choice is for this chain.
  String? inUseOf(NetworkChoice choice);

  @override
  Future<List<String>> build() async {
    final raw = await ref.watch(secretStoreProvider).read(storeKey);
    if (raw == null) return const [];
    List<String> list;
    try {
      final decoded = jsonDecode(raw);
      list = [
        if (decoded is List)
          for (final e in decoded)
            if (e is String && e.isNotEmpty) e,
      ];
    } on FormatException {
      return const [];
    }
    // Older lists may hold several public servers: only the one in use stays among them.
    String? inUse;
    try {
      final choice = await ref.read(networkChoiceProvider.future);
      if (choice.preset.chain == chain) inUse = inUseOf(choice);
    } catch (_) {}
    return keepOnePublic(
      list,
      sameKey: sameKey,
      isPublic: isBuiltInPublic,
      inUse: inUse,
    );
  }

  /// Whether [value] is in the list.
  bool has(String value) => _index(state.value ?? const [], value) >= 0;

  /// Adds [value] last. When it is public ([isPublic], told by the caller), the public
  /// server that was in the list leaves it: a switch moves the old one back to the public
  /// list.
  Future<void> add(
    String value, {
    String? inUse,
    bool Function(String)? isPublic,
  }) async {
    final now = await future;
    var list = [...now];
    if (isPublic != null && isPublic(value)) {
      final key = sameKey(value);
      list.removeWhere((e) => sameKey(e) != key && isPublic(e));
    }
    if (_index(list, value) < 0) list = _capped([...list, value], value, inUse);
    if (listEquals(list, now)) return;
    await _write(list);
  }

  /// [list] with [value] just added, cut to the most the list may hold.
  List<String> _capped(List<String> list, String value, String? inUse) => list;

  Future<void> remove(String value) async {
    final now = await future;
    final i = _index(now, value);
    if (i < 0) return;
    await _write([...now]..removeAt(i));
  }

  Future<void> _write(List<String> list) async {
    state = AsyncData(List.unmodifiable(list));
    await ref.read(secretStoreProvider).write(storeKey, jsonEncode(list));
  }

  int _index(List<String> list, String value) {
    final key = sameKey(value);
    return list.indexWhere((e) => sameKey(e) == key);
  }
}

class MyNodesNotifier extends MyServersNotifier {
  MyNodesNotifier(super.chain);

  @override
  String get storeKey => myNodesKey(chain);

  @override
  String sameKey(String value) => nodeKey(value) ?? value;

  @override
  bool isBuiltInPublic(String value) {
    final preset = networkPresets.firstWhere((p) => p.chain == chain);
    return builtInNodesFor(preset).any((n) => _sameNode(n.url, value));
  }

  @override
  String? inUseOf(NetworkChoice choice) => choice.nodeUrl;
}

class MyRelaysNotifier extends MyServersNotifier {
  MyRelaysNotifier(super.chain);

  /// The most relays kept: past it the oldest go, never the one just added or [inUse].
  static const int cap = 6;

  /// Over [cap] the oldest others are dropped, except [value] and [inUse] (the relay the
  /// wallet is on, when it is not [value]).
  @override
  List<String> _capped(List<String> list, String value, String? inUse) {
    final keep = {sameKey(value), if (inUse != null) sameKey(inUse)};
    list = [...list];
    for (var i = 0; list.length > cap && i < list.length;) {
      if (keep.contains(sameKey(list[i]))) {
        i++;
      } else {
        list.removeAt(i);
      }
    }
    return list;
  }

  @override
  String get storeKey => myRelaysKey(chain);

  @override
  String sameKey(String value) => EpicboxRelay.parse(value)?.label ?? value;

  @override
  bool isBuiltInPublic(String value) {
    final preset = networkPresets.firstWhere((p) => p.chain == chain);
    final relay = EpicboxRelay.parse(value);
    return relay != null &&
        builtInRelaysFor(preset).any((r) => r.relay == relay);
  }

  @override
  String? inUseOf(NetworkChoice choice) => choice.relay.label;
}

/// Keeps the servers the wallet just moved onto: [nodeUrl] joins My nodes and [relay] My
/// relays, listed or not, so every server the wallet connected to can be found again. A
/// public server takes the place of the public one the list had, which goes back to the
/// public list.
Future<void> rememberServers(
  WidgetRef ref,
  NetworkPreset preset, {
  String? nodeUrl,
  EpicboxRelay? relay,
}) async {
  final chain = preset.chain;
  if (nodeUrl != null) {
    final public = mergePublicNodes(
      ref.read(publicNodeStatusProvider(preset)).value,
      builtIn: builtInNodesFor(preset),
    );
    await ref
        .read(myNodesProvider(chain).notifier)
        .add(
          nodeUrl,
          isPublic: (u) => public.any((n) => _sameNode(n.url, u)),
        );
  }
  if (relay != null) {
    final public = mergePublicRelays(
      ref.read(relayStatusProvider(preset)).value,
      builtIn: builtInRelaysFor(preset),
    );
    await ref
        .read(myRelaysProvider(chain).notifier)
        .add(
          relay.label,
          inUse: relay.label,
          isPublic: (v) {
            final r = EpicboxRelay.parse(v);
            return r != null && public.any((p) => p.relay == r);
          },
        );
  }
}

/// The built-in nodes of a network: the public mainnet list, else the network's own node.
List<PublicNode> builtInNodesFor(NetworkPreset preset) =>
    preset.chain == Chain.mainnet
    ? builtInNodes
    : [
        PublicNode(
          url: preset.nodeUrl,
          operator: preset.chain == Chain.floonet ? 'BT Labs' : '',
        ),
      ];

/// The built-in relays of a network: the public mainnet list and the push relay, else the
/// network's own relay (on floonet that is the push relay).
List<PublicRelay> builtInRelaysFor(NetworkPreset preset) =>
    preset.chain == Chain.mainnet
    ? [
        ...builtInRelays,
        const PublicRelay(
          relay: EpicboxRelay(host: PushRegistration.relayHost),
          operator: 'BT Labs',
        ),
      ]
    : [
        PublicRelay(
          relay: preset.defaultRelay,
          operator: preset.chain == Chain.floonet ? 'BT Labs' : '',
        ),
      ];

/// A node address from what the user typed: `https://` is added to a bare `host[:port]`.
/// Null unless it is an http(s) address with a dotted host or a port.
String? typedNodeUrl(String text) {
  var t = text.trim();
  if (t.isEmpty || t.contains(' ')) return null;
  if (!t.contains('://')) t = 'https://$t';
  final u = Uri.tryParse(t);
  if (u == null ||
      (u.scheme != 'https' && u.scheme != 'http') ||
      u.host.isEmpty ||
      (!u.host.contains('.') && !u.hasPort) ||
      u.userInfo.isNotEmpty ||
      u.hasQuery ||
      (u.path.isNotEmpty && u.path != '/')) {
    return null;
  }
  return u.hasPort
      ? '${u.scheme}://${u.host.toLowerCase()}:${u.port}'
      : '${u.scheme}://${u.host.toLowerCase()}';
}

bool _sameNode(String a, String b) => (nodeKey(a) ?? a) == (nodeKey(b) ?? b);

// The list.

enum ServerKind { node, relay }

/// The key of a server row, by its value (the node URL or the relay label), for tests.
Key serverRowKey(String value) => ValueKey('server-row-$value');

/// The key of a node row's star, for tests.
Key serverStarKey(String value) => ValueKey('server-star-$value');

/// The key of a My relays row's remove button, for tests.
Key serverRemoveKey(String value) => ValueKey('server-remove-$value');

/// Asks before [host] leaves My nodes ([node]) or My relays: a [public] server goes back to
/// the public list, a typed-in one is gone. True to remove.
Future<bool> _confirmRemove(
  BuildContext context, {
  required bool node,
  required bool public,
  required String host,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(node ? l.serverRemoveNodeTitle : l.serverRemoveRelayTitle),
        content: Text(
          public ? l.serverRemoveBodyPublic(host) : l.serverRemoveBodyCustom(host),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.serverRemoveConfirm),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// The health of a listed server: its bars, their colour, and the words for a screen reader.
({SignalLevel level, Color color, String word}) _health(
  BuildContext context,
  NodeHealthState? state,
) {
  final t = context.tokens;
  final l = context.l10n;
  return switch (state) {
    NodeHealthState.healthy => (
      level: SignalLevel.three,
      color: t.ok,
      word: l.serverHealthy,
    ),
    NodeHealthState.degraded => (
      level: SignalLevel.two,
      color: t.warn,
      word: l.serverDegraded,
    ),
    NodeHealthState.down => (
      level: SignalLevel.one,
      color: t.risk,
      word: l.serverNotResponding,
    ),
    _ => (level: SignalLevel.three, color: t.faint, word: l.serverHealthNone),
  };
}

/// The node or Epicbox rows of [preset]'s network: a "My nodes" or "My servers" section (the
/// user's list, and the [current] server when no list has it) and the public servers. The
/// user's list holds at most one public server (the one in use after a switch) and any number
/// of typed-in ones; a server in it shows once, there, with the star (nodes) or the bin
/// (relays) that takes it out: a public one goes back to the public list, a typed-in one is
/// gone. Neither works on the [current] one, and public-list rows have neither. The push relay is a public relay with a bell. Each row is one 56 dp target; [selected] has the check, [current]
/// says so. Not scrollable itself: the sheet and Settings › Network put it in their scroll.
///
/// [value]s are node URLs or relay labels (`host` or `host:port`). [query] filters the rows
/// by host or operator.
class ServerList extends ConsumerWidget {
  const ServerList({
    super.key,
    required this.kind,
    required this.preset,
    required this.onSelected,
    this.selected,
    this.current,
    this.query = '',
  });

  final ServerKind kind;
  final NetworkPreset preset;
  final ValueChanged<String> onSelected;
  final String? selected;
  final String? current;
  final String query;

  bool _matches(String host, String? operator) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final h = q.contains('://') ? serverHost(q) : q;
    return host.toLowerCase().contains(h) ||
        (operator ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      kind == ServerKind.node ? _nodes(context, ref) : _relays(context, ref);

  Widget _nodes(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(publicNodeStatusProvider(preset));
    final listed = status.value;
    final public = mergePublicNodes(listed, builtIn: builtInNodesFor(preset));
    PublicNode? publicOf(String url) {
      for (final n in public) {
        if (_sameNode(n.url, url)) return n;
      }
      return null;
    }

    final cur = current;
    // At most one public node in the list, whatever an older list held.
    final mine = keepOnePublic(
      ref.watch(myNodesProvider(preset.chain)).value ?? const [],
      sameKey: (u) => nodeKey(u) ?? u,
      isPublic: (u) => publicOf(u) != null,
      inUse: cur,
    );
    final mineRows = [
      for (final url in mine) (url: url, node: publicOf(url), mine: true),
      if (cur != null &&
          publicOf(cur) == null &&
          !mine.any((m) => _sameNode(m, cur)))
        (url: cur, node: null, mine: true),
    ];
    final publicRows = [
      for (final n in public)
        if (!mine.any((m) => _sameNode(m, n.url)))
          (url: n.url, node: n, mine: false),
    ];
    Widget row(({String url, PublicNode? node, bool mine}) r) {
      final s = r.node?.status ?? nodeStatusFor(listed ?? const [], r.url);
      final inUse = cur != null && _sameNode(cur, r.url);
      return _NodeRow(
        key: serverRowKey(r.url),
        url: r.url,
        operator: r.node?.operator ?? s?.operator,
        status: s,
        inMine: r.mine,
        selected: selected != null && _sameNode(selected!, r.url),
        current: inUse,
        onTap: () => onSelected(r.url),
        // Leaving My nodes asks first; the node in use stays.
        onStar: inUse
            ? null
            : () async {
                if (!await _confirmRemove(
                  context,
                  node: true,
                  public: r.node != null,
                  host: serverHost(r.url),
                )) {
                  return;
                }
                await ref
                    .read(myNodesProvider(preset.chain).notifier)
                    .remove(r.url);
              },
      );
    }

    final shownMine = [
      for (final r in mineRows)
        if (_matches(serverHost(r.url), r.node?.operator)) r,
    ];
    final shownPublic = [
      for (final r in publicRows)
        if (_matches(serverHost(r.url), r.node.operator)) r,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shownMine.isNotEmpty) ...[
          _SectionHead(l.serverMyNodes),
          for (final r in shownMine) row(r),
          const SizedBox(height: 8),
        ],
        if (shownPublic.isNotEmpty) ...[
          _SectionHead(l.serverPublicNodes),
          for (final r in shownPublic) row(r),
        ],
        _HealthCaption(status: status, preset: preset),
      ],
    );
  }

  Widget _relays(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(relayStatusProvider(preset));
    final public = mergePublicRelays(
      status.value,
      builtIn: builtInRelaysFor(preset),
    );
    PublicRelay? publicOf(EpicboxRelay relay) {
      for (final r in public) {
        if (r.relay == relay) return r;
      }
      return null;
    }

    // At most one public relay in the list, whatever an older list held.
    final mine = keepOnePublic(
      ref.watch(myRelaysProvider(preset.chain)).value ?? const [],
      sameKey: (v) => EpicboxRelay.parse(v)?.label ?? v,
      isPublic: (v) {
        final r = EpicboxRelay.parse(v);
        return r != null && publicOf(r) != null;
      },
      inUse: current,
    );
    final kept = <EpicboxRelay>{
      for (final m in mine) ?EpicboxRelay.parse(m),
    };
    final extra = <EpicboxRelay>{
      for (final v in [current, selected])
        if (v != null) ?EpicboxRelay.parse(v),
    }.where((r) => !kept.contains(r) && publicOf(r) == null);
    final mineRows = [
      for (final r in kept) (relay: r, listed: publicOf(r), removable: true),
      for (final r in extra) (relay: r, listed: null, removable: false),
    ];
    final publicRows = [
      for (final p in public)
        if (!kept.contains(p.relay))
          (relay: p.relay, listed: p, removable: false),
    ];
    Widget row(
      ({EpicboxRelay relay, PublicRelay? listed, bool removable}) r,
    ) {
      final label = r.relay.label;
      final isCurrent = current == label;
      final operator = r.listed?.operator ?? '';
      return _RelayRow(
        key: serverRowKey(label),
        relay: r.relay,
        operator: operator.isEmpty ? r.listed?.status?.operator : operator,
        status: r.listed?.status,
        isDefault: r.relay == preset.defaultRelay,
        selected: selected == label,
        current: isCurrent,
        removable: r.removable,
        onTap: () => onSelected(label),
        onRemove: isCurrent
            ? null
            : () async {
                if (!await _confirmRemove(
                  context,
                  node: false,
                  public: r.listed != null,
                  host: label,
                )) {
                  return;
                }
                await ref
                    .read(myRelaysProvider(preset.chain).notifier)
                    .remove(label);
              },
      );
    }

    bool shown(({EpicboxRelay relay, PublicRelay? listed, bool removable}) r) =>
        _matches(r.relay.label, r.listed?.operator);
    final shownMine = mineRows.where(shown).toList();
    final shownPublic = publicRows.where(shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shownMine.isNotEmpty) ...[
          _SectionHead(l.serverMyRelays),
          for (final r in shownMine) row(r),
          const SizedBox(height: 8),
        ],
        if (shownPublic.isNotEmpty) ...[
          _SectionHead(l.serverPublicRelays),
          for (final r in shownPublic) row(r),
        ],
        _HealthCaption(status: status, preset: preset),
      ],
    );
  }
}

/// A caption head over a group of rows: small capitals in the dim colour.
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: t.dim,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Under a list: a thin bar while status.btlabs.uk is asked, the "health unknown" line when it
/// did not answer, and nothing when the user turned it off or the network has no monitor.
class _HealthCaption extends ConsumerWidget {
  const _HealthCaption({required this.status, required this.preset});

  final AsyncValue<Object?> status;
  final NetworkPreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (preset.statusChain == null) return const SizedBox.shrink();
    return switch (status) {
      AsyncData() => const SizedBox.shrink(),
      AsyncError() when ref.watch(useStatusSiteProvider) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          context.l10n.serverHealthUnknown,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.tokens.dim),
        ),
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
    };
  }
}

/// The frame of every row: one 56 dp target with the bars, two lines and a trailing part. A
/// [selected] row is filled and outlined in the neutral selection tokens, never the accent or
/// a health colour: beside the health bars a gold row read as a warning.
class _RowFrame extends StatelessWidget {
  const _RowFrame({
    super.key,
    required this.bars,
    required this.first,
    required this.second,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final Widget bars;
  final Widget first;
  final Widget second;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.radiusSmall),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? t.selected : null,
              border: Border.all(
                color: selected ? t.selectedLine : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Row(
                  children: [
                    bars,
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              first,
                              const SizedBox(height: 2),
                              second,
                            ],
                          ),
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One node: bars in the monitor's health colour, host in mono and its lag (`at tip`, `−12`),
/// under it operator · latency · version, or "Not responding" greyed; the star on a My nodes
/// row, which takes it out of the list (disabled on the node in use).
class _NodeRow extends StatelessWidget {
  const _NodeRow({
    super.key,
    required this.url,
    required this.operator,
    required this.status,
    required this.inMine,
    required this.selected,
    required this.current,
    required this.onTap,
    required this.onStar,
  });

  final String url;
  final String? operator;
  final NodeStatus? status;
  final bool inMine;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  /// Takes the node out of My nodes; null on the node in use, which stays.
  final VoidCallback? onStar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final s = status;
    final health = _health(context, s?.state);
    final down = s?.state == NodeHealthState.down;
    final host = serverHost(url);
    final lag = s?.tipLag;
    final tip = down || lag == null
        ? null
        : lag <= 0
        ? (text: l.serverAtTip, words: l.serverAtTip, color: t.ok)
        : (
            text: l.serverBehindShort(groupDigits(l, lag)),
            words: l.serverBehindLabel(lag),
            color: t.warn,
          );
    final latency = s?.latencyMs;
    final version = s?.nodeVersion;
    final facts = [
      if (current) l.serverCurrent,
      if (down) l.serverNotResponding,
      if (operator != null && operator!.isNotEmpty) operator!,
      if (!down && latency != null) l.serverLatency(groupDigits(l, latency)),
      if (!down && version != null && version.isNotEmpty) version,
    ];
    final words = down ? t.faint : t.text;
    final small = theme.textTheme.bodySmall?.copyWith(color: t.dim);
    final label = l.serverRowLabel(
      host,
      [
        if (current) l.serverCurrent,
        health.word,
        if (operator != null && operator!.isNotEmpty) operator!,
        ?tip?.words,
        if (!down && latency != null) l.serverLatency(groupDigits(l, latency)),
        if (!down && version != null && version.isNotEmpty) version,
      ].join(', '),
    );
    return _RowFrame(
      bars: SignalBars(level: health.level, color: health.color),
      label: label,
      selected: selected,
      onTap: onTap,
      first: Row(
        children: [
          Flexible(
            child: Text(
              host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: t.monoFamily,
                fontSize: 13,
                color: words,
              ),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(width: 8),
            Text(
              tip.text,
              style: TextStyle(
                fontFamily: t.monoFamily,
                fontSize: 12,
                color: down ? t.faint : tip.color,
              ),
            ),
          ],
        ],
      ),
      second: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) const TextSpan(text: ' · '),
              TextSpan(
                text: facts[i],
                style: facts[i] == l.serverNotResponding
                    ? TextStyle(color: t.risk)
                    : facts[i] == l.serverCurrent
                    ? TextStyle(color: t.text, fontWeight: FontWeight.w600)
                    : null,
              ),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: down ? small?.copyWith(color: t.faint) : small,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The check is green only while the chosen server is up (the bars' word); on a
          // server that is down or unknown it is dim. Never the accent, which reads as a
          // warning beside the health colours; the favourite star keeps the brand gold.
          if (selected || current)
            Icon(
              Icons.check,
              size: 20,
              color: s?.state == NodeHealthState.healthy ? t.ok : t.dim,
            ),
          // Only a node in My nodes has the star: a public one joins the list by being
          // switched to, so a star on it would have nothing to do.
          if (inMine)
            IconButton(
              key: serverStarKey(url),
              tooltip: onStar == null
                  ? l.serverRemoveInUse
                  : l.serverRemoveMine,
              isSelected: true,
              onPressed: onStar,
              icon: Icon(Icons.star_border, color: t.dim),
              selectedIcon: Icon(Icons.star, color: t.accent),
            ),
        ],
      ),
    );
  }
}

/// One Epicbox relay: bars, host in mono with the `Default` tag and, on the push relay, a bell;
/// under it operator · uptime · latency. A [removable] row (My relays) has a remove button,
/// disabled with the reason as its tooltip when [onRemove] is null (the relay in use).
class _RelayRow extends StatelessWidget {
  const _RelayRow({
    super.key,
    required this.relay,
    required this.operator,
    required this.status,
    required this.isDefault,
    required this.selected,
    required this.current,
    required this.onTap,
    this.removable = false,
    this.onRemove,
  });

  final EpicboxRelay relay;
  final String? operator;
  final RelayStatus? status;
  final bool isDefault;
  final bool selected;
  final bool current;
  final VoidCallback onTap;
  final bool removable;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final s = status;
    final push = relay.host == PushRegistration.relayHost;
    final health = _health(
      context,
      s == null
          ? null
          : s.healthy
          ? NodeHealthState.healthy
          : NodeHealthState.down,
    );
    final down = s != null && !s.healthy;
    final uptime = s?.uptime24h;
    final latency = s?.latencyMs;
    final facts = [
      if (current) l.serverCurrent,
      if (down) l.serverNotResponding,
      if (operator != null && operator!.isNotEmpty) operator!,
      if (uptime != null)
        l.serverUptime(localDigits(l, (uptime * 100).toStringAsFixed(1))),
      if (!down && latency != null) l.serverLatency(groupDigits(l, latency)),
    ];
    final small = theme.textTheme.bodySmall?.copyWith(
      color: down ? t.faint : t.dim,
    );
    return _RowFrame(
      bars: SignalBars(level: health.level, color: health.color),
      label: l.serverRowLabel(
        relay.label,
        [
          if (isDefault) l.serverDefault,
          if (push) l.serverSupportsNotifications,
          if (!down) health.word,
          ...facts,
        ].join(', '),
      ),
      selected: selected,
      onTap: onTap,
      first: Row(
        children: [
          Flexible(
            child: Text(
              relay.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: t.monoFamily,
                fontSize: 13,
                color: down ? t.faint : t.text,
              ),
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: t.lineStrong),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.serverDefault,
                style: theme.textTheme.labelSmall?.copyWith(color: t.dim),
              ),
            ),
          ],
          if (push) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.notifications_outlined,
              size: 16,
              color: down ? t.faint : t.dim,
              semanticLabel: l.serverSupportsNotifications,
            ),
          ],
        ],
      ),
      second: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) const TextSpan(text: ' · '),
              TextSpan(
                text: facts[i],
                style: facts[i] == l.serverNotResponding
                    ? TextStyle(color: t.risk)
                    : facts[i] == l.serverCurrent
                    ? TextStyle(color: t.text, fontWeight: FontWeight.w600)
                    : null,
              ),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: small,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: removable ? 20 : 44,
            child: selected || current
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: s != null && s.healthy ? t.ok : t.dim,
                  )
                : null,
          ),
          if (removable)
            IconButton(
              key: serverRemoveKey(relay.label),
              tooltip: onRemove == null
                  ? l.serverRemoveInUse
                  : l.serverRemoveRelay,
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: t.dim),
            ),
        ],
      ),
    );
  }
}

// The sheets.

/// Opens the node picker over the current screen.
Future<void> showNodePicker(BuildContext context) =>
    _showPicker(context, ServerKind.node);

/// Opens the Epicbox picker over the current screen.
Future<void> showEpicboxPicker(BuildContext context) =>
    _showPicker(context, ServerKind.relay);

Future<void> _showPicker(BuildContext context, ServerKind kind) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scroll) =>
            ServerPickerSheet(kind: kind, scrollController: scroll),
      ),
    );

/// Starts the app again on the saved network choice, when no wallet was open to switch live.
void relaunchAfterSwitch(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
    (_) => false,
  );
}

/// The picker sheet's content: title and close, for nodes the current node's card and the
/// search field, for relays the address warning; the list; the confirm strip at the foot once
/// another server is tapped. A switch goes live through [liveSwitch]; [afterSave] runs when it
/// could not, after the choice is saved (tests replace the relaunch).
class ServerPickerSheet extends ConsumerStatefulWidget {
  const ServerPickerSheet({
    super.key,
    required this.kind,
    this.scrollController,
    this.afterSave = relaunchAfterSwitch,
    this.liveSwitch = switchServersLive,
  });

  final ServerKind kind;
  final ScrollController? scrollController;
  final void Function(BuildContext context) afterSave;

  /// Moves the open wallet onto the servers; false when no wallet is open (tests replace it).
  final Future<bool> Function(
    WidgetRef ref, {
    required String nodeUrl,
    required EpicboxRelay relay,
  })
  liveSwitch;

  @override
  ConsumerState<ServerPickerSheet> createState() => _ServerPickerSheetState();
}

/// The key of the confirm strip's Switch button, for tests.
const Key serverSwitchKey = ValueKey('server-switch');

/// The key of the "Use https://…" row, for tests.
const Key serverUseTypedKey = ValueKey('server-use-typed');

class _ServerPickerSheetState extends ConsumerState<ServerPickerSheet> {
  final _query = TextEditingController();
  final _otherRelay = TextEditingController();
  String? _pending;
  String? _relayError;
  String? _error;
  bool _busy = false;

  /// The typed node being tested or tested: its URL and the answer (null while testing).
  ({String url, ({String text, bool ok})? result})? _typed;

  bool get _node => widget.kind == ServerKind.node;

  @override
  void dispose() {
    _query.dispose();
    _otherRelay.dispose();
    super.dispose();
  }

  void _pick(String value, NetworkChoice choice) {
    final current = _node ? choice.nodeUrl : choice.relay.label;
    final same = _node ? _sameNode(value, current) : value == current;
    // The keyboard (from the search or Other server field) would cover the confirm strip.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _pending = same ? null : value;
      _error = null;
    });
  }

  Future<void> _testTyped(String url, NetworkChoice choice) async {
    final l = context.l10n;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _typed = (url: url, result: null);
      _pending = null;
    });
    ({String text, bool ok}) result;
    try {
      // The node call needs no wallet, so no data directory.
      final tip = await askNodeTip(
        ref.read(walletServiceProvider),
        ref.read(sessionProvider),
        choice.preset.config(dataDir: '', nodeUrl: url),
      );
      result = (
        text: l.serverTestAnswer(groupDigits(l, tip.height), tip.nodeVersion),
        ok: true,
      );
    } catch (error) {
      result = (text: l.serverTestFailed(describeError(l, error)), ok: false);
    }
    if (!mounted || _typed?.url != url) return;
    setState(() {
      _typed = (url: url, result: result);
      if (result.ok) _pending = url;
    });
  }

  void _useOtherRelay(NetworkChoice choice) {
    final relay = EpicboxRelay.parse(_otherRelay.text);
    setState(() {
      _relayError = relay == null ? context.l10n.setupCustomRelayInvalid : null;
    });
    if (relay != null) {
      _otherRelay.clear();
      _pick(relay.label, choice);
    }
  }

  Future<void> _switch(NetworkChoice choice) async {
    final value = _pending;
    if (value == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final nodeUrl = _node ? value : choice.nodeUrl;
      final relay = _node ? choice.relay : EpicboxRelay.parse(value);
      if (relay == null) return;
      // The open wallet moves onto the servers without locking (switchServersLive saves the
      // choice once it worked); with no wallet open the choice is saved and the app starts
      // again on it. The strip's Switch, with its caption, is the confirmation.
      final live = await widget.liveSwitch(ref, nodeUrl: nodeUrl, relay: relay);
      if (!mounted) return;
      // The picked or typed server joins My nodes or My relays, so it can be found again
      // (a live switch already did; with no wallet open it is the server the app starts on).
      await rememberServers(
        ref,
        choice.preset,
        nodeUrl: _node ? nodeUrl : null,
        relay: _node ? null : relay,
      );
      if (!mounted) return;
      if (live) {
        final host = _node ? (Uri.tryParse(nodeUrl)?.host ?? nodeUrl) : relay.label;
        Navigator.of(context).maybePop();
        ref.read(noticeProvider.notifier).show(
          context.l10n.serverSwitched(host),
          level: NoticeLevel.success,
        );
        return;
      }
      widget.afterSave(context);
      // The app usually starts again on the new server; when it does not, the sheet is idle.
      if (mounted) {
        setState(() {
          _busy = false;
          _pending = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(context.l10n, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final choice = ref.watch(networkChoiceProvider).value;
    final title = _node ? l.serverNodeTitle : l.serverEpicboxTitle;
    // The modal sheet keeps the phone's bottom inset for its content (useSafeArea covers the
    // top only) and ignores the keyboard: the foot below the strip takes the larger of the
    // gesture or navigation bar and the keyboard, so the confirm strip is always in view and
    // never under either. Android folds the bar into the keyboard's inset while it shows.
    final media = MediaQuery.of(context);
    final foot = math.max(media.padding.bottom, media.viewInsets.bottom);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
              ),
              HelpButton(_node ? HelpId.node : HelpId.epicbox),
              IconButton(
                tooltip: l.commonClose,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: choice == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: _node
                      ? _nodeBody(context, choice)
                      : _relayBody(context, choice),
                ),
        ),
        if (choice != null)
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _pending == null && _error == null
                ? const SizedBox(width: double.infinity)
                : _ConfirmStrip(
                    host: _pending == null ? null : serverHost(_pending!),
                    note: _node
                        ? l.serverNodeSwitchNote
                        : l.serverRelaySwitchNote,
                    warn: !_node,
                    error: _error,
                    busy: _busy,
                    onSwitch: () => _switch(choice),
                    onCancel: () => setState(() {
                      _pending = null;
                      _error = null;
                    }),
                  ),
          ),
        SizedBox(height: foot),
      ],
    );
  }

  List<Widget> _nodeBody(BuildContext context, NetworkChoice choice) {
    final l = context.l10n;
    final typed = typedNodeUrl(_query.text);
    final public = mergePublicNodes(
      ref.watch(publicNodeStatusProvider(choice.preset)).value,
      builtIn: builtInNodesFor(choice.preset),
    );
    final mine =
        ref.watch(myNodesProvider(choice.preset.chain)).value ?? const [];
    final known =
        typed != null &&
        ([
          ...public.map((n) => n.url),
          ...mine,
          choice.nodeUrl,
        ].any((u) => _sameNode(u, typed)));
    final test = _typed;
    final nodeLocal =
        torSkipsLocalNode && isLoopbackUrl(Uri.parse(choice.nodeUrl));
    return [
      _CurrentNodeCard(choice: choice),
      // The node over Tor, or waiting for it, as the status card says (nothing otherwise).
      if (!nodeLocal) ...[
        const SizedBox(height: 8),
        const TorWayLine(route: TorRoute.node),
      ],
      const SizedBox(height: 16),
      TextField(
        controller: _query,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l.serverSearchHint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          constraints: const BoxConstraints(minHeight: 44),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {
          if (_typed != null && _typed!.url != typedNodeUrl(_query.text)) {
            _typed = null;
          }
        }),
      ),
      if (typed != null && !known) ...[
        const SizedBox(height: 8),
        _TypedRow(
          url: typed,
          result: test?.url == typed ? test!.result : null,
          testing: test?.url == typed && test!.result == null,
          selected: _pending == typed,
          onTap: () => _testTyped(typed, choice),
        ),
      ],
      ServerList(
        kind: ServerKind.node,
        preset: choice.preset,
        current: choice.nodeUrl,
        selected: _pending ?? choice.nodeUrl,
        query: typed != null && !known ? '' : _query.text,
        onSelected: (url) => _pick(url, choice),
      ),
    ];
  }

  List<Widget> _relayBody(BuildContext context, NetworkChoice choice) {
    final l = context.l10n;
    final t = context.tokens;
    return [
      EdgeCard(
        edge: t.warn,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: t.warn),
              const SizedBox(width: 8),
              Expanded(child: Text(l.serverRelayWarning)),
            ],
          ),
        ),
      ),
      // Epicbox over Tor, or waiting for it, as the status card says (nothing otherwise).
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: TorWayLine(route: TorRoute.epicbox),
      ),
      ServerList(
        kind: ServerKind.relay,
        preset: choice.preset,
        current: choice.relay.label,
        selected: _pending ?? choice.relay.label,
        onSelected: (label) => _pick(label, choice),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _otherRelay,
        keyboardType: TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => _useOtherRelay(choice),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: l.serverOtherRelay,
          errorText: _relayError,
          border: const OutlineInputBorder(),
          suffixIcon: _otherRelay.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: l.setupCustomRelayUse,
                  icon: const Icon(Icons.check),
                  onPressed: () => _useOtherRelay(choice),
                ),
        ),
      ),
    ];
  }
}

/// The row for a typed node address: `Use https://host:port`, and once tested, its answer.
class _TypedRow extends StatelessWidget {
  const _TypedRow({
    required this.url,
    required this.result,
    required this.testing,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final ({String text, bool ok})? result;
  final bool testing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final r = result;
    final second = testing ? l.serverTesting : r?.text ?? '';
    return Semantics(
      liveRegion: true,
      child: _RowFrame(
        key: serverUseTypedKey,
        bars: SizedBox.square(
          dimension: statusGlyph,
          child: testing
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Icon(
                  r == null
                      ? Icons.add_link
                      : r.ok
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: statusGlyph,
                  color: r == null
                      ? t.dim
                      : r.ok
                      ? t.ok
                      : t.risk,
                ),
        ),
        label: [
          l.serverUseAddress(url),
          if (second.isNotEmpty) second,
        ].join(', '),
        selected: selected,
        onTap: onTap,
        first: Text(
          l.serverUseAddress(url),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: t.monoFamily,
            fontSize: 13,
            color: t.text,
          ),
        ),
        second: Text(
          second,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: r != null && !r.ok ? t.risk : t.dim),
        ),
      ),
    );
  }
}

/// The strip at the sheet's foot: what a switch does with Cancel beside it, then
/// `Switch to host` full width and 48 dp tall, the last thing above the phone's bottom edge.
class _ConfirmStrip extends StatelessWidget {
  const _ConfirmStrip({
    required this.host,
    required this.note,
    required this.warn,
    required this.error,
    required this.busy,
    required this.onSwitch,
    required this.onCancel,
  });

  final String? host;
  final String note;
  final bool warn;
  final String? error;
  final bool busy;
  final VoidCallback onSwitch;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error ?? note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: error != null
                          ? t.risk
                          : warn
                          ? t.warn
                          : t.dim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: busy ? null : onCancel,
                child: Text(l.commonCancel),
              ),
            ],
          ),
          if (host != null) ...[
            const SizedBox(height: 4),
            FilledButton(
              key: serverSwitchKey,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: busy ? null : onSwitch,
              child: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l.serverSwitchTo(host!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The node in use at the top of the node sheet: bars, host and state word; Height (with
/// `at tip`), Version, Peers and Uptime 24 h as a grid, each only when known; then the
/// monitor's view of the network and when it last checked.
class _CurrentNodeCard extends ConsumerWidget {
  const _CurrentNodeCard({required this.choice});

  final NetworkChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final wallet = watchWalletStatus(ref).node;
    final listed = ref.watch(publicNodeStatusProvider(choice.preset)).value;
    final net = ref.watch(networkStatusProvider(choice.preset)).value;
    final dirNode = nodeStatusFor(listed ?? const [], choice.nodeUrl);
    final height = wallet.tip?.height.toInt() ?? dirNode?.height;
    final tipHeight = net?.tipHeight;
    final behind = height != null && tipHeight != null
        ? (tipHeight - height).clamp(0, 1 << 31)
        : dirNode?.tipLag;
    final face = nodeNetFace(context, wallet, behind: behind);
    final version = wallet.tip?.nodeVersion.isNotEmpty == true
        ? wallet.tip!.nodeVersion
        : dirNode?.nodeVersion;
    final facts = <(String, String)>[
      if (height != null)
        (
          l.serverFactHeight,
          behind != null && behind < behindAfter
              ? l.serverHeightAtTip(groupDigits(l, height))
              : groupDigits(l, height),
        ),
      if (version != null && version.isNotEmpty) (l.serverFactVersion, version),
      if (dirNode?.peers != null)
        (l.serverFactPeers, groupDigits(l, dirNode!.peers!)),
      if (dirNode?.uptime24h != null)
        (
          l.serverFactUptime,
          '${localDigits(l, (dirNode!.uptime24h! * 100).toStringAsFixed(1))} %',
        ),
    ];
    final age = net?.tipAgeSeconds;
    final network = [
      if (net?.tipHeight != null)
        l.serverNodesAgree(groupDigits(l, net!.tipHeight!)),
      if (net?.nodesHealthy != null && net?.nodesTotal != null)
        l.serverNodesUp(net!.nodesHealthy!, net.nodesTotal!),
      if (age != null)
        age < 120
            ? l.serverLastBlockSeconds(age)
            : l.serverLastBlockMinutes(age ~/ 60),
    ];
    final checked = dirNode?.lastCheckedAt;
    final small = theme.textTheme.bodySmall?.copyWith(color: t.dim);
    final host = serverHost(choice.nodeUrl);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: [l.serverCurrent, host, face.word].join(', '),
            excludeSemantics: true,
            child: Row(
              children: [
                SignalBars(
                  level: face.level,
                  color: face.color,
                  pulse: wallet.state == NodeState.syncing,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: t.monoFamily,
                      fontSize: 14,
                      color: t.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  face.word,
                  style: theme.textTheme.bodySmall?.copyWith(color: face.color),
                ),
              ],
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final (label, value) in facts)
                      SizedBox(
                        width: w,
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: small),
                              Text(
                                value,
                                style: TextStyle(
                                  fontFamily: t.monoFamily,
                                  fontSize: 13,
                                  color: t.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (network.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(network.join(' · '), style: small),
          ],
          if (checked != null)
            Text(
              l.serverCheckedAt(localClock(l, checked.toLocal())),
              style: small,
            ),
        ],
      ),
    );
  }
}
