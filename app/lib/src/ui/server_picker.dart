/// The phone's one server picker: the node and Epicbox lists ([ServerList]), the sheets the
/// status card opens ([showNodePicker], [showEpicboxPicker]) and the "my nodes" store.
///
/// Rows come from the built-in lists merged with status.btlabs.uk's ([mergePublicNodes],
/// [mergePublicRelays]); with no answer from it the built-in rows show without health. Nothing
/// switches on its own: a tap asks first, and a switch saves the network choice and starts the
/// app again on it, as Settings › Network does.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../models.dart' show Chain;
import '../network.dart';
import '../server_switch.dart';
import '../providers.dart';
import '../public_servers.dart';
import '../relay_directory.dart';
import 'common.dart' show groupDigits;
import 'notices.dart';
import 'help_screen.dart' show HelpButton, HelpId;
import 'launch_screen.dart';
import 'status.dart' hide NodeStatus;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

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

/// The user's nodes of a chain: starred public nodes and addresses they typed, in the order
/// they were added.
final myNodesProvider =
    AsyncNotifierProvider.family<MyNodesNotifier, List<String>, Chain>(
      MyNodesNotifier.new,
    );

class MyNodesNotifier extends AsyncNotifier<List<String>> {
  MyNodesNotifier(this.chain);

  final Chain chain;

  @override
  Future<List<String>> build() async {
    final raw = await ref.watch(secretStoreProvider).read(myNodesKey(chain));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      return [
        if (list is List)
          for (final e in list)
            if (e is String && e.isNotEmpty) e,
      ];
    } on FormatException {
      return const [];
    }
  }

  /// Whether [url] is in the list, by host and port.
  bool has(String url) => _index(state.value ?? const [], url) >= 0;

  Future<void> add(String url) async {
    final now = await future;
    if (_index(now, url) >= 0) return;
    await _write([...now, url]);
  }

  Future<void> remove(String url) async {
    final now = await future;
    final i = _index(now, url);
    if (i < 0) return;
    await _write([...now]..removeAt(i));
  }

  Future<void> toggle(String url) async => has(url) ? remove(url) : add(url);

  Future<void> _write(List<String> list) async {
    state = AsyncData(List.unmodifiable(list));
    await ref
        .read(secretStoreProvider)
        .write(myNodesKey(chain), jsonEncode(list));
  }

  static int _index(List<String> list, String url) {
    final key = nodeKey(url) ?? url;
    return list.indexWhere((e) => (nodeKey(e) ?? e) == key);
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

/// The built-in relays of a network: the public mainnet list, else the network's own relay.
List<PublicRelay> builtInRelaysFor(NetworkPreset preset) =>
    preset.chain == Chain.mainnet
    ? builtInRelays
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

/// The node or Epicbox rows of [preset]'s network: for nodes a "My nodes" section (starred
/// and typed addresses, and the [current] node when no list has it) and the public nodes; for
/// relays the public relays. Each row is one 56 dp target; [selected] has the check, [current]
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
    final mine = ref.watch(myNodesProvider(preset.chain)).value ?? const [];
    final public = mergePublicNodes(listed, builtIn: builtInNodesFor(preset));
    PublicNode? publicOf(String url) {
      for (final n in public) {
        if (_sameNode(n.url, url)) return n;
      }
      return null;
    }

    final cur = current;
    final mineRows = [
      for (final url in mine) (url: url, node: publicOf(url), starred: true),
      if (cur != null &&
          publicOf(cur) == null &&
          !mine.any((m) => _sameNode(m, cur)))
        (url: cur, node: null, starred: false),
    ];
    final publicRows = [
      for (final n in public)
        if (!mine.any((m) => _sameNode(m, n.url)))
          (url: n.url, node: n, starred: false),
    ];
    Widget row(({String url, PublicNode? node, bool starred}) r) {
      final s = r.node?.status ?? nodeStatusFor(listed ?? const [], r.url);
      return _NodeRow(
        key: serverRowKey(r.url),
        url: r.url,
        operator: r.node?.operator ?? s?.operator,
        status: s,
        starred: r.starred,
        selected: selected != null && _sameNode(selected!, r.url),
        current: cur != null && _sameNode(cur, r.url),
        onTap: () => onSelected(r.url),
        onStar: () =>
            ref.read(myNodesProvider(preset.chain).notifier).toggle(r.url),
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
    final relays = mergePublicRelays(
      status.value,
      builtIn: builtInRelaysFor(preset),
    );
    final known = {for (final r in relays) r.relay.label};
    final extra = {
      for (final v in [current, selected])
        if (v != null && !known.contains(v) && EpicboxRelay.parse(v) != null) v,
    };
    final rows = [
      for (final r in relays)
        (relay: r.relay, operator: r.operator, status: r.status),
      for (final v in extra)
        (relay: EpicboxRelay.parse(v)!, operator: '', status: null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(l.serverPublicRelays),
        for (final r in rows)
          if (_matches(r.relay.label, r.operator))
            _RelayRow(
              key: serverRowKey(r.relay.label),
              relay: r.relay,
              operator: r.operator.isEmpty ? r.status?.operator : r.operator,
              status: r.status,
              isDefault: r.relay == preset.defaultRelay,
              selected: selected == r.relay.label,
              current: current == r.relay.label,
              onTap: () => onSelected(r.relay.label),
            ),
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

/// The frame of every row: one 56 dp target with the bars, two lines and a trailing part.
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
              color: selected ? t.accentSoft : null,
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
/// under it operator · latency · version, or "Not responding" greyed; the star.
class _NodeRow extends StatelessWidget {
  const _NodeRow({
    super.key,
    required this.url,
    required this.operator,
    required this.status,
    required this.starred,
    required this.selected,
    required this.current,
    required this.onTap,
    required this.onStar,
  });

  final String url;
  final String? operator;
  final NodeStatus? status;
  final bool starred;
  final bool selected;
  final bool current;
  final VoidCallback onTap;
  final VoidCallback onStar;

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
                    ? TextStyle(
                        color: t.accentText,
                        fontWeight: FontWeight.w600,
                      )
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
          if (selected || current)
            Icon(Icons.check, size: 20, color: t.accentText),
          IconButton(
            key: serverStarKey(url),
            tooltip: starred ? l.serverRemoveMine : l.serverAddMine,
            isSelected: starred,
            onPressed: onStar,
            icon: Icon(Icons.star_border, color: t.dim),
            selectedIcon: Icon(Icons.star, color: t.accent),
          ),
        ],
      ),
    );
  }
}

/// One Epicbox relay: bars, host in mono with the `Default` tag, under it operator · uptime ·
/// latency.
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
  });

  final EpicboxRelay relay;
  final String? operator;
  final RelayStatus? status;
  final bool isDefault;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final s = status;
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
                    ? TextStyle(
                        color: t.accentText,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
              ),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: small,
      ),
      trailing: SizedBox(
        width: 44,
        child: selected || current
            ? Icon(Icons.check, size: 20, color: t.accentText)
            : null,
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
    setState(() {
      _pending = same ? null : value;
      _error = null;
    });
  }

  Future<void> _testTyped(String url, NetworkChoice choice) async {
    final l = context.l10n;
    setState(() {
      _typed = (url: url, result: null);
      _pending = null;
    });
    ({String text, bool ok}) result;
    try {
      // The node call needs no wallet, so no data directory.
      final tip = await ref
          .read(walletServiceProvider)
          .nodeTip(
            config: choice.preset.config(dataDir: '', nodeUrl: url),
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
      // A typed address joins My nodes, so it can be found again.
      if (_node && _typed?.url == value) {
        await ref
            .read(myNodesProvider(choice.preset.chain).notifier)
            .add(value);
      }
      final nodeUrl = _node ? value : choice.nodeUrl;
      final relay = _node ? choice.relay : EpicboxRelay.parse(value);
      if (relay == null) return;
      // The open wallet moves onto the servers without locking (switchServersLive saves the
      // choice once it worked); with no wallet open the choice is saved and the app starts
      // again on it. The strip's Switch, with its caption, is the confirmation.
      final live = await widget.liveSwitch(ref, nodeUrl: nodeUrl, relay: relay);
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
    return [
      _CurrentNodeCard(choice: choice),
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

/// The strip at the sheet's foot: what a switch does, `Switch to host` and Cancel.
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
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
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: busy ? null : onCancel,
                child: Text(l.commonCancel),
              ),
              const SizedBox(width: 8),
              if (host != null)
                Expanded(
                  child: FilledButton(
                    key: serverSwitchKey,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
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
                ),
            ],
          ),
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
