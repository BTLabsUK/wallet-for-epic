// SPDX-License-Identifier: Apache-2.0
/// Whether this build offers and names the test networks: a dev build only.
library;

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `--dart-define=WFE_DEV_NETWORKS=true`: the test networks (floonet, usernet) are offered
/// in the UI. Off in every release build: the wallet runs on one network and never names it.
const bool devNetworksBuild = bool.fromEnvironment('WFE_DEV_NETWORKS');

/// Whether the UI offers and names networks: a dev build only. Tests override it to reach the
/// picker.
final devNetworksProvider = Provider<bool>((ref) => devNetworksBuild);

/// [devNetworksProvider] for code that has only a [BuildContext] (a face, an offscreen render).
bool devNetworksOf(BuildContext context) {
  try {
    return ProviderScope.containerOf(context, listen: false).read(devNetworksProvider);
  } catch (_) {
    return devNetworksBuild;
  }
}
