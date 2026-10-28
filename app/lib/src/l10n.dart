/// Localisation helpers: the `context.l10n` shortcut, the languages offered in settings, and
/// number and date text in the reader's conventions.
///
/// Strings live in `lib/l10n/app_<locale>.arb`; `flutter gen-l10n` (run by pub get, run, build
/// and test) turns them into [AppLocalizations]. Log lines, the feedback report and files meant
/// for other programs stay in English and never go through here.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'wallet_service.dart' show Chain;

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// The strings for the app's current language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// A language the app is translated into, named in that language, as language pickers do.
typedef AppLanguage = ({String code, String name});

/// Every translation, in the order settings lists them. Keep in step with `lib/l10n/`.
const List<AppLanguage> appLanguages = [
  (code: 'en', name: 'English'),
  (code: 'de', name: 'Deutsch'),
  (code: 'pl', name: 'Polski'),
  (code: 'ru', name: 'Русский'),
  (code: 'zh', name: '简体中文'),
  (code: 'th', name: 'ไทย'),
];

/// English strings, for tests and for code that must not depend on the user's language.
AppLocalizations get englishStrings => lookupAppLocalizations(const Locale('en'));

/// A [FormatException] whose message the user reads, produced in their language when shown.
/// [message] stays English, for logs.
class LocalizedFormatException extends FormatException {
  LocalizedFormatException(this.text, [Object? source])
    : super(text(englishStrings), source);

  final String Function(AppLocalizations l) text;
}

// Numbers.

/// [canonical] number text, as `formatEpic` and `fiatText` write it (`,` between thousands, `.`
/// before decimals), in the separators of [l]'s language: `1,234.5` is `1.234,5` in German and
/// `1 234,5` (with a no-break space) in Polish and Russian.
///
/// Display only. Amount fields take `.` or `,` as the decimal separator and no grouping, so put
/// [localDecimal] text in a field, never this.
String localDigits(AppLocalizations l, String canonical) {
  final symbols = NumberFormat.decimalPattern(l.localeName).symbols;
  final group = symbols.GROUP_SEP;
  final decimal = symbols.DECIMAL_SEP;
  if (group == ',' && decimal == '.') return canonical;
  final out = StringBuffer();
  for (final char in canonical.split('')) {
    out.write(switch (char) {
      ',' => group,
      '.' => decimal,
      _ => char,
    });
  }
  return out.toString();
}

/// An ungrouped amount such as `1.5` with [l]'s decimal separator (`1,5` in German), for text
/// the app puts into an amount field. `parseEpic` reads either separator back.
String localDecimal(AppLocalizations l, String canonical) {
  final decimal = NumberFormat.decimalPattern(l.localeName).symbols.DECIMAL_SEP;
  return decimal == '.' ? canonical : canonical.replaceAll('.', decimal);
}

/// A whole number with [l]'s thousands separator: `2,500,000`, `2.500.000`, `2 500 000`.
String localInt(AppLocalizations l, Object number) =>
    NumberFormat.decimalPattern(l.localeName).format(
      number is BigInt ? number.toInt() : number as num,
    );

// Dates. English keeps the day-first style the app always had ("21 Sep 2026"); the other
// languages use CLDR's patterns ("21. Sept. 2026", "2026年9月21日").

/// `21 Sep 2026`.
String localDay(AppLocalizations l, DateTime t) => (l.localeName == 'en'
        ? DateFormat('d MMM y', 'en')
        : DateFormat.yMMMd(l.localeName))
    .format(t);

/// `21 Sep`.
String localDayMonth(AppLocalizations l, DateTime t) => (l.localeName == 'en'
        ? DateFormat('d MMM', 'en')
        : DateFormat.MMMd(l.localeName))
    .format(t);

/// `14:05`, on the 24-hour clock in every language the app has.
String localClock(AppLocalizations l, DateTime t) =>
    DateFormat.Hm(l.localeName).format(t);

// Names.

/// A chain's name for the screen. `chainLabel` in network.dart is the fixed English name for
/// logs and reports.
String chainName(AppLocalizations l, Chain chain) => switch (chain) {
  Chain.mainnet => l.networkMainnet,
  Chain.floonet => l.networkFloonet,
  Chain.usernet => l.networkUsernet,
};

/// One sentence on what a chain is, for the network picker.
String chainDescription(AppLocalizations l, Chain chain) => switch (chain) {
  Chain.mainnet => l.networkMainnetDescription,
  Chain.floonet => l.networkFloonetDescription,
  Chain.usernet => l.networkUsernetDescription,
};

/// ` (Floonet, test coins)` to put after a title on a test network, empty for Mainnet.
String networkSuffix(AppLocalizations l, Chain chain) => switch (chain) {
  Chain.mainnet => '',
  Chain.floonet || Chain.usernet => l.networkTestSuffix(chainName(l, chain)),
};

/// Plain words for an auto-lock choice: `Never`, `Immediately`, `After 5 minutes`.
String autoLockLabel(AppLocalizations l, int? minutes) => switch (minutes) {
  null => l.autoLockNever,
  0 => l.autoLockImmediately,
  _ => l.autoLockAfterMinutes(minutes),
};


/// The name of a display currency from `fiatCurrencies` (price.dart), by its lower-case code.
/// An unknown code is shown in capitals.
String currencyName(AppLocalizations l, String code) => switch (code) {
  'usd' => l.currencyUsd,
  'eur' => l.currencyEur,
  'gbp' => l.currencyGbp,
  'btc' => l.currencyBtc,
  'jpy' => l.currencyJpy,
  'cny' => l.currencyCny,
  'cad' => l.currencyCad,
  'aud' => l.currencyAud,
  'chf' => l.currencyChf,
  'inr' => l.currencyInr,
  'brl' => l.currencyBrl,
  'krw' => l.currencyKrw,
  'pln' => l.currencyPln,
  'try' => l.currencyTry,
  _ => code.toUpperCase(),
};

/// "Accepted 4 minutes ago." for an incoming payment this wallet signed [ago]: minutes below
/// 90, hours below 48, else days, each its own message so every language inflects it.
String acceptedAgoText(AppLocalizations l, Duration ago) {
  final minutes = ago.inMinutes;
  if (minutes < 90) return l.txDetailsAcceptedAgoMinutes(minutes);
  final hours = (minutes / 60).round();
  if (hours < 48) return l.txDetailsAcceptedAgoHours(hours);
  return l.txDetailsAcceptedAgoDays((hours / 24).round());
}

/// When a pairing invite went out, as a fixed fact for its row (never a ticking age): the clock
/// time today, "yesterday", else the day.
String invitedLine(AppLocalizations l, DateTime at, DateTime now) {
  final a = at.toLocal(), n = now.toLocal();
  final day = DateTime(a.year, a.month, a.day), today = DateTime(n.year, n.month, n.day);
  if (day == today) return l.pairInvitedAt(localClock(l, a));
  if (today.difference(day).inDays == 1) return l.pairInvitedYesterday;
  return l.pairInvitedOn(localDay(l, a));
}
