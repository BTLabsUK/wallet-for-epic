// SPDX-License-Identifier: Apache-2.0
/// The full licence texts the app carries, for the phone's and the desktop's licence pages.
/// Each text is shown as it is written: one preformatted block, left-aligned, in the mono face.
/// Flutter's own page guessed at layout from indents (centred lines, indented blocks), which
/// turned plain-text licences such as Tor's into a scatter of centred lines.
library;

import 'package:flutter/foundation.dart' show LicenseEntry, LicenseEntryWithLineBreaks, LicenseParagraph, LicenseRegistry;

/// Every registered licence entry, grouped by package, packages sorted by name (case-insensitive).
Future<Map<String, List<LicenseEntry>>> collectLicences() async {
  final byPackage = <String, List<LicenseEntry>>{};
  await for (final entry in LicenseRegistry.licenses) {
    for (final package in entry.packages) {
      byPackage.putIfAbsent(package, () => []).add(entry);
    }
  }
  final names = byPackage.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final n in names) n: byPackage[n]!};
}

/// The text of [entry] as written: the original text with its own line breaks when the entry
/// keeps it (every entry Flutter and the app register does), otherwise its paragraphs one
/// after another, each indent level as two spaces, no centring.
String licenceText(LicenseEntry entry) {
  if (entry is LicenseEntryWithLineBreaks) return entry.text.trimRight();
  return [
    for (final p in entry.paragraphs)
      '${p.indent > 0 && p.indent != LicenseParagraph.centeredIndent ? '  ' * p.indent : ''}${p.text}',
  ].join('\n\n');
}
