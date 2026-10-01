import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart' show ContactEditScreen;
import 'send_screen.dart' show SendScreen;

/// Minutes per Epic block, for rough "about N hours" estimates.
const int _minutesPerBlock = 1;

/// A link to the payment in a block explorer, once it is on chain: the kernel on floonet, the
/// block on mainnet (no mainnet explorer shows kernels). Null before confirmation, when the
/// kernel is not on chain yet (and for a receive is only our partial excess), and elsewhere.
String? explorerUrl(Chain chain, TxEntry tx) {
  if (tx.status != TxStatus.confirmed) return null;
  final kernel = tx.kernelExcess;
  final height = tx.blockHeight;
  return switch (chain) {
    Chain.floonet when kernel != null =>
      'https://floo-explorer.btlabs.uk/kernel/$kernel',
    Chain.mainnet when height != null =>
      'https://explorer.epicmine.io/block/$height',
    _ => null,
  };
}

/// The unit a rough duration is said in.
enum _DurationUnit { minutes, hours, days }

/// [minutes] rounded the way the details screen says it: minutes below 90, else hours below
/// 48, else days. Each sentence has one message per unit, so every language can inflect both
/// the number and the words around it.
({_DurationUnit unit, int count}) _roughDuration(int minutes) {
  if (minutes < 90) return (unit: _DurationUnit.minutes, count: minutes);
  final hours = (minutes / 60).round();
  if (hours < 48) return (unit: _DurationUnit.hours, count: hours);
  return (unit: _DurationUnit.days, count: (hours / 24).round());
}

/// Why a cancelled send was cancelled, in the words of the details screen.
String _cancelledBecause(AppLocalizations l, TxEntry tx, CancelReason reason) =>
    switch (reason) {
      CancelReason.user => l.txDetailsCancelledByUser,
      CancelReason.release => l.txDetailsCancelledReleased,
      // A finished send that never confirmed may have left this device; an unanswered one did not.
      CancelReason.expiry when tx.finalizedAtUnix != null =>
        l.txDetailsCancelledNotOnChain,
      CancelReason.expiry => l.txDetailsCancelledUnanswered,
      CancelReason.lateAnswer => l.txDetailsCancelledLateAnswer,
      CancelReason.failed => l.txDetailsCancelledUndelivered,
    };

/// Whether the chain has reached the send's expiry height.
bool _expired(TxEntry tx, BigInt? tip) {
  final cutoff = tx.ttlCutoffHeight;
  return cutoff != null && tip != null && tip >= cutoff;
}

/// Whether [address] is someone's epicbox address rather than a wallet URL.
bool _isEpicboxAddress(String? address) =>
    address != null &&
    address.contains('@') &&
    !address.toLowerCase().startsWith('http');

/// `In block 2,500,120. 3 of 10 confirmations; final in about 7 minutes.`
String _confirmingLine(AppLocalizations l, BigInt height, int n) {
  final block = groupDigits(l, height);
  final target = confirmationsTarget;
  final (:unit, :count) = _roughDuration((target - n) * _minutesPerBlock);
  return switch (unit) {
    _DurationUnit.minutes => l.txDetailsConfirmingMinutes(
      block,
      n,
      target,
      count,
    ),
    _DurationUnit.hours => l.txDetailsConfirmingHours(block, n, target, count),
    _DurationUnit.days => l.txDetailsConfirmingDays(block, n, target, count),
  };
}

/// What the status means for the user, in a sentence or two. [now] lets an old epicbox send
/// say that it can no longer complete.
String txExplanation(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  DateTime? now,
}) {
  final n = txConfirmations(tx, tip);
  final height = tx.blockHeight;
  final outgoing = txAmount(tx).outgoing;
  final tooLong = now == null ? null : daysWaitingTooLong(tx, now);
  return switch (txPhase(tx, tip)) {
    TxPhase.waitingRecipient when tooLong != null => l.txDetailsWaitingTooLong(
      tooLong,
    ),
    TxPhase.waitingRecipient when _isEpicboxAddress(tx.counterparty) =>
      l.txDetailsWaitingEpicbox,
    TxPhase.waitingRecipient => l.txDetailsWaitingRecipient,
    TxPhase.waitingSender => l.txDetailsWaitingSender,
    TxPhase.confirming when height == null || n == null =>
      outgoing ? l.txDetailsPublished : l.txDetailsWaitingConfirmation,
    TxPhase.confirming => _confirmingLine(l, height!, n!),
    TxPhase.completed =>
      height == null
          ? l.txDetailsCompleted
          : l.txDetailsCompletedInBlock(groupDigits(l, height)),
    TxPhase.cancelled when outgoing && tx.cancelReason != null =>
      _cancelledBecause(l, tx, tx.cancelReason!),
    // No recorded reason (cancelled before the wallet kept one): infer it.
    // Finalized but never confirmed, then cancelled: by the 14-day limit, or released by the
    // user after the node refused it. Either way it may have left this device once.
    TxPhase.cancelled
        when outgoing && tx.finalizedAtUnix != null && _expired(tx, tip) =>
      l.txDetailsCancelledNotOnChain,
    TxPhase.cancelled when outgoing && tx.finalizedAtUnix != null =>
      l.txDetailsCancelledReleased,
    // Unanswered, and cancelled by the 14-day limit rather than by the user.
    TxPhase.cancelled when outgoing && _expired(tx, tip) =>
      l.txDetailsCancelledUnanswered,
    TxPhase.cancelled =>
      outgoing ? l.txDetailsCancelledByUser : l.txDetailsCancelledIncoming,
    TxPhase.fromBackup => l.txDetailsFromBackup,
  };
}

/// How long a posted send may wait for the chain before details offer to broadcast it again.
const Duration stuckAfter = Duration(minutes: 30);

/// A finalized send that the chain still has not included [stuckAfter] after it was finalized
/// ([TxEntry.finalizedAtUnix], else [TxEntry.timeUnix]), and that the core can post again.
bool isStuck(TxEntry tx, DateTime now) =>
    tx.repostable &&
    tx.status == TxStatus.awaitingConfirmation &&
    now.difference(localTime(tx.finalizedAtUnix ?? tx.timeUnix)) >= stuckAfter;

/// After this long an unanswered epicbox send can no longer complete: the epicbox keeps a
/// payment 7 days, and the answer can wait up to 7 more in ours.
const Duration epicboxGiveUp = Duration(days: 14);

/// Whole days a send without an expiry has waited for its recipient past [epicboxGiveUp], or
/// null when it has an expiry (the TTL line covers it) or is not that old. Sends made before
/// the wallet set an expiry have none.
int? daysWaitingTooLong(TxEntry tx, DateTime now) {
  if (tx.status != TxStatus.awaitingRecipient ||
      tx.ttlCutoffHeight != null ||
      !_isEpicboxAddress(tx.counterparty)) {
    return null;
  }
  final waited = now.difference(localTime(tx.timeUnix));
  return waited > epicboxGiveUp ? waited.inDays : null;
}

/// When a pending transaction cancels itself, if it has an expiry.
String? ttlLine(AppLocalizations l, TxEntry tx, BigInt? tip) {
  final cutoff = tx.ttlCutoffHeight;
  if (cutoff == null || !isPending(tx)) return null;
  final block = groupDigits(l, cutoff);
  if (tip == null) return l.txDetailsCancelsAtBlock(block);
  final left = (cutoff - tip).toInt();
  if (left <= 0) return l.txDetailsExpiredAtBlock(block);
  final (:unit, :count) = _roughDuration(left * _minutesPerBlock);
  return switch (unit) {
    _DurationUnit.minutes => l.txDetailsCancelsAtBlockInMinutes(block, count),
    _DurationUnit.hours => l.txDetailsCancelsAtBlockInHours(block, count),
    _DurationUnit.days => l.txDetailsCancelsAtBlockInDays(block, count),
  };
}

/// Everything known about one transaction, with its note, contact and cancel.
class TxDetailsScreen extends ConsumerStatefulWidget {
  const TxDetailsScreen({super.key, required this.txKey});

  /// [TxEntry.key] of the transaction to show.
  final String txKey;

  @override
  ConsumerState<TxDetailsScreen> createState() => _TxDetailsScreenState();
}

class _TxDetailsScreenState extends ConsumerState<TxDetailsScreen> {
  bool _busy = false;

  void _showMessage(String message) =>
      ref.read(noticeProvider.notifier).show(message);

  Future<void> _reload() async {
    ref.invalidate(nodeTipProvider);
    try {
      await ref.read(homeProvider.notifier).reload();
    } catch (_) {
      // The screen shows what it still has.
    }
  }

  Future<void> _editNote(TxEntry tx) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _NoteDialog(initial: tx.note ?? ''),
    );
    if (note == null || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      final text = note.trim();
      await session.setTxNote(key: tx.key, note: text.isEmpty ? null : text);
      await _reload();
      if (!mounted) return;
      _showMessage(
        text.isEmpty
            ? context.l10n.txDetailsNoteRemoved
            : context.l10n.txDetailsNoteSaved,
      );
    } catch (error) {
      if (mounted) _showMessage(describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _repost(TxEntry tx) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.repostTransaction(key: tx.key);
      if (!mounted) return;
      _showMessage(context.l10n.txDetailsBroadcastAgainDone);
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Unlocks the inputs of a send the network never took, after the user confirms the risk.
  Future<void> _release(TxEntry tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.txDetailsReleaseTitle),
          content: Text(l.txDetailsReleaseBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.txDetailsReleaseKeepWaiting),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.txDetailsReleaseFunds),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.releaseStuckSend(key: tx.key);
      if (!mounted) return;
      _showMessage(context.l10n.txDetailsFundsReleased);
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(TxEntry tx) async {
    final id = tx.id;
    if (id == null) return;
    final receive = !txAmount(tx).outgoing;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.txDetailsCancelTitle),
          content: Text(
            receive ? l.txDetailsCancelReceiveBody : l.txDetailsCancelSendBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.txDetailsCancelKeep),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.txDetailsCancelPayment),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.cancelTransaction(txId: id);
      if (!mounted) return;
      _showMessage(context.l10n.txDetailsPaymentCancelled);
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final home = ref.watch(homeProvider);
    final tx = home.value?.transactions
        .where((t) => t.key == widget.txKey)
        .firstOrNull;
    if (tx == null) {
      return SlotScaffold(
        appBar: AppBar(title: Text(l.txDetailsTitle)),
        idle: home.isLoading ? SlotProgress(label: l.txDetailsLoading) : null,
        centered: !home.isLoading,
        body: home.isLoading
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: home.hasError
                    ? ErrorText(describeError(l, home.error!))
                    : Text(l.txDetailsGone, textAlign: TextAlign.center),
              ),
      );
    }

    final theme = Theme.of(context);
    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final tip = tipHeight(ref);
    final chain = ref.watch(walletConfigProvider)?.chain;
    final (:amount, :outgoing) = txAmount(tx);
    final counterparty = tx.counterparty;
    final name = contactName(ref, counterparty);
    final fiat = tx.status == TxStatus.cancelled
        ? null
        : approxFiat(l, amount, display);
    final ttl = ttlLine(l, tx, tip);
    final now = ref.watch(clockProvider)();
    final stuck = isStuck(tx, now);
    final url = chain == null ? null : explorerUrl(chain, tx);
    final fee = tx.fee;
    final blockTime = tx.blockTimeUnix;
    final note = tx.note;
    final singleOutput = tx.outputCommits.length == 1;

    return SlotScaffold(
      appBar: AppBar(title: Text(txHeading(l, tx, contactName: name))),
      idle: _busy || home.isLoading
          ? SlotProgress(label: l.txDetailsWorking)
          : null,
      body: ScreenBody(
        children: [
          Row(
            children: [
              TxIcon(tx: tx),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: hidden ? l.txDetailsAmountHidden : null,
                      excludeSemantics: hidden,
                      child: Text(
                        signedEpic(l, tx, hidden: hidden),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    if (fiat != null)
                      Text(
                        fiat,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TxStatusChip(tx: tx, tip: tip),
                  const SizedBox(height: 8),
                  Text(txExplanation(l, tx, tip, now: now)),
                  if (ttl != null) ...[
                    const SizedBox(height: 8),
                    Text(ttl, style: theme.textTheme.bodySmall),
                  ],
                  if (stuck) ...[
                    const SizedBox(height: 12),
                    Text(
                      l.txDetailsNotConfirmedYet,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l.txDetailsStuckBody),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.cell_tower),
                        label: Text(l.txDetailsBroadcastAgain),
                        onPressed: _busy ? null : () => _repost(tx),
                      ),
                    ),
                  ],
                  if (tx.releasable) ...[
                    const SizedBox(height: 12),
                    Text(l.txDetailsRefusedBody),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_open),
                        label: Text(l.txDetailsReleaseFunds),
                        onPressed: _busy ? null : () => _release(tx),
                      ),
                    ),
                  ],
                  if (tx.cancellable && tx.id != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(l.txDetailsCancelPayment),
                        onPressed: _busy ? null : () => _cancel(tx),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (tx.source != TxSource.wallet) ...[
            const SizedBox(height: 8),
            _SourceNote(source: tx.source),
          ],
          const SizedBox(height: 8),
          _DetailRow(
            label: l.txDetailsDate,
            value: formatDateTime(l, localTime(blockTime ?? tx.timeUnix)),
          ),
          if (blockTime != null &&
              tx.source == TxSource.wallet &&
              (blockTime - tx.createdAtUnix).abs() > 120)
            _DetailRow(
              label: l.txDetailsCreated,
              value: formatDateTime(l, localTime(tx.createdAtUnix)),
            ),
          if (counterparty != null)
            _CounterpartyRow(
              label: outgoing ? l.txDetailsSentTo : l.txDetailsReceivedFrom,
              address: counterparty,
              name: name,
              canSendAgain: outgoing && tx.status == TxStatus.confirmed,
            ),
          if (fee != null && outgoing)
            _DetailRow(
              label: l.txDetailsFee,
              value: shownEpic(l, fee, hidden: hidden),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.txDetailsNoteLabel,
              style: theme.textTheme.labelLarge,
            ),
            subtitle: Text(note ?? l.txDetailsNoNote),
            trailing: IconButton(
              tooltip: note == null ? l.txDetailsAddNote : l.txDetailsEditNote,
              icon: Icon(note == null ? Icons.note_add_outlined : Icons.edit),
              onPressed: _busy ? null : () => _editNote(tx),
            ),
          ),
          if (url != null)
            _DetailRow(
              label: l.txDetailsExplorerLink,
              value: url,
              copy: (
                tooltip: l.txDetailsExplorerLinkCopy,
                notice: l.txDetailsLinkCopied,
              ),
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(l.txDetailsTechnical),
            children: [
              if (tx.blockHeight case final height?)
                _DetailRow(
                  label: l.txDetailsBlockHeight,
                  value: groupDigits(l, height),
                ),
              if (tx.slateId case final slate?)
                _DetailRow(
                  label: l.txDetailsSlateId,
                  value: slate,
                  copy: (
                    tooltip: l.txDetailsSlateIdCopy,
                    notice: l.txDetailsSlateIdCopied,
                  ),
                ),
              if (tx.kernelExcess case final kernel?)
                _DetailRow(
                  label: l.txDetailsKernel,
                  value: kernel,
                  copy: (
                    tooltip: l.txDetailsKernelCopy,
                    notice: l.txDetailsKernelCopied,
                  ),
                ),
              for (final (i, commit) in tx.outputCommits.indexed)
                _DetailRow(
                  label: singleOutput
                      ? l.txDetailsOutputCommitment
                      : l.txDetailsOutputCommitmentNumbered(i + 1),
                  value: commit,
                  copy: singleOutput
                      ? (
                          tooltip: l.txDetailsOutputCommitmentCopy,
                          notice: l.txDetailsOutputCommitmentCopied,
                        )
                      : (
                          tooltip: l.txDetailsOutputCommitmentNumberedCopy(
                            i + 1,
                          ),
                          notice: l.txDetailsOutputCommitmentNumberedCopied(
                            i + 1,
                          ),
                        ),
                ),
              if (tx.ttlCutoffHeight case final cutoff?)
                _DetailRow(
                  label: l.txDetailsExpiryHeight,
                  value: groupDigits(l, cutoff),
                ),
              if (tx.id case final id?)
                _DetailRow(label: l.txDetailsLocalId, value: '$id'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for a note. Pops with the text, or null when cancelled.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.txDetailsNoteDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l.txDetailsNoteLabel,
          helperText: l.txDetailsNoteHelper,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}

/// Why a restored or imported transaction lacks details.
class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.source});

  final TxSource source;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = switch (source) {
      TxSource.restored => l.txDetailsSourceRestored,
      TxSource.imported => l.txDetailsSourceImported,
      TxSource.wallet => '',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// A labelled value that can be selected; with [copy], also copied, by the icon or a tap on the
/// row.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.copy});

  final String label;
  final String value;

  /// The copy button's tooltip and the notice after copying, for a value worth copying.
  final ({String tooltip, String notice})? copy;

  @override
  Widget build(BuildContext context) {
    final copy = this.copy;
    final VoidCallback? doCopy = copy == null
        ? null
        : () => copyText(context, value, copy.notice);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: copy == null ? SelectableText(value) : Text(value),
      onTap: doCopy,
      trailing: copy == null
          ? null
          : IconButton(
              tooltip: copy.tooltip,
              icon: const Icon(Icons.copy),
              onPressed: doCopy,
            ),
    );
  }
}

/// The other side's address, with the contact name when saved, else an offer to save it.
class _CounterpartyRow extends StatelessWidget {
  const _CounterpartyRow({
    required this.label,
    required this.address,
    required this.name,
    required this.canSendAgain,
  });

  final String label;
  final String address;
  final String? name;

  /// A completed send: offer to pay this address again.
  final bool canSendAgain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: theme.textTheme.labelLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null) Text(name!, style: theme.textTheme.titleMedium),
              SelectableText(address),
            ],
          ),
          trailing: IconButton(
            tooltip: l.txDetailsCopyAddress,
            icon: const Icon(Icons.copy),
            onPressed: () =>
                copyText(context, address, l.txDetailsAddressCopied),
          ),
        ),
        // The actions for this address, on one row in one style.
        if (name == null || canSendAgain)
          Wrap(
            spacing: 8,
            children: [
              if (name == null)
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(l.txDetailsAddToContacts),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContactEditScreen(address: address),
                    ),
                  ),
                ),
              if (canSendAgain)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text(l.txDetailsSendAgain),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SendScreen(recipient: address),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
