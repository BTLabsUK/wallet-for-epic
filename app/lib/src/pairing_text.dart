// SPDX-License-Identifier: Apache-2.0
/// Words for pairing that the phone, the desktop and the data layers share: failures, names,
/// time spans, the ended reasons. Plain Dart over the app's strings, so a data layer can word
/// an error too.
library;

import 'l10n.dart';
import 'models.dart';

/// The answerer's wait: the answer went to the relay too, so the pairing usually finishes by
/// itself. Only when it has not after this long is the answer offered to send back by hand,
/// as the fallback (Epicbox off on the other side, its wallet closed). At once when Epicbox
/// is off or the wallet is Offline.
const Duration pairReplyFallbackAfter = Duration(seconds: 30);

/// The one line a [failure] reads as: a notice, a field error, a dialog's title. [name] is
/// the other side's name where the sentence names it.
String pairingFailureText(AppLocalizations l, PairingFailure failure, {String name = ''}) => switch (failure) {
  PairingFailure.expired => l.pairExpiredTitle,
  PairingFailure.alreadyUsed => l.pairUsedTitle,
  PairingFailure.cancelled => l.pairCancelledTitle(name),
  PairingFailure.noAnswer => l.pairNoAnswerTitle(name),
  PairingFailure.notCompleted => l.pairNotCompletedTitle,
  PairingFailure.changedOnTheWay => l.pairChangedTitle,
  PairingFailure.newerVersion => l.pairNewerTitle,
  PairingFailure.notFound => l.pairNotFoundTitle,
  PairingFailure.invalid => l.pairInvalidLink,
  PairingFailure.relayUnreachable => l.pairRelayUnreachableTitle,
  PairingFailure.noRelay || PairingFailure.relaysBlocked => l.pairRelayUnreachableTitle,
  PairingFailure.ownCard => l.pairOwnCode,
  PairingFailure.sealedForOther => l.openSealedOtherTitle,
  PairingFailure.wrongNetwork => l.scanWrongNetworkTitle,
  PairingFailure.otherAddress => name.isEmpty ? l.pairOtherAddress : l.pairOtherAddressTitle(name),
  PairingFailure.otherWallet || PairingFailure.addressProofMissing => l.pairOtherWalletTitle,
  PairingFailure.peerNotProven => l.pairNotProvenBody(name),
  PairingFailure.inProgress => l.pairInProgressTitle(name),
  PairingFailure.crossed => l.pairCrossedTitle(name),
  PairingFailure.inviteDismissed => l.pairDismissedTitle(name),
  PairingFailure.ended => l.pairEndedShort,
  PairingFailure.waiting => l.pairWaitingFor(name),
};

/// The second line of an outcome for [failure], or null where the title says it all.
String? pairingFailureBody(AppLocalizations l, PairingFailure failure, {String name = '', bool file = false}) =>
    switch (failure) {
      PairingFailure.expired => l.pairExpiredBody(name),
      PairingFailure.alreadyUsed => l.pairUsedBody,
      PairingFailure.cancelled => l.pairCancelledBody,
      PairingFailure.noAnswer => l.pairNoAnswerBody,
      PairingFailure.notCompleted => l.pairNotCompletedBody(name),
      PairingFailure.changedOnTheWay => l.pairChangedBody(name),
      PairingFailure.newerVersion => file ? l.pairNewerFileBody : l.pairNewerInviteBody,
      PairingFailure.notFound => null,
      PairingFailure.invalid => l.pairInvalidBody,
      PairingFailure.relayUnreachable || PairingFailure.noRelay || PairingFailure.relaysBlocked => l.pairRelayUnreachableBody,
      PairingFailure.ownCard => l.pairOwnCodeBody,
      PairingFailure.sealedForOther => l.openSealedOtherBody,
      PairingFailure.wrongNetwork => l.pairWrongNetworkBody,
      PairingFailure.otherAddress => name.isEmpty ? null : l.pairOtherAddressBody(name),
      PairingFailure.otherWallet || PairingFailure.addressProofMissing => l.pairOtherWalletBody,
      PairingFailure.peerNotProven => null,
      PairingFailure.inProgress => null,
      PairingFailure.crossed => null,
      PairingFailure.inviteDismissed => null,
      PairingFailure.ended => l.pairEndedBody,
      PairingFailure.waiting => l.pairWaitingSendBody,
    };

/// The reason line of an ended pairing ("Anna reported the words do not match").
String pairingEndedText(AppLocalizations l, PairingEndReason reason, String name) => switch (reason) {
  PairingEndReason.mismatch => l.pairEndedMismatch,
  PairingEndReason.peerMismatch => l.pairEndedPeerMismatch(name),
  PairingEndReason.unpaired => l.noticeUnpaired(name),
  PairingEndReason.neverFinished => l.pairEndedNeverFinished(name),
};

/// A short time span for countdowns: `6 d 23 h`, `23 h 12 min`, `12 min`, `under a minute`.
/// Whole minutes only, as a countdown counts: a fresh 24 h invite reads `23 h 59 min`, never
/// `1 d 0 h` for its first minute, and the last minute reads `under a minute`.
String pairingSpan(AppLocalizations l, Duration span) {
  if (span < const Duration(minutes: 1)) return l.pairDurUnderMinute;
  final minutes = span.inMinutes;
  if (minutes < 60) return l.pairDurMinutes(minutes);
  if (minutes < 24 * 60) return l.pairDurHours(minutes ~/ 60, minutes % 60);
  return l.pairDurDays(minutes ~/ (24 * 60), (minutes % (24 * 60)) ~/ 60);
}

/// A countdown clock, `9:32`.
String pairingClock(Duration left) {
  final s = left.isNegative ? 0 : left.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The address-book contact a new pairing [record] most likely belongs to: the one whose name
/// is the name it chose, ignoring case and spaces. One with a pairing of its own comes first
/// (a restore or a re-pair, whose key check starts once the user attaches it); several
/// unpaired ones of that name are no suggestion. Only offered, never attached on its own, and
/// never one whose Epicbox address ([epicboxOf]) attaching refuses ([pairingVouchesFor]).
T? sameNamedContact<T>(
  PairingRecord record,
  Iterable<T> contacts,
  String Function(T) nameOf, {
  required bool Function(T) paired,
  required String? Function(T) epicboxOf,
}) {
  String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final names = {for (final n in [record.name, record.label]) if (n != null && norm(n).isNotEmpty) norm(n)};
  if (names.isEmpty) return null;
  final same = [for (final c in contacts) if (names.contains(norm(nameOf(c))) && pairingVouchesFor(record, epicboxOf(c))) c];
  final withPairing = same.where(paired).toList();
  if (withPairing.length == 1) return withPairing.single;
  return withPairing.isEmpty && same.length == 1 ? same.single : null;
}

/// The name the app shows for [record]: the contact's when it is attached, else the name the
/// other side chose, else the label of an invite.
String pairingName(PairingRecord record, Iterable<Contact> contacts) {
  final cid = record.contactId;
  if (cid != null) {
    final c = contacts.where((c) => c.id == cid).firstOrNull;
    if (c != null) return c.name;
  }
  return record.shownName;
}
