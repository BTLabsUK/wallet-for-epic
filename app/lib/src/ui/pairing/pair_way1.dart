// SPDX-License-Identifier: Apache-2.0
/// Way 1, Pair with a contact: the contact page's Pair. When a request can be sent (the
/// contact's wallet is a proven Epic Cash peer, its proof fresh, Epicbox on) the one sheet
/// asks Send request · Show my code instead; otherwise Pair opens the Pair screen framed for
/// the contact. Also the Pair requests list: requests from contacts, each with Pair · Not now.
library;

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
import '../../trust_ids.dart';
import '../kit/kit_button.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_tokens.dart';
import '../notices.dart' show NoticeLevel, noticeProvider;
import 'pair_flow.dart';
import '../address_view.dart' show ShortAddressText;
import '../key_picture.dart';
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
  final choice = await showKitSheet<bool>(context: context, builder: (_) => _RequestSheet(contact: contact));
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
    return KitSheet(
      title: l.pairWithName(contact.name),
      primary: KitButton(key: way1SendKey, label: l.pairSendRequest, semanticsId: TrustIds.pairflowRequestSend, onPressed: () => Navigator.pop(context, true)),
      secondary: KitButton(
        key: way1ShowCodeKey,
        label: l.pairShowMyCodeInstead,
        kind: KitButtonKind.quiet,
        semanticsId: TrustIds.pairflowRequestCode,
        onPressed: () => Navigator.pop(context, false),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(l.pairRequestBody, style: KitType.body.copyWith(color: t.dim)),
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
    return PairFlowPage(
      title: l.pairRequestsTitle,
      back: true,
      leadingId: TrustIds.pairflowRequestsBack,
      children: [
        for (final r in requests) ...[
          _RequestRow(request: r, contact: contactOfRequest(contacts, r)),
          const PairGap(),
        ],
      ],
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
    final t = context.tokens;
    final name = contact?.name ?? request.claimedName;
    return PairCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                        Text(l.pairWantsToPair(name), style: KitType.rowTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        ShortAddressText(request.fromAddress, style: KitType.rowSub.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                ],
              ),
              const PairGap(12),
              Row(
                children: [
                  Expanded(
                    child: KitButton(key: requestsPairKey, label: l.pairRequestPair, small: true, semanticsId: TrustIds.pairflowRequestsPair, onPressed: () => _pair(context, ref)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KitButton(
                      key: requestsNotNowKey,
                      label: l.pairNotNow,
                      small: true,
                      kind: KitButtonKind.quiet,
                      semanticsId: TrustIds.pairflowRequestsNotNow,
                      onPressed: () => pairingCall(ref, (api) => api.dismissRequest(request.id)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    return KitRow(
      key: contactsRequestsKey,
      title: l.pairRequestsRow(count),
      leading: KitIconWell(KitIcons.contact, color: t.info),
      chevron: true,
      semanticsId: TrustIds.pairflowRequestsRow,
      onTap: () => openPairRequests(context),
    );
  }
}

/// The Pair requests row, for tests.
const Key contactsRequestsKey = ValueKey('contacts-requests');
