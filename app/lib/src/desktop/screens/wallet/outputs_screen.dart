import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'activity_screen.dart' show ListPager;
import 'outputs_dialogs.dart';

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

String _group(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _outputs(int n) => n == 1 ? '1 output' : '$n outputs';

/// How many outputs of each part of the balance: spendable; confirming and awaiting
/// finalization; immature and mining; locked.
({int spendable, int confirming, int immature, int locked}) outputCounts(List<Output> all) {
  var s = 0, c = 0, i = 0, l = 0;
  for (final o in all) {
    switch (o.word) {
      case OutputWord.spendable:
        s++;
      case OutputWord.confirming || OutputWord.finalizing:
        c++;
      case OutputWord.immature || OutputWord.mining:
        i++;
      case OutputWord.locked:
        l++;
      case OutputWord.spent:
        break;
    }
  }
  return (spendable: s, confirming: c, immature: i, locked: l);
}

/// Outputs (F13): the pieces the balance is made of, Split and Consolidate, the defaults
/// Send uses (strategy, Split change), and every output with its status and transaction.
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

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(deskProvider.notifier).syncNow();
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not updated', text: deskErrorText(e), tone: ETone.risk);
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

  bool _matches(Output o, String q) {
    final w = o.word;
    if (w == OutputWord.spent && !_showSpent) return false;
    final kept = switch (_filter) {
      OutputsFilter.all => true,
      OutputsFilter.spendable => w == OutputWord.spendable,
      OutputsFilter.confirming => w == OutputWord.confirming || w == OutputWord.finalizing,
      OutputsFilter.locked => w == OutputWord.locked,
    };
    return kept && (q.isEmpty || o.commitment.contains(q));
  }

  @override
  Widget build(BuildContext context) {
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
      title: 'Outputs',
      width: EPageWidth.full,
      actions: [
        EIconButton(
          icon: hidden ? EIcons.eyeOff : EIcons.eye,
          label: hidden ? 'Show amounts' : 'Hide amounts',
          selected: hidden,
          onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
        ),
        _refreshing
            ? SizedBox.square(dimension: Ctl.sm, child: const Center(child: ESpinner()))
            : EIconButton(icon: EIcons.refresh, label: 'Refresh', onPressed: _refresh),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (balance != null) ...[
            _Tiles(balance: balance, counts: all == null ? null : counts),
            if (balance.locked > 0) ...[
              SizedBox(height: Sp.x2),
              Text(
                'Locked outputs are being spent by a transaction in progress. Their change shows as awaiting finalization and is not in Total until the send is finalized, so Total counts the coins once.',
                style: context.ts.caption,
              ),
            ],
            SizedBox(height: Sp.x4),
          ],
          Text(
            'Outputs are the pieces the balance is made of. A send spends whole outputs, pays the recipient and returns the rest as a new output; the spent ones are locked until the send confirms.',
            style: context.ts.bodyDim,
          ),
          SizedBox(height: Sp.x4),
          _cards(balance, counts, loaded: all != null),
          SizedBox(height: Sp.x4),
          const _DefaultsBox(),
          SizedBox(height: Sp.x6),
          ..._list(value, counts),
        ],
      ),
    );
  }

  Widget _cards(Balance? b, ({int spendable, int confirming, int immature, int locked}) counts, {required bool loaded}) {
    final locked = (b?.locked ?? 0) > 0 || counts.locked > 0;
    final wait = 'Wait until the send confirms (about 3 blocks).';
    final splitOn = loaded && !locked && counts.spendable >= 1 && _split != null;
    final splitNote = !loaded
        ? ''
        : locked
        ? wait
        : counts.spendable == 0
        ? 'Nothing to split yet.'
        : _split == null
        ? 'Spends ${_outputs(counts.spendable)}.'
        : 'Spends ${_outputs(counts.spendable)}. Fee from ${formatEpic(_split!.fee, minDecimals: 3)} EPIC.';
    final consOn = loaded && !locked && counts.spendable >= 2;
    final consNote = !loaded
        ? ''
        : locked
        ? wait
        : counts.spendable == 0
        ? 'Nothing to consolidate yet.'
        : counts.spendable == 1
        ? 'Nothing to consolidate: one spendable output.'
        : _consolidate == null
        ? '${counts.spendable} outputs into 1.'
        : '${counts.spendable} outputs into 1. Fee ${formatEpic(_consolidate!.fee, minDecimals: 3)} EPIC.';
    final split = _ActionCard(
      icon: EIcons.split,
      title: 'Split',
      text: 'Makes more outputs from the spendable balance, so several sends can follow each other without waiting.',
      note: splitNote,
      button: 'Split…',
      enabled: splitOn,
      onPressed: () => _open(() => showSplitDialog(context)),
    );
    final consolidate = _ActionCard(
      icon: EIcons.merge,
      title: 'Consolidate',
      text: 'Merges every spendable output into one. Smaller fees on the next send; everything is locked until it confirms.',
      note: consNote,
      button: 'Consolidate…',
      enabled: consOn,
      onPressed: () => _open(() => showConsolidateDialog(context, spendableCount: counts.spendable)),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 860.u
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: split),
                  SizedBox(width: Sp.x4),
                  Expanded(child: consolidate),
                ],
              ),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [split, SizedBox(height: Sp.x3), consolidate]),
    );
  }

  List<Widget> _list(AsyncValue<List<Output>> value, ({int spendable, int confirming, int immature, int locked}) counts) {
    final c = context.dc;
    final all = value.value;
    if (all == null) {
      if (value.hasError) {
        return [
          _panel(
            EEmpty(
              icon: EIcons.coins,
              title: 'Outputs not loaded',
              text: 'Refresh to try again.',
              actions: [EButton.ghost(label: 'Refresh', onPressed: _refresh)],
            ),
          ),
        ];
      }
      return [_waiting('Loading wallet data')];
    }
    if (all.isEmpty) {
      return [
        _panel(
          const EEmpty(
            icon: EIcons.coins,
            title: 'No outputs yet',
            text: 'The first payment received makes one. Split and Consolidate need something to work with.',
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
    final filters = Wrap(
      spacing: Sp.x4,
      runSpacing: Sp.x3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ESegmented<OutputsFilter>(
          segments: [
            ESegment(OutputsFilter.all, 'All', count: all.where((o) => _showSpent || o.word != OutputWord.spent).length),
            ESegment(OutputsFilter.spendable, 'Spendable', count: counts.spendable),
            ESegment(OutputsFilter.confirming, 'Confirming', count: all.where((o) => o.word == OutputWord.confirming || o.word == OutputWord.finalizing).length),
            ESegment(OutputsFilter.locked, 'Locked', count: counts.locked),
          ],
          value: _filter,
          onChanged: (v) => setState(() {
            _filter = v;
            _page = 0;
          }),
        ),
        SizedBox(
          width: 240.u,
          child: EInput(
            controller: _query,
            hint: 'Commitment',
            leading: EIcons.search,
            semanticLabel: 'Search outputs',
            onChanged: (_) => setState(() => _page = 0),
            trailing: _query.text.isEmpty ? null : EIconButton(icon: EIcons.close, label: 'Clear search', size: EBtnSize.inline, onPressed: () => setState(_query.clear)),
          ),
        ),
        ECheckbox(
          value: _showSpent,
          label: 'Show spent',
          onChanged: (v) => setState(() {
            _showSpent = v;
            _page = 0;
          }),
        ),
      ],
    );
    return [
      filters,
      SizedBox(height: Sp.x3),
      if (shown.isEmpty)
        _panel(
          EEmpty(
            icon: EIcons.search,
            title: 'No outputs match',
            text: 'Try another commitment, or clear the filter.',
            actions: [
              EButton.ghost(
                label: 'Clear filter',
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
            label: 'Outputs',
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _OutputHead(),
                for (final (i, o) in slice.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  _OutputRow(
                    output: o,
                    tip: tip,
                    tx: txs[o.txId],
                    onTx: o.txId == null ? null : () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, o.txId),
                  ),
                ],
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

/// The balance by part, each with its number of outputs; Total on the right.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.balance, required this.counts});

  final Balance balance;
  final ({int spendable, int confirming, int immature, int locked})? counts;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    Widget tile(String label, Widget? mark, int nano, int? n, {bool total = false}) => Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [?mark, if (mark != null) SizedBox(width: Sp.x2), Text(label, style: ts.small)],
          ),
          SizedBox(height: Sp.x1),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              EMoney(nano, size: Fs.lg, unit: total, weight: total ? FontWeight.w600 : null, color: nano == 0 ? c.faint : c.text),
              if (n != null) ...[SizedBox(width: Sp.x2), Text(_outputs(n), style: ts.caption)],
            ],
          ),
        ],
      ),
    );
    final icon = Ctl.iconSm;
    final b = balance;
    final n = counts;
    return EPanel(
      child: Wrap(
        spacing: 40.u,
        runSpacing: 24.u,
        children: [
          tile('Spendable', Icon(EIcons.okCircle, size: icon, color: c.ok), b.spendable, n?.spendable),
          tile('Confirming', ERing(confirmations: 1, size: icon), b.awaitingConfirmation, n?.confirming),
          if (b.immature > 0) tile('Immature', Icon(EIcons.sand, size: icon, color: c.warn), b.immature, n?.immature),
          tile('Locked in sends', Icon(EIcons.lock, size: icon, color: c.dim), b.locked, n?.locked),
          tile('Total', null, b.total, null, total: true),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.text, required this.note, required this.button, required this.enabled, required this.onPressed});

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
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: enabled ? 1 : 0.6,
                  child: EButton(label: button, icon: icon, size: EBtnSize.sm, onPressed: enabled ? onPressed : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const String _strategyHelp = 'Smallest spends the fewest small outputs and leaves the rest spendable. All spends everything and returns one output.';

/// The defaults Send uses: strategy and Split change (D-5), saved per wallet at once.
class _DefaultsBox extends ConsumerWidget {
  const _DefaultsBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(deskOutputPrefsProvider).value ?? const OutputPrefs();
    final save = ref.read(deskOutputPrefsProvider.notifier).save;
    return EPanel(
      title: 'Defaults for sends',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetRow(
            title: 'Strategy for sends',
            text: 'Which outputs a send spends. Send can change it for one send under Advanced.',
            control: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ESegmented<SelectionStrategy>(
                  segments: const [ESegment(SelectionStrategy.smallest, 'Smallest'), ESegment(SelectionStrategy.all, 'All')],
                  value: prefs.strategy,
                  onChanged: (v) => save(OutputPrefs(strategy: v, smartOutputs: prefs.smartOutputs)),
                ),
                SizedBox(width: Sp.x1),
                EIconButton(
                  icon: EIcons.help,
                  label: _strategyHelp,
                  tabStop: false,
                  onPressed: () => showEToast(context, 'Smallest or All', text: _strategyHelp, tone: ETone.neutral),
                ),
              ],
            ),
          ),
          ESetRow(
            title: 'Split change',
            text: 'When a send would leave fewer than 3 spendable outputs, its change comes back as up to 4 outputs. Costs 0.004 EPIC per extra output.',
            control: ESwitch(
              value: prefs.smartOutputs,
              semanticLabel: 'Split change',
              onChanged: (v) => save(OutputPrefs(strategy: prefs.strategy, smartOutputs: v)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Column widths of the wide list.
const double _wide = 900;

class _OutputHead extends StatelessWidget {
  const _OutputHead();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final style = context.ts.caption.copyWith(fontWeight: FontWeight.w600);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= _wide.u;
        if (box.maxWidth < 600.u) return const SizedBox.shrink();
        Widget col(double w, String t, {bool right = false}) => SizedBox(
          width: w,
          child: Text(t, style: style, textAlign: right ? TextAlign.right : TextAlign.left),
        );
        return Container(
          height: 36.u,
          padding: EdgeInsets.symmetric(horizontal: Sp.x5),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              col(150.u, 'Value', right: true),
              SizedBox(width: Sp.x5),
              col(200.u, 'Status'),
              if (wide) ...[col(104.u, 'Confirmations', right: true), SizedBox(width: Sp.x5), col(88.u, 'Height')],
              col(140.u, 'Transaction'),
              Expanded(child: Text('Commitment', style: style)),
            ],
          ),
        );
      },
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({required this.output, required this.tip, this.tx, this.onTx});

  final Output output;
  final int tip;
  final Tx? tx;
  final VoidCallback? onTx;

  (String, String?, Color) _status(DeskColors c) {
    final o = output;
    return switch (o.word) {
      OutputWord.spendable => ('Spendable', null, c.ok),
      OutputWord.confirming => ('Confirming', '${o.confirmations} / ${o.confirmationsNeeded}', c.warn),
      OutputWord.finalizing => ('Awaiting finalization', 'waiting for the sender', c.dim),
      OutputWord.immature => ('Immature', o.lockHeight != null && o.lockHeight! > tip ? '${_group(o.lockHeight! - tip)} blocks to go' : null, c.warn),
      OutputWord.mining => ('Mining', null, c.warn),
      OutputWord.locked => ('Locked', o.txId == null ? null : 'by send #${o.txId}', c.dim),
      OutputWord.spent => ('Spent', null, c.faint),
    };
  }

  String _txText(Tx t) {
    final d = t.created;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.incoming ? 'Received' : 'Sent'} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final o = output;
    final spent = o.word == OutputWord.spent;
    final (word, note, color) = _status(c);
    final mark = switch (o.word) {
      OutputWord.spendable => Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok),
      OutputWord.confirming => ERing(confirmations: o.confirmations, needed: o.confirmationsNeeded, size: 18.u),
      OutputWord.finalizing => ERing(confirmations: 0, size: 18.u),
      OutputWord.immature || OutputWord.mining => Icon(EIcons.sand, size: Ctl.iconSm, color: c.warn),
      OutputWord.locked => Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim),
      OutputWord.spent => Icon(EIcons.minusCircle, size: Ctl.iconSm, color: c.faint),
    };
    Widget status({String? extra}) => Row(
      children: [
        SizedBox(width: 18.u, height: 18.u, child: Center(child: mark)),
        SizedBox(width: Sp.x2),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: word, style: TextStyle(color: color)),
                if ((note ?? extra) != null) TextSpan(text: ' · ${note ?? extra}', style: TextStyle(color: c.faint)),
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
            child: Text(shortCommitment(o.commitment), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.mono(size: Fs.xs, color: spent ? c.faint : c.dim)),
          ),
        ),
        ECopyButton(text: o.commitment, label: 'Copy commitment ${shortCommitment(o.commitment)}'),
      ],
    );
    final value = Align(
      alignment: Alignment.centerRight,
      child: EMoney(o.value, unit: false, color: spent ? c.faint : c.text),
    );
    final t = tx;
    final txCell = t == null
        ? Text(o.txId == null ? '–' : '#${o.txId}', style: ts.small.copyWith(color: c.faint))
        : Align(alignment: Alignment.centerLeft, child: ELink(label: _txText(t), onPressed: onTx));
    final conf = o.word == OutputWord.spendable ? '${_group(o.confirmations)} confirmations' : null;
    return Opacity(
      opacity: spent ? 0.6 : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48.u),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x2),
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= 560.u) {
                final wide = box.maxWidth >= _wide.u - 2 * Sp.x5;
                return Row(
                  children: [
                    SizedBox(width: 150.u, child: value),
                    SizedBox(width: Sp.x5),
                    SizedBox(width: 200.u, child: status(extra: wide ? null : conf)),
                    if (wide) ...[
                      SizedBox(
                        width: 104.u,
                        child: Text(_group(o.confirmations), textAlign: TextAlign.right, style: ts.mono(size: Fs.xs, color: c.dim)),
                      ),
                      SizedBox(width: Sp.x5),
                      SizedBox(
                        width: 88.u,
                        child: Text((o.height ?? 0) == 0 ? '–' : _group(o.height!), style: ts.mono(size: Fs.xs, color: c.faint)),
                      ),
                    ],
                    SizedBox(width: 140.u, child: txCell),
                    Expanded(child: commitment),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: status(extra: conf)),
                      SizedBox(width: Sp.x3),
                      value,
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: commitment),
                      SizedBox(width: Sp.x3),
                      txCell,
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
