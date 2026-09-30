import 'dart:async';

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

/// How long typing must pause before the history list filters again.
const Duration searchDebounce = Duration(milliseconds: 250);

/// One line of the history list: a day heading, or a payment.
sealed class HistoryItem {}

class HistoryHeading extends HistoryItem {
  HistoryHeading(this.title);

  final String title;
}

class HistoryRow extends HistoryItem {
  HistoryRow(this.tx);

  final TxEntry tx;
}

/// The history list as flat items for a lazy list: the payments of [txs] that pass [filter] and
/// [query], grouped as in [groupHistory]. [contactName] names a counterparty for the search.
List<HistoryItem> historyItems(
  Iterable<TxEntry> txs, {
  required HistoryFilter filter,
  required String query,
  required DateTime now,
  String? Function(String? address)? contactName,
}) {
  final shown = [
    for (final tx in txs)
      if (matchesFilter(tx, filter) &&
          matchesQuery(
            tx,
            query,
            contactName: contactName?.call(tx.counterparty),
          ))
        tx,
  ];
  return [
    for (final section in groupHistory(shown, now)) ...[
      HistoryHeading(section.title),
      for (final tx in section.transactions) HistoryRow(tx),
    ],
  ];
}

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

  /// The search text the list uses: [_search] after typing pauses for [searchDebounce].
  String _query = '';
  Timer? _debounce;

  /// The last list built, and what it was built from. Frames that change none of that (a
  /// scroll, the progress bar, a price tick) reuse it.
  List<HistoryItem> _items = const [];
  Object? _itemsKey;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (mounted) setState(() => _query = text);
    });
    // The clear button shows as soon as there is text.
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _search.clear();
      _query = '';
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(nodeTipProvider);
    try {
      await ref.read(homeProvider.notifier).reload();
    } catch (_) {
      // Shown below.
    }
  }

  List<HistoryItem> _itemsFor(
    List<TxEntry> all,
    List<Contact>? contacts,
    DateTime now,
  ) {
    final key = (
      all,
      contacts,
      _filter,
      _query,
      DateTime(now.year, now.month, now.day),
    );
    if (key != _itemsKey) {
      _itemsKey = key;
      _items = historyItems(
        all,
        filter: _filter,
        query: _query,
        now: now,
        contactName: contacts == null
            ? null
            : (address) => contactNameFor(contacts, address),
      );
    }
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final contacts = ref.watch(contactsProvider).value;
    final now = ref.watch(clockProvider)();
    final all = home.value?.transactions;
    final items = all == null
        ? const <HistoryItem>[]
        : _itemsFor(all, contacts, now);
    final theme = Theme.of(context);

    final String? empty;
    if (all == null) {
      empty = null;
    } else if (all.isEmpty) {
      empty = 'Nothing yet. Payments you send or receive show up here.';
    } else if (items.isEmpty) {
      empty = _query.trim().isEmpty
          ? 'No ${historyFilterLabel(_filter).toLowerCase()} payments.'
          : 'Nothing matches "${_query.trim()}".';
    } else {
      empty = null;
    }

    final controls = <Widget>[
      TextField(
        controller: _search,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Note, contact, address or amount',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
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
          child: LinearProgressIndicator(semanticsLabel: 'Loading payments'),
        ),
      if (home.hasError && !home.isLoading)
        ErrorText(describeError(home.error!)),
      if (empty != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList.list(children: controls),
                  ),
                  // Only the rows on screen are built, so 2,000 payments scroll like 20.
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => switch (items[i]) {
                        HistoryHeading(:final title) => Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 4),
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        HistoryRow(:final tx) => TxTile(
                          key: ValueKey('row-${tx.key}'),
                          tx: tx,
                        ),
                      },
                    ),
                  ),
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
