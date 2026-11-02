// SPDX-License-Identifier: Apache-2.0
/// Conversion between atomic units and the decimal EPIC strings the user sees.
///
/// Amounts stay [BigInt] end to end. Doubles would lose precision above 2^53 atomic units.
library;

import 'l10n.dart' show AppLocalizations, LocalizedFormatException, localDecimal, localDigits;
import 'text_join.dart' show withUnit;

/// Number of decimal places in one EPIC.
const int epicDecimals = 8;

/// Atomic units in one EPIC.
final BigInt atomicPerEpic = BigInt.from(100000000);

/// Formats [atomic] as a decimal EPIC string, e.g. `150000000` -> `1.5`.
///
/// Trailing fractional zeros are dropped, but at least [minDecimals] digits are kept. With
/// [grouped], the whole part gets thousands separators (`1,234.5`). That is for display only:
/// [parseEpic] reads a comma as the decimal separator, so never put grouped text in a field.
String formatEpic(BigInt atomic, {int minDecimals = 0, bool grouped = false}) {
  assert(minDecimals >= 0 && minDecimals <= epicDecimals);
  final negative = atomic.isNegative;
  final abs = atomic.abs();
  final whole = abs ~/ atomicPerEpic;
  var fraction = (abs % atomicPerEpic).toString().padLeft(epicDecimals, '0');
  var end = fraction.length;
  while (end > minDecimals && fraction[end - 1] == '0') {
    end--;
  }
  fraction = fraction.substring(0, end);
  final wholeText = grouped ? _group(whole.toString()) : whole.toString();
  final text = fraction.isEmpty ? wholeText : '$wholeText.$fraction';
  return negative ? '-$text' : text;
}

/// Most decimals a compact amount shows: the rule of rows, tiles, lists, summaries, notices and
/// the balance headline, phone and desktop. Cut to four, then written up to the last
/// significant digit with at least one decimal (`0.892`, `12.5`, `2.0`), as every shown amount.
const int displayDecimals = 4;

/// Most decimals an exact amount shows: all eight a value has, up to its last significant
/// digit, at least one (`1.69154322`, `12.5`, `2.0`). Where exactness is the point: a payment's
/// review, its details, its QR code and payment request, fees.
const int exactDecimals = 8;

/// The decimals every shown amount writes out at least: `2.0`, never `2` or `2.00000000`.
const int shownMinDecimals = 1;

/// [atomic] cut to [decimals] decimals (towards zero, never rounded, so a balance never reads
/// more than it is), then up to its last significant digit with at least [shownMinDecimals],
/// grouped: `1,234.56`, `0.892`, `2.0`.
String cutEpic(BigInt atomic, int decimals) {
  assert(decimals >= 0 && decimals <= epicDecimals);
  final cut = BigInt.from(10).pow(epicDecimals - decimals);
  // `remainder` keeps the sign, so a negative amount is cut towards zero too.
  return formatEpic(
    atomic - atomic.remainder(cut),
    minDecimals: decimals < shownMinDecimals ? decimals : shownMinDecimals,
    grouped: true,
  );
}

/// [atomic] as the app shows an amount anywhere: at most [displayDecimals] decimals, cut off,
/// grouped: `1,234.56781234` shows as `1,234.5678`, `0.89200000` as `0.892`, `0` as `0.0`,
/// `20,999,999.99999999` as `20,999,999.9999`. Display only; where the exact value matters use
/// [exactEpic] (text) or [formatEpic] (fields, the clipboard, files).
String displayEpic(BigInt atomic) => cutEpic(atomic, displayDecimals);

/// [atomic] with every significant decimal, at least one, grouped: `1,234.56781234`, `12.5`,
/// `2.0`.
String exactEpic(BigInt atomic) =>
    formatEpic(atomic, minDecimals: shownMinDecimals, grouped: true);

/// Where an amount is shown. Each surface has one precision, the same on the phone and the
/// desktop, so a figure reads alike wherever it appears. Display only: fields, the clipboard
/// and files take [formatEpic].
enum AmountSurface {
  /// Rows, tiles, lists, summaries, notices and buttons: at most [displayDecimals], cut off.
  row(displayDecimals),

  /// Where money is committed or inspected: a payment's review (its Send button too), its
  /// details, its QR code and payment request. Up to [exactDecimals], as many as it has.
  exact(exactDecimals),

  /// The balance headline (phone Wallet, desktop Overview): at most [displayDecimals], the exact
  /// amount a tap or hover away.
  hero(displayDecimals);

  const AmountSurface(this.decimals);

  /// Most decimals shown on this surface; trailing zeros are dropped down to one decimal.
  final int decimals;
}

/// The unit of every amount.
const String epicUnit = 'EPIC';

/// [atomic] as [surface] shows it, canonical (`,` groups, `.` decimals) and without the unit:
/// `1,234.5678` for a row, `1,234.56781234` exact, `2.0` on both.
String surfaceEpic(BigInt atomic, AmountSurface surface) => cutEpic(atomic, surface.decimals);

/// The minus a shown amount carries: U+2212, as wide as the plus, never a hyphen.
const String minusSign = '\u2212';

/// [atomic] as [surface] shows it in [l]'s separators (`1.234,5678` in German), with the unit
/// after a no-break space unless [unit] is false: the one amount text of both apps (`2.0 EPIC`). With
/// [signed], `+` before a positive amount and [minusSign] before a negative one.
String epicFor(
  AppLocalizations l,
  BigInt atomic, {
  AmountSurface surface = AmountSurface.row,
  bool unit = true,
  bool signed = false,
}) {
  // The sign of what is shown: an amount that cuts to zero has none.
  final cut = BigInt.from(10).pow(epicDecimals - surface.decimals);
  final shown = atomic - atomic.remainder(cut);
  final digits = localDigits(l, surfaceEpic(shown.abs(), surface));
  final sign = shown.isNegative ? minusSign : (signed && shown > BigInt.zero ? '+' : '');
  final number = '$sign$digits';
  return unit ? withUnit(number, epicUnit) : number;
}

String _group(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

final RegExp _amountPattern = RegExp(r'^(\d*)(?:[.,](\d*))?$');

/// The most EPIC that will ever exist, 21 million, in atomic units. A typed amount above it is a
/// typo. It also keeps every parsed amount far below 2^53, so `toInt()` is exact on every
/// platform, the web included.
final BigInt maxEpicAtomic = BigInt.from(21000000) * atomicPerEpic;

/// What [parseEpic] refused, so a screen can word it its own way.
enum AmountProblem {
  /// Nothing typed, or not a plain decimal number ("abc", "1e5", "1.2.3", "-1").
  malformed,

  /// More than [epicDecimals] decimal places.
  decimals,

  /// More than [maxEpicAtomic].
  tooLarge,
}

/// [parseEpic]'s refusal: a [LocalizedFormatException] that also says which [problem].
class AmountFormatException extends LocalizedFormatException {
  AmountFormatException(this.problem, super.text, [super.source]);

  final AmountProblem problem;
}

/// Parses a user-entered EPIC amount into atomic units, exactly: never rounded, never wrapped.
///
/// The one amount parser of both apps. Accepts ASCII digits with `.` or `,` as the decimal
/// separator, at most [epicDecimals] fractional digits and at most [maxEpicAtomic]. Spaces,
/// units and thousands separators are the caller's to clean first (`normalizeAmountText`).
/// Throws an [AmountFormatException] for empty, negative, malformed, over-precise or too large
/// input.
BigInt parseEpic(String input) {
  final text = input.trim();
  final match = _amountPattern.firstMatch(text);
  if (text.isEmpty || match == null) {
    throw AmountFormatException(AmountProblem.malformed, (l) => l.amountEnterExample, input);
  }
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) {
    throw AmountFormatException(AmountProblem.malformed, (l) => l.amountEnterExample, input);
  }
  if (fraction.length > epicDecimals) {
    throw AmountFormatException(
      AmountProblem.decimals,
      (l) => l.amountTooManyDecimals(epicDecimals),
      input,
    );
  }
  final tooLarge = AmountFormatException(AmountProblem.tooLarge, (l) => l.sendAmountTooLarge, input);
  // 21 million has 8 digits: a longer whole part (leading zeros aside) is too large, without
  // parsing a pasted wall of digits.
  final digits = whole.replaceFirst(RegExp('^0+'), '');
  if (digits.length > 8) throw tooLarge;
  final wholePart = digits.isEmpty ? BigInt.zero : BigInt.parse(digits);
  final amount = wholePart * atomicPerEpic + BigInt.parse(fraction.padRight(epicDecimals, '0'));
  if (amount > maxEpicAtomic) throw tooLarge;
  return amount;
}

/// A fiat amount, cleaned by [normalizeAmountText], to atomic EPIC at [price]; [text] is what
/// was typed. A fiat amount is an estimate, so a double is fine here, but one too large for it
/// (Infinity) is refused like any amount above [maxEpicAtomic].
BigInt fiatToAtomic(String clean, double price, String text) {
  // `normalizeAmountText` leaves only digits and one dot, so no NaN, Infinity or 1e400.
  if (!RegExp(r'^\d*\.?\d*$').hasMatch(clean) || clean == '.' || clean.isEmpty) {
    throw LocalizedFormatException((l) => l.sendAmountEnterFiatExample, text);
  }
  final atomic = (double.parse(clean) / price * 100000000).roundToDouble();
  if (!atomic.isFinite || atomic > maxEpicAtomic.toDouble()) {
    throw LocalizedFormatException((l) => l.sendAmountTooLarge, text);
  }
  return BigInt.from(atomic);
}

/// Cleans a typed or pasted amount for parsing: removes spaces (also no-break and thin ones)
/// and apostrophes, a trailing unit such as "EPIC" or "USD", and thousands separators, and turns
/// a decimal comma into a dot.
///
/// Separators: when both `.` and `,` occur, the last one is the decimal separator
/// ("1,234.56", "1.234,56"). When only one kind occurs, more than one of it means thousands
/// ("1,234,567"). Thousands separators must group by exactly three after the first group, or
/// the amount is refused with a question ("1,234,5", "12,34.5"). A single one is the decimal
/// separator ("1,5", "0.25"). A single [groupSeparator], the one the app shows amounts with in
/// the reader's language (`,` in English, `.` in German), followed by exactly three digits
/// ("1,234") could be either, so it is refused with a question.
///
/// Throws a [LocalizedFormatException] for a negative or ambiguous amount.
String normalizeAmountText(
  String text, {
  required String unit,
  String groupSeparator = ',',
}) {
  var clean = text.replaceAll(RegExp(r"[\s\u00A0\u2009\u202F']"), '');
  final lower = clean.toLowerCase();
  if (lower.endsWith(unit.toLowerCase())) {
    clean = clean.substring(0, clean.length - unit.length);
  }
  if (clean.startsWith('-') || clean.startsWith('\u2212')) {
    throw LocalizedFormatException((l) => l.sendAmountNegative, text);
  }
  final dot = clean.lastIndexOf('.');
  final comma = clean.lastIndexOf(',');
  if (dot >= 0 && comma >= 0) {
    final decimal = dot > comma ? '.' : ',';
    final thousands = decimal == '.' ? ',' : '.';
    final at = clean.lastIndexOf(decimal);
    final whole = clean.substring(0, at);
    // One decimal separator, and the whole part grouped properly: "1,234.5", not "12,34.5"
    // or "1.2.3,4".
    if (whole.contains(decimal) || !_isGrouped(whole, thousands)) {
      throw _unclearAmount(text);
    }
    clean = '${whole.replaceAll(thousands, '')}.${clean.substring(at + 1)}';
  } else if (comma >= 0 || dot >= 0) {
    final sep = comma >= 0 ? ',' : '.';
    if (sep.allMatches(clean).length > 1) {
      // Several of one kind can only be thousands separators, so they must group by three:
      // "1,234,567", not "1,234,5".
      if (!_isGrouped(clean, sep)) throw _unclearAmount(text);
      clean = clean.replaceAll(sep, '');
    } else {
      final whole = clean.substring(0, clean.indexOf(sep));
      final fraction = clean.substring(clean.indexOf(sep) + 1);
      // "1,234" is 1.234 with a decimal comma but 1234 with a thousands comma, as the app
      // shows amounts in English ("1.234" in German). Guessing wrong sends 1000 times too much
      // or too little, so ask.
      if (sep == groupSeparator &&
          fraction.length == 3 &&
          RegExp(r'^[1-9]\d{0,2}$').hasMatch(whole)) {
        throw LocalizedFormatException(
          (l) => l.sendAmountAmbiguous(
            '$whole$fraction',
            localDecimal(l, '$whole.$fraction'),
          ),
          text,
        );
      }
      clean = clean.replaceAll(sep, '.');
    }
  }
  return clean;
}

LocalizedFormatException _unclearAmount(String text) =>
    LocalizedFormatException((l) => l.sendAmountUnclear, text);

/// Whether [digits] is 1 to 3 digits, then groups of exactly three after each [sep].
bool _isGrouped(String digits, String sep) =>
    RegExp('^\\d{1,3}(${RegExp.escape(sep)}\\d{3})*\$').hasMatch(digits);
