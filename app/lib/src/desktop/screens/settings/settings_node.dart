import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../legacy/gui_rules.dart' show isPrivateHost;
import '../../data/desk_node.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/node_view.dart';
import '../../data/tor_view.dart';
import '../../app/tour.dart';
import '../../widgets/kit.dart';
import '../../widgets/node_card.dart';
import '../onboarding/local_node_step.dart' show showLocalNodeSetupDialog, LocalNodeHow;
import 'combo.dart';
import 'dialogs.dart';
import 'local_node.dart';
import 'local_node_dialogs.dart' show showReuseChainDataDialog, fallbackAskedThisSession;
import 'prefs.dart';
import 'settings_frame.dart';

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

/// The picker's footer under the node list.
String nodeListNoteText(AppLocalizations l) => l.deskSetNodeListNote;

/// Before the local node starts: what that means for this computer. True to go on.
Future<bool> confirmLocalNode(BuildContext context) async {
  final yes = await showEDialog<bool>(
    context,
    builder: (context) {
      final ts = context.ts;
      final l = context.l10n;
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
        title: l.deskSetNodeStartTitle,
        description: l.deskSetNodeStartDesc,
        icon: EIcons.server,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(l.deskSetNodeStartLine1),
            line(l.deskSetNodeStartLine2),
            line(l.deskSetNodeStartLine3),
          ],
        ),
        actions: [
          EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop(false)),
          EButton.primary(label: l.deskSetNodeStartButton, onPressed: () => Navigator.of(context).pop(true)),
        ],
      );
    },
  );
  return yes ?? false;
}

/// The local node's state as the picker's This computer row says it.
String localNodeRowText(AppLocalizations l, LocalNodeState? s) {
  if (s == null) return l.deskSetNodeRowNotSetUp;
  return switch (s.phase) {
    LocalNodePhase.stopped => (s.chainDataBytes ?? 0) == 0 ? l.deskSetNodeRowNotSetUp : l.deskSetNodeRowStopped,
    LocalNodePhase.starting => l.deskSetNodeRowStarting,
    LocalNodePhase.syncing => s.progress?.overall == null ? l.deskSetFrameNodeSyncing : l.deskSetNodeRowSyncingPct(percent(s.progress!.overall!)),
    LocalNodePhase.synced => l.deskSetFrameNodeSynced,
    LocalNodePhase.error => s.stalled ? l.deskSetNodeRowStalled : l.deskSetNodeRowFailed,
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
        if (arg == NodeDemo.builtin || arg == NodeDemo.peers) {
      Future.microtask(() {
        final p = ref.read(settingsPrefsProvider.notifier);
        p.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      });
    }
    Future.microtask(_demoCard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.arg == NodeDemo.pickFailed && _error == null && !_pickFailedShown) {
      _pickFailedShown = true;
      _error = context.l10n.deskSetNodePortNote;
    }
  }

  bool _pickFailedShown = false;

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
    final l = context.l10n;
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
          _error = deskErrorText(e, l);
        });
        return;
      }
      if (!mounted) return;
      prefs.set(p.copyWith(builtin: true, clearTyped: true));
      setState(() => _saving = false);
      _combo.currentState?.collapse();
      showEToast(context, l.deskSetNodeLocalInUse, text: l.deskSetNodeLocalInUseText);
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
    final l = context.l10n;
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
        _error = l.deskSetNodePortNote;
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
    final l = context.l10n;
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
    // A figure measured the other way is dropped at once (shownLatency); the node is asked
    // again the new way.
    final torOn = torStateOf(st.settings, status) != TorState.off;
    ref.listen(deskProvider.select((s) => torStateOf(s.settings, s.status) != TorState.off), (was, now) {
      if (was != now && !prefs.builtin) ref.invalidate(deskNodeInfoProvider(current.url));
    });
    final released = info?.releasedVersion ?? info?.network?.releasedNodeVersion;

    final myRows = serverRows(mine, released: released, starred: true);
    final publicRows = serverRows(public, released: released, starred: false);
    final options = <ComboOption>[
      if (DeskFeatures.builtInNode) ComboOption(value: builtinNode, host: l.deskSetNodeLocalNode, sub: localNodeRowText(l, local), local: true, group: l.deskSetNodeGroupComputer),
      for (final r in myRows)
        ComboOption(
          value: r.value,
          host: r.host,
          sub: prefs.nodeLabels[r.value],
          server: r,
          group: l.deskSetNodeGroupMine,
          onStar: () {
            p.forgetNode(r.value);
            showEToast(context, l.deskSetNodeRemovedFromMine, text: r.host);
          },
        ),
      for (final r in publicRows)
        ComboOption(
          value: r.value,
          host: r.host,
          sub: r.operator,
          server: r,
          group: l.deskSetNodeGroupPublic,
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
        word: checking ? l.deskSetFrameChecking : (r.health == ServiceHealth.down ? l.deskSetNodeNotAnswering : null),
        sub: !checking && r.health != ServiceHealth.down ? (versionOld(r.version) ? l.deskSetNodeVersionOld(minNodeVersion) : nodeWord(l, r.health)) : null,
        tone: checking ? ETone.warn : nodeTone(r.health),
        height: checking ? null : r.height,
        actions: [
          if (!mine.any((n) => n.url == t))
            EIconButton(icon: EIcons.starOutline, label: l.deskSetNodeAddToMine, size: EBtnSize.inline, tabStop: false, onPressed: () => _addTyped(t)),
        ],
      );
    }

    // The word and state of the head: the same the rail shows. The down demo's mock wallet
    // still reaches its node, which would keep it Synced.
    final nodeHealth = widget.arg == NodeDemo.down ? ServiceHealth.down : status.nodeHealth;
    final NodeView view = prefs.builtin
        ? localNodeView(context.l10n, local, fallbackUrl: status.node.url)
        : remoteNodeView(context.l10n, current.url, info, health: nodeHealth, torOn: torOn);
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
            // The gap below the group stays outside the tour's target, so its ring ends at the box.
            child: Padding(
              padding: EdgeInsets.only(bottom: Sp.x8),
              child: TourTarget(
              id: 'node-server',
              child: ESetGroup(
              gap: false,
              title: l.deskSetFrameNode,
              trailing: head,
              rows: [
                ESetRow(
                  title: l.deskSetNodeServer,
                  hint: l.deskSetNodeServerHint,
                  stacked: true,
                  control: ServiceCombo(
                    key: _combo,
                    label: l.deskSetNodeServer,
                    hint: l.deskSetNodeFindHint,
                    kind: ServerKind.node,
                    options: options,
                    value: value,
                    fieldText: prefs.builtin ? l.deskSetNodeLocalNode : hostOf(current.url),
                    fieldSub: prefs.builtin ? localNodeRowText(l, local) : (prefs.nodeLabels[current.url] ?? current.operator),
                    tone: switch (view.state) {
                      EState.ok => ETone.ok,
                      EState.warn => ETone.warn,
                      EState.risk => ETone.risk,
                      EState.off => ETone.neutral,
                    },
                    busy: _saving,
                    busyLabel: l.deskSetNodeChecking,
                    error: _error,
                    openInitially: widget.arg == NodeDemo.comboOpen,
                    initialQuery: widget.arg == NodeDemo.typed || widget.arg == NodeDemo.pickFailed ? (widget.arg == NodeDemo.typed ? _demoTyped : 'bad.example:3413') : null,
                    onTyped: _onTyped,
                    typedRow: typedRow,
                    typedNote: (t) => _typedCheck?.health == ServiceHealth.down && _typed == t ? l.deskSetNodePortNote : l.deskSetNodeTypedNote,
                    emptyNote: l.deskSetNodeNoNodes,
                    listNote: nodeListNoteText(l),
                    onPicked: _pick,
                    footer: [
                      (l.deskSetNodeFooterAdd, EIcons.plus, _addTyped),
                      (l.deskSetNodeFooterDirectory, EIcons.book, (_) => showNodeDirectoryDialog(context)),
                    ],
                  ),
                ),
                if (!prefs.builtin)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5),
                    child: NodeCard(
                      url: current.url,
                      info: info,
                      health: nodeHealth,
                      torOn: torOn,
                      switchTo: best,
                      onSwitch: (t) => _useRemote(t.url),
                    ),
                  ),
                if (prefs.builtin) LocalNodePanel(initialTab: widget.arg == NodeDemo.peers ? LocalTab.peers : LocalTab.status),
                if (prefs.builtin && DeskFeatures.nodeBackground)
                  ESetRow(
                    title: l.deskSetNodeBackground,
                    hint: l.deskSetNodeBackgroundHint,
                    control: ESwitch(
                      value: prefs.nodeBackground,
                      semanticLabel: l.deskSetNodeBackground,
                      onChanged: (v) => p.set(prefs.copyWith(nodeBackground: v)),
                    ),
                  ),
              ],
            ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
