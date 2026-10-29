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
