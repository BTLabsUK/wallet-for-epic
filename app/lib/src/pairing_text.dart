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
/// Minutes round up, so the last minute reads `1 min` until it is under a minute.
String pairingSpan(AppLocalizations l, Duration span) {
  if (span < const Duration(minutes: 1)) return l.pairDurUnderMinute;
  final minutes = (span.inSeconds / 60).ceil();
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
