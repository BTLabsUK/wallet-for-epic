import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled fonts' OFL texts, keyed by the package name the licences page shows.
const Map<String, String> fontLicenceAssets = {
  'Montserrat': 'assets/fonts/OFL-Montserrat.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
};

/// Adds the bundled fonts' licences to [LicenseRegistry], as OFL 1.1 requires when the fonts
/// are redistributed. They appear on the licences page next to the packages'.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: asset) in fontLicenceAssets.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(asset));
    }
  });
}
