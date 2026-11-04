// SPDX-License-Identifier: Apache-2.0
/// The payment steps the level-aware screens share: the step word a row shows as its sub-line
/// ([paymentStepWord]), the steps with their known times ([paymentSteps]) and the live timeline
/// ([PaymentTimeline]). Derived from the transaction and the node tip, never invented: a step
/// shows a time only when the wallet knows it.
///
/// Sending: Payment started → (Recipient) signed → Posted to the network → Confirming (n of N)
/// → Completed. Receiving: Payment arrived → Sender finished → Posted → Confirming → Completed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/level_features.dart';
import '../../network_gate.dart' show NetGate;
import '../../pairing_providers.dart' show PairNet, pairNetProvider;
import '../../settings.dart' show clockProvider;
import '../../stall_retry.dart' show invoicePaymentStalled;
import '../../levels/level_providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../finished_not_posted.dart' show isPostElsewhere;
import '../send_tracker.dart' show RoundSteps;
import '../theme/protocol.dart' show TimelineState, TimelineStep;

/// The step word of [tx] for a row's sub-line: "Waiting for Alice", "Arriving",
/// "Confirming 1 of 3", "Received", "Sent". [who] is the other side's name when known. With
/// [TimelineStyle.technicalSteps] (level 3) it is today's status label, unchanged.
String paymentStepWord(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  required TimelineStyle style,
  int? target,
  DateTime? now,
  String? who,
  String? pairedWith,
  bool paused = false,
}) {
  final today = txStatusLabel(l, tx, tip, target: target, now: now, pairedWith: pairedWith, paused: paused);
  if (style == TimelineStyle.technicalSteps) return today;
  return switch (txPhase(tx, tip, target: target)) {
    // Not delivered / stalled keep their own words.
    TxPhase.waitingRecipient when tx.undelivered || pairedWith != null => today,
    TxPhase.waitingRecipient when now != null && invoicePaymentStalled(tx, now) => today,
    TxPhase.waitingRecipient => who == null ? l.txStatusWaitingRecipient : l.txStatusWaitingFor(who),
    // The sender's word and cancel notes keep theirs; otherwise the payment is on its way in.
    TxPhase.waitingSender when senderCancelled(tx) || pairedWith != null => today,
    TxPhase.waitingSender when now != null && senderReportsPosted(tx, now: now) => today,
    TxPhase.waitingSender => l.lvPayArriving,
    TxPhase.confirming when isPostElsewhere(tx) || tx.repostable || tx.posting || NetGate.killSwitch => today,
    // Taken by the network but in no block yet: "Posted", never "Confirming 0 of 3".
    TxPhase.confirming => switch (txConfirmations(tx, tip) ?? 0) {
      0 => l.lvPolPosted,
      final n => l.lvPayConfirming(n, target ?? confirmationsTarget),
    },
    _ => today,
  };
}

/// The step word for a row, with the level, the name, the target and the clock taken from [ref].
String paymentStepWordOf(WidgetRef ref, TxEntry tx, BigInt? tip) {
  final l = ref.context.l10n;
  return paymentStepWord(
    l,
    tx,
    tip,
    style: ref.watch(levelFeaturesProvider.select((f) => f.timeline)),
    target: confirmationsTargetOf(ref),
    now: ref.watch(clockProvider)(),
    who: txPartyName(ref, tx),
    pairedWith: txPayeeName(ref, tx),
    paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
  );
}

/// The steps of [tx] with the time of each step the wallet knows, or null where steps would add
/// nothing (cancelled, another wallet's, restored). "Recipient signed" names [who].
List<TimelineStep>? paymentSteps(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  int? target,
  DateTime? now,
  String? who,
  ({String name, String relay, bool paused})? mailbox,
  String? waiting,
  String? held,
}) {
  final today = txTimeline(l, tx, tip, target: target, now: now, mailbox: mailbox, waiting: waiting, held: held);
  if (today == null) return null;
  final steps = _plainConfirming(l, today, tx, tip, target: target);
  if (mailbox != null) return steps;
  // Which step carries which known time: started/arrived = when the record began; posted = when
  // this wallet finalized the send; completed = the block's time.
  final times = <int, int?>{
    0: tx.createdAtUnix,
    if (steps.length == 5) 2: tx.finalizedAtUnix,
    steps.length - 1: tx.status == TxStatus.confirmed ? tx.blockTimeUnix : null,
  };
  final outgoing = steps.length == 5;
  return [
    for (final (i, s) in steps.indexed)
      () {
        var label = s.label;
        if (outgoing && i == 1 && who != null && s.label == l.txStepAccepted) label = l.lvPaySigned(who);
        final at = times[i];
        // A step reached (done, or the one under way) shows its time; one not reached has none.
        final known = s.state != TimelineState.todo && at != null && at > 0;
        final time = known ? shortDate(l, localTime(at), now ?? DateTime.now()) : null;
        final detail = metaLine([s.detail, time]);
        return TimelineStep(label, s.state, detail: detail.isEmpty ? null : detail);
      }(),
  ];
}

/// [steps] with the Confirming step in the levels' one format: "Confirming 2 of 3" while blocks
/// come in; with none yet the step before it (Posted to the network, or Paid) is the one under
/// way and Confirming is still to come, so no step ever reads "Confirming 0 of 3".
List<TimelineStep> _plainConfirming(AppLocalizations l, List<TimelineStep> steps, TxEntry tx, BigInt? tip, {int? target}) {
  final n = txConfirmations(tx, tip) ?? 0;
  final t = target ?? confirmationsTarget;
  final todays = l.txStatusConfirming(n, t);
  final i = steps.indexWhere((s) => s.label == todays && s.state == TimelineState.current);
  if (i < 0) return steps;
  final out = [...steps];
  if (n > 0) {
    out[i] = TimelineStep(l.lvPayConfirming(n, t), TimelineState.current, detail: steps[i].detail);
    return out;
  }
  out[i] = TimelineStep(l.txStepConfirming, TimelineState.todo);
  if (i > 0) out[i - 1] = TimelineStep(steps[i - 1].label, TimelineState.current, detail: steps[i - 1].detail);
  return out;
}

/// The live timeline of [tx]: vertical steps, the current one pulsing a few breaths (still under
/// reduced motion) and read out as a live region. Empty where [paymentSteps] is null.
class PaymentTimeline extends ConsumerWidget {
  const PaymentTimeline({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = tipHeight(ref);
    final mailbox = txMailboxName(ref, tx);
    final steps = paymentSteps(
      context.l10n,
      tx,
      tip,
      target: confirmationsTargetOf(ref),
      now: ref.watch(clockProvider)(),
      who: txPartyName(ref, tx),
      mailbox: mailbox == null
          ? null
          : (name: mailbox, relay: '', paused: ref.watch(pairNetProvider) == PairNet.epicboxOff),
    );
    if (steps == null) return const SizedBox.shrink();
    return RoundSteps(steps: steps);
  }
}
