// SPDX-License-Identifier: Apache-2.0
/// Words for pairing that the phone, the desktop and the data layers share: failures, names,
/// time spans, the ended reasons. Plain Dart over the app's strings, so a data layer can word
/// an error too.
library;

import 'dart:ui' show Locale, PlatformDispatcher;

import 'l10n.dart';
import 'models.dart';
import 'scan/scan_checks.dart' show CodeOrigin;
import 'trust/policy.dart' show MailboxDefault, PlainReason;

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
  PairingFailure.kindDiffers => l.pairKindDiffersTitle,
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
      PairingFailure.kindDiffers => l.pairKindDiffersBody,
      PairingFailure.inviteDismissed => null,
      PairingFailure.ended => l.pairEndedBody,
      PairingFailure.waiting => l.pairWaitingSendBody,
    };

/// The reason line of an ended pairing in a notice and on the contact's page, under the title
/// Pairing ended ("Anna reported the words do not match").
String pairingEndedText(AppLocalizations l, PairingEndReason reason, String name) => switch (reason) {
  PairingEndReason.mismatch => l.pairEndedMismatch,
  PairingEndReason.peerMismatch => l.pairEndedPeerMismatch(name),
  PairingEndReason.unpaired => l.noticeUnpaired(name),
  PairingEndReason.neverFinished => l.pairEndedNeverFinished(name),
};

/// The reason line of an ended pairing under the other wallet's name (a contacts row): the name
/// is the title, so the line does not repeat it. The contact's page says the name: [pairingEndedText].
String pairingEndedRowText(AppLocalizations l, PairingEndReason reason) => switch (reason) {
  PairingEndReason.mismatch => l.pairEndedMismatch,
  PairingEndReason.peerMismatch => l.pairEndedRowPeerMismatch,
  PairingEndReason.unpaired => l.pairEndedRowUnpaired,
  PairingEndReason.neverFinished => l.pairEndedRowNeverFinished,
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

/// How an invite reached the pair-request dialog: the camera, a paste, or another app (a
/// browser's Open in BT Wallet, a tapped `epiccash://pair/…`). A request to this wallet's
/// address is [PairingInvitePreview.isRequest] instead. Null where the caller cannot tell,
/// and the dialog then shows no Source row.
enum InviteSource { scanned, pasted, opened }

/// The [InviteSource] of a code that came by [origin].
InviteSource inviteSourceOf(CodeOrigin origin) => switch (origin) {
  CodeOrigin.qr => InviteSource.scanned,
  CodeOrigin.link => InviteSource.opened,
  CodeOrigin.paste => InviteSource.pasted,
};

/// The dialog's Source value for [source], or for a request; null when there is none.
String? inviteSourceText(AppLocalizations l, InviteSource? source, {bool request = false}) {
  if (request) return l.pairIncomingSourceRequest;
  return switch (source) {
    InviteSource.scanned => l.pairIncomingSourceScanned,
    InviteSource.pasted => l.pairIncomingSourcePasted,
    InviteSource.opened => l.pairIncomingSourceOpened,
    null => null,
  };
}

/// The host of an invite's home relay (`domain:port`): the server the dialog names. Empty
/// when the invite names none.
String relayHostOf(String homeRelay) {
  final relay = homeRelay.trim();
  final colon = relay.lastIndexOf(':');
  if (colon <= 0 || int.tryParse(relay.substring(colon + 1)) == null) return relay;
  return relay.substring(0, colon);
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
  final names = {for (final n in [record.name, record.label]) if (n != null && norm(n).isNotEmpty && !isUnnamed(n)) norm(n)};
  if (names.isEmpty) return null;
  final same = [for (final c in contacts) if (names.contains(norm(nameOf(c))) && pairingVouchesFor(record, epicboxOf(c))) c];
  final withPairing = same.where(paired).toList();
  if (withPairing.length == 1) return withPairing.single;
  return withPairing.isEmpty && same.length == 1 ? same.single : null;
}

/// The name sent on the wire when the user has none: LEPIC needs 1 to 48 bytes. Never translated.
const String unnamedPeerName = 'BT Wallet';

/// True when a claimed [name] stands for "no name": empty, or [unnamedPeerName] (trimmed, exact).
bool isUnnamed(String? name) {
  final t = (name ?? '').trim();
  return t.isEmpty || t == unnamedPeerName;
}

/// What a row calls [record]: the label the user gave, else the name the other side chose,
/// else "Unnamed wallet" when it chose none.
String peerLabel(AppLocalizations l, PairingRecord record) {
  final label = record.label;
  if (label != null && label.isNotEmpty) return label;
  return isUnnamed(record.name) ? l.pairUnnamed : record.name!.trim();
}

/// The name the app shows for [record]: the contact's when it is attached, else [peerLabel].
/// Without [l] (no strings at hand) a pairing with no name reads empty.
String pairingName(PairingRecord record, Iterable<Contact> contacts, {AppLocalizations? l}) {
  final cid = record.contactId;
  if (cid != null) {
    final c = contacts.where((c) => c.id == cid).firstOrNull;
    if (c != null) return c.name;
  }
  if (l != null) return peerLabel(l, record);
  final label = record.label;
  if (label != null && label.isNotEmpty) return label;
  return isUnnamed(record.name) ? '' : record.name!.trim();
}

/// The app's strings in [locale] (null: the system's), for providers that have no context.
AppLocalizations pairingStrings(Locale? locale) {
  try {
    return lookupAppLocalizations(locale ?? PlatformDispatcher.instance.locale);
  } on Object {
    return englishStrings;
  }
}

/// The line under Send's address selector for the paired address: made when the two paired,
/// the Epicbox server it goes through, and the day the contact moved there when that was in the
/// last 30 days (`relay_moves.dart`). Also the readout for a contact with no public address.
String sendRoutePairedLineOf(AppLocalizations l, PairingRecord p) {
  final moved = p.movedAt;
  return moved == null ? l.sendRoutePairedLine(p.homeRelay) : l.sendRoutePairedMovedLine(p.homeRelay, localDayMonth(l, moved));
}

/// The line under Send's address selector for [name]'s public Epicbox address.
String sendRoutePublicLineOf(AppLocalizations l, String name) => l.sendRoutePublicLine(name);

/// The amber line under Send's address selector while the public address is selected because
/// the rule picked it: why, this time. Null when the rule starts on the paired address.
String? sendRouteReasonText(AppLocalizations l, String name, PairingRecord p, MailboxDefault d) => switch (d.reason) {
  PlainReason.none => null,
  PlainReason.otherApp => l.sendRouteReasonOtherApp(name),
  PlainReason.notHeard => l.sendRouteReasonNotHeard(name, localDayMonth(l, d.since!)),
  PlainReason.unanswered => l.sendRouteReasonUnanswered(name, l.sendRoutePairedInline, localDayMonth(l, d.since!)),
  PlainReason.notAnswering => l.sendRouteReasonNotAnswering(name, l.sendRoutePairedInline),
  PlainReason.relayDown => l.sendRouteReasonRelayDown(p.homeRelay, l.sendRoutePairedInline),
};

/// The amber line on either option when the Epicbox server both addresses use is not answering
/// ([MailboxDefault.serverDown]). Null otherwise.
String? sendRouteServerDownText(AppLocalizations l, PairingRecord p, MailboxDefault d) =>
    d.serverDown ? l.sendRouteServerDown(p.homeRelay) : null;
