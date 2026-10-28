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

/// Digits, whole and decimal, that [displayEpic] shows before it drops decimals.
const int displayDigits = 10;

/// Decimals [displayEpic] keeps at most for [atomic]: all 8 up to 99.99999999, then one fewer
/// for each further digit of the whole part, so whole and decimal digits stay within
/// [displayDigits], and never fewer than 2 (`20,999,999.99`).
int displayDecimals(BigInt atomic) {
  final wholeDigits = (atomic.abs() ~/ atomicPerEpic).toString().length;
  return (displayDigits - wholeDigits).clamp(2, epicDecimals);
}

/// [atomic] as the app shows an amount: grouped, with [displayDecimals] decimals at most and
/// trailing zeros dropped. The digits beyond are cut off, never rounded, so a balance never
/// reads more than it is: `1,234,567.12345678` shows as `1,234,567.123`.
///
/// Display only. Where the exact value matters (the Send review, transaction details, the
/// balance help, CSV, fields), use [formatEpic].
String displayEpic(BigInt atomic) {
  final cut = BigInt.from(10).pow(epicDecimals - displayDecimals(atomic));
  // `remainder` keeps the sign, so a negative amount is cut towards zero too.
  return formatEpic(atomic - atomic.remainder(cut), grouped: true);
}

/// Decimals the headline balance shows: the big figure on the phone's Wallet and in its Send
/// and Receive bar, and on the desktop's Overview.
const int headlineDecimals = 2;

/// [atomic] as the headline balance shows it: grouped, with exactly [headlineDecimals]
/// decimals, the rest cut off, never rounded, so the figure never reads more than the wallet
/// holds: `1,234.56781234` shows as `1,234.56`, and `0` as `0.00`. The exact amount stays a
/// tap or a hover away ([formatEpic]); everywhere exactness matters keeps all 8.
String headlineEpic(BigInt atomic) {
  final cut = BigInt.from(10).pow(epicDecimals - headlineDecimals);
  return formatEpic(
    atomic - atomic.remainder(cut),
    minDecimals: headlineDecimals,
    grouped: true,
  );
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

/// Parses a user-entered EPIC amount into atomic units.
///
/// Accepts `.` or `,` as the decimal separator and at most [epicDecimals] fractional digits.
/// Throws a [LocalizedFormatException] for empty, negative, malformed or over-precise input.
BigInt parseEpic(String input) {
  final text = input.trim();
  final match = _amountPattern.firstMatch(text);
  if (text.isEmpty || match == null) {
    throw LocalizedFormatException((l) => l.amountEnterExample, input);
  }
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) {
    throw LocalizedFormatException((l) => l.amountEnterExample, input);
  }
  if (fraction.length > epicDecimals) {
    throw LocalizedFormatException(
      (l) => l.amountTooManyDecimals(epicDecimals),
      input,
    );
  }
  final wholePart = whole.isEmpty ? BigInt.zero : BigInt.parse(whole);
  final fractionPart = BigInt.parse(fraction.padRight(epicDecimals, '0'));
  return wholePart * atomicPerEpic + fractionPart;
}
