/// Outputs: the pieces the balance is made of, with Split and Consolidate, the strategy a
/// send uses and the list of every output (design spec: phone §4, desktop outputs §5, §6).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../smart_outputs.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'pin.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

/// Which outputs the list shows. [immature] has no segment of its own: Home's tile opens it.
enum OutputsFilter { all, spendable, confirming, locked, immature }

/// Mining rewards and the like need more than this to unlock; the sheet words it plainly.
const int _minSplitEach = nanoEpic ~/ 2;

bool _matches(OutputsFilter f, OutputLabel w) => switch (f) {
  OutputsFilter.all => w != OutputLabel.spent,
  OutputsFilter.spendable => w == OutputLabel.spendable,
  OutputsFilter.confirming =>
    w == OutputLabel.confirming || w == OutputLabel.finalizing,
  OutputsFilter.locked => w == OutputLabel.locked,
  OutputsFilter.immature =>
    w == OutputLabel.immature || w == OutputLabel.mining,
};

String _wordText(AppLocalizations l, OutputLabel w) => switch (w) {
  OutputLabel.spendable => l.outputsWordSpendable,
  OutputLabel.confirming => l.outputsWordConfirming,
  OutputLabel.finalizing => l.outputsWordFinalizing,
  OutputLabel.immature => l.outputsWordImmature,
  OutputLabel.mining => l.outputsWordMining,
  OutputLabel.locked => l.outputsWordLocked,
  OutputLabel.spent => l.outputsWordSpent,
};

String _meaning(AppLocalizations l, OutputLabel w, int need) => switch (w) {
  OutputLabel.spendable => l.outputsMeanSpendable,
  OutputLabel.confirming => l.outputsMeanConfirming(need),
  OutputLabel.finalizing => l.outputsMeanFinalizing,
  OutputLabel.immature => l.outputsMeanImmature,
  OutputLabel.mining => l.outputsMeanMining,
  OutputLabel.locked => l.outputsMeanLocked,
  OutputLabel.spent => l.outputsMeanSpent,
};

({IconData icon, Color color}) _mark(WalletTokens t, OutputLabel w) =>
    switch (w) {
      OutputLabel.spendable => (icon: Icons.check, color: t.ok),
      OutputLabel.confirming => (icon: Icons.timelapse, color: t.accent),
      OutputLabel.locked => (icon: Icons.hourglass_top, color: t.warn),
      OutputLabel.finalizing => (icon: Icons.hourglass_empty, color: t.dim),
      OutputLabel.immature ||
      OutputLabel.mining ||
      OutputLabel.spent => (icon: Icons.circle_outlined, color: t.dim),
    };

String _strategyName(AppLocalizations l, SelectionStrategy s) =>
    s == SelectionStrategy.smallest ? l.outputsSmallest : l.outputsAll;

/// The state line of a row: the word, then what it needs to say (confirmations, when it came,
/// which send holds it).
String _rowText(
  AppLocalizations l,
  WalletOutput o,
  TxEntry? tx,
  DateTime now,
  int need, {
  String? who,
}) {
  final word = _wordText(l, outputWord(o));
  final when = tx == null
      ? null
      : shortDate(
          l,
          DateTime.fromMillisecondsSinceEpoch(tx.timeUnix * 1000),
          now,
        );
  final received = tx != null && tx.kind != TxKind.sent && when != null
      ? l.outputsNoteReceived(when)
      : null;
  final note = switch (outputWord(o)) {
    OutputLabel.confirming => [
      l.outputsNoteConfirmations(o.confirmations.toInt(), need),
      ?received,
    ].join(' · '),
    OutputLabel.locked =>
      tx?.counterparty == null
          ? l.outputsNoteSendPlain
          : l.outputsNoteSend(who ?? shortAddress(tx!.counterparty!)),
    OutputLabel.spendable => received,
    _ => null,
  };
  return note == null || note.isEmpty ? word : l.outputsRow(word, note);
}

class OutputsScreen extends ConsumerStatefulWidget {
  const OutputsScreen({super.key, this.filter});

  /// The segment the list starts on; null shows everything not spent.
  final OutputsFilter? filter;

  @override
  ConsumerState<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends ConsumerState<OutputsScreen> {
  late OutputsFilter _filter = widget.filter ?? OutputsFilter.all;
  bool _showSpent = false;

  void _reload() {
    ref.invalidate(walletOutputsProvider);
    ref.invalidate(homeProvider);
  }

  Future<void> _pickStrategy() async {
    final l = context.l10n;
    final notifier = ref.read(appSettingsProvider.notifier);
    final current =
        ref.read(appSettingsProvider).value?.sendStrategy ??
        SelectionStrategy.smallest;
    final picked = await showModalBottomSheet<SelectionStrategy>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in SelectionStrategy.values)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: s == current,
                child: ListTile(
                  minVerticalPadding: 12,
                  leading: Icon(
                    s == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: s == current
                        ? context.tokens.accent
                        : context.tokens.dim,
                  ),
                  title: Text(_strategyName(l, s)),
                  subtitle: Text(
                    s == SelectionStrategy.smallest
                        ? l.outputsSmallestText
                        : l.outputsAllText,
                  ),
                  onTap: () => Navigator.pop(context, s),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await notifier.setSendStrategy(picked);
  }

  void _openSheet(WalletOutput o, TxEntry? tx) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OutputSheet(output: o, tx: tx),
    );
  }

  Future<void> _openAction(Widget sheet) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider).value;
    final hidden = settings?.hideBalances ?? false;
    final strategy = settings?.sendStrategy ?? SelectionStrategy.smallest;
    final home = ref.watch(homeProvider).value;
    final summary = home?.summary;
    final outputs = ref.watch(walletOutputsProvider);
    final list = outputs.value;
    final need = ref.watch(countedConfirmationsProvider).toInt();
    final txs = {
      for (final x in home?.transactions ?? const <TxEntry>[])
        if (x.id != null) x.id!: x,
    };
    int count(bool Function(OutputLabel) test) =>
        list?.where((o) => test(outputWord(o))).length ?? 0;
    final nSpendable = count((w) => w == OutputLabel.spendable);
    final nConfirming = count(
      (w) => w == OutputLabel.confirming || w == OutputLabel.finalizing,
    );
    final nLocked = count((w) => w == OutputLabel.locked);
    final nImmature = count(
      (w) => w == OutputLabel.immature || w == OutputLabel.mining,
    );
    final nSpent = count((w) => w == OutputLabel.spent);
    final nAll = list == null ? 0 : list.length - nSpent;
    final locked = summary?.locked ?? BigInt.zero;
    final spendable = summary?.spendable ?? BigInt.zero;
    final canSplit =
        list != null &&
        summary != null &&
        locked == BigInt.zero &&
        spendable >= BigInt.from(nanoEpic);
    final canConsolidate =
        list != null &&
        summary != null &&
        locked == BigInt.zero &&
        nSpendable >= 2;
    final reason = list == null || summary == null
        ? null
        : locked > BigInt.zero
        ? l.outputsWaitLocked
        : [
            if (!canSplit) l.outputsSplitNeeds,
            if (!canConsolidate) l.outputsConsolidateNeeds,
          ].join(' ');

    String money(BigInt v) => shownEpic(l, v, hidden: hidden);
    Widget tile(String label, BigInt? value, int? n) => _Tile(
      label: label,
      value: value == null ? null : money(value),
      caption: n == null ? null : l.outputsCount(n),
    );

    final shown = [
      for (final o in list ?? const <WalletOutput>[])
        if (_showSpent && outputWord(o) == OutputLabel.spent ||
            _matches(_filter, outputWord(o)))
          o,
    ];
    final now = DateTime.now();

    return SlotScaffold(
      appBar: AppBar(title: Text(l.outputsTitle)),
      body: ScreenBody(
        children: [
          Row(
            children: [
              Expanded(
                child: tile(
                  l.outputsSpendable,
                  summary?.spendable,
                  list == null ? null : nSpendable,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: tile(
                  l.outputsConfirming,
                  summary == null
                      ? null
                      : summary.awaitingConfirmation +
                            summary.awaitingFinalization,
                  list == null ? null : nConfirming,
                ),
              ),
            ],
          ),
          if (locked > BigInt.zero) ...[
            const SizedBox(height: 12),
            tile(l.outputsLockedTile, locked, list == null ? null : nLocked),
          ],
          if (summary != null && summary.immature > BigInt.zero) ...[
            const SizedBox(height: 12),
            tile(
              l.outputsImmature,
              summary.immature,
              list == null ? null : nImmature,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l.outputsExplainer,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.call_split),
                  label: Text(l.outputsSplitButton),
                  onPressed: canSplit
                      ? () => _openAction(
                          _SplitSheet(spendableOutputs: nSpendable),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.merge),
                  label: Text(l.outputsConsolidateButton),
                  onPressed: canConsolidate
                      ? () => _openAction(
                          _ConsolidateSheet(spendableOutputs: nSpendable),
                        )
                      : null,
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                reason,
                style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
              ),
            ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.outputsStrategy),
            subtitle: Text(_strategyName(l, strategy)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickStrategy,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.outputsSplitChange),
            subtitle: Text(l.outputsSplitChangeText),
            value: settings?.splitChange ?? true,
            onChanged: settings == null
                ? null
                : (v) =>
                      ref.read(appSettingsProvider.notifier).setSplitChange(v),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OutputsFilter>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, 44),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              textStyle: theme.textTheme.bodySmall,
            ),
            segments: [
              ButtonSegment(
                value: OutputsFilter.all,
                label: _fit(l.outputsFilterAll(nAll)),
              ),
              ButtonSegment(
                value: OutputsFilter.spendable,
                label: _fit(l.outputsFilterSpendable(nSpendable)),
              ),
              ButtonSegment(
                value: OutputsFilter.confirming,
                label: _fit(l.outputsFilterConfirming(nConfirming)),
              ),
              if (nLocked > 0 || _filter == OutputsFilter.locked)
                ButtonSegment(
                  value: OutputsFilter.locked,
                  label: _fit(l.outputsFilterLocked(nLocked)),
                ),
            ],
            selected: {if (_filter != OutputsFilter.immature) _filter},
            onSelectionChanged: (s) => setState(
              () => _filter = s.isEmpty ? OutputsFilter.all : s.first,
            ),
          ),
          if (nSpent > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => setState(() => _showSpent = !_showSpent),
                child: Text(
                  _showSpent ? l.outputsHideSpent : l.outputsShowSpent,
                ),
              ),
            ),
          const SizedBox(height: 4),
          if (outputs.hasError && list == null)
            Column(
              children: [
                ErrorText(describeError(l, outputs.error!)),
                OutlinedButton(onPressed: _reload, child: Text(l.outputsRetry)),
              ],
            )
          else if (list == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (list.isEmpty)
            EmptyState(
              icon: const Icon(Icons.grain),
              message: '${l.outputsEmpty}\n${l.outputsEmptyHint}',
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l.outputsNoMatch,
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                ),
              ),
            )
          else
            for (final o in shown)
              _OutputRow(
                output: o,
                value: money(o.value),
                text: _rowText(
                  l,
                  o,
                  txs[o.txId],
                  now,
                  need,
                  // The contact's name, else the short address without the own server.
                  who: contactName(ref, txs[o.txId]?.counterparty) ??
                      (txs[o.txId]?.counterparty == null
                          ? null
                          : shortAddress(
                              txs[o.txId]!.counterparty!,
                              ownServer: ownEpicboxServer(ref),
                            )),
                ),
                onTap: () => _openSheet(o, txs[o.txId]),
              ),
        ],
      ),
    );
  }
}

/// A balance tile: label, value in mono, caption. [value] null shows a spinner.
/// A segment's label: one line, shrunk to the segment instead of cut.
Widget _fit(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text));

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.caption});

  final String label;
  final String? value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          const SizedBox(height: 4),
          SizedBox(
            height: 24,
            child: value == null
                ? const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value!,
                      style: TextStyle(
                        fontFamily: t.monoFamily,
                        fontSize: 18,
                        color: t.text,
                      ),
                    ),
                  ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
        ],
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({
    required this.output,
    required this.value,
    required this.text,
    required this.onTap,
  });

  final WalletOutput output;
  final String value;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final mark = _mark(t, outputWord(output));
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: mark.color),
              ),
              child: ExcludeSemantics(
                child: Icon(mark.icon, size: 18, color: mark.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: t.monoFamily,
                      fontSize: 15,
                      color: t.text,
                    ),
                  ),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.dim),
          ],
        ),
      ),
    );
  }
}

/// One output: value, what its state means, height, confirmations, the transaction and the
/// full commitment to copy.
class _OutputSheet extends ConsumerWidget {
  const _OutputSheet({required this.output, required this.tx});

  final WalletOutput output;
  final TxEntry? tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final word = outputWord(output);
    final mark = _mark(t, word);
    final hidden = ref.watch(appSettingsProvider).value?.hideBalances ?? false;
    final need = ref.watch(countedConfirmationsProvider).toInt();
    Widget fact(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
            ),
          ),
          value,
        ],
      ),
    );
    TextStyle mono() => TextStyle(fontFamily: t.monoFamily, color: t.text);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shownEpic(l, output.value, hidden: hidden, exact: true),
              style: mono().copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(mark.icon, size: 18, color: mark.color),
                const SizedBox(width: 8),
                Text(
                  _wordText(l, word),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: mark.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _meaning(l, word, need),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
            ),
            const SizedBox(height: 12),
            fact(
              l.outputsFactHeight,
              Text(
                output.height == BigInt.zero ? '–' : '${output.height}',
                style: mono(),
              ),
            ),
            fact(
              l.outputsFactConfirmations,
              Text('${output.confirmations}', style: mono()),
            ),
            if (tx != null)
              fact(
                l.outputsFactTransaction,
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TxDetailsScreen(txKey: tx!.key),
                      ),
                    );
                  },
                  child: Text('#${tx!.id}'),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l.outputsFactCommitment,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.field,
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: SelectableText(
                output.commitment,
                style: mono().copyWith(fontSize: 12),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l.outputsCopy),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: output.commitment),
                  );
                  if (!context.mounted) return;
                  ref
                      .read(noticeProvider.notifier)
                      .show(l.outputsCopied, level: NoticeLevel.success);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What both action sheets share: the estimate for the count asked, the PIN gate and the
/// post. Subclasses say which wallet call they make.
mixin _SelfSend<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  FeeEstimate? estimate;
  Object? estimateError;
  bool estimating = true;
  bool posting = false;
  Object? postError;
  int _token = 0;

  Future<FeeEstimate> runEstimate(WalletSession s, BigInt conf);

  Future<void> estimateNow() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final token = ++_token;
    setState(() => estimating = true);
    try {
      final e = await runEstimate(
        session,
        ref.read(countedConfirmationsProvider),
      );
      if (!mounted || token != _token) return;
      setState(() {
        estimate = e;
        estimateError = null;
        estimating = false;
      });
    } catch (error) {
      if (!mounted || token != _token) return;
      setState(() {
        estimate = null;
        estimateError = error;
        estimating = false;
      });
    }
  }

  /// Asks for the PIN, then runs [post]; true once it posted.
  Future<bool> gate(
    String reason,
    Future<void> Function(WalletSession s, BigInt conf) post,
  ) async {
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return false;
    final vault = ref.read(vaultProvider);
    final ok = await askPin(
      context,
      reason: reason,
      action: (pin) async {
        await vault.checkPin(session, config, pin);
        return true;
      },
    );
    if (ok != true || !mounted) return false;
    setState(() {
      posting = true;
      postError = null;
    });
    try {
      await post(session, ref.read(countedConfirmationsProvider));
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          posting = false;
          postError = error;
        });
      }
      return false;
    }
  }
}

Widget _fact(BuildContext context, String label, Widget value) {
  final t = context.tokens;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: t.dim),
          ),
        ),
        value,
      ],
    ),
  );
}

Widget _monoText(BuildContext context, String text, {bool dim = false}) {
  final t = context.tokens;
  return Text(
    text,
    style: TextStyle(fontFamily: t.monoFamily, color: dim ? t.dim : t.text),
  );
}

Widget _sheetFrame(BuildContext context, String title, List<Widget> children) {
  return SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet({required this.spendableOutputs});

  final int spendableOutputs;

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet>
    with _SelfSend<_SplitSheet> {
  int _count = 4;

  @override
  void initState() {
    super.initState();
    estimateNow();
  }

  @override
  Future<FeeEstimate> runEstimate(WalletSession s, BigInt conf) =>
      s.estimateSplit(outputs: _count, minimumConfirmations: conf);

  void _step(int by) {
    final next = (_count + by).clamp(minSplitOutputs, maxSplitOutputs);
    if (next == _count) return;
    setState(() => _count = next);
    estimateNow();
  }

  Future<void> _split() async {
    final l = context.l10n;
    final n = _count;
    final done = await gate(
      l.outputsSplitPin,
      (s, conf) => s.splitOutputs(outputs: n, minimumConfirmations: conf),
    );
    if (!done || !mounted) return;
    ref
        .read(noticeProvider.notifier)
        .show(l.outputsSplitStarted(n), level: NoticeLevel.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hidden = ref.watch(appSettingsProvider).value?.hideBalances ?? false;
    final e = estimate;
    String money(BigInt v) => shownEpic(l, v, hidden: hidden);
    final tooSmall = e != null && e.amount < BigInt.from(_minSplitEach);
    final ready = e != null && !tooSmall && !estimating;
    return _sheetFrame(context, l.outputsSplitTitle, [
      if (e != null)
        Text(
          l.outputsSplitText(
            money(e.locked),
            money(e.amount),
            l.outputsCount(_count),
            l.outputsCount(e.inputCount),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Text(l.outputsToMake, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            tooltip: '−',
            onPressed: posting || _count <= minSplitOutputs
                ? null
                : () => _step(-1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 32,
            child: Semantics(
              liveRegion: true,
              child: Text(
                '$_count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: t.monoFamily,
                  fontSize: 18,
                  color: t.text,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '+',
            onPressed: posting || _count >= maxSplitOutputs
                ? null
                : () => _step(1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      Text(
        l.outputsStepperHint,
        style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
      ),
      const SizedBox(height: 8),
      if (estimating && e == null)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      if (e != null) ...[
        _fact(context, l.outputsFactFee, _monoText(context, money(e.fee))),
        _fact(
          context,
          l.outputsFactEach,
          _monoText(context, l.outputsFactAbout(money(e.amount))),
        ),
        _fact(
          context,
          l.outputsFactLocked,
          _monoText(context, l.outputsFactLockedValue(money(e.locked))),
        ),
        Text(
          l.outputsNothingSpendable,
          style: theme.textTheme.bodySmall?.copyWith(color: t.warn),
        ),
        if (tooSmall)
          Text(
            l.outputsMinEach,
            style: theme.textTheme.bodySmall?.copyWith(color: t.warn),
          ),
      ],
      if (estimateError != null) ErrorText(describeError(l, estimateError!)),
      if (postError != null) ErrorText(describeError(l, postError!)),
      const SizedBox(height: 12),
      BusyButton(
        label: l.outputsSplitInto(_count),
        busy: posting,
        onPressed: ready ? _split : null,
      ),
      TextButton(
        onPressed: posting ? null : () => Navigator.pop(context),
        child: Text(l.outputsCancel),
      ),
    ]);
  }
}

class _ConsolidateSheet extends ConsumerStatefulWidget {
  const _ConsolidateSheet({required this.spendableOutputs});

  final int spendableOutputs;

  @override
  ConsumerState<_ConsolidateSheet> createState() => _ConsolidateSheetState();
}

class _ConsolidateSheetState extends ConsumerState<_ConsolidateSheet>
    with _SelfSend<_ConsolidateSheet> {
  @override
  void initState() {
    super.initState();
    estimateNow();
  }

  @override
  Future<FeeEstimate> runEstimate(WalletSession s, BigInt conf) =>
      s.estimateConsolidate(minimumConfirmations: conf);

  Future<void> _consolidate() async {
    final l = context.l10n;
    final done = await gate(
      l.outputsConsolidatePin,
      (s, conf) => s.consolidateOutputs(minimumConfirmations: conf),
    );
    if (!done || !mounted) return;
    ref
        .read(noticeProvider.notifier)
        .show(l.outputsConsolidateStarted, level: NoticeLevel.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hidden = ref.watch(appSettingsProvider).value?.hideBalances ?? false;
    final e = estimate;
    String money(BigInt v) => shownEpic(l, v, hidden: hidden);
    return _sheetFrame(context, l.outputsConsolidateTitle, [
      if (e != null)
        Text(
          l.outputsConsolidateText(
            money(e.locked),
            money(e.amount),
            l.outputsCount(e.inputCount),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      const SizedBox(height: 8),
      if (estimating && e == null)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      if (e != null) ...[
        _fact(context, l.outputsFactFee, _monoText(context, money(e.fee))),
        _fact(
          context,
          l.outputsFactLocked,
          _monoText(context, l.outputsFactLockedValue(money(e.locked))),
        ),
        Text(
          l.outputsNothingSpendable,
          style: theme.textTheme.bodySmall?.copyWith(color: t.warn),
        ),
      ],
      if (estimateError != null) ErrorText(describeError(l, estimateError!)),
      if (postError != null) ErrorText(describeError(l, postError!)),
      const SizedBox(height: 12),
      BusyButton(
        label: l.outputsConsolidateAction,
        busy: posting,
        onPressed: e != null && !estimating ? _consolidate : null,
      ),
      TextButton(
        onPressed: posting ? null : () => Navigator.pop(context),
        child: Text(l.outputsCancel),
      ),
    ]);
  }
}
