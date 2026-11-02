// SPDX-License-Identifier: Apache-2.0
// Switches for the two loops that widget tests turn off in test/flutter_test_config.dart: a loop
// never lets `pumpAndSettle` settle. They live alone in this file so the test config, which every
// test compiles, imports nothing else of the app: a change to a screen then reaches only the
// tests that use it (tools/t affected). Only tests write them.

/// Whether a waiting tile's run travels (`common.dart`). Off in widget tests, where the tile
/// then shows the full current mark, as with reduced motion. The loader's own tests turn it on.
bool txEdgeRunMoves = true;

/// Whether the current marker's ring on Send's tracker pulses (`send_tracker.dart`). Off in
/// widget tests; reduced motion stops it too.
bool sendPulseMoves = true;
