import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../contacts.dart' show contactNameFor, contactsProvider;
import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';

enum HistoryFilter { all, sent, received, pending, cancelled }

String historyFilterLabel(HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => 'All',
  HistoryFilter.sent => 'Sent',
  HistoryFilter.received => 'Received',
  HistoryFilter.pending => 'Pending',
  HistoryFilter.cancelled => 'Cancelled',
};

bool _outgoing(TxEntry tx) =>
    tx.kind == TxKind.sent || tx.kind == TxKind.sentCancelled;

/// Whether [tx] belongs under [filter]. Sent and Received leave out cancelled transactions,
/// which have their own filter.
bool matchesFilter(TxEntry tx, HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => true,
  HistoryFilter.sent => _outgoing(tx) && tx.status != TxStatus.cancelled,
  HistoryFilter.received => !_outgoing(tx) && tx.status != TxStatus.cancelled,
  HistoryFilter.pending => isPending(tx),
  HistoryFilter.cancelled => tx.status == TxStatus.cancelled,
};

/// Whether [query] appears in the note, counterparty, contact name, amount, slate id or kernel
/// of [tx]. Case does not matter; a decimal comma matches a decimal point.
bool matchesQuery(TxEntry tx, String query, {String? contactName}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final amount = formatEpic(txAmount(tx).amount);
  final grouped = formatEpic(txAmount(tx).amount, grouped: true);
  final fields = [
    tx.note,
    tx.counterparty,
    contactName,
    tx.slateId,
    tx.kernelExcess,
    amount,
    grouped,
  ];
  if (fields.any((f) => f != null && f.toLowerCase().contains(q))) return true;
  return amount.contains(q.replaceAll(',', '.'));
}

/// A heading and its transactions.
typedef HistorySection = ({String title, List<TxEntry> transactions});

/// Pending transactions in their own section on top, then the rest by local day, newest first.
List<HistorySection> groupHistory(Iterable<TxEntry> txs, DateTime now) {
  final ordered = pendingFirst(txs);
  final sections = <HistorySection>[];
  final pending = ordered.where(isPending).toList();
  if (pending.isNotEmpty) {
    sections.add((title: 'Pending', transactions: pending));
  }
  for (final tx in ordered.where((t) => !isPending(t))) {
    final title = dayLabel(localTime(tx.timeUnix), now);
    if (sections.isNotEmpty && sections.last.title == title) {
      sections.last.transactions.add(tx);
    } else {
      sections.add((title: title, transactions: [tx]));
    }
  }
  return sections;
}

/// Every transaction, searchable and filtered, grouped by day.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.filter = HistoryFilter.all});

  /// The filter selected when the screen opens.
  final HistoryFilter filter;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  late HistoryFilter _filter = widget.filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(nodeTipProvider);
    try {
      await ref.read(homeProvider.notifier).reload();
    } catch (_) {
      // Shown below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final contacts = ref.watch(contactsProvider).value;
    final now = ref.watch(clockProvider)();
    final all = home.value?.transactions;
    final query = _search.text;
    final shown = [
      for (final tx in all ?? const <TxEntry>[])
        if (matchesFilter(tx, _filter) &&
            matchesQuery(
              tx,
              query,
              contactName: contacts == null
                  ? null
                  : contactNameFor(contacts, tx.counterparty),
            ))
          tx,
    ];
    final sections = groupHistory(shown, now);
    final theme = Theme.of(context);

    final String? empty;
    if (all == null) {
      empty = null;
    } else if (all.isEmpty) {
      empty = 'Nothing yet. Payments you send or receive show up here.';
    } else if (shown.isEmpty) {
      empty = query.trim().isEmpty
          ? 'No ${historyFilterLabel(_filter).toLowerCase()} payments.'
          : 'Nothing matches "${query.trim()}".';
    } else {
      empty = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Note, contact, address or amount',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _search.clear()),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // One scrolling row, so the list starts higher on a phone.
                  FadingRow(
                    children: [
                      for (final filter in HistoryFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(historyFilterLabel(filter)),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                  if (home.isLoading && all == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Loading payments',
                      ),
                    ),
                  if (home.hasError && !home.isLoading)
                    ErrorText(describeError(home.error!)),
                  if (empty != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(empty, textAlign: TextAlign.center),
                    ),
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Semantics(
                        header: true,
                        child: Text(
                          section.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    for (final tx in section.transactions) TxTile(tx: tx),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row whose edge fades while more lies beyond it, so a cut-off chip
/// reads as "scroll for more".
class FadingRow extends StatefulWidget {
  const FadingRow({super.key, required this.children});

  final List<Widget> children;

  @override
  State<FadingRow> createState() => FadingRowState();
}

class FadingRowState extends State<FadingRow> {
  bool _moreLeft = false;
  bool _moreRight = false;

  /// Content lies beyond the left edge, which then fades.
  bool get moreLeft => _moreLeft;

  /// Content lies beyond the right edge, which then fades.
  bool get moreRight => _moreRight;

  bool _onMetrics(ScrollMetrics metrics) {
    final left = metrics.pixels > metrics.minScrollExtent;
    final right = metrics.pixels < metrics.maxScrollExtent;
    if (left != _moreLeft || right != _moreRight) {
      setState(() {
        _moreLeft = left;
        _moreRight = right;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const edge = 0.08;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              _moreLeft ? Colors.transparent : Colors.black,
              Colors.black,
              Colors.black,
              _moreRight ? Colors.transparent : Colors.black,
            ],
            stops: const [0, edge, 1 - edge, 1],
          ).createShader(bounds),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: widget.children),
          ),
        ),
      ),
    );
  }
}
