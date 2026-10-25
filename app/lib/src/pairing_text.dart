/// Words for pairing that the phone, the desktop and the data layers share: failures, names,
/// time spans. Plain Dart over the app's strings, so a data layer can word an error too.
library;

import 'l10n.dart';
import 'models.dart';

/// The one line a [failure] reads as: the outcome screen's title, a field error, a toast.
/// [name] is the other side's name where the sentence names it.
String pairingFailureText(AppLocalizations l, PairingFailure failure, {String name = ''}) => switch (failure) {
  PairingFailure.expired => l.pairExpiredTitle,
  PairingFailure.alreadyUsed => l.pairUsedTitle,
  PairingFailure.cancelled => l.pairCancelledTitle(name),
  PairingFailure.noAnswer => l.pairNoAnswerTitle(name),
  PairingFailure.changedOnTheWay => l.pairChangedTitle,
  PairingFailure.newerVersion => l.pairNewerTitle,
  PairingFailure.notFound => l.pairEnterNotFound,
  PairingFailure.invalid => l.pairInvalidLink,
  PairingFailure.relayUnreachable => l.pairRelayUnreachableTitle,
  PairingFailure.ownCard => l.pairOwnCode,
  PairingFailure.sealedForOther => l.openSealedOtherTitle,
};

/// The second line of an outcome screen for [failure], or null where the title says it all.
String? pairingFailureBody(AppLocalizations l, PairingFailure failure, {String name = '', bool file = false}) =>
    switch (failure) {
      PairingFailure.expired => l.pairExpiredBody(name),
      PairingFailure.alreadyUsed => l.pairUsedBody,
      PairingFailure.cancelled => l.pairCancelledBody,
      PairingFailure.noAnswer => l.pairNoAnswerBody,
      PairingFailure.changedOnTheWay => l.pairChangedBody(name),
      PairingFailure.newerVersion => file ? l.pairNewerFileBody : l.pairNewerInviteBody,
      PairingFailure.notFound => null,
      PairingFailure.invalid => l.pairInvalidBody,
      PairingFailure.relayUnreachable => l.pairRelayUnreachableBody,
      PairingFailure.ownCard => l.pairOwnCodeBody,
      PairingFailure.sealedForOther => l.openSealedOtherBody,
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

/// A countdown clock, `9:32`, for the pairing words' ten minutes.
String pairingClock(Duration left) {
  final s = left.isNegative ? 0 : left.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The five pairing [words] as one line to copy: each emoji and its name.
String pairingWordsText(List<SasWord> words) => words.map((w) => '${w.emoji} ${w.name}').join('  ');

/// The address-book contact a new pairing [record] most likely belongs to: the one whose name
/// is the name it chose, ignoring case and spaces. One with a pairing of its own comes first
/// (a restore or a re-pair, whose key check starts once the user attaches it); several
/// unpaired ones of that name are no suggestion. Only offered, never attached on its own
/// (PAIR-LNX-7).
T? sameNamedContact<T>(PairingRecord record, Iterable<T> contacts, String Function(T) nameOf, {required bool Function(T) paired}) {
  String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final names = {for (final n in [record.name, record.label]) if (n != null && norm(n).isNotEmpty) norm(n)};
  if (names.isEmpty) return null;
  final same = [for (final c in contacts) if (names.contains(norm(nameOf(c)))) c];
  final withPairing = same.where(paired).toList();
  if (withPairing.length == 1) return withPairing.single;
  return withPairing.isEmpty && same.length == 1 ? same.single : null;
}
