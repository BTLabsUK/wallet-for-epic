// SPDX-License-Identifier: Apache-2.0
/// One payment as a phone list row (Home's Recent, the contact page): [KitPaymentRow] filled
/// from the payment. The words are today's: the title, the step word and the spoken sentence
/// come from the same helpers the older rows use, so a payment reads the same everywhere. The
/// step word is the plain one ([TimelineStyle.casualSteps]); the phone shows things by state,
/// not by level.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart';
import '../pairing_providers.dart' show PairNet, pairNetProvider;
import '../settings.dart' show clockProvider;
import 'address_view.dart' show ShortAddressText;
import 'common.dart';
import 'epic1/epic1_sealed.dart' show phoneShowsSealed;
import 'kit/kit_avatar.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_payment_row.dart';
import 'kit/kit_tokens.dart';
import '../levels/level_features.dart' show TimelineStyle;
import 'levels/payment_steps.dart' show paymentStepWord;
import 'status_icons.dart' show EpicGlyphs;
import 'theme/tokens.dart';
import 'tx_details_screen.dart';
import 'tx_label.dart' show TxLabelEditor;
import '../initials.dart' show nameInitials;

/// Whether [tx] is under way: confirming, or waiting on the other side.
bool paymentInProgress(TxEntry tx, BigInt? tip, {int? target}) => switch (txPhase(tx, tip, target: target)) {
  TxPhase.confirming ||
  TxPhase.maturing ||
  TxPhase.waitingRecipient ||
  TxPhase.waitingSender ||
  TxPhase.waitingPayer => true,
  TxPhase.completed || TxPhase.cancelled || TxPhase.fromBackup => false,
};

/// The row for [tx]; a tap opens its details, a long press labels it. The Contacts tab shows a
/// contact by its latest payment: [onOpen] then opens the contact and [name] is the contact's.
class PaymentRow extends ConsumerWidget {
  const PaymentRow({super.key, required this.tx, this.onOpen, this.name});

  final TxEntry tx;

  /// Replaces the tap that opens the payment.
  final VoidCallback? onOpen;

  /// The row's name when the caller knows it better than the payment does.
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    final now = ref.watch(clockProvider)();
    final (:amount, :outgoing) = txAmount(tx);
    final cancelled = tx.status == TxStatus.cancelled;
    final name = this.name ?? txPartyName(ref, tx);
    final ownServer = ownEpicboxServer(ref);
    final counterparty = tx.counterparty;
    final title = txTitle(l, tx, contactName: name, ownServer: ownServer);
    final addressTitle = counterparty != null && name == null && title == shortAddress(counterparty, ownServer: ownServer);
    final aside = txTitleAside(tx, contactName: name, ownServer: ownServer);
    final date = shortDate(l, localTime(tx.timeUnix), now);
    final step = paymentStepWord(
      l,
      tx,
      tip,
      style: TimelineStyle.casualSteps,
      target: target,
      now: now,
      who: name,
      pairedWith: txPayeeName(ref, tx),
      paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
    );
    final sealed = phoneShowsSealed(ref, tx);
    final inProgress = paymentInProgress(tx, tip, target: target);
    final signed = signedEpic(l, tx, hidden: display.hidden);
    final fiat = cancelled ? null : approxFiat(l, amount, display, short: true);
    void open() => onOpen != null ? onOpen!() : Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)));
    final canLabel = tx.origin != TxOrigin.linkedDevice;
    final dim = KitType.rowSub.copyWith(color: t.dim);
    final initials = name == null ? null : nameInitials(name);
    final avatar = KitAvatar(
      initials: initials,
      icon: initials == null ? (tx.label != null ? KitIcons.invoice : KitIcons.contact) : null,
      neutral: initials == null,
      direction: inProgress ? KitDirection.pending : (outgoing ? KitDirection.out : KitDirection.incoming),
    );
    // The long press opens the label field in place; the editor hands its opener out.
    VoidCallback? edit;
    final row = TxLabelEditor(
      tx: tx,
      style: KitType.rowTitle,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      wrap: null,
      idle: (context, startEdit) {
        edit = canLabel ? startEdit : null;
        return KitPaymentRow(
          avatar: avatar,
          title: addressTitle
              ? ShortAddressText(counterparty, ownServer: ownServer, style: KitType.address.copyWith(color: t.text, fontSize: 14.5))
              : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text)),
          state: Text.rich(
            TextSpan(
              style: dim,
              children: [
                TextSpan(text: date),
                const TextSpan(text: metaSeparator),
                TextSpan(
                  text: step,
                  style: inProgress ? dim.copyWith(color: t.info) : null,
                ),
                if (aside != null) ...[const TextSpan(text: metaSeparator), TextSpan(text: aside)],
                if (sealed) ...[
                  const TextSpan(text: metaSeparator),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 3),
                      child: Icon(EpicGlyphs.sealed, size: 13, color: t.dim),
                    ),
                  ),
                  TextSpan(text: l.deskE1Sealed),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          amount: signed,
          fiat: fiat,
          amountColor: cancelled
              ? t.txCancelled
              : outgoing
              ? t.text
              : t.txReceived,
          struck: cancelled,
          onTap: open,
          onLongPress: canLabel ? () => edit?.call() : null,
          longPressHint: canLabel ? (tx.label == null ? l.txLabelAdd : l.txLabelEdit) : null,
          semanticsLabel: txSpokenLabel(
            l,
            tx,
            who: name ?? (counterparty == null ? null : shortAddress(counterparty, ownServer: ownServer)),
            date: date,
            status: step,
            hidden: display.hidden,
            label: tx.label,
            sealed: sealed,
          ),
        );
      },
    );
    return KeyedSubtree(key: ValueKey('tx-${tx.key}'), child: row);
  }
}
