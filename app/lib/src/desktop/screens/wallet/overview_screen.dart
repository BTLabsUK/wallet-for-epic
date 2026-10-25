import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network_gate.dart' show NetBlock;
import '../../app/tour.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../../l10n.dart' show localDigits, localInt;
import '../../widgets/kit.dart';
import '../invoices/overview_card.dart';
import '../settings/backup.dart' show HistoryImportOffer, HistoryReminder, historyBackupProvider;
import '../settings/prefs.dart' show settingsPrefsProvider;
import 'restore_scan_panel.dart';
import 'tx_display.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;

/// States the tour can start Overview in.
enum OverviewDemo { loading, empty, nodeDown, starting, syncing, nodeProblem }

/// Mock price for the fiat line.
const double _usdPerEpic = 0.42;

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
    final hidden = s.settings.hideAmounts;
    final loading = demo == OverviewDemo.loading || s.balance == null;
    // The scan a restore owes: its progress, not the empty-wallet state (R16, R35).
    final restore = demo == null ? s.status?.restoreScan : null;
    final empty = demo == OverviewDemo.empty || (demo == null && restore == null && s.balance?.total == 0 && (s.txs?.isEmpty ?? false));
    final starting = demo == OverviewDemo.starting;
    final syncing = demo == OverviewDemo.syncing;
    // Offline (but with a local node) and Tor only: the node is not asked, so its last answer
    // is not news.
    final netBlock = demo == null ? deskNetBlock(s, nodeOnly: true) : NetBlock.none;
    final offline = netBlock == NetBlock.offline;
    final nodeDown = demo == OverviewDemo.nodeDown || (demo == null && netBlock == NetBlock.none && s.status?.nodeHealth == ServiceHealth.down);
    // The wallet's own sync (a refresh or a scan), not the node's.
    final walletSync = demo == null && s.status?.syncProgress != null;
    final balance = empty ? const Balance(spendable: 0, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0) : s.balance;
    final txs = empty ? const <Tx>[] : (demo == OverviewDemo.loading ? null : s.txs);
    final nav = ref.read(deskNavProvider.notifier);
    final nodeUrl = (s.status?.node.url ?? 'https://node.epiccash.com').replaceFirst(RegExp(r'^https?://'), '');

    final recent = _Recent(txs: txs, onOpen: (t) => nav.go(DeskRoute.activity, t.id), onAll: () => nav.go(DeskRoute.activity));
    final pending = empty ? 0 : s.pendingFiles;
    final gap = SizedBox(height: Sp.x4);

    final notices = <Widget>[
      if (restore != null) RestoreScanPanel(scan: restore),
      if (s.status?.notice != null) ENotice(tone: ETone.warn, icon: EIcons.alert, title: s.status!.notice!),
      if (ref.watch(historyBackupProvider).value case final backup? when backup.importOffer) const HistoryImportOffer(),
      if (ref.watch(historyBackupProvider).value case final backup? when backup.reminder != null && !backup.importOffer) HistoryReminder(state: backup),
      if (starting) const _Steps(),
      if (demo == OverviewDemo.nodeProblem && !_addressNoteHidden)
        ENotice(
          icon: EIcons.info,
          title: l.deskOvNodeAddrTitle,
          text: l.deskOvNodeAddrText,
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
            if (DeskFeatures.builtInNode && advancedHas(ref, AdvancedFeature.builtInNode)) EButton(label: l.deskOvUseLocalNode, icon: EIcons.server, size: EBtnSize.inline, busy: _restarting, onPressed: _restartNode),
            EButton(label: l.deskOvHide, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _problemHidden = true)),
          ],
        ),
      if (nodeDown)
        ENotice(
          tone: ETone.risk,
          title: l.deskOvCantReachNode(nodeUrl),
          text: l.deskOvCantReachNodeText,
          actionsBelow: true,
          actions: [
            if (DeskFeatures.builtInNode && ref.watch(settingsPrefsProvider).builtin)
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
    ];

    return EPage(
      title: l.deskOvTitle,
      width: EPageWidth.full,
      actions: [
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
                label: netBlockReason(l, netBlock) ?? l.deskOvRefresh,
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
              updating: !offline && (starting || syncing || loading || walletSync),
              offline: offline,
              asOfBlock: syncing ? _walletTip : null,
              sendBlocked: syncing || nodeDown || demo == OverviewDemo.nodeProblem || restore != null,
              restoring: restore != null,
            ),
          ),
          SizedBox(height: Sp.x2),
          recent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ENotice(
          tone: ETone.warn,
          icon: EIcons.server,
          title: l.deskOvSyncTitle((part * 100).round()),
          text: l.deskOvSyncText(_group(l, walletTip)),
        ),
        SizedBox(height: Sp.x2),
        Semantics(
          label: l.deskOvSyncProgress,
          value: '${(part * 100).round()}%',
          child: EProgress(value: part),
        ),
        SizedBox(height: Sp.x1),
        Text(l.deskOvSyncOfChain((part * 100).round()), style: ts.caption),
      ],
    );
  }
}

String _group(AppLocalizations l, int n) => localInt(l, n);

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({required this.balance, required this.empty, required this.hidden, this.updating = false, this.asOfBlock, this.sendBlocked = false, this.restoring = false, this.offline = false});

  final Balance? balance;
  final bool empty;
  final bool hidden;

  /// Not yet checked against the node: amounts dimmed, "Updating" tag.
  final bool updating;
  final int? asOfBlock;

  /// The node is not synced: Send waits, and says why.
  final bool sendBlocked;

  /// A restore's scan has not ended: Send waits for it, and says so.
  final bool restoring;

  /// Offline mode: the amounts are the last known ones, marked as such.
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final b = balance;
    // What senders report posted leaves Awaiting finalization for its own line, named as its
    // rows are; it is still not in a block, so not in Total (LNX-13).
    final reported = (ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[])
        .where((t) => t.incoming && t.senderPosted)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final posted = b == null ? 0 : reported.clamp(0, b.awaitingFinalization);
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
                  EButton.primary(label: l.deskOvSend, icon: EIcons.send, onPressed: sendBlocked ? null : () => nav.go(DeskRoute.send)),
                  EButton(label: l.deskOvReceive, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
                ],
        ),
        if (sendBlocked && !empty) ...[
          SizedBox(height: Sp.x2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 240.u),
            child: Text(restoring ? l.deskRsSendWaits : l.deskOvSendWaits, style: ts.small),
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
                        if (offline) EBadge(l.deskRailOffline, key: const ValueKey('overview-offline')),
                      ],
                    ),
                    SizedBox(height: 6.u),
                    amount,
                    SizedBox(height: 6.u),
                    if (empty)
                      Text(l.deskOvEmptyHint, style: ts.bodyDim)
                    else if (DeskFeatures.fiatPrice && b != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: hidden ? '≈ \$•••' : '≈ \$${(b.total / nanoPerEpic * _usdPerEpic).toStringAsFixed(2)}'), // l10n-ok: the dollar sign and digits
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
          SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          LayoutBuilder(
            builder: (context, box) {
              final items = <(String, int?, Widget?)>[
                (l.deskOvBreakTotal, b?.total, Icon(EIcons.wallet, size: Ctl.iconSm, color: c.dim)),
                (l.deskOvBreakConfirming, b?.awaitingConfirmation, ERing(confirmations: 1, size: Ctl.iconSm)),
                if (b == null || b.immature > 0) (l.deskOvBreakImmature, b?.immature, Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim)),
                (l.deskOvBreakAwaiting, b == null ? null : b.awaitingFinalization - posted, Icon(EIcons.pencil, size: Ctl.iconSm, color: c.dim)),
                if (posted > 0) (l.deskTxStatusSenderPosted, posted, Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim)),
                (l.deskOvBreakLocked, b?.locked, Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim)),
              ];
              // Two columns on a narrow panel, one row otherwise.
              if (box.maxWidth < items.length * 180.u) {
                final half = (box.maxWidth / 2).floorToDouble();
                return Wrap(
                  children: [
                    for (final (i, it) in items.indexed)
                      SizedBox(
                        width: i == items.length - 1 && items.length.isOdd ? box.maxWidth : half,
                        child: _Break(
                          width: i == items.length - 1 && items.length.isOdd ? box.maxWidth : half,
                          label: it.$1,
                          nano: it.$2,
                          lead: it.$3,
                          dim: updating,
                          right: i.isEven && !(i == items.length - 1 && items.length.isOdd),
                          bottom: i < items.length - (items.length.isEven ? 2 : 1),
                        ),
                      ),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, it) in items.indexed)
                      Expanded(
                        child: _Break(
                          label: it.$1,
                          nano: it.$2,
                          lead: it.$3,
                          width: box.maxWidth / items.length,
                          dim: updating,
                          first: i == 0,
                          right: i < items.length - 1,
                        ),
                      ),
                  ],
                ),
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

/// The balance in Montserrat 44: whole part bright, fraction dim, unit in mono.
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
    final canonical = formatEpic(nano);
    final dot = canonical.indexOf('.');
    final whole = localDigits(l, dot < 0 ? canonical : canonical.substring(0, dot));
    final frac = dot < 0 ? '' : localDigits(l, canonical.substring(dot));
    final text = whole + frac;
    return LayoutBuilder(
      builder: (context, box) {
        final base = ts.display.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
        final unitStyle = ts.mono(size: Fs.md, weight: FontWeight.w500);
        final unitPainter = TextPainter(
          text: TextSpan(text: 'EPIC', style: unitStyle),
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
              label: hidden ? context.l10n.deskOvHiddenAmount : '$text EPIC',
              excludeSemantics: true,
              child: Row(
                key: const ValueKey('balance-row'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: spans),
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  SizedBox(width: 10.u),
                  Text(
                    'EPIC',
                    style: ts.mono(size: Fs.md, color: c.dim, weight: FontWeight.w500),
                  ),
                ],
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

/// The gold signal trace under the balance (R5): as wide as the balance row, easing to a new
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
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (lead != null) ...[SizedBox(width: Ctl.iconSm, height: Ctl.iconSm, child: Center(child: lead!)), SizedBox(width: 6.u)],
              Flexible(
                child: Text(label, style: ts.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: Sp.x1),
          nano == null
              ? _Skeleton(width: 90.u, height: 16.u)
              : FitMoney(
                  nano!,
                  sizes: const [Fs.lg, Fs.md, Fs.sm, Fs.xs],
                  width: width - (first ? Sp.x8 : Sp.x5) - Sp.x5,
                  color: zero || dim ? c.faint : c.text,
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
              EButton.primary(label: l.deskOvShowAddress, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.receive)),
              EButton.ghost(label: l.deskOvReceiveFile, size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.importTx)),
            ],
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final (i, t) in list.take(5).indexed) ...[if (i > 0) Divider(height: 1, color: c.line), TxRow(tx: t, compact: true, onTap: () => onOpen(t))],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(
          l.deskOvRecent,
          top: Sp.x6,
          trailing: list == null || list.isEmpty ? null : ELink(label: l.deskOvViewAll(list.length), onPressed: onAll),
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
