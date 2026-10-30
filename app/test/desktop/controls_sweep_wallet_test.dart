// SPDX-License-Identifier: Apache-2.0
// The controls sweep (controls_sweep.dart) over the Wallet and Transfer shots.
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';

import 'controls_sweep.dart';

void main() => sweepControls([...walletShots, ...transferShots]);
