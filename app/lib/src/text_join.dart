// SPDX-License-Identifier: Apache-2.0
/// How both apps join short pieces of text: a number and its unit, and the parts of a
/// metadata line. Display only: nothing here is ever parsed, sent or stored.
library;

import 'package:flutter/painting.dart' show InlineSpan, TextSpan, TextStyle;

/// U+00A0: a space a line never breaks at.
const String noBreakSpace = '\u00A0';

/// The separator between the parts of a metadata line ("Link · HTTP · Tom"): one space each
/// side of a middle dot, the one before it no-break, so a dot never starts a line; the line
/// may break after it.
const String metaSeparator = '$noBreakSpace\u00B7 ';

/// [number] and its [unit] as one piece that never wraps between them: `12.5000 EPIC`.
String withUnit(String number, String unit) => '$number$noBreakSpace$unit';

/// [parts] as one metadata line joined by [metaSeparator]. Null and blank parts are dropped
/// and each part is trimmed, so no separator is doubled and no space is doubled around one.
/// With [whole], each part never breaks inside ([keepWhole]): the line wraps only after a dot.
String metaLine(Iterable<String?> parts, {bool whole = false}) => [
  for (final p in parts)
    if (p?.trim() case final t? when t.isNotEmpty) whole ? keepWhole(t) : t,
].join(metaSeparator);

/// [text] with its spaces made no-break: a short fact that must never wrap inside
/// ("40 s ago", "Link · HTTP" as one method name).
String keepWhole(String text) => text.replaceAll(' ', noBreakSpace);

/// "≈ 5.25 USD": an estimate's mark, kept on the line of its figure.
String approxText(String figure) => '\u2248$noBreakSpace$figure';

/// [parts] as spans of one metadata line: [metaSeparator] between them, in [dot] when given
/// (a fainter dot than the words). Null parts are dropped, so nothing is doubled.
List<InlineSpan> metaSpans(Iterable<InlineSpan?> parts, {TextStyle? dot}) {
  final out = <InlineSpan>[];
  for (final p in parts) {
    if (p == null || (p is TextSpan && p.children == null && (p.text?.trim().isEmpty ?? true))) continue;
    if (out.isNotEmpty) out.add(TextSpan(text: metaSeparator, style: dot));
    out.add(p);
  }
  return out;
}

final RegExp _numberThenWord = RegExp(r'(\d) (?=\p{L})', unicode: true);

/// [text] with every ordinary space between a number and the word after it made no-break, so
/// a sentence never leaves a unit alone at the start of a line: `6 blocks`, `1,586.2321 EPIC`,
/// `(1 block)`. For a translated sentence that puts amounts and counts in its own words.
String keepNumbersWithUnits(String text) => text.replaceAllMapped(_numberThenWord, (m) => '${m[1]}$noBreakSpace');
