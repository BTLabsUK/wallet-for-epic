// SPDX-License-Identifier: Apache-2.0
// The controls sweep (controls_sweep.dart) over the Settings shots, after the Wallet and
// Transfer shots of controls_sweep_wallet_test.dart.
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';

import 'controls_sweep.dart';

void main() => sweepControls(settingsShots, after: [...walletShots, ...transferShots]);
