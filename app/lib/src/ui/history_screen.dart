// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math' as math;

import '../devices/phone_devices.dart' show watchHistory;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../contacts.dart' show contactNameFor, contactsProvider;
import '../errors.dart';
import '../initials.dart' show nameInitials;
import '../l10n.dart';
import '../providers.dart';
import 'theme/tokens.dart';
import '../settings.dart';
import '../wallet_service.dart';
import '../pairing_providers.dart' show pairingsProvider;
import 'common.dart';
import 'invoice_review_screen.dart';
import 'invoices_screen.dart' show invoiceSenderName;
import 'kit/kit_avatar.dart';
import 'kit/kit_button.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_search_field.dart';
import 'kit/kit_segmented.dart';
import 'kit/kit_tokens.dart';
import '../trust_ids.dart';
import 'phone_tx_row.dart';
import 'post_finished_screen.dart' show openPostFinished;
import 'tour/tour_target.dart';

enum HistoryFilter { all, sent, received, pending, cancelled }

/// The filters the segmented control offers, in the frame's order. Pending and Cancelled stay
/// as values (Home opens Activity on Pending); a cancelled payment stays in the list, greyed.
const _segmentFilters = [HistoryFilter.all, HistoryFilter.received, HistoryFilter.sent];

/// The filter's chip label.
String historyFilterLabel(AppLocalizations l, HistoryFilter filter) =>
    switch (filter) {
      HistoryFilter.all => l.historyFilterAll,
      HistoryFilter.sent => l.historyFilterSent,
      HistoryFilter.received => l.historyFilterReceived,
      HistoryFilter.pending => l.historyFilterPending,
      HistoryFilter.cancelled => l.historyFilterCancelled,
    };

/// What the list says when [filter] matches none of the wallet's payments. Every payment
/// passes [HistoryFilter.all], so that case only says the wallet has none.
String _noneUnder(AppLocalizations l, HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => l.historyEmpty,
  HistoryFilter.sent => l.historyNoSent,
  HistoryFilter.received => l.historyNoReceived,
  HistoryFilter.pending => l.historyNoPending,
  HistoryFilter.cancelled => l.historyNoCancelled,
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

/// Whether [query] appears in the label, note, counterparty, contact name, amount, slate id or kernel
/// of [tx]. Case does not matter; a decimal comma matches a decimal point.
bool matchesQuery(TxEntry tx, String query, {String? contactName}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final amount = formatEpic(txAmount(tx).amount);
  final grouped = formatEpic(txAmount(tx).amount, grouped: true);
  // What the row shows, which may have fewer decimals.
  final shown = displayEpic(txAmount(tx).amount);
  final fields = [
    tx.label,
    tx.note,
    tx.counterparty,
    contactName,
    tx.slateId,
    tx.kernelExcess,
    amount,
    grouped,
    shown,
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
  HistoryHeading(this.title, {this.pending = false});

  final String title;

  /// The heading of the open payments, which the screen words "In progress".
  final bool pending;
}

class HistoryRow extends HistoryItem {
  HistoryRow(this.tx);

  final TxEntry tx;
}

/// The history list as flat items for a lazy list: the payments of [txs] that pass [filter] and
/// [query], grouped as in [groupHistory]. [contactName] names a counterparty for the search.
List<HistoryItem> historyItems(
  AppLocalizations l,
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
    for (final section in groupHistory(l, shown, now)) ...[
      HistoryHeading(section.title, pending: section.transactions.any(isPending)),
      for (final tx in section.transactions) HistoryRow(tx),
    ],
  ];
}

/// Pending transactions in their own section on top, then the rest by local day, newest first.
List<HistorySection> groupHistory(
  AppLocalizations l,
  Iterable<TxEntry> txs,
  DateTime now,
) {
  final ordered = pendingFirst(txs);
  final sections = <HistorySection>[];
  final pending = ordered.where(isPending).toList();
  if (pending.isNotEmpty) {
    sections.add((title: l.historySectionPending, transactions: pending));
  }
  for (final tx in ordered.where((t) => !isPending(t))) {
    final title = dayLabel(l, localTime(tx.timeUnix), now);
    if (sections.isNotEmpty && sections.last.title == title) {
      sections.last.transactions.add(tx);
    } else {
      sections.add((title: title, transactions: [tx]));
    }
  }
  return sections;
}

/// The key of the Kill switch caption above the list, for tests.
const Key historyLastKnownKey = ValueKey('history-last-known');

/// The key of the Activity menu, for tests.
const Key historyMenuKey = ValueKey('history-menu');

/// The key of the menu's Post a finished payment entry, for tests.
const Key historyPostFinishedKey = ValueKey('history-post-finished');

/// The id a driver finds a filter segment by.
String historyFilterId(HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => TrustIds.activityFilterAll,
  HistoryFilter.sent => TrustIds.activityFilterSent,
  HistoryFilter.received => TrustIds.activityFilterReceived,
  HistoryFilter.pending => TrustIds.activityFilterPending,
  HistoryFilter.cancelled => TrustIds.activityFilterCancelled,
};

/// Every transaction, searchable and filtered, grouped by day (the Activity frame): the title
/// and the "…" menu, the search field, the All / Received / Sent control, the invoices that need
/// the user, the payments in progress, then the days.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.filter = HistoryFilter.all, this.query});

  /// The filter selected when the screen opens.
  final HistoryFilter filter;

  /// The search text the screen opens with (a contact's name from its page).
  final String? query;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final _search = TextEditingController(text: widget.query ?? '');
  late HistoryFilter _filter = widget.filter;

  /// The search text the list uses: [_search] after typing pauses for [searchDebounce].
  late String _query = widget.query ?? '';
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
    AppLocalizations l,
    List<TxEntry> all,
    List<Contact>? contacts,
    DateTime now,
  ) {
    final key = (
      l.localeName,
      all,
      contacts,
      _filter,
      _query,
      DateTime(now.year, now.month, now.day),
    );
    if (key != _itemsKey) {
      _itemsKey = key;
      _items = historyItems(
        l,
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

  void _help() {
    final l = context.l10n;
    showKitHelp(
      context,
      title: l.phoneActHelpTitle,
      lines: [l.phoneActHelp1, l.phoneActHelp2, l.phoneActHelp3],
      sheetId: TrustIds.activityHelpSheet,
      moreId: TrustIds.activityHelpMore,
    );
  }

  Widget _menu(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return PopupMenuButton<String>(
      key: historyMenuKey,
      tooltip: l.phoneActMenu,
      icon: Icon(KitIcons.more, color: t.text),
      onSelected: (value) => value == 'help' ? _help() : openPostFinished(context),
      itemBuilder: (_) => [
        PopupMenuItem<String>(value: 'help', child: Text(l.sendHelp)),
        PopupMenuItem<String>(key: historyPostFinishedKey, value: 'post-finished', child: Text(l.postFinishedTitle)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final home = ref.watch(homeProvider);
    final contacts = ref.watch(contactsProvider).value;
    final now = ref.watch(clockProvider)();
    final rows = home.value?.transactions;
    // With the payments the linked devices make.
    final all = rows == null ? null : watchHistory(ref, rows);
    final items = all == null
        ? const <HistoryItem>[]
        : _itemsFor(l, all, contacts, now);
    final searching = _query.trim().isNotEmpty;

    final String? empty;
    if (all == null) {
      empty = null;
    } else if (all.isEmpty) {
      empty = l.historyEmpty;
    } else if (items.isEmpty) {
      empty = searching ? l.historyNoMatch(_query.trim()) : _noneUnder(l, _filter);
    } else {
      empty = null;
    }

    final canPop = Navigator.of(context).canPop();
    final header = canPop
        ? KitPageHeader(
            backLabel: l.phoneKitBack,
            onBack: () => Navigator.of(context).maybePop(),
            title: l.historyTitle,
            onHelp: _help,
            backId: TrustIds.activityBack,
            helpId: TrustIds.activityHelp,
          )
        : KitTabTitle(l.historyTitle, trailing: _menu(context));

    return SlotScaffold(
      // Only the first load shows the bar: a refresh runs in the background, often during a
      // sync, and the list it refreshes stays on screen.
      idle: home.isLoading && all == null ? SlotProgress(label: l.historyLoading) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PhoneTourTarget(
              id: 'tour-activity-list',
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: header),
                    SliverToBoxAdapter(
                      child: KitSearchField(
                        controller: _search,
                        hint: l.phoneActSearchHint,
                        onChanged: _onSearchChanged,
                        semanticsId: TrustIds.activitySearch,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: KitSegmented<HistoryFilter>(
                          value: _filter,
                          onChanged: (filter) => setState(() => _filter = filter),
                          segments: [
                            for (final filter in _segmentFilters)
                              KitSegment(
                                value: filter,
                                label: historyFilterLabel(l, filter),
                                semanticsId: historyFilterId(filter),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (home.hasError && !home.isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0),
                          child: ErrorText(describeError(l, home.error!)),
                        ),
                      ),
                    // Kill switch asks no node: the list is the one seen last.
                    if (ref.watch(balanceLastKnownProvider))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 12, Kit.gutter + 4, 0),
                          child: Text(
                            l.lastKnownList,
                            key: historyLastKnownKey,
                            style: KitType.rowSub.copyWith(color: t.dim),
                          ),
                        ),
                      ),
                    // An invoice waiting for the user sits on top of the whole list.
                    if (_filter == HistoryFilter.all && !searching)
                      const SliverToBoxAdapter(child: _NeedsYou()),
                    if (empty != null)
                      SliverLayoutBuilder(
                        builder: (context, box) => SliverToBoxAdapter(
                          // The rest of the screen, so the state sits in the middle of it.
                          child: SizedBox(
                            height: math.max(box.remainingPaintExtent, 320),
                            child: KitEmptyState(
                          icon: searching ? Icons.search_off_rounded : KitIcons.activity,
                          title: all != null && all.isEmpty ? l.phoneActEmptyTitle : l.phoneActNoneTitle,
                          message: empty,
                          // The way out of a search that matches nothing, as on the desktop.
                          actionLabel: searching ? l.historyClearSearch : null,
                          onAction: searching ? _clearSearch : null,
                          actionId: TrustIds.activityClearSearch,
                            ),
                          ),
                        ),
                      )
                    else
                      // Only the rows on screen are built, so 2,000 payments scroll like 20.
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 24),
                        sliver: SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) => switch (items[i]) {
                            HistoryHeading(:final title, :final pending) => KitGroupLabel(
                              pending ? l.phoneActInProgress : title,
                            ),
                            HistoryRow(:final tx) => _GroupSegment(
                              first: i == 0 || items[i - 1] is HistoryHeading,
                              last: i == items.length - 1 || items[i + 1] is HistoryHeading,
                              child: PhoneTxRow(key: ValueKey('row-${tx.key}'), tx: tx),
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
      ),
    );
  }
}

/// One row of a [KitGroup] drawn on its own, so a long day builds only the rows on screen: the
/// group fill and edge, rounded on the first and last row, a hair divider under all but the
/// last, starting after the avatar.
class _GroupSegment extends StatelessWidget {
  const _GroupSegment({required this.first, required this.last, required this.child});

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.vertical(
      top: first ? const Radius.circular(Kit.rGroup) : Radius.zero,
      bottom: last ? const Radius.circular(Kit.rGroup) : Radius.zero,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: CustomPaint(
        painter: _SegmentPainter(fill: t.group, edge: t.hair, first: first, last: last),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                child,
                if (!last)
                  Positioned(
                    left: Kit.dividerInsetList,
                    right: 0,
                    bottom: 0,
                    child: const KitHairline(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The fill and 1 px edge of one [_GroupSegment]: the rounded group outline, clipped to the row
/// so the sides run straight into the neighbouring rows.
class _SegmentPainter extends CustomPainter {
  const _SegmentPainter({required this.fill, required this.edge, required this.first, required this.last});

  final Color fill;
  final Color edge;
  final bool first;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Kit.rGroup;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // A row in the middle of a group draws the outline of a taller shape, off the clip.
    final rect = Rect.fromLTRB(0, first ? 0 : -2 * r, size.width, last ? size.height : size.height + 2 * r);
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(r));
    canvas.drawRRect(shape, Paint()..color = fill);
    canvas.drawRRect(
      shape.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = edge,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.fill != fill || old.edge != edge || old.first != first || old.last != last;
}

/// The key of an invoice's Needs-you card.
Key needsYouInvoiceKey(String slateId) => ValueKey('quiet-invoice-$slateId');

/// The invoices waiting for the user, a gold-tinted card each with a Review button: the one
/// gold button of Activity. Nothing when none waits.
class _NeedsYou extends ConsumerWidget {
  const _NeedsYou();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(pendingInvoicesProvider).value ?? const <PendingInvoice>[];
    if (invoices.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final display = amountDisplay(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitGroupLabel(l.phoneActNeedsYou),
        for (final invoice in invoices)
          _NeedsYouCard(
            key: needsYouInvoiceKey(invoice.slateId),
            invoice: invoice,
            who: invoiceSenderName(l, pairings, contacts, invoice.pairingId),
            amount: shownEpic(l, invoice.amount, hidden: display.hidden),
          ),
      ],
    );
  }
}

class _NeedsYouCard extends StatelessWidget {
  const _NeedsYouCard({super.key, required this.invoice, required this.who, required this.amount});

  final PendingInvoice invoice;
  final String who;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InvoiceReviewScreen(invoice: invoice)),
    );
    final initials = nameInitials(who, count: 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 8),
      child: Semantics(
        container: true,
        label: [who, l.phoneActInvoiceFor(amount)].join(', '),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.goldSoft,
            borderRadius: BorderRadius.circular(Kit.rGroup),
            border: Border.all(color: t.goldLine),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: initials.isEmpty ? const KitAvatar(icon: KitIcons.invoice) : KitAvatar(initials: initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(who, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: t.info, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l.phoneActInvoiceFor(amount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KitType.rowSub.copyWith(color: t.info),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                KitButton(
                  label: l.phoneActReview,
                  onPressed: open,
                  small: true,
                  semanticsId: TrustIds.activityReview,
                ),
              ],
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
