// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import '../name_service/pins.dart' show LinkPaymentRec;
import '../name_service/receipts.dart';
import '../recipient.dart' show parseRecipient;
import '../scan/scan_checks.dart' show CodeOrigin;
import '../scan/scan_router.dart' show PaymentRequest;
import '../trust/policy.dart' show MailboxSendStage, mailboxSendStage;
import 'receipt_line.dart';

import '../devices/device_ending.dart' show deviceEndingLine;
import '../devices/phone_devices.dart' show deviceServiceProvider, phoneDevices, watchHistory;
import 'devices/device_parts.dart' show confirmDeviceAction;
import 'package:flutter/material.dart';
import '../help/help_content.dart' show HelpAnchor, HelpId;
import 'help_screen.dart' show openHelp;
import 'cancel_dialog.dart';
import 'cancel_note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cancel_final.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'epic1/epic1_sealed.dart' show Epic1SealedBadge, phoneShowsSealed;
import '../network.dart' show EpicboxRelay;
import '../pairing_providers.dart' show PairNet, pairNetProvider, pairingByIdProvider, pairingSlateProvider;
import '../send_preflight.dart' show recipientRelay;
import '../settings.dart';
import '../settings_file/host_settings.dart' show hostSettings;
import '../wallet_service.dart';
import '../stall_retry.dart' show invoicePaymentStalled;
import '../watch_mode.dart' show BlockWait;
import '../contacts.dart' show contactsProvider;
import '../trust/contact_trust.dart' show MailboxResendOffer, mailboxResendOffer, relationshipOf, trustAddressOf;
import 'address_view.dart';
import 'common.dart';
import 'mailbox_resend.dart';
import 'finished_not_posted.dart';
import 'contacts_screen.dart' show ContactEditScreen;
import 'invoice_request_screen.dart' show IssuedInvoiceBlock;
import 'invoice_review_screen.dart' show PaidInvoiceBlock;
import 'pairing/pair_check.dart' show CheckWordsScreen;
import 'pairing/pairing_notices.dart' show pairingNewsOnScreen, pairingSlateNoticeTag;
import 'pairing/pairing_parts.dart' show PairEdgeNotice;
import 'pairing/withdrawal_block.dart';
import 'sent_from_other_wallet.dart';
import 'theme/advanced.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'method_names.dart';
import 'tx_edit_sheet.dart';
import 'tx_label.dart';
import 'inline_button.dart';
import '../amount.dart' show epicUnit;
import '../initials.dart' show nameInitials;
import '../network_gate.dart' show NetGate;
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_kv.dart';
import 'kit/kit_route_icon.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_steps.dart';
import 'kit/kit_support.dart';
import 'kit/kit_tokens.dart';
import 'payment_progress.dart';
import 'theme/epic1_mark.dart' show Epic1Glyph, Epic1Text;
import '../trust_ids.dart';
import 'via.dart';
import '../explorer_check.dart' show ExplorerHas, explorerHasBlock;

/// Minutes per Epic block, for rough "about N hours" estimates.
const int _minutesPerBlock = 1;

/// A link to the payment's block in the explorer (`[explorer] block` of `app-config.toml`),
/// once it is on chain. Null before confirmation, or when no explorer is configured.
String? explorerUrl(Chain chain, TxEntry tx) {
  if (tx.status != TxStatus.confirmed) return null;
  final height = tx.blockHeight;
  return height == null ? null : hostSettings.explorerBlock(height.toInt());
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
      CancelReason.user => l.phoneTxCancelledByUser,
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
  BlockWait wait = BlockWait.none,
  bool? cancelFinal,
}) {
  final n = txConfirmations(tx, tip);
  final height = tx.blockHeight;
  final outgoing = txAmount(tx).outgoing;
  // Coins another wallet on this recovery phrase spent or received: only the chain shows it.
  if (tx.origin == TxOrigin.otherWallet) {
    if (!outgoing) return tx.deviceName != null ? l.txDetailsDeviceIn(tx.deviceName!) : l.txDetailsOtherWalletIn;
    // Only the node's answers show it so far: the next completed scan checks it.
    return tx.unverified ? '${l.txDetailsOtherWallet} ${l.txDetailsUnverified}' : l.txDetailsOtherWallet;
  }
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
    // The sender's word: the wallet clears it by itself (sender_cancel.dart).
    TxPhase.waitingSender when senderCancelled(tx) => l.txDetailsSenderCancelledWaiting,
    // Past its watch window and still in no block: why, in one calm line.
    TxPhase.waitingSender || TxPhase.confirming when height == null && wait == BlockWait.noNewBlock =>
      l.txWaitNoNewBlock,
    TxPhase.waitingSender || TxPhase.confirming when height == null && wait == BlockWait.notInBlock =>
      l.txWaitNotInBlock,
    TxPhase.waitingSender when now != null && senderReportsPosted(tx, now: now) =>
      l.txDetailsSenderPosted,
    TxPhase.waitingSender => l.txDetailsWaitingSender,
    TxPhase.waitingPayer => l.txDetailsWaitingPayer,
    // Finished, but the node refused it (android-17): it is not on the network.
    TxPhase.confirming when isPostElsewhere(tx) => l.txPostElsewhereKill,
    TxPhase.confirming when tx.repostable && finishedUnderKillKeys.contains(tx.key) => l.txPostElsewhereAfter,
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
    // A reward on the chain, locked until its maturity (the desktop's words).
    TxPhase.maturing => switch (rewardMaturityOf(tx)) {
      final maturity? => l.deskTxNowImmature(maturity),
      null => l.outputsWordImmature,
    },
    TxPhase.completed =>
      height == null
          ? l.txDetailsCompleted
          : l.txDetailsCompletedInBlock(groupDigits(l, height)),
    // The receiver refused it: the core cancelled it, whatever else is recorded.
    TxPhase.cancelled when receiverDeclined(tx) => l.txDetailsReceiverDeclined,
    // One the other side could have finished (cancel_final.dart): final once its coins were
    // spent again, by Cancel's spend back or a later payment. [cancelFinal] is null until known.
    // Release coins is such a cancel too: the same words, so a released send whose coins
    // stayed in place reads honestly after Stop waiting.
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
    TxPhase.cancelled when senderCancelled(tx) => l.txDetailsSenderCancelled,
    TxPhase.cancelled =>
      outgoing ? l.phoneTxCancelledByUser : l.phoneTxCancelledIncoming,
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

/// The "Technical details" row inside the More sheet.
const Key txDetailsTechnicalKey = ValueKey('tx-details-technical');

/// The receive's Cancel, once its hold is over, and the line that stands in for it before.
const Key txDetailsCancelReceiveKey = ValueKey('tx-details-cancel-receive');
const Key txDetailsCancelHoldKey = ValueKey('tx-details-cancel-hold');

/// The details' Message rows (the other side's, this wallet's) and the Private note row.
const Key txTheirMessageKey = ValueKey('tx-their-message');
const Key txOwnMessageKey = ValueKey('tx-own-message');
const Key txPrivateNoteKey = ValueKey('tx-private-note');

/// Everything known about one transaction, with its note, contact and cancel.
class TxDetailsScreen extends ConsumerStatefulWidget {
  const TxDetailsScreen({super.key, required this.txKey});

  /// [TxEntry.key] of the transaction to show.
  final String txKey;

  @override
  ConsumerState<TxDetailsScreen> createState() => _TxDetailsScreenState();
}

class _TxDetailsScreenState extends ConsumerState<TxDetailsScreen> {
  /// The steps of a finished payment are open.
  bool _stepsOpen = false;

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
    final note = await showKitSheet<String>(
      context: context,
      builder: (sheet) => _NoteSheet(initial: tx.note ?? ''),
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

  /// Unlocks the coins of a send the network never took, once the user chose how: Cancel for
  /// sure also spends them back to this wallet, Stop waiting only unlocks them (cancel_dialog.dart).
  Future<void> _release(TxEntry tx) async {
    final session0 = ref.read(sessionProvider);
    // What moving the coins back costs, on its button; without it the button has no figure.
    final fee = session0 == null ? null : await spendBackFeeOf(session0, tx);
    if (!mounted) return;
    final l0 = context.l10n;
    final choice = await showCancelChoices(
      context,
      title: l0.txDetailsReleaseTitle,
      body: l0.txDetailsReleaseBody,
      anchor: HelpAnchor.sending,
      keepLabel: l0.txDetailsReleaseKeepWaiting,
      fee: fee,
    );
    if (!choice.cancels || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      // The network refused it, but a copy could still reach it: the coins go back to this
      // wallet as with Cancel (cancel_final.dart).
      final result = await ref.read(cancelFinalProvider).release(session, tx, spendBack: choice.spendBack);
      if (!mounted) return;
      final l = context.l10n;
      _showMessage(
        switch (result) {
          CancelResult.cancelled => l.txDetailsFundsReleased,
          CancelResult.spentBack || CancelResult.spendBackPending => l.txDetailsFundsReleased,
          CancelResult.stoppedWaiting => l.txDetailsStoppedWaiting,
          CancelResult.alreadyPaid => l.errorPaymentAlreadyWentThrough,
        },
        // Calm, never a warning: a retry or a payment left open is
        // information, not alarm.
        level: switch (result) {
          CancelResult.spendBackPending || CancelResult.stoppedWaiting || CancelResult.alreadyPaid => NoticeLevel.info,
          _ => NoticeLevel.success,
        },
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
    // A request this wallet paid: the issuer holds a copy it can finish, so the words differ.
    final paidRequest = !receive &&
        (tx.flow == TxFlow.invoice || (tx.slateId != null && ref.read(paidInvoiceProvider(tx.slateId!)).value != null));
    // A send both wallets signed: a copy could still reach the network. Either way the user
    // picks Move coins back (spent back, for a fee) or the free Unlock coins
    // (cancel_dialog.dart); a plain cancel has one free choice.
    final signedSend = !receive && !paidRequest && cancelSpendsBack(tx);
    final CancelChoice choice;
    if (paidRequest || signedSend) {
      final session0 = ref.read(sessionProvider);
      final fee = session0 == null ? null : await spendBackFeeOf(session0, tx);
      if (!mounted) return;
      final l0 = context.l10n;
      choice = await showCancelChoices(
        context,
        title: l0.txDetailsCancelTitle,
        body: paidRequest ? l0.txDetailsCancelRequestBody : l0.txDetailsCancelNotPostedBody,
        anchor: paidRequest ? HelpAnchor.requests : HelpAnchor.sending,
        keepLabel: l0.txDetailsCancelKeep,
        fee: fee,
      );
    } else {
      final l0 = context.l10n;
      final confirmed = await showPlainCancel(
        context,
        title: l0.txDetailsCancelTitle,
        body: receive ? l0.txDetailsCancelReceiveBody : l0.txDetailsCancelSendBody,
        anchor: receive ? HelpAnchor.receiving : HelpAnchor.sending,
        keepLabel: l0.txDetailsCancelKeep,
        cancelLabel: l0.txDetailsCancelPayment,
      );
      choice = confirmed ? CancelChoice.cancelForSure : CancelChoice.keep;
    }
    if (!choice.cancels || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(cancelFinalProvider).cancel(session, tx, spendBack: choice.spendBack);
      // The linked devices free its coins at once, not at the next tick.
      unawaited(ref.read(deviceServiceProvider)?.announceNow());
      if (!mounted) return;
      final l = context.l10n;
      _showMessage(
        switch (result) {
          CancelResult.cancelled => l.txDetailsPaymentCancelled,
          CancelResult.spentBack || CancelResult.spendBackPending => l.txDetailsPaymentCancelled,
          CancelResult.stoppedWaiting => l.txDetailsStoppedWaiting,
          CancelResult.alreadyPaid => l.errorPaymentAlreadyWentThrough,
        },
        level: switch (result) {
          CancelResult.spendBackPending || CancelResult.stoppedWaiting || CancelResult.alreadyPaid => NoticeLevel.info,
          _ => NoticeLevel.success,
        },
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

  /// Cancel and send to their public Epicbox address for a payment made from a payment link nobody answered: one
  /// confirm, the ordinary cancel (inputs unlocked, a late answer refused), then Send opens with
  /// the amount, to the payee's saved contact address when there is one, else empty.
  Future<void> _resendLink(TxEntry tx, LinkPaymentRec rec, String name) async {
    final l = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.mailboxResendTitle),
        content: Text(l.linkResendBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.mailboxKeepWaiting)),
          FilledButton(
            key: mailboxResendConfirmKey,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.mailboxResendAction),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final contacts = ref.read(contactsProvider).value ?? const <Contact>[];
    final address = contactEpicboxFor(rec, contacts.map((c) => c.epicbox));
    setState(() => _busy = true);
    try {
      await ref.read(cancelFinalProvider).cancel(session, tx, spendBack: false);
      unawaited(ref.read(deviceServiceProvider)?.announceNow());
      if (!mounted) return;
      ref
          .read(sendRecipientProvider.notifier)
          .handRequest(PaymentRequest(recipient: parseRecipient(address ?? ''), amount: rec.amount), CodeOrigin.link);
      showShellFlow(context, ShellFlow.send);
    } catch (error) {
      if (!mounted) return;
      _showMessage(describeError(context.l10n, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Cancel and send to their public Epicbox address (trust policy, an unanswered mailbox send): the waiting send
  /// is cancelled through the ordinary cancel, then an ordinary Epicbox send of the same amount
  /// and message goes to [address], the contact's Epicbox address. One confirm first; two rows
  /// stay in the history, so the details close on the list.
  Future<void> _resendByEpicbox(TxEntry tx, String name, String address) async {
    if (!await confirmCancelAndSendByEpicbox(context, name) || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final minimum = ref.read(countedConfirmationsProvider);
    final (:amount, outgoing: _) = txAmount(tx);
    final message = messageBy(tx.messages, SlateRole.sender);
    setState(() => _busy = true);
    try {
      await ref.read(cancelFinalProvider).cancel(session, tx, spendBack: false);
      // The linked devices free its coins at once, not at the next tick.
      unawaited(ref.read(deviceServiceProvider)?.announceNow());
      await session.sendEpicbox(amount: amount, minimumConfirmations: minimum, address: address, message: message);
      if (!mounted) return;
      _showMessage(context.l10n.mailboxResent, level: NoticeLevel.success);
      await _reload();
      if (mounted) await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(describeError(context.l10n, error), level: NoticeLevel.error);
      await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final home = ref.watch(homeProvider);
    final tx = watchHistory(ref, home.value?.transactions ?? const <TxEntry>[])
        .where((t) => t.key == widget.txKey)
        .firstOrNull;
    if (tx == null) {
      return SlotScaffold(
        idle: home.isLoading ? SlotProgress(label: l.txDetailsLoading) : null,
        centered: !home.isLoading,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitPageHeader(
                    backLabel: l.historyTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                    backId: TrustIds.payBack,
                  ),
                  Expanded(
                    child: home.isLoading
                        ? const SizedBox.shrink()
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: home.hasError
                                  ? ErrorText(describeError(l, home.error!))
                                  : Text(l.txDetailsGone, textAlign: TextAlign.center),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Another linked device's payment ("Sent from Desktop"): the same screen as every other
    // payment (UP-007), with what that device told this one and the chain's view; its coins
    // held here can be released from the status card. No label or note: there is no record
    // of it on this device to keep them on.
    final device = tx.origin == TxOrigin.linkedDevice;
    final deviceName = tx.deviceName ?? '';
    final deviceView = device ? ref.watch(phoneDevices.view) : null;
    final hold = deviceView?.book.holds
        .where((h) => h.state.holds && h.slateId == tx.slateId && h.commitments.any(tx.spentCommits.contains))
        .firstOrNull;

    final display = amountDisplay(ref);
    final hidden = display.hidden;
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    // A mining reward: the blocks to go until it can be spent, from its output's lock height.
    final rewardBlocks = rewardBlocksLeft(tx, tip);
    final rewardMaturity = rewardMaturityOf(tx);
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
    // The paired contact behind the mailbox and its Epicbox address: Cancel and send to their public Epicbox address
    // needs one (trust policy, mailboxResendOffer).
    final mailboxContact = mailboxPairing?.contactId == null
        ? null
        : (ref.watch(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == mailboxPairing!.contactId).firstOrNull;
    final resendAddress = trustAddressOf(mailboxContact?.epicbox, mailboxPairing);
    final name = txPartyName(ref, tx) ?? mailboxName;
    final fiat = tx.status == TxStatus.cancelled
        ? null
        : phoneFiat(l, amount, display, approx: true);
    final ttl = ttlLine(l, tx, tip);
    final now = ref.watch(clockProvider)();
    final resendOffer = mailboxWaiting && mailboxPairing != null && txAmount(tx).outgoing
        ? mailboxResendOffer(
            relationshipOf(inContacts: mailboxContact != null, epicboxAddress: mailboxContact?.epicbox, pairing: mailboxPairing),
            txSentAt(tx),
            now,
          )
        : null;
    // A payment made from a payment link: its payee's silent rows and the optional receipt.
    final linkRec = tx.slateId == null ? null : ref.watch(linkPaymentProvider(tx.slateId!));
    final linkName = linkRec == null ? null : linkPayeeName(ref.watch(nameServiceReceiptsProvider), linkRec);
    final linkOffer = linkRec != null && mailboxName == null && outgoing && tx.status == TxStatus.awaitingRecipient && !tx.undelivered
        ? switch (mailboxSendStage(txSentAt(tx), now)) {
            MailboxSendStage.waiting => null,
            final stage => MailboxResendOffer(stage: stage, resend: true),
          }
        : null;
    final linkPosted = tx.finalizedAtUnix != null &&
        (tx.status == TxStatus.awaitingConfirmation || tx.status == TxStatus.confirmed);
    final linkReceipt = linkRec != null &&
        outgoing &&
        mailboxName == null &&
        (tx.status == TxStatus.awaitingRecipient || linkPosted);
    final wait = tip == null ? BlockWait.none : ref.read(blockWatchProvider).waitOf(tx, now: now, tip: tip);
    final stuck = isStuck(tx);
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
    final issued =
        tx.isRequest ||
        switch (tx.slateId) {
          final slate? => ref.watch(issuedInvoiceProvider(slate)).value != null,
          null => false,
        };

    // A withdrawal from a paired exchange has its own steps (WithdrawalBlock).
    final withdrawal = withdrawalOf(ref, tx);
    // An invoice this payment paid (PaidInvoiceBlock): a paired contact's has its own card and
    // steps, so the card here keeps only what the user can do.
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
    // A cancelled payment the other side could have finished: whether its coins were spent
    // again, from the outputs (null while they load).
    final cancelFinalNow = cancelledMayComplete(tx)
        ? switch (ref.watch(walletOutputsProvider).value) {
            final outputs? => cancelFinal(tx, outputs),
            null => null,
          }
        : null;
    _tickWhile(cancelHeld && !incoming.senderReportsPosted);
    final t = context.tokens;
    final paused = ref.watch(pairNetProvider) == PairNet.epicboxOff;
    // The steps of a payment this wallet made or received; none for the other kinds (a status
    // line instead), and none where a block of its own says where it stands.
    final progress = ownSteps
        ? null
        : paymentProgress(
            l,
            tx,
            tip,
            now: now,
            who: name,
            target: target,
            reserved: tx.kind == TxKind.sent ? epicText(l, tx.amountDebited) : null,
            wait: wait,
            paused: paused,
            killSwitch: NetGate.killSwitch,
          );
    final via = paymentVia(tx);
    // What the status area offers beside the status.
    final ownServer = ownEpicboxServer(ref);
    final who = withdrawal?.name ??
        name ??
        (counterparty == null ? null : shortAddress(counterparty, ownServer: ownServer));
    final canSendAgain = outgoing &&
        tx.status == TxStatus.confirmed &&
        paidInvoice == null &&
        withdrawal == null &&
        counterparty != null;

    // The notices and cards of a payment that waits on a paired contact or a payment link.
    final notices = <Widget>[
      if (!ownSteps) ...[
        // Waiting for a paired contact's answer: its relay silent, or its keys changed meanwhile.
        if (mailboxWaiting && mailboxPairing != null && mailboxPairing.state == PairingState.keysChanged)
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
          )
        else if (mailboxWaiting && (mailboxPairing?.relayDown ?? false))
          PairEdgeNotice(
            tone: BadgeTone.warn,
            title: l.contactRelayDownTitle(mailboxName),
            body: l.contactRelayDownBody,
          )
        // Unanswered for a day, or gone from the relay after seven: Cancel and send by Epicbox,
        // when the contact has an Epicbox address.
        else if (resendOffer != null)
          MailboxResendCard(
            offer: resendOffer,
            name: mailboxName ?? '',
            busy: _busy,
            onResend: resendAddress == null ? null : () => _resendByEpicbox(tx, mailboxName ?? '', resendAddress),
            onKeepWaiting: () => Navigator.of(context).maybePop(),
          ),
        if (linkOffer != null && linkRec != null)
          MailboxResendCard(
            offer: linkOffer,
            name: linkName ?? l.linkPayeeLead,
            busy: _busy,
            onResend: () => _resendLink(tx, linkRec, linkName ?? l.linkPayeeMid),
            onKeepWaiting: () => Navigator.of(context).maybePop(),
          ),
        if (linkReceipt) ReceiptLine(slateId: tx.slateId!, posted: linkPosted, finalizedAtUnix: tx.finalizedAtUnix),
      ],
    ];

    // The status: the steps, or one line when there are none to show.
    final Widget statusArea;
    // The frame's gap above the status, less the 8 the route chip's tap target adds: 22 under the
    // chip of a finished payment, 18 above the steps of an open one.
    var statusGap = 14.0;
    if (ownSteps) {
      statusArea = const SizedBox.shrink();
    } else if (progress != null && progress.completed) {
      final doneAt = localTime(blockTime ?? tx.timeUnix);
      // "2 Nov, 20:31" within the year, the full date and time before.
      final done = doneAt.year == now.year
          ? l.dateWithTime(localDayMonth(l, doneAt), localClock(l, doneAt))
          : formatDateTime(l, doneAt);
      statusArea = KitGroup(
        children: [
          KitRow(
            size: KitRowSize.settings,
            title: l.phonePayCompleted,
            leading: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.ok.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(KitIcons.check, size: 16, color: t.ok),
            ),
            // At large text the date wraps in its own room, so the row never runs out of width.
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(done, textAlign: TextAlign.end, style: KitType.body.copyWith(fontSize: 14, color: t.dim, height: 1.3)),
                  ),
                  const SizedBox(width: 6),
                  Icon(_stepsOpen ? KitIcons.chevronUp : KitIcons.chevronDown, size: 18, color: t.faint),
                ],
              ),
            ),
            onTap: () => setState(() => _stepsOpen = !_stepsOpen),
            semanticsId: TrustIds.payCompleted,
            semanticsLabel: l.phonePayCompletedOn(done),
          ),
          if (_stepsOpen) KitSteps(steps: progress.steps, card: false, semanticsId: TrustIds.paySteps),
          if (phoneShowsSealed(ref, tx))
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Kit.rowSettings),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(width: 32, height: 32, child: Center(child: Epic1Glyph(size: 19, columns: 5, color: t.accentText))),
                    const SizedBox(width: 12),
                    Expanded(child: Epic1Text(l.deskE1Sealed, style: KitType.rowTitle.copyWith(color: t.text))),
                  ],
                ),
              ),
            ),
        ],
      );
    } else if (progress != null) {
      statusGap = 10;
      statusArea = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Before the payment is on the network, one gold line answers the worry.
          KitSteps(
            steps: progress.steps,
            semanticsId: TrustIds.paySteps,
            footer: progress.beforeNetwork
                ? KitKvRow(
                    label: l.phonePayNever,
                    labelColor: t.accentText,
                    chevron: true,
                    onTap: () => _showNever(outgoing),
                    semanticsId: TrustIds.payNever,
                  )
                : null,
          ),
          // A send that never went out, or waits too long, says what to do and which relay was
          // silent: the step only names the state.
          if (txPhase(tx, tip, target: target) == TxPhase.waitingRecipient &&
              (tx.undelivered || invoicePaymentStalled(tx, now) || daysWaitingTooLong(tx, now) != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 10, Kit.gutter + 4, 0),
              child: Text(
                txExplanation(l, tx, tip, now: now, target: target, mailbox: mailboxName != null, wait: wait),
                style: KitType.body.copyWith(color: t.dim),
              ),
            ),
        ],
      );
    } else {
      statusArea = Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: _PlainCard(
          children: [
            if (phoneShowsSealed(ref, tx))
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [TxStatusChip(tx: tx, tip: tip), const Epic1SealedBadge()],
              )
            else
              TxStatusChip(tx: tx, tip: tip),
            const SizedBox(height: 8),
            Text(
              device
                  ? (hold != null ? l.txDeviceStatusHeld(deviceName) : l.txDeviceStatusMadeOn(deviceName))
                  : rewardBlocks != null && rewardMaturity != null
                  ? l.deskTxNowImmature(rewardMaturity)
                  : txExplanation(l, tx, tip, now: now, target: target, mailbox: mailboxName != null, wait: wait, cancelFinal: cancelFinalNow),
              style: KitType.body.copyWith(color: t.text),
            ),
            if (rewardBlocks != null) ...[
              const SizedBox(height: 8),
              Text(l.deskTxStepBlocksToGo(rewardBlocks), style: KitType.rowSub.copyWith(color: t.dim)),
            ],
            if (device && tx.deviceEnding != null)
              if (deviceEndingLine(l, tx.deviceEnding!, deviceName, tx.deviceWhy) case final line?) ...[
                const SizedBox(height: 8),
                Text(line, style: KitType.rowSub.copyWith(color: t.dim)),
              ],
            if (tx.origin == TxOrigin.otherWallet && tx.deviceName == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: InlineTextButton(
                  key: const ValueKey('tx-other-wallet-help'),
                  onPressed: () => openHelp(context, HelpId.otherWallet),
                  child: Text(l.txOtherWalletMore),
                ),
              ),
            if (txTimeline(
              l,
              tx,
              tip,
              target: target,
              now: now,
              mailbox: mailboxName == null
                  ? null
                  : (name: mailboxName, relay: mailboxPairing?.homeRelay ?? '', paused: paused),
            ) case final steps?) ...[
              const SizedBox(height: 16),
              StatusTimeline(steps: steps),
            ],
          ],
        ),
      );
    }

    // The rows under the status: messages, note, label, fee, and the sheet with the rest.
    final labelInMore = progress != null && !progress.completed;
    final noteRow = KitKvRow(
      key: txPrivateNoteKey,
      label: l.phonePayNote,
      value: note ?? l.phonePayAddNote,
      valueColor: note == null ? t.accentText : null,
      onTap: _busy ? null : () => _editNote(tx),
      semanticsId: TrustIds.payNote,
    );
    final rows = <Widget>[
      if (theirMessage != null)
        KeyedSubtree(
          key: txTheirMessageKey,
          child: _FieldRow(
            title: l.txDetailsMessageFromSender,
            body: '$theirMessage\n${messageHint(l, incoming: !outgoing, bySender: !outgoing)}',
          ),
        ),
      if (ownMessage != null)
        KeyedSubtree(
          key: txOwnMessageKey,
          child: _FieldRow(
            title: l.txDetailsYourMessage,
            body: '$ownMessage\n${messageHint(l, incoming: !outgoing, bySender: outgoing)}',
          ),
        ),
      if (!device) noteRow,
      // The frame's open payment shows no Label row: the sheet of more details has it.
      if (!device && !labelInMore) _LabelRow(tx: tx),
      // Only a payment a scan found takes a typed sender, method and note.
      if (tx.source == TxSource.restored)
        KitRow(
          size: KitRowSize.settings,
          title: tx.manualFields.any((f) => f != ManualField.label) ? l.txEditEdit : l.txEditAdd,
          titleColor: tx.manualFields.any((f) => f != ManualField.label) ? null : t.accentText,
          chevron: true,
          onTap: _busy ? null : () => _editDetails(tx),
        ),
      if (fee != null && outgoing)
        KitKvRow(label: l.phonePayFee, value: shownEpic(l, fee, hidden: hidden, exact: true), mono: true)
      else if (tx.origin == TxOrigin.otherWallet && outgoing)
        // The other wallet paid it; this wallet only saw the coins leave.
        KitKvRow(label: l.phonePayFee, value: l.txDetailsNotKnown),
      KitKvRow(
        key: txDetailsMoreKey,
        label: l.phonePayMore,
        chevron: true,
        onTap: () => _showMore(tx, name: name, mailboxName: mailboxName, withdrawal: withdrawal, via: via, label: labelInMore && !device),
        semanticsId: TrustIds.payMore,
      ),
    ];

    final buttons = <Widget>[
      // The explanation says it is not on the network.
      if (stuck && !isPostElsewhere(tx))
        KitButton(
          label: finishedUnderKillKeys.contains(tx.key) ? l.txPostNow : l.txDetailsBroadcastAgain,
          icon: Icons.cell_tower,
          kind: KitButtonKind.quiet,
          onPressed: _busy ? null : () => _repost(tx),
          semanticsId: TrustIds.payRepost,
        ),
      if (stuck && !isPostElsewhere(tx) && finishedUnderKillKeys.contains(tx.key)) FinishedPaymentButtons(tx: tx, primarySave: false),
      // HTTP and Tor sends are sent again from the desktop only.
      if (tx.undelivered && tx.transport == 'epicbox')
        KitButton(
          label: l.txDetailsSendAgain,
          icon: Icons.send,
          kind: KitButtonKind.quiet,
          onPressed: _busy ? null : () => _sendAgain(tx),
          semanticsId: TrustIds.paySendAgainUndelivered,
        ),
      // The other device's coins held here: let them go.
      if (hold != null)
        KitButton(
          label: l.devicesRelease,
          icon: Icons.lock_open,
          kind: KitButtonKind.quiet,
          onPressed: _busy
              ? null
              : () async {
                  final yes = await confirmDeviceAction(
                    context,
                    title: l.devicesReleaseTitle,
                    body: l.devicesReleaseBody(deviceName),
                    action: l.devicesRelease,
                    risky: true,
                    icon: Icons.lock_open_outlined,
                  );
                  if (!yes || !context.mounted) return;
                  await ref.read(deviceServiceProvider)?.releaseByHandOf(hold.deviceId, hold.slateId);
                  ref.read(noticeProvider.notifier).show(l.devicesReleased, level: NoticeLevel.success);
                },
          semanticsId: TrustIds.payDeviceRelease,
        ),
      if (tx.releasable) ...[
        Text(l.txDetailsRefusedBody, style: KitType.body.copyWith(color: t.dim)),
        KitButton(
          label: l.txDetailsReleaseFunds,
          icon: Icons.lock_open,
          kind: KitButtonKind.quiet,
          onPressed: _busy ? null : () => _release(tx),
          semanticsId: TrustIds.payRelease,
        ),
      ],
      // A request this wallet sent is withdrawn in its own block, which keeps its state; a plain
      // cancel would not.
      if (cancel)
        KeyedSubtree(
          key: outgoing ? null : txDetailsCancelReceiveKey,
          child: KitButton(
            label: l.txDetailsCancelPayment,
            kind: KitButtonKind.danger,
            onPressed: _busy ? null : () => _cancel(tx),
            semanticsId: TrustIds.payCancel,
          ),
        ),
      // Inside the hold, or while the sender reports it posted: no button, the line says when
      // Cancel comes (receiveCancelHold).
      if (cancelHeld)
        CancelNote(
          key: txDetailsCancelHoldKey,
          text: incoming.senderReportsPosted
              ? l.txDetailsCancelWhileReported
              : l.txDetailsCancelHold(incoming.holdMinutesLeft),
          anchor: HelpAnchor.receiving,
        ),
      if (canSendAgain)
        KitButton(
          label: l.txDetailsSendAgain,
          icon: KitIcons.send,
          kind: KitButtonKind.quiet,
          onPressed: () => showShellFlow(context, ShellFlow.send, recipient: counterparty),
          semanticsId: TrustIds.paySendAgain,
        ),
    ];

    return SlotScaffold(
      idle: _busy || home.isLoading ? SlotProgress(label: l.txDetailsWorking) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitPageHeader(
                  backLabel: l.historyTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  onHelp: () => showKitHelp(
                    context,
                    title: l.phonePayHelpTitle,
                    lines: [l.phonePayHelp1, l.phonePayHelp2, l.phonePayHelp3],
                    onMore: () => openHelp(context, outgoing ? HelpId.send : HelpId.receive),
                    sheetId: TrustIds.payHelpSheet,
                    moreId: TrustIds.payHelpMore,
                  ),
                  backId: TrustIds.payBack,
                  helpId: TrustIds.payHelp,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PayHero(
                          tx: tx,
                          name: withdrawal?.name ?? name,
                          who: who,
                          fiat: fiat,
                          hidden: hidden,
                          via: via,
                          onVia: via == null ? null : () => _showVia(tx, via, name: name),
                        ),
                        SizedBox(height: statusGap),
                        statusArea,
                        if (ttl != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 10, Kit.gutter + 4, 0),
                            child: Text(ttl, style: KitType.rowSub.copyWith(color: t.dim)),
                          ),
                        // Finished under Kill switch: save it or show the QR for a device that is online.
                        if (isPostElsewhere(tx) && !ownSteps)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0),
                            child: FinishedPaymentButtons(tx: tx),
                          ),
                        for (final notice in notices)
                          Padding(padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0), child: notice),
                        // The invoice this payment paid, if any (I-03).
                        PaidInvoiceBlock(tx: tx, onCancel: _busy || tx.id == null ? null : () => _cancel(tx)),
                        // The request this wallet sent, if it is one (I-06).
                        IssuedInvoiceBlock(tx: tx),
                        // A withdrawal a paired exchange sent.
                        WithdrawalBlock(tx: tx),
                        if (tx.source != TxSource.wallet)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0),
                            child: _SourceNote(source: tx.source),
                          ),
                        const SizedBox(height: 12),
                        KitGroup(dividerInset: Kit.dividerInsetPlain, children: rows),
                        // The end of the details of a row another wallet made: the quiet "link this
                        // device" offer goes here (Linked devices).
                        if (tx.origin == TxOrigin.otherWallet && tx.deviceName == null)
                          const Padding(padding: EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 0), child: SentFromOtherWalletOffer()),
                      ],
                    ),
                  ),
                ),
                // The frame's `.foot`: the buttons sit at the bottom, 6 apart, 34 above the edge.
                if (buttons.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Kit.gutter,
                      8,
                      Kit.gutter,
                      (34 - MediaQuery.viewPaddingOf(context).bottom).clamp(0.0, 34.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, b) in buttons.indexed) ...[if (i > 0) const SizedBox(height: 6), b],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Why a waiting payment is safe, and how to end it.
  Future<void> _showNever(bool outgoing) {
    final l = context.l10n;
    return showKitSheet<void>(
      context: context,
      builder: (sheet) => KitSheet(
        title: l.phonePayNever,
        primaryLabel: l.commonDone,
        primaryKind: KitButtonKind.quiet,
        onPrimary: () => Navigator.of(sheet).pop(),
        primaryId: TrustIds.payNeverDone,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            outgoing ? l.phonePayNeverSend : l.phonePayNeverReceive,
            style: KitType.body.copyWith(color: context.tokens.dim),
          ),
        ),
      ),
    );
  }

  /// What the route chip explains: how this payment travelled, and the other ways.
  Future<void> _showVia(TxEntry tx, Via via, {required String? name}) {
    final l = context.l10n;
    final outgoing = txAmount(tx).outgoing;
    final route = _routeName(l, via);
    final explanation = switch (via) {
      Via.epicbox => outgoing
          ? (name == null ? l.phonePayViaEpicboxOut : l.phonePayViaEpicboxOutNamed(name))
          : l.phonePayViaEpicboxIn,
      Via.link => l.phonePayViaEpic1,
      Via.inPerson || Via.qr => l.phonePayViaInPerson,
      Via.file => l.phonePayViaFile,
      Via.tor => l.phonePayViaTor,
      Via.http => l.phonePayViaHttp,
    };
    final others = [Via.epicbox, Via.link, Via.inPerson, Via.file, Via.tor].where((v) => v != via && !(v == Via.inPerson && via == Via.qr));
    String sub(Via v) => switch (v) {
      Via.epicbox => l.phonePayViaServer,
      Via.link => l.phonePayRouteSubEpic1,
      Via.inPerson || Via.qr => l.phonePayRouteSubInPerson,
      Via.file => l.phonePayRouteSubFile,
      Via.tor || Via.http => l.phonePayRouteSubTor,
    };
    final t = context.tokens;
    final host = via == Via.epicbox ? recipientRelay(tx.counterparty ?? '')?.label : null;
    return showKitSheet<void>(
      context: context,
      builder: (sheet) => KitSheet(
        primaryLabel: l.commonDone,
        primaryKind: KitButtonKind.quiet,
        onPrimary: () => Navigator.of(sheet).pop(),
        primaryId: TrustIds.payViaDone,
        actionsTop: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The frame's title row: the route's icon in gold, then the title.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Kit.rowSheet),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    KitIconWell.child(KitRouteIcon(via, size: 22, color: t.accentText)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          outgoing ? l.phonePayViaSent(route) : l.phonePayViaReceived(route),
                          style: KitType.sheetTitle.copyWith(color: t.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(explanation, style: KitType.rowSub.copyWith(color: t.dim, height: 1.45)),
            ),
            if (host != null) ...[
              const SizedBox(height: 14),
              KitGroup(
                onSheet: true,
                children: [
                  KitKvRow(
                    label: l.phonePayViaServer,
                    valueWidget: Text(host, style: KitType.rowAmount.copyWith(fontSize: 13.5, color: t.text, height: 1.3)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            KitGroupLabel(l.phonePayViaOther),
            KitGroup(
              onSheet: true,
              dividerInset: Kit.dividerInsetList,
              children: [
                for (final v in others)
                  KitRow(
                    size: KitRowSize.sheet,
                    compact: true,
                    title: _routeName(l, v),
                    subtitle: sub(v),
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(10)),
                      child: KitRouteIcon(v, size: 18),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The sheet with everything else about the payment.
  Future<void> _showMore(
    TxEntry tx, {
    required String? name,
    required String? mailboxName,
    required ({PairingSlate slate, String name})? withdrawal,
    required Via? via,
    required bool label,
  }) => showKitSheet<void>(
    context: context,
    builder: (sheet) => _MoreSheet(
      tx: tx,
      name: name,
      mailboxName: mailboxName,
      withdrawalName: withdrawal?.name,
      withdrawalPairingId: withdrawal?.slate.pairingId,
      via: via,
      label: label,
    ),
  );
}


/// How [tx] travelled, for the route chip and its explanation: an epic1 payment by its link or
/// in person, else by the transport it used; a payment through a pairing went by Epicbox. Null
/// when nothing says (a restored row, a mining reward).
Via? paymentVia(TxEntry tx) => switch (tx.epic1Via) {
  Epic1Via.inPerson => Via.inPerson,
  Epic1Via.link => Via.link,
  null => viaOfTransport(tx.transport) ?? (tx.pairingId != null ? Via.epicbox : null),
};

/// The name of a route, as the chip and the explanation say it.
String _routeName(AppLocalizations l, Via via) => switch (via) {
  Via.epicbox => l.phonePayRouteEpicbox,
  Via.link => l.phonePayRouteEpic1,
  Via.inPerson || Via.qr => l.phonePayRouteInPerson,
  Via.file => l.phonePayRouteFile,
  Via.tor => l.phonePayRouteTor,
  Via.http => l.phonePayRouteHttp,
};

/// The top of the payment page: the avatar, the exact amount, who it was with and the route chip.
class _PayHero extends StatelessWidget {
  const _PayHero({
    required this.tx,
    required this.name,
    required this.who,
    required this.fiat,
    required this.via,
    required this.onVia,
    required this.hidden,
  });

  final TxEntry tx;

  /// The contact's name, when there is one: its initials fill the avatar.
  final String? name;

  /// The name, or the short address, the line under the amount names.
  final String? who;
  final String? fiat;
  final Via? via;
  final VoidCallback? onVia;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final (:amount, :outgoing) = txAmount(tx);
    final cancelled = tx.status == TxStatus.cancelled;
    final initials = name == null || name!.isEmpty ? '' : nameInitials(name!, count: 2, phone: true);
    final color = cancelled ? t.txCancelled : (outgoing ? t.text : t.txReceived);
    final full = signedEpic(l, tx, hidden: hidden, exact: true);
    final split = !hidden && full.endsWith(epicUnit);
    final numberStyle = KitType.amountOnPage.copyWith(
      color: color,
      decoration: cancelled ? TextDecoration.lineThrough : null,
      decorationColor: color,
    );
    // `.hero .a`: the figure, then the small gold unit 10 further and 6 higher.
    final amountText = split
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(text: full.substring(0, full.length - epicUnit.length).trimRight(), style: numberStyle),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text(epicUnit, style: KitType.unit.copyWith(color: t.accentText), textScaler: TextScaler.noScaling),
                    ),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          )
        : Text(full, style: numberStyle, maxLines: 1, textAlign: TextAlign.center);
    final line = who != null
        ? (outgoing ? l.phonePayTo(who!) : l.phonePayFrom(who!))
        : txHeading(l, tx, contactName: name);
    return Padding(
      // `.hero` sits 6 under the nav: the header's own 6 without a title.
      padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
      child: Column(
        children: [
          // `.hero .av`: 48, radius 16, the initials 15; a thing that is not a person has an icon.
          ExcludeSemantics(
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(16)),
              child: initials.isEmpty
                  ? Icon(
                      tx.kind == TxKind.coinbase ? Icons.bolt_rounded : KitIcons.contact,
                      size: 24,
                      color: cancelled ? t.dim : t.accentText,
                    )
                  : Text(
                      initials,
                      style: KitType.initials.copyWith(color: cancelled ? t.dim : t.accentText, fontSize: 15),
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: hidden ? l.txDetailsAmountHidden : null,
            excludeSemantics: hidden,
            child: FittedBox(fit: BoxFit.scaleDown, child: amountText),
          ),
          const SizedBox(height: 10),
          Text(
            fiat == null ? line : '$line · $fiat',
            textAlign: TextAlign.center,
            style: KitType.body.copyWith(color: t.dim, height: 1.21),
          ),
          if (via != null) ...[
            // `.chip` margin 12, less the 8 the 44 tap target adds above the 28 pill.
            const SizedBox(height: 2),
            KitChip(
              _routeName(l, via!),
              leading: KitRouteIcon(via!),
              onTap: onVia,
              semanticsId: TrustIds.payRoute,
            ),
          ],
        ],
      ),
    );
  }
}

/// A card for the status of a payment without steps: the group's fill and edge.
class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.group,
        borderRadius: BorderRadius.circular(Kit.rGroup),
        border: Border.all(color: t.hair),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Kit.gutter),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

/// A row of a group with a title and a body that may take several lines (a message, a note, an
/// address): [KitRow] keeps one line.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.title,
    this.body,
    this.hint,
    this.trailing,
    this.onTap,
    this.semanticsId,
    this.bodyLines = 6,
  });

  final String title;
  final String? body;
  final String? hint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticsId;
  final int bodyLines;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Kit.rowSettings),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KitType.rowTitle.copyWith(color: t.text)),
                  if (body != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(body!, maxLines: bodyLines, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.dim)),
                    ),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(hint!, style: KitType.rowSub.copyWith(color: t.faint)),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
    return kitId(
      semanticsId,
      Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? Semantics(container: true, child: content)
            : Semantics(button: true, child: InkWell(onTap: onTap, child: content)),
      ),
    );
  }
}

/// "Add a label", or "Label" with its value: the field opens in the row's place.
class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final label = tx.label;
    return TxLabelEditor(
      tx: tx,
      style: KitType.body.copyWith(color: t.text),
      wrap: (field) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: field),
      idle: (context, edit) => KitKvRow(
        label: l.phonePayLabel,
        value: label ?? l.phonePayAddLabel,
        valueColor: label == null ? t.accentText : null,
        valueWidget: label != null && tx.manualFields.contains(ManualField.label)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, style: KitType.body.copyWith(height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  ManualTag(editedAtUnix: tx.manualEditedAtUnix, compact: true),
                ],
              )
            : null,
        onTap: edit,
        semanticsId: TrustIds.payLabel,
      ),
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
    final t = context.tokens;
    final text = switch (source) {
      TxSource.restored => l.txDetailsSourceRestored,
      TxSource.imported => l.txDetailsSourceImported,
      TxSource.wallet => '',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(KitIcons.info, size: 20, color: t.dim),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: KitType.rowSub.copyWith(color: t.dim))),
      ],
    );
  }
}

/// Asks for a note. Pops with the text, or null when cancelled.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initial});

  final String initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KitSheet(
      title: l.txDetailsNoteDialogTitle,
      primaryLabel: l.commonSave,
      onPrimary: () => Navigator.of(context).pop(_controller.text),
      primaryId: TrustIds.payNoteSave,
      secondaryLabel: l.commonCancel,
      onSecondary: () => Navigator.of(context).pop(),
      secondaryId: TrustIds.payNoteCancel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.txDetailsNoteLabel, helperText: l.txDetailsNoteHelper),
        ),
      ),
    );
  }
}

/// The sheet with everything else about the payment: who, how, when, the fee and the ids.
class _MoreSheet extends ConsumerStatefulWidget {
  const _MoreSheet({
    required this.tx,
    required this.name,
    required this.mailboxName,
    required this.withdrawalName,
    required this.withdrawalPairingId,
    required this.via,
    required this.label,
  });

  /// The Label row sits here when the page does not show it (a payment still open).
  final bool label;
  final TxEntry tx;
  final String? name;
  final String? mailboxName;
  final String? withdrawalName;
  final String? withdrawalPairingId;
  final Via? via;

  @override
  ConsumerState<_MoreSheet> createState() => _MoreSheetState();
}

class _MoreSheetState extends ConsumerState<_MoreSheet> {
  /// "Technical details" was tapped: the technical rows show for this view although the switch
  /// is off.
  bool _more = false;

  /// The block height the explorer had not reached when its link was copied.
  int? _behind;

  Future<void> _checkExplorer(int height) async {
    final has = await explorerHasBlock(height);
    if (mounted) setState(() => _behind = has == ExplorerHas.notYet ? height : null);
  }

  /// A row of the frame's kind (`.kv` with `.cp`): the shortened value and the copy mark at the end.
  Widget _copyKv(String title, String value, {required String notice, required String shown, String? id}) {
    final t = context.tokens;
    return KitKvRow(
      label: title,
      valueWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(shown, style: KitType.rowAmount.copyWith(color: t.text, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Icon(KitIcons.copy, size: 16, color: t.accentText),
        ],
      ),
      semanticsId: id,
      onTap: () => copyText(context, value, notice),
    );
  }

  Widget _copyRow(String title, String value, {required String notice, String? shown, String? hint, VoidCallback? after, String? id}) {
    final t = context.tokens;
    return _FieldRow(
      title: title,
      body: shown ?? value,
      bodyLines: 3,
      hint: hint,
      semanticsId: id,
      trailing: Icon(KitIcons.copy, size: 20, color: t.dim),
      onTap: () async {
        await copyText(context, value, notice);
        after?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final tx = widget.tx;
    final hidden = amountDisplay(ref).hidden;
    final (:amount, :outgoing) = txAmount(tx);
    final counterparty = tx.counterparty;
    final fee = tx.fee;
    final blockTime = tx.blockTimeUnix;
    final chain = ref.watch(walletConfigProvider)?.chain;
    final url = chain == null ? null : explorerUrl(chain, tx);
    final singleOutput = tx.outputCommits.length == 1;
    final technical = AdvancedOptions.has(context, AdvancedFeature.technicalDetails) || _more;
    final via = widget.via;
    final slate = tx.slateId;
    final coins = tx.outputCommits.length;

    // "Sent to" and its address sit above the rows, not in them (the frame's sheet).
    Widget? who;
    final live = ref.watch(homeProvider).value?.transactions.where((x) => x.key == tx.key).firstOrNull ?? tx;
    final rows = <Widget>[
      if (widget.label) _LabelRow(tx: live),
      // A withdrawal names the paired exchange, never its address (RFC C-21).
      if (widget.withdrawalPairingId != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: WithdrawalFromRow(pairingId: widget.withdrawalPairingId!, name: widget.withdrawalName ?? ''),
        )
      else if (counterparty != null) ...[
        if (widget.name == null)
          KitKvRow(
            label: l.txDetailsAddToContacts,
            labelColor: t.accentText,
            chevron: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ContactEditScreen(address: counterparty)),
            ),
          ),
      ]
      // Through the pairing: the contact, no address (DESIGN 1.2).
      else if (widget.mailboxName != null)
        _FieldRow(
          title: outgoing ? l.txDetailsSentTo : l.txDetailsReceivedFrom,
          body: '${widget.mailboxName}\n${l.sendRecipientPairing(widget.mailboxName!, l.sendRoutePairedInline)}',
        ),
      if (via != null) KitKvRow(label: outgoing ? l.phonePaySentThrough : l.phonePayReceivedThrough, value: _routeName(l, via)),
      if (fee != null && outgoing)
        KitKvRow(label: l.phonePayTotal, value: shownEpic(l, amount + fee, hidden: hidden, exact: true), mono: true),
      // A finished payment shows its date in the status row above.
      if (tx.status != TxStatus.confirmed)
        KitKvRow(label: l.txDetailsDate, value: formatDateTime(l, localTime(blockTime ?? tx.timeUnix))),
      if (isPostElsewhere(tx) || (tx.repostable && finishedUnderKillKeys.contains(tx.key)))
        KitKvRow(label: l.txModeRow, value: l.txModeFinishedKill),
      if (blockTime != null && tx.source == TxSource.wallet && (blockTime - tx.createdAtUnix).abs() > 120)
        KitKvRow(label: l.txDetailsCreated, value: formatDateTime(l, localTime(tx.createdAtUnix))),
      if (tx.source == TxSource.restored && tx.transport != null)
        KitKvRow(
          label: l.sendMethodLabel,
          value: txMethodWord(l, tx.transport),
          valueWidget: tx.manualFields.contains(ManualField.transport)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(txMethodWord(l, tx.transport), style: KitType.body.copyWith(height: 1.3), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    ManualTag(editedAtUnix: tx.manualEditedAtUnix),
                  ],
                )
              : null,
        ),
      if (tx.blockHeight case final height?) KitKvRow(label: l.phonePayBlock, value: groupDigits(l, height), mono: true),
      if (slate != null)
        _copyKv(
          l.phonePayId,
          slate,
          notice: l.txDetailsSlateIdCopied,
          shown: technical ? slate : shortAddress(slate),
          id: null,
        ),
      if (coins > 0)
        KitKvRow(
          label: l.phonePayCoins,
          value: coins == 1 ? l.phonePayOutputsOne : l.phonePayOutputsMany('$coins'),
          valueColor: t.dim,
          chevron: true,
          onTap: () => _showCoins(tx, technical: technical),
        ),
      // Advanced › Technical details shows the rows; without it the coins sheet has a row that
      // shows them for that view only (the switch stays off), or this one when no coins are
      // listed. Send feedback carries the slate id for support.
      if (!technical && coins == 0)
        KitKvRow(
          key: txDetailsTechnicalKey,
          label: l.txDetailsTechnical,
          labelColor: t.accentText,
          chevron: true,
          onTap: () => setState(() => _more = true),
          semanticsId: TrustIds.payTechnical,
        )
      else if (technical) ...[
        if (tx.kernelExcess case final kernel?)
          _copyRow(l.txDetailsKernel, kernel, notice: l.txDetailsKernelCopied),
        for (final (i, commit) in tx.outputCommits.indexed)
          _copyRow(
            singleOutput ? l.txDetailsOutputCommitment : l.txDetailsOutputCommitmentNumbered(i + 1),
            commit,
            notice: singleOutput ? l.txDetailsOutputCommitmentCopied : l.txDetailsOutputCommitmentNumberedCopied(i + 1),
          ),
        if (tx.ttlCutoffHeight case final cutoff?) KitKvRow(label: l.txDetailsExpiryHeight, value: groupDigits(l, cutoff), mono: true),
        if (tx.id case final id?) KitKvRow(label: l.txDetailsLocalId, value: '$id', mono: true),
      ],
    ];
    if (widget.withdrawalPairingId == null && counterparty != null) {
      who = Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              outgoing
                  ? l.txDetailsSentTo
                  : tx.isRequest
                  ? l.txDetailsRequestedFrom
                  : l.txDetailsReceivedFrom,
              style: KitType.rowSub.copyWith(color: t.dim),
            ),
            const SizedBox(height: 6),
            // The frame's .addr glyph pitch measures 7.82 px (44 to a line), as on Receive.
            MarkedAddress(counterparty, selectable: true, flat: true, flow: true, style: KitType.address.copyWith(letterSpacing: -0.55)),
            if (tx.manualFields.contains(ManualField.counterparty))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ManualTag(editedAtUnix: tx.manualEditedAtUnix, from: true),
              ),
          ],
        ),
      );
    }

    return KitSheet(
      title: l.phonePayMore,
      primaryLabel: l.commonDone,
      primaryKind: KitButtonKind.quiet,
      onPrimary: () => Navigator.of(context).pop(),
      primaryId: TrustIds.payMoreDone,
      actionsTop: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?who,
          KitGroup(onSheet: true, dividerInset: Kit.dividerInsetPlain, children: rows),
          if (counterparty != null || url != null) ...[
            const SizedBox(height: 12),
            KitGroup(
              onSheet: true,
              dividerInset: Kit.dividerInsetPlain,
              children: [
                if (counterparty != null)
                  KitKvRow(
                    label: l.txDetailsCopyAddress,
                    labelColor: t.accentText,
                    semanticsId: TrustIds.payCopyAddress,
                    onTap: () => copyText(context, counterparty, l.txDetailsAddressCopied),
                  ),
                if (url != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KitKvRow(
                        label: l.txDetailsExplorerLink,
                        labelColor: t.accentText,
                        semanticsId: TrustIds.payCopyExplorer,
                        onTap: () async {
                          await copyText(context, url, l.txDetailsLinkCopied);
                          _checkExplorer(tx.blockHeight!.toInt());
                        },
                      ),
                      if (_behind != null && _behind == tx.blockHeight?.toInt())
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Text(l.txDetailsExplorerBehind, style: KitType.rowSub.copyWith(color: t.dim)),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The coins the payment used, each with its commitment to copy. Without Advanced › Technical
  /// details a last row shows the kernel, expiry and local id here only.
  Future<void> _showCoins(TxEntry tx, {required bool technical}) {
    final l = context.l10n;
    final t = context.tokens;
    final single = tx.outputCommits.length == 1;
    var more = false;
    return showKitSheet<void>(
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => KitSheet(
          title: l.phonePayCoins,
          primaryLabel: l.commonDone,
          primaryKind: KitButtonKind.quiet,
          onPrimary: () => Navigator.of(sheet).pop(),
          primaryId: TrustIds.payCoinsDone,
          actionsTop: 14,
          child: KitGroup(
            onSheet: true,
            dividerInset: Kit.dividerInsetPlain,
            children: [
              if (more)
                if (tx.kernelExcess case final kernel?) _copyRow(l.txDetailsKernel, kernel, notice: l.txDetailsKernelCopied),
              for (final (i, commit) in tx.outputCommits.indexed)
                _copyRow(
                  single ? l.txDetailsOutputCommitment : l.txDetailsOutputCommitmentNumbered(i + 1),
                  commit,
                  notice: single ? l.txDetailsOutputCommitmentCopied : l.txDetailsOutputCommitmentNumberedCopied(i + 1),
                ),
              if (more) ...[
                if (tx.ttlCutoffHeight case final cutoff?) KitKvRow(label: l.txDetailsExpiryHeight, value: groupDigits(l, cutoff), mono: true),
                if (tx.id case final id?) KitKvRow(label: l.txDetailsLocalId, value: '$id', mono: true),
              ],
              if (!technical && !more)
                KitKvRow(
                  key: txDetailsTechnicalKey,
                  label: l.txDetailsTechnical,
                  labelColor: t.accentText,
                  chevron: true,
                  onTap: () => setSheet(() => more = true),
                  semanticsId: TrustIds.payTechnical,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
