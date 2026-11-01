// SPDX-License-Identifier: Apache-2.0
/// Outputs: the pieces the balance is made of, with Split and Consolidate, the strategy a
/// send uses and the list of every output.
library;

import 'phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../smart_outputs.dart';
import '../devices/phone_devices.dart' show phoneDevices;
import '../wallet_service.dart';
import 'common.dart';
import 'pin.dart';
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';
import 'devices/device_tx_details.dart' show heldByLine;
import 'settings_rows.dart' show NavChevron;

/// Which outputs the list shows. [immature] has no segment of its own: Home's tile opens it.
enum OutputsFilter { all, spendable, confirming, locked, immature }

/// Mining rewards and the like need more than this to unlock; the sheet words it plainly.
const int _minSplitEach = nanoEpic ~/ 2;

/// Whether the list shows [o] under [f]: All every output with an [OutputPart] (what Total
/// counts, UD-008: not the spent ones nor an unpaid invoice's); each other filter its part,
/// the one its tile counts.
bool _matches(OutputsFilter f, WalletOutput o) => switch (f) {
  OutputsFilter.all => walletOutputPart(o) != null,
  OutputsFilter.spendable => walletOutputPart(o) == OutputPart.spendable,
  OutputsFilter.confirming => walletOutputPart(o) == OutputPart.confirming,
  OutputsFilter.locked => walletOutputPart(o) == OutputPart.locked,
  OutputsFilter.immature => walletOutputPart(o) == OutputPart.immature,
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
      OutputLabel.confirming => (icon: Icons.timelapse, color: t.info),
      OutputLabel.locked => (icon: Icons.hourglass_top, color: t.warn),
      OutputLabel.finalizing => (icon: Icons.hourglass_empty, color: t.dim),
      OutputLabel.immature ||
      OutputLabel.mining ||
      OutputLabel.spent => (icon: Icons.circle_outlined, color: t.dim),
    };

/// The note under a row's state word: the day it came (no clock: the cell is narrow, and the
/// sheet has the transaction), which send holds it. Confirmations have a column of their own.
String? _rowNote(
  AppLocalizations l,
  WalletOutput o,
  TxEntry? tx,
  DateTime now, {
  String? who,
}) {
  final when = tx == null
      ? null
      : shortDay(
          l,
          DateTime.fromMillisecondsSinceEpoch(tx.timeUnix * 1000),
          now,
        );
  final received = tx != null && tx.kind != TxKind.sent && when != null
      ? l.outputsNoteReceived(
          when == l.dateToday || when == l.dateYesterday
              ? when.toLowerCase()
              : when,
        )
      : null;
  return switch (outputWord(o)) {
    OutputLabel.confirming || OutputLabel.spendable => received,
    OutputLabel.locked =>
      tx?.counterparty == null
          ? l.outputsNoteSendPlain
          : l.outputsNoteSend(who ?? shortAddress(tx!.counterparty!)),
    _ => null,
  };
}

/// The confirmations cell: the count, a dash for an output not on chain yet.
String _confirmations(AppLocalizations l, WalletOutput o) =>
    o.height == BigInt.zero ? '–' : localDigits(l, '${o.confirmations}');

/// The link to the send defaults (now in Settings › Transactions), for tests.
const Key outputsDefaultsLinkKey = ValueKey('outputs-defaults-link');

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

  void _openSheet(WalletOutput o, TxEntry? tx) {
    showPhoneSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OutputSheet(output: o, tx: tx),
    );
  }

  Future<void> _openAction(Widget sheet) async {
    await showPhoneSheet<void>(
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
    // Advanced › Send options shows the defaults a send uses; one that is not at its default
    // stays (never hide a choice in use).
    final showDefaults =
        AdvancedOptions.has(context, AdvancedFeature.sendOptions) ||
        strategy != SelectionStrategy.smallest ||
        !(settings?.splitChange ?? true);
    final home = ref.watch(homeProvider).value;
    final summary = home?.summary;
    final outputs = ref.watch(walletOutputsProvider);
    final list = outputs.value;
    final devices = ref.watch(phoneDevices.view);
    final txs = {
      for (final x in home?.transactions ?? const <TxEntry>[])
        if (x.id != null) x.id!: x,
    };
    // One count for a tile and its filter: the outputs of its [OutputPart] (#69).
    int listed(OutputsFilter f) =>
        list?.where((o) => _matches(f, o)).length ?? 0;
    final nSpendable = listed(OutputsFilter.spendable);
    final nConfirming = listed(OutputsFilter.confirming);
    final nLocked = listed(OutputsFilter.locked);
    final nAll = listed(OutputsFilter.all);
    final nSpent =
        list?.where((o) => outputWord(o) == OutputLabel.spent).length ?? 0;
    // Total counts what All lists: every output with a part, so the numbers add up.
    final nTotalTile = nAll;
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
        ? l.outputsWaitLocked(ref.watch(countedConfirmationsProvider).toInt())
        : [
            if (!canSplit) l.outputsSplitNeeds,
            if (!canConsolidate) l.outputsConsolidateNeeds,
          ].join(' ');

    String money(BigInt v) => shownEpic(l, v, hidden: hidden);
    Widget tile(String label, BigInt? value, int? n) => _Tile(
      label: label,
      count: n == null ? null : l.outputsCount(n),
      value: value == null ? null : money(value),
      dim: n == 0,
    );

    final shown = [
      for (final o in list ?? const <WalletOutput>[])
        if (_showSpent && outputWord(o) == OutputLabel.spent ||
            _matches(_filter, o))
          o,
    ];
    final now = DateTime.now();

    return SlotScaffold(
      appBar: AppBar(title: Text(l.outputsTitle)),
      body: ScreenBody(
        children: [
          // The four balances as a 2 × 2 grid, zero ones dimmed, so the layout never jumps.
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: tile(
                  l.outputsLockedTile,
                  summary == null ? null : locked,
                  list == null ? null : nLocked,
                ),
              ),
              const SizedBox(width: 12),
              // Total instead of Immature on a phone: nobody mines to one. Immature
              // outputs stay in the list and in Total.
              Expanded(
                child: tile(
                  l.homeTileTotal,
                  // The sum of the parts, as its count is (awaiting finalization and
                  // immature included); the wallet's own total stays the headline elsewhere.
                  summary == null
                      ? null
                      : summary.spendable +
                            summary.awaitingConfirmation +
                            summary.awaitingFinalization +
                            summary.immature +
                            summary.locked,
                  list == null ? null : nTotalTile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          else ...[
            _TableHead(
              state: l.outputsColState,
              value: l.outputsColValue,
              confirmations: l.outputsColConfirmations,
            ),
            for (final o in shown)
              _OutputRow(
                output: o,
                value: money(o.value),
                confirmations: _confirmations(l, o),
                word: _wordText(l, outputWord(o)),
                // A coin another linked device is spending says so first.
                note: heldByLine(l, devices, o.commitment) ?? _rowNote(
                  l,
                  o,
                  txs[o.txId],
                  now,
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
          const SizedBox(height: 24),
          ProtocolSectionHead(l.outputsAdvanced),
          const SizedBox(height: 12),
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
          if (showDefaults) ...[
            const SizedBox(height: 8),
            // The send defaults live in Settings › Transactions; one place for each setting.
            ListTile(
              key: outputsDefaultsLinkKey,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune),
              title: Text(l.outputsDefaultsMoved),
              trailing: const NavChevron(),
              onTap: () => openSettingsSection(context, SettingsSection.transactions),
            ),
          ],
        ],
      ),
    );
  }
}

/// A segment's label: one line, shrunk to the segment instead of cut.
Widget _fit(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text));

/// A balance tile: the label as the eyebrow, the output count as the main line, the value in
/// mono below. A null [count] or [value] shows a spinner in its place.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.count,
    required this.value,
    this.dim = false,
  });

  final String label;
  final String? count;
  final String? value;

  /// No outputs in the tile: the count in the dim colour.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    Widget spinner(double size) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox.square(
        dimension: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
    Widget line(double height, Widget child) =>
        SizedBox(height: height, child: child);
    Widget fit(Widget child) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
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
          line(
            28,
            count == null
                ? spinner(20)
                : fit(
                    Text(
                      count!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: dim ? t.dim : t.text,
                      ),
                    ),
                  ),
          ),
          line(
            20,
            value == null
                ? spinner(14)
                : fit(
                    Text(
                      value!,
                      style: TextStyle(
                        fontFamily: t.monoFamily,
                        fontSize: 14,
                        color: t.dim,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The columns of the output table: the state takes the room the value leaves, the
/// confirmations a fixed width, so the header and every row line up.
const double _confWidth = 84;
const double _cellGap = 8;

/// The table's header: three small dim labels over the columns of [_OutputRow].
class _TableHead extends StatelessWidget {
  const _TableHead({
    required this.state,
    required this.value,
    required this.confirmations,
  });

  final String state;
  final String value;
  final String confirmations;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim);
    Widget cell(String text, TextAlign align) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: style,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          Expanded(flex: 13, child: cell(state, TextAlign.start)),
          const SizedBox(width: _cellGap),
          Expanded(flex: 8, child: cell(value, TextAlign.end)),
          const SizedBox(width: _cellGap),
          SizedBox(
            width: _confWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: cell(confirmations, TextAlign.end),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the table: the state mark with its word and note, the value and the
/// confirmations. The whole row is the tap target.
class _OutputRow extends StatelessWidget {
  const _OutputRow({
    required this.output,
    required this.value,
    required this.confirmations,
    required this.word,
    required this.note,
    required this.onTap,
  });

  final WalletOutput output;
  final String value;
  final String confirmations;
  final String word;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final mark = _mark(t, outputWord(output));
    final mono = TextStyle(fontFamily: t.monoFamily, color: t.text);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 13,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The word wraps ("Awaiting finalization") rather than being cut.
                        Text(
                          word,
                          maxLines: 2,
                          style: theme.textTheme.bodyMedium,
                        ),
                        // The note wraps to a second line on a narrow phone ("Received
                        // Yesterday, 11:08" at 360 dp) instead of being cut (android-19).
                        if (note != null)
                          Text(
                            note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.dim,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _cellGap),
            Expanded(
              flex: 8,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(value, maxLines: 1, style: mono.copyWith(fontSize: 14)),
              ),
            ),
            const SizedBox(width: _cellGap),
            SizedBox(
              width: _confWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  confirmations,
                  maxLines: 1,
                  style: mono.copyWith(fontSize: 13),
                ),
              ),
            ),
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
              decoration: t.well,
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

/// A label at the start and its [value] at the end; a value too wide for the room left
/// wraps rather than overflows (amounts carry four decimals).
Widget _fact(BuildContext context, String label, Widget value) {
  final t = context.tokens;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: t.dim),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: DefaultTextStyle.merge(textAlign: TextAlign.end, child: value),
        ),
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
        .show(
          l.outputsSplitStarted(n, ref.read(countedConfirmationsProvider).toInt()),
          level: NoticeLevel.success,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hidden = ref.watch(appSettingsProvider).value?.hideBalances ?? false;
    final blocks = ref.watch(countedConfirmationsProvider).toInt();
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
            blocks,
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
          _monoText(context, l.outputsFactLockedValue(money(e.locked), blocks)),
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
        .show(
          l.outputsConsolidateStarted(ref.read(countedConfirmationsProvider).toInt()),
          level: NoticeLevel.success,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hidden = ref.watch(appSettingsProvider).value?.hideBalances ?? false;
    final blocks = ref.watch(countedConfirmationsProvider).toInt();
    final e = estimate;
    String money(BigInt v) => shownEpic(l, v, hidden: hidden);
    return _sheetFrame(context, l.outputsConsolidateTitle, [
      if (e != null)
        Text(
          l.outputsConsolidateText(
            money(e.locked),
            money(e.amount),
            l.outputsCount(e.inputCount),
            blocks,
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
          _monoText(context, l.outputsFactLockedValue(money(e.locked), blocks)),
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
