// SPDX-License-Identifier: Apache-2.0
/// What Send shows under the recipient for a saved contact: "Send via" with the
/// kinds of address the contact has, when it has several (a kind whose method is off in
/// Settings › Transactions shows disabled, with the reason); for a paired contact its trust and
/// whether the payment is sealed, and for Epicbox the switch to send through its mailbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart' show plainReasonText, sendViaMailboxHintOf;
import '../../payment_prefs.dart';
import '../../settings.dart';
import '../../trust/policy.dart' show MailboxDefault;
import '../../trust/trust_providers.dart' show mailboxDefaultFor;
import '../../wallet_service.dart';
import '../badge.dart';
import '../method_names.dart';
import '../net_block.dart' show methodOffReason;
import '../status_icons.dart' show EpicGlyphs;
import '../theme/tokens.dart';
import 'pairing_parts.dart';

/// The key of the mailbox switch, for tests.
const Key sendViaMailboxKey = ValueKey('send-via-mailbox');

/// The key of the "Send via" segments, for tests.
const Key sendViaKey = ValueKey('send-via');

/// The pairing a send to [address] would be sealed for, or null: the paired contact the
/// address belongs to. [watch] false reads once, outside a build.
PairingRecord? sendPairingFor(WidgetRef ref, String address, {bool watch = true}) {
  if (!(watch ? ref.watch(pairingSupportedProvider) : ref.read(pairingSupportedProvider))) return null;
  final contacts = (watch ? ref.watch(contactsProvider) : ref.read(contactsProvider)).value ?? const <Contact>[];
  final contact = contactFor(contacts, address);
  if (contact == null) return null;
  final pairing = contactPairingProvider(contact.id);
  final p = watch ? ref.watch(pairing) : ref.read(pairing);
  // The pairing proves the Epicbox address it carries, not the contact's other addresses: an
  // HTTP or Tor address, or one a contacts file added, never shows its badge.
  if (p == null || parseRecipient(address).kind != RecipientKind.epicbox) return null;
  final paired = p.paymentsAddress;
  if (paired != null && epicboxKey(paired) != epicboxKey(address)) return null;
  return p;
}

/// How long without a sealed message from a contact before Send says so.
const Duration sealQuietFor = Duration(days: 90);

class SendPairingLine extends ConsumerWidget {
  const SendPairingLine({
    super.key,
    required this.address,
    required this.epicbox,
    required this.viaMailbox,
    required this.onViaMailbox,
    required this.onAddress,
    this.showVia = true,
  });

  /// "Send via" with the contact's other addresses; off where Send's own Change menu picks
  /// them.
  final bool showVia;

  /// The recipient as typed or picked.
  final String address;

  /// The Epicbox method is chosen: the pairing switch shows.
  final bool epicbox;

  /// The user's choice on the pairing switch; null follows the rule's default.
  final bool? viaMailbox;
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
    // The phone sends to an http(s) address whatever its stored Link · HTTP switch says.
    final prefs = (ref.watch(appSettingsProvider).value?.payments ?? PaymentPrefs.defaults).copyWith(linkHttp: true);
    // The rule (trust policy) says whether the pairing route is offered and which way the
    // switch starts; the user's tap overrides it until the recipient changes.
    final d = pairing == null ? const MailboxDefault.hidden() : mailboxDefaultFor(ref, contact, pairing);
    final mailbox = pairing != null && epicbox && d.offered;
    final on = viaMailbox ?? d.on;
    final hint = switch (viaMailbox) {
      false => l.sendViaPublicHint(contact.name),
      null when !d.on => plainReasonText(l, contact.name, d),
      _ => pairing == null ? null : sendViaMailboxHintOf(l, pairing),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showVia && kinds.length > 1) ...[
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
                if (pairing.seals && (!epicbox || (mailbox && on))) SealedBadge(name: contact.name),
              ],
            ),
          if (mailbox) ...[
            const SizedBox(height: 8),
            PairCard(
              children: [
                PairSwitchRow(
                  switchKey: sendViaMailboxKey,
                  label: l.sendViaMailbox,
                  info: '',
                  hint: hint,
                  value: on,
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

/// Keys of the pairing recipient (a contact with no address), for tests.
const Key sendPairingCardKey = ValueKey('send-pairing-card');
const Key sendPairingClearKey = ValueKey('send-pairing-clear');
const Key sendPairingReadoutKey = ValueKey('send-pairing-readout');
const Key sendPairingCheckKey = ValueKey('send-pairing-check');

/// Send's recipient when it is a paired contact with no address (DESIGN 1.2): in the To slot,
/// the avatar, the name with its trust badge and "Through Anna's pairing", never an address;
/// [onClear] (×) goes back to the empty To field.
class PairingRecipientCard extends StatelessWidget {
  const PairingRecipientCard({super.key, required this.pairing, required this.name, this.onClear});

  final PairingRecord pairing;
  final String name;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      key: sendPairingCardKey,
      padding: EdgeInsetsDirectional.fromSTEB(12, 10, onClear == null ? 12 : 0, 10),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Row(
        children: [
          PairAvatar(name: name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall?.copyWith(color: t.text)),
                    TrustBadge(pairing, short: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l.sendRecipientPairing(name), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
              ],
            ),
          ),
          if (onClear case final clear?)
            IconButton(
              key: sendPairingClearKey,
              tooltip: l.sendClearRecipient,
              icon: Icon(Icons.close, color: t.dim),
              onPressed: clear,
            ),
        ],
      ),
    );
  }
}

/// A [PairSwitchRow] without the switch: the mailbox a pairing-only contact is paid through,
/// as a fact. [paused] while Epicbox is off: the payment waits.
class PairReadoutRow extends StatelessWidget {
  const PairReadoutRow({super.key, required this.label, required this.hint, this.paused = false});

  final String label;
  final String hint;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(paused ? Icons.pause : EpicGlyphs.sealed, size: 20, color: paused ? t.warn : t.dim),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: t.text)),
                    Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the pairing recipient: the Sealed badge and the mailbox readout ("Send through Anna's
/// mailbox", "Sealed. Delivered via …", or "Paused while Epicbox is off"). When the pairing
/// can no longer take a payment (keys changed meanwhile, or a card that does not open sealed
/// messages), a warn notice with Check the words instead.
class SendPairingMailbox extends ConsumerWidget {
  const SendPairingMailbox({super.key, required this.pairing, required this.name, required this.onCheck});

  final PairingRecord pairing;
  final String name;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!pairing.paysByMailbox) {
      final changed = pairing.state == PairingState.keysChanged;
      return PairEdgeNotice(
        key: sendPairingReadoutKey,
        tone: BadgeTone.warn,
        title: changed ? l.contactKeysChangedTitle(name) : l.contactSendNoSealed(name),
        body: changed ? l.contactKeysChangedBody : null,
        actions: [
          if (changed) OutlinedButton(key: sendPairingCheckKey, onPressed: onCheck, child: Text(l.noticeCheckWords)),
        ],
      );
    }
    final paused = ref.watch(pairNetProvider) == PairNet.epicboxOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: SealedBadge(name: name)),
        const SizedBox(height: 8),
        PairCard(
          key: sendPairingReadoutKey,
          children: [
            PairReadoutRow(
              label: l.sendViaMailbox,
              hint: paused ? l.contactPausedEpicboxOff : sendViaMailboxHintOf(l, pairing),
              paused: paused,
            ),
          ],
        ),
      ],
    );
  }
}
