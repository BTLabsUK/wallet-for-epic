// SPDX-License-Identifier: Apache-2.0
/// What the contact pages and the payment details feed the trust policy (`policy.dart`): the
/// relationship a contact and its pairing make, the Epicbox key the policy is asked about, and
/// the line or notice the policy's answer becomes. Pure functions, shared by phone and desktop.
library;

import '../l10n.dart';
import '../models.dart' show PairingRecord, PairingState;
import 'policy.dart';

/// How long LEPIC keeps what it learned about a key that was silent since: pruned on open.
const Duration peerCompatRetention = Duration(days: 180);

/// The relationship the user has with a contact, from the address book and its pairing.
/// [inContacts]: the contact is saved; [epicboxAddress]: its Epicbox address from the book.
Relationship relationshipOf({
  required bool inContacts,
  required String? epicboxAddress,
  PairingRecord? pairing,
}) {
  final hasAddress = epicboxAddress != null || pairing?.paymentsAddress != null;
  if (pairing == null || pairing.removedByPeer) {
    return inContacts ? Relationship(RelationshipKind.contact, hasEpicboxAddress: hasAddress) : const Relationship.none();
  }
  final kind = switch (pairing.state) {
    PairingState.pendingInvite || PairingState.pendingReply => RelationshipKind.contact,
    PairingState.paired => RelationshipKind.paired,
    PairingState.verified => RelationshipKind.verified,
    PairingState.keysChanged => RelationshipKind.keysChanged,
  };
  return Relationship(kind, waiting: pairing.state.isPending, hasEpicboxAddress: hasAddress);
}

/// The Epicbox address the policy is asked about: the book's, else the pairing card's.
String? trustAddressOf(String? epicboxAddress, PairingRecord? pairing) => epicboxAddress ?? pairing?.paymentsAddress;

/// The words of a contact line, or null for none.
String? contactLineText(AppLocalizations l, ContactLine line, String name) => switch (line.kind) {
  ContactLineKind.none => null,
  ContactLineKind.answeredByOtherApp => l.trustLineOtherApp(name),
  ContactLineKind.notHeardSince => l.trustLineNotHeard(name, localDayMonth(l, line.since!)),
};

/// What the details of an unanswered mailbox send offer, by its age and the contact.
class MailboxResendOffer {
  const MailboxResendOffer({required this.stage, required this.resend});

  final MailboxSendStage stage;

  /// "Cancel and send by Epicbox" is offered (the contact has an Epicbox address).
  final bool resend;

  /// After 24 hours the resend is the main action; at 7 days Cancel is, and the resend second.
  bool get resendPrimary => resend && stage == MailboxSendStage.notAnswered;

  /// The line under the status: "never picked this up" once the relay has dropped it.
  bool get gone => stage == MailboxSendStage.neverPickedUp;
}

/// The offer for a mailbox send made at [sentAt] to the contact [r] stands for, or null while
/// the send is simply waiting.
MailboxResendOffer? mailboxResendOffer(Relationship r, DateTime sentAt, DateTime now) {
  final stage = mailboxSendStage(sentAt, now);
  if (stage == MailboxSendStage.waiting) return null;
  return MailboxResendOffer(stage: stage, resend: mayCancelAndSendByEpicbox(r, sentAt, now));
}

/// The status word of an unanswered mailbox send, or null while it is simply waiting.
String? mailboxStageWord(AppLocalizations l, DateTime sentAt, DateTime now) => switch (mailboxSendStage(sentAt, now)) {
  MailboxSendStage.waiting => null,
  MailboxSendStage.notAnswered => l.mailboxNotAnswered,
  MailboxSendStage.neverPickedUp => l.mailboxNotPickedUp,
};
