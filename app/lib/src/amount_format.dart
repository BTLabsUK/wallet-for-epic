// SPDX-License-Identifier: Apache-2.0
/// The plain-Dart part of `amount.dart`: atomic units to a canonical EPIC string. It imports no
/// Flutter, so the wallet core (the history export) can use it; `amount.dart` exports it.
library;

/// Number of decimal places in one EPIC.
const int epicDecimals = 8;

/// Atomic units in one EPIC.
final BigInt atomicPerEpic = BigInt.from(100000000);

/// Formats [atomic] as a decimal EPIC string, e.g. `150000000` -> `1.5`.
///
/// Trailing fractional zeros are dropped, but at least [minDecimals] digits are kept. With
/// [grouped], the whole part gets thousands separators (`1,234.5`). That is for display only:
/// `parseEpic` reads a comma as the decimal separator, so never put grouped text in a field.
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

/// The decimals every shown amount writes out at least: `2.0`, never `2` or `2.00000000`.
const int shownMinDecimals = 1;

String _group(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
