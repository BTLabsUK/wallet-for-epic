// SPDX-License-Identifier: Apache-2.0
/// The panel of Settings › Node for the user's own node: the
/// node's facts asked directly every 15 s (never the status site, which cannot see it), the
/// failover and syncing notices, and the Owner access row. With owner access the built-in
/// node's Status and Peers come from the node's owner API: the sync stage and its tiles, the
/// peers table with Ban / Unban. Where the panel is wide, status and peers sit side by side.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../app/desk_failover.dart';
import '../../data/desk_node.dart';
import '../../data/node_view.dart';
import '../../data/own_node.dart' show ownerSecretMayTravel, ownerSecretPlainOnLan;
import '../../../net/tor_switch.dart' show TorSwitch;
import '../../widgets/kit.dart';
import '../../widgets/node_card.dart' show NodeFact, ageText;
import '../../widgets/server_row.dart' show digitsText;
import 'local_node.dart' show LocalTab, NodeTile, NodeSyncBar, StageStrip, localNodeHelp;
import 'local_node_peers.dart';
import 'prefs.dart';
import '../../../settings_file/host_settings.dart' show appConfig;
import '../../../settings_file/status_site.dart' show statusSiteHost;

/// How often an own node is asked while its panel is open.
Duration get ownAskEvery => appConfig.ownNodeAsk;

/// From this panel width, status and details (or peers) sit side by side.
double get nodePanelWideFrom => Lay.wide;

/// A tile's chart: taller where the panel is wide.
double nodeChartHeight({required bool wide}) => wide ? 72.u : 32.u;

/// Picks the node's `.api_secret` ("Pick the file…", this computer only); tests replace it.
final ownerSecretFilePickerProvider = Provider<Future<String?> Function(String title, String? folder)>(
  (ref) => (title, folder) async => (await FilePicker.pickFile(dialogTitle: title, initialDirectory: folder))?.path,
);

/// Where the node keeps `.api_secret` on this computer, for the picker to open in.
String? epicDataFolder(String? chain) {
  final home = Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  if (home == null) return null;
  return '$home${Platform.pathSeparator}.epic${Platform.pathSeparator}${chain == 'floonet' ? 'floo' : 'main'}';
}

/// The fallback node for an own node: the one standing in now, else the fallback default.
String ownFallbackHost(NodeFailover? f) => nodeHost(f?.inUse ?? defaultFallbackNodeUrl);

class OwnNodePanel extends ConsumerStatefulWidget {
  const OwnNodePanel({super.key, required this.url, this.health, this.initialTab = LocalTab.status, this.openAccess = false, this.clock});

  /// The own node: the chosen one, also while failover stands in for it.
  final String url;

  /// The wallet's own view of the node in use.
  final ServiceHealth? health;
  final LocalTab initialTab;

  /// The tour: the Owner access dialog opens at once.
  final bool openAccess;

  /// For tests; the clock otherwise.
  final DateTime Function()? clock;

  @override
  ConsumerState<OwnNodePanel> createState() => _OwnNodePanelState();
}

class _Sample {
  const _Sample(this.at, this.value);

  final DateTime at;
  final double value;
}

class _OwnNodePanelState extends ConsumerState<OwnNodePanel> {
  late LocalTab _tab = widget.initialTab;
  Timer? _ask;
  final List<_Sample> _sync = [];
  final List<_Sample> _pool = [];

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _ask = Timer.periodic(ownAskEvery, (_) => _again());
    if (widget.openAccess) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _addAccess() : null);
  }

  @override
  void dispose() {
    _ask?.cancel();
    super.dispose();
  }

  void _again() {
    if (!mounted) return;
    ref.invalidate(deskNodeInfoProvider(widget.url));
    ref.invalidate(deskOwnStatusProvider);
    ref.invalidate(deskOwnPeersProvider(widget.url));
  }

  void _push(List<_Sample> l, double? v) {
    if (v == null) return;
    if (l.isNotEmpty && _now.difference(l.last.at) < ownAskEvery - const Duration(seconds: 1)) return;
    l.add(_Sample(_now, v));
    if (l.length > 120) l.removeAt(0);
  }

  Future<void> _addAccess() async {
    final added = await showOwnerAccessDialog(context, ref, widget.url);
    if (added == true && mounted) {
      ref.invalidate(deskOwnerSecretProvider(widget.url));
      showEToast(context, context.l10n.deskOwnAdded, text: ownAddress(widget.url), tone: ETone.ok);
    }
  }

  Future<void> _removeAccess() async {
    await ref.read(deskNodeProvider).removeOwnerSecret(widget.url);
    if (!mounted) return;
    ref.invalidate(deskOwnerSecretProvider(widget.url));
    showEToast(context, context.l10n.deskOwnRemoved, text: ownAddress(widget.url), tone: ETone.ok);
  }

  void _answerSyncing(bool usePublic) {
    final p = ref.read(settingsPrefsProvider);
    ref.read(settingsPrefsProvider.notifier).set(p.copyWith(ownFallback: {...p.ownFallback, widget.url: usePublic}));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final url = widget.url;
    final info = ref.watch(deskNodeInfoProvider(url)).value;
    final failover = ref.watch(deskFailoverProvider);
    final standIn = failover != null && failover.chosen == url ? failover : null;
    final prefs = ref.watch(settingsPrefsProvider);
    final has = ref.watch(deskOwnerSecretProvider(url)).value ?? false;
    final owner = has ? ref.watch(deskOwnStatusProvider((url: url, tip: info?.networkHeight))) : null;
    final ownerOk = owner?.value;
    final ownerOff = owner?.error is OwnerUnavailable ? owner!.error as OwnerUnavailable : null;
    _push(_pool, info?.poolSize?.toDouble());
    _push(_sync, ownerOk == null ? null : (ownerOk.synced ? 1.0 : ownerOk.progress?.overall));

    final cls = shownClass(url, info, mine: prefs.mineNodes.contains(url));
    // Failover stands in: the wallet's health is the stand-in's, so the head is the node's own answer.
    final v = remoteNodeView(l, url, info, health: standIn == null && widget.health == ServiceHealth.ok ? widget.health : null, mine: prefs.mineNodes.contains(url));
    final head = info?.head;
    final syncing = head == NodeHead.syncing || (ownerOk != null && !ownerOk.synced && ownerOk.progress != null);
    final fallback = ownFallbackHost(standIn);
    final answered = prefs.ownFallback[url];

    final String? detail = standIn != null && !standIn.syncing
        ? [l.deskOwnUsingMeanwhile(fallback), if (standIn.at != null) l.deskKitSince(hhmm(standIn.at!))].join(' · ')
        : standIn != null
        ? l.deskOwnUsingUntilSynced(fallback)
        : null;

    final headRow = Row(
      children: [
        EStatusGlyph(icon: EIcons.node, state: v.state, label: v.word, size: 16.u),
        SizedBox(width: Sp.x1),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: v.word, style: ts.body.copyWith(fontWeight: FontWeight.w600, color: stateColor(c, v.state))),
                TextSpan(text: ' · ', style: ts.body.copyWith(color: c.faint)),
                TextSpan(text: ownLabel(l, cls, url), style: ts.body.copyWith(color: c.text)),
                if (detail != null) ...[
                  TextSpan(text: ' · ', style: ts.body.copyWith(color: c.faint)),
                  TextSpan(text: detail, style: ts.small.copyWith(color: c.dim)),
                ],
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final notices = <Widget>[
      if (standIn != null && !standIn.syncing)
        ENotice(
          tone: ETone.risk,
          title: l.deskOwnDownTitle,
          actionsBelow: true,
          text: l.deskOwnDownText(fallback),
          actions: [
            EButton(label: l.deskOwnTryNow, size: EBtnSize.inline, onPressed: () => ref.read(deskFailoverWatchProvider.notifier).tryBack()),
            EButton(label: l.deskOwnUseForGood(fallback), size: EBtnSize.inline, onPressed: () => ref.read(deskProvider.notifier).useNode(standIn.inUse)),
          ],
        )
      else if (standIn != null)
        ENotice(
          tone: ETone.info,
          title: l.deskOwnSyncUsingTitle(fallback),
          text: l.deskOwnSyncUsingText,
          actions: [EButton(label: l.deskOwnWaitForMine, size: EBtnSize.inline, onPressed: () => _answerSyncing(false))],
        )
      else if (syncing && answered == null)
        ENotice(
          title: l.deskOwnSyncTitle,
          actionsBelow: true,
          text: l.deskOwnSyncText(fallback),
          actions: [
            EButton(label: l.deskSetLnodeUseMeanwhile(fallback), size: EBtnSize.inline, onPressed: () => _answerSyncing(true)),
            EButton(label: l.deskOwnWaitForMine, size: EBtnSize.inline, onPressed: () => _answerSyncing(false)),
          ],
        ),
    ];

    final facts = _facts(l, info);
    Widget factGrid(double width) {
      final per = width >= 900.u ? facts.length : (width >= 560.u ? 3 : 2);
      final gap = 14.u;
      final w = ((width - gap * (per - 1)) / per).floorToDouble();
      return Wrap(spacing: gap, runSpacing: 20.u, children: [for (final f in facts) SizedBox(width: w, child: f)]);
    }

    Widget statusBlock({required bool wide}) {
      final o = ownerOk;
      if (o == null) return const SizedBox.shrink();
      final p = o.progress;
      final tiles = [
        NodeTile(label: l.deskSetLnodeTilePeers, value: '${o.peers}', series: [for (final h in ref.read(deskNodeProvider).ownPeerHistory(url)) (h.inbound + h.outbound).toDouble()], chart: nodeChartHeight(wide: wide)),
        NodeTile(label: l.deskSetLnodeTileSync, value: o.synced ? '100 %' : (p?.overall == null ? '–' : percent(p!.overall!)), series: [for (final x in _sync) x.value], chart: nodeChartHeight(wide: wide)),
        NodeTile(label: l.deskOwnFactMempool, value: info?.poolSize == null ? '–' : poolText(l, info!.poolSize!), series: [for (final x in _pool) x.value], chart: nodeChartHeight(wide: wide)),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p != null && !o.synced) ...[
            NodeSyncBar(value: p.overall),
            SizedBox(height: Sp.x2),
            Row(
              children: [
                Expanded(child: Text(stageLine(l, p), style: ts.small)),
                if (p.overall != null) Text(percent(p.overall!), style: ts.small.copyWith(color: c.dim)),
              ],
            ),
            SizedBox(height: Sp.x3),
            StageStrip(step: stripStep(p.stage)),
            SizedBox(height: Sp.x4),
          ],
          LayoutBuilder(
            builder: (context, box) {
              final gap = Sp.x3;
              final n = box.maxWidth >= Lay.sm ? tiles.length : 2;
              final w = ((box.maxWidth - gap * (n - 1)) / n).floorToDouble();
              return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
            },
          ),
          SizedBox(height: Sp.x2),
          Text(l.deskOwnAccessNote, style: ts.caption.copyWith(color: c.faint)),
        ],
      );
    }

    final source = Text(sourceLine(l, info), style: ts.caption.copyWith(color: c.faint));

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= nodePanelWideFrom;
        final pad = EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x5);
        final Widget body;
        if (ownerOk != null && wide) {
          // Status beside the peers.
          final colW = (box.maxWidth - pad.horizontal - Sp.col) / 2;
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headRow,
                    for (final n in notices) ...[SizedBox(height: Sp.x4), n],
                    SizedBox(height: Sp.x4),
                    factGrid(colW),
                    SizedBox(height: Sp.x4),
                    statusBlock(wide: true),
                    SizedBox(height: Sp.x3),
                    source,
                  ],
                ),
              ),
              SizedBox(width: Sp.col),
              Expanded(child: PeersTab(restartNeeded: false, ownUrl: url)),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headRow,
              for (final n in notices) ...[SizedBox(height: Sp.x4), n],
              SizedBox(height: Sp.x4),
              factGrid(box.maxWidth - pad.horizontal),
              if (ownerOk != null) ...[
                SizedBox(height: Sp.x5),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ESegmented<LocalTab>(
                    segments: [ESegment(LocalTab.status, l.deskSetLnodeTabStatus), ESegment(LocalTab.peers, l.deskSetLnodeTabPeers)],
                    value: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                ),
                SizedBox(height: Sp.x4),
                _tab == LocalTab.status ? statusBlock(wide: false) : PeersTab(restartNeeded: false, ownUrl: url),
              ],
              SizedBox(height: Sp.x3),
              source,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(container: true, label: l.deskKitNodeSemantics(v.word, ownAddress(url)), child: Padding(padding: pad, child: body)),
            Divider(height: 1, thickness: 1, color: c.line),
            _accessRow(l, has: has, ok: ownerOk != null, off: ownerOff, cls: cls),
          ],
        );
      },
    );
  }

  Widget _accessRow(AppLocalizations l, {required bool has, required bool ok, required OwnerUnavailable? off, required NodeClass cls}) {
    final refused = off?.why == OwnerOff.refused;
    // Add… only where the secret may go now: with Tor on, an https node says why instead.
    final mine = ref.watch(settingsPrefsProvider.select((p) => p.mineNodes.contains(widget.url)));
    final may = ownerSecretMayTravel(widget.url, mine: mine, torOn: TorSwitch.on);
    final tor = off?.why == OwnerOff.torOn || (!has && !may && TorSwitch.on);
    final text = tor
        ? l.deskOwnAccessTor
        : !has
        ? l.deskOwnAccessNotSet
        : refused
        ? l.deskOwnAccessRefused(off!.since == null ? '–' : hhmm(off.since!))
        : tor
        ? l.deskOwnAccessTor
        : ownerSecretPlainOnLan(widget.url)
        ? l.deskOwnAccessOnPlain
        : l.deskOwnAccessOn;
    return ESetRow(
        title: l.deskOwnAccess,
        hint: l.deskOwnAccessHint,
        hintHelp: localNodeHelp(ref),
        text: text,
        badge: refused ? EBadge(l.deskOwnAccessRefusedBadge, tone: BadgeTone.warn) : null,
        wrap: true,
        control: Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            if (!has && may) EButton(label: l.deskOwnAdd, size: EBtnSize.sm, onPressed: _addAccess),
            if (refused) EButton(label: l.deskOwnUpdate, size: EBtnSize.sm, onPressed: _addAccess),
            if (has) EButton(label: l.deskOwnRemove, size: EBtnSize.sm, onPressed: _removeAccess),
          ],
        ),
    );
  }

  List<Widget> _facts(AppLocalizations l, NodeInfo? i) {
    final down = i?.head == NodeHead.down || i?.source == NodeInfoSource.none;
    final at = _now;
    final behind = i?.blocksBehind;
    final tipAge = i?.tipTime == null ? null : at.difference(i!.tipTime!);
    final heightSub = i == null
        ? null
        : down
        ? l.deskKitNodeNoAnswer
        : behind != null
        ? (behind <= syncedWithinBlocks ? l.deskKitAtTip : l.deskKitBehind(behind, digitsText(l, behind)))
        : (tipAge == null ? null : l.deskKitLastBlock(ageText(l, tipAge)));
    final old = i?.updateAvailable == true;
    return [
      NodeFact(
        l.deskKitFactHeight,
        i?.height == null || down ? '–' : digitsText(l, i!.height!),
        heightSub,
        tone: down ? EState.risk : (behind == null ? null : (behind <= syncedWithinBlocks ? EState.ok : EState.warn)),
      ),
      NodeFact(
        l.deskKitFactVersion,
        i?.version == null ? '–' : i!.version!,
        i?.version == null || i?.releasedVersion == null ? null : (old ? l.deskKitVersionOut('${i!.releasedVersion}') : l.deskKitVersionLatest),
        tone: old ? EState.warn : null,
      ),
      NodeFact(l.deskKitFactLatency, i?.latencyMs == null || down ? '–' : '${digitsText(l, i!.latencyMs!)} ms', i?.latencyMs == null || down ? null : l.deskKitFromThisComputer),
      NodeFact(
        l.deskKitFactAccepts,
        down || i == null
            ? '–'
            : switch (i.readyForTxs) {
                true => l.deskKitFactYes,
                false => l.deskKitFactNotYet,
                null => l.deskKitFactUnknown,
              },
        null,
        tone: i?.readyForTxs == false && !down ? EState.warn : null,
      ),
      NodeFact(l.deskOwnFactMempool, i?.poolSize == null || down ? '–' : poolText(l, i!.poolSize!), null),
    ];
  }
}

/// "3 waiting", "empty".
String poolText(AppLocalizations l, int n) => n == 0 ? l.deskOwnPoolEmpty : l.deskOwnPoolWaiting(n);

/// "Asked directly every 15 s · tip from the status site" (or "from 4 public nodes").
String sourceLine(AppLocalizations l, NodeInfo? i) => switch (i?.tipFrom) {
  TipReference.statusSite => l.deskOwnSourceSite(statusSiteHost),
  TipReference.publicNodes => l.deskOwnSourceNodes(i!.tipNodes ?? 0),
  null => l.deskOwnSourceNone,
};

/// Owner access to an own node: paste the secret (or pick `.api_secret` on this computer),
/// checked with one owner call. True when it was kept.
Future<bool?> showOwnerAccessDialog(BuildContext context, WidgetRef ref, String url) => showEDialog<bool>(
  context,
  builder: (_) => _OwnerAccessDialog(url: url),
);

class _OwnerAccessDialog extends ConsumerStatefulWidget {
  const _OwnerAccessDialog({required this.url});

  final String url;

  @override
  ConsumerState<_OwnerAccessDialog> createState() => _OwnerAccessDialogState();
}

class _OwnerAccessDialogState extends ConsumerState<_OwnerAccessDialog> {
  final _secret = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _file;
  bool _quiet = false;

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final l = context.l10n;
    final path = await ref.read(ownerSecretFilePickerProvider)(l.deskOwnDlgPick, epicDataFolder(ref.read(deskNodeProvider).chain.name));
    if (path == null || !mounted) return;
    String first = '';
    try {
      final lines = await File(path).readAsLines();
      first = lines.isEmpty ? '' : lines.first.trim();
    } on Object {
      first = '';
    }
    if (!mounted) return;
    setState(() {
      if (first.isEmpty) {
        _error = l.deskOwnDlgFileEmpty;
        _file = null;
      } else {
        // The secret is never shown: the field holds it hidden.
        _secret.text = first;
        _file = path.split(Platform.pathSeparator).last;
        _error = null;
      }
    });
  }

  Future<void> _ok() async {
    final l = context.l10n;
    if (_secret.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref.read(deskNodeProvider).addOwnerSecret(widget.url, _secret.text);
    if (!mounted) return;
    if (_quiet) {
      final p = ref.read(settingsPrefsProvider);
      ref.read(settingsPrefsProvider.notifier).set(p.copyWith(plainHttpSeen: {...p.plainHttpSeen, widget.url}));
    }
    switch (r) {
      case OwnerCheck.ok:
        Navigator.of(context).pop(true);
      case OwnerCheck.noAnswer:
        showEToast(context, l.deskOwnDlgNoAnswer, tone: ETone.warn);
        Navigator.of(context).pop(true);
      case OwnerCheck.refused:
        setState(() {
          _busy = false;
          _error = l.deskOwnDlgRefused;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final url = widget.url;
    final prefs = ref.watch(settingsPrefsProvider);
    final warn = ownerSecretPlainOnLan(url) && !prefs.plainHttpSeen.contains(url);
    final thisComputer = nodeClassOf(url) == NodeClass.thisComputer;
    return EDialog(
      title: l.deskOwnDlgTitle(ownAddress(url)),
      description: l.deskOwnDlgWhere,
      icon: EIcons.key,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warn) ...[
            ENotice(tone: ETone.warn, title: l.deskOwnDlgPlainTitle, text: l.deskOwnDlgPlainText),
            SizedBox(height: Sp.x2),
            ECheckbox(value: _quiet, onChanged: (v) => setState(() => _quiet = v), label: l.deskOwnDlgPlainAgain),
            SizedBox(height: Sp.x4),
          ],
          Text(l.deskOwnDlgPaste, style: ts.small),
          SizedBox(height: Sp.x1),
          EPasswordInput(
            controller: _secret,
            autofocus: true,
            invalid: _error != null,
            semanticLabel: l.deskOwnDlgPaste,
            onChanged: (_) => setState(() {
              _error = null;
              _file = null;
            }),
            onSubmitted: (_) => _busy ? null : _ok(),
          ),
          SizedBox(height: Sp.x1),
          // One held line: what is wrong, or what the file gave; empty it keeps its room.
          ReservedSlot.lines(
            style: ts.caption,
            child: _error != null
                ? Text(_error!, style: ts.caption.copyWith(color: c.risk))
                : _file != null
                ? Text(l.deskOwnDlgFileRead(_file!), style: ts.caption.copyWith(color: c.dim))
                : null,
          ),
          if (thisComputer) ...[
            SizedBox(height: Sp.x3),
            Align(alignment: AlignmentDirectional.centerStart, child: EButton(label: l.deskOwnDlgPick, icon: EIcons.folder, size: EBtnSize.sm, onPressed: _busy ? null : _pick)),
          ],
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        EButton.primary(label: l.deskOwnDlgAdd, busy: _busy, onPressed: _busy ? null : _ok),
      ],
    );
  }
}
