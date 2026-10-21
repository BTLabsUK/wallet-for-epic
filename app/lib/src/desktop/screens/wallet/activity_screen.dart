import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'tx_detail.dart';
import 'tx_display.dart';

enum ActivityTab { transactions, outputs }

enum _Filter { all, received, sent }

enum _OutFilter { all, unspent, unconfirmed }

/// Starts Activity on a tab, a selected transaction, or the empty state.
class ActivityArgs {
  const ActivityArgs({this.tab = ActivityTab.transactions, this.txId, this.empty = false, this.waitingNode = false, this.query});

  final ActivityTab tab;
  final int? txId;
  final bool empty;

  /// Empty and the node not synced yet: a waiting line instead of the learn panel.
  final bool waitingNode;
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
  final _outQuery = TextEditingController();
  _Filter _filter = _Filter.all;
  _OutFilter _outFilter = _OutFilter.all;
  int _page = 0;
  int _outPage = 0;
  bool _refreshing = false;

  bool get _noTxs => _args.empty || _args.waitingNode;

  @override
  void dispose() {
    _query.dispose();
    _outQuery.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    ref.invalidate(deskOutputsProvider);
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

  /// The search of the tab that shows. [full] fills its row (narrow layout).
  Widget _search({required bool full, required bool hasItems}) {
    final width = MediaQuery.sizeOf(context).width;
    final outputs = _tab == ActivityTab.outputs;
    final ctl = outputs ? _outQuery : _query;
    final input = EInput(
      controller: ctl,
      enabled: hasItems,
      hint: hasItems ? (outputs ? 'Commitment' : 'Address or slate id') : 'Nothing to search yet',
      leading: EIcons.search,
      semanticLabel: outputs ? 'Search outputs' : 'Search transactions',
      onChanged: (_) => setState(() => outputs ? _outPage = 0 : _page = 0),
      trailing: ctl.text.isEmpty ? null : EIconButton(icon: EIcons.close, label: 'Clear search', size: EBtnSize.inline, onPressed: () => setState(ctl.clear)),
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
    final outputs = _noTxs ? const AsyncValue<List<Output>>.data([]) : ref.watch(deskOutputsProvider);
    final selectedTx = all?.where((t) => t.id == _selected).firstOrNull;
    final hasItems = _tab == ActivityTab.outputs ? (outputs.value?.isNotEmpty ?? false) : (all?.isNotEmpty ?? false);

    final tabs = ESegmented<ActivityTab>(
      segments: const [ESegment(ActivityTab.transactions, 'Transactions'), ESegment(ActivityTab.outputs, 'Outputs')],
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
    );
    final actions = <Widget>[
      if (roomy) ...[tabs, SizedBox(width: Sp.x2), _search(full: false, hasItems: hasItems)],
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

    final body = _tab == ActivityTab.outputs ? _outputs(outputs, s.balance) : _txList(all);
    final list = roomy
        ? body
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: tabs),
              SizedBox(height: Sp.x3),
              _search(full: true, hasItems: hasItems),
              SizedBox(height: Sp.x4),
              body,
            ],
          );
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
                SizedBox(width: Sp.x6),
                SizedBox(
                  width: width >= 1400.u ? 440.u : 380.u,
                  child: _DetailPane(tx: selectedTx, onClose: () => setState(() => _selected = null)),
                ),
              ],
            )
          : SingleChildScrollView(child: list),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
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
          ),
        ),
        SizedBox(height: Sp.x3),
        if (shown.isEmpty)
          _panel(
            EEmpty(
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
            ),
          )
        else
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const _ListHead(), ...rows])),
        _Pager(pages: pages, page: page, onPage: (p) => setState(() => _page = p)),
      ],
    );
  }

  Widget _panel(Widget child) {
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: child,
    );
  }

  Widget _outputs(AsyncValue<List<Output>> value, Balance? balance) {
    final ts = context.ts;
    final head = <Widget>[
      if (balance != null) ...[_OutputSummary(balance: balance), SizedBox(height: Sp.x4)],
      Text('Outputs are the coins the balance is made of. A send spends whole outputs and returns the change as a new one.', style: ts.bodyDim),
      SizedBox(height: Sp.x4),
    ];
    Widget column(List<Widget> rest) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...head, ...rest]);
    final all = value.value;
    if (all == null) {
      if (value.hasError) {
        return column([_panel(EEmpty(icon: EIcons.coins, title: 'Outputs not loaded', text: 'Refresh to try again.'))]);
      }
      return column([_waiting('Loading wallet data')]);
    }
    if (all.isEmpty) {
      if (_args.waitingNode) return column([_waiting('Waiting for the node to be synced.')]);
      return column([_panel(EEmpty(icon: EIcons.coins, title: 'No outputs yet', text: 'Coins appear here once the wallet receives its first payment.'))]);
    }
    final q = _outQuery.text.trim().toLowerCase();
    final shown = [
      for (final o in all)
        if ((_outFilter == _OutFilter.all ||
                (_outFilter == _OutFilter.unspent && o.status == OutputStatus.unspent) ||
                (_outFilter == _OutFilter.unconfirmed && o.status == OutputStatus.unconfirmed)) &&
            (q.isEmpty || o.commitment.contains(q)))
          o,
    ];
    final pages = (shown.length / _pageSize).ceil();
    final page = _outPage.clamp(0, (pages - 1).clamp(0, 999));
    final slice = shown.skip(page * _pageSize).take(_pageSize).toList();
    final c = context.dc;
    return column([
      Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ESegmented<_OutFilter>(
            segments: [
              ESegment(_OutFilter.all, 'All', count: all.length),
              ESegment(_OutFilter.unspent, 'Unspent', count: all.where((o) => o.status == OutputStatus.unspent).length),
              ESegment(_OutFilter.unconfirmed, 'Unconfirmed', count: all.where((o) => o.status == OutputStatus.unconfirmed).length),
            ],
            value: _outFilter,
            onChanged: (v) => setState(() {
              _outFilter = v;
              _outPage = 0;
            }),
          ),
        ),
      ),
      SizedBox(height: Sp.x3),
      if (shown.isEmpty)
        _panel(
          EEmpty(
            icon: EIcons.search,
            title: 'No outputs match',
            text: 'Try another commitment, or clear the filter.',
            actions: [
              EButton.ghost(
                label: 'Clear search',
                onPressed: () => setState(() {
                  _outQuery.clear();
                  _outFilter = _OutFilter.all;
                }),
              ),
            ],
          ),
        )
      else
        _panel(
          Semantics(
            label: 'Outputs',
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _OutputHead(),
                for (final (i, o) in slice.indexed) ...[if (i > 0) Divider(height: 1, color: c.line), _OutputRow(output: o, tip: _tipHeight(ref))],
              ],
            ),
          ),
        ),
      _Pager(pages: pages, page: page, onPage: (p) => setState(() => _outPage = p)),
    ]);
  }
}

/// The chain tip, for "blocks to go".
int _tipHeight(WidgetRef ref) => ref.read(deskProvider).status?.nodeHeight ?? 0;

/// Page buttons: the first and last pages with the current one in the middle, "Page X of Y".
/// Wraps instead of overflowing; on a narrow row only previous, "Page X of Y" and next.
class _Pager extends StatelessWidget {
  const _Pager({required this.pages, required this.page, required this.onPage});

  final int pages;

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
      padding: EdgeInsets.only(top: Sp.x4),
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

class _ListHead extends StatelessWidget {
  const _ListHead();

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
                width: 52.u,
                child: Text('Time', style: style),
              ),
              SizedBox(width: Sp.x4),
              Text('Amount', style: style),
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
              stage(const ERing(confirmations: 2), 'Confirming', 'On the chain. About one block a minute.'),
              stage(const ERing(confirmations: 10), 'Spendable', 'After $minConfirmations confirmations, about $minConfirmations minutes.'),
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
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.lineStrong),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56.u,
            padding: EdgeInsets.only(left: Sp.x5, right: Sp.x2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(tx.incoming ? 'Received transaction' : 'Sent transaction', style: context.ts.h3)),
                ),
                EIconButton(icon: EIcons.close, label: 'Close', onPressed: onClose),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Sp.x5),
              child: TxDetail(tx: tx),
            ),
          ),
        ],
      ),
    );
  }
}

/// The balance lines above the outputs.
class _OutputSummary extends StatelessWidget {
  const _OutputSummary({required this.balance});

  final Balance balance;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    Widget item(String label, int nano, {bool unit = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ts.small),
        SizedBox(height: 2),
        EMoney(nano, unit: unit, size: Fs.md, color: nano == 0 ? c.faint : c.text),
      ],
    );
    return Semantics(
      container: true,
      label: 'Balance',
      child: Wrap(
        spacing: Sp.x8,
        runSpacing: Sp.x3,
        children: [
          item('Spendable', balance.spendable, unit: true),
          item('Confirming', balance.awaitingConfirmation),
          item('Awaiting finalization', balance.awaitingFinalization),
          if (balance.immature > 0) item('Immature', balance.immature),
          item('Locked', balance.locked),
        ],
      ),
    );
  }
}

/// "08c7a1e9f0…b2d4a6c8e0": both ends of a long id.
String _mid(String s, int keep) => s.length <= keep * 2 + 1 ? s : '${s.substring(0, keep)}…${s.substring(s.length - keep)}';

String _group(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class _OutputHead extends StatelessWidget {
  const _OutputHead();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final style = context.ts.caption.copyWith(fontWeight: FontWeight.w600);
    return LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxWidth >= 640.u;
        return Container(
          height: 36.u,
          padding: EdgeInsets.symmetric(horizontal: Sp.x5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(child: Text('Commitment', style: style)),
              if (roomy) ...[
                SizedBox(width: Sp.x4),
                SizedBox(
                  width: 96.u,
                  child: Text('Height', style: style),
                ),
              ],
              SizedBox(width: Sp.x4),
              SizedBox(
                width: 120.u,
                child: Text('Value', style: style, textAlign: TextAlign.right),
              ),
              if (roomy) ...[
                SizedBox(width: Sp.x4),
                SizedBox(
                  width: 200.u,
                  child: Text('Status', style: style),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({required this.output, required this.tip});

  final Output output;
  final int tip;

  (String, String?, ETone) _status() {
    final o = output;
    return switch (o.status) {
      OutputStatus.confirming => ('Confirming ${o.confirmations}/$minConfirmations', null, ETone.warn),
      OutputStatus.unconfirmed => ('Unconfirmed', null, ETone.neutral),
      OutputStatus.unspent => ('Unspent', null, ETone.ok),
      OutputStatus.immature => ('Immature', o.lockHeight != null && o.lockHeight! > tip ? '${_group(o.lockHeight! - tip)} blocks to go' : null, ETone.warn),
      OutputStatus.locked => ('Locked', null, ETone.neutral),
      OutputStatus.spent => ('Spent', null, ETone.neutral),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final o = output;
    final spent = o.status == OutputStatus.spent;
    final (word, note, tone) = _status();
    final toneColor = switch (tone) {
      ETone.ok => c.ok,
      ETone.warn => c.warn,
      _ => c.dim,
    };
    final mark = switch (o.status) {
      OutputStatus.confirming => ERing(confirmations: o.confirmations, needed: minConfirmations, size: 18.u),
      OutputStatus.unconfirmed => ERing(confirmations: 0, size: 18.u),
      OutputStatus.unspent => Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok),
      OutputStatus.immature => Icon(EIcons.sand, size: Ctl.iconSm, color: c.warn),
      OutputStatus.locked => Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim),
      OutputStatus.spent => Icon(EIcons.minusCircle, size: Ctl.iconSm, color: c.faint),
    };
    final status = Row(
      children: [
        mark,
        SizedBox(width: Sp.x2),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: word,
                  style: TextStyle(color: toneColor),
                ),
                if (note != null)
                  TextSpan(
                    text: ' · $note',
                    style: TextStyle(color: c.faint),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts.small,
          ),
        ),
      ],
    );
    final commitment = Row(
      children: [
        Flexible(
          child: Tooltip(
            message: o.commitment,
            child: Text(
              _mid(o.commitment, 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts.mono(size: Fs.xs, color: spent ? c.faint : c.dim),
            ),
          ),
        ),
        ECopyButton(text: o.commitment, label: 'Copy commitment ${_mid(o.commitment, 8)}'),
      ],
    );
    final value = Align(
      alignment: Alignment.centerRight,
      child: EMoney(o.value, unit: false, color: spent ? c.faint : c.text),
    );
    return Opacity(
      opacity: spent ? 0.7 : 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= 600.u) {
              return Row(
                children: [
                  Expanded(child: commitment),
                  SizedBox(width: Sp.x4),
                  SizedBox(
                    width: 96.u,
                    child: Text(
                      o.height == null ? '-' : _group(o.height!),
                      style: ts.mono(size: Fs.xs, color: c.faint),
                    ),
                  ),
                  SizedBox(width: Sp.x4),
                  SizedBox(width: 120.u, child: value),
                  SizedBox(width: Sp.x4),
                  SizedBox(width: 200.u, child: status),
                ],
              );
            }
            // Narrow: commitment and value on the first line, status and height under them.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: commitment),
                    SizedBox(width: Sp.x3),
                    value,
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: status),
                    if (o.height != null)
                      Text(
                        _group(o.height!),
                        style: ts.mono(size: Fs.xs, color: c.faint),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
