// SPDX-License-Identifier: Apache-2.0
/// The sidebar's bottom slot: what is going on now, else a quiet resting row. The wallet's name,
/// the status rows and Lock live in the title bar (title_bar.dart), so nothing is said twice:
/// the slot shows progress and events (Offline mode, a scan, an update out or to restart, a
/// payment on its way, new requests, the local node syncing, an update downloading), at most two
/// lines, the most important first, a `+N` for the rest; each line opens its screen. Resting:
/// Help · Report a problem. Health (a node that does not answer, Epicbox, Tor) stays in the title
/// bar's status.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../node/local_node_state.dart' show LocalNodePhase;
import '../data/desk_node.dart' show deskLocalNodeProvider, deskNodeInfoProvider, deskOwnerSecretProvider, deskOwnStatusProvider, NodeHead, nodeClassOf;
import '../data/desk_update.dart' show DeskUpdatePhase, deskUpdateProvider;
import '../data/desk_update_apply.dart' show deskUpdateApplierProvider;
import '../data/invoice_state.dart' show deskInvoiceBadgeProvider;
import '../data/node_view.dart' show localNodeView, digits, percent;
import 'desk_failover.dart' show deskFailoverProvider;
import '../../l10n.dart' show localInt;
import '../../tor_build.dart' show inAppUpdates;
import '../desk_l10n.dart';
import '../screens/settings/prefs.dart';
import '../screens/settings/report_problem.dart' show showReportProblemDialog;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'update_notice.dart' show deskUpdateAct, deskUpdateWords;

/// One line of the slot.
@immutable
class NowItem {
  const NowItem({required this.id, required this.icon, required this.tone, required this.title, this.detail, this.hint, this.act = false, this.stacked = false, this.progress, this.onTap});

  /// Stable per kind, so a line that only changes its numbers never animates.
  final String id;
  final IconData icon;
  final ETone tone;
  final String title;

  /// After the title, never cut ("62 %", "2 of 3", "Restart").
  final String? detail;

  /// More words for the tooltip and screen readers only.
  final String? hint;

  /// The detail is the click's action word: in the accent.
  final bool act;

  /// The detail goes under the title, each with the line's whole width (an update: its words
  /// and version must read whole).
  final bool stacked;

  /// 0–1 for a bar under the line; -1 for a bar that moves without a known end.
  final double? progress;
  final VoidCallback? onTap;

  String get words => [detail == null ? title : '$title · $detail', ?hint].join('\n');
}

/// What goes on now, the most important first (the slot shows two).
List<NowItem> nowItems(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final s = ref.watch(deskProvider);
  final nav = ref.read(deskNavProvider.notifier);
  final here = ref.watch(deskNavProvider.select((a) => a.route));
  final items = <NowItem>[];
  final status = s.status;
  void go(DeskRoute r, [Object? arg]) {
    deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    nav.go(r, arg);
  }

  // A line whose screen is open now says what goes on, and takes no click.
  VoidCallback? to(DeskRoute r, [Object? arg]) => r == here ? null : () => go(r, arg);

  // 1. The network mode is the title bar's mark, not a line here; only Tor only waiting for
  //    Tor is an event (the Tor row below says it).
  // 2. A scan: the one a restore owes, or a Recheck balance.
  final scan = status?.restoreScan;
  if (scan != null) {
    items.add(switch (scan.state) {
      RestoreScanState.running => NowItem(
        id: 'scan',
        icon: EIcons.scan,
        tone: ETone.info,
        title: l.deskSlotScanning,
        detail: scan.percent == null ? null : '${localInt(l, scan.percent!)}%',
        progress: scan.percent == null ? -1 : scan.percent! / 100,
        hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan),
      ),
      RestoreScanState.waiting => NowItem(id: 'scan', icon: EIcons.scan, tone: ETone.warn, title: l.deskSlotScanWaits, hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan)),
      RestoreScanState.failed => NowItem(
        id: 'scan',
        icon: EIcons.scan,
        tone: ETone.warn,
        title: l.deskSlotScanStopped,
        detail: l.deskSlotTryAgain,
        act: true,
        hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan),
      ),
    });
  } else if (status?.scanning ?? false) {
    items.add(NowItem(id: 'scan', icon: EIcons.scan, tone: ETone.info, title: l.deskSlotScanning, progress: -1, hint: DeskRoute.settingsRescan == here ? null : l.deskSlotOpenRecheck, onTap: to(DeskRoute.settingsRescan)));
  }
  // 3. An update: out (download it, or the page), to restart, to try again; 8. one downloading.
  final u = ref.watch(deskUpdateProvider);
  NowItem? downloading;
  if (inAppUpdates && u.offered) {
    final w = deskUpdateWords(l, u, byHand: ref.read(deskUpdateApplierProvider)?.byHand ?? false);
    if (u.phase == DeskUpdatePhase.downloading) {
      downloading = NowItem(id: 'update', icon: EIcons.download, tone: ETone.info, title: w.title, progress: u.progress ?? -1);
    } else {
      items.add(
        NowItem(
          id: 'update',
          icon: w.warn ? EIcons.alert : (u.phase == DeskUpdatePhase.available ? EIcons.download : EIcons.restart),
          tone: w.warn ? ETone.warn : ETone.gold,
          title: w.title,
          detail: w.second,
          act: w.act,
          stacked: true,
          hint: w.tip,
          onTap: () => unawaited(deskUpdateAct(context, ref)),
        ),
      );
    }
  }
  // 4. A send under way.
  if (ref.watch(deskSendingProvider) > 0) {
    items.add(NowItem(id: 'sending', icon: EIcons.send, tone: ETone.info, title: l.deskSlotSending, progress: -1, hint: DeskRoute.send == here ? null : l.deskSlotOpenSend, onTap: to(DeskRoute.send)));
  }
  // 5. Payments posted and confirming (never a mining reward, which matures for a day).
  final moving = [
    for (final t in s.txs ?? const <Tx>[])
      if (!t.coinbase && (t.state == TxState.posted || t.state == TxState.confirming)) t,
  ]..sort((a, b) => b.created.compareTo(a.created));
  if (moving.isNotEmpty) {
    final t = moving.first;
    final sent = moving.where((m) => m.direction == TxDirection.sent).length;
    final needed = t.confirmationsNeeded <= 0 ? 1 : t.confirmationsNeeded;
    final done = t.state == TxState.posted ? 0 : t.confirmations.clamp(0, needed);
    final count = l.deskSlotOf(localInt(l, done), localInt(l, needed));
    items.add(
      NowItem(
        id: 'payment',
        icon: t.direction == TxDirection.sent ? EIcons.send : EIcons.receive,
        tone: ETone.info,
        title: moving.length > 1
            ? (sent == moving.length ? l.deskSlotPaymentsOut : l.deskSlotPaymentsMoving)
            : t.direction == TxDirection.sent
            ? l.deskSlotPaymentOut
            : l.deskSlotPaymentIn,
        detail: t.state == TxState.posted ? l.deskSlotWaitingBlock : count,
        progress: done / needed,
        hint: DeskRoute.activity == here ? null : l.deskSlotOpenActivity, onTap: to(DeskRoute.activity, t.id),
      ),
    );
  }
  // 6. Requests to pay (Invoices on).
  final requests = ref.watch(deskInvoiceBadgeProvider);
  if (requests > 0) {
    items.add(NowItem(id: 'requests', icon: EIcons.invoice, tone: ETone.warn, title: l.deskSlotRequests, detail: localInt(l, requests), hint: DeskRoute.invoices == here ? null : l.deskSlotOpenInvoices, onTap: to(DeskRoute.invoices)));
  }
  // 7. The local node starting or syncing.
  if (ref.watch(settingsPrefsProvider.select((p) => p.builtin))) {
    final node = ref.watch(deskLocalNodeProvider).value;
    if (node != null && (node.phase == LocalNodePhase.starting || node.phase == LocalNodePhase.syncing)) {
      final v = localNodeView(l, node);
      items.add(
        NowItem(
          id: 'node',
          icon: EIcons.node,
          tone: ETone.info,
          title: node.phase == LocalNodePhase.starting ? l.deskSlotNodeStarting : l.deskSlotNodeSyncing,
          detail: node.phase == LocalNodePhase.starting ? null : v.marker,
          // The share its percent says, else a bar without a known end.
          progress: node.phase == LocalNodePhase.syncing ? node.progress?.overall ?? -1 : -1,
          hint: DeskRoute.settingsNode == here ? null : l.deskRailOpenNode, onTap: to(DeskRoute.settingsNode),
        ),
      );
    }
  }
  // 8. The user's own node syncing: its progress here, its health on the rail.
  if (!ref.watch(settingsPrefsProvider.select((p) => p.builtin))) {
    final prefs = ref.watch(settingsPrefsProvider);
    final chosen = ref.watch(deskFailoverProvider)?.chosen ?? (prefs.typedNode ?? status?.node)?.url;
    if (chosen != null && nodeClassOf(chosen, mine: prefs.mineNodes.contains(chosen)).own) {
      final info = ref.watch(deskNodeInfoProvider(chosen)).value;
      if (info?.head == NodeHead.syncing) {
        final has = ref.watch(deskOwnerSecretProvider(chosen)).value ?? false;
        final owner = has ? ref.watch(deskOwnStatusProvider((url: chosen, tip: info!.networkHeight))).value : null;
        final behind = info!.blocksBehind;
        items.add(
          NowItem(
            id: 'own-node',
            icon: EIcons.node,
            tone: ETone.info,
            title: l.deskOwnSlotSyncing,
            detail: owner?.progress?.overall != null ? percent(owner!.progress!.overall!) : (behind != null && behind > 0 ? l.deskNodeMarkerBehind(digits(l, behind)) : null),
            progress: owner?.progress?.overall ?? -1,
            hint: DeskRoute.settingsNode == here ? null : l.deskRailOpenNode, onTap: to(DeskRoute.settingsNode),
          ),
        );
      }
    }
  }
  if (downloading != null) items.add(downloading);
  // 9. A notice from the wallet core (a database being rebuilt).
  final notice = status?.notice;
  if (notice != null && notice.isNotEmpty) {
    items.add(NowItem(id: 'notice', icon: EIcons.info, tone: ETone.info, title: notice, hint: DeskRoute.settingsNode == here ? null : l.deskRailOpenNode, onTap: to(DeskRoute.settingsNode)));
  }
  return items;
}

/// The slot. [compact] is the 72 px rail: icons, the words in their tooltips.
class NowSlot extends ConsumerStatefulWidget {
  const NowSlot({super.key, required this.compact});

  final bool compact;

  @override
  ConsumerState<NowSlot> createState() => _NowSlotState();
}

class _NowSlotState extends ConsumerState<NowSlot> {
  /// Every line on screen, also one closing; [_open] those that are (or are opening) in view.
  final Map<String, NowItem> _lines = {};
  final Set<String> _open = {};
  final Map<String, Timer> _gone = {};

  /// The lines' order on screen: a line that leaves keeps its place while it closes.
  List<String> _order = const [];
  String _said = '';

  @override
  void dispose() {
    for (final t in _gone.values) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final items = nowItems(context, ref);
    final shown = items.take(2).toList();
    final more = items.skip(2).toList();
    final ids = {for (final i in shown) i.id};
    // Arrivals for screen readers (never every percent); they open on the next frame, so the
    // height and the fade run in; a line that goes closes the same way before it leaves.
    final arrived = [for (final i in shown) if (!_lines.containsKey(i.id) || !_open.contains(i.id)) i.title];
    if (arrived.isNotEmpty) _said = arrived.join(', ');
    for (final i in shown) {
      final isNew = !_lines.containsKey(i.id);
      _lines[i.id] = i;
      _gone.remove(i.id)?.cancel();
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _lines.containsKey(i.id)) setState(() => _open.add(i.id));
        });
      } else {
        _open.add(i.id);
      }
    }
    for (final id in _lines.keys.where((k) => !ids.contains(k)).toList()) {
      _open.remove(id);
      _gone[id] ??= Timer(Motion.expand + const Duration(milliseconds: 60), () {
        if (!mounted) return;
        setState(() {
          _gone.remove(id);
          if (!_open.contains(id)) _lines.remove(id);
        });
      });
    }
    final order = [for (final id in _order) if (_lines.containsKey(id)) id];
    for (final (n, i) in shown.indexed) {
      if (order.contains(i.id)) continue;
      order.insert(n == 0 ? 0 : order.indexOf(shown[n - 1].id) + 1, i.id);
    }
    // The lines in view take their slots in priority order; the closing ones stay put.
    final slots = [for (final (k, id) in order.indexed) if (ids.contains(id)) k];
    for (final (n, k) in slots.indexed) {
      order[k] = shown[n].id;
    }
    _order = order;
    return Semantics(
      container: true,
      label: l.deskSlotNow,
      child: Container(
        padding: EdgeInsets.all(widget.compact ? Sp.x2 : Sp.x3),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // A hidden polite live region with what just arrived.
            Semantics(liveRegion: true, label: _said, child: const SizedBox.shrink()),
            for (final id in order)
              ExpandFade(
                key: ValueKey('now-$id'),
                open: _open.contains(id),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.u),
                  child: _Line(item: _lines[id]!, compact: widget.compact, more: shown.isNotEmpty && id == shown.last.id ? more : const []),
                ),
              ),
            AnimatedContainer(duration: Motion.expand, height: shown.isEmpty ? 0 : Sp.x1),
            _Resting(compact: widget.compact),
          ],
        ),
      ),
    );
  }
}

Color _toneColor(DeskColors c, ETone t) => switch (t) {
  ETone.ok => c.ok,
  ETone.warn => c.warn,
  ETone.risk => c.risk,
  ETone.info => c.info,
  ETone.gold => c.accentText,
  ETone.neutral => c.faint,
};

/// Sweeps a bar without a known end plays before it holds still: about 9 s, as the status dot's
/// five beats.
@visibleForTesting
const int slotBarSweeps = 5;

/// One sweep of Flutter's bar without a known end.
const Duration _sweep = Duration(milliseconds: 1800);

/// A 2 px bar without a known end: it sweeps [slotBarSweeps] times, then holds the empty track
/// each sweep starts from. A sync can last hours, and a bar that never stops redraws the window
/// all that time. A new state (its key) sweeps again.
class _SweepBar extends StatefulWidget {
  const _SweepBar({super.key, required this.color});

  final Color color;

  @override
  State<_SweepBar> createState() => _SweepBarState();
}

class _SweepBarState extends State<_SweepBar> {
  Timer? _stop;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _stop = Timer(_sweep * slotBarSweeps, () {
      if (mounted) setState(() => _held = true);
    });
  }

  @override
  void dispose() {
    _stop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LinearProgressIndicator(value: _held ? 0 : null, minHeight: 2, backgroundColor: context.dc.s3, color: widget.color);
}

/// A line: icon, title · detail, a 2 px bar under it when it has progress.
class _Line extends StatelessWidget {
  const _Line({required this.item, required this.compact, required this.more});

  final NowItem item;
  final bool compact;
  final List<NowItem> more;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final i = item;
    final tone = _toneColor(c, i.tone);
    final bar = i.progress == null
        ? null
        : ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: 2,
              child: i.progress! < 0
                  ? _SweepBar(key: ValueKey('${i.id}/${i.title}'), color: i.tone == ETone.gold ? c.accent : c.info)
                  : TweenAnimationBuilder<double>(
                      tween: Tween(end: i.progress!.clamp(0.0, 1.0)),
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Dur.base,
                      builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 2, backgroundColor: c.s3, color: i.tone == ETone.gold ? c.accent : c.info),
                    ),
            ),
          );
    final tip = [i.words, for (final m in more) m.words].join('\n');
    Widget content;
    if (compact) {
      content = SizedBox(
        height: bar == null ? Ctl.inline : 36.u,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(i.icon, size: Ctl.iconSm, color: tone),
                if (more.isNotEmpty)
                  PositionedDirectional(
                    end: -14.u,
                    top: -6.u,
                    child: Text('+${more.length}', style: ts.caption.copyWith(fontSize: 10, color: c.dim)), // l10n-ok: a count
                  ),
              ],
            ),
            if (bar != null) ...[SizedBox(height: 6.u), SizedBox(width: 20.u, child: bar)],
          ],
        ),
      );
    } else {
      final under = i.stacked && i.detail != null;
      content = Container(
        height: under ? 40.u : (bar == null ? Ctl.inline : 36.u),
        padding: EdgeInsets.symmetric(horizontal: Sp.x2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) => Row(
              children: [
                Icon(i.icon, size: Ctl.iconSm, color: tone),
                SizedBox(width: Sp.x2),
                Flexible(
                  child: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: ts.small.copyWith(color: c.text, height: 20 / Fs.sm)),
                ),
                if (i.detail != null && !under) ...[
                  Text(' · ', style: ts.small.copyWith(color: c.lineField)), // l10n-ok: separator
                  // A number or an action word fits whole; a longer detail gives up at half the line.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
                    child: Text(i.detail!, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: i.act ? c.accentText : c.dim)),
                  ),
                ],
                if (more.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    margin: EdgeInsetsDirectional.only(start: Sp.x1),
                    padding: EdgeInsets.symmetric(horizontal: 6.u, vertical: 1.u),
                    decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(Rad.sm)),
                    child: Text('+${more.length}', style: ts.caption.copyWith(color: c.dim)), // l10n-ok: a count
                  ),
                ],
              ],
            ),

            ),
            if (under)
              Padding(
                padding: EdgeInsetsDirectional.only(start: Ctl.iconSm + Sp.x2),
                child: Text(i.detail!, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: ts.caption.copyWith(color: i.act ? c.accentText : c.dim, height: 16 / Fs.xs)),
              ),
            if (bar != null) ...[SizedBox(height: 5.u), bar],
          ],
        ),
      );
    }
    final line = Semantics(
      button: i.onTap != null,
      label: [i.words, for (final m in more) m.words].join(', '),
      excludeSemantics: true,
      child: i.onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: i.onTap, borderRadius: BorderRadius.circular(Rad.sm), hoverColor: c.hover, child: content),
            ),
    );
    return Tooltip(message: tip, waitDuration: const Duration(milliseconds: 400), child: line);
  }
}

/// Help · Report a problem.
class _Resting extends ConsumerWidget {
  const _Resting({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    void help() {
      deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp);
    }

    if (compact) {
      return Center(
        child: EIconButton(key: const ValueKey('now-help'), icon: EIcons.help, label: l.deskSlotHelp, size: EBtnSize.inline, onPressed: help),
      );
    }
    return SizedBox(
      height: 24.u,
      child: Row(
        children: [
          _TextLink(key: const ValueKey('now-help'), label: l.deskSlotHelp, onTap: help),
          Text(' · ', style: context.ts.caption.copyWith(color: c.lineField)), // l10n-ok: separator
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _TextLink(
              key: const ValueKey('now-report'),
              label: l.deskSetReportTitle,
              onTap: () {
                final shown = deskNavigatorKey.currentContext;
                if (shown != null) unawaited(showReportProblemDialog(shown));
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextLink extends StatefulWidget {
  const _TextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onTap,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                padding: EdgeInsets.symmetric(horizontal: Sp.x1, vertical: 2.u),
                decoration: BoxDecoration(color: _hover ? c.hover : Colors.transparent, borderRadius: BorderRadius.circular(Rad.xs)),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.ts.caption.copyWith(color: _hover ? c.text : c.faint),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
