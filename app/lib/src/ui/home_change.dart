// The change of the wallet's open sends, for Home's confirming chip and the balance sheet.
//
// A send spends whole coins: what is left over comes back as change, and LEPIC counts it as
// spendable only after the confirmations the balance counts with. Until then Home shows it in
// one chip, "994.992 confirming · waiting for Tom", and the balance sheet lists each send.

import '../l10n.dart';
import '../models.dart';
import 'common.dart' show TxPhase, txConfirmations, txPhase;

/// What an open send's change waits for.
enum ChangeWait {
  /// The other side has not accepted the send yet: no time can be given.
  reply,

  /// Finalized and posted, not in a block yet: about a block, then the confirmations.
  block,

  /// In a block, confirming.
  confirming,
}

/// One open send with change: the send, the name of its other side ([who], null with none),
/// its change, what it waits for, the minutes until the change can be spent (null while it
/// waits for a reply) and its confirmations so far.
typedef OpenChange = ({
  TxEntry tx,
  String? who,
  BigInt change,
  ChangeWait wait,
  int? minutes,
  int confirmations,
});

/// The sends among [txs] whose change cannot be spent yet: sends that are not cancelled and
/// not completed, with change ([TxEntry.amountCredited]). One block is about one minute: in a
/// block the change needs the confirmations left of [target], at least one; posted it needs a
/// block and then [target]. Sorted by the soonest, the ones waiting for a reply last.
List<OpenChange> openChange(
  Iterable<TxEntry> txs,
  BigInt? tip, {
  required int target,
  String? Function(TxEntry tx)? nameOf,
}) {
  final out = <OpenChange>[];
  for (final tx in txs) {
    if (tx.kind != TxKind.sent || tx.amountCredited <= BigInt.zero) continue;
    final phase = txPhase(tx, tip, target: target);
    if (phase != TxPhase.waitingRecipient && phase != TxPhase.confirming) continue;
    final got = txConfirmations(tx, tip) ?? 0;
    final (wait, minutes) = switch (phase) {
      TxPhase.waitingRecipient => (ChangeWait.reply, null),
      _ when tx.blockHeight == null => (ChangeWait.block, target + 1),
      _ => (ChangeWait.confirming, target - got < 1 ? 1 : target - got),
    };
    out.add((
      tx: tx,
      who: nameOf?.call(tx),
      change: tx.amountCredited,
      wait: wait,
      minutes: minutes,
      confirmations: got,
    ));
  }
  int order(OpenChange c) => c.minutes ?? 1 << 30;
  // A stable sort: the list's own order breaks ties.
  final indexed = out.indexed.toList()
    ..sort((a, b) {
      final by = order(a.$2).compareTo(order(b.$2));
      return by != 0 ? by : a.$1.compareTo(b.$1);
    });
  return [for (final (_, c) in indexed) c];
}

/// The change of [sends] together.
BigInt changeSum(Iterable<OpenChange> sends) =>
    sends.fold(BigInt.zero, (sum, c) => sum + c.change);

/// What of [sends]' change is in a block (counted in [WalletSummary.awaitingConfirmation]).
BigInt changeInBlock(Iterable<OpenChange> sends) => changeSum(
  sends.where((c) => c.wait == ChangeWait.confirming),
);

/// A name for the chip: up to [max] characters, cut at a word with "…" when longer, or at
/// [max] characters when its first word is longer.
String chipName(String name, {int max = 12}) {
  final s = name.trim();
  if (s.length <= max) return s;
  var cut = '';
  for (final word in s.split(RegExp(r'\s+'))) {
    final next = cut.isEmpty ? word : '$cut $word';
    if (next.length > max) break;
    cut = next;
  }
  if (cut.isEmpty) cut = s.substring(0, max);
  return '$cut…';
}

/// The chip's words for [sends] (not empty), with [amount] already shown: what a single send
/// waits for, else the soonest time, else how many replies are awaited.
String changeChipText(AppLocalizations l, List<OpenChange> sends, String amount) {
  final timed = sends.where((c) => c.minutes != null).toList();
  if (timed.isEmpty) {
    if (sends.length > 1) return l.phoneChangeWaitingReplies(amount, sends.length);
    final who = sends.single.who?.trim();
    return who == null || who.isEmpty
        ? l.phoneChangeWaitingReply(amount)
        : l.phoneChangeWaitingFor(amount, chipName(who));
  }
  final soonest = timed.first.minutes!;
  return sends.length == 1 ? l.phoneChangeAbout(amount, soonest) : l.phoneChangeNextIn(amount, soonest);
}

/// How far the soonest of [sends] is, for the chip's ring: null (an hourglass) while every send
/// waits for a reply, a short arc while the soonest waits for a block.
double? changeFraction(List<OpenChange> sends, int target) {
  final first = sends.first;
  return switch (first.wait) {
    ChangeWait.reply => null,
    ChangeWait.block => 0.1,
    ChangeWait.confirming => target <= 0 ? 1 : (first.confirmations / target).clamp(0.1, 1.0),
  };
}

/// A send's line in the balance sheet: what it waits for and when.
String changeRowHint(AppLocalizations l, OpenChange c, int target) => switch (c.wait) {
  ChangeWait.reply => l.phoneChangeRowReply,
  ChangeWait.block => l.phoneChangeRowBlock(c.minutes!),
  ChangeWait.confirming => l.phoneChangeRowConfirming(c.minutes!, c.confirmations, target),
};
