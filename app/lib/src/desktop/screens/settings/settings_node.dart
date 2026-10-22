import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../legacy/gui_rules.dart' show isPrivateHost;
import '../../data/desk_node.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/node_view.dart';
import '../../widgets/kit.dart';
import '../../widgets/node_card.dart';
import '../onboarding/local_node_step.dart' show showLocalNodeSetupDialog, LocalNodeHow;
import 'combo.dart';
import 'dialogs.dart';
import 'local_node.dart';
import 'local_node_dialogs.dart' show showReuseChainDataDialog, fallbackAskedThisSession;
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_privacy.dart';

/// Start states of Settings › Node. [behind], [old], [limited] and [down] put the node card
/// in that state through the mock node layer (the tour); [builtin] shows the local node panel.
enum NodeDemo { comboOpen, typed, pickFailed, builtin, peers, behind, old, limited, down }

/// A typed node address as a URL: as typed when it has a scheme; else https, except this
/// computer and the local network, where nodes answer plain http.
String nodeUrlOf(String typed) {
  final t = typed.trim();
  if (t.contains('://')) return t;
  final host = t.startsWith('[') ? t.substring(0, t.indexOf(']') + 1) : t.split(RegExp('[:/]')).first;
  return '${isPrivateHost(host) ? 'http' : 'https'}://$t';
}

String hostOf(String url) => url.replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/+$'), '');

/// Something typed that may be an address: a dot or a colon, no spaces.
final _addressLike = RegExp(r'^[^\s]*[.:][^\s]*$');

/// The oldest node version the wallet works well with.
const minNodeVersion = '3.6.0';

bool versionOld(String? v) {
  if (v == null) return false;
  final a = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final b = minNodeVersion.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    if (x != b[i]) return x < b[i];
  }
  return false;
}

ETone nodeTone(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => ETone.ok,
  ServiceHealth.slow || ServiceHealth.checking => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

const _portNote = 'Check the address and the port (usually 3413).';

/// The picker's footer under the node list.
const nodeListNote = 'State from status.btlabs.uk, checked every few minutes. Latency as measured from this computer.';

/// Before the local node starts: what that means for this computer. True to go on.
Future<bool> confirmLocalNode(BuildContext context) async {
  final yes = await showEDialog<bool>(
    context,
    builder: (context) {
      final ts = context.ts;
      Widget line(String text) => Padding(
        padding: EdgeInsets.only(bottom: Sp.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•', style: ts.small),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(text, style: ts.small)),
          ],
        ),
      );
      return EDialog(
        title: 'Start the local node?',
        description: 'A separate program syncs the Epic chain on this computer.',
        icon: EIcons.server,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line('Downloads the whole chain: several GB of disk space and bandwidth.'),
            line('The first sync takes hours. Until it is done the node shows Syncing.'),
            line('The firewall may ask to allow the node program.'),
          ],
        ),
        actions: [
          EButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
          EButton.primary(label: 'Start local node', onPressed: () => Navigator.of(context).pop(true)),
        ],
      );
    },
  );
  return yes ?? false;
}

/// The local node's state as the picker's This computer row says it.
String localNodeRowText(LocalNodeState? s) {
  if (s == null) return 'Not set up';
  return switch (s.phase) {
    LocalNodePhase.stopped => (s.chainDataBytes ?? 0) == 0 ? 'Not set up' : 'Stopped',
    LocalNodePhase.starting => 'Starting',
    LocalNodePhase.syncing => s.progress?.overall == null ? 'Syncing' : 'Syncing ${percent(s.progress!.overall!)}',
    LocalNodePhase.synced => 'Synced',
    LocalNodePhase.error => s.stalled ? 'Stalled' : 'Failed',
  };
}

/// The picker rows of the wallet's node list ([NodeServer]s), in the neutral order of §18.
/// [released] is the released node version when known; else the newest in the list counts.
List<ServerInfo> serverRows(List<NodeServer> nodes, {String? released, bool? starred}) {
  final heights = [for (final n in nodes) if (n.height != null && n.health != ServiceHealth.down) n.height!];
  final tip = heights.isEmpty ? null : heights.reduce((a, b) => a > b ? a : b);
  var newest = released;
  if (newest == null) {
    for (final n in nodes) {
      final v = n.version;
      if (v != null && (newest == null || (compareVersions(v, newest) ?? 0) > 0)) newest = v;
    }
  }
  final rows = [
    for (final n in nodes)
      () {
        final down = n.health == ServiceHealth.down;
        final behind = down || tip == null || n.height == null ? null : (tip - n.height!).clamp(0, 1 << 30);
        final old = n.version != null && newest != null && (compareVersions(n.version!, newest) ?? 0) < 0;
        return ServerInfo(
          value: n.url,
          host: nodeHost(n.url),
          full: hostOf(n.url),
          operator: n.operator ?? (n.label.isEmpty ? null : n.label),
          state: ServerInfo.stateFor(
            down: down,
            behind: n.health == ServiceHealth.slow ? (behind ?? 1) : behind,
            versionOld: old,
            checking: n.health == ServiceHealth.checking,
          ),
          behind: behind,
          latencyMs: n.latencyMs,
          version: n.version,
          versionOld: old,
          starred: starred,
        );
      }(),
  ];
  return neutralOrder(rows, state: (r) => r.state, latency: (r) => r.latencyMs);
}

class SettingsNodeScreen extends ConsumerStatefulWidget {
  const SettingsNodeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsNodeScreen> createState() => _SettingsNodeScreenState();
}

class _SettingsNodeScreenState extends ConsumerState<SettingsNodeScreen> {
  final _combo = GlobalKey<ServiceComboState>();
  bool _saving = false;
  String? _error;

  // The live check of a typed address.
  String _typed = '';
  NodeServer? _typedCheck;
  Timer? _debounce;

  static const _demoTyped = 'http://10.0.0.5:3413';

  @override
  void initState() {
    super.initState();
    final arg = widget.arg;
    if (arg == NodeDemo.typed) _onTyped(_demoTyped);
    if (arg == NodeDemo.pickFailed) _error = _portNote;
    if (arg == NodeDemo.builtin || arg == NodeDemo.peers) {
      Future.microtask(() {
        final p = ref.read(settingsPrefsProvider.notifier);
        p.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      });
    }
    Future.microtask(_demoCard);
  }

  /// The tour's card states, through the mock node layer; any other start puts the mock's
  /// answer back (the shots run one after another).
  void _demoCard() {
    if (!mounted) return;
    final api = ref.read(deskNodeProvider);
    final status = ref.read(deskProvider).status;
    if (api is! MockDeskNode || status == null) return;
    final url = (ref.read(settingsPrefsProvider).typedNode ?? status.node).url;
    final host = nodeHost(url);
    final before = api.infos[host];
    switch (widget.arg) {
      case NodeDemo.behind:
        api.infos[host] = mockNodeInfo(url, behind: 12, state: NodeHealthState.degraded);
      case NodeDemo.old:
        api.infos[host] = mockNodeInfo(url, version: '4.1.0', latencyMs: 1083);
      case NodeDemo.limited:
        api.infos[host] = mockNodeInfo(url, source: NodeInfoSource.limited);
      case NodeDemo.down:
        api.infos[host] = mockNodeInfo(url, state: NodeHealthState.down);
      default:
        api.infos.remove(host);
    }
    if (before != api.infos[host]) ref.invalidate(deskNodeInfoProvider(url));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTyped(String t) {
    _debounce?.cancel();
    setState(() {
      _typed = t;
      _typedCheck = null;
      _error = null;
    });
    if (!_addressLike.hasMatch(t)) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final url = nodeUrlOf(t);
      final r = await ref.read(deskApiProvider).checkNode(url);
      if (mounted && _typed == t) setState(() => _typedCheck = r);
    });
  }

  Future<void> _pick(String value) async {
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final p = ref.read(settingsPrefsProvider);
    if (value == builtinNode) {
      if (!p.builtin) {
        // The same content as the first run's Local node step (§21): nothing starts before
        // the primary action; the fallback checkbox answers D-7 for good.
        final choice = await showLocalNodeSetupDialog(context);
        if (choice == null || !mounted) return;
        if (choice.how == LocalNodeHow.existing) return _useRemote(choice.existingUrl);
        final node = ref.read(deskNodeProvider);
        final found = await node.chainDataCandidates();
        if (!mounted) return;
        if (found.isNotEmpty && await showReuseChainDataDialog(context, node) == null) return;
        if (!mounted) return;
        // Answered for good only once the node is going to start.
        await ref.read(deskFallbackProvider.notifier).set(FallbackChoice(choice.useFallback ? FallbackConsent.accepted : FallbackConsent.declined, at: DateTime.now()));
        fallbackAskedThisSession = true;
      }
      if (!mounted) return;
      setState(() {
        _saving = true;
        _error = null;
      });
      try {
        await ref.read(deskProvider.notifier).useBuiltInNode(true);
      } on Object catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = deskErrorText(e);
        });
        return;
      }
      if (!mounted) return;
      prefs.set(p.copyWith(builtin: true, clearTyped: true));
      setState(() => _saving = false);
      _combo.currentState?.collapse();
      showEToast(context, 'Local node in use', text: 'It downloads the whole chain. Needs 5 GB free.');
      return;
    }
    await _useRemote(value);
  }

  /// "Add to my nodes" with [typed] in the picker's field: the dialog starts from that address
  /// (scheme added as a pick would) and the label; Cancel puts the typed text back in the field.
  Future<void> _addTyped(String typed) async {
    final t = typed.trim();
    if (!_addressLike.hasMatch(t)) {
      await showMyNodeDialog(context, adding: true);
      return;
    }
    _combo.currentState?.collapse();
    final saved = await showMyNodeDialog(context, initial: nodeUrlOf(t), adding: true);
    if (saved != true && mounted) _combo.currentState?.keepTyped(t);
  }

  Future<void> _useRemote(String value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final url = nodeUrlOf(value);
    final known = (ref.read(deskProvider).nodes ?? const <NodeServer>[]).any((n) => n.url == url);
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted) return;
    if (r.health == ServiceHealth.down) {
      setState(() {
        _saving = false;
        _error = _portNote;
      });
      _combo.currentState?.keepTyped(hostOf(url));
      return;
    }
    await ref.read(deskProvider.notifier).useNode(url);
    if (!mounted) return;
    ref.read(settingsPrefsProvider.notifier).set(ref.read(settingsPrefsProvider).copyWith(builtin: false, typedNode: known ? null : r, clearTyped: known));
    setState(() => _saving = false);
    _combo.currentState?.collapse();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    final nodes = st.nodes;
    final status = st.status;
    if (nodes == null || status == null) {
      return const SettingsFrame(route: DeskRoute.settingsNode, child: SettingsLoading());
    }
    final p = ref.read(settingsPrefsProvider.notifier);
    final visible = nodes.where((n) => !prefs.removedNodes.contains(n.url)).toList();
    final mine = visible.where((n) => n.own).toList();
    final public = visible.where((n) => !n.own).toList();
    final current = prefs.typedNode ?? status.node;
    final value = prefs.builtin ? builtinNode : current.url;
    final local = ref.watch(deskLocalNodeProvider).value;
    final info = prefs.builtin ? null : ref.watch(deskNodeInfoProvider(current.url)).value;
    final released = info?.releasedVersion ?? info?.network?.releasedNodeVersion;

    final myRows = serverRows(mine, released: released, starred: true);
    final publicRows = serverRows(public, released: released, starred: false);
    final options = <ComboOption>[
      if (DeskFeatures.builtInNode) ComboOption(value: builtinNode, host: 'Local node', sub: localNodeRowText(local), local: true, group: 'This computer'),
      for (final r in myRows)
        ComboOption(
          value: r.value,
          host: r.host,
          sub: prefs.nodeLabels[r.value],
          server: r,
          group: 'My nodes',
          onStar: () {
            p.forgetNode(r.value);
            showEToast(context, 'Removed from my nodes', text: r.host);
          },
        ),
      for (final r in publicRows)
        ComboOption(
          value: r.value,
          host: r.host,
          sub: r.operator,
          server: r,
          group: 'Public nodes',
          onStar: () => showMyNodeDialog(context, initial: r.value, label: r.operator ?? '', adding: true),
        ),
    ];

    ComboOption? typedRow(String t) {
      if (!_addressLike.hasMatch(t)) return null;
      final r = _typedCheck;
      final checking = r == null || _typed != t;
      return ComboOption(
        value: t,
        host: hostOf(t),
        word: checking ? 'Checking…' : (r.health == ServiceHealth.down ? 'Not answering' : null),
        sub: !checking && r.health != ServiceHealth.down ? (versionOld(r.version) ? 'Version older than $minNodeVersion' : nodeWord(r.health)) : null,
        tone: checking ? ETone.warn : nodeTone(r.health),
        height: checking ? null : r.height,
        actions: [
          if (!mine.any((n) => n.url == t))
            EIconButton(icon: EIcons.starOutline, label: 'Add to my nodes', size: EBtnSize.inline, tabStop: false, onPressed: () => _addTyped(t)),
        ],
      );
    }

    // The word and state of the head: the same the rail shows.
    final NodeView view = prefs.builtin
        ? localNodeView(local, fallbackUrl: status.node.url)
        : remoteNodeView(current.url, info, health: status.nodeHealth);
    final down = view.state == EState.risk && !prefs.builtin;
    // The Switch action's target: the healthy node with the lowest latency, My nodes first.
    SwitchTarget? best;
    if (down) {
      for (final r in [...myRows, ...publicRows]) {
        if (r.state == EState.ok && r.value != current.url) {
          best = SwitchTarget(host: r.host, url: r.value);
          break;
        }
      }
    }

    final head = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(EIcons.node, size: Ctl.iconSm, color: stateColor(c, view.state)),
        SizedBox(width: Sp.x2),
        Text(view.word, style: ts.small.copyWith(color: stateColor(c, view.state), fontWeight: FontWeight.w600)),
      ],
    );

    return SettingsFrame(
      route: DeskRoute.settingsNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JumpSection(
            section: SettingsJump.node,
            child: ESetGroup(
              title: 'Node',
              trailing: head,
              rows: [
                ESetRow(
                  title: 'Node server',
                  text: 'The node the wallet reads the chain through and sends with.',
                  stacked: true,
                  control: ServiceCombo(
                    key: _combo,
                    label: 'Node server',
                    hint: 'Find or type a node address',
                    kind: ServerKind.node,
                    options: options,
                    value: value,
                    fieldText: prefs.builtin ? 'Local node' : hostOf(current.url),
                    fieldSub: prefs.builtin ? localNodeRowText(local) : (prefs.nodeLabels[current.url] ?? current.operator),
                    tone: switch (view.state) {
                      EState.ok => ETone.ok,
                      EState.warn => ETone.warn,
                      EState.risk => ETone.risk,
                      EState.off => ETone.neutral,
                    },
                    busy: _saving,
                    busyLabel: 'Checking the node…',
                    error: _error,
                    openInitially: widget.arg == NodeDemo.comboOpen,
                    initialQuery: widget.arg == NodeDemo.typed || widget.arg == NodeDemo.pickFailed ? (widget.arg == NodeDemo.typed ? _demoTyped : 'bad.example:3413') : null,
                    onTyped: _onTyped,
                    typedRow: typedRow,
                    typedNote: (t) => _typedCheck?.health == ServiceHealth.down && _typed == t ? _portNote : 'Enter uses it. The star keeps it in My nodes.',
                    emptyNote: 'No nodes to show.',
                    listNote: nodeListNote,
                    onPicked: _pick,
                    footer: [
                      ('Add to my nodes…', EIcons.plus, _addTyped),
                      ('Node directory…', EIcons.book, (_) => showNodeDirectoryDialog(context)),
                    ],
                  ),
                ),
                if (!prefs.builtin)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5),
                    child: NodeCard(
                      url: current.url,
                      info: info,
                      switchTo: best,
                      onSwitch: (t) => _useRemote(t.url),
                    ),
                  ),
                if (prefs.builtin) LocalNodePanel(initialTab: widget.arg == NodeDemo.peers ? LocalTab.peers : LocalTab.status),
                if (prefs.builtin && DeskFeatures.nodeBackground)
                  ESetRow(
                    title: 'Sync in background',
                    text: 'Keeps syncing while the app is closed.',
                    control: ESwitch(
                      value: prefs.nodeBackground,
                      semanticLabel: 'Sync in background',
                      onChanged: (v) => p.set(prefs.copyWith(nodeBackground: v)),
                    ),
                  ),
              ],
            ),
          ),
          const PrivacyGroup(),
        ],
      ),
    );
  }
}
