// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/send_tracker.dart';
import 'package:flutter_test/flutter_test.dart' show setUp;

import 'support/test_settings.dart';

/// Runs before every test file here. A waiting payment's tile loops for as long as it waits,
/// and so does the pulse on Send's tracker. A loop never lets `pumpAndSettle` settle, so the
/// tests see both still (the full current mark, a plain ring). `test/tx_icon_test.dart` turns
/// the tile's loop on for the tests of the loader. Every test reads its hosts from
/// `test/settings/` (the two files, example hosts only), the process-wide settings.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  txEdgeRunMoves = false;
  sendPulseMoves = false;
  hostSettings = testSettings();
  // A test that changes the settings (a pick, a switch) does not leak into the next one.
  setUp(() {
    hostSettings = testSettings();
    shippedHostSettings = hostSettings;
  });
  await testMain();
}
