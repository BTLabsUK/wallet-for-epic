// SPDX-License-Identifier: Apache-2.0
// Dumps everything in Flutter's LicenseRegistry, as the app has it at run time (the packages'
// NOTICES plus the licences the app registers: fonts, word lists, tor), to the JSON file named
// by LICENCES_JSON. Run by tool/licences/gen_licences.py; not part of the normal test run.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/password_lists.dart' show registerPasswordListLicences;
import 'package:epic_wallet/src/tor_licence.dart' show registerTorLicence;
import 'package:epic_wallet/src/ui/theme/fonts.dart' show registerFontLicences;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dump licences', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicences();
    registerPasswordListLicences();
    registerTorLicence();
    final out = Platform.environment['LICENCES_JSON'];
    if (out == null) fail('LICENCES_JSON not set');
    final byPackage = <String, List<String>>{};
    // The packages' licences: Flutter reads them from NOTICES.Z in the bundle at run time (the
    // same parse as services/binding.dart); a test has no such bundle, so it is read from a build.
    final notices = Platform.environment['LICENCES_NOTICES'];
    if (notices == null) fail('LICENCES_NOTICES not set (build/flutter_assets/NOTICES.Z)');
    final raw = utf8.decode(gzip.decode(File(notices).readAsBytesSync()));
    for (final block in raw.split('\n${'-' * 80}\n')) {
      final split = block.indexOf('\n\n');
      final names = split >= 0 ? block.substring(0, split).split('\n') : <String>[];
      final text = (split >= 0 ? block.substring(split + 2) : block).trimRight();
      for (final p in names) {
        byPackage.putIfAbsent(p, () => []).add(text);
      }
    }
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry is LicenseEntryWithLineBreaks
          ? entry.text.trimRight()
          : entry.paragraphs.map((p) => '${p.indent > 0 && p.indent != LicenseParagraph.centeredIndent ? '  ' * p.indent : ''}${p.text}').join('\n\n');
      for (final p in entry.packages) {
        byPackage.putIfAbsent(p, () => []).add(text);
      }
    }
    File(out).writeAsStringSync(jsonEncode(byPackage));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
