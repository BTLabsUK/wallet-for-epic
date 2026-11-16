// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../announcements/announcement_card.dart' show AnnouncementToast, firstLiveAnnouncementProvider;
import '../../../connection_grace.dart' show connectionGraceProvider;
import '../../../network_gate.dart' show NetBlock, NetBlockByMode, NetGate;
import '../../../price.dart' show fiatChoiceProvider, fiatText, priceProvider;
import '../../../trust_ids.dart';
import '../../app/desk_failover.dart' show deskNodeHealthProvider;
import '../../app/relay_offer.dart' show DeskRelayNotice;
import '../../app/shell_notices.dart' show DeskShellNotices, deskShellNoticesShownProvider;
import '../../app/tour.dart';
import '../../data/invoice_state.dart' show deskInvoicesProvider;
import '../../data/pairing_state.dart' show deskInvoicesShownProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../../amount.dart' show AmountSurface, atomicPerEpic, epicUnit, surfaceEpic;
import '../../../l10n.dart' show localDigits, localInt;
import '../../../ui/common.dart' show epicExact, exactAmountTip;
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart' show DeskPaymentSteps, PayAccentBox, PayStepDots, payInFlight, payStepList, payStepNowText;
import '../invoices/overview_card.dart';
import '../settings/backup.dart' show HistoryReminder, historyBackupProvider, showHistoryImportOffer;
import '../settings/prefs.dart' show SettingsJump, settingsPrefsProvider;
import '../../../recent_activity.dart' show recentActivityCount, showViewAll;
import '../../../ui/theme/lattice.dart' show BrandLattice, latticeCellDesktop, latticeStrength;
import 'activity_screen.dart' show ActivityArgs;
import 'home_contacts.dart';
import 'home_chart.dart';
import 'home_field.dart';
import 'restore_scan_panel.dart';
import '../scan/desk_scan.dart' show DeskScanButton;
import '../scan/desk_scan_route.dart';
import '../../../ui/via.dart';
import 'tx_display.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../../settings_file/host_settings.dart' show hostSettings;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;

/// States the tour can start Overview in.
enum OverviewShot { loading, empty, nodeDown, starting, syncing, nodeProblem }

/// Mock sync state for [OverviewShot.syncing].
const double _syncPart = 0.62;
const int _walletTip = 2903118;

/// How a screenshot state reads on the balance panel: [busy] updating, [asOfBlock] the
/// wallet's height while the node syncs, [sendBlocked] Send waits, [nodeTrouble] the node
/// answers but cannot be used. A live Overview (no shot) has none of them.
({bool busy, int? asOfBlock, bool sendBlocked, bool nodeTrouble}) _shotBalance(OverviewShot? shot) => (
  busy: shot == OverviewShot.starting || shot == OverviewShot.syncing,
  asOfBlock: shot == OverviewShot.syncing ? _walletTip : null,
  sendBlocked: shot == OverviewShot.syncing || shot == OverviewShot.nodeProblem,
  nodeTrouble: shot == OverviewShot.nodeProblem,
);

/// Home: the balance (the one framed object), what is in motion and recent activity; the
/// service state lives in the status bar.
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  bool _refreshing = false;
  bool _restarting = false;

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
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shot = widget.arg is OverviewShot ? widget.arg! as OverviewShot : null;
    final s = ref.watch(deskProvider);
    final hidden = s.settings.hideAmounts;
    final loading = shot == OverviewShot.loading || s.balance == null;
    // The scan a restore owes: its progress, not the empty-wallet state.
    final restore = shot == null ? s.status?.restoreScan : null;
    final empty = shot == OverviewShot.empty || (shot == null && restore == null && s.balance?.total == 0 && (s.txs?.isEmpty ?? false));
    final shotView = _shotBalance(shot);
    // Offline (but with a local node) and Tor only: the node is not asked, so its last answer
    // is not news.
    final netBlock = shot == null ? deskNetBlock(s, nodeOnly: true) : NetBlock.none;
    final offline = netBlock.byMode;
    final nodeDown = shot == OverviewShot.nodeDown || (shot == null && netBlock == NetBlock.none && ref.watch(deskNodeHealthProvider) == ServiceHealth.down);
    // Its notice waits out the connection grace after the start or a return (item 11): the
    // status icon alone says Connecting meanwhile.
    final nodeDownSaid = nodeDown && (shot != null || !ref.watch(connectionGraceProvider));
    // The wallet's own sync (a refresh or a scan), not the node's.
    final walletSync = shot == null && s.status?.syncProgress != null;
    final balance = empty ? const Balance(spendable: 0, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0) : s.balance;
    final txs = empty ? const <Tx>[] : (shot == OverviewShot.loading ? null : s.txs);
    final nav = ref.read(deskNavProvider.notifier);
    final nodeUrl = shownUrl(s.status?.node.url ?? hostSettings.nodeFallback);

    final recent = _Recent(txs: txs, onOpen: (t) => nav.go(DeskRoute.activity, t.id), onAll: () => nav.go(DeskRoute.activity));
    final pending = empty ? 0 : s.pendingFiles;
    // The payment the In motion card shows, when it is a file send waiting for its response.
    final top = txs?.where(payInFlight).firstOrNull;
    final onCard = top != null && _waitsForFile(top) ? 1 : 0;
    final gap = SizedBox(height: Sp.x4);
    final book = ref.watch(deskInvoicesProvider);
    final invoicesWait = book != null && (book.waiting.isNotEmpty || book.openRequests.isNotEmpty || book.needsAction.isNotEmpty);

    // A restored wallet's first unlock asks once about its history backup, after the
    // first-run tour, never over it.
    final tour = ref.watch(deskTourProvider);
    if (shot == null && !_importOffered && tour.seen && !tour.open && (ref.watch(historyBackupProvider).value?.importOffer ?? false)) {
      _importOffered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showHistoryImportOffer(context, ref));
      });
    }
    final notices = _notices(context, s, restore: restore, nodeDownSaid: nodeDownSaid, nodeUrl: nodeUrl, netBlock: netBlock);

    // The Epicbox server offer and the move as toasts (item 16), not cards in the layout.
    return DeskRelayNotice(
      child: EPage(
        title: l.deskOvTitle,
        header: false,
        width: EPageWidth.full,
        // The BT Labs lattice in the room a short Recent activity leaves, fading as rows come.
        fill: restore == null || (s.txs?.isNotEmpty ?? false)
            ? BrandLattice(
                // Light draws it in the brand brown, stronger: the text colour at the dark
                // theme's alpha is a smudge on paper.
                color: context.dc.wash.a == 0 ? context.dc.text : context.dc.accentDeep,
                strength: latticeStrength(txs?.length),
                cell: latticeCellDesktop.u,
                vignette: true,
                gain: context.dc.wash.a == 0 ? 1 : 1.6,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final n in notices) ...[n, gap],
            if (shot != null) _ShotNotices(shot: shot, nodeUrl: nodeUrl, restarting: _restarting, onRestartNode: _restartNode),
            TourTarget(
              id: 'balance',
              child: _BalancePanel(
                balance: loading ? null : balance,
                empty: empty,
                hidden: hidden,
                // Not beside "Cannot reach the node": a refresh still waiting on a node that does
                // not answer (packets dropped) only ends at its timeout.
                updating: _refreshing || (!offline && !nodeDown && (shotView.busy || loading || walletSync)),
                offline: offline,
                asOfBlock: shotView.asOfBlock,
                sendBlocked: shotView.sendBlocked || nodeDown,
                nodeAnswers: !(nodeDown || shotView.nodeTrouble),
                // While it runs the "Updating" tag is the one indicator; the slot stays, empty,
                // so nothing moves.
                refresh: _refreshing
                    ? SizedBox.square(dimension: Ctl.inline)
                    : EIconButton(
                        semanticsId: TrustIds.overviewRefresh,
                        icon: EIcons.refresh,
                        size: EBtnSize.inline,
                        label: netBlock == NetBlock.killSwitch ? l.recheckOffKill : (netBlockReason(l, netBlock) ?? l.deskOvRefresh),
                        onPressed: netBlock == NetBlock.none ? _refresh : null,
                      ),
              ),
            ),
            // The field: what to pay, typed or pasted (home_field.dart). Not in an empty wallet,
            // where Receive is the one thing to do.
            if (!empty) ...[SizedBox(height: Sp.x4), const TourTarget(id: 'field', child: HomeField())],
            // Something to act on goes first; a quiet card stays below Recent activity.
            if (invoicesWait) const OverviewInvoicesCard(),
            // A payment in progress: its steps live (D11).
            if (txs != null) _InFlight(txs: txs, onOpen: (t) => nav.go(DeskRoute.activity, t.id), onMore: () => nav.go(DeskRoute.activity, const ActivityArgs(pending: true))),
            // While the restore scan runs, Recent activity shows what it finds, never "No
            // transactions yet" (copy D1). The contacts used last stand beside it in a window
            // with the room, under it otherwise.
            if (restore == null || (s.txs?.isNotEmpty ?? false))
              LayoutBuilder(
                builder: (context, box) => box.maxWidth >= Lay.xl && (s.contacts?.isNotEmpty ?? false)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: recent),
                          // Wide enough that Recent activity's "View all" does not run into the Contacts title.
                          SizedBox(width: Sp.x10),
                          SizedBox(width: 340.u, child: const HomeContacts()),
                        ],
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [recent, const HomeContacts()]),
              ),
            // The file sends to finish that the card above does not already offer.
            if (pending - onCard > 0) _PendingFiles(count: pending - onCard),
            if (!invoicesWait) const OverviewInvoicesCard(),
          ],
        ),
      ),
    );
  }

  /// The notices above the balance, most pressing last: the shell's, a restore's scan, the
  /// node's and Tor's.
  List<Widget> _notices(
    BuildContext context,
    DeskState s, {
    required RestoreScan? restore,
    required bool nodeDownSaid,
    required String nodeUrl,
    required NetBlock netBlock,
  }) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final announcement = ref.watch(firstLiveAnnouncementProvider);
    return [
      // A message from BT Labs, on the notices' surface: one at a time, until dismissed.
      if (announcement != null)
        DecoratedBox(
          key: const ValueKey('overview-announcement'),
          decoration: BoxDecoration(
            color: context.dc.s1,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: context.dc.lineStrong),
          ),
          child: AnnouncementToast(announcement, dense: true),
        ),
      // The shell's notice; the Epicbox server offer is a toast.
      if (ref.watch(deskShellNoticesShownProvider)) const DeskShellNotices(),
      if (restore != null) RestoreScanPanel(scan: restore),
      if (ref.watch(historyBackupProvider).value case final backup? when backup.reminder != null && !backup.importOffer) HistoryReminder(state: backup),
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
      // Tor only, Tor not up yet: the node waits for it (in progress, as Send and Receive say).
      if (netBlock == NetBlock.waitingForTor)
        ENotice(
          key: const ValueKey('overview-waiting-tor'),
          tone: ETone.info,
          title: l.netBlockWaitingForTorLong,
          actions: [EButton(label: l.netChangeLink, size: EBtnSize.inline, onPressed: () => ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network))],
        ),
    ];
  }
}

/// The notices of the states a live Overview only passes through, which only a screenshot
/// holds still (the tour, the screenshot tool): just unlocked, the node syncing, a node that
/// cannot be used. Each with the gap the live notices have under them.
class _ShotNotices extends ConsumerStatefulWidget {
  const _ShotNotices({required this.shot, required this.nodeUrl, required this.restarting, required this.onRestartNode});

  final OverviewShot shot;
  final String nodeUrl;
  final bool restarting;
  final VoidCallback onRestartNode;

  @override
  ConsumerState<_ShotNotices> createState() => _ShotNoticesState();
}

class _ShotNoticesState extends ConsumerState<_ShotNotices> {
  bool _problemHidden = false;
  bool _addressNoteHidden = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final nodeProblem = widget.shot == OverviewShot.nodeProblem;
    final notices = <Widget>[
      if (widget.shot == OverviewShot.starting) const _Steps(),
      if (nodeProblem && !_addressNoteHidden)
        ENotice(
          icon: EIcons.info,
          title: l.deskOvNodeAddrTitle,
          text: l.deskOvNodeAddrText(hostPort(hostSettings.nodeUse)),
          actionsBelow: true,
          actions: [EButton(label: l.commonOk, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _addressNoteHidden = true))],
        ),
      if (nodeProblem && !_problemHidden)
        ENotice(
          tone: ETone.risk,
          title: l.deskOvNodeIncompatTitle,
          text: l.deskOvNodeUrl(widget.nodeUrl),
          actionsBelow: true,
          actions: [
            EButton(label: l.deskOvUsePublicNode, icon: EIcons.web, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsNode)),
            if (advancedHas(ref, AdvancedFeature.builtInNode))
              EButton(label: l.deskOvUseLocalNode, icon: EIcons.server, size: EBtnSize.inline, busy: widget.restarting, onPressed: widget.onRestartNode),
            EButton(label: l.deskOvHide, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _problemHidden = true)),
          ],
        ),
      if (widget.shot == OverviewShot.syncing) const _SyncNotice(part: _syncPart, walletTip: _walletTip),
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final n in notices) ...[n, SizedBox(height: Sp.x4)]],
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


class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({required this.balance, required this.empty, required this.hidden, required this.refresh, this.updating = false, this.asOfBlock, this.sendBlocked = false, this.nodeAnswers = true, this.offline = false});

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

  /// Refresh, at the end of the label's row.
  final Widget refresh;

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
    // The value in the chosen currency and what one EPIC costs, between the figure and its trace.
    final fiat = price == null || b == null
        ? null
        : Wrap(
            spacing: Sp.x3p5,
            runSpacing: Sp.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: hidden ? '≈ ••• ${currency.toUpperCase()}' : '≈ ${localDigits(l, fiatText(BigInt.from(b.figure(own)), price, currency))}'), // l10n-ok: digits and the currency code
                    TextSpan(text: l.deskOvFiatNote, style: TextStyle(color: c.faint)),
                  ],
                ),
                style: ts.mono(size: Fs.lg, weight: FontWeight.w500),
              ),
              Text('${withUnit(localDigits(l, '1'), epicUnit)} = ${localDigits(l, fiatText(atomicPerEpic, price, currency))}', style: ts.mono(size: Fs.sm, color: c.dim)), // l10n-ok: digits and units
            ],
          );
    final amount = b == null
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Skeleton(width: 260.u, height: 40.u), SizedBox(height: Sp.x4), _Trace(width: 260.u)])
        : _BigAmount(nano: b.figure(own), hidden: hidden, dim: updating, under: fiat);
    // The parts of the balance that are not zero, in the phone's order (GP-007), then the total
    // when it is more than the figure above. One precision for all of them (UP-016, C-01).
    final parts = <(String, int)>[
      if (b != null) ...[
        if (b.awaitingConfirmation > 0) (l.deskPayTileConfirming, b.awaitingConfirmation),
        if (b.immature > 0) (l.deskPayTileMining, b.immature),
        if (b.awaitingFinalization - own - posted > 0) (l.deskPayTileAwaiting, b.awaitingFinalization - own - posted),
        if (posted > 0) (l.deskTxStatusSenderPosted, posted),
        if (b.locked > 0) (l.deskPayTileLocked, b.locked),
        if (b.total != b.figure(own)) (l.deskOvBreakTotal, b.total),
      ],
    ];
    final buttons = <Widget>[
      if (empty)
        EButton.primary(semanticsId: TrustIds.navReceive, label: l.deskOvReceiveEpic, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive))
      else ...[
        // Send is the one main action here; it and Receive carry the ids the tabs had.
        EButton.primary(semanticsId: TrustIds.navSend, label: l.deskOvSend, icon: EIcons.send, onPressed: sendBlocked ? null : () => nav.go(DeskRoute.send)),
        EButton(semanticsId: TrustIds.navReceive, label: l.deskOvReceive, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
        if (ref.watch(deskInvoicesShownProvider)) EButton(key: const ValueKey('home-request'), label: l.deskOvRequest, icon: EIcons.request, onPressed: () => nav.go(DeskRoute.invoiceIssue)),
        // Scan reads any code and opens it like a link; greyed out with no camera.
        DeskScanButton(key: const ValueKey('home-scan'), label: l.deskOvScan, onScan: () => unawaited(openDeskScan(context, ref)), size: EBtnSize.md),
      ],
    ];
    return ETicked(
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 560.u;
          final words = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: Sp.x2,
                      runSpacing: Sp.x1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        trustId(TrustIds.overviewAvailable, Text(l.deskOvBalance, style: ts.small)),
                        if (asOfBlock != null) EBadge(l.deskOvAsOfBlock(localInt(l, asOfBlock!)), tone: ETone.warn),
                        if (updating && asOfBlock == null) const _UpdatingTag(),
                        if (offline) EBadge(l.lastKnownCaption, key: const ValueKey('overview-offline')),
                      ],
                    ),
                  ),
                  SizedBox(width: Sp.x1),
                  refresh,
                ],
              ),
              amount,
              SizedBox(height: Sp.x1p5),
              // What Send can use, when a send's change or a payment is still confirming, then
              // the parts of the balance.
              if (b != null && (parts.isNotEmpty || b.spendable != b.figure(own)))
                Wrap(
                  spacing: Sp.x3p5,
                  runSpacing: Sp.x1,
                  children: [
                    Text(l.deskOvSpendableNow(hidden ? '••••••' : epicTextL(l, b.spendable)), key: const ValueKey('overview-spendable-now'), style: ts.small),
                    for (final (label, nano) in parts)
                      Row(
                        key: ValueKey('overview-part-$label'),
                        mainAxisSize: MainAxisSize.min,
                        spacing: Sp.x1p5,
                        children: [
                          // A long label gives way in a narrow window; the amount never does.
                          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small)),
                          FitMoney(nano, sizes: const [Fs.sm], surface: AmountSurface.row, color: updating ? c.dim : c.text),
                        ],
                      ),
                  ],
                ),
              if (empty) Text(l.deskOvEmptyHint, style: ts.small),
            ],
          );
          // Two by two beside the balance; one row under it in a narrow window, two by two
          // again where four would not hold their labels.
          final perRow = buttons.length == 1 ? 1 : (narrow && box.maxWidth >= 440.u ? buttons.length : 2);
          final grid = Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Sp.x2,
            children: [
              for (var i = 0; i < buttons.length; i += perRow)
                Row(
                  spacing: Sp.x2,
                  children: [
                    for (var j = i; j < i + perRow; j++) Expanded(child: j < buttons.length ? EButtonFill(child: buttons[j]) : const SizedBox.shrink()),
                  ],
                ),
              if (sendBlocked && !empty) Text(nodeAnswers ? l.deskOvSendWaits : l.deskOvSendWaitsNode, style: ts.small),
            ],
          );
          return Padding(
            padding: narrow ? EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4p5) : EdgeInsets.symmetric(horizontal: 28.u, vertical: Sp.x5p5),
            child: narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [words, SizedBox(height: Sp.x4), grid])
                : Row(
                    children: [
                      Expanded(child: words),
                      // The last 30 days between the balance and the buttons, where there is room.
                      if (!hidden && !empty && b != null && txs.isNotEmpty && box.maxWidth >= 1000.u) ...[
                        SizedBox(width: Sp.x8),
                        Expanded(child: HomeChart(txs: txs, total: b.total)),
                      ],
                      SizedBox(width: Sp.x10),
                      SizedBox(width: 288.u, child: grid),
                    ],
                  ),
          );
        },
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
  const _BigAmount({required this.nano, required this.hidden, this.dim = false, this.under});

  final int nano;
  final bool hidden;
  final bool dim;

  /// Between the figure and its trace: the value in the chosen currency.
  final Widget? under;

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
                    SizedBox(width: Sp.x2p5),
                    Text(
                      epicUnit,
                      style: ts.mono(size: Fs.md, color: c.dim, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (under != null) ...[SizedBox(height: Sp.x1), under!],
            SizedBox(height: Sp.x3),
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
  const _Recent({required this.txs, required this.onOpen, required this.onAll});

  final List<Tx>? txs;
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
          builder: (context, ref, _) => EEmpty(
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
          for (final (i, t) in list.take(recentActivityCount).indexed) ...[if (i > 0) Divider(height: 1, color: c.line), TxRow(tx: t, compact: true, onTap: () => onOpen(t))],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No title over the empty state: it comes back with the first payment.
        if (list != null && list.isEmpty)
          SizedBox(height: Sp.x6)
        else
          ESectionHead(
            l.deskOvRecent,
            top: Sp.x6,
            trailing: list == null || !showViewAll(list.length) ? null : ELink(label: l.deskOvViewAll(list.length), onPressed: onAll),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: panelBox(c),
          child: body,
        ),
      ],
    );
  }
}

/// The payments under way, above Recent activity (D11): the newest as a card with
/// its live steps ("On its way to Alice"), the next three as one line each in a box under it,
/// then "N more · View" (Activity, Pending) for the rest.
class _InFlight extends ConsumerWidget {
  const _InFlight({required this.txs, required this.onOpen, required this.onMore});

  final List<Tx> txs;
  final ValueChanged<Tx> onOpen;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = txs.where(payInFlight).toList();
    if (live.isEmpty) return const SizedBox.shrink();
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    final t = live.first;
    // One name for the title and the steps.
    final name = deskTxMailboxName(ref, t, any: true) ?? t.contactName;
    // A file send that waits for the recipient's file: the next step is on its card, beside
    // the amount, or under the title in a window too narrow for both.
    final reply = _waitsForFile(t)
        ? EButton(key: const ValueKey('home-open-reply'), label: l.sendOpenReply, size: EBtnSize.sm, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize))
        : null;
    final roomy = MediaQuery.sizeOf(context).width >= Lay.lg;
    final rows = live.skip(1).take(3).toList();
    final more = live.length - 1 - rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(l.deskOvInMotion, top: Sp.x6),
        PayAccentBox(
            key: ValueKey('overview-inflight-${t.id}'),
            child: Semantics(
              button: true,
              onTap: () => onOpen(t),
              child: EInkWell(
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
                                Text(_inFlightTitle(l, t, name), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.strong),
                                Text(
                                  l.deskPayStartedAt(hidden ? '••••••' : formatEpicL(l, t.amount), timeOf(t)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts.small,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: Sp.x4),
                          ExcludeSemantics(child: TxAmount(t, showFee: false)),
                          if (reply != null && roomy) ...[SizedBox(width: Sp.x4), reply],
                        ],
                      ),
                      if (reply != null && !roomy) Padding(padding: EdgeInsets.only(top: Sp.x3), child: Align(alignment: AlignmentDirectional.centerStart, child: reply)),
                      SizedBox(height: Sp.x4),
                      DeskPaymentSteps(tx: t, name: name, dense: true),
                    ],
                  ),
                ),
              ),
            ),
        ),
        if (rows.isNotEmpty || more > 0)
          Padding(
            padding: EdgeInsets.only(top: Sp.x3),
            child: PayAccentBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, r) in rows.indexed) ...[
                    if (i > 0) Divider(height: 1, color: c.line),
                    _InFlightRow(key: ValueKey('overview-inflight-row-${r.id}'), tx: r, onOpen: onOpen),
                  ],
                  if (more > 0) ...[
                    if (rows.isNotEmpty) Divider(height: 1, color: c.line),
                    Padding(
                      key: const ValueKey('overview-inflight-more'),
                      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(l.deskOvInflightMore(more), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: c.dim)),
                          ),
                          SizedBox(width: Sp.x3),
                          ELink(label: l.deskOvInflightView, onPressed: onMore),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A file send that waits for the recipient's response file (what [DeskState.pendingFiles] counts).
bool _waitsForFile(Tx t) => t.method == TxMethod.file && t.state == TxState.waitingRecipient && !t.incoming;

/// A payment under way on one line: who, the step it is at in words, the five steps as dots
/// (dropped when the row is narrow), the amount.
class _InFlightRow extends ConsumerWidget {
  const _InFlightRow({super.key, required this.tx, required this.onOpen});

  final Tx tx;
  final ValueChanged<Tx> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final name = deskTxMailboxName(ref, tx, any: true) ?? tx.contactName;
    final steps = payStepList(l, tx, name: name);
    final title = _inFlightTitle(l, tx, name);
    final step = payStepNowText(steps);
    return Semantics(
      button: true,
      label: '$title, $step',
      excludeSemantics: true,
      onTap: () => onOpen(tx),
      child: EInkWell(
        onTap: () => onOpen(tx),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                TxIcon(tx, size: 28.u),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.strong),
                      Text(step, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: c.info)),
                    ],
                  ),
                ),
                if (box.maxWidth >= Lay.sm) ...[SizedBox(width: Sp.x4), PayStepDots(steps)],
                SizedBox(width: Sp.x4),
                TxAmount(tx, showFee: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "On its way to Alice"; a payment coming in reads "Arriving from Bob". [name] is the name the
/// steps use. With none, the way names it ("via file", "in person"), else the address.
String _inFlightTitle(AppLocalizations l, Tx t, String? name) {
  final via = name == null ? viaOf(t) : null;
  if (via == Via.inPerson && !t.incoming) return l.deskPaySendingInPerson;
  if (via != null) return t.incoming ? l.deskPayArrivingVia(viaPhrase(l, via)) : l.deskPaySendingVia(viaPhrase(l, via));
  final who = name ?? whoOf(l, t);
  return t.incoming ? l.deskPayArrivingFrom(who) : l.deskPayOnItsWayTo(who);
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
