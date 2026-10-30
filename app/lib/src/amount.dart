// SPDX-License-Identifier: Apache-2.0
/// Conversion between atomic units and the decimal EPIC strings the user sees.
///
/// Amounts stay [BigInt] end to end. Doubles would lose precision above 2^53 atomic units.
library;

import 'l10n.dart' show LocalizedFormatException;

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

/// Decimals every shown amount has: the one display rule of both apps, phone and desktop
/// (headers, tiles, detail rows, activity lists, summaries, notices). Four, always written out
/// (`0.0000`, `12.5000`), so figures line up and a balance never reads as fiat.
const int displayDecimals = 4;

/// Decimals an exact amount has: all eight, always written out (`1.69154322`, `12.50000000`).
/// Only where exactness is the point: the balance sheet, a payment's exact amount, fees.
const int exactDecimals = 8;

/// [atomic] cut to [decimals] decimals (towards zero, never rounded, so a balance never reads
/// more than it is), shown with exactly that many, grouped (`1,234.5600`).
String cutEpic(BigInt atomic, int decimals) {
  assert(decimals >= 0 && decimals <= epicDecimals);
  final cut = BigInt.from(10).pow(epicDecimals - decimals);
  // `remainder` keeps the sign, so a negative amount is cut towards zero too.
  return formatEpic(
    atomic - atomic.remainder(cut),
    minDecimals: decimals,
    grouped: true,
  );
}

/// [atomic] as the app shows an amount anywhere: [displayDecimals] decimals, cut off, grouped:
/// `1,234.56781234` shows as `1,234.5678`, `0` as `0.0000`, `20,999,999.99999999` as
/// `20,999,999.9999`. Display only; where the exact value matters use [exactEpic] (text) or
/// [formatEpic] (fields, the clipboard, files).
String displayEpic(BigInt atomic) => cutEpic(atomic, displayDecimals);

/// [atomic] with every decimal, grouped: `1,234.56781234`, `12.50000000`.
String exactEpic(BigInt atomic) =>
    formatEpic(atomic, minDecimals: exactDecimals, grouped: true);

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
