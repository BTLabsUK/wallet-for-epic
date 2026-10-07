import 'dart:async';

import 'package:epic_wallet/src/ui/common.dart';

/// Runs before every test file here. A waiting payment's tile loops for as long as it waits,
/// and a loop never lets `pumpAndSettle` settle, so the tests see the tile still (the full
/// current mark). `test/tx_icon_test.dart` turns the loop on for the tests of the loader.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  txEdgeRunMoves = false;
  await testMain();
}
