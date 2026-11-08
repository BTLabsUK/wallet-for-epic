// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mock_fixtures.dart';

import '../../desk_l10n.dart';
import '../../../legacy/gui_rules.dart' show isPrivateHost;
import '../../../network.dart' show mainnetPreset;
import '../../../settings_file/host_settings.dart' show appConfig, shippedHostSettings, hostSettings, localNodePortValues;
import '../../../settings_file/settings_providers.dart' show writeHostSettings;
import '../../data/desk_levels.dart' show deskLevelUiProvider;
import '../../data/desk_node.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/node_view.dart';
import '../../data/node_switch.dart';
import '../../data/tor_view.dart';
import '../../app/desk_failover.dart';
import '../../app/tour.dart';
import '../../widgets/kit.dart';
import '../../widgets/node_card.dart';
import '../../widgets/server_list_panel.dart';
import '../../widgets/server_row.dart';
import '../../data/server_lists.dart';
import '../onboarding/local_node_step.dart' show showLocalNodeSetupDialog, LocalNodeHow;
import 'local_node.dart';
import 'local_node_dialogs.dart' show showReuseChainDataDialog, fallbackAskedThisSession;
import 'own_node_panel.dart';
import 'prefs.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../../settings_file/status_site.dart' show statusSiteHost;

/// Start states of Settings › Node. [behind], [old], [limited] and [down] put the node card
/// in that state through the mock node layer (the tour); [builtin] shows the local node panel.
/// The own* states show a home-network node ([ownShotUrl]): tier 1, with owner access, its
/// peers, the Owner access dialog, syncing, and down with a public node standing in.
enum NodeShot { comboOpen, typed, badAddress, removed, picked, pickFailed, builtin, peers, behind, old, limited, down, own, ownAccess, ownPeers, ownDialog, ownSyncing, ownDown }

/// The tour's own node.
String get ownShotUrl => 'http://192.168.1.24:${appConfig.localNodeApiPort}'; // l10n-ok: a node address

bool _ownShot(Object? arg) => arg is NodeShot && arg.name.startsWith('own');

/// A typed node address as a URL: as typed when it has a scheme; else https, except this
/// computer and the local network, where nodes answer plain http.
String nodeUrlOf(String typed) {
  final t = typed.trim();
  if (t.contains('://')) return t;
  final host = t.startsWith('[') ? t.substring(0, t.indexOf(']') + 1) : t.split(RegExp('[:/]')).first;
  return '${isPrivateHost(host) ? 'http' : 'https'}://$t';
}

/// A node URL as the screens show it: host:port ([hostPort]).
String hostOf(String url) => hostPort(url);

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

/// The picker's footer under the node list.
String nodeListNoteText(AppLocalizations l) => l.deskSetNodeListNote(statusSiteHost);

/// The local node's state as the picker's This computer row says it.
String localNodeRowText(AppLocalizations l, LocalNodeState? s) {
  if (s == null) return l.deskSetNodeRowNotSetUp;
  return switch (s.phase) {
    LocalNodePhase.stopped => (s.chainDataBytes ?? 0) == 0 ? l.deskSetNodeRowNotSetUp : l.deskSetNodeRowStopped,
    LocalNodePhase.starting => l.deskSetNodeRowStarting,
    LocalNodePhase.syncing => s.progress?.overall == null ? l.deskSetFrameNodeSyncing : l.deskSetNodeRowSyncingPct(syncPercent(l, s.progress!.overall!)),
    LocalNodePhase.synced => l.deskSetFrameNodeSynced,
    LocalNodePhase.error => s.stalled ? l.deskSetNodeRowStalled : l.deskSetNodeRowFailed,
  };
}

/// The picker rows of the wallet's node list ([NodeServer]s), in the neutral order of §18.
/// [released] is the released node version when known; else the newest in the list counts.
List<ServerInfo> serverRows(List<NodeServer> nodes, {String? released}) {
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

class _SettingsNodeScreenState extends ConsumerState<SettingsNodeScreen> with _NodePicker<SettingsNodeScreen> {
  final _panel = GlobalKey<ServerListPanelState>();

  @override
  void initState() {
    super.initState();
    final arg = widget.arg;
    if (arg == NodeShot.builtin || arg == NodeShot.peers) {
      Future.microtask(() {
        final p = ref.read(settingsPrefsProvider.notifier);
        p.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      });
    }
    if (_ownShot(arg)) Future.microtask(_shotOwn);
    Future.microtask(_shotCard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.arg == NodeShot.pickFailed && _error == null && !_pickFailedShown) {
      _pickFailedShown = true;
      _error = context.l10n.deskSetNodePortNote('${appConfig.localNodeApiPort}');
    }
  }

  bool _pickFailedShown = false;

  /// The tour's card states, through the mock node layer; any other start puts the mock's
  /// answer back (the shots run one after another).
  void _shotCard() {
    if (!mounted) return;
    final api = ref.read(deskNodeProvider);
    final status = ref.read(deskProvider).status;
    if (api is! MockDeskNode || status == null) return;
    final url = (ref.read(settingsPrefsProvider).typedNode ?? status.node).url;
    final host = nodeHost(url);
    final before = api.infos[host];
    switch (widget.arg) {
      case NodeShot.behind:
        api.infos[host] = mockNodeInfo(url, behind: 12, state: NodeHealthState.degraded);
      case NodeShot.old:
        api.infos[host] = mockNodeInfo(url, version: '4.1.0', latencyMs: 1083);
      case NodeShot.limited:
        api.infos[host] = mockNodeInfo(url, source: NodeInfoSource.limited);
      case NodeShot.down:
        api.infos[host] = mockNodeInfo(url, state: NodeHealthState.down);
      default:
        api.infos.remove(host);
    }
    if (before != api.infos[host]) ref.invalidate(deskNodeInfoProvider(url));
  }

  /// The tour's own-node states, through the mock node layer.
  Future<void> _shotOwn() async {
    if (!mounted) return;
    final api = ref.read(deskNodeProvider);
    if (api is! MockDeskNode) return;
    final arg = widget.arg;
    final host = nodeHost(ownShotUrl);
    api.infos[host] = mockOwnNodeInfo(
      ownShotUrl,
      head: switch (arg) {
        NodeShot.ownSyncing => NodeHead.syncing,
        NodeShot.ownDown => NodeHead.down,
        _ => NodeHead.synced,
      },
      behind: arg == NodeShot.ownSyncing ? 12340 : 0,
    );
    api.ownStatus = arg == NodeShot.ownSyncing
        ? OwnNodeStatus(
            at: DateTime(2026, 10, 22, 14, 2),
            syncStatus: 'txhashset_kernels_validation',
            progress: const SyncProgress(SyncStage.chainStateKernels, overall: 0.64, done: 3100000, total: 4800000),
            peers: 9,
            version: mockNodeVersion,
            height: mockTip - 12340,
          )
        : null;
    if (arg == NodeShot.ownAccess || arg == NodeShot.ownPeers || arg == NodeShot.ownSyncing) {
      await api.addOwnerSecret(ownShotUrl, api.ownerSecret);
    } else {
      await api.removeOwnerSecret(ownShotUrl);
    }
    if (!mounted) return;
    final p = ref.read(settingsPrefsProvider);
    ref.read(settingsPrefsProvider.notifier).set(
      p.copyWith(builtin: false, typedNode: NodeServer(url: ownShotUrl, label: '', health: ServiceHealth.ok, latencyMs: 6, height: mockTip, version: mockNodeVersion, own: true), ownFallback: {...p.ownFallback}..remove(ownShotUrl)),
    );
    if (arg == NodeShot.ownDown) {
      ref.read(deskFailoverProvider.notifier).moved(NodeFailover(chosen: ownShotUrl, inUse: mainnetPreset.nodeUrl, at: DateTime(2026, 10, 22, 14, 2)));
    }
    ref.invalidate(deskNodeInfoProvider(ownShotUrl));
    ref.invalidate(deskOwnerSecretProvider(ownShotUrl));
  }

  /// The tour's panel states.
  ServerPanelShot? get _panelShot => switch (widget.arg) {
    NodeShot.typed => ServerPanelShot(query: 'node.example.org:${appConfig.localNodeApiPort}'), // l10n-ok: a node address
    NodeShot.badAddress => const ServerPanelShot(query: 'my home node', submit: true), // l10n-ok: what a user might type
    // The shipped list's last and second nodes.
    NodeShot.removed => ServerPanelShot(remove: shippedHostSettings.nodeServers.last.url),
    NodeShot.picked => ServerPanelShot(pick: shippedHostSettings.nodeServers.elementAtOrNull(1)?.url ?? shippedHostSettings.nodeUse),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    if (st.nodes == null || st.status == null) {
      return const SettingsFrame(route: DeskRoute.settingsNode, child: SettingsLoading());
    }
    final p = ref.read(settingsPrefsProvider.notifier);
    final m = _nodePick(downShot: widget.arg == NodeShot.down, panelKey: _panel, openInitially: widget.arg == NodeShot.comboOpen, shot: _panelShot)!;
    final (current, chosenUrl, own, switching, view) = (m.current, m.chosenUrl, m.own, m.switching, m.view);
    final down = view.state == EState.risk && !prefs.builtin && !own;
    // The Switch action's target: the healthy listed node with the lowest latency.
    SwitchTarget? best;
    if (down) {
      for (final r in serverRows(m.listed, released: m.released)) {
        if (r.state == EState.ok && r.value != current.url) {
          best = SwitchTarget(host: r.host, url: r.value);
          break;
        }
      }
    }

    return SettingsFrame(
      route: DeskRoute.settingsNode,
      // The same cap as the other sections (UD-011); only the local or own node's panel
      // (facts, tiles, charts and peers table) takes a big screen's width.
      width: prefs.builtin || own ? SettingsWidth.wide : SettingsWidth.form,
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
              title: l.deskSetNodeConnection,
              rows: [
                m.row,
                const NodeFailoverRow(),
                // A listed https node the user also runs: marked as theirs, it is asked directly.
                if (!prefs.builtin && Uri.tryParse(chosenUrl)?.scheme == 'https' && !nodeClassOf(chosenUrl).local)
                  ESetRow(
                    anchor: SetId.myNode,
                    title: l.deskOwnMine,
                    hint: l.deskOwnMineHint(statusSiteHost),
                    hintHelp: localNodeHelp(ref),
                    control: ESwitch(
                      value: m.mine,
                      semanticLabel: l.deskOwnMine,
                      onChanged: (v) => p.set(prefs.copyWith(mineNodes: v ? {...prefs.mineNodes, chosenUrl} : ({...prefs.mineNodes}..remove(chosenUrl)))),
                    ),
                  ),
              ],
            ),
            ),
            ),
          ),
          // What the node says of itself: its card, or the panel of the user's own node or of
          // the node on this computer.
          if (!(switching != null && !prefs.builtin && !own))
            ESetGroup(
              key: const ValueKey('node-status'),
              title: l.deskSetNodeStatus,
              rows: [
                if (own)
                  OwnNodePanel(
                    key: ValueKey('own-$chosenUrl'),
                    url: chosenUrl,
                    health: m.nodeHealth,
                    initialTab: widget.arg == NodeShot.ownPeers ? LocalTab.peers : LocalTab.status,
                    openAccess: widget.arg == NodeShot.ownDialog,
                  ),
                // While switching, the old node's status would read as the new one's.
                if (!prefs.builtin && !own && switching == null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5),
                    child: NodeCard(
                      url: current.url,
                      info: m.info,
                      health: m.nodeHealth,
                      torOn: m.torOn,
                      switchTo: best,
                      onSwitch: (t) => _useRemote(t.url),
                    ),
                  ),
                if (prefs.builtin) SetAnchor(id: SetId.localNode, child: LocalNodePanel(initialTab: widget.arg == NodeShot.peers ? LocalTab.peers : LocalTab.status)),
                if (prefs.builtin && DeskFeatures.nodeBackground)
                  ESetRow(
                    title: l.deskSetNodeBackground,
                    hint: l.deskSetNodeBackgroundHint,
                    hintHelp: localNodeHelp(ref),
                    control: ESwitch(
                      value: prefs.nodeBackground,
                      semanticLabel: l.deskSetNodeBackground,
                      onChanged: (v) => p.set(prefs.copyWith(nodeBackground: v)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// What the node picker shows and the Node page builds on: the node in use, the chosen one
/// while failover stands in, the switch under way and the state of the field.
typedef _NodePick = ({
  NodeServer current,
  String chosenUrl,
  bool mine,
  bool own,
  NodeSwitch? switching,
  NodeInfo? info,
  bool torOn,
  String? released,
  List<NodeServer> listed,
  ServiceHealth nodeHealth,
  NodeView view,
  Widget row,
});

/// The node picker's pick, test and switch, shared by Settings › Node and the Shallow
/// Network & privacy page ([NodeServerPicker]). While on screen it asks every listed node
/// ([DeskController.showNodes]).
mixin _NodePicker<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _saving = false;
  /// The node being switched to while [_saving] (its answer is checked first); null for the
  /// local node.
  String? _target;
  String? _error;
  late final DeskController _desk;

  @override
  void initState() {
    super.initState();
    _desk = ref.read(deskProvider.notifier);
    _desk.showNodes(true);
  }

  @override
  void dispose() {
    _desk.showNodes(false);
    super.dispose();
  }

  Future<void> _pick(String value) async {
    final l = context.l10n;
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final p = ref.read(settingsPrefsProvider);
    if (value == builtinNode) {
      if (!p.builtin) {
        // The same content as the first run's Local node step (§21): nothing starts before
        // the primary action; the fallback checkbox answers the fallback question for good.
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
        // The ports under Advanced: in settings.toml only while they differ from the defaults.
        final ports = choice.ports;
        if (ports.valid) await writeHostSettings(localNodePortValues(hostSettings, api: ports.api!, p2p: ports.p2p!));
        if (!mounted) return;
      }
      if (!mounted) return;
      setState(() {
        _saving = true;
        _target = null;
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
      showEToast(context, l.deskSetNodeLocalInUse, text: l.deskSetNodeLocalInUseText, tone: ETone.info);
      return;
    }
    await _useRemote(value);
  }

  /// Add's test: the node gives its tip, then it is kept as an own node so the wallet checks
  /// it with the others. Null when it answered, else why not.
  Future<String?> _test(String url) async {
    final l = context.l10n;
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (r.health == ServiceHealth.down) return l.deskSlNodeNoAnswer;
    // Over Tor before tor connected: the node was never asked.
    if (r.health == ServiceHealth.checking) return DeskFeatures.tor ? l.deskSlTorWait : l.deskSlNodeNoAnswer;
    await ref.read(deskProvider.notifier).addNode(NodeServer(url: url, label: r.label, health: r.health, latencyMs: r.latencyMs, height: r.height, version: r.version, own: true));
    return null;
  }

  Future<void> _useRemote(String value) async {
    final l = context.l10n;
    final url = nodeUrlOf(value);
    setState(() {
      _saving = true;
      _target = url;
      _error = null;
    });
    final known = (ref.read(deskProvider).nodes ?? const <NodeServer>[]).any((n) => n.url == url);
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted) return;
    if (r.health == ServiceHealth.down) {
      setState(() {
        _saving = false;
        _error = l.deskSetNodePortNote('${appConfig.localNodeApiPort}');
      });
      return;
    }
    try {
      await ref.read(deskProvider.notifier).useNode(url);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = deskErrorText(e, l);
      });
      return;
    }
    if (!mounted) return;
    ref.read(settingsPrefsProvider.notifier).set(ref.read(settingsPrefsProvider).copyWith(builtin: false, typedNode: known ? null : r, clearTyped: known));
    setState(() => _saving = false);
  }

  /// The picker's state and its row (Node server), worked out in build; null while the node
  /// list or the status loads. [downShot] is the tour's down node, whose mock wallet still
  /// reaches its node.
  _NodePick? _nodePick({bool downShot = false, Key? panelKey, bool openInitially = false, ServerPanelShot? shot}) {
    final l = context.l10n;
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    final nodes = st.nodes;
    final status = st.status;
    if (nodes == null || status == null) return null;
    final current = prefs.typedNode ?? status.node;
    final value = prefs.builtin ? builtinNode : current.url;
    // Node failover stands in for the chosen node this session: the field says which.
    final failover = prefs.typedNode == null ? ref.watch(deskFailoverProvider) : null;
    // The user's own node: its panel shows the chosen node, also while a public one stands in.
    final chosenUrl = failover?.chosen ?? current.url;
    final mine = prefs.mineNodes.contains(chosenUrl);
    final chosenInfo = prefs.builtin ? null : ref.watch(deskNodeInfoProvider(chosenUrl)).value;
    final own = !prefs.builtin && shownClass(chosenUrl, chosenInfo, mine: mine).own;
    final local = ref.watch(deskLocalNodeProvider).value;
    // A switch under way: the field names the node switched to and says what happens, from the
    // pick on (its answer is checked first), until the wallet runs on it. The local node then
    // stops behind it; the field says so while the node closes its files.
    final moving = ref.watch(deskNodeSwitchProvider);
    final switching = _saving
        ? NodeSwitch(_target == null ? NodeSwitchStep.starting : NodeSwitchStep.connecting, url: _target)
        : moving?.step == NodeSwitchStep.stopping
        ? null
        : moving;
    final stopping = moving?.step == NodeSwitchStep.stopping && !prefs.builtin;
    final info = prefs.builtin ? null : ref.watch(deskNodeInfoProvider(current.url)).value;
    // A figure measured the other way is dropped at once (shownLatency); the node is asked
    // again the new way.
    final torOn = torStateOf(st.settings, status) != TorState.off;
    ref.listen(deskProvider.select((s) => torStateOf(s.settings, s.status) != TorState.off), (was, now) {
      if (was != now && !prefs.builtin) ref.invalidate(deskNodeInfoProvider(current.url));
    });
    final released = info?.releasedVersion ?? info?.network?.releasedNodeVersion;
    final all = [...nodes, if (!nodes.any((n) => n.url == current.url)) current];
    final list = ref.watch(deskServerListProvider(ServerKind.node));
    final listed = list == null ? all : [for (final n in all) if (list.has(ServerKind.node, n.url)) n];

    // The word and state of the head: the same the rail shows.
    final nodeHealth = downShot ? ServiceHealth.down : status.nodeHealth;
    // An own node: the one state its panel's line shows too ([ownNodeView]), whichever node
    // stands in for it, so the field's dot never says Synced next to Not answering (#76).
    final NodeView view = prefs.builtin
        ? localNodeView(context.l10n, local, fallbackUrl: status.node.url)
        : own
        ? ownNodeView(context.l10n, chosenUrl, chosenInfo, health: nodeHealth, standIn: ref.watch(deskFailoverProvider), mine: mine)
        : remoteNodeView(context.l10n, current.url, info, health: nodeHealth, torOn: torOn);
    return (
      current: current,
      chosenUrl: chosenUrl,
      mine: mine,
      own: own,
      switching: switching,
      info: info,
      torOn: torOn,
      released: released,
      listed: listed,
      nodeHealth: nodeHealth,
      view: view,
      row: ESetRow(
        anchor: SetId.nodeServer,
        title: l.deskSetNodeServer,
        hint: l.deskSetNodeServerHint,
        stacked: true,
        // The picker keeps a form's width; the panel under it takes the page's.
        control: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Ctl.narrow),
          child: ServerListPanel(
          key: panelKey,
          kind: ServerKind.node,
          label: l.deskSetNodeServer,
          value: value,
          fieldText: switching != null
              ? (switching.url == null ? l.deskSetNodeLocalNode : hostOf(switching.url!))
              : prefs.builtin
              ? l.deskSetNodeLocalNode
              : hostOf(current.url),
          fieldSub: prefs.builtin
              ? localNodeRowText(l, local)
              : stopping
              ? nodeSwitchText(l, moving!)
              : failover != null
              ? l.deskNodeFailoverInsteadOf(nodeHost(failover.chosen))
              : (prefs.nodeLabels[current.url] ?? current.operator),
          tone: stateTone(view.state),
          state: switching != null ? EState.active : view.state,
          servers: nodePanelRows(all, released: released, labels: prefs.nodeLabels, ownLabel: (url) {
            final c = nodeClassOf(url, mine: prefs.mineNodes.contains(url));
            return c.own ? ownLabel(l, c, url) : null;
          }),
          source: nodeSource(nodes, inUse: prefs.builtin ? null : current.url),
          // Advanced › Built-in node; the node in use stays listed.
          local: (ref.watch(deskLevelUiProvider).builtInNode && advancedHas(ref, AdvancedFeature.builtInNode)) || prefs.builtin ? PanelLocalRow(value: builtinNode, stateText: localNodeRowText(l, local)) : null,
          listNote: nodeListNoteText(l),
          busy: switching != null,
          busyLabel: switching == null ? null : nodeSwitchText(l, switching),
          error: _error,
          openInitially: openInitially,
          shot: shot,
          onChoose: _pick,
          onTest: _test,
        ),
        ),
        ),
      ),
    );
  }
}

/// Settings › Node's server picker alone (the Node server row): the Shallow Network & privacy
/// page's. Nothing while the node list or the status loads.
class NodeServerPicker extends ConsumerStatefulWidget {
  const NodeServerPicker({super.key});

  @override
  ConsumerState<NodeServerPicker> createState() => _NodeServerPickerState();
}

class _NodeServerPickerState extends ConsumerState<NodeServerPicker> with _NodePicker<NodeServerPicker> {
  @override
  Widget build(BuildContext context) => _nodePick()?.row ?? const SizedBox.shrink();
}

/// Node failover: on by default, the one switch that keeps the simple app working.
class NodeFailoverRow extends ConsumerWidget {
  const NodeFailoverRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((s) => s.settings));
    return ESetRow(
      key: const ValueKey('adv-nodeFailover'),
      anchor: SetId.failover,
      title: l.deskSetNodeFailover,
      hint: l.deskSetAdvNodeFailoverHint,
      hintTitle: l.deskSetNodeFailover,
      control: ESwitch(
        value: s.advanced.nodeFailover,
        semanticLabel: l.deskSetNodeFailover,
        onChanged: (v) => ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withNodeFailover(v))),
      ),
    );
  }
}
