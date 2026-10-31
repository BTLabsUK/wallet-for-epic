// SPDX-License-Identifier: Apache-2.0
/// The local node panel of Settings › Node: the Status and Peers tabs, the
/// controls, the sync bar and step strip, the notices of every phase, the tiles, and the rows
/// under the panel (start with the app, the fallback while syncing, the data folder, the chain
/// data). Everything goes through [DeskNodeApi]; nothing here starts a node or downloads
/// anything without the user pressing Start.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../data/desk_node.dart';
import '../../../network_gate.dart' show NetBlockByMode;
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/net_mode_view.dart';
import '../../data/node_view.dart';
import '../../widgets/kit.dart';
import '../../../help/help_content.dart' show HelpId;
import 'help_pairing.dart' show HelpAt;
import 'local_node_dialogs.dart';
import 'local_node_peers.dart';
import '../../../settings_file/host_settings.dart' show hostSettings;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import 'own_node_panel.dart' show nodePanelWideFrom, nodeChartHeight;

enum LocalTab { status, peers }

/// Starts the node at launch (the switch under the panel).
final localAutostartProvider = FutureProvider.autoDispose<bool>((ref) => ref.watch(deskNodeProvider).startWithApp());

/// The node's peer options (preferred peers, the two maxima).
final localNodeOptionsProvider = FutureProvider.autoDispose<NodeTomlOptions>((ref) => ref.watch(deskNodeProvider).options());

/// The host of the fallback node as the rows print it (no port).
String fallbackHost(FallbackChoice? c) => nodeHost(c?.nodeUrl ?? defaultFallbackNodeUrl);

/// A sample of the Status tab's tiles, every 30 s while the tab is open.
class _Sample {
  const _Sample(this.at, this.value);

  final DateTime at;
  final double value;
}

/// How often the tiles sample while the page is open.
const Duration tileSampleEvery = Duration(seconds: 30);

class LocalNodePanel extends ConsumerStatefulWidget {
  const LocalNodePanel({super.key, this.initialTab = LocalTab.status, this.clock});

  final LocalTab initialTab;

  /// For tests; the clock otherwise.
  final DateTime Function()? clock;

  @override
  ConsumerState<LocalNodePanel> createState() => _LocalNodePanelState();
}

class _LocalNodePanelState extends ConsumerState<LocalNodePanel> {
  late LocalTab _tab = widget.initialTab;

  /// The control pressed and still running: 'start', 'stop' or 'restart'.
  String? _busy;
  Timer? _sampler;
  final List<_Sample> _sync = [];
  final List<_Sample> _download = [];
  final List<_Sample> _disk = [];

  /// A folder move in progress: bytes done and total.
  (int, int)? _moving;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _sampler = Timer.periodic(tileSampleEvery, (_) => _sample());
    WidgetsBinding.instance.addPostFrameCallback((_) => _sample());
  }

  @override
  void dispose() {
    _sampler?.cancel();
    super.dispose();
  }

  void _sample() {
    if (!mounted) return;
    final s = ref.read(deskLocalNodeProvider).value;
    if (s == null) return;
    final at = _now;
    void push(List<_Sample> l, double? v) {
      if (v == null) return;
      l.add(_Sample(at, v));
      if (l.length > 120) l.removeAt(0);
    }

    push(_sync, s.progress?.overall);
    push(_download, s.stageRate);
    push(_disk, s.chainDataBytes?.toDouble());
    setState(() {});
  }

  Future<void> _run(String what, Future<void> Function() go) async {
    setState(() => _busy = what);
    try {
      await go();
    } on Object catch (e) {
      logWarn('desk', 'built-in node $what failed: $e');
      if (mounted) {
        final l = context.l10n;
        showEToast(context, switch (what) {
          'start' => l.deskSetLnodeDidNotStart,
          'stop' => l.deskSetLnodeDidNotStop,
          _ => l.deskSetLnodeDidNotRestart,
        }, text: deskErrorText(e, l), tone: ETone.risk);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _changeFolder(LocalNodeState s) async {
    final api = ref.read(deskNodeProvider);
    final l = context.l10n;
    final how = await showChangeFolderDialog(context, api, s);
    if (how == null || !mounted) return;
    setState(() => _moving = (0, s.chainDataBytes ?? 0));
    try {
      await api.changeDataFolder(how.$1, how.$2, progress: (d, t) {
        if (mounted) setState(() => _moving = (d, t));
      });
      if (mounted) showEToast(context, how.$2 == FolderChange.move ? l.deskSetLnodeMoved : l.deskSetLnodeFolderChanged, text: how.$1, tone: ETone.ok);
    } on Object catch (e) {
      logWarn('desk', 'node data folder not changed: $e');
      if (mounted) showEToast(context, l.deskSetLnodeFolderFailed, text: deskErrorText(e, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _moving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final api = ref.read(deskNodeProvider);
    // The fallback question, once, when the node first syncs and nothing was answered.
    ref.listen(deskFallbackDecisionProvider, (_, d) {
      if (d?.action == FallbackAction.ask) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? maybeAskFallback(context, ref) : null);
    });
    final s = ref.watch(deskLocalNodeProvider).value;
    final choice = ref.watch(deskFallbackProvider).value;
    final fallback = fallbackHost(choice);
    final accepted = choice?.consent == FallbackConsent.accepted;
    final hasFallback = (choice?.nodeUrl ?? defaultFallbackNodeUrl).isNotEmpty;
    if (s == null) {
      return Padding(
        padding: EdgeInsets.all(Sp.x5),
        child: Text(l.deskSetNodeLocalNode, style: ts.body.copyWith(color: c.dim)),
      );
    }
    final running = s.phase != LocalNodePhase.stopped && s.phase != LocalNodePhase.error;
    // Offline mode: the node would only sit without a network.
    final offline = ref.watch(deskNetBlockProvider).byMode;
    final noBinary = s.phase == LocalNodePhase.error && s.failure == NodeFailure.binaryMissing;
    final controls = <Widget>[
      if (!running && !noBinary)
        ERowControl(
          child: EButton.primary(
            label: l.deskSetLnodeStart,
            icon: Icons.play_arrow_rounded,
            size: EBtnSize.sm,
            busy: _busy == 'start',
            onPressed: _busy == null && !offline ? () => _run('start', api.start) : null,
          ),
        ),
      if (running) ...[
        ERowControl(child: EButton(label: l.deskSetLnodeStop, icon: EIcons.stop, size: EBtnSize.sm, busy: _busy == 'stop', onPressed: _busy == null ? () => _run('stop', api.stop) : null)),
        ERowControl(child: EButton(label: l.deskSetLnodeRestart, icon: EIcons.refresh, size: EBtnSize.sm, busy: _busy == 'restart', onPressed: _busy == null && !offline ? () => _run('restart', api.restart) : null)),
      ],
    ];

    Widget status({required bool wide}) => _StatusTab(
        key: const ValueKey('status'),
        wide: wide,
        state: s,
        fallback: fallback,
        accepted: accepted,
        sync: _sync,
        download: _download,
        disk: _disk,
        peerHistory: api.peerHistory(),
        moving: _moving,
        onUseFallback: () => ref.read(deskFallbackProvider.notifier).answer(true),
        onStart: _busy == null ? () => _run('start', api.start) : null,
        onRestart: _busy == null ? () => _run('restart', api.restart) : null,
        onLog: () => showNodeLogDialog(context, api),
        onChangeFolder: () => _changeFolder(s),
        now: _now,
      );
    final peers = PeersTab(key: const ValueKey('peers'), restartNeeded: s.restartNeeded, onRestart: _busy == null ? () => _run('restart', api.restart) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wide: Status and Peers side by side, no tabs.
        LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= nodePanelWideFrom;
            final buttons = Wrap(alignment: WrapAlignment.end, spacing: Sp.x2, runSpacing: Sp.x2, children: controls);
            if (wide) {
              return Padding(
                padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: AlignmentDirectional.centerEnd, child: buttons),
                    SizedBox(height: Sp.x4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: status(wide: true)),
                        SizedBox(width: Sp.col),
                        Expanded(child: peers),
                      ],
                    ),
                  ],
                ),
              );
            }
            final Widget tab = _tab == LocalTab.status ? status(wide: false) : peers;
            return Padding(
          padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ESegmented<LocalTab>(
                    segments: [ESegment(LocalTab.status, l.deskSetLnodeTabStatus), ESegment(LocalTab.peers, l.deskSetLnodeTabPeers)],
                    value: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  SizedBox(width: Sp.x3),
                  // Row buttons at the card's right edge; under each other when the card is narrow.
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: buttons,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Sp.x4),
              AnimatedSwitcher(
                duration: Motion.cross,
                switchInCurve: Motion.easeOut,
                switchOutCurve: Motion.easeIn,
                layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                child: tab,
              ),
            ],
          ),
        );
          },
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        _AutostartRow(api: api),
        Divider(height: 1, thickness: 1, color: c.line),
        _PortsRow(api: api, state: s),
        Divider(height: 1, thickness: 1, color: c.line),
        ESetRow(
          title: l.deskSetLnodeWhileSyncing,
          // An empty Node list has no public node to offer: the list's own state, nothing to pick.
          text: hasFallback ? l.deskSetLnodeWhileSyncingText(fallback) : l.deskSlNoNodeTitle,
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ERowControl(
                child: EButton(
                  label: l.deskSetLnodeChange,
                  size: EBtnSize.sm,
                  onPressed: !hasFallback ? null : () async {
                    final url = await showFallbackPickerDialog(context, current: choice?.nodeUrl ?? defaultFallbackNodeUrl);
                    if (url != null) await ref.read(deskFallbackProvider.notifier).node(url);
                  },
                ),
              ),
              SizedBox(width: Sp.x3),
              ESwitch(value: accepted && hasFallback, semanticLabel: l.deskSetLnodeUseWhileSyncing(fallback), onChanged: !hasFallback ? null : (v) => ref.read(deskFallbackProvider.notifier).answer(v)),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        ESetRow(
          title: l.deskSetLnodeDataFolder,
          stacked: true,
          // The path with the two row buttons beside it, or under it when they leave it too little room.
          control: LayoutBuilder(
            builder: (context, box) {
              final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EMiddleEllipsis(s.dataFolder, style: ts.mono(size: Fs.sm, color: c.text)),
                    SizedBox(height: 2.u),
                    Text(
                      [if (s.chainDataBytes != null) l.deskSetLnodeUsed(bytesText(s.chainDataBytes!, l)), s.freeBytes == null ? l.deskSetLnodeFreeUnknown : l.deskSetLnodeFree(bytesText(s.freeBytes!, l))].join(' · '),
                      style: ts.caption.copyWith(color: c.dim),
                    ),
                  ],
              );
              final buttons = Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x2,
                children: [
              ERowControl(
                child: EButton(
                  label: l.deskSetLnodeOpen,
                  size: EBtnSize.sm,
                  onPressed: () async {
                    final ok = await ref.read(deskOpenFolderProvider)(s.dataFolder);
                    if (!ok && context.mounted) showEToast(context, l.deskSetLnodeFolderNotOpened, text: s.dataFolder, tone: ETone.warn);
                  },
                ),
              ),
              ERowControl(child: EButton(label: l.deskSetLnodeChange, size: EBtnSize.sm, onPressed: _moving == null ? () => _changeFolder(s) : null)),
                ],
              );
              if (box.maxWidth - 2 * Ctl.rowW - Sp.x2 - Sp.x3 >= 240.u) {
                return Row(children: [Expanded(child: info), SizedBox(width: Sp.x3), buttons]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, SizedBox(height: Sp.x3), buttons]);
            },
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        // Two row buttons: under the text when the card leaves the words too little room.
        LayoutBuilder(
          builder: (context, box) => ESetRow(
          title: l.deskSetLnodeChainData,
          stacked: box.maxWidth < 720.u,
          text: s.chainDataOrigin == ChainDataOrigin.pointed ? l.deskSetLnodeChainPointed : l.deskSetLnodeChainText,
          control: Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              ERowControl(child: EButton(label: l.deskSetLnodeReuse, size: EBtnSize.sm, onPressed: () => showReuseChainDataDialog(context, api))),
              ERowControl(
                child: EButton(
                  label: l.deskSetLnodeDelete,
                  kind: EBtnKind.danger,
                  size: EBtnSize.sm,
                  onPressed: s.chainDataOrigin == ChainDataOrigin.pointed ? null : () => showDeleteChainDataDialog(context, api, s),
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }
}

/// Opens Help › Running the local node: the "More in Help" link of the local-node rows'
/// popovers (WD2-063).
VoidCallback localNodeHelp(WidgetRef ref) => () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.localNode));

class _AutostartRow extends ConsumerWidget {
  const _AutostartRow({required this.api});

  final DeskNodeApi api;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(localAutostartProvider).value ?? false;
    final l = context.l10n;
    return ESetRow(
      title: l.deskSetLnodeAutostart,
      hint: l.deskSetLnodeAutostartHint,
      hintHelp: localNodeHelp(ref),
      control: ESwitch(
        value: on,
        semanticLabel: l.deskSetLnodeAutostart,
        onChanged: (v) async {
          await api.setStartWithApp(v);
          ref.invalidate(localAutostartProvider);
        },
      ),
    );
  }
}

/// The built-in node's ports (API, P2P) and Change…, which opens [showLocalNodePortsDialog].
class _PortsRow extends ConsumerWidget {
  const _PortsRow({required this.api, required this.state});

  final DeskNodeApi api;
  final LocalNodeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(hostSettingsProvider);
    return ESetRow(
      title: l.deskSetLnodePorts,
      text: l.deskOnbNodePortsSub('${s.localNodeApiPort}', '${s.localNodeP2pPort}'),
      hint: l.deskOnbNodePortsWhy,
      hintHelp: localNodeHelp(ref),
      control: ERowControl(
        child: EButton(
          key: const ValueKey('local-node-ports-change'),
          label: l.deskSetLnodeChange,
          size: EBtnSize.sm,
          onPressed: () => showLocalNodePortsDialog(context, api, running: state.phase != LocalNodePhase.stopped && state.phase != LocalNodePhase.error),
        ),
      ),
    );
  }
}

/// What the Status tab says for a state (the table of §19): the detail after the word, and the
/// notice (tone, title, text, action) if any.
class StatusWords {
  const StatusWords({required this.detail, this.notice});

  final String detail;
  final ({ETone tone, String title, String? text, NodeAct? action})? notice;
}

/// What a Status notice's button does.
enum NodeAct { start, restart, log, folder, fallback }

/// The label of a notice's button; [fallback] is the host the fallback act names.
String nodeActLabel(AppLocalizations l, NodeAct a, String fallback) => switch (a) {
  NodeAct.start => l.deskSetLnodeStart,
  NodeAct.restart => l.deskSetLnodeRestart,
  NodeAct.log => l.deskSetLnodeViewLog,
  NodeAct.folder => l.deskSetLnodeChangeFolder,
  NodeAct.fallback => l.deskSetLnodeUseMeanwhile(fallback),
};

StatusWords statusWords(AppLocalizations l, LocalNodeState s, {required String fallback, required bool accepted}) {
  switch (s.phase) {
    case LocalNodePhase.starting:
      return StatusWords(detail: l.deskSetLnodeWaitingPeers);
    case LocalNodePhase.syncing:
      final stage = s.progress == null ? l.deskSetLnodeSyncingLower : stageName(l, s.progress!.stage);
      if (accepted) return StatusWords(detail: l.deskSetLnodeStageUsing(stage, fallback));
      return StatusWords(
        detail: stage,
        notice: (tone: ETone.neutral, title: l.deskSetLnodeNothingUntilSynced, text: null, action: NodeAct.fallback),
      );
    case LocalNodePhase.synced:
      return StatusWords(detail: [if (s.height != null) digits(l, s.height!), l.deskSetLnodeAtTip].join(' · '));
    case LocalNodePhase.error:
      if (s.stalled) {
        return StatusWords(
          detail: l.deskSetLnodeStalledDetail,
          // The node has stopped: the header says Start, so does the notice (UD-019).
          notice: (tone: ETone.risk, title: l.deskSetLnodeNoProgress, text: l.deskSetLnodeNoProgressText, action: NodeAct.start),
        );
      }
      return StatusWords(
        detail: failureLine(l, s),
        notice: switch (s.failure) {
          NodeFailure.portInUse => (
            tone: ETone.risk,
            title: l.deskSetLnodePortInUse('${hostSettings.localNodeApiPort}'),
            text: l.deskSetLnodePortInUseText,
            action: NodeAct.log,
          ),
          NodeFailure.diskLow => (tone: ETone.risk, title: l.deskSetLnodeDiskLow, text: l.deskSetLnodeDiskLowText, action: NodeAct.folder),
          NodeFailure.binaryMissing => (tone: ETone.risk, title: l.deskSetLnodeMissing, text: l.deskSetLnodeMissingText, action: null),
          _ => (tone: ETone.risk, title: l.deskSetLnodeStopped, text: l.deskSetLnodeStoppedText, action: NodeAct.log),
        },
      );
    case LocalNodePhase.stopped:
      return StatusWords(detail: accepted ? l.deskSetLnodeUsesMeanwhile(fallback) : l.deskSetLnodeNothingUntilRuns);
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    super.key,
    this.wide = false,
    required this.state,
    required this.fallback,
    required this.accepted,
    required this.sync,
    required this.download,
    required this.disk,
    required this.peerHistory,
    required this.moving,
    required this.onUseFallback,
    required this.onStart,
    required this.onRestart,
    required this.onLog,
    required this.onChangeFolder,
    required this.now,
  });

  /// Beside the peers on a wide panel: taller charts.
  final bool wide;
  final LocalNodeState state;
  final String fallback;
  final bool accepted;
  final List<_Sample> sync;
  final List<_Sample> download;
  final List<_Sample> disk;
  final List<PeerCountSample> peerHistory;
  final (int, int)? moving;
  final VoidCallback onUseFallback;
  final VoidCallback? onStart;
  final VoidCallback? onRestart;
  final VoidCallback onLog;
  final VoidCallback onChangeFolder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final s = state;
    final v = localNodeView(l, s);
    final words = statusWords(l, s, fallback: fallback, accepted: accepted);
    final p = s.progress;
    final syncing = s.phase == LocalNodePhase.syncing || s.phase == LocalNodePhase.starting;
    final live = s.phase != LocalNodePhase.stopped && s.phase != LocalNodePhase.error;
    final overall = p?.overall;
    final pct = overall == null ? null : percent(overall);
    final startedAgo = s.startedAt == null ? null : now.difference(s.startedAt!);

    VoidCallback? actionOf(NodeAct? act) => switch (act) {
      NodeAct.start => onStart,
      NodeAct.restart => onRestart,
      NodeAct.log => onLog,
      NodeAct.folder => onChangeFolder,
      null => null,
      NodeAct.fallback => onUseFallback,
    };

    Widget notice(({ETone tone, String title, String? text, NodeAct? action}) n) => ENotice(
      tone: n.tone,
      title: n.title,
      text: n.text,
      actions: [if (n.action != null) EButton(label: nodeActLabel(l, n.action!, fallback), size: EBtnSize.inline, onPressed: actionOf(n.action))],
    );

    final tiles = <Widget>[
      NodeTile(
        label: l.deskSetLnodeTilePeers,
        value: s.peers == null ? '–' : '${s.peers}',
        series: [for (final h in peerHistory) (h.inbound + h.outbound).toDouble()],
        chart: nodeChartHeight(wide: wide),
      ),
      NodeTile(label: l.deskSetLnodeTileSync, value: pct ?? (s.phase == LocalNodePhase.synced ? '100%' : '–'), series: [for (final x in sync) x.value], chart: nodeChartHeight(wide: wide)),
      if (p?.stage == SyncStage.chainStateDownload)
        NodeTile(
          label: l.deskSetLnodeTileDownload,
          value: s.stageRate == null ? '–' : '${bytesText(s.stageRate!.round(), l)}/s',
          suffix: p?.done == null ? null : l.deskSetLnodeSoFar(bytesText(p!.done!, l)),
          series: [for (final x in download) x.value],
          chart: nodeChartHeight(wide: wide),
        )
      else
        NodeTile(
          label: l.deskSetLnodeTileDisk,
          value: s.chainDataBytes == null ? '–' : bytesText(s.chainDataBytes!, l),
          suffix: s.chainDataBytes != null && s.chainDataBytesAtStart != null && s.chainDataBytes! > s.chainDataBytesAtStart!
              ? l.deskSetLnodeThisSession(bytesText(s.chainDataBytes! - s.chainDataBytesAtStart!, l))
              : null,
          series: [for (final x in disk) x.value],
          chart: nodeChartHeight(wide: wide),
        ),
    ];

    final meta = [
      if (s.version != null) l.deskSetLnodeVersion(s.version!),
      if (live && s.uptime != null) l.deskSetLnodeRunning(duration(l, s.uptime!)),
      if (!live) l.deskSetLnodeStoppedAt(hhmm(s.at)),
      if (live && s.peers != null) l.deskSetLnodePeersCount(s.peers!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EStatusGlyph(icon: EIcons.node, state: v.state, label: v.word, size: 16.u),
            SizedBox(width: Sp.x1),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: v.word, style: ts.body.copyWith(fontWeight: FontWeight.w600, color: stateColor(c, v.state))),
                    TextSpan(text: ' · ', style: ts.body.copyWith(color: c.faint)),
                    TextSpan(text: words.detail, style: ts.small.copyWith(color: c.dim)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (moving != null) ...[
          SizedBox(height: Sp.x4),
          NodeSyncBar(value: moving!.$2 == 0 ? null : moving!.$1 / moving!.$2),
          SizedBox(height: Sp.x2),
          Text(l.deskSetLnodeMoving(bytesText(moving!.$1, l), bytesText(moving!.$2, l)), style: ts.small),
        ] else if (syncing) ...[
          SizedBox(height: Sp.x4),
          NodeSyncBar(value: overall),
          SizedBox(height: Sp.x2),
          Row(
            children: [
              Expanded(child: Text(p == null ? l.deskSetLnodeConnectingPeers : stageLine(l, p), style: ts.small)),
              SizedBox(width: Sp.x3),
              Text(
                p?.stage == SyncStage.waitingForPeers || p == null
                    ? (startedAgo == null ? '' : (startedAgo.inSeconds < 90 ? l.deskSetLnodeStartedSecAgo(startedAgo.inSeconds) : l.deskSetLnodeStartedAgo(duration(l, startedAgo))))
                    : pct ?? '',
                style: ts.small.copyWith(color: c.dim),
              ),
            ],
          ),
          SizedBox(height: Sp.x3),
          StageStrip(step: p == null ? null : stripStep(p.stage)),
        ],
        // The last notice stays the child while it closes, so the collapse eases out (240 ms
        // both ways) instead of snapping.
        _KeepLast(
          value: words.notice,
          builder: (n) => ExpandFade(
            open: words.notice != null,
            child: n == null ? const SizedBox.shrink() : Padding(padding: EdgeInsets.only(top: Sp.x4), child: notice(n)),
          ),
        ),
        ExpandFade(
          open: s.restartNeeded && live,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x4),
            child: ENotice(
              tone: ETone.warn,
              title: l.deskSetLnodeSettingsChanged,
              text: l.deskSetLnodeSettingsChangedText,
              actions: [EButton(label: l.deskSetLnodeRestartNow, size: EBtnSize.inline, onPressed: onRestart)],
            ),
          ),
        ),
        if (live) ...[
          SizedBox(height: Sp.x4),
          LayoutBuilder(
            builder: (context, box) {
              final n = tiles.length;
              final gap = Sp.x3;
              final per = (box.maxWidth - gap * (n - 1)) / n;
              final w = per < 170.u ? (box.maxWidth - gap) / 2 : per;
              // Never wider than the box, even when that is under the 150 u minimum.
              final tileW = w.clamp(150.u < box.maxWidth ? 150.u : box.maxWidth, box.maxWidth);
              return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: tileW, child: t)]);
            },
          ),
          SizedBox(height: Sp.x2),
          Text(l.deskSetLnodeSampled, style: ts.caption.copyWith(color: c.faint)),
        ],
        SizedBox(height: Sp.x4),
        Row(
          children: [
            Expanded(child: Text(meta, style: ts.small.copyWith(color: c.dim), overflow: TextOverflow.ellipsis)),
            SizedBox(width: Sp.x3),
            ERowControl(child: EButton(label: l.deskSetLnodeViewLog, icon: EIcons.log, size: EBtnSize.sm, onPressed: onLog)),
          ],
        ),
        if (s.userToml) ...[
          SizedBox(height: Sp.x2),
          Text(l.deskSetLnodeTomlEdited, style: ts.caption.copyWith(color: c.warn)),
        ],
      ],
    );
  }
}

/// Builds with the last non-null [value] (null until there was one).
class _KeepLast<T extends Object> extends StatefulWidget {
  const _KeepLast({super.key, required this.value, required this.builder});

  final T? value;
  final Widget Function(T? last) builder;

  @override
  State<_KeepLast<T>> createState() => _KeepLastState<T>();
}

class _KeepLastState<T extends Object> extends State<_KeepLast<T>> {
  T? _last;

  @override
  Widget build(BuildContext context) {
    _last = widget.value ?? _last;
    return widget.builder(_last);
  }
}

class NodeSyncBar extends StatelessWidget {
  const NodeSyncBar({super.key, required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3.u),
      child: SizedBox(
        height: 6.u,
        // Reduced motion: no sweep for an unknown amount; a still, dimmed full bar instead.
        child: LinearProgressIndicator(
          value: value ?? (reduced ? 1 : null),
          backgroundColor: c.s3,
          color: value == null && reduced ? c.info.withValues(alpha: 0.35) : c.info,
          semanticsLabel: context.l10n.deskSetLnodeSyncProgress,
          semanticsValue: value == null ? null : '${(value! * 100).floor()}%',
        ),
      ),
    );
  }
}

/// Headers → Chain state → Blocks → Synced: done = ok dot, current = accent dot and text,
/// to-do = outline. [step] null: everything to do (waiting for peers).
class StageStrip extends StatelessWidget {
  const StageStrip({super.key, required this.step});

  final int? step;

  static List<String> namesOf(AppLocalizations l) => [l.deskSetLnodeStepHeaders, l.deskSetLnodeStepChainState, l.deskSetLnodeStepBlocks, l.deskSetFrameNodeSynced];

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final names = namesOf(l);
    return Semantics(
      label: step == null ? l.deskSetLnodeStepsNone : l.deskSetLnodeStepOf(step! + 1, names[step!]),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0) Expanded(child: Container(height: 1, color: step != null && i <= step! ? c.ok : c.line)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.u,
                  height: 8.u,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step == null || i > step! ? null : (i == step ? c.info : c.ok),
                    border: Border.all(color: step == null || i > step! ? c.lineStrong : (i == step ? c.info : c.ok)),
                  ),
                ),
                SizedBox(width: Sp.x1),
                Text(names[i], style: ts.caption.copyWith(color: step != null && i == step ? c.info : (step != null && i < step! ? c.dim : c.faint))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A tile: label, value (+ a small dim suffix), a 32 u sparkline of one series.
class NodeTile extends StatelessWidget {
  const NodeTile({super.key, required this.label, required this.value, this.suffix, required this.series, this.chart});

  final String label;
  final String value;
  final String? suffix;
  final List<double> series;

  /// The sparkline's height: 32 u, taller where the panel is wide ([nodeChartHeight]).
  final double? chart;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      label: '$label: $value${suffix == null ? '' : ', $suffix'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(Sp.x3),
        decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ts.caption.copyWith(color: c.faint)),
            SizedBox(height: 2.u),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value, style: ts.body.copyWith(fontSize: 15.u, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
                  if (suffix != null) TextSpan(text: '  $suffix', style: ts.caption.copyWith(color: c.dim)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Sp.x2),
            SizedBox(height: chart ?? 32.u, width: double.infinity, child: CustomPaint(painter: Sparkline(series, c.accent))),
          ],
        ),
      ),
    );
  }
}

/// One series: a 2 u accent line over a 12 % accent fill; no axes, no legend.
class Sparkline extends CustomPainter {
  const Sparkline(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      if (values.length == 1) {
        canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 2.u);
      }
      return;
    }
    var lo = values.reduce((a, b) => a < b ? a : b), hi = values.reduce((a, b) => a > b ? a : b);
    if (hi == lo) {
      lo -= 1;
      hi += 1;
    }
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / (hi - lo) * (size.height - 2.u) - 1.u;
      pts.add(Offset(x, y));
    }
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.u
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(Sparkline old) => old.values != values || old.color != color;
}
