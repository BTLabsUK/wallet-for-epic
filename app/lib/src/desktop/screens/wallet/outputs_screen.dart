// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../../l10n.dart' show localInt;
import '../../widgets/kit.dart';
import 'activity_screen.dart' show ListPager;
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../../../devices/device_providers.dart' show holdOf;
import '../../data/devices_state.dart' show deskDeviceBookProvider;
import '../settings/settings_devices.dart' show deskReleaseHeld;
import '../../../models.dart' show defaultMinimumConfirmations;
import '../../../smart_outputs.dart' show OutputPart;
import 'outputs_dialogs.dart';
import 'tx_display.dart' show iconOf, shortDayMonth;

/// The list's filter on the Outputs page.
enum OutputsFilter { all, spendable, confirming, locked }

/// Starts the Outputs page on given data (the screenshot tour) or a state.
class OutputsArgs {
  const OutputsArgs({this.outputs, this.balance, this.filter = OutputsFilter.all, this.showSpent = false, this.waiting = false, this.error = false});

  /// Shown instead of the wallet's; [balance] with them.
  final List<Output>? outputs;
  final Balance? balance;
  final OutputsFilter filter;
  final bool showSpent;

  /// Loading, as before the first answer.
  final bool waiting;

  /// The list could not be read.
  final bool error;
}

const int _pageSize = 20;

/// "08c7a1…b2d4a6": both ends of a commitment, the whole on hover and when copied.
String shortCommitment(String s) => s.length <= 13 ? s : '${s.substring(0, 6)}…${s.substring(s.length - 6)}';

String _group(AppLocalizations l, int n) => localInt(l, n);

/// [w]'s [OutputPart]: the one mapping the tiles, the filter tabs' counts and the table share.
OutputPart? outputPart(OutputWord w) => switch (w) {
  OutputWord.spendable => OutputPart.spendable,
  OutputWord.confirming || OutputWord.finalizing => OutputPart.confirming,
  OutputWord.immature || OutputWord.mining => OutputPart.immature,
  OutputWord.locked => OutputPart.locked,
  OutputWord.unpaidInvoice || OutputWord.spent => null,
};

/// Whether the table lists an output of [w] under [filter]: All lists every output with an
/// [OutputPart] (what Total counts, UD-008), and the spent ones with [showSpent]; each other
/// filter lists its part. An unpaid invoice's output is in none.
bool outputListed(OutputsFilter filter, OutputWord w, {bool showSpent = false}) => switch (filter) {
  OutputsFilter.all => outputPart(w) != null || (showSpent && w == OutputWord.spent),
  OutputsFilter.spendable => outputPart(w) == OutputPart.spendable,
  OutputsFilter.confirming => outputPart(w) == OutputPart.confirming,
  OutputsFilter.locked => outputPart(w) == OutputPart.locked,
};

/// How many outputs of each [OutputPart], and in Total: every output with a part, so Total =
/// All = the sum of the tiles (UD-008).
typedef OutputCounts = ({int spendable, int confirming, int immature, int locked, int total});

/// The Outputs page's Total value: the sum of its tiles' values (Confirming's takes awaiting
/// finalization), so it adds up as its count does. Only this page: elsewhere the balance's own
/// [Balance.total] stays the headline.
int outputsTotalValue(Balance b) => b.spendable + b.awaitingConfirmation + b.awaitingFinalization + b.immature + b.locked;

OutputCounts outputCounts(List<Output> all) {
  var s = 0, c = 0, i = 0, l = 0, t = 0;
  for (final o in all) {
    final part = outputPart(o.word);
    switch (part) {
      case OutputPart.spendable:
        s++;
      case OutputPart.confirming:
        c++;
      case OutputPart.immature:
        i++;
      case OutputPart.locked:
        l++;
      case null:
        break;
    }
    if (part != null) t++;
  }
  return (spendable: s, confirming: c, immature: i, locked: l, total: t);
}

/// Outputs: the balance by part, every output with its status and transaction, then
/// Advanced: what outputs are, Split and Consolidate, and a line to the defaults Send uses
/// (Settings › Transactions). Tiles, table, management, as on the phone.
class OutputsScreen extends ConsumerStatefulWidget {
  const OutputsScreen({super.key, this.arg});

  /// An [OutputsArgs].
  final Object? arg;

  @override
  ConsumerState<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends ConsumerState<OutputsScreen> {
  late final OutputsArgs _args = widget.arg is OutputsArgs ? widget.arg! as OutputsArgs : const OutputsArgs();
  final _query = TextEditingController();
  late OutputsFilter _filter = _args.filter;
  late bool _showSpent = _args.showSpent;
  int _page = 0;
  bool _refreshing = false;

  /// The cards' estimates, for the balance they were made with.
  Balance? _estimatedFor;
  SendEstimate? _split;
  SendEstimate? _consolidate;
  bool _dialogOpen = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Release by hand on the coin another device's payment holds (the plan's confirm).
  Future<void> _releaseHeld(Output o) async {
    final book = ref.read(deskDeviceBookProvider);
    final hold = book == null ? null : holdOf(book, o.commitment);
    if (hold != null) await deskReleaseHeld(context, ref, hold);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(deskProvider.notifier).syncNow();
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskOutNotUpdated, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) {
        ref.invalidate(deskOutputsProvider);
        setState(() => _refreshing = false);
      }
    }
  }

  /// The fee notes on the cards: once per balance, never while a dialog is open.
  void _estimateFor(Balance b, int spendableCount) {
    if (_dialogOpen || identical(b, _estimatedFor)) return;
    _estimatedFor = b;
    final api = ref.read(deskApiProvider);
    if (spendableCount < 1 || b.locked > 0) {
      _split = null;
      _consolidate = null;
      return;
    }
    api.estimateSplit(2).then((e) => mounted ? setState(() => _split = e) : null, onError: (_) => mounted ? setState(() => _split = null) : null);
    if (spendableCount >= 2) {
      api.estimateConsolidate().then((e) => mounted ? setState(() => _consolidate = e) : null, onError: (_) => mounted ? setState(() => _consolidate = null) : null);
    }
  }

  Future<void> _open(Future<void> Function() dialog) async {
    _dialogOpen = true;
    await dialog();
    _dialogOpen = false;
    if (!mounted) return;
    // Posted, cancelled or not: the outputs and the balance are read again.
    ref.invalidate(deskOutputsProvider);
    try {
      await ref.read(deskProvider.notifier).refresh();
    } on Object {
      // The next refresh shows it.
    }
    if (mounted) setState(() => _estimatedFor = null);
  }

  bool _matches(Output o, String q) =>
      outputListed(_filter, o.word, showSpent: _showSpent) && (q.isEmpty || o.commitment.contains(q));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(deskProvider);
    final hidden = s.settings.hideAmounts;
    final AsyncValue<List<Output>> value = _args.error
        ? AsyncValue.error('demo', StackTrace.empty)
        : _args.waiting
        ? const AsyncValue.loading()
        : _args.outputs != null
        ? AsyncValue.data(_args.outputs!)
        : ref.watch(deskOutputsProvider);
    final balance = _args.balance ?? s.balance;
    final all = value.value;
    final counts = outputCounts(all ?? const []);
    if (balance != null && all != null) {
      final b = balance;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _estimateFor(b, counts.spendable);
      });
    }

    return EPage(
      title: l.deskOutTitle,
      width: EPageWidth.full,
      actions: [
        EIconButton(
          icon: hidden ? EIcons.eyeOff : EIcons.eye,
          label: hidden ? l.deskOutShowAmounts : l.deskOutHideAmounts,
          selected: hidden,
          onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
        ),
        _refreshing
            ? SizedBox.square(dimension: Ctl.sm, child: const Center(child: ESpinner()))
            : EIconButton(icon: EIcons.refresh, label: l.deskOutRefresh, onPressed: _refresh),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tiles(balance: balance, counts: all == null ? null : counts),
          SizedBox(height: Sp.x4),
          ..._list(value, counts),
          // The management part, after the table: what outputs are, Split and Consolidate,
          // a line to where the defaults for sends are.
          ESectionHead(l.deskOutAdvanced, top: Sp.x8),
          Text(l.deskOutIntro, style: context.ts.bodyDim),
          SizedBox(height: Sp.x4),
          _cards(balance, counts, loaded: all != null),
          const _DefaultsMoved(),
        ],
      ),
    );
  }

  Widget _cards(Balance? b, OutputCounts counts, {required bool loaded}) {
    final l = context.l10n;
    final locked = (b?.locked ?? 0) > 0 || counts.locked > 0;
    final wait = l.deskOutCardWait(deskMinConfirmations(ref));
    final splitOn = loaded && !locked && counts.spendable >= 1 && _split != null;
    final splitNote = !loaded
        ? ''
        : locked
        ? wait
        : counts.spendable == 0
        ? l.deskOutSplitNothing
        : _split == null
        ? l.deskOutSplitSpends(counts.spendable)
        : l.deskOutSplitSpendsFee(counts.spendable, formatEpicL(l, _split!.fee, minDecimals: 3));
    final consOn = loaded && !locked && counts.spendable >= 2;
    final consNote = !loaded
        ? ''
        : locked
        ? wait
        : counts.spendable == 0
        ? l.deskOutConsNothing
        : counts.spendable == 1
        ? l.deskOutConsOne
        : _consolidate == null
        ? l.deskOutConsInto(counts.spendable)
        : l.deskOutConsIntoFee(counts.spendable, formatEpicL(l, _consolidate!.fee, minDecimals: 3));
    final split = _ActionCard(
      icon: EIcons.split,
      title: l.deskOutSplitCardTitle,
      text: l.deskOutSplitCardText,
      note: splitNote,
      button: l.deskOutSplitCardButton,
      enabled: splitOn,
      onPressed: () => _open(() => showSplitDialog(context)),
    );
    final consolidate = _ActionCard(
      icon: EIcons.merge,
      title: l.deskOutConsCardTitle,
      text: l.deskOutConsCardText,
      note: consNote,
      button: l.deskOutConsCardButton,
      enabled: consOn,
      onPressed: () => _open(() => showConsolidateDialog(context, spendableCount: counts.spendable)),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= Lay.xl
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: split.copyWith(fill: true)),
                  SizedBox(width: Sp.x4),
                  Expanded(child: consolidate.copyWith(fill: true)),
                ],
              ),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [split, SizedBox(height: Sp.x3), consolidate]),
    );
  }

  List<Widget> _list(AsyncValue<List<Output>> value, OutputCounts counts) {
    final l = context.l10n;
    final all = value.value;
    if (all == null) {
      if (value.hasError) {
        return [
          _panel(
            EEmpty(
              icon: EIcons.coins,
              title: l.deskOutNotLoadedTitle,
              text: l.deskOutNotLoadedText,
              actions: [EButton.ghost(label: l.deskOutRefresh, onPressed: _refresh)],
            ),
          ),
        ];
      }
      return [_waiting(l.deskOutLoading)];
    }
    if (all.isEmpty) {
      return [
        _panel(
          EEmpty(
            icon: EIcons.coins,
            title: l.deskOutNoneTitle,
            text: l.deskOutNoneText,
          ),
        ),
      ];
    }
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final o in all)
        if (_matches(o, q)) o,
    ];
    final pages = (shown.length / _pageSize).ceil();
    final page = _page.clamp(0, (pages - 1).clamp(0, 999));
    final slice = shown.skip(page * _pageSize).take(_pageSize).toList();
    final txs = {for (final t in ref.watch(deskProvider).txs ?? const <Tx>[]) t.id: t};
    final tip = ref.watch(deskProvider.select((s) => s.status?.nodeHeight)) ?? 0;
    // One line of Ctl.sm controls on one centre line: the status tabs and Show spent on the
    // left, the commitment search at the right end. Short of room (a narrow window) the
    // search goes under the tabs, at its own width; the tabs shrink before they clip.
    // Each tab counts the rows it lists, so a tab and its tile agree (#69).
    int listed(OutputsFilter f) => all.where((o) => outputListed(f, o.word, showSpent: _showSpent)).length;
    final tabs = ESegmented<OutputsFilter>(
      shrink: true,
      segments: [
        for (final (f, label) in [
          (OutputsFilter.all, l.deskOutFilterAll),
          (OutputsFilter.spendable, l.deskOutFilterSpendable),
          (OutputsFilter.confirming, l.deskOutFilterConfirming),
          (OutputsFilter.locked, l.deskOutFilterLocked),
        ])
          ESegment(f, label, count: listed(f)),
      ],
      value: _filter,
      onChanged: (v) => setState(() {
        _filter = v;
        _page = 0;
      }),
    );
    final showSpent = SizedBox(
      height: Ctl.sm,
      child: Center(
        child: ECheckbox(
          value: _showSpent,
          label: l.deskOutShowSpent,
          onChanged: (v) => setState(() {
            _showSpent = v;
            _page = 0;
          }),
        ),
      ),
    );
    final search = ESearch(
      controller: _query,
      width: double.nan,
      hint: l.deskOutSearchHint,
      label: l.deskOutSearchLabel,
      clearLabel: l.deskOutClearSearch,
      onChanged: (_) => setState(() => _page = 0),
    );
    final picks = Row(
      children: [
        Flexible(child: tabs),
        SizedBox(width: Sp.x5),
        showSpent,
      ],
    );
    final filters = LayoutBuilder(
      builder: (context, box) => box.maxWidth >= Lay.xl
          ? Row(children: [Expanded(child: picks), SizedBox(width: Sp.x5), search])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [picks, SizedBox(height: Sp.x3), search]),
    );
    return [
      filters,
      SizedBox(height: Sp.x3),
      if (shown.isEmpty)
        _panel(
          EEmpty(
            icon: EIcons.search,
            title: l.deskOutNoMatchTitle,
            text: l.deskOutNoMatchText,
            actions: [
              EButton.ghost(
                label: l.deskOutClearFilter,
                onPressed: () => setState(() {
                  _query.clear();
                  _filter = OutputsFilter.all;
                }),
              ),
            ],
          ),
        )
      else
        _panel(
          Semantics(
            label: l.deskOutTitle,
            container: true,
            child: _OutputTable(
              rows: [
                for (final o in slice)
                  _OutputRow(
                    output: o,
                    tip: tip,
                    tx: txs[o.txId],
                    onTx: o.txId == null ? null : () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, o.txId),
                    onRelease: o.heldBy == null ? null : () => _releaseHeld(o),
                  ),
              ],
            ),
          ),
        ),
      ListPager(pages: pages, page: page, onPage: (p) => setState(() => _page = p)),
    ];
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
          children: [const ESpinner(), Text(text, style: context.ts.bodyDim)],
        ),
      ),
    ),
  );

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
}

/// The balance by part, each with its number of outputs; Total on the right. Every tile is
/// always there (a zero one dimmed), so the row never changes with the balance; until the
/// balance and the outputs are read, each count and value is a [Skeleton] of the loaded text.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.balance, required this.counts});

  final Balance? balance;
  final OutputCounts? counts;

  /// What a loading tile lays out under its bars: a count and a value of a usual width.
  static const int _placeholderCount = 88;
  static const int _placeholderNano = 1000 * 100000000;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final b = balance;
    final n = counts;
    final loading = b == null || n == null;
    // Label, then "N outputs", then the value, as the phone's tiles. [hint] puts an
    // explanation behind an info icon after the label (the Locked tile while outputs are locked).
    Widget tile(String label, Widget? mark, int? nano, int? count, {bool total = false, String? hint}) {
      final shownCount = loading ? _placeholderCount : count!;
      final shownNano = loading ? _placeholderNano : nano!;
      return Semantics(
        container: true,
        child: ConstrainedBox(
          // A tile's width does not follow its figures, so the next tile stays put as they load.
          constraints: BoxConstraints(minWidth: 128.u),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?mark,
                  if (mark != null) SizedBox(width: Sp.x2),
                  Text(label, style: ts.small),
                  if (hint != null && !loading) ...[SizedBox(width: Sp.x1), EInfoHint(hint)],
                ],
              ),
              SizedBox(height: Sp.x1),
              Skeleton(
                key: loading ? const ValueKey('outputs-count-loading') : null,
                loading: loading,
                color: c.s3,
                radius: Rad.xs,
                inset: EdgeInsets.symmetric(vertical: 5.u),
                child: SizedBox(
                  height: 24.u,
                  child: Text(l.deskOutCount(shownCount), style: ts.body.copyWith(fontSize: Fs.lg, fontWeight: FontWeight.w600, color: shownCount == 0 ? c.dim : c.text)),
                ),
              ),
              SizedBox(height: 2.u),
              Skeleton(
                loading: loading,
                color: c.s3,
                radius: Rad.xs,
                inset: EdgeInsets.symmetric(vertical: 3.u),
                child: EMoney(shownNano, size: Fs.sm, unit: total, weight: total ? FontWeight.w600 : null, color: shownNano == 0 ? c.faint : c.dim),
              ),
            ],
          ),
        ),
      );
    }

    final icon = Ctl.iconSm;
    return EPanel(
      child: Wrap(
        spacing: 40.u,
        runSpacing: 24.u,
        children: [
          tile(l.deskOutTileSpendable, Icon(EIcons.okCircle, size: icon, color: c.ok), b?.spendable, n?.spendable),
          // Its count takes the outputs awaiting finalization too, so its value does (linux-08),
          // as the phone's: they are in no other figure and not in Total.
          tile(l.deskOutTileConfirming, ERing(confirmations: 1, needed: b?.minConfirmations ?? defaultMinimumConfirmations, size: icon), b == null ? null : b.awaitingConfirmation + b.awaitingFinalization, n?.confirming),
          tile(l.deskOutTileImmature, Icon(EIcons.sand, size: icon, color: c.info), b?.immature, n?.immature),
          tile(l.deskOutTileLocked, Icon(EIcons.lock, size: icon, color: c.dim), b?.locked, n?.locked, hint: (b?.locked ?? 0) > 0 ? l.deskOutLockedNote : null),
          tile(l.deskOutTileTotal, null, b == null ? null : outputsTotalValue(b), n?.total, total: true),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.text, required this.note, required this.button, required this.enabled, required this.onPressed, this.fill = false});

  /// Side by side at one height: the button at the bottom, level with the other card's.
  final bool fill;

  _ActionCard copyWith({bool? fill}) =>
      _ActionCard(icon: icon, title: title, text: text, note: note, button: button, enabled: enabled, onPressed: onPressed, fill: fill ?? this.fill);

  final IconData icon;
  final String title;
  final String text;
  final String note;
  final String button;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return EPanel(
      expand: fill,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EGlyphTile(size: 56.u, icon: icon),
          SizedBox(width: Sp.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                SizedBox(height: Sp.x1),
                Text(text, style: ts.small),
                if (note.isNotEmpty) ...[
                  SizedBox(height: Sp.x1),
                  Semantics(liveRegion: true, child: Text(note, style: ts.caption)),
                ],
                SizedBox(height: 10.u),
                if (fill) const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: enabled ? 1 : 0.6,
                  child: ERowControl(child: EButton(label: button, icon: icon, size: EBtnSize.sm, onPressed: enabled ? onPressed : null)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the defaults for sends went: Settings › Transactions holds the strategy and
/// Split change. One line, shown while Advanced › Send options is on, so nothing is kept twice.
class _DefaultsMoved extends ConsumerWidget {
  const _DefaultsMoved();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!advancedHas(ref, AdvancedFeature.sendOptions)) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4),
      child: Wrap(
        key: const ValueKey('out-defaults-moved'),
        spacing: Sp.x3,
        runSpacing: Sp.x1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l.deskOutDefaultsMoved, style: context.ts.bodyDim),
          EButton(
            label: l.deskOutDefaultsOpen,
            size: EBtnSize.inline,
            onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsReceiving),
          ),
        ],
      ),
    );
  }
}

/// The outputs as a table: every column as wide as its content on the page (the widest
/// value, the longest status), a gap apart, the commitment in the rest; numbers right-aligned,
/// the words left. One grid holds the head and the rows, so nothing sits a few pixels off.
/// Under [Lay.md] of width the rows stack their cells instead, without a head.
class _OutputTable extends StatelessWidget {
  const _OutputTable({required this.rows});

  final List<_OutputRow> rows;

  /// The panel's inset: the first column starts where the summary tiles do.
  static double get inset => Sp.x6;

  /// Half the gap between columns (each cell pads both sides).
  static double get pad => Sp.x3;

  /// The row's height for one line of a status and its note.
  static double get rowHeight => 52.u;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth - 2 * inset;
        if (width < Lay.md) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, r) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                r,
              ],
            ],
          );
        }
        // Confirmations and Height have their own columns in a panel Lay.xl wide; below, the
        // status shows the confirmations.
        final wide = box.maxWidth >= Lay.xl;
        final head = context.ts.caption.copyWith(fontWeight: FontWeight.w600);
        Widget th(String t, {bool right = false}) => Container(
          height: 36.u,
          alignment: right ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Text(t, style: head, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
        Widget td(Widget w, {bool right = false, bool dim = false}) => Container(
          constraints: BoxConstraints(minHeight: rowHeight),
          alignment: right ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: Sp.x2),
          child: dim ? Opacity(opacity: 0.6, child: w) : w,
        );
        final cap = MinColumnWidth(const IntrinsicColumnWidth(), FixedColumnWidth(240.u + 2 * pad));
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset - pad),
          child: Table(
            columnWidths: {
              0: const IntrinsicColumnWidth(),
              1: cap,
              if (wide) ...{2: const IntrinsicColumnWidth(), 3: const IntrinsicColumnWidth()},
              (wide ? 4 : 2): cap,
              (wide ? 5 : 3): const FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(horizontalInside: BorderSide(color: c.line)),
            children: [
              TableRow(
                children: [
                  th(l.deskOutColValue, right: true),
                  th(l.deskOutColStatus),
                  if (wide) ...[th(l.deskOutColConfirmations, right: true), th(l.deskOutColHeight, right: true)],
                  th(l.deskOutColTransaction),
                  th(l.deskOutColCommitment),
                ],
              ),
              for (final r in rows)
                TableRow(
                  children: [
                    for (final (i, cell) in r.cells(context, wide: wide).indexed) td(cell, right: i == 0 || (wide && (i == 2 || i == 3)), dim: r.output.word == OutputWord.spent),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({required this.output, required this.tip, this.tx, this.onTx, this.onRelease});

  final Output output;
  final int tip;
  final Tx? tx;
  final VoidCallback? onTx;

  /// Release by hand, for a coin another device's payment holds.
  final VoidCallback? onRelease;

  (String, String?, Color) _status(AppLocalizations l, DeskColors c) {
    final o = output;
    return switch (o.word) {
      OutputWord.spendable => (l.deskOutStatusSpendable, null, c.ok),
      OutputWord.confirming => (l.deskOutStatusConfirming, l.deskOutConfirmations(o.confirmations, _group(l, o.confirmations)), c.info),
      OutputWord.finalizing => (l.deskOutStatusAwaiting, tx != null && !tx!.incoming ? l.deskOutNoteWaitingRecipient : l.deskOutNoteWaitingSender, c.dim),
      OutputWord.unpaidInvoice => (l.deskOutStatusUnpaid, l.deskOutNoteNotInBalance, c.dim),
      OutputWord.immature => (l.deskOutStatusImmature, o.lockHeight != null && o.lockHeight! > tip ? l.deskOutNoteBlocksToGo(o.lockHeight! - tip, _group(l, o.lockHeight! - tip)) : null, c.info),
      OutputWord.mining => (l.deskOutStatusMining, null, c.info),
      OutputWord.locked => (l.deskOutStatusLocked, o.heldBy != null ? l.devicesHeldBy(o.heldBy!) : (o.txId == null ? null : l.deskOutNoteBySend(o.txId!)), c.dim),
      OutputWord.spent => (l.deskOutStatusSpent, null, c.faint),
    };
  }

  String _txText(AppLocalizations l, Tx t) {
    final date = shortDayMonth(l, t.created);
    return t.incoming ? l.deskOutTxReceived(date) : l.deskOutTxSent(date);
  }

  _Cells _build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final o = output;
    final spent = o.word == OutputWord.spent;
    final (word, note, color) = _status(l, c);
    final mark = switch (o.word) {
      OutputWord.spendable => Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok),
      OutputWord.confirming => ERing(confirmations: o.confirmations, needed: o.confirmationsNeeded, size: 18.u),
      OutputWord.finalizing => ERing(confirmations: 0, size: 18.u),
      OutputWord.unpaidInvoice => Icon(EIcons.invoice, size: Ctl.iconSm, color: c.dim),
      OutputWord.immature || OutputWord.mining => Icon(EIcons.sand, size: Ctl.iconSm, color: c.info),
      OutputWord.locked => Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim),
      OutputWord.spent => Icon(EIcons.minusCircle, size: Ctl.iconSm, color: c.faint),
    };
    Widget status({String? extra}) {
      final detail = note ?? extra;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18.u, height: 18.u, child: Center(child: mark)),
          SizedBox(width: Sp.x2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.small.copyWith(color: color)),
                if (detail != null)
                  Text(
                    detail,
                    // A coin another device holds names the payment: two lines.
                    maxLines: o.heldBy != null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.caption.copyWith(color: c.faint),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    final commitment = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: EShortAddress(o.commitment, style: ts.mono(size: Fs.xs, color: spent ? c.faint : c.dim))),
        SizedBox(width: Sp.x1),
        ECopyButton(text: o.commitment, label: l.deskOutCopyCommitment(shortCommitment(o.commitment))),
      ],
    );
    final value = EMoney(o.value, unit: false, color: spent ? c.faint : c.text);
    final t = tx;
    final txCell = onRelease != null
        ? ELink(key: ValueKey('out-release-${o.commitment}'), label: l.devicesRelease, onPressed: onRelease)
        : t == null
        ? Text('–', style: ts.small.copyWith(color: c.faint)) // l10n-ok: no payment known
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The direction, as in Activity: green in, red out.
              Icon(iconOf(t), size: Ctl.iconSm, color: t.incoming ? c.txReceived : c.txSent),
              SizedBox(width: Sp.x1),
              Flexible(child: ELink(label: _txText(l, t), onPressed: onTx)),
            ],
          );
    final conf = o.word == OutputWord.spendable ? l.deskOutConfirmations(o.confirmations, _group(l, o.confirmations)) : null;
    final number = ts.mono(size: Fs.xs, color: c.dim);
    return _Cells(
      value: value,
      status: status,
      conf: conf,
      confirmations: Text(_group(l, o.confirmations), style: number),
      height: Text((o.height ?? 0) == 0 ? '–' : _group(l, o.height!), style: number.copyWith(color: c.faint)),
      tx: txCell,
      commitment: commitment,
    );
  }

  /// The row's cells in the table's column order: value, status, (confirmations, height
  /// when [wide]), transaction, commitment.
  List<Widget> cells(BuildContext context, {required bool wide}) {
    final x = _build(context);
    return [x.value, x.status(extra: wide ? null : x.conf), if (wide) ...[x.confirmations, x.height], x.tx, x.commitment];
  }

  /// Under [Lay.md]: the status and value on one line, the commitment and transaction under.
  @override
  Widget build(BuildContext context) {
    final x = _build(context);
    return Opacity(
      opacity: output.word == OutputWord.spent ? 0.6 : 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _OutputTable.inset, vertical: Sp.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: x.status(extra: x.conf)), SizedBox(width: Sp.x3), x.value]),
            SizedBox(height: Sp.x1),
            Row(children: [Expanded(child: x.commitment), SizedBox(width: Sp.x3), x.tx]),
          ],
        ),
      ),
    );
  }
}

/// One output's cells, built once for either layout.
class _Cells {
  const _Cells({required this.value, required this.status, required this.conf, required this.confirmations, required this.height, required this.tx, required this.commitment});

  final Widget value;
  final Widget Function({String? extra}) status;

  /// "N confirmations" for a spendable output, the status's note where there is no column.
  final String? conf;
  final Widget confirmations;
  final Widget height;
  final Widget tx;
  final Widget commitment;
}
