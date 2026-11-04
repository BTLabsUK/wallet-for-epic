// SPDX-License-Identifier: Apache-2.0
/// A withdrawal from a paired contact on its payment page: the contact sent it sealed, the
/// wallet signed and answered it on its own, and the contact posts it. "Received. Waiting for
/// Northwind Exchange to post" until it is on the chain, and the timeline: the answer
/// delivered over Epicbox, posted by it, then the confirmations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import 'add_to_contacts_button.dart';
import 'pair_check.dart' show attachPairingTo, pickContactForPairing, savePairingAsNewContact;
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

/// "Received from" on a withdrawal: the paired contact by name. Not in the contacts yet, it
/// offers Add to contacts, as the words result does; nothing is matched by name or address.
class WithdrawalFromRow extends ConsumerWidget {
  const WithdrawalFromRow({super.key, required this.pairingId, required this.name});

  final String pairingId;
  final String name;

  Future<void> _attach(BuildContext context, WidgetRef ref, PairingRecord record, Contact? contact) async {
    if (contact == null || !context.mounted) return;
    await attachPairingTo(context, ref, record, contact);
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
            AddToContactsButton(
              onNew: () async {
                final saved = await savePairingAsNewContact(context, record);
                if (context.mounted) await _attach(context, ref, record, saved);
              },
              onExisting: () async {
                final picked = await pickContactForPairing(context);
                if (context.mounted) await _attach(context, ref, record, picked);
              },
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
            InlineNotice(
              level: NoticeLevel.info,
              title: l.reqReceivedWaiting(w.name),
              text: l.reqReceivedWaitingBody,
              liveRegion: true,
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
              TimelineStep(l.reqTlAnswerDelivered, TimelineState.done),
              TimelineStep(l.reqTlPosted(w.name), posted ? TimelineState.done : TimelineState.current),
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
