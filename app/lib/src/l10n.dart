// SPDX-License-Identifier: Apache-2.0
/// Localisation helpers: the `context.l10n` shortcut, the languages offered in settings, and
/// number and date text in the reader's conventions.
///
/// Strings live in `lib/l10n/app_<locale>.arb`; `flutter gen-l10n` (run by pub get, run, build
/// and test) turns them into [AppLocalizations]. Log lines, the feedback report and files meant
/// for other programs stay in English and never go through here.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'network.dart' show chainShownName;
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

/// A percentage as [l]'s language writes it (`40%` in English, `40 %` with a no-break space
/// in German, Polish and Russian): the one way every percent on both platforms is shown.
/// [value] is 0–100; a fraction is rounded unless [decimals] keeps some.
String percentText(AppLocalizations l, num value, {int decimals = 0}) =>
    l.percentValue(decimals == 0 ? localInt(l, value.round()) : localDigits(l, value.toStringAsFixed(decimals)));

// Dates. English keeps the day-first style the app always had ("21 Sep 2026"); the other
// languages use CLDR's patterns ("21. Sept. 2026", "2026年9月21日").

bool _dateData = false;

/// [t] in [format], with CLDR's names and patterns of every language loaded first (once, and at
/// once: the Future only reports it). Material's localizations load them too, but a screen
/// built without them (the desktop's settings in a test) formats the restore start as well.
String _date(DateFormat Function() format, DateTime t) {
  if (!_dateData) {
    initializeDateFormatting();
    _dateData = true;
  }
  return format().format(t);
}

/// `21 Sep 2026`.
String localDay(AppLocalizations l, DateTime t) =>
    _date(() => l.localeName == 'en' ? DateFormat('d MMM y', 'en') : DateFormat.yMMMd(l.localeName), t);

/// `21 Sep`.
String localDayMonth(AppLocalizations l, DateTime t) =>
    _date(() => l.localeName == 'en' ? DateFormat('d MMM', 'en') : DateFormat.MMMd(l.localeName), t);

/// `September 2021`, `Wrzesień 2021`, `2021年9月`: a month and its year as a value on its own
/// (the restore start), capitalised: Polish and Russian write the month small only inside a
/// sentence.
String localMonthYear(AppLocalizations l, DateTime t) {
  final s = _date(() => DateFormat.yMMMM(l.localeName), t);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// `Sep`, `Sept.`, `9月`: a month's short name on its own (the standalone form: `wrz`, not
/// a date's), in a month picker's grid.
String localMonthShort(AppLocalizations l, DateTime t) =>
    _date(() => DateFormat.LLL(l.localeName), t);

/// `September`: a month's full name, for a screen reader.
String localMonthName(AppLocalizations l, DateTime t) =>
    _date(() => DateFormat.LLLL(l.localeName), t);

/// `2021`, `2021年`: a year as a picker's header shows it.
String localYear(AppLocalizations l, DateTime t) => _date(() => DateFormat.y(l.localeName), t);

/// `14:05`, on the 24-hour clock in every language the app has.
String localClock(AppLocalizations l, DateTime t) =>
    _date(() => DateFormat.Hm(l.localeName), t);

// Names.

/// A chain's name, for the development builds only (`devNetworksBuild`): release builds show
/// no network name anywhere, so these are English literals and not in the l10n tables.
/// [l] is kept so the callers need no change.
String chainName(AppLocalizations l, Chain chain) => chainShownName(chain);

/// One sentence on what a chain is, for the development network picker (English only).
String chainDescription(AppLocalizations l, Chain chain) => switch (chain) {
  Chain.mainnet => 'The real Epic Cash network.',
  Chain.floonet => 'A public test network. Its coins have no value.',
  Chain.usernet => 'A test network running on this computer.',
};

/// ` (Test network)` to put after a title on a test network, empty for Mainnet. The
/// callers show it only when `devNetworksProvider` is on.
String networkSuffix(AppLocalizations l, Chain chain) => switch (chain) {
  Chain.mainnet => '',
  Chain.floonet || Chain.usernet => ' (${chainShownName(chain)})',
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


/// When a pairing invite went out, as a fixed fact for its row (never a ticking age): the clock
/// time today, "yesterday", else the day.
String invitedLine(AppLocalizations l, DateTime at, DateTime now) {
  final a = at.toLocal(), n = now.toLocal();
  final day = DateTime(a.year, a.month, a.day), today = DateTime(n.year, n.month, n.day);
  if (day == today) return l.pairInvitedAt(localClock(l, a));
  if (today.difference(day).inDays == 1) return l.pairInvitedYesterday;
  return l.pairInvitedOn(localDay(l, a));
}

/// The line under a payment's Message: which way the text went. The sender's message on an
/// incoming payment is "From the sender"; this wallet's own is "Sent to the recipient" (or to
/// the sender, for the receiver's message on an invoice).
String messageHint(AppLocalizations l, {required bool incoming, required bool bySender}) =>
    switch ((incoming, bySender)) {
      (false, true) => l.txDetailsMessageHintToRecipient,
      (true, true) => l.txDetailsMessageHintFromSender,
      (false, false) => l.txDetailsMessageHintFromRecipient,
      (true, false) => l.txDetailsMessageHintToSender,
    };
