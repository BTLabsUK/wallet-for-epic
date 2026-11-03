// SPDX-License-Identifier: Apache-2.0
// The controls sweep (controls_sweep.dart) over the second half of the Settings shots, after
// every shot the other sweep files press.
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';

import 'controls_sweep.dart';

void main() => sweepControls(settingsShots.sublist(settingsShots.length ~/ 2),
    after: [...walletShots, ...transferShots, ...settingsShots.sublist(0, settingsShots.length ~/ 2)]);
