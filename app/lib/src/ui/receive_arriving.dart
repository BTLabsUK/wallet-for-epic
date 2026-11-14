// SPDX-License-Identifier: Apache-2.0
/// The sheet that opens over Receive when a payment arrives (Receive-3): who and how much, the
/// shared payment steps ([paymentProgress]) and Done or View payment. It follows the payment
/// while it is open, so the steps move on by themselves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart' show epicUnit;
import '../initials.dart' show nameInitials;
import '../l10n.dart';
import '../network_gate.dart' show NetGate;
import '../pairing_providers.dart' show PairNet, pairNetProvider;
import '../providers.dart';
import '../settings.dart' show clockProvider;
import '../trust_ids.dart';
import '../watch_mode.dart' show BlockWait;
import 'common.dart';
import 'kit/kit_button.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_steps.dart';
import 'kit/kit_tokens.dart';
import 'payment_progress.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

/// Opens the arriving-payment sheet for [txKey].
Future<void> showReceiveArrival(BuildContext context, String txKey) =>
    showKitSheet<void>(context: context, builder: (_) => ReceiveArrivalSheet(txKey: txKey));

/// The sheet's content: the payment [txKey], read live from the wallet's history.
class ReceiveArrivalSheet extends ConsumerWidget {
  const ReceiveArrivalSheet({super.key, required this.txKey});

  final String txKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final tx = ref.watch(homeProvider.select((h) => h.value?.transactions.where((x) => x.key == txKey).firstOrNull));
    final done = KitButton(
      label: l.commonDone,
      onPressed: () => Navigator.of(context).pop(),
      semanticsId: TrustIds.receiveArriveDone,
    );
    if (tx == null) return KitSheet(primary: done);
    final hidden = amountDisplay(ref).hidden;
    final who = txPartyName(ref, tx);
    final tip = tipHeight(ref);
    final now = ref.watch(clockProvider)();
    final progress = paymentProgress(
      l,
      tx,
      tip,
      now: now,
      who: who,
      target: confirmationsTargetOf(ref),
      wait: tip == null ? BlockWait.none : ref.read(blockWatchProvider).waitOf(tx, now: now, tip: tip),
      paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
      killSwitch: NetGate.killSwitch,
    );
    final initials = who == null || who.isEmpty ? '' : nameInitials(who, count: 2, phone: true);
    final amount = signedEpic(l, tx, hidden: hidden);
    final number = amount.endsWith(epicUnit) ? amount.substring(0, amount.length - epicUnit.length).trimRight() : amount;
    return TrustId(
      TrustIds.receiveArriveSheet,
      child: KitSheet(
        primary: done,
        secondary: KitButton(
          label: l.phoneRecvViewPayment,
          kind: KitButtonKind.ghost,
          semanticsId: TrustIds.receiveArriveView,
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            navigator.push(MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)));
          },
        ),
        actionsTop: 18,
        buttonsGap: 4,
        child: Column(
          children: [
            // `.center`: 6 above, 20 in, 6 between the avatar, the amount and the line.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(16)),
                      child: initials.isEmpty
                          ? Icon(KitIcons.contact, size: 22, color: t.accentText)
                          : Text(
                              initials,
                              style: KitType.initials.copyWith(color: t.accentText, fontSize: 15, letterSpacing: 0.3),
                              maxLines: 1,
                              textScaler: TextScaler.noScaling,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: who == null ? amount : l.lvPayArrivalFrom(amount, who),
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        number,
                        style: KitType.amountOnPage.copyWith(color: t.txReceived, fontSize: 38, letterSpacing: -1.52),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ExcludeSemantics(
                    child: Text(
                      who == null ? epicUnit : '$epicUnit ${l.phoneRecvArrivalFrom(who)}',
                      style: KitType.body.copyWith(color: t.dim),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (progress != null)
              KitSteps(steps: progress.steps)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  txStatusLabel(l, tx, tip, target: confirmationsTargetOf(ref), now: now),
                  style: KitType.body.copyWith(color: t.dim),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
