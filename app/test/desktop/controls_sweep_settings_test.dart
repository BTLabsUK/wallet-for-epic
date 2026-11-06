// SPDX-License-Identifier: Apache-2.0
// The controls sweep (controls_sweep.dart) over the first half of the Settings shots, after the
// Wallet and Transfer shots of controls_sweep_wallet_test.dart; the second half is in
// controls_sweep_settings_2_test.dart and controls_sweep_settings_3_test.dart.
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';

import 'controls_sweep.dart';

void main() => sweepControls(settingsShots.sublist(0, settingsShots.length ~/ 2), after: [...walletShots, ...transferShots]);
