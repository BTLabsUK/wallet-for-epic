// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../connection_grace.dart' show connectionGraceProvider;
import '../../../network_gate.dart' show NetBlock, NetBlockByMode, NetGate;
import '../../../price.dart' show fiatChoiceProvider, fiatText, priceProvider;
import '../../app/shell_notices.dart' show DeskShellNotices, deskShellNoticesShownProvider;
import '../../app/tour.dart';
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider, deskLevelUiProvider;
import '../../../levels/level_features.dart' show LevelWording;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../../amount.dart' show AmountSurface, surfaceEpic;
import '../../../l10n.dart' show localDigits, localInt;
import '../../../ui/common.dart' show epicExact, exactAmountTip;
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart' show DeskPaymentSteps, payInFlight;
import '../invoices/overview_card.dart';
import '../settings/backup.dart' show HistoryReminder, historyBackupProvider, showHistoryImportOffer;
import '../settings/prefs.dart' show SettingsJump, settingsPrefsProvider;
import '../../../recent_activity.dart' show recentActivityCount, showViewAll;
import '../../../ui/theme/lattice.dart' show BrandLattice, latticeCellDesktop, latticeStrength;
import 'restore_scan_panel.dart';
import 'tx_display.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../../settings_file/host_settings.dart' show hostSettings;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;

/// States the tour can start Overview in.
enum OverviewDemo { loading, empty, nodeDown, starting, syncing, nodeProblem }

/// Mock sync state for [OverviewDemo.syncing].
const double _syncPart = 0.62;
const int _walletTip = 2903118;

/// Overview: the balance (the one framed object) and recent activity; the service state lives in the rail.
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  bool _refreshing = false;
  bool _restarting = false;
  bool _problemHidden = false;
  bool _addressNoteHidden = false;

  /// Shallow's first-open notice was answered on this Overview.
  bool _readyHidden = false;

  /// The history import offer was asked on this Overview.
  bool _importOffered = false;

  /// Asks the node now, as 6.1.6's refresh does; says so when it could not.
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(deskProvider.notifier).syncNow();
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskOvNotUpdated, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Starts the built-in node again when it stopped; a running one is left as it is.
  Future<void> _restartNode() async {
    setState(() => _restarting = true);
    try {
      await ref.read(deskProvider.notifier).useBuiltInNode(true);
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskOvNodeNotStarted, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    }
    if (mounted) setState(() => _restarting = false);
  }


  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final demo = widget.arg is OverviewDemo ? widget.arg! as OverviewDemo : null;
    final s = ref.watch(deskProvider);
    final lv = ref.watch(deskLevelUiProvider);
    final shallow = lv.heroSentence;
    final hidden = s.settings.hideAmounts;
    final loading = demo == OverviewDemo.loading || s.balance == null;
    // The scan a restore owes: its progress, not the empty-wallet state.
    final restore = demo == null ? s.status?.restoreScan : null;
    final empty = demo == OverviewDemo.empty || (demo == null && restore == null && s.balance?.total == 0 && (s.txs?.isEmpty ?? false));
    final starting = demo == OverviewDemo.starting;
    final syncing = demo == OverviewDemo.syncing;
    // Offline (but with a local node) and Tor only: the node is not asked, so its last answer
    // is not news.
    final netBlock = demo == null ? deskNetBlock(s, nodeOnly: true) : NetBlock.none;
    final offline = netBlock.byMode;
    final nodeDown = demo == OverviewDemo.nodeDown || (demo == null && netBlock == NetBlock.none && s.status?.nodeHealth == ServiceHealth.down);
    // Its notice waits out the connection grace after the start or a return (item 11): the
    // status icon alone says Connecting meanwhile.
    final nodeDownSaid = nodeDown && (demo != null || !ref.watch(connectionGraceProvider));
    // The wallet's own sync (a refresh or a scan), not the node's.
    final walletSync = demo == null && s.status?.syncProgress != null;
    final balance = empty ? const Balance(spendable: 0, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0) : s.balance;
    final txs = empty ? const <Tx>[] : (demo == OverviewDemo.loading ? null : s.txs);
    final nav = ref.read(deskNavProvider.notifier);
    final nodeUrl = (s.status?.node.url ?? hostSettings.nodeFallback).replaceFirst(RegExp(r'^https?://'), '');

    final recent = _Recent(txs: txs, shallow: shallow, onOpen: (t) => nav.go(DeskRoute.activity, t.id), onAll: () => nav.go(DeskRoute.activity));
    final pending = empty ? 0 : s.pendingFiles;
    final gap = SizedBox(height: Sp.x4);

    // A restored wallet's first unlock asks once about its history backup, after the
    // first-run tour, never over it.
    final tour = ref.watch(deskTourProvider);
    if (demo == null && !_importOffered && tour.seen && !tour.open && (ref.watch(historyBackupProvider).value?.importOffer ?? false)) {
      _importOffered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showHistoryImportOffer(context, ref));
      });
    }
    final notices = <Widget>[
      // The one notice about levels and the Epicbox server offer (the shell's).
      if (ref.watch(deskShellNoticesShownProvider)) const DeskShellNotices(),
      if (shallow && empty && !_readyHidden)
        ENotice(
          key: const ValueKey('overview-ready'),
          tone: ETone.ok,
          title: l.deskLvPayReadyHead,
          text: l.deskLvPayReadyText,
          actionsBelow: true,
          actions: [
            EButton(label: l.deskOvShowAddress, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.receive)),
            EButton(label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _readyHidden = true)),
          ],
        ),
      if (restore != null) RestoreScanPanel(scan: restore),
      if (s.status?.notice != null) ENotice(tone: ETone.warn, icon: EIcons.alert, title: s.status!.notice!),
      // This session runs on the unencrypted records; the next unlock copies them again.
      if (s.status?.recordsPlain ?? false) ENotice(key: const ValueKey('overview-records-plain'), tone: ETone.info, icon: EIcons.info, title: l.storeRecordsPlain),
      if (ref.watch(historyBackupProvider).value case final backup? when backup.reminder != null && !backup.importOffer) HistoryReminder(state: backup),
      if (starting) const _Steps(),
      if (demo == OverviewDemo.nodeProblem && !_addressNoteHidden)
        ENotice(
          icon: EIcons.info,
          title: l.deskOvNodeAddrTitle,
          text: l.deskOvNodeAddrText(hostPort(hostSettings.nodeUse)),
          actionsBelow: true,
          actions: [EButton(label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _addressNoteHidden = true))],
        ),
      if (demo == OverviewDemo.nodeProblem && !_problemHidden)
        ENotice(
          tone: ETone.risk,
          title: l.deskOvNodeIncompatTitle,
          text: l.deskOvNodeUrl(nodeUrl),
          actionsBelow: true,
          actions: [
            EButton(label: l.deskOvUsePublicNode, icon: EIcons.web, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsNode)),
            if (advancedHas(ref, AdvancedFeature.builtInNode)) EButton(label: l.deskOvUseLocalNode, icon: EIcons.server, size: EBtnSize.inline, busy: _restarting, onPressed: _restartNode),
            EButton(label: l.deskOvHide, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _problemHidden = true)),
          ],
        ),
      // The Node list is empty: nothing to reach, so no "Cannot reach the node at …".
      if (nodeDownSaid && ref.watch(hostSettingsProvider.select((h) => h.nodeUrls.isEmpty)))
        ENotice(
          key: const ValueKey('overview-no-node'),
          tone: ETone.warn,
          icon: EIcons.server,
          title: l.deskSlNoNodeTitle,
          text: l.deskSlNoNodeText,
          actionsBelow: true,
          actions: [EButton(label: l.deskOvNodeSettings, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsNode))],
        )
      else if (nodeDownSaid)
        ENotice(
          tone: ETone.risk,
          title: l.deskOvCantReachNode(nodeUrl),
          text: l.deskOvCantReachNodeText,
          actionsBelow: true,
          actions: [
            if (ref.watch(settingsPrefsProvider).builtin)
            EButton(
              label: _restarting ? l.deskOvStarting : l.deskOvStartNode,
              icon: EIcons.refresh,
              size: EBtnSize.inline,
              busy: _restarting,
              onPressed: _restarting ? null : _restartNode,
            ),
            EButton(label: l.deskOvNodeSettings, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsNode)),
          ],
        ),
      if (syncing) _SyncNotice(part: _syncPart, walletTip: _walletTip),
      // Tor only, Tor not up yet: the node waits for it (in progress, as Send and Receive say).
      if (netBlock == NetBlock.waitingForTor)
        ENotice(
          key: const ValueKey('overview-waiting-tor'),
          tone: ETone.info,
          title: l.netBlockWaitingForTorLong,
          actions: [EButton(label: l.netChangeLink, size: EBtnSize.inline, onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network))],
        ),
    ];

    return EPage(
      title: l.deskOvTitle,
      width: EPageWidth.full,
      // The BT Labs lattice in the room a short Recent activity leaves, fading as rows come.
      fill: restore == null || (s.txs?.isNotEmpty ?? false)
          ? BrandLattice(
              color: context.dc.text,
              strength: latticeStrength(txs?.length),
              cell: latticeCellDesktop.u,
              vignette: true,
            )
          : null,
      actions: [
        // Shallow moves the eye to Settings › Appearance.
        if (lv.hideAmountsInHeader)
          EIconButton(
            icon: hidden ? EIcons.eyeOff : EIcons.eye,
            label: hidden ? l.deskOvShowAmounts : l.deskOvHideAmounts,
            selected: hidden,
            onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
          ),
        _refreshing
            ? SizedBox.square(
                dimension: Ctl.sm,
                child: Center(child: ESpinner()),
              )
            : EIconButton(
                icon: EIcons.refresh,
                label: netBlock == NetBlock.killSwitch ? l.recheckOffKill : (netBlockReason(l, netBlock) ?? l.deskOvRefresh),
                onPressed: netBlock == NetBlock.none ? _refresh : null,
              ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in notices) ...[n, gap],
          TourTarget(
            id: 'balance',
            child: _BalancePanel(
              balance: loading ? null : balance,
              empty: empty,
              hidden: hidden,
              // Not beside "Cannot reach the node": a refresh still waiting on a node that does
              // not answer (packets dropped) only ends at its timeout.
              updating: !offline && !nodeDown && (starting || syncing || loading || walletSync),
              offline: offline,
              asOfBlock: syncing ? _walletTip : null,
              sendBlocked: syncing || nodeDown || demo == OverviewDemo.nodeProblem,
              nodeAnswers: !(nodeDown || demo == OverviewDemo.nodeProblem),
              shallow: shallow,
              casual: lv.casualWords,
            ),
          ),
          // A payment in progress, at every level: its steps live (D11).
          if (txs != null) _InFlight(txs: txs, onOpen: (t) => nav.go(DeskRoute.activity, t.id)),
          SizedBox(height: Sp.x2),
          // While the restore scan runs, Recent activity shows what it finds, never "No
          // transactions yet" (copy D1).
          if (restore == null || (s.txs?.isNotEmpty ?? false)) recent,
          if (pending > 0) _PendingFiles(count: pending),
          const OverviewInvoicesCard(),
        ],
      ),
    );
  }
}

/// Just unlocked: what still runs in the background, one line per step.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    Widget step(_StepState st, String text) {
      final mark = switch (st) {
        _StepState.done => Icon(EIcons.check, size: Ctl.iconSm, color: c.ok),
        _StepState.now => ESpinner(size: Ctl.iconSm),
        _StepState.wait => Icon(EIcons.clock, size: Ctl.iconSm, color: c.faint),
      };
      final state = switch (st) {
        _StepState.done => l.deskOvStepDone,
        _StepState.now => l.deskOvStepNow,
        _StepState.wait => l.deskOvStepWait,
      };
      return Semantics(
        label: l.deskOvStepSemantics(text, state),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            SizedBox(width: Sp.x2),
            Flexible(
              child: Text(
                text,
                style: st == _StepState.wait ? ts.small.copyWith(color: c.faint) : ts.small.copyWith(color: c.text),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      label: l.deskOvStartingUp,
      child: Wrap(
        spacing: Sp.x6,
        runSpacing: Sp.x2,
        children: [
          step(_StepState.done, l.deskOvStepUnlocked),
          step(_StepState.done, l.deskOvStepConnected),
          step(_StepState.now, l.deskOvStepUpdating),
          step(_StepState.wait, l.deskOvStepEpicbox),
        ],
      ),
    );
  }
}

enum _StepState { done, now, wait }

/// The node is still catching up with the network.
class _SyncNotice extends StatelessWidget {
  const _SyncNotice({required this.part, required this.walletTip});

  final double part;
  final int walletTip;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    // The bar and its caption inside the notice, under the text (UD-017).
    return ENotice(
      tone: ETone.info,
      title: l.deskOvSyncTitle((part * 100).round()),
      text: l.deskOvSyncText,
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l.deskOvSyncProgress,
            value: percentText(l, part * 100),
            child: EProgress(value: part),
          ),
          SizedBox(height: Sp.x1),
          Text(l.deskOvSyncOfChain((part * 100).round()), style: ts.caption, textAlign: TextAlign.end),
        ],
      ),
    );
  }
}

String _group(AppLocalizations l, int n) => localInt(l, n);

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({required this.balance, required this.empty, required this.hidden, this.updating = false, this.asOfBlock, this.sendBlocked = false, this.nodeAnswers = true, this.offline = false, this.shallow = false, this.casual = false});

  final Balance? balance;
  final bool empty;
  final bool hidden;

  /// Not yet checked against the node: amounts dimmed, "Updating" tag.
  final bool updating;
  final int? asOfBlock;

  /// The node is not synced: Send waits, and says why.
  final bool sendBlocked;

  /// The node answers (Send waits for its sync); false when it does not answer at all.
  final bool nodeAnswers;

  /// Offline mode: the amounts are the last known ones, marked as such.
  final bool offline;

  /// Shallow: one number and one sentence, no tiles, no fiat line.
  final bool shallow;

  /// Deeper: the tiles in casual words.
  final bool casual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final b = balance;
    // The price as the phone has it (price.dart), only while settings.toml's `[online] price` is
    // on. Off in Node only and Kill switch: the figure is hidden, never a stale one.
    final price = b == null || empty || NetGate.restricted || !ref.watch(hostSettingsProvider.select((h) => h.priceEnabled))
        ? null
        : ref.watch(priceProvider).value;
    // The currency the price is in (main_desktop.dart sets it).
    final currency = ref.watch(fiatChoiceProvider).value?.currency ?? '';
    // What senders report posted leaves Awaiting finalization for its own line, named as its
    // rows are; it is still not in a block, so not in Total (LNX-13).
    final txs = ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[];
    final reported = txs.where((t) => t.incoming && t.senderPosted).fold<int>(0, (sum, t) => sum + t.amount);
    // The change of this wallet's own sends is in Locked in sends already: never awaiting anyone.
    final own = b == null ? 0 : ownChangeOffChain(txs).clamp(0, b.awaitingFinalization);
    final posted = b == null ? 0 : reported.clamp(0, b.awaitingFinalization - own);
    final amount = b == null
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Skeleton(width: 260.u, height: 40.u), SizedBox(height: Sp.x4), _Trace(width: 260.u)])
        : _BigAmount(nano: b.spendable, hidden: hidden, dim: updating);
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: empty
              ? [EButton.primary(label: l.deskOvReceiveEpic, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive))]
              : [
                  // Send and Receive look alike: neither is the one thing to do here.
                  EButton(label: l.deskOvSend, icon: EIcons.send, onPressed: sendBlocked ? null : () => nav.go(DeskRoute.send)),
                  EButton(label: l.deskOvReceive, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
                ],
        ),
        if (sendBlocked && !empty) ...[
          SizedBox(height: Sp.x2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 240.u),
            child: Text(nodeAnswers ? l.deskOvSendWaits : l.deskOvSendWaitsNode, style: ts.small),
          ),
        ],
      ],
    );
    return ETicked(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.x8, Sp.x6, Sp.x8, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final words = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Sp.x2,
                      runSpacing: Sp.x1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l.deskOvAvailable, style: ts.bodyDim.copyWith(fontWeight: FontWeight.w500)),
                        if (asOfBlock != null) EBadge(l.deskOvAsOfBlock(_group(l, asOfBlock!)), tone: ETone.warn),
                        if (updating && asOfBlock == null) const _UpdatingTag(),
                        if (offline) EBadge(l.lastKnownCaption, key: const ValueKey('overview-offline')),
                      ],
                    ),
                    SizedBox(height: 6.u),
                    amount,
                    SizedBox(height: 6.u),
                    if (empty)
                      Text(shallow ? l.deskLvPayHeroNothing : l.deskOvEmptyHint, style: ts.bodyDim)
                    else if (shallow)
                      _HeroSentence(txs: txs, hidden: hidden)
                    else if (price != null && b != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: hidden ? '≈ ••• ${currency.toUpperCase()}' : '≈ ${localDigits(l, fiatText(BigInt.from(b.total), price, currency))}'), // l10n-ok: digits and the currency code
                            TextSpan(
                              text: l.deskOvFiatNote,
                              style: TextStyle(color: c.faint),
                            ),
                          ],
                        ),
                        style: ts.bodyDim,
                      ),
                  ],
                );
                if (box.maxWidth < 560.u) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      words,
                      SizedBox(height: Sp.x4),
                      actions,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: words),
                    SizedBox(width: Sp.x6),
                    actions,
                  ],
                );
              },
            ),
          ),
          SizedBox(height: shallow ? Sp.x6 : Sp.x5),
          if (!shallow) Divider(height: 1, color: c.line),
          if (!shallow)
          LayoutBuilder(
            builder: (context, box) {
              // The phone's order (GP-007); Available to spend is the big figure above.
              final items = <(String, int?, Widget?)>[
                (casual ? l.deskLvPayTileConfirming : l.deskOvBreakConfirming, b?.awaitingConfirmation, ERing(confirmations: 1, needed: deskMinConfirmations(ref), size: Ctl.iconSm)),
                // Loading draws the tiles most wallets have: no Immature (a miner's tile).
                if (b != null && b.immature > 0) (casual ? l.deskLvPayTileMining : l.deskOvBreakImmature, b.immature, Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim)),
                (casual ? l.deskLvPayTileAwaiting : l.deskOvBreakAwaiting, b == null ? null : b.awaitingFinalization - own - posted, Icon(EIcons.pencil, size: Ctl.iconSm, color: c.dim)),
                if (posted > 0) (l.deskTxStatusSenderPosted, posted, Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim)),
                (casual ? l.deskLvPayTileLocked : l.deskOvBreakLocked, b?.locked, Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim)),
                (l.deskOvBreakTotal, b?.total, Icon(EIcons.wallet, size: Ctl.iconSm, color: c.dim)),
              ];
              // One precision for every tile, the row surface as the phone's tiles (UP-016, C-01):
              // never computed from the data; the exact value is each tile's tooltip.
              const surface = AmountSurface.row;
              // One row when it fits; else rows of three (two for four tiles), the last row's
              // tiles stretching, so no tile is left alone beside an empty cell.
              final perRow = box.maxWidth >= items.length * 180.u ? items.length : (items.length == 4 ? 2 : 3);
              final rows = [for (var i = 0; i < items.length; i += perRow) items.sublist(i, i + perRow > items.length ? items.length : i + perRow)];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (r, row) in rows.indexed)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, it) in row.indexed)
                            Expanded(
                              child: _Break(
                                label: it.$1,
                                nano: it.$2,
                                lead: it.$3,
                                surface: surface,
                                width: box.maxWidth / row.length,
                                dim: updating,
                                hidden: hidden,
                                first: i == 0,
                                right: i < row.length - 1,
                                bottom: r < rows.length - 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UpdatingTag extends StatelessWidget {
  const _UpdatingTag();

  @override
  Widget build(BuildContext context) => EBadge(context.l10n.deskOvUpdating, busy: true, liveRegion: true);
}

/// The balance in Montserrat 44: whole part bright, the four decimals ([AmountSurface.hero], the one
/// display rule) dim, unit in mono. A hover shows the exact amount.
class _BigAmount extends StatelessWidget {
  const _BigAmount({required this.nano, required this.hidden, this.dim = false});

  final int nano;
  final bool hidden;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final canonical = surfaceEpic(BigInt.from(nano), AmountSurface.hero);
    final dot = canonical.indexOf('.');
    final whole = localDigits(l, dot < 0 ? canonical : canonical.substring(0, dot));
    final frac = dot < 0 ? '' : localDigits(l, canonical.substring(dot));
    final text = whole + frac;
    return LayoutBuilder(
      builder: (context, box) {
        final base = ts.display.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
        final unitStyle = ts.mono(size: Fs.md, weight: FontWeight.w500);
        final unitPainter = TextPainter(
          text: TextSpan(text: epicUnit, style: unitStyle),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final unitW = unitPainter.width;
        unitPainter.dispose();
        final size = fitFontSize(context, hidden ? '••••••' : text, base, const [Fs.display, Fs.h1, Fs.h2], box.maxWidth, extra: unitW + 10.u);
        final spans = hidden
            ? [const TextSpan(text: '••••••')]
            : [
                TextSpan(text: whole),
                TextSpan(
                  text: frac,
                  style: TextStyle(color: c.dim),
                ),
              ];
        final style = base.copyWith(fontSize: size, color: dim ? c.dim : null);
        // The row's width (amount, gap, unit) for the trace under it.
        final amountPainter = TextPainter(
          text: TextSpan(children: spans, style: style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final rowW = (amountPainter.width + 10.u + unitW).clamp(0.0, box.maxWidth);
        amountPainter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: hidden ? context.l10n.deskOvHiddenAmount : epicExact(l, BigInt.from(nano)),
              excludeSemantics: true,
              child: exactAmountTip(
                context,
                BigInt.from(nano),
                hidden: hidden,
                child: Row(
                key: const ValueKey('balance-row'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // Past the least size the figure scales down rather than cut to an
                  // ellipsis: a clipped balance reads as a different number (A-01).
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text.rich(
                        TextSpan(children: spans),
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.u),
                  Text(
                    epicUnit,
                    style: ts.mono(size: Fs.md, color: c.dim, weight: FontWeight.w500),
                  ),
                ],
                ),
              ),
            ),
            SizedBox(height: Sp.x4),
            _Trace(width: rowW),
          ],
        );
      },
    );
  }
}

/// The gold signal trace under the balance: as wide as the balance row, easing to a new
/// width when the balance changes (at once under reduced motion).
class _Trace extends StatelessWidget {
  const _Trace({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('balance-trace'),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Motion.expand,
    curve: Motion.easeOut,
    width: width,
    height: 26.u,
    child: CustomPaint(painter: _TracePainter(context.dc.accent)),
  );
}

class _Break extends StatelessWidget {
  const _Break({
    required this.label,
    required this.nano,
    required this.width,
    this.lead,
    this.first = false,
    this.right = false,
    this.bottom = false,
    this.dim = false,
    this.surface = AmountSurface.row,
    this.hidden = false,
  });

  /// Where the amounts sit, so their decimals: the same in every tile of the row.
  final AmountSurface surface;

  /// Amounts hidden: no exact value in the tooltip.
  final bool hidden;

  /// The cell's width, for fitting the amount.
  final double width;

  final String label;
  final int? nano;
  final Widget? lead;
  final bool first;
  final bool right;
  final bool bottom;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final zero = nano == 0;
    final side = BorderSide(color: c.line);
    return Container(
      padding: EdgeInsets.fromLTRB(first ? Sp.x8 : Sp.x5, Sp.x4, Sp.x5, Sp.x4),
      decoration: BoxDecoration(
        border: Border(right: right ? side : BorderSide.none, bottom: bottom ? side : BorderSide.none),
      ),
      // Label at the top, value at the bottom: values share one baseline when a label wraps.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (lead != null) ...[SizedBox(width: Ctl.iconSm, height: Ctl.iconSm, child: Center(child: lead!)), SizedBox(width: 6.u)],
              Flexible(
                child: Text(label, style: ts.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: Sp.x1),
            child: nano == null
              ? _Skeleton(width: 90.u, height: 16.u)
              : exactAmountTip(
                  context,
                  BigInt.from(nano!),
                  hidden: hidden,
                  child: FitMoney(
                    nano!,
                    surface: surface,
                    sizes: const [Fs.lg, Fs.md, Fs.sm, Fs.xs],
                    width: width - (first ? Sp.x8 : Sp.x5) - Sp.x5,
                    color: zero || dim ? c.faint : c.text,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The signal trace of the 700×26 original: x stretched to the panel, y scaled with the interface.
    final sx = size.width / 700;
    final pts = <Offset>[
      Offset(0, 13.u),
      Offset(150, 13.u),
      Offset(156, 4.u),
      Offset(164, 22.u),
      Offset(172, 8.u),
      Offset(178, 13.u),
      Offset(368, 13.u),
      Offset(374, 6.u),
      Offset(380, 20.u),
      Offset(386, 13.u),
      Offset(700, 13.u),
    ];
    final path = Path()..moveTo(pts.first.dx * sx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx * sx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) => old.color != color;
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: context.dc.s3, borderRadius: BorderRadius.circular(Rad.xs)),
  );
}

class _Recent extends StatelessWidget {
  const _Recent({required this.txs, required this.onOpen, required this.onAll, this.shallow = false});

  final List<Tx>? txs;

  /// Shallow: no mining rows, and an empty state that is only its title.
  final bool shallow;
  final ValueChanged<Tx> onOpen;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final list = txs;
    Widget body;
    if (list == null) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: Sp.x10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ESpinner(),
            SizedBox(width: Sp.x3),
            Text(l.deskOvLoading, style: context.ts.bodyDim),
          ],
        ),
      );
    } else if (list.isEmpty) {
      body = Builder(
        builder: (context) => Consumer(
          builder: (context, ref, _) => shallow
              ? EEmpty(icon: EIcons.receive, title: l.deskOvEmptyTitle)
              : EEmpty(
                  icon: EIcons.receive,
                  title: l.deskOvEmptyTitle,
                  text: l.deskOvEmptyText(deskMinConfirmations(ref)),
                  actions: [
                    // The hero's Receive EPIC is the primary: one per screen.
                    EButton(label: l.deskOvShowAddress, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.receive)),
                    EButton.ghost(label: l.deskOvReceiveFile, size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.importTx)),
                  ],
                ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final (i, t) in (shallow ? list.where((t) => !t.immature) : list).take(recentActivityCount).indexed) ...[if (i > 0) Divider(height: 1, color: c.line), TxRow(tx: t, compact: true, onTap: () => onOpen(t))],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(
          l.deskOvRecent,
          top: Sp.x6,
          trailing: list == null || !showViewAll(list.length) ? null : ELink(label: l.deskOvViewAll(list.length), onPressed: onAll),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.s1,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(Rad.sm),
          ),
          child: body,
        ),
      ],
    );
  }
}

/// Shallow's one sentence under the balance: what is moving, in two parts at most ("+12.5000
/// arriving from Bob · 25.0000 on hold until Alice signs"). Nothing when nothing moves.
class _HeroSentence extends StatelessWidget {
  const _HeroSentence({required this.txs, required this.hidden});

  final List<Tx> txs;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final arriving = [for (final t in txs) if (t.incoming && payInFlight(t)) t];
    final held = [for (final t in txs) if (!t.incoming && t.state == TxState.waitingRecipient && !t.notPosted && payInFlight(t)) t];
    String money(List<Tx> of) => hidden ? '••••••' : formatEpicL(l, of.fold<int>(0, (sum, t) => sum + t.amount));
    final parts = <(IconData, Color, String)>[
      if (arriving.isNotEmpty)
        (
          EIcons.clock,
          c.info,
          arriving.length == 1 && arriving.first.contactName != null ? l.deskLvPayHeroArriving(money(arriving), arriving.first.contactName!) : l.deskLvPayHeroArrivingMany(money(arriving)),
        ),
      if (held.isNotEmpty)
        (
          EIcons.lock,
          c.dim,
          held.length == 1 && held.first.contactName != null ? l.deskLvPayHeroHold(money(held), held.first.contactName!) : l.deskLvPayHeroHoldMany(money(held)),
        ),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      key: const ValueKey('overview-hero-sentence'),
      spacing: Sp.x2,
      runSpacing: Sp.x1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, (icon, color, text)) in parts.indexed) ...[
          if (i > 0) Text('·', style: ts.small.copyWith(color: c.faint)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: Ctl.iconSm, color: color)),
              SizedBox(width: Sp.x1),
              Flexible(child: Text(text, style: ts.small.copyWith(color: color))),
            ],
          ),
        ],
      ],
    );
  }
}

/// The payments under way, each a card with its live steps ("On its way to Alice"): above
/// Recent activity at every level (D11). The newest three.
class _InFlight extends ConsumerWidget {
  const _InFlight({required this.txs, required this.onOpen});

  final List<Tx> txs;
  final ValueChanged<Tx> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = txs.where(payInFlight).take(3).toList();
    if (live.isEmpty) return const SizedBox.shrink();
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final technical = ref.watch(deskLevelFeaturesProvider.select((f) => f.wording)) == LevelWording.technical;
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in live)
          Padding(
            padding: EdgeInsets.only(top: Sp.x4),
            child: Semantics(
              button: true,
              onTap: () => onOpen(t),
              child: Container(
                key: ValueKey('overview-inflight-${t.id}'),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.s1,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(Rad.sm),
                ),
                // The accent bar is drawn under the card, not laid out beside it: the steps
                // measure their own width (no intrinsic sizes here).
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(width: 3, child: ColoredBox(color: c.info, child: const SizedBox.expand())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => onOpen(t),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    ExcludeSemantics(child: TxIcon(t)),
                                    SizedBox(width: Sp.x4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_title(l, t, technical), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.strong),
                                          Text(
                                            l.deskLvPayStartedAt(hidden ? '••••••' : formatEpicL(l, t.amount), timeOf(t)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: ts.small,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: Sp.x4),
                                    ExcludeSemantics(child: TxAmount(t, showFee: false)),
                                  ],
                                ),
                                SizedBox(height: Sp.x4),
                                DeskPaymentSteps(tx: t, dense: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// "On its way to Alice" (Deep end: "Sending to Alice"); a payment coming in reads "Arriving
  /// from Bob". The Deep end names an address when no contact does.
  String _title(AppLocalizations l, Tx t, bool technical) {
    final name = t.contactName ?? (technical ? whoOf(l, t) : null);
    if (t.incoming) return name == null ? l.lvPayArriving : l.deskLvPayArrivingFrom(name);
    if (name == null) return l.lvPayOnItsWay;
    return technical ? l.deskLvPaySendingTo(name) : l.deskLvPayOnItsWayTo(name);
  }
}

class _PendingFiles extends ConsumerWidget {
  const _PendingFiles({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: EdgeInsets.only(top: Sp.x3),
    child: ENotice(
      tone: ETone.info,
      icon: EIcons.file,
      title: context.l10n.deskOvPendingFiles(count),
      text: context.l10n.deskOvPendingText,
      actions: [
        EButton(label: context.l10n.deskOvFinalize, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize)),
      ],
    ),
  );
}
