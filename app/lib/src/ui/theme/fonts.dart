import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The fallback for Thai, set on both themes: Montserrat and JetBrains Mono have no Thai, and the
/// platform's own Thai font differs per system (or is missing on some Linux installs).
const List<String> thaiFallback = ['NotoSansThai'];

/// The bundled fonts' OFL texts and the language flags' MIT text, keyed by the package name the
/// licences page shows.
const Map<String, String> fontLicenceAssets = {
  'Montserrat': 'assets/fonts/OFL-Montserrat.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  'Noto Sans Thai': 'assets/fonts/OFL-NotoSansThai.txt',
  'flag-icons': 'assets/flags/LICENSE-flag-icons.txt',
};

/// The licences screens' line for the language flags: a proper name and a licence, English as
/// the licence texts themselves.
const String flagsLicenceNote = 'Language flags from flag-icons: MIT licence.';

/// Adds the bundled fonts' licences to [LicenseRegistry], as OFL 1.1 requires when the fonts
/// are redistributed, and the flag-icons MIT text. They appear on the licences page next to the
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
