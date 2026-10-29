// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../legacy/gui_rules.dart' show isPrivateHost;
import '../../../network.dart' show mainnetPreset;
import '../../../settings_file/host_settings.dart' show appConfig, shippedHostSettings;
import '../../data/desk_node.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/node_view.dart';
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
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../../settings_file/status_site.dart' show statusSiteHost;

/// Start states of Settings › Node. [behind], [old], [limited] and [down] put the node card
/// in that state through the mock node layer (the tour); [builtin] shows the local node panel.
/// The own* states show a home-network node ([ownDemoUrl]): tier 1, with owner access, its
/// peers, the Owner access dialog, syncing, and down with a public node standing in.
enum NodeDemo { comboOpen, typed, badAddress, removed, picked, pickFailed, builtin, peers, behind, old, limited, down, own, ownAccess, ownPeers, ownDialog, ownSyncing, ownDown }

/// The tour's own node.
String get ownDemoUrl => 'http://10.0.1.24:${appConfig.localNodeApiPort}'; // l10n-ok: a node address

bool _ownDemo(Object? arg) => arg is NodeDemo && arg.name.startsWith('own');

/// A typed node address as a URL: as typed when it has a scheme; else https, except this
/// computer and the local network, where nodes answer plain http.
String nodeUrlOf(String typed) {
  final t = typed.trim();
  if (t.contains('://')) return t;
  final host = t.startsWith('[') ? t.substring(0, t.indexOf(']') + 1) : t.split(RegExp('[:/]')).first;
  return '${isPrivateHost(host) ? 'http' : 'https'}://$t';
}

String hostOf(String url) => url.replaceFirst(RegExp('^https?://'), '').replaceFirst(RegExp(r'/+$'), '');

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
  ServiceHealth.checking => ETone.info,
  ServiceHealth.slow => ETone.warn,
  ServiceHealth.down => ETone.risk,
  ServiceHealth.off => ETone.neutral,
};

/// The picker's footer under the node list.
String nodeListNoteText(AppLocalizations l) => l.deskSetNodeListNote(statusSiteHost);

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

class _SettingsNodeScreenState extends ConsumerState<SettingsNodeScreen> {
  final _panel = GlobalKey<ServerListPanelState>();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final arg = widget.arg;
    if (arg == NodeDemo.builtin || arg == NodeDemo.peers) {
      Future.microtask(() {
        final p = ref.read(settingsPrefsProvider.notifier);
        p.set(ref.read(settingsPrefsProvider).copyWith(builtin: true, clearTyped: true));
      });
    }
    if (_ownDemo(arg)) Future.microtask(_demoOwn);
    Future.microtask(_demoCard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.arg == NodeDemo.pickFailed && _error == null && !_pickFailedShown) {
      _pickFailedShown = true;
      _error = context.l10n.deskSetNodePortNote('${appConfig.localNodeApiPort}');
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

  /// The tour's own-node states, through the mock node layer.
  Future<void> _demoOwn() async {
    if (!mounted) return;
    final api = ref.read(deskNodeProvider);
    if (api is! MockDeskNode) return;
    final arg = widget.arg;
    final host = nodeHost(ownDemoUrl);
    api.infos[host] = mockOwnNodeInfo(
      ownDemoUrl,
      head: switch (arg) {
        NodeDemo.ownSyncing => NodeHead.syncing,
        NodeDemo.ownDown => NodeHead.down,
        _ => NodeHead.synced,
      },
      behind: arg == NodeDemo.ownSyncing ? 12340 : 0,
    );
    api.ownStatus = arg == NodeDemo.ownSyncing
        ? OwnNodeStatus(
            at: DateTime(2026, 10, 22, 14, 2),
            syncStatus: 'txhashset_kernels_validation',
            progress: const SyncProgress(SyncStage.chainStateKernels, overall: 0.64, done: 3100000, total: 4800000),
            peers: 9,
            version: '4.1.1',
            height: mockTip - 12340,
          )
        : null;
    if (arg == NodeDemo.ownAccess || arg == NodeDemo.ownPeers || arg == NodeDemo.ownSyncing) {
      await api.addOwnerSecret(ownDemoUrl, api.ownerSecret);
    } else {
      await api.removeOwnerSecret(ownDemoUrl);
    }
    if (!mounted) return;
    final p = ref.read(settingsPrefsProvider);
    ref.read(settingsPrefsProvider.notifier).set(
      p.copyWith(builtin: false, typedNode: NodeServer(url: ownDemoUrl, label: '', health: ServiceHealth.ok, latencyMs: 6, height: mockTip, version: '4.1.1', own: true), ownFallback: {...p.ownFallback}..remove(ownDemoUrl)),
    );
    if (arg == NodeDemo.ownDown) {
      ref.read(deskFailoverProvider.notifier).moved(NodeFailover(chosen: ownDemoUrl, inUse: mainnetPreset.nodeUrl, at: DateTime(2026, 10, 22, 14, 2)));
    }
    ref.invalidate(deskNodeInfoProvider(ownDemoUrl));
    ref.invalidate(deskOwnerSecretProvider(ownDemoUrl));
  }

  /// The tour's panel states.
  ServerPanelDemo? get _panelDemo => switch (widget.arg) {
    NodeDemo.typed => ServerPanelDemo(query: 'node.example.org:${appConfig.localNodeApiPort}'), // l10n-ok: a node address
    NodeDemo.badAddress => const ServerPanelDemo(query: 'my home node', submit: true), // l10n-ok: what a user might type
    // The shipped list's last and second nodes.
    NodeDemo.removed => ServerPanelDemo(remove: shippedHostSettings.nodeServers.last.url),
    NodeDemo.picked => ServerPanelDemo(pick: shippedHostSettings.nodeServers.elementAtOrNull(1)?.url ?? shippedHostSettings.nodeUse),
    _ => null,
  };

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
        _error = l.deskSetNodePortNote('${appConfig.localNodeApiPort}');
      });
      return;
    }
    await ref.read(deskProvider.notifier).useNode(url);
    if (!mounted) return;
    ref.read(settingsPrefsProvider.notifier).set(ref.read(settingsPrefsProvider).copyWith(builtin: false, typedNode: known ? null : r, clearTyped: known));
    setState(() => _saving = false);
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

    // The word and state of the head: the same the rail shows. The down demo's mock wallet
    // still reaches its node, which would keep it Synced.
    final nodeHealth = widget.arg == NodeDemo.down ? ServiceHealth.down : status.nodeHealth;
    final NodeView view = prefs.builtin
        ? localNodeView(context.l10n, local, fallbackUrl: status.node.url)
        : own
        ? remoteNodeView(context.l10n, chosenUrl, chosenInfo, health: failover == null && nodeHealth == ServiceHealth.ok ? nodeHealth : null, mine: mine)
        : remoteNodeView(context.l10n, current.url, info, health: nodeHealth, torOn: torOn);
    final down = view.state == EState.risk && !prefs.builtin && !own;
    // The Switch action's target: the healthy listed node with the lowest latency.
    SwitchTarget? best;
    if (down) {
      for (final r in serverRows(listed, released: released)) {
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
      // The panel's facts, tiles, charts and peers table use a big screen's width.
      width: SettingsWidth.wide,
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
                  // The picker keeps a form's width; the panel under it takes the page's.
                  control: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Ctl.narrow),
                    child: ServerListPanel(
                    key: _panel,
                    kind: ServerKind.node,
                    label: l.deskSetNodeServer,
                    value: value,
                    fieldText: prefs.builtin ? l.deskSetNodeLocalNode : hostOf(current.url),
                    fieldSub: prefs.builtin
                        ? localNodeRowText(l, local)
                        : failover != null
                        ? l.deskNodeFailoverInsteadOf(nodeHost(failover.chosen))
                        : (prefs.nodeLabels[current.url] ?? current.operator),
                    tone: stateTone(view.state),
                    servers: nodePanelRows(all, released: released, labels: prefs.nodeLabels, ownLabel: (url) {
                      final c = nodeClassOf(url, mine: prefs.mineNodes.contains(url));
                      return c.own ? ownLabel(l, c, url) : null;
                    }),
                    source: nodeSource(nodes, inUse: prefs.builtin ? null : current.url),
                    // Advanced › Built-in node; the node in use stays listed.
                    local: DeskFeatures.builtInNode && advancedHas(ref, AdvancedFeature.builtInNode, keep: prefs.builtin) ? PanelLocalRow(value: builtinNode, stateText: localNodeRowText(l, local)) : null,
                    listNote: nodeListNoteText(l),
                    busy: _saving,
                    busyLabel: l.deskSetNodeChecking,
                    error: _error,
                    openInitially: widget.arg == NodeDemo.comboOpen,
                    demo: _panelDemo,
                    onChoose: _pick,
                    onTest: _test,
                  ),
                  ),
                  ),
                ),
                if (own)
                  OwnNodePanel(
                    key: ValueKey('own-$chosenUrl'),
                    url: chosenUrl,
                    health: nodeHealth,
                    initialTab: widget.arg == NodeDemo.ownPeers ? LocalTab.peers : LocalTab.status,
                    openAccess: widget.arg == NodeDemo.ownDialog,
                  ),
                if (!prefs.builtin && !own)
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
                // A listed https node the user also runs: marked as theirs, it is asked directly.
                if (!prefs.builtin && Uri.tryParse(chosenUrl)?.scheme == 'https' && !nodeClassOf(chosenUrl).local)
                  ESetRow(
                    title: l.deskOwnMine,
                    hint: l.deskOwnMineHint(statusSiteHost),
                    control: ESwitch(
                      value: mine,
                      semanticLabel: l.deskOwnMine,
                      onChanged: (v) => p.set(prefs.copyWith(mineNodes: v ? {...prefs.mineNodes, chosenUrl} : ({...prefs.mineNodes}..remove(chosenUrl)))),
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
