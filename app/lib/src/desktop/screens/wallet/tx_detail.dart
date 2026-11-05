// SPDX-License-Identifier: Apache-2.0
import '../../../amount.dart' show exactEpic;
import '../../../name_service/pins.dart' show LinkPaymentRec;
import '../../../name_service/receipts.dart';
import '../../../trust/policy.dart' show MailboxSendStage, mailboxSendStage;
import '../transfer/send_screen.dart' show SendArgs;
import 'receipt_line.dart';
import '../../../cancel_choice.dart';
import '../../../cancel_final.dart' show CancelResult;
import '../../../connection_grace.dart' show connectionGraceProvider;
import '../../../network_gate.dart' show NetGate;
import '../../../explorer_check.dart' show ExplorerHas, explorerHasBlock;
import '../transfer/finished_payment.dart' show FinishedPaymentActions;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../known_relays.dart' show recipientRelay;
import '../../../devices/device_ending.dart' show deviceEndingLabel, deviceEndingLine;
import '../../../l10n.dart' show messageHint;
import '../../../models.dart' show IncomingCancel, PairingRecord, PairingState, SlatePurpose, incomingCancelAt;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../../watch_mode.dart' show BlockWait;
import '../../data/clock.dart';
import '../../data/invoice_state.dart' show PayState, deskInvoicesProvider;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/pairing_state.dart' show DeskPairNet, deskPairNetProvider, deskPairingByIdProvider, deskPairingNameProvider, deskPairingSlateProvider;
import '../pairing/add_to_contacts_button.dart' show DeskAddToContactsButton;
import '../pairing/pair_screens.dart' show deskAttachPairing, deskSuggestedContact;
import '../../desk_l10n.dart';
import '../../../levels/level_features.dart' show TimelineStyle, TxActionSet;
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider, deskLevelUiProvider;
import '../../../trust/contact_trust.dart' show MailboxResendOffer, mailboxResendOffer, relationshipOf, trustAddressOf;
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart';
import '../../widgets/server_row.dart' show digitsText;
import '../invoices/tx_invoice_block.dart';
import 'cancel_note.dart';
import '../../../help/help_content.dart' show HelpAnchor, HelpId;
import '../settings/help_pairing.dart' show HelpAt;
import 'tx_details_dialog.dart';
import 'tx_display.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../settings/settings_frame.dart' show groupDigits;
import 'other_wallet_offer.dart';
import 'tx_label.dart';
import 'contacts_screen.dart' show ContactsArgs;
import '../../../recipient.dart' show parseRecipient, recipientShaped;

/// The screenshot tour presses More on the open transaction.
final txMoreShotProvider = NotifierProvider<TxMoreShot, bool>(TxMoreShot.new);

class TxMoreShot extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
}

/// One transaction: amount and counterparty, where it stands, its progress, details, proof,
/// technical details and the actions it allows (cancel, finalize).
/// Cancel and send by Epicbox on the details, and its dialog's confirm, for tests.
const Key deskTxResendKey = ValueKey('tx-resend-epicbox');
const Key deskMailboxResendConfirmKey = ValueKey('mailbox-resend-confirm');

class TxDetail extends ConsumerStatefulWidget {
  const TxDetail({super.key, required this.tx, this.showTitle = false, this.frame});

  final Tx tx;

  /// Starts with the title (the label's field), for a layout whose page title is a plain string.
  final bool showTitle;

  /// Puts the details and the bar of the payment's actions (null when it has none) in the
  /// caller's frame: the bar pinned at a pane's foot or a page's bottom, so Cancel, Finalize
  /// and Post again are in view however long the details run (C-03). Without it the bar sits
  /// under the status.
  final Widget Function(Widget details, Widget? actions)? frame;

  @override
  ConsumerState<TxDetail> createState() => _TxDetailState();
}

class _TxDetailState extends ConsumerState<TxDetail> {
  bool _cancelling = false;

  /// The node already had this receive when Cancel was asked: Cancel stays away for this visit.
  int? _onNetworkFor;

  /// The block height the explorer had not reached when its link was copied.
  int? _explorerBehind;

  /// One request on Copy: is the block in the explorer yet ([explorerHasBlock]).
  Future<void> _checkExplorer(int height) async {
    final has = await explorerHasBlock(height);
    if (mounted) setState(() => _explorerBehind = has == ExplorerHas.notYet ? height : null);
  }

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

  @override
  void dispose() {
    _minute?.cancel();
    super.dispose();
  }

  /// The line under an incoming payment's status while this wallet waits for its sender: how
  /// long ago it signed, and when Cancel comes or what it is for (receiveCancelHold).
  String _holdLine(AppLocalizations l, IncomingCancel hold) => hold.senderReportsPosted
      ? l.txDetailsCancelWhileReported
      : l.txDetailsCancelHold(hold.holdMinutesLeft);

  /// The More link is open: the technical rows show for this view only.
  bool _more = false;

  String _now(AppLocalizations l, Tx t) => t.fromBackup
      ? l.deskTxNowBackup
      : t.otherWallet
      ? (t.incoming
            ? (t.receivedOn != null ? l.txDetailsDeviceIn(t.receivedOn!) : l.txDetailsOtherWalletIn)
            : (t.unverified ? '${l.txDetailsOtherWallet} ${l.txDetailsUnverified}' : l.txDetailsOtherWallet))
      : t.immature
      ? l.deskTxNowImmature(coinbaseMaturity)
      : switch (t.state) {
          TxState.waitingRecipient when t.undelivered => switch ((t.method, recipientRelay(t.counterparty ?? ''))) {
            (TxMethod.http || TxMethod.tor, _) => l.deskTxNowUndeliveredDirect(methodLabel(l, t.method)),
            (TxMethod.epicbox, final relay?) => l.deskTxNowUndeliveredRelay(relay.label),
            _ => l.deskTxNowUndelivered,
          },
          // The sender's word: the wallet clears it by itself (sender_cancel.dart).
          TxState.waitingRecipient when t.incoming && t.senderCancelled => l.txDetailsSenderCancelledWaiting,
          // Past its watch window and still in no block: why, in one calm line.
          TxState.waitingRecipient || TxState.posted when t.blockWait == BlockWait.noNewBlock => l.txWaitNoNewBlock,
          TxState.waitingRecipient || TxState.posted when t.blockWait == BlockWait.notInBlock => l.txWaitNotInBlock,
          TxState.waitingRecipient when t.incoming && t.senderPosted => l.deskTxNowSenderPosted,
          TxState.waitingRecipient =>
            t.incoming
                ? l.deskTxNowWaitingSender
                : t.method == TxMethod.file
                ? l.deskTxNowWaitingResponseFile
                : l.deskTxNowWaitingRecipient,
          TxState.posted when t.notPosted && NetGate.killSwitch => l.txPostElsewhereKill,
          TxState.posted when t.notPosted => l.deskTxNowNotPosted,
          TxState.posted => l.deskTxNowPosted,
          TxState.confirming => l.deskTxNowConfirming(t.confirmations, t.confirmationsNeeded),
          // Both facts, as the phone (UD-028): the confirmations and the block.
          TxState.confirmed => t.height == null ? l.deskTxNowConfirmed(t.confirmations) : l.deskTxNowConfirmedBlock(t.confirmations, digitsText(l, t.height!)),
          // The wallet keeps looking for a cancelled receive, so a late post still arrives.
          TxState.cancelled when t.deviceEnding != null =>
            deviceEndingLine(l, t.deviceEnding!, t.deviceName ?? '', t.deviceWhy) ?? deviceEndingLabel(l, t.deviceEnding!, t.deviceName ?? ''),
          TxState.cancelled when t.incoming && !t.isInvoice && t.senderCancelled => l.txDetailsSenderCancelled,
          TxState.cancelled when t.incoming && !t.isInvoice => l.txDetailsCancelledIncoming,
          TxState.cancelled => l.deskTxNowCancelled,
        };

  /// The block explorer link: the block by its height, once the payment is confirmed; null
  /// before that, or when `app-config.toml` names no explorer.
  String? _explorerUrl(Tx t) {
    if (t.state != TxState.confirmed || !ref.watch(deskLevelFeaturesProvider.select((f) => f.explorerLink))) return null;
    final settings = ref.watch(hostSettingsProvider);
    final height = t.height;
    return height == null ? null : settings.explorerBlock(height);
  }

  /// The phone's technical rows, in its order: block height, slate ID, kernel, the output
  /// commitments, expiry height and the local id.
  Widget _techFacts(Tx t, AppLocalizations l, DeskText ts) {
    Widget mono(String v) => Text(v, style: ts.mono(size: Fs.xs));
    Widget copyable(String v, String copy) => Row(
      children: [Expanded(child: mono(v)), ECopyButton(text: v, label: copy)],
    );
    final single = t.outputCommits.length == 1;
    return EFacts(labelWidth: 132.u, [
      if (t.height case final h?) (l.txDetailsBlockHeight, mono(groupDigits(l, h))),
      if (t.slateId.isNotEmpty) (l.txDetailsSlateId, copyable(t.slateId, l.txDetailsSlateIdCopy)),
      if (t.kernel case final k? when k.trim().isNotEmpty) (l.txDetailsKernel, copyable(k, l.txDetailsKernelCopy)),
      for (final (i, c) in t.outputCommits.indexed)
        (
          single ? l.txDetailsOutputCommitment : l.txDetailsOutputCommitmentNumbered(i + 1),
          copyable(c, single ? l.txDetailsOutputCommitmentCopy : l.txDetailsOutputCommitmentNumberedCopy(i + 1)),
        ),
      if (t.expiryHeight case final e?) (l.txDetailsExpiryHeight, mono(groupDigits(l, e))),
      (l.txDetailsLocalId, mono('${t.id}')),
    ]);
  }

  Future<void> _sendAgain() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).resendTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, context.l10n.deskTxNotSent, text: deskErrorText(e, context.l10n), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, context.l10n.deskTxSentAgain, text: context.l10n.deskTxSentAgainText, tone: ETone.ok);
  }

  Future<void> _broadcastAgain() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).repostTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, context.l10n.deskTxNotSent, text: deskErrorText(e, context.l10n), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, context.l10n.deskTxBroadcastDone, tone: ETone.ok);
  }

  /// Cancel and send by Epicbox (trust policy, an unanswered mailbox send): the waiting send
  /// is cancelled through the ordinary cancel, then an ordinary Epicbox send of the same amount
  /// and message goes to [address], the contact's Epicbox address. One confirm first.
  Future<void> _resend(String name, String address) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.mailboxResendTitle,
        description: l.mailboxResendBody(name),
        icon: EIcons.send,
        actions: [
          EButton(label: l.mailboxKeepWaiting, onPressed: () => Navigator.of(ctx).pop(false)),
          EButton.primary(key: deskMailboxResendConfirmKey, label: l.mailboxResendAction, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final t = widget.tx;
    setState(() => _cancelling = true);
    try {
      final n = ref.read(deskProvider.notifier);
      await n.cancelTx(t.id, spendBack: false);
      await n.send(SendRequest(method: TxMethod.epicbox, amount: t.amount, to: address, message: t.messageBySender ? t.message : null));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    showEToast(context, l.mailboxResent, tone: ETone.ok);
  }

  /// Cancel and send by Epicbox for a payment made from a payment link nobody answered: one
  /// confirm, the ordinary cancel, then Send opens with the amount, to the payee's saved contact
  /// address when there is one, else empty.
  Future<void> _resendLink(LinkPaymentRec rec, String name) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.mailboxResendTitle,
        description: l.linkResendBody,
        icon: EIcons.send,
        actions: [
          EButton(label: l.mailboxKeepWaiting, onPressed: () => Navigator.of(ctx).pop(false)),
          EButton.primary(key: deskMailboxResendConfirmKey, label: l.mailboxResendAction, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final address = contactEpicboxFor(rec, (ref.read(deskProvider.select((s) => s.contacts)) ?? const <Contact>[]).map((c) => c.epicbox));
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(widget.tx.id, spendBack: false);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showEToast(context, deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    ref.read(deskNavProvider.notifier).go(DeskRoute.send, SendArgs(recipient: address, amount: exactEpic(rec.amount)));
  }

  Future<void> _cancel() async {
    final choice = await showCancelTxDialog(context, widget.tx) ?? CancelChoice.keep;
    if (!choice.cancels || !mounted) return;
    setState(() => _cancelling = true);
    final CancelResult result;
    try {
      result = await ref.read(deskProvider.notifier).cancelTx(widget.tx.id, spendBack: choice.spendBack);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      // The node already has a receive: not a failure, the payment is on its way (as the phone says).
      if (widget.tx.incoming && e is DeskError && e.cancelRefused) {
        setState(() => _onNetworkFor = widget.tx.id);
        showEToast(context, context.l10n.txDetailsCancelRefusedOnNetwork, tone: ETone.info);
        unawaited(ref.read(deskProvider.notifier).refresh());
        return;
      }
      showEToast(context, context.l10n.deskTxNotCancelled, text: deskErrorText(e, context.l10n), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    final l = context.l10n;
    // A send both wallets signed: Cancel for sure spent its coins back (or will try again),
    // Stop waiting left them in place. Calm tones only: a retry is information, not alarm.
    switch (result) {
      case CancelResult.spentBack:
        showEToast(context, l.deskTxCancelled, text: l.deskInvPayerSpentText, tone: ETone.ok);
      case CancelResult.spendBackPending:
        showEToast(context, l.deskTxCancelled, text: l.deskInvPayerSpendFailedText, tone: ETone.info);
      case CancelResult.stoppedWaiting:
        showEToast(context, l.cancelStoppedWaitingTitle, text: l.cancelStoppedWaitingText, tone: ETone.info);
      case CancelResult.cancelled:
        showEToast(context, l.deskTxCancelled, tone: ETone.ok);
      case CancelResult.alreadyPaid:
        showEToast(context, l.errorPaymentAlreadyWentThrough, tone: ETone.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final t = widget.tx;
    ref.listen(txMoreShotProvider, (_, open) {
      if (open && !_more) setState(() => _more = true);
    });
    final total = t.amount + (t.incoming ? 0 : t.fee);
    // The level: Shallow and Deeper read the steps in plain words and Shallow keeps Cancel as
    // the one action, no method, fee or technical rows; the Deep end is today's detail.
    final features = ref.watch(deskLevelFeaturesProvider);
    final shallow = ref.watch(deskLevelUiProvider.select((f) => f.shallow));
    final fullActions = features.txActions == TxActionSet.full;
    final plainSteps = features.timeline != TimelineStyle.technicalSteps;
    // A send can be cancelled while it waits for the recipient, or when the node refused its
    // post (its outputs stay locked otherwise). Once posted (a Direct HTTP or Tor send is
    // finalized and posted in one step) it has gone out and shows as sent, never cancellable.
    // Invoice-flow transactions take their actions from the Invoice block.
    // An incoming payment this wallet signed: for receiveCancelHold after, and while its sender
    // reports it posted, Cancel stays away and the status box says why (incomingCancelAt).
    final waitingIncoming = t.incoming && t.state == TxState.waitingRecipient && !t.fromBackup && !t.isInvoice && t.cancellable;
    final hold = waitingIncoming
        ? incomingCancelAt(
            signedAt: t.startedAt ?? t.created,
            now: ref.watch(deskClockProvider)(),
            senderReportsPosted: t.senderPosted,
            senderCancelled: t.senderCancelled,
          )
        : null;
    _tickWhile(hold != null && !hold.offered && !hold.senderReportsPosted);
    final cancelable = !t.fromBackup &&
        !t.isInvoice &&
        (t.incoming
            ? t.cancellable && t.state != TxState.cancelled && t.state != TxState.confirmed && (hold?.offered ?? true) && _onNetworkFor != t.id
            : (t.cancellable && t.state == TxState.waitingRecipient) || t.notPosted);
    // A send through a paired contact's mailbox (no address; LEPIC keeps it as an export):
    // its answer comes back by itself, so there is no file to finalize.
    final mailboxName = deskTxMailboxName(ref, t, any: true);
    final mailboxPairing = mailboxName == null
        ? null
        : switch (t.pairingId ?? ref.watch(deskPairingSlateProvider(t.slateId)).value?.pairingId) {
            final id? => ref.watch(deskPairingByIdProvider(id)),
            null => null,
          };
    // The paired contact behind the mailbox and its Epicbox address: Cancel and send by Epicbox
    // needs one (trust policy, mailboxResendOffer).
    final mailboxContact = mailboxPairing?.contactId == null
        ? null
        : (ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[]).where((x) => x.id == mailboxPairing!.contactId).firstOrNull;
    final resendAddress = trustAddressOf(mailboxContact?.epicbox, mailboxPairing);
    final resendOffer = mailboxName != null && !t.incoming && t.state == TxState.waitingRecipient && !t.undelivered && mailboxPairing != null
        ? mailboxResendOffer(
            relationshipOf(inContacts: mailboxContact != null, epicboxAddress: mailboxContact?.epicbox, pairing: mailboxPairing),
            t.created,
            ref.watch(deskClockProvider)(),
          )
        : null;
    // A payment made from a payment link: its payee's silent rows and the optional receipt.
    final linkRec = t.slateId.isEmpty ? null : ref.watch(linkPaymentProvider(t.slateId));
    final linkName = linkRec == null ? null : linkPayeeName(ref.watch(nameServiceReceiptsProvider), linkRec);
    final linkWaiting = linkRec != null && mailboxName == null && !t.incoming && t.state == TxState.waitingRecipient && !t.undelivered;
    final linkOffer = linkWaiting
        ? switch (mailboxSendStage(t.created, ref.watch(deskClockProvider)())) {
            MailboxSendStage.waiting => null,
            final stage => MailboxResendOffer(stage: stage, resend: true),
          }
        : null;
    final linkPosted = t.state == TxState.posted || t.state == TxState.confirming || t.state == TxState.confirmed;
    final linkReceipt = linkRec != null && mailboxName == null && !t.incoming && (linkWaiting || linkPosted);
    final finalizable = fullActions && !t.fromBackup && !t.incoming && !t.isInvoice && t.method == TxMethod.file && t.state == TxState.waitingRecipient && mailboxName == null;
    // The node refused it: broadcast it again at once (android-17); the app also does by itself.
    final repostable = fullActions && !t.fromBackup && !t.isInvoice && t.notPosted;
    final sendAgain = fullActions && t.undelivered;
    // A payment to a paired contact's request, or a withdrawal from a paired contact: the
    // contact's own steps.
    final paid = !t.incoming ? ref.watch(deskInvoicesProvider)?.invoiceOfTx(t.id) : null;
    final paidTo = paid?.pairingId;
    final slate = t.incoming && !t.isInvoice && t.slateId.isNotEmpty ? ref.watch(deskPairingSlateProvider(t.slateId)).value : null;
    final withdrawal = slate?.purpose == SlatePurpose.withdrawal ? slate : null;
    final contact = paidTo ?? withdrawal?.pairingId;
    final contactName = contact == null ? '' : ref.watch(deskPairingNameProvider(contact));
    final steps = paidTo != null
        ? _paidSteps(l, t, paid!.state, contactName)
        : withdrawal != null
        ? _withdrawalSteps(l, t, contactName)
        // The mailbox steps are the payer's; the payee's are the usual receive steps (LNX3-8).
        : mailboxName != null && !t.incoming
        ? _mailboxSteps(l, t, mailboxName, mailboxPairing?.homeRelay ?? '', ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff)
        : _steps(l, t);
    final onChain = t.state == TxState.confirming || t.state == TxState.confirmed;
    // The payment's actions: a destructive Cancel at the start, the way on (Finalize, Post
    // again, Send again) at the end.
    final cancel = cancelable
        ? EButton(
            label: _cancelling ? l.deskTxCancelling : (t.incoming ? l.deskTxCancelIncomingAction : l.deskTxCancelOutgoingAction),
            icon: EIcons.cancel,
            // A receive's Cancel is a tidy-up for a payment the sender never posted, so
            // it stays quiet; a send's unlocks funds.
            kind: t.incoming && !t.senderCancelled ? EBtnKind.ghost : EBtnKind.danger,
            size: EBtnSize.sm,
            busy: _cancelling,
            onPressed: _cancel,
          )
        : null;
    final onward = <Widget>[
      // An unanswered mailbox send: after a day the main action, at seven days second to
      // Cancel (trust policy). Only with the contact's Epicbox address.
      if (resendOffer != null && resendAddress != null)
        resendOffer.resendPrimary
            ? EButton.primary(
                key: deskTxResendKey,
                label: l.mailboxResendTitle,
                icon: EIcons.send,
                size: EBtnSize.sm,
                busy: _cancelling,
                onPressed: _cancelling ? null : () => _resend(mailboxName!, resendAddress),
              )
            : EButton(
                key: deskTxResendKey,
                label: l.mailboxResendTitle,
                icon: EIcons.send,
                size: EBtnSize.sm,
                busy: _cancelling,
                onPressed: _cancelling ? null : () => _resend(mailboxName!, resendAddress),
              ),
      if (linkOffer != null && linkRec != null)
        linkOffer.resendPrimary
            ? EButton.primary(
                key: deskTxResendKey,
                label: l.mailboxResendTitle,
                icon: EIcons.send,
                size: EBtnSize.sm,
                busy: _cancelling,
                onPressed: _cancelling ? null : () => _resendLink(linkRec, linkName ?? l.linkPayeeMid),
              )
            : EButton(
                key: deskTxResendKey,
                label: l.mailboxResendTitle,
                icon: EIcons.send,
                size: EBtnSize.sm,
                busy: _cancelling,
                onPressed: _cancelling ? null : () => _resendLink(linkRec, linkName ?? l.linkPayeeMid),
              ),
      if (sendAgain)
        EButton.primary(
          label: context.l10n.deskTxSendAgain,
          icon: EIcons.refresh,
          size: EBtnSize.sm,
          busy: _cancelling,
          onPressed: _sendAgain,
        ),
      if (repostable && NetGate.killSwitch) FinishedPaymentActions(tx: t),
      if (repostable && !NetGate.killSwitch)
        EButton.primary(
          label: l.deskTxBroadcastAgain,
          icon: EIcons.refresh,
          size: EBtnSize.sm,
          busy: _cancelling,
          onPressed: _broadcastAgain,
        ),
      if (finalizable)
        EButton.primary(
          label: l.deskTxFinalize,
          icon: EIcons.fileDown,
          size: EBtnSize.sm,
          onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize),
        ),
    ];
    final actions = cancel == null && onward.isEmpty ? null : TxActionBar(leading: cancel, trailing: onward);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTitle) ...[
          TxPanelTitle(tx: t, fallback: t.isInvoice ? l.deskInvActBlock : (t.incoming ? l.deskActDetailReceived : l.deskActDetailSent)),
          SizedBox(height: Sp.x4),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TxIcon(t, size: 44.u),
            SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitMoney(
                    t.incoming ? t.amount : -t.amount,
                    // The details are where an amount is inspected: every decimal.
                    surface: AmountSurface.exact,
                    sign: !txAsked(t),
                    sizes: const [Fs.h2, Fs.h3, Fs.lg, Fs.md],
                    weight: FontWeight.w500,
                    color: t.state == TxState.cancelled ? c.txCancelled : (txAsked(t) ? c.text : (t.incoming ? c.txReceived : c.txSent)),
                  ),
                  // Not money yet: the row's caption, by the big amount too.
                  if (txAsked(t) && t.state == TxState.waitingRecipient) Text(context.l10n.deskInvUnpaid, style: ts.caption),
                  const SizedBox(height: 2),
                  if (t.otherWallet || t.deviceName != null)
                    Text(whoOf(l, t), style: ts.small)
                  else if (t.foundByScan && t.contactName == null)
                    Text(t.foundDuring == FoundDuring.restore ? l.deskTxHeadRestored : l.deskTxHeadFoundOnChain, style: ts.small)
                  else if (t.fromBackup && t.counterparty == null)
                    Text(l.deskTxHeadBackup, style: ts.small)
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          // The name sits in its own style: split the sentence at a marker.
                          for (final (i, part) in (t.incoming ? l.deskTxHeadFrom('\u0001') : l.deskTxHeadTo('\u0001')).split('\u0001').indexed) ...[
                            if (i > 0)
                              // A withdrawal is from the paired contact, by name.
                              withdrawal != null && contactName.isNotEmpty
                                  ? TextSpan(text: contactName, style: TextStyle(color: c.text))
                                  : mailboxName != null
                                  ? TextSpan(text: mailboxName, style: TextStyle(color: c.text))
                                  : TextSpan(
                                      text: fileNameOf(t) ?? whoOf(l, t),
                                      style: whoIsAddress(t) ? ts.mono(size: Fs.xs, color: c.text) : TextStyle(color: c.text),
                                    ),
                            TextSpan(text: part),
                          ],
                        ],
                      ),
                      style: ts.small,
                    ),
                  if (whoTip(l, t) != null && !(t.fromBackup && t.counterparty == null)) ...[const SizedBox(height: 2), Text(whoTip(l, t)!, style: ts.small.copyWith(color: c.faint))],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x4),
        // A withdrawal not posted yet: its notice below stands alone.
        if (!t.isInvoice && !(withdrawal != null && !onChain))
        Container(
          padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 10.u),
          decoration: BoxDecoration(
            color: c.s2,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              TxStateMark(t),
              SizedBox(width: Sp.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The words on the badge, the meaning under it.
                    if (t.incoming && t.senderCancelled && t.state == TxState.waitingRecipient) ...[
                      EBadge(l.txStatusSenderCancelled, key: const ValueKey('tx-sender-cancelled'), tone: ETone.neutral),
                      SizedBox(height: Sp.x1),
                    ] else if (t.incoming && t.senderPosted && t.state == TxState.waitingRecipient) ...[
                      EBadge(l.deskTxStatusSenderPosted, key: const ValueKey('tx-sender-posted'), tone: ETone.info),
                      SizedBox(height: Sp.x1),
                    ],
                    Text(
                      resendOffer != null
                          ? (resendOffer.gone ? l.mailboxNotPickedUp : l.mailboxNotAnswered)
                          : mailboxName != null && !t.incoming && t.state == TxState.waitingRecipient && !t.undelivered
                          ? l.deskTxStatusWaitingFor(mailboxName)
                          : linkOffer != null
                          ? (linkOffer.gone ? l.mailboxNotPickedUp : l.mailboxNotAnswered)
                          : linkWaiting && linkName != null
                          ? l.deskTxStatusWaitingFor(linkName)
                          : _now(l, t),
                      style: ts.body,
                    ),
                    // Gone from the relay after seven days: the line says so.
                    if (resendOffer?.gone ?? false) ...[
                      SizedBox(height: Sp.x1),
                      Text(l.mailboxNeverPickedUp(mailboxName!), key: const ValueKey('tx-mailbox-gone'), style: ts.small),
                    ],
                    if (linkOffer?.gone ?? false) ...[
                      SizedBox(height: Sp.x1),
                      Text(l.mailboxNeverPickedUp(linkName ?? l.linkPayeeLead), key: const ValueKey('tx-link-gone'), style: ts.small),
                    ],
                    if (t.otherWallet && !t.fromBackup && t.receivedOn == null) ...[
                      SizedBox(height: Sp.x1),
                      ELink(
                        key: const ValueKey('tx-other-wallet-help'),
                        label: l.txOtherWalletMore,
                        onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.otherWallet)),
                      ),
                    ],
                    // Its sender cancelled it: Cancel is there at once, with no line to weigh.
                    if (hold != null && !hold.senderCancelled && !hold.offered) ...[
                      SizedBox(height: Sp.x1),
                      DeskCancelNote(key: const ValueKey('tx-cancel-hold'), text: _holdLine(l, hold), anchor: HelpAnchor.receiving),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Waiting for a paired contact's answer: its keys changed meanwhile, or its relay is
        // silent.
        if (mailboxName != null && !t.incoming && t.state == TxState.waitingRecipient && mailboxPairing != null) ..._mailboxNotices(l, mailboxName, mailboxPairing),
        // The optional receipt for the payee of a payment link.
        if (linkReceipt) ...[
          SizedBox(height: Sp.x3),
          DeskReceiptLine(slateId: t.slateId, posted: linkPosted),
        ],
        // A withdrawal from a paired contact, not yet posted by it.
        if (withdrawal != null && !onChain) ...[
          SizedBox(height: Sp.x3),
          ENotice(title: l.reqReceivedWaiting(contactName), text: l.reqReceivedWaitingBody, tone: ETone.info),
        ],
        // Inline, the bar comes first: Cancel, Send again and Finalize are seen without scrolling.
        if (actions != null && widget.frame == null) ...[
          SizedBox(height: Sp.x4),
          actions,
          SizedBox(height: Sp.x2),
        ],
        // An invoice-flow transaction: the invoice behind it, in the Invoices page's words.
        if (t.isInvoice) TxInvoiceBlock(tx: t),
        if (paidTo != null && t.isInvoice && t.state != TxState.cancelled) ...[_Sub(l.deskTxSubProgress), for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1)],
        if (t.state != TxState.cancelled && !t.senderCancelled && !t.fromBackup && !t.isInvoice && !t.otherWallet) ...[
          _Sub(l.deskTxSubProgress),
          // Every level reads an ordinary payment's five shared steps (A-03), in its words.
          if (payHasSteps(t) && paidTo == null && withdrawal == null)
            DeskPaymentSteps(tx: t, vertical: true)
          else
            for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1),
        ],
        _SubBar(
          l.deskTxSubDetails,
          [
            // Shallow and Deeper: the payment's facts as text (the phone's Copy details).
            if (plainSteps && t.slateId.isNotEmpty)
              ECopyButton(
                key: const ValueKey('tx-copy-details'),
                text: _detailsText(l, t),
                label: l.lvPayCopyDetails,
                withLabel: true,
              ),
            if (t.restored)
              EButton(
                label: _typed(t) ? l.deskTxDetailsEdit : l.deskTxDetailsAdd,
                icon: _typed(t) ? EIcons.pencil : EIcons.plus,
                kind: EBtnKind.ghost,
                size: EBtnSize.inline,
                onPressed: () => showTxDetailsDialog(context, t),
              ),
            if (t.deviceName == null)
            EButton(
              label: t.labelText == null ? l.deskTxLabelAdd : l.deskTxLabelEdit,
              icon: EIcons.pencil,
              kind: EBtnKind.ghost,
              size: EBtnSize.inline,
              onPressed: () => ref.read(txLabelEditingProvider.notifier).open(t.key, txLabelDetailPlace),
            ),
          ],
        ),
        EFacts(labelWidth: 96.u, [
          (l.deskTxFactDate, Text(dateTimeOf(l, t))),
          // A withdrawal names the paired contact, never its address (RFC C-21).
          if (withdrawal != null)
            (l.deskTxFactFrom, _PairedFrom(pairingId: withdrawal.pairingId, name: contactName))
          // Through the pairing: the contact, never the mailbox as an address (DESIGN 1.3).
          else if (mailboxName != null)
            (
              t.incoming ? l.deskTxFactFrom : l.deskTxFactTo,
              Column(
                key: const ValueKey('tx-fact-pairing'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(mailboxName), Text(l.sendRecipientPairing(mailboxName), style: ts.small)],
              ),
            )
          else if (t.counterparty != null)
            (
              // The phone's words, so the row is found the same way (Add to contacts under it).
              t.method == TxMethod.file || t.toSelf ? (t.incoming ? l.deskTxFactFrom : l.deskTxFactTo) : (t.incoming ? l.txDetailsReceivedFrom : l.txDetailsSentTo),
              _withTag(
                t,
                ManualField.counterparty,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: t.method == TxMethod.file
                              ? EMiddleEllipsis(fileNameOf(t)!, style: ts.mono(size: Fs.xs))
                              : Padding(padding: const EdgeInsets.only(top: 2), child: EFullAddress(t.counterparty!)),
                        ),
                        ECopyButton(text: t.counterparty!, label: l.deskTxCopyAddress),
                      ],
                    ),
                    if (_offerContact(t))
                      EButton(
                        key: const ValueKey('tx-add-contact'),
                        label: l.txDetailsAddToContacts,
                        icon: EIcons.userPlus,
                        kind: EBtnKind.ghost,
                        size: EBtnSize.inline,
                        onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.contacts, ContactsArgs(adding: true, address: t.counterparty, fromTx: t.id)),
                      ),
                  ],
                ),
              ),
            ),
          if (!t.otherWallet && !shallow)
            (
              l.deskTxFactMethod,
              t.foundByScan
                  ? _withTag(t, ManualField.transport, Text(restoredMethodOf(l, t) ?? '–'))
                  : Text(methodLabel(l, mailboxName != null ? TxMethod.epicbox : t.method)),
            ),
          (l.deskTxFactAmount, EMoney(t.amount, surface: AmountSurface.exact)),
          // The other wallet paid the fee: this wallet only saw the coins leave.
          if (shallow) ...const <(String, Widget)>[]
          else if (!t.incoming && t.otherWallet) (l.deskTxFactFee, Text(l.txDetailsNotKnown))
          else if (!t.incoming) ...[(l.deskTxFactFee, EMoney(t.fee, surface: AmountSurface.exact)), (l.deskTxFactTotal, EMoney(total, weight: FontWeight.w600, surface: AmountSurface.exact))],
          // The same word as Send's field and its review; the line under it says which way it went.
          if (t.message != null)
            (
              l.deskTxFactMessage,
              Column(
                key: const ValueKey('tx-message'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(t.message!), Text(messageHint(l, incoming: t.incoming, bySender: t.messageBySender), style: ts.small)],
              ),
            ),
          // Never sent: only this device and its exported data hold it.
          if (t.note != null && t.note!.trim().isNotEmpty)
            (
              l.deskTxDetailsNote,
              Column(
                key: const ValueKey('tx-private-note'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_withTag(t, ManualField.note, Text(t.note!)), Text(l.txDetailsNoteHelper, style: ts.small)],
              ),
            ),
        ]),
        if (_typed(t)) ...[SizedBox(height: Sp.x2), ManualTag(t, t.manualFields.firstWhere((f) => f != ManualField.label))],
        // A payment another linked device made: where its details come from, and why its coins
        // are held here while it is under way.
        if (t.deviceName != null) ...[
          SizedBox(height: Sp.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(l.txDeviceMadeOn(t.deviceName!), key: const ValueKey('tx-device-note'), style: ts.small)),
              if (deskStatusFromDevice(t)) deskDeviceStatusInfo(l, t),
            ],
          ),
          if (t.pending) Padding(padding: EdgeInsets.only(top: Sp.x1), child: Text(l.txDeviceHeld, style: ts.small)),
        ],
        // The phone's explorer row (GP-015): above the fold, once the payment is confirmed.
        if (_explorerUrl(t) case final url?) ...[
          SizedBox(height: Sp.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ECopyButton(key: const ValueKey('tx-explorer-link'), text: url, label: l.txDetailsExplorerLink, withLabel: true, onCopied: () => _checkExplorer(t.height!)),
          ),
          if (_explorerBehind != null && _explorerBehind == t.height)
            Padding(
              padding: EdgeInsets.only(top: Sp.x1),
              child: Semantics(liveRegion: true, child: Text(l.txDetailsExplorerBehind, key: const ValueKey('tx-explorer-behind'), style: ts.small)),
            ),
        ],
        // Advanced › Technical details: the fold, or a small More link that shows the same rows
        // for this view only (the switch stays off). Report a problem carries the slate id either way.
        if (shallow) ...const <Widget>[]
        else if (advancedHas(ref, AdvancedFeature.technicalDetails)) ...[
          SizedBox(height: Sp.x5),
          EDetails(title: l.deskTxTechTitle, child: _techFacts(t, l, ts)),
        ] else ...[
          SizedBox(height: Sp.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ELink(
              key: const ValueKey('tx-more'),
              label: _more ? l.deskTxLess : l.deskTxMore,
              onPressed: () => setState(() => _more = !_more),
            ),
          ),
          ExpandFade(
            open: _more,
            child: Padding(
              padding: EdgeInsets.only(top: Sp.x3),
              child: _techFacts(t, l, ts),
            ),
          ),
        ],
        // The end of the details of a row another wallet made: the quiet "link this device" offer
        // goes here (Linked devices).
        if (t.otherWallet && t.receivedOn == null) DeskSentFromOtherWalletOffer(incoming: t.incoming),
      ],
    );
    return widget.frame?.call(details, actions) ?? details;
  }

  /// What Copy details puts on the clipboard: who, how much, where it stands, when, its id.
  String _detailsText(AppLocalizations l, Tx t) {
    final (word, _) = levelStatusWithMailbox(l, t, ref.read(deskLevelFeaturesProvider).wording, t.contactName);
    return [
      titleOf(l, t),
      epicTextL(l, t.incoming ? t.amount : -t.amount, surface: AmountSurface.exact, signed: true),
      word,
      '${l.lvPayStarted}: ${dateTimeOf(l, t, at: t.startedAt)}',
      '${l.lvPayPaymentId}: ${t.slateId}',
    ].join('\n');
  }

  /// An address no contact holds yet, of a payment that names one (not a file, a mining
  /// reward or a payment to this wallet): the phone's Add to contacts (Max, 26.10.19).
  bool _offerContact(Tx t) {
    final address = t.counterparty;
    if (address == null || t.contactName != null || t.toSelf || t.coinbase || t.method == TxMethod.file) return false;
    final to = parseRecipient(address);
    if (!recipientShaped(to)) return false;
    final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
    return !contacts.any((c) => c.addresses.any((a) => parseRecipient(a).address == to.address));
  }

  /// Whether the user has typed a sender, method or note on this scan find.
  bool _typed(Tx t) => t.manualFields.any((f) => f != ManualField.label);

  /// [value] with a pen after it when the user typed [field]; the one "Added by you" line sits
  /// under the details.
  Widget _withTag(Tx t, ManualField field, Widget value) => t.manualFields.contains(field)
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: value),
            SizedBox(width: Sp.x1),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ExcludeSemantics(child: Icon(EIcons.pencil, size: 12.u, color: context.dc.faint)),
            ),
          ],
        )
      : value;

  /// A request a paired contact sent, paid: Paid, Delivered to its relay, Posted
  /// by it, the confirmations.
  List<_Step> _paidSteps(AppLocalizations l, Tx t, PayState state, String name) {
    final delivered = state != PayState.notDelivered;
    final posted = state == PayState.posted || state == PayState.confirming || state == PayState.completed || t.state == TxState.confirming || t.state == TxState.confirmed;
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed || state == PayState.completed;
    return [
      _Step(l.reqTlPaid, _S.done, ''),
      _Step(l.reqTlDelivered, delivered ? _S.done : _S.now, '', sub: delivered ? null : l.reqRelayRetrying),
      _Step(l.reqTlPosted(name), posted ? _S.done : (delivered ? _S.now : _S.todo), ''),
      _Step(
        done ? l.reqTlConfirmed : l.reqTlConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        '',
        sub: inBlock && !done ? l.reqTlConfirmingHint(t.confirmations, t.confirmationsNeeded) : null,
      ),
    ];
  }

  /// A withdrawal from a paired contact (RFC 12.5): the answer delivered over Epicbox, Posted
  /// by it, the confirmations.
  List<_Step> _withdrawalSteps(AppLocalizations l, Tx t, String name) {
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(l.reqTlAnswerDelivered, _S.done, ''),
      _Step(l.reqTlPosted(name), inBlock ? _S.done : _S.now, ''),
      _Step(
        done ? l.reqTlConfirmed : l.reqTlConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        '',
        sub: inBlock && !done ? l.reqTlConfirmingHint(t.confirmations, t.confirmationsNeeded) : null,
      ),
    ];
  }

  /// A send through a paired contact's mailbox (DESIGN 1.3): sent through it (still current,
  /// paused, while Epicbox is off and it waits in the outbox), the contact's answer, posted,
  /// the confirmations.
  List<_Step> _mailboxSteps(AppLocalizations l, Tx t, String name, String relay, bool paused) {
    final waiting = t.state == TxState.waitingRecipient;
    final queued = waiting && paused;
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || (t.state == TxState.posted && !t.notPosted && !t.posting);
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    return [
      _Step(
        l.txStepSentMailbox(name),
        queued ? _S.now : _S.done,
        queued ? '' : timeOf(t),
        sub: queued ? l.contactPausedEpicboxOff : (relay.isEmpty ? null : l.contactDeliveredVia(relay)),
      ),
      _Step(l.txStepAnswerFrom(name), queued ? _S.todo : (waiting ? _S.now : _S.done), '', sub: waiting && !queued ? l.txStepCollecting(name) : null),
      // Then the shared steps' words (payStepList, A-03).
      _Step(l.txStepPosted, posted ? _S.done : (!waiting && !inBlock ? _S.now : _S.todo), ''),
      ...payStepList(l, t, ref.read(deskLevelFeaturesProvider).timeline, name: name).skip(3),
    ];
  }

  /// The warn notices on a send waiting for [name]'s answer: keys changed, relay silent.
  List<Widget> _mailboxNotices(AppLocalizations l, String name, PairingRecord p) => [
    if (p.state == PairingState.keysChanged) ...[
      SizedBox(height: Sp.x3),
      ENotice(key: const ValueKey('tx-mailbox-keys'), title: l.contactKeysChangedTitle(name), text: l.contactKeysChangedBody, tone: ETone.warn),
    ] else if (p.relayDown && !ref.watch(connectionGraceProvider)) ...[
      SizedBox(height: Sp.x3),
      ENotice(key: const ValueKey('tx-mailbox-relay'), title: l.contactRelayDownTitle(name), text: l.contactRelayDownBody, tone: ETone.warn),
    ],
  ];

  List<_Step> _steps(AppLocalizations l, Tx t) {
    // The steps happened when this wallet took the slate, not when the block came (LNX2-3).
    final at = t.startedAt ?? t.created;
    String hm(Duration d) => timeOf(Tx(id: 0, slateId: '', direction: t.direction, state: t.state, method: t.method, amount: 0, fee: 0, created: at.add(d)));
    if (t.coinbase || t.foundByScan) {
      final left = coinbaseMaturity - t.confirmations;
      return [
        _Step(t.coinbase ? l.deskTxStepMined : foundTexts(l, t).step, _S.done, hm(Duration.zero), sub: t.coinbase ? null : foundTexts(l, t).note),
        if (t.coinbase)
          _Step(l.deskTxStepSpendable, t.immature ? _S.now : _S.done, '', sub: t.immature ? l.deskTxStepBlocksToGo(left) : null)
        else
          _Step(l.deskTxStepSpendable, _S.done, ''),
      ];
    }
    // A payment another linked device made: the five shared steps, as every other payment.
    return payStepList(l, t, ref.read(deskLevelFeaturesProvider).timeline, name: t.contactName, times: true);
  }
}

/// The step list's types are the shared ones ([PayStep]): the payment steps on Overview and
/// Send read the same record the same way.
typedef _S = PayStepState;
typedef _Step = PayStep;

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    // The phone tracker's stepper: round nodes, a green check done, a blue ring now,
    // a grey ring to come.
    final mark = Container(
      width: 20.u,
      height: 20.u,
      decoration: BoxDecoration(
        color: step.state == _S.done ? c.ok : c.s1,
        shape: BoxShape.circle,
        border: step.state == _S.done ? null : Border.all(color: step.state == _S.now ? c.info : c.lineStrong, width: 2),
      ),
      child: step.state == _S.done ? Icon(EIcons.check, size: 13.u, color: c.bg) : null,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20.u,
            child: Column(
              children: [
                mark,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: step.state == _S.done ? c.ok : c.lineStrong,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: Sp.x3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : Sp.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: step.state == _S.todo ? ts.body.copyWith(color: c.faint, fontWeight: FontWeight.w500) : ts.strong,
                  ),
                  if (step.sub != null) Text(step.sub!, style: ts.small.copyWith(color: c.faint)),
                ],
              ),
            ),
          ),
          Text(
            step.time,
            style: ts.mono(size: Fs.xs, color: c.faint),
          ),
        ],
      ),
    );
  }
}

/// A payment's actions on one line: [leading] (Cancel, destructive) at the start, [trailing]
/// (the way on, its primary last) at the end; in a narrow pane the end group goes under it.
class TxActionBar extends StatelessWidget {
  const TxActionBar({super.key, this.leading, this.trailing = const []});

  final Widget? leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final end = Wrap(alignment: WrapAlignment.end, spacing: Sp.x2, runSpacing: Sp.x2, crossAxisAlignment: WrapCrossAlignment.center, children: trailing);
    final lead = leading;
    if (lead == null) return Align(alignment: AlignmentDirectional.centerEnd, child: end);
    if (trailing.isEmpty) return Align(alignment: AlignmentDirectional.centerStart, child: lead);
    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      spacing: Sp.x3,
      overflowSpacing: Sp.x2,
      overflowAlignment: OverflowBarAlignment.end,
      children: [lead, end],
    );
  }
}

/// A payment's [TxActionBar] pinned at a page's bottom (the narrow Activity's detail page):
/// the pane's foot in the page's gutter, a hairline over it.
class TxPageActions extends StatelessWidget {
  const TxPageActions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      key: const ValueKey('tx-actions-bar'),
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < Bp.phone ? Sp.x4 : Sp.x6, vertical: Sp.x3),
      decoration: BoxDecoration(color: c.s1, border: Border(top: BorderSide(color: c.line))),
      child: child,
    );
  }
}

/// A sub-header with ghost buttons at its end.
class _SubBar extends StatelessWidget {
  const _SubBar(this.title, this.actions);

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Sp.x6, bottom: Sp.x2),
    // The buttons drop under the title when the panel is too narrow for both.
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: Sp.x1,
      children: [
        Semantics(header: true, child: Text(title, style: context.ts.label)),
        Wrap(spacing: Sp.x1, children: actions),
      ],
    ),
  );
}

class _Sub extends StatelessWidget {
  const _Sub(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Sp.x6, bottom: Sp.x3),
    child: Semantics(header: true, child: Text(title, style: context.ts.label)),
  );
}

/// Asks before cancelling an unfinished send, or an incoming payment the node has not seen.
/// Null and [CancelChoice.keep] both mean don't cancel. A send both wallets signed that the
/// network refused offers Keep / Stop waiting / Cancel for sure (cancel_choice.dart); a send
/// still waiting, and a received payment, one free cancel.
Future<CancelChoice?> showCancelTxDialog(BuildContext context, Tx t) => showEDialog<CancelChoice>(
  context,
  builder: (context) {
    final l = context.l10n;
    final twoWays = !t.incoming && t.notPosted;
    final anchor = t.incoming ? HelpAnchor.receiving : HelpAnchor.sending;
    // One calm sentence, the buttons say the rest (the owner, 2026-10-30); a received payment
    // is checked against the network first.
    return EDialog(
      title: t.incoming ? l.deskTxCancelIncomingTitle : l.deskTxCancelOutgoingTitle,
      icon: EIcons.cancel,
      tone: ETone.neutral,
      // The amount as the details show it, exact, kept on one line with its unit.
      description: t.incoming
          ? l.txDetailsCancelReceiveBody
          : keepNumbersWithUnits(
              twoWays
                  ? l.deskTxCancelNotPostedBody(EMoney.figure(l, t.amount, surface: AmountSurface.exact), whoOf(l, t))
                  : l.deskTxCancelOutgoingBody(EMoney.figure(l, t.amount, surface: AmountSurface.exact), whoOf(l, t)),
            ),
      body: twoWays ? DeskCancelChoices(anchor: anchor) : DeskCancelNote(anchor: anchor, inDialog: true),
      // Named by outcome (B-04): Keep and Unlock coins outlined, Move coins back the one
      // primary where both ways are offered; a plain cancel keeps its risk outline.
      actions: [
        EButton(label: l.deskTxCancelKeep, onPressed: () => Navigator.pop(context, CancelChoice.keep)),
        if (twoWays) EButton(label: l.cancelUnlockOpen, onPressed: () => Navigator.pop(context, CancelChoice.stopWaiting)),
        if (twoWays)
          EButton.primary(label: l.cancelMoveBack, onPressed: () => Navigator.pop(context, CancelChoice.cancelForSure))
        else
          EButton(
            label: t.incoming ? l.deskTxCancelIncomingAction : l.deskTxCancelOutgoingAction,
            kind: EBtnKind.danger,
            onPressed: () => Navigator.pop(context, CancelChoice.cancelForSure),
          ),
      ],
    );
  },
);

/// "From" on a withdrawal: the paired contact by name; not in the contacts yet, Add to
/// contacts, as Settings › Invoices offers it.
class _PairedFrom extends ConsumerWidget {
  const _PairedFrom({required this.pairingId, required this.name});

  final String pairingId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = ref.watch(deskPairingByIdProvider(pairingId));
    final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
    final saved = r?.contactId != null && contacts.any((c) => c.id == r!.contactId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        if (r != null && !saved) ...[
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              if (deskSuggestedContact(ref, r) case final c?)
                EButton.primary(label: l.pairAddToNamed(c.name), size: EBtnSize.sm, onPressed: () => deskAttachPairing(context, ref, r, c)),
              DeskAddToContactsButton(record: r),
            ],
          ),
        ],
      ],
    );
  }
}
