import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../app/tour.dart';
import '../../widgets/kit.dart';
import 'tx_detail.dart';
import 'tx_display.dart';

enum _Filter { all, received, sent }

/// Starts Activity on a selected transaction, a search, or the empty state.
class ActivityArgs {
  const ActivityArgs({this.txId, this.empty = false, this.waitingNode = false, this.query});

  final int? txId;
  final bool empty;

  /// Empty and the node not synced yet: a waiting line instead of the learn panel.
  final bool waitingNode;
  final String? query;
}

const int _pageSize = 12;

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
  int _page = 0;
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
      if (mounted) showEToast(context, 'Not updated', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  List<Tx> _filtered(List<Tx> all) {
    final q = _query.text.trim().toLowerCase();
    return [
      for (final t in all)
        if ((_filter == _Filter.all || (_filter == _Filter.received) == t.incoming) &&
            (q.isEmpty ||
                whoOf(t).toLowerCase().contains(q) ||
                (t.counterparty ?? '').toLowerCase().contains(q) ||
                (t.message ?? '').toLowerCase().contains(q) ||
                t.slateId.contains(q) ||
                formatEpic(t.amount).contains(q)))
          t,
    ];
  }

  /// The search. [full] fills its row (narrow layout).
  Widget _search({required bool full, required bool hasItems}) {
    final width = MediaQuery.sizeOf(context).width;
    final input = EInput(
      controller: _query,
      enabled: hasItems,
      hint: hasItems ? 'Address or slate id' : 'Nothing to search yet',
      leading: EIcons.search,
      semanticLabel: 'Search transactions',
      onChanged: (_) => setState(() => _page = 0),
      trailing: _query.text.isEmpty ? null : EIconButton(icon: EIcons.close, label: 'Clear search', size: EBtnSize.inline, onPressed: () => setState(_query.clear)),
    );
    if (full) return input;
    return SizedBox(width: width >= 1280.u ? 280.u : 200.u, child: input);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(deskProvider);
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
        label: hidden ? 'Show amounts' : 'Hide amounts',
        selected: hidden,
        onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
      ),
      _refreshing
          ? SizedBox.square(
              dimension: Ctl.sm,
              child: Center(child: ESpinner()),
            )
          : EIconButton(icon: EIcons.refresh, label: 'Refresh', onPressed: _refresh),
    ];

    // Narrow: the detail replaces the list.
    if (!split && selectedTx != null) {
      return EPage(
        title: selectedTx.incoming ? 'Received transaction' : 'Sent transaction',
        width: EPageWidth.narrow,
        onBack: () => setState(() => _selected = null),
        child: TxDetail(tx: selectedTx),
      );
    }

    // The list and the detail are one unit (docs/plans/w7-layout.md R1, R2): same top, same
    // bottom, header bands of one height; each scrolls inside itself when the window is short.
    final list = TourTarget(id: 'activity-list', child: _txList(all));
    return EPage(
      title: 'Activity',
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
    if (all == null) return _waiting('Loading transactions');
    if (all.isEmpty) return _args.waitingNode ? _waiting('Waiting for the node to be synced.') : _panel(const _Learn());
    final shown = _filtered(all);
    final pages = (shown.length / _pageSize).ceil();
    final page = _page.clamp(0, (pages - 1).clamp(0, 999));
    final slice = shown.skip(page * _pageSize).take(_pageSize).toList();
    final counts = (all.length, all.where((t) => t.incoming).length, all.where((t) => !t.incoming).length);
    final rows = <Widget>[];
    String? day;
    for (final t in slice) {
      final d = dayLabel(t.created);
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
          tx: t,
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
          ESegment(_Filter.all, 'All', count: counts.$1),
          ESegment(_Filter.received, 'Received', count: counts.$2),
          ESegment(_Filter.sent, 'Sent', count: counts.$3),
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
              title: 'No transactions match',
              text: 'Try another address or slate id, or clear the filter.',
              actions: [
                EButton.ghost(
                  label: 'Clear search',
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
    Widget num(int i) =>
        EButton(label: '${i + 1}', size: EBtnSize.sm, kind: i == page ? EBtnKind.secondary : EBtnKind.ghost, onPressed: i == page ? null : () => onPage(i));
    final gap = Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x1),
      child: Text('…', style: ts.body.copyWith(color: c.faint)),
    );
    final of = Text('Page ${page + 1} of $pages', style: ts.small.copyWith(color: c.faint));
    final prev = EIconButton(icon: EIcons.chevronLeft, label: 'Previous page', onPressed: page > 0 ? () => onPage(page - 1) : null);
    final next = EIconButton(icon: EIcons.chevronRight, label: 'Next page', onPressed: page < pages - 1 ? () => onPage(page + 1) : null);
    return Padding(
      padding: EdgeInsets.only(top: top ?? Sp.x4),
      child: Semantics(
        container: true,
        label: 'Pages',
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
              Expanded(flex: 16, child: Text('From / to', style: style)),
              SizedBox(width: Sp.x4),
              Expanded(flex: 10, child: Text('Status', style: style)),
              SizedBox(width: Sp.x4),
              SizedBox(
                width: txTimeWidth,
                child: Text('Time', textAlign: TextAlign.right, style: style),
              ),
              SizedBox(width: Sp.x4),
              SizedBox(
                width: txAmountWidth,
                child: Text('Amount', textAlign: TextAlign.right, style: style),
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
    final ts = context.ts;
    final c = context.dc;
    final nav = ref.read(deskNavProvider.notifier);
    final needed = deskMinConfirmations(ref);
    Widget stage(Widget mark, String title, String text) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                Text(text, style: ts.small),
              ],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440.u),
          child: Column(
            children: [
              EEmpty(
                icon: EIcons.activity,
                title: 'No transactions yet',
                text: 'Every payment sent or received is listed here, newest first, with who it was with and how far along it is.',
              ),
              stage(Icon(EIcons.sand, size: 20.u, color: c.warn), 'Waiting', 'Both wallets sign it. Over Epicbox this is automatic.'),
              stage(ERing(confirmations: 1, needed: needed), 'Confirming', 'On the chain. About one block a minute.'),
              stage(ERing(confirmations: needed, needed: needed), 'Spendable', 'After $needed confirmations, about $needed minutes.'),
              SizedBox(height: Sp.x5),
              Wrap(
                spacing: Sp.x2,
                children: [
                  EButton.primary(label: 'Show address', icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
                  EButton.ghost(label: 'Receive a file', size: EBtnSize.md, onPressed: () => nav.go(DeskRoute.importTx)),
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
    return EPanel(
      strong: true,
      scroll: true,
      padding: EdgeInsets.all(Sp.panel),
      head: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(tx.incoming ? 'Received transaction' : 'Sent transaction', style: context.ts.h3)),
          ),
          EIconButton(icon: EIcons.close, label: 'Close', onPressed: onClose),
        ],
      ),
      child: TxDetail(tx: tx),
    );
  }
}
