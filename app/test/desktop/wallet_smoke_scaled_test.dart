// SPDX-License-Identifier: Apache-2.0
// The wallet shots at narrow and phone width again at 125 % and 150 % (wallet_smoke.dart).
import 'package:flutter/material.dart';

import 'wallet_smoke.dart';

void main() => smokeWalletShots(const [
  (Size(1000, 700), 1.25),
  (Size(560, 800), 1.25),
  (Size(1000, 700), 1.5),
  (Size(560, 800), 1.5),
]);
