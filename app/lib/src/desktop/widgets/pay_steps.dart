// SPDX-License-Identifier: Apache-2.0
/// A payment's live steps on the desktop (wallet levels): started → signed → posted →
/// confirming → done, in the level's words. Overview's in-flight card, Send after the send,
/// Receive's arrival card and the payment detail show it.
///
/// The state of each step comes from [PayFacts], the one reading of a [Tx] that the Deep end's
/// own step list (tx_detail.dart) shares: nothing is invented, a step shows a time only when
/// the wallet knows it, and a sub-line appears only when the data says so.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../known_relays.dart' show recipientRelay;
import '../../levels/level_features.dart' show TimelineStyle;
import '../../network_gate.dart' show NetGate;
import '../data/desk_levels.dart';
import '../desk_l10n.dart';
import '../screens/wallet/tx_display.dart' show deskTxMailboxName;
import 'kit.dart';

/// Where a step stands.
enum PayStepState { done, now, todo }

/// One step of a payment: its words, where it stands, the time the wallet knows for it, and a
/// line under it when the data says something about it.
class PayStep {
  const PayStep(this.title, this.state, this.time, {this.sub, this.subTip});

  final String title;
  final PayStepState state;
  final String time;
  final String? sub;

  /// The whole of what [sub] names (the relay's host), on hover: the sub-line stays short.
  final String? subTip;
}

/// What the record of [t] says about how far the payment has come.
class PayFacts {
  const PayFacts._({
    required this.signed,
    required this.waitingSender,
    required this.posted,
    required this.inBlock,
    required this.done,
    required this.notPostedKill,
  });

  factory PayFacts.of(Tx t) {
    // An incoming payment is on record only once this wallet signed it; it then waits for the
    // sender to post it.
    final signed = t.incoming || t.state != TxState.waitingRecipient;
    final waitingSender = t.incoming && t.state == TxState.waitingRecipient;
    final posted = t.state == TxState.confirming || t.state == TxState.confirmed || (t.state == TxState.posted && !t.notPosted && !t.posting);
    final inBlock = t.state == TxState.confirming || t.state == TxState.confirmed;
    return PayFacts._(
      signed: signed,
      waitingSender: waitingSender,
      posted: posted,
      inBlock: inBlock,
      done: t.state == TxState.confirmed,
      notPostedKill: t.notPosted && NetGate.killSwitch,
    );
  }

  /// This wallet signed it (a receive) or the recipient did (a send).
  final bool signed;

  /// A receive whose sender has not posted it yet.
  final bool waitingSender;

  /// The network took it.
  final bool posted;

  /// In a block (confirming or confirmed).
  final bool inBlock;

  /// Confirmed.
  final bool done;

  /// Finished and unposted under Kill switch: a device that is online posts it.
  final bool notPostedKill;

  /// Whether the Posted step is the one under way: a send both wallets signed that is not posted
  /// yet, a receive whose sender reports it posted, or a finished one waiting for a device that
  /// is online (Kill switch).
  bool postedNow(Tx t) => !posted && (notPostedKill || (t.incoming ? t.senderPosted : signed));
}

/// Whether [t] is an ordinary payment whose steps are the five of [payStepList]: not a mining
/// reward, a scan find, another wallet's, a backup's, an invoice's, a cancelled one.
bool payHasSteps(Tx t) =>
    !t.coinbase && !t.foundByScan && !t.otherWallet && !t.fromBackup && !t.isInvoice && t.deviceName == null && t.state != TxState.cancelled && !t.senderCancelled;

/// Whether [t] is a payment still under way (the in-flight card).
bool payInFlight(Tx t) => payHasSteps(t) && t.state != TxState.confirmed;

final _clock = DateFormat('HH:mm:ss');

/// The five steps of [t] in the words of [style], the phone's own five ([sendSteps] and
/// [paymentSteps] there, A-03): Payment started (or arrived), Recipient signed (or Signed and
/// returned), Posted to the network, Confirming, Completed. The technical level counts
/// "Confirming 2/6" as the phone's details do; the other levels say "Confirming 2 of 6", and
/// with no block yet keep Posted as the step under way. [name] is the other side by name when
/// known; [times] adds the time of the step the wallet knows (the started one).
List<PayStep> payStepList(AppLocalizations l, Tx t, TimelineStyle style, {String? name, bool times = false}) {
  final f = PayFacts.of(t);
  final technical = style == TimelineStyle.technicalSteps;
  final at = t.startedAt ?? t.created;
  final started = times ? _clock.format(at) : '';
  final n = t.confirmations;
  final target = t.confirmationsNeeded;

  // The current "Recipient signed" step's sub-line: what the payment waits on, never slate
  // jargon. Over Epicbox the relay's host is in the tooltip, never broken across lines (#06).
  final String? recipientSub;
  String? recipientTip;
  if (t.incoming || f.signed) {
    recipientSub = null;
  } else if (t.undelivered) {
    recipientSub = l.deskTxStatusUndelivered;
  } else if (t.method == TxMethod.file) {
    recipientSub = l.deskTxStepWaitingFile;
  } else if (t.method != TxMethod.epicbox) {
    recipientSub = null;
  } else {
    recipientSub = name == null ? l.deskLvPayOnEpicbox : l.sendTrackWaitingFor(name);
    recipientTip = recipientRelay(t.counterparty ?? '')?.label;
  }

  PayStepState at2(bool doneNow, bool nowNow) => doneNow ? PayStepState.done : (nowNow ? PayStepState.now : PayStepState.todo);

  final inBlockNow = f.inBlock && !f.done;
  // The levels never read "Confirming 0 of 6": until a block has it, Posted is under way.
  final postedHolds = !technical && inBlockNow && n <= 0;

  final first = PayStep(t.incoming ? l.txStepArrived : l.txStepStarted, PayStepState.done, started);
  final second = t.incoming
      ? PayStep(
          l.txStepSenderFinished,
          at2(!f.waitingSender || t.senderPosted, true),
          '',
          sub: f.waitingSender && !t.senderPosted ? l.deskTxStatusWaitingSender : null,
        )
      : PayStep(
          technical || name == null ? l.txStepAccepted : l.lvPaySigned(name),
          f.signed ? PayStepState.done : PayStepState.now,
          '',
          sub: recipientSub,
          subTip: recipientTip,
        );
  final third = PayStep(
    l.txStepPosted,
    postedHolds ? PayStepState.now : at2(f.posted, f.postedNow(t)),
    '',
    sub: f.notPostedKill ? l.txPostElsewhere : (t.incoming && t.senderPosted && !f.posted ? l.deskTxStatusSenderPosted : null),
  );
  final fourth = PayStep(
    f.done
        ? l.txStepConfirmed
        : inBlockNow && !postedHolds
        ? (technical ? l.txStatusConfirming(n, target) : l.lvPayConfirmingOf(n, target))
        : l.txStepConfirming,
    postedHolds ? PayStepState.todo : at2(f.done, inBlockNow),
    '',
  );
  final fifth = PayStep(l.txStatusCompleted, f.done ? PayStepState.done : PayStepState.todo, '');
  return [first, second, third, fourth, fifth];
}

class DeskPaymentSteps extends ConsumerWidget {
  const DeskPaymentSteps({super.key, required this.tx, this.dense = false, this.vertical});

  final Tx tx;

  /// Fewer lines: the in-flight card and the arrival card.
  final bool dense;

  /// Down the page (the payment detail) instead of across; by default across, and down in a
  /// width too narrow for five columns.
  final bool? vertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!payHasSteps(tx)) return const SizedBox.shrink();
    final l = context.l10n;
    final style = ref.watch(deskLevelFeaturesProvider.select((f) => f.timeline));
    final mailbox = deskTxMailboxName(ref, tx, any: true);
    final name = mailbox ?? tx.contactName;
    final down = vertical ?? false;
    final steps = payStepList(l, tx, style, name: name, times: down && !dense);
    return LayoutBuilder(
      builder: (context, box) => Semantics(
        container: true,
        liveRegion: true,
        // Across while each step keeps 120 u (five steps: Lay.md), never wider than Max.steps.
        child: down || box.maxWidth < Lay.md
            ? _Down(steps: steps)
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(constraints: BoxConstraints(maxWidth: Max.steps), child: _Across(steps: steps, dense: dense)),
              ),
      ),
    );
  }
}

String _stateWord(AppLocalizations l, PayStepState s) => switch (s) {
  PayStepState.done => l.deskOvStepDone,
  PayStepState.now => l.deskOvStepNow,
  PayStepState.todo => l.deskOvStepWait,
};

/// A step's sub-line, with the whole of what it names on hover ([PayStep.subTip]).
class _Sub extends StatelessWidget {
  const _Sub(this.step, this.child);

  final PayStep step;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (step.subTip) {
    final tip? => ETip.value(tip, mono: true, child: child),
    null => child,
  };
}

class _Dot extends StatelessWidget {
  const _Dot(this.state, {required this.size});

  final PayStepState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: state == PayStepState.done ? c.ok : (state == PayStepState.now ? c.info : c.s1),
        shape: BoxShape.circle,
        border: state == PayStepState.todo ? Border.all(color: c.lineStrong, width: 2) : null,
      ),
      child: state == PayStepState.done ? Icon(EIcons.check, size: size * 0.65, color: c.bg) : null,
    );
  }
}

/// The step the payment is at, for a one-line reading: the sub-line when the data says what it
/// waits on ("Waiting for the recipient"), else the step's own words ("Confirmations 2 / 6").
String payStepNowText(List<PayStep> steps) {
  final s = steps.firstWhere((s) => s.state == PayStepState.now, orElse: () => steps.last);
  return s.sub ?? s.title;
}

/// The five steps as a small mark, a dot each with a short line between: done green, the one under
/// way blue, to come a ring. Decoration beside words that say the same; it carries no semantics.
class PayStepDots extends StatelessWidget {
  const PayStepDots(this.steps, {super.key});

  final List<PayStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final dot = 9.u;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, s) in steps.indexed) ...[
            if (i > 0) Container(width: 6.u, height: 2, color: steps[i - 1].state == PayStepState.done ? c.ok : c.lineStrong),
            Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: switch (s.state) {
                  PayStepState.done => c.ok,
                  PayStepState.now => c.info,
                  PayStepState.todo => c.s1,
                },
                shape: BoxShape.circle,
                border: s.state == PayStepState.todo ? Border.all(color: c.lineStrong, width: 1.5) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The steps across: a dot and a line to the next one, the words under each, the current one
/// bold with its sub-line.
class _Across extends StatelessWidget {
  const _Across({required this.steps, required this.dense});

  final List<PayStep> steps;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final dot = (dense ? 14 : 16).u;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, s) in steps.indexed)
          Expanded(
            child: Semantics(
              label: l.deskOvStepSemantics(s.sub == null ? s.title : '${s.title}, ${s.sub}', _stateWord(l, s.state)),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Dot(s.state, size: dot),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(height: 2, color: s.state == PayStepState.done ? c.ok : c.lineStrong),
                        ),
                    ],
                  ),
                  SizedBox(height: Sp.x2),
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: Sp.x2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: s.state == PayStepState.now
                              ? ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)
                              : ts.small.copyWith(color: s.state == PayStepState.todo ? c.faint : c.dim),
                        ),
                        if (s.sub != null) _Sub(s, Text(s.sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.caption.copyWith(color: s.state == PayStepState.now ? c.info : c.faint))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The steps down the page, as the payment detail draws them, with the known time at the end.
class _Down extends StatelessWidget {
  const _Down({required this.steps});

  final List<PayStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in steps.indexed)
          Semantics(
            label: l.deskOvStepSemantics(s.sub == null ? s.title : '${s.title}, ${s.sub}', _stateWord(l, s.state)),
            excludeSemantics: true,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20.u,
                    child: Column(
                      children: [
                        _Dot(s.state, size: 20.u),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: s.state == PayStepState.done ? c.ok : c.lineStrong),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : Sp.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: s.state == PayStepState.todo ? ts.body.copyWith(color: c.faint, fontWeight: FontWeight.w500) : ts.strong),
                          if (s.sub != null) _Sub(s, Text(s.sub!, style: ts.small.copyWith(color: s.state == PayStepState.now ? c.info : c.faint))),
                        ],
                      ),
                    ),
                  ),
                  if (s.time.isNotEmpty) Text(s.time, style: ts.mono(size: Fs.xs, color: c.faint)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
