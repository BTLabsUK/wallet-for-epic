/// A withdrawal from a paired exchange on its payment page: the
/// exchange sent it sealed, the wallet signed and answered it on its own, and the exchange
/// posts it. "Received. Waiting for Northwind Exchange to post" until it is on the chain, and
/// the timeline: the answer delivered to its relay, posted by it, then the confirmations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import 'pair_check.dart' show pickContactForPairing, savePairingAsNewContact;
import '../theme/protocol.dart';
import '../theme/tokens.dart';

/// The withdrawal [tx] is, with the name of the contact it came from; null when it is none.
({PairingSlate slate, String name})? withdrawalOf(WidgetRef ref, TxEntry tx) {
  final slateId = tx.slateId;
  if (slateId == null || tx.kind != TxKind.received) return null;
  final slate = ref.watch(pairingSlateProvider(slateId)).value;
  if (slate == null || slate.purpose != SlatePurpose.withdrawal) return null;
  final record = ref.watch(pairingByIdProvider(slate.pairingId));
  final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
  return (slate: slate, name: record == null ? '' : pairingName(record, contacts));
}

/// "Received from" on a withdrawal: the paired exchange by name. Not in the contacts yet, it
/// offers Save as a new contact and Add to a contact, as the words result does; nothing is
/// matched by name or address.
class WithdrawalFromRow extends ConsumerWidget {
  const WithdrawalFromRow({super.key, required this.pairingId, required this.name});

  final String pairingId;
  final String name;

  Future<void> _attach(WidgetRef ref, Contact? contact) async {
    if (contact == null) return;
    await pairingCall(ref, (api) => api.attach(pairingId, contact.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(pairingId));
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final saved = record?.contactId != null && contacts.any((c) => c.id == record!.contactId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.txDetailsReceivedFrom, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(name, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
          if (record != null && !saved) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async => _attach(ref, await savePairingAsNewContact(context, record)),
                    child: Text(l.pairSaveNewContact, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async => _attach(ref, await pickContactForPairing(context)),
                    child: Text(l.pairAddToAContact, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WithdrawalBlock extends ConsumerWidget {
  const WithdrawalBlock({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = withdrawalOf(ref, tx);
    if (w == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    final confirmations = txConfirmations(tx, tip);
    final posted = confirmations != null;
    final confirmed = posted && confirmations >= target;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!posted) ...[
            EdgeCard(
              edge: t.info,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.reqReceivedWaiting(w.name), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(l.reqReceivedWaitingBody, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (w.slate.reference case final reference? when reference.isNotEmpty) ...[
            Text(l.reqReference, style: theme.textTheme.labelMedium?.copyWith(color: t.dim)),
            const SizedBox(height: 2),
            // The exchange's own words for it: shown, never trusted for crediting.
            Text(reference, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
          ],
          StatusTimeline(
            steps: [
              TimelineStep(l.reqTlAnswerDelivered(w.name), TimelineState.done),
              TimelineStep(
                l.reqTlPosted(w.name),
                posted ? TimelineState.done : TimelineState.current,
                detail: posted ? null : l.reqTlPostedHint,
              ),
              if (confirmed)
                TimelineStep(l.reqTlConfirmed, TimelineState.done)
              else if (posted)
                TimelineStep(l.reqTlConfirming, TimelineState.current, detail: l.reqTlConfirmingHint(confirmations, target))
              else
                TimelineStep(l.reqTlConfirmed, TimelineState.todo),
            ],
          ),
        ],
      ),
    );
  }
}
