// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../amount.dart' as shared show formatEpic;

import '../../data/net_mode_view.dart' show deskLastKnownProvider;
import '../../desk_l10n.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../app/tour.dart';
import '../../widgets/kit.dart';
import 'tx_detail.dart';
import 'tx_display.dart';
import 'tx_label.dart';
import '../../data/pairing_state.dart' show deskInvoicesShownProvider;

enum _Filter { all, sent, received, pending, cancelled, requests }

/// Starts Activity on a selected transaction, a search, or the empty state.
class ActivityArgs {
  const ActivityArgs({this.txId, this.empty = false, this.waitingNode = false, this.query, this.page = 0});

  final int? txId;

  /// The list page to open on (zero-based).
  final int page;
  final bool empty;

  /// Empty and the node not synced yet: a waiting line instead of the learn panel.
  final bool waitingNode;
  final String? query;
}

const int _pageSize = 12;

/// The no-break spaces Polish and Russian group digits with.
final RegExp _nbsp = RegExp('[\u00A0\u202F]');

/// Activity: every transaction (filter, search, pages) with the selected one in a detail pane
/// beside the list at desktop width, or in its place below. Outputs have their own page.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.arg});

  /// An int selects that transaction; an [ActivityArgs] sets more.
  final Object? arg;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  late final ActivityArgs _args = switch (widget.arg) {
    final int id => ActivityArgs(txId: id),
    final ActivityArgs a => a,
    _ => const ActivityArgs(),
  };
  late int? _selected = _args.txId;
  late final _query = TextEditingController(text: _args.query);
  _Filter _filter = _Filter.all;
  late int _page = _args.page;
  bool _refreshing = false;

  bool get _noTxs => _args.empty || _args.waitingNode;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Asks the node now, as 6.1.6's refresh does; says so when it could not.
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(deskProvider.notifier).syncNow();
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskActNotUpdated, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  List<Tx> _filtered(List<Tx> all) {
    final q = _query.text.trim().toLowerCase();
    final l = context.l10n;
    return [
      for (final t in all)
        if (_matches(t, _filter) &&
            (q.isEmpty ||
                whoOf(l, t).toLowerCase().contains(q) ||
                (t.labelText ?? '').toLowerCase().contains(q) ||
                (t.counterparty ?? '').toLowerCase().contains(q) ||
                (t.message ?? '').toLowerCase().contains(q) ||
                t.slateId.contains(q) ||
                // The exact amount, and the four decimals the list shows.
                shared.formatEpic(BigInt.from(t.amount)).contains(q) ||
                formatEpic(t.amount).contains(q) ||
                // As the list shows it (1.234,5 in German); a typed space matches the no-break one.
                formatEpicL(l, t.amount).replaceAll(_nbsp, ' ').contains(q.replaceAll(_nbsp, ' '))))
          t,
    ];
  }

  /// The phone's filters (GP-002): Sent and Received leave out cancelled payments, which have
  /// their own; Pending is what still waits for the other side or for blocks.
  static bool _matches(Tx t, _Filter f) => switch (f) {
    _Filter.all => true,
    _Filter.sent => !t.isInvoice && !t.incoming && t.state != TxState.cancelled,
    _Filter.received => !t.isInvoice && t.incoming && t.state != TxState.cancelled,
    _Filter.pending => !t.isInvoice && !t.fromBackup && t.pending,
    _Filter.cancelled => !t.isInvoice && t.state == TxState.cancelled,
    _Filter.requests => t.isInvoice,
  };

  /// The search. [full] fills its row (narrow layout).
  Widget _search({required bool full, required bool hasItems}) {
    final width = MediaQuery.sizeOf(context).width;
    final l = context.l10n;
    final input = EInput(
      controller: _query,
      enabled: hasItems,
      hint: l.deskActSearchHint,
      leading: EIcons.search,
      semanticLabel: l.deskActSearchLabel,
      onChanged: (_) => setState(() => _page = 0),
      trailing: _query.text.isEmpty ? null : EIconButton(icon: EIcons.close, label: l.deskActClearSearch, size: EBtnSize.inline, onPressed: () => setState(_query.clear)),
    );
    if (full) return input;
    return SizedBox(width: width >= 1280.u ? 280.u : 200.u, child: input);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(deskProvider);
    final l = context.l10n;
    final hidden = s.settings.hideAmounts;
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= Bp.desktop;
    // Below this the tabs and the search move out of the header into the page.
    final roomy = width >= 900.u;
    final all = _noTxs ? const <Tx>[] : s.txs;
    final selectedTx = all?.where((t) => t.id == _selected).firstOrNull;
    final hasItems = all?.isNotEmpty ?? false;
    final actions = <Widget>[
      if (roomy) _search(full: false, hasItems: hasItems),
      EIconButton(
        icon: hidden ? EIcons.eyeOff : EIcons.eye,
        label: hidden ? l.deskActShowAmounts : l.deskActHideAmounts,
        selected: hidden,
        onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
      ),
      _refreshing
          ? SizedBox.square(
              dimension: Ctl.sm,
              child: Center(child: ESpinner()),
            )
          : EIconButton(icon: EIcons.refresh, label: l.deskActRefresh, onPressed: _refresh),
    ];

    // Narrow: the detail replaces the list.
    if (!split && selectedTx != null) {
      return EPage(
        title: selectedTx.isInvoice ? l.deskInvActBlock : (selectedTx.incoming ? l.deskActDetailReceived : l.deskActDetailSent),
        width: EPageWidth.narrow,
        onBack: () => setState(() => _selected = null),
        child: TxDetail(tx: selectedTx, showTitle: true),
      );
    }

    // The list and the detail are one unit: same top, same
    // bottom, header bands of one height; each scrolls inside itself when the window is short.
    final list = TourTarget(id: 'activity-list', child: _txList(all));
    return EPage(
      title: l.deskActTitle,
      width: EPageWidth.full,
      scroll: false,
      actions: actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!roomy) ...[
            _search(full: true, hasItems: hasItems),
            SizedBox(height: Sp.x4),
          ],
          // Kill switch asks no node: the list is the one seen last.
          if (ref.watch(deskLastKnownProvider)) ...[
            Text(l.lastKnownList, key: const ValueKey('activity-last-known'), style: context.ts.small.copyWith(color: context.dc.dim)),
            SizedBox(height: Sp.x3),
          ],
          Flexible(
            child: split && selectedTx != null
                ? PanelRow(
                    main: list,
                    side: _DetailPane(tx: selectedTx, onClose: () => setState(() => _selected = null)),
                    sideWidth: width >= Ctl.sideWideFrom ? Ctl.sideWide : Ctl.side,
                    // A large scale on a small window keeps room for the list's rows.
                    maxSideFraction: Ctl.sideMaxFraction,
                  )
                : list,
          ),
        ],
      ),
    );
  }

  Widget _waiting(String text) => _panel(
    Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x10, horizontal: Sp.x5),
      child: Semantics(
        liveRegion: true,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Sp.x3,
          runSpacing: Sp.x2,
          children: [
            const ESpinner(),
            Text(text, style: context.ts.bodyDim, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );

  Widget _txList(List<Tx>? all) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    if (all == null) return _waiting(l.deskActLoading);
    if (all.isEmpty) return _args.waitingNode ? _waiting(l.deskActWaitingNode) : _panel(const _Learn());
    final shown = _filtered(all);
    final pages = (shown.length / _pageSize).ceil();
    final page = _page.clamp(0, (pages - 1).clamp(0, 999));
    final slice = shown.skip(page * _pageSize).take(_pageSize).toList();
    int count(_Filter f) => all.where((t) => _matches(t, f)).length;
    final rows = <Widget>[];
    String? day;
    for (final t in slice) {
      final d = dayLabel(l, t.created);
      if (d != day) {
        day = d;
        rows.add(
          Container(
            padding: EdgeInsets.fromLTRB(Sp.x5, Sp.x3, Sp.x5, 6.u),
            decoration: BoxDecoration(
              color: c.s1,
              border: Border(
                bottom: BorderSide(color: c.line),
                top: rows.isEmpty ? BorderSide.none : BorderSide(color: c.line),
              ),
            ),
            child: Text(d, style: ts.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
        );
      } else {
        rows.add(Divider(height: 1, color: c.line));
      }
      rows.add(
        TxRow(
          key: ValueKey('tx-${t.id}'),
          tx: t,
          labelEditable: true,
          selected: t.id == _selected,
          onTap: () => setState(() => _selected = t.id),
          onFinalize: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize),
        ),
      );
    }
    // The filter sits in the list's header band, level with the detail pane's title.
    final tabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ESegmented<_Filter>(
        segments: [
          ESegment(_Filter.all, l.deskActFilterAll, count: count(_Filter.all)),
          ESegment(_Filter.sent, l.deskActFilterSent, count: count(_Filter.sent)),
          ESegment(_Filter.received, l.deskActFilterReceived, count: count(_Filter.received)),
          ESegment(_Filter.pending, l.historyFilterPending, count: count(_Filter.pending)),
          ESegment(_Filter.cancelled, l.historyFilterCancelled, count: count(_Filter.cancelled)),
          if (ref.watch(deskInvoicesShownProvider))
            ESegment(_Filter.requests, l.deskInvActFilter, icon: EIcons.request, count: all.where((t) => t.isInvoice).length),
        ],
        value: _filter,
        onChanged: (v) => setState(() {
          _filter = v;
          _page = 0;
        }),
      ),
    );
    return _panel(
      head: tabs,
      foot: pages > 1 ? ListPager(pages: pages, page: page, top: 0, onPage: (p) => setState(() => _page = p)) : null,
      shown.isEmpty
          ? EEmpty(
              icon: EIcons.search,
              title: _query.text.trim().isEmpty ? l.deskActNoneUnderFilter : l.deskActNoMatchTitle(_query.text.trim()),
              actions: [
                EButton.ghost(
                  label: l.deskActClearSearch,
                  onPressed: () => setState(() {
                    _query.clear();
                    _filter = _Filter.all;
                  }),
                ),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const ActivityListHead(), ...rows]),
    );
  }

  /// The list's panel: as tall as its content up to the page's height, then it scrolls inside;
  /// stretched to the detail pane's height when that is taller.
  Widget _panel(Widget child, {Widget? head, Widget? foot}) =>
      EPanel(head: head, foot: foot, padding: EdgeInsets.zero, scroll: true, child: child);
}

/// Page buttons: the first and last pages with the current one in the middle, "Page X of Y".
/// Wraps instead of overflowing; on a narrow row only previous, "Page X of Y" and next.
class ListPager extends StatelessWidget {
  const ListPager({super.key, required this.pages, required this.page, required this.onPage, this.top});

  final int pages;

  /// Space above it; [Sp.x4] by default, 0 in a panel's foot band.
  final double? top;

  /// Zero-based.
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox.shrink();
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    Widget num(int i) =>
        EButton(label: '${i + 1}', size: EBtnSize.sm, kind: i == page ? EBtnKind.secondary : EBtnKind.ghost, onPressed: i == page ? null : () => onPage(i));
    final gap = Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x1),
      child: Text('…', style: ts.body.copyWith(color: c.faint)),
    );
    final of = Text(l.deskActPageOf(page + 1, pages), style: ts.small.copyWith(color: c.faint));
    final prev = EIconButton(icon: EIcons.chevronLeft, label: l.deskActPrevPage, onPressed: page > 0 ? () => onPage(page - 1) : null);
    final next = EIconButton(icon: EIcons.chevronRight, label: l.deskActNextPage, onPressed: page < pages - 1 ? () => onPage(page + 1) : null);
    return Padding(
      padding: EdgeInsets.only(top: top ?? Sp.x4),
      child: Semantics(
        container: true,
        label: l.deskActPages,
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 480.u) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  prev,
                  SizedBox(width: Sp.x2),
                  Flexible(child: of),
                  SizedBox(width: Sp.x2),
                  next,
                ],
              );
            }
            // First two, last two, and the current one with its neighbours.
            final keep = <int>{0, 1, pages - 2, pages - 1, page - 1, page, page + 1}.where((i) => i >= 0 && i < pages).toList()..sort();
            final items = <Widget>[prev];
            for (var k = 0; k < keep.length; k++) {
              if (k > 0 && keep[k] != keep[k - 1] + 1) items.add(gap);
              items.add(num(keep[k]));
            }
            items.addAll([next, SizedBox(width: Sp.x2), of]);
            return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 2, runSpacing: Sp.x2, children: items);
          },
        ),
      ),
    );
  }
}

class ActivityListHead extends StatelessWidget {
  const ActivityListHead({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final style = context.ts.caption.copyWith(fontWeight: FontWeight.w600);
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < txRowFullWidth) return const SizedBox.shrink();
        return Container(
          height: 36.u,
          padding: EdgeInsets.symmetric(horizontal: Sp.x5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              SizedBox(width: 36.u + Sp.x4),
              Expanded(flex: 16, child: Text(l.deskActColFromTo, style: style)),
              SizedBox(width: Sp.x4),
              Expanded(flex: 10, child: Text(l.deskActColStatus, style: style)),
              SizedBox(width: Sp.x4),
              SizedBox(
                width: txTimeWidth,
                child: Text(l.deskActColTime, textAlign: TextAlign.right, style: style),
              ),
              SizedBox(width: Sp.x4),
              SizedBox(
                width: txAmountWidth,
                child: Text(l.deskActColAmount, textAlign: TextAlign.right, style: style),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// No transactions yet: the three stages a payment goes through.
class _Learn extends ConsumerWidget {
  const _Learn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440.u),
          child: Column(
            children: [
              EEmpty(
                icon: EIcons.activity,
                title: l.deskActEmptyTitle,
                text: l.deskActEmptyText,
              ),
              SizedBox(height: Sp.x5),
              Wrap(
                spacing: Sp.x2,
                children: [
                  EButton.primary(label: l.deskActShowAddress, icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
                  EButton.ghost(label: l.deskActReceiveFile, size: EBtnSize.md, onPressed: () => nav.go(DeskRoute.importTx)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({required this.tx, required this.onClose});

  final Tx tx;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EPanel(
      strong: true,
      scroll: true,
      padding: EdgeInsets.all(Sp.panel),
      head: Row(
        children: [
          Expanded(
            child: TxPanelTitle(tx: tx, fallback: tx.isInvoice ? l.deskInvActBlock : (tx.incoming ? l.deskActDetailReceived : l.deskActDetailSent)),
          ),
          EIconButton(icon: EIcons.close, label: l.commonClose, onPressed: onClose),
        ],
      ),
      child: TxDetail(tx: tx),
    );
  }
}
