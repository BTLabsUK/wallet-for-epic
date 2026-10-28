import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tor_build.dart';

/// Tor's licence file from the bundled Tor Expert Bundle (tools/fetch-tor.sh checks its hash).
const String torLicenceAsset = 'assets/licenses/tor.txt';

/// Where the bundled tor comes from, shown above its licence: these builds of tor say they are
/// covered by the GPL (version 3, https://www.gnu.org/licenses/gpl-3.0.txt), which asks that the
/// source be available.
const String torSourceNote =
    'The app runs tor 0.4.9.14, unmodified, from the Tor Project\'s Tor Expert Bundle 15.0.25 '
    '(desktop) and its Android bundle of the same version (phones). This build of tor is '
    'covered by the GNU General Public License, version 3 (https://www.gnu.org/licenses/gpl-3.0.txt). '
    'Its source: '
    'https://dist.torproject.org/tor-0.4.9.14.tar.gz and the Tor Browser build at '
    'https://gitlab.torproject.org/tpo/applications/tor-browser-build (release 15.0.25).';

/// Adds the bundled tor's licence to [LicenseRegistry], next to the packages'; nothing in the
/// build without Tor ([torBuilt]).
void registerTorLicence() {
  if (!torBuilt) return;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'tor',
    ], '$torSourceNote\n\n${await rootBundle.loadString(torLicenceAsset)}');
  });
}
