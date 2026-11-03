// SPDX-License-Identifier: Apache-2.0
// The wallet shots at desktop, narrow and phone width (wallet_smoke.dart); the larger text
// scales are in wallet_smoke_scaled_test.dart, so no one file sets the length of a whole run.
import 'package:flutter/material.dart';

import 'wallet_smoke.dart';

void main() => smokeWalletShots(const [
  (Size(1280, 800), 1.0),
  (Size(1000, 700), 1.0),
  (Size(560, 800), 1.0),
]);
