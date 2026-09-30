import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
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

/// `45 minutes`, `5 hours`, `3 days`.
String roughDuration(int minutes) {
  if (minutes < 90) return minutes == 1 ? '1 minute' : '$minutes minutes';
  final hours = (minutes / 60).round();
  if (hours < 48) return '$hours hours';
  return '${(hours / 24).round()} days';
}

/// Why a cancelled send was cancelled, in the words of the details screen.
String _cancelledBecause(TxEntry tx, CancelReason reason) => switch (reason) {
  CancelReason.user =>
    'Cancelled. Nothing was sent, and the funds are spendable again.',
  CancelReason.release =>
    'The network never took it, so its funds were released. Check the '
        'recipient did not receive it before sending again.',
  // A finished send that never confirmed may have left this device; an unanswered one did not.
  CancelReason.expiry when tx.finalizedAtUnix != null =>
    'It did not reach the network within 14 days, so the wallet cancelled '
        'it. Check the recipient did not receive it before sending again.',
  CancelReason.expiry =>
    'The recipient did not answer within 14 days, so the wallet cancelled '
        'it. Nothing was sent, and the funds are spendable again.',
  CancelReason.lateAnswer =>
    'The recipient answered after the 14-day limit, so the wallet cancelled '
        'it instead of finishing it. Nothing was sent, and the funds are '
        'spendable again.',
  CancelReason.failed =>
    'It could not be delivered to the recipient, so the wallet cancelled it '
        'at once. Nothing was sent, and the funds are spendable again.',
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

/// What the status means for the user, in a sentence or two. [now] lets an old epicbox send
/// say that it can no longer complete.
String txExplanation(TxEntry tx, BigInt? tip, {DateTime? now}) {
  final n = txConfirmations(tx, tip);
  final height = tx.blockHeight;
  final outgoing = txAmount(tx).outgoing;
  final tooLong = now == null ? null : daysWaitingTooLong(tx, now);
  return switch (txPhase(tx, tip)) {
    TxPhase.waitingRecipient when tooLong != null =>
      'Waiting for $tooLong days. The epicbox deletes payments after 7 days, '
          'so this one can no longer complete. Cancel it to unlock your funds, '
          'then send again.',
    TxPhase.waitingRecipient when _isEpicboxAddress(tx.counterparty) =>
      'Sent to the recipient\'s epicbox. It completes when their wallet comes '
          'online. Your funds stay locked until then, or until you cancel.',
    TxPhase.waitingRecipient =>
      'Waiting for the recipient to answer with their transaction file. Your '
          'funds stay locked until then, or until you cancel.',
    TxPhase.waitingSender =>
      'You accepted this payment. It completes when the sender finishes it '
          'and publishes it to the network.',
    TxPhase.confirming when height == null || n == null =>
      outgoing
          ? 'Published to the network. Waiting for the first confirmation.'
          : 'Waiting for the network to confirm it.',
    TxPhase.confirming =>
      'In block ${groupDigits(height!)}. $n of $confirmationsTarget '
          'confirmations; final in about '
          '${roughDuration((confirmationsTarget - n!) * _minutesPerBlock)}.',
    TxPhase.completed =>
      height == null
          ? 'Completed.'
          : 'Completed in block ${groupDigits(height)}.',
    TxPhase.cancelled when outgoing && tx.cancelReason != null =>
      _cancelledBecause(tx, tx.cancelReason!),
    // No recorded reason (cancelled before the wallet kept one): infer it.
    // Finalized but never confirmed, then cancelled: by the 14-day limit, or released by the
    // user after the node refused it. Either way it may have left this device once.
    TxPhase.cancelled
        when outgoing && tx.finalizedAtUnix != null && _expired(tx, tip) =>
      'It did not reach the network within 14 days, so the wallet cancelled '
          'it. Check the recipient did not receive it before sending again.',
    TxPhase.cancelled when outgoing && tx.finalizedAtUnix != null =>
      'The network never took it, so its funds were released. Check the '
          'recipient did not receive it before sending again.',
    // Unanswered, and cancelled by the 14-day limit rather than by the user.
    TxPhase.cancelled when outgoing && _expired(tx, tip) =>
      'The recipient did not answer within 14 days, so the wallet cancelled '
          'it. Nothing was sent, and the funds are spendable again.',
    TxPhase.cancelled =>
      outgoing
          ? 'Cancelled. Nothing was sent, and the funds are spendable again.'
          : 'Cancelled. This payment will not arrive.',
    TxPhase.fromBackup =>
      'This payment comes from a history backup and was not finished when '
          'the backup was made. This wallet has no record of its own for it, '
          'so it cannot tell whether it completed. Nothing is locked.',
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
String? ttlLine(TxEntry tx, BigInt? tip) {
  final cutoff = tx.ttlCutoffHeight;
  if (cutoff == null || !isPending(tx)) return null;
  if (tip == null) {
    return 'Cancels automatically if not completed by block '
        '${groupDigits(cutoff)}.';
  }
  final left = (cutoff - tip).toInt();
  if (left <= 0) {
    return 'Expired at block ${groupDigits(cutoff)}. The wallet cancels it '
        'on the next refresh.';
  }
  return 'Cancels automatically if not completed by block '
      '${groupDigits(cutoff)} (in about '
      '${roughDuration(left * _minutesPerBlock)}).';
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
      if (mounted) _showMessage(text.isEmpty ? 'Note removed' : 'Note saved');
    } catch (error) {
      if (mounted) _showMessage(describeError(error));
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
      _showMessage('Broadcast again. It should confirm within a few minutes.');
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Unlocks the inputs of a send the network never took, after the user confirms the risk.
  Future<void> _release(TxEntry tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release funds?'),
        content: const Text(
          'Use this only if the payment will never confirm. If it still does, '
          'you may see a wrong balance until you rescan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep waiting'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Release funds'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.releaseStuckSend(key: tx.key);
      if (!mounted) return;
      _showMessage('Funds released');
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(error));
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
      builder: (context) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: Text(
          receive
              ? 'The sender may still finish this payment. If they do after '
                    'you cancel, it will not show until you rescan.'
              : 'Cancel this payment and unlock its funds? Only do this if '
                    'the recipient has not finished it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel payment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.cancelTransaction(txId: id);
      if (!mounted) return;
      _showMessage('Payment cancelled');
      await _reload();
    } catch (error) {
      if (mounted) _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final tx = home.value?.transactions
        .where((t) => t.key == widget.txKey)
        .firstOrNull;
    if (tx == null) {
      return SlotScaffold(
        appBar: AppBar(title: const Text('Payment')),
        idle: home.isLoading ? const SlotProgress(label: 'Loading') : null,
        centered: !home.isLoading,
        body: home.isLoading
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: home.hasError
                    ? ErrorText(describeError(home.error!))
                    : const Text(
                        'This payment is no longer in the wallet.',
                        textAlign: TextAlign.center,
                      ),
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
        : approxFiat(amount, display);
    final ttl = ttlLine(tx, tip);
    final now = ref.watch(clockProvider)();
    final stuck = isStuck(tx, now);
    final url = chain == null ? null : explorerUrl(chain, tx);
    final fee = tx.fee;
    final blockTime = tx.blockTimeUnix;
    final note = tx.note;

    return SlotScaffold(
      appBar: AppBar(title: Text(txHeading(tx, contactName: name))),
      idle: _busy || home.isLoading
          ? const SlotProgress(label: 'Working')
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
                      label: hidden ? 'Amount hidden' : null,
                      excludeSemantics: hidden,
                      child: Text(
                        signedEpic(tx, hidden: hidden),
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
                  Text(txExplanation(tx, tip, now: now)),
                  if (ttl != null) ...[
                    const SizedBox(height: 8),
                    Text(ttl, style: theme.textTheme.bodySmall),
                  ],
                  if (stuck) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Not confirmed yet',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The network has not taken this payment yet. Broadcasting '
                      'it again is safe. The same payment cannot go through '
                      'twice.',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.cell_tower),
                        label: const Text('Broadcast again'),
                        onPressed: _busy ? null : () => _repost(tx),
                      ),
                    ),
                  ],
                  if (tx.releasable) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'The network refused this payment and it never reached the '
                      'chain. You can release the funds it locked.',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Release funds'),
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
                        label: const Text('Cancel payment'),
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
            label: 'Date',
            value: formatDateTime(localTime(blockTime ?? tx.timeUnix)),
          ),
          if (blockTime != null &&
              tx.source == TxSource.wallet &&
              (blockTime - tx.createdAtUnix).abs() > 120)
            _DetailRow(
              label: 'Created',
              value: formatDateTime(localTime(tx.createdAtUnix)),
            ),
          if (counterparty != null)
            _CounterpartyRow(
              label: outgoing ? 'Sent to' : 'Received from',
              address: counterparty,
              name: name,
              canSendAgain: outgoing && tx.status == TxStatus.confirmed,
            ),
          if (fee != null && outgoing)
            _DetailRow(
              label: 'Fee',
              value: shownEpic(fee, hidden: hidden),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Note', style: theme.textTheme.labelLarge),
            subtitle: Text(
              note ?? 'No note. Add one to remember what this was for.',
            ),
            trailing: IconButton(
              tooltip: note == null ? 'Add note' : 'Edit note',
              icon: Icon(note == null ? Icons.note_add_outlined : Icons.edit),
              onPressed: _busy ? null : () => _editNote(tx),
            ),
          ),
          if (url != null)
            _DetailRow(
              label: 'Copy explorer link',
              value: url,
              copy: true,
              copyLabel: 'Copy explorer link',
              copyWhat: 'Link',
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Technical details'),
            children: [
              if (tx.blockHeight case final height?)
                _DetailRow(label: 'Block height', value: groupDigits(height)),
              if (tx.slateId case final slate?)
                _DetailRow(label: 'Slate ID', value: slate, copy: true),
              if (tx.kernelExcess case final kernel?)
                _DetailRow(label: 'Kernel', value: kernel, copy: true),
              for (final (i, commit) in tx.outputCommits.indexed)
                _DetailRow(
                  label: tx.outputCommits.length == 1
                      ? 'Output commitment'
                      : 'Output commitment ${i + 1}',
                  value: commit,
                  copy: true,
                ),
              if (tx.ttlCutoffHeight case final cutoff?)
                _DetailRow(label: 'Expiry height', value: groupDigits(cutoff)),
              if (tx.id case final id?)
                _DetailRow(label: 'Local id', value: '$id'),
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
    return AlertDialog(
      title: const Text('Note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Note',
          helperText: 'Only on this device and in your history backups.',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
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
    final text = switch (source) {
      TxSource.restored =>
        'Found by scanning the chain. Details such as the sender and fee are '
            'not stored on the chain; import a history backup to restore them.',
      TxSource.imported =>
        'Imported from a history backup. This wallet has no record of its own '
            'for it, so its status may be out of date.',
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
  const _DetailRow({
    required this.label,
    required this.value,
    this.copy = false,
    this.copyLabel,
    this.copyWhat,
  });

  final String label;
  final String value;
  final bool copy;
  final String? copyLabel;
  final String? copyWhat;

  @override
  Widget build(BuildContext context) {
    void doCopy() => copyText(context, value, copyWhat ?? label);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: copy ? Text(value) : SelectableText(value),
      onTap: copy ? doCopy : null,
      trailing: copy
          ? IconButton(
              tooltip: copyLabel ?? 'Copy ${label.toLowerCase()}',
              icon: const Icon(Icons.copy),
              onPressed: doCopy,
            )
          : null,
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
            tooltip: 'Copy address',
            icon: const Icon(Icons.copy),
            onPressed: () => copyText(context, address, 'Address'),
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
                  label: const Text('Add to contacts'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContactEditScreen(address: address),
                    ),
                  ),
                ),
              if (canSendAgain)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Send again'),
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
