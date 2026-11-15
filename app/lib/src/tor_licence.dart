// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tor_build.dart';

/// Tor's licence file from the bundled Tor Expert Bundle (tools/fetch-tor.sh checks its hash).
const String torLicenceAsset = 'assets/licenses/tor.txt';

/// Where the bundled tor comes from, shown above its licence on the Licences page: these builds of tor say they are
/// covered by the GPL (version 3), which asks that the source be available. The text, with the
/// addresses of the licence and the source, is an asset so that no address is in the code.
const String torSourceAsset = 'assets/licenses/tor-source.txt';

/// Adds the bundled tor's licence to [LicenseRegistry], next to the packages'; nothing in the
/// build without Tor ([torBuilt]).
void registerTorLicence() {
  if (!torBuilt) return;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'tor',
    ], '${(await rootBundle.loadString(torSourceAsset)).trim()}\n\n${await rootBundle.loadString(torLicenceAsset)}');
  });
}
