import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../network.dart' show EpicboxRelay;
import '../pairing_providers.dart' show PairNet, pairNetProvider, pairingByIdProvider, pairingSlateProvider;
import '../send_preflight.dart' show recipientRelay;
import '../settings.dart';
import '../wallet_service.dart';
import '../stall_retry.dart' show invoicePaymentStalled;
import 'common.dart';
import 'contacts_screen.dart' show ContactEditScreen;
import 'invoice_request_screen.dart' show IssuedInvoiceBlock;
import 'invoice_review_screen.dart' show PaidInvoiceBlock;
import 'pairing/pair_check.dart' show CheckWordsScreen;
import 'pairing/pairing_notices.dart' show pairingNewsOnScreen, pairingSlateNoticeTag;
import 'pairing/pairing_parts.dart' show PairEdgeNotice;
import 'pairing/withdrawal_block.dart';
import 'theme/advanced.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'method_names.dart';
import 'tx_edit_sheet.dart';
import 'tx_label.dart';

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

/// The relay of an Epicbox send's address, null for any other.
EpicboxRelay? _epicboxRelayOf(TxEntry tx) =>
    tx.transport == 'epicbox' ? recipientRelay(tx.counterparty ?? '') : null;

/// Whether [address] is someone's epicbox address rather than a wallet URL.
bool _isEpicboxAddress(String? address) =>
    address != null &&
    address.contains('@') &&
    !address.toLowerCase().startsWith('http');

/// Whether [tx] went straight to the other wallet over HTTP or Tor, whose counterparty is
/// its URL (`http://<onion>` over Tor).
bool _isDirect(TxEntry tx) {
  final to = tx.counterparty?.trim().toLowerCase() ?? '';
  return to.startsWith('http://') || to.startsWith('https://');
}

/// `In block 2,500,120. 1 of 3 confirmations; final in about 2 minutes.`
String _confirmingLine(AppLocalizations l, BigInt height, int n, int target) {
  final block = groupDigits(l, height);
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
  int? target,
  bool mailbox = false,
}) {
  final n = txConfirmations(tx, tip);
  final height = tx.blockHeight;
  final outgoing = txAmount(tx).outgoing;
  final tooLong = now == null ? null : daysWaitingTooLong(tx, now);
  return switch (txPhase(tx, tip, target: target)) {
    TxPhase.waitingRecipient when tx.undelivered => switch ((tx.transport, _epicboxRelayOf(tx))) {
      ('http' || 'tor', _) => l.txDetailsNotDeliveredDirectBody,
      (_, final relay?) => l.txDetailsNotDeliveredRelayBody(relay.label),
      _ => l.txDetailsNotDeliveredBody,
    },
    TxPhase.waitingRecipient
        when now != null && invoicePaymentStalled(tx, now) =>
      l.txDetailsStalledBody,
    TxPhase.waitingRecipient when tooLong != null => l.txDetailsWaitingTooLong(
      tooLong,
    ),
    // Through a paired contact's mailbox: an Epicbox payment, though kept as an export.
    TxPhase.waitingRecipient when mailbox || _isEpicboxAddress(tx.counterparty) =>
      l.txDetailsWaitingEpicbox,
    TxPhase.waitingRecipient => l.txDetailsWaitingRecipient,
    TxPhase.waitingSender when now != null && senderReportsPosted(tx, now: now) =>
      l.txDetailsSenderPosted,
    TxPhase.waitingSender => l.txDetailsWaitingSender,
    TxPhase.waitingPayer => l.txDetailsWaitingPayer,
    // Finished, but the node refused it (android-17): it is not on the network.
    TxPhase.confirming when tx.repostable => l.txDetailsStuckBody,
    // Over HTTP or Tor their wallet took it in the exchange itself: only a block is left.
    TxPhase.confirming when outgoing && height == null && _isDirect(tx) =>
      l.sendDeliveredWaitingBlock,
    TxPhase.confirming when height == null || n == null =>
      outgoing ? l.txDetailsPublished : l.txDetailsWaitingConfirmation,
    TxPhase.confirming => _confirmingLine(
      l,
      height!,
      n!,
      target ?? confirmationsTarget,
    ),
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
    TxPhase.cancelled when tx.isRequest => l.txDetailsRequestEnded,
    TxPhase.cancelled =>
      outgoing ? l.txDetailsCancelledByUser : l.txDetailsCancelledIncoming,
    TxPhase.fromBackup => l.txDetailsFromBackup,
  };
}

/// A finished send the node refused ([TxEntry.repostable]): details offer to broadcast it
/// again at once, and the app tries again by itself (stall_retry.dart).
bool isStuck(TxEntry tx) =>
    tx.repostable && tx.status == TxStatus.awaitingConfirmation;

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

/// The key of the "More" link that shows the technical rows once, for tests.
const Key txDetailsMoreKey = ValueKey('tx-details-more');

/// The receive's Cancel, once its hold is over, and the line that stands in for it before.
const Key txDetailsCancelReceiveKey = ValueKey('tx-details-cancel-receive');
const Key txDetailsCancelHoldKey = ValueKey('tx-details-cancel-hold');

/// Everything known about one transaction, with its note, contact and cancel.
class TxDetailsScreen extends ConsumerStatefulWidget {
  const TxDetailsScreen({super.key, required this.txKey});

  /// [TxEntry.key] of the transaction to show.
  final String txKey;

  @override
  ConsumerState<TxDetailsScreen> createState() => _TxDetailsScreenState();
}

class _TxDetailsScreenState extends ConsumerState<TxDetailsScreen> {
  /// "More" was tapped: the technical rows show for this view although the switch is off.
  bool _more = false;

  /// The page shows its own withdrawal.
  bool _shows(PairingEvent e) {
    if (e.kind != PairingEventKind.withdrawalFromContact || e.slateId == null) return false;
    if (widget.txKey == 's:${e.slateId}') return true;
    final tx = ref.read(homeProvider).value?.transactions.where((t) => t.key == widget.txKey).firstOrNull;
    return tx?.slateId == e.slateId;
  }

  @override
  void initState() {
    super.initState();
    pairingNewsOnScreen.add(_shows);
    // A withdrawal's notice led here, or would repeat what the page shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final slate = widget.txKey.startsWith('s:')
          ? widget.txKey.substring(2)
          : ref.read(homeProvider).value?.transactions.where((t) => t.key == widget.txKey).firstOrNull?.slateId;
      if (slate != null) ref.read(noticeProvider.notifier).dismissTag(pairingSlateNoticeTag(slate));
    });
  }

  @override
  void dispose() {
    _minute?.cancel();
    pairingNewsOnScreen.remove(_shows);
    super.dispose();
  }

  bool _busy = false;

  /// The node already had this receive when Cancel was asked: it is on its way, so Cancel
  /// stays away for this visit.
  bool _onNetwork = false;

  /// Ticks once a minute while an incoming payment waits inside its Cancel hold, so the
  /// "accepted N minutes ago" line and the hold's end move without a refresh.
  Timer? _minute;

  void _tickWhile(bool held) {
    if (held && _minute == null) {
      _minute = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!held && _minute != null) {
      _minute!.cancel();
      _minute = null;
    }
  }

  void _showMessage(String message, {required NoticeLevel level}) =>
      ref.read(noticeProvider.notifier).show(message, level: level);

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
        level: NoticeLevel.success,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          describeError(context.l10n, error),
          level: NoticeLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the details sheet of a restored row and saves what comes back.
  Future<void> _editDetails(TxEntry tx) async {
    final input = await showTxDetailsSheet(context, tx);
    if (input == null || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final l = context.l10n;
    const fields = {
      ManualField.counterparty,
      ManualField.transport,
      ManualField.note,
    };
    final had = tx.manualFields.intersection(fields).isNotEmpty;
    final has =
        input.counterparty != null ||
        input.transport != null ||
        input.note != null;
    setState(() => _busy = true);
    try {
      await session.setTxDetails(
        key: tx.key,
        counterparty: input.counterparty,
        transport: input.transport,
        note: input.note,
      );
      await _reload();
      if (!mounted) return;
      if (had || has) {
        _showMessage(
          !has
              ? l.txEditRemovedNotice
              : had
              ? l.txEditSavedNotice
              : l.txEditAddedNotice,
          level: NoticeLevel.info,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(describeError(l, error), level: NoticeLevel.error);
      }
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
      _showMessage(
        context.l10n.txDetailsBroadcastAgainDone,
        level: NoticeLevel.success,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        _showMessage(
          describeError(context.l10n, error),
          level: NoticeLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendAgain(TxEntry tx) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await session.resendEpicbox(key: tx.key);
      if (!mounted) return;
      _showMessage(
        context.l10n.txDetailsSendAgainDone,
        level: NoticeLevel.success,
      );
    } catch (error) {
      if (mounted) {
        // The relay is named: a mistyped domain never answers, however often it is tried.
        final relay = _epicboxRelayOf(tx);
        _showMessage(
          error is WalletError &&
                  error.kind == WalletErrorKind.transportFailed &&
                  relay != null
              ? context.l10n.relayNoAnswer(relay.label)
              : describeError(context.l10n, error),
          level: NoticeLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _reload();
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
      _showMessage(
        context.l10n.txDetailsFundsReleased,
        level: NoticeLevel.success,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        _showMessage(
          describeError(context.l10n, error),
          level: NoticeLevel.error,
        );
      }
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
      _showMessage(
        context.l10n.txDetailsPaymentCancelled,
        level: NoticeLevel.success,
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      // LEPIC asked the node first and found the kernel in its pool or chain (OnChain,
      // InPool, mapped to invalidArgument): not a failure, the payment is on its way. The
      // refresh after it lets the row show that.
      final onNetwork = receive &&
          error is WalletError &&
          error.kind == WalletErrorKind.invalidArgument;
      _showMessage(
        onNetwork
            ? context.l10n.txDetailsCancelRefusedOnNetwork
            : describeError(context.l10n, error),
        level: onNetwork ? NoticeLevel.info : NoticeLevel.error,
      );
      if (onNetwork) {
        setState(() => _onNetwork = true);
        await _reload();
      }
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
    final target = confirmationsTargetOf(ref);
    final chain = ref.watch(walletConfigProvider)?.chain;
    final (:amount, :outgoing) = txAmount(tx);
    final counterparty = tx.counterparty;
    // A payment through a paired contact's mailbox (no address): the contact, never the
    // mailbox.
    final mailboxName = txMailboxName(ref, tx, any: true);
    final mailboxPairing = mailboxName == null
        ? null
        : switch (tx.pairingId ?? ref.watch(pairingSlateProvider(tx.slateId!)).value?.pairingId) {
            final id? => ref.watch(pairingByIdProvider(id)),
            null => null,
          };
    final mailboxWaiting = mailboxName != null && tx.status == TxStatus.awaitingRecipient;
    final name = txPartyName(ref, tx) ?? mailboxName;
    final fiat = tx.status == TxStatus.cancelled
        ? null
        : approxFiat(l, amount, display);
    final ttl = ttlLine(l, tx, tip);
    final now = ref.watch(clockProvider)();
    final stuck = isStuck(tx);
    final url = chain == null ? null : explorerUrl(chain, tx);
    final fee = tx.fee;
    final blockTime = tx.blockTimeUnix;
    final note = tx.note;
    // The money's side this wallet is on writes "your" message; the other side's is theirs.
    final ownRole = outgoing ? SlateRole.sender : SlateRole.receiver;
    final ownMessage = messageBy(tx.messages, ownRole);
    final theirMessage = messageBy(
      tx.messages,
      outgoing ? SlateRole.receiver : SlateRole.sender,
    );
    final singleOutput = tx.outputCommits.length == 1;
    final issued =
        tx.isRequest ||
        switch (tx.slateId) {
          final slate? => ref.watch(issuedInvoiceProvider(slate)).value != null,
          null => false,
        };

    // A withdrawal from a paired exchange has its own steps (WithdrawalBlock).
    final withdrawal = withdrawalOf(ref, tx);
    // An invoice this payment paid (PaidInvoiceBlock): a paired contact's has its own card and
    // steps (SPEC 2.8), so the card here keeps only what the user can do (PAIR-AND-4).
    final paidInvoice = switch (tx.slateId) {
      final slate? => ref.watch(paidInvoiceProvider(slate)).value,
      null => null,
    };
    final ownSteps = withdrawal != null || paidInvoice?.pairingId != null;
    // LEPIC never releases an invoice payment early: Cancel comes once its time runs out, as
    // the Invoice block says; a withdrawn one offers Cancel there.
    final invoiceHold = paidInvoice != null &&
        (paidInvoice.status == InvoiceStatus.withdrawn ||
            now.difference(DateTime.fromMillisecondsSinceEpoch(tx.createdAtUnix * 1000)) < invoiceExpiry);
    final cancellable = tx.cancellable && tx.id != null && !issued && !invoiceHold;
    // An incoming payment this wallet signed: for receiveCancelHold after, and while its sender
    // reports it posted, Cancel stays away and one line says why (incomingCancelOf).
    final incoming = incomingCancelOf(tx, now: now);
    final cancel = cancellable && incoming.offered && !_onNetwork;
    final cancelHeld = cancellable && !incoming.offered;
    _tickWhile(cancelHeld && !incoming.senderReportsPosted);
    // What the status card offers beside the status.
    final actions = stuck || (tx.undelivered && tx.transport == 'epicbox') || tx.releasable || cancel || cancelHeld;
    return SlotScaffold(
      appBar: AppBar(
        title: Text(switch (withdrawal) {
          final w? => l.reqWithdrawalFrom(w.name),
          null => txHeading(l, tx, contactName: name),
        }),
      ),
      idle: _busy || home.isLoading
          ? SlotProgress(label: l.txDetailsWorking)
          : null,
      body: ScreenBody(
        children: [
          Row(
            children: [
              TxIcon(tx: tx, tip: tip),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: hidden ? l.txDetailsAmountHidden : null,
                      excludeSemantics: hidden,
                      child: Text(
                        signedEpic(l, tx, hidden: hidden, exact: true),
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
          // A withdrawal's own block below says where it stands: the card keeps only what
          // the user can do about it (Cancel, Send again, Release).
          if (!ownSteps || actions) ...[
            const SizedBox(height: 16),
            Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!ownSteps) ...[
                    TxStatusChip(tx: tx, tip: tip),
                    const SizedBox(height: 8),
                    Text(txExplanation(l, tx, tip, now: now, target: target, mailbox: mailboxName != null)),
                    // Waiting for a paired contact's answer: its relay silent, or its keys
                    // changed meanwhile.
                    if (mailboxWaiting && mailboxPairing != null && mailboxPairing.state == PairingState.keysChanged) ...[
                      const SizedBox(height: 12),
                      PairEdgeNotice(
                        tone: BadgeTone.warn,
                        title: l.contactKeysChangedTitle(mailboxName),
                        body: l.contactKeysChangedBody,
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: mailboxPairing.id, recheck: true)),
                            ),
                            child: Text(l.noticeCheckWords),
                          ),
                        ],
                      ),
                    ] else if (mailboxWaiting && (mailboxPairing?.relayDown ?? false)) ...[
                      const SizedBox(height: 12),
                      PairEdgeNotice(
                        tone: BadgeTone.warn,
                        title: l.contactRelayDownTitle(mailboxName),
                        body: l.contactRelayDownBody,
                      ),
                    ],
                    if (txTimeline(
                      l,
                      tx,
                      tip,
                      target: target,
                      now: now,
                      mailbox: mailboxName == null
                          ? null
                          : (
                              name: mailboxName,
                              relay: mailboxPairing?.homeRelay ?? '',
                              paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
                            ),
                    ) case final steps?) ...[
                      const SizedBox(height: 16),
                      StatusTimeline(steps: steps),
                    ],
                  ],
                  if (ttl != null) ...[
                    const SizedBox(height: 8),
                    Text(ttl, style: theme.textTheme.bodySmall),
                  ],
                  // The explanation above says it is not on the network.
                  if (stuck) ...[
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
                  // HTTP and Tor sends are sent again from the desktop only.
                  if (tx.undelivered && tx.transport == 'epicbox') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.send),
                        label: Text(l.txDetailsSendAgain),
                        onPressed: _busy ? null : () => _sendAgain(tx),
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
                  // A request this wallet sent is withdrawn in its own block, which keeps
                  // its state; a plain cancel would not.
                  if (cancel) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      // A send's Cancel is the way out of waiting; a receive's is a tidy-up
                      // for a payment the sender never posted, so a quieter button.
                      child: outgoing
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(l.txDetailsCancelPayment),
                              onPressed: _busy ? null : () => _cancel(tx),
                            )
                          : TextButton.icon(
                              key: txDetailsCancelReceiveKey,
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(l.txDetailsCancelPayment),
                              onPressed: _busy ? null : () => _cancel(tx),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        outgoing
                            ? l.sendCancelPossibleWhileWaiting
                            : '${acceptedAgoText(l, incoming.signedAgo)} ${l.txDetailsCancelOffered}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  // Inside the hold, or while the sender reports it posted: no button, the
                  // line says when Cancel comes (receiveCancelHold).
                  if (cancelHeld) ...[
                    const SizedBox(height: 8),
                    Text(
                      incoming.senderReportsPosted
                          ? l.txDetailsCancelWhileReported
                          : '${acceptedAgoText(l, incoming.signedAgo)} ${l.txDetailsCancelHold(incoming.holdMinutesLeft)}',
                      key: txDetailsCancelHoldKey,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ],
          // The invoice this payment paid, if any (I-03).
          PaidInvoiceBlock(
            tx: tx,
            onCancel: _busy || tx.id == null ? null : () => _cancel(tx),
          ),
          // The request this wallet sent, if it is one (I-06).
          IssuedInvoiceBlock(tx: tx),
          // A withdrawal a paired exchange sent (SPEC 2.8).
          WithdrawalBlock(tx: tx),
          if (tx.source != TxSource.wallet) ...[
            const SizedBox(height: 8),
            _SourceNote(source: tx.source),
          ],
          // Only a payment a scan found takes a typed sender, method and note.
          if (tx.source == TxSource.restored)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                tx.manualFields.any((f) => f != ManualField.label)
                    ? Icons.edit_outlined
                    : Icons.add,
              ),
              title: Text(
                tx.manualFields.any((f) => f != ManualField.label)
                    ? l.txEditEdit
                    : l.txEditAdd,
                style: theme.textTheme.labelLarge,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : () => _editDetails(tx),
            ),
          _LabelTile(tx: tx),
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
          if (tx.source == TxSource.restored && tx.transport != null)
            _DetailRow(
              label: l.sendMethodLabel,
              value: txMethodWord(l, tx.transport),
              tag: tx.manualFields.contains(ManualField.transport)
                  ? ManualTag(editedAtUnix: tx.manualEditedAtUnix)
                  : null,
            ),
          // A withdrawal names the paired exchange, never its address (RFC C-21).
          if (withdrawal != null)
            WithdrawalFromRow(pairingId: withdrawal.slate.pairingId, name: withdrawal.name)
          else if (counterparty != null)
            _CounterpartyRow(
              label: outgoing
                  ? l.txDetailsSentTo
                  : tx.isRequest
                  ? l.txDetailsRequestedFrom
                  : l.txDetailsReceivedFrom,
              address: counterparty,
              name: name,
              // An invoice is paid again by a new invoice, not a send to its address (PAIR-AND-18).
              canSendAgain: outgoing && tx.status == TxStatus.confirmed && paidInvoice == null,
              tag: tx.manualFields.contains(ManualField.counterparty)
                  ? ManualTag(editedAtUnix: tx.manualEditedAtUnix, from: true)
                  : null,
            )
          // Through the pairing: the method and the contact, no address (DESIGN 1.2).
          else if (mailboxName != null) ...[
            _DetailRow(label: l.sendMethodLabel, value: MethodIcons.fullName(l, MethodKind.epicbox)),
            _DetailRow(
              label: outgoing ? l.txDetailsSentTo : l.txDetailsReceivedFrom,
              value: '$mailboxName\n${l.sendRecipientPairing(mailboxName)}',
            ),
          ],
          if (fee != null && outgoing)
            _DetailRow(
              label: l.txDetailsFee,
              value: shownEpic(l, fee, hidden: hidden, exact: true),
            ),
          if (theirMessage != null)
            _DetailRow(
              label: outgoing
                  ? l.txDetailsMessageFromRecipient
                  : l.txDetailsMessageFromSender,
              value: theirMessage,
            ),
          if (ownMessage != null)
            _DetailRow(label: l.txDetailsYourMessage, value: ownMessage),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: _TitleWithTag(
              l.txDetailsPrivateNoteLabel,
              tag: tx.manualFields.contains(ManualField.note)
                  ? ManualTag(editedAtUnix: tx.manualEditedAtUnix)
                  : null,
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
          // Advanced › Technical details shows the rows; without it a small "More" shows them
          // for this view only (the switch stays off). Send feedback carries the slate id for
          // support either way.
          if (!AdvancedOptions.has(context, AdvancedFeature.technicalDetails) &&
              !_more)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: txDetailsMoreKey,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => setState(() => _more = true),
                child: Text(l.txDetailsMore),
              ),
            )
          else
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: true,
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
  const _DetailRow({
    required this.label,
    required this.value,
    this.copy,
    this.tag,
  });

  final String label;
  final String value;

  /// "Added by you", after the title, for a value the user typed.
  final Widget? tag;

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
      title: _TitleWithTag(label, tag: tag),
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
    this.tag,
  });

  final String label;

  /// "Added by you", after the title, for a sender the user typed.
  final Widget? tag;
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
          title: _TitleWithTag(label, tag: tag),
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
                  onPressed: () =>
                      showShellTab(context, ShellTab.send, recipient: address),
                ),
            ],
          ),
      ],
    );
  }
}

/// A list tile's title in the label style, with [tag] after it when there is one.
class _TitleWithTag extends StatelessWidget {
  const _TitleWithTag(this.text, {this.tag});

  final String text;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final tag = this.tag;
    if (tag == null) return Text(text, style: style);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(text, style: style),
        tag,
      ],
    );
  }
}

/// "Add label", or "Label" with its value: the field opens in the tile's place.
class _LabelTile extends StatelessWidget {
  const _LabelTile({required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final label = tx.label;
    const tagIcon = Icon(Icons.sell_outlined);
    return TxLabelEditor(
      tx: tx,
      style: theme.textTheme.bodyLarge,
      wrap: (field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            tagIcon,
            const SizedBox(width: 16),
            Expanded(child: field),
          ],
        ),
      ),
      idle: (context, edit) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: tagIcon,
        title: _TitleWithTag(
          label == null ? l.txLabelAdd : l.txLabel,
          tag: label == null
              ? null
              : ManualTag(editedAtUnix: tx.manualEditedAtUnix),
        ),
        subtitle: label == null ? null : Text(label),
        trailing: ExcludeSemantics(
          child: Icon(Icons.edit_outlined, size: 20, color: context.tokens.dim),
        ),
        onTap: edit,
      ),
    );
  }
}
