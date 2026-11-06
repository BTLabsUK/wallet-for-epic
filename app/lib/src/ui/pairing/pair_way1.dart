// SPDX-License-Identifier: Apache-2.0
/// Way 1, Pair with a contact: the contact page's Pair. When a request can be sent (the
/// contact's wallet is a proven Epic Cash peer, its proof fresh, Epicbox on) the one sheet
/// asks Send request · Show my code instead; otherwise Pair opens the Pair screen framed for
/// the contact. Also the Pair requests list: requests from contacts, each with Pair · Not now.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../errors.dart';
import '../../key_picture.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../trust/policy.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../address_view.dart' show ShortAddressText;
import '../key_picture.dart';
import '../phone_sheet.dart';
import '../settings_rows.dart' show NavChevron;
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'pair_incoming.dart';
import 'pair_screen.dart';
import 'pairing_parts.dart';

/// Keys for tests.
const Key way1SendKey = ValueKey('way1-send');
const Key way1ShowCodeKey = ValueKey('way1-show-code');
const Key requestsPairKey = ValueKey('requests-pair');
const Key requestsNotNowKey = ValueKey('requests-not-now');

/// Whether a request can be sent to [contact] now: a plain contact with an Epicbox address
/// whose key is fresh and claims pair requests, and Epicbox on.
Future<bool> canSendPairRequest(WidgetRef ref, Contact contact) async {
  final address = contact.epicbox;
  if (address == null || address.trim().isEmpty) return false;
  if (ref.read(pairNetProvider) != PairNet.online) return false;
  final relationship = ref.read(contactRelationshipProvider(contact.id));
  final compat = await ref.read(contactPeerCompatProvider(address).future);
  return mayOfferPair(compat, relationship, ref.read(pairingClockProvider)());
}

/// Pair on the contact page: the request sheet when a request can go, else the Pair screen
/// framed for [contact].
Future<void> pairWithContact(BuildContext context, WidgetRef ref, Contact contact) async {
  final sendable = await canSendPairRequest(ref, contact);
  if (!context.mounted) return;
  if (!sendable) return _showCode(context, contact);
  final choice = await showPhoneSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RequestSheet(contact: contact),
  );
  if (choice == null || !context.mounted) return;
  if (!choice) return _showCode(context, contact);
  await sendPairRequest(context, ref, contact);
}

Future<void> _showCode(BuildContext context, Contact contact) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairScreen(contact: contact)));

/// Sends the request to [contact]; a refusal is one notice, and one that cannot be sent at
/// all opens the Pair screen for the contact instead.
Future<void> sendPairRequest(BuildContext context, WidgetRef ref, Contact contact) async {
  final l = context.l10n;
  final notices = ref.read(noticeProvider.notifier);
  final name = await seenAsForWire(ref);
  if (!context.mounted) return;
  try {
    await pairingCall(ref, (api) => api.requestPairing(toAddress: contact.epicbox!, name: name, contactId: contact.id));
    notices.show(l.pairRequestSent(localDayMonth(l, ref.read(pairingClockProvider)())), level: NoticeLevel.success);
  } catch (error) {
    if (!context.mounted) return;
    final failure = pairingFailureOf(error);
    if (failure == PairingFailure.peerNotProven || failure == PairingFailure.relayUnreachable) {
      await _showCode(context, contact);
      return;
    }
    notices.show(failure == null ? describeError(l, error) : pairingFailureText(l, failure, name: contact.name), level: NoticeLevel.warning);
  }
}

/// "Pair with Anna": one sentence, Send request · Show my code instead. Pops true to send.
class _RequestSheet extends StatelessWidget {
  const _RequestSheet({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final foot = math.max(MediaQuery.paddingOf(context).bottom, MediaQuery.viewInsetsOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + foot),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l.pairWithName(contact.name), style: theme.textTheme.titleLarge)),
          const SizedBox(height: 10),
          Text(l.pairRequestBody, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 20),
          FilledButton(
            key: way1SendKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.pairSendRequest),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: way1ShowCodeKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.pairShowMyCodeInstead),
          ),
        ],
      ),
    );
  }
}

/// Pair requests: those from contacts, newest first, each with Pair · Not now. Pair opens the
/// same incoming sheet; Not now dismisses the request (a newer one shows again).
class PairRequestsScreen extends ConsumerWidget {
  const PairRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(pairRequestsProvider).value ?? const <PairRequest>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final none = requests.isEmpty && ref.watch(pairRequestsProvider).hasValue;
    if (none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) Navigator.of(context).pop();
      });
    }
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairRequestsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [for (final r in requests) _RequestRow(request: r, contact: contactOfRequest(contacts, r))],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.request, required this.contact});

  final PairRequest request;
  final Contact? contact;

  Future<void> _pair(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    try {
      final preview = await ref.read(pairingApiProvider).openRequest(request.id);
      if (!context.mounted) return;
      await showIncomingInvite(context, ref, preview, contact: contact);
    } catch (error) {
      if (!context.mounted) return;
      final failure = pairingFailureOf(error);
      ref.read(noticeProvider.notifier).show(failure == null ? describeError(l, error) : pairingFailureText(l, failure, name: request.claimedName), level: NoticeLevel.warning);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final name = contact?.name ?? request.claimedName;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Row(
        children: [
          if (inviteKeyOf(request.inviteLink) case final key?)
            KeyPictureView(picture: KeyPicture.of(key), size: 48)
          else
            PairAvatar(name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.pairWantsToPair(name), style: theme.textTheme.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                ShortAddressText(request.fromAddress, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(key: requestsPairKey, onPressed: () => _pair(context, ref), child: Text(l.pairRequestPair)),
          const SizedBox(width: 4),
          TextButton(
            key: requestsNotNowKey,
            onPressed: () => pairingCall(ref, (api) => api.dismissRequest(request.id)),
            child: Text(l.pairNotNow),
          ),
        ],
      ),
    );
  }
}

/// Opens the Pair requests list.
void openPairRequests(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PairRequestsScreen()));

/// The Pair requests row of Contacts: shown only while contacts' requests wait.
class PairRequestsRow extends ConsumerWidget {
  const PairRequestsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final count = (ref.watch(pairRequestsProvider).value ?? const <PairRequest>[]).length;
    if (count == 0) return const SizedBox.shrink();
    return ListTile(
      key: contactsRequestsKey,
      minTileHeight: 64,
      // The contacts list's one tile size and text column (48 tile, 12 gap).
      horizontalTitleGap: 12,
      leading: GlyphTile(size: 48, child: Icon(Icons.handshake_outlined, color: t.info)),
      title: Text(l.pairRequestsRow(count)),
      trailing: const NavChevron(),
      onTap: () => openPairRequests(context),
    );
  }
}

/// The Pair requests row, for tests.
const Key contactsRequestsKey = ValueKey('contacts-requests');
