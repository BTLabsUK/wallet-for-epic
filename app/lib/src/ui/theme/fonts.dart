// SPDX-License-Identifier: Apache-2.0
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The fallback for Thai, set on both themes: Montserrat and JetBrains Mono have no Thai, and the
/// platform's own Thai font differs per system (or is missing on some Linux installs).
const List<String> thaiFallback = ['NotoSansThai'];

/// The Chinese UI's characters (and the language names), for installs without a CJK font.
const String cjkFamily = 'NotoSansSCSubset';

/// Every bundled fallback, in order: Thai, then Chinese. The pairing pictures are SVGs
/// (ui/sas_picture.dart) and need no font.
const List<String> bundledFallback = ['NotoSansThai', cjkFamily];

/// [bundledFallback] where the phone theme needs it: never on Android, which has Thai in its own
/// fonts, and where any fallback list moved body text off Roboto on Android 11 to a font that
/// draws Polish ś, ć, ń, ź and ż as a letter with a loose accent. The real system is
/// asked, not the target platform, so tests and tours on a desktop host keep the bundled font.
List<String>? get phoneFontFallback => !kIsWeb && Platform.isAndroid ? null : bundledFallback;

/// The bundled fonts' OFL texts, the language flags' MIT text and the pairing pictures' notice, keyed by the package name the
/// licences page shows.
const Map<String, String> fontLicenceAssets = {
  'Montserrat': 'assets/fonts/OFL-Montserrat.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  'Noto Sans Thai': 'assets/fonts/OFL-NotoSansThai.txt',
  'Noto Sans SC (subset)': 'assets/fonts/OFL-NotoSansSC.txt',
  'flag-icons': 'assets/flags/LICENSE-flag-icons.txt',
  'Noto Emoji (pairing pictures)': 'assets/sas/LICENSE.txt',
  'Status icons (Bootstrap Icons, Carbon, Material Symbols)': 'assets/licenses/status-icons.txt',
};

/// The licences screens' line for the language flags: a proper name and a licence, English as
/// the licence texts themselves.
const String flagsLicenceNote = 'Language flags from flag-icons: MIT licence.';

/// The licences screens' line for the pairing pictures (assets/sas, ui/sas_picture.dart), in
/// English like [flagsLicenceNote].
const String sasPicturesLicenceNote = 'Pairing pictures from Noto Emoji: Apache 2.0 licence.';

/// Adds the bundled fonts' licences to [LicenseRegistry], as OFL 1.1 requires when the fonts
/// are redistributed, the flag-icons MIT text and the Noto Emoji notice of the pairing pictures. They appear on the licences page next to the
/// packages'.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: asset) in fontLicenceAssets.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(asset));
    }
  });
}
