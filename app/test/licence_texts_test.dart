// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/licence_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a licence with line breaks shows as written: its indents and centred lines kept as text', () {
    const raw = '        This file contains the license for Tor,\n'
        '   a free software project.\n\n'
        'Redistribution and use in source and binary forms\n'
        '  * are permitted.\n';
    expect(licenceText(LicenseEntryWithLineBreaks(const ['tor'], raw)), raw.trimRight());
  });

  test('an entry without the raw text: paragraphs in order, indents as spaces, none centred', () {
    final entry = _Paragraphs(const [
      LicenseParagraph('Title', LicenseParagraph.centeredIndent),
      LicenseParagraph('Body', 0),
      LicenseParagraph('Item', 2),
    ]);
    expect(licenceText(entry), 'Title\n\nBody\n\n    Item');
  });
}

class _Paragraphs extends LicenseEntry {
  const _Paragraphs(this.paragraphs);

  @override
  Iterable<String> get packages => const ['x'];

  @override
  final Iterable<LicenseParagraph> paragraphs;
}
