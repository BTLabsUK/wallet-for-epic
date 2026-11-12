// SPDX-License-Identifier: Apache-2.0
/// The one model of where a payment stands, for every phone screen that shows steps: the payment
/// page, and the Send and Receive screens after a payment is made or arrives. A pure function of
/// the transaction, the chain's tip and the clock, so a screen and its test see the same steps.
///
/// Sending: Sent → Waiting for Tom → In the network, waiting for a block → Confirmed.
/// Receiving: Arriving → Sender finished → In the network, waiting for a block → Confirmed.
/// A request this wallet sent: Requested → Paid → network → Confirmed.
///
/// The current step carries one line saying why the payment is there ([PaymentProgress.reason]).
/// The network step is the one where the payment is on the network and no block has it yet:
/// [PaymentProgress.network] is true while it is current, and the screen draws the animated
/// network mark for it ([KitStep.network]). Steps go back when the payment drops back: a send
/// that was not delivered shows its first step as the current one, a finished send that is not
/// posted (reposting, Kill switch) shows the network step as current without the animation.
///
/// There are no steps ([paymentProgress] is null) for a payment another wallet made, a
/// restored one, a mining reward, a cancelled one and one from a history backup: those have a
/// status line, not a journey.
library;

import '../l10n.dart';
import '../models.dart';
import '../network_gate.dart' show NetGate;
import '../stall_retry.dart' show invoicePaymentStalled;
import '../watch_mode.dart' show BlockWait;
import 'common.dart';
import 'finished_not_posted.dart' show isPostElsewhere;
import 'kit/kit_steps.dart' show KitStep, KitStepState;

/// The steps of one payment and where it is.
class PaymentProgress {
  const PaymentProgress({required this.steps, required this.current, required this.reason, required this.network});

  /// Four steps, each done, the current one, or later; a done step carries its time when the
  /// wallet knows it, the current one its [reason].
  final List<KitStep> steps;

  /// The index of the current step; [steps] length when every step is done.
  final int current;

  /// One line on why the payment is at the current step; null when it is completed.
  final String? reason;

  /// The current step is the network step and the payment is on the network (not posted
  /// elsewhere or reposting): the animated network mark.
  final bool network;

  /// Every step is done.
  bool get completed => current >= steps.length;
}

/// The progress of [tx] at chain height [tip] and time [now], or null where steps say nothing.
///
/// [who] is the other side's name (null: "the recipient" or "the sender"), [target] the
/// confirmations the wallet counts a payment complete at, [reserved] the formatted amount a
/// waiting send keeps set aside ("12.508 EPIC"), [wait] why a payment past its watch window is
/// still in no block, [paused] that Epicbox is off, [killSwitch] that every connection is held,
/// [clockAt] that a step done today carries "at 18:12" instead of "Today 18:12".
PaymentProgress? paymentProgress(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  required DateTime now,
  String? who,
  int? target,
  String? reserved,
  BlockWait wait = BlockWait.none,
  bool paused = false,
  bool killSwitch = false,
  bool clockAt = false,
}) {
  if (tx.source != TxSource.wallet || tx.kind == TxKind.coinbase || tx.origin != TxOrigin.thisWallet) return null;
  final phase = txPhase(tx, tip, target: target);
  final goal = target ?? confirmationsTarget;
  final confirmations = txConfirmations(tx, tip) ?? 0;
  final outgoing = tx.kind == TxKind.sent || tx.kind == TxKind.sentCancelled;
  final request = tx.isRequest;
  final name = who;

  final List<String> labels;
  if (request) {
    labels = [l.txStepRequested, l.txStepPaid, l.phoneProgNetwork, l.txStepConfirmed];
  } else if (outgoing) {
    labels = [
      l.phoneProgSent,
      // The frame's words for the second step: it is the other wallet that answers.
      name == null ? l.phoneProgWaitingAnswer : l.phoneProgWaitingAnswerNamed(name),
      l.phoneProgNetwork,
      l.txStepConfirmed,
    ];
  } else {
    labels = [l.lvPayArriving, l.phoneProgSenderFinished, l.phoneProgNetwork, l.txStepConfirmed];
  }

  // The current step and its reason.
  final int at;
  String? reason;
  var network = false;
  switch (phase) {
    case TxPhase.cancelled || TxPhase.fromBackup || TxPhase.maturing:
      return null;
    case TxPhase.completed:
      at = 4;
    case TxPhase.waitingPayer:
      at = 1;
      reason = name == null ? l.phoneProgPayerPending : l.phoneProgPayerPendingNamed(name);
    case TxPhase.waitingRecipient:
      if (!outgoing) {
        at = 0;
        reason = name == null ? l.phoneProgSenderPending : l.phoneProgSenderPendingNamed(name);
      } else if (tx.undelivered || invoicePaymentStalled(tx, now)) {
        // It never went out: back to the first step, with the status the wallet already words.
        at = 0;
        reason = txStatusLabel(l, tx, tip, target: target, now: now, paused: paused);
      } else if (paused) {
        at = 0;
        reason = l.contactPausedEpicboxOff;
      } else {
        at = 1;
        reason = _waitingReason(l, tx, name, reserved);
      }
    case TxPhase.waitingSender:
      if (senderCancelled(tx)) return null;
      if (senderReportsPosted(tx, now: now)) {
        at = 2;
        network = true;
        reason = name == null ? l.phoneProgReported : l.phoneProgReportedNamed(name);
      } else {
        at = 0;
        reason = name == null ? l.phoneProgSenderPending : l.phoneProgSenderPendingNamed(name);
      }
    case TxPhase.confirming:
      if (outgoing && toPostElsewhere(tx, killSwitch: killSwitch)) {
        at = 2;
        reason = l.phoneProgPostElsewhere;
      } else if (outgoing && tx.posting) {
        at = 2;
        network = true;
        reason = l.phoneProgPosting;
      } else if (outgoing && (tx.repostable || killSwitch && tx.blockHeight == null)) {
        at = 2;
        reason = killSwitch ? l.phoneProgKillSwitch : l.phoneProgNotPosted;
      } else if (tx.blockHeight == null || confirmations < 1) {
        at = 2;
        network = true;
        reason = switch (wait) {
          BlockWait.noNewBlock => l.phoneProgNoNewBlock,
          BlockWait.notInBlock => l.phoneProgNotInBlock,
          BlockWait.none => l.phoneProgInNetwork,
        };
      } else {
        at = 3;
        reason = l.lvPayConfirming(confirmations, goal);
      }
  }

  // The times the wallet knows: the first step when the record began, the network step when
  // this wallet finalized the send, the last when its block was found.
  String? time(int? unix) {
    if (unix == null || unix <= 0) return null;
    final at = localTime(unix);
    // "Today 18:12", as the frames print it; the contact page's bubble: "at 18:12".
    if (clockAt && daysAgo(at, now) == 0) return l.phoneProgAtTime(localClock(l, at));
    return daysAgo(at, now) == 0 ? '${l.dateToday} ${localClock(l, at)}' : shortDate(l, at, now);
  }
  final times = <String?>[
    time(tx.createdAtUnix),
    null,
    outgoing ? time(tx.finalizedAtUnix) : null,
    tx.status == TxStatus.confirmed ? time(tx.blockTimeUnix) : null,
  ];

  return PaymentProgress(
    steps: [
      // The frames draw three steps until the payment is on the network; the network step
      // joins when it is the current one or past.
      for (var i = 0; i < 4; i++)
        if (i != 2 || at >= 2)
        KitStep(
          title: labels[i],
          state: i < at ? KitStepState.done : (i == at ? KitStepState.now : KitStepState.later),
          detail: i < at ? times[i] : (i == at ? reason : null),
          network: i == 2,
        ),
    ],
    current: at,
    reason: reason,
    network: network,
  );
}

/// Why a send waits for the other side's answer, by how it travels.
String _waitingReason(AppLocalizations l, TxEntry tx, String? who, String? reserved) {
  final answer = switch (tx.transport) {
    'epicbox' => who == null ? l.phoneProgAnswersEpicbox : l.phoneProgAnswersEpicboxNamed(who),
    'file' => who == null ? l.phoneProgAnswersFile : l.phoneProgAnswersFileNamed(who),
    _ => who == null ? l.phoneProgAnswersLive : l.phoneProgAnswersLiveNamed(who),
  };
  return reserved == null ? answer : '$answer ${l.phoneProgSetAside(reserved)}';
}

/// The word under a row's name in the Activity list while a payment is open: "Waiting for Tom",
/// "Arriving", "Confirming 1 of 3", "Posted". The same words as the level screens' plain style,
/// without the level: the phone shows one wording to everyone. [who] is the other side's name,
/// [pairedWith] the payee of a paired send.
String paymentRowWord(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  int? target,
  DateTime? now,
  String? who,
  String? pairedWith,
  bool paused = false,
}) {
  final today = txStatusLabel(l, tx, tip, target: target, now: now, pairedWith: pairedWith, paused: paused);
  return switch (txPhase(tx, tip, target: target)) {
    TxPhase.waitingRecipient when tx.undelivered || pairedWith != null => today,
    TxPhase.waitingRecipient when now != null && invoicePaymentStalled(tx, now) => today,
    TxPhase.waitingRecipient => who == null ? l.txStatusWaitingRecipient : l.txStatusWaitingFor(who),
    TxPhase.waitingSender when senderCancelled(tx) || pairedWith != null => today,
    TxPhase.waitingSender when now != null && senderReportsPosted(tx, now: now) => today,
    TxPhase.waitingSender => l.lvPayArriving,
    TxPhase.confirming when isPostElsewhere(tx) || tx.repostable || tx.posting || NetGate.killSwitch => today,
    TxPhase.confirming => switch (txConfirmations(tx, tip) ?? 0) {
      0 => l.lvPolPosted,
      final n => l.lvPayConfirming(n, target ?? confirmationsTarget),
    },
    _ => today,
  };
}
