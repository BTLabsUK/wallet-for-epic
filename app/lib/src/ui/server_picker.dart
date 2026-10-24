/// The phone's one server picker: the node and Epicbox lists ([ServerList]), the sheets the
/// status card opens ([showNodePicker], [showEpicboxPicker]) and the "my servers" stores.
///
/// Rows come from the built-in lists merged with status.btlabs.uk's ([mergePublicNodes],
/// [mergePublicRelays]); with no answer from it the built-in rows show without health. The
/// user's list ("My nodes", "My servers") is the server in use and the ones they added by
/// hand; the public servers stay in their own list, so no row carries a control that has
/// nothing to do. Nothing switches on its own: a tap asks first, and a switch saves the
/// network choice and starts the app again on it, as Settings › Network does.
library;

import 'dart:async';
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

/// The user's nodes of a chain: public nodes they moved onto, addresses they typed and nodes the
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

/// The key of the bin on a My-list row of a typed-in server, for tests.
Key serverMenuKey(String value) => ValueKey('server-menu-$value');

/// The key of the one item in the bin's popup, for tests.
Key serverMenuItemKey(String value) => ValueKey('server-menu-item-$value');

/// The bin at the end of a My-list row of a typed-in server that is not in use: its popup's
/// one item, "Delete", deletes the server. The server in use has no bin, as it cannot go.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.value, required this.onDelete});

  final String value;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return PopupMenuButton<bool>(
      key: serverMenuKey(value),
      tooltip: l.serverMenuDelete,
      icon: Icon(Icons.delete_outline, color: t.dim),
      onSelected: (_) => onDelete(),
      itemBuilder: (context) => [
        PopupMenuItem(
          key: serverMenuItemKey(value),
          value: true,
          child: Text(l.serverMenuDelete),
        ),
      ],
    );
  }
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

/// The node or Epicbox rows of [preset]'s network in two groups. "My nodes" or "My servers"
/// is the [current] server first, then the servers the user added by hand (the stored list
/// less the public ones); "Public nodes" or "Public servers" is every public server not in
/// use. A public server is in the user's group only while it is in use, so a switch to another
/// one moves it back down by itself, and the group never needs a control to send it back. A
/// typed-in server that is not in use has a bin ([_DeleteButton]); the one in use and the
/// public rows have none: tapping a row selects it, and what a tap does can be said under each
/// head ([myNote], [publicNote]). The push relay is a public relay with a bell. Each row is one
/// 56 dp target; [selected] has the check, [current] says so. Not scrollable itself: the sheet
/// and Setup put it in their scroll.
///
/// [value]s are node URLs or relay labels (`host` or `host:port`). [query] filters the rows
/// by host or operator; [onDeleted] hears the value a bin deleted.
class ServerList extends ConsumerWidget {
  const ServerList({
    super.key,
    required this.kind,
    required this.preset,
    required this.onSelected,
    this.selected,
    this.current,
    this.query = '',
    this.myNote,
    this.publicNote,
    this.onDeleted,
  });

  final ServerKind kind;
  final NetworkPreset preset;
  final ValueChanged<String> onSelected;
  final String? selected;
  final String? current;
  final String query;

  /// One line under the "My …" head: what the group is.
  final String? myNote;

  /// One line under the "Public …" head: what a tap does.
  final String? publicNote;

  /// Called with the value of a typed-in server the user deleted, after it left the list.
  final ValueChanged<String>? onDeleted;

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

  Widget _groups(
    BuildContext context, {
    required String myHead,
    required String publicHead,
    required List<Widget> mine,
    required List<Widget> public,
    required AsyncValue<Object?> status,
  }) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.isNotEmpty) ...[
          _SectionHead(myHead, note: myNote),
          ...mine,
          const SizedBox(height: 8),
        ],
        if (public.isNotEmpty) ...[
          _SectionHead(publicHead, note: publicNote),
          ...public,
        ],
        if (mine.isEmpty && public.isEmpty && query.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l.serverNoMatch,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ),
        _HealthCaption(status: status, preset: preset),
      ],
    );
  }

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
    // The node in use first, then the typed-in ones. A public node an older list stored is
    // left to the public group unless it is the one in use.
    final stored = ref.watch(myNodesProvider(preset.chain)).value ?? const [];
    final mine = <String>[
      ?cur,
      for (final url in stored)
        if (publicOf(url) == null && !(cur != null && _sameNode(url, cur))) url,
    ];
    final mineRows = [
      for (final url in mine) (url: url, node: publicOf(url), mine: true),
    ];
    final publicRows = [
      for (final n in public)
        if (!mine.any((m) => _sameNode(m, n.url)))
          (url: n.url, node: n, mine: false),
    ];
    // The check follows the selection; the server in use keeps it while the selection (a
    // typed address, say) is in neither list.
    final selectedListed =
        selected != null &&
        [...mineRows, ...publicRows].any((r) => _sameNode(selected!, r.url));
    Widget row(({String url, PublicNode? node, bool mine}) r) {
      final s = r.node?.status ?? nodeStatusFor(listed ?? const [], r.url);
      final inUse = cur != null && _sameNode(cur, r.url);
      final isSelected = selected != null && _sameNode(selected!, r.url);
      return _NodeRow(
        key: serverRowKey(r.url),
        url: r.url,
        operator: r.node?.operator ?? s?.operator,
        status: s,
        healthUnknown: s == null && status is AsyncData,
        selected: isSelected,
        check: isSelected || (inUse && !selectedListed),
        current: inUse,
        // The bin: only a typed-in node that is not in use leaves the list.
        deletable: r.mine && r.node == null && !inUse,
        onTap: () => onSelected(r.url),
        onDelete: () async {
          await ref.read(myNodesProvider(preset.chain).notifier).remove(r.url);
          onDeleted?.call(r.url);
        },
      );
    }

    return _groups(
      context,
      myHead: l.serverMyNodes,
      publicHead: l.serverPublicNodes,
      mine: [
        for (final r in mineRows)
          if (_matches(serverHost(r.url), r.node?.operator)) row(r),
      ],
      public: [
        for (final r in publicRows)
          if (_matches(serverHost(r.url), r.node.operator)) row(r),
      ],
      status: status,
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

    final cur = current == null ? null : EpicboxRelay.parse(current!);
    final stored = ref.watch(myRelaysProvider(preset.chain)).value ?? const [];
    // The relay in use first, then the typed-in ones; a public relay an older list stored
    // stays in the public group unless it is the one in use.
    final mine = <EpicboxRelay>[
      ?cur,
      for (final v in stored)
        if (EpicboxRelay.parse(v) case final r?
            when r != cur && publicOf(r) == null)
          r,
    ];
    final sel = selected == null ? null : EpicboxRelay.parse(selected!);
    // A relay picked but in no list (Setup's own field): shown, without a bin.
    final extra = sel != null && !mine.contains(sel) && publicOf(sel) == null;
    final mineRows = [
      for (final r in mine) (relay: r, listed: publicOf(r), mine: true),
      if (extra) (relay: sel, listed: null, mine: false),
    ];
    final publicRows = [
      for (final p in public)
        if (!mine.contains(p.relay)) (relay: p.relay, listed: p, mine: false),
    ];
    final selectedListed = [...mineRows, ...publicRows].any(
      (r) => r.relay.label == selected,
    );
    Widget row(({EpicboxRelay relay, PublicRelay? listed, bool mine}) r) {
      final label = r.relay.label;
      final isCurrent = r.relay == cur;
      final operator = r.listed?.operator ?? '';
      return _RelayRow(
        key: serverRowKey(label),
        relay: r.relay,
        operator: operator.isEmpty ? r.listed?.status?.operator : operator,
        status: r.listed?.status,
        healthUnknown: r.listed?.status == null && status is AsyncData,
        isDefault: r.relay == preset.defaultRelay,
        selected: selected == label,
        check: selected == label || (isCurrent && !selectedListed),
        current: isCurrent,
        deletable: r.mine && r.listed == null && !isCurrent,
        onTap: () => onSelected(label),
        onDelete: () async {
          await ref.read(myRelaysProvider(preset.chain).notifier).remove(label);
          onDeleted?.call(label);
        },
      );
    }

    bool shown(({EpicboxRelay relay, PublicRelay? listed, bool mine}) r) =>
        _matches(r.relay.label, r.listed?.operator);
    return _groups(
      context,
      myHead: l.serverMyRelays,
      publicHead: l.serverPublicRelays,
      mine: [for (final r in mineRows.where(shown)) row(r)],
      public: [for (final r in publicRows.where(shown)) row(r)],
      status: status,
    );
  }
}

/// A caption head over a group of rows: small capitals in the dim colour, and under it the
/// optional [note], one short line in the same colour.
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.text, {this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: t.dim,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note!,
                style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
              ),
            ),
        ],
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
/// under it operator · latency · version, or "Not responding" greyed, or "Health unknown"
/// when the monitor answered without it; a bin on a typed-in node that is not in use
/// ([deletable]).
class _NodeRow extends StatelessWidget {
  const _NodeRow({
    super.key,
    required this.url,
    required this.operator,
    required this.status,
    required this.healthUnknown,
    required this.selected,
    required this.check,
    required this.current,
    required this.deletable,
    required this.onTap,
    required this.onDelete,
  });

  final String url;
  final String? operator;
  final NodeStatus? status;

  /// Whether the monitor answered and had nothing on this node: the words say so.
  final bool healthUnknown;
  final bool selected;

  /// Whether the check shows: on the selected row, and on the one in use while the selection
  /// is not in the list.
  final bool check;
  final bool current;

  /// Whether the bin shows: a typed-in node in My nodes that is not in use.
  final bool deletable;
  final VoidCallback onTap;

  /// Takes the node out of My nodes.
  final VoidCallback onDelete;

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
      if (healthUnknown) l.serverHealthNone,
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
      second: _Facts(facts: facts, style: down ? small?.copyWith(color: t.faint) : small),
      trailing: _Trailing(
        check: check,
        checkColor: s?.state == NodeHealthState.healthy ? t.ok : t.dim,
        delete: deletable ? _DeleteButton(value: url, onDelete: onDelete) : null,
      ),
    );
  }
}

/// One Epicbox relay: bars, host in mono with the `Default` tag and, on the push relay, a bell;
/// under it operator · uptime · latency, or "Health unknown" when the monitor answered
/// without it; a bin on a typed-in relay that is not in use ([deletable]).
class _RelayRow extends StatelessWidget {
  const _RelayRow({
    super.key,
    required this.relay,
    required this.operator,
    required this.status,
    required this.healthUnknown,
    required this.isDefault,
    required this.selected,
    required this.check,
    required this.current,
    required this.deletable,
    required this.onTap,
    required this.onDelete,
  });

  final EpicboxRelay relay;
  final String? operator;
  final RelayStatus? status;

  /// Whether the monitor answered and had nothing on this relay: the words say so.
  final bool healthUnknown;
  final bool isDefault;
  final bool selected;

  /// Whether the check shows, as for [_NodeRow].
  final bool check;
  final bool current;

  /// Whether the bin shows: a typed-in relay in My servers that is not in use.
  final bool deletable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
      if (healthUnknown) l.serverHealthNone,
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
      second: _Facts(facts: facts, style: small),
      trailing: _Trailing(
        check: check,
        checkColor: s != null && s.healthy ? t.ok : t.dim,
        delete: deletable
            ? _DeleteButton(value: relay.label, onDelete: onDelete)
            : null,
      ),
    );
  }
}

/// A row's second line: the facts joined by ` · `, "Not responding" in the risk colour and
/// "Current" in the text colour, bold.
class _Facts extends StatelessWidget {
  const _Facts({required this.facts, required this.style});

  final List<String> facts;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Text.rich(
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
      style: style,
    );
  }
}

/// The end of a row: the check in a 44 dp slot (20 dp beside a bin, so the checks line up),
/// then the bin when the row has one. The check is green only while the chosen server is up;
/// on one that is down or unknown it is dim, never the accent, which reads as a warning
/// beside the health colours.
class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.check,
    required this.checkColor,
    required this.delete,
  });

  final bool check;
  final Color checkColor;
  final Widget? delete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: delete != null ? 20 : 44,
        child: check ? Icon(Icons.check, size: 20, color: checkColor) : null,
      ),
      ?delete,
    ],
  );
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

/// The key of the "Other server" field at the foot of the list, for tests.
const Key serverAddFieldKey = ValueKey('server-add-field');

/// The key of the Add button beside it, for tests.
const Key serverAddKey = ValueKey('server-add');

/// The key of the line at the sheet's foot that answers an action, for tests.
const Key serverFootLineKey = ValueKey('server-foot-line');

class _ServerPickerSheetState extends ConsumerState<ServerPickerSheet> {
  final _query = TextEditingController();
  final _other = TextEditingController();
  String? _pending;
  String? _otherError;
  String? _error;
  bool _busy = false;

  /// Whether the typed node is being asked for its tip before it joins the list.
  bool _adding = false;

  /// What the last action did ("Added to My servers."), at the foot for a few seconds.
  String? _line;
  Timer? _lineTimer;

  bool get _node => widget.kind == ServerKind.node;

  @override
  void dispose() {
    _lineTimer?.cancel();
    _query.dispose();
    _other.dispose();
    super.dispose();
  }

  /// Shows [text] at the foot for a success notice's time, then takes it away.
  void _say(String text) {
    _lineTimer?.cancel();
    setState(() => _line = text);
    _lineTimer = Timer(
      noticeDuration(
        NoticeLevel.success,
        accessible: MediaQuery.accessibleNavigationOf(context),
      ),
      () {
        if (mounted) setState(() => _line = null);
      },
    );
  }

  void _pick(String value, NetworkChoice choice) {
    final current = _node ? choice.nodeUrl : choice.relay.label;
    final same = _node ? _sameNode(value, current) : value == current;
    // The keyboard (from the search or Other server field) would cover the confirm strip.
    FocusManager.instance.primaryFocus?.unfocus();
    // A tap on the server in use answers: it takes a pending choice back, or says so.
    if (same && _pending == null) _say(context.l10n.serverAlreadyInUse);
    setState(() {
      _pending = same ? null : value;
      _error = null;
    });
  }

  /// Whether [value] is already a row: public, in the user's list, or in use.
  bool _listed(String value, NetworkChoice choice) {
    if (_node) {
      final public = mergePublicNodes(
        ref.read(publicNodeStatusProvider(choice.preset)).value,
        builtIn: builtInNodesFor(choice.preset),
      );
      return [
        ...public.map((n) => n.url),
        ...?ref.read(myNodesProvider(choice.preset.chain)).value,
        choice.nodeUrl,
      ].any((u) => _sameNode(u, value));
    }
    final relay = EpicboxRelay.parse(value);
    final public = mergePublicRelays(
      ref.read(relayStatusProvider(choice.preset)).value,
      builtIn: builtInRelaysFor(choice.preset),
    );
    return public.any((p) => p.relay == relay) ||
        (ref.read(myRelaysProvider(choice.preset.chain)).value ?? const [])
            .any((v) => EpicboxRelay.parse(v) == relay) ||
        choice.relay == relay;
  }

  /// Add: the typed server joins My nodes or My servers and is offered for a switch. A node
  /// is asked for its tip first, so a typo does not get saved; one already listed is picked
  /// instead of added again.
  Future<void> _add(NetworkChoice choice) async {
    final l = context.l10n;
    final value = _node
        ? typedNodeUrl(_other.text)
        : EpicboxRelay.parse(_other.text)?.label;
    if (value == null) {
      setState(() {
        _otherError = _node ? l.serverOtherNodeInvalid : l.setupCustomRelayInvalid;
      });
      return;
    }
    if (_listed(value, choice)) {
      _other.clear();
      final current = _node ? choice.nodeUrl : choice.relay.label;
      final same = _node ? _sameNode(value, current) : value == current;
      // The server in use: nothing to switch to, and the sheet says so; another listed
      // one is picked, not added again.
      setState(() {
        _otherError = null;
        if (same) _pending = null;
      });
      if (same) {
        FocusManager.instance.primaryFocus?.unfocus();
        _say(l.serverAlreadyInUse);
      } else {
        _pick(value, choice);
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final chain = choice.preset.chain;
    if (_node) {
      setState(() {
        _adding = true;
        _otherError = null;
      });
      try {
        // The node call needs no wallet, so no data directory.
        await askNodeTip(
          ref.read(walletServiceProvider),
          ref.read(sessionProvider),
          choice.preset.config(dataDir: '', nodeUrl: value),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _adding = false;
          _otherError = l.serverTestFailed(describeError(l, error));
        });
        return;
      }
      if (!mounted) return;
      await ref.read(myNodesProvider(chain).notifier).add(value);
    } else {
      await ref
          .read(myRelaysProvider(chain).notifier)
          .add(value, inUse: choice.relay.label);
    }
    if (!mounted) return;
    _other.clear();
    setState(() {
      _adding = false;
      _otherError = null;
      _pending = value;
      _error = null;
    });
    _say(_node ? l.serverAddedNode : l.serverAddedRelay);
  }

  void _deleted(String value) {
    _say(context.l10n.serverDeleted(serverHost(value)));
    if (_pending == value) setState(() => _pending = null);
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
    final line = _line;
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
                  children: [
                    ...(_node
                        ? _nodeBody(context, choice)
                        : _relayBody(context, choice)),
                    const SizedBox(height: 16),
                    _AddField(
                      controller: _other,
                      label: _node ? l.serverOtherNode : l.serverOtherRelay,
                      error: _otherError,
                      busy: _adding,
                      onChanged: () {
                        if (_otherError != null) {
                          setState(() => _otherError = null);
                        }
                      },
                      onAdd: () => _add(choice),
                    ),
                  ],
                ),
        ),
        if (choice != null)
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (line != null) _FootLine(line),
                if (_pending != null || _error != null)
                  _ConfirmStrip(
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
              ],
            ),
          ),
        SizedBox(height: foot),
      ],
    );
  }

  List<Widget> _nodeBody(BuildContext context, NetworkChoice choice) {
    final l = context.l10n;
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
        onChanged: (_) => setState(() {}),
      ),
      ServerList(
        kind: ServerKind.node,
        preset: choice.preset,
        current: choice.nodeUrl,
        selected: _pending ?? choice.nodeUrl,
        query: _query.text,
        myNote: l.serverMyListNote,
        publicNote: l.serverPublicNote,
        onSelected: (url) => _pick(url, choice),
        onDeleted: _deleted,
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
        myNote: l.serverMyListNote,
        publicNote: l.serverPublicNote,
        onSelected: (label) => _pick(label, choice),
        onDeleted: _deleted,
      ),
    ];
  }
}

/// The "Other server" field at the foot of the list with Add beside it, 48 dp tall and always
/// enabled: an empty or malformed field answers with the error line, so the button never
/// does nothing. While a node is asked for its tip, Add shows a spinner.
class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.label,
    required this.error,
    required this.busy,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final bool busy;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: serverAddFieldKey,
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: label,
              errorText: error,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // The field is 56 dp tall: the button sits 4 dp down, centred on it.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton.tonal(
            key: serverAddKey,
            style: FilledButton.styleFrom(minimumSize: const Size(72, 48)),
            onPressed: busy ? null : onAdd,
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.serverAdd),
          ),
        ),
      ],
    );
  }
}

/// One line at the sheet's foot that says what the last action did, with a check before
/// it; read out as it appears.
class _FootLine extends StatelessWidget {
  const _FootLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      key: serverFootLineKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: t.ok),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.text),
              ),
            ),
          ],
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
