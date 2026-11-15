// SPDX-License-Identifier: Apache-2.0
/// A contact by its latest payment, as the Contacts frame draws it: the name, a second line with
/// where the payment stands (a mark and the status word while it is open, else the way it went
/// and the note or "Sealed"), and under the amount the time. No fiat and no direction badge:
/// the row is about the person.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../initials.dart' show nameInitials;
import '../l10n.dart';
import '../pairing_providers.dart' show PairNet, pairNetProvider;
import '../settings.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'kit/kit_avatar.dart';
import 'kit/kit_support.dart';
import 'kit/kit_tokens.dart';
import 'payment_progress.dart' show paymentRowWord;
import 'phone_tx_row.dart' show PhoneProgressMark, paymentInProgress, phoneProgressFraction, phoneRowDay;
import 'theme/epic1_mark.dart' show Epic1Glyph;
import 'theme/tokens.dart';

class ContactActivityRow extends ConsumerWidget {
  const ContactActivityRow({super.key, required this.tx, required this.name, required this.onOpen, this.others = const []});

  final TxEntry tx;
  final String name;
  final VoidCallback onOpen;

  /// All the contact's payments, to count those on their way.
  final List<TxEntry> others;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final now = ref.watch(clockProvider)();
    final target = confirmationsTargetOf(ref);
    final (:amount, :outgoing) = txAmount(tx);
    final cancelled = tx.status == TxStatus.cancelled;
    final open = paymentInProgress(tx, tip, target: target);
    final sealed = tx.sealed && !cancelled;
    final paused = ref.watch(pairNetProvider) == PairNet.epicboxOff;
    // Two or more payments from the contact on their way: the count, as the frame says.
    final arriving = others.where((o) => !txAmount(o).outgoing && paymentInProgress(o, tip, target: target)).length;
    final String status;
    if (open && !outgoing && arriving > 1) {
      status = l.phoneContactsArriving(arriving);
    } else if (open) {
      status = paymentRowWord(l, tx, tip, target: target, now: now, who: name, pairedWith: txPayeeName(ref, tx), paused: paused);
    } else if (tx.status == TxStatus.confirmed) {
      // A finished payment names who paid whom.
      status = outgoing ? l.phoneContactsYouPaid : l.phoneContactsPaidYou;
    } else {
      status = txStatusLabel(l, tx, tip, target: target, now: now, paused: paused);
    }
    final when = localTime(tx.timeUnix);
    // Under a minute: Now; the time of day for today, else the day (Yesterday, the weekday, the date).
    final time = now.difference(when).abs() < const Duration(minutes: 1)
        ? l.phoneContactsNow
        : daysAgo(when, now) == 0
        ? localClock(l, when)
        : phoneRowDay(l, when, now);
    final note = tx.note?.trim() ?? '';
    final sub = KitType.rowSub;
    final Widget second;
    if (open) {
      second = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhoneProgressMark(fraction: phoneProgressFraction(tx, tip, target: target)),
          const SizedBox(width: 6),
          Flexible(child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: sub.copyWith(color: t.info))),
        ],
      );
    } else {
      second = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              !sealed && note.isNotEmpty ? '$status · $note' : status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sub.copyWith(color: t.dim),
            ),
          ),
          if (sealed) ...[
            Text(' · ', style: sub.copyWith(color: t.dim)),
            ExcludeSemantics(child: Epic1Glyph(size: 16, color: t.accentText)),
            const SizedBox(width: 3),
            Flexible(child: Text(l.phoneActSealed, maxLines: 1, overflow: TextOverflow.ellipsis, style: sub.copyWith(color: t.dim))),
          ],
        ],
      );
    }
    final amountColor = cancelled ? t.txCancelled : (outgoing ? t.text : t.txReceived);
    final amountText = display.hidden ? hiddenAmount : '${outgoing ? minusSign : '+'}${displayEpic(amount)}';
    return KitPress(
      onTap: onOpen,
      semanticsLabel: txSpokenLabel(
        l,
        tx,
        who: name,
        date: shortDate(l, when, now),
        status: status,
        hidden: display.hidden,
        label: tx.label,
        sealed: sealed,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Kit.rowList),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ExcludeSemantics(child: KitAvatar(initials: nameInitials(name, phone: true))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text)),
                    const SizedBox(height: 3),
                    second,
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KitType.rowAmount.copyWith(
                          color: amountColor,
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                          decorationColor: amountColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(time, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.faint, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
