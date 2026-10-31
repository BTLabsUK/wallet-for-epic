// SPDX-License-Identifier: Apache-2.0
/// Level 1 Receive: the arrival card for a payment coming in, and the notice that follows a
/// Epicbox server move (the "New today" badge, the server's name, who needs the new address).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/relay_switch_providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../theme/tokens.dart';
import '../tx_details_screen.dart';
import 'payment_steps.dart';

/// Key of the arrival card, for tests.
const Key payArrivalKey = ValueKey('pay-arrival');

/// The newest incoming payment still on its way in, or null.
TxEntry? arrivingPayment(Iterable<TxEntry> txs) {
  TxEntry? best;
  for (final tx in txs) {
    if (txAmount(tx).outgoing || tx.status == TxStatus.cancelled || tx.kind == TxKind.coinbase) continue;
    if (!isPending(tx) || tx.source != TxSource.wallet) continue;
    if (best == null || tx.timeUnix > best.timeUnix) best = tx;
  }
  return best;
}

/// "+12.5 EPIC from Bob · Arriving", with the receiving steps, while a payment comes in.
class ArrivalCard extends ConsumerWidget {
  const ArrivalCard({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final hidden = amountDisplay(ref).hidden;
    final who = txPartyName(ref, tx);
    final word = paymentStepWordOf(ref, tx, tipHeight(ref));
    final amount = signedEpic(l, tx, hidden: hidden);
    return Card(
      key: payArrivalKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              liveRegion: true,
              child: Text(
                who == null ? amount : l.lvPayArrivalFrom(amount, who),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 2),
            Text(word, style: theme.textTheme.bodyMedium?.copyWith(color: t.info)),
            const SizedBox(height: 12),
            PaymentTimeline(tx: tx),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)),
                ),
                child: Text(l.lvPayOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// After the wallet moved to another Epicbox server: "New today" on the address, the server's
/// name, and that anyone with the old address needs the new one (the old address is not
/// promised to keep working).
class NewAddressBadge extends StatelessWidget {
  const NewAddressBadge({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: EBadge(context.l10n.lvPayNewToday, tone: BadgeTone.info),
  );
}

/// The two lines under the new address.
class NewAddressLines extends StatelessWidget {
  const NewAddressLines({super.key, required this.result});

  final RelaySwitchResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.lvPayServerLine(result.name), key: const ValueKey('pay-server-line'), style: style),
        const SizedBox(height: 2),
        Text(l.lvPayOldAddressLine, style: style),
      ],
    );
  }
}
