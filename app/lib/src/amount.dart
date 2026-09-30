/// Conversion between atomic units and the decimal EPIC strings the user sees.
///
/// Amounts stay [BigInt] end to end. Doubles would lose precision above 2^53 atomic units.
library;

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
/// Throws [FormatException] for empty, negative, malformed or over-precise input.
BigInt parseEpic(String input) {
  final text = input.trim();
  final match = _amountPattern.firstMatch(text);
  if (text.isEmpty || match == null) {
    throw FormatException('Enter an amount such as 1.5', input);
  }
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) {
    throw FormatException('Enter an amount such as 1.5', input);
  }
  if (fraction.length > epicDecimals) {
    throw FormatException('At most $epicDecimals decimal places', input);
  }
  final wholePart = whole.isEmpty ? BigInt.zero : BigInt.parse(whole);
  final fractionPart = BigInt.parse(fraction.padRight(epicDecimals, '0'));
  return wholePart * atomicPerEpic + fractionPart;
}
