// SPDX-License-Identifier: Apache-2.0
/// One payment as the phone's Activity list shows it (the Activity frame): an avatar with the
/// direction badge, the name, a second line, and the amount in the mono face with its value
/// under it. The second line is the status word with a small mark while the payment is open
/// (a ring filled by the confirmations, an hourglass while the other side is awaited, a short
/// arc while it arrives), else the time and the note, or the time and "Sealed".
///
/// Colours follow the owner's rules: incoming amounts are green, a sent amount is plain text,
/// a cancelled one is grey and struck through, in-progress words are blue. A screen reader
/// hears one sentence ([txSpokenLabel]) and a long press offers to label the payment, as in
/// [TxTile], which stays for Home and the desktop.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
import '../initials.dart' show nameInitials;
import '../l10n.dart';
import '../pairing_providers.dart' show PairNet, pairNetProvider;
import '../settings.dart';
import '../wallet_service.dart';
import 'address_view.dart' show ShortAddressText;
import 'common.dart';
import 'epic1/epic1_sealed.dart' show phoneShowsSealed;
import 'kit/kit_avatar.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_tokens.dart';
import 'payment_progress.dart' show paymentRowWord;
import 'theme/epic1_mark.dart' show Epic1Glyph;
import 'theme/tokens.dart';
import 'tx_details_screen.dart' show TxDetailsScreen;
import 'tx_label.dart' show ManualTag, TxLabelEditor;

/// The mark before an open payment's status word: [fraction] of a ring filled (a payment
/// confirming, or arriving), or an hourglass when the other side is awaited ([fraction] null).
class PhoneProgressMark extends StatelessWidget {
  const PhoneProgressMark({super.key, required this.fraction, this.size = 13, this.color});

  final double? fraction;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.tokens.info;
    final f = fraction;
    if (f == null) {
      return ExcludeSemantics(child: Icon(Icons.hourglass_empty_rounded, size: size, color: ink));
    }
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _RingPainter(ink, f.clamp(0.0, 1.0))),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.ink, this.fraction);

  final Color ink;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    // The frame's ring: a 24 unit box, radius 9, stroke 3.
    final unit = size.width / 24;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 9 * unit);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * unit
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = ink.withValues(alpha: 0.3));
    if (fraction > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, stroke..color = ink);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ink != ink || old.fraction != fraction;
}

/// How far an open payment is, for [PhoneProgressMark]: null while the other side is awaited,
/// the confirmations over the target while confirming, a short arc while arriving.
double? phoneProgressFraction(TxEntry tx, BigInt? tip, {required int target}) =>
    switch (txPhase(tx, tip, target: target)) {
      TxPhase.confirming => (txConfirmations(tx, tip) ?? 0) <= 0 ? 0.1 : txConfirmedShare(txConfirmations(tx, tip) ?? 0, target),
      TxPhase.waitingSender => 0.1,
      _ => null,
    };

/// The title's initials for the avatar, or null when the title is not a name: an address, a
/// mining reward, a payment's method.
String? _initialsOf(TxEntry tx, String title, {required bool named}) {
  final label = tx.label?.trim() ?? '';
  if (!named && label.isEmpty) return null;
  final text = nameInitials(title, count: 2);
  return text.isEmpty ? null : text;
}

IconData _fallbackIcon(TxEntry tx) {
  if (tx.kind == TxKind.coinbase) return Icons.bolt_rounded;
  if (tx.origin == TxOrigin.linkedDevice) return KitIcons.devices;
  if (tx.origin == TxOrigin.otherWallet) return KitIcons.contact;
  return KitIcons.contact;
}

/// Whether [tx] is under way: confirming, or waiting on the other side.
bool paymentInProgress(TxEntry tx, BigInt? tip, {int? target}) => switch (txPhase(tx, tip, target: target)) {
  TxPhase.confirming ||
  TxPhase.maturing ||
  TxPhase.waitingRecipient ||
  TxPhase.waitingSender ||
  TxPhase.waitingPayer => true,
  TxPhase.completed || TxPhase.cancelled || TxPhase.fromBackup => false,
};

/// The phone's row for [tx] (Activity, Home's Recent, Contacts); opens its payment page. The
/// Contacts tab shows a contact by its latest payment: [onOpen] then opens the contact and
/// [name] is the contact's.
class PhoneTxRow extends ConsumerWidget {
  const PhoneTxRow({super.key, required this.tx, this.onOpen, this.name, this.dated = false});

  final TxEntry tx;

  /// Replaces the tap that opens the payment.
  final VoidCallback? onOpen;

  /// The row's name when the caller knows it better than the payment does.
  final String? name;

  /// The time with its day (Home and Contacts, which have no day headers); else the clock only,
  /// as under Activity's day headers.
  final bool dated;

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
    final name = this.name ?? txPartyName(ref, tx);
    final counterparty = tx.counterparty;
    final own = ownEpicboxServer(ref);
    // The phone names the relay of an address that is not the wallet's own server.
    final title = txTitle(l, tx, contactName: name, ownServer: own);
    final addressTitle =
        counterparty != null && name == null && title == shortAddress(counterparty, ownServer: own);
    final aside = txTitleAside(tx, contactName: name, ownServer: own);
    final time = dated ? shortDate(l, localTime(tx.timeUnix), now) : localClock(l, localTime(tx.timeUnix));
    final sealed = phoneShowsSealed(ref, tx);
    final paused = ref.watch(pairNetProvider) == PairNet.epicboxOff;
    final status = open
        ? paymentRowWord(
            l,
            tx,
            tip,
            target: target,
            now: now,
            who: name,
            pairedWith: txPayeeName(ref, tx),
            paused: paused,
          )
        : txStatusLabel(l, tx, tip, target: target, now: now, paused: paused);
    final fiat = cancelled ? null : approxFiat(l, amount, display, short: true);
    final sign = outgoing ? minusSign : '+';
    final amountText = display.hidden ? hiddenAmount : '$sign${displayEpic(amount)}';
    final note = tx.note?.trim() ?? '';

    // The second line's pieces.
    final Widget sub;
    final mono = KitType.rowSub;
    if (open) {
      final fraction = phoneProgressFraction(tx, tip, target: target);
      sub = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhoneProgressMark(fraction: fraction),
          const SizedBox(width: 6),
          Flexible(
            child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: mono.copyWith(color: t.info)),
          ),
        ],
      );
    } else {
      final word = cancelled
          ? (outgoing && status == l.txStatusCancelled ? l.phoneActCancelledNothing : status)
          : null;
      final detail = word ?? (note.isNotEmpty ? note : aside);
      sub = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One text: the date and time first, so the ellipsis cuts the detail, not the time.
          Flexible(
            child: Text(
              (!(sealed && !cancelled) && detail != null && detail.isNotEmpty) ? '$time · $detail' : time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono.copyWith(color: t.dim),
            ),
          ),
          if (sealed && !cancelled) ...[
            Text(' · ', style: mono.copyWith(color: t.dim)),
            ExcludeSemantics(child: Epic1Glyph(size: 16, color: t.accentText)),
            const SizedBox(width: 3),
            Flexible(child: Text(l.phoneActSealed, maxLines: 1, overflow: TextOverflow.ellipsis, style: mono.copyWith(color: t.dim))),
          ],
        ],
      );
    }

    final initials = _initialsOf(tx, title, named: name != null);
    final direction = open
        ? KitDirection.pending
        : (outgoing ? KitDirection.out : KitDirection.incoming);
    final avatar = KitAvatar(
      initials: initials,
      icon: initials == null ? _fallbackIcon(tx) : null,
      neutral: cancelled,
      direction: direction,
    );

    void openPage() => onOpen != null
        ? onOpen!()
        : Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)));
    final editable = tx.origin != TxOrigin.linkedDevice;
    VoidCallback? edit;

    final amountColor = cancelled ? t.txCancelled : (outgoing ? t.text : t.txReceived);
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            key: ValueKey('tx-${tx.key}'),
            button: true,
            label: txSpokenLabel(
              l,
              tx,
              who: name ?? (counterparty == null ? null : shortAddress(counterparty, ownServer: own)),
              date: shortDate(l, localTime(tx.timeUnix), now),
              status: status,
              hidden: display.hidden,
              label: tx.label,
              sealed: sealed,
            ),
            onTap: openPage,
            onLongPress: editable ? () => edit?.call() : null,
            onLongPressHint: editable ? (tx.label == null ? l.txLabelAdd : l.txLabelEdit) : null,
            excludeSemantics: true,
            child: InkWell(onTap: openPage, onLongPress: editable ? () => edit?.call() : null),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Kit.rowList),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IgnorePointer(child: ExcludeSemantics(child: avatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 26,
                        child: TxLabelEditor(
                          tx: tx,
                          style: KitType.rowTitle.copyWith(color: t.text),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          idle: (context, startEdit) {
                            edit = editable ? startEdit : null;
                            return IgnorePointer(
                              child: ExcludeSemantics(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: addressTitle
                                            ? ShortAddressText(counterparty, ownServer: own, style: KitType.address.copyWith(fontSize: 14))
                                            : Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: KitType.rowTitle.copyWith(color: cancelled ? t.dim : t.text),
                                              ),
                                      ),
                                      // What the user typed is marked, as in the old list.
                                      if (tx.manualFields.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        ManualTag(editedAtUnix: tx.manualEditedAtUnix, compact: true),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      IgnorePointer(child: ExcludeSemantics(child: sub)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IgnorePointer(
                  child: ExcludeSemantics(
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
                          if (fiat != null)
                            Text(fiat, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.dim)),
                        ],
                      ),
                    ),
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
