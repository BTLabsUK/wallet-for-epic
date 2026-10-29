// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../known_relays.dart' show recipientRelay;
import '../../../devices/device_ending.dart' show deviceEndingLabel, deviceEndingLine;
import '../../../l10n.dart' show acceptedAgoText, messageHint;
import '../../../models.dart' show IncomingCancel, PairingRecord, PairingState, SlatePurpose, incomingCancelAt;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../../watch_mode.dart' show BlockWait;
import '../../data/clock.dart';
import '../../data/invoice_state.dart' show PayState, deskInvoicesProvider;
import '../../data/lepic_desk_wallet.dart' show cancelRefusedText, deskErrorText;
import '../../data/pairing_state.dart' show DeskPairNet, deskPairNetProvider, deskPairingByIdProvider, deskPairingNameProvider, deskPairingSlateProvider;
import '../pairing/pair_screens.dart' show deskAttachPairing, deskPutPairingInContacts, deskSuggestedContact;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../invoices/tx_invoice_block.dart';
import 'cancel_note.dart';
import '../../../help/help_content.dart' show HelpAnchor;
import 'tx_details_dialog.dart';
import 'tx_display.dart';
import '../settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import 'other_wallet_offer.dart';
import 'tx_label.dart';
import 'contacts_screen.dart' show ContactsArgs;
import '../../../recipient.dart' show parseRecipient, recipientShaped;

/// The screenshot tour presses More on the open transaction.
final txMoreDemoProvider = NotifierProvider<TxMoreDemo, bool>(TxMoreDemo.new);

class TxMoreDemo extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
}

/// One transaction: amount and counterparty, where it stands, its progress, details, proof,
/// technical details and the actions it allows (cancel, finalize).
class TxDetail extends ConsumerStatefulWidget {
  const TxDetail({super.key, required this.tx, this.showTitle = false});

  final Tx tx;

  /// Starts with the title (the label's field), for a layout whose page title is a plain string.
  final bool showTitle;

  @override
  ConsumerState<TxDetail> createState() => _TxDetailState();
}

class _TxDetailState extends ConsumerState<TxDetail> {
  bool _cancelling = false;

  /// The node already had this receive when Cancel was asked: Cancel stays away for this visit.
  int? _onNetworkFor;

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
      : hold.offered
      ? '${acceptedAgoText(l, hold.signedAgo)} ${l.txDetailsCancelOffered}'
      : '${acceptedAgoText(l, hold.signedAgo)} ${l.txDetailsCancelHold(hold.holdMinutesLeft)}';

  /// The More link is open: the technical rows show for this view only.
  bool _more = false;

  String _now(AppLocalizations l, Tx t) => t.fromBackup
      ? l.deskTxNowBackup
      : t.otherWallet
      ? (t.incoming
            ? l.txDetailsOtherWalletIn
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
          TxState.posted when t.notPosted => l.deskTxNowNotPosted,
          TxState.posted => l.deskTxNowPosted,
          TxState.confirming => l.deskTxNowConfirming(t.confirmations, t.confirmationsNeeded),
          TxState.confirmed => l.deskTxNowConfirmed(t.confirmations),
          // The wallet keeps looking for a cancelled receive, so a late post still arrives.
          TxState.cancelled when t.deviceEnding != null =>
            deviceEndingLine(l, t.deviceEnding!, t.deviceName ?? '', t.deviceWhy) ?? deviceEndingLabel(l, t.deviceEnding!, t.deviceName ?? ''),
          TxState.cancelled when t.incoming && !t.isInvoice && t.senderCancelled => l.txDetailsSenderCancelled,
          TxState.cancelled when t.incoming && !t.isInvoice => l.txDetailsCancelledIncoming,
          TxState.cancelled => l.deskTxNowCancelled,
        };

  /// The core's own fields: ids, height, kernel, status and type.
  /// The phone's block explorer link (GP-015): the kernel on Floonet, the block on mainnet,
  /// once the payment is confirmed; null before that.
  String? _explorerUrl(Tx t) {
    if (t.state != TxState.confirmed) return null;
    final settings = ref.watch(hostSettingsProvider);
    final kernel = t.kernel;
    final byKernel = kernel == null ? null : settings.explorerKernel(kernel);
    if (byKernel != null) return byKernel;
    final height = t.height;
    return height == null ? null : settings.explorerBlock(height);
  }

  Widget _techFacts(Tx t, AppLocalizations l, DeskText ts) {
    final url = _explorerUrl(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _techRows(t, l, ts),
        if (url != null) ...[
          SizedBox(height: Sp.x2),
          ECopyButton(key: const ValueKey('tx-explorer-link'), text: url, label: l.txDetailsExplorerLink, withLabel: true),
        ],
      ],
    );
  }

  Widget _techRows(Tx t, AppLocalizations l, DeskText ts) =>
      EFacts(labelWidth: 96.u, [
            (l.deskTxTechId, Text('${t.id}', style: ts.mono(size: Fs.xs))),
            (
              l.deskTxTechSlate,
              Row(
                children: [
                  Expanded(
                    child: Text(t.slateId.isEmpty ? '-' : t.slateId, style: ts.mono(size: Fs.xs)),
                  ),
                  if (t.slateId.isNotEmpty) ECopyButton(text: t.slateId, label: l.deskTxCopySlate),
                ],
              ),
            ),
            (l.deskTxTechHeight, Text(t.height == null ? '-' : '${t.height}', style: ts.mono(size: Fs.xs))),
            (l.deskTxTechKernel, Text(t.kernel ?? '-', style: ts.mono(size: Fs.xs))),
            (l.deskTxTechConfirmed, Text(t.confirmedAt == null ? '-' : dateTimeOf(l, t, at: t.confirmedAt))),
            (l.deskTxTechCredited, EMoney(t.incoming ? t.amount : 0, unit: false)),
            (l.deskTxTechDebited, EMoney(t.incoming ? 0 : t.amount + t.fee, unit: false)),
            (l.deskTxTechStatus, Text(t.state.name, style: ts.mono(size: Fs.xs))),
            (l.deskTxTechType, Text(t.coinbase ? 'ConfirmedCoinbase' : (t.incoming ? 'TxReceived' : 'TxSent'), style: ts.mono(size: Fs.xs))), // l10n-ok: the core's type names
          ]);

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

  Future<void> _cancel() async {
    final ok = await showCancelTxDialog(context, widget.tx);
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(widget.tx.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      // The node already has a receive: not a failure, the payment is on its way (as the phone says).
      if (widget.tx.incoming && e is DeskError && e.message == cancelRefusedText) {
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
    showEToast(context, context.l10n.deskTxCancelled, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final t = widget.tx;
    ref.listen(txMoreDemoProvider, (_, open) {
      if (open && !_more) setState(() => _more = true);
    });
    final total = t.amount + (t.incoming ? 0 : t.fee);
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
    final finalizable = !t.fromBackup && !t.incoming && !t.isInvoice && t.method == TxMethod.file && t.state == TxState.waitingRecipient && mailboxName == null;
    // The node refused it: broadcast it again at once (android-17); the app also does by itself.
    final repostable = !t.fromBackup && !t.isInvoice && t.notPosted;
    // A payment to a paired contact's request, or a withdrawal from a paired exchange: the
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
    return Column(
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
                              // A withdrawal is from the paired exchange, by name.
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
                    Text(mailboxName != null && !t.incoming && t.state == TxState.waitingRecipient && !t.undelivered ? l.deskTxStatusWaitingFor(mailboxName) : _now(l, t), style: ts.body),
                    // Its sender cancelled it: Cancel is there at once, with no line to weigh.
                    if (hold != null && !hold.senderCancelled) ...[
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
        // A withdrawal from a paired exchange, not yet posted by it.
        if (withdrawal != null && !onChain) ...[
          SizedBox(height: Sp.x3),
          ENotice(title: l.reqReceivedWaiting(contactName), text: l.reqReceivedWaitingBody, tone: ETone.info),
        ],
        // An invoice-flow transaction: the invoice behind it, in the Invoices page's words.
        if (t.isInvoice) TxInvoiceBlock(tx: t),
        if (paidTo != null && t.isInvoice && t.state != TxState.cancelled) ...[_Sub(l.deskTxSubProgress), for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1)],
        if (t.state != TxState.cancelled && !t.senderCancelled && !t.fromBackup && !t.isInvoice && !t.otherWallet) ...[_Sub(l.deskTxSubProgress), for (final (i, st) in steps.indexed) _TimelineStep(step: st, last: i == steps.length - 1)],
        _SubBar(
          l.deskTxSubDetails,
          [
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
          // A withdrawal names the paired exchange, never its address (RFC C-21).
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
            )
          // A QR code or file exchange carries no address: the row says so rather than
          // leaving the payment with no other side.
          else if (noAddressShown(t))
            (t.incoming ? l.txDetailsReceivedFrom : l.txDetailsSentTo, Text(l.txDetailsNoAddress, key: const ValueKey('tx-fact-no-address'))),
          if (!t.otherWallet)
            (
              l.deskTxFactMethod,
              t.foundByScan
                  ? _withTag(t, ManualField.transport, Text(restoredMethodOf(l, t) ?? '–'))
                  : Text(methodLabel(l, mailboxName != null ? TxMethod.epicbox : t.method)),
            ),
          (l.deskTxFactAmount, EMoney(t.amount)),
          // The other wallet paid the fee: this wallet only saw the coins leave.
          if (!t.incoming && t.otherWallet) (l.deskTxFactFee, Text(l.txDetailsNotKnown))
          else if (!t.incoming) ...[(l.deskTxFactFee, EMoney(t.fee)), (l.deskTxFactTotal, EMoney(total, weight: FontWeight.w600))],
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
        if (DeskFeatures.paymentProofs && t.hasProof) ...[
          _Sub(l.deskTxPaymentProof),
          Row(
            children: [
              Icon(EIcons.proof, size: Ctl.iconSm, color: c.ok),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskTxSignedByRecipient, style: ts.small)),
              EButton(label: l.deskTxProofView, kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => showTxProofDialog(context, t)),
            ],
          ),
        ],
        // Advanced › Technical details: the fold, or a small More link that shows the same rows
        // for this view only (the switch stays off). Report a problem carries the slate id either way.
        if (advancedHas(ref, AdvancedFeature.technicalDetails)) ...[
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
        if (t.otherWallet) DeskSentFromOtherWalletOffer(incoming: t.incoming),
        if (cancelable || finalizable || t.undelivered || repostable) ...[
          SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          SizedBox(height: Sp.x4),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (cancelable)
                EButton(
                  label: _cancelling ? l.deskTxCancelling : (t.incoming ? l.deskTxCancelIncomingAction : l.deskTxCancelOutgoingAction),
                  icon: EIcons.cancel,
                  // A receive's Cancel is a tidy-up for a payment the sender never posted, so
                  // it stays quiet; a send's unlocks funds.
                  kind: t.incoming && !t.senderCancelled ? EBtnKind.ghost : EBtnKind.danger,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _cancel,
                ),
              if (t.undelivered)
                EButton.primary(
                  label: context.l10n.deskTxSendAgain,
                  icon: EIcons.refresh,
                  size: EBtnSize.sm,
                  busy: _cancelling,
                  onPressed: _sendAgain,
                ),
              if (repostable)
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
            ],
          ),
          // What this Cancel does, with the way to the Help topic, on its own line under the
          // buttons (an incoming payment's line sits in the status box above).
          if (cancelable && (!t.incoming || hold == null)) ...[
            SizedBox(height: Sp.x2),
            DeskCancelNote(
              key: const ValueKey('tx-cancel-note'),
              text: t.incoming
                  ? l.txDetailsCancelOffered
                  : t.notPosted
                  ? l.cancelNoteNotPosted
                  : l.cancelNoteSendWaiting,
              anchor: t.incoming ? HelpAnchor.receiving : HelpAnchor.sending,
            ),
          ],
        ],
      ],
    );
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
      _Step(l.reqTlDelivered(name), delivered ? _S.done : _S.now, '', sub: delivered ? null : l.reqRelayRetrying),
      _Step(l.reqTlPosted(name), posted ? _S.done : (delivered ? _S.now : _S.todo), '', sub: !posted && delivered ? l.reqTlPostedHint : null),
      _Step(
        done ? l.reqTlConfirmed : l.reqTlConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        '',
        sub: inBlock && !done ? l.reqTlConfirmingHint(t.confirmations, t.confirmationsNeeded) : null,
      ),
    ];
  }

  /// A withdrawal from a paired exchange (RFC 12.5): the answer delivered to its relay, Posted
  /// by it, the confirmations.
  List<_Step> _withdrawalSteps(AppLocalizations l, Tx t, String name) {
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(l.reqTlAnswerDelivered(name), _S.done, ''),
      _Step(l.reqTlPosted(name), inBlock ? _S.done : _S.now, '', sub: inBlock ? null : l.reqTlPostedHint),
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
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || (t.state == TxState.posted && !t.notPosted);
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(
        l.txStepSentMailbox(name),
        queued ? _S.now : _S.done,
        queued ? '' : timeOf(t),
        sub: queued ? l.contactPausedEpicboxOff : (relay.isEmpty ? null : l.contactDeliveredVia(relay)),
      ),
      _Step(l.txStepAnswerFrom(name), queued ? _S.todo : (waiting ? _S.now : _S.done), '', sub: waiting && !queued ? l.txStepCollecting(name) : null),
      _Step(l.deskTxStepPosted, posted ? _S.done : (!waiting && !inBlock ? _S.now : _S.todo), ''),
      _Step(
        l.deskTxStepConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        '',
        sub: t.state == TxState.confirming ? l.deskTxStepProgress(t.confirmations, t.confirmationsNeeded) : null,
      ),
      _Step(l.deskTxStepSpendable, done ? _S.done : _S.todo, ''),
    ];
  }

  /// The warn notices on a send waiting for [name]'s answer: keys changed, relay silent.
  List<Widget> _mailboxNotices(AppLocalizations l, String name, PairingRecord p) => [
    if (p.state == PairingState.keysChanged) ...[
      SizedBox(height: Sp.x3),
      ENotice(key: const ValueKey('tx-mailbox-keys'), title: l.contactKeysChangedTitle(name), text: l.contactKeysChangedBody, tone: ETone.warn),
    ] else if (p.relayDown) ...[
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
    // An incoming payment is on record only once this wallet signed it; it then waits for the
    // sender to post it.
    final signed = t.incoming || t.state != TxState.waitingRecipient;
    final waitingSender = t.incoming && t.state == TxState.waitingRecipient;
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || (t.state == TxState.posted && !t.notPosted);
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    final done = t.state == TxState.confirmed;
    return [
      _Step(t.incoming ? l.deskTxStepReceivedSlate : l.deskTxStepCreated, _S.done, hm(Duration.zero)),
      _Step(
        t.incoming ? l.deskTxStepSignedReturned : l.deskTxSignedByRecipient,
        signed ? _S.done : _S.now,
        // Only a time the record has: this wallet signs a payment the moment it takes it in;
        // when the recipient signed, or the payment was posted, it does not keep (LNX-13).
        signed && t.incoming ? hm(Duration.zero) : '',
        sub: signed ? null : (t.method == TxMethod.file ? l.deskTxStepWaitingFile : l.deskTxStepWaitingRecipient),
      ),
      _Step(
        l.deskTxStepPosted,
        posted ? _S.done : (waitingSender ? _S.now : _S.todo),
        '',
        sub: waitingSender ? (t.senderPosted ? l.deskTxStatusSenderPosted : l.deskTxStatusWaitingSender) : null,
      ),
      _Step(
        l.deskTxStepConfirming,
        done ? _S.done : (inBlock ? _S.now : _S.todo),
        '',
        sub: t.state == TxState.confirming ? l.deskTxStepProgress(t.confirmations, t.confirmationsNeeded) : null,
      ),
      _Step(l.deskTxStepSpendable, done ? _S.done : _S.todo, ''),
    ];
  }
}

enum _S { done, now, todo }

class _Step {
  const _Step(this.title, this.state, this.time, {this.sub});

  final String title;
  final _S state;
  final String time;
  final String? sub;
}

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
Future<bool?> showCancelTxDialog(BuildContext context, Tx t) => showEDialog<bool>(
  context,
  builder: (context) {
    final l = context.l10n;
    // A send the recipient has not answered is certain to cancel; one the node refused after
    // both signed, and a received payment, are checked against the network first.
    return EDialog(
      title: t.incoming ? l.deskTxCancelIncomingTitle : l.deskTxCancelOutgoingTitle,
      icon: EIcons.cancel,
      tone: ETone.risk,
      description: t.incoming
          ? l.txDetailsCancelReceiveBody
          : t.notPosted
          ? l.deskTxCancelNotPostedBody(formatEpicL(l, t.amount), whoOf(l, t))
          : l.deskTxCancelOutgoingBody(formatEpicL(l, t.amount), whoOf(l, t)),
      body: DeskCancelNote(anchor: t.incoming ? HelpAnchor.receiving : HelpAnchor.sending, inDialog: true),
      actions: [
        EButton(label: l.deskTxCancelKeep, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
        EButton(label: t.incoming ? l.deskTxCancelIncomingAction : l.deskTxCancelOutgoingAction, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  },
);

/// The payment proof: who signed what, with copy and export. Shows what the transaction carries;
/// without a proof (or without its sender and signature) it says so and offers nothing to export.
String? _some(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

Future<void> showTxProofDialog(BuildContext context, Tx t) => showEDialog<void>(
  context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final ts = context.ts;
      final l = context.l10n;
      Widget field(String label, String copyLabel, String value) => Padding(
        padding: EdgeInsets.only(bottom: Sp.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: ts.small),
            SizedBox(height: Sp.x1),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: ts.mono(size: Fs.xs),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ECopyButton(text: value, label: copyLabel),
              ],
            ),
          ],
        ),
      );
      final sender = _some(t.proofSender), signature = _some(t.proofSignature);
      if (!t.hasProof || (sender == null && signature == null)) {
        return EDialog(
          title: l.deskTxPaymentProof,
          icon: EIcons.proof,
          width: 520.u,
          body: Text(l.deskTxProofNone, style: ts.body),
          actions: [EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: () => Navigator.pop(context))],
        );
      }
      // An address the user typed is not what the payment's proof is about: never shown here.
      final recipient = t.manualFields.contains(ManualField.counterparty) ? null : _some((t.counterparty ?? '').split('@').first);
      return EDialog(
        title: l.deskTxPaymentProof,
        icon: EIcons.proof,
        tone: ETone.ok,
        description: t.incoming ? l.deskTxProofIncoming(formatEpicL(l, t.amount)) : l.deskTxProofOutgoing(formatEpicL(l, t.amount)),
        width: 520.u,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_some(t.kernel) != null) field(l.deskTxTechKernel, l.deskTxProofCopyKernel, t.kernel!),
            if (sender != null) field(l.deskTxProofSenderAddress, l.deskTxProofCopySender, sender),
            if (recipient != null) field(l.deskTxProofRecipientAddress, l.deskTxProofCopyRecipient, recipient),
            if (signature != null) field(l.deskTxProofRecipientSignature, l.deskTxProofCopySignature, signature),
          ],
        ),
        actions: [
          EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
          EButton.primary(
            label: l.deskTxProofExport,
            icon: EIcons.download,
            size: EBtnSize.sm,
            onPressed: () async {
              final path = await ref.read(deskApiProvider).exportProof(t.id);
              if (context.mounted) {
                showEToast(context, l.deskTxProofSaved, text: path, tone: ETone.ok);
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  ),
);

/// "From" on a withdrawal: the paired exchange by name; not in the contacts yet, Save as a
/// new contact and Add to a contact, as Settings › Invoices offers them.
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
              EButton(label: l.pairSaveNewContact, size: EBtnSize.sm, onPressed: () => deskPutPairingInContacts(context, ref, r, asNew: true)),
              EButton(label: l.pairAddToAContact, size: EBtnSize.sm, onPressed: () => deskPutPairingInContacts(context, ref, r, asNew: false)),
            ],
          ),
        ],
      ],
    );
  }
}
