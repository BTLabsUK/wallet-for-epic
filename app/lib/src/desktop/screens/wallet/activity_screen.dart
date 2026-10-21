import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'tx_detail.dart';
import 'tx_display.dart';

enum ActivityTab { transactions, outputs }

enum _Filter { all, received, sent }

/// Starts Activity on a tab, a selected transaction, or the empty state.
class ActivityArgs {
  const ActivityArgs({this.tab = ActivityTab.transactions, this.txId, this.empty = false, this.query});

  final ActivityTab tab;
  final int? txId;
  final bool empty;
  final String? query;
}

const int _pageSize = 12;

/// Activity: every transaction (filter, search, pages) with the selected one in a detail pane
/// beside the list at desktop width, or in its place below. Outputs on the second tab.
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
  late ActivityTab _tab = _args.tab;
  late int? _selected = _args.txId;
  late final _query = TextEditingController(text: _args.query);
  _Filter _filter = _Filter.all;
  int _page = 0;
  bool _refreshing = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(deskProvider.notifier).refresh();
    if (mounted) setState(() => _refreshing = false);
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(deskProvider);
    final hidden = s.settings.hideAmounts;
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= Bp.desktop;
    final all = _args.empty ? const <Tx>[] : s.txs;
    final selectedTx = all?.where((t) => t.id == _selected).firstOrNull;

    final search = SizedBox(
      width: width >= 1280 ? 280 : 200,
      child: EInput(
        controller: _query,
        hint: 'Search',
        leading: EIcons.search,
        semanticLabel: 'Search transactions',
        onChanged: (_) => setState(() => _page = 0),
        trailing: _query.text.isEmpty
            ? null
            : EIconButton(
                icon: EIcons.close,
                label: 'Clear search',
                size: EBtnSize.inline,
                onPressed: () => setState(() => _query.clear()),
              ),
      ),
    );
    final actions = <Widget>[
      ESegmented<ActivityTab>(
        segments: const [ESegment(ActivityTab.transactions, 'Transactions'), ESegment(ActivityTab.outputs, 'Outputs')],
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
      ),
      const SizedBox(width: Sp.x2),
      if (_tab == ActivityTab.transactions && width >= 900) search,
      EIconButton(
        icon: hidden ? EIcons.eyeOff : EIcons.eye,
        label: hidden ? 'Show amounts' : 'Hide amounts',
        selected: hidden,
        onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
      ),
      _refreshing
          ? const SizedBox.square(dimension: Ctl.sm, child: Center(child: ESpinner()))
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

    final list = _tab == ActivityTab.outputs ? _Outputs(txs: all) : _txList(all);
    return EPage(
      title: 'Activity',
      width: EPageWidth.full,
      scroll: false,
      actions: actions,
      child: split && selectedTx != null && _tab == ActivityTab.transactions
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: list)),
                const SizedBox(width: Sp.x6),
                SizedBox(
                  width: width >= 1400 ? 440 : 380,
                  child: _DetailPane(tx: selectedTx, onClose: () => setState(() => _selected = null)),
                ),
              ],
            )
          : SingleChildScrollView(child: list),
    );
  }

  Widget _txList(List<Tx>? all) {
    final c = context.dc;
    final ts = context.ts;
    if (all == null) {
      return _panel(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.x10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const ESpinner(), const SizedBox(width: Sp.x3), Text('Loading transactions', style: ts.bodyDim)],
          ),
        ),
      );
    }
    if (all.isEmpty) return _panel(const _Learn());
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
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x3, Sp.x5, 6),
            decoration: BoxDecoration(color: c.s1, border: Border(bottom: BorderSide(color: c.line), top: rows.isEmpty ? BorderSide.none : BorderSide(color: c.line))),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ESegmented<_Filter>(
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
          ],
        ),
        const SizedBox(height: Sp.x3),
        if (shown.isEmpty)
          _panel(
            EEmpty(
              icon: EIcons.search,
              title: 'No match',
              text: 'Search looks at names, addresses, messages, amounts and slate ids.',
              actions: [EButton.ghost(label: 'Clear search', onPressed: () => setState(() => _query.clear()))],
            ),
          )
        else
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ListHead(),
                ...rows,
              ],
            ),
          ),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: Sp.x4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EIconButton(icon: EIcons.chevronLeft, label: 'Previous page', onPressed: page > 0 ? () => setState(() => _page = page - 1) : null),
                for (var i = 0; i < pages; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: EButton(
                      label: '${i + 1}',
                      size: EBtnSize.sm,
                      kind: i == page ? EBtnKind.secondary : EBtnKind.ghost,
                      onPressed: () => setState(() => _page = i),
                    ),
                  ),
                EIconButton(icon: EIcons.chevronRight, label: 'Next page', onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
              ],
            ),
          ),
      ],
    );
  }

  Widget _panel(Widget child) {
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: child,
    );
  }
}

class _ListHead extends StatelessWidget {
  const _ListHead();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final style = context.ts.caption.copyWith(fontWeight: FontWeight.w600);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          const SizedBox(width: 36 + Sp.x4),
          Expanded(flex: 16, child: Text('From / to', style: style)),
          const SizedBox(width: Sp.x4),
          Expanded(flex: 10, child: Text('Status', style: style)),
          const SizedBox(width: Sp.x4),
          SizedBox(width: 52, child: Text('Time', style: style)),
          const SizedBox(width: Sp.x4),
          Text('Amount', style: style),
        ],
      ),
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
    Widget stage(Widget mark, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: ts.strong), Text(text, style: ts.small)],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x8, vertical: Sp.x10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              EEmpty(icon: EIcons.activity, title: 'No transactions yet', text: 'A payment goes through three stages.'),
              stage(Icon(EIcons.sand, size: 20, color: c.warn), 'Waiting', 'Both wallets sign it. Over Epicbox this is automatic.'),
              stage(const ERing(confirmations: 2), 'Confirming', 'On the chain. About one block a minute.'),
              stage(const ERing(confirmations: 10), 'Spendable', 'After $minConfirmations confirmations, about $minConfirmations minutes.'),
              const SizedBox(height: Sp.x5),
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
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.lineStrong), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.only(left: Sp.x5, right: Sp.x2),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(tx.incoming ? 'Received transaction' : 'Sent transaction', style: context.ts.h3),
                  ),
                ),
                EIconButton(icon: EIcons.close, label: 'Close', onPressed: onClose),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(padding: const EdgeInsets.all(Sp.x5), child: TxDetail(tx: tx)),
          ),
        ],
      ),
    );
  }
}

/// Unspent outputs, from the history (the mock has no outputs list of its own).
class _Outputs extends StatelessWidget {
  const _Outputs({required this.txs});

  final List<Tx>? txs;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final list = (txs ?? const <Tx>[]).where((t) => t.incoming && t.state != TxState.cancelled).toList();
    final total = list.fold<int>(0, (a, t) => a + t.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            _Chip('Outputs', '${list.length}'),
            _Chip('Unspent', formatEpic(total)),
            _Chip('Unconfirmed', '${list.where((t) => t.state != TxState.confirmed).length}'),
          ],
        ),
        const SizedBox(height: Sp.x3),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: Column(
            children: [
              for (final (i, t) in list.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
                  child: Row(
                    children: [
                      TxStateMark(t),
                      const SizedBox(width: Sp.x3),
                      Expanded(
                        child: Text(
                          '08${t.slateId.replaceAll('-', '')}${t.slateId.replaceAll('-', '').substring(0, 30)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts.mono(size: Fs.xs, color: c.dim),
                        ),
                      ),
                      const SizedBox(width: Sp.x4),
                      SizedBox(width: 90, child: Text(t.height == null ? '-' : '${t.height}', style: ts.mono(size: Fs.xs, color: c.faint))),
                      ETag(t.state == TxState.confirmed ? 'Unspent' : 'Unconfirmed', tone: t.state == TxState.confirmed ? ETone.ok : ETone.gold),
                      const SizedBox(width: Sp.x4),
                      SizedBox(width: 150, child: Align(alignment: Alignment.centerRight, child: EMoney(t.amount, unit: false))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k ', style: context.ts.small),
          Text(v, style: context.ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
