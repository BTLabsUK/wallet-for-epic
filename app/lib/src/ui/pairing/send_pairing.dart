/// What Send shows under the recipient for a saved contact (SPEC 2.5, 2.9): "Send via" with the
/// kinds of address the contact has, when it has several (a kind whose method is off in
/// Settings › Transactions shows disabled, with the reason); for a paired contact its trust and
/// whether the payment is sealed, and for Epicbox the switch to send through its mailbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../payment_prefs.dart';
import '../../settings.dart';
import '../../wallet_service.dart';
import '../method_names.dart';
import '../net_block.dart' show methodOffReason;
import '../theme/tokens.dart';
import 'pairing_parts.dart';

/// The key of the mailbox switch, for tests.
const Key sendViaMailboxKey = ValueKey('send-via-mailbox');

/// The key of the "Send via" segments, for tests.
const Key sendViaKey = ValueKey('send-via');

/// The pairing a send to [address] would be sealed for, or null: the paired contact the
/// address belongs to.
PairingRecord? sendPairingFor(WidgetRef ref, String address) {
  if (!ref.watch(pairingSupportedProvider)) return null;
  final contact = contactFor(ref.watch(contactsProvider).value ?? const <Contact>[], address);
  return contact == null ? null : ref.watch(contactPairingProvider(contact.id));
}

class SendPairingLine extends ConsumerWidget {
  const SendPairingLine({
    super.key,
    required this.address,
    required this.epicbox,
    required this.viaMailbox,
    required this.onViaMailbox,
    required this.onAddress,
  });

  /// The recipient as typed or picked.
  final String address;

  /// The Epicbox method is chosen: the mailbox switch shows.
  final bool epicbox;
  final bool viaMailbox;
  final ValueChanged<bool> onViaMailbox;

  /// Another of the contact's addresses was chosen under Send via.
  final ValueChanged<String> onAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final contact = contactFor(ref.watch(contactsProvider).value ?? const <Contact>[], address);
    if (contact == null) return const SizedBox.shrink();
    final pairing = sendPairingFor(ref, address);
    final kinds = contact.kinds;
    final current = parseRecipient(address).kind;
    final prefs = ref.watch(appSettingsProvider).value?.payments ?? PaymentPrefs.defaults;
    final mailbox = pairing != null && epicbox && pairing.seals && ref.watch(pairNetProvider) == PairNet.online;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kinds.length > 1) ...[
            Text(l.sendVia, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.dim)),
            const SizedBox(height: 4),
            SegmentedButton<RecipientKind>(
              key: sendViaKey,
              segments: [
                for (final k in kinds)
                  ButtonSegment(
                    value: k,
                    label: Text(recipientMethodWord(l, k)),
                    enabled: prefs.offers(MethodKind.ofRecipient(k)),
                    tooltip: prefs.offers(MethodKind.ofRecipient(k)) ? null : methodOffReason(l, MethodKind.ofRecipient(k)),
                  ),
              ],
              selected: {if (kinds.contains(current)) current else kinds.first},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onAddress(contact.addressOf(s.first)!),
            ),
            const SizedBox(height: 8),
          ],
          if (pairing != null)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                TrustBadge(pairing),
                if (pairing.seals && (!epicbox || viaMailbox)) SealedBadge(name: contact.name),
              ],
            ),
          if (mailbox) ...[
            const SizedBox(height: 8),
            PairCard(
              children: [
                PairSwitchRow(
                  switchKey: sendViaMailboxKey,
                  label: l.sendViaMailbox(contact.name),
                  info: '',
                  hint: l.sendViaMailboxHint(pairing.homeRelay),
                  value: viaMailbox,
                  onChanged: onViaMailbox,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
