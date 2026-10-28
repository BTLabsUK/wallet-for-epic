// SPDX-License-Identifier: Apache-2.0
/// Whether this build has Tor: the one build-time switch of the variant without Tor (for app
/// stores and countries where Tor is a problem). `--dart-define=WFE_TOR=false` (or `0`, `off`)
/// builds it; the build scripts set it from their `WFE_TOR=0`, which also leaves the tor
/// binary out. Unset, Tor is in, as in every build before the switch.
///
/// Without Tor: no tor is looked for or started ([findTorBundle] is null, so both apps take
/// their "no tor" paths), Link · Tor and Tor only cannot be chosen (a stored choice reads as
/// off and Standard), and the screens hide every Tor switch, status and address. Sending to an
/// onion says this version cannot reach Tor addresses. LEPIC's Tor code stays in the library,
/// never called.
library;

import 'dist_build.dart';

const String _torDefine = String.fromEnvironment('WFE_TOR', defaultValue: 'true');

/// Tor is in this build (the default).
const bool torBuilt = _torDefine != 'false' && _torDefine != '0' && _torDefine != 'off';

/// The in-app update check and download run: never in the build without Tor, nor in a store
/// build ([distUpdates]). The update feed (update.json) names the builds with Tor, under the same
/// app ids, so an in-app update would put Tor back; app stores update their own builds (and
/// Google Play allows no other way).
const bool inAppUpdates = torBuilt && distUpdates;
